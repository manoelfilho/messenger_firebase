//
//  ConversationTableViewCell.swift
//  Messenger
//
//  Created by Manoel Filho on 11/11/21.
//

import UIKit
import SDWebImage

class ConversationTableViewCell: UITableViewCell {
    
    static let identifier = "ConversationTableViewCell"
    
    private let userImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 30
        imageView.layer.masksToBounds = true
        return imageView
    }()
    
    private let userNameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .semibold)
        label.textColor = UIColor(named: "grey_color")
        return label
    }()

    private let userMessageLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .regular)
        label.textColor = UIColor(named: "grey_color")
        label.numberOfLines = 0
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?){
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.backgroundColor = UIColor(named: "bg_color_light")
        
        self.userImageView.layer.borderWidth = 5
        self.userImageView.layer.borderColor = UIColor(named: "yellow")?.cgColor
        
        contentView.addSubview(self.userImageView)
        contentView.addSubview(self.userNameLabel)
        contentView.addSubview(self.userMessageLabel)
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        userImageView.frame = CGRect(
            x: 10,
            y: 10,
            width: 60,
            height: 60
        )
        
        userNameLabel.frame = CGRect(
            x: userImageView.right + 10,
            y: 10,
            width: (contentView.width - 20) - userImageView.width,
            height: 30
        )
        
        userMessageLabel.frame = CGRect(
            x: userImageView.right + 10,
            y: userNameLabel.bottom + 0,
            width: (contentView.width - 20) - userImageView.width,
            height: 30
        )
        
    }
    
    public func configure(with model: Conversation){
        self.userMessageLabel.text = model.latestMessage.text
        self.userNameLabel.text = model.name
        
        let path = "images/\(model.otherUserEmail)_profile_picture.png"
        
        StorageManager.shared.donwloadUrl(for: path, completion: {[weak self] result in
            switch result {
                case .success(let url):
                DispatchQueue.main.async {
                    self?.userImageView.sd_setImage(with: url, completed: nil)
                }
                case .failure(let error):
                    print("Error ao buscar imagem do usuário na lista de msgs \(error)")
            }
        })
        
    }

}
