//
//  SceneKitEngine.swift
//  Carthage
//
//  Created by Markus Moenig on 12/7/21.
//

import SceneKit
import RealityFoundation

#if os(OSX)
typealias SCNFloat = CGFloat
#elseif os(iOS)
typealias SCNFloat = Float
#endif


class SceneKitEntity : CarthageEntity {
    
    var node            : SCNNode
    
    /// Default material for procedural objects
    //var material        : SCNMaterial? = nil
    
    init(object: CarthageObject, node: SCNNode? = nil) {
        
        if let node = node {
            self.node = node
        } else {
            self.node = SCNNode()
        }
        
        super.init(object: object)
        
        updateFromModel()
        
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
            let position = transform.getFloat3("Position")
            node.position = SCNVector3(x: SCNFloat(position.x), y: SCNFloat(position.y), z: SCNFloat(position.z))
            
            let rotation = transform.getFloat3("Rotation")
            node.eulerAngles = SCNVector3(x: SCNFloat(rotation.x.degreesToRadians), y: SCNFloat(rotation.y.degreesToRadians), z: SCNFloat(rotation.z.degreesToRadians))
        }
        
        if object.type == .Procedural {
                        
            if let procedural = object.dataGroups.getGroup("Procedural") {
                if object.proceduralType == .Sphere {
                    let radius = procedural.getFloat("Radius", 1)
                    
                    let sphereGeometry = SCNSphere(radius: SCNFloat(radius))
                    node.geometry = sphereGeometry
                } else
                if object.proceduralType == .Cube {
                    let size = procedural.getFloat3("Size", float3(1,1,1))
                    let cornerRadius = procedural.getFloat("Corner Radius")

                    let cubeGeometry = SCNBox(width: SCNFloat(size.x), height: SCNFloat(size.y), length: SCNFloat(size.z), chamferRadius: SCNFloat(cornerRadius))
                    
                    
                    node.geometry = cubeGeometry
                } else
                if object.proceduralType == .Plane {
                    let size = procedural.getFloat2("Size", float2(20,20))
                    let cornerRadius = procedural.getFloat("Corner Radius")
                    
                    let planeGeometry = SCNPlane(width: SCNFloat(size.x), height: SCNFloat(size.y))
                    planeGeometry.cornerRadius = SCNFloat(cornerRadius)
                    node.geometry = planeGeometry
                }
            }
            
            if let materialData = object.dataGroups.getGroup("Material") {
                
                let diffuse = materialData.getFloat3("Color", float3(0.5,0.5,0.5))
                let metallic = materialData.getFloat("Metallic", 0)
                let roughness = materialData.getFloat("Roughness", 0.5)

                let material = SCNMaterial()
                material.lightingModel = .physicallyBased
                material.diffuse.contents = CGColor(red: SCNFloat(diffuse.x), green: SCNFloat(diffuse.y), blue: SCNFloat(diffuse.z), alpha: 1)
                material.metalness.contents = SCNFloat(metallic)
                material.roughness.contents = SCNFloat(roughness)
                node.geometry?.materials = [material]
            }
        }
    }
    
    override var position: [String: Double]  {
        get {
            return ["x": Double(node.position.x), "y": Double(node.position.y), "z": Double(node.position.z)]
        }
        set {
            if let x = newValue["x"] { node.position.x = SCNFloat(x) }
            if let y = newValue["y"] { node.position.y = SCNFloat(y) }
            if let z = newValue["z"] { node.position.z = SCNFloat(z) }
        }
    }
}

/// The SceneKit implementation of the CarthageEngine abstract
class SceneKitScene: CarthageScene, SCNSceneRendererDelegate {
    
    var scene               : SCNScene? = nil
    var view                : SCNView? = nil
    
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

        /*
        let light = SCNLight()
        light.type = SCNLight.LightType.omni
        let lightNode = SCNNode()
        lightNode.light = light
        lightNode.position = SCNVector3(x: 1.5, y: 1.5, z: 1.5)
         */


        //let constraint = SCNLookAtConstraint(target: sphereNode)
        //constraint.isGimbalLockEnabled = true
        //cameraNode.constraints = [constraint]
        
        sceneObject.entity = SceneKitEntity(object: sceneObject, node: scene!.rootNode)

        //scene!.rootNode.addChildNode(lightNode)
        scene!.rootNode.addChildNode(cameraNode)
        
        super.init(model: model, sceneObject: sceneObject)        
    }
    
    /// Adds the given object to it's parent.
    override func addObject(object: CarthageObject) {                
        object.entity = SceneKitEntity(object: object)
    }
    
    override func play()
    {
        super.play()
        view?.isPlaying = true
    }
    
    override func stop()
    {
        super.stop()
        view?.isPlaying = false
    }
    
    func renderer(_: SCNSceneRenderer, willRenderScene: SCNScene, atTime: TimeInterval)
    {
        tick(Double(atTime))
    }
}

