//
//  FileDetailView.swift
//  Remote Text
//
//  Created by Sam Gauck on 4/7/23.
//

import SwiftUI

struct FileDetailView: View {
    
    @Environment(\.dismiss) var dismiss
    @ObservedObject var model: FileModel
  
    @State var hash: String = ""
    @State var fileName = ""
    @State var content = ""
    @State private var loading = true
  
    private let id: UUID

    init(_ file: FileSummary, _ model: FileModel) {
        self.id = file.id
        self._fileName = State(wrappedValue: file.name)
        self.model = model
    }
    
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
                    .scrollContentBackground(.hidden)
                    .background(.gray)
                    .cornerRadius(5)
                    .padding()
            }
            .navigationTitle(fileName)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        PreviewView(id, model, hash)
                    } label: {
                        Text("Preview")
                    }
                }
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

struct PreviewView: View {
    private let id: UUID
    private let model: FileModel
    private let hash: String
    
    @State private var state: PreviewState = .loading
    @State private var data: Data = Data()
    
    init(_ id: UUID, _ model: FileModel, _ hash: String) {
        self.id = id
        self.model = model
        self.hash = hash
    }
    
    enum PreviewState {
        case loading
        case previewFailed, previewSucceeded
        case previewFetched
    }
    
    var body: some View {
        switch state {
        case .loading:
            VStack {
                ProgressView()
                Text("Previewing file")
            }
            .onAppear {
                Task {
                    let comp = await model.previewFile(id: id, atVersion: hash)
                    switch comp.state {
                    case .SUCCESS:
                        self.state = .previewSucceeded
                    case .FAILURE:
                        self.state = .previewFailed
                    }
                }
            }
        case .previewFailed:
            Text("Preview unsuccessful")
        case .previewSucceeded:
            VStack {
                ProgressView()
                Text("Fetching preview")
            }
            .onAppear {
                Task {
                    let data = await model.getPreview(id: id, atVersion: hash)
                    self.data = data
                    self.state = .previewFetched
                }
            }
        case .previewFetched:
            PDFKitRepresentedView(data)
        }
    }
}

import PDFKit
struct PDFKitRepresentedView: UIViewRepresentable {
    let data: Data

    init(_ data: Data) {
        self.data = data
    }

    func makeUIView(context: UIViewRepresentableContext<PDFKitRepresentedView>) -> PDFKitRepresentedView.UIViewType {
        // Create a `PDFView` and set its `PDFDocument`.
        let pdfView = PDFView()
        pdfView.document = PDFDocument(data: data)
        return pdfView
    }

    func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<PDFKitRepresentedView>) {
        // Update the view.
    }
}
