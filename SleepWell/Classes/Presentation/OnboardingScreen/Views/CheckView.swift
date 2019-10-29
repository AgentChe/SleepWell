//
//  CheckView.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 29/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import UIKit

class CheckView: UIView {
    var changedCheck: ((Bool) -> ())?
    
    @IBInspectable var isCheck: Bool = false {
        didSet {
            update()
        }
    }
    
    @IBInspectable var titleLocalizableKey: String = "" {
        didSet {
            label.text = titleLocalizableKey.localized
        }
    }
    
    @IBInspectable var title: String = "" {
        didSet {
             label.text = title
        }
    }
    
    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private lazy var label: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = UIFont(name: "Poppins-Regular", size: 17)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var selectedTitleColor = UIColor(red: 0.541, green: 0.498, blue: 0.525, alpha: 1)
    private lazy var unSelectedTitleColor = UIColor(red: 0.921, green: 0.898, blue: 0.917, alpha: 1)
    
    private lazy var selectedBackgroundColor = UIColor(red: 0.792, green: 0.760, blue: 0.756, alpha: 1)
    private lazy var unSelectedBackgroundColor = UIColor.clear
    
    private lazy var selectedImage = UIImage(named: "checked")
    private lazy var unSelectedImage = UIImage(named: "unchecked")
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        configure()
        addSubviews()
        update()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        configure()
        addSubviews()
        update()
    }
    
    private func configure() {
        borderWidth = 2
        borderColor = UIColor.white.withAlphaComponent(0.3)
        cornerRadius = 16
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapAction))
        addGestureRecognizer(tapGesture)
    }
    
    private func addSubviews() {
        addSubview(imageView)
        addSubview(label)
        
        imageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        imageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18).isActive = true
        imageView.widthAnchor.constraint(equalToConstant: 20).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: 20).isActive = true
        
        label.topAnchor.constraint(equalTo: topAnchor, constant: 14).isActive = true
        label.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 16).isActive = true
        label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16).isActive = true
        label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16).isActive = true
    }
    
    @objc private func tapAction() {
        isCheck = !isCheck
        changedCheck?(isCheck)
    }
    
    private func update() {
        backgroundColor = isCheck ? selectedBackgroundColor : unSelectedBackgroundColor
        imageView.image = isCheck ? selectedImage : unSelectedImage
        label.textColor = isCheck ? selectedTitleColor : unSelectedTitleColor
    }
}
