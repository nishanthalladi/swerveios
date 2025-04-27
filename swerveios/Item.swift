import SpriteKit

class Item: SKLabelNode {
    let type: ItemType

    init(type: ItemType, position: CGPoint) {
        self.type = type
        super.init()
        self.text = type.emoji
        self.fontSize = 30
        self.fontColor = .white
        self.position = position
        self.name = "item_\(type)"
        self.zPosition = 10
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
