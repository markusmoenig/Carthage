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
    
    @State var mode                     : CarthageObject.SettingsMode = .parameters

    @Binding var document               : CarthageDocument

    @State   var selected               : CarthageObject? = nil

    @Environment(\.colorScheme) var deviceColorScheme   : ColorScheme
    
    var body: some View {
        
        VStack(alignment: .leading) {

            if let selected = selected {
                
                HStack {
                    
                    if selected.type == .Geometry || selected.type == .Procedural {                                        
                        Button(action: {
                            mode = .parameters
                            selected.settingsMode = mode
                        })
                        {
                            Image(systemName: mode == .parameters ? "cube.fill" : "cube")
                                .imageScale(.large)
                        }
                        .buttonStyle(.borderless)
                    }

                    Button(action: {
                        mode = .javascript
                        selected.settingsMode = mode
                    })
                    {
                        Image(systemName: mode == .javascript ? "j.square.fill" : "j.square")
                            .imageScale(.large)
                    }
                    .buttonStyle(.borderless)
                    
                    Button(action: {
                        mode = .settings
                        selected.settingsMode = mode
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
                
                if mode == .parameters {
                    if let translationData = selected.dataGroups.getGroup("Transform") {
                        DataView(model: document.model, data: translationData)
                    }
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
                            document.model.setScene(document.model.currentScene!)
                            document.model.engineChanged.send()
                        })
                        
                        Button("RealityKit", action: {
                            document.model.engineType = .RealityKit
                            document.model.setScene(document.model.currentScene!)
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
        .animation(.default)
        
        .onReceive(document.model.objectSelected) { object in
            selected = object
            mode = object.settingsMode
            object.scriptContext = ""
            document.model.scriptEditor?.setSession(object)
        }
        
        .onAppear(perform: {
            selected = document.model.selected
            mode = selected!.settingsMode
        })
        
        /*
        VStack(alignment: .leading) {
            if let selected = selected {
                
                /*
                if selected.type == .Scene {
                    SideSceneView(document: $document, selected: $selected)
                } else
                if selected.type == .Geometry || selected.type == .Procedural {
                    SideGeometryView(document: $document, selected: $selected)
                }*/
            }
        }
        
        .onReceive(document.model.objectSelected) { object in
            selected = object
        }*/
    }
}
