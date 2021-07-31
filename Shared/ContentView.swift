//
//  ContentView.swift
//  Shared
//
//  Created by Markus Moenig on 11/7/21.
//

import SwiftUI
import SceneKit
import RealityKit

struct ContentView: View {
    
    @Environment(\.colorScheme) var deviceColorScheme   : ColorScheme

    enum Mode {
        case normal, scripting
    }
    
    @State private var mode             : Mode = .normal

    @Binding var document               : CarthageDocument
    
    @State var sideViewIsVisible        : Bool = true
    
    @State var engineType               : CarthageModel.EngineType = .SceneKit
    @State var engineTypeText           : String = ""
    
    @State var isPlaying                : Bool = false
    
    @State   var selected               : CarthageObject? = nil

    @State private var searchText       = ""
    
    var body: some View {
        
        GeometryReader { geometry in

            NavigationView {
            
                ProjectView(document: $document)
                    .frame(maxWidth: 250)

                VStack(alignment: .leading, spacing: 2) {
                
                    HStack {
                    
                        if mode == .normal {
                            if engineType == .SceneKit {
                                SKView(document.model)
                            } else {
                                RKView(document.model)
                            }
                            
                            if sideViewIsVisible {
                                SideView(document: $document)
                                    .frame(width: min(geometry.size.width / 2.8, 700))
                            }
                        } else
                        if mode == .scripting {
                            
                            ZStack(alignment: .topTrailing) {
                                WebView(document.model, deviceColorScheme)
                                    .onChange(of: deviceColorScheme) { newValue in
                                        document.model.scriptEditor?.setTheme(newValue)
                                    }
                                
                                if engineType == .SceneKit {
                                    SKView(document.model)
                                        .frame(width: geometry.size.width / 3, height: geometry.size.height / 3)
                                        .opacity(isPlaying ? 1 : 0.5)
                                } else {
                                    RKView(document.model)
                                        .frame(width: geometry.size.width / 3, height: geometry.size.height / 3)
                                        .opacity(isPlaying ? 1 : 0.5)
                                }
                                
                                //JSHelpView(document: $document)
                                //    .offset(x: 0, y: 200)
                                    //.frame(width: 100, height: 200)
                            }
                        }
                    }
                    
                    BrowserView(document: $document)
                        .frame(height: 100)
                }
            }
        }
        
        .onReceive(document.model.engineChanged) { _ in
            engineType = document.model.engineType
        }
        
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                HStack(spacing: 0) {
                    Button(action: {
                        document.model.engine?.play()
                        isPlaying = true
                    }, label: {
                        Image(systemName: isPlaying == true ? "play.fill" : "play")
                    })
                        .keyboardShortcut("r")
                    
                    Button(action: {
                        isPlaying = false
                        document.model.engine?.stop()
                    }, label: {
                        Image(systemName: isPlaying == false ? "stop.fill" : "stop")
                    })
                        .keyboardShortcut("t")
                }
            }

            ToolbarItemGroup(placement: .automatic) {
                Spacer()

                Menu {
                    Button("SceneKit", action: {
                        document.model.engineType = .SceneKit
                        document.model.setScene(document.model.currentScene!)
                        document.model.engineChanged.send()
                        engineTypeText = "SceneKit"
                    })
                    
                    Button("RealityKit", action: {
                        document.model.engineType = .RealityKit
                        document.model.setScene(document.model.currentScene!)
                        document.model.engineChanged.send()
                        engineTypeText = "RealityKit"
                    })
                }
                label: {
                    Text(engineTypeText)
                }
                .disabled(isPlaying)
            }
                        
            ToolbarItemGroup(placement: .automatic) {
                Spacer()
                
                HStack(spacing: 0) {

                    Button(action: {
                        if mode == .normal {
                            mode = .scripting
                            if let selected = selected {
                                if selected.settingsMode != .javascript && selected.settingsMode != .data {
                                    selected.settingsMode = .javascript
                                }
                            }
                        } else {
                            mode = .normal
                        }
                    }, label: {
                        Image(systemName: mode == .normal ? "rectangle" : "rectangle.fill")
                    })
                    .keyboardShortcut("f")

                    Button(action: {
                        sideViewIsVisible.toggle()
                    }, label: {
                        Image(systemName: "sidebar.right")
                    })
                }
            }
        }
        
        .animation(.default)

        .onAppear(perform: {
            if document.model.engineType == .SceneKit {
                engineTypeText = "SceneKit"
            } else
            if document.model.engineType == .RealityKit {
                engineTypeText = "RealityKit"
            }
        })
        
        // Library search
        .searchable(text: $searchText) {
            ForEach(searchResults, id: \.self) { result in
                Text("\(result)").searchCompletion(result)
            }
        }
        
        // In scripting view set the new script mode
        .onReceive(document.model.objectSelected) { object in
            selected = object
            if mode == .scripting {
                mode = .normal
                //mode = .scripting

                //object.codeContext = ""
                //object.dataContext = ""
                //document.model.scriptEditor?.setSession(object)
            }
        }
    }
    
    /// Supplies the search results in the library for the current search text
    var searchResults: [String] {
        var tags : [String] = []
        var names : [String] = []

        let request = LibraryEntity.fetchRequest()
        
        let managedObjectContext = PersistenceController.shared.container.viewContext
        let objects = try! managedObjectContext.fetch(request)

        objects.forEach { ca in
            
            guard let tag = ca.tags else {
                return
            }
            
            guard let name = ca.name else {
                return
            }
            
            tags.append(tag)
            names.append(name)
        }
        
        if searchText.isEmpty {
            document.model.searchResultsChanged.send(names)
            return []//names
        } else {
            //return names.filter { $0.contains(searchText) }
            var results : [String] = []

            let text = searchText.lowercased()
            
            for (index, name) in names.enumerated() {
                if tags[index].lowercased().contains(text) {
                    results.append(name)
                }
            }
            
            document.model.searchResultsChanged.send(results)
            return []//results
        }
    }
}
