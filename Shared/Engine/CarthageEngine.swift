//
//  CarthageEngine.swift
//  Carthage
//
//  Created by Markus Moenig on 12/7/21.
//

import Foundation
import JavaScriptCore

/// The javascript protocol for object
@objc protocol CarthageEntityJSExports: JSExport {
    
    //var position: [String: Double] { get set }
    //var rotation: [String: Double] { get set }
    //var scale: [String: Double] { get set }
}

@objc class CarthageEntity : NSObject, CarthageEntityJSExports {
    
    let object          : CarthageObject
    
    init(object: CarthageObject) {
        self.object = object
        
        super.init()
        
        object.entity = self
    }
    
    /// Get the object position
    func getPosition() -> float3 {
        return float3()
    }
    
    /// Set the object position
    func setPosition(_ p: float3) {
    }
    
    func addForce(_ direction: float3,_ position: float3) {
    }
    
    func applyImpulse(_ direction: float3,_ position: float3) {
    }
    
    /// Update the entity from the data model, this is heavy but only gets called to set the initial states of the entity before the scene starts.
    func updateFromModel(groupName: String = "")
    {
    }
}

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
    
    let applyForce: @convention(block) (String) -> () = { input in
        let context = JSContext.current()
        let object = context?.objectForKeyedSubscript("_internal").toObject() as? CarthageScene
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
        tickObjects = []
        keyDownObjects = []
        keyUpObjects = []

        func setupJS(_ object: CarthageObject) {
            if object.jsCode.isEmpty { return }
            
            object.jsContext = JSContext()
            
            object.jsContext?.setObject(require, forKeyedSubscript: "require" as NSString)
            object.jsContext?.setObject(printConsole, forKeyedSubscript: "print" as NSString)
            object.jsContext?.setObject(printConsole, forKeyedSubscript: "console" as NSString)
            
            // Init scene js object
            object.jsContext?.setObject(CarthageJSScene.self, forKeyedSubscript: "Scene" as NSString)
            object.jsContext?.setObject(CarthageJSObject.self, forKeyedSubscript: "Object" as NSString)
            
            object.jsContext?.setObject(object.entity, forKeyedSubscript: "__si" as NSString)
            object.jsContext?.evaluateScript("scene = Scene.getInstance();")
            
            if object.json.isEmpty == false {
                object.jsContext?.evaluateScript("scene.data = " + object.json)
            }
            
            if object.type != .Scene {
                // Init object js object

                object.jsContext?.setObject(object.entity, forKeyedSubscript: "__oi" as NSString)
                object.jsContext?.evaluateScript("object = Object.getInstance();")
                
                if object.json.isEmpty == false {
                    object.jsContext?.evaluateScript("object.data = " + object.json)
                }
            }

            // Exception handler.
            object.jsContext!.exceptionHandler = { context, exception in
                if let exc = exception {
                    if let str = exc.toString() {
                        gModel?.logText.append("Error in \(object.name): \(str) \n")
                        gModel?.logChanged.send()
                    }
                }
            }
            
            require(object, "math")

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
        
        for o in jsObjects {
            o.jsContext = nil
        }
    }
    
    /// The game loop, call the tick functions of the js contexts who signed up for this
    func tick(_ time: Double)
    {
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
}
