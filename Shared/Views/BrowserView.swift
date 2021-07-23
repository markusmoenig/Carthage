//
//  BrowserView.swift
//  Carthage
//
//  Created by Markus Moenig on 12/7/21.
//

import SwiftUI
import ModelIO

struct BrowserView: View {
    
    enum Mode {
        case browser, log
    }
    
    @Environment(\.managedObjectContext) var managedObjectContext

    @FetchRequest(
      entity: LibraryEntity.entity(),
      sortDescriptors: [
        NSSortDescriptor(keyPath: \LibraryEntity.name, ascending: true)
      ]
    ) var objects: FetchedResults<LibraryEntity>
    
    @Binding var document               : CarthageDocument

    @State private var mode             : Mode = .browser
    
    @State private var IconSize         : CGFloat = 80
        
    @State private var importing        : Bool = false
    
    @State private var selected         : String = ""
    
    @State private var searchResults    : [String] = []
    
    @State private var log              : String = ""

    var body: some View {
            
            HStack(alignment: .top, spacing: 1) {

                VStack(alignment: .center, spacing: 4) {
                                    
                    Button(action: {
                        importing = true
                    })
                    {
                        Image(systemName: "plus")
                            .imageScale(.large)
                    }
                    .buttonStyle(.borderless)
                    .padding(.top, 10)
                    .disabled(mode == .log)
                    //.padding(.leading, 4)
                              
                    Divider()
                    
                    Spacer()
                    
                    Button(action: {
                        mode = .browser
                    })
                    {
                        Image(systemName: mode == .browser ? "b.square.fill" : "b.square")
                            .imageScale(.large)
                    }
                    .buttonStyle(.borderless)
                    .keyboardShortcut("b")

                    Button(action: {
                        mode = .log
                    })
                    {
                        Image(systemName: mode == .log ? "l.square.fill" : "l.square")
                            .imageScale(.large)
                    }
                    .buttonStyle(.borderless)
                    .keyboardShortcut("l")
                    //.padding(.leading, 4)
                    
                    //Divider()
                    //    .frame(maxHeight: 16)
                    

                    Spacer()
                }
                .frame(maxWidth: 40)
                .fileImporter(
                    isPresented: $importing,
                    allowedContentTypes: [.item],
                    allowsMultipleSelection: false
                ) { result in
                    do {
                        let selectedFiles = try result.get()
                        
                        let url = selectedFiles[0]
                        
                        var fileName = url.lastPathComponent
                        
                        let components = fileName.components(separatedBy: ".")
                        if components.count > 1 {
                            fileName = components[0]
                        }
                        
                        // Check for 3D model via ModelIO
                        if MDLAsset.canImportFileExtension(url.pathExtension) {
                            if let data = urlToData(url) {
                                let object = LibraryEntity(context: managedObjectContext)
                                
                                object.name = fileName
                                object.ext = url.pathExtension
                                object.tags = "3d, model, " + fileName + ", " + url.pathExtension
                                object.data = data
                                object.type = 0
                                
                                do {
                                    try managedObjectContext.save()
                                } catch {}
                            }
                        } else {
                            // If not a 3D model, check if it is an Image
                            
                            var isImage = false
                            
                            #if os(OSX)
                            if let _ =  NSImage(contentsOfFile: url.path) { isImage = true }
                            #elseif os(iOS)
                            if let _ =  UIImage(contentsOfFile: url.path) { isImage = true }
                            #endif
                            
                            if isImage {
                                if let data = urlToData(url) {
                                    let object = LibraryEntity(context: managedObjectContext)
                                    
                                    object.name = fileName
                                    object.ext = url.pathExtension
                                    object.tags = "image, texture, " + fileName + ", " + url.pathExtension
                                    object.data = data
                                    object.type = 1
                                    
                                    do {
                                        try managedObjectContext.save()
                                    } catch {}
                                }
                            }
                        }

                    } catch {
                        // Handle failure.
                    }
                }
                
                
                Divider()
                
                if mode == .browser {
                    
                    let rows: [GridItem] = Array(repeating: .init(.fixed(70)), count: 1)
                    
                    ScrollView(.horizontal) {
                        LazyHGrid(rows: rows, alignment: .center) {
                            ForEach(objects, id: \.self) { object in
                                
                                if searchResults.contains(object.name!) {
                                ZStack(alignment: .center) {
                                    
                                    if object.type == 0 {
                                        // 3D Asset
                                        Image(systemName: "view.3d")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: IconSize * 0.8, height: IconSize * 0.8)
                                            .padding(.bottom, 15)
                                            .onTapGesture(perform: {
                                                selected = object.name!
                                            })
                                            .contextMenu {
                                                Button("Add to Project") {
                                                    let object = CarthageObject(type: .Geometry, name: object.name!, libraryName: object.name!)

                                                    document.model.addToProject(object: object)
                                                }
                                                
                                                Button("Remove") {
                                                    managedObjectContext.delete(object)
                                                    do {
                                                        try managedObjectContext.save()
                                                    } catch {}
                                                }
                                            }
                                    } else
                                    // Image
                                    if object.type == 1 {
                                        Image(systemName: "photo")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: IconSize * 0.8, height: IconSize * 0.8)
                                            .padding(.bottom, 15)
                                            .onTapGesture(perform: {
                                                selected = object.name!
                                            })
                                            .contextMenu {
                                                
                                                /*
                                                Button("Add to Project") {
                                                    let object = CarthageObject(type: .Geometry, name: object.name!, libraryName: object.name!)

                                                    document.model.addToProject(object: object)
                                                }*/
                                                
                                                Button("Remove") {
                                                    managedObjectContext.delete(object)
                                                    do {
                                                        try managedObjectContext.save()
                                                    } catch {}
                                                }
                                            }
                                    }
                                    
                                    /*
                                    if let image = shape.icon {
                                        Image(image, scale: 1.0, label: Text(item))
                                            .onTapGesture(perform: {
     
                                            })
                                    } else {
                                        Rectangle()
                                            .fill(Color.secondary)
                                            .frame(width: CGFloat(IconSize), height: CGFloat(IconSize))
                                            .onTapGesture(perform: {

                                            })
                                            .contextMenu {
                                                Button("Add to Project") {
                                                    
                                                    let object = CarthageObject(type: .Geometry, name: object.name!, assetName: object.name!)

                                                    document.model.addToProject(object: object)
                                                }
                                                
                                                Button("Remove") {
                                                    managedObjectContext.delete(object)
                                                    try! managedObjectContext.save()
                                                }
                                            }
                                    }*/
                                    
                                    if object.name == selected {
                                        Rectangle()
                                            .stroke(Color.accentColor, lineWidth: 2)
                                            .frame(width: CGFloat(IconSize), height: CGFloat(IconSize))
                                            .allowsHitTesting(false)
                                    }
                                    
                                    Rectangle()
                                        .fill(.black)
                                        .opacity(0.4)
                                        .frame(width: CGFloat(IconSize - (object.name == selected ? 2 : 0)), height: CGFloat(20 - (object.name == selected ? 1 : 0)))
                                        .padding(.top, CGFloat(IconSize - (20 + (object.name == selected ? 1 : 0))))
                                    
                                    object.name.map(Text.init)
                                    //Text(item.name)
                                        .padding(.top, CGFloat(IconSize - 20))
                                        .allowsHitTesting(false)
                                        .foregroundColor(.white)
                                }
                                }
                            }
                        }
                        .padding()
                    .padding(.top, 0)
                }
                    
                .onReceive(document.model.searchResultsChanged) { results in
                    searchResults = results
                }
            } else
            if mode == .log {
                //TextEditor(text: $log)
                //    .onReceive(document.model.logChanged) { _ in
                //        log = document.model.logText
                //    }
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        HStack {
                            Text(log)
                                .lineLimit(nil)
                            Spacer()
                        }
                        .padding(.leading, 4)
                    }.frame(maxWidth: .infinity)
                }
            }
        }
        .animation(.default)
        
        .onReceive(document.model.logChanged) { _ in
            log = document.model.logText
            mode = .log
        }
    }
    
    /// Loads an url into a Data
    func urlToData(_ url: URL) -> Data? {
                
        do {
            let data = try Data(contentsOf: url)
            return data
        } catch {
            print(error)
        }
        
        /*
        if var tempURL = document.model.getTempURL() {
            tempURL.appendPathExtension(".usd")
            
            let asset = MDLAsset(url: url)
            
            do {
                try asset.export(to: tempURL)
                let data = try Data(contentsOf: tempURL)
                return data
            } catch {
                print(error)
            }
        }*/
        
        return nil
    }
}
