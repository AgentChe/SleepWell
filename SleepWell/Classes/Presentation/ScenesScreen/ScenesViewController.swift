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
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    private func setupUI() {
        collectionView.register(UINib(nibName: "SceneImageCell", bundle: nil), forCellWithReuseIdentifier: "SceneImageCell")
        collectionView.register(SceneVideoCell.self, forCellWithReuseIdentifier: "SceneVideoCell")
        collectionView.infiniteLayout.itemSize = UIScreen.main.bounds.size
        collectionView.infiniteLayout.minimumLineSpacing = 0
        collectionView.velocityMultiplier = 1
        collectionView.isItemPagingEnabled = true
        let imageEdgeInsets = UIEdgeInsets(
            top: 26.5,
            left: 28.5,
            bottom: 26.5,
            right: 28.5
        )
        pauseButton.imageEdgeInsets = imageEdgeInsets
        playButton.imageEdgeInsets = imageEdgeInsets
        
        let settingsInsets = UIEdgeInsets(
            top: 23.31,
            left: 20.875,
            bottom: 23.31,
            right: 20.875
        )
        settingsButton.imageEdgeInsets = settingsInsets
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
    
    @objc func didBecomeActive() {}
    
    func bind(to viewModel: ScenesViewModelInterface, with input: Input) -> Output {
        AmplitudeAnalytics.shared.log(with: .sceneScr)
        
        let elements = viewModel.elements(subscription: input.subscription)

        let modelSelected = collectionView.rx.modelCentered(SceneCellModel.self)
            .compactMap { $0?.fields }

        let visibleCellSignal = collectionView.rx.itemCentered
            .compactMap { $0?.row }
            .distinctUntilChanged()
            .share(replay: 1, scope: .whileConnected)
        
        let _didBecomeActive = rx.methodInvoked(#selector(didBecomeActive))
            .map { _ in () }
            .asSignal(onErrorSignalWith: .empty())
        
        elements
            .drive(collectionView.rx.items(infinite: true)) { collection, index, item in
                switch item {
                case .image(let fields):
                    let cell = collection.dequeueReusableCell(
                        withReuseIdentifier: "SceneImageCell",
                        for: IndexPath(row: index, section: 0)
                    ) as! SceneImageCell
                    cell.setup(model: fields)
                    return cell
                case .video(let fields):
                    let cell = collection.dequeueReusableCell(
                        withReuseIdentifier: "SceneVideoCell",
                        for: IndexPath(row: index, section: 0)
                    ) as! SceneVideoCell
                    cell.setup(model: fields, didBecomeActive: _didBecomeActive)
                    return cell
                }
            }
            .disposed(by: disposeBag)
        
        let sceneAction = modelSelected
            .flatMapLatest { scene -> Signal<ScenesViewModel.Action> in
                viewModel.sceneDetails(scene: scene)
            }
        
        let cellIndex = visibleCellSignal
            .scan((0, 0)) { ($0.1, $1) }

        input.subscription
            .filter { !$0 }
            .withLatestFrom(cellIndex)
            .compactMap { tuple -> Int? in
                let (last, new) = tuple
                guard new > 0 else {
                    return nil
                }
                return abs(last - new) == 1 ? last : 0
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
                guard case .paygate = $0 else { return false  }
                return true
            }
            .map { _ in MainRoute.paygate }
            .do(onNext: { _ in AmplitudeAnalytics.shared.log(with: .blockedScenePaygateScr) })
            .asSignal(onErrorJustReturn: .paygate)
        
        let sceneDetail = sceneAction.map { $0.sceneDetail }
            .asDriver(onErrorDriveWith: .empty())
        
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
        
        let loadedVideo = BehaviorRelay<Set<Int>>(value: Set<Int>())
        
        sceneDetail.filter { $0?.scene.mime.isVideo == true }
            .map { $0! }
            .withLatestFrom(loadedVideo.asDriver()) { ($0, $1) }
            .filter { !$1.contains($0.scene.id) }
            .do(onNext: { scene, set in
                var set = set
                set.insert(scene.scene.id)
                loadedVideo.accept(set)
            })
            .map { [$0.0.scene.url] }
            .flatMap { viewModel.copy(url: $0).asSignal(onErrorSignalWith: .empty()) }
            .emit()
            .disposed(by: disposeBag)
        
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
            .withLatestFrom(viewModel.isScenePlaying) { ($0, $1) }
            .filter { $1 }
            .map { $0.0 }
            .asObservable()
        
        let playSceneByOpeningSettings = settingsButton.rx.tap.asObservable()
            .withLatestFrom(sceneDetail.asObservable())
            .filter { $0 != nil }
            .map { $0! }
            .flatMapLatest { scene in
                viewModel.isPlaying(scene: scene)
                    .take(1)
                    .map { (scene, $0) }
            }
            .filter { !$1 }
            .map { $0.0 }
        
        let didTapPlayScene = playButton.rx.tap.asObservable()
            .withLatestFrom(sceneDetail.asObservable())
            .filter { $0 != nil }
            .map { $0! }
        
        let shouldPlayScene = Observable
            .merge(
                initialScene.map { _ in true },
                playSceneBySwipe.map { _ in true },
                playSceneByOpeningSettings.map { _ in true },
                didTapPlayScene.map { _ in true },
                pauseButton.rx.tap.asObservable().map { _ in false }
            )
        
        let playScene = Observable
            .merge(
                initialScene,
                playSceneBySwipe.debounce(.seconds(1), scheduler: MainScheduler.instance),
                playSceneByOpeningSettings,
                didTapPlayScene
            )
        
        playScene
            .flatMapLatest { scene in
                viewModel.pauseScene(style: .force).map { _ in scene }
            }
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .background))
            .flatMapLatest { sceneDetail in
                viewModel.copy(url: sceneDetail.sounds.map { $0.soundUrl })
                    .map { _ in sceneDetail }
            }
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .background))
            .flatMapLatest {
                viewModel.add(sceneDetail: $0)
                    .andThen(Single.just(()))
            }
            .asSignal(onErrorSignalWith: .empty())
            .flatMapFirst { _ -> Signal<Void> in
                Signal.zip(
                    viewModel.pauseNoise(),
                    viewModel.pauseRecording(style: .force)
                ) { _, _ in () }
            }
            .withLatestFrom(shouldPlayScene.asSignal(onErrorSignalWith: .empty()))
            .flatMapLatest { shouldPlay in
                shouldPlay ? viewModel.playScene(style: .force) : .empty()
            }
            .emit()
            .disposed(by: disposeBag)
        
        pauseButton.rx.tap.asSignal()
            .map { _ in .force }
            .flatMapFirst { viewModel.pauseScene(style: $0) }
            .emit()
            .disposed(by: disposeBag)
        
        let isPlaying = viewModel.isScenePlaying
        
        let isPlayingBySwipe = Observable
            .merge(
                initialScene.map { _ in false },
                playSceneBySwipe.map { _ in true },
                playSceneByOpeningSettings.map { _ in false },
                didTapPlayScene.map { _ in false },
                pauseButton.rx.tap.asObservable().map { _ in false }
            )
            .distinctUntilChanged()
            .asDriver(onErrorDriveWith: .empty())
        
        Driver
            .combineLatest(
                isPlaying,
                isPlayingBySwipe
            ) { $0 || $1 }
            .drive(Binder(self) { base, isPlaying in
                base.pauseButton.isHidden = !isPlaying
                base.playButton.isHidden = isPlaying
            })
            .disposed(by: disposeBag)
        
        let actions = Signal
            .merge(
                pauseButton.rx.tap.asSignal().do(onNext: { AmplitudeAnalytics.shared.log(with: .scenePlayPauseTap) }),
                playButton.rx.tap.asSignal().do(onNext: { AmplitudeAnalytics.shared.log(with: .scenePlayPauseTap) }),
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
                self.pauseButtonBottomConstraint.constant = CGFloat(-80)
                self.settingsButtonBottomConstraint.constant = CGFloat(-80)
                
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
                self.pauseButtonBottomConstraint.constant = CGFloat(108.5)
                self.settingsButtonBottomConstraint.constant = CGFloat(110.32)
                
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
