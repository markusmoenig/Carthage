//
//  CarthageJSObject.swift
//  Carthage
//
//  Created by Markus Moenig on 20/7/21.
//

import Foundation
import JavaScriptCore

@objc protocol CarthageJSObjectJSExports: JSExport {
    
    var name: String { get }

    var position: [String: Double] { get set }

    func applyForce() -> String

    static func getInstance() -> CarthageJSObject
}

class CarthageJSObject: NSObject, CarthageJSObjectJSExports {
    
    /// name property
    var name: String  {
        get {
            if let entity = getSelf() {
                return entity.object.name
            }
            return ""
        }
    }
    
    var position: [String: Double]  {
        get {
            if let entity = getSelf() {
                let p = entity.getPosition()
                return ["x": Double(p.x), "y": Double(p.y), "z": Double(p.z)]
            }
            return [:]
        }
        set {
            if let entity = getSelf() {
                var p = float3(0,0,0)
                if let x = newValue["x"] { p.x = Float(x) }
                if let y = newValue["y"] { p.x = Float(y) }
                if let z = newValue["z"] { p.x = Float(z) }
                entity.setPosition(p)
            }
        }
    }
    
    func applyForce() -> String {
        if let entity = getSelf() {
            return entity.object.name
        }
       
       return ""
    }

    /// Class initializer
    class func getInstance() -> CarthageJSObject {
        return CarthageJSObject()
    }
    
    /// Return a reference to the embedded CarthageEntity
    func getSelf() -> CarthageEntity? {
        let context = JSContext.current()
        if let entity = context?.objectForKeyedSubscript("__oi").toObject() as? CarthageEntity {
            return entity
        }
        return nil
    }
}
