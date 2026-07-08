//
//  SteamAnimationView.swift
//  ForgetMedNot
//
//  Created by Grace Haataja on 7/7/26.
//

import SwiftUI

/// Draws a wavy vertical ribbon where the wave pattern continuously
/// travels upward along the ribbon, creating a "rolling" motion.
struct SteamPath: Shape {
    var timelineProgress: CGFloat
    let amplitude: CGFloat
    let height: CGFloat
    let waveFrequency: CGFloat

    var animatableData: CGFloat {
        get { timelineProgress }
        set { timelineProgress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let midX = rect.midX
        let steps = 60
        let visibleHeight = height

        for i in 0...steps {
            let t = CGFloat(i) / CGFloat(steps) // 0 at base, 1 at the top
            let y = rect.maxY - (t * visibleHeight)

            // Sync the traveling wave phase tightly to our moving timeline progress
            let wavePhase = timelineProgress * .pi * 4.0
            
            // Steam expands outward dramatically as it rises up into cooler air
            let curlGrowth = 0.2 + pow(t, 1.4) * 2.0
            
            // Subtracting wavePhase makes the crests visibly climb upwards
            let x = midX + sin((t * waveFrequency) - wavePhase) * amplitude * curlGrowth

            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        return path
    }
}

struct SteamRibbon: View {
    let delay: Double
    let baseXOffset: CGFloat
    let cycleDuration: Double
    let amplitude: CGFloat
    let waveFrequency: CGFloat
    
    // Driven directly from the external clock time input parameter
    let time: TimeInterval

    private let ribbonHeight: CGFloat = 110
    private let lineWidth: CGFloat = 4.0

    var body: some View {
        let adjustedTime = max(0, time - delay)
        
        // Loop the progression factor smoothly from 0.0 -> 1.0 continuously
        let progress = CGFloat((adjustedTime / cycleDuration).truncatingRemainder(dividingBy: 1.0))
        
        ZStack {
            // Tight structural vapor center glow (Opacity is now constant)
            SteamPath(
                timelineProgress: progress,
                amplitude: amplitude,
                height: ribbonHeight,
                waveFrequency: waveFrequency
            )
            .stroke(
                Color(red: 1.0, green: 0.98, blue: 0.93).opacity(0.35),
                style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
            )
            .blur(radius: 2.5)
            
            // Diffused atmospheric veil expanding wider out (Opacity is now constant)
            SteamPath(
                timelineProgress: progress,
                amplitude: amplitude + 2,
                height: ribbonHeight,
                waveFrequency: waveFrequency * 0.85
            )
            .stroke(
                Color(red: 1.0, green: 0.97, blue: 0.95).opacity(0.18),
                style: StrokeStyle(lineWidth: lineWidth * 2.2, lineCap: .round, lineJoin: .round)
            )
            .blur(radius: 7.0)
        }
        .offset(x: baseXOffset)
        .frame(width: amplitude * 5 + lineWidth * 2, height: ribbonHeight)
    }
}

struct SteamAnimationView: View {
    let mugCenterX: CGFloat
    let mugCenterY: CGFloat
    
    private let containerHeight: CGFloat = 110

    var body: some View {
        TimelineView(.animation) { context in
            let time = context.date.timeIntervalSince1970
            
            ZStack {
                // Leftward ribbon
                SteamRibbon(delay: 0.0, baseXOffset: -6, cycleDuration: 3.4, amplitude: 5, waveFrequency: .pi * 2.2, time: 0.5*time)
                
                // Rightward staggered ribbon
                SteamRibbon(delay: 1.6, baseXOffset: 6, cycleDuration: 2.9, amplitude: 4, waveFrequency: .pi * 2.8, time: 0.5*time)
            }
            .frame(height: containerHeight)
            // PERSISTENCE IMPROVEMENT: A static mask fades the edges out, allowing the rising lines inside to flow infinitely
            .mask(
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: .clear, location: 0.0),       // Soft fade right at the mug rim
                        .init(color: .black, location: 0.15),      // Solid stream quickly achieved
                        .init(color: .black, location: 0.70),      // Remains fully solid through the air
                        .init(color: .clear, location: 1.0)        // Evaporates completely into nothingness at the top
                    ]),
                    startPoint: .bottom,
                    endPoint: .top
                )
            )
            .position(x: mugCenterX, y: mugCenterY)
        }
    }
}
