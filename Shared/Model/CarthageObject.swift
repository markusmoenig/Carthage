//
//  CarthageObject.swift
//  Carthage
//
//  Created by Markus Moenig on 12/7/21.
//

import Foundation
import JavaScriptCore

/// Represents an object in a scene
class CarthageObject : Codable, Hashable, Identifiable {
    
    enum CarthageObjectType: Int32, Codable {
        case Camera, Scene, Procedural, Geometry, Audio
    }
    
    enum CarthageProceduralObjectType: Int32, Codable {
        case Plane, Sphere, Cube
    }
    
    enum SettingsMode: Int32, Codable {
        case parameters, materials, physics, data, javascript, settings, help
    }
    
    var settingsMode    : SettingsMode = .parameters
    
    var id              = UUID()
    var name            : String
    
    var type            : CarthageObjectType
    var proceduralType  : CarthageProceduralObjectType

    weak var parent     : CarthageObject? = nil
    weak var scene      : CarthageObject? = nil

    var children        : [CarthageObject]? = nil

    var dataGroups      : CarthageDataGroups

    /// The JavaScript code for this object
    var jsCode          : String = ""

    /// The JSON data for this object
    var json            : String = ""
    
    /// The name of the referenced asset in the library
    var libraryName     : String = ""

    /// The optional JavaScript context for this object. Only scene objects always have a JS context, for other objects the
    /// user has to enable them in the object settings.
    var jsContext       : JSContext? = nil
    
    /// To identify the editor session in the script editor
    var codeContext   = ""
    var dataContext   = ""

    /// The reference to the underlying engine entity implementing this object
    var entity          : CarthageEntity? = nil
    
    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case type
        case settingsMode
        case proceduralType
        case children
        case dataGroups
        case jsCode
        case libraryName
    }
    
    init(type: CarthageObjectType, name: String = "Unnamed", proceduralType: CarthageProceduralObjectType = .Plane, libraryName: String = "")
    {
        self.type = type
        self.proceduralType = proceduralType
        self.name = name
        self.libraryName = name
        
        dataGroups = CarthageDataGroups()
        initDataGroups(fromConstructor: true)
        
        if type != .Camera {
            children = []
        }
        
        if type == .Geometry || type == .Procedural {
            // Default object code
            if let path = Bundle.main.path(forResource: "object", ofType: "js", inDirectory: "Files/defaults") {
                if let value = try? String(contentsOfFile: path, encoding: String.Encoding.utf8) {
                    jsCode = value
                }
            }
            
            // Default object json
            if let path = Bundle.main.path(forResource: "object_data", ofType: "js", inDirectory: "Files/defaults") {
                if let value = try? String(contentsOfFile: path, encoding: String.Encoding.utf8) {
                    json = value
                }
            }
        } else
        if type == .Scene {
            // Default scene json
            if let path = Bundle.main.path(forResource: "scene_data", ofType: "js", inDirectory: "Files/defaults") {
                if let value = try? String(contentsOfFile: path, encoding: String.Encoding.utf8) {
                    json = value
                }
            }
            
            // Default object code
            if let path = Bundle.main.path(forResource: "scene", ofType: "js", inDirectory: "Files/defaults") {
                if let value = try? String(contentsOfFile: path, encoding: String.Encoding.utf8) {
                    jsCode = value
                }
            }
        }
    }
    
    required init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        type = try container.decode(CarthageObjectType.self, forKey: .type)
        settingsMode = try container.decode(CarthageObject.SettingsMode.self, forKey: .settingsMode)
        proceduralType = try container.decode(CarthageProceduralObjectType.self, forKey: .proceduralType)
        children = try container.decode([CarthageObject]?.self, forKey: .children)
        dataGroups = try container.decode(CarthageDataGroups.self, forKey: .dataGroups)
        jsCode = try container.decode(String.self, forKey: .jsCode)
        libraryName = try container.decode(String.self, forKey: .libraryName)
        
        initDataGroups()
    }
    
    func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(type, forKey: .type)
        try container.encode(settingsMode, forKey: .settingsMode)
        try container.encode(proceduralType, forKey: .proceduralType)
        try container.encode(children, forKey: .children)
        try container.encode(dataGroups, forKey: .dataGroups)
        try container.encode(jsCode, forKey: .jsCode)
        try container.encode(libraryName, forKey: .libraryName)
    }
    
    static func ==(lhs: CarthageObject, rhs: CarthageObject) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    /// Initializes the data groups with default values, or, when already exists, make sure all options are present
    func initDataGroups(fromConstructor: Bool = false) {
        if type == .Scene {
            
            settingsMode = .javascript
            dataGroups.addGroup("Physics", CarthageData([
                CarthageDataEntity("Gravity", float3(0,-9.8,0), float2(-100, 100)),
            ]))
        }
        
        if type == .Geometry || type == .Procedural {
            
            // Init default data types for geometry objects
            addDataGroup(name: "Transform", entities: [
                CarthageDataEntity("Position", float3(0,0,0), float2(-0.5, 0.5)),
                CarthageDataEntity("Rotation", float3(0,0,0), float2(0, 360), .Slider),
                CarthageDataEntity("Scale", float3(1,1,1), float2(0, 10), .Slider),
            ])
            
            addDataGroup(name: "Physics", entities: [
                CarthageDataEntity("Type", Int(0), float2(0, 3), .Menu, .None, "Static, Dynamic, Kinematic"),
                CarthageDataEntity("Mass", Float(0.5), float2(0, 1000), .Numeric),
            ])
        } else
        if type == .Scene {
            addDataGroup(name: "Settings", entities: [
                CarthageDataEntity("Background", float3(0.5,0.5,0.5), float2(0, 1), .Color, .Texture),
            ])
        } else
        if type == .Camera {
            // Init default data types for geometry objects
            addDataGroup(name: "Camera", entities: [
                CarthageDataEntity("Position", float3(0,1,3), float2(-1000, 1000)),
                CarthageDataEntity("Look At", float3(0,0,0), float2(-1000, 1000)),
            ])
        }
        
        if type == .Procedural {
            if proceduralType == .Sphere {
                addDataGroup(name: "Procedural", entities: [
                    CarthageDataEntity("Radius", Float(0.5), float2(0, 10), .Slider),
                ])
            } else
            if proceduralType == .Cube {
                addDataGroup(name: "Procedural", entities: [
                    CarthageDataEntity("Size", float3(1, 1, 1), float2(0, 10), .Numeric),
                    CarthageDataEntity("Corner Radius", Float(0), float2(0, 0.5), .Slider),
                ])
            } else
            if proceduralType == .Plane {
                addDataGroup(name: "Procedural", entities: [
                    CarthageDataEntity("Size", float2(20, 20), float2(0, 1000), .Numeric),
                    CarthageDataEntity("Corner Radius", Float(0), float2(0, 10), .Slider),
                ])
                if fromConstructor == true {
                    if let transform = dataGroups.getGroup("Transform") {
                        transform.set("Rotation", float3(270, 0, 0))
                    }
                }
            }
            
            addDataGroup(name: "Material", entities: [
                CarthageDataEntity("Color", float3(0.5,0.5,0.5), float2(0, 1), .Color, .Texture),
                CarthageDataEntity("Metallic", Float(0), float2(0, 1), .Slider, .Texture),
                CarthageDataEntity("Roughness", Float(0.5 ), float2(0, 1), .Slider, .Texture),
            ])
        }
    }
    
    /// Creates or adds the given entities to the new or existing group. This way we can dynamically add new options to existing projects.
    func addDataGroup(name: String, entities: [CarthageDataEntity]) {
        let group = dataGroups.getGroup(name)
        if let group = group {
            // If group exists, make sure all entities are present

            for e in entities {
                if group.exists(e.key) == false {
                    group.data.append(e)
                }
            }
        } else {
            // If group does not exist add it
            dataGroups.addGroup(name, CarthageData(entities))
        }
    }
    
    /// Returns a flat array with the children of this object
    func collectChildren() -> [CarthageObject] {
        
        var objects : [CarthageObject] = []
        
        /// Recursively reparent the children
        func collect(_ o: CarthageObject) {
            objects.append(o)
            if let children = o.children {
                for c in children {
                    collect(c)
                }
            }
        }
        
        if let children = children {
            for c in children {
                collect(c)
            }
        }
        
        return objects
    }
}
