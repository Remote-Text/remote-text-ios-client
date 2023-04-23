//
//  Structs.swift
//  Remote Text
//
//  Created by Sima Nerush on 4/6/23.
//

import Foundation

struct File: Identifiable, Codable {
  let name: String
  let id: UUID
  let content: String
}

struct FileSummary: Identifiable, Codable {
  let name: String
  let id: UUID
  let editedTime: Date
  let createdTime: Date
}

struct GitCommit: Codable {
  let hash: String
  let parent: String?
}

struct CompilationOutput: Codable {
  let log: String
  let state: CompilationState
}

struct GitRef: Codable {
  let name: String
  let hash: String
}

struct GitHistory: Codable {
  let commits: [GitCommit]
  let refs: [GitRef]
}

enum CompilationState: String, Codable {
  case SUCCESS = "SUCCESS"
  case FAILURE = "FAILURE"
}

enum PreviewType {
  case PDF
  case HTML
}

// MARK: - Needed for inputs to fetch requests
struct FileNameAndOptionalContent: Codable {
  let name: String
  let content: String?
}

struct FileIDAndGitHash: Codable {
  let id: UUID
  let hash: String
}

struct FileAndHashAndBranchName: Codable {
  let name: String
  let id: UUID
  let content: String
  let parent: String
  let branch: String
}

struct IdOnly: Codable {
  let id: UUID
}
