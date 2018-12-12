//
//  Photo+Extensions.swift
//  VirualTourist
//
//  Created by بدور on 10/12/2018.
//  Copyright © 2018 Bdour. All rights reserved.
//

import Foundation
import CoreData

extension Photo {
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        creationDate = Date()
    }
}
