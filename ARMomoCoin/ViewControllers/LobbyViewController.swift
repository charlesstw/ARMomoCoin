//
//  LobbyViewController.swift
//  ARMomoCoin
//
//  Created by Kerry Dong on 2022/10/7.
//

import UIKit

class LobbyViewController: UIViewController {
    let kCornerRadius: CGFloat = 8
    
    @IBOutlet var hostButton: UIButton!
    @IBOutlet var resolveButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        hostButton.layer.cornerRadius = kCornerRadius
        resolveButton.layer.cornerRadius = kCornerRadius
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
}
