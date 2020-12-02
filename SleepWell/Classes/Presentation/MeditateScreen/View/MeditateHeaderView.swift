//
//  MeditateHeaderView.swift
//  SleepWell
//
//  Created by Vitaliy Zagorodnov on 26/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

final class MeditateHeaderView: UIView {

    @IBOutlet fileprivate var titleView: HeaderTitleView!
    @IBOutlet fileprivate var collectionView: UICollectionView!
    @IBOutlet private var conteinerView: UIView!
    @IBOutlet private var flowLayout: UICollectionViewFlowLayout!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initialize()
    }
    
    private func initialize() {
        UINib(nibName: "MeditateHeaderView", bundle: nil).instantiate(withOwner: self, options: nil)
        conteinerView.frame = bounds
        addSubview(conteinerView)

        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(UINib(nibName: "MeditateTagCell", bundle: nil), forCellWithReuseIdentifier: "MeditateTagCell")
        flowLayout.estimatedItemSize = CGSize(width: 100, height: 30)
        collectionView.contentInset = UIEdgeInsets(top: 20, left: .zero, bottom: 20, right: .zero)
        
    }
    
    func setup(title: String, subtitle: String) {
        titleView.setup(title: title, subtitle: subtitle)
    }
    
    fileprivate var _elements: [TagCellModel] = []
    fileprivate let didTapCell = BehaviorRelay<Int?>(value: nil)
}

extension MeditateHeaderView {
    var selectTag: Signal<Int?> {
        return didTapCell.asSignal(onErrorJustReturn: nil)
    }
    
    var didTapMenu: Signal<Void> {
        titleView.menuButton.rx.tap.asSignal()
    }
}

extension MeditateHeaderView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        SDKStorage.shared
            .amplitudeManager
            .logEvent(name: "Tag tap", parameters: [:])
        
        didTapCell.accept(_elements[indexPath.row].id)
    }
    
}

extension MeditateHeaderView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return _elements.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MeditateTagCell", for: indexPath) as! MeditateTagCell
        cell.setup(model: _elements[indexPath.row])
        return cell
    }
    
}

extension Reactive where Base: MeditateHeaderView {
    var tags: Binder<[TagCellModel]> {
        return Binder(base) { base, elements in
            base._elements = elements
            base.collectionView.reloadData()
        }
    }
}
