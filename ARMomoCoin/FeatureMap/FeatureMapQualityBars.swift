//
//  FeatureMapQualityBars.swift
//  ARMomoCoin
//
//  Created by Kerry Dong on 2022/10/7.
//

import Foundation
import SceneKit

class FeatureMapQualityBars: SCNNode {
    private let kHorizontalBarNum: Int = 25
    private let kVerticalBarNum: Int = 21
    private let kSpacingRad: Float = Float.pi * (7.5 / 180)
    
    private var qualityBars: [FeatureMapQualityBar] = []
    private var isHorizontal = false
    
    override init() {
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    convenience init(radius: Float, isHorizontal: Bool) {
        self.init()
        self.isHorizontal = isHorizontal
        if isHorizontal {
            for index in 0..<kHorizontalBarNum {
                let angle = Float(index) * kSpacingRad
                let qualityBar = FeatureMapQualityBar(radius: radius, angle: angle, isHorizontal: isHorizontal)
                qualityBars.append(qualityBar)
                addChildNode(qualityBar)
            }
        } else {
            for index in 0..<kVerticalBarNum {
                let angle = Float.pi / 12 + Float(index) * kSpacingRad
                let qualityBar = FeatureMapQualityBar(radius: radius, angle: angle, isHorizontal: isHorizontal)
                qualityBars.append(qualityBar)
                addChildNode(qualityBar)
            }
        }
    }
    
    func updateVisualization(angle: Float, featureMapQuality: Int) {
        let barNum = isHorizontal ? kHorizontalBarNum : kVerticalBarNum
        let angleWithGap = isHorizontal ? angle : angle - Float.pi / 12
        let barIndex = Int(angleWithGap / kSpacingRad)
        if barIndex >= 0, barIndex < barNum {
            let qualityBar = qualityBars[barIndex]
            qualityBar.updateVisualization(featureMapQuality)
        }
    }
    
    func featureMapQualityAvg() -> Float {
        var sum: Float = 0.0
        for qualityBar in qualityBars {
            sum += qualityBar.quality()
        }
        return sum / Float(qualityBars.count)
    }
}
