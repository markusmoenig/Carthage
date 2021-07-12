//
//  CarthageModel.swift
//  Carthage
//
//  Created by Markus Moenig on 11/7/21.
//

import Combine
import SceneKit

class CarthageModel: NSObject, ObservableObject {

    @Published var selected         : CarthageObject? = nil
    @Published var selectedScene    : CarthageObject? = nil

    /// Send when an object has been selected
    let objectSelected              = PassthroughSubject<CarthageObject, Never>()
    
    let scene           : SCNScene
    let camera          : SCNCamera
    let cameraNode      : SCNNode
    
    /// The project itself
    var project                             : CarthageProject

    override init() {

        project = CarthageProject()

        scene = SCNScene()
        //sceneView.scene = scene

        camera = SCNCamera()
        cameraNode = SCNNode()
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(x: -3.0, y: 3.0, z: 3.0)

        let light = SCNLight()
        light.type = SCNLight.LightType.omni
        let lightNode = SCNNode()
        lightNode.light = light
        lightNode.position = SCNVector3(x: 1.5, y: 1.5, z: 1.5)

        let sphereGeometry = SCNSphere(radius: 0.5)

        let sphereNode = SCNNode(geometry: sphereGeometry)

        let constraint = SCNLookAtConstraint(target: sphereNode)
        constraint.isGimbalLockEnabled = true
        cameraNode.constraints = [constraint]

        scene.rootNode.addChildNode(lightNode)
        scene.rootNode.addChildNode(cameraNode)
        scene.rootNode.addChildNode(sphereNode)
        
        super.init()

    }
}
