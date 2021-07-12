//
//  ProjectView.swift
//  Carthage
//
//  Created by Markus Moenig on 12/7/21.
//

import SwiftUI

struct ProjectView: View {
    
    @Binding var document               : CarthageDocument
    
    @State   var selectedScene          : CarthageObject? = nil
    @State   var selected               : CarthageObject? = nil

    var body: some View {
        
        List(document.model.project.scenes, children: \.children) { object in
            
            Button(action: {
                
                if object.type == .Scene {
                    document.model.selectedScene = object
                    selectedScene = object
                } else {
                    document.model.selected = object
                    selected = object
                    
                    document.model.objectSelected.send(object)
                }
            })
            {
                Label(object.name, systemImage: getObjectIconName(object))
                    //.frame(maxWidth: .infinity, alignment: .leading)
                    //.contentShape(Rectangle())
                    .foregroundColor(selected === object || selectedScene === object ? .accentColor : .primary)
            }
            .buttonStyle(PlainButtonStyle())
            //.listRowBackground(Group {
            //    if selected === object || selectedScene === object{
            //        Color.accentColor.mask(RoundedRectangle(cornerRadius: 4))
            //    } else { Color.clear }
            //})
        }
        
        //.onChange(of: document.model.selected) { sel in
        //    print("selected")
        //}
    }
    
    /// Returns the system icon name for the given object type
    func getObjectIconName(_ obj: CarthageObject) -> String {
        var name = "cylinder"
        
        if obj.type == .Procedural || obj.type == .Geometry {
            name = "cube"
        }
        
        return name
    }
}
