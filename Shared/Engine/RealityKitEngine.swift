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
    
    init(object: CarthageObject, entity: Entity) {
        self.entity = entity
        super.init(object: object)
        
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
            if let position = transform.getFloat3("Position") {
                entity.position = position
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
        
        //let newBox = ModelEntity(mesh: .generateBox(size: 1))
        let newSphere = ModelEntity(mesh: .generateSphere(radius: 1))

        object.entity = RealityKitEntity(object: object, entity: newSphere)
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

