//
//  CreateFileView.swift
//  Remote Text
//
//  Created by Sam Gauck on 4/7/23.
//

import SwiftUI

struct CreateFileView: View {
    @EnvironmentObject var model: FileModel
  
    @State var fileName = ""
    @State var content = ""
    
    var body: some View {
        VStack {
            TextField(text: $fileName, prompt: Text("README.md")) {
                Text("File name")
            }.padding()
            TextEditor(text: $content)
                .monospaced()
                .scrollContentBackground(.hidden)
                .background(.gray)
                .cornerRadius(5)
                .padding()
        }
        .navigationTitle("Create new file")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        Task {
                            let newFile = await model.createFile(named: fileName, withContent: content)
                            self.model.path.removeLast()
                            //TODO: fix
                            self.model.path.append(ContentView.Navigation.fileEditor(id: newFile.id, hash: "TODO", branches: ["main"]))
                        }
                    } label: {
                        Text("Create")
                    }
                    Button {
                        Task {
                            await model.createFile(named: fileName, withContent: content)
                            self.model.path.removeLast()
                        }
                    } label: {
                        Text("Create & Close")
                    }
                } label: {
                    Text("Create & Preview")
                } primaryAction: {
                    Task {
                        let newFile = await model.createFile(named: fileName, withContent: content)
                        let hash = await model.getHistory(id: newFile.id).commits[0].hash
                        self.model.path.removeLast()
                        self.model.path.append(ContentView.Navigation.fileEditor(id: newFile.id, hash: hash, branches: ["main"]))
                        
                        self.model.path.append(ContentView.Navigation.previewFile(id: newFile.id, hash: hash, filename: newFile.name))
                    }
                }
                .disabled(fileName.isEmpty)
            }
        }
    }
}
