//
//  CreateFileView.swift
//  Remote Text
//
//  Created by Sam Gauck on 4/7/23.
//

import SwiftUI

struct CreateFileView: View {
  
    @Environment(\.dismiss) var dismiss
  
    @ObservedObject var model: FileModel
  
    @State var fileName = ""
    @State var content = ""
    
    var body: some View {
        VStack {
            TextField(text: $fileName, prompt: Text("README.md")) {
                Text("File name")
            }.padding()
            TextEditor(text: $content)
                .monospaced()
                .padding()
        }
        .navigationTitle("Create new file")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    Task {
                        await model.createFile(named: fileName, withContent: content)
                        self.dismiss.callAsFunction()
                    }
                } label: {
                    Text("Done")
                }.disabled(fileName.isEmpty)
            }
        }
    }
}
