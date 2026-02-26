// Models.swift
// Markbook Online REST API v1.5
// https://smpcsonline.com.au/markbook/api/v1.5

import Foundation

// MARK: - Enumerations

/// All supported API actions.
public enum APIAction: String, Codable, Sendable {
    case authentication
    case markbookList        = "markbooklist"
    case userList            = "userlist"
    case getMarkbook         = "getmarkbook"
    case getMarkbookAlt      = "getmarkbookalt"
    case getOutcomes         = "getoutcomes"
    case getOutcomesAlt      = "getoutcomesalt"
    case putStudentResult    = "putstudentresult"
    case createStudent       = "createstudent"
    case updateStudent       = "updatestudent"
    case updateStudentClass  = "updatestudentclass"
    case deleteStudent       = "deletestudent"
    case createClass         = "createclass"
    case scheduleBackup      = "schedulebackup"
    case getBackupURL        = "getbackupurl"
    case createMarkbook      = "createmarkbook"
}

/// The status string returned with every API response.
/// Backup-specific error states are represented as dedicated cases.
public enum APIStatus: Decodable, Equatable, Sendable {
    case okay
    case errorPending
    case errorNoBackup
    case error(String)

    public init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        switch raw {
        case "OKAY":             self = .okay
        case "ERROR:pending":   self = .errorPending
        case "ERROR:no backup": self = .errorNoBackup
        default:                self = .error(raw)
        }
    }

    /// `true` only when the status is `.okay`.
    public var isOkay: Bool { self == .okay }
}

/// Student gender value used in create and update calls.
public enum Gender: String, Codable, Sendable {
    case male, female, other
}

// MARK: - Shared Sub-models

public struct MarkbookClass: Codable, Sendable {
    public let key: Int
    public let name: String
    /// Teacher family name.
    public let teacherName1: String
    /// Teacher given name.
    public let teacherName2: String

    enum CodingKeys: String, CodingKey {
        case key, name
        case teacherName1 = "teachername1"
        case teacherName2 = "teachername2"
    }
}

public struct MarkbookTask: Codable, Sendable {
    public let key: Int
    public let name: String
    public let maximum: Int
    public let decimalPlaces: Int

    enum CodingKeys: String, CodingKey {
        case key, name, maximum
        case decimalPlaces = "decimalplaces"
    }
}

// MARK: - markbooklist

/// A lightweight markbook summary returned by the `markbooklist` action.
public struct MarkbookSummary: Codable, Sendable {
    public let key: Int
    public let name: String
    public let owner: String
    public let year: String
    public let course: String
}

public struct MarkbookListResponse: Decodable, Sendable {
    public let source: String
    public let api: String
    public let seconds: Int
    public let date: String
    public let schoolName: String
    public let action: APIAction
    public let status: APIStatus
    public let list: [MarkbookSummary]

    enum CodingKeys: String, CodingKey {
        case source, api, seconds, date, action, status, list
        case schoolName = "schoolname"
    }
}

// MARK: - userlist

public struct User: Codable, Sendable {
    public let key: Int
    public let name: String
    public let loginID: String
    public let email: String

    enum CodingKeys: String, CodingKey {
        case key, name, email
        case loginID = "loginid"
    }
}

public struct UserListResponse: Decodable, Sendable {
    public let source: String
    public let api: String
    public let seconds: Int
    public let date: String
    public let schoolName: String
    public let action: APIAction
    public let status: APIStatus
    public let list: [User]

    enum CodingKeys: String, CodingKey {
        case source, api, seconds, date, action, status, list
        case schoolName = "schoolname"
    }
}

// MARK: - getmarkbook

/// A student record including per-task result arrays (standard format).
public struct StudentWithResults: Decodable, Sendable {
    public let key: Int
    public let studentID: String
    public let familyName: String
    public let givenName: String
    public let preferredName: String
    public let classKey: Int
    public let className: String
    /// Raw result strings in the same order as the parent `tasklist`.
    public let rawResults: [String]
    /// Rounded result strings in the same order as the parent `tasklist`.
    public let roundedResults: [String]

    enum CodingKeys: String, CodingKey {
        case key
        case studentID      = "studentid"
        case familyName     = "familyname"
        case givenName      = "givename"
        case preferredName  = "preferredname"
        case classKey       = "classkey"
        case className      = "classname"
        case rawResults     = "rawresults"
        case roundedResults = "roundedresults"
    }
}

public struct GetMarkbookResponse: Decodable, Sendable {
    public let source: String
    public let api: String
    public let seconds: Int
    public let date: String
    public let schoolName: String
    public let action: APIAction
    public let status: APIStatus
    public let markbookKey: Int
    public let markbookName: String
    public let markbookYear: String
    public let markbookCourse: String
    public let ownerKey: Int
    public let shareList: [Int]
    public let classList: [MarkbookClass]
    public let taskList: [MarkbookTask]
    public let studentList: [StudentWithResults]

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
    }
}

// MARK: - getmarkbookalt

/// A student record without embedded result arrays (used in the alternate format).
public struct Student: Codable, Sendable {
    public let key: Int
    public let studentID: String
    public let familyName: String
    public let givenName: String
    public let preferredName: String
    public let classKey: Int
    public let className: String

    enum CodingKeys: String, CodingKey {
        case key
        case studentID     = "studentid"
        case familyName    = "familyname"
        case givenName     = "givename"
        case preferredName = "preferredname"
        case classKey      = "classkey"
        case className     = "classname"
    }
}

/// A single result entry in the flat `resultlist` array.
public struct StudentTaskResult: Decodable, Sendable {
    public let studentKey: Int
    public let taskKey: Int
    public let rawResult: String
    public let roundedResult: String

    enum CodingKeys: String, CodingKey {
        case studentKey    = "studentkey"
        case taskKey       = "taskkey"
        case rawResult     = "rawresult"
        case roundedResult = "roundedresult"
    }
}

public struct GetMarkbookAltResponse: Decodable, Sendable {
    public let source: String
    public let api: String
    public let seconds: Int
    public let date: String
    public let schoolName: String
    public let action: APIAction
    public let status: APIStatus
    public let markbookKey: Int
    public let markbookName: String
    public let markbookYear: String
    public let markbookCourse: String
    public let ownerKey: Int
    public let shareList: [Int]
    public let classList: [MarkbookClass]
    public let taskList: [MarkbookTask]
    public let studentList: [Student]
    public let resultList: [StudentTaskResult]

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

public struct Outcome: Codable, Sendable {
    public let key: Int
    /// Short code for the outcome (may be empty).
    public let code: String
    public let name: String
    /// Full outcome description.
    public let outcome: String
    /// Keys of tasks that contribute to this outcome level.
    public let taskList: [Int]

    enum CodingKeys: String, CodingKey {
        case key, code, name, outcome
        case taskList = "tasklist"
    }
}

/// A student record with per-outcome level strings (standard outcomes format).
public struct StudentWithOutcomes: Decodable, Sendable {
    public let key: Int
    public let studentID: String
    public let familyName: String
    public let givenName: String
    public let preferredName: String
    public let classKey: Int
    public let className: String
    /// Outcome level strings in the same order as the parent `outcomelist`.
    public let outcomeLevels: [String]

    enum CodingKeys: String, CodingKey {
        case key
        case studentID     = "studentid"
        case familyName    = "familyname"
        case givenName     = "givename"
        case preferredName = "preferredname"
        case classKey      = "classkey"
        case className     = "classname"
        case outcomeLevels = "outcomelevels"
    }
}

public struct GetOutcomesResponse: Decodable, Sendable {
    public let source: String
    public let api: String
    public let seconds: Int
    public let date: String
    public let schoolName: String
    public let action: APIAction
    public let status: APIStatus
    public let classList: [MarkbookClass]
    public let outcomeList: [Outcome]
    public let studentList: [StudentWithOutcomes]

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
public struct StudentOutcomeLevel: Decodable, Sendable {
    public let studentKey: Int
    public let outcomeKey: Int
    public let outcomeLevel: String

    enum CodingKeys: String, CodingKey {
        case studentKey   = "studentkey"
        case outcomeKey   = "outcomekey"
        case outcomeLevel = "outcomelevel"
    }
}

public struct GetOutcomesAltResponse: Decodable, Sendable {
    public let source: String
    public let api: String
    public let seconds: Int
    public let date: String
    public let schoolName: String
    public let action: APIAction
    public let status: APIStatus
    public let classList: [MarkbookClass]
    public let outcomeList: [Outcome]
    public let studentList: [Student]
    public let levelList: [StudentOutcomeLevel]

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
// Used internally for putstudentresult, updatestudent, updatestudentclass,
// deletestudent, and schedulebackup. Not part of the public API surface.

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

public struct CreateStudentResponse: Decodable, Sendable {
    public let source: String
    public let api: String
    public let seconds: Int
    public let date: String
    public let schoolName: String
    public let action: APIAction
    public let status: APIStatus
    /// Key of the newly created student.
    public let studentKey: Int

    enum CodingKeys: String, CodingKey {
        case source, api, seconds, date, action, status
        case schoolName = "schoolname"
        case studentKey = "studentkey"
    }
}

// MARK: - createclass

public struct CreateClassResponse: Decodable, Sendable {
    public let source: String
    public let api: String
    public let seconds: Int
    public let date: String
    public let schoolName: String
    public let action: APIAction
    public let status: APIStatus
    /// Key of the newly created class.
    public let classKey: Int

    enum CodingKeys: String, CodingKey {
        case source, api, seconds, date, action, status
        case schoolName = "schoolname"
        case classKey   = "classkey"
    }
}

// MARK: - getbackupurl

public struct GetBackupURLResponse: Decodable, Sendable {
    public let source: String
    public let api: String
    public let seconds: Int
    public let date: String
    public let schoolName: String
    public let action: APIAction
    public let status: APIStatus
    /// The download URL for the backup zip. Empty when status is not `.okay`.
    public let url: String

    enum CodingKeys: String, CodingKey {
        case source, api, seconds, date, action, status, url
        case schoolName = "schoolname"
    }
}

// MARK: - createmarkbook (POST)

/// The JSON payload sent as `jsondata` in the `createmarkbook` POST call.
/// Class and student keys are local to this payload and may start from 1.
public struct CreateMarkbookRequest: Encodable, Sendable {
    public let api: String
    public let schoolName: String
    public let action: APIAction
    public let markbookName: String
    public let markbookYear: String
    public let markbookCourse: String
    /// Must match a key returned by `userlist`.
    public let ownerKey: Int
    /// Keys of users to share the markbook with. Must exist in `userlist`.
    public let shareList: [Int]
    public let classList: [NewMarkbookClass]
    public let studentList: [NewMarkbookStudent]

    public init(
        api: String,
        schoolName: String,
        action: APIAction,
        markbookName: String,
        markbookYear: String,
        markbookCourse: String,
        ownerKey: Int,
        shareList: [Int],
        classList: [NewMarkbookClass],
        studentList: [NewMarkbookStudent]
    ) {
        self.api = api
        self.schoolName = schoolName
        self.action = action
        self.markbookName = markbookName
        self.markbookYear = markbookYear
        self.markbookCourse = markbookCourse
        self.ownerKey = ownerKey
        self.shareList = shareList
        self.classList = classList
        self.studentList = studentList
    }

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
public struct NewMarkbookClass: Codable, Sendable {
    /// Local key (unique within this request, may start from 1).
    public let key: Int
    public let name: String
    public let teacherName1: String
    public let teacherName2: String

    public init(key: Int, name: String, teacherName1: String, teacherName2: String) {
        self.key = key
        self.name = name
        self.teacherName1 = teacherName1
        self.teacherName2 = teacherName2
    }

    enum CodingKeys: String, CodingKey {
        case key, name
        case teacherName1 = "teachername1"
        case teacherName2 = "teachername2"
    }
}

/// A student definition inside a `createmarkbook` payload.
public struct NewMarkbookStudent: Codable, Sendable {
    /// Local key (unique within this request, may start from 1).
    public let key: Int
    /// Must be non-empty; used as the student's permanent identifier.
    public let studentID: String
    public let familyName: String
    public let givenName: String
    public let preferredName: String
    /// Must match a `key` in the accompanying `classList`.
    public let classKey: Int
    /// Human-readable class name. Not validated by the API; `classKey` is authoritative.
    public let className: String

    public init(
        key: Int,
        studentID: String,
        familyName: String,
        givenName: String,
        preferredName: String,
        classKey: Int,
        className: String
    ) {
        self.key = key
        self.studentID = studentID
        self.familyName = familyName
        self.givenName = givenName
        self.preferredName = preferredName
        self.classKey = classKey
        self.className = className
    }

    enum CodingKeys: String, CodingKey {
        case key
        case studentID     = "studentid"
        case familyName    = "familyname"
        case givenName     = "givename"
        case preferredName = "preferredname"
        case classKey      = "classkey"
        case className     = "classname"
    }
}

public struct CreateMarkbookResponse: Decodable, Sendable {
    public let source: String
    public let api: String
    public let seconds: Int
    public let date: String
    public let schoolName: String
    public let action: APIAction
    public let status: APIStatus
    /// Key of the newly created markbook.
    public let markbookKey: Int
    /// Actual name used (may have a "-1" suffix if the requested name was already taken).
    public let markbookName: String
    public let classCount: Int
    public let studentCount: Int
    public let shareCount: Int

    enum CodingKeys: String, CodingKey {
        case source, api, seconds, date, action, status
        case schoolName   = "schoolname"
        case markbookKey  = "markbookkey"
        case markbookName = "markbookname"
        case classCount   = "classcount"
        case studentCount = "studentcount"
        case shareCount   = "sharecount"
    }
}

// MARK: - Internal: Authentication
// These types are used exclusively inside MarkbookAPIClient and are not part of
// the public API surface. Consumers never construct or inspect them directly.

struct AuthenticationResponse: Decodable {
    let source: String
    let api: String
    let seconds: Int
    let date: String
    let schoolName: String
    let action: APIAction
    let status: APIStatus
    let sessionToken: String
    let sessionKey: Int

    enum CodingKeys: String, CodingKey {
        case source, api, seconds, date, action, status
        case schoolName   = "schoolname"
        case sessionToken = "sessiontoken"
        case sessionKey   = "sessionkey"
    }
}

/// Bundles the session credentials needed for every API call after authentication.
struct SessionCredentials {
    let sessionToken: String
    let sessionKey: Int
    let apiKey: String
}