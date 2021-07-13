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

// Protocol must be declared with `@objc`
@objc protocol SceneJSExports: JSExport {
    //var firstName: String { get set }
    var fullName: String { get }

    func testFunction() -> Int
    
    // Imported as `Person.createWithFirstNameLastName(_:_:)`
    //static func createWith(firstName: String, lastName: String) -> Person
}

@objc class CarthageScene: NSObject, SceneJSExports {
    
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
}
