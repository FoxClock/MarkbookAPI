// Models.swift
// Markbook Online REST API v1.5
// https://smpcsonline.com.au/markbook/api/v1.5

import Foundation

// MARK: - Base Response

/// The common envelope returned by every API endpoint.
struct APIResponse: Decodable {
    let source: String
    let api: String
    /// Unix timestamp of the response.
    let seconds: Int
    let date: String
    let schoolName: String
    let action: APIAction
    let status: APIStatus

    enum CodingKeys: String, CodingKey {
        case source, api, seconds, date, action, status
        case schoolName = "schoolname"
    }
}

// MARK: - Enumerations

/// All supported API actions.
enum APIAction: String, Codable {
    case authentication
    case markbookList     = "markbooklist"
    case userList         = "userlist"
    case getMarkbook      = "getmarkbook"
    case getMarkbookAlt   = "getmarkbookalt"
    case getOutcomes      = "getoutcomes"
    case getOutcomesAlt   = "getoutcomesalt"
    case putStudentResult = "putstudentresult"
    case createStudent    = "createstudent"
    case updateStudent    = "updatestudent"
    case updateStudentClass = "updatestudentclass"
    case deleteStudent    = "deletestudent"
    case createClass      = "createclass"
    case scheduleBackup   = "schedulebackup"
    case getBackupURL     = "getbackupurl"
    case createMarkbook   = "createmarkbook"
}

/// The status string returned with every response.
/// Backup-specific error states are represented as separate cases.
enum APIStatus: Decodable, Equatable {
    case okay
    case errorPending
    case errorNoBackup
    case error(String)

    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        switch raw {
        case "OKAY":              self = .okay
        case "ERROR:pending":    self = .errorPending
        case "ERROR:no backup":  self = .errorNoBackup
        default:                 self = .error(raw)
        }
    }

    var isOkay: Bool { self == .okay }
}

/// Student gender value used in create / update calls.
enum Gender: String, Codable {
    case male, female, other
}

// MARK: - Shared Sub-models

struct MarkbookClass: Codable {
    let key: Int
    let name: String
    /// Teacher family name.
    let teacherName1: String
    /// Teacher given name.
    let teacherName2: String

    enum CodingKeys: String, CodingKey {
        case key, name
        case teacherName1 = "teachername1"
        case teacherName2 = "teachername2"
    }
}

struct MarkbookTask: Codable {
    let key: Int
    let name: String
    let maximum: Int
    let decimalPlaces: Int

    enum CodingKeys: String, CodingKey {
        case key, name, maximum
        case decimalPlaces = "decimalplaces"
    }
}

// MARK: - Authentication

/// Response returned after a successful POST to `authenticate.lc`.
struct AuthenticationResponse: Decodable {
    let source: String
    let api: String
    let seconds: Int
    let date: String
    let schoolName: String
    let action: APIAction
    let status: APIStatus
    /// 16-character session token. Required for all subsequent calls.
    let sessionToken: String
    /// Random numeric session key. Required for all subsequent calls.
    let sessionKey: Int

    enum CodingKeys: String, CodingKey {
        case source, api, seconds, date, action, status
        case schoolName  = "schoolname"
        case sessionToken = "sessiontoken"
        case sessionKey   = "sessionkey"
    }
}

/// Convenience container for the credentials needed by every API call after authentication.
struct SessionCredentials {
    let sessionToken: String
    let sessionKey: Int
    let apiKey: String
}

// MARK: - markbooklist

/// A lightweight markbook summary returned by the `markbooklist` action.
struct MarkbookSummary: Codable {
    let key: Int
    let name: String
    let owner: String
    let year: String
    let course: String
}

struct MarkbookListResponse: Decodable {
    let source: String
    let api: String
    let seconds: Int
    let date: String
    let schoolName: String
    let action: APIAction
    let status: APIStatus
    let list: [MarkbookSummary]

    enum CodingKeys: String, CodingKey {
        case source, api, seconds, date, action, status, list
        case schoolName = "schoolname"
    }
}

// MARK: - userlist

struct User: Codable {
    let key: Int
    let name: String
    let loginID: String
    let email: String

    enum CodingKeys: String, CodingKey {
        case key, name, email
        case loginID = "loginid"
    }
}

struct UserListResponse: Decodable {
    let source: String
    let api: String
    let seconds: Int
    let date: String
    let schoolName: String
    let action: APIAction
    let status: APIStatus
    let list: [User]

    enum CodingKeys: String, CodingKey {
        case source, api, seconds, date, action, status, list
        case schoolName = "schoolname"
    }
}

// MARK: - getmarkbook

/// A student record including per-task result arrays (standard format).
struct StudentWithResults: Decodable {
    let key: Int
    let studentID: String
    let familyName: String
    let givenName: String
    let preferredName: String
    let classKey: Int
    let className: String
    /// Raw result strings in the same order as the parent `tasklist`.
    let rawResults: [String]
    /// Rounded result strings in the same order as the parent `tasklist`.
    let roundedResults: [String]

    enum CodingKeys: String, CodingKey {
        case key
        case studentID     = "studentid"
        case familyName    = "familyname"
        case givenName     = "givename"
        case preferredName = "preferredname"
        case classKey      = "classkey"
        case className     = "classname"
        case rawResults    = "rawresults"
        case roundedResults = "roundedresults"
    }
}

struct GetMarkbookResponse: Decodable {
    let source: String
    let api: String
    let seconds: Int
    let date: String
    let schoolName: String
    let action: APIAction
    let status: APIStatus
    let markbookKey: Int
    let markbookName: String
    let markbookYear: String
    let markbookCourse: String
    let ownerKey: Int
    let shareList: [Int]
    let classList: [MarkbookClass]
    let taskList: [MarkbookTask]
    let studentList: [StudentWithResults]

    enum CodingKeys: String, CodingKey {
        case source, api, seconds, date, action, status
        case schoolName    = "schoolname"
        case markbookKey   = "markbookkey"
        case markbookName  = "markbookname"
        case markbookYear  = "markbookyear"
        case markbookCourse = "markbookcourse"
        case ownerKey      = "ownerkey"
        case shareList     = "sharelist"
        case classList     = "classlist"
        case taskList      = "tasklist"
        case studentList   = "studentlist"
    }
}

// MARK: - getmarkbookalt

/// A student record without result arrays (used in the alternate format).
struct Student: Codable {
    let key: Int
    let studentID: String
    let familyName: String
    let givenName: String
    let preferredName: String
    let classKey: Int
    let className: String

    enum CodingKeys: String, CodingKey {
        case key
        case studentID   = "studentid"
        case familyName  = "familyname"
        case givenName   = "givename"
        case preferredName = "preferredname"
        case classKey    = "classkey"
        case className   = "classname"
    }
}

/// A single result entry in the flat `resultlist` array.
struct StudentTaskResult: Decodable {
    let studentKey: Int
    let taskKey: Int
    let rawResult: String
    let roundedResult: String

    enum CodingKeys: String, CodingKey {
        case studentKey    = "studentkey"
        case taskKey       = "taskkey"
        case rawResult     = "rawresult"
        case roundedResult = "roundedresult"
    }
}

struct GetMarkbookAltResponse: Decodable {
    let source: String
    let api: String
    let seconds: Int
    let date: String
    let schoolName: String
    let action: APIAction
    let status: APIStatus
    let markbookKey: Int
    let markbookName: String
    let markbookYear: String
    let markbookCourse: String
    let ownerKey: Int
    let shareList: [Int]
    let classList: [MarkbookClass]
    let taskList: [MarkbookTask]
    let studentList: [Student]
    let resultList: [StudentTaskResult]

    enum CodingKeys: String, CodingKey {
        case source, api, seconds, date, action, status
        case schoolName     = "schoolname"
        case markbookKey    = "markbookkey"
        case markbookName   = "markbookname"
        case markbookYear   = "markbookyear"
        case markbookCourse = "markbookcourse"
        case ownerKey       = "ownerkey"
        case shareList      = "sharelist"
        case classList      = "classlist"
        case taskList       = "tasklist"
        case studentList    = "studentlist"
        case resultList     = "resultlist"
    }
}

// MARK: - getoutcomes

struct Outcome: Codable {
    let key: Int
    /// Short code for the outcome (may be empty).
    let code: String
    let name: String
    /// Full outcome description.
    let outcome: String
    /// Keys of tasks that contribute to this outcome level.
    let taskList: [Int]

    enum CodingKeys: String, CodingKey {
        case key, code, name, outcome
        case taskList = "tasklist"
    }
}

/// A student record with per-outcome level strings (standard outcomes format).
struct StudentWithOutcomes: Decodable {
    let key: Int
    let studentID: String
    let familyName: String
    let givenName: String
    let preferredName: String
    let classKey: Int
    let className: String
    /// Outcome level strings in the same order as the parent `outcomelist`.
    let outcomeLevels: [String]

    enum CodingKeys: String, CodingKey {
        case key
        case studentID    = "studentid"
        case familyName   = "familyname"
        case givenName    = "givename"
        case preferredName = "preferredname"
        case classKey     = "classkey"
        case className    = "classname"
        case outcomeLevels = "outcomelevels"
    }
}

struct GetOutcomesResponse: Decodable {
    let source: String
    let api: String
    let seconds: Int
    let date: String
    let schoolName: String
    let action: APIAction
    let status: APIStatus
    let classList: [MarkbookClass]
    let outcomeList: [Outcome]
    let studentList: [StudentWithOutcomes]

    enum CodingKeys: String, CodingKey {
        case source, api, seconds, date, action, status
        case schoolName  = "schoolname"
        case classList   = "classlist"
        case outcomeList = "outcomelist"
        case studentList = "studentlist"
    }
}

// MARK: - getoutcomesalt

/// A single entry in the flat `levellist` array.
struct StudentOutcomeLevel: Decodable {
    let studentKey: Int
    let outcomeKey: Int
    let outcomeLevel: String

    enum CodingKeys: String, CodingKey {
        case studentKey  = "studentkey"
        case outcomeKey  = "outcomekey"
        case outcomeLevel = "outcomelevel"
    }
}

struct GetOutcomesAltResponse: Decodable {
    let source: String
    let api: String
    let seconds: Int
    let date: String
    let schoolName: String
    let action: APIAction
    let status: APIStatus
    let classList: [MarkbookClass]
    let outcomeList: [Outcome]
    let studentList: [Student]
    let levelList: [StudentOutcomeLevel]

    enum CodingKeys: String, CodingKey {
        case source, api, seconds, date, action, status
        case schoolName  = "schoolname"
        case classList   = "classlist"
        case outcomeList = "outcomelist"
        case studentList = "studentlist"
        case levelList   = "levellist"
    }
}

// MARK: - Simple status-only responses
// putstudentresult, updatestudent, updatestudentclass,
// deletestudent, schedulebackup all share this shape.

struct StatusOnlyResponse: Decodable {
    let source: String
    let api: String
    let seconds: Int
    let date: String
    let schoolName: String
    let action: APIAction
    let status: APIStatus

    enum CodingKeys: String, CodingKey {
        case source, api, seconds, date, action, status
        case schoolName = "schoolname"
    }
}

// MARK: - createstudent

struct CreateStudentResponse: Decodable {
    let source: String
    let api: String
    let seconds: Int
    let date: String
    let schoolName: String
    let action: APIAction
    let status: APIStatus
    /// Key of the newly created student.
    let studentKey: Int

    enum CodingKeys: String, CodingKey {
        case source, api, seconds, date, action, status
        case schoolName = "schoolname"
        case studentKey = "studentkey"
    }
}

// MARK: - createclass

struct CreateClassResponse: Decodable {
    let source: String
    let api: String
    let seconds: Int
    let date: String
    let schoolName: String
    let action: APIAction
    let status: APIStatus
    /// Key of the newly created class.
    let classKey: Int

    enum CodingKeys: String, CodingKey {
        case source, api, seconds, date, action, status
        case schoolName = "schoolname"
        case classKey   = "classkey"
    }
}

// MARK: - getbackupurl

struct GetBackupURLResponse: Decodable {
    let source: String
    let api: String
    let seconds: Int
    let date: String
    let schoolName: String
    let action: APIAction
    let status: APIStatus
    /// The download URL for the backup zip. Empty when status is not `.okay`.
    let url: String

    enum CodingKeys: String, CodingKey {
        case source, api, seconds, date, action, status, url
        case schoolName = "schoolname"
    }
}

// MARK: - createmarkbook (POST)

/// The JSON payload sent as `jsondata` in the `createmarkbook` POST call.
/// Class and student keys are local to this payload and may start from 1.
struct CreateMarkbookRequest: Encodable {
    let api: String
    let schoolName: String
    let action: APIAction
    let markbookName: String
    let markbookYear: String
    let markbookCourse: String
    /// Must match a key returned by `userlist`.
    let ownerKey: Int
    /// Keys of users to share the markbook with. Must exist in `userlist`.
    let shareList: [Int]
    let classList: [NewMarkbookClass]
    let studentList: [NewMarkbookStudent]

    enum CodingKeys: String, CodingKey {
        case api, action
        case schoolName     = "schoolname"
        case markbookName   = "markbookname"
        case markbookYear   = "markbookyear"
        case markbookCourse = "markbookcourse"
        case ownerKey       = "ownerkey"
        case shareList      = "sharelist"
        case classList      = "classlist"
        case studentList    = "studentlist"
    }
}

/// A class definition inside a `createmarkbook` payload.
struct NewMarkbookClass: Codable {
    /// Local key (unique within this request, may start from 1).
    let key: Int
    let name: String
    let teacherName1: String
    let teacherName2: String

    enum CodingKeys: String, CodingKey {
        case key, name
        case teacherName1 = "teachername1"
        case teacherName2 = "teachername2"
    }
}

/// A student definition inside a `createmarkbook` payload.
struct NewMarkbookStudent: Codable {
    /// Local key (unique within this request, may start from 1).
    let key: Int
    /// Must be non-empty; used as the student's permanent identifier.
    let studentID: String
    let familyName: String
    let givenName: String
    let preferredName: String
    /// Must match a `key` in the accompanying `classList`.
    let classKey: Int
    /// Human-readable class name. Not validated by the API; `classKey` is authoritative.
    let className: String

    enum CodingKeys: String, CodingKey {
        case key
        case studentID   = "studentid"
        case familyName  = "familyname"
        case givenName   = "givename"
        case preferredName = "preferredname"
        case classKey    = "classkey"
        case className   = "classname"
    }
}

struct CreateMarkbookResponse: Decodable {
    let source: String
    let api: String
    let seconds: Int
    let date: String
    let schoolName: String
    let action: APIAction
    let status: APIStatus
    /// Key of the newly created markbook.
    let markbookKey: Int
    /// Actual name used (may have a "-1" suffix if the requested name was already taken).
    let markbookName: String
    let classCount: Int
    let studentCount: Int
    let shareCount: Int

    enum CodingKeys: String, CodingKey {
        case source, api, seconds, date, action, status
        case schoolName    = "schoolname"
        case markbookKey   = "markbookkey"
        case markbookName  = "markbookname"
        case classCount    = "classcount"
        case studentCount  = "studentcount"
        case shareCount    = "sharecount"
    }
}