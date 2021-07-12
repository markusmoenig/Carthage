//
//  ContentView.swift
//  Shared
//
//  Created by Markus Moenig on 11/7/21.
//

import SwiftUI
import SceneKit

struct ContentView: View {
    
    @Binding var document               : CarthageDocument
    
    @State var sideViewIsVisible        : Bool = true
    
    var body: some View {
        
        GeometryReader { geometry in

            NavigationView {
            
                ProjectView(document: $document)

                VStack {
                
                    HStack {
                    
                        SceneView(
                            scene: document.model.scene,
                            pointOfView: document.model.cameraNode,
                            options: [.allowsCameraControl]
                        )
                        
                        if sideViewIsVisible {
                            SideView()
                                .frame(width: min(geometry.size.width / 2.5, 800))
                        }
                    }
                    
                    BrowserView()
                        .frame(height: 100)
                }
            }
        }
        
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                
                Button(action: {
                    sideViewIsVisible.toggle()
                }, label: {
                    Image(systemName: "sidebar.right")
                })
            }
        }
        
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(document: .constant(CarthageDocument()))
    }
}
