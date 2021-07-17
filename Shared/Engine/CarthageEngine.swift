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
    var rotation: [String: Double] { get set }
    var scale: [String: Double] { get set }
}

@objc class CarthageEntity : NSObject, CarthageObjectJSExports {
    
    let object          : CarthageObject
    
    init(object: CarthageObject) {
        self.object = object
        
        super.init()
        
        object.entity = self
    }
    
    /// Update the entity from the data model, this is heavy but only gets called to set the initial states of the entity before the scene starts.
    func updateFromModel(groupName: String = "")
    {
    }
    
    /// position property
    var position: [String: Double]  {
        get {
            return [:]
        }
        set {            
        }
    }
    
    /// rotation property
    var rotation: [String: Double]  {
        get {
            return [:]
        }
        set {
        }
    }
    
    /// scale property
    var scale: [String: Double]  {
        get {
            return [:]
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
    
    var isPlaying       : Bool = false
            
    /// Initialize the engine
    init(model: CarthageModel, sceneObject: CarthageObject)
    {
        self.model = model
        self.sceneObject = sceneObject
        
        super.init()        
    }
    
    /// Loads / initializes the given objects in the derived engines
    func load() {
        
        func loadObject(_ o: CarthageObject) {
            addObject(object: o)

            if let children = o.children {
                for c in children {
                    loadObject(c)
                }
            }
        }
        
        if let children = sceneObject.children {
            for c in children {
                loadObject(c)
            }
        }
    }

    func testFunction() -> Int {
        return 5
    }
    
    let printConsole: @convention(block) (String) -> () = { input in
        DispatchQueue.main.async {
            gModel?.logText.append(input + "\n")
            gModel?.logChanged.send()
        }
    }
    
    /// If the given data has a text associated with it, use it as the library name and return the URL to the local file
    func getUrl(data: CarthageData, key: String) -> URL? {
        if let text = data.getText(key) {
            return model.getLibraryURL(text)
        }
        return nil
    }
    
    /// Adds an object to the scene
    func addObject(object: CarthageObject) {
    }
    
    func destroy() {
        
    }
    
    ///  Setup the js context
    func play() {
        
        isPlaying = true
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
        
        model.logText = ""
        model.logChanged.send()
    }
    
    /// Stops the game, removes the javascript contexts and updates the entities back to the model
    func stop() {
        isPlaying = false
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
