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

    var position                : Any { get set }
    var transform               : Any { get set }
    var orientation             : Any { get set }

    var lookAt                  : Any { get set }

    func setEuler(_ angles: [String: AnyObject])

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
    
    var position: Any  {
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
    
    var transform: Any {
        get {
            if let entity = getSelf() {
                return fromFloat4x4(entity.getTransform())
            }
            return [:]
        }
        set {
            if let entity = getSelf() {
                entity.setTransform(toFloat4x4(newValue))
            }
        }
    }
    
    var orientation: Any {
        get {
            if let entity = getSelf() {
                return fromFloat4AsQuat(entity.getOrientation())
            }
            return [:]
        }
        set {
            if let entity = getSelf() {
                entity.setOrientation(toFloat4(newValue))
            }
        }
    }
    
    var lookAt: Any  {
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
    
    func setEuler(_ angles: [String: AnyObject]) {
        if let entity = getSelf() {
            entity.setEuler(toFloat3(angles))
        }
    }

    /// Class initializer
    class func getInstance() -> CarthageJSCamera {
        return CarthageJSCamera()
    }
}
