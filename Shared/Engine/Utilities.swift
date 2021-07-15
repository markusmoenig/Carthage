//
//  Utilities.swift
//  Carthage
//
//  Created by Markus Moenig on 15/7/21.
//

import Foundation

let π = Float.pi

extension Float {
    var radiansToDegrees: Float {
        (self / π) * 180
    }
    var degreesToRadians: Float {
        (self / 180) * π
    }
}

extension Double {
    var radiansToDegrees: Double {
        (self / Double.pi) * 180
    }
    var degreesToRadians: Double {
        (self / 180) * Double.pi
    }
}
