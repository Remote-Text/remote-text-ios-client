//
//  FileDetailView.swift
//  Remote Text
//
//  Created by Sam Gauck on 4/7/23.
//

import SwiftUI

struct FileDetailView: View {
    private let id: UUID
    var model: FileModel
    @State var hash: String = ""
    
    @State private var loading = true
    
    init(_ file: FileSummary, _ model: FileModel) {
        self.id = file.id
        self._fileName = State(wrappedValue: file.name)
        self.model = model
    }
    
    @State var fileName = ""
    @State var content = ""
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        if loading {
            Image(systemSymbol: .arrowDownDoc).scaledToFit()
                .onAppear {
                    Task {
                        let history = await model.getHistory(id: id)
                        self.hash = history.refs.first { $0.name == "main" }!.hash
                        let file = await model.getFile(id: id, atVersion: self.hash)
                        self.fileName = file.name
                        self.content = file.content
                        self.loading = false
                    }
                }
        } else {
            VStack {
                TextField(text: $fileName, prompt: Text("README.md")) {
                    Text("File name")
                }.padding()
                TextEditor(text: $content)
                    .monospaced()
                    .padding()
            }
            .navigationTitle(fileName)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task {
                            await model.saveFile(id: id, name: fileName, content: content, parentCommit: hash, branch: "main")
                            self.dismiss.callAsFunction()
                        }
                    } label: {
                        Text("Save")
                    }.disabled(fileName.isEmpty)
                }
            }
        }
    }
}
