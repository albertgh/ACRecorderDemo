//
//  SoundItemTableViewCell.swift
//  ACRecorderDemo
//
//  Created by Albert Chu on 2016/11/3.
//  Copyright © 2016年 ACSoft. All rights reserved.
//

import UIKit

// MARK: - Protocol
protocol SoudItemCellPlayButtonProtocol : class {    // 'class' means only class types can implement it
    func playButton(tappedAt cell: SoundItemTableViewCell) -> Void
}

class SoundItemTableViewCell: UITableViewCell {

    weak var delegate : SoudItemCellPlayButtonProtocol?
    
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var desLabel: UILabel!
    
    @IBAction func playButtonAction(_ sender: UIButton) {
        self.delegate?.playButton(tappedAt: self)
    }
    
    // MARK: view
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        self.playButton.setTitle("play", for: UIControlState())
        self.playButton.setTitleColor(UIColor.blue, for: UIControlState())
        self.selectionStyle = UITableViewCellSelectionStyle.none
    }
    
    // MARK: cell
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    override func prepareForReuse() {
        super.prepareForReuse()

        self.playButton.setTitle("play", for: UIControlState())
        self.playButton.setTitleColor(UIColor.blue, for: UIControlState())
    }
    
    // MARK: public
    public static func heightForCell() -> CGFloat {
        return 100
    }
    
    public func bind(delegate: SoudItemCellPlayButtonProtocol) {
        self.delegate = delegate
    }
    
    public func configCell(soundItem: ACSoundItem) {
        
        if soundItem.isPlaying {
            self.playButton.setTitle("playing", for: UIControlState())
            self.playButton.setTitleColor(UIColor.green, for: UIControlState())
        }
        else {
            self.playButton.setTitle("play", for: UIControlState())
            self.playButton.setTitleColor(UIColor.blue, for: UIControlState())
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd hh:mm:ss"
        let dateString = dateFormatter.string(from: soundItem.createdAt!)
        self.desLabel.text = dateString
        
    }

}
