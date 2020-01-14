//
//  SoundGroupView.swift
//  SleepWell
//
//  Created by Vitaliy Zagorodnov on 04/01/2020.
//  Copyright © 2020 Andrey Chernyshev. All rights reserved.
//

import UIKit

final class SoundGroupView: UIView {

    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var collectionView: UICollectionView!
    @IBOutlet private var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet private var conteinerView: UIView!
    
    var selectedItem: ((Noise) -> Void)?
    
    override init(frame: CGRect) {
           super.init(frame: frame)
           initialize()
       }
       
       required init?(coder: NSCoder) {
           super.init(coder: coder)
           initialize()
       }
    
    private func initialize() {
        UINib(nibName: "SoundGroupView", bundle: nil).instantiate(withOwner: self, options: nil)
        conteinerView.frame = bounds
        addSubview(conteinerView)

        collectionView.register(UINib(nibName: "SoundCell", bundle: nil), forCellWithReuseIdentifier: "SoundCell")
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        collectionView.delegate = self
        collectionView.dataSource = self
        flowLayout.minimumLineSpacing = 40
    }
    
    func setup(model: NoiseCategory) {
        titleLabel.text = model.name
        elements = model.noises
        collectionView.reloadData()
    }
    
    private var elements: [Noise] = []
}

extension SoundGroupView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedItem?(elements[indexPath.row])
    }
}

extension SoundGroupView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return elements.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SoundCell", for: indexPath) as! SoundCell
        let element = elements[indexPath.row]
        cell.setup(image: element.imageUrl, title: element.name)
        return cell
    }
}

extension SoundGroupView: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 76, height: 120)
    }
}
