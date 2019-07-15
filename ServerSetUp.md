# Kitura "I'm Safe" Lab

<p align="center">
<img src="https://www.ibm.com/cloud-computing/bluemix/sites/default/files/assets/page/catalog-swift.svg" width="120" alt="Kitura Bird">
</p>

<p align="center">
<a href= "http://swift-at-ibm-slack.mybluemix.net/">
    <img src="http://swift-at-ibm-slack.mybluemix.net/badge.svg"  alt="Slack">
</a>
</p>

## Workshop Table of Contents:

1. [Getting Started](https://github.com/dokun1/kitua-safe-lab/blob/master/GettingStarted.md)
2. **[Setting up the Server](https://github.com/dokun1/kitua-safe-lab/blob/master/ServerSetup.md)**
3. [Setting up the Dashboard](https://github.com/dokun1/kitua-safe-lab/blob/master/DashboardSetup.md)
4. [Setting up the iOS client](https://github.com/dokun1/kitua-safe-lab/blob/master/iOSSetup.md)
5. [Handling status reports and Disasters](https://github.com/dokun1/kitua-safe-lab/blob/master/StatusReportsAndDisasters.md)

# Server Set Up

First, stop your server, let's add the ability to connect to it with a WebSocket connection. Open up the `WebSocketService.swift` file in the Services folder of your server, and add the following code underneath your import statement for `Foundation`:

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

Next, you're going to add some protocol stubs inside your `DisasterSocketService`, we will be adding to these later:

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

This is all you need to set up a websocket connection. In order to make sure that this service is live, open `Application.swift`, add the line `import KituraWebSocket` at the very top of the file, and add this line of code to the bottom of the `postInit()` function:

```swift
WebSocket.register(service: DisasterSocketService(), onPath: "/disaster")
```

Run your server. Open Terminal and enter the following command:

```bash
curl --include \
     --no-buffer \
     --header "Connection: Upgrade" \
     --header "Upgrade: websocket" \
     --header "Host: example.com:80" \
     --header "Origin: http://example.com:80" \
     --header "Sec-WebSocket-Key: SGVsbG8sIHdvcmxkIQ==" \
     --header "Sec-WebSocket-Version: 13" \
     http://localhost:8080/disaster
```

Check the logs of your server, and you should see that a connection was established. Hit ctrl+c to quit, and continue.

Next, go back to `WebsocketService.swift` and add the following three stored properties inside the top of your `DisasterSocketService` class declaration:

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

Put a breakpoint in your `connected` function. Build and run your server, and make sure that your server is running. Now you're going to build out your macOS client (dashboard) to be able to register with the server.
