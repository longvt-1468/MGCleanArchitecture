//
//  GettingProductListTests.swift
//  CleanArchitectureTests
//
//  Created by Tuan Truong on 6/29/20.
//  Copyright © 2020 Sun Asterisk. All rights reserved.
//

@testable import CleanArchitecture
import XCTest
import RxTest

final class GettingProductListTests: XCTestCase, GettingProductList {
    var productGateway: ProductGatewayType {
        return productGatewayMock
    }
    
    private var productGatewayMock: ProductGatewayMock!
    private var disposeBag: DisposeBag!
    private var getProductListOutput: TestableObserver<PagingInfo<Product>>!
    private var scheduler: TestScheduler!

    override func setUpWithError() throws {
        disposeBag = DisposeBag()
        productGatewayMock = ProductGatewayMock()
        
        scheduler = TestScheduler(initialClock: 0)
        getProductListOutput = scheduler.createObserver(PagingInfo<Product>.self)
    }
    
    func test_getProductList() {
        // act
        self.getProductList(page: 1)
            .subscribe(getProductListOutput)
            .disposed(by: disposeBag)

        // assert
        XCTAssert(productGatewayMock.getProductListCalled)
        XCTAssertEqual(getProductListOutput.events.first?.value.element?.items.count, 1)
    }
    
    func test_getProductList_fail() {
        // assign
        productGatewayMock.getProductListReturnValue = Observable.error(TestError())

        // act
        self.getProductList(page: 1)
        .subscribe(getProductListOutput)
        .disposed(by: disposeBag)

        // assert
        XCTAssert(productGatewayMock.getProductListCalled)
        XCTAssertEqual(getProductListOutput.events, [.error(0, TestError())])
    }

}
