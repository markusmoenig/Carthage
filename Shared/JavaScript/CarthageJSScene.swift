//
//  CarthageJSScene.swift
//  Carthage
//
//  Created by Markus Moenig on 20/7/21.
//

import Foundation
import JavaScriptCore

@objc protocol CarthageJSSceneJSExports: JSExport {
    
    var name                    : String { get }

    var resolution              : Any { get }

    static func getInstance() -> CarthageJSScene
}

class CarthageJSScene: CarthageJSBase, CarthageJSSceneJSExports {
    
    override init() {
        super.init()
        _id = "__si"
    }
    
    /// name property
    var name: String  {
        get {
            if let entity = getSelf() {
                return entity.object.name
            }
            return ""
        }
    }
    
    var resolution: Any {
        get {
            if let entity = getSelf() {
                return fromFloat2(entity.getResolution())
            }
            return [:]
        }
    }

    /// Class initializer
    class func getInstance() -> CarthageJSScene {
        return CarthageJSScene()
    }
}
