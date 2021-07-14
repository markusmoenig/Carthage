//
//  RealityKitEngine.swift
//  Carthage
//
//  Created by Markus Moenig on 13/7/21.
//

import Foundation
import RealityKit

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
    }
}

/// The SceneKit implementation of the CarthageEngine abstract
class RealityKitScene: CarthageScene {
    
    var sceneAnchor         : AnchorEntity? = nil

    var cameraAnchor        : AnchorEntity? = nil
    var camera              : PerspectiveCamera? = nil
    
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

}

