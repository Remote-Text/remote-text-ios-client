//
//  Remote_TextApp.swift
//  Remote Text
//
//  Created by Sima Nerush on 4/6/23.
//

import SwiftUI

@main
struct Remote_TextApp: App {
  
  @ObservedObject var model: FileModel
  
  init() {
    self.model = FileModel()
  }
  
  var body: some Scene {
    WindowGroup {
      ContentView(model: model)
        .task {
          await model.createFile(named: "sam.md", withContent: "Hello, world!")
        }
    }
  }
}
