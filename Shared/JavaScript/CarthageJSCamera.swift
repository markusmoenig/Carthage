//
//  CarthageJSCamera.swift
//  Carthage
//
//  Created by Markus Moenig on 22/7/21.
//

import Foundation
import JavaScriptCore

@objc protocol CarthageJSCameraJSExports: JSExport {
    
    var name                    : String { get }

    var position                : [String: AnyObject] { get set }
    var lookAt                  : [String: AnyObject] { get set }

    static func getInstance() -> CarthageJSCamera
}

class CarthageJSCamera: CarthageJSBase, CarthageJSCameraJSExports {
    
    override init() {
        super.init()
        _id = "__ci"
    }
    
    /// name property
    var name: String  {
        get {
            if let entity = getSelf() {
                return entity.object.name
            }
            return ""
        }
    }
    
    var position: [String: AnyObject]  {
        get {
            if let entity = getSelf() {
                return fromFloat3(entity.getPosition())
            }
            return [:]
        }
        set {
            if let entity = getSelf() {
                entity.setPosition(toFloat3(newValue))
            }
        }
    }
    
    var lookAt: [String: AnyObject]  {
        get {
            if let entity = getSelf() {
                return fromFloat3(entity.getLookAt())
            }
            return [:]
        }
        set {
            if let entity = getSelf() {
                entity.setLookAt(toFloat3(newValue))
            }
        }
    }

    /// Class initializer
    class func getInstance() -> CarthageJSCamera {
        return CarthageJSCamera()
    }
}
