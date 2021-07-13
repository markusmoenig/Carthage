//
//  SideGeometryView.swift
//  Carthage
//
//  Created by Markus Moenig on 13/7/21.
//

import SwiftUI

struct SideGeometryView: View {
    
    enum Mode {
        case parameters, javascript, settings
    }
    
    @State var mode                     : Mode = .parameters

    @Binding var document               : CarthageDocument
    @Binding var selected               : CarthageObject?

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
                    if let translationData = selected.dataGroups.getGroup("Translation") {
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
                }
            }
            
            //Spacer()
        }
    }
}
