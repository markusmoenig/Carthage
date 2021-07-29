//
//  RealityKitEngine.swift
//  Carthage
//
//  Created by Markus Moenig on 13/7/21.
//

import Foundation
import RealityKit
import Combine
import GLKit

#if os(OSX)
import AppKit
#else
import UIKit
#endif

class RealityKitEntity : CarthageEntity {
    
    var scene               : RealityKitScene
    var entity              : Entity
    
    // To remember which texture urls we set so we dont update them every time when we update other
    // material properties (which would be very slow)
    var textureDict         : [String: String] = [:]
    
    var material            : PhysicallyBasedMaterial? = nil

    init(scene: RealityKitScene, object: CarthageObject, entity: Entity? = nil, updateFromModel: Bool = true) {
        
        self.scene = scene
        if let entity = entity {
            self.entity = entity
        } else {
            
            if object.type == .Camera {
                self.entity = PerspectiveCamera()
            } else {
                self.entity = ModelEntity()
            }
        }

        self.entity.name = object.name
        super.init(object: object)
        
        if updateFromModel {
            self.updateFromModel()
        }
        
        attach()
    }
    
    func attach() {
        if let parent = object.parent {
            if let e = parent.entity as? RealityKitEntity {
                e.entity.addChild(entity)
                //print("attaching", entity.name, "to", e.entity.name)
            }
        }
    }
    
    override func updateFromModel(groupName: String = "")
    {        
        if let transform = object.dataGroups.getGroup("Transform"), groupName == "Transform" || groupName.isEmpty {
            let rotation = transform.getFloat3("Rotation")
            entity.transform = Transform()
            entity.transform.translation = transform.getFloat3("Position")
            entity.transform.scale = transform.getFloat3("Scale")
            entity.transform.rotation *= simd_quatf(angle: rotation.x.degreesToRadians, axis: SIMD3<Float>(1,0,0))
            entity.transform.rotation *= simd_quatf(angle: rotation.y.degreesToRadians, axis: SIMD3<Float>(0,1,0))
            entity.transform.rotation *= simd_quatf(angle: rotation.z.degreesToRadians, axis: SIMD3<Float>(0,0,1))
        }
        
        if object.type == .Procedural {
            
            if material == nil {
                material = PhysicallyBasedMaterial()
            }
            
            if let materialData = object.dataGroups.getGroup("Material"), groupName == "Material" || groupName == "Procedural"  || groupName.isEmpty  {
                
                let diffuse = materialData.getFloat3("Color", float3(0.5,0.5,0.5))
                
                var key = "Color"
                if let url = scene.getUrl(data: materialData, key: key) {
                    if textureDict[key] != materialData.getText(key) {
                        do {
                            let texture = try TextureResource.load(contentsOf: url)
                            material?.baseColor.texture = PhysicallyBasedMaterial.Texture(texture)
                            textureDict[key] = materialData.getText(key)
                        } catch {}
                    }
                } else {
                    #if os(OSX)
                    //material?.baseColor.tint = NSColor.red// NSColor(red: SCNFloat(diffuse.x), green: SCNFloat(diffuse.y), blue: SCNFloat(diffuse.z), alpha: 1)
                    #elseif os(iOS)
                    material?.baseColor.tint = UIColor(red: SCNFLOAT(diffuse.x), green: SCNFLOAT(diffuse.y), blue: SCNFLOAT(diffuse.z), alpha: 1)
                    #endif
                    textureDict[key] = nil
                }
                
                key = "Roughness"
                if let url = scene.getUrl(data: materialData, key: "Roughness") {
                    if textureDict[key] != materialData.getText(key) {
                        do {
                            let texture = try TextureResource.load(contentsOf: url)
                            material?.roughness.texture = PhysicallyBasedMaterial.Texture(texture)
                            textureDict[key] = materialData.getText(key)
                        } catch {}
                    }
                } else {
                    material?.roughness.scale = materialData.getFloat("Roughness", 0.5)
                    textureDict[key] = materialData.getText(key)
                }
                
                key = "Metallic"
                if let url = scene.getUrl(data: materialData, key: "Metallic") {
                    if textureDict[key] != materialData.getText(key) {
                        do {
                            let texture = try TextureResource.load(contentsOf: url)
                            material?.metallic.texture = PhysicallyBasedMaterial.Texture(texture)
                            textureDict[key] = materialData.getText(key)
                        } catch {}
                    }
                } else {
                    material?.metallic.scale = materialData.getFloat("Metallic", 0)
                }
                
                // If we only update the material group we need to set the new material to the model
                if let modelEntity = entity as? ModelEntity, groupName == "Material" {
                    modelEntity.model?.materials = [material!]
                }
            }
            
            if let procedural = object.dataGroups.getGroup("Procedural"), groupName == "Procedural" || groupName.isEmpty  {
                if object.proceduralType == .Sphere {
                    let radius = procedural.getFloat("Radius", 1)
                    
                    if let modelEntity = entity as? ModelEntity {
                        modelEntity.model = ModelComponent(mesh: .generateSphere(radius: radius), materials: [material!])
                    }
                } else
                if object.proceduralType == .Cube {
                    let size = procedural.getFloat3("Size", float3(1,1,1))
                    let cornerRadius = procedural.getFloat("Corner Radius")
                    if let modelEntity = entity as? ModelEntity {
                        modelEntity.model = ModelComponent(mesh: .generateBox(size: size, cornerRadius: cornerRadius), materials: [material!])
                    }
                }
                
                if object.proceduralType == .Plane {
                    let size = procedural.getFloat2("Size", float2(20,0.1))
                    let cornerRadius = procedural.getFloat("Corner Radius")
                    
                    if let modelEntity = entity as? ModelEntity {
                        modelEntity.model = ModelComponent(mesh: .generatePlane(width: size.x, height: size.y, cornerRadius: cornerRadius), materials: [material!])
                    }
                }
            }
        }
        
        if let camera = object.dataGroups.getGroup("Camera"), groupName == "Camera" || groupName.isEmpty  {
            let position = camera.getFloat3("Position")
            let lookAt = camera.getFloat3("Look At")
            
            if let perspectiveCam = entity as? PerspectiveCamera {
                perspectiveCam.look(at: lookAt, from: position, relativeTo: nil)
                perspectiveCam.camera.fieldOfViewInDegrees = 60
            }
        }
        
        // Physics
        if object.type == .Geometry || object.type == .Procedural {

            if let physicsData = object.dataGroups.getGroup("Physics"), groupName == "Physics" || groupName.isEmpty  {

                if let modelEntity = entity as? ModelEntity {
                    var mode = PhysicsBodyMode.static
                    
                    if scene.isPlaying == true {
                        let type = physicsData.getInt("Type", 0)
                        if type == 1 {
                            mode = .dynamic
                        } else
                        if type == 2 {
                            mode = .kinematic
                        }
                        
                        modelEntity.generateCollisionShapes(recursive: true)
                    }
                    
                    modelEntity.physicsBody = PhysicsBodyComponent(massProperties: .init(mass: physicsData.getFloat("Mass", 1)), material: nil, mode: mode)
                    //modelEntity.physicsMotion = .init(linearVelocity: [0.1 ,0, 0], angularVelocity: [3, 3, 3])
                    //modelEntity.components.set(modelEntity.physicsBody!)
                    //modelEntity.components.set(modelEntity.physicsMotion!)
                }
            }
        }
        
        if object.type == .Scene {
            
            if let settingsData = object.dataGroups.getGroup("Settings"), groupName == "Settings" || groupName.isEmpty {
                let key = "Background"
                if let url = self.scene.getUrl(data: settingsData, key: key) {
                    //scene.arView?.environment.background =
                } else {
                    let color = settingsData.getFloat3(key, float3(0.5,0.5,0.5))
                    if let arView = scene.arView {
                        arView.environment.background = ARView.Environment.Background.color(NSColor(red: SCNFloat(color.x), green: SCNFloat(color.y), blue: SCNFloat(color.z), alpha: 1))
                    }
                }
            }
        }
    }
    
    // The following are the member functions called from JavaScript

    override func getIsActive() -> Bool {
        return entity.isEnabled
    }
    
    override func setIsActive(_ b: Bool) {
        entity.isEnabled = b
    }
    
    override func getPosition() -> float3 {
        return  float3(Float(entity.transform.translation.x), Float(entity.transform.translation.y), Float(entity.transform.translation.z))
    }
    
    override func setPosition(_ p: float3) {
        entity.transform.translation.x = p.x
        entity.transform.translation.y = p.y
        entity.transform.translation.z = p.z
    }
    
    // https://stackoverflow.com/questions/42029347/position-a-scenekit-object-in-front-of-scncameras-current-orientation
    override func getDirection() -> float3 {
        let x = Float(-entity.transform.rotation.imag.x)
        let y = Float(-entity.transform.rotation.imag.y)
        let z = Float(-entity.transform.rotation.imag.z)
        let w = Float(entity.transform.rotation.real)
        
        let m00 = cos(w) + pow(x, 2) * (1 - cos(w))
        let m01 = x * y * (1 - cos(w)) - z * sin(w)
        let m02 = x * z * (1 - cos(w)) + y*sin(w)
        
        let m10 = y*x*(1-cos(w)) + z*sin(w)
        let m11 = cos(w) + pow(y, 2) * (1 - cos(w))
        let m12 = y*z*(1-cos(w)) - x*sin(w)
        
        let m20 = z*x*(1 - cos(w)) - y*sin(w)
        let m21 = z*y*(1 - cos(w)) + x*sin(w)
        let m22 = cos(w) + pow(z, 2) * ( 1 - cos(w))

        let nodeRotationMatrix = GLKMatrix3Make( m00,
                                                 m01,
                                                 m02,

                                                 m10,
                                                 m11,
                                                 m12,

                                                 m20,
                                                 m21,
                                                 m22)

        let direction = GLKMatrix3MultiplyVector3(nodeRotationMatrix, GLKVector3Make(0.0, 0.0, -1.0))
        return float3(direction.x, direction.y, direction.z)
    }
    
    override func getOrientation() -> float4 {
        return  float4(Float(entity.orientation.imag.x), Float(entity.orientation.imag.y), Float(entity.orientation.imag.z), Float(entity.orientation.real))
    }
    
    override func setOrientation(_ q: float4) {
        entity.orientation = simd_quatf(vector: q)
    }
    
    override func setEuler(_ q: float3) {
        entity.transform = Transform(pitch: q.x, yaw: q.y, roll: q.z)// eulerAngles = SCNVector3(SCNFloat(q.x),SCNFloat(q.y),SCNFloat(q.z))
    }
    
    override func getResolution() -> float2 {
        if let view = scene.arView {
            return float2(Float(view.frame.width), Float(view.frame.height))
        }
        return float2()
    }
    
    override func setLookAt(_ lookAt: float3) {
        if let perspectiveCam = entity as? PerspectiveCamera {
            perspectiveCam.look(at: lookAt, from: getPosition(), relativeTo: nil)
        }
    }
    
    override func clone() -> CarthageEntity {
        let cloneObject = CarthageObject(type: object.type, name: "Copy of " + object.name)
        cloneObject.parent = object.parent
        let entity = entity.clone(recursive: true)
        let clone = RealityKitEntity(scene: scene, object: cloneObject, entity: entity, updateFromModel: false)
        scene.clones.append(clone)
        return clone
    }
    
    override func addForce(_ direction: float3,_ position: float3) {

    }
    
    override func applyImpulse(_ direction: float3,_ position: float3) {
        if let modelEntity = entity as? ModelEntity {
            modelEntity.applyImpulse(direction, at: position, relativeTo: modelEntity)
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
    
    var clones              : [RealityKitEntity] = []
    
    /// Initialize the engine
    override init(model: CarthageModel, sceneObject: CarthageObject)
    {
        sceneAnchor = AnchorEntity(world: [0, 0, 0])
        super.init(model: model, sceneObject: sceneObject)

        sceneObject.entity = RealityKitEntity(scene: self, object: sceneObject, entity: sceneAnchor!)
        load()
    }
    
    /// Sets the view
    func setView(_ sceneView: ARView) {
        
        arView = sceneView
        if let rkView = sceneView as? RKInpuView {
            rkView.carthageScene = self
            
            sceneObject.entity?.updateFromModel()
        }
    }
    
    /// Adds the given object to it's parent.
    override func addObject(object: CarthageObject) {
        
        if object.type == .Geometry {
           
            if let url = model.getLibraryURL(object.libraryName) {
                let modelEntity = try? Entity.load(contentsOf: url)
                let entity = RealityKitEntity(scene: self, object: object, entity: modelEntity)
                object.entity = entity
            }
        } else {
            let entity = RealityKitEntity(scene: self, object: object)
            object.entity = entity
            
            if object.type == .Camera {
                cameraAnchor = AnchorEntity(world: [0,0,0])
                cameraAnchor?.addChild(entity.entity)
            }
        }
    }

    override func play()
    {
        let children = sceneObject.collectChildren()
            
        // We need to iterate all objects to set proper physic types because in isPlaying == false mode all
        // objects are created as .static. RealityKit cannot be paused ...
        // TODO: Some initialisation stuff like collision shape generation should only be done one time
        
        isPlaying = true
        for c in children {
            c.entity?.updateFromModel(groupName: "Physics")
        }
        
        super.play()
        
        if let arView = arView {
            sceneObserver = arView.scene.subscribe(to: SceneEvents.Update.self) { [unowned self] (_) in
                tick(Date.timeIntervalSinceReferenceDate)
            }
        }
    }
    
    override func stop()
    {
        for c in clones {
            c.entity.removeFromParent()
        }
        clones = []
        super.stop()
        
        sceneObserver = nil
    }
}

