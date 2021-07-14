//
//  SceneKitEngine.swift
//  Carthage
//
//  Created by Markus Moenig on 12/7/21.
//

import SceneKit

class SceneKitEntity : CarthageEntity {
    
    var node             : SCNNode
    
    init(object: CarthageObject, node: SCNNode) {
        self.node = node
        super.init(object: object)
        
        attach()
    }
    
    func attach() {
        if let parent = object.parent {
            if let e = parent.entity as? SceneKitEntity {
                e.node.addChildNode(node)
            }
        }
    }
    
    override func updateFromModel()
    {
        if let transform = object.dataGroups.getGroup("Transform") {
            if let position = transform.getFloat3("Position") {
                node.position = SCNVector3(x: CGFloat(position.x), y: CGFloat(position.y), z: CGFloat(position.z))
            }
        }
    }
    
    override var position: [String: Double]  {
        get {
            return ["x": node.position.x, "y": node.position.y, "z": node.position.z]
        }
        set {
            if let x = newValue["x"] { node.position.x = x }
            if let y = newValue["y"] { node.position.y = y }
            if let z = newValue["z"] { node.position.z = z }
        }
    }
}

/// The SceneKit implementation of the CarthageEngine abstract
class SceneKitScene: CarthageScene, SCNSceneRendererDelegate {
    
    var scene               : SCNScene? = nil
    //var view                : SCNView? = nil
    
    //let scene           : SCNScene
    let camera          : SCNCamera
    let cameraNode      : SCNNode
    
    //let camera          : SCNCamera
    //let cameraNode      : SCNNode
    
    /// Initialize the engine
    override init(model: CarthageModel, sceneObject: CarthageObject)
    {
        scene = SCNScene()
        
        camera = SCNCamera()
        cameraNode = SCNNode()
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(x: 0.0, y: 0.0, z: 3.0)
        cameraNode.look(at: SCNVector3(x: 0, y: 0, z: 0))

        let light = SCNLight()
        light.type = SCNLight.LightType.omni
        let lightNode = SCNNode()
        lightNode.light = light
        lightNode.position = SCNVector3(x: 1.5, y: 1.5, z: 1.5)


        //let constraint = SCNLookAtConstraint(target: sphereNode)
        //constraint.isGimbalLockEnabled = true
        //cameraNode.constraints = [constraint]
        
        sceneObject.entity = SceneKitEntity(object: sceneObject, node: scene!.rootNode)

        scene!.rootNode.addChildNode(lightNode)
        scene!.rootNode.addChildNode(cameraNode)
        
        super.init(model: model, sceneObject: sceneObject)        
    }
    
    /// Adds the given object to it's parent.
    override func addObject(object: CarthageObject) {
        let sphereGeometry = SCNSphere(radius: 0.5)
        let node = SCNNode(geometry: sphereGeometry)
        
        print("addObject", object.type)
        
        object.entity = SceneKitEntity(object: object, node: node)        
    }
    
    override func play()
    {
        super.play()
    }
    
    func renderer(_: SCNSceneRenderer, willRenderScene: SCNScene, atTime: TimeInterval)
    {
    }
    
    /// Returns the native scene object for attaching it to the view
    override func getNativeScene() -> AnyObject? {
        return scene
    }
}

