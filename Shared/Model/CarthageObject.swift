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
        case Scene, Procedural, Geometry, Audio
    }
    
    enum CarthageProceduralObjectType: Int32, Codable {
        case Sphere, Cube
    }
    
    var id              = UUID()
    var name            : String
    
    var type            : CarthageObjectType
    
    weak var parent     : CarthageObject? = nil
    
    var children        : [CarthageObject]? = nil

    var dataGroups      : CarthageDataGroups

    var code            : String = ""

    var assetName       : String = ""
    
    /// The optional JavaScript context for this object. Only scene objects always have a JS context, for other objects the
    /// user has to enable them in the object settings.
    var jsContext       : JSContext? = nil
    
    /// To identify the editor session in the script editor
    var scriptContext   = ""
    
    /// The reference to the underlying engine entity implementing this object
    var entity          : CarthageEntity? = nil
    
    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case type
        case children
        case dataGroups
        case code
        case assetName
    }
    
    init(_ type: CarthageObjectType, _ name: String = "Unnamed")
    {
        self.type = type
        self.name = name
        dataGroups = CarthageDataGroups()
        
        if type == .Geometry || type == .Procedural {
            // Init default data types for geometry objects
            
            dataGroups.addGroup("Transform", CarthageData([
                CarthageDataEntity("Position", float3(0,0,0), float2(-0.5, 0.5)),
                CarthageDataEntity("Rotation", float3(0,0,0), float2(0, 360), .Slider),
            ]))
        }
        
        if type == .Procedural {
                
            dataGroups.addGroup("Type", CarthageData([
                CarthageDataEntity("Type", 0, float2(0,20), .Numeric)
            ]))
                
            dataGroups.addGroup("Sphere", CarthageData([
                CarthageDataEntity("Radius", Float(0), float2(0, 10), .Slider),
            ]))

            dataGroups.addGroup("Cube", CarthageData([
                CarthageDataEntity("Size", float3(1, 1, 1), float2(0, 10), .Numeric),
            ]))
        }
        
        children = []
    }
    
    required init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        type = try container.decode(CarthageObjectType.self, forKey: .type)
        children = try container.decode([CarthageObject]?.self, forKey: .children)
        dataGroups = try container.decode(CarthageDataGroups.self, forKey: .dataGroups)
        code = try container.decode(String.self, forKey: .code)
        assetName = try container.decode(String.self, forKey: .assetName)
    }
    
    func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(type, forKey: .type)
        try container.encode(children, forKey: .children)
        try container.encode(dataGroups, forKey: .dataGroups)
        try container.encode(code, forKey: .code)
        try container.encode(assetName, forKey: .assetName)
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
