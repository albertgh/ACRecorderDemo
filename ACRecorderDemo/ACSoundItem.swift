//
//  ACSoundItem.swift
//  ACRecorderDemo
//
//  Created by Albert Chu on 2016/11/2.
//  Copyright © 2016年 ACSoft. All rights reserved.
//

import UIKit

import Foundation

import CoreData

class ACSoundItem: NSManagedObject {

    @NSManaged var sid: String?
    @NSManaged var fileName: String?
    @NSManaged var createdAt: Date?
    @NSManaged var isPlaying: Bool

    
}
