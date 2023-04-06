//
//  ContentView.swift
//  Remote Text
//
//  Created by Sima Nerush on 4/6/23.
//

import SwiftUI

struct ContentView: View {
    @Binding var document: Remote_TextDocument

    var body: some View {
        TextEditor(text: $document.text)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(document: .constant(Remote_TextDocument()))
    }
}
