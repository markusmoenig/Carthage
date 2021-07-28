//
//  JSHelpView.swift
//  JSHelpView
//
//  Created by Markus Moenig on 24/7/21.
//

import SwiftUI

struct JSHelpView: View {
    
    @Binding var document               : CarthageDocument

    var body: some View {
        VStack {
            Text(document.model.helpText)
        }
            .background(.white)
            .frame(width: 100, height: 200)
    }
}
