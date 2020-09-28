//
//  ContentView.swift
//  TreeDrawing
//
//  Created by Chris Eidhof on 14.09.20.
//  Copyright © 2020 objc.io. All rights reserved.
//

import SwiftUI

struct Point: Hashable {
    var x: Int
    var y: Int
    
    static let zero = Point(x: 0, y: 0)
}

final class Tree<A>: ObservableObject, Identifiable, CustomStringConvertible {
    init(_ value: A, point: Point = .zero, left: Tree<A>? = nil, right: Tree<A>? = nil) {
        self.value = value
        self.point = point
        self.left = left
        self.right = right
    }
    
    @Published var value: A
    @Published var point: Point = .zero
    @Published var left: Tree<A>? {
        didSet { left?.parent = self }
    }
    @Published var right: Tree<A>? {
        didSet { right?.parent = self }
    }
    weak var parent: Tree<A>? = nil
    
    var id: ObjectIdentifier {
        ObjectIdentifier(self)
    }
    
    var description: String {
        "Tree(\(value) \(point) \(left?.description ?? "") \(right?.description ?? ""))"
    }
    
    func relayout() {
        var root = self
        while let p = root.parent {
            root = p
        }
        root.layout()
    }
}

extension Tree {
    func modifyAll(_ transform: (Tree<A>) -> ()) {
        transform(self)
        left?.modifyAll(transform)
        right?.modifyAll(transform)
    }
    
    var allSubtrees: [Tree<A>] {
        return [self] + (left?.allSubtrees ?? []) + (right?.allSubtrees ?? [])
    }
    
    var allEdges: [(from: Tree<A>, to: Tree<A>)] {
        var result: [(from: Tree<A>, to: Tree<A>)] = []
        if let l = left {
            result.append((from: self, to: l))
            result.append(contentsOf: l.allEdges)
        }
        if let r = right {
            result.append((from: self, to: r))
            result.append(contentsOf: r.allEdges)
        }
        return result
    }
}

struct DrawTree<A, Node>: View where Node: View {
    @ObservedObject var tree: Tree<A>
    var spacing: CGFloat = 5
    let node: (Tree<A>) -> Node
    let nodeSize = CGSize(width: 50, height: 50)
    
    func cgPoint(for point: Point) -> CGPoint {
        CGPoint(x: CGFloat(point.x) * (nodeSize.width + spacing), y: CGFloat(point.y) * (nodeSize.height + spacing))
    }
    
    var body: some View {
        return ZStack(alignment: .topLeading) {
            ForEach(tree.allSubtrees) { (tree: Tree<A>) in
                self.node(tree)
                    .frame(width: self.nodeSize.width, height: self.nodeSize.height)
                    .alignmentGuide(.leading, computeValue: { _ in
                        -self.cgPoint(for: tree.point).x
                    })
                    .alignmentGuide(.top, computeValue: { _ in
                        -self.cgPoint(for: tree.point).y
                    })
            }
        }
        .background(
            ZStack {
                ForEach(tree.allEdges, id: \.to.id) { edge in
                    Line(from: self.cgPoint(for: edge.from.point), to: self.cgPoint(for: edge.to.point))
                        .stroke(Color.primary, lineWidth: 2)
                }
            }
            .offset(CGSize(width: nodeSize.width/2, height: nodeSize.height/2))
        )
    }
}

var counter = 0
func newNode() -> Tree<Int> {
    counter += 1
    return Tree(counter)
}

struct ContentView: View {
    var tree = newNode()
    var body: some View {
        return VStack {
            DrawTree(tree: tree, node: { Node(x: $0) })
                .animation(.default)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
}

extension Tree {
    func layout() {
        bottomUp(depth: 0)
    }
    
    func knuth(depth: Int, x: inout Int) {
        left?.knuth(depth: depth + 1, x: &x)
        point.x = x
        point.y = depth
        x += 1
        right?.knuth(depth: depth + 1, x: &x)
    }
    
    func alt(depth: Int, x: inout [Int:Int]) {
        left?.alt(depth: depth+1, x: &x)
        point.x = x[depth, default: 0]
        if let l = left {
            point.x = l.point.x + 1
        }
        point.y = depth
        x[depth, default: 0] = point.x + 1
        right?.alt(depth: depth+1, x: &x)
        right?.moveRight(1)
        for (d, v) in x {
            if d > depth {
                x[d] = v + 1
            }
        }
    }
    
    func bottomUp(depth: Int) {
        point.y = depth
        left?.bottomUp(depth: depth+1)
        right?.bottomUp(depth: depth + 1)
        
        if let l = left, let r = right {
            let lContour = l.contour(depth: 0, Swift.max)
            let rContour = r.contour(depth: 0, Swift.min)
            let overlap = lContour.merging(rContour, uniquingKeysWith: { $1 - $0 }).values.min()!
            if overlap < 1 {
                r.moveRight(abs(overlap)+1)
            }
            let offset = (r.point.x - l.point.x).isMultiple(of: 2) ? 0 : 1
            r.moveRight(offset)
            point.x = (offset + l.point.x + r.point.x) / 2
        } else if let l = left {
            point.x = l.point.x + 1
        } else if let r = right {
            point.x = r.point.x - 1
            if point.x < 0 {
                r.moveRight(abs(point.x))
                point.x = 0
            }
        } else {
            point.x = 0
        }
    }
    
    func contour(depth: Int, _ combineX: (Int, Int) -> Int) -> [Int:Int] {
        let l = left?.contour(depth: depth+1, combineX) ?? [:]
        let r = right?.contour(depth: depth+1, combineX) ?? [:]
        return [depth: point.x].merging(l.merging(r, uniquingKeysWith: combineX), uniquingKeysWith: combineX)
    }
    
    func moveRight(_ amount: Int) {
        modifyAll { $0.point.x += amount }
    }
}
    

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

