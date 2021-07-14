//
//  CarthageEngine.swift
//  Carthage
//
//  Created by Markus Moenig on 12/7/21.
//

import Foundation
import JavaScriptCore

/// The javascript protocol for object
@objc protocol CarthageObjectJSExports: JSExport {
    
    var position: [String: Double] { get set }
}

@objc class CarthageEntity : NSObject, CarthageObjectJSExports {
    
    let object          : CarthageObject
    
    init(object: CarthageObject) {
        self.object = object
        
        super.init()
        
        object.entity = self
    }
    
    /// Update the entity from the data model, this is heavy but only gets called to set the initial states of the entity before the scene starts.
    func updateFromModel()
    {
    }
    
    /// position property
    var position: [String: Double]  {
        get {
            return ["x": 0, "y": 0, "z": 0]
        }
        set {            
        }
    }
}

/// The javascript protocol for scenes
@objc protocol CarthageSceneJSExports: JSExport {

    func testFunction() -> Int
}

@objc class CarthageScene: NSObject, CarthageSceneJSExports {
    
    let model           : CarthageModel
    let sceneObject     : CarthageObject
    
    var jsObjects       : [CarthageObject] = []
            
    /// Initialize the engine
    init(model: CarthageModel, sceneObject: CarthageObject)
    {
        self.model = model
        self.sceneObject = sceneObject
        
        super.init()
        
        load()
    }
    
    /// Loads / initializes the given objects in the derived engines
    func load() {
        
        func loadObject(_ o: CarthageObject) {
            addObject(object: o)

            if let children = o.children {
                for c in children {
                    addObject(object: c)
                }
            }
        }
        
        if let children = sceneObject.children {
            for c in children {
                addObject(object: c)
            }
        }
    }

    func testFunction() -> Int {
        return 5
    }
    
    let printConsole: @convention(block) (String) -> () = { input in
        print(input)
    }
    
    /// Adds an object to the scene
    func addObject(object: CarthageObject) {
    }
    
    func destroy() {
        
    }
    
    ///  Setup the js context
    func play() {
        
        jsObjects = []
        func setupJS(_ object: CarthageObject) {
            if object.code.isEmpty { return }
            
            object.jsContext = JSContext()
                        
            // Add an exception handler.
            object.jsContext!.exceptionHandler = { context, exception in
                if let exc = exception {
                    if let str = exc.toString() {
                        print("JS Exception:", str)
                    }
                }
            }
                        
            //object.jsContext?.setObject(CarthageScene.self, forKeyedSubscript: "Scene" as NSString)
            //object.jsContext?.setObject(CarthageObject.self, forKeyedSubscript: "Object" as NSString)

            object.jsContext?.setObject(unsafeBitCast(self, to: AnyObject.self), forKeyedSubscript: "scene" as NSString)
            object.jsContext?.setObject(unsafeBitCast(object.entity, to: AnyObject.self), forKeyedSubscript: "object" as NSString)
            
            object.jsContext?.evaluateScript(object.code)

            object.jsContext?.setObject(printConsole, forKeyedSubscript: "print" as NSString)
            object.jsContext?.setObject(printConsole, forKeyedSubscript: "console" as NSString)

            jsObjects.append(object)
        }
        
        let children = sceneObject.collectChildren()
        
        for c in children {
            setupJS(c)
        }        
    }
    
    /// Stops the game, removes the javascript contexts and updates the entities back to the model
    func stop() {
        let children = sceneObject.collectChildren()
            
        for c in children {
            c.jsContext = nil
            c.entity?.updateFromModel()
        }
    }
    
    /// The game loop, call the tick functions of the js contexts who signed up for this
    func tick(_ time: Double)
    {
        for o in jsObjects {
            o.jsContext?.evaluateScript("tick(\(time))")
        }
    }
}
