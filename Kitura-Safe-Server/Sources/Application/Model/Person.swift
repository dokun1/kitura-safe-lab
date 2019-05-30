//
//  Person.swift
//  Application
//
//  Created by David Okun on 5/30/19.
//

import Foundation

enum Safety: String, Codable {
    enum CodingKeys: String, CodingKey {
        case unreported = "unreported"
        case safe = "safe"
        case unsafe = "unsafe"
    }
    
    case unreported
    case safe
    case unsafe
}

struct Person: Codable, Hashable {
    var latitude: Double
    var longitude: Double
    var name: String
    var status: Safety
}
