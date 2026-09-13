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
    
    @State private var isPulsing = false
    @State private var animationToken = UUID()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        VStack {
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
                                .fill(Color.white.opacity(isPulsing ? 0.85 : 0.0))
                                .frame(maxWidth: .infinity, minHeight: 20, maxHeight: 32)
                                .border(Color.black, width: 0.8)
                                .cornerRadius(4)
                                .id(animationToken)
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
        .onAppear {
            updateAnimation()
        }
        .onChange(of: isCharging) { _, _ in
            updateAnimation()
        }
        .onChange(of: isQuickCharging) { _, _ in
            updateAnimation()
        }
        .onChange(of: targetSegmentIndex) { _, _ in
            updateAnimation()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                restartAnimation()
            }
        }
    }
    
    private func updateAnimation() {
        if isCharging {
            restartAnimation()
        } else {
            stopAnimation()
        }
    }
    
    private func restartAnimation() {
            isPulsing = false
            animationToken = UUID()
            guard isCharging else { return }
            
            let duration = isQuickCharging ? 0.3 : 0.5
            DispatchQueue.main.async {
                withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            }
        }
    
    private func stopAnimation() {
        withAnimation(.easeInOut(duration: 0.2)) {
            isPulsing = false
        }
    }
    
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
