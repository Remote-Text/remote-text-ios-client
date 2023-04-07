//
//  ContentView.swift
//  Remote Text
//
//  Created by Sima Nerush on 4/6/23.
//

import SwiftUI

struct ContentView: View {
    
    @ObservedObject var model: FileModel
    @State private var data = ""
    
    @State private var _id: String = ""
    private var id: UUID? {
        UUID(uuidString: _id)
    }
    @State private var hash: String = ""
    @State private var name: String = ""
    @State private var content: String = ""
    
    
    var body: some View {
        HStack {
            VStack {
                TextField("ID", text: $_id)
                TextField("Hash", text: $hash)
                TextField("Name", text: $name)
                TextField("Content", text: $content)
            }
            VStack {
                Button {
                    Task {
                        print(await model.listFiles())
                    }
                } label: {
                    Text("List Files")
                }
                Button {
                    Task {
                        let file = await model.createFile(named: name, withContent: content)
                        _id = file.id.uuidString
                        print(file)
                    }
                } label: {
                    Text("Create File")
                }
                Button {
                    Task {
                        guard let id = id else {
                            return
                        }
                        let file = await model.getFile(id: id, atVersion: hash)
                        name = file.name
                        print(file)
                    }
                } label: {
                    Text("Get File")
                }
                Button {
                    Task {
                        guard let id = id else { return }
                        let res = await model.saveFile(id: id, name: name, content: content, parentCommit: hash, branch: "main")
                        hash = res.hash
                        print(res)
                    }
                } label: {
                    Text("Save File")
                }
                Button {
                    Task {
                        guard let id = id else { return }
                        let res = await model.previewFile(id: id, atVersion: hash)
                        print(res)
                    }
                } label: {
                    Text("Preview File")
                }
                Button {
                    Task {
                        guard let id = id else { return }
                        let res = await model.getPreview(id: id, atVersion: hash)
                        print(res)
                    }
                } label: {
                    Text("Get Preview")
                }
                Button {
                    Task {
                        guard let id = id else { return }
                        let res = await model.getHistory(id: id)
                        print(res)
                    }
                } label: {
                    Text("Get History")
                }
                Button {
                    Task {
                        guard let id = id else { return }
                        let res = await model.deleteFile(id: id)
                        print("ok")
                    }
                } label: {
                    Text("Delete File")
                }
            }
        }
    }
}
