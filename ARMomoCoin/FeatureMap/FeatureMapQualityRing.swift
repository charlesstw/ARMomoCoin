//
//  FeatureMapQualityRing.swift
//  ARMomoCoin
//
//  Created by Kerry Dong on 2022/10/7.
//

import Foundation
import SceneKit

class FeatureMapQualityRing: SCNNode {
    private let kPipeRadius: CGFloat = 0.001
    
    override init() {
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    convenience init(radius: CGFloat, isHorizontal: Bool) {
        self.init()
        let torus = SCNTorus(ringRadius: radius, pipeRadius: kPipeRadius)
        torus.firstMaterial?.diffuse.contents = createUIImage()
        let torusNode = SCNNode(geometry: torus)
        
        if !isHorizontal {
            torusNode.eulerAngles = SCNVector3(-Float.pi/2, 0, 0)
        }
        addChildNode(torusNode)
    }
    
    func createUIImage() -> UIImage? {
        let imageSize = CGSize(width: 100, height: 100)
        let imageRect = CGRect(x: 0, y: 0, width: imageSize.width, height: imageSize.height)
        UIGraphicsBeginImageContextWithOptions(imageRect.size, false, 0)
        
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        context.clear(imageRect)
        
        let smallRect = CGRect(x: imageSize.width / 4, y: 0, width: imageSize.width / 2, height: imageSize.height)
        context.setFillColor(UIColor.white.cgColor)
        context.fill(smallRect)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
}
