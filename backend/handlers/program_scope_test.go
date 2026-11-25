package handlers_test

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strconv"
	"strings"
	"testing"

	"github.com/raihanmuzaffar/edu-track-campus/backend/handlers"
	"github.com/raihanmuzaffar/edu-track-campus/backend/models"
)

func TestKaprodiCaseScopeAndDirectIDAccess(t *testing.T) {
	tx := testDB.Begin()
	if tx.Error != nil {
		t.Fatal(tx.Error)
	}
	defer tx.Rollback()

	kaprodi := models.User{
		Name: "Kaprodi Scope Test", Email: "kaprodi-scope@example.test",
		Role: "kaprodi", ProgramStudi: "TRKJ",
	}
	ownStudent := models.User{
		Name: "Mahasiswa Scope Test", Email: "student-own@example.test",
		Role: "mahasiswa", ProgramStudi: "TRKJ",
	}
	otherStudent := models.User{
		Name: "Mahasiswa Other Test", Email: "student-other@example.test",
		Role: "mahasiswa", ProgramStudi: "TI",
	}
	for _, user := range []*models.User{&kaprodi, &ownStudent, &otherStudent} {
		if err := tx.Create(user).Error; err != nil {
			t.Fatal(err)
		}
	}

	ownCase := models.Case{
		StudentID: ownStudent.ID, Level: "Ringan", Reason: "own-program",
		Followup: "Pantau", Status: "Draf",
	}
	otherCase := models.Case{
		StudentID: otherStudent.ID, Level: "Ringan", Reason: "other-program",
		Followup: "Pantau", Status: "Draf",
	}
	for _, record := range []*models.Case{&ownCase, &otherCase} {
		if err := tx.Create(record).Error; err != nil {
			t.Fatal(err)
		}
	}

	handler := &handlers.CaseHandler{DB: tx}
	listRequest := withRole(withUserID(newRequest(http.MethodGet, "/admin/cases/list", nil), kaprodi.ID), "kaprodi")
	listResponse := httptest.NewRecorder()
	handler.GetAllCases(listResponse, listRequest)
	if listResponse.Code != http.StatusOK {
		t.Fatalf("GetAllCases status = %d, want %d", listResponse.Code, http.StatusOK)
	}
	var listPayload map[string]interface{}
	if err := json.Unmarshal(listResponse.Body.Bytes(), &listPayload); err != nil {
		t.Fatal(err)
	}
	data, ok := listPayload["data"].([]interface{})
	if !ok || len(data) != 1 || !strings.Contains(listResponse.Body.String(), "own-program") {
		t.Fatalf("scoped case list did not contain only the assigned-program record: %s", listResponse.Body.String())
	}
	if strings.Contains(listResponse.Body.String(), "other-program") {
		t.Fatalf("scoped case list exposed another program's record: %s", listResponse.Body.String())
	}

	createRequest := withRole(withUserID(
		newRequest(http.MethodPost, "/admin/cases", map[string]interface{}{
			"student_id": ownStudent.ID, "level": "Ringan", "reason": "new-own",
			"followup": "Pantau", "status": "Draf",
		}),
		kaprodi.ID,
	), "kaprodi")
	createResponse := httptest.NewRecorder()
	handler.CreateCase(createResponse, createRequest)
	if createResponse.Code != http.StatusCreated {
		t.Fatalf("CreateCase for assigned student status = %d, want %d: %s",
			createResponse.Code, http.StatusCreated, createResponse.Body.String())
	}

	crossProgramCreate := withRole(withUserID(
		newRequest(http.MethodPost, "/admin/cases", map[string]interface{}{
			"student_id": otherStudent.ID, "level": "Ringan", "reason": "blocked",
			"followup": "Pantau", "status": "Draf",
		}),
		kaprodi.ID,
	), "kaprodi")
	crossProgramCreateResponse := httptest.NewRecorder()
	handler.CreateCase(crossProgramCreateResponse, crossProgramCreate)
	if crossProgramCreateResponse.Code != http.StatusForbidden {
		t.Fatalf("CreateCase for another program status = %d, want %d",
			crossProgramCreateResponse.Code, http.StatusForbidden)
	}

	updateRequest := withRole(withUserID(
		newRequest(http.MethodPut, "/admin/cases/update?id="+strconv.FormatUint(uint64(otherCase.ID), 10), map[string]interface{}{
			"student_id": ownStudent.ID, "level": "Ringan", "reason": "attempted-update",
			"followup": "Pantau", "status": "Draf",
		}),
		kaprodi.ID,
	), "kaprodi")
	updateResponse := httptest.NewRecorder()
	handler.UpdateCase(updateResponse, updateRequest)
	if updateResponse.Code != http.StatusNotFound {
		t.Fatalf("UpdateCase by an out-of-scope ID status = %d, want %d",
			updateResponse.Code, http.StatusNotFound)
	}

	deleteRequest := withRole(withUserID(
		newRequest(http.MethodDelete, "/admin/cases/delete?id="+strconv.FormatUint(uint64(otherCase.ID), 10), nil),
		kaprodi.ID,
	), "kaprodi")
	deleteResponse := httptest.NewRecorder()
	handler.DeleteCase(deleteResponse, deleteRequest)
	if deleteResponse.Code != http.StatusNotFound {
		t.Fatalf("DeleteCase by an out-of-scope ID status = %d, want %d",
			deleteResponse.Code, http.StatusNotFound)
	}
	var remaining int64
	if err := tx.Model(&models.Case{}).Where("id = ?", otherCase.ID).Count(&remaining).Error; err != nil {
		t.Fatal(err)
	}
	if remaining != 1 {
		t.Fatal("out-of-scope direct-ID operation changed the other program's case")
	}
}

func TestKaprodiWithoutProgramAssignmentFailsClosed(t *testing.T) {
	tx := testDB.Begin()
	if tx.Error != nil {
		t.Fatal(tx.Error)
	}
	defer tx.Rollback()

	kaprodi := models.User{
		Name: "Kaprodi Unassigned Test", Email: "kaprodi-unassigned@example.test",
		Role: "kaprodi",
	}
	student := models.User{
		Name: "Non Kaprodi Scope Test", Email: "non-kaprodi-scope@example.test",
		Role: "mahasiswa", ProgramStudi: "TRKJ",
	}
	for _, user := range []*models.User{&kaprodi, &student} {
		if err := tx.Create(user).Error; err != nil {
			t.Fatal(err)
		}
	}

	handler := &handlers.CaseHandler{DB: tx}
	request := withRole(withUserID(newRequest(http.MethodGet, "/admin/cases/list", nil), kaprodi.ID), "kaprodi")
	response := httptest.NewRecorder()
	handler.GetAllCases(response, request)
	if response.Code != http.StatusForbidden {
		t.Fatalf("GetAllCases without a program assignment status = %d, want %d",
			response.Code, http.StatusForbidden)
	}

	mismatchedIdentity := withRole(
		withUserID(newRequest(http.MethodGet, "/admin/cases/list", nil), student.ID),
		"kaprodi",
	)
	mismatchedResponse := httptest.NewRecorder()
	handler.GetAllCases(mismatchedResponse, mismatchedIdentity)
	if mismatchedResponse.Code != http.StatusForbidden {
		t.Fatalf("GetAllCases with an identity not assigned as Kaprodi status = %d, want %d",
			mismatchedResponse.Code, http.StatusForbidden)
	}
}

func TestKaprodiDocumentScopeAndDirectIDAccess(t *testing.T) {
	tx := testDB.Begin()
	if tx.Error != nil {
		t.Fatal(tx.Error)
	}
	defer tx.Rollback()

	// Hapus kaprodi lama agar ID tidak bertabrakan dengan test sebelumnya
	tx.Unscoped().Delete(&models.User{}, "role = ?", "kaprodi")

	kaprodi := models.User{
		Name: "Kaprodi Doc Test", Email: "kaprodi-doc@example.test",
		Role: "kaprodi", ProgramStudi: "TRKJ",
	}
	ownStudent := models.User{
		Name: "Student Doc Own", Email: "student-doc-own@example.test",
		Role: "mahasiswa", ProgramStudi: "TRKJ",
	}
	otherStudent := models.User{
		Name: "Student Doc Other", Email: "student-doc-other@example.test",
		Role: "mahasiswa", ProgramStudi: "TI",
	}
	if err := tx.Create(&kaprodi).Error; err != nil {
		t.Fatal(err)
	}
	if err := tx.Create(&ownStudent).Error; err != nil {
		t.Fatal(err)
	}
	if err := tx.Create(&otherStudent).Error; err != nil {
		t.Fatal(err)
	}

	ownDoc := models.Document{
		StudentID: ownStudent.ID,
		Type:      "Surat Keterangan",
		Semester:  "2025/2026",
		Status:    "Draf",
	}
	otherDoc := models.Document{
		StudentID: otherStudent.ID,
		Type:      "Surat Keterangan",
		Semester:  "2025/2026",
		Status:    "Draf",
	}
	if err := tx.Create(&ownDoc).Error; err != nil {
		t.Fatal(err)
	}
	if err := tx.Create(&otherDoc).Error; err != nil {
		t.Fatal(err)
	}

	handler := &handlers.DocumentHandler{DB: tx}

	inScopeReq := withRole(withUserID(newRequest(http.MethodDelete, "/admin/documents/delete?id="+strconv.FormatUint(uint64(ownDoc.ID), 10), nil), kaprodi.ID), "kaprodi")
	inScopeResp := httptest.NewRecorder()
	handler.DeleteDocument(inScopeResp, inScopeReq)
	if inScopeResp.Code != http.StatusOK {
		t.Fatalf("Delete in-scope doc status = %d, want %d", inScopeResp.Code, http.StatusOK)
	}
	var cnt int64
	if err := tx.Model(&models.Document{}).Where("id = ?", ownDoc.ID).Count(&cnt).Error; err != nil {
		t.Fatal(err)
	}
	if cnt != 0 {
		t.Fatalf("expected deleted doc count 0, got %d", cnt)
	}

	outReq := withRole(withUserID(newRequest(http.MethodDelete, "/admin/documents/delete?id="+strconv.FormatUint(uint64(otherDoc.ID), 10), nil), kaprodi.ID), "kaprodi")
	outResp := httptest.NewRecorder()
	handler.DeleteDocument(outResp, outReq)
	if outResp.Code != http.StatusNotFound {
		t.Fatalf("Delete out-of-scope doc status = %d, want %d", outResp.Code, http.StatusNotFound)
	}
	if err := tx.Model(&models.Document{}).Where("id = ?", otherDoc.ID).Count(&cnt).Error; err != nil {
		t.Fatal(err)
	}
	if cnt != 1 {
		t.Fatalf("expected other doc still exists, count %d", cnt)
	}
}

func TestKaprodiUKTScopeAndDirectIDAccess(t *testing.T) {
	tx := testDB.Begin()
	if tx.Error != nil {
		t.Fatal(tx.Error)
	}
	defer tx.Rollback()

	// Hapus kaprodi lama agar ID tidak bertabrakan dengan test sebelumnya
	tx.Unscoped().Delete(&models.User{}, "role = ?", "kaprodi")

	kaprodi := models.User{
		Name: "Kaprodi UKT Test", Email: "kaprodi-ukt@example.test",
		Role: "kaprodi", ProgramStudi: "TRKJ",
	}
	ownStudent := models.User{
		Name: "Student UKT Own", Email: "student-ukt-own@example.test",
		Role: "mahasiswa", ProgramStudi: "TRKJ",
	}
	otherStudent := models.User{
		Name: "Student UKT Other", Email: "student-ukt-other@example.test",
		Role: "mahasiswa", ProgramStudi: "TI",
	}
	if err := tx.Create(&kaprodi).Error; err != nil {
		t.Fatal(err)
	}
	if err := tx.Create(&ownStudent).Error; err != nil {
		t.Fatal(err)
	}
	if err := tx.Create(&otherStudent).Error; err != nil {
		t.Fatal(err)
	}

	ownUKT := models.UKT{
		StudentID: ownStudent.ID,
		Semester:  "2025/2026",
		Billed:    1000000,
		Paid:      1000000,
	}
	otherUKT := models.UKT{
		StudentID: otherStudent.ID,
		Semester:  "2025/2026",
		Billed:    2000000,
		Paid:      1000000,
	}
	if err := tx.Create(&ownUKT).Error; err != nil {
		t.Fatal(err)
	}
	if err := tx.Create(&otherUKT).Error; err != nil {
		t.Fatal(err)
	}

	handler := &handlers.UKTHandler{DB: tx}

	inScopeReq := withRole(withUserID(newRequest(http.MethodDelete, "/admin/ukt/delete?id="+strconv.FormatUint(uint64(ownUKT.ID), 10), nil), kaprodi.ID), "kaprodi")
	inScopeResp := httptest.NewRecorder()
	handler.DeleteUKT(inScopeResp, inScopeReq)
	if inScopeResp.Code != http.StatusOK {
		t.Fatalf("Delete in-scope UKT status = %d, want %d", inScopeResp.Code, http.StatusOK)
	}
	var cnt int64
	if err := tx.Model(&models.UKT{}).Where("id = ?", ownUKT.ID).Count(&cnt).Error; err != nil {
		t.Fatal(err)
	}
	if cnt != 0 {
		t.Fatalf("expected deleted UKT count 0, got %d", cnt)
	}

	outReq := withRole(withUserID(newRequest(http.MethodDelete, "/admin/ukt/delete?id="+strconv.FormatUint(uint64(otherUKT.ID), 10), nil), kaprodi.ID), "kaprodi")
	outResp := httptest.NewRecorder()
	handler.DeleteUKT(outResp, outReq)
	if outResp.Code != http.StatusNotFound {
		t.Fatalf("Delete out-of-scope UKT status = %d, want %d", outResp.Code, http.StatusNotFound)
	}
	if err := tx.Model(&models.UKT{}).Where("id = ?", otherUKT.ID).Count(&cnt).Error; err != nil {
		t.Fatal(err)
	}
	if cnt != 1 {
		t.Fatalf("expected other UKT still exists, count %d", cnt)
	}
}
