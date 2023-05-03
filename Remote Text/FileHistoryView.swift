//
//  FileHistoryView.swift
//  Remote Text
//
//  Created by Sam Gauck on 5/2/23.
//

import SwiftUI

struct FileHistoryView: View {
    @EnvironmentObject var model: FileModel
    
    @State private var tree: Tree<(hash: String, branches: [String])>? = nil
    
    private let id: UUID
    
    init(_ id: UUID) {
        self.id = id
    }
    
    var body: some View {
        if let root = tree {
            ScrollView([.horizontal, .vertical]) {
                TreeView(root: root)
                    .environment(\.fileID, self.id)
            }
            .padding()
        } else {
            ProgressView()
                .onAppear {
                    Task {
                        let res = await model.getHistory(id: id)
                        var dict = [String?: [String]]()
                        for commit in res.commits {
                            dict[commit.parent, default: []].append(commit.hash)
                        }
                        func tree(for hash: String) -> Tree<(hash: String, branches: [String])> {
                            let branches = res.refs.filter { $0.hash == hash }.map { $0.name }
                            let children = dict[hash, default: []].map(tree(for:))
                            return Tree((hash, branches), children: children)
                        }
                        self.tree = tree(for: dict[nil]!.first!)
                    }
                }
        }
    }
}

struct FileIDKey: EnvironmentKey {
    static let defaultValue: UUID = .init()
}

extension EnvironmentValues {
    var fileID: UUID {
        get { self[FileIDKey.self] }
        set { self[FileIDKey.self] = newValue }
    }
}

struct TreeView: View {
    let root: Tree<(hash: String, branches: [String])>
    
    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            NodeView(node: root)
            if !root.children.isEmpty {
                Rectangle()
                    .fill(Color.blue)
                    .frame(width: 0.5, height: 20)
                HStack(alignment: .top, spacing: 5) {
                    ForEach(root.children, id: \.id) { child in
                        TreeView(root: child)
                            .anchorPreference(key: TopPreferenceKey.self, value: .top) { anchor in
                                let id = root.id
                                return [TopPreference(id: id, top: anchor)]
                            }
                    }
                }
                .backgroundPreferenceValue(TopPreferenceKey.self) { (tops: [TopPreference]) in
                    GeometryReader { geo in
                        ForEach(tops.indices, id: \.self) { index in
                            if index < tops.count - 1 {
                                Line(from: geo[tops[index].top], to: geo[tops[index + 1].top]).stroke(lineWidth: 0.5).foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
        }
        .drawingGroup()
    }
}

struct NodeView: View {
    @EnvironmentObject var model: FileModel
    @Environment(\.fileID) var fileID
    let node: Tree<(hash: String, branches: [String])>
    
    var body: some View {
        VStack {
            Text(node.value.hash.dropLast(33))
                .font(.body.monospaced())
            Text(node.value.branches.joined(separator: ", "))
                .font(.caption2.italic())
        }
        .padding()
        .overlay(alignment: .center) {
            ZStack {
                RoundedRectangle(cornerRadius: 5)
                    .fill(Color.blue)
                VStack {
                    Text(node.value.hash.dropLast(33))
                        .font(.body.monospaced())
                    Text(node.value.branches.joined(separator: ", "))
                        .font(.caption2.italic())
                }
            }
        }
//        Text(node.value.hash.dropLast(33))
//            .font(.body.monospaced())
//            .padding()
//            .overlay(alignment: .center) {
//                ZStack {
//                    RoundedRectangle(cornerRadius: 5)
//                        .fill(Color.blue)
//                    Text(node.value.hash.dropLast(33))
//                        .font(.body.monospaced())
//                        .foregroundColor(.white)
//                }
//            }
//        }
        .onTapGesture {
            print("tap on \(node.value.hash)")
            self.model.path.append(.fileEditor(id: fileID, hash: node.value.hash, branches: node.value.branches))
//            self.model.path.append(.previewFile(id: fileID, hash: node.value.hash, filename: "test"))
////            withAnimation {
////                let child = Node(context: viewContext)
////                child.id = UUID()
////                child.name = "\(Int.random(in: 1...9))"
////                child.parent = node
////                try? viewContext.save()
////            }
        }
//        .contextMenu(ContextMenu(menuItems: {
//            Button(action: {
//                viewContext.delete(node)
//                try? viewContext.save()
//            }, label: {
//                Label("Delete", systemImage: "trash")
//            })
//        }))
    }
}

struct Line: Shape {
    var from: CGPoint
    var to: CGPoint
    var animatableData: AnimatablePair<CGPoint.AnimatableData, CGPoint.AnimatableData> {
        get { AnimatablePair(from.animatableData, to.animatableData) }
        set {
            from.animatableData = newValue.first
            to.animatableData = newValue.second
        }
    }

    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: from)
            p.addLine(to: to)
        }
    }
}

struct TopPreference {
    let id: UUID
    let top: Anchor<CGPoint>
}

struct TopPreferenceKey: PreferenceKey {
    typealias Value = [TopPreference]
    
    static var defaultValue: Value = []
    
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value.append(contentsOf: nextValue())
    }
}

struct Tree<A> {
    let value: A
    let children: [Tree<A>]
    
    init(_ value: A, children: [Tree<A>] = []) {
        self.value = value
        self.children = children
    }
    
    let id: UUID = .init()
}
