import NIO
import NIOHTTP1
import Foundation
import NIOFoundationCompat

struct HTTPRequest {
    let head: HTTPRequestHead
    let body: Data
}

class TinyWebFramework {
    let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
    var channel: Channel?
    var routes: [String: (ChannelHandlerContext, HTTPRequest) -> Void] = [:]

    func startServer(host: String = "127.0.0.1", port: Int = 8080) {
        let bootstrap = ServerBootstrap(group: group)
            .serverChannelOption(ChannelOptions.backlog, value: 256)
            .serverChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            .childChannelInitializer { channel in
                channel.pipeline.configureHTTPServerPipeline().flatMap {
                    channel.pipeline.addHandler(HTTPHandler(routes: self.routes))
                }
            }
            .childChannelOption(ChannelOptions.socket(IPPROTO_TCP, TCP_NODELAY), value: 1)
            .childChannelOption(ChannelOptions.maxMessagesPerRead, value: 1)
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

    func addRoute(_ path: String, handler: @escaping (ChannelHandlerContext, HTTPRequest) -> Void) {
        routes[path] = handler
    }
}

final class HTTPHandler: ChannelInboundHandler {
    typealias InboundIn = HTTPServerRequestPart

    private let routes: [String: (ChannelHandlerContext, HTTPRequest) -> Void]
    private var requestHead: HTTPRequestHead?
    private var bodyBuffer: ByteBuffer?

    init(routes: [String: (ChannelHandlerContext, HTTPRequest) -> Void]) {
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
            let request = HTTPRequest(head: requestHead, body: bodyData)

            if let handler = routes[requestHead.uri] {
                handler(context, request)
            } else {
                sendNotFound(context: context, version: requestHead.version)
            }
            self.requestHead = nil
            self.bodyBuffer = nil
        }
    }

    func sendNotFound(context: ChannelHandlerContext, version: HTTPVersion) {
        let headers = HTTPHeaders([("content-type", "text/html; charset=utf-8")])
        let responseHead = HTTPResponseHead(version: version, status: .notFound, headers: headers)
        context.write(NIOAny(HTTPServerResponsePart.head(responseHead)), promise: nil)

        var buffer = context.channel.allocator.buffer(capacity: 0)
        buffer.writeString("<h1>404 Not Found</h1>")
        context.write(NIOAny(HTTPServerResponsePart.body(.byteBuffer(buffer))), promise: nil)

        context.writeAndFlush(NIOAny(HTTPServerResponsePart.end(nil))).whenComplete { _ in
            context.close(promise: nil)
        }
    }

    func errorCaught(context: ChannelHandlerContext, error: Error) {
        print("Error: \(error)")
        context.close(promise: nil)
    }
}
