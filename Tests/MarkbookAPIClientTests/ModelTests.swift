// ModelTests.swift
// MarkbookAPITests

import Testing
@testable import MarkbookAPI

// MARK: - Helpers

private let decoder = JSONDecoder()

private func decode<T: Decodable>(_ type: T.Type, from fixture: String) throws -> T {
    try decoder.decode(type, from: Fixtures.data(for: fixture))
}

// MARK: - APIStatus

@Suite("APIStatus Decoding")
struct APIStatusTests {

    @Test("OKAY decodes to .okay")
    func okay() throws {
        let status = try decoder.decode(APIStatus.self, from: Data("\"OKAY\"".utf8))
        #expect(status == .okay)
    }

    @Test("ERROR:pending decodes to .errorPending")
    func errorPending() throws {
        let status = try decoder.decode(APIStatus.self, from: Data("\"ERROR:pending\"".utf8))
        #expect(status == .errorPending)
    }

    @Test("ERROR:no backup decodes to .errorNoBackup")
    func errorNoBackup() throws {
        let status = try decoder.decode(APIStatus.self, from: Data("\"ERROR:no backup\"".utf8))
        #expect(status == .errorNoBackup)
    }

    @Test("Unknown error string decodes to generic .error case")
    func unknownError() throws {
        let status = try decoder.decode(APIStatus.self, from: Data("\"ERROR:invalid student\"".utf8))
        #expect(status == .error("ERROR:invalid student"))
    }

    @Test("isOkay is true only for .okay")
    func isOkay() {
        #expect(APIStatus.okay.isOkay)
        #expect(!APIStatus.errorPending.isOkay)
        #expect(!APIStatus.errorNoBackup.isOkay)
        #expect(!APIStatus.error("anything").isOkay)
    }
}

// MARK: - AuthenticationResponse

@Suite("AuthenticationResponse Decoding")
struct AuthenticationResponseTests {

    @Test("Successful response decodes all fields correctly")
    func successfulResponse() throws {
        let response = try decode(AuthenticationResponse.self, from: Fixtures.authenticationSuccess)
        #expect(response.sessionToken == "AbCdeFgHiJkLmOp")
        #expect(response.sessionKey == 987654)
        #expect(response.schoolName == "Test School")
        #expect(response.action == .authentication)
        #expect(response.status == .okay)
    }

    @Test("Failed response decodes non-OKAY status")
    func failedResponse() throws {
        let response = try decode(AuthenticationResponse.self, from: Fixtures.authenticationFailure)
        #expect(response.status == .error("ERROR:invalid credentials"))
        #expect(!response.status.isOkay)
    }
}

// MARK: - MarkbookListResponse

@Suite("MarkbookListResponse Decoding")
struct MarkbookListResponseTests {

    @Test("Decodes the correct number of markbooks")
    func markbookCount() throws {
        let response = try decode(MarkbookListResponse.self, from: Fixtures.markbookList)
        #expect(response.list.count == 2)
    }

    @Test("Decodes first markbook fields correctly")
    func firstMarkbookFields() throws {
        let response = try decode(MarkbookListResponse.self, from: Fixtures.markbookList)
        let first = try #require(response.list.first)
        #expect(first.key == 1000001)
        #expect(first.name == "Sample")
        #expect(first.year == "Year 9")
        #expect(first.course == "Science")
    }

    @Test("Decodes second markbook owner field")
    func secondMarkbookOwner() throws {
        let response = try decode(MarkbookListResponse.self, from: Fixtures.markbookList)
        #expect(response.list[1].owner == "jsmith")
    }

    @Test("Decodes empty markbook list")
    func emptyList() throws {
        let response = try decode(MarkbookListResponse.self, from: Fixtures.markbookListEmpty)
        #expect(response.list.isEmpty)
    }
}

// MARK: - UserListResponse

@Suite("UserListResponse Decoding")
struct UserListResponseTests {

    @Test("Decodes the correct number of users")
    func userCount() throws {
        let response = try decode(UserListResponse.self, from: Fixtures.userList)
        #expect(response.list.count == 2)
    }

    @Test("Decodes user fields correctly")
    func userFields() throws {
        let response = try decode(UserListResponse.self, from: Fixtures.userList)
        let first = try #require(response.list.first)
        #expect(first.key == 1)
        #expect(first.name == "John Smith")
        #expect(first.loginID == "jsmith")
        #expect(first.email == "jsmith@school.edu.au")
    }
}

// MARK: - GetMarkbookResponse

@Suite("GetMarkbookResponse Decoding")
struct GetMarkbookResponseTests {

    let response: GetMarkbookResponse

    init() throws {
        response = try decode(GetMarkbookResponse.self, from: Fixtures.getMarkbook)
    }

    @Test("Decodes markbook metadata")
    func markbookMetadata() {
        #expect(response.markbookKey == 1000001)
        #expect(response.markbookName == "Sample")
        #expect(response.markbookYear == "Year 9")
        #expect(response.markbookCourse == "Science")
        #expect(response.ownerKey == 1)
    }

    @Test("Decodes share list")
    func shareList() {
        #expect(response.shareList == [1, 2])
    }

    @Test("Decodes class list with correct fields")
    func classList() {
        #expect(response.classList.count == 2)
        let first = response.classList[0]
        #expect(first.key == 7)
        #expect(first.name == "9SCI-1")
        #expect(first.teacherName1 == "Mr Tom")
        #expect(first.teacherName2 == "Reynolds")
    }

    @Test("Decodes task list with correct fields including decimal places")
    func taskList() {
        #expect(response.taskList.count == 3)
        let task = response.taskList[2]
        #expect(task.key == 3)
        #expect(task.name == "Assignment 2")
        #expect(task.maximum == 25)
        #expect(task.decimalPlaces == 2)
    }

    @Test("Decodes student with preferred name")
    func studentWithPreferredName() throws {
        let student = try #require(response.studentList.first)
        #expect(student.key == 2)
        #expect(student.studentID == "94665837")
        #expect(student.familyName == "Alexander")
        #expect(student.givenName == "Eddie")
        #expect(student.preferredName == "Ed")
        #expect(student.classKey == 6)
    }

    @Test("Decodes student with empty preferred name")
    func studentWithEmptyPreferredName() {
        let student = response.studentList[1]
        #expect(student.preferredName == "")
    }

    @Test("Decodes student raw and rounded result arrays")
    func studentResultArrays() throws {
        let student = try #require(response.studentList.first)
        #expect(student.rawResults == ["67.500000", "18", "12.50"])
        #expect(student.roundedResults == ["68", "18", "13"])
    }

    @Test("Result array count matches task count for every student")
    func resultCountMatchesTaskCount() {
        for student in response.studentList {
            #expect(
                student.rawResults.count == response.taskList.count,
                "Student \(student.studentID): rawResults count should match taskList"
            )
            #expect(
                student.roundedResults.count == response.taskList.count,
                "Student \(student.studentID): roundedResults count should match taskList"
            )
        }
    }
}

// MARK: - GetMarkbookAltResponse

@Suite("GetMarkbookAltResponse Decoding")
struct GetMarkbookAltResponseTests {

    let response: GetMarkbookAltResponse

    init() throws {
        response = try decode(GetMarkbookAltResponse.self, from: Fixtures.getMarkbookAlt)
    }

    @Test("Decodes result list with correct count")
    func resultListCount() {
        #expect(response.resultList.count == 2)
    }

    @Test("Decodes result fields correctly")
    func resultFields() {
        let result = response.resultList[0]
        #expect(result.studentKey == 2)
        #expect(result.taskKey == 1)
        #expect(result.rawResult == "67.500000")
        #expect(result.roundedResult == "68")
    }

    @Test("Students in alt format carry no embedded result arrays")
    func studentsHaveNoResultArrays() throws {
        let student = try #require(response.studentList.first)
        #expect(student.studentID == "94665837")
    }

    @Test("Decodes empty share list")
    func emptyShareList() {
        #expect(response.shareList.isEmpty)
    }
}

// MARK: - GetOutcomesResponse

@Suite("GetOutcomesResponse Decoding")
struct GetOutcomesResponseTests {

    let response: GetOutcomesResponse

    init() throws {
        response = try decode(GetOutcomesResponse.self, from: Fixtures.getOutcomes)
    }

    @Test("Decodes outcome list with correct count")
    func outcomeListCount() {
        #expect(response.outcomeList.count == 2)
    }

    @Test("Decodes outcome fields correctly")
    func outcomeFields() {
        let outcome = response.outcomeList[0]
        #expect(outcome.key == 1)
        #expect(outcome.code == "SC1")
        #expect(outcome.name == "Periodic Table")
        #expect(outcome.taskList == [3, 7])
    }

    @Test("Decodes outcome with empty code string")
    func outcomeWithEmptyCode() {
        let outcome = response.outcomeList[1]
        #expect(outcome.code == "")
    }

    @Test("Decodes student outcome levels")
    func studentOutcomeLevels() throws {
        let student = try #require(response.studentList.first)
        #expect(student.outcomeLevels == ["Sound", "High"])
    }

    @Test("Outcome level count matches outcome list for every student")
    func outcomeLevelCountMatchesOutcomeList() {
        for student in response.studentList {
            #expect(
                student.outcomeLevels.count == response.outcomeList.count,
                "Student \(student.studentID): outcomeLevels count should match outcomeList"
            )
        }
    }
}

// MARK: - GetOutcomesAltResponse

@Suite("GetOutcomesAltResponse Decoding")
struct GetOutcomesAltResponseTests {

    @Test("Decodes level list correctly")
    func levelList() throws {
        let response = try decode(GetOutcomesAltResponse.self, from: Fixtures.getOutcomesAlt)
        #expect(response.levelList.count == 1)
        let level = response.levelList[0]
        #expect(level.studentKey == 1)
        #expect(level.outcomeKey == 1)
        #expect(level.outcomeLevel == "Sound")
    }
}

// MARK: - CreateStudentResponse

@Suite("CreateStudentResponse Decoding")
struct CreateStudentResponseTests {

    @Test("Decodes student key and OKAY status")
    func decodesStudentKey() throws {
        let response = try decode(CreateStudentResponse.self, from: Fixtures.createStudent)
        #expect(response.studentKey == 172)
        #expect(response.status == .okay)
    }
}

// MARK: - CreateClassResponse

@Suite("CreateClassResponse Decoding")
struct CreateClassResponseTests {

    @Test("Decodes class key and OKAY status")
    func decodesClassKey() throws {
        let response = try decode(CreateClassResponse.self, from: Fixtures.createClass)
        #expect(response.classKey == 3)
        #expect(response.status == .okay)
    }
}

// MARK: - GetBackupURLResponse

@Suite("GetBackupURLResponse Decoding")
struct GetBackupURLResponseTests {

    @Test("Decodes ready backup with download URL")
    func readyBackup() throws {
        let response = try decode(GetBackupURLResponse.self, from: Fixtures.getBackupURLReady)
        #expect(response.status == .okay)
        #expect(response.url == "https://smpcsonline.com.au/markbook/download/school-backup-140323-200PM.zip")
    }

    @Test("Decodes pending status with empty URL")
    func pendingStatus() throws {
        let response = try decode(GetBackupURLResponse.self, from: Fixtures.getBackupURLPending)
        #expect(response.status == .errorPending)
        #expect(response.url.isEmpty)
    }

    @Test("Decodes no-backup status with empty URL")
    func noBackupStatus() throws {
        let response = try decode(GetBackupURLResponse.self, from: Fixtures.getBackupURLNoBackup)
        #expect(response.status == .errorNoBackup)
        #expect(response.url.isEmpty)
    }
}

// MARK: - CreateMarkbookResponse

@Suite("CreateMarkbookResponse Decoding")
struct CreateMarkbookResponseTests {

    @Test("Decodes successful creation response")
    func successfulCreation() throws {
        let response = try decode(CreateMarkbookResponse.self, from: Fixtures.createMarkbook)
        #expect(response.markbookKey == 1034973)
        #expect(response.markbookName == "2024 Y9 Science")
        #expect(response.classCount == 1)
        #expect(response.studentCount == 2)
        #expect(response.shareCount == 2)
    }

    @Test("Decodes duplicate-name response with -1 suffix appended by server")
    func duplicateNameSuffix() throws {
        let response = try decode(CreateMarkbookResponse.self, from: Fixtures.createMarkbookDuplicateName)
        #expect(response.markbookName == "2024 Y9 Science-1")
        #expect(response.markbookKey == 1034974)
    }
}

// MARK: - CreateMarkbookRequest Encoding

@Suite("CreateMarkbookRequest Encoding")
struct CreateMarkbookRequestEncodingTests {

    let encoded: [String: Any]

    init() throws {
        let request = CreateMarkbookRequest(
            api: "https://smpcsonline.com.au/markbook/api/v1.5",
            schoolName: "Test School",
            action: .createMarkbook,
            markbookName: "2024 Y9 Science",
            markbookYear: "Year 9",
            markbookCourse: "Science",
            ownerKey: 13,
            shareList: [13, 24],
            classList: [
                NewMarkbookClass(key: 1, name: "9SCI-1", teacherName1: "Mr Tom", teacherName2: "Reynolds")
            ],
            studentList: [
                NewMarkbookStudent(
                    key: 1,
                    studentID: "9812345",
                    familyName: "Alexander",
                    givenName: "Eddie",
                    preferredName: "",
                    classKey: 1,
                    className: "9SCI-1"
                )
            ]
        )
        let data = try JSONEncoder().encode(request)
        encoded = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    @Test("Encodes markbook name with snake_case JSON key")
    func markbookName() {
        #expect(encoded["markbookname"] as? String == "2024 Y9 Science")
    }

    @Test("Encodes markbook year with snake_case JSON key")
    func markbookYear() {
        #expect(encoded["markbookyear"] as? String == "Year 9")
    }

    @Test("Encodes markbook course with snake_case JSON key")
    func markbookCourse() {
        #expect(encoded["markbookcourse"] as? String == "Science")
    }

    @Test("Encodes owner key with snake_case JSON key")
    func ownerKey() {
        #expect(encoded["ownerkey"] as? Int == 13)
    }

    @Test("Encodes share list array correctly")
    func shareList() {
        #expect(encoded["sharelist"] as? [Int] == [13, 24])
    }

    @Test("Encodes action as its raw string value")
    func actionRawValue() {
        #expect(encoded["action"] as? String == "createmarkbook")
    }

    @Test("Encodes class list with correct snake_case JSON keys")
    func classList() throws {
        let classList = try #require(encoded["classlist"] as? [[String: Any]])
        #expect(classList.count == 1)
        #expect(classList[0]["name"] as? String == "9SCI-1")
        #expect(classList[0]["teachername1"] as? String == "Mr Tom")
        #expect(classList[0]["teachername2"] as? String == "Reynolds")
    }

    @Test("Encodes student list with correct snake_case JSON keys")
    func studentList() throws {
        let studentList = try #require(encoded["studentlist"] as? [[String: Any]])
        #expect(studentList.count == 1)
        #expect(studentList[0]["studentid"] as? String == "9812345")
        #expect(studentList[0]["familyname"] as? String == "Alexander")
        #expect(studentList[0]["givename"] as? String == "Eddie")
        #expect(studentList[0]["classkey"] as? Int == 1)
    }
}

// MARK: - MarkbookAPIError

@Suite("MarkbookAPIError")
struct MarkbookAPIErrorTests {

    @Test("HTTP error description includes status code")
    func httpErrorDescription() {
        let error = MarkbookAPIError.httpError(statusCode: 404)
        #expect(error.errorDescription == "HTTP error: 404")
    }

    @Test("API error description is non-nil")
    func apiErrorDescription() {
        let error = MarkbookAPIError.apiError(.error("ERROR:bad request"))
        #expect(error.errorDescription != nil)
    }

    @Test("Invalid URL error has correct description")
    func invalidURLDescription() {
        let error = MarkbookAPIError.invalidURL
        #expect(error.errorDescription == "Could not construct a valid request URL.")
    }

    @Test("Invalid backup matching parameter has correct description")
    func invalidBackupMatchingDescription() {
        let error = MarkbookAPIError.invalidBackupMatchingParameter
        #expect(error.errorDescription == "The 'matching' parameter must be at least two characters.")
    }

    @Test("Authentication failed description contains 'Authentication failed' prefix")
    func authenticationFailedDescription() {
        let underlying = URLError(.notConnectedToInternet)
        let error = MarkbookAPIError.authenticationFailed(underlying: underlying)
        #expect(error.errorDescription?.hasPrefix("Authentication failed") == true)
    }
}