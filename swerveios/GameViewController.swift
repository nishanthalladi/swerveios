import UIKit
import SpriteKit
import CoreMotion

class GameViewController: UIViewController {
    var scene: GameScene?
    let sensitivitySlider = UISlider()

    override func viewDidLoad() {
        super.viewDidLoad()
        let skView = SKView(frame: self.view.frame)
        skView.ignoresSiblingOrder = true  // Optimizes rendering performance
        self.view.addSubview(skView)
        scene = GameScene(size: skView.bounds.size)
        scene?.scaleMode = .resizeFill
        skView.presentScene(scene)
        
//        setupSliders()
    }
    
    func setupSliders() {
        sensitivitySlider.frame = CGRect(x: 20, y: view.frame.height - 100, width: view.frame.width - 40, height: 30)
        sensitivitySlider.minimumValue = 0
        sensitivitySlider.maximumValue = 200
        sensitivitySlider.value = 100
        sensitivitySlider.addTarget(self, action: #selector(sensitivityValueChanged(_:)), for: .valueChanged)
        view.addSubview(sensitivitySlider)
    }

    @objc func sensitivityValueChanged(_ sender: UISlider) {
        scene?.sensitivity = CGFloat(sender.value)
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
