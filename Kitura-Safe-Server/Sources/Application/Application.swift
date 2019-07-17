import Foundation
import Kitura
import LoggerAPI
import Configuration
import CloudEnvironment
import KituraContracts
import Health
import KituraOpenAPI
import KituraWebSocket

public let projectPath = ConfigurationManager.BasePath.project.path
public let health = Health()

public class App {
    weak var delegate: WebSocketService?
    let router = Router()
    let cloudEnv = CloudEnv()
    let disasterService = DisasterSocketService()

    public init() throws {
        // Run the metrics initializer
        initializeMetrics(router: router)
    }

    func postInit() throws {
        // Endpoints
        initializeHealthRoutes(app: self)
        KituraOpenAPI.addEndpoints(to: router)
        WebSocket.register(service: disasterService, onPath: "/disaster")
        router.get("/all", handler: getAllHandler)
        router.get("/safe", handler: percentageSafeHandler)
        router.get("/danger", handler: percentageDangerHandler)
        router.get("/unknown", handler: percentageUnknownHandler)
    }
    
    func getAllHandler(completion: (Int?, RequestError?) -> Void ) {
        
        return completion(disasterService.getAllConnections(), nil)
        
    }
    
    func percentageSafeHandler(completion: (Double?, RequestError?) -> Void ) {
        
    }
    
    func percentageDangerHandler(completion: (Double?, RequestError?) -> Void ) {
        
    }
    
    func percentageUnknownHandler(completion: (Double?, RequestError?) -> Void ) {
        
    }

    public func run() throws {
        try postInit()
        KituraOpenAPI.addEndpoints(to: router)
        Kitura.addHTTPServer(onPort: cloudEnv.port, with: router)
        Kitura.run()
    }
}
