//
//  WebsocketService.swift
//  Application
//
//  Created by David Okun on 5/30/19.
//

import Foundation
import KituraWebSocket
import LoggerAPI

extension WebSocketConnection: Equatable {
    public static func == (lhs: WebSocketConnection, rhs: WebSocketConnection) -> Bool {
        return lhs.id == rhs.id
    }
}

class DisasterSocketService: WebSocketService {
    private var allConnections = [WebSocketConnection]()
    private var dashboardConnection: Dashboard?
    private var connectedPeople = [Person]()
    
    public func getAllConnections() -> [Person]? {
        
        return connectedPeople
        
    }
    
    public func getSafeConnections() -> Double? {
        
        var percentNumber = 100/Double(connectedPeople.count)
        var safeNumber = 0.00
        for person in connectedPeople {
            
            safeNumber = 0
            if person.status.rawValue == "safe" {
                safeNumber += 1
            }
        
        }
        
        var percentageSafe = percentNumber*safeNumber
        return percentageSafe
        
    }
    
    func connected(connection: WebSocketConnection) {
        Log.info("connection established: \(connection)")
        allConnections.append(connection)
        do {
            connection.send(message: try JSONEncoder().encode(RegistrationToken(tokenID: connection.id)))
        } catch let error {
            Log.error("Could not send registration token to connection \(connection.id): \(error.localizedDescription)")
        }
    }
    
    func disconnected(connection: WebSocketConnection, reason: WebSocketCloseReasonCode) {
        Log.info("Connection dropped for \(connection.id), reason: \(reason)")
        if connection.id == dashboardConnection?.dashboardID {
            dashboardConnection = nil
        }
        connectedPeople = connectedPeople.filter { $0.id != connection.id }
        allConnections = allConnections.filter { $0 != connection }
    }
    
    
    func received(message: Data, from: WebSocketConnection) {
        Log.info("data message received: \(String(describing: String(data: message, encoding: .utf8)))")
        parse(message, for: from)
    }
    
    func received(message: String, from: WebSocketConnection) {
        Log.info("string message received: \(message)")
    }
    
    private func parse(_ data: Data, for connection: WebSocketConnection) {
        if let person = try? JSONDecoder().decode(Person.self, from: data) {
            Log.info("person status reported: \(person.name) is \(person.status.rawValue)")
            reportStatus(for: person)
        } else if let disaster = try? JSONDecoder().decode(Disaster.self, from: data) {
            Log.info("disaster occurred! \(disaster.name) at (\(disaster.coordinate.latitude), \(disaster.coordinate.longitude))")
            notifyDevices(of: disaster)
        } else if let dashboard = try? JSONDecoder().decode(Dashboard.self, from: data) {
            Log.info("dashboard registered with id: \(dashboard.dashboardID)")
            self.dashboardConnection = dashboard
        }
    }
    
    private func reportStatus(for person: Person) {
        connectedPeople = connectedPeople.filter { $0.id != person.id }
        connectedPeople.append(person)
        guard let dashboard = dashboardConnection else {
            return Log.error("dashboard is not currently registered with server")
        }
        let dashboardConnection = allConnections.filter { $0.id == dashboard.dashboardID }.first
        do {
            dashboardConnection?.send(message: try JSONEncoder().encode(person))
        } catch let error {
            Log.error("encountered error reporting status for person \(person.id): \(error.localizedDescription)")
        }
    }
    
    private func notifyDevices(of disaster: Disaster) {
        guard let dashboardConnection = dashboardConnection else {
            return Log.error("no registered dashboard connection")
        }
        let connectedDevices = allConnections.filter { $0.id != dashboardConnection.dashboardID }
        for device in connectedDevices {
            do {
                device.send(message: try JSONEncoder().encode(disaster))
            } catch let error {
                Log.error("Encountered error reporting disaster to device \(device.id): \(error.localizedDescription)")
            }
        }
    }
}
