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
    
    /*
    let require: @convention(block) (String) -> () = { input in
        print("require", input)
    }*/
    
    func require(_ object: CarthageObject,_ module: String) {
        guard let path = Bundle.main.path(forResource: module, ofType: "js", inDirectory: "Files/jslibs") else {
            return
        }
        
        if let value = try? String(contentsOfFile: path, encoding: String.Encoding.utf8) {
            object.jsContext?.evaluateScript(value)
        }
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
        
        model.logText = ""
        model.logChanged.send()
        
        isPlaying = true
        jsObjects = []
        func setupJS(_ object: CarthageObject) {
            if object.code.isEmpty { return }
            
            object.jsContext = JSContext()
                        
            // Add an exception handler.
            object.jsContext!.exceptionHandler = { context, exception in
                if let exc = exception {
                    if let str = exc.toString() {
                        gModel?.logText.append("Error in \(object.name): \(str) \n")
                        gModel?.logChanged.send()
                    }
                }
            }
                                    
            //object.jsContext?.setObject(CarthageScene.self, forKeyedSubscript: "Scene" as NSString)
            //object.jsContext?.setObject(CarthageObject.self, forKeyedSubscript: "Object" as NSString)

            object.jsContext?.setObject(unsafeBitCast(self, to: AnyObject.self), forKeyedSubscript: "scene" as NSString)
            object.jsContext?.setObject(unsafeBitCast(object.entity, to: AnyObject.self), forKeyedSubscript: "object" as NSString)
            
            object.jsContext?.setObject(require, forKeyedSubscript: "require" as NSString)
            object.jsContext?.setObject(printConsole, forKeyedSubscript: "print" as NSString)
            object.jsContext?.setObject(printConsole, forKeyedSubscript: "console" as NSString)

            require(object, "matrix")

            object.jsContext?.evaluateScript(object.code)

            jsObjects.append(object)
        }
        
        let children = sceneObject.collectChildren()
        
        setupJS(sceneObject)

        for c in children {
            setupJS(c)
        }
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
            
            if o.jsContext?.objectForKeyedSubscript("tick").isUndefined == false {
                o.jsContext?.evaluateScript("tick(\(time))")
            }
        }
    }
}
