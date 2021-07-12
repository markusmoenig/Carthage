//
//  CarthageEngine.swift
//  Carthage
//
//  Created by Markus Moenig on 12/7/21.
//

import Foundation
import JavaScriptCore

@objc class CarthageEntity : NSObject, JSExport {
    
    let object          : CarthageObject
    
    init(object: CarthageObject) {
        self.object = object
        
        super.init()
        
        object.entity = self
    }
    
    /// Update the entity from the given object
    func update()
    {
    }
}

class CarthageEngine {
    
    let model           : CarthageModel
            
    /// Initialize the engine
    init(model: CarthageModel)
    {
        self.model = model
        
        model.engine = self
    }
    
    /// Sets up a scene
    func setupScene(sceneObject: CarthageObject)
    {
    }
}
