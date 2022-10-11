//
//  LobbyViewController.swift
//  ARMomoCoin
//
//  Created by Kerry Dong on 2022/10/7.
//

import UIKit
import FirebaseDatabase

class LobbyViewController: UIViewController {
    let kCornerRadius: CGFloat = 8
    
    @IBOutlet var hostButton: UIButton!
    @IBOutlet var resolveButton: UIButton!
    @IBOutlet var remoteResolveButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        hostButton.layer.cornerRadius = kCornerRadius
        resolveButton.layer.cornerRadius = kCornerRadius
        remoteResolveButton.layer.cornerRadius = kCornerRadius
    }
    
    @IBAction func hostButtonClicked(_ sender: UIButton) {
        guard let storyboard = self.storyboard else { return }
        let hostViewController = storyboard.instantiateViewController(withIdentifier: "HostViewController")
        self.navigationController?.pushViewController(hostViewController, animated: true)
    }
    
    @IBAction func resolveButtonClicked(_ sender: UIButton) {
        guard let storyboard = self.storyboard else { return }
        let resolveLobbyViewController = storyboard.instantiateViewController(withIdentifier: "ResolveLobbyViewController")
        self.navigationController?.pushViewController(resolveLobbyViewController, animated: true)
    }
    
    @IBAction func remoteResolveButtonClicked(_ sender: UIButton) {
        FIRDatabaseManager.shared.getAnchorIds { [weak self] anchorIds in
            guard let resolveViewController = self?.storyboard?.instantiateViewController(withIdentifier: "ResolveViewController") as? ResolveViewController else { return }
            
            resolveViewController.anchorIds = anchorIds
            self?.navigationController?.pushViewController(resolveViewController, animated: true)
        }
    }
}
