//
//  SectionedProductsViewController.swift
//  CleanArchitecture
//
//  Created by Tuan Truong on 6/11/18.
//  Copyright © 2018 Sun Asterisk. All rights reserved.
//

import UIKit
import Reusable
import RxDataSources

final class SectionedProductsViewController: UIViewController, Bindable {
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var tableView: LoadMoreTableView!
    
    // MARK: - Properties
    
    var viewModel: SectionedProductsViewModel!
    
    private typealias ProductSectionModel = SectionModel<String, ProductItemViewModel>
    private var dataSource: RxTableViewSectionedReloadDataSource<ProductSectionModel>?
    private let editProductTrigger = PublishSubject<IndexPath>()
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configView()
    }
    
    deinit {
        logDeinit()
    }
    
    // MARK: - Methods
    
    private func configView() {
        tableView.do {
            $0.estimatedRowHeight = 550
            $0.rowHeight = UITableView.automaticDimension
            $0.register(cellType: SectionedProductCell.self)
            $0.register(headerFooterViewType: ProductHeaderView.self)
        }
        
        tableView.rx
            .setDelegate(self)
            .disposed(by: rx.disposeBag)
        
        view.backgroundColor = ColorCompatibility.systemBackground
    }

    func bindViewModel() {
        let updatedProductTrigger = NotificationCenter.default.rx
            .notification(Notification.Name.updatedProduct)
            .map { notification in
                notification.object as? Product
            }
            .unwrap()
            .asDriverOnErrorJustComplete()
        
        let input = SectionedProductsViewModel.Input(
            loadTrigger: Driver.just(()),
            reloadTrigger: tableView.refreshTrigger,
            loadMoreTrigger: tableView.loadMoreTrigger,
            selectProductTrigger: tableView.rx.itemSelected.asDriver(),
            editProductTrigger: editProductTrigger.asDriverOnErrorJustComplete(),
            updatedProductTrigger: updatedProductTrigger
        )
        
        let output = viewModel.transform(input, disposeBag: rx.disposeBag)
        
        let dataSource = RxTableViewSectionedReloadDataSource<ProductSectionModel>(
            configureCell: { [weak self] (_, tableView, indexPath, product) -> UITableViewCell in
                return tableView.dequeueReusableCell(for: indexPath,
                                                     cellType: SectionedProductCell.self)
                    .then {
                        $0.bindViewModel(product)
                        
                        $0.editProductAction = {
                            self?.editProductTrigger.onNext(indexPath)
                        }
                    }
            }, titleForHeaderInSection: { _, _ in
                return ""
            })
        
        self.dataSource = dataSource
        
        output.$productSections
            .asDriver()
            .map {
                $0.map { section in
                    ProductSectionModel(model: section.header, items: section.productList)
                }
            }
            .drive(tableView.rx.items(dataSource: dataSource))
            .disposed(by: rx.disposeBag)
        
        output.$error
            .asDriver()
            .unwrap()
            .drive(rx.error)
            .disposed(by: rx.disposeBag)
        
        output.$isLoading
            .asDriver()
            .drive(rx.isLoading)
            .disposed(by: rx.disposeBag)
        
        output.$isReloading
            .asDriver()
            .drive(tableView.isRefreshing)
            .disposed(by: rx.disposeBag)
        
        output.$isLoadingMore
            .asDriver()
            .drive(tableView.isLoadingMore)
            .disposed(by: rx.disposeBag)
        
        output.$isEmpty
            .asDriver()
            .drive(tableView.isEmpty)
            .disposed(by: rx.disposeBag)
    }

}

// MARK: - UITableViewDelegate
extension SectionedProductsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNonzeroMagnitude
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 44
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableHeaderFooterView(ProductHeaderView.self)
        header?.titleLabel.text = dataSource?.sectionModels[section].model
        return header
    }
}

// MARK: - StoryboardSceneBased
extension SectionedProductsViewController: StoryboardSceneBased {
    static var sceneStoryboard = Storyboards.product
}
