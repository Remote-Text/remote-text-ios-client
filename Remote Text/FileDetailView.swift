//
//  FileDetailView.swift
//  Remote Text
//
//  Created by Sam Gauck on 4/7/23.
//

import SwiftUI
import HighlightedTextEditor
import CodeEditor

struct FileDetailView: View {
    @EnvironmentObject var model: FileModel
  
    @State var hash: String = ""
    @State var fileName = ""
    @State var content = ""
    @State private var loading = true
    @State private var initialFilename = ""
    @State private var initialContent = ""
  
    private let id: UUID

    init(_ file: FileSummary) {
        self.id = file.id
        self._fileName = State(wrappedValue: file.name)
    }
    
    var body: some View {
        Group {
            if loading {
                Image(systemSymbol: .arrowDownDoc).scaledToFit()
                    .onAppear {
                        Task {
                            let history = await model.getHistory(id: id)
                            self.hash = history.refs.first { $0.name == "main" || $0.name == "master" }!.hash
                            let file = await model.getFile(id: id, atVersion: self.hash)
                            self.fileName = file.name
                            self.content = file.content
                            self.initialFilename = file.name
                            self.initialContent = file.content
                            self.loading = false
                        }
                    }
            } else {
                VStack {
                    TextField(text: $fileName, prompt: Text("README.md")) {
                        Text("File name")
                    }.padding()
                    switch fileName.split(separator: ".").last {
                        //                case "md", "markdown":
                        //                    HighlightedTextEditor(text: $content, highlightRules: .markdown)
                        ////                    CodeEditor(source: $content, language: .markdown)
                        //                        .monospaced()
                        //                        .scrollContentBackground(.hidden)
                        //                        .background(.gray)
                        //                        .cornerRadius(5)
                        //                        .padding()
                        //                case "tex":
                        //                    CodeEditor(source: $content, language: .tex)
                        //                        .monospaced()
                        //                        .scrollContentBackground(.hidden)
                        //                        .background(.gray)
                        //                        .cornerRadius(5)
                        //                        .padding()
                    default:
                        TextEditor(text: $content)
                            .monospaced()
                            .scrollContentBackground(.hidden)
                            .background(.gray)
                            .cornerRadius(5)
                            .padding()
                    }
                }
                .navigationTitle(fileName)
                .toolbar {
                    if self.initialContent == self.content && self.initialFilename == self.fileName {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            NavigationLink(value: ContentView.Navigation.previewFile(id: id, hash: hash, filename: fileName)) {
                                Text("Preview")
                            }
                        }
                    } else {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Menu {
                                Button {
                                    Task {
                                        let res = await model.saveFile(id: id, name: fileName, content: content, parentCommit: hash, branch: "main")
                                        self.hash = res.hash
                                        self.initialContent = self.content
                                    }
                                } label: {
                                    Text("Save")
                                }
                                Button {
                                    Task {
                                        await model.saveFile(id: id, name: fileName, content: content, parentCommit: hash, branch: "main")
                                        self.model.path.removeLast()
                                    }
                                } label: {
                                    Text("Save & Close")
                                }
                            } label: {
                                Text("Save & Preview")
                            } primaryAction: {
                                Task {
                                    let res = await model.saveFile(id: id, name: fileName, content: content, parentCommit: hash, branch: "main")
                                    self.hash = res.hash
                                    self.initialContent = self.content
                                    self.model.path.append(ContentView.Navigation.previewFile(id: id, hash: self.hash, filename: self.fileName))
                                }
                            }
                            .disabled(fileName.isEmpty)
                        }
                    }
                }
            }
        }
    }
}
