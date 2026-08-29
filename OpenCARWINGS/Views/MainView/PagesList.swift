//
//  PagesList.swift
//  OpenCARWINGS
//
//  Created by Ruben Mkrtumyan on 29.4.2025.
//

import SwiftUI

struct PagesList: View {
    @Binding var pages: [HomeItemData]
    @Binding var outside: Bool
    var body: some View {
        VStack(spacing: 0) {
            ForEach(pages, id: \.text) { page in
                if #available(iOS 26.0, *) {
                    HomeItem(homeitemData: page, ctxOut: $outside).glassEffect().padding(8).padding([.horizontal], 8)
                } else {
                    // Fallback on earlier versions
                    HomeItem(homeitemData: page, ctxOut: $outside).padding([.horizontal], 8)
                }
            }
        }
    }
}

#Preview {
    PagesList(pages: .constant([HomeItemData(icon: "info.fill", text: "DEMO", subText: .constant("demo1"), destination: EmptyView())]), outside: .constant(false))
}
