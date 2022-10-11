//
//  FIRDatabaseManager.swift
//  ARMomoCoin
//
//  Created by Kerry Dong on 2022/10/11.
//

import Foundation
import FirebaseDatabase

class FIRDatabaseManager {
    static let shared = FIRDatabaseManager()
    
    private let reference: DatabaseReference
    private let tableKey = "shared_anchor_codelab_root"
    private let currentIndexKey = "next_short_code"
    private let anchorKey = "anchor;"
    
    private init() {
        reference = Database.database().reference()
    }
    
    func getCurrentIndex(completionHandler: @escaping (Int?) -> Void) {
        reference.child("\(tableKey)/\(currentIndexKey)").getData(completion: { (error, snapshot) in
            if let error = error {
                print(error.localizedDescription)
                completionHandler(nil)
                return
            }
        
            let currentIndex = snapshot?.value as? Int
            completionHandler(currentIndex)
        })
    }
    
    func getAnchorIds(completionHandler: @escaping ([String]) -> Void) {
        reference.child("\(tableKey)").getData(completion: { (error, snapshot) in
            if let error = error {
                print(error.localizedDescription)
                completionHandler([])
                return
            }
        
            guard let records = snapshot?.children.allObjects as? [DataSnapshot] else {
                completionHandler([])
                return
            }
            
            let anchorIds = records
                .filter({ $0.key.starts(with: self.anchorKey) })
                .compactMap({ $0.value as? String })
            
            completionHandler(anchorIds)
        })
    }
    
    func setAnchor(by index: Int?, anchorId: String) {
        guard let index = index else {
            print("getAnchorId index is nil")
            return
        }
        
        reference.child("\(tableKey)/\(anchorKey)\(index+1)").setValue(anchorId)
        reference.child("\(tableKey)/\(currentIndexKey)").setValue(index+1)
    }
}
