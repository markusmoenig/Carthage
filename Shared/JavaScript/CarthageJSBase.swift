//
//  CarthageJSBase.swift
//  Carthage
//
//  Created by Markus Moenig on 22/7/21.
//

import Foundation
import JavaScriptCore

class CarthageJSBase: NSObject {
    
    var _id         : String = ""
    
    /// Return a reference to the embedded CarthageEntity
    func getSelf(_ id: String? = nil) -> CarthageEntity? {
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
    func toFloat3(_ o: [String: AnyObject]) -> float3 {
        var p = float3(0,0,0)
        if let x = o["x"] { p.x = toFloat(x) }
        if let y = o["y"] { p.y = toFloat(y) }
        if let z = o["z"] { p.z = toFloat(z) }
        return p
    }
    
    /// Converts a JSValue to float4
    func toFloat4(_ o: [String: AnyObject]) -> float4 {
        var p = float4(0,0,0,0)
        if let x = o["x"] { p.x = toFloat(x) }
        if let y = o["y"] { p.y = toFloat(y) }
        if let z = o["z"] { p.z = toFloat(z) }
        if let w = o["w"] { p.w = toFloat(w) }
        return p
    }
    
    /// Float to JSValue
    func fromFloat(_ v: Float) -> JSValue {
        return JSValue(double: Double(v), in: JSContext.current())
    }
    
    /// float2 to JSValue
    func fromFloat2(_ p: float2) -> [String:JSValue] {
        return ["x": fromFloat(p.x), "y": fromFloat(p.y)]
    }
    
    /// float3 to JSValue
    func fromFloat3(_ p: float3) -> [String:JSValue] {
        return ["x": fromFloat(p.x), "y": fromFloat(p.y), "z": fromFloat(p.z)]
    }
    
    /// float4 to JSValue
    func fromFloat4(_ p: float4) -> [String:JSValue] {
        return ["x": fromFloat(p.x), "y": fromFloat(p.y), "z": fromFloat(p.z), "w": fromFloat(p.w)]
    }
}
