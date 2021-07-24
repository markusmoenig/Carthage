//
//  CarthageEngine.swift
//  Carthage
//
//  Created by Markus Moenig on 12/7/21.
//

import Foundation
import JavaScriptCore

/// The javascript protocol for scenes
@objc protocol CarthageSceneJSExports: JSExport {
}

@objc class CarthageScene: NSObject, CarthageSceneJSExports {
    
    let model           : CarthageModel
    let sceneObject     : CarthageObject
        
    var isPlaying       : Bool = false
    
    /// All js enabled objects of the scene
    var jsObjects       : [CarthageObject] = []
    /// All objects who needs to be send a tick each frame
    var tickObjects     : [CarthageObject] = []
    /// All objects who needs to be send keyDown events
    var keyDownObjects  : [CarthageObject] = []
    /// All objects who needs to be send keyUp events
    var keyUpObjects  : [CarthageObject] = []
    
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
    
    /// JavaScript require. Load and execute the given module
    let require: @convention(block) (String) -> () = { input in
        if let object = getObject() {
            guard let path = Bundle.main.path(forResource: input, ofType: "js", inDirectory: "Files/jslibs") else {
                return
            }
            
            if let value = try? String(contentsOfFile: path, encoding: String.Encoding.utf8) {
                object.jsContext?.evaluateScript(value)
            }
        }
    }
    
    /// JavaScript print
    let printConsole: @convention(block) (String) -> () = { input in
        if let model = getModel() {
            model.logText.append(input + "\n")
            model.logChanged.send()
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
        tickObjects = []
        keyDownObjects = []
        keyUpObjects = []
        
        func getTopLevelObject(_ type: CarthageObject.CarthageObjectType) -> CarthageObject? {
            for o in sceneObject.children! {
                if o.type == type {
                    return o
                }
            }
            return nil
        }
        
        let camera = getTopLevelObject(.Camera)

        func setupJS(_ object: CarthageObject) {
            if object.jsCode.isEmpty { return }
            
            object.jsContext = JSContext()
            
            object.jsContext?.setObject(require, forKeyedSubscript: "require" as NSString)
            object.jsContext?.setObject(printConsole, forKeyedSubscript: "print" as NSString)
            object.jsContext?.setObject(printConsole, forKeyedSubscript: "console" as NSString)
            
            // Init scene js object
            object.jsContext?.setObject(CarthageJSCamera.self, forKeyedSubscript: "Camera" as NSString)
            object.jsContext?.setObject(CarthageJSScene.self, forKeyedSubscript: "Scene" as NSString)
            object.jsContext?.setObject(CarthageJSObject.self, forKeyedSubscript: "Object" as NSString)
            
            // Exception handler
            object.jsContext!.exceptionHandler = { context, exception in
                if let exc = exception {
                    if let str = exc.toString() {
                        self.model.logText.append("Error in \(object.name): \(str) \n")
                        self.model.logChanged.send()
                    }
                }
            }
            
            object.jsContext?.setObject(object.entity, forKeyedSubscript: "__si" as NSString)
            object.jsContext?.evaluateScript("scene = Scene.getInstance();")

            if object.json.isEmpty == false {
                object.jsContext?.evaluateScript("scene.data = " + object.json)
            }
            
            // Set the camera object into the context
            if let camera = camera {
                object.jsContext?.evaluateScript("scene.camera = Camera.getInstance();")
                object.jsContext?.setObject(camera.entity, forKeyedSubscript: "__ci" as NSString)
            }
            
            if object.type != .Scene {
                // Init object js object

                object.jsContext?.setObject(object.entity, forKeyedSubscript: "__oi" as NSString)
                object.jsContext?.evaluateScript("object = Object.getInstance();")
                
                if object.json.isEmpty == false {
                    object.jsContext?.evaluateScript("object.data = " + object.json)
                }
            } else {
                // __oi always points to the object
                object.jsContext?.setObject(object.entity, forKeyedSubscript: "__oi" as NSString)
            }
            
            object.jsContext?.evaluateScript("CT = {};")
            object.jsContext?.evaluateScript(object.jsCode)
            
            // Collect the objects who need callbacks
            if object.jsContext?.objectForKeyedSubscript("tick").isUndefined == false {
                tickObjects.append(object)
            }
            
            if object.jsContext?.objectForKeyedSubscript("keyDown").isUndefined == false {
                keyDownObjects.append(object)
            }
            
            if object.jsContext?.objectForKeyedSubscript("keyUp").isUndefined == false {
                keyUpObjects.append(object)
            }
            
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
        if isPlaying == false { return }
        // Send a tick to each object who supports it
        for o in tickObjects {
            o.jsContext?.evaluateScript("tick(\(time))")
        }
    }
    
    func keyDown(_ key: String) {
        for o in keyDownObjects {
            o.jsContext?.evaluateScript("keyDown(`\(key)`)")
        }
    }
    
    func keyUp(_ key: String) {
        for o in keyUpObjects {
            o.jsContext?.evaluateScript("keyUp(`\(key)`)")
        }
    }
    
    /// Returns the CarthageModel from the current JSContext
    static func getModel() -> CarthageModel? {
        let context = JSContext.current()
        if let entity = context?.objectForKeyedSubscript("__si").toObject() as? CarthageEntity {
            if let sceneKitEntity = entity as? SceneKitEntity {
                return sceneKitEntity.scene.model

            } else
            if let realityKitEntity = entity as? RealityKitEntity {
                return realityKitEntity.scene.model
            }
        }
        return nil
    }
    
    /// Returns the CarthageModel from the current JSContext
    static func getObject() -> CarthageObject? {
        let context = JSContext.current()
        if let entity = context?.objectForKeyedSubscript("__oi").toObject() as? CarthageEntity {
            return entity.object
        }
        return nil
    }
}
