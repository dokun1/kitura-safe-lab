// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "kitura-safe-server",
    dependencies: [
      .package(url: "https://github.com/IBM-Swift/Kitura.git", .upToNextMinor(from: "2.7.0")),
      .package(url: "https://github.com/IBM-Swift/HeliumLogger.git", from: "1.7.1"),
      .package(url: "https://github.com/IBM-Swift/CloudEnvironment.git", from: "9.0.0"),
      .package(url: "https://github.com/RuntimeTools/SwiftMetrics.git", from: "2.0.0"),
      .package(url: "https://github.com/IBM-Swift/Health.git", from: "1.0.0"),
      .package(url: "https://github.com/IBM-Swift/Kitura-WebSocket-NIO.git", from: "2.0.0"),
      .package(url: "https://github.com/IBM-Swift/Kitura-OpenAPI.git", from: "1.2.1"),
      .package(url: "https://github.com/IBM-Swift/Kitura-CORS.git", from: "2.1.0"),
      .package(url: "https://github.com/IBM-Swift/TypeDecoder.git", from: "1.3.3")
    ],
    targets: [
      .target(name: "kitura-safe-server", dependencies: [ .target(name: "Application"), "Kitura" , "HeliumLogger", "TypeDecoder"]),
      .target(name: "Application", dependencies: [ "KituraCORS","Kitura", "CloudEnvironment","SwiftMetrics", "Health", "Kitura-WebSocket", "KituraOpenAPI", "TypeDecoder"]),

      .testTarget(name: "ApplicationTests" , dependencies: [.target(name: "Application"), "Kitura","HeliumLogger" ])
    ]
)
