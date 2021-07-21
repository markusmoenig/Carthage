//
//  SideView.swift
//  Carthage
//
//  Created by Markus Moenig on 12/7/21.
//

import SwiftUI

struct SideView: View {
    
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
                        
                        Button(action: {
                            mode = .materials
                            selected.settingsMode = mode
                        })
                        {
                            Image(systemName: mode == .materials ? "light.max" : "light.min")
                                .imageScale(.large)
                        }
                        .buttonStyle(.borderless)
                    }

                    if selected.type == .Geometry || selected.type == .Procedural || selected.type == .Scene {
                        
                        Button(action: {
                            mode = .physics
                            selected.settingsMode = mode
                        })
                        {
                            Image(systemName: mode == .physics ? "paperplane.fill" : "paperplane")
                                .imageScale(.large)
                        }
                        .buttonStyle(.borderless)
                        
                        Button(action: {
                            mode = .data
                            selected.settingsMode = mode
                            document.model.scriptEditor?.setSession(selected)
                        })
                        {
                            Image(systemName: mode == .data ? "square.stack.3d.up.fill" : "square.stack.3d.up")
                                .imageScale(.large)
                        }
                        .buttonStyle(.borderless)
                        
                        Button(action: {
                            mode = .javascript
                            selected.settingsMode = mode
                            document.model.scriptEditor?.setSession(selected)
                        })
                        {
                            Image(systemName: mode == .javascript ? "j.square.fill" : "j.square")
                                .imageScale(.large)
                        }
                        .buttonStyle(.borderless)
                    }
                    
                    if selected.type == .Camera {
                        Button(action: {
                            mode = .parameters
                            selected.settingsMode = mode
                        })
                        {
                            Image(systemName: mode == .parameters ? "gearshape.fill" : "gearshape")
                                .imageScale(.large)
                        }
                        .buttonStyle(.borderless)
                    }
                    
                    Button(action: {
                        mode = .help
                        selected.settingsMode = mode
                    })
                    {
                        Image(systemName: mode == .help ? "questionmark.square.fill" : "questionmark.square")
                            .imageScale(.large)
                    }
                    .buttonStyle(.borderless)
                    
                    Spacer()
                }
                .padding(.top, 6)
                .padding(.leading, 6)
                
                Divider()
                
                if mode == .parameters {                    
                    if selected.type == .Geometry {
                        if let transformData = selected.dataGroups.getGroup("Transform") {
                            DataView(model: document.model, data: transformData)
                        }
                    }
                    
                    if selected.type == .Procedural {
                        if let proceduralData = selected.dataGroups.getGroup("Procedural"), let transformData = selected.dataGroups.getGroup("Transform") {
                            DataViews(model: document.model, data: [transformData, proceduralData])
                        }
                    }
                    
                    if let cameraData = selected.dataGroups.getGroup("Camera") {
                        DataView(model: document.model, data: cameraData)
                    }
                }
                
                if mode == .materials {
                    if let materialData = selected.dataGroups.getGroup("Material") {
                        DataView(model: document.model, data: materialData)
                    }
                }
                
                if mode == .physics {
                    if let physicsData = selected.dataGroups.getGroup("Physics") {
                        DataView(model: document.model, data: physicsData)
                    }
                }
                
                if mode == .javascript || mode == .data {
                    WebView(document.model, deviceColorScheme)
                        .onChange(of: deviceColorScheme) { newValue in
                            document.model.scriptEditor?.setTheme(newValue)
                        }
                }
                
                if mode == .help {
                    Text(getHelpText())
                    Spacer()
                }
                
                //if mode == .settings {
                //}
            }
            
            //Spacer()
        }
        .animation(.default)
        
        .onReceive(document.model.objectSelected) { object in
            selected = object
            mode = object.settingsMode
            object.codeContext = ""
            object.dataContext = ""
            document.model.scriptEditor?.setSession(object)
        }
        
        .onAppear(perform: {
            selected = document.model.selected
            mode = selected!.settingsMode
        })
        
    }
    
    func getHelpText() -> AttributedString {
        let text = """
        **Help**
        
        Have to implement help for each object type.
        
        """
        
        do {
            let astring = try AttributedString(markdown: text, options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace))
            return astring
        } catch {
            return "Parsing Error"
        }
    }
}
