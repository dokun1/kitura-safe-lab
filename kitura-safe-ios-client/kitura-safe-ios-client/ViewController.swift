//
//  ViewController.swift
//  kitura-safe-ios-client
//
//  Created by David Okun on 5/30/19.
//  Copyright © 2019 David Okun. All rights reserved.
//

import UIKit
import MapKit

class ViewController: UIViewController {
    @IBOutlet weak var mapView: MKMapView?
    var locationManager: LocationManager?
    var lastLocation: CLLocationCoordinate2D?
    var client = DisasterSocketClient(address: "localhost:8080")

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        client.delegate = self
        locationManager = LocationManager()
        locationManager?.delegate = self
    }
}

extension ViewController: LocationManagerDelegate {
    func manager(_ manager: LocationManager, didReceiveFirst location: CLLocationCoordinate2D) {
        let span = MKCoordinateSpan(latitudeDelta: 0.15, longitudeDelta: 0.15)
        let region = MKCoordinateRegion(center: location, span: span)
        self.mapView?.setRegion(region, animated: true)
        lastLocation = location
    }
}

extension ViewController { //IBActions
    @IBAction func connect(target: Any) {
        client.attemptConnection()
    }
}

extension ViewController: DisasterSocketClientDelegate {
    func clientReceivedID(client: DisasterSocketClient, id: String) {
        guard let currentLocation = locationManager?.lastLoggedLocation?.coordinate else {
            return
        }
        let person = Person(latitude: currentLocation.latitude, longitude: currentLocation.longitude, name: "David", id: id, status: .unreported)
        client.confirmPhone(with: person)
    }
    
    func statusReported(client: DisasterSocketClient, person: Person) {
        print("")
    }
    
    func clientConnected(client: DisasterSocketClient) {
        print("")
    }
    
    func clientDisconnected(client: DisasterSocketClient) {
        print("")
    }
    
    func clientErrorOccurred(client: DisasterSocketClient, error: Error) {
        print("")
    }
}
