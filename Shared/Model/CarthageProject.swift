//
//  CarthageProject.swift
//  Carthage
//
//  Created by Markus Moenig on 12/7/21.
//

import Foundation
import CoreGraphics

class CarthageProject: Codable {

    private enum CodingKeys: String, CodingKey {
        case scenes
    }
    
    /// The objects in the project
    var scenes                              : [CarthageObject] = []
        
    init() {
        let scene = CarthageObject(type: .Scene, name: "Scene")
        scene.children = [CarthageObject(type: .Camera, name: "Camera")]
        scene.children?[0].parent = scene
        
        scenes.append(scene)
    }
    
    required init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        scenes = try container.decode([CarthageObject].self, forKey: .scenes)
        reparent()
    }
    
    func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(scenes, forKey: .scenes)
    }
    
    /// Reparents the objects, only needed after loading
    func reparent() {
        
        var scene : CarthageObject? = nil
        
        /// Recursively reparent the children
        func reparent(_ o: CarthageObject) {
            o.scene = scene
            if let children = o.children {
                for c in children {
                    c.parent = o
                    reparent(c)
                }
            }
        }
        
        for s in scenes {
            scene = s
            reparent(s)
        }
    }
}
