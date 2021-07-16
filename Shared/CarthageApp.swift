//
//  CarthageApp.swift
//  Shared
//
//  Created by Markus Moenig on 11/7/21.
//

import SwiftUI

@main
struct CarthageApp: App {
    
    let persistenceController = PersistenceController.shared
    @Environment(\.scenePhase) var scenePhase

    var body: some Scene {
        DocumentGroup(newDocument: CarthageDocument()) { file in
            ContentView(document: file.$document)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
        .onChange(of: scenePhase) { _ in
            persistenceController.save()
        }
    }
}
