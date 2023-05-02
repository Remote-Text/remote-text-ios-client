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
    @State var unreachable = false
    
    @State private var taskId: UUID = .init()
    
//    @State private var navPath = NavigationPath()
    
    var filesList: some View {
        Group {
            if files.isEmpty {
                Text("No Files")
                    .font(.body.lowercaseSmallCaps())
                    .foregroundColor(.gray)
            } else {
                ScrollView(.vertical) {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))]) {
                        ForEach(files) { file in
                            if deleting {
                                VStack {
                                    ZStack(alignment: .topLeading) {
                                        Image(systemSymbol: .docText)
                                            .font(.largeTitle)
                                            .imageScale(.large)
                                        Button {
                                            self.files = self.files.filter { $0.id != file.id }
                                            Task {
                                                await model.deleteFile(id: file.id)
                                            }
                                        } label: {
                                            Image(systemSymbol: .minusCircleFill)
                                                .foregroundColor(.red)
                                                .background(in: Circle())
                                        }
                                    }
                                    Text(file.name)
                                }
                                .padding()
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
                                .simultaneousGesture(LongPressGesture()
                                    .onEnded { finished in
                                        print("Gesture complete")
                                        self.deleting = true
                                    })
                            }
                        }
                    }
                }
            }
        }
        .refreshable {
            print("Loading files (drag)")
            taskId = .init()
        }
    }
    
    var body: some View {
        NavigationStack(path: $model.path) {
            ZStack {
                filesList
                if self.unreachable {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Text("Server Unreachable")
                                .font(.body.lowercaseSmallCaps())
                                .padding()
                                .background(.red)
                                .cornerRadius(5)
                                .transition(.asymmetric(insertion: .push(from: .bottom), removal: .scale))
                            Spacer()
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Button {
                            print("Loading files (button)")
                            self.taskId = .init()
                        } label: {
                            Image(systemSymbol: .arrowClockwise)
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
            print("Loading files (periodic)")
            self.taskId = .init()
        }
        .task(id: taskId) {
            print("Rerunning task")
            self.isLoading = true
            do {
                self.files = try await model.listFiles()
                withAnimation {
                    self.unreachable = false
                }
                print("success")
            } catch let error as URLError {
                switch error.code {
                case URLError.cannotConnectToHost:
                    withAnimation {
                        self.unreachable = true
                    }
                default:
                    print("URLError \(error.code)")
                }
            } catch let error {
                print("Unknown error type: \(type(of: error))")
            }
            self.isLoading = false
        }
    }
}
