//
//  ContentView.swift
//  Remote Text
//
//  Created by Sima Nerush on 4/6/23.
//

import SwiftUI
import SFSafeSymbols

struct ContentView: View {
    
    @ObservedObject var model: FileModel
    
    @State private var _id: String = ""
    private var id: UUID? {
        UUID(uuidString: _id)
    }
    
    @State private var data = ""
    @State private var hash: String = ""
    @State private var name: String = ""
    @State private var content: String = ""
    @State var files: [FileSummary] = []
    
    @State private var isLoading = false
    
    let timer = Timer.publish(every: 15, on: .main, in: .common).autoconnect()
    
    private func load(t: Timer) {
        
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    if isLoading {
                        ProgressView()
                            .padding()
                    } else {
                        Button {
                            Task {
#if DEBUG
                                print("Loading files (button)")
#endif
                                isLoading = true
                                self.files = await model.listFiles()
                                isLoading = false
                            }
                        } label: {
                            Image(systemSymbol: .arrowClockwise)
                        }.padding()
                    }
                    Spacer()
                    NavigationLink {
                        CreateFileView(model: model)
                    } label: {
                        Image(systemSymbol: .plus)
                    }.padding()
                }
                Spacer()
                if files.isEmpty {
                    Text("No Files")
                        .font(.body.lowercaseSmallCaps())
                        .foregroundColor(.gray)
                        .onAppear {
                            Task {
#if DEBUG
                                print("Loading files (onAppear)")
#endif
                                isLoading = true
                                self.files = await model.listFiles()
                                isLoading = false
                            }
                        }
                } else {
                    ScrollView(.vertical) {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))]) {
                            ForEach(files) { file in
                                NavigationLink {
                                    FileDetailView(file, model)
                                } label: {
                                    VStack {
                                        Image(systemSymbol: .docText)
                                            .font(.largeTitle)
                                            .imageScale(.large)
                                        Text(file.name)
                                    }
                                }.padding()
                            }
                        }
                    }
                }
                Spacer()
            }
        }.onReceive(timer) { input in
            Task {
#if DEBUG
                print("Loading files (periodic)")
#endif
                self.isLoading = true
                self.files = await model.listFiles()
                self.isLoading = false
            }
        }
    }
}
