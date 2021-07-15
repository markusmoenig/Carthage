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

    @Published var currentScene     : CarthageObject? = nil

    var engineType                  : EngineType = .SceneKit
    
    /// Send when an object has been selected
    let objectSelected              = PassthroughSubject<CarthageObject, Never>()
    
    /// Send when an object has been selected
    let engineChanged               = PassthroughSubject<Void, Never>()
    
    /// Send when an object has been selected
    let projectChanged              = PassthroughSubject<Void, Never>()
    
    /// The current rendering engine
    var engine                      : CarthageScene? = nil
    
    /// 
    var context                     = JSContext()
    
    var scriptEditor                : ScriptEditor? = nil
    
    /// The project itself
    var project                     : CarthageProject

    override init() {

        project = CarthageProject()
        selected = project.scenes.first
        
        super.init()
        
        setScene(project.scenes.first!)
    }
    
    func setScene(_ scene: CarthageObject)
    {
        engine?.destroy()
        if engineType == .SceneKit {
            engine = SceneKitScene(model: self, sceneObject: scene)
        } else {
            engine = RealityKitScene(model: self, sceneObject: scene)
        }
        
        currentScene = scene
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.objectSelected.send(scene)
        }
    }
    
    /// Updates the engine entity of the currently selected object, i.e. applies changes in the UI to the rendering engine.
    func updateSelected() {
        if let selected = selected {
            if let entity = selected.entity {
                entity.updateFromModel()
            }
        }
    }
}
