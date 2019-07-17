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

## Add Support for handling a GET request on `/all`

REST APIs typically consist of an HTTP request using a verb such as `POST`, `PUT`, `GET` or `DELETE` along with a URL and an optional data payload. The server then handles the request and responds with an optional data payload.

A request to load all of the stored data typically consists of a `GET` request with no data, which the server then handles and responds with an array of all the data in the store.

1. Register a handler for a `GET` request on `/` that loads the data  
   Add the following into the `postInit()` function:  
   ```swift
	router.get("/", handler: getAllHandler)
   ```
2. Implement a public `getAllConnections` function in `WebsocketService.swift` that returns an array of the connected people above the `connceted` function

  ```swift
  public func getAllConnections() -> [Person]? {
        return connectedPeople
    }
  ```
3.  Implement the `getAllHandler()` that responds with all of the connected people as an array.      
   Add the following as a function in the App class:

  ```swift
  func getAllHandler(completion: ([Person]?, RequestError?) -> Void ) {
    return completion(disasterService.getAllConnections(), nil)
  }
  ```
4. Refresh SwaggerUI again and view your new GET route. Clicking "Try it out!" will return the empty array (because there are no current connections to the server), but experiment with connecting to the server and using the GET method to see all the connections. REST APIs are easy!

## Add Support for handling a `GET` request on `/safe`

For this request, we want to find the percentage of people that have been registered safe to the server.

1. Register a handler for a `GET` request on `/safe` that loads the data  
   Add the following into the `postInit()` function:  
   ```swift
	router.get("/safe", handler: getSafeHandler)
   ```
2. Implement a public `getSafeConnections` function in `WebsocketService.swift`, that returns a percentage of the safe connected people, beneath your `getAllConnections` function

  ```swift
  public func getSafeConnections() -> Double? {

        var percentNumber = 100/Double(connectedPeople.count)
        var safeNumber = 0.00
        for person in connectedPeople {

            safeNumber = 0
            if person.status.rawValue == "safe" {
                safeNumber += 1
            }

        }

        var percentageSafe = percentNumber*safeNumber
        return percentageSafe

    }
  ```
3.  Implement the `getSafeHandler()` that responds with all of the stored ToDo items as an array.      
   Add the following as a function in the App class:

  ```swift
  func getSafeHandler(completion: (Double?, RequestError?) -> Void ) {
    return completion(disasterService.getSafeConnections(), nil)
  }
  ```
4. Refresh SwaggerUI again and view your new GET route.

## Add Support for handling a `GET` request on `/danger`

For this request, we want to find the percentage of people that have been registered safe to the server.

1. Register a handler for a `GET` request on `/safe` that loads the data  
   Add the following into the `postInit()` function:  
   ```swift
	router.get("/safe", handler: getSafeHandler)
   ```
2. Implement a public `getSafeConnections` function in `WebsocketService.swift`, that returns a percentage of the safe connected people, beneath your `getAllConnections` function

  ```swift
  public func getSafeConnections() -> Double? {

        var percentNumber = 100/Double(connectedPeople.count)
        var safeNumber = 0.00
        for person in connectedPeople {

            safeNumber = 0
            if person.status.rawValue == "safe" {
                safeNumber += 1
            }

        }

        var percentageSafe = percentNumber*safeNumber
        return percentageSafe

    }
  ```
3.  Implement the `getSafeHandler()` that responds with all of the stored ToDo items as an array.      
   Add the following as a function in the App class:

  ```swift
  func getSafeHandler(completion: (Double?, RequestError?) -> Void ) {
    return completion(disasterService.getSafeConnections(), nil)
  }
  ```
4. Refresh SwaggerUI again and view your new GET route.

# Next Steps

With this app, it only really serves purpose to use the `GET` methods of the API and display different statistics

Continue to the [next page](https://github.com/dokun1/kitua-safe-lab/blob/master/DockerAndKubernetes.md) to learn how to use Docker and Kubernetes.
