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

    var data            : CarthageData

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
        case data
        case code
        case assetName
    }
    
    init(_ type: CarthageObjectType, _ name: String = "Unnamed", data: CarthageData = CarthageData([]))
    {
        self.type = type
        self.name = name
        self.data = data
        
        if type == .Geometry || type == .Procedural {
            // Init default data types for geometry objects
            
            if self.data.exists("Rotation") == false {
                self.data.data.insert(CarthageDataEntity("Rotation", float3(0,0,0), float2(0, 360), .Slider), at: 0)
            }
            
            if self.data.exists("Position") == false {
                self.data.data.insert(CarthageDataEntity("Position", float3(0,0,0), float2(-0.5, 0.5)), at: 0)
            }
        }
        
        if type == .Procedural {
            if self.data.exists("Type") == false {
                self.data.data.insert(CarthageDataEntity("Type", 0, float2(0,0), .Numeric), at: 0)
            }
        }
    }
    
    required init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        type = try container.decode(CarthageObjectType.self, forKey: .type)
        children = try container.decode([CarthageObject]?.self, forKey: .children)
        data = try container.decode(CarthageData.self, forKey: .data)
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
        try container.encode(data, forKey: .data)
        try container.encode(code, forKey: .code)
        try container.encode(assetName, forKey: .assetName)
    }
    
    static func ==(lhs: CarthageObject, rhs: CarthageObject) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
