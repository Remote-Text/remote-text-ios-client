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
    
    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                  if isLoading {
                        ProgressView()
                      } else {
                        Button {
                            Task {
                                print("in task")
                                isLoading = true
                                self.files = await model.listFiles()
                                isLoading = false
                            }
                        } label: {
                            Image(systemSymbol: .arrowClockwise)
                        }.padding(.all)
                      }
                    Spacer()
                    NavigationLink {
                        CreateFileView(model: model)
                    } label: {
                        Image(systemSymbol: .plus)
                    }.padding(.all)
                }
                Spacer()
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
                            }.padding(.all)
                        }
                    }
                }
                Spacer()
            }
        }
    }
}
