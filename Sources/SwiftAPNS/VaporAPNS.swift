import HTTP
import Transport
import Foundation
import SwiftString
import JSON
import Vapor
import TLS
import hpack

public class VaporAPNS {
    private var options: Options
    fileprivate var apnsAuthKey: String
    
    private var httpClient: Client<TCPClientStream, Serializer<Request>, Parser<Response>>?
    private var sock: TLS.Socket?
    
    public init?(authKeyPath: String, options: Options? = nil) throws {
        self.apnsAuthKey = try authKeyPath.tokenString()
        self.options = options ?? Options()
        try connect()
    }
    
    private func connect() throws {
//        httpClient = try Client<TCPClientStream, Serializer<Request>, Parser<Response>>.init(scheme: "https", host: self.hostURL(development: self.options.development), port: self.options.port.rawValue, securityLayer: .tls(nil))
        sock = try TLS.Socket(mode: .client, hostname: self.hostURL(development: self.options.development), port: UInt16(self.options.port.rawValue))
        try sock?.connect(servername: self.hostURL(development: self.options.development))
//        let t = try sock.receive()
//        print (t)
    }
    
    public func send(applePushMessage message: ApplePushMessage) -> Result {
        do {
            let headers = self.requestHeaders(for: message)
            let headerBytes = Encoder().encode(headers)
            try sock?.send(headerBytes)
            let line = try sock?.receiveLine()
            print (line)
//            let response = try httpClient.post(path: "/3/device/\(message.deviceToken)", headers: headers)
//            print (response.json)
            return Result.success(apnsId: message.messageId, serviceStatus: .success)
        } catch {
            return Result.networkError(apnsId: message.messageId, error: error)
        }
    }
   
    private func requestHeaders(for message: ApplePushMessage) -> [Header] {
        var headers: [String : String] = [
            "authorization": "bearer \(apnsAuthKey)",
            "apns-id": message.messageId,
            "apns-expiration": "\(message.expirationDate?.timeIntervalSince1970.rounded() ?? 0)",
            "apns-priority": "\(message.priority.rawValue)",
            "apns-topic": message.topic
        ]

        if let collapseId = message.collapseIdentifier {
            headers["apns-collapse-id"] = collapseId
        }
        
        if let threadId = message.threadIdentifier {
            headers["thread-id"] = threadId
        }
        
        var headerss: [Header] = []
        for (key, value) in headers {
            headerss.append((key, value))
        }
        print (headerss)
        print (headerss)
        print (headerss)
        print (headerss)

        return headerss
    
    }
}

extension VaporAPNS {
    fileprivate func hostURL(development: Bool) -> String {
        if development {
            return "api.development.push.apple.com" //   "
        } else {
            return "api.push.apple.com" //   /3/device/"
        }
    }
}
