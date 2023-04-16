//
//  FileModel.swift
//  Remote Text
//
//  Created by Sima Nerush on 4/6/23.
//

import Foundation

class FileModel: ObservableObject {
  
    static let shared = FileModel()
    
    private func request(to endpoint: String, with data: Codable?) throws -> URLRequest {
        let BASE_URL = "http://localhost:3030/api"
        guard let url = URL(string: "\(BASE_URL)/\(endpoint)") else {
            fatalError("Cannot construct URL for API call!")
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        if let data = data {
            let jsonData = try JSONEncoder().encode(data)
            
            urlRequest.httpBody = jsonData
            urlRequest.setValue("application/json", forHTTPHeaderField: "content-type")
        }
        
        return urlRequest
    }
    
    func listFiles() async throws -> [FileSummary] {
        let urlRequest = try request(to: "listFiles", with: nil)
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let response = response as? HTTPURLResponse else {
            fatalError("Response is not HTTPResponse")
        }
        switch response.statusCode {
        case 200:
            break
        default:
            fatalError("Got status code \(response.statusCode)")
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        
        let files = try decoder.decode([FileSummary].self, from: data)
        
        return files
    }
    
    @discardableResult
    func createFile(named name: String, withContent content: String) async -> FileSummary {
        let dataToEncode = FileNameAndOptionalContent(name: name, content: content)
        let urlRequest = try! request(to: "createFile", with: dataToEncode)
        let (data, response) = try! await URLSession.shared.data(for: urlRequest)
        
        guard let response = response as? HTTPURLResponse else {
            fatalError("Response is not HTTPResponse")
        }
        switch response.statusCode {
        case 200:
            break
        case 500:
            fatalError("Internal server error")
        default:
            fatalError("Got status code \(response.statusCode)")
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        
        let file = try! decoder.decode(FileSummary.self, from: data)
        
        return file
    }
    
    func getFile(id: UUID, atVersion hash: String) async -> File {
        let dataToEncode = FileIDAndGitHash(id: id, hash: hash)
        let urlRequest = try! request(to: "getFile", with: dataToEncode)
        let (data, response) = try! await URLSession.shared.data(for: urlRequest)
        
        guard let response = response as? HTTPURLResponse else {
            fatalError("Response is not HTTPResponse")
        }
        switch response.statusCode {
        case 200:
            break
        case 400:
            fatalError("Bad hash")
        case 404:
            fatalError("Bad UUID")
        case 500:
            fatalError("Internal server error")
        default:
            fatalError("Got status code \(response.statusCode)")
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        
        let file = try! decoder.decode(File.self, from: data)
        
        return file
    }
    
    @discardableResult
    func saveFile(id: UUID, name: String, content: String, parentCommit parent: String, branch: String) async -> GitCommit {
        let dataToEncode = FileAndHashAndBranchName(name: name, id: id, content: content, parent: parent, branch: branch)
        let urlRequest = try! request(to: "saveFile", with: dataToEncode)
        let (data, response) = try! await URLSession.shared.data(for: urlRequest)
        
        guard let response = response as? HTTPURLResponse else {
            fatalError("Response is not HTTPResponse")
        }
        switch response.statusCode {
        case 200:
            break
        case 400:
            fatalError("Bad hash")
        case 404:
            fatalError("Bad UUID")
        case 500:
            fatalError("Internal server error")
        default:
            fatalError("Got status code \(response.statusCode)")
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        
        let gitCommit = try! decoder.decode(GitCommit.self, from: data)
        
        return gitCommit
    }
    
    func previewFile(id: UUID, atVersion hash: String) async -> CompilationOutput {
        let dataToEncode = FileIDAndGitHash(id: id, hash: hash)
        let urlRequest = try! request(to: "previewFile", with: dataToEncode)
        let (data, response) = try! await URLSession.shared.data(for: urlRequest)
        
        guard let response = response as? HTTPURLResponse else {
            fatalError("Response is not HTTPResponse")
        }
        switch response.statusCode {
        case 200:
            break
        case 400:
            fatalError("Bad hash")
        case 404:
            fatalError("Bad UUID")
        case 500:
            fatalError("Internal server error")
        default:
            fatalError("Got status code \(response.statusCode)")
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        
        let output = try! decoder.decode(CompilationOutput.self, from: data)
        
        return output
    }
    
    func getPreview(id: UUID, atVersion hash: String) async -> Data {
        let dataToEncode = FileIDAndGitHash(id: id, hash: hash)
        let urlRequest = try! request(to: "getPreview", with: dataToEncode)
        let (data, response) = try! await URLSession.shared.data(for: urlRequest)
        
        guard let response = response as? HTTPURLResponse else {
            fatalError("Response is not HTTPResponse")
        }
        switch response.statusCode {
        case 200:
            break
        case 400:
            fatalError("Bad hash")
        case 404:
            fatalError("Bad UUID")
        case 500:
            fatalError("Internal server error")
        default:
            fatalError("Got status code \(response.statusCode)")
        }
        
        return data
    }
    
    func getHistory(id: UUID) async -> GitHistory {
        let dataToEncode = IdOnly(id: id)
        let urlRequest = try! request(to: "getHistory", with: dataToEncode)
        let (data, response) = try! await URLSession.shared.data(for: urlRequest)
        
        guard let response = response as? HTTPURLResponse else {
            fatalError("Response is not HTTPResponse")
        }
        switch response.statusCode {
        case 200:
            break
        case 404:
            fatalError("Bad UUID")
        case 500:
            fatalError("Internal server error")
        default:
            fatalError("Got status code \(response.statusCode)")
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        
        let gitHistory = try! decoder.decode(GitHistory.self, from: data)
        
        return gitHistory
    }
    
    func deleteFile(id: UUID) async {
        let dataToEncode = IdOnly(id: id)
        let urlRequest = try! request(to: "deleteFile", with: dataToEncode)
        let (_, response) = try! await URLSession.shared.data(for: urlRequest)
        
        guard let response = response as? HTTPURLResponse else {
            fatalError("Response is not HTTPResponse")
        }
        switch response.statusCode {
        case 200:
            break
        case 400:
            fatalError("Bad hash")
        case 404:
            fatalError("Bad UUID")
        case 500:
            fatalError("Internal server error")
        default:
            fatalError("Got status code \(response.statusCode)")
        }
        
//        let decoder = JSONDecoder()
//        decoder.keyDecodingStrategy = .convertFromSnakeCase
//        decoder.dateDecodingStrategy = .iso8601
//
//        let file = try! decoder.decode(File.self, from: data)
//
//        print(file)
    }
}
