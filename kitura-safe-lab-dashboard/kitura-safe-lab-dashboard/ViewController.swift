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
    @IBOutlet weak var mapView: MKMapView?
    var annotations = [PersonAnnotation]()
    
    override func viewDidAppear() {
        super.viewDidAppear()
    }
}

extension ViewController { //IBActions
    @IBAction func connectDashboard(target: Any) {
        
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

extension ViewController: DisasterSegueConfirmationViewControllerDelegate {
    func disasterSegueConfirmationViewControllerDidConfirmDisasterName(controller: DisasterSegueConfirmationViewController, name: String) {
        controller.dismiss(nil)
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
