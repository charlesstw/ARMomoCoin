//
//  ResolveLobbyViewController.swift
//  ARMomoCoin
//
//  Created by Kerry Dong on 2022/10/9.
//

import UIKit

class ResolveLobbyViewController: UIViewController {
    private let KDayToSeconds: TimeInterval = 24 * 60 * 60
    private let KHourToSeconds: TimeInterval = 60 * 60
    private let KHourToMinutes: TimeInterval = 60
    private let KMinutesToSeconds: TimeInterval = 60
    private let kNicknameCornerRadius: CGFloat = 4
    private let kResolveCornerRadius: CGFloat = 8
    private let kTableIdentifier = "tableIdentifier"
    private let kNicknameTimeStampDictionary = "NicknameTimeStampDictionary"
    private let kNicknameAnchorIdDictionary = "NicknameAnchorIdDictionary"

    private var nicknameToTimestamps: [String: Date] = [:]
    private var nicknameToAnchorIds: [String: String] = [:]
    private var sortedNicknames: [String] = []
    private var tableViewAnchorIds: Set<String> = []
    private var selectedNicknames: Set<String> = []
    private var inputAnchorIds: [String] = []
    
    @IBOutlet var nicknameButton: UIButton!
    @IBOutlet var nicknameTableView: UITableView!
    @IBOutlet var resolveButton: UIButton!
    @IBOutlet var anchorIdsField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        nicknameButton.layer.borderWidth = 1.0
        nicknameButton.layer.borderColor = UIColor.gray.cgColor
        nicknameButton.layer.cornerRadius = kNicknameCornerRadius
        nicknameTableView.delegate = self
        nicknameTableView.dataSource = self
        nicknameTableView.isHidden = true
        resolveButton.layer.cornerRadius = kResolveCornerRadius
        startObservingNicknames()
        anchorIdsField.delegate = self
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        tapGestureRecognizer.delegate = self
        view.addGestureRecognizer(tapGestureRecognizer)
    }
    
    private func startObservingNicknames() {
        nicknameToTimestamps = UserDefaults.standard.object(forKey: kNicknameTimeStampDictionary) as? [String: Date] ?? [:]
        nicknameToAnchorIds = UserDefaults.standard.object(forKey: kNicknameAnchorIdDictionary) as? [String: String] ?? [:]

        for (key, value) in nicknameToTimestamps {
            if Date().timeIntervalSince(value) > KDayToSeconds {
                nicknameToTimestamps.removeValue(forKey: key)
                nicknameToAnchorIds.removeValue(forKey: key)
            }
        }
        
        sortedNicknames = nicknameToTimestamps.sorted(by: { $0.0 < $1.0 }).map({ $0.key })
        
        UserDefaults.standard.set(nicknameToTimestamps, forKey: kNicknameTimeStampDictionary)
        UserDefaults.standard.set(nicknameToAnchorIds, forKey: kNicknameAnchorIdDictionary)
        
        nicknameTableView.reloadData()
    }
    
    @objc private func handleTap() {
        view.endEditing(true)
    }
    
    private func updateNicknameButtonText() {
        let showSelectedNames = Array(selectedNicknames).joined(separator: ", ")
        nicknameButton.setTitle(showSelectedNames, for: .normal)
    }
}



extension ResolveLobbyViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return nicknameToTimestamps.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: kTableIdentifier)
        let nickname = sortedNicknames[indexPath.row]
        
        var time = ""
        let interval = Date().timeIntervalSince(nicknameToTimestamps[nickname] ?? Date())
        let hours = Int(interval / KHourToSeconds)
        let minutes = Int(interval / KMinutesToSeconds - Double(hours) * KHourToMinutes)
        
        if hours > 0 {
            time = "\(hours)h"
        } else {
            time = "\(minutes)m"
        }
        time = "\(time) ago"
        
        cell.textLabel?.text = nickname
        cell.detailTextLabel?.text = time
        cell.tintColor = UIColor.blue
        return cell
    }
}

extension ResolveLobbyViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = nicknameTableView.cellForRow(at: indexPath)
        tableViewAnchorIds.insert(nicknameToAnchorIds[cell?.textLabel?.text ?? ""] ?? "")
        selectedNicknames.insert(cell?.textLabel?.text ?? "")
        updateNicknameButtonText()
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let cell = nicknameTableView.cellForRow(at: indexPath)
        tableViewAnchorIds.remove(nicknameToAnchorIds[cell?.textLabel?.text ?? ""] ?? "")
        selectedNicknames.remove(cell?.textLabel?.text ?? "")
        updateNicknameButtonText()
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .init(rawValue: 3) ?? .none
    }
}

extension ResolveLobbyViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

extension ResolveLobbyViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return !CGRectContainsPoint(nicknameTableView.bounds, touch.location(in: nicknameTableView))
    }
}

extension ResolveLobbyViewController {
    @IBAction func nicknameButtonClicked(_ sender: UIButton) {
        nicknameTableView.isHidden = !nicknameTableView.isHidden
        nicknameTableView.setEditing(true, animated: true)
    }
    
    @IBAction func resolveButtonClicked(_ sender: UIButton) {
        view.endEditing(true)
        if let anchorText = anchorIdsField.text, anchorText.count > 0 {
            inputAnchorIds = []
            inputAnchorIds = anchorText.components(separatedBy: ",")
        }
        
        guard let resolveViewController = storyboard?.instantiateViewController(withIdentifier: "ResolveViewController") as? ResolveViewController else { return }
        if inputAnchorIds.count > 0 {
            resolveViewController.anchorIds = inputAnchorIds
        } else {
            resolveViewController.anchorIds = Array(tableViewAnchorIds)
        }
        navigationController?.pushViewController(resolveViewController, animated: true)
    }
}
