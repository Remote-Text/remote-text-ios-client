//
//  FileDetailView.swift
//  Remote Text
//
//  Created by Sam Gauck on 4/7/23.
//

import SwiftUI
import HighlightedTextEditor
import CodeEditor
import PDFKit

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
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
//                        PreviewView(id, model, hash, fileName.split(separator: ".").dropLast(1).joined(separator: ".") + ".pdf")
                        PreviewView(id, model, hash, fileName.replacing(/\.tex$/) { _ in ".pdf" })
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
    private let filename: String
    
    @State private var state: PreviewState = .loading
    @State private var data: Data = Data()
    @State private var log: String = ""
  
    @State private var document: PDFDocument = PDFDocument()
    @State private var previewImage: Image = Image("")
    
    init(_ id: UUID, _ model: FileModel, _ hash: String, _ filename: String) {
        self.id = id
        self.model = model
        self.hash = hash
        self.filename = filename
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
            .navigationTitle("Previewing file")
            .onAppear {
                Task {
                    let comp = await model.previewFile(id: id, atVersion: hash)
                    switch comp.state {
                    case .SUCCESS:
                        self.state = .previewSucceeded
                    case .FAILURE:
                        self.state = .previewFailed
                        self.log = comp.log
                    }
                }
            }
        case .previewFailed:
            VStack {
                Text("Preview unsuccessful")
                    .font(.title)
                ScrollView(.vertical) {
                    Text(log)
                        .lineLimit(nil)
                }
            }
            .navigationTitle("Preview unsuccessful")
        case .previewSucceeded:
            VStack {
                ProgressView()
                Text("Fetching preview")
            }
            .navigationTitle("Fetching preview")
            .onAppear {
                Task {
                    let data = await model.getPreview(id: id, atVersion: hash)
                    self.data = data
                    self.state = .previewFetched
                }
            }
        case .previewFetched:
            PDFKitRepresentedView(data)
                .navigationTitle(filename)
                .toolbar {
                  ToolbarItem(placement: .navigationBarTrailing) {
                    let _ = print(document.documentAttributes!)
                    ShareLink(item: document,
                              preview: SharePreview(
                                filename,
                                image: previewImage
                              )
                    )
                  }
                }
                .onAppear {
                  guard let pdf = PDFDocument(data: data),
                        let image = pdf.imageRepresenation else {
                    fatalError("something went wrong...")
                  }
                  
                  pdf.documentAttributes![PDFDocumentAttribute.titleAttribute] = filename
                  self.document = pdf
                  self.previewImage = Image(uiImage: image)
                }
        }
    }
}

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
