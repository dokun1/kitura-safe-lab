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

public var startDate = String()

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
        let date: Date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T 'HH:mm:ss"
        startDate = dateFormatter.string(from: date)
        
        initializeHealthRoutes(app: self)
        WebSocket.register(service: disasterService, onPath: "/disaster")
        router.get("/users", handler: getAllHandler)
        router.get("/users", handler: getOneHandler)
        router.get("/stats", handler: getStatsHandler)
    }
    
    func getAllHandler(completion: ([Person]?, RequestError?) -> Void ) {
        
        return completion(disasterService.getAllConnections(), nil)
        
    }
    
    func getOneHandler(id: String, completion:(Person?, RequestError?) -> Void ) {
        
        return completion(disasterService.getOnePerson(id: id), nil)
        
    }
    
    func getStatsHandler(completion: (StatsStructure?, RequestError?) -> Void ) {
        
        return completion(disasterService.getStats(), nil)
        
    }

    public func run() throws {
        try postInit()
        KituraOpenAPI.addEndpoints(to: router)
        Kitura.addHTTPServer(onPort: cloudEnv.port, with: router)
        Kitura.run()
    }
}
