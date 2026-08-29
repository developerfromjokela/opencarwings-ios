//
//  LeafSegmentDisplay.swift
//  OpenCARWINGS
//
//  Created by Ruben Mkrtumyan on 29.4.2025.
//

import SwiftUI
import Foundation

struct LeafSegmentDisplay: View {
    let totalSegments: Int = 12
    var activeSegments: Int
    var isCharging: Bool
    var isQuickCharging: Bool
    
    @State private var pulseOpacity: Double = 0.0
    @State private var animationRunning = false


    var body: some View {
        VStack {
            // TODO bug in the pulse, after leaving the app and returning back, pulsing stops and it stays white
            // all the time
            
            // Segment display
            HStack(spacing: 4) {
                ForEach(0..<totalSegments, id: \.self) { index in
                    ZStack {
                        Rectangle()
                            .fill(segmentColor(for: index))
                            .frame(maxWidth: .infinity,minHeight: 20, maxHeight: 32)
                            .border(Color.black, width: 0.8)
                            .cornerRadius(4)
                        // Pulsing overlay for the target segment
                        if isCharging && index == targetSegmentIndex {
                            Rectangle()
                                .fill(Color.white.opacity(pulseOpacity))
                                .frame(maxWidth: .infinity, minHeight: 20, maxHeight: 32)
                                .border(Color.black, width: 0.8)
                                .cornerRadius(4)
                                .onChange(of: isQuickCharging) { _, _ in
                                    if isCharging && animationRunning {
                                        stopPulseAnimation()
                                        startPulseAnimation()
                                    }
                                }
                                .onAppear {
                                    if isCharging && !animationRunning {
                                        startPulseAnimation()
                                    }
                                }
                        }
                    }.onChange(of: isCharging) {_, _ in
                        if !isCharging && animationRunning {
                            stopPulseAnimation()
                        }
                    }
                
                }
            }

            // Labels
            HStack {
                Text("EMPTY")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("FULL")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func startPulseAnimation() {
        guard !animationRunning else {return}
        animationRunning = true
         let interval = isQuickCharging ? 0.2 : 0.5
         
         withAnimation(.easeInOut(duration: interval).repeatForever(autoreverses: true)) {
             pulseOpacity = 0.85
         }
     }
     
     // Stop the pulsing animation
     private func stopPulseAnimation() {
         animationRunning = false
         withAnimation(.easeInOut(duration: 0.2)) {
             pulseOpacity = 0.0
         }
     }
     
    
    // Determine the index of the segment to pulse
    private var targetSegmentIndex: Int {
        let totalFilled = activeSegments
        if totalFilled > 0 {
            // Last non-gray segment
            return totalFilled - 1
        } else {
            // First gray segment
            return 0
        }
    }

    // Determine the color of each segment based on its index
    private func segmentColor(for index: Int) -> Color {
        let totalFilled = activeSegments
        if index < 2 && index < totalFilled {
            return .red // Full segments
        } else if index < totalFilled {
            return .blue // Partially filled segments
        } else {
            return .gray // Empty segments
        }
    }
}

// Example usage and preview
struct LeafSegmentDisplay_Previews: PreviewProvider {
    static var previews: some View {
        LeafSegmentDisplay(activeSegments: 4, isCharging: true, isQuickCharging: true)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
