// Fixtures.swift
// MarkbookAPITests

import Foundation

/// Static JSON fixture strings mirroring the real API response shapes.
/// Each fixture is valid JSON that can be decoded into the corresponding model.
enum Fixtures {

    // MARK: - Authentication

    static let authenticationSuccess = """
    {
        "source": "Markbook Online",
        "api": "https://smpcsonline.com.au/markbook/api/v1.5",
        "seconds": 1718683389,
        "date": "Mon, 14 Jun 2024 12:58:32 +1000",
        "schoolname": "Test School",
        "action": "authentication",
        "status": "OKAY",
        "sessiontoken": "AbCdeFgHiJkLmOp",
        "sessionkey": 987654
    }
    """

    static let authenticationFailure = """
    {
        "source": "Markbook Online",
        "api": "https://smpcsonline.com.au/markbook/api/v1.5",
        "seconds": 1718683389,
        "date": "Mon, 14 Jun 2024 12:58:32 +1000",
        "schoolname": "Test School",
        "action": "authentication",
        "status": "ERROR:invalid credentials",
        "sessiontoken": "",
        "sessionkey": 0
    }
    """

    // MARK: - markbooklist

    static let markbookList = """
    {
        "source": "Markbook Online",
        "api": "https://smpcsonline.com.au/markbook/api/v1.5",
        "seconds": 1718683389,
        "date": "Mon, 14 Jun 2024 12:58:32 +1000",
        "schoolname": "Test School",
        "action": "markbooklist",
        "status": "OKAY",
        "list": [
            {
                "key": 1000001,
                "name": "Sample",
                "owner": "",
                "year": "Year 9",
                "course": "Science"
            },
            {
                "key": 1000002,
                "name": "My Second Markbook",
                "owner": "jsmith",
                "year": "Year 10",
                "course": "Maths"
            }
        ]
    }
    """

    static let markbookListEmpty = """
    {
        "source": "Markbook Online",
        "api": "https://smpcsonline.com.au/markbook/api/v1.5",
        "seconds": 1718683389,
        "date": "Mon, 14 Jun 2024 12:58:32 +1000",
        "schoolname": "Test School",
        "action": "markbooklist",
        "status": "OKAY",
        "list": []
    }
    """

    // MARK: - userlist

    static let userList = """
    {
        "source": "Markbook Online",
        "api": "https://smpcsonline.com.au/markbook/api/v1.5",
        "seconds": 1718683389,
        "date": "Mon, 14 Jun 2024 12:58:32 +1000",
        "schoolname": "Test School",
        "action": "userlist",
        "status": "OKAY",
        "list": [
            {
                "key": 1,
                "name": "John Smith",
                "loginid": "jsmith",
                "email": "jsmith@school.edu.au"
            },
            {
                "key": 2,
                "name": "Jane Doe",
                "loginid": "jdoe",
                "email": "jdoe@school.edu.au"
            }
        ]
    }
    """

    // MARK: - getmarkbook

    static let getMarkbook = """
    {
        "source": "Markbook Online",
        "api": "https://smpcsonline.com.au/markbook/api/v1.5",
        "seconds": 1718683389,
        "date": "Mon, 14 Jun 2024 12:58:32 +1000",
        "schoolname": "Test School",
        "action": "getmarkbook",
        "status": "OKAY",
        "markbookkey": 1000001,
        "markbookname": "Sample",
        "markbookyear": "Year 9",
        "markbookcourse": "Science",
        "ownerkey": 1,
        "sharelist": [1, 2],
        "classlist": [
            {
                "key": 7,
                "name": "9SCI-1",
                "teachername1": "Mr Tom",
                "teachername2": "Reynolds"
            },
            {
                "key": 6,
                "name": "9SCI-2",
                "teachername1": "Mr Henry",
                "teachername2": "Griffith"
            }
        ],
        "tasklist": [
            { "key": 1, "name": "Term 1 Exam", "maximum": 100, "decimalplaces": 0 },
            { "key": 2, "name": "Assignment 1", "maximum": 25, "decimalplaces": 0 },
            { "key": 3, "name": "Assignment 2", "maximum": 25, "decimalplaces": 2 }
        ],
        "studentlist": [
            {
                "key": 2,
                "studentid": "94665837",
                "familyname": "Alexander",
                "givename": "Eddie",
                "preferredname": "Ed",
                "classkey": 6,
                "classname": "9SCI-2",
                "rawresults": ["67.500000", "18", "12.50"],
                "roundedresults": ["68", "18", "13"]
            },
            {
                "key": 89,
                "studentid": "80822649",
                "familyname": "Ameche",
                "givename": "Joan",
                "preferredname": "",
                "classkey": 7,
                "classname": "9SCI-1",
                "rawresults": ["53.000000", "20", "15"],
                "roundedresults": ["53", "20", "15"]
            }
        ]
    }
    """

    // MARK: - getmarkbookalt

    static let getMarkbookAlt = """
    {
        "source": "Markbook Online",
        "api": "https://smpcsonline.com.au/markbook/api/v1.5",
        "seconds": 1718683389,
        "date": "Mon, 14 Jun 2024 12:58:32 +1000",
        "schoolname": "Test School",
        "action": "getmarkbookalt",
        "status": "OKAY",
        "markbookkey": 1000001,
        "markbookname": "Sample",
        "markbookyear": "Year 9",
        "markbookcourse": "Science",
        "ownerkey": 1,
        "sharelist": [],
        "classlist": [
            {
                "key": 7,
                "name": "9SCI-1",
                "teachername1": "Mr Tom",
                "teachername2": "Reynolds"
            }
        ],
        "tasklist": [
            { "key": 1, "name": "Term 1 Exam", "maximum": 100, "decimalplaces": 0 },
            { "key": 2, "name": "Assignment 1", "maximum": 25, "decimalplaces": 0 }
        ],
        "studentlist": [
            {
                "key": 2,
                "studentid": "94665837",
                "familyname": "Alexander",
                "givename": "Eddie",
                "preferredname": "",
                "classkey": 7,
                "classname": "9SCI-1"
            }
        ],
        "resultlist": [
            { "studentkey": 2, "taskkey": 1, "rawresult": "67.500000", "roundedresult": "68" },
            { "studentkey": 2, "taskkey": 2, "rawresult": "18", "roundedresult": "18" }
        ]
    }
    """

    // MARK: - getoutcomes

    static let getOutcomes = """
    {
        "source": "Markbook Online",
        "api": "https://smpcsonline.com.au/markbook/api/v1.5",
        "seconds": 1718683389,
        "date": "Mon, 14 Jun 2024 12:58:32 +1000",
        "schoolname": "Test School",
        "action": "getoutcomes",
        "status": "OKAY",
        "classlist": [
            {
                "key": 5,
                "name": "9SCI-3",
                "teachername1": "Ms Linda",
                "teachername2": "Greene"
            }
        ],
        "outcomelist": [
            {
                "key": 1,
                "code": "SC1",
                "name": "Periodic Table",
                "outcome": "Describe features of atoms using atomic theory.",
                "tasklist": [3, 7]
            },
            {
                "key": 2,
                "code": "",
                "name": "Designs Circuits",
                "outcome": "Designs and constructs electrical circuits.",
                "tasklist": [2, 8]
            }
        ],
        "studentlist": [
            {
                "key": 1,
                "studentid": "94665837",
                "familyname": "Adams",
                "givename": "Wendy",
                "preferredname": "",
                "classkey": 5,
                "classname": "9SCI-3",
                "outcomelevels": ["Sound", "High"]
            }
        ]
    }
    """

    // MARK: - getoutcomesalt

    static let getOutcomesAlt = """
    {
        "source": "Markbook Online",
        "api": "https://smpcsonline.com.au/markbook/api/v1.5",
        "seconds": 1718683389,
        "date": "Mon, 14 Jun 2024 12:58:32 +1000",
        "schoolname": "Test School",
        "action": "getoutcomesalt",
        "status": "OKAY",
        "classlist": [
            {
                "key": 5,
                "name": "9SCI-3",
                "teachername1": "Ms Linda",
                "teachername2": "Greene"
            }
        ],
        "outcomelist": [
            {
                "key": 1,
                "code": "SC1",
                "name": "Periodic Table",
                "outcome": "Describe features of atoms using atomic theory.",
                "tasklist": [3, 7]
            }
        ],
        "studentlist": [
            {
                "key": 1,
                "studentid": "94665837",
                "familyname": "Adams",
                "givename": "Wendy",
                "preferredname": "",
                "classkey": 5,
                "classname": "9SCI-3"
            }
        ],
        "levellist": [
            { "studentkey": 1, "outcomekey": 1, "outcomelevel": "Sound" }
        ]
    }
    """

    // MARK: - Status-only (shared shape)

    static let statusOkay = """
    {
        "source": "Markbook Online",
        "api": "https://smpcsonline.com.au/markbook/api/v1.5",
        "seconds": 1718683389,
        "date": "Mon, 14 Jun 2024 12:58:32 +1000",
        "schoolname": "Test School",
        "action": "putstudentresult",
        "status": "OKAY"
    }
    """

    static let statusError = """
    {
        "source": "Markbook Online",
        "api": "https://smpcsonline.com.au/markbook/api/v1.5",
        "seconds": 1718683389,
        "date": "Mon, 14 Jun 2024 12:58:32 +1000",
        "schoolname": "Test School",
        "action": "putstudentresult",
        "status": "ERROR:invalid student"
    }
    """

    // MARK: - createstudent

    static let createStudent = """
    {
        "source": "Markbook Online",
        "api": "https://smpcsonline.com.au/markbook/api/v1.5",
        "seconds": 1718683389,
        "date": "Mon, 14 Jun 2024 12:58:32 +1000",
        "schoolname": "Test School",
        "action": "createstudent",
        "status": "OKAY",
        "studentkey": 172
    }
    """

    // MARK: - createclass

    static let createClass = """
    {
        "source": "Markbook Online",
        "api": "https://smpcsonline.com.au/markbook/api/v1.5",
        "seconds": 1718683389,
        "date": "Mon, 14 Jun 2024 12:58:32 +1000",
        "schoolname": "Test School",
        "action": "createclass",
        "status": "OKAY",
        "classkey": 3
    }
    """

    // MARK: - getbackupurl

    static let getBackupURLReady = """
    {
        "source": "Markbook Online",
        "api": "https://smpcsonline.com.au/markbook/api/v1.5",
        "seconds": 1718683389,
        "date": "Mon, 14 Jun 2024 12:58:32 +1000",
        "schoolname": "Test School",
        "action": "getbackupurl",
        "status": "OKAY",
        "url": "https://smpcsonline.com.au/markbook/download/school-backup-140323-200PM.zip"
    }
    """

    static let getBackupURLPending = """
    {
        "source": "Markbook Online",
        "api": "https://smpcsonline.com.au/markbook/api/v1.5",
        "seconds": 1718683389,
        "date": "Mon, 14 Jun 2024 12:58:32 +1000",
        "schoolname": "Test School",
        "action": "getbackupurl",
        "status": "ERROR:pending",
        "url": ""
    }
    """

    static let getBackupURLNoBackup = """
    {
        "source": "Markbook Online",
        "api": "https://smpcsonline.com.au/markbook/api/v1.5",
        "seconds": 1718683389,
        "date": "Mon, 14 Jun 2024 12:58:32 +1000",
        "schoolname": "Test School",
        "action": "getbackupurl",
        "status": "ERROR:no backup",
        "url": ""
    }
    """

    // MARK: - createmarkbook

    static let createMarkbook = """
    {
        "source": "Markbook Online",
        "api": "https://smpcsonline.com.au/markbook/api/v1.5",
        "seconds": 1718683389,
        "date": "Mon, 14 Jun 2024 12:58:32 +1000",
        "schoolname": "Test School",
        "action": "createmarkbook",
        "status": "OKAY",
        "markbookkey": 1034973,
        "markbookname": "2024 Y9 Science",
        "classcount": 1,
        "studentcount": 2,
        "sharecount": 2
    }
    """

    static let createMarkbookDuplicateName = """
    {
        "source": "Markbook Online",
        "api": "https://smpcsonline.com.au/markbook/api/v1.5",
        "seconds": 1718683389,
        "date": "Mon, 14 Jun 2024 12:58:32 +1000",
        "schoolname": "Test School",
        "action": "createmarkbook",
        "status": "OKAY",
        "markbookkey": 1034974,
        "markbookname": "2024 Y9 Science-1",
        "classcount": 1,
        "studentcount": 2,
        "sharecount": 2
    }
    """

    // MARK: - Helpers

    /// Converts a fixture string into UTF-8 `Data`, force-unwrapping for test convenience.
    static func data(for fixture: String) -> Data {
        Data(fixture.utf8)
    }

    /// Builds a successful HTTP 200 response for use with `MockURLProtocol`.
    static func httpResponse(
        for url: URL,
        statusCode: Int = 200
    ) -> HTTPURLResponse {
        HTTPURLResponse(
            url: url,
            statusCode: statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"]
        )!
    }
}
