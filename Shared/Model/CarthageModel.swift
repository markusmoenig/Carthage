//
//  CarthageModel.swift
//  Carthage
//
//  Created by Markus Moenig on 11/7/21.
//

import Combine
import JavaScriptCore

class CarthageModel: NSObject, ObservableObject {

    @Published var selected         : CarthageObject? = nil

    /// Send when an object has been selected
    let objectSelected              = PassthroughSubject<CarthageObject, Never>()
    
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
        engineScene = SceneKitScene(model: self, sceneObject: scene)

        
        selected = scene
    }
    
    func play() {
    }
    
    func stop() {
        
    }
}
