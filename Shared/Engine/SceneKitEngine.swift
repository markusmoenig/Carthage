//
//  SceneKitEngine.swift
//  Carthage
//
//  Created by Markus Moenig on 12/7/21.
//

import SceneKit
import JavaScriptCore

@objc class SceneKitScene : SceneKitEntity {
    
    var scene             : SCNScene
    
    init(object: CarthageObject, scene: SCNScene) {
        self.scene = scene
        super.init(object: object, node: scene.rootNode)
    }
    
    /// Update the entity from the given object
    override func update()
    {
    }
}

@objc class SceneKitEntity : CarthageEntity {
    
    var node             : SCNNode
    
    init(object: CarthageObject, node: SCNNode) {
        self.node = node
        super.init(object: object)
    }
    
    /// Update the entity from the given object
    override func update()
    {
    }
}

/// The SceneKit implementation of the CarthageEngine abstract
class SceneKitEngine: CarthageEngine {
    
    var scnScene            : SCNScene? = nil
    var scene               : SceneKitScene? = nil

    var sceneObject         : CarthageObject? = nil

    //let camera          : SCNCamera
    //let cameraNode      : SCNNode
    
    /// Initialize the engine
    override init(model: CarthageModel)
    {
        super.init(model: model)
    }
    
    /// Sets up a scene
    override func setupScene(sceneObject: CarthageObject)
    {
        scene = SceneKitScene(object: sceneObject, scene: SCNScene())
        
        model.context!.setObject(SceneKitScene.self, forKeyedSubscript: "Scene" as NSString)
    }
}
