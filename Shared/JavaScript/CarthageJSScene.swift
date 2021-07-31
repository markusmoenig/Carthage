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

    func getObject(_ name: String) -> CarthageJSObject?

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
    
    func getObject(_ name: String) -> CarthageJSObject? {
        if let entity = getSelf() {
            if let children = entity.object.scene?.children {
                for o in children {
                    if o.name == name {
                        return CarthageJSObject(entity: o.entity!)
                    }
                }
            }
            //entity.setEuler(toFloat3(angles))
            //return fromFloat3(entity.getDirection())
        }
        return nil
    }

    /// Class initializer
    class func getInstance() -> CarthageJSScene {
        return CarthageJSScene()
    }
}
