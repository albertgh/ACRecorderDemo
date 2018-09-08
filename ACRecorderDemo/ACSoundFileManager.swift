//
//  ACSoundFileManager.swift
//  ACRecorderDemo
//
//  Created by Albert Chu on 2016/11/3.
//  Copyright © 2016年 ACSoft. All rights reserved.
//

import Foundation

import AudioKit

class ACSoundFileManager {
    
    // MARK: Local Variable
    var dirString : String
    
    
    // MARK: Shared Instance
    static let sharedInstance : ACSoundFileManager = {
        let instance = ACSoundFileManager(dir: "rec")
        return instance
    }()
    
    // MARK: init
    init(dir: String) {
        dirString = dir
    }
    
    
    // MARK: public
    public func urlBy(_ soundItem: ACSoundItem) -> URL? {
        let fileManager = FileManager.default
        let documentPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        
        let recPath = NSURL(fileURLWithPath: documentPath).appendingPathComponent(self.dirString)
        if fileManager.fileExists(atPath: recPath!.path) {
            let fileName = String(format:"%@", soundItem.fileName!)
            let soundURL = URL(fileURLWithPath: (recPath?.path)!).appendingPathComponent(fileName)
            return soundURL
        }
        return nil
    }
    
    public func saveFileBy(_ audioFile: AVAudioFile) -> Void {
        let fileManager = FileManager.default
        let documentPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        
        let currentFile: AVAudioFile = audioFile
        let currentFileFullPath: String = String(format:"%@/%@",
                                                 currentFile.directoryPath.path,
                                                 currentFile.fileNamePlusExtension)
        
        // creat rec path if not exist
        let recPath = NSURL(fileURLWithPath: documentPath).appendingPathComponent(self.dirString)
        if !fileManager.fileExists(atPath: (recPath?.path)!) {
            do {
                try fileManager.createDirectory(atPath: (recPath?.path)!, withIntermediateDirectories: false, attributes: nil)
            }
            catch let error as NSError {
                print("createDirectory error: \(error)")
            }
        }
        
        let now = Date()
        let timeInterval:TimeInterval = now.timeIntervalSince1970
        let timeStamp = Int(timeInterval)
        let timeStampString = String(timeStamp)
        let fileName = String(format:"%@.%@", timeStampString, currentFile.fileExt)
        
        // copy file to rec path
        let recDirWithFileName = String(format:"%@/%@", self.dirString, fileName)
        let fullDestPath = NSURL(fileURLWithPath: documentPath).appendingPathComponent(recDirWithFileName)
        let fullDestPathString = fullDestPath!.path
        do {
            try fileManager.copyItem(atPath: currentFileFullPath, toPath: fullDestPathString)
        }
        catch let error as NSError {
            print("copyItem error: \(error)")
        }
    }
    
}
