//
//  WebsocketClient.swift
//  kitura-safe-lab-dashboard
//
//  Created by David Okun on 5/30/19.
//  Copyright © 2019 David Okun. All rights reserved.
//

import Foundation
import Starscream

protocol DisasterSocketClientDelegate: class {
    func statusReported(client: DisasterSocketClient, person: Person)
    func clientConnected(client: DisasterSocketClient)
    func clientDisconnected(client: DisasterSocketClient)
    func clientErrorOccurred(client: DisasterSocketClient, error: Error)
}

enum DisasterSocketError: Error {
    case badConnection
}

class DisasterSocketClient: WebSocketDelegate, WebSocketAdvancedDelegate {
    func websocketDidConnect(socket: WebSocket) {
                print("")
    }
    
    func websocketDidDisconnect(socket: WebSocket, error: Error?) {
                print("")
    }
    
    func websocketDidReceiveMessage(socket: WebSocket, text: String, response: WebSocket.WSResponse) {
                print("")
    }
    
    func websocketDidReceiveData(socket: WebSocket, data: Data, response: WebSocket.WSResponse) {
                print("")
    }
    
    func websocketHttpUpgrade(socket: WebSocket, request: String) {
        print("")
    }
    
    func websocketHttpUpgrade(socket: WebSocket, response: String) {
        print("")
    }
    
    func websocketDidConnect(socket: WebSocketClient) {
        delegate?.clientConnected(client: self)
    }
    
    func websocketDidDisconnect(socket: WebSocketClient, error: Error?) {
        delegate?.clientDisconnected(client: self)
    }
    
    func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {
        print("websocket message received: \(text)")
    }
    
    func websocketDidReceiveData(socket: WebSocketClient, data: Data) {
        print("websocket message received: \(String(describing: String(data: data, encoding: .utf8)))")
    }
    
    weak var delegate: DisasterSocketClientDelegate?
    var address: String
    public var disasterSocket: WebSocket?
    
    init(address: String) {
        self.address = address
    }
    
    public func attemptConnection() {
        guard let url = URL(string: "ws://\(self.address)/disaster") else {
            delegate?.clientErrorOccurred(client: self, error: DisasterSocketError.badConnection)
            return
        }
        let socket = WebSocket(url: url)
        socket.delegate = self
        socket.advancedDelegate = self
        socket.disableSSLCertValidation = true
        disasterSocket = socket
        disasterSocket?.connect()
    }
}
