//
//  ViewController.swift
//  kitura-safe-lab-dashboard
//
//  Created by David Okun on 5/30/19.
//  Copyright © 2019 David Okun. All rights reserved.
//

import Cocoa
import Starscream
import MapKit

class ViewController: NSViewController {
    var client = DisasterSocketClient(address: "localhost:8080")

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        client.delegate = self
        client.attemptConnection()
        //disasterSocketClient.disasterSocket?.connect()
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
}

extension ViewController: DisasterSocketClientDelegate {
    func statusReported(client: DisasterSocketClient, person: Person) {
        print("")
    }
    
    func clientConnected(client: DisasterSocketClient) {
        client.disconnect()
    }
    
    func clientDisconnected(client: DisasterSocketClient) {
        print("")
    }
    
    func clientErrorOccurred(client: DisasterSocketClient, error: Error) {
        print("")
    }
}
