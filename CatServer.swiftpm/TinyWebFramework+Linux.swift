// TinyWebFramework+Linux.swift
#if os(Linux)
import Foundation
import NIO
import NIOHTTP1

class TinyWebFramework: TinyWebFrameworkProtocol {
    private let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
    private var channel: Channel?
    private var routes: [String: (HTTPRequest, @escaping (HTTPResponse) -> Void) -> Void] = [:]
    
    func startServer(host: String = "127.0.0.1", port: Int = 8080) {
        let bootstrap = ServerBootstrap(group: group)
            .serverChannelOption(ChannelOptions.backlog, value: 256)
            .childChannelInitializer { channel in
                channel.pipeline.configureHTTPServerPipeline().flatMap {
                    channel.pipeline.addHandler(HTTPHandler(routes: self.routes))
                }
            }
            .serverChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            .childChannelOption(ChannelOptions.socket(IPPROTO_TCP, TCP_NODELAY), value: 1)
            .childChannelOption(ChannelOptions.recvAllocator, value: AdaptiveRecvByteBufferAllocator())
        
        do {
            channel = try bootstrap.bind(host: host, port: port).wait()
            print("Server started and listening on \(channel!.localAddress!)")
        } catch {
            print("Failed to start server: \(error)")
        }
    }
    
    func stopServer() {
        try? channel?.close().wait()
        try? group.syncShutdownGracefully()
        print("Server stopped.")
    }
    
    func addRoute(_ path: String, handler: @escaping (HTTPRequest, @escaping (HTTPResponse) -> Void) -> Void) {
        routes[path] = handler
    }
    
    final class HTTPHandler: ChannelInboundHandler {
        typealias InboundIn = HTTPServerRequestPart
        
        private let routes: [String: (HTTPRequest, @escaping (HTTPResponse) -> Void) -> Void]
        private var requestHead: HTTPRequestHead?
        private var bodyBuffer: ByteBuffer?
        
        init(routes: [String: (HTTPRequest, @escaping (HTTPResponse) -> Void) -> Void]) {
            self.routes = routes
        }
        
        func channelRead(context: ChannelHandlerContext, data: NIOAny) {
            let reqPart = unwrapInboundIn(data)
            
            switch reqPart {
            case .head(let head):
                requestHead = head
                bodyBuffer = context.channel.allocator.buffer(capacity: 0)
            case .body(var body):
                bodyBuffer?.writeBuffer(&body)
            case .end:
                guard let requestHead = requestHead else {
                    context.close(promise: nil)
                    return
                }
                let readableBytes = bodyBuffer?.readableBytes ?? 0
                let bodyData: Data
                if let bodyBuffer = bodyBuffer, readableBytes > 0 {
                    bodyData = bodyBuffer.getData(at: bodyBuffer.readerIndex, length: readableBytes) ?? Data()
                } else {
                    bodyData = Data()
                }
                var headersDict = [String: String]()
                for header in requestHead.headers {
                    headersDict[header.name] = header.value
                }
                let request = HTTPRequest(
                    method: requestHead.method.rawValue,
                    path: requestHead.uri,
                    headers: headersDict,
                    body: bodyData
                )
                
                if let handler = routes[requestHead.uri] {
                    handler(request) { response in
                        self.sendResponse(context: context, response: response, version: requestHead.version)
                    }
                } else {
                    self.sendNotFound(context: context, version: requestHead.version)
                }
                self.requestHead = nil
                self.bodyBuffer = nil
            }
        }
        
        func sendResponse(context: ChannelHandlerContext, response: HTTPResponse, version: HTTPVersion) {
            var headers = HTTPHeaders()
            for (name, value) in response.headers {
                headers.add(name: name, value: value)
            }
            headers.add(name: "Content-Length", value: "\(response.body.count)")
            let responseHead = HTTPResponseHead(version: version, status: HTTPResponseStatus(statusCode: response.statusCode), headers: headers)
            context.write(NIOAny(HTTPServerResponsePart.head(responseHead)), promise: nil)
            
            var buffer = context.channel.allocator.buffer(capacity: response.body.count)
            buffer.writeBytes(response.body)
            context.write(NIOAny(HTTPServerResponsePart.body(.byteBuffer(buffer))), promise: nil)
            
            context.writeAndFlush(NIOAny(HTTPServerResponsePart.end(nil))).whenComplete { _ in
                context.close(promise: nil)
            }
        }
        
        func sendNotFound(context: ChannelHandlerContext, version: HTTPVersion) {
            let response = HTTPResponse(
                statusCode: 404,
                headers: ["Content-Type": "text/html; charset=utf-8"],
                body: "<h1>404 Not Found</h1>".data(using: .utf8) ?? Data()
            )
            sendResponse(context: context, response: response, version: version)
        }
        
        func errorCaught(context: ChannelHandlerContext, error: Error) {
            print("Error: \(error)")
            context.close(promise: nil)
        }
    }
}
#endif
