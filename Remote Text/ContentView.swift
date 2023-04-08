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
    
    @State var deleting = false
    
    var body: some View {
        NavigationStack {
            Group {
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
                                if deleting {
                                    VStack {
                                        ZStack {
                                            Image(systemSymbol: .docText)
                                                .font(.largeTitle)
                                                .imageScale(.large)
                                            VStack {
                                                HStack {
                                                    Button {
                                                        Task {
                                                            await model.deleteFile(id: id!)
                                                        }
                                                    } label: {
                                                        Image(systemSymbol: .minusCircleFill)
                                                            .foregroundColor(.red)
                                                    }
                                                    Spacer()
                                                }
                                                Spacer()
                                            }
                                        }
                                        Text(file.name)
                                    }
                                } else {
                                    NavigationLink {
                                        FileDetailView(file, model)
                                    } label: {
                                        VStack {
                                            Image(systemSymbol: .docText)
                                                .font(.largeTitle)
                                                .imageScale(.large)
                                            Text(file.name)
                                        }
                                    }
                                    .padding()
                                }
                            }
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if deleting {
                        
                    } else {
                        if isLoading {
                            ProgressView()
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
                            }
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if deleting {
                        Button {
                            self.deleting = false
                        } label: {
                            Text("Done")
                        }
                    } else {
                        NavigationLink {
                            CreateFileView(model: model)
                        } label: {
                            Image(systemSymbol: .plus)
                        }.padding()
                    }
                }
            }
        }
        .onReceive(timer) { input in
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
