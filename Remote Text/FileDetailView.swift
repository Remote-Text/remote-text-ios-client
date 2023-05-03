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
  
    @State var fileName = ""
    @State var content = ""
    @State private var loading = true
    @State private var initialFilename = ""
    @State private var initialContent = ""
  
    private let id: UUID
    private let hash: String
    
    private let branchOptions: [String]
    enum Branch: Hashable {
        case none
        case branch(name: String)
    }
    @State private var branch: String = ""
    private var branchSelection: Binding<Branch> {
        .init(
            get: {
                if self.branchOptions.contains(self.branch) {
                    return .branch(name: self.branch)
                } else {
                    return .none
                }
            }, set: { newValue in
                if case .branch(let name) = newValue {
                    self.branch = name
                } else {
                    //Now editing branch name
                    self.branch = ""
                }
            }
        )
    }
    
    init(id file: UUID, hash: String, branches: [String]) {
        self.id = file
        self.hash = hash
        self.branchOptions = branches
        if let first = branches.first {
            self._branch = State(wrappedValue: first)
        }
    }
    
    var body: some View {
        Group {
            if loading {
                Image(systemSymbol: .arrowDownDoc).scaledToFit()
                    .onAppear {
                        Task {
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
                    HStack {
                        Text("Filename:").bold()
                        TextField("Filename", text: $fileName, prompt: Text("README.md")).labelsHidden()
                        
                        Spacer()//doesn't space enough! why? fuck me, i guess. TODO: fix
                        Text("Branch:").bold()
                        TextField("branch", text: $branch, prompt: Text("main"))
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                        Picker("branch", selection: branchSelection) {
                            ForEach(self.branchOptions, id: \.self) { b in
                                Text(b).tag(Branch.branch(name: b))
                            }
                            Text("New Branch")
                                .tag(Branch.none)
                        }
                    }
                    .padding()
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
                                        let res = await model.saveFile(id: id, name: fileName, content: content, parentCommit: hash, branch: branch)
                                        let idx = self.model.path.count - 1
                                        self.model.path[idx] = .fileEditor(id: self.id, hash: res.hash, branches: [branch])
                                    }
                                } label: {
                                    Text("Save")
                                }
                                Button {
                                    Task {
                                        await model.saveFile(id: id, name: fileName, content: content, parentCommit: hash, branch: branch)
                                        self.model.path.removeLast()
                                    }
                                } label: {
                                    Text("Save & Close")
                                }
                            } label: {
                                Text("Save & Preview")
                            } primaryAction: {
                                Task {
                                    let res = await model.saveFile(id: id, name: fileName, content: content, parentCommit: hash, branch: branch)
                                    self.model.path.removeLast()
                                    self.model.path += [.fileEditor(id: self.id, hash: res.hash, branches: [branch]), .previewFile(id: self.id, hash: res.hash, filename: self.fileName)]
                                }
                            }
                            .disabled(fileName.isEmpty || branch.isEmpty)
                        }
                    }
                }
            }
        }
    }
}
