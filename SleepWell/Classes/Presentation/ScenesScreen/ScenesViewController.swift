//
//  ScenesViewController.swift
//  SleepWell
//
//  Created by Vitaliy Zagorodnov on 29/10/2019.
//  Copyright (c) 2019 Andrey Chernyshev. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

final class ScenesViewController: UIViewController {
    @IBOutlet private var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        collectionView.register(UINib(nibName: "SceneCell", bundle: nil), forCellWithReuseIdentifier: "SceneCell")
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = view.frame.size
        layout.minimumLineSpacing = 0
        layout.scrollDirection = .horizontal
        collectionView.delegate = self
        collectionView.collectionViewLayout = layout
        collectionView.isPagingEnabled = true
    }

    private let visibleCellIndex = PublishRelay<Int?>()
    private let disposeBag = DisposeBag()
}

extension ScenesViewController: BindsToViewModel {
    typealias ViewModel = ScenesViewModel
    typealias Input = Observable<Bool>
    typealias Output = Signal<MainRoute>

    static func make() -> ScenesViewController {
        let storyboard = UIStoryboard(name: "ScenesScreen", bundle: nil)
        return storyboard.instantiateViewController(withIdentifier: "ScenesViewController") as! ScenesViewController
    }
    
    func bind(to viewModel: ScenesViewModelInterface, with input: Input) -> Output {
        let elements = viewModel.elements(subscription: input)

        elements
            .drive(collectionView.rx.items) { collection, index, item in
                let cell = collection.dequeueReusableCell(withReuseIdentifier: "SceneCell", for: IndexPath(row: index, section: 0)) as! SceneCell
                cell.setup(model: item)
                return cell
            }
            .disposed(by: disposeBag)
        
        let sceneAction = visibleCellIndex
            .compactMap { $0 }
            .withLatestFrom(elements) { ($0, $1) }
            .flatMapLatest { index, scene -> Signal<ScenesViewModel.Action?> in
                guard index <= scene.count - 1 else {
                    return .empty()
                }
                
                return viewModel.sceneDetails(id: scene[index].id)
            }
        
        sceneAction
            .bind { detail in
                print(detail)
            }
            .disposed(by: disposeBag)
        
        let paygate = sceneAction
            .filter {
                guard case .paygate = $0 else {  return false  }
                return true
            }
            .map { _ in MainRoute.paygate }
            .asSignal(onErrorJustReturn: .paygate)

        return paygate
    }
}

extension ScenesViewController: UICollectionViewDelegate, UIScrollViewDelegate {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if let cell = collectionView.visibleCells.first {
            visibleCellIndex.accept(collectionView.indexPath(for: cell)?.row)
        }
    }
}
