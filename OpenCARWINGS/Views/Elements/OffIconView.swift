//
//  OffIconView.swift
//  OpenCARWINGS
//
//  Created by Ruben Mkrtumyan on 29.4.2025.
//

import Foundation
import SwiftUI

struct OffIconView: View {
    let imageName: String
    let size: CGFloat

    var body: some View {
        ZStack {
            // The base image
            Image(systemName: imageName)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .foregroundColor(.gray)

            Path { path in
                path.move(to: CGPoint(x: 0, y: size))
                path.addLine(to: CGPoint(x: size, y: 0))
            }
            .stroke(lineWidth: 2)
            .frame(width: size, height: size)
        }
    }
}
