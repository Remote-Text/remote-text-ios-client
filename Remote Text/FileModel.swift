//
//  FileModel.swift
//  Remote Text
//
//  Created by Sima Nerush on 4/6/23.
//

import Foundation

class FileModel: ObservableObject {
  
  func fetchDocuments() async {
    guard let url = URL(string: "http://134.10.131.233:3030/api/listFiles") else { fatalError("Missing URL") }
           let urlRequest = URLRequest(url: url)
           let (data, _) = try! await URLSession.shared.data(for: urlRequest)
    
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    
    let files = try! decoder.decode(Array<FileSummary>.self, from: data)
    
    print(files)
  }
}
