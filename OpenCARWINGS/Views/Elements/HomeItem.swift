//
//  HomeItem.swift
//  OpenCARWINGS
//
//  Created by Ruben Mkrtumyan on 29.4.2025.
//


import SwiftUI

struct HomeItemData {
    let icon: String
    let text: String
    @Binding var subText: String?
    let destination: any View
}

struct HomeItem: View {
    var homeitemData: HomeItemData
    @Binding var ctxOut: Bool
    @State private var isActive = false
    var body: some View {
        NavigationLink(destination: AnyView(homeitemData.destination), isActive: $isActive) {
            HStack(alignment: .center) {
                Image(systemName: homeitemData.icon).resizable().scaledToFit().frame(width: 20).padding(.trailing, 8)
                VStack(alignment: .leading) {
                    Text(LocalizedStringKey(homeitemData.text)).font(.system(size: 18))
                    if homeitemData.subText != nil {
                        Text(LocalizedStringKey(homeitemData.subText!))
                            .font(.caption).multilineTextAlignment(.leading)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
            }.frame(alignment: .center)
            .padding(12).padding(.horizontal, 10)
        }.buttonStyle(.plain).foregroundColor(.primary).onChange(of: isActive) { value in
            ctxOut = value
        }
    }
}
