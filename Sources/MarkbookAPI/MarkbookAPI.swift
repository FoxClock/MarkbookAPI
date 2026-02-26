// MarkbookAPIClient.swift
// Markbook Online REST API v1.5
// https://smpcsonline.com.au/markbook/api/v1.5

import Foundation

// MARK: - Errors

public enum MarkbookAPIError: Error, LocalizedError {
    /// The server returned a non-2xx HTTP status code.
    case httpError(statusCode: Int)
    /// The API returned a non-OKAY status in the response body.
    case apiError(APIStatus)
    /// A required URL could not be constructed from the given parameters.
    case invalidURL
    /// The `matching` parameter for `scheduleBackup` must be two or more characters.
    case invalidBackupMatchingParameter
    /// The session could not be established or refreshed.
    case authenticationFailed(underlying: Error)

    public var errorDescription: String? {
        switch self {
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .apiError(let status):
            return "API error: \(status)"
        case .invalidURL:
            return "Could not construct a valid request URL."
        case .invalidBackupMatchingParameter:
            return "The 'matching' parameter must be at least two characters."
        case .authenticationFailed(let error):
            return "Authentication failed: \(error.localizedDescription)"
        }
    }
}

// MARK: - Protocol

/// Defines the full surface area of the Markbook Online API client.
/// Conform a mock to this protocol to enable unit testing without network calls.
public protocol MarkbookAPIClientProtocol {
    func markbookList() async throws -> MarkbookListResponse
    func userList() async throws -> UserListResponse
    func getMarkbook(key: Int) async throws -> GetMarkbookResponse
    func getMarkbookAlt(key: Int) async throws -> GetMarkbookAltResponse
    func getOutcomes(key: Int) async throws -> GetOutcomesResponse
    func getOutcomesAlt(key: Int) async throws -> GetOutcomesAltResponse
    func putStudentResult(
        markbookKey: Int,
        studentKey: Int,
        sid: String,
        taskKey: Int,
        taskName: String,
        result: String
    ) async throws
    func createStudent(
        markbookKey: Int,
        sid: String,
        familyName: String,
        givenName: String,
        preferredName: String,
        gender: Gender,
        classKey: Int
    ) async throws -> CreateStudentResponse
    func updateStudent(
        markbookKey: Int,
        studentKey: Int,
        sid: String,
        familyName: String,
        givenName: String,
        preferredName: String,
        gender: Gender
    ) async throws
    func updateStudentClass(
        markbookKey: Int,
        studentKey: Int,
        sid: String,
        classKey: Int
    ) async throws
    func deleteStudent(
        markbookKey: Int,
        studentKey: Int,
        sid: String
    ) async throws
    func createClass(
        markbookKey: Int,
        name: String,
        teacherFamilyName: String,
        teacherGivenName: String
    ) async throws -> CreateClassResponse
    func scheduleBackup(matching: String) async throws
    func getBackupURL() async throws -> GetBackupURLResponse
    func createMarkbook(_ request: CreateMarkbookRequest) async throws -> CreateMarkbookResponse
}

// MARK: - Client

/// An `actor`-isolated client for the Markbook Online REST API v1.5.
///
/// Authentication is handled automatically. The session token and key expire after
/// 20 minutes; the client tracks the authentication timestamp and transparently
/// re-authenticates before any call that would use an expired session.
///
/// ```swift
/// import MarkbookAPI
///
/// let client = MarkbookAPIClient(
///     apiKey: "YOUR_32_CHAR_API_KEY",
///     username: "adminuser",
///     password: "secret"
/// )
/// let markbooks = try await client.markbookList()
/// ```
public actor MarkbookAPIClient: MarkbookAPIClientProtocol {

    // MARK: - Private State

    private let apiKey: String
    private let username: String
    private let password: String

    private let baseURL: URL
    private let urlSession: URLSession
    private let decoder: JSONDecoder

    /// Cached credentials. `nil` until the first successful authentication.
    private var session: SessionCredentials?
    /// The time at which the current session was established.
    private var sessionEstablishedAt: Date?
    /// Re-authenticate one minute before the API's 20-minute expiry to avoid races.
    private let sessionLifetime: TimeInterval = 19 * 60

    // MARK: - Initialisation

    /// Creates a new API client.
    ///
    /// - Parameters:
    ///   - apiKey: The 32-character school-specific API key.
    ///   - username: Login name of a user with *Allow user administration* permission.
    ///   - password: Password for the above user.
    ///   - baseURL: Override only for testing. Defaults to the production endpoint.
    ///   - urlSession: Override to inject a mock session for testing.
    public init(
        apiKey: String,
        username: String,
        password: String,
        baseURL: URL = URL(string: "https://smpcsonline.com.au/markbook/api/v1.5")!,
        urlSession: URLSession = .shared
    ) {
        self.apiKey = apiKey
        self.username = username
        self.password = password
        self.baseURL = baseURL
        self.urlSession = urlSession
        self.decoder = JSONDecoder()
    }

    // MARK: - Public API Methods

    /// Returns the list of all markbooks in the school database.
    public func markbookList() async throws -> MarkbookListResponse {
        try await get(queryItems: [
            .init(name: "action", value: APIAction.markbookList.rawValue)
        ])
    }

    /// Returns the list of all users in the school database.
    public func userList() async throws -> UserListResponse {
        try await get(queryItems: [
            .init(name: "action", value: APIAction.userList.rawValue)
        ])
    }

    /// Returns the full contents of a markbook, with per-student result arrays.
    /// - Parameter key: The markbook key from ``markbookList()``.
    public func getMarkbook(key: Int) async throws -> GetMarkbookResponse {
        try await get(queryItems: [
            .init(name: "action", value: APIAction.getMarkbook.rawValue),
            .init(name: "key", value: String(key))
        ])
    }

    /// Returns the full contents of a markbook in the flat alternate format.
    /// - Parameter key: The markbook key from ``markbookList()``.
    public func getMarkbookAlt(key: Int) async throws -> GetMarkbookAltResponse {
        try await get(queryItems: [
            .init(name: "action", value: APIAction.getMarkbookAlt.rawValue),
            .init(name: "key", value: String(key))
        ])
    }

    /// Returns outcome levels for all students in a markbook.
    /// - Parameter key: The markbook key from ``markbookList()``.
    public func getOutcomes(key: Int) async throws -> GetOutcomesResponse {
        try await get(queryItems: [
            .init(name: "action", value: APIAction.getOutcomes.rawValue),
            .init(name: "key", value: String(key))
        ])
    }

    /// Returns outcome levels in the flat alternate format.
    /// - Parameter key: The markbook key from ``markbookList()``.
    public func getOutcomesAlt(key: Int) async throws -> GetOutcomesAltResponse {
        try await get(queryItems: [
            .init(name: "action", value: APIAction.getOutcomesAlt.rawValue),
            .init(name: "key", value: String(key))
        ])
    }

    /// Updates a single student result in a markbook.
    ///
    /// - Parameters:
    ///   - markbookKey: The markbook key from ``markbookList()``.
    ///   - studentKey: The student key from ``getMarkbook(key:)`` or ``getMarkbookAlt(key:)``.
    ///   - sid: The student ID from the same source as `studentKey`.
    ///   - taskKey: The task key from the markbook's `tasklist`.
    ///   - taskName: The task name from the markbook's `tasklist`.
    ///   - result: The result value to record.
    public func putStudentResult(
        markbookKey: Int,
        studentKey: Int,
        sid: String,
        taskKey: Int,
        taskName: String,
        result: String
    ) async throws {
        let response: StatusOnlyResponse = try await get(queryItems: [
            .init(name: "action", value: APIAction.putStudentResult.rawValue),
            .init(name: "key", value: String(markbookKey)),
            .init(name: "studentkey", value: String(studentKey)),
            .init(name: "sid", value: sid),
            .init(name: "taskkey", value: String(taskKey)),
            .init(name: "taskname", value: taskName),
            .init(name: "result", value: result)
        ])
        guard response.status.isOkay else {
            throw MarkbookAPIError.apiError(response.status)
        }
    }

    /// Creates a new student in the specified class of a markbook.
    ///
    /// - Parameters:
    ///   - markbookKey: The markbook key from ``markbookList()``.
    ///   - sid: A unique student ID not already present in the markbook.
    ///   - familyName: Student family name.
    ///   - givenName: Student given name.
    ///   - preferredName: Student preferred name (may be empty).
    ///   - gender: Student gender.
    ///   - classKey: The class key from ``getMarkbook(key:)`` or ``getMarkbookAlt(key:)``.
    /// - Returns: The response containing the new student's key.
    public func createStudent(
        markbookKey: Int,
        sid: String,
        familyName: String,
        givenName: String,
        preferredName: String,
        gender: Gender,
        classKey: Int
    ) async throws -> CreateStudentResponse {
        try await get(queryItems: [
            .init(name: "action", value: APIAction.createStudent.rawValue),
            .init(name: "key", value: String(markbookKey)),
            .init(name: "sid", value: sid),
            .init(name: "family", value: familyName),
            .init(name: "given", value: givenName),
            .init(name: "preferred", value: preferredName),
            .init(name: "gender", value: gender.rawValue),
            .init(name: "classkey", value: String(classKey))
        ])
    }

    /// Updates the name details of an existing student.
    /// All fields must be provided even if unchanged. The `sid` cannot be changed.
    ///
    /// - Parameters:
    ///   - markbookKey: The markbook key from ``markbookList()``.
    ///   - studentKey: The student key from ``getMarkbook(key:)`` or ``getMarkbookAlt(key:)``.
    ///   - sid: The student ID — used for identification only, cannot be changed.
    ///   - familyName: Student family name.
    ///   - givenName: Student given name.
    ///   - preferredName: Student preferred name (may be empty).
    ///   - gender: Student gender.
    public func updateStudent(
        markbookKey: Int,
        studentKey: Int,
        sid: String,
        familyName: String,
        givenName: String,
        preferredName: String,
        gender: Gender
    ) async throws {
        let response: StatusOnlyResponse = try await get(queryItems: [
            .init(name: "action", value: APIAction.updateStudent.rawValue),
            .init(name: "key", value: String(markbookKey)),
            .init(name: "studentkey", value: String(studentKey)),
            .init(name: "sid", value: sid),
            .init(name: "family", value: familyName),
            .init(name: "given", value: givenName),
            .init(name: "preferred", value: preferredName),
            .init(name: "gender", value: gender.rawValue)
        ])
        guard response.status.isOkay else {
            throw MarkbookAPIError.apiError(response.status)
        }
    }

    /// Moves a student into a different class within a markbook.
    /// Can also be used to restore a previously deleted student.
    ///
    /// - Parameters:
    ///   - markbookKey: The markbook key from ``markbookList()``.
    ///   - studentKey: The student key from ``getMarkbook(key:)`` or ``getMarkbookAlt(key:)``.
    ///   - sid: The student ID from the same source as `studentKey`.
    ///   - classKey: The destination class key.
    public func updateStudentClass(
        markbookKey: Int,
        studentKey: Int,
        sid: String,
        classKey: Int
    ) async throws {
        let response: StatusOnlyResponse = try await get(queryItems: [
            .init(name: "action", value: APIAction.updateStudentClass.rawValue),
            .init(name: "key", value: String(markbookKey)),
            .init(name: "studentkey", value: String(studentKey)),
            .init(name: "sid", value: sid),
            .init(name: "classkey", value: String(classKey))
        ])
        guard response.status.isOkay else {
            throw MarkbookAPIError.apiError(response.status)
        }
    }

    /// Soft-deletes a student from a markbook.
    /// The student remains in the database and can be restored via
    /// ``updateStudentClass(markbookKey:studentKey:sid:classKey:)``.
    ///
    /// - Parameters:
    ///   - markbookKey: The markbook key from ``markbookList()``.
    ///   - studentKey: The student key from ``getMarkbook(key:)`` or ``getMarkbookAlt(key:)``.
    ///   - sid: The student ID from the same source as `studentKey`.
    public func deleteStudent(
        markbookKey: Int,
        studentKey: Int,
        sid: String
    ) async throws {
        let response: StatusOnlyResponse = try await get(queryItems: [
            .init(name: "action", value: APIAction.deleteStudent.rawValue),
            .init(name: "key", value: String(markbookKey)),
            .init(name: "studentkey", value: String(studentKey)),
            .init(name: "sid", value: sid)
        ])
        guard response.status.isOkay else {
            throw MarkbookAPIError.apiError(response.status)
        }
    }

    /// Creates a new class in a markbook. The class name must be unique within the markbook.
    ///
    /// - Parameters:
    ///   - markbookKey: The markbook key from ``markbookList()``.
    ///   - name: A unique class name (e.g. "9ENG1").
    ///   - teacherFamilyName: The class teacher's family name.
    ///   - teacherGivenName: The class teacher's given name.
    /// - Returns: The response containing the new class key.
    public func createClass(
        markbookKey: Int,
        name: String,
        teacherFamilyName: String,
        teacherGivenName: String
    ) async throws -> CreateClassResponse {
        try await get(queryItems: [
            .init(name: "action", value: APIAction.createClass.rawValue),
            .init(name: "key", value: String(markbookKey)),
            .init(name: "name", value: name),
            .init(name: "family", value: teacherFamilyName),
            .init(name: "given", value: teacherGivenName)
        ])
    }

    /// Schedules a nightly backup of markbooks whose names contain `matching`.
    /// The backup is created at approximately 1 AM. Call ``getBackupURL()`` the following day.
    /// Only one backup can be scheduled per day; a second call replaces the first.
    ///
    /// - Parameter matching: A substring filter (minimum 2 characters) applied to markbook names.
    public func scheduleBackup(matching: String) async throws {
        guard matching.count >= 2 else {
            throw MarkbookAPIError.invalidBackupMatchingParameter
        }
        let response: StatusOnlyResponse = try await get(queryItems: [
            .init(name: "action", value: APIAction.scheduleBackup.rawValue),
            .init(name: "matching", value: matching)
        ])
        guard response.status.isOkay else {
            throw MarkbookAPIError.apiError(response.status)
        }
    }

    /// Returns the download URL for the most recently completed scheduled backup.
    ///
    /// The zip file is deleted approximately one hour after the URL is first returned,
    /// so it should be downloaded promptly. The timestamp on the zip is UTC.
    ///
    /// - Returns: The full response, including the `url` and `status`.
    ///   Check `status` for `.errorPending` (backup not yet ready) or `.errorNoBackup`
    ///   (no backup has been scheduled).
    public func getBackupURL() async throws -> GetBackupURLResponse {
        try await get(queryItems: [
            .init(name: "action", value: APIAction.getBackupURL.rawValue)
        ])
    }

    /// Creates a new markbook via the POST endpoint.
    ///
    /// - Parameter request: The fully populated ``CreateMarkbookRequest``.
    ///   Build it with the local class/student keys starting from 1.
    /// - Returns: The response containing the new markbook key and actual name used.
    public func createMarkbook(_ request: CreateMarkbookRequest) async throws -> CreateMarkbookResponse {
        try await post(action: APIAction.createMarkbook.rawValue, body: request)
    }

    // MARK: - Session Management

    /// Returns valid credentials, refreshing the session if it has expired.
    private func validSession() async throws -> SessionCredentials {
        if let existing = session, let establishedAt = sessionEstablishedAt {
            if Date().timeIntervalSince(establishedAt) < sessionLifetime {
                return existing
            }
        }
        return try await refreshSession()
    }

    @discardableResult
    private func refreshSession() async throws -> SessionCredentials {
        let authResponse = try await performAuthentication()
        let credentials = SessionCredentials(
            sessionToken: authResponse.sessionToken,
            sessionKey: authResponse.sessionKey,
            apiKey: apiKey
        )
        session = credentials
        sessionEstablishedAt = Date()
        return credentials
    }

    private func performAuthentication() async throws -> AuthenticationResponse {
        let authURL = baseURL.appendingPathComponent("authenticate.lc", isDirectory: false)

        var components = URLComponents()
        components.queryItems = [
            .init(name: "apiuser", value: username),
            .init(name: "apipassword", value: password)
        ]
        guard let body = components.query?.data(using: .utf8) else {
            throw MarkbookAPIError.invalidURL
        }

        var request = URLRequest(url: authURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = body

        do {
            return try await perform(request)
        } catch {
            throw MarkbookAPIError.authenticationFailed(underlying: error)
        }
    }

    // MARK: - Transport Helpers

    /// Builds and executes a GET request, automatically injecting session credentials.
    private func get<T: Decodable>(queryItems: [URLQueryItem]) async throws -> T {
        let credentials = try await validSession()

        var allItems = queryItems
        allItems.append(contentsOf: [
            .init(name: "sessiontoken", value: credentials.sessionToken),
            .init(name: "sessionkey", value: String(credentials.sessionKey)),
            .init(name: "apikey", value: credentials.apiKey)
        ])

        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
        components?.queryItems = allItems

        guard let url = components?.url else {
            throw MarkbookAPIError.invalidURL
        }

        return try await perform(URLRequest(url: url))
    }

    /// Builds and executes a POST request, encoding `body` as JSON in the `jsondata` field.
    private func post<Body: Encodable, T: Decodable>(
        action: String,
        body: Body
    ) async throws -> T {
        let credentials = try await validSession()

        let jsonData = try JSONEncoder().encode(body)
        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            throw MarkbookAPIError.invalidURL
        }

        var components = URLComponents()
        components.queryItems = [
            .init(name: "apikey", value: credentials.apiKey),
            .init(name: "sessiontoken", value: credentials.sessionToken),
            .init(name: "sessionkey", value: String(credentials.sessionKey)),
            .init(name: "apiaction", value: action),
            .init(name: "jsondata", value: jsonString)
        ]
        guard let formBody = components.query?.data(using: .utf8) else {
            throw MarkbookAPIError.invalidURL
        }

        let postURL = baseURL.appendingPathComponent("post.lc", isDirectory: false)
        var request = URLRequest(url: postURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = formBody

        return try await perform(request)
    }

    /// Executes a `URLRequest`, validates the HTTP status, and decodes the response body.
    private func perform<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await urlSession.data(for: request)

        if let httpResponse = response as? HTTPURLResponse,
           !(200..<300).contains(httpResponse.statusCode) {
            throw MarkbookAPIError.httpError(statusCode: httpResponse.statusCode)
        }

        let decoded = try decoder.decode(T.self, from: data)

        // Surface API-level errors uniformly for any response type that carries a status.
        if let statusCarrier = decoded as? any StatusCarrying, !statusCarrier.status.isOkay {
            throw MarkbookAPIError.apiError(statusCarrier.status)
        }

        return decoded
    }
}

// MARK: - StatusCarrying

/// Internal protocol used to extract `status` from any response type for uniform error surfacing.
private protocol StatusCarrying {
    var status: APIStatus { get }
}

extension AuthenticationResponse: StatusCarrying {}
extension MarkbookListResponse: StatusCarrying {}
extension UserListResponse: StatusCarrying {}
extension GetMarkbookResponse: StatusCarrying {}
extension GetMarkbookAltResponse: StatusCarrying {}
extension GetOutcomesResponse: StatusCarrying {}
extension GetOutcomesAltResponse: StatusCarrying {}
extension StatusOnlyResponse: StatusCarrying {}
extension CreateStudentResponse: StatusCarrying {}
extension CreateClassResponse: StatusCarrying {}
extension GetBackupURLResponse: StatusCarrying {}
extension CreateMarkbookResponse: StatusCarrying {}