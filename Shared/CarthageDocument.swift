//
//  CarthageDocument.swift
//  Shared
//
//  Created by Markus Moenig on 11/7/21.
//

import SwiftUI
import UniformTypeIdentifiers

extension UTType {
    static var carthageProject: UTType {
        UTType(exportedAs: "com.Carthage.project")
    }
}

struct CarthageDocument: FileDocument {
    
    var model       = CarthageModel()

    static var readableContentTypes: [UTType] { [.carthageProject] }
    static var writableContentTypes: [UTType] { [.carthageProject] }

    init() {
    }
    
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
                let project = try? JSONDecoder().decode(CarthageProject.self, from: data)
        else {
            /*
            do {
                let data = configuration.file.regularFileContents
                let response = try JSONDecoder().decode(Project.self, from: data!)
            } catch {
                print(error) //here.....
            }*/
            
            throw CocoaError(.fileReadCorruptFile)
        }
        if data.isEmpty == false {
            
            model.setProject(project: project)
        }
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        var data = Data()
        
        let encodedData = try? JSONEncoder().encode(model.project)
        if let json = String(data: encodedData!, encoding: .utf8) {
            data = json.data(using: .utf8)!
        }
        
        return .init(regularFileWithContents: data)
    }
}
