//
//  CarthageData.swift
//  Carthage
//
//  Created by Markus Moenig on 12/7/21.
//

import Foundation

typealias float2 = SIMD2<Float>
typealias float3 = SIMD3<Float>
typealias float4 = SIMD4<Float>

/// A singlee data entity of a given type and optionally at a given time, for convenience and speed use float4 to store
class CarthageDataEntity: Codable, Hashable {
    
    enum DataType: String, Codable {
        case Int, Float, Float2, Float3, Float4
    }
    
    enum UsageType: String, Codable {
        case Numeric, Slider, Color
    }
    
    var id          = UUID()

    var key         : String
    
    var type        : DataType
    var usage       : UsageType
    
    var value       : float4
    var defaultValue: float4
    var time        : Double?
    var range       : float2
        
    private enum CodingKeys: String, CodingKey {
        case key
        case type
        case usage
        case value
        case range
        case time
        case defaultValue
    }
    
    init(_ key: String,_ v: Int,_ r: float2 = float2(0,1),_ u: UsageType = .Slider,_ t: Double? = nil) {
        self.key = key
        type = .Int
        usage = u
        value = float4(Float(v), 0, 0, 0)
        range = r
        time = t
        
        defaultValue = value
    }
    
    init(_ key: String,_ v: Float,_ r: float2 = float2(0,1),_ u: UsageType = .Slider,_ t: Double? = nil) {
        self.key = key
        type = .Float
        usage = u
        value = float4(v, 0, 0, 0)
        range = r
        time = t
        
        defaultValue = value
    }
    
    init(_ key: String,_ v: float2,_ r: float2 = float2(0,1),_ u: UsageType = .Numeric,_ t: Double? = nil) {
        self.key = key
        type = .Float2
        usage = u
        value = float4(v.x, v.y, 0, 0)
        range = r
        time = t
        
        defaultValue = value
    }
    
    init(_ key: String,_ v: float3,_ r: float2 = float2(0,1),_ u: UsageType = .Numeric,_ t: Double? = nil) {
        self.key = key
        type = .Float3
        usage = u
        value = float4(v.x, v.y, v.z, 0)
        range = r
        time = t
        
        defaultValue = value
    }
    
    init(_ key: String,_ v: float4,_ r: float2 = float2(0,1),_ u: UsageType = .Numeric,_ t: Double? = nil) {
        self.key = key
        type = .Float4
        usage = u
        value = v
        range = r
        time = t
        
        defaultValue = value
    }
    
    required init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        key = try container.decode(String.self, forKey: .key)
        type = try container.decode(DataType.self, forKey: .type)
        usage = try container.decode(UsageType.self, forKey: .usage)
        value = try container.decode(float4.self, forKey: .value)
        range = try container.decode(float2.self, forKey: .range)
        time = try container.decode(Double?.self, forKey: .time)
        defaultValue = try container.decode(float4.self, forKey: .defaultValue)
    }
    
    func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(key, forKey: .key)
        try container.encode(type, forKey: .type)
        try container.encode(usage, forKey: .usage)
        try container.encode(value, forKey: .value)
        try container.encode(range, forKey: .range)
        try container.encode(time, forKey: .time)
        try container.encode(defaultValue, forKey: .defaultValue)
    }
    
    static func ==(lhs: CarthageDataEntity, rhs: CarthageDataEntity) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

/// A dictionary of CarthageDataEntity's to create a data fault for values which can be keyed over time.
class CarthageData: Codable {
 
    var data: [CarthageDataEntity]
    
    private enum CodingKeys: String, CodingKey {
        case data
    }
    
    init(_ data: [CarthageDataEntity])
    {
        self.data = data
    }
    
    required init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        data = try container.decode([CarthageDataEntity].self, forKey: .data)
    }
    
    func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(data, forKey: .data)
    }
    
    /// Get an Int key
    func getInt(_ key: String,_ time: Double? = nil) -> Int? {
        for e in data {
            if e.key == key && e.type == .Int && e.time == time {
                return Int(e.value.x)
            }
        }
        // TODO: Interpolate between existing values
        return nil
    }
    
    /// Get an Float key
    func getFloat(_ key: String,_ defaultValue: Float = 0,_ time: Double? = nil) -> Float {
        for e in data {
            if e.key == key && e.type == .Float && e.time == time {
                return e.value.x
            }
        }
        // TODO: Interpolate between existing values
        return defaultValue
    }
    
    /// Get an Float2 key
    func getFloat2(_ key: String,_ defaultValue: float2 = float2(0,0),_ time: Double? = nil) -> float2 {
        for e in data {
            if e.key == key && e.type == .Float2 && e.time == time {
                return float2(e.value.x, e.value.y)
            }
        }
        // TODO: Interpolate between existing values
        return defaultValue
    }
    
    /// Get an Float3 key
    func getFloat3(_ key: String,_ defaultValue: float3 = float3(0,0,0),_ time: Double? = nil) -> float3 {
        for e in data {
            if e.key == key && e.type == .Float3 && e.time == time {
                return float3(e.value.x, e.value.y, e.value.z)
            }
        }
        // TODO: Interpolate between existing values
        return defaultValue
    }
    
    /// Get an Float4 key
    func getFloat4(_ key: String,_ time: Double? = nil) -> float4? {
        for e in data {
            if e.key == key && e.type == .Float4 && e.time == time {
                return e.value
            }
        }
        // TODO: Interpolate between existing values
        return nil
    }
    
    /// Checks if a given key exists
    func exists(_ key : String) -> Bool {
        for e in data {
            if e.key == key {
                return true
            }
        }
        return false
    }
    
    /// Set Int
    func set(_ key: String,_ value: Int,_ range: float2 = float2(0,1),_ usage: CarthageDataEntity.UsageType = .Slider,_ time: Double? = nil) {
        if let ex = getExisting(key, .Int, time) {
            ex.value = float4(Float(value), 0, 0, 0)
        } else {
            data.append(CarthageDataEntity(key, value, range, usage, time))
        }
    }
    
    /// Set Float
    func set(_ key: String,_ value: Float,_ range: float2 = float2(0,1),_ usage: CarthageDataEntity.UsageType = .Slider,_ time: Double? = nil) {
        if let ex = getExisting(key, .Float, time) {
            ex.value = float4(value, 0, 0, 0)
        } else {
            data.append(CarthageDataEntity(key, value, range, usage, time))
        }
    }
    
    /// Set Float2
    func set(_ key: String,_ value: float2,_ range: float2 = float2(0,1),_ usage: CarthageDataEntity.UsageType = .Numeric,_ time: Double? = nil) {
        if let ex = getExisting(key, .Float2, time) {
            ex.value = float4(value.x, value.y, 0, 0)
        } else {
            data.append(CarthageDataEntity(key, value, range, usage, time))
        }
    }
    
    /// Set Float3
    func set(_ key: String,_ value: float3,_ range: float2 = float2(0,1),_ usage: CarthageDataEntity.UsageType = .Numeric,_ time: Double? = nil) {
        if let ex = getExisting(key, .Float3, time) {
            ex.value = float4(value.x, value.y, value.z, 0)
        } else {
            data.append(CarthageDataEntity(key, value, range, usage, time))
        }
    }
    
    /// Set Float4
    func set(_ key: String,_ value: float4,_ range: float2 = float2(0,1),_ usage: CarthageDataEntity.UsageType = .Numeric,_ time: Double? = nil) {
        if let ex = getExisting(key, .Float4, time) {
            ex.value = value
        } else {
            data.append(CarthageDataEntity(key, value, range, usage, time))
        }
    }
    
    /// Returns either an existing DataEntity for the given key, type and time or creates a new one.
    func getExisting(_ key: String,_ type: CarthageDataEntity.DataType,_ time: Double?) -> CarthageDataEntity? {
        for e in data {
            if e.key == key && e.type == type && e.time == time {
                return e
            }
        }
        return nil
    }
    
    func debug() {
        print("start")
        for e in data {
            print(e.key, e.value)
        }
    }
}

/// A group of data dictionaries
class CarthageDataGroups: Codable {
 
    var groups: [String: CarthageData]
    
    private enum CodingKeys: String, CodingKey {
        case groups
    }
    
    init(_ groups: [String: CarthageData] = [:])
    {
        self.groups = groups
    }
    
    required init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        groups = try container.decode([String: CarthageData].self, forKey: .groups)
    }
    
    func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(groups, forKey: .groups)
    }
    
    func getGroup(_ name: String) -> CarthageData? {
        return groups[name]
    }
    
    func addGroup(_ name: String,_ data: CarthageData) {
        groups[name] = data
    }
}
