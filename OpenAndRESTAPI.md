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
4. [Setting up the iOS Client](https://github.com/dokun1/kitua-safe-lab/blob/master/iOSSetUp.md)
5. [Handling Status Reports and Disasters](https://github.com/dokun1/kitua-safe-lab/blob/master/StatusReportsAndDisasters.md)
6. **[Setting up OpenAPI and REST API functionality](https://github.com/dokun1/kitua-safe-lab/blob/master/OpenAndRESTAPI.md)**
7. [Build your app into a Docker image and deploy it on Kubernetes](https://github.com/dokun1/kitua-safe-lab/blob/master/DockerAndKubernetes.md)
8. [Enable monitoring through Prometheus/Grafana](https://github.com/dokun1/kitua-safe-lab/blob/master/PrometheusAndGrafana.md)

# Setting up OpenAPI and REST API functionality

## Try out OpenAPI in Kitura

Now, you can open [http://localhost:8080/openapi](http://localhost:8080/openapi) and view the live OpenAPI specification of your Kitura application in JSON format.

You can also open [http://localhost:8080/openapi/ui](http://localhost:8080/openapi/ui) and view SwaggerUI, a popular API development tool. You will see one route defined: the GET `/health` route. Click on the route to expand it, then click "Try it out!" to query the API from inside SwaggerUI.

You should see a Response Body in JSON format, like:

```
{
  "status": "UP",
  "details": [],
  "timestamp": "2018-06-04T16:03:17+0000"
}
```

and a Response Code of 200.

Congratulations, you have added OpenAPI support to your Kitura application and used SwaggerUI to query a REST API!

## Add Support for handling a `GET` request on `/users`

REST APIs typically consist of an HTTP request using a verb such as `POST`, `PUT`, `GET` or `DELETE` along with a URL and an optional data payload. The server then handles the request and responds with an optional data payload.

A request to load all of the stored data typically consists of a `GET` request with no data, which the server then handles and responds with an array of all the data in the store.

1. Register a handler for a `GET` request on `/users` that loads the data.  Add the following into the `postInit()` function of the `Application.swift` file in the `kitura-safe-server` directory:  
   ```swift
	router.get("/users", handler: getAllHandler)
   ```
2. Implement a public `getAllConnections` function in `MyWebSocketService.swift` that returns an array of the connected people above the `connected` function

  ```swift
  public func getAllConnections() -> [Person]? {
        return connectedPeople
    }
  ```
3.  Implement the `getAllHandler()` that responds with all of the connected people as an array.  Add the following as a function in the App class:

  ```swift
  func getAllHandler(completion: ([Person]?, RequestError?) -> Void ) {
    return completion(disasterService.getAllConnections(), nil)
  }
  ```
4. Refresh SwaggerUI again and view your new GET route. Clicking "Try it out!" will return the empty array (because there are no current connections to the server), but experiment with connecting to the server and using the GET method to see all the connections. REST APIs are easy!

## Add Support for handling a `GET` request on `/users:id`

For this request, we want to return all the info on a specific user by using their unique id

1. Register a handler for a `GET` request on `/users` that loads the data.  Add the following into the `postInit()` function:  
   ```swift
	router.get("/users", handler: getOneHandler)
   ```
2. Implement a public `getOnePerson` function in `MyWebSocketService.swift`, that returns a Person object, beneath your `getAllConnections` function

  ```swift
  public func getOnePerson(id: String) -> Person? {

        for person in connectedPeople {
            if person.id == id {
                return person
            }
        }
        return nil
    }
  ```
3.  Implement the `getOneHandler()` that takes a String that is the person's specific id and responds with all the data associated with that user.  Add the following as a function in the App class:

  ```swift
  func getOneHandler(id: String, completion:(Person?, RequestError?) -> Void ) {
        return completion(disasterService.getOnePerson(id: id), nil)
    }
  ```
4. Refresh SwaggerUI again and view your new GET route.

## Add Support for handling a `GET` request on `/stats`

For this request, we want to find several statistics about the server. We will display:

* The start time of the server
* The current time
* The percentage of connected users reported as safe
* The percentage of connected users reported as unsafe
* The percentage of connected users reported as unreported

1. Register a handler for a `GET` request on `/stats` that loads the data  
   Add the following into the `postInit()` function:  
   ```swift
	router.get("/stats", handler: getStatsHandler)
   ```
2. Create a global variable in `Application.swift` outside the scope of the App class that stores the time of the server when launched:
   ```swift
   public var startDate = String()
   ```
   Then at the start of the `postInit()` method, add:
   ```swift
   let date: Date = Date()
   let dateFormatter = DateFormatter()
   dateFormatter.dateFormat = "yyyy-MM-dd'T 'HH:mm:ss"
   startDate = dateFormatter.string(from: date)
   ```

3. Create a Codable structure in `Models.swift` that holds all the values we need for our statistics:

```swift
struct StatsStructure: Codable {
    var safePercentage: Double
    var unsafePercentage: Double
    var unreportedPercentage: Double
    var startTime: String
    var currentTime: String
}
```

4. Implement a public `getStats` function in `MyWebSocketService.swift`, that returns all the statistics we need for our server:

  ```swift
  public func getStats() -> StatsStructure? {

    let date: Date = Date()
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd'T 'HH:mm:ss"
    let currentDate = dateFormatter.string(from: date)

    var currentStatsStructure = StatsStructure(safePercentage: 0.0, unsafePercentage: 0.0, unreportedPercentage: 0.0, startTime: startDate, currentTime: currentDate)

    if connectedPeople.count>0 {

      let percentNumber = 100/Double(connectedPeople.count)
      var safeNumber = 0.0
      var unsafeNumber = 0.0
      var unreportedNumber = 0.0

      for person in connectedPeople {

        if person.status.status == "Safe" {
          safeNumber += 1.0
        }

        else if person.status.status == "Unsafe" {
          unsafeNumber += 1.0
        }

        else {
          unreportedNumber += 1.0
        }

        }

        let percentageSafe = percentNumber*safeNumber
        currentStatsStructure.safePercentage = percentageSafe

        let percentageUnsafe = percentNumber*unsafeNumber
        currentStatsStructure.unsafePercentage = percentageUnsafe

        let percentageUnreported = percentNumber*safeNumber
        currentStatsStructure.unreportedPercentage = percentageUnreported

        }

        return currentStatsStructure

    }
  ```
5.  Implement a `getStatsHandler()` that responds with all the data.  Add the following as a function in the App class:

  ```swift
  func getStatsHandler(completion: (StatsStructure?, RequestError?) -> Void ) {
        return completion(disasterService.getStats(), nil)
    }
  ```
6. Refresh SwaggerUI again and view your new GET route.

# Next Steps

Continue to the [next page](https://github.com/dokun1/kitua-safe-lab/blob/master/DockerAndKubernetes.md) to learn how to use Docker and Kubernetes.
