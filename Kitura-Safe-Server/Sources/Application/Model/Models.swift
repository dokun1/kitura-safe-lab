//
//  Person.swift
//  Application
//
//  Created by David Okun on 5/30/19.
//

import Foundation

struct Safety: Codable {
    var status: String
}

struct Coordinate: Codable, Hashable {
    var latitude: Double
    var longitude: Double
}

struct Person: Codable, Hashable {
    static func == (lhs: Person, rhs: Person) -> Bool {
        return lhs.id == rhs.id
    }

    var coordinate: Coordinate
    var name: String
    var id: String
    var status: Safety
}

struct Disaster: Codable {
    var coordinate: Coordinate
    var name: String
}

struct Dashboard: Codable {
    var coordinate: Coordinate
    var dashboardID: String
}

struct RegistrationToken: Codable {
    var tokenID: String
}
