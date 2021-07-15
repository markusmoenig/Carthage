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
struct SwiftUISKView: NSViewRepresentable {
    public typealias NSViewType     = SCNView
    var model                       : CarthageModel!

    private let skView: SCNView = SCNView()
    public func makeNSView(context: NSViewRepresentableContext<SwiftUISKView>) -> SCNView {
        
        if let skEngine = model.engine as? SceneKitScene {
            skEngine.view = skView
            skView.scene = skEngine.scene
            
            skView.delegate = skEngine
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
struct SwiftUISKView: UIViewRepresentable {
    public typealias UIViewType = SCNView
    var model       : CarthageModel!
    
    private let skView: SCNView = SCNView()
    public func makeUIView(context: UIViewRepresentableContext<SwiftUISKView>) -> SCNView {
        
        if let skEngine = model.engine as? SceneKitScene {
            skEngine.view = skView
            skView.scene = skEngine.scene
            skView.delegate = skEngine
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

