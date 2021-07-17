//
//  RealityKitEngine.swift
//  Carthage
//
//  Created by Markus Moenig on 13/7/21.
//

import Foundation
import RealityKit
import Combine
import AppKit

class RealityKitEntity : CarthageEntity {
    
    var scene              : RealityKitScene
    var entity             : Entity
    
    init(scene: RealityKitScene, object: CarthageObject, entity: Entity? = nil) {
        
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
        
        updateFromModel()
        
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
    
    override func updateFromModel()
    {
        if let transform = object.dataGroups.getGroup("Transform") {
            let rotation = transform.getFloat3("Rotation")
            entity.transform = Transform()
            entity.transform.translation = transform.getFloat3("Position")
            entity.transform.scale = transform.getFloat3("Scale")
            entity.transform.rotation *= simd_quatf(angle: rotation.x.degreesToRadians, axis: SIMD3<Float>(1,0,0))
            entity.transform.rotation *= simd_quatf(angle: rotation.y.degreesToRadians, axis: SIMD3<Float>(0,1,0))
            entity.transform.rotation *= simd_quatf(angle: rotation.z.degreesToRadians, axis: SIMD3<Float>(0,0,1))
        }
        
        if object.type == .Procedural {
            
            var material = PhysicallyBasedMaterial()
            if let materialData = object.dataGroups.getGroup("Material") {
                
                let diffuse = materialData.getFloat3("Color", float3(0.5,0.5,0.5))
                
                if let url = scene.getUrl(data: materialData, key: "Color") {
                    do {
                        let texture = try TextureResource.load(contentsOf: url)
                        material.baseColor.texture = PhysicallyBasedMaterial.Texture(texture)
                    } catch {}
                } else {
                    material.baseColor.tint = NSColor(red: SCNFloat(diffuse.x), green: SCNFloat(diffuse.y), blue: SCNFloat(diffuse.z), alpha: 1)
                }
                
                if let url = scene.getUrl(data: materialData, key: "Roughness") {
                    do {
                        let texture = try TextureResource.load(contentsOf: url)
                        material.roughness.texture = PhysicallyBasedMaterial.Texture(texture)
                    } catch {}
                } else {
                    material.roughness.scale = materialData.getFloat("Roughness", 0.5)
                }
                
                if let url = scene.getUrl(data: materialData, key: "Metallic") {
                    do {
                        let texture = try TextureResource.load(contentsOf: url)
                        material.metallic.texture = PhysicallyBasedMaterial.Texture(texture)
                    } catch {}
                } else {
                    material.metallic.scale = materialData.getFloat("Metallic", 0)
                }
            }
            
            if let procedural = object.dataGroups.getGroup("Procedural") {
                if object.proceduralType == .Sphere {
                    let radius = procedural.getFloat("Radius", 1)
                    
                    if let modelEntity = entity as? ModelEntity {
                        modelEntity.model = ModelComponent(mesh: .generateSphere(radius: radius), materials: [material])
                    }
                } else
                if object.proceduralType == .Cube {
                    let size = procedural.getFloat3("Size", float3(1,1,1))
                    let cornerRadius = procedural.getFloat("Corner Radius")
                    if let modelEntity = entity as? ModelEntity {
                        modelEntity.model = ModelComponent(mesh: .generateBox(size: size, cornerRadius: cornerRadius), materials: [material])
                    }
                }
                
                if object.proceduralType == .Plane {
                    let size = procedural.getFloat2("Size", float2(20,0.1))
                    let cornerRadius = procedural.getFloat("Corner Radius")
                    
                    if let modelEntity = entity as? ModelEntity {
                        modelEntity.model = ModelComponent(mesh: .generatePlane(width: size.x, height: size.y, cornerRadius: cornerRadius), materials: [material])
                    }
                }
            }
        }
        
        if let camera = object.dataGroups.getGroup("Camera") {
            let position = camera.getFloat3("Position")
            let lookAt = camera.getFloat3("Look At")
            
            if let perspectiveCam = entity as? PerspectiveCamera {
                perspectiveCam.look(at: lookAt, from: position, relativeTo: nil)
                perspectiveCam.camera.fieldOfViewInDegrees = 60
            }
        }
    }
    
    override var position: [String: Double]  {
        get {
            return ["x": Double(entity.transform.translation.x), "y": Double(entity.transform.translation.y), "z": Double(entity.transform.translation.z)]
        }
        set {
            if let x = newValue["x"] { entity.transform.translation.x = Float(x) }
            if let y = newValue["y"] { entity.transform.translation.y = Float(y) }
            if let z = newValue["z"] { entity.transform.translation.z = Float(z) }
        }
    }
    
    override var rotation: [String: Double]  {
        get {
            return ["x": Double(entity.position.x), "y": Double(entity.position.y), "z": Double(entity.position.z)]
        }
        set {
            if let x = newValue["x"] { entity.position.x = Float(x) }
            if let y = newValue["y"] { entity.position.y = Float(y) }
            if let z = newValue["z"] { entity.position.z = Float(z) }
        }
    }
    
    override var scale: [String: Double]  {
        get {
            return ["x": Double(entity.transform.scale.x), "y": Double(entity.transform.scale.y), "z": Double(entity.transform.scale.z)]
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
        
        super.init(model: model, sceneObject: sceneObject)

        sceneObject.entity = RealityKitEntity(scene: self, object: sceneObject, entity: sceneAnchor!)
        load()
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
        super.play()
        
        if let arView = arView {
            sceneObserver = arView.scene.subscribe(to: SceneEvents.Update.self) { [unowned self] (_) in
                tick(Date.timeIntervalSinceReferenceDate)
            }
        }
    }
    
    override func stop()
    {
        super.stop()
        
        sceneObserver = nil
    }
}

