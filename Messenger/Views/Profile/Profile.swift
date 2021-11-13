//
//  Profile.swift
//  Messenger
//
//  Created by Manoel Filho on 03/11/21.
//

import UIKit

class Profile: UIView {

    @IBOutlet weak var image: UIImageView!
    @IBOutlet var contentView: UIView!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var email: UILabel!
    @IBOutlet weak var createdAt: UILabel!
    
    override init(frame: CGRect){
        super .init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder){
        super .init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit(){
        Bundle.main.loadNibNamed("Profile", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
    }

}
