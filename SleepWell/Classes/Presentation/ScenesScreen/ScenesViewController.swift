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
import InfiniteLayout

final class ScenesViewController: UIViewController {
    @IBOutlet private var collectionView: RxInfiniteCollectionView!
    @IBOutlet weak var pauseButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var settingsButton: UIButton!
    @IBOutlet var tapGesture: UITapGestureRecognizer!
    @IBOutlet weak var pauseButtonBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var settingsButtonBottomConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        collectionView.register(UINib(nibName: "SceneCell", bundle: nil), forCellWithReuseIdentifier: "SceneCell")
        collectionView.infiniteLayout.itemSize = UIScreen.main.bounds.size
        collectionView.infiniteLayout.minimumLineSpacing = 0
        collectionView.velocityMultiplier = 1
        collectionView.isItemPagingEnabled = true
        let imageEdgeInsets = UIEdgeInsets(
            top: 3,
            left: 3,
            bottom: 3,
            right: 3
        )
        pauseButton.imageEdgeInsets = imageEdgeInsets
        playButton.imageEdgeInsets = imageEdgeInsets
    }

    private let disposeBag = DisposeBag()
}

extension ScenesViewController: BindsToViewModel {
    typealias ViewModel = ScenesViewModel
    typealias Output = Signal<MainRoute>
    
    struct Input {
        let subscription: Observable<Bool>
        let isMainScreen: Driver<Bool>
        let hideTabbarClosure: (Bool) -> Void
    }

    static func make() -> ScenesViewController {
        let storyboard = UIStoryboard(name: "ScenesScreen", bundle: nil)
        return storyboard.instantiateViewController(withIdentifier: "ScenesViewController") as! ScenesViewController
    }
    
    func bind(to viewModel: ScenesViewModelInterface, with input: Input) -> Output {
        let elements = viewModel.elements(subscription: input.subscription)

        let modelSelected = collectionView.rx.modelCentered(SceneCellModel.self)
            .compactMap { $0 }

        let visibleCellSignal = collectionView.rx.itemCentered
            .compactMap { $0?.row }
            .distinctUntilChanged()
            .share(replay: 1, scope: .whileConnected)
    
        elements
            .drive(collectionView.rx.items(infinite: true)) { collection, index, item in
                let cell = collection.dequeueReusableCell(withReuseIdentifier: "SceneCell", for: IndexPath(row: index, section: 0)) as! SceneCell
                cell.setup(model: item)
                return cell
            }
            .disposed(by: disposeBag)
        
        let sceneAction = modelSelected
            .flatMapLatest { scene -> Signal<ScenesViewModel.Action> in
                viewModel.sceneDetails(scene: scene)
            }
        
        input.subscription
            .filter { !$0 }
            .withLatestFrom(visibleCellSignal)
            .compactMap { index -> Int? in
                guard index > 0 else {
                    return nil
                }
                return index - 1
            }
            .bind(to: Binder(collectionView) {
                $0.scrollToItem(at: IndexPath(row: $1, section: 0), at: .centeredHorizontally, animated: true)
            })
            .disposed(by: disposeBag)
        
        let paygate = modelSelected
            .flatMapLatest { scene -> Signal<ScenesViewModel.Action> in
                return viewModel.sceneDetails(scene: scene)
            }
            .filter {
                guard case .paygate = $0 else {  return false  }
                return true
            }
            .map { _ in MainRoute.paygate }
            .asSignal(onErrorJustReturn: .paygate)
        
        let sceneDetail = sceneAction.map { $0.sceneDetail }
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
        
        let viewDidAppear = rx.methodInvoked(#selector(UIViewController.viewDidAppear))
            .take(1)
        
        let initialScene = Observable
            .combineLatest(
                viewDidAppear,
                sceneDetail.asObservable()
            ) { $1 }
            .take(1)
            .filter { $0 != nil }
            .map { $0! }
        
        let playSceneBySwipe = sceneDetail.skip(1)
            .filter { $0 != nil }
            .map { $0! }
            .filter { viewModel.isOtherScenePlaying(scene: $0) }
            .asObservable()
        
        let didTapPlayScene = playButton.rx.tap.asObservable()
            .withLatestFrom(sceneDetail.asObservable())
            .filter { $0 != nil }
            .map { $0! }
        
        Observable
            .merge(
                initialScene,
                playSceneBySwipe,
                didTapPlayScene
            )
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
        
        let isPlaying = viewModel.isScenePlaying
        
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
                viewDidAppear.map { _ in Action.appear }
                    .asSignal(onErrorSignalWith: .empty()),
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
            
        isExpanded.filter { $0 }
            .withLatestFrom(input.isMainScreen.asSignal(onErrorSignalWith: .empty())) { ($0, $1) }
            .filter { $1 }
            .map { $0.0 }
            .emit(to: Binder(self) { base, isExpanded in
                input.hideTabbarClosure(isExpanded)
                self.pauseButtonBottomConstraint.constant = CGFloat(-33)
                self.settingsButtonBottomConstraint.constant = CGFloat(-35)
                
                UIView.animate(withDuration: 0.5) {
                    self.view.layoutIfNeeded()
                }
            })
            .disposed(by: disposeBag)
        
        isExpanded.filter { !$0 }
            .withLatestFrom(isPlaying)
            .withLatestFrom(input.isMainScreen.asSignal(onErrorSignalWith: .empty())) { ($0, $1) }
            .filter { $1 }
            .map { $0.0 }
            .emit(to: Binder(self) { base, isPlaying in
                input.hideTabbarClosure(false)
                self.pauseButtonBottomConstraint.constant = CGFloat(116)
                self.settingsButtonBottomConstraint.constant = CGFloat(117)
                
                UIView.animate(withDuration: 0.5) {
                    self.view.layoutIfNeeded()
                }
            })
            .disposed(by: disposeBag)
        
        return paygate
    }
}

private extension ScenesViewController {
    
    enum Action {
        case backgroundTap
        case none
        case appear
    }
}
