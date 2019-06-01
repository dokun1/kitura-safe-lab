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
    @IBOutlet weak var mapView: MKMapView?
    
    override func viewDidAppear() {
        super.viewDidAppear()
        client.delegate = self
        
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
}

extension ViewController { //IBActions
    @IBAction func connectDashboard(target: Any) {
        client.attemptConnection()
    }
    
    @IBAction func simulateDisaster(target: Any) {
        performSegue(withIdentifier: "DisasterNameSegue", sender: nil)
    }
}

class PersonAnnotation: NSObject, MKAnnotation {
    init(coordinate: CLLocationCoordinate2D, person: Person) {
        self.coordinate = coordinate
        self.person = person
    }
    var coordinate: CLLocationCoordinate2D
    var person: Person?
}

extension ViewController: DisasterSocketClientDelegate {
    func statusReported(client: DisasterSocketClient, person: Person) {
        let coordinate = CLLocationCoordinate2D(latitude: person.coordinate.latitude, longitude: person.coordinate.longitude)
        let annotation = PersonAnnotation(coordinate: coordinate, person: person)
        DispatchQueue.main.async {
            self.mapView?.showAnnotations([annotation], animated: true)
//            self.mapView?.addAnnotation(annotation)
        }
    }
    
    func clientConnected(client: DisasterSocketClient) {
        guard let currentLocation = mapView?.userLocation else {
            return
        }
        let span = MKCoordinateSpan(latitudeDelta: 0.15, longitudeDelta: 0.15)
        let region = MKCoordinateRegion(center: currentLocation.coordinate, span: span)
        self.mapView?.setRegion(region, animated: true)
    }
    
    func clientDisconnected(client: DisasterSocketClient) {
        print("")
    }
    
    func clientErrorOccurred(client: DisasterSocketClient, error: Error) {
        print("")
    }
    
    func clientReceivedRegistrationID(client: DisasterSocketClient, id: String) {
        guard let currentLocation = mapView?.userLocation.coordinate else {
            return
        }
        let dashboard = Dashboard(coordinate: Coordinate(latitude: currentLocation.latitude, longitude: currentLocation.longitude), dashboardID: id)
        client.confirm(dashboard)
    }
}

extension ViewController: DisasterSegueConfirmationViewControllerDelegate {
    func disasterSegueConfirmationViewControllerDidConfirmDisasterName(controller: DisasterSegueConfirmationViewController, name: String) {
        controller.dismiss(nil)
        guard let location = mapView?.userLocation.coordinate else {
            return
        }
        let disaster = Disaster(coordinate: Coordinate(latitude: location.latitude, longitude: location.longitude), name: name)
        client.simulateDisaster(disaster)
    }
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        if segue.identifier == "DisasterNameSegue" {
            let controller = segue.destinationController as! DisasterSegueConfirmationViewController
            controller.delegate = self
        }
    }
}
