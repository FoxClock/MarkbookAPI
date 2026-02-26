# MarkbookAPI

A Swift library for interacting with the [Markbook Online](https://smpcsonline.com.au/markbook) REST API (v1.5). The library provides a fully typed, async/await client with automatic session management, structured error handling, and a protocol-based design for easy testing.

---

## Requirements

| Requirement | Minimum Version |
|---|---|
| Swift | 5.9 |
| iOS | 16.0 |
| macOS | 13.0 |
| Xcode | 15.0 |

---

## Installation

### Swift Package Manager

Add the package to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/foxclock/MarkbookAPI.git", from: "1.0.0")
]
```

Then add `MarkbookAPI` as a dependency of your target:

```swift
.target(
    name: "YourApp",
    dependencies: ["MarkbookAPI"]
)
```

### Xcode

1. Open your project in Xcode.
2. Go to **File → Add Package Dependencies…**
3. Enter the repository URL and select the version you want.
4. Add `SMMarksApi` to your app target.

---

## Getting Started

### Prerequisites

To use this library you will need:

- A **Markbook Online API key** — a 32-character school-specific string. A user with *Allow user administration* permission can find this under **Other administration actions → Show API Key** in the Markbook Online interface.
- The **login name and password** of a Markbook Online user who has *Allow user administration* permission. This user is used exclusively to establish API sessions and is never exposed outside the client.

### Creating a Client

```swift
import SMMarksApi

let client = MarkbookAPIClient(
    apiKey: "YOUR_32_CHARACTER_API_KEY",
    username: "adminloginname",
    password: "adminpassword"
)
```

The client is an `actor`, so it is safe to create once and share across your application. Authentication is performed automatically on the first call and transparently renewed before the session expires.

---

## Usage

All methods are `async throws` and must be called from an asynchronous context.

### Fetching Markbooks

```swift
// List all markbooks in the school
let response = try await client.markbookList()
for markbook in response.list {
    print("\(markbook.key): \(markbook.name) — \(markbook.course)")
}
```

### Fetching Users

```swift
let response = try await client.userList()
for user in response.list {
    print("\(user.key): \(user.name) <\(user.email)>")
}
```

### Reading a Markbook

The library provides two formats for reading markbook data.

**Standard format** — results are embedded in each student as parallel arrays matching the order of the `taskList`:

```swift
let markbook = try await client.getMarkbook(key: 1000001)

for student in markbook.studentList {
    print("\(student.familyName), \(student.givenName)")
    for (task, result) in zip(markbook.taskList, student.roundedResults) {
        print("  \(task.name): \(result) / \(task.maximum)")
    }
}
```

**Alternate format** — results are returned as a flat list with explicit student and task keys. This can be more convenient when building lookup tables or updating results selectively:

```swift
let markbook = try await client.getMarkbookAlt(key: 1000001)

// Build a lookup: [studentKey: [taskKey: roundedResult]]
let lookup = Dictionary(
    grouping: markbook.resultList,
    by: \.studentKey
).mapValues {
    Dictionary(uniqueKeysWithValues: $0.map { ($0.taskKey, $0.roundedResult) })
}
```

### Reading Outcomes

```swift
// Standard format — outcome levels are arrays on each student
let outcomes = try await client.getOutcomes(key: 1000001)

for student in outcomes.studentList {
    for (outcome, level) in zip(outcomes.outcomeList, student.outcomeLevels) {
        print("\(student.familyName) — \(outcome.name): \(level)")
    }
}

// Alternate format — flat list with explicit student and outcome keys
let outcomesAlt = try await client.getOutcomesAlt(key: 1000001)
```

### Updating a Student Result

```swift
try await client.putStudentResult(
    markbookKey: 1000001,
    studentKey: 89,
    sid: "80822649",
    taskKey: 4,
    taskName: "Assignment 3",
    result: "21"
)
```

> **Note:** `studentKey`, `sid`, `taskKey`, and `taskName` must come from a prior call to `getMarkbook(key:)` or `getMarkbookAlt(key:)`.

### Creating a Student

```swift
let response = try await client.createStudent(
    markbookKey: 1000001,
    sid: "99999",
    familyName: "Lee",
    givenName: "Susannah",
    preferredName: "Sue",
    gender: .female,
    classKey: 7
)
print("New student key: \(response.studentKey)")
```

### Updating a Student

All name fields must be included even if they are unchanged. The `sid` is used to identify the student and cannot itself be updated.

```swift
try await client.updateStudent(
    markbookKey: 1000001,
    studentKey: 170,
    sid: "99999",
    familyName: "Lee",
    givenName: "Susannah",
    preferredName: "Susan",   // Updated preferred name
    gender: .female
)
```

### Moving a Student to a Different Class

```swift
try await client.updateStudentClass(
    markbookKey: 1000001,
    studentKey: 170,
    sid: "99999",
    classKey: 5
)
```

> **Tip:** Calling `updateStudentClass` on a deleted student is how you restore them. Deleted students remain in the database and can be undeleted this way.

### Deleting a Student

This is a soft delete. The student remains in the database and can be restored using `updateStudentClass`.

```swift
try await client.deleteStudent(
    markbookKey: 1000001,
    studentKey: 170,
    sid: "99999"
)
```

### Creating a Class

The class name must be unique within the markbook.

```swift
let response = try await client.createClass(
    markbookKey: 1000001,
    name: "9ENG1",
    teacherFamilyName: "Thackeray",
    teacherGivenName: "Mark"
)
print("New class key: \(response.classKey)")
```

### Creating a Markbook

Creating a markbook uses the POST endpoint and takes a `CreateMarkbookRequest`. Class and student keys within the request are local — they exist only to link students to classes inside the payload and can start from `1`.

```swift
let request = CreateMarkbookRequest(
    api: "https://smpcsonline.com.au/markbook/api/v1.5",
    schoolName: "your school name",
    action: .createMarkbook,
    markbookName: "2024 Y9 Science",
    markbookYear: "Year 9",
    markbookCourse: "Science",
    ownerKey: 13,       // Must match a key from userList()
    shareList: [13, 24], // Must match keys from userList()
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

let response = try await client.createMarkbook(request)
print("Created markbook key: \(response.markbookKey), name: \(response.markbookName)")
// Note: if the name was already taken, the API appends "-1" (or "-2", etc.)
```

### Scheduling and Downloading a Backup

Backups are a two-step, two-day process. The backup is created overnight at approximately 1 AM.

**Day 1 — schedule the backup:**

```swift
// The `matching` string filters markbooks by name substring.
// It must be at least 2 characters.
try await client.scheduleBackup(matching: "2024")
```

**Day 2 — retrieve the download URL:**

```swift
let response = try await client.getBackupURL()

switch response.status {
case .okay:
    print("Download URL: \(response.url)")
    // Download promptly — the zip is deleted approximately one hour after this call.
case .errorPending:
    print("Backup not yet ready. Try again tomorrow.")
case .errorNoBackup:
    print("No backup has been scheduled.")
default:
    print("Unexpected status: \(response.status)")
}
```

> **Note:** Only one backup can be scheduled per day. A second call to `scheduleBackup` replaces the previous one. The zip file timestamp is UTC.

---

## Error Handling

All methods throw `MarkbookAPIError`. Handle it with a `do/catch` block:

```swift
do {
    let markbooks = try await client.markbookList()
    // use markbooks
} catch MarkbookAPIError.httpError(let statusCode) {
    print("Network error — HTTP \(statusCode)")
} catch MarkbookAPIError.apiError(let status) {
    print("API rejected the request with status: \(status)")
} catch MarkbookAPIError.authenticationFailed(let underlying) {
    print("Could not authenticate: \(underlying.localizedDescription)")
} catch MarkbookAPIError.invalidBackupMatchingParameter {
    print("The matching string must be at least 2 characters")
} catch {
    print("Unexpected error: \(error)")
}
```

### Error Cases

| Case | Description |
|---|---|
| `.httpError(statusCode:)` | The server returned a non-2xx HTTP status code. |
| `.apiError(APIStatus)` | The request succeeded but the API returned a non-`OKAY` status in the response body. |
| `.invalidURL` | A valid URL could not be constructed from the supplied parameters. |
| `.invalidBackupMatchingParameter` | The `matching` string passed to `scheduleBackup` was fewer than 2 characters. |
| `.authenticationFailed(underlying:)` | Session authentication or renewal failed. The underlying error provides more detail. |

---

## Session Management

Authentication is handled entirely by the client. You do not need to manage tokens manually.

- On the first API call, the client authenticates using the supplied username and password and caches the session token and key.
- Sessions are valid for 20 minutes per the API specification. The client proactively refreshes the session after 19 minutes to avoid race conditions at the boundary.
- If a refresh fails, a `MarkbookAPIError.authenticationFailed` error is thrown.

---

## Testing

`MarkbookAPIClient` conforms to `MarkbookAPIClientProtocol`. Inject a mock in your tests to avoid real network calls:

```swift
import MarkbookAPI

final class MockMarkbookAPIClient: MarkbookAPIClientProtocol {

    var stubbedMarkbookList: MarkbookListResponse?

    func markbookList() async throws -> MarkbookListResponse {
        guard let stub = stubbedMarkbookList else {
            throw MarkbookAPIError.apiError(.error("Not stubbed"))
        }
        return stub
    }

    // Implement remaining protocol methods as needed...
}

// In your test:
func testMarkbookListDisplaysResults() async throws {
    let mock = MockMarkbookAPIClient()
    mock.stubbedMarkbookList = MarkbookListResponse(/* ... */)

    let viewModel = MarkbookListViewModel(client: mock)
    try await viewModel.load()

    XCTAssertEqual(viewModel.markbooks.count, 1)
}
```

You can also inject a custom `URLSession` configured with `URLProtocol` stubs when you want to test the real client against fixture data at the network layer.

---

## File Structure

```
Sources/MarkbookAPI/
├── Models.swift            # All Codable request and response types
└── MarkbookAPIClient.swift # Actor client, protocol, and error types
```

---

## API Reference

For the full upstream API specification, refer to the official Markbook Online documentation:
**https://smpcsonline.com.au/markbook/api/v1.5**

The authentication test form is available at:
**https://smpcsonline.com.au/markbook/api/v1.5/authenticate.html**

The POST method test form is available at:
**https://smpcsonline.com.au/markbook/api/v1.5/post.html**

---

## License

Distributed under the MIT License. See `LICENSE` for details.