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
                self.node.camera = SCNCamera()
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
                    //node.physicsBody?.physicsShape = SCNPhysicsShape(geometry: sphereGeometry)
                } else
                if object.proceduralType == .Cube {
                    let size = procedural.getFloat3("Size", float3(1,1,1))
                    let cornerRadius = procedural.getFloat("Corner Radius")

                    let cubeGeometry = SCNBox(width: SCNFloat(size.x), height: SCNFloat(size.y), length: SCNFloat(size.z), chamferRadius: SCNFloat(cornerRadius))
                    
                    node.geometry = cubeGeometry
                    //node.physicsBody?.physicsShape = SCNPhysicsShape(geometry: cubeGeometry)
                } else
                if object.proceduralType == .Plane {
                    let size = procedural.getFloat2("Size", float2(20,20))
                    let cornerRadius = procedural.getFloat("Corner Radius")
                    
                    let planeGeometry = SCNPlane(width: SCNFloat(size.x), height: SCNFloat(size.y))
                    planeGeometry.cornerRadius = SCNFloat(cornerRadius)
                    node.geometry = planeGeometry
                    //node.physicsBody?.physicsShape = SCNPhysicsShape(geometry: planeGeometry)
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
        
        // Scene Physics (World)
        if object.type == .Scene {

            if let scene = scene.scene {
                if let physicsData = object.dataGroups.getGroup("Physics"), groupName == "Physics" || groupName.isEmpty  {

                    scene.physicsWorld.gravity = SCNVector3(physicsData.getFloat3("Gravity"))
                    scene.physicsWorld.speed = 1.0
                }

                /*
                let gravityNode = SCNNode()
                 let downGravityCategory = 1 << 0

                let gravityField = SCNPhysicsField.linearGravity()
                gravityField.categoryBitMask = downGravityCategory
                                                gravityField.isActive = true
                gravityField.strength = 3.0
                                                gravityField.isExclusive = true
                                                gravityNode.physicsField = gravityField
                                                scene.rootNode.addChildNode(gravityNode)
                 */
                //_sceneView.scene!.rootNode.addChildNode(_gravityFieldNode)
            }
        }
            
        if let camera = object.dataGroups.getGroup("Camera"), groupName == "Camera" || groupName.isEmpty  {
            let position = camera.getFloat3("Position")
            let lookAt = camera.getFloat3("Look At")
                        
            print("update", position, lookAt)
            node.position = SCNVector3(x: SCNFloat(position.x), y: SCNFloat(position.y), z: SCNFloat(position.z))
            node.look(at: SCNVector3(x: SCNFloat(lookAt.x), y: SCNFloat(lookAt.y), z: SCNFloat(lookAt.z)), up: SCNVector3(0,1,0), localFront: SCNVector3(0,0,-1))
        }
        
        // Physics
        if object.type == .Geometry || object.type == .Procedural {

            if let physicsData = object.dataGroups.getGroup("Physics"), groupName == "Physics" || groupName.isEmpty  {

                let type = physicsData.getInt("Type", 0)
                node.physicsBody = SCNPhysicsBody(type: SCNPhysicsBodyType(rawValue: type)!, shape: nil)
                if type == 0 {
                    node.physicsBody?.isAffectedByGravity = false
                }

                // attach the sphere node to the scene's root node
                //_mySphereNode.categoryBitMask = downGravityCategory
                //_sceneView.scene!.rootNode.addChildNode(_mySphereNode)
                
                //let gravityField = SCNPhysicsField.radialGravity()
                //gravityField.strength = 750
                //gravityField.isActive = true
                //node.physicsField = gravityField
                
                node.physicsBody?.mass = 0.125

                //node.categoryBitMask = downGravityCategory

                //node.physicsBody?.friction = 0
                //node.physicsBody?.restitution = 1
                //node.physicsBody?.angularDamping = 1
                
                //node.physicsBody?.physicsShape = SCNPhysicsShape(geometry: SCNSphere(radius: 0.5))
            }
        }
    }
    
    // The following are the member functions called from JavaScript 
    
    override func getPosition() -> float3 {
        return  float3(Float(node.position.x), Float(node.position.y), Float(node.position.z))
    }
    
    override func setPosition(_ p: float3) {
        print("position", p)

        node.position.x = SCNFloat(p.x)
        node.position.y = SCNFloat(p.y)
        node.position.z = SCNFloat(p.z)
    }
    
    override func getResolution() -> float2 {
        if let view = scene.view {
            return float2(Float(view.frame.width), Float(view.frame.height))
        }
        return float2()
    }
    
    override func getLookAt() -> float3 {
        return  float3(0,0,0)
    }
    
    override func setLookAt(_ lookAt: float3) {
        if object.type == .Camera {
            print("lookAt", lookAt)

            node.look(at: SCNVector3(x: SCNFloat(lookAt.x), y: SCNFloat(lookAt.y), z: SCNFloat(lookAt.z)))
        }
    }
    
    override func addForce(_ direction: float3,_ position: float3) {

    }
    
    override func applyImpulse(_ direction: float3,_ position: float3) {
        node.physicsBody?.applyForce(SCNVector3(direction), at: SCNVector3(position), asImpulse: true)
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
        scene?.isPaused = true

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
    
    /// Sets the view
    func setView(_ sceneView: SCNView) {
        view = sceneView
        view?.isPlaying = false
        sceneView.autoenablesDefaultLighting = true
        if let skView = sceneView as? SKInpuView {
            skView.carthageScene = self
        }
    }
    
    override func play()
    {
        super.play()
        scene?.isPaused = false
        view?.isPlaying = true
    }
    
    override func stop()
    {
        super.stop()
        scene?.isPaused = true
        view?.isPlaying = false
    }
    
    func renderer(_: SCNSceneRenderer, willRenderScene: SCNScene, atTime: TimeInterval)
    {
        tick(Double(atTime))
    }
}

