## Kitura "I'm Safe" Lab

This is meant to be a hands-on lab that will be delivered at AltConf 2019 on Wednesday, June 5 at 1pm PST. 

If you've ever been in an area where there's a natural disaster that's occurred and has affected a large number of people, you may have seen a Facebook notification pop up asking you to report whether or not you are "safe". This has been helpful to families concerned about their loved ones when they can't reach them. Today, we are going to implement this feature with Kitura and Websockets.

## Requirements

- [Cocoapods](https://cocoapods.org)
- Swift 5.0+
- Terminal

## Optional

- [ngrok](https://ngrok.com/)
- an iOS device that can run apps from Xcode

## Getting started

// TODO: make branch for starter projects, as completed project should be on master branch.

First, clone this repository. The `master` branch of this repo is the completed project. The `` branch is the starter project for lab completion. Here's how you can prepare your development environment for either branch.

### Setting up the server

1. Open Terminal.
2. Navigate to the `kitura-safe-server` directory.
3. Type `ls` - if you see `Package.swift` in the resulting output, you are in the right place.
4. Enter `export KITURA_NIO=1` into Terminal.
5. Enter `swift package generate-xcodeproj` into Terminal, then `xed .` when the command is done.
6. In Xcode, run the server on My Mac.
7. Open a web browser, and navigate to `localhost:8080`. If you see the Kitura home page, you are ready to go! Don't quit the server!

### Setting up the macOS client

1. Open Terminal.
2. Navigate to the `kitura-safe-lab-dashboard` directory.
3. Type `ls` - if you see `Podfile` in the resulting output, then you are in the right place.
4. Enter `pod install` into Terminal.
5. Enter `xed .` into Terminal.
6. Run the main application on My Mac.
7. Accept location tracking for the application.

### Setting up the iOS client

1. Open Terminal.
2. Navigate to the `kitura-safe-ios-client` directory.
3. Type `ls` - if you see `Podfile` in the resulting output, then you are in the right place.
4. Enter `pod install` into Terminal.
5. Enter `xed .` into Terminal.
6. Run the main application on an iOS simulator of your choice.
7. Type `Always Allow` when prompted for location tracking on the iOS app.

## App Workflow

If you are working with the completed project, run things in this order:

1. Start your server
2. Start your macOS dashboard
3. Accept location tracking on your dashboard
3. Click the "connect" button on your dashboard
4. Run an iOS simulator
5. Ensure that location tracking is working, either through Xcode or specifying a specific location in the simulator menu "Debug"
6. Tap the "connect" button on your device
7. Enter your name, then tap confirm
8. Ensure that pin drops on dashboard
9. Click "Disaster" button on dashboard, confirm name of disaster
10. Respond to alert on iOS device

If you want to test this with real devices, either deploy this server and use the address, or use [ngrok](https://ngrok.com) to tunnel connections through to localhost, and then update the addresses in both the macOS and iOS clients. This can handle *many* concurrent connections, and the pins should drop when the responses are received.

## Lab Instructions

First, make sure that you follow the [setup]() instructions first. After that, you are ready to begin.

### Part 1 - Starting up your server

First, stop your server, and let's add the ability to connect to it with a WebSocket connection. Open up the `WebsocketService.swift` file in your server, and add the following code underneath your import statement for `Foundation`:

```swift
import KituraWebSocket
import LoggerAPI

extension WebSocketConnection: Equatable {
    public static func == (lhs: WebSocketConnection, rhs: WebSocketConnection) -> Bool {
        return lhs.id == rhs.id
    }
}
class DisasterSocketService: WebSocketService {

}
```

Next, you're going to add some protocol stubs inside your `DisasterSocketService`:

```swift
func connected(connection: WebSocketConnection) {
    Log.info("connection established: \(connection)")
}
    
func disconnected(connection: WebSocketConnection, reason: WebSocketCloseReasonCode) {
    Log.info("Connection dropped for \(connection.id), reason: \(reason)")
}
    
func received(message: Data, from: WebSocketConnection) {
    Log.info("data message received: \(String(describing: String(data: message, encoding: .utf8)))")
}
    
func received(message: String, from: WebSocketConnection) {
    Log.info("string message received: \(message)")
}
```

This is all you need to set up a websocket connection. In order to make sure that this service is live, open `Application.swift` and add this line of code to the bottom of the `postInit()` function:

```swift
WebSocket.register(service: DisasterSocketService(), onPath: "/disaster")
```

Run your server. Use a browser based tool to test your websocket connection, and confirm that it works by checking the logs of your server.

Next, add the following three stored properties inside the top of your `DisasterSocketService` class declaration:

```swift
private var allConnections = [WebSocketConnection]()
private var dashboardConnection: Dashboard?
private var connectedPeople = [Person]()
```

Next, add these three function signatures, which you will use later:

```swift 
private func parse(_ data: Data, for connection: WebSocketConnection) {

}
    
private func reportStatus(for person: Person) {

}
    
private func notifyDevices(of disaster: Disaster) {

}
```

First, you need to act whenever a client connects to you. You will send them a "token", which lets the client know how to identify itself for all future communications. Add this code to your `connected:` function:

```swift
allConnections.append(connection)
do {
    connection.send(message: try JSONEncoder().encode(RegistrationToken(tokenID: connection.id)))
} catch let error {
    Log.error("Could not send registration token to connection \(connection.id): \(error.localizedDescription)")
}
```

Next, add the code that handles a disconnection inside the `disconnected:` function:

```swift
Log.info("Connection dropped for \(connection.id), reason: \(reason)")
if connection.id == dashboardConnection?.dashboardID {
    dashboardConnection = nil
}
connectedPeople = connectedPeople.filter { $0.id != connection.id }
allConnections = allConnections.filter { $0 != connection }
```

The first "real" thing you'll need to do is handle a dashboard confirming it's registration with you. Since WebSockets can transmit binary data over the wire, you can make use of the `Codable` protocol to easily check what kind of object you've received. Update your `received: Data` function to look like so:

```swift
Log.info("data message received: \(String(describing: String(data: message, encoding: .utf8)))")
parse(message, for: from)
```

Next, go inside your `parse:` function and add the following code to handle the registration of a dashboard:

```swift
if let dashboard = try? JSONDecoder().decode(Dashboard.self, from: data) {
    Log.info("dashboard registered with id: \(dashboard.dashboardID)")
    self.dashboardConnection = dashboard
}
```

Put a breakpoint on the line that saves `dashboard` to `self.dashboard`. Build and run your server, and make sure that your server is running. Now you're going to build out your macOS client to be able to register with the server.

### Part 2 - Setting up your macOS Client

Switch to your macOS client project, and open the `DisasterSocketClient.swift` file in Xcode. Add the following code to this file:

```swift
import Starscream

protocol DisasterSocketClientDelegate: class {
    func statusReported(client: DisasterSocketClient, person: Person)
    func clientConnected(client: DisasterSocketClient)
    func clientDisconnected(client: DisasterSocketClient)
    func clientErrorOccurred(client: DisasterSocketClient, error: Error)
    func clientReceivedToken(client: DisasterSocketClient, token: RegistrationToken)
}

enum DisasterSocketError: Error {
    case badConnection
}

class DisasterSocketClient {

}
```

This stubs out what you need to set up a websocket client in your macOS app. This might look familiar when you start working with your iOS client, but you will notice a couple of key differences.

At the very bottom of this file, outside of the scope of your `DisasterSocketClient` scope, add the following extension:

```swift
extension DisasterSocketClient: WebSocketDelegate {
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
    
    private func parse(_ data: Data) {

    }
}
```