//
//  CloudAnchorManager.swift
//  ARMomoCoin
//
//  Created by Kerry Dong on 2022/10/7.
//

import Foundation
import ARKit
import SceneKit
import ARCore

protocol CloudAnchorManagerDelegate: GARSessionDelegate {
    func cloudAnchorManager(manager: CloudAnchorManager, didUpdate frame: GARFrame, tracking: Bool, cameraTransform: simd_float4x4, anchors: [ARAnchor], featureMapQuality: Int)
}

class CloudAnchorManager: NSObject {
    weak var session: ARSession?
    weak var delegate: CloudAnchorManagerDelegate?
    
    var gSession: GARSession!
    
    convenience init(session: ARSession) {
        self.init()
        self.session = session
        self.session?.delegate = self
        
        do {
            try gSession = GARSession(apiKey: "AIzaSyD2dtcN_0uWUJcN_9WsI__W-Q7nP6GqF_Y", bundleIdentifier: nil)
        } catch {
            fatalError("Create CloudAnchorManager fail: \(error.localizedDescription)")
        }
        gSession.delegateQueue = DispatchQueue.main
        
        let configuration = GARSessionConfiguration()
        configuration.cloudAnchorMode = GARCloudAnchorMode.enabled
        gSession.setConfiguration(configuration, error: nil)
    }
    
    func setDelegate(_ delegate: CloudAnchorManagerDelegate) {
        self.delegate = delegate
        self.gSession.delegate = delegate
    }
    
    func hostCloudAnchor(archor: ARAnchor) -> GARAnchor? {
        do {
            return try gSession.hostCloudAnchor(archor, ttlDays: 1)
        } catch {
            print("Host cloud anchor failed: \(error.localizedDescription)")
            return nil
        }
    }
    
    func resolveAnchor(with anchorId: String) throws -> GARAnchor {
        return try gSession.resolveCloudAnchor(anchorId)
    }
    
    func removeAnchor(anchor: GARAnchor) {
        gSession.remove(anchor)
    }
    
    func getFeatureMapQuality(frame: ARFrame) -> Int {
        do {
            let quality = try gSession.estimateFeatureMapQualityForHosting(frame.camera.transform)
            return quality.rawValue
        } catch {
            return (error as NSError).code
        }
    }
    
    func getAnchorNode() -> SCNNode? {
        let scene = SCNScene(named: "art.scnassets/mining_equipment.scn")
        let anchorNode = scene?.rootNode.childNode(withName: "scene", recursively: false)
//
//        // Load ship.scn
//        let scene = SCNScene(named: "art.scnassets/ship.scn")
//        let anchorNode = scene?.rootNode.childNode(withName: "ship", recursively: false)
//        let shipAnchor = anchorNode?.childNode(withName: "shipMesh", recursively: true)
//        shipAnchor?.scale = SCNVector3(0.01, 0.01, 0.01)
        
        // Load toy_drummer.scn
//        let scene = SCNScene(named: "art.scnassets/toy_drummer.scn")
//        let anchorNode = scene?.rootNode.childNode(withName: "toy_drummer", recursively: false)
//        let geomAnchor = anchorNode?.childNode(withName: "Geom", recursively: true)
//        geomAnchor?.scale = SCNVector3(0.01, 0.01, 0.01)
        
        return anchorNode
    }
}

extension CloudAnchorManager: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        do {
            let garFrame = try gSession.update(frame)

            var isTracking = false
            if case ARCamera.TrackingState.normal = frame.camera.trackingState {
                isTracking = true
            }
            
            let featureMapQuality = getFeatureMapQuality(frame: frame)
            
            delegate?.cloudAnchorManager(manager: self, didUpdate: garFrame, tracking: isTracking, cameraTransform: frame.camera.transform, anchors: frame.anchors, featureMapQuality: featureMapQuality)
            
        } catch {
            print("CloudAnchorManager didUpdate failed: \(error.localizedDescription)")
        }
    }
}
