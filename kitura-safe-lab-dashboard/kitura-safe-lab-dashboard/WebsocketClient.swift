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
    func clientReceivedRegistrationID(client: DisasterSocketClient, id: String)
}

enum DisasterSocketError: Error {
    case badConnection
}

class DisasterSocketClient: WebSocketDelegate {
    weak var delegate: DisasterSocketClientDelegate?
    var address: String
    var id: String?
    public var disasterSocket: WebSocket?
    
    init(address: String) {
        self.address = address
    }
    
    func websocketDidConnect(socket: WebSocketClient) {
        delegate?.clientConnected(client: self)
    }
    
    func websocketDidDisconnect(socket: WebSocketClient, error: Error?) {
        delegate?.clientDisconnected(client: self)
    }
    
    func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {
        print("websocket message received: \(text)")
        parse(text)
    }
    
    func websocketDidReceiveData(socket: WebSocketClient, data: Data) {
        parse(data)
        print("websocket message received: \(String(describing: String(data: data, encoding: .utf8)))")
    }
    
    private func parse(_ data: Data) {
        if let person = try? JSONDecoder().decode(Person.self, from: data) {
            print("received status of person: \(person.id)")
            delegate?.statusReported(client: self, person: person)
        }
    }
    
    private func parse(_ message: String) {
        let components = message.components(separatedBy: "=")
        if components.first == "ID" {
            guard let id = components.last else {
                return
            }
            delegate?.clientReceivedRegistrationID(client: self, id: id)
        }
    }
    
    public func confirm(_ dashboard: Dashboard) {
        self.id = dashboard.dashboardID
        do {
            disasterSocket?.write(data: try JSONEncoder().encode(dashboard))
        } catch let error {
            print("error writing dashboard registration to socket: \(error.localizedDescription)")
        }
    }
    
    public func simulateDisaster(_ disaster: Disaster) {
        do {
            try disasterSocket?.write(data: JSONEncoder().encode(disaster))
        } catch let error {
            delegate?.clientErrorOccurred(client: self, error: error)
        }
    }
    
    public func disconnect() {
        disasterSocket?.disconnect()
    }
    
    public func attemptConnection() {
        guard let url = URL(string: "ws://\(self.address)/disaster") else {
            delegate?.clientErrorOccurred(client: self, error: DisasterSocketError.badConnection)
            return
        }
        let socket = WebSocket(url: url)
        socket.delegate = self
        disasterSocket = socket
        disasterSocket?.connect()
    }
}
