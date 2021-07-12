//
//  SideView.swift
//  Carthage
//
//  Created by Markus Moenig on 12/7/21.
//

import SwiftUI

struct SideView: View {
    
    @Binding var document               : CarthageDocument

    @State   var selected               : CarthageObject? = nil

    
    var body: some View {
           
        VStack {
            if let selected = selected {
                DataView(model: document.model, data: selected.data)
            }
        }
        
        .onReceive(document.model.objectSelected) { object in
            selected = object
        }
    }
}
