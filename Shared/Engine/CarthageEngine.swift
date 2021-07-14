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
    //var fullName: String { get }

    //func position() -> Dictionary<String, Double>
    //func position() -> Dictionary<String, Double>
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
    //var firstName: String { get set }
    var fullName: String { get }

    func testFunction() -> Int
    
    // Imported as `Person.createWithFirstNameLastName(_:_:)`
    //static func createWith(firstName: String, lastName: String) -> Person
}

@objc class CarthageScene: NSObject, CarthageSceneJSExports {
    
    let model           : CarthageModel
    let sceneObject     : CarthageObject
            
    /// Initialize the engine
    init(model: CarthageModel, sceneObject: CarthageObject)
    {
        self.model = model
        self.sceneObject = sceneObject
        
        sceneObject.jsContext = JSContext()
        
        //sceneObject.jsContext?.setObject(CarthageScene.self, forKeyedSubscript: "Scene" as NSString)
        
        // Add an exception handler.
        sceneObject.jsContext!.exceptionHandler = { context, exception in
            if let exc = exception {
                if let str = exc.toString() {
                    print("JS Exception:", str)
                }
            }
        }
        
        super.init()
        
        sceneObject.jsContext?.setObject(unsafeBitCast(self, to: AnyObject.self), forKeyedSubscript: "scene" as NSString)
        sceneObject.jsContext?.setObject(printConsole, forKeyedSubscript: "print" as NSString)
        
        
        //print(sceneObject.jsContext?.evaluateScript("scene.fullName; scene.testFunction();")?.toString())
        //print(sceneObject.jsContext?.evaluateScript("print('hallo')")?.toString())
        
        print(sceneObject.children?.count)
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

    var fullName: String {
        return "i am here test"
    }
    
    func testFunction() -> Int {
         print("Yo")
        return 5
    }
    
    let printConsole: @convention(block) (String) -> () = { input in
        print(input)
    }
    
    func getNativeScene() -> AnyObject? {
        return nil
    }
    
    /// Adds an object to the scene
    func addObject(object: CarthageObject) {
        
    }
    
    func destroy() {
        
    }
    
    ///  Setup the js context
    func play() {
        
        func setupJS(_ object: CarthageObject) {
            
            print(object.name, object.code)

            if object.code.isEmpty { return }
            
            
            object.jsContext = JSContext()
            
            //sceneObject.jsContext?.setObject(CarthageScene.self, forKeyedSubscript: "Scene" as NSString)
            
            // Add an exception handler.
            object.jsContext!.exceptionHandler = { context, exception in
                if let exc = exception {
                    if let str = exc.toString() {
                        print("JS Exception:", str)
                    }
                }
            }
                        
            object.jsContext?.setObject(unsafeBitCast(object.entity, to: AnyObject.self), forKeyedSubscript: "object" as NSString)
            
            object.jsContext?.evaluateScript(object.code)

            //sceneObject.jsContext?.setObject(printConsole, forKeyedSubscript: "print" as NSString)
            
            //print(object.jsContext?.evaluateScript("object.position")?.toObject())
            //print(object.jsContext?.evaluateScript("object.position = { x: 1}")?.toObject())
            //print(object.jsContext?.evaluateScript("object.position")?.toObject())
            //print(sceneObject.jsContext?.evaluateScript("print('hallo')")?.toString())
        }
        
        let children = sceneObject.collectChildren()
        
        for c in children {
            setupJS(c)
        }
    }
    
    /// Stops the game, remove the javascript contexts and update the entities back to the model
    func stop() {
        let children = sceneObject.collectChildren()
            
        for c in children {
            c.jsContext = nil
            c.entity?.updateFromModel()
        }
    }
}
