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

    var position: [String: AnyObject] { get set }

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
    
    /// Converts a JSValue to Float
    func toFloat(_ o: AnyObject) -> Float {
        var v : Float = 0
        if let value = JSValue(object: o, in: JSContext.current()) {
            v = Float(value.toDouble())
        }
        return v
    }
    
    /// Converts a JSValue to float3
    func toFloat3(_ o: [String: AnyObject]) -> float3 {
        var p = float3(0,0,0)
        if let x = o["x"] { p.x = toFloat(x) }
        if let y = o["y"] { p.y = toFloat(y) }
        if let z = o["z"] { p.z = toFloat(z) }
        return p
    }
    
    /// Float to JSValue
    func fromFloat(_ v: Float) -> JSValue {
        return JSValue(double: Double(v), in: JSContext.current())
    }
    
    /// float3 to JSValue
    func fromFloat3(_ p: float3) -> [String:JSValue] {
        return ["x": fromFloat(p.x), "y": fromFloat(p.y), "z": fromFloat(p.z)]
    }
}