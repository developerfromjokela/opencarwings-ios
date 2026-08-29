//
//  CarRendering.swift
//  OpenCARWINGS
//
//  Created by Ruben Mkrtumyan on 30.4.2025.
//

import SwiftUI
import RestAPI

struct CarRendering: View {
    @Binding var car: Car?
    @State private var currentImageIndex = 0
    private let images = ["tire_f1", "tire_f2", "tire_f3", "tire_f4"]
    private let imagesEnv200 = ["car_env200_f1", "car_env200_f2", "car_env200_f3", "car_env200_f4"]
    private let imagesZE1 = ["l2_t_4", "l2_t_3", "l2_t_2", "l2_t_1"]
    private let timer = Timer.publish(every: 0.07, on: .main, in: .common).autoconnect()
    var body: some View {
        ZStack {
            Image(car?.color?.rawValue ?? "l_superblack") // Replace with actual car image
                .resizable()
                .scaledToFit()
                .frame(height: 140)
                .padding(.vertical)
            if (car?.color?.rawValue.starts(with: "l2_") == true) {
                if car?.evInfo.isCarRunning == true {
                    Image("l2_hd") // Replace with actual car image
                        .resizable()
                        .scaledToFit()
                        .frame(height: 140)
                }
                if car?.evInfo.carGear != 0 {
                    Image(imagesZE1[currentImageIndex]) // Replace with actual car image
                        .resizable()
                        .scaledToFit()
                        .frame(height: 140)
                }
                if car?.evInfo.isPluggedIn == true || car?.evInfo.isCharging == true {
                    Image("l2_cp") // Replace with actual car image
                        .resizable()
                        .scaledToFit()
                        .frame(height: 140)
                    if car?.evInfo.isQuickCharging == true {
                        Image("l2_q_chg") // Replace with actual car image
                            .resizable()
                            .scaledToFit()
                            .frame(height: 140)
                    } else if car?.evInfo.isCharging == true {
                        Image("l2_chg") // Replace with actual car image
                            .resizable()
                            .scaledToFit()
                            .frame(height: 140)
                    } else if (car?.evInfo.isPluggedIn == true) {
                        Image("l2_cw") // Replace with actual car image
                            .resizable()
                            .scaledToFit()
                            .frame(height: 140)
                    }
                }
            } else {
                if car?.evInfo.isCarRunning == true {
                    Image("leaf_hd") // Replace with actual car image
                        .resizable()
                        .scaledToFit()
                        .frame(height: 140)
                }
                if car?.evInfo.carGear != 0 {
                    Image(car?.color?.rawValue.contains("env200") == true ? imagesEnv200[currentImageIndex] : images[currentImageIndex]) // Replace with actual car image
                        .resizable()
                        .scaledToFit()
                        .frame(height: 140)
                }
                if car?.evInfo.isPluggedIn == true || car?.evInfo.isCharging == true {
                    Image("leaf_cp") // Replace with actual car image
                        .resizable()
                        .scaledToFit()
                        .frame(height: 140)
                    if car?.evInfo.isQuickCharging == true {
                        Image("leaf_dc_chg") // Replace with actual car image
                            .resizable()
                            .scaledToFit()
                            .frame(height: 140)
                    } else if car?.evInfo.isCharging == true {
                        Image("leaf_ac_chg") // Replace with actual car image
                            .resizable()
                            .scaledToFit()
                            .frame(height: 140)
                    } else if (car?.evInfo.isPluggedIn == true) {
                        Image("leaf_ac_plg") // Replace with actual car image
                            .resizable()
                            .scaledToFit()
                            .frame(height: 140)
                    }
                }
            }
        }
        .padding(.vertical)
        .foregroundColor(.cyan)
        .onReceive(timer) { _ in
            currentImageIndex = (currentImageIndex + 1) % images.count
        }
    }
}

#Preview {
    CarRendering(car: .constant(nil))
}
