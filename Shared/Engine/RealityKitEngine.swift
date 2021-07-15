//
//  RealityKitEngine.swift
//  Carthage
//
//  Created by Markus Moenig on 13/7/21.
//

import Foundation
import RealityKit
import Combine

class RealityKitEntity : CarthageEntity {
    
    var entity             : Entity
    
    init(object: CarthageObject, entity: Entity? = nil) {
        if let entity = entity {
            self.entity = entity
        } else {
            self.entity = ModelEntity()
        }

        super.init(object: object)
        
        updateFromModel()
        
        attach()
    }
    
    func attach() {
        if let parent = object.parent {
            if let e = parent.entity as? RealityKitEntity {
                e.entity.addChild(entity)
            }
        }
    }
    
    override func updateFromModel()
    {
        if let transform = object.dataGroups.getGroup("Transform") {
            entity.position = transform.getFloat3("Position")
        }
        
        if object.type == .Procedural {
            if let procedural = object.dataGroups.getGroup("Procedural") {
                if object.proceduralType == .Sphere {
                    let radius = procedural.getFloat("Radius", 1)
                    
                    if let modelEntity = entity as? ModelEntity {
                        modelEntity.model = ModelComponent(mesh: .generateSphere(radius: radius), materials: [])
                    }
                } else
                if object.proceduralType == .Cube {
                    let size = procedural.getFloat3("Size", float3(1,1,1))
                    let cornerRadius = procedural.getFloat("Corner Radius")
                    if let modelEntity = entity as? ModelEntity {
                        modelEntity.model = ModelComponent(mesh: .generateBox(size: size, cornerRadius: cornerRadius), materials: [])
                    }
                }
                
                if object.proceduralType == .Plane {
                    let size = procedural.getFloat2("Size", float2(20,0.1))
                    let cornerRadius = procedural.getFloat("Corner Radius")
                    
                    if let modelEntity = entity as? ModelEntity {
                        modelEntity.model = ModelComponent(mesh: .generatePlane(width: size.x, height: size.y, cornerRadius: cornerRadius), materials: [])
                    }
                }
            }
        }
    }
    
    override var position: [String: Double]  {
        get {
            return ["x": Double(entity.position.x), "y": Double(entity.position.y), "z": Double(entity.position.z)]
        }
        set {
            if let x = newValue["x"] { entity.position.x = Float(x) }
            if let y = newValue["y"] { entity.position.y = Float(y) }
            if let z = newValue["z"] { entity.position.z = Float(z) }
        }
    }
}

/// The SceneKit implementation of the CarthageEngine abstract
class RealityKitScene: CarthageScene {
    
    var arView              : ARView? = nil

    var sceneAnchor         : AnchorEntity? = nil

    var cameraAnchor        : AnchorEntity? = nil
    var camera              : PerspectiveCamera? = nil
    
    var sceneObserver       : Cancellable!
    
    /// Initialize the engine
    override init(model: CarthageModel, sceneObject: CarthageObject)
    {
        sceneAnchor = AnchorEntity(world: [0, 0, 0])
        
        camera = PerspectiveCamera()
        let cameraTranslation = SIMD3<Float>(0, 0, 0)
        camera?.look(at: .zero, from: cameraTranslation, relativeTo: nil)
        camera?.camera.fieldOfViewInDegrees = 60
        
        cameraAnchor = AnchorEntity(world: [0,0,3])
        cameraAnchor?.addChild(camera!)
        
        sceneObject.entity = RealityKitEntity(object: sceneObject, entity: sceneAnchor!)

        super.init(model: model, sceneObject: sceneObject)
    }
    
    /// Adds the given object to it's parent.
    override func addObject(object: CarthageObject) {

        object.entity = RealityKitEntity(object: object)
    }

    override func play()
    {
        super.play()
        
        sceneObserver = arView!.scene.subscribe(to: SceneEvents.Update.self) { [unowned self] (_) in
            tick(Date.timeIntervalSinceReferenceDate)
        }
    }
    
    override func stop()
    {
        super.stop()
        
        sceneObserver = nil
    }
}

