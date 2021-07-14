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
            if let selected = selected {
                if selected.type == .Scene {
                    SideSceneView(document: $document, selected: $selected)
                } else
                if selected.type == .Geometry || selected.type == .Procedural {
                    SideGeometryView(document: $document, selected: $selected)
                }
            }
        }
        
        .onReceive(document.model.objectSelected) { object in
            selected = object
        }
    }
}
