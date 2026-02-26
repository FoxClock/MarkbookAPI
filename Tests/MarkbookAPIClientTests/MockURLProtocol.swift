// MockURLProtocol.swift
// MarkbookAPITests

import Foundation

/// A `URLProtocol` subclass that intercepts all network requests during tests.
///
/// Configure `requestHandlers` with an ordered queue of closures before making
/// API calls. Each call to `startLoading` pops the next handler from the front
/// of the queue, allowing multi-step flows (e.g. authentication then data fetch)
/// to be driven in sequence without any real network activity.
///
/// Usage:
/// ```swift
/// MockURLProtocol.enqueue { request in
///     (Fixtures.httpResponse(for: request.url!), Fixtures.data(for: Fixtures.authenticationSuccess))
/// }
/// MockURLProtocol.enqueue { request in
///     (Fixtures.httpResponse(for: request.url!), Fixtures.data(for: Fixtures.markbookList))
/// }
/// ```
final class MockURLProtocol: URLProtocol {

    // MARK: - Queue

    typealias RequestHandler = (URLRequest) throws -> (HTTPURLResponse, Data)

    private static let lock = NSLock()
    private static var _handlers: [RequestHandler] = []

    /// All requests that have been intercepted, in order. Useful for asserting
    /// that the correct URLs and HTTP methods were used.
    private(set) static var capturedRequests: [URLRequest] = []

    /// Appends a handler to the back of the response queue.
    static func enqueue(_ handler: @escaping RequestHandler) {
        lock.withLock { _handlers.append(handler) }
    }

    /// Removes all queued handlers and clears captured requests.
    /// Call this in `tearDown` to keep tests isolated.
    static func reset() {
        lock.withLock {
            _handlers.removeAll()
            capturedRequests.removeAll()
        }
    }

    /// Convenience: enqueue a fixed successful response for any request.
    static func enqueue(data: Data, statusCode: Int = 200, url: URL? = nil) {
        enqueue { request in
            let responseURL = url ?? request.url ?? URL(string: "https://example.com")!
            return (Fixtures.httpResponse(for: responseURL, statusCode: statusCode), data)
        }
    }

    /// Convenience: enqueue a fixture string as a successful response.
    static func enqueue(fixture: String, statusCode: Int = 200) {
        enqueue(data: Fixtures.data(for: fixture), statusCode: statusCode)
    }

    // MARK: - URLProtocol

    override class func canInit(with request: URLRequest) -> Bool { true }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        var handler: RequestHandler?
        MockURLProtocol.lock.withLock {
            guard !MockURLProtocol._handlers.isEmpty else { return }
            handler = MockURLProtocol._handlers.removeFirst()
            MockURLProtocol.capturedRequests.append(request)
        }

        guard let handler else {
            client?.urlProtocol(
                self,
                didFailWithError: MockURLProtocolError.noHandlerQueued(request.url?.absoluteString ?? "unknown")
            )
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

// MARK: - Errors

enum MockURLProtocolError: Error, LocalizedError {
    case noHandlerQueued(String)

    var errorDescription: String? {
        switch self {
        case .noHandlerQueued(let url):
            return "MockURLProtocol: no handler queued for request to \(url)"
        }
    }
}

// MARK: - URLSession Factory

extension URLSession {
    /// Creates a `URLSession` that routes all requests through `MockURLProtocol`.
    static func makeMockSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        // Disable caching to ensure fixture data is always used.
        config.urlCache = nil
        return URLSession(configuration: config)
    }
}
