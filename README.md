## Kitura "I'm Safe" Lab

This is meant to be a hands-on lab that will be delivered at AltConf 2019 on Wednesday, June 5 at 1pm PST. 

If you've ever been in an area where there's a natural disaster that's occurred and has affected a large number of people, you may have seen a Facebook notification pop up asking you to report whether or not you are "safe". This has been helpful to families concerned about their loved ones when they can't reach them. Today, we are going to implement this feature with Kitura and Websockets.

## Requirements

This lab was written in Swift 5.0 for Xcode 10.2.1. We cannot guarantee this will all work as expected on beta software 🙃.

- [Cocoapods](https://cocoapods.org)
- Swift 5.0+
- Terminal

## Optional

- [ngrok](https://ngrok.com/)
- an iOS device that can run apps from Xcode

## App Workflow

In this lab, you will want to start with the `starter` branch. If you are working with the completed project on the `master` branch, run things in this order:

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

## Getting started

First, clone this repository. The `master` branch of this repo is the completed project. The `starter` branch is the starter project for lab completion. Here's how you can prepare your development environment for either branch.

### Setting up the server

1. Open Terminal.
2. Navigate to the `kitura-safe-server` directory.
3. Type `ls` - if you see `Package.swift` in the resulting output, you are in the right place.
4. Enter `export KITURA_NIO=1` into Terminal.
5. Enter `swift package generate-xcodeproj` into Terminal, then `xed .` when the command is done.
6. In Xcode, run the server on My Mac.
7. Open a web browser, and navigate to `localhost:8080`. If you see the Kitura home page, you are ready to go! Don't quit the server!

### Setting up the macOS client (dashboard)

1. Open Terminal.
2. Navigate to the `kitura-safe-lab-dashboard` directory.
3. Type `ls` - if you see `Podfile` in the resulting output, then you are in the right place.
4. Enter `pod install` into Terminal.
5. Enter `xed .` into Terminal.
6. Run the main application on My Mac.
7. Accept location tracking for the application.

You also may need to turn off code signing on your Xcode. To do this:

- go to `Build Settings` in your Xcode project
- search "identity"
- make sure you have black text entered for any identities

### Setting up the iOS client

1. Open Terminal.
2. Navigate to the `kitura-safe-ios-client` directory.
3. Type `ls` - if you see `Podfile` in the resulting output, then you are in the right place.
4. Enter `pod install` into Terminal.
5. Enter `xed .` into Terminal.
6. Run the main application on an iOS simulator of your choice.
7. Type `Always Allow` when prompted for location tracking on the iOS app.
8. With the iOS simulator open, click the `Debug` menu in the top toolbar, then Location -> Custom Location. Enter your coordinates here to simulate where you are. The San Jose Marriott is at `(37.330171, -121.888368)`.

If you want to test this with real devices, either deploy this server and use the address, or use [ngrok](https://ngrok.com) to tunnel connections through to localhost, and then update the addresses in both the macOS and iOS clients. This can handle *many* concurrent connections, and the pins should drop when the responses are received. 

## Lab Instructions

First, make sure that you follow the [setup](https://github.com/dokun1/kitura-safe-lab#setting-up-the-server) instructions first. After that, you are ready to begin.

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

### Part 2 - Setting up your macOS Client (dashboard)

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

You'll add more to this in just a moment, but first let's set up your initializer - add the following code at the top of your `DisasterSocketClient` class:

```swift
weak var delegate: DisasterSocketClientDelegate?
var address: String
var id: String?
public var disasterSocket: WebSocket?
    
init(address: String) {
    self.address = address
}
```

Next, add the following function to establish a connection:

```swift
public func attemptConnection() {
    guard let url = URL(string: "ws://\(self.address)/disaster") else {
        delegate?.clientErrorOccurred(client: self, error: DisasterSocketError.badConnection)
        return
    }
    let socket = WebSocket(url: url)
    socket.delegate = self
    disasterSocket = socket
    disasterSocket?.connect()
}
```

Note: it is very important to maintain a stored property of your websocket connection - if you don't save the memory of this connection outside of this function scope, you will try to work with something that is nil. Let's also add a way to disconnect your client:

```swift
public func disconnect() {
    disasterSocket?.disconnect()
}
```

Lastly, go back to `ViewController.swift`, and inside the top of your `ViewController` definition, update your code to look like so:

```swift
class ViewController: NSViewController {
    var disasterClient = DisasterSocketClient(address: "localhost:8080")
    var annotationProcessingQueue = DispatchQueue(label: "com.ibm.annotationProcessingQueue")
    @IBOutlet weak var mapView: MKMapView?
    var annotations = [PersonAnnotation]()
    
    override func viewDidAppear() {
        super.viewDidAppear()
        disasterClient.delegate = self
        mapView?.delegate = self
    }
}
```

You'll need to make sure this controller conforms to your `DisasterSocketClientDelegate`. At the bottom of this file, add the following extension:

```swift
extension ViewController: DisasterSocketClientDelegate {
    func statusReported(client: DisasterSocketClient, person: Person) {

    }
    
    func removeDuplicateAnnotations(for person: Person) {
    
    }
    
    func clientConnected(client: DisasterSocketClient) {
        guard let currentLocation = mapView?.userLocation.coordinate else {
            return
        }
        let region = MKCoordinateRegion(center: currentLocation, latitudinalMeters: 1000, longitudinalMeters: 1000)
        self.mapView?.setRegion(region, animated: true)
    }
    
    func clientDisconnected(client: DisasterSocketClient) {
        print("client disconnected")
    }
    
    func clientErrorOccurred(client: DisasterSocketClient, error: Error) {
        print("error occurred: \(error.localizedDescription)")
    }
    
    func clientReceivedToken(client: DisasterSocketClient, token: RegistrationToken) {

    }
}
```

Then scroll down to the `connectDashboard:` function that occurs whenever you click the "Connect" button:

```swift
disasterClient.attemptConnection()
```

Make sure your server is running. Build and run your macOS dashboard, and accept location tracking. Click the connect button, and look at your server - you should have triggered a breakpoint. Nice work! Skip past the breakpoint, and make sure that the mapview zooms in to the right region. 

Now let's authenticate your dashboard with a token returned from the server. 

## Part 3 - Using Websockets to authenticate connections

Open up your server, and open `WebsocketService.swift`. Scroll to your `connected:` function, and remember that you are using a model object to verify that the dashboard should hang onto an id. In a second, you're going to go back to your dashboard and add code to handle the receipt of this token, but first, also notice that, whenever you receive a payload of type `Data` over your connection, you have a function to check what type of object it can be decoded into, and you act accordingly. Now let's make sure that your dashboard responds appropriately when you receive a registration token from the server. 

Open your dashboard and go back to `DisasterSocketClient.swift`. Scroll to your `websocketDidReceiveData` function and add this:

```swift
parse(data)
```

Next, go into your `parse:` function and add the following code:

```swift
if let token = try? JSONDecoder().decode(RegistrationToken.self, from: data) {
    print("received registration token: \(token.tokenID)")
    delegate?.clientReceivedToken(client: self, token: token)
}
```

Whenever you get a `Data` message sent over your connection, you then see if you can decode a `RegistrationToken` object from it. If so, pass it to your view controller. Scroll up to your `disconnect:` function and add the following function underneath it:

```swift
public func confirm(_ dashboard: Dashboard) {
    self.id = dashboard.dashboardID
    do {
        disasterSocket?.write(data: try JSONEncoder().encode(dashboard))
    } catch let error {
        print("error writing dashboard registration to socket: \(error.localizedDescription)")
    }
}
```

Now, open `ViewController.swift`, so you can write code to take advantage of this function. Go inside your extension for your `DisasterSocketClientDelegate` and add the following code to your `clientReceivedToken` function:

```swift
guard let currentLocation = mapView?.userLocation.coordinate else {
    return
}
let dashboard = Dashboard(coordinate: Coordinate(latitude: currentLocation.latitude, longitude: currentLocation.longitude), dashboardID: token.tokenID)
client.confirm(dashboard)
```

If you want, add some breakpoints to the functions you have been working with so far. Restart both your server and your dashboard, and click the "Connect" button on your dashboard. In order:

1. Your dashboard tries to connect with the server
2. Your server gets the connection, and sends back a registration token
3. Your dashboard receives the token, and responds on the same connection with a confirmation
4. Your server receives the confirmation, and keeps track of which connection is the dashboard.

Now that you've set up your dashboard to work with your server, it's time to set up your iOS client.

## Part 4 - Setting up your iOS client

Open your iOS project with the `.xcworkspace` file. Open the `DisasterSocketClient.swift` file and add the following code:

```swift
import Starscream

protocol DisasterSocketClientDelegate: class {
    func clientConnected(client: DisasterSocketClient)
    func clientDisconnected(client: DisasterSocketClient)
    func clientErrorOccurred(client: DisasterSocketClient, error: Error)
    func clientReceivedToken(client: DisasterSocketClient, token: RegistrationToken)
    func clientReceivedDisaster(client: DisasterSocketClient, disaster: Disaster)
}

enum DisasterSocketError: Error {
    case badConnection
}

class DisasterSocketClient {
    weak var delegate: DisasterSocketClientDelegate?
    var address: String
    var person: Person?
    public var disasterSocket: WebSocket?
    
    init(address: String) {
        self.address = address
    }
}
```

Next, let's make this class conform to the delegate that we need. Add the following extension at the bottom of this file, outside the scope of your `DisasterSocketClient` class:

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
        parse(data)
    }
    
    private func parse(_ data: Data) {

    }
}
```

This should look familiar. Even though we are referencing one file for our model objects here, this file will actually be distinctly different from our websocket client on our macOS dashboard. Go right underneath your `init` function inside `DisasterSocketClient` and add your connection and disconnection functionality:

```swift   
public func attemptConnection() {
    guard let url = URL(string: "ws://\(self.address)/disaster") else {
        delegate?.clientErrorOccurred(client: self, error: DisasterSocketError.badConnection)
        return
    }
    let socket = WebSocket(url: url)
    socket.delegate = self
    disasterSocket = socket
    disasterSocket?.connect()
}
    
public func disconnect() {
    disasterSocket?.disconnect()
}
```

Again, this should look familiar. Now, you're going to set up your iOS client to establish a connection with your server. First, open `ViewController.swift` and update your class declaration to look like so:

```swift
class ViewController: UIViewController {
    @IBOutlet weak var mapView: MKMapView?
    var locationManager: LocationManager?
    var disasterClient = DisasterSocketClient(address: "localhost:8080")
    var currentPerson: Person?

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        disasterClient.delegate = self
        locationManager = LocationManager()
        locationManager?.delegate = self
    }
}
```

Next, let's make the controller conform to the right delegate, so add this extension to the very bottom of this file:

```swift
extension ViewController: DisasterSocketClientDelegate {
    func clientReceivedDisaster(client: DisasterSocketClient, disaster: Disaster) {
    
    }
    
    func clientReceivedToken(client: DisasterSocketClient, token: RegistrationToken) {
    
    }
    
    func clientConnected(client: DisasterSocketClient) {
        print("websocket client connected")
    }
    
    func clientDisconnected(client: DisasterSocketClient) {
        print("websocket client disconnected")
    }
    
    func clientErrorOccurred(client: DisasterSocketClient, error: Error) {
        print("error occurred with websocket client: \(error.localizedDescription)")
    }
}
```

You'll use this delegate shortly. Scroll up to the `IBAction` function where you tap the "Connect" button, and add the following code inside that function:

```swift
disasterClient.attemptConnection()
```

Build and run your iOS app. You can test your server if you'd like by adding a breakpoint to the `connected:` function on your server to see if it receives the connection request from the phone when you tap the "Connect" button. 

On your phone, instead of responding with a dashboard, you are going to respond to the authentication token with your first use of the `Person` object. Open up `DisasterSocketClient.swift` and add the following code underneath the `disconnect:` function:

```swift
public func reportStatus(for person: Person) {
    do {
        disasterSocket?.write(data: try JSONEncoder().encode(person))
    } catch let error {
        delegate?.clientErrorOccurred(client: self, error: error)
    }
}
```

Next, inside your `parse:` function, add the following decoder logic:

```swift
if let token = try? JSONDecoder().decode(RegistrationToken.self, from: data) {
    print("registration token received: \(token.tokenID)")
    delegate?.clientReceivedToken(client: self, token: token)
}
```

Now go back to `ViewController.swift`, and find the `clientReceivedToken` function in your delegate. Add the following code, which will allow you to "register" yourself with the server:

```swift
DispatchQueue.main.async {
    guard let currentLocation = self.locationManager?.lastLoggedLocation?.coordinate else {
        return
    }
    let alert = UIAlertController(title: "What is your name?", message: nil, preferredStyle: .alert)
    alert.addTextField { textField in
        textField.placeholder = "Enter name here"
    }
    let saveAction = UIAlertAction(title: "Confirm", style: .default) { action in
        guard let name = alert.textFields?.first?.text else {
            print("could not get name from alert controller")
            return
        }
        let person = Person(coordinate: Coordinate(latitude: currentLocation.latitude, longitude: currentLocation.longitude), name: name, id: token.tokenID, status: .unreported)
        self.currentPerson = person
        client.reportStatus(for: person)
    }
    alert.addAction(saveAction)
    self.present(alert, animated: true, completion: nil)
}
```

Build and run your iOS app - you should now be sending off a message with a person report. Now your phone should be able to do everything it needs to do to report your status when you initially register with the server. 

## Part 5 - Handling a status report on your server and dashboard

Now, go back to your server project. Open `WebsocketService.swift` and go to the `parse:` function. Add this conditional decode logic at the bottom of the function:

```swift
if let person = try? JSONDecoder().decode(Person.self, from: data) {
    Log.info("person status reported: \(person.name) is \(person.status.rawValue)")
    reportStatus(for: person)
}
```

Next, beneath this function, add the following code to `reportStatus` whenever a connection confirms a `Person` object:

```swift
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
```

By now, you are handling the registration of a person, storing their status, and sending that registration onto the dashboard. Open your mac dashboard application, and open `DisasterSocketClient.swift`. Add this decode logic to the `parse:` function:

```swift
if let person = try? JSONDecoder().decode(Person.self, from: data) {
    print("received status of person: \(person.id)")
    delegate?.statusReported(client: self, person: person)
}
```

Now, open `ViewController.swift` and find the delegate function for `statusReported:`. Add the following code inside this function:

```swift
annotationProcessingQueue.sync {
    let coordinate = CLLocationCoordinate2D(latitude: person.coordinate.latitude, longitude: person.coordinate.longitude)
    switch person.status {
    case .unreported:
        let newAnnotation = UnreportedPersonAnnotation(coordinate: coordinate, person: person)
        self.annotations.append(newAnnotation)
        drop(newAnnotation)
        break
    case .safe:
        removeDuplicateAnnotations(for: person)
        let newAnnotation = SafePersonAnnotation(coordinate: coordinate, person: person)
        self.annotations.append(newAnnotation)
        drop(newAnnotation)
        break
    case .unsafe:
        removeDuplicateAnnotations(for: person)
        let newAnnotation = UnsafePersonAnnotation(coordinate: coordinate, person: person)
        self.annotations.append(newAnnotation)
        drop(newAnnotation)
        break
    }
}
```

This does a lot of the MapKit work for you, but you can follow the logic to see what happens. For now, you are only really going to handle an unreported status. Lastly, add the following code inside your `removeDuplicateAnnotations:` function:

```swift
let existingAnnotation = self.annotations.filter { $0.person?.id == person.id }
self.annotations = self.annotations.filter { $0.person?.id != person.id }
DispatchQueue.main.async {
    self.mapView?.removeAnnotations(existingAnnotation)
}
```

Restart your server, run your dashboard, connect, then run your iOS client and connect. Without any breakpoints, you should see a pin drop for the person that registered after that person confirms their name. You are now ready to handle a disaster!!

## Part 6 - Disaster strikes!

You're going to trigger a disaster from your dashboard, and the server will notify each iOS device connected to it. As each device reports its status, the dashboard will update asynchronously with the statuses as they come in. 

First, open `DisasterSocketClient.swift` on your dashboard. Add the following code underneath the `confirm:Dashboard` function:

```swift
public func simulate(_ disaster: Disaster) {
    do {
        try disasterSocket?.write(data: JSONEncoder().encode(disaster))
    } catch let error {
        delegate?.clientErrorOccurred(client: self, error: error)
    }
}
```

Now you have the ability to report a disaster. Scroll to the succintly named `disasterSegueConfirmationViewControllerDidConfirmDisasterName:` function in `ViewController.swift` and add the following code after `dismiss()` is called:

```swift
guard let location = mapView?.userLocation.coordinate else {
    return
}
let disaster = Disaster(coordinate: Coordinate(latitude: location.latitude, longitude: location.longitude), name: name)
disasterClient.simulate(disaster)
```

Now your dashboard is wired up. Next open your server, and open up `WebsocketService.swift`. Add the following code to the bottom of your `parse:Data` function:

```swift
else if let disaster = try? JSONDecoder().decode(Disaster.self, from: data) {
        Log.info("disaster occurred! \(disaster.name) at (\(disaster.coordinate.latitude), \(disaster.coordinate.longitude))")
    notifyDevices(of: disaster)
}
```

By now, your `parse` function should effectively be looking for three different types of `Data`, all thanks to `Codable`. Now, scroll to the `notifyDevices` function, and add the following code:

```swift
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
```

This loops through all of the existing connections to iOS devices, and sends a message to each of them with the disaster type. All that's left is to handle this on your device!

Open your iOS client project, and open `DisasterSocketClient.swift`. Add this code to the bottom of your `parse:Data` function:

```swift
else if let disaster = try? JSONDecoder().decode(Disaster.self, from: data) {
    print("disaster reported: \(disaster.name)")
    delegate?.clientReceivedDisaster(client: self, disaster: disaster)
}
```

Now, open `ViewController.swift` and add the following code inside the `clientReceivedDisaster:` function:

```swift
DispatchQueue.main.async {
    guard var person = self.currentPerson else {
        print("no current person listed")
        return
    }
    let alert = UIAlertController(title: "DISASTER!!!", message: "Oh no! \(disaster.name) in your area!! Are you safe?", preferredStyle: .alert)
    let safeAction = UIAlertAction(title: "Yes", style: .default, handler: { action in
        person.status = .safe
        client.reportStatus(for: person)
    })
    let unsafeAction = UIAlertAction(title: "No", style: .destructive, handler: { action in
        person.status = .unsafe
        client.reportStatus(for: person)
    })
    alert.addAction(safeAction)
    alert.addAction(unsafeAction)
    self.present(alert, animated: true, completion: nil)
}
```

Save everything. You are now ready to test the entire flow!

## Part 7 - The Final Test!

Follow these steps in order:

1. Run your server
2. Run your dashboard
3. Connect your dashboard
4. Run your iOS client
5. Connect your iOS client
6. Confirm the status of your iOS client on your dashboard
7. Report a disaster from the dashboard
8. Respond to the disaster on your iOS client
9. Watch the status report on the dashboard