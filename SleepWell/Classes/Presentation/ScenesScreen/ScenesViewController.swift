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
    @IBOutlet weak var pauseButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var settingsButton: UIButton!
    @IBOutlet var tapGesture: UITapGestureRecognizer!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    
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
        collectionView.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMinXMaxYCorner]
        let imageEdgeInsets = UIEdgeInsets(
            top: 2.5,
            left: 2.5,
            bottom: 2.5,
            right: 2.5
        )
        pauseButton.imageEdgeInsets = imageEdgeInsets
        playButton.imageEdgeInsets = imageEdgeInsets
    }

    private let visibleCellIndex = BehaviorRelay<Int?>(value: 0)
    private let disposeBag = DisposeBag()
}

extension ScenesViewController: BindsToViewModel {
    typealias ViewModel = ScenesViewModel
    typealias Output = Signal<MainRoute>
    
    struct Input {
        let subscription: Observable<Bool>
        let isMainScreen: Signal<Bool>
        let hideTabbarClosure: (Bool) -> Void
    }

    static func make() -> ScenesViewController {
        let storyboard = UIStoryboard(name: "ScenesScreen", bundle: nil)
        return storyboard.instantiateViewController(withIdentifier: "ScenesViewController") as! ScenesViewController
    }
    
    func bind(to viewModel: ScenesViewModelInterface, with input: Input) -> Output {
        let elements = viewModel.elements(subscription: input.subscription)

        elements
            .drive(collectionView.rx.items) { collection, index, item in
                let cell = collection.dequeueReusableCell(withReuseIdentifier: "SceneCell", for: IndexPath(row: index, section: 0)) as! SceneCell
                cell.setup(model: item)
                return cell
            }
            .disposed(by: disposeBag)
        
        let sceneAction = Driver
            .combineLatest(
                visibleCellIndex.compactMap { $0 }
                    .asDriver(onErrorDriveWith: .empty()),
                elements
            )
            .flatMapLatest { index, scene -> Signal<ScenesViewModel.Action?> in
                guard index <= scene.count - 1 else {
                    return .empty()
                }
                
                return viewModel.sceneDetails(id: scene[index].id)
            }
        
//        sceneAction
//            .bind { detail in
//                print(detail)
//            }
//            .disposed(by: disposeBag)
        
        let paygate = visibleCellIndex.compactMap { $0 }
            .withLatestFrom(elements) { ($0, $1) }
            .flatMapLatest { index, scene -> Signal<ScenesViewModel.Action?> in
                guard index <= scene.count - 1 else {
                    return .empty()
                }
                
                return viewModel.sceneDetails(id: scene[index].id)
            }
            .filter {
                guard case .paygate = $0 else {  return false  }
                return true
            }
            .map { _ in MainRoute.paygate }
            .asSignal(onErrorJustReturn: .paygate)
        
        let sceneDetail = sceneAction.map { $0?.sceneDetail }
            .asSignal(onErrorSignalWith: .empty())
        
        let didDismissSetting = settingsButton.rx.tap.asSignal()
            .withLatestFrom(sceneDetail)
            .filter { $0 != nil }
            .map { $0! }
            .do(onNext: { _ in
                input.hideTabbarClosure(true)
            })
            .flatMapLatest {
                viewModel.showSettings(sceneDetail: $0)
            }
        
        playButton.rx.tap.asObservable()
            .withLatestFrom(sceneDetail.asObservable())
            .filter { $0 != nil }
            .map { $0! }
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .background))
            .do(onNext: {
                viewModel.add(sceneDetail: $0)
            })
            .map { _ in () }
            .asSignal(onErrorSignalWith: .empty())
            .emit(to: viewModel.playScene)
            .disposed(by: disposeBag)
        
        pauseButton.rx.tap.asSignal()
            .emit(to: viewModel.pauseScene)
            .disposed(by: disposeBag)
        
        let isPlaying = sceneAction.map { $0?.sceneDetail }
            .flatMapLatest { scene -> Driver<Bool> in
                guard let scene = scene else {
                    return .just(false)
                }
                return viewModel.isPlaying(scene: scene)
            }
            .distinctUntilChanged()
            .asDriver(onErrorDriveWith: .empty())
            
        isPlaying
            .drive(Binder(self) { base, isPlaying in
                base.pauseButton.isHidden = !isPlaying
                base.playButton.isHidden = isPlaying
            })
            .disposed(by: disposeBag)
        
        let actions = Signal
            .merge(
                pauseButton.rx.tap.asSignal(),
                playButton.rx.tap.asSignal(),
                settingsButton.rx.tap.asSignal(),
                tapGesture.rx.event.asSignal()
                    .map { _ in () },
                rx.methodInvoked(#selector(UIViewController.viewDidAppear))
                    .asSignal(onErrorSignalWith: .empty())
                    .map { _ in () },
                didDismissSetting.map { _ in () }
            )
            .startWith(())
        
        let isExpanded = Signal
            .merge(
                actions.debounce(.seconds(5))
                    .map { _ in Action.none },
                tapGesture.rx.event.asSignal()
                    .map { _ in Action.backgroundTap },
                rx.methodInvoked(#selector(UIViewController.viewDidAppear))
                    .asSignal(onErrorSignalWith: .empty())
                    .map { _ in Action.appear },
                didDismissSetting.map { _ in Action.appear }
            )
            .withLatestFrom(input.isMainScreen.asSignal(onErrorSignalWith: .empty())) {
                (action: $0, isMain: $1)
            }
            .scan(false) { state, tuple in
                guard tuple.isMain else {
                    return false
                }
                switch tuple.action {
                case .appear:
                    return false
                case .none:
                    return true
                case .backgroundTap:
                    return !state
                }
            }
            .distinctUntilChanged()
            
        isExpanded.filter { $0 }
            .emit(to: Binder(self) { base, isExpanded in
                input.hideTabbarClosure(isExpanded)
                
                UIView.animate(
                    withDuration: 0.8,
                    animations: {
                        base.bottomConstraint.constant = 0
                        base.collectionView.cornerRadius = 0
                        
                        self.pauseButton.isHidden = true
                        self.playButton.isHidden = true
                        self.settingsButton.isHidden = true
                    }
                )
            })
            .disposed(by: disposeBag)
        
        isExpanded.filter { !$0 }
            .withLatestFrom(isPlaying)
            .emit(to: Binder(self) { base, isPlaying in
                input.hideTabbarClosure(false)
                
                UIView.animate(
                    withDuration: 0.8,
                    animations: {
                        base.bottomConstraint.constant = GlobalDefinitions.tabBarHeight
                        base.collectionView.cornerRadius = 40
                        
                        if isPlaying {
                            self.pauseButton.isHidden = false
                        } else {
                            self.playButton.isHidden = false
                        }
                        
                        self.settingsButton.isHidden = false
                    }
                )
            })
            .disposed(by: disposeBag)
        
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

private extension ScenesViewController {
    
    enum Action {
        case backgroundTap
        case none
        case appear
    }
}
