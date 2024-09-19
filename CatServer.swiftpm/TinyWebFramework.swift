// TinyWebFramework.swift
import Foundation

public protocol TinyWebFrameworkProtocol {
    func startServer(host: String, port: Int)
    func stopServer()
    func addRoute(_ path: String, handler: @escaping (HTTPRequest, @escaping (HTTPResponse) -> Void) -> Void)
}

// Ensure HTTPRequest and HTTPResponse are public
public struct HTTPRequest {
    public let method: String
    public let path: String
    public let headers: [String: String]
    public let body: Data
}

public struct HTTPResponse {
    public var statusCode: Int
    public var headers: [String: String]
    public var body: Data
}