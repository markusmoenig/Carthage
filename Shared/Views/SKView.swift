//
//  SKView.swift
//  Carthage
//
//  Created by Markus Moenig on 14/7/21.
//

import SwiftUI
import Combine
import SceneKit

#if os(OSX)

class SKInpuView: SCNView {
    
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
    
    var mouseIsDown         : Bool = false
    var mousePos            = float2(0, 0)
    
    var hasTap              : Bool = false
    var hasDoubleTap        : Bool = false
    
    /// To get continuous mouse events on macOS
    override public func updateTrackingAreas()
    {
        let options : NSTrackingArea.Options = [.mouseEnteredAndExited, .mouseMoved, .activeInKeyWindow]
        let trackingArea = NSTrackingArea(rect: self.bounds, options: options,
                                      owner: self, userInfo: nil)
        self.addTrackingArea(trackingArea)
    }
    
    func setMousePos(_ event: NSEvent)
    {
        var location = event.locationInWindow
        location.y = location.y - CGFloat(frame.height)
        location = convert(location, from: nil)
        
        mousePos.x = Float(location.x)// / frame.width) - 0.5
        mousePos.y = Float(location.y)// / frame.height) - 0.5
    }
    
    override public func mouseDown(with event: NSEvent) {
        setMousePos(event)
        carthageScene?.touchDown(mousePos)
    }
    
    override public func mouseMoved(with event: NSEvent) {
        setMousePos(event)
        carthageScene?.touchMoved(mousePos)
    }
    
    override public func mouseDragged(with event: NSEvent) {
        setMousePos(event)
        carthageScene?.touchDragged(mousePos)
    }
    
    override public func mouseUp(with event: NSEvent) {
        mouseIsDown = false
        hasTap = false
        hasDoubleTap = false
        setMousePos(event)
        carthageScene?.touchUp(mousePos)
    }
}

struct SwiftUISKView: NSViewRepresentable {
    public typealias NSViewType     = SCNView
    var model                       : CarthageModel!

    private let skView: SCNView = SKInpuView()
    public func makeNSView(context: NSViewRepresentableContext<SwiftUISKView>) -> SCNView {
        
        if let skEngine = model.engine as? SceneKitScene {
            skView.scene = skEngine.scene
            skView.delegate = skEngine
            skEngine.setView(skView)
        }
        
        return skView
    }

    public func updateNSView(_ nsView: SCNView, context: NSViewRepresentableContext<SwiftUISKView>) { }

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

class SKInpuView: SCNView {
    
    weak var carthageScene  : CarthageScene? = nil
}

struct SwiftUISKView: UIViewRepresentable {
    public typealias UIViewType = SCNView
    var model       : CarthageModel!
    
    private let skView: SCNView = SKInpuView()
    public func makeUIView(context: UIViewRepresentableContext<SwiftUISKView>) -> SCNView {
        
        if let skEngine = model.engine as? SceneKitScene {
            skView.scene = skEngine.scene
            skView.delegate = skEngine
            skEngine.setView(skView)
        }
        
        return skView
    }

    public func updateUIView(_ uiView: SCNView, context: UIViewRepresentableContext<SwiftUISKView>) { }

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

struct SKView  : View {
    var model       : CarthageModel

    init(_ model: CarthageModel) {
        self.model = model
    }
    
    var body: some View {
        SwiftUISKView(model: model)
    }
}

