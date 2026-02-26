// MarkbookAPIClientTests.swift
// MarkbookAPITests

import Testing
import Foundation
@testable import MarkbookAPI

// MARK: - Shared Test Support

/// Helpers used across all client test suites.
private enum ClientTestSupport {

    static let apiKey = "ABCDEFGHIJKLMNOPQRSTUVWXYZABCDEF"

    /// Creates a fresh client wired to `MockURLProtocol` and resets the mock queue.
    static func makeClient() -> MarkbookAPIClient {
        MockURLProtocol.reset()
        return MarkbookAPIClient(
            apiKey: apiKey,
            username: "testadmin",
            password: "testpassword",
            urlSession: .makeMockSession()
        )
    }

    /// Enqueues an authentication success response followed by one data response.
    static func enqueueAuth(then fixture: String) {
        MockURLProtocol.enqueue(fixture: Fixtures.authenticationSuccess)
        MockURLProtocol.enqueue(fixture: fixture)
    }

    /// Returns URL query items from a captured request as a `[String: String]` dictionary.
    static func queryItems(of request: URLRequest) throws -> [String: String] {
        let url = try #require(request.url)
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        return Dictionary(
            uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name, $0.value ?? "") }
        )
    }

    /// Decodes URL-encoded form body fields from a POST request as a `[String: String]` dictionary.
    static func formFields(of request: URLRequest) throws -> [String: String] {
        let body = try #require(request.httpBody)
        let bodyString = try #require(String(data: body, encoding: .utf8))
        var components = URLComponents()
        components.query = bodyString
        return Dictionary(
            uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name, $0.value ?? "") }
        )
    }

    /// The data request (index 1) after authentication (index 0).
    static var dataRequest: URLRequest {
        get throws {
            try #require(MockURLProtocol.capturedRequests.dropFirst().first)
        }
    }
}

// MARK: - Authentication

@Suite("Authentication")
struct AuthenticationTests {

    let client = ClientTestSupport.makeClient()

    @Test("First API call triggers a POST to authenticate.lc")
    func firstCallTriggersAuthentication() async throws {
        ClientTestSupport.enqueueAuth(then: Fixtures.markbookList)
        _ = try await client.markbookList()

        let authRequest = try #require(MockURLProtocol.capturedRequests.first)
        #expect(authRequest.httpMethod == "POST")
        #expect(authRequest.url?.absoluteString.contains("authenticate.lc") == true)
    }

    @Test("Authentication POST body contains username and password")
    func authRequestCredentials() async throws {
        ClientTestSupport.enqueueAuth(then: Fixtures.markbookList)
        _ = try await client.markbookList()

        let authRequest = try #require(MockURLProtocol.capturedRequests.first)
        let fields = try ClientTestSupport.formFields(of: authRequest)
        #expect(fields["apiuser"] == "testadmin")
        #expect(fields["apipassword"] == "testpassword")
    }

    @Test("Second call within session lifetime reuses the cached session")
    func secondCallReusesSession() async throws {
        ClientTestSupport.enqueueAuth(then: Fixtures.markbookList)
        _ = try await client.markbookList()

        // Enqueue only a data response — no auth. If re-auth occurs this will fail.
        MockURLProtocol.enqueue(fixture: Fixtures.markbookList)
        _ = try await client.markbookList()

        // 1 auth + 2 data = 3 total
        #expect(MockURLProtocol.capturedRequests.count == 3)
    }

    @Test("Session credentials are injected into subsequent GET requests")
    func sessionCredentialsInjected() async throws {
        ClientTestSupport.enqueueAuth(then: Fixtures.markbookList)
        _ = try await client.markbookList()

        let dataRequest = try ClientTestSupport.dataRequest
        let params = try ClientTestSupport.queryItems(of: dataRequest)
        #expect(params["sessiontoken"] == "AbCdeFgHiJkLmOp")
        #expect(params["sessionkey"] == "987654")
        #expect(params["apikey"] == ClientTestSupport.apiKey)
    }

    @Test("Authentication failure from API throws authenticationFailed error")
    func authenticationFailure() async throws {
        MockURLProtocol.enqueue(fixture: Fixtures.authenticationFailure)

        await #expect(throws: MarkbookAPIError.self) {
            _ = try await client.markbookList()
        }
    }

    @Test("Network failure during authentication wraps error in authenticationFailed")
    func networkFailureDuringAuth() async throws {
        MockURLProtocol.enqueue { _ in throw URLError(.notConnectedToInternet) }

        let thrownError = try await #require(
            throwing: MarkbookAPIError.self,
            performing: { try await client.markbookList() }
        )
        guard case .authenticationFailed(let underlying) = thrownError else {
            Issue.record("Expected .authenticationFailed, got \(thrownError)")
            return
        }
        #expect((underlying as? URLError)?.code == .notConnectedToInternet)
    }
}

// MARK: - HTTP Error Handling

@Suite("HTTP Error Handling")
struct HTTPErrorHandlingTests {

    let client = ClientTestSupport.makeClient()

    @Test("HTTP 401 response throws httpError with correct status code")
    func http401() async throws {
        MockURLProtocol.enqueue(fixture: Fixtures.authenticationSuccess)
        MockURLProtocol.enqueue(data: Data(), statusCode: 401)

        let thrownError = try await #require(
            throwing: MarkbookAPIError.self,
            performing: { try await client.markbookList() }
        )
        guard case .httpError(let code) = thrownError else {
            Issue.record("Expected .httpError, got \(thrownError)")
            return
        }
        #expect(code == 401)
    }

    @Test("HTTP 500 response throws httpError with correct status code")
    func http500() async throws {
        MockURLProtocol.enqueue(fixture: Fixtures.authenticationSuccess)
        MockURLProtocol.enqueue(data: Data(), statusCode: 500)

        let thrownError = try await #require(
            throwing: MarkbookAPIError.self,
            performing: { try await client.markbookList() }
        )
        guard case .httpError(let code) = thrownError else {
            Issue.record("Expected .httpError, got \(thrownError)")
            return
        }
        #expect(code == 500)
    }

    @Test("Network timeout propagates as an error after successful authentication")
    func networkTimeout() async throws {
        MockURLProtocol.enqueue(fixture: Fixtures.authenticationSuccess)
        MockURLProtocol.enqueue { _ in throw URLError(.timedOut) }

        await #expect(throws: (any Error).self) {
            _ = try await client.markbookList()
        }
    }
}

// MARK: - markbookList

@Suite("markbookList()")
struct MarkbookListTests {

    let client = ClientTestSupport.makeClient()

    @Test("Returns the decoded list of markbooks")
    func returnsMarkbooks() async throws {
        ClientTestSupport.enqueueAuth(then: Fixtures.markbookList)
        let response = try await client.markbookList()

        #expect(response.status == .okay)
        #expect(response.list.count == 2)
        #expect(response.list[0].key == 1000001)
        #expect(response.list[0].name == "Sample")
        #expect(response.list[1].key == 1000002)
    }

    @Test("Sends action=markbooklist query parameter")
    func sendsCorrectAction() async throws {
        ClientTestSupport.enqueueAuth(then: Fixtures.markbookList)
        _ = try await client.markbookList()

        let params = try ClientTestSupport.queryItems(of: try ClientTestSupport.dataRequest)
        #expect(params["action"] == "markbooklist")
    }

    @Test("Uses HTTP GET method")
    func usesGetMethod() async throws {
        ClientTestSupport.enqueueAuth(then: Fixtures.markbookList)
        _ = try await client.markbookList()

        let dataRequest = try ClientTestSupport.dataRequest
        #expect((dataRequest.httpMethod ?? "GET") == "GET")
    }

    @Test("Returns successfully with an empty markbook list")
    func emptyList() async throws {
        ClientTestSupport.enqueueAuth(then: Fixtures.markbookListEmpty)
        let response = try await client.markbookList()
        #expect(response.list.isEmpty)
    }
}

// MARK: - userList

@Suite("userList()")
struct UserListTests {

    let client = ClientTestSupport.makeClient()

    @Test("Returns the decoded list of users")
    func returnsUsers() async throws {
        ClientTestSupport.enqueueAuth(then: Fixtures.userList)
        let response = try await client.userList()

        #expect(response.list.count == 2)
        #expect(response.list[0].loginID == "jsmith")
    }

    @Test("Sends action=userlist query parameter")
    func sendsCorrectAction() async throws {
        ClientTestSupport.enqueueAuth(then: Fixtures.userList)
        _ = try await client.userList()

        let params = try ClientTestSupport.queryItems(of: try ClientTestSupport.dataRequest)
        #expect(params["action"] == "userlist")
    }
}

// MARK: - getMarkbook

@Suite("getMarkbook(key:)")
struct GetMarkbookTests {

    let client = ClientTestSupport.makeClient()

    @Test("Returns the decoded markbook with students and tasks")
    func returnsMarkbook() async throws {
        ClientTestSupport.enqueueAuth(then: Fixtures.getMarkbook)
        let response = try await client.getMarkbook(key: 1000001)

        #expect(response.markbookKey == 1000001)
        #expect(response.studentList.count == 2)
        #expect(response.taskList.count == 3)
        #expect(response.classList.count == 2)
    }

    @Test("Sends action=getmarkbook and the markbook key as query parameters")
    func sendsCorrectParameters() async throws {
        ClientTestSupport.enqueueAuth(then: Fixtures.getMarkbook)
        _ = try await client.getMarkbook(key: 1000001)

        let params = try ClientTestSupport.queryItems(of: try ClientTestSupport.dataRequest)
        #expect(params["action"] == "getmarkbook")
        #expect(params["key"] == "1000001")
    }

    @Test("Result arrays align with the task list for every student")
    func resultArraysAlignWithTasks() async throws {
        ClientTestSupport.enqueueAuth(then: Fixtures.getMarkbook)
        let response = try await client.getMarkbook(key: 1000001)

        for student in response.studentList {
            #expect(student.rawResults.count == response.taskList.count)
            #expect(student.roundedResults.count == response.taskList.count)
        }
    }
}

// MARK: - getMarkbookAlt

@Suite("getMarkbookAlt(key:)")
struct GetMarkbookAltTests {

    let client = ClientTestSupport.makeClient()

    @Test("Returns flat result list with correct entries")
    func returnsResultList() async throws {
        ClientTestSupport.enqueueAuth(then: Fixtures.getMarkbookAlt)
        let response = try await client.getMarkbookAlt(key: 1000001)

        #expect(response.resultList.count == 2)
        #expect(response.resultList[0].studentKey == 2)
        #expect(response.resultList[0].taskKey == 1)
        #expect(response.resultList[0].roundedResult == "68")
    }

    @Test("Sends action=getmarkbookalt and the markbook key as query parameters")
    func sendsCorrectParameters() async throws {
        ClientTestSupport.enqueueAuth(then: Fixtures.getMarkbookAlt)
        _ = try await client.getMarkbookAlt(key: 1000001)

        let params = try ClientTestSupport.queryItems(of: try ClientTestSupport.dataRequest)
        #expect(params["action"] == "getmarkbookalt")
        #expect(params["key"] == "1000001")
    }
}

// MARK: - getOutcomes

@Suite("getOutcomes(key:)")
struct GetOutcomesTests {

    let client = ClientTestSupport.makeClient()

    @Test("Returns outcome list and student outcome levels")
    func returnsOutcomes() async throws {
        ClientTestSupport.enqueueAuth(then: Fixtures.getOutcomes)
        let response = try await client.getOutcomes(key: 1000001)

        #expect(response.outcomeList.count == 2)
        #expect(response.studentList[0].outcomeLevels == ["Sound", "High"])
    }

    @Test("Sends action=getoutcomes and the markbook key as query parameters")
    func sendsCorrectParameters() async throws {
        ClientTestSupport.enqueueAuth(then: Fixtures.getOutcomes)
        _ = try await client.getOutcomes(key: 1000001)

        let params = try ClientTestSupport.queryItems(of: try ClientTestSupport.dataRequest)
        #expect(params["action"] == "getoutcomes")
        #expect(params["key"] == "1000001")
    }
}

// MARK: - getOutcomesAlt

@Suite("getOutcomesAlt(key:)")
struct GetOutcomesAltTests {

    let client = ClientTestSupport.makeClient()

    @Test("Returns flat level list with correct entries")
    func returnsLevelList() async throws {
        ClientTestSupport.enqueueAuth(then: Fixtures.getOutcomesAlt)
        let response = try await client.getOutcomesAlt(key: 1000001)

        #expect(response.levelList.count == 1)
        #expect(response.levelList[0].outcomeLevel == "Sound")
    }

    @Test("Sends action=getoutcomesalt query parameter")
    func sendsCorrectAction() async throws {
        ClientTestSupport.enqueueAuth(then: Fixtures.getOutcomesAlt)
        _ = try await client.getOutcomesAlt(key: 1000001)

        let params = try ClientTestSupport.queryItems(of: try ClientTestSupport.dataRequest)
        #expect(params["action"] == "getoutcomesalt")
    }
}

// MARK: - putStudentResult

@Suite("putStudentResult(...)")
struct PutStudentResultTests {

    let client = ClientTestSupport.makeClient()

    @Test("Completes without throwing on OKAY response")
    func completesSuccessfully() async throws {
        ClientTestSupport.enqueueAuth(then: Fixtures.statusOkay)
        try await client.putStudentResult(
            markbookKey: 1000001, studentKey: 89, sid: "80822649",
            taskKey: 4, taskName: "Assignment 3", result: "21"
        )
    }

    @Test("Sends all required query parameters")
    func sendsAllParameters() async throws {
        ClientTestSupport.enqueueAuth(then: Fixtures.statusOkay)
        try await client.putStudentResult(
            markbookKey: 1000001, studentKey: 89, sid: "80822649",
            taskKey: 4, taskName: "Assignment 3", result: "21"
        )

        let params = try ClientTestSupport.queryItems(of: try ClientTestSupport.dataRequest)
        #expect(params["action"] == "putstudentresult")
        #expect(params["key"] == "1000001")
        #expect(params["studentkey"] == "89")
        #expect(params["sid"] == "80822649")
        #expect(params["taskkey"] == "4")
        #expect(params["taskname"] == "Assignment 3")
        #expect(params["result"] == "21")
    }

    @Test("Non-OKAY API response throws apiError")
    func apiErrorThrows() async throws {
        ClientTestSupport.enqueueAuth(then: Fixtures.statusError)

        let thrownError = try await #require(
            throwing: MarkbookAPIError.self,
            performing: {
                try await client.putStudentResult(
                    markbookKey: 1000001, studentKey: 89, sid: "80822649",
                    taskKey: 4, taskName: "Assignment 3", result: "21"
                )
            }
        )
        guard case .apiError(let status) = thrownError else {
            Issue.record("Expected .apiError, got \(thrownError)")
            return
        }
        #expect(status == .error("ERROR:invalid student"))
    }

    @Test("Task name containing special characters is sent without error")
    func specialCharactersInTaskName() async throws {
        ClientTestSupport.enqueueAuth(then: Fixtures.statusOkay)
        try await client.putStudentResult(
            markbookKey: 1000001, studentKey: 89, sid: "80822649",
            taskKey: 4, taskName: "Term 1 & 2 Exam", result: "85"
        )
        #expect(MockURLProtocol.capturedRequests.count == 2)
    }
}

// MARK: - createStudent

@Suite("createStudent(...)")
struct CreateStudentTests {

    let client = ClientTestSupport.makeClient()

    @Test("Returns the new student key on success")
    func returnsStudentKey() async throws {
        ClientTestSupport.enqueueAuth(then: Fixtures.createStudent)
        let response = try await client.createStudent(
            markbookKey: 1000001, sid: "99999", familyName: "Lee",
            givenName: "Susannah", preferredName: "Sue", gender: .female, classKey: 7
        )
        #expect(response.studentKey == 172)
    }

    @Test("Sends all required query parameters")
    func sendsAllParameters() async throws {
        ClientTestSupport.enqueueAuth(then: Fixtures.createStudent)
        _ = try await client.createStudent(
            markbookKey: 1000001, sid: "99999", familyName: "Lee",
            givenName: "Susannah", preferredName: "Sue", gender: .female, classKey: 7
        )

        let params = try ClientTestSupport.queryItems(of: try ClientTestSupport.dataRequest)
        #expect(params["action"] == "createstudent")
        #expect(params["key"] == "1000001")
        #expect(params["sid"] == "99999")
        #expect(params["family"] == "Lee")
        #expect(params["given"] == "Susannah")
        #expect(params["preferred"] == "Sue")
        #expect(params["gender"] == "female")
        #expect(params["classkey"] == "7")
    }

    @Test("Male gender encodes to 'male' string")
    func maleGenderEncoding() async throws {
        ClientTestSupport.enqueueAuth(then: Fixtures.createStudent)
        _ = try await client.createStudent(
            markbookKey: 1000001, sid: "11111", familyName: "Smith",
            givenName: "James", preferredName: "", gender: .male, classKey: 7
        )
        let params = try ClientTestSupport.queryItems(of: try ClientTestSupport.dataRequest)
        #expect(params["gender"] == "male")
    }

    @Test("Other gender encodes to 'other' string")
    func otherGenderEncoding() async throws {
        ClientTestSupport.enqueueAuth(then: Fixtures.createStudent)
        _ = try await client.createStudent(
            markbookKey: 1000001, sid: "22222", familyName: "Jones",
            givenName: "Alex", preferredName: "", gender: .other, classKey: 7
        )
        let params = try ClientTestSupport.queryItems(of: try ClientTestSupport.dataRequest)
        #expect(params["gender"] == "other")
    }

    @Test("Empty preferred name sends empty string parameter")
    func emptyPreferredName() async throws {
        ClientTestSupport.enqueueAuth(then: Fixtures.createStudent)
        _ = try await client.createStudent(
            markbookKey: 1000001, sid: "33333", familyName: "Brown",
            givenName: "Alice", preferredName: "", gender: .female, classKey: 7
        )
        let params = try ClientTestSupport.queryItems(of: try ClientTestSupport.dataRequest)
        #expect(params["preferred"] == "")
    }
}

// MARK: - updateStudent

@Suite("updateStudent(...)")
struct UpdateStudentTests {

    let client = ClientTestSupport.makeClient()

    @Test("Completes without throwing on OKAY response")
    func completesSuccessfully() async throws {
        ClientTestSupport.enqueueAuth(then: Fixtures.statusOkay)
        try await client.updateStudent(
            markbookKey: 1000001, studentKey: 170, sid: "99999",
            familyName: "Lee", givenName: "Susannah", preferredName: "Susan", gender: .female
        )
    }

    @Test("Sends all required query parameters including all name fields")
    func sendsAllParameters() async throws {
        ClientTestSupport.enqueueAuth(then: Fixtures.statusOkay)
        try await client.updateStudent(
            markbookKey: 1000001, studentKey: 170, sid: "99999",
            familyName: "Lee", givenName: "Susannah", preferredName: "Susan", gender: .female
        )

        let params = try ClientTestSupport.queryItems(of: try ClientTestSupport.dataRequest)
        #expect(params["action"] == "updatestudent")
        #expect(params["key"] == "1000001")
        #expect(params["studentkey"] == "170")
        #expect(params["sid"] == "99999")
        #expect(params["family"] == "Lee")
        #expect(params["given"] == "Susannah")
        #expect(params["preferred"] == "Susan")
        #expect(params["gender"] == "female")
    }

    @Test("Non-OKAY API response throws apiError")
    func apiErrorThrows() async throws {
        ClientTestSupport.enqueueAuth(then: Fixtures.statusError)

        await #expect(throws: MarkbookAPIError.self) {
            try await client.updateStudent(
                markbookKey: 1000001, studentKey: 170, sid: "99999",
                familyName: "Lee", givenName: "Susannah", preferredName: "Susan", gender: .female
            )
        }
    }
}

// MARK: - updateStudentClass

@Suite("updateStudentClass(...)")
struct UpdateStudentClassTests {

    let client = ClientTestSupport.makeClient()

    @Test("Completes without throwing on OKAY response")
    func completesSuccessfully() async throws {
        ClientTestSupport.enqueueAuth(then: Fixtures.statusOkay)
        try await client.updateStudentClass(
            markbookKey: 1000001, studentKey: 170, sid: "99999", classKey: 5
        )
    }

    @Test("Sends all required query parameters")
    func sendsCorrectParameters() async throws {
        ClientTestSupport.enqueueAuth(then: Fixtures.statusOkay)
        try await client.updateStudentClass(
            markbookKey: 1000001, studentKey: 170, sid: "99999", classKey: 5
        )

        let params = try ClientTestSupport.queryItems(of: try ClientTestSupport.dataRequest)
        #expect(params["action"] == "updatestudentclass")
        #expect(params["key"] == "1000001")
        #expect(params["studentkey"] == "170")
        #expect(params["sid"] == "99999")
        #expect(params["classkey"] == "5")
    }

    @Test("Non-OKAY API response throws apiError")
    func apiErrorThrows() async throws {
        ClientTestSupport.enqueueAuth(then: Fixtures.statusError)
        await #expect(throws: MarkbookAPIError.self) {
            try await client.updateStudentClass(
                markbookKey: 1000001, studentKey: 170, sid: "99999", classKey: 5
            )
        }
    }
}

// MARK: - deleteStudent

@Suite("deleteStudent(...)")
struct DeleteStudentTests {

    let client = ClientTestSupport.makeClient()

    @Test("Completes without throwing on OKAY response")
    func completesSuccessfully() async throws {
        ClientTestSupport.enqueueAuth(then: Fixtures.statusOkay)
        try await client.deleteStudent(markbookKey: 1000001, studentKey: 170, sid: "99999")
    }

    @Test("Sends all required query parameters")
    func sendsCorrectParameters() async throws {
        ClientTestSupport.enqueueAuth(then: Fixtures.statusOkay)
        try await client.deleteStudent(markbookKey: 1000001, studentKey: 170, sid: "99999")

        let params = try ClientTestSupport.queryItems(of: try ClientTestSupport.dataRequest)
        #expect(params["action"] == "deletestudent")
        #expect(params["key"] == "1000001")
        #expect(params["studentkey"] == "170")
        #expect(params["sid"] == "99999")
    }

    @Test("Non-OKAY API response throws apiError")
    func apiErrorThrows() async throws {
        ClientTestSupport.enqueueAuth(then: Fixtures.statusError)
        await #expect(throws: MarkbookAPIError.self) {
            try await client.deleteStudent(markbookKey: 1000001, studentKey: 170, sid: "99999")
        }
    }
}

// MARK: - createClass

@Suite("createClass(...)")
struct CreateClassTests {

    let client = ClientTestSupport.makeClient()

    @Test("Returns the new class key on success")
    func returnsClassKey() async throws {
        ClientTestSupport.enqueueAuth(then: Fixtures.createClass)
        let response = try await client.createClass(
            markbookKey: 1000001, name: "9ENG1",
            teacherFamilyName: "Thackeray", teacherGivenName: "Mark"
        )
        #expect(response.classKey == 3)
    }

    @Test("Sends all required query parameters")
    func sendsCorrectParameters() async throws {
        ClientTestSupport.enqueueAuth(then: Fixtures.createClass)
        _ = try await client.createClass(
            markbookKey: 1000001, name: "9ENG1",
            teacherFamilyName: "Thackeray", teacherGivenName: "Mark"
        )

        let params = try ClientTestSupport.queryItems(of: try ClientTestSupport.dataRequest)
        #expect(params["action"] == "createclass")
        #expect(params["key"] == "1000001")
        #expect(params["name"] == "9ENG1")
        #expect(params["family"] == "Thackeray")
        #expect(params["given"] == "Mark")
    }
}

// MARK: - scheduleBackup

@Suite("scheduleBackup(matching:)")
struct ScheduleBackupTests {

    let client = ClientTestSupport.makeClient()

    @Test("Completes without throwing for a valid matching string")
    func validMatchingString() async throws {
        ClientTestSupport.enqueueAuth(then: Fixtures.statusOkay)
        try await client.scheduleBackup(matching: "2024")
    }

    @Test("Minimum two-character matching string is accepted")
    func twoCharacterMinimum() async throws {
        ClientTestSupport.enqueueAuth(then: Fixtures.statusOkay)
        try await client.scheduleBackup(matching: "24")
    }

    @Test("Sends action=schedulebackup and matching query parameters")
    func sendsCorrectParameters() async throws {
        ClientTestSupport.enqueueAuth(then: Fixtures.statusOkay)
        try await client.scheduleBackup(matching: "2024")

        let params = try ClientTestSupport.queryItems(of: try ClientTestSupport.dataRequest)
        #expect(params["action"] == "schedulebackup")
        #expect(params["matching"] == "2024")
    }

    @Test("One-character matching string throws invalidBackupMatchingParameter")
    func oneCharacterThrows() async throws {
        let thrownError = try await #require(
            throwing: MarkbookAPIError.self,
            performing: { try await client.scheduleBackup(matching: "x") }
        )
        guard case .invalidBackupMatchingParameter = thrownError else {
            Issue.record("Expected .invalidBackupMatchingParameter, got \(thrownError)")
            return
        }
    }

    @Test("Empty matching string throws invalidBackupMatchingParameter")
    func emptyStringThrows() async throws {
        await #expect(throws: MarkbookAPIError.self) {
            try await client.scheduleBackup(matching: "")
        }
    }

    @Test("Validation error fires before any network request is made")
    func validationFiringBeforeNetwork() async throws {
        do {
            try await client.scheduleBackup(matching: "x")
        } catch MarkbookAPIError.invalidBackupMatchingParameter {
            #expect(MockURLProtocol.capturedRequests.isEmpty)
        }
    }

    @Test("Non-OKAY API response throws apiError")
    func apiErrorThrows() async throws {
        ClientTestSupport.enqueueAuth(then: Fixtures.statusError)
        await #expect(throws: MarkbookAPIError.self) {
            try await client.scheduleBackup(matching: "2024")
        }
    }
}

// MARK: - getBackupURL

@Suite("getBackupURL()")
struct GetBackupURLTests {

    let client = ClientTestSupport.makeClient()

    @Test("Returns the backup URL when the backup is ready")
    func returnsURLWhenReady() async throws {
        ClientTestSupport.enqueueAuth(then: Fixtures.getBackupURLReady)
        let response = try await client.getBackupURL()

        #expect(response.status == .okay)
        #expect(!response.url.isEmpty)
    }

    @Test("Sends action=getbackupurl query parameter")
    func sendsCorrectAction() async throws {
        ClientTestSupport.enqueueAuth(then: Fixtures.getBackupURLReady)
        _ = try await client.getBackupURL()

        let params = try ClientTestSupport.queryItems(of: try ClientTestSupport.dataRequest)
        #expect(params["action"] == "getbackupurl")
    }

    @Test("Pending backup surfaces as apiError with errorPending status")
    func pendingBackupThrowsApiError() async throws {
        ClientTestSupport.enqueueAuth(then: Fixtures.getBackupURLPending)

        let thrownError = try await #require(
            throwing: MarkbookAPIError.self,
            performing: { try await client.getBackupURL() }
        )
        guard case .apiError(let status) = thrownError else {
            Issue.record("Expected .apiError, got \(thrownError)")
            return
        }
        #expect(status == .errorPending)
    }

    @Test("No-backup state surfaces as apiError with errorNoBackup status")
    func noBackupThrowsApiError() async throws {
        ClientTestSupport.enqueueAuth(then: Fixtures.getBackupURLNoBackup)

        let thrownError = try await #require(
            throwing: MarkbookAPIError.self,
            performing: { try await client.getBackupURL() }
        )
        guard case .apiError(let status) = thrownError else {
            Issue.record("Expected .apiError, got \(thrownError)")
            return
        }
        #expect(status == .errorNoBackup)
    }
}

// MARK: - createMarkbook

@Suite("createMarkbook(_:)")
struct CreateMarkbookTests {

    let client = ClientTestSupport.makeClient()

    private func makeRequest() -> CreateMarkbookRequest {
        CreateMarkbookRequest(
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
                NewMarkbookStudent(key: 1, studentID: "9812345", familyName: "Alexander",
                                   givenName: "Eddie", preferredName: "", classKey: 1, className: "9SCI-1"),
                NewMarkbookStudent(key: 2, studentID: "9854321", familyName: "Ameche",
                                   givenName: "Joan", preferredName: "", classKey: 1, className: "9SCI-1")
            ]
        )
    }

    @Test("Returns the new markbook key and counts on success")
    func returnsMarkbookKey() async throws {
        ClientTestSupport.enqueueAuth(then: Fixtures.createMarkbook)
        let response = try await client.createMarkbook(makeRequest())

        #expect(response.markbookKey == 1034973)
        #expect(response.markbookName == "2024 Y9 Science")
        #expect(response.classCount == 1)
        #expect(response.studentCount == 2)
        #expect(response.shareCount == 2)
    }

    @Test("Uses HTTP POST method")
    func usesPostMethod() async throws {
        ClientTestSupport.enqueueAuth(then: Fixtures.createMarkbook)
        _ = try await client.createMarkbook(makeRequest())

        let postRequest = try ClientTestSupport.dataRequest
        #expect(postRequest.httpMethod == "POST")
    }

    @Test("Posts to the post.lc endpoint")
    func postsToCorrectEndpoint() async throws {
        ClientTestSupport.enqueueAuth(then: Fixtures.createMarkbook)
        _ = try await client.createMarkbook(makeRequest())

        let postRequest = try ClientTestSupport.dataRequest
        #expect(postRequest.url?.absoluteString.contains("post.lc") == true)
    }

    @Test("Form body contains apiaction, apikey, sessiontoken, and jsondata fields")
    func formBodyContainsRequiredFields() async throws {
        ClientTestSupport.enqueueAuth(then: Fixtures.createMarkbook)
        _ = try await client.createMarkbook(makeRequest())

        let postRequest = try ClientTestSupport.dataRequest
        let fields = try ClientTestSupport.formFields(of: postRequest)
        #expect(fields["apiaction"] == "createmarkbook")
        #expect(fields["apikey"] == ClientTestSupport.apiKey)
        #expect(fields["sessiontoken"] == "AbCdeFgHiJkLmOp")
        #expect(fields["jsondata"] != nil)
    }

    @Test("JSON payload contains the markbook name")
    func jsonPayloadContainsMarkbookName() async throws {
        ClientTestSupport.enqueueAuth(then: Fixtures.createMarkbook)
        _ = try await client.createMarkbook(makeRequest())

        let postRequest = try ClientTestSupport.dataRequest
        let fields = try ClientTestSupport.formFields(of: postRequest)
        let jsonData = try #require(fields["jsondata"])
        #expect(jsonData.contains("2024 Y9 Science"))
    }

    @Test("Content-Type header is application/x-www-form-urlencoded")
    func contentTypeHeader() async throws {
        ClientTestSupport.enqueueAuth(then: Fixtures.createMarkbook)
        _ = try await client.createMarkbook(makeRequest())

        let postRequest = try ClientTestSupport.dataRequest
        #expect(postRequest.value(forHTTPHeaderField: "Content-Type") == "application/x-www-form-urlencoded")
    }

    @Test("Duplicate name response returns server-suffixed markbook name")
    func duplicateNameReturnsSuffix() async throws {
        ClientTestSupport.enqueueAuth(then: Fixtures.createMarkbookDuplicateName)
        let response = try await client.createMarkbook(makeRequest())
        #expect(response.markbookName == "2024 Y9 Science-1")
    }
}

// MARK: - Concurrent Requests

@Suite("Concurrent Requests")
struct ConcurrentRequestTests {

    let client = ClientTestSupport.makeClient()

    @Test("Simultaneous calls share a single authentication request")
    func concurrentCallsAuthenticateOnce() async throws {
        // Enqueue one auth and two data responses.
        // If the actor re-authenticates, a data response would be consumed by auth
        // and the second API call would fail.
        MockURLProtocol.enqueue(fixture: Fixtures.authenticationSuccess)
        MockURLProtocol.enqueue(fixture: Fixtures.markbookList)
        MockURLProtocol.enqueue(fixture: Fixtures.userList)

        async let markbooks = client.markbookList()
        async let users = client.userList()

        let (markbookResponse, userResponse) = try await (markbooks, users)

        #expect(markbookResponse.list.count == 2)
        #expect(userResponse.list.count == 2)
        // 1 auth + 2 data = 3 total requests
        #expect(MockURLProtocol.capturedRequests.count == 3)
    }
}

// MARK: - #require(throwing:performing:) Helper

/// Swift Testing does not ship a built-in `#require(throws:)` variant that returns
/// the thrown error for further inspection. This helper fills that gap cleanly.
private func require<E: Error, R>(
    throwing errorType: E.Type,
    performing body: () async throws -> R,
    sourceLocation: SourceLocation = #_sourceLocation
) async throws -> E {
    do {
        _ = try await body()
        Issue.record("Expected an error of type \(E.self) to be thrown but nothing was thrown.",
                     sourceLocation: sourceLocation)
        throw TestSupportError.expectedThrow
    } catch let error as E {
        return error
    } catch {
        Issue.record("Expected error of type \(E.self) but got \(type(of: error)): \(error)",
                     sourceLocation: sourceLocation)
        throw TestSupportError.wrongErrorType
    }
}

private enum TestSupportError: Error { case expectedThrow, wrongErrorType }