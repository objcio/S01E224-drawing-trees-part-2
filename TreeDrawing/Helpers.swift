//
//  Helpers.swift
//  TreeDrawingRecording
//
//  Created by Chris Eidhof on 24.09.20.
//

import SwiftUI

struct Line: Shape {
    var from: CGPoint
    var to: CGPoint
    
    var animatableData: AnimatablePair<CGPoint.AnimatableData, CGPoint.AnimatableData> {
        get { return AnimatablePair(from.animatableData, to.animatableData) }
        set {
            from.animatableData = newValue.first
            to.animatableData = newValue.second
        }
    }
    
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: from)
            p.addLine(to: to)
        }
    }
}


struct CircleStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Font.footnote.bold())
            .frame(width: 16, height: 16)
            .background(
                Circle()
                    .fill(Color.red)
                    .overlay(Circle().fill(configuration.isPressed ? Color.white.opacity(0.5) : Color.clear))
            )
        
    }
}


struct Node: View {
    @ObservedObject var x: Tree<Int>
    
    var body: some View {
        return ZStack {
            Circle()
                .fill(Color(NSColor.windowBackgroundColor))
            Circle()
                .stroke(Color.primary, lineWidth: 2)
            Text("\(x.value)")
            VStack {
                Spacer()
                HStack {
                    Button(action: {
                        let hasLeft = self.x.left != nil
                        self.x.left = hasLeft ? nil : newNode()
                        self.x.relayout()
                    }, label: {
                        Text(x.left == nil ? "+" : "-")
                    })
                    Spacer()
                    Button(action: {
                        let hasRight = self.x.right != nil
                        self.x.right = hasRight ? nil : newNode()
                        self.x.relayout()
                    }, label: { Text(x.right == nil ? "+" : "-") })
                }.buttonStyle(CircleStyle())
            }
        }
    }
}
