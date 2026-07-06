//
//  SwiftUIView.swift
//  NJPackage
//
//  Created by 정지훈 on 7/1/26.
//

import SwiftUI
import SpriteKit

import DomainCatsInterface
import SharedDesign
import Kingfisher

final class HomeMapScene: SKScene {
    var cats: [Cat]

    // MARK: - Init

    init(
        size: CGSize,
        cats: [Cat]
    ) {
        self.cats = cats
        super.init(size: size)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Override

    override func didMove(to view: SKView) {
        view.allowsTransparency = true
        backgroundColor = .clear
        scaleMode = .resizeFill

        addMapBackground()
        addCats()
    }

    override func update(_ currentTime: TimeInterval) {
        for node in children where node.name == Constant.catNodeName {
            node.zPosition = Constant.catZPositionBase - node.position.y
        }
    }
}

// MARK: - Private Method

extension HomeMapScene {
    private func addMapBackground() {
        let texture = SKTexture(image: NJImage.map.uiImage)
        texture.filteringMode = .nearest

        let map = SKSpriteNode(texture: texture)
        map.anchorPoint = Constant.mapAnchorPoint
        map.position = CGPoint(x: size.width / 2, y: size.height / 2)
        map.zPosition = Constant.mapZPosition

        let scale = max(
            size.width / map.size.width,
            size.height / map.size.height
        )
        map.setScale(scale)

        addChild(map)
    }

    private func addCats() {
        cats.forEach {
            guard let url = URL(string: $0.imageURL) else { return }

            KingfisherManager.shared.retrieveImage(with: url) { [weak self] result in
                guard let self else { return }
                guard case let .success(value) = result else { return }

                let texture = SKTexture(image: value.image)
                texture.filteringMode = .nearest

                self.addCat(texture: texture)
            }
        }
    }

    private func addCat(texture: SKTexture) {
        let cat = SKSpriteNode(texture: texture)
        cat.name = Constant.catNodeName
        cat.size = Constant.catSize
        cat.position = CGPoint(
            x: size.width / 2 + CGFloat(Int.random(in: Constant.initialXOffsetRange)),
            y: size.height / 2
        )
        cat.zPosition = Constant.catDefaultZPosition

        addChild(cat)
        moveRandomly(cat)
    }

    private func moveRandomly(_ cat: SKSpriteNode) {
        let wait = SKAction.wait(forDuration: .random(in: Constant.waitDurationRange))

        let chooseMove = SKAction.run { [weak self, weak cat] in
            guard let self, let cat else { return }

            let target = CGPoint(
                x: CGFloat.random(in: Constant.horizontalMoveInset...(self.size.width - Constant.horizontalMoveInset)),
                y: CGFloat.random(in: Constant.verticalMoveInset...(self.size.height - Constant.verticalMoveInset))
            )

            cat.xScale = target.x < cat.position.x ? -1 : 1

            let move = SKAction.move(
                to: target,
                duration: .random(in: Constant.moveDurationRange)
            )

            cat.run(move)
        }

        cat.run(.repeatForever(.sequence([wait, chooseMove])))
    }
}

// MARK: - Constant

private extension HomeMapScene {
    enum Constant {
        static let catNodeName: String = "cat"
        static let catSize = CGSize(width: 48, height: 48)
        static let catDefaultZPosition: CGFloat = 10
        static let catZPositionBase: CGFloat = 1000

        static let mapAnchorPoint = CGPoint(x: 0.5, y: 0.5)
        static let mapZPosition: CGFloat = 0

        static let initialXOffsetRange: ClosedRange<Int> = 1...20
        static let horizontalMoveInset: CGFloat = 40
        static let verticalMoveInset: CGFloat = 80

        static let waitDurationRange: ClosedRange<TimeInterval> = 0.5...1.5
        static let moveDurationRange: ClosedRange<TimeInterval> = 2.0...4.0
    }
}
