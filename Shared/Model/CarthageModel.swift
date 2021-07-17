//
//  CarthageModel.swift
//  Carthage
//
//  Created by Markus Moenig on 11/7/21.
//

import Combine
import JavaScriptCore
import ModelIO

class CarthageModel: NSObject, ObservableObject {
    
    enum EngineType {
        case SceneKit, RealityKit
    }

    @Published var selected         : CarthageObject? = nil

    @Published var currentScene     : CarthageObject? = nil

    var engineType                  : EngineType = .SceneKit
    
    /// Send when an object has been selected
    let objectSelected              = PassthroughSubject<CarthageObject, Never>()
    
    /// Send when an object has been selected
    let engineChanged               = PassthroughSubject<Void, Never>()
    
    /// Send when an object has been selected
    let projectChanged              = PassthroughSubject<Void, Never>()
    
    /// Send when the user search generated new results, used to update browser view
    let searchResultsChanged        = PassthroughSubject<[String], Never>()
    
    /// The current rendering engine
    var engine                      : CarthageScene? = nil
    
    /// 
    var context                     = JSContext()
    
    var scriptEditor                : ScriptEditor? = nil
    
    /// The project itself
    var project                     : CarthageProject
    
    /// A dictionary containing local temporary URLs for library names / assets which have already been copied to local storage
    var urlLibrary                  : [String: URL] = [:]

    
    override init() {

        project = CarthageProject()
        selected = project.scenes.first
        
        super.init()
        
        setScene(project.scenes.first!)
    }
    
    func setScene(_ scene: CarthageObject)
    {
        engine?.destroy()
        if engineType == .SceneKit {
            engine = SceneKitScene(model: self, sceneObject: scene)
        } else {
            engine = RealityKitScene(model: self, sceneObject: scene)
        }
        
        currentScene = scene
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.objectSelected.send(scene)
        }
    }
    
    /// Updates the engine entity of the currently selected object, i.e. applies changes in the UI to the rendering engine.
    func updateSelected() {
        if let selected = selected {
            if let entity = selected.entity {
                entity.updateFromModel()
            }
        }
    }
    
    /// Adds the given object ti the project
    func addToProject(object: CarthageObject) {
        if let selected = selected {
            
            if selected.children == nil {
                selected.children = []
            }
            
            selected.children!.append(object)
            object.parent = selected
            engine?.addObject(object: object)
            
            self.selected = object
            objectSelected.send(object)
            projectChanged.send()
            if engineType == .RealityKit {
                engineChanged.send()
            }
        }
    }
    
    /// Gets the url for an library item, i.e. saves the data to a temporary file and returns the URL
    func getLibraryURL(_ libraryName: String) -> URL? {
        
        // If the url for the given library name already exists, return it
        if let url = urlLibrary[libraryName] {
            return url
        }
        
        // Otherwise copy the data from the library asset to a temporary file so that i can be loaded via the url
        // As SceneKit and RealityKit mostly load 3D assets via URLs 
        
        var rc : URL? = nil
        
        let request = LibraryEntity.fetchRequest()
        
        let managedObjectContext = PersistenceController.shared.container.viewContext
        let objects = try! managedObjectContext.fetch(request)

        objects.forEach { ca in
            
            guard let objectName = ca.name else {
                return
            }

            if objectName == libraryName {
                
                if var url = getTempURL() {
                    url.appendPathExtension(ca.ext!)
                    
                    if let data = ca.data {
                        do {
                            try data.write(to: url)
                            rc = url
                        } catch {
                            
                        }
                    }
                }
            }
        }
        
        return rc
    }
    
    /// Gets the URL for a temporary file name
    func getTempURL() -> URL? {
        
        let directory = NSTemporaryDirectory()
        let fileName = NSUUID().uuidString

        return NSURL.fileURL(withPathComponents: [directory, fileName])
    }
}
