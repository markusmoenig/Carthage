//
//  CarthageApp.swift
//  Shared
//
//  Created by Markus Moenig on 11/7/21.
//

import SwiftUI

@main
struct CarthageApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: CarthageDocument()) { file in
            ContentView(document: file.$document)
        }
    }
}
