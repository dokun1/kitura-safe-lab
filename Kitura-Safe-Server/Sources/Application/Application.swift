import Foundation
import Kitura
import LoggerAPI
import Configuration
import CloudEnvironment
import KituraContracts
import Health
import KituraOpenAPI
import KituraWebSocket
import TypeDecoder

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
        WebSocket.register(service: disasterService, onPath: "/disaster")
        router.get("/users", handler: getAllHandler)
        router.get("/safe", handler: percentageSafeHandler)
        router.get("/users", handler: getOneHandler)
    }
    
    func getAllHandler(completion: ([Person]?, RequestError?) -> Void ) {
        
        return completion(disasterService.getAllConnections(), nil)
        
    }
    
    func getOneHandler(id: Int, completion:(Person?, RequestError?) -> Void ) {
        

        
    }
    
    func percentageSafeHandler(completion: (DoubleStructure?, RequestError?) -> Void ) {
        
        return completion(disasterService.getSafeConnections(), nil)
        
    }

    public func run() throws {
        try postInit()
        KituraOpenAPI.addEndpoints(to: router)
        Kitura.addHTTPServer(onPort: cloudEnv.port, with: router)
        Kitura.run()
    }
}

extension Safety: ValidSingleCodingValueProvider {
    public static func validCodingValue() -> Any? {
        // Returns the string "Unreported"
        return self.unreported.rawValue
    }
}
