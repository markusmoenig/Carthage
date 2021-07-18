//
//  SceneKitEngine.swift
//  Carthage
//
//  Created by Markus Moenig on 12/7/21.
//

import SceneKit
import SceneKit.ModelIO
import RealityFoundation

#if os(OSX)
typealias SCNFloat = CGFloat
#elseif os(iOS)
typealias SCNFloat = Float
#endif


class SceneKitEntity : CarthageEntity {
    
    var scene           : SceneKitScene
    var node            : SCNNode
    
    var material        : SCNMaterial? = nil
    
    // To remember which texture urls we set so we dont update them every time when we update other
    // material properties (which would be very slow)
    var textureDict     : [String: String] = [:]
        
    init(scene: SceneKitScene, object: CarthageObject, node: SCNNode? = nil) {
        self.scene = scene
        
        if let node = node {
            self.node = node
        } else {
            self.node = SCNNode()
            
            if object.type == .Camera {
                let camera = SCNCamera()
                self.node.camera = camera
                self.node.position = SCNVector3(x: 0.0, y: 0.0, z: 0.0)
                self.node.look(at: SCNVector3(x: 0, y: 0, z: 0))
                //camera.usesOrthographicProjection = true
                //camera.orthographicScale = 2
            }
        }
        
        self.node.name = object.name
        
        super.init(object: object)
        
        updateFromModel()
        
        attach()
    }
    
    func attach() {
        if let parent = object.parent {
            if let e = parent.entity as? SceneKitEntity {
                e.node.addChildNode(node)
                //print("attaching", node.name, "to", e.node.name)
            }
        }
    }
     
    override func updateFromModel(groupName: String = "")
    {
        //print("updateFromModel", groupName)
        
        if let transform = object.dataGroups.getGroup("Transform"), groupName == "Transform" || groupName.isEmpty {
            let position = transform.getFloat3("Position")
            node.position = SCNVector3(x: SCNFloat(position.x), y: SCNFloat(position.y), z: SCNFloat(position.z))
            
            let rotation = transform.getFloat3("Rotation")
            node.eulerAngles = SCNVector3(x: SCNFloat(rotation.x.degreesToRadians), y: SCNFloat(rotation.y.degreesToRadians), z: SCNFloat(rotation.z.degreesToRadians))
            
            let scale = transform.getFloat3("Scale")
            node.scale = SCNVector3(x: SCNFloat(scale.x), y: SCNFloat(scale.y), z: SCNFloat(scale.z))
        }
        
        if object.type == .Procedural {
                        
            if let procedural = object.dataGroups.getGroup("Procedural"), groupName == "Procedural" || groupName.isEmpty  {
                
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
            
            if let materialData = object.dataGroups.getGroup("Material"), groupName == "Material" || groupName == "Procedural" || groupName.isEmpty {
                
                if material == nil {
                    material = SCNMaterial()
                }

                let diffuse = materialData.getFloat3("Color", float3(0.5,0.5,0.5))
                
                material?.lightingModel = .physicallyBased
                
                var key = "Color"
                if let url = scene.getUrl(data: materialData, key: key) {
                    if textureDict[key] != materialData.getText(key) {
                        material?.diffuse.contents = url
                        textureDict[key] = materialData.getText(key)
                    }
                } else {
                    material?.diffuse.contents = CGColor(red: SCNFloat(diffuse.x), green: SCNFloat(diffuse.y), blue: SCNFloat(diffuse.z), alpha: 1)
                    textureDict[key] = nil
                }
                
                key = "Metallic"
                if let url = scene.getUrl(data: materialData, key: key) {
                    if textureDict[key] != materialData.getText(key) {
                        material?.metalness.contents = url
                        textureDict[key] = materialData.getText(key)
                    }
                } else {
                    material?.metalness.contents = SCNFloat(materialData.getFloat(key, 0))
                    textureDict[key] = nil
                }
          
                key = "Roughness"
                if let url = scene.getUrl(data: materialData, key: key) {
                    if textureDict[key] != materialData.getText(key) {
                        material?.roughness.contents = url
                        textureDict[key] = materialData.getText(key)
                    }
                } else {
                    material?.roughness.contents = SCNFloat(materialData.getFloat(key, 0.5))
                    textureDict[key] = nil
                }
                
                if let material = material {
                    node.geometry?.materials = [material]
                }
            }
        }
        
        if let camera = object.dataGroups.getGroup("Camera"), groupName == "Camera" || groupName.isEmpty  {
            let position = camera.getFloat3("Position")
            let lookAt = camera.getFloat3("Look At")
            
            node.position = SCNVector3(x: SCNFloat(position.x), y: SCNFloat(position.y), z: SCNFloat(position.z))
            node.look(at: SCNVector3(x: SCNFloat(lookAt.x), y: SCNFloat(lookAt.y), z: SCNFloat(lookAt.z)))
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
    
    override var rotation: [String: Double]  {
        get {
            return ["x": Double(node.rotation.x), "y": Double(node.rotation.y), "z": Double(node.rotation.z)]
        }
        set {
            if let x = newValue["x"] { node.rotation.x = SCNFloat(x) }
            if let y = newValue["y"] { node.rotation.y = SCNFloat(y) }
            if let z = newValue["z"] { node.rotation.z = SCNFloat(z) }
        }
    }
    
    override var scale: [String: Double]  {
        get {
            return ["x": Double(node.scale.x), "y": Double(node.scale.y), "z": Double(node.scale.z)]
        }
        set {
            if let x = newValue["x"] { node.scale.x = SCNFloat(x) }
            if let y = newValue["y"] { node.scale.y = SCNFloat(y) }
            if let z = newValue["z"] { node.scale.z = SCNFloat(z) }
        }
    }
}

/// The SceneKit implementation of the CarthageEngine abstract
class SceneKitScene: CarthageScene, SCNSceneRendererDelegate {
    
    var scene               : SCNScene? = nil
    var view                : SCNView? = nil
    
    var cameraNode          : SCNNode? = nil

    //let camera          : SCNCamera
    //let cameraNode      : SCNNode
    
    //let camera          : SCNCamera
    //let cameraNode      : SCNNode
    
    /// Initialize the engine
    override init(model: CarthageModel, sceneObject: CarthageObject)
    {
        scene = SCNScene()

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
        
        super.init(model: model, sceneObject: sceneObject)
        sceneObject.entity = SceneKitEntity(scene: self, object: sceneObject, node: scene!.rootNode)
        load()
    }
    
    /// Adds the given object to it's parent.
    override func addObject(object: CarthageObject) {
        
        if object.type == .Geometry {
            if let url = model.getLibraryURL(object.libraryName) {
                let node = SCNReferenceNode(url: url)
                node?.load()
                let entity = SceneKitEntity(scene: self, object: object, node: node)
                object.entity = entity
            }
        } else {
            let entity = SceneKitEntity(scene: self, object: object)
            object.entity = entity
            
            if object.type == .Camera {
                cameraNode = entity.node
                cameraNode?.constraints = []
            }
        }
    }
    
    func setView(_ sceneView: SCNView) {
        view = sceneView
        sceneView.autoenablesDefaultLighting = true
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

