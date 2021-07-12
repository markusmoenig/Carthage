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
        let scene = CarthageObject(.Scene, "Start Scene")
        
        scene.children = [CarthageObject(.Procedural, "Sphere")]
        
        scenes.append(scene)
    }
    
    required init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        scenes = try container.decode([CarthageObject].self, forKey: .scenes)
        //camera = try container.decode(SignedPinholeCamera.self, forKey: .camera)
    }
    
    func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(scenes, forKey: .scenes)
        //try container.encode(camera, forKey: .camera)
    }
}
