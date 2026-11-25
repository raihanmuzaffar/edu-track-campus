package utils

import "testing"

func TestCanManageUserRole(t *testing.T) {
	tests := []struct {
		name      string
		actorRole string
		target    string
		want      bool
	}{
		{name: "admin may manage admin", actorRole: "admin", target: "admin", want: true},
		{name: "admin may manage kaprodi", actorRole: "admin", target: "kaprodi", want: true},
		{name: "kaprodi may manage student", actorRole: "kaprodi", target: "mahasiswa", want: true},
		{name: "kaprodi may not manage admin", actorRole: "kaprodi", target: "admin", want: false},
		{name: "kaprodi may not manage kaprodi", actorRole: "kaprodi", target: "kaprodi", want: false},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			if got := CanManageUserRole(test.actorRole, test.target); got != test.want {
				t.Fatalf("CanManageUserRole(%q, %q) = %t, want %t", test.actorRole, test.target, got, test.want)
			}
		})
	}
}

func TestProgramScopeMatches(t *testing.T) {
	tests := []struct {
		name            string
		actorRole       string
		actorProgram    string
		resourceProgram string
		want            bool
	}{
		{name: "kaprodi may access assigned program", actorRole: "kaprodi", actorProgram: "TRKJ", resourceProgram: "TRKJ", want: true},
		{name: "trimmed assignment matches", actorRole: "kaprodi", actorProgram: " TRKJ ", resourceProgram: "TRKJ", want: true},
		{name: "kaprodi cannot access another program", actorRole: "kaprodi", actorProgram: "TRKJ", resourceProgram: "TI", want: false},
		{name: "empty assignment fails closed", actorRole: "kaprodi", actorProgram: " ", resourceProgram: "TRKJ", want: false},
		{name: "empty resource program fails closed", actorRole: "kaprodi", actorProgram: "TRKJ", resourceProgram: " ", want: false},
		{name: "other roles do not inherit scope access", actorRole: "dosen", actorProgram: "TRKJ", resourceProgram: "TRKJ", want: false},
		{name: "admin access remains unchanged", actorRole: "admin", resourceProgram: "TI", want: true},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			if got := ProgramScopeMatches(test.actorRole, test.actorProgram, test.resourceProgram); got != test.want {
				t.Fatalf("ProgramScopeMatches(%q, %q, %q) = %t, want %t",
					test.actorRole, test.actorProgram, test.resourceProgram, got, test.want)
			}
		})
	}
}
