//
//  HostViewController.swift
//  ARMomoCoin
//
//  Created by Kerry Dong on 2022/10/7.
//

import UIKit
import ARKit
import ARCore

enum HostState {
    case hostStateDefault, hostStateAnchorCreate, hostStateHosting, hostStateFinished
}

class HostViewController: UIViewController {
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet var messageLabel: UILabel!
    @IBOutlet var debugLabel: UILabel!
    
    private var arAnchor: ARAnchor?
    private var garAnchor: GARAnchor?
    private var state = HostState.hostStateDefault
    private var cloudAnchorId = ""
    private var message = ""
    private var debugMessage = ""
    private lazy var cloudAnchorManager: CloudAnchorManager = {
        return CloudAnchorManager(session: self.sceneView.session)
    }()
    
    private let kFeatureMapQualityThreshold: Float = 0.6
    private let kRadius: Float = 0.2
    private let kPlaneColor: [CGFloat] = [0, 0, 1.0, 0.7]
    private let kMaxDistance: Float = 10
    private let kSecToMilliseconds: Double = 1000
    private let kDebugMessagePrefix = "Debug panel\n"
    private let kNicknameTimeStampDictionary = "NicknameTimeStampDictionary"
    private let kNicknameAnchorIdDictionary = "NicknameAnchorIdDictionary"
    
    private var qualityBars: [SCNNode] = []
    private var featureMapQualityBars: FeatureMapQualityBars?
    private var anchorPlaced = false
    private var hitHorizontalPlane = false
    private var anchorIdentifier = UUID()
    private var cameraTransform = simd_float4x4([0.0, 0.0, 0.0, 0.0], [0.0, 0.0, 0.0, 0.0], [0.0, 0.0, 0.0, 0.0], [0.0, 0.0, 0.0, 0.0])
    private var hostBeginDate = Date()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        messageLabel.numberOfLines = 3
        debugLabel.numberOfLines = 3
        hitHorizontalPlane = true
        cloudAnchorManager.setDelegate(self)
        sceneView.delegate = self
        runSession()
        enterState(state: .hostStateDefault)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if touches.count < 1 || state != HostState.hostStateDefault { return }
        
        let touch = touches.first
        guard let touchLocation = touch?.location(in: sceneView) else {
            print("Touch Location is nil")
            return
        }
        let extent = ARHitTestResult.ResultType.existingPlaneUsingExtent.rawValue
        let horizontalPlane = ARHitTestResult.ResultType.estimatedHorizontalPlane.rawValue
        let verticalPane = ARHitTestResult.ResultType.estimatedHorizontalPlane.rawValue
        var hitTestResultTypes = extent | horizontalPlane
        if #available(iOS 11.3, *) {
            hitTestResultTypes = hitTestResultTypes | verticalPane
        }
        let hitTestReaults = sceneView.hitTest(touchLocation, types: ARHitTestResult.ResultType(rawValue: hitTestResultTypes))
        
        if hitTestReaults.count > 0 {
            let result = hitTestReaults.first
            if let anchor = result?.anchor, anchor.isKind(of: ARPlaneAnchor.self) {
                let planeAnchor = ARPlaneAnchor(anchor: anchor)
                hitHorizontalPlane = planeAnchor.alignment == ARPlaneAnchor.Alignment.horizontal
            }
            
            let angle: Float = 0
            let worldTransform = result?.worldTransform ?? simd_float4x4(rows: [])
            if hitHorizontalPlane {
                let anchorTCamera = simd_mul(simd_inverse(worldTransform), cameraTransform)
                let x: Float = anchorTCamera.columns.3.x
                let z: Float = anchorTCamera.columns.3.z

                var angle = atan2f(x, z)
                angle = z > 0 ? angle : angle + Float.pi
            }
            
            let roatation = SCNMatrix4MakeRotation(angle, 0, 1, 0)
            let rotateAnchor: matrix_float4x4 = simd_mul(worldTransform, float4x4(roatation))
            addAnchor(with: rotateAnchor)
        }
        enterState(state: .hostStateAnchorCreate)
        anchorPlaced = true
    }
}

extension HostViewController: ARSCNViewDelegate {
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        if anchor.isKind(of: ARPlaneAnchor.self) == false {
            return cloudAnchorNode()
        } else {
            return SCNNode()
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if anchor.isKind(of: ARPlaneAnchor.self) {
            let planeAnchor = ARPlaneAnchor(anchor: anchor)
            
            let width: CGFloat = CGFloat(planeAnchor.extent.x)
            let height: CGFloat = CGFloat(planeAnchor.extent.z)
            let plane = SCNPlane(width: width, height: height)
            
            plane.materials.first?.diffuse.contents = UIColor(red: kPlaneColor[0], green: kPlaneColor[1], blue: kPlaneColor[2], alpha: kPlaneColor[3])
            
            let planeNode = SCNNode(geometry: plane)
            let x: Float = planeAnchor.center.x
            let y: Float = planeAnchor.center.y
            let z: Float = planeAnchor.center.z
            planeNode.position = SCNVector3Make(x, y, z)
            planeNode.eulerAngles = SCNVector3Make(-Float.pi / 2, 0, 0)
            
            node.addChildNode(planeNode)
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        if anchor.isKind(of: ARPlaneAnchor.self) {
            if anchorPlaced {
                let planeNode = node.childNodes.first
                planeNode?.removeFromParentNode()
            } else {
                let planeAnchor = ARPlaneAnchor(anchor: anchor)
                
                let planeNode = node.childNodes.first
                let plane = planeNode?.geometry as? SCNPlane
                
                let width: CGFloat = CGFloat(planeAnchor.extent.x)
                let height: CGFloat = CGFloat(planeAnchor.extent.z)
                plane?.width = width
                plane?.height = height
                
                let x: Float = planeAnchor.center.x
                let y: Float = planeAnchor.center.y
                let z: Float = planeAnchor.center.z
                planeNode?.position = SCNVector3Make(x, y, z)
            }
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        if anchor.isKind(of: ARPlaneAnchor.self) {
            let planeNode = node.childNodes.first
            planeNode?.removeFromParentNode()
        }
    }
}

extension HostViewController: CloudAnchorManagerDelegate {
    func cloudAnchorManager(manager: CloudAnchorManager, didUpdate frame: GARFrame, tracking: Bool, cameraTransform: simd_float4x4, anchors: [ARAnchor], featureMapQuality: Int) {
        if state != .hostStateAnchorCreate || !tracking { return }
        guard let arAnchor = arAnchor else {
            print("arAnchor is nil")
            return
        }
        
        self.cameraTransform = cameraTransform
        updateDebugMessageLabel(from: featureMapQuality)
        
        let avg: Float = featureMapQualityBars?.featureMapQualityAvg() ?? 0.0
        print("History of average mapping quality calls: \(avg)")
        if avg > kFeatureMapQualityThreshold {
            garAnchor = cloudAnchorManager.hostCloudAnchor(archor: arAnchor)
            enterState(state: .hostStateHosting)
            hostBeginDate = Date()
            return
        }
        
        if featureMapQualityBars == nil {
            return
        }
        
        for anchor in anchors {
            if anchor.identifier == anchorIdentifier {
                let anchorTCamera = simd_mul(simd_inverse(anchor.transform), cameraTransform)
                let x: Float = anchorTCamera.columns.3.x
                let y: Float = anchorTCamera.columns.3.y
                let z: Float = anchorTCamera.columns.3.z
                
                let angle = hitHorizontalPlane ? atan2f(z, x) : atan2f(y, x)
                featureMapQualityBars?.updateVisualization(angle: angle, featureMapQuality: featureMapQuality)
                let distance = hitHorizontalPlane ? sqrt(z * z + x * x) : sqrt(y * y + x * x)
                
                if distance > kMaxDistance {
                    message = "You are too far; come closer"
                } else if distance < kRadius {
                    message = "You are too close; move backward"
                } else {
                    message = "Save the object here by capturing it from all sides"
                }
                messageLabel.text = message
                break
            }
        }
    }
}

extension HostViewController: GARSessionDelegate {
    func session(_ session: GARSession, didHost anchor: GARAnchor) {
        garAnchor = anchor
        enterState(state: .hostStateFinished)
        let durationSec = Date().timeIntervalSince(hostBeginDate)
        print("Time taken to complete hosting process: \(durationSec * kSecToMilliseconds) ms")
        sendSaveAlert(anchorId: anchor.cloudIdentifier)
    }
    
    func session(_ session: GARSession, didFailToHost anchor: GARAnchor) {
        garAnchor = anchor
        enterState(state: .hostStateFinished)
    }
}

// MARK: - Private Function
extension HostViewController {
    private func runSession() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.worldAlignment = .gravity
        let horizontalPlane = ARWorldTrackingConfiguration.PlaneDetection.horizontal.rawValue
        if #available(iOS 11.3, *) {
            let verticalPlane = ARWorldTrackingConfiguration.PlaneDetection.vertical.rawValue
            configuration.planeDetection = ARWorldTrackingConfiguration.PlaneDetection(rawValue: horizontalPlane | verticalPlane)
        } else {
            configuration.planeDetection = ARWorldTrackingConfiguration.PlaneDetection(rawValue: horizontalPlane)
        }
        
        sceneView.session.run(configuration)
    }
    
    private func enterState(state: HostState) {
        switch state {
        case .hostStateDefault:
            message = "Tap to place an object."
            debugMessage = "Tap a vertical or horizontal plane..."
        case .hostStateAnchorCreate:
            message = "Save the object here by capturing it from all sides"
            debugMessage = "Average mapping quality: "
        case .hostStateHosting:
            message = "Processing..."
            debugMessage = "GARFeatureMapQuality average has reached Sufficient-Good, triggering hostCloudAnchor:TTLDays:error"
        case .hostStateFinished:
            message = "Finished: \(cloudStateString(garAnchor?.cloudState))"
            debugMessage = "Anchor \(garAnchor?.cloudIdentifier ?? "0") created"
        }
        self.state = state
        updateMessageLabel()
    }
    
    private func updateMessageLabel() {
        messageLabel.text = message
        debugLabel.text = "\(kDebugMessagePrefix)\(debugMessage)"
    }
    
    private func updateDebugMessageLabel(from quality: Int) {
        let featureMapQualityMessage = "\(debugMessage)\(getString(from: quality))"
        debugLabel.text = "\(kDebugMessagePrefix)\(featureMapQualityMessage)"
    }
    
    private func getString(from quality: Int) -> String {
        switch quality {
        case 1:
            return "Sufficient"
        case 2:
            return "Good"
        default:
            return "Insufficient"
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
            return "TaskInProgress"
        case .errorNotAuthorized:
            return "ErrorNotAuthorized"
        case .errorResourceExhausted:
            return "ErrorResourceExhausted"
        case .errorHostingDatasetProcessingFailed:
            return "ErrorHostingDatasetProcessingFailed"
        case .errorCloudIdNotFound:
            return "ErrorCloudIdNotFound"
        case .errorHostingServiceUnavailable:
            return "ErrorHostingServiceUnavailable"
        default:
            return "Unknown"
        }
    }
    
    private func cloudAnchorNode() -> SCNNode? {
        let anchorNode = cloudAnchorManager.getAnchorNode()
        
        let ringNode = FeatureMapQualityRing(radius: CGFloat(kRadius), isHorizontal: hitHorizontalPlane)
        anchorNode?.addChildNode(ringNode)
        featureMapQualityBars = FeatureMapQualityBars(radius: kRadius, isHorizontal: hitHorizontalPlane)
        anchorNode?.addChildNode(featureMapQualityBars!)
        
        return anchorNode
    }
    
    private func addAnchor(with transform: matrix_float4x4) {
        arAnchor = ARAnchor(transform: transform)
        anchorIdentifier = arAnchor!.identifier
        sceneView.session.add(anchor: arAnchor!)
    }
}

// MARK: - Alert Private Function
extension HostViewController {
    private func sendSaveAlert(anchorId: String?) {
        let kSaveAnchorAlertTitle = "Enter name"
        let kAlertMessage =
            "Enter a name for your anchor ID(to be stored in local app storage)"
        let kSaveAnchorAlertOkButtonText = "OK"
        let kNicknameTimeStampDictionary = "NicknameTimeStampDictionary"

        let alertController = UIAlertController(title: kSaveAnchorAlertTitle, message: kAlertMessage, preferredStyle: .alert)

        let okAction = UIAlertAction(title: kSaveAnchorAlertOkButtonText, style: .default) { _ in
            if let nickname = alertController.textFields?[0].text {
                self.saveAnchor(nickname: nickname, anchorId: anchorId)
            }
        }
        alertController.addAction(okAction)
        alertController.addTextField { textField in
            let timeStamps = UserDefaults.standard.object(forKey: kNicknameTimeStampDictionary) as? [String: Date] ?? [:]
            textField.placeholder = "Anchor\(timeStamps.count)"
        }
        
        present(alertController, animated: true)
    }
    
    private func saveAnchor(nickname: String, anchorId: String?) {
        guard let anchorId = anchorId else {
            print("Anchor Id is nil")
            return
        }

        var nicknameToTimeStampDictionary = UserDefaults.standard.object(forKey: kNicknameTimeStampDictionary) as? [String: Date] ?? [:]
        var nicknameToAnchorIdDictionary = UserDefaults.standard.object(forKey: kNicknameAnchorIdDictionary) as? [String: String] ?? [:]
        
        nicknameToTimeStampDictionary[nickname] = Date()
        nicknameToAnchorIdDictionary[nickname] = anchorId
        
        UserDefaults.standard.set(nicknameToTimeStampDictionary, forKey: kNicknameTimeStampDictionary)
        UserDefaults.standard.set(nicknameToAnchorIdDictionary, forKey: kNicknameAnchorIdDictionary)
        
        // Save to firebase
        FIRDatabaseManager.shared.getCurrentIndex { index in
            FIRDatabaseManager.shared.setAnchor(by: index, anchorId: anchorId)
        }
    }
}
