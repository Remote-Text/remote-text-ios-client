//
//  ServerUnreachable.swift
//  Remote Text
//
//  Created by Sam Gauck on 5/2/23.
//

import Foundation
import SwiftUI

extension View {
    func unreachable(_ unreachable: Bool) -> some View {
        if unreachable {
            return AnyView(ZStack {
                self
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text("Server Unreachable")
                            .font(.body.lowercaseSmallCaps())
                            .padding()
                            .background(.red)
                            .cornerRadius(5)
                            .transition(.asymmetric(insertion: .push(from: .bottom), removal: .scale))
                        Spacer()
                    }
                }
            })
        } else {
            return AnyView(self)
        }
    }
}
