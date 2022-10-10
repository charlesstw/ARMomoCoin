//
//  FeatureMapQualityBar.swift
//  ARMomoCoin
//
//  Created by Kerry Dong on 2022/10/7.
//

import Foundation
import SceneKit

class FeatureMapQualityBar: SCNNode {
    private let kCapsuleRadius: CGFloat = 0.006
    private let kCapsuleHeight: CGFloat = 0.03
    
    private lazy var capsuleNode: SCNNode = {
        let capsule = SCNCapsule(capRadius: kCapsuleRadius, height: kCapsuleHeight)
        capsule.materials.first?.diffuse.contents = UIColor.white
        return SCNNode(geometry: capsule)
    }()
    
    private var featureMapQuality = 0
    
    override init() {
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    convenience init(radius: Float, angle: Float, isHorizontal: Bool) {
        self.init()
        
        if isHorizontal {
            capsuleNode.position = SCNVector3(radius * cos(angle),  Float(kCapsuleHeight) / 2, radius * sin(angle))
        } else {
            capsuleNode.position = SCNVector3(radius * cos(angle), radius * sin(angle), -Float(kCapsuleHeight) / 2)
            capsuleNode.eulerAngles = SCNVector3(-Float.pi/2, 0, 0)
        }
        addChildNode(capsuleNode)
    }

    
    func updateVisualization(_ featureMapQuality: Int) {
        updateQualiaty(featureMapQuality)
        
        capsuleNode.geometry?.firstMaterial?.diffuse.contents = colorForQuality(quality: featureMapQuality)
    }
    
    private func updateQualiaty(_ featureMapQuality: Int) {
        switch featureMapQuality {
        case 1:
            self.featureMapQuality = max(1, featureMapQuality)
        case 2:
            self.featureMapQuality = max(2, featureMapQuality)
        default:
            self.featureMapQuality = max(0, featureMapQuality)
        }
    }
    
    func quality() -> Float {
        switch featureMapQuality {
        case 1:
            return 0.5
        case 2:
            return 1.0
        default:
            return 0.0
        }
    }
    
    private func colorForQuality(quality: Int) -> UIColor {
        switch quality {
        case 1:
            return UIColor.yellow
        case 2:
            return UIColor.green
        default:
            return UIColor.red
        }
    }
}
