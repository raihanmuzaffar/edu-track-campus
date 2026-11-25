import { randomUUID } from 'node:crypto'
import { readFile, realpath } from 'node:fs/promises'
import path from 'node:path'
import { fileURLToPath, pathToFileURL } from 'node:url'

export const scenarioIds = Object.freeze({
  admin: 'admin-announcement-to-prodi-mobile',
  kaprodi: 'kaprodi-announcement-to-admin-mobile',
})

const scenarioDefinitions = {
  [scenarioIds.admin]: { writerRole: 'admin' },
  [scenarioIds.kaprodi]: { writerRole: 'kaprodi' },
}

const roleEnvironment = {
  admin: ['EDUTRACK_E2E_ADMIN_EMAIL', 'EDUTRACK_E2E_ADMIN_PASSWORD'],
  kaprodi: ['EDUTRACK_E2E_KAPRODI_EMAIL', 'EDUTRACK_E2E_KAPRODI_PASSWORD'],
  mahasiswa: ['EDUTRACK_E2E_MAHASISWA_EMAIL', 'EDUTRACK_E2E_MAHASISWA_PASSWORD'],
}

export class PreconditionError extends Error {
  constructor(reasons) {
    super('Runtime E2E preconditions are not satisfied.')
    this.name = 'PreconditionError'
    this.reasons = reasons
  }
}

export function observeBrowserDiagnostics(page) {
  if (!page || typeof page.on !== 'function') {
    throw new TypeError('A Playwright-compatible page event source is required.')
  }
  const diagnostics = { consoleErrors: [], networkErrors: [] }
  const onConsole = (message) => {
    if (message?.type?.() === 'error') diagnostics.consoleErrors.push({ kind: 'console_error' })
  }
  const onPageError = () => diagnostics.consoleErrors.push({ kind: 'page_error' })
  const onRequestFailed = () => diagnostics.networkErrors.push({ kind: 'request_failed' })

  page.on('console', onConsole)
  page.on('pageerror', onPageError)
  page.on('requestfailed', onRequestFailed)

  return {
    snapshot: () => ({
      consoleErrors: [...diagnostics.consoleErrors],
      networkErrors: [...diagnostics.networkErrors],
    }),
    detach() {
      page.off?.('console', onConsole)
      page.off?.('pageerror', onPageError)
      page.off?.('requestfailed', onRequestFailed)
    },
  }
}

function normalizedUrl(value) {
  try {
    const url = new URL(value)
    if (!['http:', 'https:'].includes(url.protocol) || url.username || url.password || url.search || url.hash) {
      return null
    }
    return url.toString().replace(/\/+$/, '')
  } catch {
    return null
  }
}

function validRunId(value) {
  return typeof value === 'string' && /^[a-zA-Z0-9][a-zA-Z0-9_-]{0,47}$/.test(value)
}

function reportRunId(value) {
  return validRunId(value) ? value : 'unassigned'
}

function isWithinDirectory(directory, target) {
  const relativePath = path.relative(directory, target)
  return relativePath === '' ||
    (relativePath !== '..' &&
      !relativePath.startsWith(`..${path.sep}`) &&
      !path.isAbsolute(relativePath))
}

export function validateRuntimeConfig({ env, approval, scenario, now = new Date() }) {
  const reasons = []
  const definition = scenarioDefinitions[scenario]
  const baseUrl = normalizedUrl(env.EDUTRACK_E2E_BASE_URL)
  const approvedBaseUrl = normalizedUrl(approval?.baseUrl)

  if (!definition) reasons.push('scenario_not_supported')
  if (!baseUrl) reasons.push('EDUTRACK_E2E_BASE_URL_missing_or_invalid')
  if (!approval) reasons.push('approval_manifest_missing')
  if (approval?.targetApproved !== true || !approval.approvalReference) {
    reasons.push('owner_approval_missing')
  }
  if (!['staging', 'disposable'].includes(approval?.environmentClassification)) {
    reasons.push('environment_not_approved')
  }
  if (approval?.databaseClassification !== 'disposable' || !approval.databaseTarget) {
    reasons.push('database_not_confirmed_disposable')
  }
  if (approval?.credentialSource !== 'approved-secret-manager') {
    reasons.push('credential_source_not_approved')
  }
  if (!approvedBaseUrl || approvedBaseUrl !== baseUrl) reasons.push('base_url_not_in_approval_manifest')
  if (!Number.isFinite(Date.parse(approval?.expiresAt)) || Date.parse(approval.expiresAt) <= now.getTime()) {
    reasons.push('approval_expired_or_invalid')
  }
  if (approval?.cleanupPolicy !== 'runner-created-records-only') {
    reasons.push('cleanup_policy_not_limited_to_runner_records')
  }
  if (definition && approval?.scenarioApprovals?.[scenario]?.approved !== true) {
    reasons.push('scenario_not_approved')
  }
  if (definition && approval?.productDecisions?.kaprodiAnnouncementRead !== 'global-approved') {
    reasons.push('kaprodi_announcement_read_scope_not_approved')
  }
  if (definition?.writerRole === 'kaprodi' &&
      approval?.productDecisions?.kaprodiAnnouncementWrite !== 'global-approved') {
    reasons.push('kaprodi_announcement_write_scope_not_approved')
  }
  if (definition && !approval?.approvedRoles?.includes('admin')) reasons.push('admin_role_not_approved')
  if (definition && !approval?.approvedRoles?.includes('kaprodi')) reasons.push('kaprodi_role_not_approved')
  if (definition && !approval?.approvedRoles?.includes('mahasiswa')) reasons.push('mahasiswa_role_not_approved')

  const credentials = {}
  for (const [role, names] of Object.entries(roleEnvironment)) {
    const [emailName, passwordName] = names
    if (!env[emailName]) reasons.push(`${emailName}_missing`)
    if (!env[passwordName]) reasons.push(`${passwordName}_missing`)
    if (!approval?.credentialReferences?.[role]) reasons.push(`${role}_credential_reference_missing`)
    credentials[role] = { email: env[emailName], password: env[passwordName] }
  }

  const timeoutMs = env.EDUTRACK_E2E_TIMEOUT_MS === undefined
    ? 10000
    : Number(env.EDUTRACK_E2E_TIMEOUT_MS)
  if (!Number.isInteger(timeoutMs) || timeoutMs < 1000 || timeoutMs > 30000) {
    reasons.push('EDUTRACK_E2E_TIMEOUT_MS_out_of_range')
  }

  const requestedRunId = env.EDUTRACK_E2E_RUN_ID
  if (requestedRunId && !validRunId(requestedRunId)) reasons.push('EDUTRACK_E2E_RUN_ID_invalid')
  if (reasons.length > 0) throw new PreconditionError(reasons)

  return {
    mode: 'runtime',
    scenario,
    baseUrl,
    timeoutMs,
    runId: requestedRunId || `e2e-${randomUUID().slice(0, 12)}`,
    credentials,
  }
}

export async function readApprovalManifest(env, repoRoot) {
  const approvalPath = env.EDUTRACK_E2E_APPROVAL_FILE
  if (!approvalPath || !path.isAbsolute(approvalPath)) {
    throw new PreconditionError(['EDUTRACK_E2E_APPROVAL_FILE_must_be_an_absolute_path'])
  }

  const resolvedPath = path.resolve(approvalPath)
  if (isWithinDirectory(path.resolve(repoRoot), resolvedPath)) {
    throw new PreconditionError(['approval_manifest_must_be_outside_repository'])
  }

  let resolvedRepoRoot
  let resolvedManifestPath
  try {
    [resolvedRepoRoot, resolvedManifestPath] = await Promise.all([
      realpath(repoRoot),
      realpath(resolvedPath),
    ])
  } catch {
    throw new PreconditionError(['approval_manifest_unavailable'])
  }
  if (isWithinDirectory(resolvedRepoRoot, resolvedManifestPath)) {
    throw new PreconditionError(['approval_manifest_must_be_outside_repository'])
  }

  let contents
  try {
    contents = await readFile(resolvedManifestPath, 'utf8')
  } catch {
    throw new PreconditionError(['approval_manifest_unavailable'])
  }
  try {
    return JSON.parse(contents)
  } catch {
    throw new PreconditionError(['approval_manifest_invalid_json'])
  }
}

function createReport(mode, scenario, runId) {
  return {
    mode: ['mock', 'runtime'].includes(mode) ? mode : 'unsupported',
    scenario: scenarioDefinitions[scenario] ? scenario : 'unsupported',
    runId: reportRunId(runId),
    status: 'FAIL',
    assertions: [],
    networkErrors: [],
    consoleErrors: { status: 'NOT_COLLECTED_API_ONLY', count: 0 },
    cleanupStatus: 'NOT_NEEDED',
    evidence: ['HTTP API assertions only; browser UI and Flutter runtime are not exercised.'],
  }
}

function assertStep(report, name, passed) {
  report.assertions.push({ name, status: passed ? 'PASS' : 'FAIL' })
  if (!passed) {
    const error = new Error('assertion_failed')
    error.step = name
    throw error
  }
}

async function request(config, fetchImpl, report, step, endpoint, { method = 'GET', identity, body } = {}) {
  const controller = new AbortController()
  const timeout = setTimeout(() => controller.abort(), config.timeoutMs)
  let response
  try {
    const url = new URL(endpoint.replace(/^\/+/, ''), `${config.baseUrl}/`)
    response = await fetchImpl(url, {
      method,
      redirect: 'error',
      signal: controller.signal,
      headers: {
        Accept: 'application/json',
        ...(body === undefined ? {} : { 'Content-Type': 'application/json' }),
        ...(config.mode === 'mock' && identity ? { 'X-Mock-Role': identity.role } : {}),
        ...(config.mode === 'runtime' && identity ? { Authorization: `Bearer ${identity.token}` } : {}),
      },
      ...(body === undefined ? {} : { body: JSON.stringify(body) }),
    })
  } catch {
    clearTimeout(timeout)
    report.networkErrors.push({ step, kind: 'request_failed' })
    const error = new Error('network_request_failed')
    error.step = step
    throw error
  }

  let payload
  try {
    payload = await response.json()
  } catch {
    const error = new Error('invalid_json_response')
    error.step = step
    throw error
  } finally {
    clearTimeout(timeout)
  }
  return { status: response.status, payload }
}

function roleFromScenario(scenario) {
  return scenarioDefinitions[scenario]?.writerRole
}

function dateOffset(date, days) {
  const value = new Date(date)
  value.setUTCDate(value.getUTCDate() + days)
  return value.toISOString().slice(0, 10)
}

export async function runAnnouncementScenario({ config, fetchImpl, now = new Date() }) {
  const report = createReport(config.mode, config.scenario, config.runId)
  const writerRole = roleFromScenario(config.scenario)
  if (!writerRole || typeof fetchImpl !== 'function') {
    report.status = 'BLOCKED'
    report.blockedReasons = ['scenario_or_transport_not_supported']
    return report
  }

  const identities = {}
  let createdRecord
  let adminIdentity

  const fail = (step, code) => {
    if (!report.assertions.some((item) => item.name === step && item.status === 'FAIL')) {
      report.assertions.push({ name: step, status: 'FAIL', code })
    }
  }

  const login = async (role) => {
    if (config.mode === 'mock') {
      assertStep(report, `${role}.mock_identity`, true)
      return { role }
    }
    const credentials = config.credentials[role]
    const result = await request(config, fetchImpl, report, `${role}.login`, 'login', {
      method: 'POST',
      body: { email: credentials.email, password: credentials.password },
    })
    assertStep(report, `${role}.login`, result.status === 200 && result.payload?.data?.role === role)
    assertStep(report, `${role}.token_received`, typeof result.payload?.data?.token === 'string')
    return { role, token: result.payload.data.token }
  }

  try {
    adminIdentity = await login('admin')
    identities.kaprodi = await login('kaprodi')
    identities.mahasiswa = await login('mahasiswa')
    const writerIdentity = writerRole === 'admin' ? adminIdentity : identities[writerRole]
    const title = `E2E-${config.runId}`
    const created = await request(config, fetchImpl, report, 'writer.create_announcement', 'admin/announcements', {
      method: 'POST',
      identity: writerIdentity,
      body: {
        title,
        category: 'Akademik',
        content: `Test run ${config.runId}`,
        start_date: dateOffset(now, -1),
        end_date: dateOffset(now, 7),
        status: 'Aktif',
      },
    })
    const returnedRecord = created.payload?.data
    const recordIsOurs = created.status === 201 &&
      Number.isInteger(returnedRecord?.id) &&
      returnedRecord.id > 0 &&
      returnedRecord.title === title
    if (!recordIsOurs) {
      report.cleanupStatus = 'MANUAL_REVIEW_REQUIRED'
      assertStep(report, 'writer.create_announcement', false)
    }
    assertStep(report, 'writer.create_announcement', true)
    createdRecord = { id: returnedRecord.id, title }
    report.cleanupStatus = 'PENDING'

    for (const role of ['admin', 'kaprodi', 'mahasiswa']) {
      const identity = role === 'admin' ? adminIdentity : identities[role]
      const result = await request(config, fetchImpl, report, `${role}.readback`, 'admin/announcements/list', { identity })
      const records = result.payload?.data
      assertStep(
        report,
        `${role}.readback`,
        result.status === 200 &&
          Array.isArray(records) &&
          records.some((item) => item.id === createdRecord.id && item.title === createdRecord.title),
      )
    }
  } catch (error) {
    if (error.step === 'writer.create_announcement' && !createdRecord) {
      report.cleanupStatus = 'MANUAL_REVIEW_REQUIRED'
    }
    fail(error.step || 'scenario.execution', error.message || 'scenario_failed')
  } finally {
    if (createdRecord && adminIdentity) {
      try {
        const deleted = await request(
          config,
          fetchImpl,
          report,
          'cleanup.delete_runner_record',
          `admin/announcements/delete?id=${encodeURIComponent(createdRecord.id)}`,
          { method: 'DELETE', identity: adminIdentity },
        )
        const deletedSuccessfully = deleted.status === 200
        assertStep(report, 'cleanup.delete_runner_record', deletedSuccessfully)
        if (deletedSuccessfully) {
          const readback = await request(config, fetchImpl, report, 'cleanup.verify_absent', 'admin/announcements/list', {
            identity: adminIdentity,
          })
          const records = readback.payload?.data
          const absent = readback.status === 200 &&
            Array.isArray(records) &&
            !records.some((item) => item.id === createdRecord.id)
          assertStep(report, 'cleanup.verify_absent', absent)
          report.cleanupStatus = absent ? 'PASS' : 'FAIL'
        } else {
          report.cleanupStatus = 'MANUAL_REVIEW_REQUIRED'
        }
      } catch (error) {
        fail(error.step || 'cleanup.execution', error.message || 'cleanup_failed')
        report.cleanupStatus = 'MANUAL_REVIEW_REQUIRED'
      }
    }
  }

  report.status = report.assertions.some((item) => item.status === 'FAIL') ? 'FAIL' : 'PASS'
  return report
}

export async function execute({ mode, scenario, env = {}, approval, fetchImpl, now = new Date() }) {
  if (mode === 'mock') {
    if (!scenarioDefinitions[scenario]) {
      return {
        ...createReport('mock', scenario, env.EDUTRACK_E2E_RUN_ID || 'mock-run'),
        status: 'BLOCKED',
        blockedReasons: ['scenario_not_supported'],
      }
    }
    if (typeof fetchImpl !== 'function') throw new TypeError('Mock transport is required in mock mode.')
    const mockConfig = {
      mode: 'mock',
      scenario,
      baseUrl: 'mock://edutrack.invalid/api/v1',
      timeoutMs: 1000,
      runId: validRunId(env.EDUTRACK_E2E_RUN_ID) ? env.EDUTRACK_E2E_RUN_ID : 'mock-run-001',
      credentials: {},
    }
    return runAnnouncementScenario({ config: mockConfig, fetchImpl, now })
  }

  if (mode !== 'runtime') {
    return {
      ...createReport(mode, scenario, env.EDUTRACK_E2E_RUN_ID || 'unassigned'),
      status: 'BLOCKED',
      blockedReasons: ['mode_must_be_explicit_mock_or_runtime'],
    }
  }

  try {
    const config = validateRuntimeConfig({ env, approval, scenario, now })
    return await runAnnouncementScenario({ config, fetchImpl, now })
  } catch (error) {
    if (!(error instanceof PreconditionError)) {
      return {
        ...createReport('runtime', scenario, env.EDUTRACK_E2E_RUN_ID || 'unassigned'),
        status: 'FAIL',
        blockedReasons: ['runner_initialization_failed'],
      }
    }
    return {
      ...createReport('runtime', scenario, env.EDUTRACK_E2E_RUN_ID || 'unassigned'),
      status: 'BLOCKED',
      blockedReasons: error.reasons,
    }
  }
}

function parseArguments(args) {
  const options = { mode: 'mock', scenario: scenarioIds.admin }
  for (let index = 0; index < args.length; index += 1) {
    if (args[index] === '--mode') options.mode = args[index + 1]
    if (args[index] === '--scenario') options.scenario = args[index + 1]
  }
  return options
}

async function main() {
  const options = parseArguments(process.argv.slice(2))
  let report
  if (options.mode === 'mock') {
    const { createMockTransport } = await import('./mockTransport.mjs')
    const transport = createMockTransport()
    report = await execute({ ...options, env: process.env, fetchImpl: transport.fetch })
  } else if (options.mode === 'runtime') {
    const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..')
    try {
      const approval = await readApprovalManifest(process.env, repoRoot)
      report = await execute({ ...options, env: process.env, approval, fetchImpl: globalThis.fetch })
    } catch (error) {
      report = {
        ...createReport('runtime', options.scenario, process.env.EDUTRACK_E2E_RUN_ID || 'unassigned'),
        status: 'BLOCKED',
        blockedReasons: error instanceof PreconditionError ? error.reasons : ['runner_initialization_failed'],
      }
    }
  } else {
    report = {
      ...createReport(options.mode, options.scenario, process.env.EDUTRACK_E2E_RUN_ID || 'unassigned'),
      status: 'BLOCKED',
      blockedReasons: ['mode_must_be_explicit_mock_or_runtime'],
    }
  }

  process.stdout.write(`${JSON.stringify(report, null, 2)}\n`)
  process.exitCode = report.status === 'PASS' ? 0 : report.status === 'BLOCKED' ? 2 : 1
}

if (process.argv[1] && import.meta.url === pathToFileURL(path.resolve(process.argv[1])).href) {
  await main()
}
