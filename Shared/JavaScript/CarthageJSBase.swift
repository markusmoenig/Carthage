//
//  CarthageJSBase.swift
//  Carthage
//
//  Created by Markus Moenig on 22/7/21.
//

import Foundation
import JavaScriptCore

class CarthageJSBase: NSObject {
    
    /// The id of the object in the global context of the JavaScript Context
    var _id         : String = ""
    
    /// Set when this object has been returned from Swift, i.e. a reference or clone of another object
    var _ref        : CarthageEntity? = nil
    
    /// Return a reference to the embedded CarthageEntity
    func getSelf(_ id: String? = nil) -> CarthageEntity? {
        
        // Existing entity
        if let ref = _ref {
            return ref
        }
        
        // Get the reference from the JS context
        let idToUse = id == nil ? _id : id
        let context = JSContext.current()
        if let entity = context?.objectForKeyedSubscript(idToUse).toObject() as? CarthageEntity {
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
    func toFloat3(_ o: Any) -> float3 {
        if let o = o as? [String: AnyObject] {
            var p = float3(0,0,0)
            if let x = o["x"] { p.x = toFloat(x) }
            if let y = o["y"] { p.y = toFloat(y) }
            if let z = o["z"] { p.z = toFloat(z) }
            return p
        }
        return float3()
    }
    
    /// Converts a JSValue to float4
    func toFloat4(_ o: Any) -> float4 {
        if let o = o as? [String: AnyObject] {
            var p = float4(0,0,0,0)
            if let x = o["x"] { p.x = toFloat(x) }
            if let y = o["y"] { p.y = toFloat(y) }
            if let z = o["z"] { p.z = toFloat(z) }
            if let w = o["w"] { p.w = toFloat(w) }
            return p
        }
        return float4()
    }
    
    /// Float to JSValue
    func fromFloat(_ v: Float) -> JSValue {
        return JSValue(double: Double(v), in: JSContext.current())
    }
    
    /// float2 to JSValue
    func fromFloat2(_ p: float2) -> Any {
        if let object = JSContext.current().evaluateScript("new CT.Math.Vector2(\(p.x), \(p.y))") {
            return object
        }
        //return ["x": fromFloat(p.x), "y": fromFloat(p.y)]
        return [:]
    }
    
    /// float3 to JSValue
    func fromFloat3(_ p: float3) -> Any {
        if let object = JSContext.current().evaluateScript("new CT.Math.Vector3(\(p.x), \(p.y), \(p.z))") {
            return object
        }
        //return ["x": fromFloat(p.x), "y": fromFloat(p.y), "z": fromFloat(p.z)]
        return [:]
    }
    
    /// float4 to JSValue
    func fromFloat4(_ p: float4) -> Any {
        if let object = JSContext.current().evaluateScript("new CT.Math.Vector4(\(p.x), \(p.y), \(p.z), \(p.w)") {
            return object
        }
        //return ["x": fromFloat(p.x), "y": fromFloat(p.y), "z": fromFloat(p.z), "w": fromFloat(p.w)]
        return [:]
    }
}
