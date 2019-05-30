//
//  DisasterRoutes.swift
//  Application
//
//  Created by David Okun on 5/30/19.
//

import Foundation
import LoggerAPI
import KituraContracts
import KituraWebSocket

func initializeDisasterRoutes(app: App) {
    app.router.get("/connections", handler: getConnections)
    WebSocket.register(service: DisasterSocketService(), onPath: "/disaster")
}

func getConnections(completion: @escaping ([Person]?, RequestError?) -> Void) {
    return completion(nil, nil)
}
