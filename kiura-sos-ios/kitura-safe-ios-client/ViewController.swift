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

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        locationManager = LocationManager()
        locationManager?.delegate = self
    }
}

extension ViewController: LocationManagerDelegate {
    func manager(_ manager: LocationManager, didReceiveFirst location: CLLocationCoordinate2D) {
        DispatchQueue.main.async {
            let region = MKCoordinateRegion(center: location, latitudinalMeters: 1000, longitudinalMeters: 1000)
            self.mapView?.setRegion(region, animated: true)
        }
    }
}

extension ViewController { //IBActions
    @IBAction func connect(target: Any) {
        
    }
}
