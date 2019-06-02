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
2. Navigate to the `Kitura-Safe-Server` directory.
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