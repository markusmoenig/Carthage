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

#if os(OSX)
struct SwiftUIRKView: NSViewRepresentable {
    public typealias NSViewType     = ARView
    var model                       : CarthageModel!

    private let arView: ARView = ARView(frame: .zero)//, cameraMode: .ar, automaticallyConfigureSession: true)
    public func makeNSView(context: NSViewRepresentableContext<SwiftUIRKView>) -> ARView {
        
        if let rkEngine = model.engine as? RealityKitScene {
            if let sceneAnchor = rkEngine.sceneAnchor {
                arView.scene.anchors.append(sceneAnchor)
            }
            
            if let cameraAnchor = rkEngine.cameraAnchor {
                arView.scene.anchors.append(cameraAnchor)
            }
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
    
    private let arView: ARView = ARView(frame: .zero)//, cameraMode: .ar, automaticallyConfigureSession: true)
    public func makeUIView(context: UIViewRepresentableContext<SwiftUIRKView>) -> ARView {
        if let rkEngine = model.engine as? RealityKitScene {
            if let sceneAnchor = rkEngine.sceneAnchor {
                arView.scene.anchors.append(sceneAnchor)
            }
            
            if let cameraAnchor = rkEngine.cameraAnchor {
                arView.scene.anchors.append(cameraAnchor)
            }
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

