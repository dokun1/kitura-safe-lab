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

1. [Getting Started](https://github.com/dokun1/kitua-safe-lab/blob/master/README.md)
2. [Setting up the Server](https://github.com/dokun1/kitua-safe-lab/blob/master/ServerSetUp.md)
3. [Setting up the Dashboard](https://github.com/dokun1/kitua-safe-lab/blob/master/DashboardSetUp.md)
4. **[Setting up the iOS Client](https://github.com/dokun1/kitua-safe-lab/blob/master/iOSSetUp.md)**
5. [Handling Status Reports and Disasters](https://github.com/dokun1/kitua-safe-lab/blob/master/StatusReportsAndDisasters.md)
6. [Setting up OpenAPI and REST API functionality](https://github.com/dokun1/kitua-safe-lab/blob/master/OpenAndRESTAPI.md)
7. [Build your app into a Docker image and deploy it on Kubernetes](https://github.com/dokun1/kitua-safe-lab/blob/master/DockerAndKubernetes.md)
8. [Enable monitoring through Prometheus/Grafana](https://github.com/dokun1/kitua-safe-lab/blob/master/PrometheusAndGrafana.md)

# iOS Client Set Up

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
    let person = Person(coordinate: Coordinate(latitude: currentLocation.latitude, longitude: currentLocation.longitude), name: name, id: token.tokenID, status: Safety(status: "Unreported"))
    self.currentPerson = person
    client.reportStatus(for: person)
  }
  alert.addAction(saveAction)
  self.present(alert, animated: true, completion: nil)
}
```

Build and run your iOS app - you should now be sending off a message with a person report. Now your phone should be able to do everything it needs to do to report your status when you initially register with the server.

# Next Steps

Continue to the [next page](https://github.com/dokun1/kitua-safe-lab/blob/master/StatusReportsAndDisasters.md) to set up handling of Status Reports and Disasters.
