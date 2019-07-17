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

1. **[Getting Started](https://github.com/dokun1/kitua-safe-lab/blob/master/README.md)**
2. [Setting up the Server](https://github.com/dokun1/kitua-safe-lab/blob/master/ServerSetUp.md)
3. [Setting up the Dashboard](https://github.com/dokun1/kitua-safe-lab/blob/master/DashboardSetUp.md)
4. [Setting up the iOS Client](https://github.com/dokun1/kitua-safe-lab/blob/master/iOSSetUp.md)
5. [Handling Status Reports and Disasters](https://github.com/dokun1/kitua-safe-lab/blob/master/StatusReportsAndDisasters.md)
6. [Setting up OpenAPI and REST API functionality](https://github.com/dokun1/kitua-safe-lab/blob/master/OpenAndRESTAPI.md)
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
2. Implement the `getAllHandler()` that responds with all of the  items as an array.      
   Add the following as a function in the App class:

3.  Run the project and re-run the tests by reloading the test page in the browser.

  ```swift
  func getAllHandler(completion: ([Person]?, RequestError?) -> Void ) {
    completion(todoStore, nil)
  }
  ```

4.

The first seven tests should now pass, with the eighth test failing:  
:x: `each new todo has a url, which returns a todo`

```
GET http://localhost:8080/0
FAILED

404: Not Found (Cannot GET /0.)
```

Refresh SwaggerUI again and view your new GET route. Clicking "Try it out!" will return the empty array (because you just restarted the application and the store is empty), but experiment with using the POST route to add ToDo items then viewing them by running the GET route again. REST APIs are easy!

### 8. Add Support for handling a `GET` request on `/:id`

The next failing test is trying to load a specific ToDo item by making a `GET` request with the ID of the ToDo item that it wishes to retrieve, which is based on the ID in the `url` field of the ToDo item set when the item was stored by the earlier `POST` request. In the test above the reqest was for `GET /0` - a request for id 0.

Kitura's Codable Routing is able to automatically convert identifiers used in the `GET` request to a parameter that is passed to the registered handler. As a result, the handler is registered against the `/` route, with the handler taking an extra parameter.

1. Register a handler for a `GET` request on `/`:
   ```swift
    router.get("/", handler: getOneHandler)
   ```

2. Implement the `getOneHandler()` that receives an `id` and responds with a ToDo item:
    ```swift      
    func getOneHandler(id: Int, completion: (ToDo?, RequestError?) -> Void ) {
        guard let todo = todoStore.first(where: { $0.id == id }) else {
            return completion(nil, .notFound)
        }
        completion(todo, nil)
    }
    ```

3.  Run the project and re-run the tests by reloading the test page in the browser.

The first nine tests now pass. The tenth fails with the following:  
:x: `can change the todo's title by PATCHing to the todo's url`  

```
PATCH http://localhost:8080/0
FAILED

404: Not Found (Cannot PATCH /0.)
```

Refresh SwaggerUI and experiment with using the POST route to create ToDo items, then using the GET route on `/{id}` to retrieve the stored items by ID.

### 9. Add Support for handling a `PATCH` request on `/:id`

The failing test is trying to `PATCH` a specific ToDo item. A `PATCH` request updates an existing item by updating any fields sent as part of the `PATCH` request. This means that a field by field update needs to be done.

1.  Register a handler for a `PATCH` request on `/`:
   ```swift
   router.patch("/", handler: updateHandler)
   ```
2. Implement the `updateHandler()` that receives an `id` and responds with the updated ToDo item:
   ```swift
    func updateHandler(id: Int, new: ToDo, completion: (ToDo?, RequestError?) -> Void ) {
        guard let index = todoStore.index(where: { $0.id == id }) else {
            return completion(nil, .notFound)
        }
        var current = todoStore[index]
        current.user = new.user ?? current.user
        current.order = new.order ?? current.order
        current.title = new.title ?? current.title
        current.completed = new.completed ?? current.completed
        execute {
            todoStore[index] = current
        }
        completion(current, nil)
    }
   ```
3.  Run the project and rerun the tests by reloading the test page in the browser.

Twelve tests should now be passing, with the thirteenth failing as follows:
:x: `can delete a todo making a DELETE request to the todo's url`

```
DELETE http://localhost:8080/0
FAILED

404: Not Found (Cannot DELETE /0.)
```

Refresh SwaggerUI and experiment with using the POST route to create ToDo items, then using the PATCH route to update an existing item. For example, if you have a ToDo item at `http://localhost:8080/0` with a title of "mow the lawn", you can change its title by issuing a PATCH with id 0 and this JSON input:

```
{ "title": "wash the dog" }
```

You should see a response code of 200 with a response body of:

```
{
  "id": 0,
  "title": "wash the dog",
  "completed": false,
  "url": "http://localhost:8080/0"
}
```

### 10. Add Support for handling a DELETE request on `/:id`

The failing test is trying to `DELETE` a specific ToDo item. To fix this you need an additional route handler for `DELETE` that this time accepts an ID as a parameter.

1. Register a handler for a `DELETE` request on `/`:
   ```swift
   router.delete("/", handler: deleteOneHandler)
   ```
2. Implement the `deleteOneHandler()` that receives an `id` and removes the specified ToDo item:
   ```swift
    func deleteOneHandler(id: Int, completion: (RequestError?) -> Void ) {
        guard let index = todoStore.index(where: { $0.id == id }) else {
            return completion(.notFound)
        }
        execute {
            todoStore.remove(at: index)
        }
        completion(nil)
    }
   ```
3.  Run the project and rerun the tests by reloading the test page in the browser.

All sixteen tests should now be passing!
