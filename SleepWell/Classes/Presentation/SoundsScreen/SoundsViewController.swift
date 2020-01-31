//
//  SoundsViewController.swift
//  SleepWell
//
//  Created by Vitaliy Zagorodnov on 04/01/2020.
//  Copyright (c) 2020 Andrey Chernyshev. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

final class SoundsViewController: UIViewController {
    @IBOutlet private var addSoundButton: UIButton!
    @IBOutlet private var soundsView: ViewportView!
    @IBOutlet private var emptyView: UIView!
    
    private let soundsListView = SoundsListView()
    private let closeButton = UIButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        closeButton.setImage(UIImage(named: "close_sounds"), for: .normal)
    }
    
    private let sounds = BehaviorRelay<Set<Noise>>(value: [])
    private let disposeBag = DisposeBag()
}

extension SoundsViewController: BindsToViewModel {
    typealias ViewModel = SoundsViewModel
    typealias Output = Signal<MainRoute>
    
    struct Input {
        let isActiveSubscription: Observable<Bool>
        let isMainScreen: Driver<Bool>
        let hideTabbarClosure: (Bool) -> Void
    }

    static func make() -> SoundsViewController {
        let storyboard = UIStoryboard(name: "SoundsScreen", bundle: nil)
        return storyboard.instantiateViewController(withIdentifier: "SoundsViewController") as! SoundsViewController
    }
    
    func bind(to viewModel: SoundsViewModelInterface, with input: Input) -> Output {
        let elements = viewModel.sounds()
        
        let selectedCellModel = soundsListView
            .selectedItem
        
        let selectedNoise = selectedCellModel
            .filter { $0.paid }
            .map { $0.noise }
        
        Driver
            .combineLatest(elements,
                           input.isActiveSubscription.asDriver(onErrorDriveWith: .never()))
            .drive(onNext: { [weak self] stub in
                let (noiseCategories, isActiveSubscription) = stub
                
                self?.soundsListView.setup(noiseCategories: noiseCategories, isActiveSubscription: isActiveSubscription)
            })
            .disposed(by: disposeBag)
        
        let addSound = selectedNoise.map { NoiseAction.add($0) }
        let deleteSound = soundsView.deletedSound.map { NoiseAction.delete($0) }
        
        Observable<NoiseAction>
            .merge(addSound, deleteSound)
            .scan([Noise]()) { old, action -> [Noise] in
                var result = old
                switch action {
                case let .add(noise):
                    result.append(noise)
                case let .delete(id):
                    result.removeAll(where: { $0.id == id })
                }
                return result
            }
            .map { Set($0) }
            .bind(to: sounds)
            .disposed(by: disposeBag)

        selectedNoise
            .bind(to: soundsView.item)
            .disposed(by: disposeBag)
        
        let userAction = Observable<UserAction>
            .merge(
                soundsView.didTapAdd.asObservable().map { _ in .add },
                addSoundButton.rx.tap.map { _ in .add },
                closeButton.rx.tap.map { _ in .close },
                selectedNoise.map { _ in .close }
            )
        
        let emptyViewTap = UITapGestureRecognizer()
        emptyView.addGestureRecognizer(emptyViewTap)
        let showTabbarByTapOnEmptyView = emptyViewTap.rx.event.asSignal().map { _ in false }
        let hideTabbarByTimeout = Signal
            .merge(
                input.isMainScreen.asSignal(onErrorSignalWith: .empty()),
                showTabbarByTapOnEmptyView,
                soundsView.didTapAdd.asSignal().map { _ in false },
                addSoundButton.rx.tap.asSignal().map { _ in false }
            )
            .withLatestFrom(userAction.asSignal(onErrorSignalWith: .empty()).startWith(.close)) { ($0, $1) }
            .filter { $0.1 != .add }
            .map { $0.0 }
            .filter { $0 }
            .debounce(.seconds(2))
        
        let showSoundsList = userAction
            .filter { $0 == .add }
        
        Signal
            .merge(
                hideTabbarByTimeout.asSignal(),
                soundsView.didMovingView.asSignal().filter { $0 },
                showTabbarByTapOnEmptyView,
                showSoundsList.asSignal(onErrorSignalWith: .empty()).map { _ in false },
                soundsView.didTap.map { _ in false }
            )
            .distinctUntilChanged()
            .withLatestFrom(input.isMainScreen.asSignal(onErrorSignalWith: .empty())) { ($0, $1) }
            .filter { $0.1 }
            .map { $0.0 }
            .emit(onNext: input.hideTabbarClosure)
            .disposed(by: disposeBag)
        
        userAction
            .withLatestFrom(sounds) { ($0, $1) }
            .bind(to: Binder(self) { base, elements in
                base.showSoundsList(action: elements.0, isEmpty: elements.1.isEmpty)
            })
            .disposed(by: disposeBag)
        
        let noiseSounds = sounds
            .map { sounds -> Set<NoiseSound> in
                return sounds
                    .map { $0.sounds }
                    .reduce(Set<NoiseSound>()) { $0.union($1) }
            }
            .share(replay: 1, scope: .forever)
        
        Driver
            .combineLatest(
                input.isMainScreen,
                noiseSounds.asDriver(onErrorDriveWith: .empty())
            ) { ($0, $1) }
            .filter { $0 && !$1.isEmpty }
            .flatMapFirst { _ in
                Signal
                    .zip(
                        viewModel.pauseScene(style: .force),
                        viewModel.pauseRecording(style: .force)
                    ) { _, _ in () }
            }
            .emit(to: viewModel.playNoise)
            .disposed(by: disposeBag)
        
        soundsView.changeVolume
            .emit(to: viewModel.noiseVolume)
            .disposed(by: disposeBag)
        
        let loadableSounds = BehaviorRelay<Set<Int>>(value: Set<Int>())
        let loadedSounds = BehaviorRelay<Set<Int>>(value: Set<Int>())
        
        //массив с id загружающихся звуков
        Driver
            .combineLatest(
                noiseSounds.map { Set($0.map { $0.id }) }.asDriver(onErrorDriveWith: .empty()),
                loadableSounds.asDriver()
            ) { Array($0.intersection($1)) }
            .distinctUntilChanged()
            .drive(soundsView.loadingSounds)
            .disposed(by: disposeBag)
        
        noiseSounds
            .withLatestFrom(loadableSounds.asDriver()) { ($0, $1) }
            .withLatestFrom(loadedSounds.asDriver()) { ($0.0, $0.1, $1) }
            .map { noises, loadable, loaded -> ([NoiseSound], Set<Int>)  in
                
                let ids = Set(noises.map { $0.id }).subtracting(loadable)
                    .subtracting(loaded)
                return (noises.filter { ids.contains($0.id) }, loadable)
            }
            .do(onNext: { noises, loadable in
                loadableSounds.accept(loadable.union(noises.map { $0.id }))
            })
            .flatMap { tuple in
                viewModel.copy(url: tuple.0.map { $0.soundUrl })
                    .map { _ in tuple.0.map { $0.id } }
            }
            .withLatestFrom(loadedSounds.asDriver()) { $1.union($0) }
            .asSignal(onErrorSignalWith: .empty())
            .emit(to: loadedSounds)
            .disposed(by: disposeBag)
        
        loadedSounds.asDriver()
            .withLatestFrom(loadableSounds.asDriver()) { $1.subtracting($0) }
            .drive(loadableSounds)
            .disposed(by: disposeBag)
        
        Driver
            .combineLatest(
                noiseSounds.asDriver(onErrorDriveWith: .empty()),
                loadedSounds.asDriver()
            ) { noises, loaded in
                noises.filter { loaded.contains($0.id) }
            }
            .distinctUntilChanged()
            .flatMap { viewModel.add(noises: $0).asDriver(onErrorDriveWith: .empty()) }
            .drive()
            .disposed(by: disposeBag)
        
        soundsView
            .didTapSleepTimer
            .emit(onNext: { viewModel.showSleepTimerScreen() })
            .disposed(by: disposeBag)
        
        return selectedCellModel
            .filter { !$0.paid }
            .map { _ in MainRoute.paygate }
            .asSignal(onErrorSignalWith: .never())
    }
}

private extension SoundsViewController {
    
    enum UserAction {
        case add
        case close
    }
    
    enum NoiseAction {
        case add(Noise)
        case delete(Int)
    }
    
    func showSoundsList(action: UserAction, isEmpty: Bool) {
        soundsView.isHidden = isEmpty
        emptyView.isHidden = !isEmpty
        switch action {
        case .add:
            soundsListView.frame = view.frame
            closeButton.frame = CGRect(origin: CGPoint(x: view.frame.width - 50.18, y: 50), size: CGSize(width: 32, height: 32))
            closeButton.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
            view.addSubview(soundsListView)
            view.addSubview(closeButton)
            let originY = view.frame.origin.y + 88
            soundsListView.frame.size.height -= 88
            soundsListView.frame.origin.y += view.frame.height

            UIView.animate(withDuration: 0.5) {
                self.soundsListView.frame.origin.y = originY
                self.closeButton.transform = .identity
                if isEmpty {
                    self.emptyView.transform = CGAffineTransform(translationX: 0, y: -self.view.frame.height)
                    self.addSoundButton.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
                } else {
                    self.soundsView.transform = CGAffineTransform(translationX: 0, y: -self.view.frame.height)
                }
            }
            
        case .close:
            UIView.animate(withDuration: 0.5, animations: {
                self.closeButton.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
                self.soundsListView.frame.origin.y += self.view.frame.height
                if isEmpty {
                    self.emptyView.transform = .identity
                    self.addSoundButton.transform = .identity
                } else {
                    self.soundsView.transform = .identity
                }
            }) { _ in
                self.closeButton.transform = .identity
                self.closeButton.removeFromSuperview()
                self.soundsListView.removeFromSuperview()
            }
        }
    }
}
