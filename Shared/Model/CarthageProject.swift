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
        //case camera
    }
    
    /// The objects in the project
    var scenes                              : [CarthageObject] = []
        
    init() {
        let scene = CarthageObject(type: .Scene, name: "Start Scene")
        
        scene.children = [CarthageObject(type: .Camera, name: "Camera")]
        
        scenes.append(scene)
    }
    
    required init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        scenes = try container.decode([CarthageObject].self, forKey: .scenes)
        //camera = try container.decode(SignedPinholeCamera.self, forKey: .camera)
        reparent()
    }
    
    func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(scenes, forKey: .scenes)
        //try container.encode(camera, forKey: .camera)
    }
    
    /// Reparents the objects, only needed after loading
    func reparent() {
        
        /// Recursively reparent the children
        func reparent(_ o: CarthageObject) {
            if let children = o.children {
                for c in children {
                    c.parent = o
                    reparent(c)
                }
            }
        }
        
        for scene in scenes {
            reparent(scene)
        }
    }
}
