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
    WindowGroup {
      ContentView(model: FileModel.shared)
    }
  }
}
