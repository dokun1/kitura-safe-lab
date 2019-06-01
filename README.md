## Kitura "I'm Safe" Lab

This is meant to be a hands on lab that will be delivered at AltConf 2019 on Wednesday, June 5 at 1pm PST. 

If you've ever been in an area where there's a natural disaster that's occurred and has affected a large number of people, you may have seen a Facebook notification pop up asking you to report whether or not you are "safe". This has been helpful to families concerned about their loved ones when they can't reach them. Today, we are going to implement this feature with Kitura and Websockets.

## Getting started

// TODO: make branch for starter projects, as completed project should be on master branch.

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

## What's happening underneath the hood

- Server is running, can accept websocket connections
- macOS client runs
- macOS client connects to server with websocket connection
- iOS client connects to server via websocket
- server sends websocket message to macOS client notifying that there is an iOS client "online" in the area
- iOS client now waiting for "disaster" message
- macOS client has button to simulate disaster, button is pushed.
- macOS client sends websocket message to server with group of iOS device IDs that need notifications sent to them
- server receives message, sends websocket message to each listed device, asking for safe/not safe response
- each ios client responds with safe/not safe response
- server takes response, sends websocket message to macOS client with device id and safe/not safe
- macOS client drops pin at gps location of device with annotation of safe or unsafe
- lab participants watch as pins drop in real time as people respond

