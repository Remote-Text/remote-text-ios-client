//
//  FileListView.swift
//  Remote Text
//
//  Created by Sam Gauck on 5/2/23.
//

import SwiftUI


struct FileListView: View {
    @Environment(\.refresh) var refresh: () -> Void
    @Environment(\.isLoading) var isLoading: Bool
    @Environment(\.unreachable) var unreachable: Bool
    
    @EnvironmentObject var model: FileModel
    
    @State private var deleting: Bool = false
    
    @Binding var files: [FileSummary]
    
    init(files: Binding<[FileSummary]>) {
        self._files = files
    }
    
    var body: some View {
        filesList
            .unreachable(self.unreachable)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Button {
                            self.refresh()
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
                        NavigationLink(value: ContentView.Navigation.fileCreator) {
                            Image(systemSymbol: .plus)
                        }.padding()
                    }
                }
            }
    }
    
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
//                                NavigationLink(value: ContentView.Navigation.fileEditor(file: file)) {
                                NavigationLink(value: ContentView.Navigation.fileHistory(id: file.id)) {
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
            self.refresh()
        }
    }
}
