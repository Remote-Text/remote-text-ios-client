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
import WebKit

struct FileDetailView: View {
    
    @Environment(\.dismiss) var dismiss
    @ObservedObject var model: FileModel
  
    @State var hash: String = ""
    @State var fileName = ""
    @State var content = ""
    @State private var loading = true
    @State private var initialContent = ""
  
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
                        self.initialContent = file.content
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
                if self.initialContent == self.content {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        NavigationLink {
                            PreviewView(id, model, hash, fileName)
                        } label: {
                            Text("Preview")
                        }
                    }
                } else {
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
}

struct PreviewView: View {
    private let id: UUID
    private let model: FileModel
    private let hash: String
    private let filename: String
    
    @State private var state: PreviewState = .loading
    @State private var data: Data = Data()
    @State private var log: String = ""
    @State private var type: PreviewType = .HTML
  
    @State private var pdfDocument: PDFDocument = PDFDocument()
    @State private var htmlDocument: HTMLDocument = HTMLDocument()
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
                        self.log = comp.log
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
                    let (data, type) = await model.getPreview(id: id, atVersion: hash)
                    self.data = data
                    self.state = .previewFetched
                    self.type = type
                }
            }
        case .previewFetched:
            switch self.type {
            case .PDF:
                PDFKitRepresentedView(data)
                    .navigationTitle(filename.replacing(/\.tex$/, with: ".pdf"))
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            ShareLink(item: pdfDocument,
                                      preview: SharePreview(
                                        filename.replacing(/\.tex$/, with: ".pdf"),
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
                        self.pdfDocument = pdf
                        self.previewImage = Image(uiImage: image)
                    }
            case .HTML:
                WebView(self.data)
                    .navigationTitle(filename.replacing(/\..+$/, with: ".html"))
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                          ShareLink(item: htmlDocument,
                                      preview: SharePreview(
                                        filename.replacing(/\..+$/, with: ".html")
                                      )
                            )
                        }
                    }
                    .onAppear {
                      self.htmlDocument = HTMLDocument(title: filename, source: data)
                    }
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
struct WebView: UIViewRepresentable {
    let source: String
    
    init(_ data: Data) {
        self.source = String(bytes: data, encoding: .utf8)!
    }
    
    func makeUIView(context: Context) -> WKWebView {
        return WKWebView()
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        uiView.loadHTMLString(source, baseURL: nil)
    }
}
