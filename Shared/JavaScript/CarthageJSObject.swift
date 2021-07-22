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

    var position                : [String: AnyObject] { get set }

    func addForce(_ position: [String: AnyObject],_ direction: [String: AnyObject])
    func applyImpulse(_ position: [String: AnyObject],_ direction: [String: AnyObject])

    static func getInstance() -> CarthageJSObject
}

class CarthageJSObject: CarthageJSBase, CarthageJSObjectJSExports {
    
    override init() {
        super.init()
        _id = "__oi"
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
    
    func addForce(_ direction: [String: AnyObject], _ position: [String: AnyObject]) {
        if let entity = getSelf() {
            entity.addForce(toFloat3(direction), toFloat3(position))
        }
    }
    
    func applyImpulse(_ direction: [String: AnyObject], _ position: [String: AnyObject]) {
        if let entity = getSelf() {
            entity.applyImpulse(toFloat3(direction), toFloat3(position))
        }
    }

    /// Class initializer
    class func getInstance() -> CarthageJSObject {
        return CarthageJSObject()
    }
}
