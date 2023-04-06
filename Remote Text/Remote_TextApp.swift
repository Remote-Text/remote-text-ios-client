//
//  Remote_TextApp.swift
//  Remote Text
//
//  Created by Sima Nerush on 4/6/23.
//

import SwiftUI

@main
struct Remote_TextApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: Remote_TextDocument()) { file in
            ContentView(document: file.$document)
        }
    }
}
