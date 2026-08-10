//
//  HomeMapScene.swift
//  NJPackage
//
//  Created by 정지훈 on 7/1/26.
//

import SpriteKit

import CoreImageLoaderInterface
import DomainCatsInterface
import SharedDesign

final class HomeMapScene: SKScene {
    typealias CatID = String
    typealias CatPosition = CGPoint

    private var cats: [Cat]
    private weak var selectedCatNode: SKNode?

    private let imageLoaderClient: ImageLoaderClient
    private let displayScale: CGFloat

    private let onCatTapped: (CatID, CatPosition) -> Void
    private let onSelectionCleared: () -> Void

    // MARK: - Init

    init?(
        size: CGSize,
        cats: [Cat],
        imageLoaderClient: ImageLoaderClient,
        displayScale: CGFloat,
        onCatTapped: @escaping (CatID, CatPosition) -> Void,
        onSelectionCleared: @escaping () -> Void,
    ) {
        guard size.width >= Constant.horizontalMoveInset * 2,
              size.height >= Constant.bottomMoveInset + Constant.topMoveInset else {
            return nil
        }

        self.cats = cats
        self.imageLoaderClient = imageLoaderClient
        self.displayScale = displayScale
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

        if childNode(withName: Constant.mapNodeName) == nil {
            addMapBackground()
        }
        syncCats(cats)
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
            clearSelection()
            return
        }

        selectCat(catNode)
    }
}

// MARK: - Private Method

extension HomeMapScene {
    func clearSelection() {
        guard let selectedCatNode else {
            return
        }
        selectedCatNode.isPaused = false
        self.selectedCatNode = nil
        onSelectionCleared()
    }

    func syncCats(_ cats: [Cat]) {
        self.cats = cats
        let catIDs = Set(cats.map(\.id))
        let catNodes = children.filter { $0.name == Constant.catNodeName }

        let catsByID = Dictionary(uniqueKeysWithValues: cats.map { ($0.id, $0) })
        catNodes.forEach { node in
            guard let catID = node.userData?[Constant.catIDKey] as? String,
                  let cat = catsByID[catID] else {
                return
            }
            updateNameTag(cat.name, in: node)
        }

        catNodes
            .filter { node in
                guard let catID = node.userData?[Constant.catIDKey] as? String else {
                    return true
                }
                return !catIDs.contains(catID)
            }
            .forEach { node in
                if selectedCatNode === node {
                    clearSelection()
                }
                node.removeFromParent()
            }

        let existingCatIDs: Set<String> = Set(children.compactMap { node in
            guard node.name == Constant.catNodeName else { return nil }
            return node.userData?[Constant.catIDKey] as? String
        })

        cats
            .filter { !existingCatIDs.contains($0.id) }
            .forEach { cat in
                loadCat(cat)
            }
    }

    private func loadCat(_ cat: Cat) {
        guard let imageURL = URL(string: cat.imageURL) else { return }

        Task {
            guard let image = try? await imageLoaderClient.loadImage(
                imageURL,
                Constant.catSize,
                displayScale,
                [.memory, .disk, .network]
            ) else { return }

            let texture = SKTexture(image: image)
            texture.filteringMode = .nearest
            addCat(texture: texture, cat: cat)
        }
    }

    private func isValidContentSize(_ size: CGSize) -> Bool {
        size.width >= Constant.horizontalMoveInset * 2
            && size.height >= Constant.bottomMoveInset + Constant.topMoveInset
    }

    private func addMapBackground() {
        let texture = SKTexture(image: NJImage.map.uiImage)
        texture.filteringMode = .nearest

        let map = SKSpriteNode(texture: texture)
        map.name = Constant.mapNodeName
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

    private func addCat(texture: SKTexture, cat: Cat) {
        let node = SKNode()
        node.name = Constant.catNodeName
        node.userData = [Constant.catIDKey: cat.id]
        node.position = randomCatPosition()
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
        label.name = Constant.nameTagLabelNodeName
        label.text = name
        label.fontSize = Constant.nameTagFontSize
        label.fontColor = .white
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center

        let nameTagSize = nameTagSize(for: label)
        let nameTagPosition = CGPoint(
            x: 0,
            y: -(Constant.catSize.height / 2 + Constant.nameTagSpacing + Constant.nameTagHeight / 2)
        )

        let background = SKShapeNode(rectOf: nameTagSize)
        background.name = Constant.nameTagBackgroundNodeName
        background.fillColor = .black
        background.strokeColor = .clear
        background.position = nameTagPosition

        label.position = nameTagPosition
        label.zPosition = 1

        cat.addChild(background)
        cat.addChild(label)
    }

    private func updateNameTag(_ name: String, in cat: SKNode) {
        guard let label = cat.childNode(
            withName: Constant.nameTagLabelNodeName
        ) as? SKLabelNode,
        let background = cat.childNode(
            withName: Constant.nameTagBackgroundNodeName
        ) as? SKShapeNode else {
            addNameTag(name, to: cat)
            return
        }

        label.text = name
        let size = nameTagSize(for: label)
        background.path = CGPath(
            rect: CGRect(
                x: -size.width / 2,
                y: -size.height / 2,
                width: size.width,
                height: size.height
            ),
            transform: nil
        )
    }

    private func nameTagSize(for label: SKLabelNode) -> CGSize {
        CGSize(
            width: max(
                label.frame.width + Constant.nameTagHorizontalPadding * 2,
                Constant.nameTagMinimumWidth
            ),
            height: Constant.nameTagHeight
        )
    }

    private func moveRandomly(_ cat: SKNode, sprite: SKSpriteNode) {
        let wait = SKAction.wait(forDuration: .random(in: Constant.waitDurationRange))

        let chooseMove = SKAction.run { [weak self, weak cat, weak sprite] in
            guard let self, let cat, let sprite else { return }
            guard self.isValidContentSize(self.size) else { return }

            let target = self.randomCatPosition()

            sprite.xScale = target.x < cat.position.x ? -1 : 1

            let move = SKAction.move(
                to: target,
                duration: .random(in: Constant.moveDurationRange)
            )

            cat.run(move)
        }

        cat.run(.repeatForever(.sequence([wait, chooseMove])))
    }

    private func randomCatPosition() -> CGPoint {
        CGPoint(
            x: CGFloat.random(
                in: Constant.horizontalMoveInset...(size.width - Constant.horizontalMoveInset)
            ),
            y: CGFloat.random(
                in: Constant.bottomMoveInset...(size.height - Constant.topMoveInset)
            )
        )
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

        if selectedCatNode === catNode {
            clearSelection()
            return
        }

        clearSelection()

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

}

// MARK: - Constant

private extension HomeMapScene {
    enum Constant {
        static let mapNodeName = "map"
        static let catNodeName = "cat"
        static let catSize = CGSize(width: 48, height: 48)
        static let catDefaultZPosition: CGFloat = 10
        static let catZPositionBase: CGFloat = 1000

        static let catIDKey: String = "catID"

        static let nameTagLabelNodeName = "catNameLabel"
        static let nameTagBackgroundNodeName = "catNameBackground"
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

        static let horizontalMoveInset: CGFloat = catSize.width / 2
        static let bottomMoveInset: CGFloat = catSize.height / 2 + nameTagSpacing + nameTagHeight
        static let topMoveInset: CGFloat = catSize.height / 2

        static let waitDurationRange: ClosedRange<TimeInterval> = 0.5...1.5
        static let moveDurationRange: ClosedRange<TimeInterval> = 2.0...4.0
    }
}
