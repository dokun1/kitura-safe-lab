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
    var currentPerson: Person?

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
    func clientReceivedDisaster(client: DisasterSocketClient, disaster: Disaster) {
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
    }
    
    func clientReceivedID(client: DisasterSocketClient, id: String) {
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
                let person = Person(coordinate: Coordinate(latitude: currentLocation.latitude, longitude: currentLocation.longitude), name: name, id: id, status: .unreported)
                self.currentPerson = person
                client.reportStatus(for: person)
            }
            alert.addAction(saveAction)
            self.present(alert, animated: true, completion: nil)
        }
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
