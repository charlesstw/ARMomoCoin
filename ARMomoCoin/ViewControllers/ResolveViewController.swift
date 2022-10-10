//
//  ResolveViewController.swift
//  ARMomoCoin
//
//  Created by Kerry Dong on 2022/10/9.
//

import UIKit
import ARKit
import ARCore

enum ResolveState {
    case ResolveStateDefault, ResolveStateResolving, ResolveStateFinished
}

class ResolveViewController: UIViewController {
    var anchorIds: [String] = []
    
    private var state = ResolveState.ResolveStateDefault
    private var message = ""
    private var debugMessage = ""
    private lazy var cloudAnchorManager: CloudAnchorManager = {
        return CloudAnchorManager(session: self.sceneView.session)
    }()
    
    private let kDebugMessagePrefix = "Debug panel\n"
    private var idToResolvedAnchorNodes: [String: SCNNode] = [:]
    private var idToGarAnchors: [String: GARAnchor] = [:]
    
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet var messageLabel: UILabel!
    @IBOutlet var debugLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        messageLabel.numberOfLines = 3
        debugLabel.numberOfLines = 5
        cloudAnchorManager.setDelegate(self)
        sceneView.delegate = self
        runSession()
        enterState(.ResolveStateDefault)
        resolveAnchors(anchorIds: anchorIds)
    }
}

extension ResolveViewController: CloudAnchorManagerDelegate {
    func cloudAnchorManager(manager: CloudAnchorManager, didUpdate garFrame: GARFrame, tracking: Bool, cameraTransform: simd_float4x4, anchors: [ARAnchor], featureMapQuality: Int) {
        if state == .ResolveStateResolving {
            for garAnchor in garFrame.updatedAnchors {
                if let anchorNode = idToResolvedAnchorNodes[garAnchor.cloudIdentifier ?? ""] {
                    anchorNode.simdTransform = garAnchor.transform
                    anchorNode.isHidden = !garAnchor.hasValidTransform
                }
            }
        }
    }
}

extension ResolveViewController: ARSCNViewDelegate {
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        if anchor.isKind(of: ARPlaneAnchor.self) == false {
            return cloudAnchorNode()
        } else {
            return nil
        }
    }
}

extension ResolveViewController: GARSessionDelegate {
    func session(_ session: GARSession, didResolve anchor: GARAnchor) {
        if state != .ResolveStateResolving || (idToGarAnchors[anchor.cloudIdentifier ?? ""] == nil) { return }
        
        idToGarAnchors[anchor.cloudIdentifier ?? ""] = anchor
        let node = cloudAnchorNode()
        node.simdTransform = anchor.transform
        sceneView.scene.rootNode.addChildNode(node)
        idToResolvedAnchorNodes[anchor.cloudIdentifier ?? ""] = node
        debugMessage = "Resolved \(idToResolvedAnchorNodes.keys.joined(separator: ", ")) continuing to refine pose."
        updateMessageLabel()
        updateResolveStatus()
    }
        
    func session(_ session: GARSession, didFailToResolve anchor: GARAnchor) {
        if state != .ResolveStateResolving || (idToGarAnchors[anchor.cloudIdentifier ?? ""] == nil) { return }
        
        idToGarAnchors[anchor.cloudIdentifier ?? ""] = anchor
        updateResolveStatus()
    }
}

// MARK: - Private Function
extension ResolveViewController {
    private func runSession() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.worldAlignment = .gravity
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration)
    }
    
    private func enterState(_ state: ResolveState) {
        switch state {
        case .ResolveStateDefault:
            message = "Look at the location you expect to see the AR experience appear."
            let num = anchorIds.count
            debugMessage = "Attempting to resolve \(num)/40 anchors"
            print("Attempting to resolve \(num) out of 40 anchors: \(anchorIds.joined(separator: ", "))")
        case .ResolveStateResolving:
            message = "Resolving..."
            debugMessage = "To cancel the resolve, call removeAnchor"
        case .ResolveStateFinished:
            message = "Resolve Finished: \n"
            
            for anchorId in idToGarAnchors.keys {
                message = "\(message)\(cloudStateString(idToGarAnchors[anchorId]?.cloudState))"
            }
            debugMessage = "Resolved \(idToResolvedAnchorNodes.keys.joined(separator: ", ")) continuing to refine pose.\nTo stop refining, call removeAnchor."
        }
        self.state = state
        updateMessageLabel()
    }
    
    private func resolveAnchors(anchorIds: [String]) {
        enterState(.ResolveStateResolving)
        do {
            for anchorId in anchorIds {
                idToGarAnchors[anchorId] = try cloudAnchorManager.resolveAnchor(with: anchorId)
            }
        } catch {
            print("Resolve anchor failed: \(error.localizedDescription)")
        }
    }
    
    private func cloudStateString(_ cloudState: GARCloudAnchorState?) -> String {
        switch cloudState {
        case .none?:
            return "None"
        case .success:
            return "Success"
        case .errorInternal:
            return "ErrorInternal"
        case .taskInProgress:
            return "taskInProgress"
        case .errorNotAuthorized:
            return "ErrorNotAuthorized"
        case .errorResourceExhausted:
            return "ErrorResourceExhausted"
        case .errorCloudIdNotFound:
            return "ErrorCloudIdNotFound"
        default:
            return "Unknown"
        }
    }
    
    private func updateMessageLabel() {
        messageLabel.text = message
        debugLabel.text = "\(kDebugMessagePrefix)\(debugMessage)"
    }
    
    private func cloudAnchorNode() -> SCNNode {
        let scene = SCNScene(named: "art.scnassets/mining_equipment.scn")
        let anchorNode = scene?.rootNode.childNode(withName: "scene", recursively: false)
        return anchorNode ?? SCNNode.init()
    }
    
    private func updateResolveStatus() {
        var allFinished = true
        for anchorId in idToGarAnchors.keys {
            if idToGarAnchors[anchorId]?.cloudState == GARCloudAnchorState.none || idToGarAnchors[anchorId]?.cloudState == GARCloudAnchorState.taskInProgress {
                allFinished = false
                break
            }
        }
        if allFinished {
            enterState(.ResolveStateFinished)
        }
    }
}
