//
//  CarthageObject.swift
//  Carthage
//
//  Created by Markus Moenig on 12/7/21.
//

import Foundation

/// Represents an object in a scene
class CarthageObject : Codable, Hashable, Identifiable {
    
    enum CarthageObjectType: Int32, Codable {
        case Scene, ProceduralGeometry, Geometry, Audio
    }
    
    var id              = UUID()
    var name            : String
    
    var type            : CarthageObjectType
    
    var children        : [CarthageObject]? = nil

    var data            : CarthageData

    var code            : String = ""

    var assetName       : String = ""
    
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
        
        if type == .Geometry || type == .ProceduralGeometry {
            // Init default data types for geometry objects
            
            if self.data.exists("Rotation") == false {
                self.data.data.insert(CarthageDataEntity("Rotation", float3(0,0,0), float2(0, 360)), at: 0)
            }
            
            if self.data.exists("Position") == false {
                self.data.data.insert(CarthageDataEntity("Position", float3(0,0,0), float2(-0.5, 0.5)), at: 0)
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
