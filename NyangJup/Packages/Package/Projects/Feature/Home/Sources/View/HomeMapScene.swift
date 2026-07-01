//
//  SwiftUIView.swift
//  NJPackage
//
//  Created by 정지훈 on 7/1/26.
//

import SwiftUI
import SpriteKit
import SharedDesign

final class HomeMapScene: SKScene {
    override func didMove(to view: SKView) {
        view.allowsTransparency = true
        backgroundColor = .clear
        scaleMode = .resizeFill
        
        addMapBackground()
        addCats()
    }
    
    override func update(_ currentTime: TimeInterval) {
        for node in children where node.name == "cat" {
            node.zPosition = 1000 - node.position.y
        }
    }
    
    private func addMapBackground() {
        let texture = SKTexture(image: NJImage.map.uiImage)
        texture.filteringMode = .nearest
        
        let map = SKSpriteNode(texture: texture)
        map.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        map.position = CGPoint(x: size.width / 2, y: size.height / 2)
        map.zPosition = 0
        
        let scale = max(
            size.width / map.size.width,
            size.height / map.size.height
        )
        map.setScale(scale)
        
        addChild(map)
    }
    
    private func addCats() {
        for index in 0..<3 {
            let texture = SKTexture(image: NJImage.cherryBlossomTree.uiImage)
            texture.filteringMode = .nearest
            
            let cat = SKSpriteNode(texture: texture)
            cat.name = "cat"
            cat.size = CGSize(width: 48, height: 48)
            cat.position = CGPoint(
                x: size.width / 2 + CGFloat(index * 40),
                y: size.height / 2
            )
            cat.zPosition = 10
            
            addChild(cat)
            moveRandomly(cat)
        }
    }
    
    private func moveRandomly(_ cat: SKSpriteNode) {
        let wait = SKAction.wait(forDuration: .random(in: 0.5...1.5))
        
        let chooseMove = SKAction.run { [weak self, weak cat] in
            guard let self, let cat else { return }
            
            let target = CGPoint(
                x: CGFloat.random(in: 40...(self.size.width - 40)),
                y: CGFloat.random(in: 80...(self.size.height - 80))
            )
            
            cat.xScale = target.x < cat.position.x ? -1 : 1
            
            let move = SKAction.move(
                to: target,
                duration: .random(in: 2.0...4.0)
            )
            
            cat.run(move)
        }
        
        cat.run(.repeatForever(.sequence([wait, chooseMove])))
    }
}
