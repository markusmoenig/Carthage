//
//  CarthageModel.swift
//  Carthage
//
//  Created by Markus Moenig on 11/7/21.
//

import Combine
import JavaScriptCore

class CarthageModel: NSObject, ObservableObject {
    
    enum EngineType {
        case SceneKit, RealityKit
    }

    @Published var selected         : CarthageObject? = nil

    var engineType                  : EngineType = .SceneKit
    
    /// Send when an object has been selected
    let objectSelected              = PassthroughSubject<CarthageObject, Never>()
    
    /// Send when an object has been selected
    let engineChanged               = PassthroughSubject<Void, Never>()
    
    /// Send when an object has been selected
    let projectChanged              = PassthroughSubject<Void, Never>()
    
    /// The current rendering engine
    var engineScene                 : CarthageScene? = nil
    
    /// 
    var context                     = JSContext()
    
    var scriptEditor                : ScriptEditor? = nil
    
    /// The project itself
    var project                     : CarthageProject

    override init() {

        project = CarthageProject()
         
        super.init()
        
        selectScene(project.scenes.first!)
    }
    
    func selectScene(_ scene: CarthageObject)
    {
        engineScene?.destroy()
        if engineType == .SceneKit {
            engineScene = SceneKitScene(model: self, sceneObject: scene)
        } else {
            engineScene = RealityKitScene(model: self, sceneObject: scene)
        }
        
        selected = scene
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.objectSelected.send(scene)
        }
    }
    
    func play() {
    }
    
    func stop() {
        
    }
}
