//
//  SettingsItemView.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 05/12/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import UIKit

class SettingsItemView: UIView {
    lazy var label: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy var arrowImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "arrow_right")
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    lazy var button: UIButton = {
        let button = UIButton()
        button.setTitle("", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    init() {
        super.init(frame: .zero)
        
        configure()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        configure()
    }
    
    private func configure() {
        backgroundColor = .clear
        translatesAutoresizingMaskIntoConstraints = false
        
        addSubviews()
    }
    
    fileprivate func addSubviews() {
        addSubview(label)
        addSubview(arrowImageView)
        addSubview(button)
        
        arrowImageView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        arrowImageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        arrowImageView.widthAnchor.constraint(equalToConstant: 8).isActive = true
        arrowImageView.heightAnchor.constraint(equalToConstant: 13).isActive = true
        
        label.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        label.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        label.trailingAnchor.constraint(equalTo: arrowImageView.leadingAnchor).isActive = true
        
        button.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        button.topAnchor.constraint(equalTo: topAnchor).isActive = true
        button.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        button.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
    }
}

class SettingsItemWithImageView: SettingsItemView {
    lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    override func addSubviews() {
        addSubview(label)
        addSubview(arrowImageView)
        addSubview(imageView)
        addSubview(button)
        
        arrowImageView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        arrowImageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        arrowImageView.widthAnchor.constraint(equalToConstant: 8).isActive = true
        arrowImageView.heightAnchor.constraint(equalToConstant: 13).isActive = true
        
        imageView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        imageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        imageView.widthAnchor.constraint(equalToConstant: 24).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: 24).isActive = true
        
        label.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 16).isActive = true
        label.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        label.trailingAnchor.constraint(equalTo: arrowImageView.leadingAnchor).isActive = true
        
        button.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        button.topAnchor.constraint(equalTo: topAnchor).isActive = true
        button.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        button.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
    }
}
