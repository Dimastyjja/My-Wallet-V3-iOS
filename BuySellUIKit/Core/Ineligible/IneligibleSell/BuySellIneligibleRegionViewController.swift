//
//  BuySellIneligibleRegionViewController.swift
//  BuySellUIKit
//
//  Created by Alex McGregor on 9/10/20.
//  Copyright © 2020 Blockchain Luxembourg S.A. All rights reserved.
//

import PlatformUIKit
import UIKit
import RxSwift

public final class BuySellIneligibleRegionViewController: UIViewController {
    
    // MARK: - Private Properties
    
    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let buttonView = ButtonView()
    private let outerStackView = UIStackView()
    private let innerStackView = UIStackView()
    
    private let presenter: BuySellIneligibleScreenPresenter
    private let disposeBag = DisposeBag()
    
    // MARK: - Setup
    
    init(presenter: BuySellIneligibleScreenPresenter) {
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    public override func loadView() {
        view = UIView()
        view.backgroundColor = .white
        view.addSubview(imageView)
        view.addSubview(outerStackView)
        
        outerStackView.spacing = 24.0
        innerStackView.spacing = 16.0
        
        imageView.layout(size: .init(width: 52.0, height: 52.0))
        imageView.layoutToSuperview(.centerX)
        imageView.layoutToSuperview(.top, offset: 40.0)
        
        outerStackView.layout(edge: .top, to: .bottom, of: imageView, offset: 24.0)
        outerStackView.layoutToSuperview(.leading, offset: 24.0)
        outerStackView.layoutToSuperview(.trailing, offset: -24.0)
        outerStackView.layoutToSuperview(.bottom, usesSafeAreaLayoutGuide: true, offset: -16.0)
        
        outerStackView.addArrangedSubview(innerStackView)
        outerStackView.addArrangedSubview(buttonView)
        innerStackView.addArrangedSubview(titleLabel)
        innerStackView.addArrangedSubview(subtitleLabel)
        
        buttonView.layout(edges: .leading, .trailing, to: outerStackView)
        buttonView.layout(dimension: .height, to: 48.0)
        
        [titleLabel, subtitleLabel].forEach { $0.numberOfLines = 0 }
        
        [outerStackView, innerStackView].forEach {
            $0.axis = .vertical
            $0.alignment = .center
        }
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        buttonView.viewModel = presenter.buttonViewModel
        
        presenter
            .titleLabelContent
            .drive(titleLabel.rx.content)
            .disposed(by: disposeBag)
        
        presenter
            .subtitleLabelContent
            .drive(subtitleLabel.rx.content)
            .disposed(by: disposeBag)
        
        presenter
            .imageViewContent
            .drive(imageView.rx.content)
            .disposed(by: disposeBag)
    }
}
