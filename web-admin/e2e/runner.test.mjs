import assert from 'node:assert/strict'
import { randomUUID } from 'node:crypto'
import { EventEmitter } from 'node:events'
import test from 'node:test'

import { createMockTransport } from './mockTransport.mjs'
import {
  execute,
  observeBrowserDiagnostics,
  readApprovalManifest,
  scenarioIds,
  validateRuntimeConfig,
} from './runner.mjs'

const runtimeEnv = {
  EDUTRACK_E2E_BASE_URL: 'https://staging.example.invalid/api/v1',
  EDUTRACK_E2E_ADMIN_EMAIL: 'admin-fixture@example.invalid',
  EDUTRACK_E2E_ADMIN_PASSWORD: randomUUID(),
  EDUTRACK_E2E_KAPRODI_EMAIL: 'kaprodi-fixture@example.invalid',
  EDUTRACK_E2E_KAPRODI_PASSWORD: randomUUID(),
  EDUTRACK_E2E_MAHASISWA_EMAIL: 'student-fixture@example.invalid',
  EDUTRACK_E2E_MAHASISWA_PASSWORD: randomUUID(),
}

function approvedManifest(scenario) {
  return {
    targetApproved: true,
    approvalReference: 'OPS-APPROVAL-REF',
    environmentClassification: 'staging',
    databaseClassification: 'disposable',
    databaseTarget: 'isolated-e2e-db',
    credentialSource: 'approved-secret-manager',
    credentialReferences: {
      admin: 'approved-admin-test-account',
      kaprodi: 'approved-kaprodi-test-account',
      mahasiswa: 'approved-mahasiswa-test-account',
    },
    baseUrl: runtimeEnv.EDUTRACK_E2E_BASE_URL,
    expiresAt: '2027-01-01T00:00:00.000Z',
    cleanupPolicy: 'runner-created-records-only',
    approvedRoles: ['admin', 'kaprodi', 'mahasiswa'],
    scenarioApprovals: { [scenario]: { approved: true } },
    productDecisions: {
      kaprodiAnnouncementRead: 'global-approved',
      kaprodiAnnouncementWrite: 'global-approved',
    },
  }
}

test('mock mode completes API flow and cleans up only its own record', async () => {
  const transport = createMockTransport({
    preexistingRecords: [{ id: 700, title: 'pre-existing-record' }],
  })
  const report = await execute({
    mode: 'mock',
    scenario: scenarioIds.admin,
    fetchImpl: transport.fetch,
  })

  assert.equal(report.status, 'PASS')
  assert.equal(report.mode, 'mock')
  assert.deepEqual(report.assertions.filter((item) => item.status === 'FAIL'), [])
  assert.equal(report.cleanupStatus, 'PASS')
  assert.deepEqual([...transport.records.keys()], [700])
  assert.equal(report.consoleErrors.status, 'NOT_COLLECTED_API_ONLY')
  assert.equal(transport.requests.some((request) => request.pathname === 'login'), false)
  assert.ok(transport.requests.some((request) => request.pathname === 'admin/announcements'))
})

test('mock assertion failure is reported and the runner still cleans its created record', async () => {
  const transport = createMockTransport({ omitReadbackForRole: 'mahasiswa' })
  const report = await execute({
    mode: 'mock',
    scenario: scenarioIds.admin,
    fetchImpl: transport.fetch,
  })

  assert.equal(report.status, 'FAIL')
  assert.ok(report.assertions.some((item) => item.name === 'mahasiswa.readback' && item.status === 'FAIL'))
  assert.equal(report.cleanupStatus, 'PASS')
  assert.equal(transport.records.size, 0)
})

test('create response mismatch fails and requires manual review', async () => {
  const transport = createMockTransport()
  const report = await execute({
    mode: 'mock',
    scenario: scenarioIds.admin,
    fetchImpl: async (input, options) => {
      const url = new URL(input)
      if (options.method === 'POST' && url.pathname.endsWith('/admin/announcements')) {
        return {
          status: 201,
          async json() {
            return { status: 'Created', data: { id: 1, title: 'unexpected-record' } }
          },
        }
      }
      return transport.fetch(input, options)
    },
  })

  assert.equal(report.status, 'FAIL')
  assert.ok(report.assertions.some((item) => item.name === 'writer.create_announcement' && item.status === 'FAIL'))
  assert.equal(report.cleanupStatus, 'MANUAL_REVIEW_REQUIRED')
  assert.equal(transport.requests.some((request) => request.method === 'DELETE'), false)
})

test('create with an unreadable response requires manual review', async () => {
  const report = await execute({
    mode: 'mock',
    scenario: scenarioIds.admin,
    fetchImpl: async (input, options) => {
      const url = new URL(input)
      if (options.method === 'POST' && url.pathname.endsWith('/admin/announcements')) {
        return {
          status: 201,
          async json() {
            throw new Error('response parse details')
          },
        }
      }
      throw new Error('Unexpected follow-up request')
    },
  })

  assert.equal(report.status, 'FAIL')
  assert.equal(report.cleanupStatus, 'MANUAL_REVIEW_REQUIRED')
  assert.equal(JSON.stringify(report).includes('response parse details'), false)
})

test('mock mode exercises the Kaprodi writer scenario without runtime approval', async () => {
  const transport = createMockTransport()
  const report = await execute({
    mode: 'mock',
    scenario: scenarioIds.kaprodi,
    fetchImpl: transport.fetch,
  })

  assert.equal(report.status, 'PASS')
  assert.ok(transport.requests.some(
    (request) => request.method === 'POST' &&
      request.pathname === 'admin/announcements' &&
      request.role === 'kaprodi',
  ))
  assert.equal(transport.records.size, 0)
})

test('failed cleanup preserves the record and requires manual review', async () => {
  const transport = createMockTransport({ failDelete: true })
  const report = await execute({
    mode: 'mock',
    scenario: scenarioIds.admin,
    fetchImpl: transport.fetch,
  })

  assert.equal(report.status, 'FAIL')
  assert.equal(report.cleanupStatus, 'MANUAL_REVIEW_REQUIRED')
  assert.equal(transport.records.size, 1)
})

test('runtime preflight blocks before any login or mutation request when approval is missing', async () => {
  let requestCount = 0
  const report = await execute({
    mode: 'runtime',
    scenario: scenarioIds.admin,
    env: runtimeEnv,
    fetchImpl: async () => {
      requestCount += 1
      throw new Error('Must not be called')
    },
  })

  assert.equal(report.status, 'BLOCKED')
  assert.equal(requestCount, 0)
  assert.ok(report.blockedReasons.includes('approval_manifest_missing'))
})

test('runtime preflight rejects a manifest whose database is not disposable', async () => {
  const approval = { ...approvedManifest(scenarioIds.admin), databaseClassification: 'unknown' }
  let requestCount = 0

  const report = await execute({
    mode: 'runtime',
    scenario: scenarioIds.admin,
    env: runtimeEnv,
    approval,
    fetchImpl: async () => {
      requestCount += 1
      throw new Error('Must not be called')
    },
  })

  assert.equal(report.status, 'BLOCKED')
  assert.equal(requestCount, 0)
  assert.ok(report.blockedReasons.includes('database_not_confirmed_disposable'))
})

test('runtime preflight requires accounts to be approved from a secret manager', () => {
  const approval = {
    ...approvedManifest(scenarioIds.admin),
    credentialSource: 'unverified',
    credentialReferences: {},
  }
  assert.throws(
    () => validateRuntimeConfig({
      env: runtimeEnv,
      approval,
      scenario: scenarioIds.admin,
      now: new Date('2026-11-23T00:00:00.000Z'),
    }),
    (error) => error.name === 'PreconditionError' &&
      error.reasons.includes('credential_source_not_approved') &&
      error.reasons.includes('admin_credential_reference_missing'),
  )
})

test('runtime preflight requires explicit Kaprodi scope approval', () => {
  const approval = {
    ...approvedManifest(scenarioIds.admin),
    productDecisions: { kaprodiAnnouncementRead: 'pending' },
  }
  assert.throws(
    () => validateRuntimeConfig({
      env: runtimeEnv,
      approval,
      scenario: scenarioIds.admin,
      now: new Date('2026-11-23T00:00:00.000Z'),
    }),
    (error) => error.name === 'PreconditionError' &&
      error.reasons.includes('kaprodi_announcement_read_scope_not_approved'),
  )
})

test('complete runtime approval produces a config without making requests', () => {
  const config = validateRuntimeConfig({
    env: runtimeEnv,
    approval: approvedManifest(scenarioIds.admin),
    scenario: scenarioIds.admin,
    now: new Date('2026-11-23T00:00:00.000Z'),
  })

  assert.equal(config.mode, 'runtime')
  assert.equal(config.baseUrl, runtimeEnv.EDUTRACK_E2E_BASE_URL)
  assert.match(config.runId, /^e2e-/)
})

test('blocked report never includes account secrets', async () => {
  const report = await execute({
    mode: 'runtime',
    scenario: scenarioIds.admin,
    env: runtimeEnv,
  })
  const output = JSON.stringify(report)
  for (const value of Object.values(runtimeEnv)) {
    assert.equal(output.includes(value), false)
  }
})

test('network failures are summarized without request data', async () => {
  const report = await execute({
    mode: 'mock',
    scenario: scenarioIds.admin,
    fetchImpl: async () => {
      throw new Error('private request contents')
    },
  })

  assert.equal(report.status, 'FAIL')
  assert.deepEqual(report.networkErrors, [{ step: 'writer.create_announcement', kind: 'request_failed' }])
  assert.equal(report.cleanupStatus, 'MANUAL_REVIEW_REQUIRED')
  assert.equal(JSON.stringify(report).includes('private request contents'), false)
})

test('browser diagnostic adapter captures error classes without messages or URLs', () => {
  const page = new EventEmitter()
  const sensitiveSentinel = randomUUID()
  const observer = observeBrowserDiagnostics(page)
  page.emit('console', { type: () => 'error', text: () => sensitiveSentinel })
  page.emit('pageerror', new Error(sensitiveSentinel))
  page.emit('requestfailed', { url: () => `https://example.invalid/?reference=${sensitiveSentinel}` })

  const report = observer.snapshot()
  assert.deepEqual(report.consoleErrors, [{ kind: 'console_error' }, { kind: 'page_error' }])
  assert.deepEqual(report.networkErrors, [{ kind: 'request_failed' }])
  assert.equal(JSON.stringify(report).includes(sensitiveSentinel), false)
  observer.detach()
})

test('approval manifest inside repository is rejected before file access', async () => {
  const repoRoot = process.cwd()
  await assert.rejects(
    readApprovalManifest({
      EDUTRACK_E2E_APPROVAL_FILE: `${repoRoot}/package.json`,
    }, repoRoot),
    (error) => error.name === 'PreconditionError' &&
      error.reasons.includes('approval_manifest_must_be_outside_repository'),
  )
})
