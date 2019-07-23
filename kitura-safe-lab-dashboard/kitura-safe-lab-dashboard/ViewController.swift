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
    var disasterClient = DisasterSocketClient(address: "localhost:8080")
    var annotationProcessingQueue = DispatchQueue(label: "com.ibm.annotationProcessingQueue")
    @IBOutlet weak var mapView: MKMapView?
    var annotations = [PersonAnnotation]()
    
    override func viewDidAppear() {
        super.viewDidAppear()
        disasterClient.delegate = self
        mapView?.delegate = self
    }
}

extension ViewController { //IBActions
    @IBAction func connectDashboard(target: Any) {
        disasterClient.attemptConnection()
    }
    
    @IBAction func simulateDisaster(target: Any) {
        performSegue(withIdentifier: "DisasterNameSegue", sender: nil)
    }
    
    @IBAction func resetButtonTapped(target: Any) {
        if let mapAnnotations = self.mapView?.annotations {
            self.mapView?.removeAnnotations(mapAnnotations)
        }
        self.annotations.removeAll()
    }
}

extension ViewController: DisasterSocketClientDelegate {
    func statusReported(client: DisasterSocketClient, person: Person) {
        annotationProcessingQueue.sync {
            let coordinate = CLLocationCoordinate2D(latitude: person.coordinate.latitude, longitude: person.coordinate.longitude)
            if person.status.status == "Unreported" {
                let newAnnotation = UnreportedPersonAnnotation(coordinate: coordinate, person: person)
                self.annotations.append(newAnnotation)
                drop(newAnnotation)
            }
            else if person.status.status == "Safe" {
                removeDuplicateAnnotations(for: person)
                let newAnnotation = SafePersonAnnotation(coordinate: coordinate, person: person)
                self.annotations.append(newAnnotation)
                drop(newAnnotation)
            }
            else if person.status.status == "Unsafe" {
                removeDuplicateAnnotations(for: person)
                let newAnnotation = UnsafePersonAnnotation(coordinate: coordinate, person: person)
                self.annotations.append(newAnnotation)
                drop(newAnnotation)
            }
        }
    }
    
    func removeDuplicateAnnotations(for person: Person) {
        let existingAnnotation = self.annotations.filter { $0.person?.id == person.id }
        self.annotations = self.annotations.filter { $0.person?.id != person.id }
        DispatchQueue.main.async {
            self.mapView?.removeAnnotations(existingAnnotation)
        }
    }
    
    func clientConnected(client: DisasterSocketClient) {
        guard let currentLocation = mapView?.userLocation.coordinate else {
            return
        }
        let region = MKCoordinateRegion(center: currentLocation, latitudinalMeters: 1000, longitudinalMeters: 1000)
        self.mapView?.setRegion(region, animated: true)
    }
    
    func clientDisconnected(client: DisasterSocketClient) {
        print("client disconnected")
    }
    
    func clientErrorOccurred(client: DisasterSocketClient, error: Error) {
        print("error occurred: \(error.localizedDescription)")
    }
    
    func clientReceivedToken(client: DisasterSocketClient, token: RegistrationToken) {
        guard let currentLocation = mapView?.userLocation.coordinate else {
            return
        }
        let dashboard = Dashboard(coordinate: Coordinate(latitude: currentLocation.latitude, longitude: currentLocation.longitude), dashboardID: token.tokenID)
        client.confirm(dashboard)
    }
}

extension ViewController: DisasterSegueConfirmationViewControllerDelegate {
    func vcConfDisasterName(controller: DisasterSegueConfirmationViewController, name: String) {
        controller.dismiss(nil)
        guard let location = mapView?.userLocation.coordinate else {
            return
        }
        let disaster = Disaster(coordinate: Coordinate(latitude: location.latitude, longitude: location.longitude), name: name)
        disasterClient.simulate(disaster)
    }
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        if segue.identifier == "DisasterNameSegue" {
            let controller = segue.destinationController as! DisasterSegueConfirmationViewController
            controller.delegate = self
        }
    }
}

extension ViewController: MKMapViewDelegate {
    func drop(_ annotation: PersonAnnotation) {
        DispatchQueue.main.async {
            self.mapView?.addAnnotation(annotation)
            self.mapView?.selectAnnotation(annotation, animated: true)
        }
    }

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        var view = MKPinAnnotationView()
        if annotation is SafePersonAnnotation {
            view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "safePerson")
            view.pinTintColor = .blue
        } else if annotation is UnsafePersonAnnotation {
            view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "unsafePerson")
            view.pinTintColor = .red
        } else if annotation is UnreportedPersonAnnotation {
            view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "unreportedPerson")
            view.pinTintColor = .green
        }
        view.animatesDrop = true
        view.canShowCallout = true
        return view
    }
}
