//
//  SideView.swift
//  Carthage
//
//  Created by Markus Moenig on 12/7/21.
//

import SwiftUI

struct SideView: View {
    
    enum Mode {
        case parameters, javascript, settings
    }
    
    @State var mode                     : Mode? = .parameters

    @Binding var document               : CarthageDocument

    @State   var selected               : CarthageObject? = nil

    @Environment(\.colorScheme) var deviceColorScheme   : ColorScheme

    
    var body: some View {
           
        VStack(alignment: .leading) {
            
            HStack {
                
                Button(action: {
                    mode = .parameters
                })
                {
                    Image(systemName: mode == .parameters ? "cube.fill" : "cube")
                        .imageScale(.large)
                }
                .buttonStyle(.borderless)

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

            if let selected = selected {
                
                if mode == .parameters {
                    DataView(model: document.model, data: selected.data)
                }
                
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
            
            Spacer()
        }
        
        .onReceive(document.model.objectSelected) { object in
            selected = object
            document.model.scriptEditor?.setSession(object)
        }
    }
}
