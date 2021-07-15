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
        
        ZStack(alignment: .bottomLeading) {
            List(document.model.project.scenes, children: \.children) { object in
                
                Button(action: {
                    
                    document.model.selected = object
                    selected = object
                    
                    document.model.objectSelected.send(object)
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
            
            HStack {
                Menu {
                    
                    Button("Plane", action: {
                        if let selected = document.model.selected {
                            
                            let o = CarthageObject(type: .Procedural, name: "Plane", proceduralType: .Plane)
                            if selected.children == nil {
                                selected.children = []
                            }
                            selected.children!.append(o)
                            o.parent = selected
                            document.model.engine?.addObject(object: o)
                            
                            document.model.selected = o
                            document.model.objectSelected.send(o)
                            document.model.projectChanged.send()
                            if document.model.engineType == .RealityKit {
                                document.model.engineChanged.send()
                            }
                        }
                    })
                    
                    Button("Cube", action: {
                        if let selected = document.model.selected {
                            
                            let o = CarthageObject(type: .Procedural, name: "Cube", proceduralType: .Cube)
                            if selected.children == nil {
                                selected.children = []
                            }
                            selected.children!.append(o)
                            o.parent = selected
                            document.model.engine?.addObject(object: o)
                            
                            document.model.selected = o
                            document.model.objectSelected.send(o)
                            document.model.projectChanged.send()
                            if document.model.engineType == .RealityKit {
                                document.model.engineChanged.send()
                            }
                        }
                    })
                    
                    Button("Sphere", action: {
                        if let selected = document.model.selected {
                            
                            let o = CarthageObject(type: .Procedural, name: "Sphere", proceduralType: .Sphere)
                            if selected.children == nil {
                                selected.children = []
                            }
                            selected.children!.append(o)
                            o.parent = selected
                            document.model.engine?.addObject(object: o)
                            
                            document.model.selected = o
                            document.model.objectSelected.send(o)
                            document.model.projectChanged.send()
                            if document.model.engineType == .RealityKit {
                                document.model.engineChanged.send()
                            }
                        }
                    })
                }
                label: {
                    Label("Add Asset", systemImage: "plus")
                }
                .menuStyle(BorderlessButtonMenuStyle())
                .padding(.leading, 10)
                .padding(.bottom, 6)
                Spacer()
            }
        }
        
        .onReceive(document.model.projectChanged) { _ in
            self.selectedScene = document.model.selected
            self.selectedScene = nil
        }
        
        .onReceive(document.model.objectSelected) { sel in
            selected = sel
        }
        
        .onAppear(perform: {
            selected = document.model.selected
        })
    }
    
    /// Returns the system icon name for the given object type
    func getObjectIconName(_ obj: CarthageObject) -> String {
        var name = "cylinder"
        
        if obj.type == .Procedural || obj.type == .Geometry {
            name = "cube"
        } else
        if obj.type == .Camera {
            name = "video"
        }
        
        if selected == obj {
            name += ".fill"
        }
        
        return name
    }
}
