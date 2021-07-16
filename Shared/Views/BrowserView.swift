//
//  BrowserView.swift
//  Carthage
//
//  Created by Markus Moenig on 12/7/21.
//

import SwiftUI
import ModelIO

struct BrowserView: View {
    
    @Environment(\.managedObjectContext) var managedObjectContext

    @FetchRequest(
      entity: LibraryEntity.entity(),
      sortDescriptors: [
        NSSortDescriptor(keyPath: \LibraryEntity.name, ascending: true)
      ]
    ) var objects: FetchedResults<LibraryEntity>
    
    @Binding var document               : CarthageDocument

    @State private var IconSize         : CGFloat = 80
        
    @State private var importing        : Bool = false
    
    @State private var selected         : String = ""

    var body: some View {
            
            HStack(alignment: .top, spacing: 1) {

                VStack(alignment: .leading, spacing: 4) {
                                    
                    Button(action: {
                        importing = true
                    })
                    {
                        Image(systemName: "plus")
                            .imageScale(.large)
                    }
                    .buttonStyle(.borderless)
                    .padding(.top, 10)
                    //.padding(.leading, 4)
                              
                    //Divider()
                    
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
                        
                        if MDLAsset.canImportFileExtension(url.pathExtension) {
                            
                            var fileName = url.lastPathComponent
                            
                            let components = fileName.components(separatedBy: ".")
                            if components.count > 1 {
                                fileName = components[0]
                            }

                            if let data = modelToData(url) {
                                let object = LibraryEntity(context: managedObjectContext)
                                
                                object.name = fileName
                                object.ext = url.pathExtension
                                object.tags = "3d model, 3d"
                                object.data = data
                                
                                try! managedObjectContext.save()
                            }
                        }

                    } catch {
                        // Handle failure.
                    }
                }
                
                
                Divider()
                
                let rows: [GridItem] = Array(repeating: .init(.fixed(70)), count: 1)
                
                ScrollView(.horizontal) {
                    LazyHGrid(rows: rows, alignment: .center) {
                        ForEach(objects, id: \.self) { object in
                            
                            ZStack(alignment: .center) {
                                
                                if object.tags!.contains("3d") {
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
                                                let object = CarthageObject(type: .Geometry, name: object.name!, assetName: object.name!)

                                                document.model.addToProject(object: object)
                                            }
                                            
                                            Button("Remove") {
                                                managedObjectContext.delete(object)
                                                try! managedObjectContext.save()
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
                    .padding()
                .padding(.top, 0)
            }
            
            //.onReceive(model.componentPreviewNeedsUpdate) { _ in
            //}
            
            //.onReceive(model.objectSelected) { object in

            //}
            
            //.onChange(of: brushSize) { value in
            //    model.brushSize = value
            //}
        }
    }
    
    /// Imports a model and returns a Data file, if the model is not USDX convert it to USD so that we have a single file representation of the model.
    func modelToData(_ url: URL) -> Data? {
                
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
