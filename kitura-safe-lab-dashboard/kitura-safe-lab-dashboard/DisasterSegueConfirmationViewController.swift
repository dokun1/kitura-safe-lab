//
//  DisasterSegueConfirmationViewController.swift
//  kitura-safe-lab-dashboard
//
//  Created by David Okun on 6/1/19.
//  Copyright © 2019 David Okun. All rights reserved.
//

import Foundation
import AppKit

protocol DisasterSegueConfirmationViewControllerDelegate: class {
    func vcConfDisasterName(controller: DisasterSegueConfirmationViewController, name: String)
}

class DisasterSegueConfirmationViewController: NSViewController {
    weak var delegate: DisasterSegueConfirmationViewControllerDelegate?
    @IBOutlet weak var textField: NSTextField?
    
    @IBAction func confirm(target: Any) {
        guard let text = textField?.stringValue else {
            return
        }
        delegate?.vcConfDisasterName(controller: self, name: text)
    }
}
