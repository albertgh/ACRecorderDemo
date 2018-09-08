//
//  SoundListViewController.swift
//  ACRecorderDemo
//
//  Created by Albert Chu on 2016/11/1.
//  Copyright © 2016年 ACSoft. All rights reserved.
//

import UIKit

import AVFoundation

import CoreData


class SoundListViewController: UITableViewController, SoudItemCellPlayButtonProtocol, NSFetchedResultsControllerDelegate, AVAudioPlayerDelegate {
    
    
    lazy var fetchedResultsController:NSFetchedResultsController<ACSoundItem> = {
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        
        let managedContext = appDelegate?.persistentContainer.viewContext
        managedContext?.automaticallyMergesChangesFromParent = true
        
        let fetchRequest =  NSFetchRequest<ACSoundItem>(entityName: "ACSoundItem")
        
        let primarySortDescriptor = NSSortDescriptor(key: "createdAt", ascending: false)
        fetchRequest.sortDescriptors = [primarySortDescriptor]
        
        let resultsController = NSFetchedResultsController<ACSoundItem>(fetchRequest: fetchRequest, managedObjectContext: managedContext!, sectionNameKeyPath: nil, cacheName: nil)
        
        resultsController.delegate = self
        
        return resultsController
    }()

    
    open var currentPlayingFileName: String = ""
    
    var currentPlayingItem: ACSoundItem?
    
    var audioPlayer: AVAudioPlayer?
    
    
    // MARK: viewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        self.configView()
    }
    
    // MARK: Table view delegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView .deselectRow(at: indexPath, animated: true)
        
        if ((self.currentPlayingItem) != nil) {
            let currentPlayingIndexPath: IndexPath = self.fetchedResultsController.indexPath(forObject: self.currentPlayingItem!)!
            if (currentPlayingIndexPath == indexPath){
                self.update(self.currentPlayingItem!, to: false)
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100

    }

    // MARK: Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let sections = self.fetchedResultsController.sections {
            let currentSection = sections[section]
            return currentSection.numberOfObjects
        }
        return 0
    }
    
    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "SoundItemTableViewCell", for: indexPath) as! SoundItemTableViewCell

        cell.bind(delegate: self)
        
        configureCell(cell, indexPath: indexPath)
        
        return cell
    }
    
    func configureCell(_ cell: UITableViewCell, indexPath: IndexPath) {
        let soundItem = self.fetchedResultsController.object(at: indexPath)
        
        if cell is SoundItemTableViewCell {
            let soundItemCell: SoundItemTableViewCell = cell as! SoundItemTableViewCell
            soundItemCell.configCell(soundItem: soundItem)
        }
    }
    
    func playButton(tappedAt cell: SoundItemTableViewCell) {
        let indexPath: IndexPath = self.tableView.indexPath(for: cell)!
        let soundItem = self.fetchedResultsController.object(at: indexPath)
        
        if soundItem != self.currentPlayingItem {
            if (self.currentPlayingItem != nil) {
                self.update(self.currentPlayingItem!, to: false)
            }
            self.update(soundItem, to: true)
            self.playFileBy(soundItem)
        }
    }
    
    // MARK: NSFetchedResultsControllerDelegate
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }

    @objc(controller:didChangeObject:atIndexPath:forChangeType:newIndexPath:) func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch (type) {
        case .insert:
            if let indexPath = newIndexPath {
                tableView.insertRows(at: [indexPath], with: .fade)
            }
            break;
        case .delete:
            if let indexPath = indexPath {
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
            break;
        case .update:
            if let indexPath = indexPath {
                if let cell = tableView.cellForRow(at: indexPath) {
                    configureCell(cell, indexPath: indexPath)
                }
            }
            break;
        case .move:
            if let indexPath = indexPath {
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
            
            if let newIndexPath = newIndexPath {
                tableView.insertRows(at: [newIndexPath], with: .fade)
            }
            break;
        }
    }

    
    // MARK: AVAudioPlayer Delegate
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        //You can stop the audio
        if ((self.currentPlayingItem) != nil) {
            self.update(self.currentPlayingItem!, to: false)
        }
    }
    
    // MARK: private
    func configView() {
        self.title = "sound list"
        self.view.backgroundColor = UIColor.white
        
        let nibName = UINib(nibName: "SoundItemTableViewCell", bundle:nil)
        self.tableView.register(nibName, forCellReuseIdentifier: "SoundItemTableViewCell")
        
        do {
            try self.fetchedResultsController.performFetch()
        } catch {
            print("An error occurred")
        }

    }
    
    func update(_ soundItem:ACSoundItem, to state: Bool) {
        if !state {
            self.currentPlayingItem = nil
            self.audioPlayer?.stop()
        }
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        appDelegate.persistentContainer.performBackgroundTask { (managedContext) in
            soundItem.isPlaying = state
            do {
                try managedContext.save()
            } catch let error as NSError {
                print("Could not save. \(error), \(error.userInfo)")
            }
            
            DispatchQueue.main.async {
                let indexPath: IndexPath = self.fetchedResultsController.indexPath(forObject: soundItem)!
                self.tableView.reloadRows(at: [indexPath], with: UITableViewRowAnimation.fade)
            }
        }

    }
    
    func playFileBy(_ soundItem:ACSoundItem) -> Void {
        if !(soundItem.fileName!.isEmpty) {
            
            let soundURL = ACSoundFileManager.sharedInstance.urlBy(soundItem)
            if (soundURL != nil) {
                do {
                    let p = try AVAudioPlayer(contentsOf: soundURL!)
                    
                    self.audioPlayer = p
                    self.audioPlayer?.delegate = self
                    self.audioPlayer?.prepareToPlay()
                    self.audioPlayer?.play()
                    
                    self.currentPlayingItem = soundItem
                } catch let error as NSError {
                    print("Could not play. \(error), \(error.userInfo)")
                }
            }
            
        }
    }
    
}
