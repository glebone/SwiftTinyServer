// TinyWebFramework.swift
import Foundation

protocol TinyWebFrameworkProtocol {
    func startServer(host: String, port: Int)
    func stopServer()
    func addRoute(_ path: String, handler: @escaping (HTTPRequest, @escaping (HTTPResponse) -> Void) -> Void)
}

struct HTTPRequest {
    let method: String
    let path: String
    let headers: [String: String]
    let body: Data
}

struct HTTPResponse {
    var statusCode: Int
    var headers: [String: String]
    var body: Data
}
