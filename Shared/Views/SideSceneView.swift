//
//  SideSceneView.swift
//  Carthage
//
//  Created by Markus Moenig on 13/7/21.
//

import SwiftUI

struct SideSceneView: View {
    
    enum Mode {
        case parameters, javascript, settings
    }
    
    @State var mode                     : Mode = .javascript

    @Binding var document               : CarthageDocument
    @Binding var selected               : CarthageObject?
    
    @Environment(\.colorScheme) var deviceColorScheme   : ColorScheme

    var body: some View {
           
        VStack(alignment: .leading) {
            
            HStack {

                Button(action: {
                    mode = .javascript
                })
                {
                    Image(systemName: mode == .javascript ? "j.square.fill" : "j.square")
                        .imageScale(.large)
                }
                .buttonStyle(.borderless)
                
                Button(action: {
                    mode = .settings
                })
                {
                    Image(systemName: mode == .settings ? "gearshape.fill" : "gearshape")
                        .imageScale(.large)
                }
                .buttonStyle(.borderless)
                
                Spacer()
            }
            .padding(.top, 6)
            .padding(.leading, 6)
            
            Divider()
            
            if let _ = selected {

                if mode == .javascript {
                    WebView(document.model, deviceColorScheme)
                        .onChange(of: deviceColorScheme) { newValue in
                            document.model.scriptEditor?.setTheme(newValue)
                        }
                }
                
                if mode == .settings {
                    Menu {
                        Button("SceneKit", action: {
                            document.model.engineType = .SceneKit
                            document.model.selectScene(document.model.selected!)
                            document.model.engineChanged.send()
                        })
                        
                        Button("RealityKit", action: {
                            document.model.engineType = .RealityKit
                            document.model.selectScene(document.model.selected!)
                            document.model.engineChanged.send()
                        })
                    }
                    label: {
                        Text("Engine")
                    }
                }
            }
            
            //Spacer()
        }
    }
}
