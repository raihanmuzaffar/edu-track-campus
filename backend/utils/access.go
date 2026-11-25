package utils

import "strings"

func CanManageUserRole(actorRole, targetRole string) bool {
	return actorRole == "admin" || (targetRole != "admin" && targetRole != "kaprodi")
}

func ProgramScopeMatches(actorRole, actorProgram, resourceProgram string) bool {
	if actorRole == "admin" {
		return true
	}
	if actorRole != "kaprodi" {
		return false
	}

	actorProgram = strings.TrimSpace(actorProgram)
	return actorProgram != "" && actorProgram == strings.TrimSpace(resourceProgram)
}
