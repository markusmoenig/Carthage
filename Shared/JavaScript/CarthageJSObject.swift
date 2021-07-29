//
//  CarthageJSObject.swift
//  Carthage
//
//  Created by Markus Moenig on 20/7/21.
//

import Foundation
import JavaScriptCore

@objc protocol CarthageJSObjectJSExports: JSExport {
    
    var name                    : String { get }

    var position                : Any { get set }
    var transform               : Any { get set }
    var orientation             : Any { get set }

    var isActive                : Bool { get set }

    func clone() -> CarthageJSObject

    func getDirection() -> Any

    func setEuler(_ angles: [String: AnyObject])

    func addForce(_ position: Any,_ direction: Any)
    func applyImpulse(_ position: Any,_ direction: Any)

    static func getInstance() -> CarthageJSObject
}

class CarthageJSObject: CarthageJSBase, CarthageJSObjectJSExports {
    
    /// Called from JavaScript
    override init() {
        super.init()
        _id = "__oi"
    }
    
    /// Called from Swift when cloning or referencing an existing CarthageEntity
    init(entity: CarthageEntity) {
        super.init()
        _id = ""
        _ref = entity
    }
    
    // MARK: PROPERTIES
    
    /// name property
    var name: String  {
        get {
            if let entity = getSelf() {
                return entity.object.name
            }
            return ""
        }
    }
    
    /// isActive property
    var isActive: Bool  {
        get {
            if let entity = getSelf() {
                return entity.getIsActive()
            }
            return false
        }
        set {
            if let entity = getSelf() {
                entity.setIsActive(newValue)
            }
        }
    }
    
    var position: Any {
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
    
    var orientation: Any  {
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
    
    // MARK: FUNCTIONS
    
    func clone() -> CarthageJSObject {
        if let entity = getSelf() {
            let clonedEntity = entity.clone()
            return CarthageJSObject(entity: clonedEntity)
        }
        return CarthageJSObject()
    }
    
    func getDirection() -> Any {
        if let entity = getSelf() {
            //entity.setEuler(toFloat3(angles))
            return fromFloat3(entity.getDirection())
        }
        return [:]
    }
    
    func setEuler(_ angles: [String: AnyObject]) {
        if let entity = getSelf() {
            entity.setEuler(toFloat3(angles))
        }
    }
    
    func addForce(_ direction: Any, _ position: Any) {
        if let entity = getSelf() {
            entity.addForce(toFloat3(direction), toFloat3(position))
        }
    }
    
    func applyImpulse(_ direction: Any, _ position: Any) {
        if let entity = getSelf() {
            entity.applyImpulse(toFloat3(direction), toFloat3(position))
        }
    }

    /// Class initializer
    class func getInstance() -> CarthageJSObject {
        return CarthageJSObject()
    }
}
