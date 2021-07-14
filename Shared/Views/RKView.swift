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


class RKViewModel: ObservableObject {
    @Published var didFinishLoading: Bool = false
    
    init () {
    }
}

#if os(OSX)
struct SwiftUIRKView: NSViewRepresentable {
    public typealias NSViewType     = ARView
    var model                       : CarthageModel!
    //let cameraMode = ARView.CameraMode.nonAR

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
        
        /*
        let newAnchor = AnchorEntity(world: [0, 0, 0])
        let newBox = ModelEntity(mesh: .generateBox(size: 0.3))
        newAnchor.addChild(newBox)
        arView.scene.anchors.append(newAnchor)
        
        let cameraEntity = PerspectiveCamera()

        let cameraTranslation = SIMD3<Float>(0, 0, 0)

        cameraEntity.look(at: .zero, from: cameraTranslation, relativeTo: nil)

        cameraEntity.camera.fieldOfViewInDegrees = 60
        let cameraAnchor = AnchorEntity(world: [0,0,1])
        cameraAnchor.addChild(cameraEntity)
        arView.scene.addAnchor(cameraAnchor)
        */
        
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
struct SwiftUIWebView: UIViewRepresentable {
    public typealias UIViewType = WKWebView
    var model       : Model!
    var colorScheme : ColorScheme
    
    private let webView: WKWebView = WKWebView()
    public func makeUIView(context: UIViewRepresentableContext<SwiftUIWebView>) -> WKWebView {
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator as? WKUIDelegate
        webView.configuration.userContentController.add(context.coordinator, name: "jsHandler")
        
        if let url = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "Files") {
            
            webView.loadFileURL(url, allowingReadAccessTo: url)
            let request = URLRequest(url: url)
            webView.load(request)
        }
        
        return webView
    }

    public func updateUIView(_ uiView: WKWebView, context: UIViewRepresentableContext<SwiftUIWebView>) { }

    public func makeCoordinator() -> Coordinator {
        return Coordinator(model, colorScheme)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        
        private var model        : Model
        private var colorScheme : ColorScheme
        
        init(_ model: Model,_ colorScheme: ColorScheme) {
            self.model = model
            self.colorScheme = colorScheme
        }
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "jsHandler" {
                if let scriptEditor = model.scriptEditor {
                    scriptEditor.updated()
                }
            }
        }
        
        public func webView(_: WKWebView, didFail: WKNavigation!, withError: Error) { }

        public func webView(_: WKWebView, didFailProvisionalNavigation: WKNavigation!, withError: Error) { }

        //After the webpage is loaded, assign the data in WebViewModel class
        public func webView(_ web: WKWebView, didFinish: WKNavigation!) {
            model.scriptEditor = ScriptEditor(web, model, colorScheme)
        }

        public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) { }

        public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            decisionHandler(.allow)
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

