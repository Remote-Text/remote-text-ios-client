//
//  HTMLDocument.swift
//  Remote Text
//
//  Created by Sima Nerush on 4/23/23.
//

import SwiftUI
import WebKit

public struct HTMLDocument {
  let title: String
  let source: Data
  
  init(title: String = "", source: Data = Data()) {
    self.title = title
    self.source = source
  }
}

extension HTMLDocument: Transferable {
  static public var transferRepresentation: some TransferRepresentation {
    FileRepresentation(exportedContentType: .html) { html in
      let fileURL = FileManager.default
        .temporaryDirectory
        .appendingPathComponent(html.title)
      
      try html.source.write(to: fileURL)
      return SentTransferredFile(fileURL)
    }
  }
}


