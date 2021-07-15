//
//  ContentView.swift
//  Shared
//
//  Created by Markus Moenig on 11/7/21.
//

import SwiftUI
import SceneKit
import RealityKit

struct ContentView: View {
    
    @Binding var document               : CarthageDocument
    
    @State var sideViewIsVisible        : Bool = true
    
    @State var engineType               : CarthageModel.EngineType = .SceneKit
    @State var engineTypeText           : String = ""
    
    @State var isPlaying                : Bool = false
    
    var body: some View {
        
        GeometryReader { geometry in

            NavigationView {
            
                ProjectView(document: $document)
                    .frame(maxWidth: 250)

                VStack {
                
                    HStack {
                    
                        if engineType == .SceneKit {
                            /*
                            SceneView(
                                scene: document.model.engine?.getNativeScene() as? SCNScene,
                                //pointOfView: document.model.cameraNode,
                                options: [.allowsCameraControl],
                                delegate: document.model.engine as? SceneKitScene
                            )*/
                            SKView(document.model)
                        } else {
                            RKView(document.model)
                        }
                        
                        if sideViewIsVisible {
                            SideView(document: $document)
                                .frame(width: min(geometry.size.width / 2.5, 800))
                        }
                    }
                    
                    BrowserView()
                        .frame(height: 100)
                }
            }
        }
        
        .onReceive(document.model.engineChanged) { _ in
            engineType = document.model.engineType
        }
        
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                
                Button(action: {
                    document.model.engine?.play()
                    isPlaying = true
                }, label: {
                    Image(systemName: isPlaying == true ? "play.fill" : "play")
                })
                
                Button(action: {
                    isPlaying = false
                    document.model.engine?.stop()
                }, label: {
                    Image(systemName: isPlaying == false ? "stop.fill" : "stop")
                })
            }
            
            ToolbarItemGroup(placement: .automatic) {
                Menu {
                    Button("SceneKit", action: {
                        document.model.engineType = .SceneKit
                        document.model.setScene(document.model.currentScene!)
                        document.model.engineChanged.send()
                        engineTypeText = "SceneKit"
                    })
                    
                    Button("RealityKit", action: {
                        document.model.engineType = .RealityKit
                        document.model.setScene(document.model.currentScene!)
                        document.model.engineChanged.send()
                        engineTypeText = "RealityKit"
                    })
                }
                label: {
                    Text(engineTypeText)
                }
            }
            
            ToolbarItemGroup(placement: .automatic) {
                Button(action: {
                    sideViewIsVisible.toggle()
                }, label: {
                    Image(systemName: "sidebar.right")
                })
            }
        }
        
        .onAppear(perform: {
            if document.model.engineType == .SceneKit {
                engineTypeText = "SceneKit"
            } else
            if document.model.engineType == .RealityKit {
                engineTypeText = "RealityKit"
            }
        })
        
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(document: .constant(CarthageDocument()))
    }
}
