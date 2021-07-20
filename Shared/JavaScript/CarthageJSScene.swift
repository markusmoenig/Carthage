//
//  CarthageJSScene.swift
//  Carthage
//
//  Created by Markus Moenig on 20/7/21.
//

import Foundation
import JavaScriptCore

@objc protocol CarthageJSSceneJSExports: JSExport {
    
    var name: String { get }

    static func getInstance() -> CarthageJSScene
}

class CarthageJSScene: NSObject, CarthageJSSceneJSExports {
    
    /// name property
    var name: String  {
        get {
            if let entity = getSelf() {
                return entity.object.name
            }
            return ""
        }
    }

    /// Class initializer
    class func getInstance() -> CarthageJSScene {
        return CarthageJSScene()
    }
    
    /// Return a reference to the embedded CarthageEntity
    func getSelf() -> CarthageEntity? {
        let context = JSContext.current()
        if let entity = context?.objectForKeyedSubscript("__si").toObject() as? CarthageEntity {
            return entity
        }
        return nil
    }
}
