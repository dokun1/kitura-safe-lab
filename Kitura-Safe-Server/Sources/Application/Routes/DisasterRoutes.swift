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

func initializeDisasterService(app: App) {
    WebSocket.register(service: DisasterSocketService(), onPath: "/disaster")
}
