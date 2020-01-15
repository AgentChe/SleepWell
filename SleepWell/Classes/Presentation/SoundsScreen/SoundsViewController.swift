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
    
    private let tapGesture = UITapGestureRecognizer()
    private let soundsListView = SoundsListView()
    private let closeButton = UIButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        closeButton.setImage(UIImage(named: "close_sounds"), for: .normal)
        soundsView.addGestureRecognizer(tapGesture)
    }
    
    private let sounds = BehaviorRelay<[Noise]>(value: [])
    private let disposeBag = DisposeBag()
}

extension SoundsViewController: BindsToViewModel {
    typealias ViewModel = SoundsViewModel
    
    struct Input {
        let hideTabbarClosure: (Bool) -> Void
    }

    static func make() -> SoundsViewController {
        let storyboard = UIStoryboard(name: "SoundsScreen", bundle: nil)
        return storyboard.instantiateViewController(withIdentifier: "SoundsViewController") as! SoundsViewController
    }
    
    func bind(to viewModel: SoundsViewModelInterface, with input: Input) -> () {
        let elements = viewModel.sounds()
        
        elements
            .drive(soundsListView.elements)
            .disposed(by: disposeBag)
        
        soundsListView
            .selectedItem
            .scan([]) { old, new in
                var result = old
                result.append(new)
                return result
            }
            .bind(to: sounds)
            .disposed(by: disposeBag)
        
        soundsListView
            .selectedItem
            .bind(to: soundsView.item)
            .disposed(by: disposeBag)
        
        let userAction = Observable<UserAction>
            .merge(
                soundsView.didTapAdd.asObservable().map { _ in .add },
                addSoundButton.rx.tap.map { _ in .add },
                closeButton.rx.tap.map { _ in .close },
                soundsListView.selectedItem.map { _ in .close }
            )
        
        let didUserAction = userAction
            .map { action -> Bool in
                guard case .add = action else { return false }
                return true
            }
        
        Observable.merge(soundsView.didMovingView.asObservable().filter { $0 }, didUserAction)
            .bind(onNext: input.hideTabbarClosure)
            .disposed(by: disposeBag)
        
        userAction
            .withLatestFrom(sounds) { ($0, $1) }
            .bind(to: Binder(self) { base, elements in
                base.showSoundsList(action: elements.0, isEmpty: elements.1.isEmpty)
            })
            .disposed(by: disposeBag)
        
        let noiseSounds = soundsListView
            .selectedItem
            .map { $0.sounds }
            .scan(Set<NoiseSound>()) { $0.union($1) }
        
        noiseSounds
            .scan(Set<NoiseSound>()) { $0.union($1) }
            .flatMap(viewModel.add)
            .subscribe()
            .disposed(by: disposeBag)
        
        soundsView.changeVolume
            .emit(to: viewModel.noiseVolume)
            .disposed(by: disposeBag)
        
        let loadedSounds = BehaviorRelay<Set<Int>>(value: Set<Int>())
        
        noiseSounds
            .withLatestFrom(loadedSounds.asDriver()) { ($0, $1) }
            .map { noises, loaded -> ([NoiseSound], Set<Int>)  in
                
                let ids = Set(noises.map { $0.id }).subtracting(loaded)
                return (noises.filter { ids.contains($0.id) }, loaded)
            }
            .do(onNext: { noises, loaded in
                loadedSounds.accept(loaded.union(noises.map { $0.id }))
            })
            .map { $0.0.map { $0.soundUrl } }
            .flatMap(viewModel.copy)
            .subscribe()
            .disposed(by: disposeBag)
    }
}

private extension SoundsViewController {
    
    enum UserAction {
        case add
        case close
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
