//
//  CarthageEntity.swift
//  Carthage
//
//  Created by Markus Moenig on 22/7/21.
//

import Foundation
import JavaScriptCore
import simd

/// The abstract API for entities, this gets subclassed by the different engines for each node in a graph.
@objc protocol CarthageEntityJSExports: JSExport {
}

@objc class CarthageEntity : NSObject, CarthageEntityJSExports {
    
    let object          : CarthageObject
    
    init(object: CarthageObject) {
        self.object = object
        
        super.init()
        
        object.entity = self
    }
    
    /// Update the entity from the data model, this is heavy but only gets called to set the initial states of the entity before the scene starts.
    func updateFromModel(groupName: String = "")
    {
    }
    
    // PROPERTIES
    
    /// Get the active state
    func getIsActive() -> Bool {
        return true
    }
    
    /// Set the active state
    func setIsActive(_ b: Bool) {
    }
    
    /// Get the object transform
    func getTransform() -> float4x4 {
        return float4x4()
    }
    
    /// Set the object transform
    func setTransform(_ p: float4x4) {
    }
    
    /// Get the object position
    func getPosition() -> float3 {
        return float3()
    }
    
    /// Set the object position
    func setPosition(_ p: float3) {
    }
    
    /// Get the object orientation (quaternion)
    func getOrientation() -> float4 {
        return float4()
    }
    
    /// Set the euler angles
    func setEuler(_ p: float3) {
    }
    
    /// Set the object orientation (quaternion)
    func setOrientation(_ p: float4) {
    }
    
    /// Get the resolution
    func getResolution() -> float2 {
        return float2()
    }
    
    func getDirection() -> float3 {
        return  float3()
    }
    
    func getLookAt() -> float3 {
        return  float3()
    }
    
    func setLookAt(_ lookAt: float3) {
    }
    
    // FUNCTIONS
    
    func clone() -> CarthageEntity {
        let object = CarthageObject(type: .Geometry, name: "copy")
        let clone = CarthageEntity(object: object)
        return clone
    }
    
    func addForce(_ direction: float3,_ position: float3) {
    }
    
    func applyImpulse(_ direction: float3,_ position: float3) {
    }
}
