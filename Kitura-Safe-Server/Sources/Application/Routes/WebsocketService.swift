//
//  WebsocketService.swift
//  Application
//
//  Created by David Okun on 5/30/19.
//

import Foundation
import KituraWebSocket
import LoggerAPI

class DisasterSocketService: WebSocketService {
    func connected(connection: WebSocketConnection) {
        Log.info("connection established: \(connection)")
        allConnections.append(connection)
        connection.send(message: "ID=\(connection.id)")
    }
    
    func disconnected(connection: WebSocketConnection, reason: WebSocketCloseReasonCode) {
        //allConnections.removeAll { $0.id == connection.id }
        Log.info("Connection dropped for \(connection.id), reason: \(reason)")
    }
    
    func received(message: Data, from: WebSocketConnection) {
        Log.info("data message received: \(String(describing: String(data: message, encoding: .utf8)))")
        do {
            guard let person = try? JSONDecoder().decode(Person.self, from: message) else {
                return
            }
            connectedPeople.append(person)
            guard let dashboardID = dashboardConnection else {
                return
            }
            let connections = allConnections.filter { $0.id == dashboardID}
            for connection in connections {
                connection.send(message: message)
            }
        }
    }
    
    func received(message: String, from: WebSocketConnection) {
        parse(message, for: from)
        Log.info("string message received: \(message)")
    }
    
    
    
    private func parse(_ message: String, for connection: WebSocketConnection) {
        let components = message.components(separatedBy: "=")
        if components.first == "CONFIRMDASHBOARD" {
            guard let id = components.last else {
                return
            }
            dashboardConnection = id
        }
    }
    
    private var allConnections = [WebSocketConnection]()
    private var dashboardConnection: String?
    private var connectedPeople = [Person]()
}
