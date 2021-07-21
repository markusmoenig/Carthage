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
    
    enum SettingsMode {
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
    var code            : String = ""

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
        case proceduralType
        case children
        case dataGroups
        case code
        case libraryName
    }
    
    init(type: CarthageObjectType, name: String = "Unnamed", proceduralType: CarthageProceduralObjectType = .Plane, libraryName: String = "")
    {
        self.type = type
        self.proceduralType = proceduralType
        self.name = name
        self.libraryName = name
        
        dataGroups = CarthageDataGroups()
        
        if type == .Scene {
            settingsMode = .javascript
            
            dataGroups.addGroup("Physics", CarthageData([
                CarthageDataEntity("Gravity", float3(0,-9.8,0), float2(-100, 100)),
            ]))
        }
        
        if type == .Geometry || type == .Procedural {
            // Init default data types for geometry objects
            
            dataGroups.addGroup("Transform", CarthageData([
                CarthageDataEntity("Position", float3(0,0,0), float2(-0.5, 0.5)),
                CarthageDataEntity("Rotation", float3(0,0,0), float2(0, 360), .Slider),
                CarthageDataEntity("Scale", float3(1,1,1), float2(0, 10), .Slider),
            ]))
            
            dataGroups.addGroup("Physics", CarthageData([
                CarthageDataEntity("Type", Int(0), float2(0, 3), .Menu, .None, "Static, Dynamic, Kinematic"),
            ]))
            
            // Default object code
            if let path = Bundle.main.path(forResource: "object", ofType: "js", inDirectory: "Files/defaults") {
                if let value = try? String(contentsOfFile: path, encoding: String.Encoding.utf8) {
                    code = value
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
                    code = value
                }
            }
        } else
        if type == .Camera {
            // Init default data types for geometry objects
            
            dataGroups.addGroup("Camera", CarthageData([
                CarthageDataEntity("Position", float3(0,1,3), float2(-1000, 1000)),
                CarthageDataEntity("Look At", float3(0,0,0), float2(-1000, 1000)),
                //CarthageDataEntity("Scale", float3(1,1,1), float2(0, 10), .Slider),
            ]))
        }
        
        if type == .Procedural {
            if proceduralType == .Sphere {
                dataGroups.addGroup("Procedural", CarthageData([
                    CarthageDataEntity("Radius", Float(0.5), float2(0, 10), .Slider),
                ]))
            } else
            if proceduralType == .Cube {
                dataGroups.addGroup("Procedural", CarthageData([
                    CarthageDataEntity("Size", float3(1, 1, 1), float2(0, 10), .Numeric),
                    CarthageDataEntity("Corner Radius", Float(0), float2(0, 0.5), .Slider),
                ]))
            } else
            if proceduralType == .Plane {
                dataGroups.addGroup("Procedural", CarthageData([
                    CarthageDataEntity("Size", float2(20, 20), float2(0, 1000), .Numeric),
                    CarthageDataEntity("Corner Radius", Float(0), float2(0, 10), .Slider),
                ]))
                if let transform = dataGroups.getGroup("Transform") {
                    transform.set("Rotation", float3(270, 0, 0))
                }
            }
            
            dataGroups.addGroup("Material", CarthageData([
                CarthageDataEntity("Color", float3(0.5,0.5,0.5), float2(0, 1), .Color, .Texture),
                CarthageDataEntity("Metallic", Float(0), float2(0, 1), .Slider, .Texture),
                CarthageDataEntity("Roughness", Float(0.5 ), float2(0, 1), .Slider, .Texture),
            ]))
        }
        
        if type != .Camera {
            children = []
        }
    }
    
    required init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        type = try container.decode(CarthageObjectType.self, forKey: .type)
        proceduralType = try container.decode(CarthageProceduralObjectType.self, forKey: .proceduralType)
        children = try container.decode([CarthageObject]?.self, forKey: .children)
        dataGroups = try container.decode(CarthageDataGroups.self, forKey: .dataGroups)
        code = try container.decode(String.self, forKey: .code)
        libraryName = try container.decode(String.self, forKey: .libraryName)
    }
    
    func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(type, forKey: .type)
        try container.encode(proceduralType, forKey: .proceduralType)
        try container.encode(children, forKey: .children)
        try container.encode(dataGroups, forKey: .dataGroups)
        try container.encode(code, forKey: .code)
        try container.encode(libraryName, forKey: .libraryName)
    }
    
    static func ==(lhs: CarthageObject, rhs: CarthageObject) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
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
