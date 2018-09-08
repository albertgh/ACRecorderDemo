//
//  ViewController.swift
//  ACRecorderDemo
//
//  Created by Albert Chu on 2016/11/1.
//  Copyright © 2016年 ACSoft. All rights reserved.
//

import UIKit

import AudioKit

import CoreData


class ViewController: UIViewController {

    // UI
    @IBOutlet weak var fileLabel: UILabel!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var resetButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var recordControl: UILabel!

    // AudioKit
    var micMixer: AKMixer!
    
    var recorder: AKNodeRecorder!
    var player: AKPlayer!
    var tape: AKAudioFile!
    var micBooster: AKBooster!
    var moogLadder: AKMoogLadder!
    
    var mainMixer: AKMixer!

    
    // MARK: viewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.configView()
        self.configRecorder()
        self.restRecorder()
    }

    
    // MARK: action
    func listAction(sender: UIBarButtonItem) {
        let soundListVC: SoundListViewController = SoundListViewController(nibName: nil,bundle: nil)
        self.navigationController?.pushViewController(soundListVC, animated: true)
    }
    
    @IBAction func playAction(_ sender: UIButton) {
        print("play")
        if self.player!.isStarted {
            self.player!.stop()
        }
        else {
            self.player!.play()
        }
    }
    
    @IBAction func resetAction(_ sender: UIButton) {
        print("reset")
        self.restRecorder()
    }
    
    @IBAction func saveAction(_ sender: UIButton) {
        let currentFile: AVAudioFile = self.player!.audioFile!
        ACSoundFileManager.sharedInstance.saveFileBy(currentFile)
        self.saveToCoreDataBy(currentFile)
    }
    
    
    // MARK: Save to CoreData
    func saveToCoreDataBy(_ currentFile:AVAudioFile) {
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        appDelegate.persistentContainer.performBackgroundTask { (managedContext) in
            
            //let soundItem = NSEntityDescription.insertNewObject(forEntityName: "ACSoundItem", into: managedContext) as! ACSoundItem
            
            let soundItemEntity = NSEntityDescription.entity(forEntityName: "ACSoundItem",
                                                             in: managedContext)!
            let soundItem = ACSoundItem(entity: soundItemEntity, insertInto: managedContext)
            
            let now = Date()
            let timeInterval:TimeInterval = now.timeIntervalSince1970
            let timeStamp = Int(timeInterval)
            let timeStampString = String(timeStamp)
            let fileName = String(format:"%@.%@", timeStampString, currentFile.fileExt)
            soundItem.sid = String(timeStamp)
            soundItem.fileName = fileName
            soundItem.createdAt = now
            
            do {
                try managedContext.save()
            } catch let error as NSError {
                print("Could not save. \(error), \(error.userInfo)")
            }
            
            self.restRecorder()
        }
        
    }
    
    
    // MARK: private
    func restRecorder() {
        DispatchQueue.main.async {
            self.player!.stop()
            
            do {
                try self.recorder?.reset()
            } catch { print("Errored resetting.") }
                        
            self.fileLabel.text = "no file"
            
            self.playButton.isEnabled = false
            self.resetButton.isEnabled = false
            self.saveButton.isEnabled = false
        }
    }
    
    func configRecorder() {
        // Clean tempFiles !
        AKAudioFile.cleanTempDirectory()
        
        // Session settings
        AKSettings.bufferLength = .medium
        
        do {
            try AKSettings.setSession(category: .playAndRecord, with: .allowBluetoothA2DP)
        } catch {
            AKLog("Could not set session category.")
        }
 
        AKSettings.defaultToSpeaker = true
        
        // Patching
        let mic = AKMicrophone()
        self.micMixer = AKMixer(mic)
        self.micBooster = AKBooster(self.micMixer)
        
        // Will set the level of microphone monitoring
        self.micBooster.gain = 0
        self.recorder = try? AKNodeRecorder(node: self.micMixer)
        if let file = self.recorder.audioFile {
            self.player = AKPlayer(audioFile: file)
        }
        self.player.isLooping = false
        self.player.completionHandler = playingEnded
        
        self.moogLadder = AKMoogLadder(self.player)
        
        self.mainMixer = AKMixer(self.moogLadder, self.micBooster)
        
        AudioKit.output = mainMixer
        
        do {
            try AudioKit.start()
        } catch {
            AKLog("AudioKit did not start!")
        }
    }
    
    func playingEnded() {
        DispatchQueue.main.async {
            print("play ended")
        }
    }
    
    func configView() {
        self.view.backgroundColor = UIColor.white
        
        let barButtonItem = UIBarButtonItem(title: "list", style: UIBarButtonItemStyle.plain, target: self, action: #selector(listAction(sender:)))
        self.navigationItem.rightBarButtonItem = barButtonItem
        
        
        self.recordControl.clipsToBounds = true
        self.recordControl.layer.cornerRadius = self.recordControl.frame.size.width / 2.0
        let longPress = UILongPressGestureRecognizer(target: self,
                                                     action: #selector(handleLongPress(gestureReconizer:)))
        longPress.minimumPressDuration = 0.0
        self.recordControl.isUserInteractionEnabled = true;
        self.recordControl.addGestureRecognizer(longPress)
    }
    
    func handleLongPress(gestureReconizer: UILongPressGestureRecognizer) {
        if gestureReconizer.state == UIGestureRecognizerState.began {
            print("long press began ")
            self.recordControl.alpha = 0.5
            
            AVAudioSession.sharedInstance().requestRecordPermission({(granted: Bool)-> Void in
                if granted {
                    // microphone will be monitored while recording
                    // only if headphones are plugged
                    if AKSettings.headPhonesPlugged {
                        self.micBooster!.gain = 1
                    }
                    do {
                        try self.recorder?.record()
                    } catch {
                        print("Errored recording.")
                    }
                }
                else {
                    print("Permission to record not granted")
                }
            })
        }
        else if gestureReconizer.state == UIGestureRecognizerState.ended {
            print("long press end ")
            self.recordControl.alpha = 1.0

            // Microphone monitoring is muted
            self.micBooster.gain = 0
            
            self.tape = self.recorder.audioFile!
            self.player.load(audioFile: self.tape)
            
            if let _ = self.player.audioFile?.duration {
                self.recorder.stop()
                
                let currentFile: AVAudioFile = self.player!.audioFile!
                self.fileLabel.text = currentFile.fileNamePlusExtension
                
                self.playButton.isEnabled = true
                self.resetButton.isEnabled = true
                self.saveButton.isEnabled = true
                
//                self.tape.exportAsynchronously(name: "TempTestFile.m4a",
//                                          baseDir: .documents,
//                                          exportFormat: .m4a) {_, exportError in
//                                            if let error = exportError {
//                                                print("Export Failed \(error)")
//                                            } else {
//                                                print("Export succeeded")
//                                            }
//                }

            }
            
        }
    }


}

