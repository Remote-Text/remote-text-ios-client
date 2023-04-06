//
//  Structs.swift
//  Remote Text
//
//  Created by Sima Nerush on 4/6/23.
//

import Foundation

struct File: Identifiable {
  let name: String
  let id: UUID
  let content: String
}

struct FileSummary: Identifiable, Codable {
  let name: String
  let id: UUID
  let editedTime: String
  let createdTime: String
}

struct GitCommit {
  let hash: String
  let parent: String?
}

struct CompilationOutput {
  let log: String
  let state: CompilationState
}

struct PreviewDetail {
  let id: UUID
  let name: String
  let data: String
  let type: PreviewDetailType
}

struct GitRef {
  let name: String
  let hash: String
}

struct GitHistory {
  let commits: [GitCommit]
  let refs: [GitRef]
}

enum CompilationState {
  case SUCCESS
  case FAILURE
}

enum PreviewDetailType {
  case PDF
  case HTML
}

// MARK: - Needed for inputs to fetch requests
struct FileNameAndOptionalContent: Codable {
  let name: String
  let content: String?
}

struct FileIDAndGitHash {
  let id: UUID
  let hash: String
}

struct FileAndHashAndBranchName {
  let name: String
  let id: UUID
  let content: String
  let parent: String
  let branch: String
}

struct IdOnly {
  let id: UUID
}
