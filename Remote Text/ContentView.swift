//
//  ContentView.swift
//  Remote Text
//
//  Created by Sima Nerush on 4/6/23.
//

import SwiftUI
import SFSafeSymbols

struct ContentView: View {
    @AppStorage("api_url") var serverURL: String = ""
    
    @ObservedObject var model: FileModel
    @State var files: [FileSummary] = []
    
    @State private var isLoading = false
    
    let timer = Timer.publish(every: 15, on: .main, in: .common).autoconnect()
    
    @State var unreachable = false
    
    @State private var taskId: UUID = .init()
    
    public enum Navigation: Hashable {
//        case listFiles
        case fileEditor(file: FileSummary)
        case fileCreator
        case previewFile(id: UUID, hash: String, filename: String)
    }
    
    var body: some View {
        if serverURL == "" {
            VStack {
                Spacer()
                Text("Please go to Settings to set the root API URL:").font(.title).multilineTextAlignment(.center)
                Button {
                    UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                } label: {
                    Text("Open Settings")
                }
                Spacer()
                Text("It will probably be of the form:").font(.caption)
                Text("http://blinky.wholphin-wyvern.ts.net:3030/api").monospaced()
                Spacer()
            }.padding()
        } else {
            normalUsage
        }
    }
    
    var normalUsage: some View {
        NavigationStack(path: $model.path) {
            FileListView(files: self.$files)
                .navigationDestination(for: Navigation.self) { nav in
                    switch nav {
//                    case .listFiles
                    case .fileEditor(let file):
                        FileDetailView(file)
                    case .fileCreator:
                        CreateFileView()
                    case let .previewFile(id, hash, filename):
                        PreviewView(id, hash, filename)
                    }
                }
        }
        .environment(\.refresh, { self.taskId = .init() })
        .environment(\.isLoading, self.isLoading)
        .environment(\.unreachable, self.unreachable)
        .environmentObject(model)
        .onReceive(timer) { input in
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
                case URLError.notConnectedToInternet:
                    withAnimation {
                        //i.e., internet is off
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

struct RefreshKey: EnvironmentKey {
    static let defaultValue: () -> Void = {}
}
struct IsLoadingKey: EnvironmentKey {
    static let defaultValue: Bool = false
}
struct UnreachableKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

extension EnvironmentValues {
    var refresh: () -> Void {
        get { self[RefreshKey.self] }
        set { self[RefreshKey.self] = newValue }
    }
    var isLoading: Bool {
        get { self[IsLoadingKey.self] }
        set { self[IsLoadingKey.self] = newValue }
    }
    var unreachable: Bool {
        get { self[UnreachableKey.self] }
        set { self[UnreachableKey.self] = newValue }
    }
}
