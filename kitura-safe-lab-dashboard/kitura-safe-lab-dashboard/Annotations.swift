//
//  Annotations.swift
//  kitura-safe-lab-dashboard
//
//  Created by David Okun on 6/1/19.
//  Copyright © 2019 David Okun. All rights reserved.
//

import Foundation
import MapKit

class PersonAnnotation: NSObject, MKAnnotation {
    init(coordinate: CLLocationCoordinate2D, person: Person) {
        self.coordinate = coordinate
        self.person = person
        self.title = person.name
        self.subtitle = person.status.status
    }
    var coordinate: CLLocationCoordinate2D
    var person: Person?
    var title: String?
    var subtitle: String?
}

class SafePersonAnnotation: PersonAnnotation { }
class UnsafePersonAnnotation: PersonAnnotation { }
class UnreportedPersonAnnotation: PersonAnnotation { }
