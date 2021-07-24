//
//  RKView.swift
//  Carthage
//
//  Created by Markus Moenig on 13/7/21.
//

import SwiftUI
import WebKit
import Combine
import RealityKit

class RKInpuView: ARView {
    
    weak var carthageScene  : CarthageScene? = nil
    
    var keyCodes    : [UInt16:String] = [
        53: "Escape",

        50: "Back Quote",
        18: "1",
        19: "2",
        20: "3",
        21: "4",
        23: "5",
        22: "6",
        26: "7",
        28: "8",
        25: "9",
        29: "0",
        27: "-",
        24: "=",
        51: "Delete",

        48: "Tab",
        12: "Q",
        13: "W",
        14: "E",
        15: "R",
        17: "T",
        16: "Y",
        32: "U",
        34: "I",
        31: "O",
        35: "P",
        33: "[",
        30: "]",
        42: "\\",
        
//        57: "Caps Lock",
        0: "A",
        1: "S",
        2: "D",
        3: "F",
        5: "G",
        4: "H",
        38: "J",
        40: "K",
        37: "L",
        41: ";",
        39: ",",
        36: "Return",
        
        57: "Shift",
        6: "Z",
        7: "X",
        8: "C",
        9: "V",
        11: "B",
        45: "N",
        46: "M",
        43: "Comma",
        47: "Period",
        44: "/",
        60: "Shift",
        
        63: "fn",
        59: "Control",
        58: "Option",
        55: "Command",
        49: "Space",
//        55: "R. Command",
        61: "R. Option",
        
        123: "Arrow Left",
        126: "Arrow Up",
        124: "Arrow Right",
        125: "Arrow Down",
    ]
    
    override func keyDown(with event: NSEvent) {
        if let keyText = keyCodes[event.keyCode] {
            if let carthageScene = carthageScene {
                carthageScene.keyDown(keyText)
            }
        }
    }
    
    override func keyUp(with event: NSEvent) {
        if let keyText = keyCodes[event.keyCode] {
            if let carthageScene = carthageScene {
                carthageScene.keyUp(keyText)
            }
        }
    }
}

#if os(OSX)
struct SwiftUIRKView: NSViewRepresentable {
    public typealias NSViewType     = ARView
    var model                       : CarthageModel!

    private let arView: ARView = RKInpuView()//ARView(frame: .zero)//, cameraMode: .ar, automaticallyConfigureSession: true)
    public func makeNSView(context: NSViewRepresentableContext<SwiftUIRKView>) -> ARView {
        
        if let rkEngine = model.engine as? RealityKitScene {
            if let sceneAnchor = rkEngine.sceneAnchor {
                arView.scene.anchors.append(sceneAnchor)
            }
            
            if let cameraAnchor = rkEngine.cameraAnchor {
                arView.scene.anchors.append(cameraAnchor)
            }
            
            rkEngine.setView(arView)
        }
        
        return arView
    }

    public func updateNSView(_ nsView: ARView, context: NSViewRepresentableContext<SwiftUIRKView>) { }

    public func makeCoordinator() -> Coordinator {
        return Coordinator(model)
    }
    
    class Coordinator: NSObject {
        
        private var model        : CarthageModel

        init(_ model: CarthageModel) {
            self.model = model
        }
    }
}
#else
struct SwiftUIRKView: UIViewRepresentable {
    public typealias UIViewType = ARView
    var model       : CarthageModel!
    
    private let arView: ARView = ARView(frame: .zero, cameraMode: .nonAR, automaticallyConfigureSession: false)
    public func makeUIView(context: UIViewRepresentableContext<SwiftUIRKView>) -> ARView {
        if let rkEngine = model.engine as? RealityKitScene {
            if let sceneAnchor = rkEngine.sceneAnchor {
                arView.scene.anchors.append(sceneAnchor)
            }
            
            if let cameraAnchor = rkEngine.cameraAnchor {
                arView.scene.anchors.append(cameraAnchor)
            }
            
            rkEngine.arView = arView
        }
        return arView
    }

    public func updateUIView(_ uiView: ARView, context: UIViewRepresentableContext<SwiftUIRKView>) { }

    public func makeCoordinator() -> Coordinator {
        return Coordinator(model)
    }
    
    class Coordinator: NSObject {
        
        private var model        : CarthageModel
        
        init(_ model: CarthageModel) {
            self.model = model
        }
    }
}

#endif

struct RKView  : View {
    var model       : CarthageModel

    init(_ model: CarthageModel) {
        self.model = model
    }
    
    var body: some View {
        SwiftUIRKView(model: model)
    }
}

