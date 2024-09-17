//
//  Item.swift
//  Arc-POC
//
//  Created by Womack, Chris on 9/16/24.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
