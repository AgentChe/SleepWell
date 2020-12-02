//
//  StoriesViewController.swift
//  SleepWell
//
//  Created by Vitaliy Zagorodnov on 28/10/2019.
//  Copyright (c) 2019 Andrey Chernyshev. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

final class StoriesViewController: UIViewController {
    @IBOutlet private var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        tableView.register(UINib(nibName: "StoryCell", bundle: nil), forCellReuseIdentifier: "StoryCell")
        tableView.register(UINib(nibName: "PremiumUnlockCell", bundle: nil), forCellReuseIdentifier: "PremiumUnlockCell")

        var tableHeaderFrame = tableHeaderView.frame
        tableHeaderFrame.size.width = tableView.frame.size.width
        tableHeaderView.frame = tableHeaderFrame
        
        tableHeaderView.setNeedsLayout()
        tableHeaderView.layoutIfNeeded()
        
        let height = tableHeaderView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
        
        var tableHeaderUpdatedFrame = tableHeaderView.frame
        tableHeaderUpdatedFrame.size.height = height
        
        tableHeaderView.frame = tableHeaderUpdatedFrame
        
        tableHeaderView.setup(title: "Stories", subtitle: "stories_subtitle".localized)
        tableView.tableHeaderView = tableHeaderView
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: GlobalDefinitions.tableBottomInsert, right: 0)
    }

    private let tableHeaderView = StoriesHeaderView()
    private let disposeBag = DisposeBag()
}

extension StoriesViewController: BindsToViewModel {
    typealias ViewModel = StoriesViewModel
    struct Input {
        let subscription: Observable<Bool>
        let scrollToTop: Signal<Void>
    }
    typealias Output = Signal<MainRoute>

    static func make() -> StoriesViewController {
        let storyboard = UIStoryboard(name: "StoriesScreen", bundle: nil)
        return storyboard.instantiateViewController(withIdentifier: "StoriesViewController") as! StoriesViewController
    }
    
    func bind(to viewModel: StoriesViewModelInterface, with input: Input) -> Output {
        SDKStorage.shared
            .amplitudeManager
            .logEvent(name: "Stories scr", parameters: [:])
        
        input.scrollToTop.emit(to: tableView.rx.scrollToTop)
            .disposed(by: disposeBag)
        
        let elements = viewModel.elements(subscription: input.subscription)

        elements
            .drive(tableView.rx.items) { table, index, item in
                switch item {
                case let .story(element):
                    let cell = table.dequeueReusableCell(withIdentifier: "StoryCell") as! StoryCell
                    cell.setup(model: element)
                    return cell
                case .premiumUnlock:
                    let cell = table.dequeueReusableCell(withIdentifier: "PremiumUnlockCell") as! PremiumUnlockCell
                    return cell
                }
            }
            .disposed(by: disposeBag)
        
        tableHeaderView.didTapMenu
            .emit(onNext: { [weak self] in
                let vc = SettingsViewController()
                vc.modalPresentationStyle = .overFullScreen
                self?.present(vc, animated: false)
            })
            .disposed(by: disposeBag)

        let randomElement = tableHeaderView.didTapRandom
            .withLatestFrom(elements)
            .flatMapFirst { viewModel.randomElement(items: $0) }
        
       return Signal
        .merge(
            randomElement.map { ($0, 1) },
            tableView.rx.modelSelected(StoriesCellType.self).asSignal().map { ($0, 2) }
        )
        .flatMapFirst { stub -> Signal<MainRoute> in
            let (cellType, id) = stub
            
            guard case let .story(story) = cellType else {
                SDKStorage.shared
                    .amplitudeManager
                    .logEvent(name: "Unlock premium stories paygate scr", parameters: [:])
                
                return Signal.just(.paygate(.stories))
            }
            
            return viewModel
                .getStoryDetails(id: story.id, subscription: input.subscription)
                .map { action -> MainRoute in
                    switch action {
                    case .paygate:
                        if id == 1 {
                            SDKStorage.shared
                                .amplitudeManager
                                .logEvent(name: "Blocked random story paygate scr", parameters: [:])
                        }
                        if id == 2 {
                            SDKStorage.shared
                                .amplitudeManager
                                .logEvent(name: "Blocked story paygate scr", parameters: [:])
                        }
                        return .paygate(.stories)
                    case let .detail(detail):
                        guard let recording = detail else {
                            assertionFailure(" ⚠️ Пустая запись ⚠️")
                            return .paygate(.stories)
                        }
                        return .play(recording)
                    }
                }
        }
    }
}
