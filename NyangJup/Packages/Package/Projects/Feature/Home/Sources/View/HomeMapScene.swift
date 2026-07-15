//
//  HomeMapScene.swift
//  NJPackage
//
//  Created by 정지훈 on 7/1/26.
//

import SpriteKit

import DomainCatsInterface
import SharedDesign

final class HomeMapScene: SKScene {
    typealias CatID = String
    typealias CatPosition = CGPoint

    var cats: [Cat]
    private weak var selectedCatNode: SKNode?

    var onCatTapped: (CatID, CatPosition) -> Void
    var onSelectionCleared: () -> Void

    // MARK: - Init

    init(
        size: CGSize,
        cats: [Cat],
        onCatTapped: @escaping (CatID, CatPosition) -> Void,
        onSelectionCleared: @escaping () -> Void,
    ) {
        self.cats = cats
        self.onCatTapped = onCatTapped
        self.onSelectionCleared = onSelectionCleared

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

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }

        let location = touch.location(in: self)
        let touchedNodes = nodes(at: location)

        guard let catNode = touchedNodes.compactMap({
            findCatNode(from: $0)
        }).first else {
            deselectCat()
            return
        }

        selectCat(catNode)
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
        cats.forEach { cat in
            guard let appearance = CatAppearance(rawValue: cat.appearanceKey) else { return }

            let texture = SKTexture(image: appearance.imageAsset.uiImage)
            texture.filteringMode = .nearest
            addCat(texture: texture, cat: cat)
        }
    }

    private func addCat(texture: SKTexture, cat: Cat) {
        let node = SKNode()
        node.name = Constant.catNodeName
        node.userData = [Constant.catIDKey: cat.id]
        node.position = CGPoint(
            x: size.width / 2 + CGFloat(Int.random(in: Constant.initialXOffsetRange)),
            y: size.height / 2
        )
        node.zPosition = Constant.catDefaultZPosition

        let sprite = SKSpriteNode(texture: texture)
        sprite.size = Constant.catSize
        node.addChild(sprite)

        addNameTag(cat.name, to: node)

        addChild(node)
        moveRandomly(node, sprite: sprite)
    }

    private func addNameTag(_ name: String, to cat: SKNode) {

        let label = SKLabelNode(fontNamed: Constant.nameTagFontName)
        label.text = name
        label.fontSize = Constant.nameTagFontSize
        label.fontColor = .white
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center

        let nameTagSize = CGSize(
            width: max(
                label.frame.width + Constant.nameTagHorizontalPadding * 2,
                Constant.nameTagMinimumWidth
            ),
            height: Constant.nameTagHeight
        )
        let nameTagPosition = CGPoint(
            x: 0,
            y: -(Constant.catSize.height / 2 + Constant.nameTagSpacing + Constant.nameTagHeight / 2)
        )

        let background = SKShapeNode(rectOf: nameTagSize)
        background.fillColor = .black
        background.strokeColor = .clear
        background.position = nameTagPosition

        label.position = nameTagPosition
        label.zPosition = 1

        cat.addChild(background)
        cat.addChild(label)
    }

    private func moveRandomly(_ cat: SKNode, sprite: SKSpriteNode) {
        let wait = SKAction.wait(forDuration: .random(in: Constant.waitDurationRange))

        let chooseMove = SKAction.run { [weak self, weak cat, weak sprite] in
            guard let self, let cat, let sprite else { return }

            let target = CGPoint(
                x: CGFloat.random(in: Constant.horizontalMoveInset...(self.size.width - Constant.horizontalMoveInset)),
                y: CGFloat.random(in: Constant.verticalMoveInset...(self.size.height - Constant.verticalMoveInset))
            )

            sprite.xScale = target.x < cat.position.x ? -1 : 1

            let move = SKAction.move(
                to: target,
                duration: .random(in: Constant.moveDurationRange)
            )

            cat.run(move)
        }

        cat.run(.repeatForever(.sequence([wait, chooseMove])))
    }

    private func findCatNode(from node: SKNode) -> SKNode? {
        var currentNode: SKNode? = node

        while let node = currentNode {
            if node.name == Constant.catNodeName {
                return node
            }

            currentNode = node.parent
        }

        return nil
    }

    private func selectCat(_ catNode: SKNode) {
        guard let catID = catNode.userData?[Constant.catIDKey] as? String else {
            return
        }

        deselectCat()
        onSelectionCleared()

        if selectedCatNode === catNode { return }

        selectedCatNode = catNode
        catNode.isPaused = true

        let position = speechBubblePosition(for: catNode)
        onCatTapped(catID, position)
    }

    private func speechBubblePosition(for catNode: SKNode) -> CGPoint {
        let bubbleHalfWidth = Constant.speechBubbleSize.width / 2
        let minimumBubbleCenterX = bubbleHalfWidth
            + Constant.speechBubbleEdgeInset
        let maximumBubbleCenterX = size.width
            - bubbleHalfWidth
            - Constant.speechBubbleEdgeInset
        let bubblePositionX = min(
            max(catNode.position.x, minimumBubbleCenterX),
            maximumBubbleCenterX
        )

        let catPositionY = size.height - catNode.position.y
        let bubbleOffset = Constant.catSize.height / 2
            + Constant.speechBubbleSpacing
            + Constant.speechBubbleSize.height / 2
        let positionAboveCat = catPositionY - bubbleOffset
        let minimumBubbleCenterY = Constant.speechBubbleSize.height / 2
            + Constant.speechBubbleEdgeInset

        if positionAboveCat >= minimumBubbleCenterY {
            return CGPoint(
                x: bubblePositionX,
                y: positionAboveCat
            )
        }

        let positionBelowCat = catPositionY
            + Constant.catSize.height / 2
            + Constant.nameTagSpacing
            + Constant.nameTagHeight
            + Constant.speechBubbleSpacing
            + Constant.speechBubbleSize.height / 2
            + 20

        return CGPoint(
            x: bubblePositionX,
            y: positionBelowCat
        )
    }

    private func deselectCat() {
        guard let selectedCatNode else {
            return
        }
        selectedCatNode.isPaused = false
        self.selectedCatNode = nil
        onSelectionCleared()
    }
}

// MARK: - Constant

private extension HomeMapScene {
    enum Constant {
        static let catNodeName = "cat"
        static let catSize = CGSize(width: 48, height: 48)
        static let catDefaultZPosition: CGFloat = 10
        static let catZPositionBase: CGFloat = 1000

        static let catIDKey: String = "catID"

        static let nameTagFontName: String = "HelveticaNeue-Bold"
        static let nameTagFontSize: CGFloat = 10
        static let nameTagHeight: CGFloat = 16
        static let nameTagMinimumWidth: CGFloat = 24
        static let nameTagHorizontalPadding: CGFloat = 4
        static let nameTagSpacing: CGFloat = 2

        static let speechBubbleSize = CGSize(width: 250, height: 112)
        static let speechBubbleSpacing: CGFloat = 8
        static let speechBubbleEdgeInset: CGFloat = 16

        static let mapAnchorPoint = CGPoint(x: 0.5, y: 0.5)
        static let mapZPosition: CGFloat = 0

        static let initialXOffsetRange: ClosedRange<Int> = 1...20
        static let horizontalMoveInset: CGFloat = 40
        static let verticalMoveInset: CGFloat = 80

        static let waitDurationRange: ClosedRange<TimeInterval> = 0.5...1.5
        static let moveDurationRange: ClosedRange<TimeInterval> = 2.0...4.0
    }
}
