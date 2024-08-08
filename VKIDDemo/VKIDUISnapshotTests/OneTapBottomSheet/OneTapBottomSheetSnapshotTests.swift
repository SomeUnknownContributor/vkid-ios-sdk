//
// Copyright (c) 2024 - present, LLC “V Kontakte”
//
// 1. Permission is hereby granted to any person obtaining a copy of this Software to
// use the Software without charge.
//
// 2. Restrictions
// You may not modify, merge, publish, distribute, sublicense, and/or sell copies,
// create derivative works based upon the Software or any part thereof.
//
// 3. Termination
// This License is effective until terminated. LLC “V Kontakte” may terminate this
// License at any time without any negative consequences to our rights.
// You may terminate this License at any time by deleting the Software and all copies
// thereof. Upon termination of this license for any reason, you shall continue to be
// bound by the provisions of Section 2 above.
// Termination will be without prejudice to any rights LLC “V Kontakte” may have as
// a result of this agreement.
//
// 4. Disclaimer of warranty and liability
// THE SOFTWARE IS MADE AVAILABLE ON THE “AS IS” BASIS. LLC “V KONTAKTE” DISCLAIMS
// ALL WARRANTIES THAT THE SOFTWARE MAY BE SUITABLE OR UNSUITABLE FOR ANY SPECIFIC
// PURPOSES OF USE. LLC “V KONTAKTE” CAN NOT GUARANTEE AND DOES NOT PROMISE ANY
// SPECIFIC RESULTS OF USE OF THE SOFTWARE.
// UNDER NO CIRCUMSTANCES LLC “V KONTAKTE” BEAR LIABILITY TO THE LICENSEE OR ANY
// THIRD PARTIES FOR ANY DAMAGE IN CONNECTION WITH USE OF THE SOFTWARE.
//

import SnapshotTesting
import VKIDCore
import XCTest
@testable import VKID
@testable import VKIDAllureReport

final class OneTapBottomSheetSnapshotTests: XCTestCase, TestCaseInfra {
    private let testCaseMeta = Allure.TestCase.MetaInformation(
        owner: .vkidTester,
        layer: .ui,
        product: .VKIDSDK,
        feature: "Шторка авторизации",
        priority: .critical
    )
    private let timeToUpdateViewController = 0.05
    var vkid: VKID!
    private let window = UIWindow()
    private var authFlowBuilderMock: AuthFlowBuilderMock!
    private var viewController: UIViewController!
    private var bottomSheetViewController: UIViewController!
    private var bottomSheetConfig: OneTapBottomSheet!
    private var authFlowMock: AuthFlowMock!

    override func setUpWithError() throws {
        self.authFlowBuilderMock = AuthFlowBuilderMock()
        let rootContainer = self.createRootContainer()
        rootContainer.authFlowBuilder = self.authFlowBuilderMock
        self.vkid = self.createVKID(rootContainer: rootContainer)
        self.viewController = UIViewController()
        self.window.makeKeyAndVisible()
        self.window.rootViewController = self.viewController
    }

    override func tearDownWithError() throws {
        self.vkid = nil
        self.viewController = nil
        self.bottomSheetViewController = nil
        self.bottomSheetConfig = nil
        self.authFlowBuilderMock = nil
        self.authFlowMock = nil
    }

    func testSignInAction() {
        Allure.report(
            .init(
                id: 2335327,
                name: "Конфигурация шторки 'Войти'",
                meta: self.testCaseMeta
            )
        )
        self.snapshotTest(
            targetActionText: .signIn,
            description: "'Войти'",
            testName: #function
        )
    }

    func testSignApplyForAction() {
        Allure.report(
            .init(
                id: 2335322,
                name: "Конфигурация шторки 'Подать заявку'",
                meta: self.testCaseMeta
            )
        )
        self.snapshotTest(
            targetActionText: .applyFor,
            description: "'Подать заявку'",
            testName: #function
        )
    }

    func testOrderCheckoutAction() {
        Allure.report(
            .init(
                id: 2335326,
                name: "Конфигурация шторки 'Оформить заказ'",
                meta: self.testCaseMeta
            )
        )
        self.snapshotTest(
            targetActionText: .orderCheckout,
            description: "'Оформить заказ'",
            testName: #function
        )
    }

    func testRegisterForEventAction() {
        Allure.report(
            .init(
                id: 2335324,
                name: "Конфигурация шторки 'Зарегистрироваться на событие'",
                meta: self.testCaseMeta
            )
        )
        self.snapshotTest(
            targetActionText: .registerForEvent,
            description: "'Зарегистрироваться на событие'",
            testName: #function
        )
    }

    func testOrderCheckoutAtService() {
        Allure.report(
            .init(
                id: 2335331,
                name: "Конфигурация шторки 'Оформить заказ в сервисе'",
                meta: self.testCaseMeta
            )
        )
        self.snapshotTest(
            targetActionText: .orderCheckoutAtService("Test service"),
            description: "'Оформить заказ в сервисе'",
            testName: #function
        )
    }

    func testSignInToService() {
        Allure.report(
            .init(
                id: 2335329,
                name: "Конфигурация шторки 'Войти в учетную запись указанного сервиса'",
                meta: self.testCaseMeta
            )
        )
        self.snapshotTest(
            targetActionText: .signInToService("Test service"),
            description: "'Войти в учетную запись указанного сервиса'",
            testName: #function
        )
    }

    func testOKAlternativeProvider() {
        Allure.report(
            .init(
                id: 2335330,
                name: "Конфигурация шторки с ОК",
                meta: self.testCaseMeta
            )
        )
        self.snapshotTest(
            alternativeProviders:[.ok],
            description: "OK",
            testName: #function
        )
    }

    func testMailAlternativeProvider() {
        Allure.report(
            .init(
                id: 2335328,
                name: "Конфигурация шторки с Mail",
                meta: self.testCaseMeta
            )
        )
        self.snapshotTest(
            alternativeProviders:[.mail],
            description: "Mail",
            testName: #function
        )
    }

    func testOKAndMailAlternativeProvider() {
        Allure.report(
            .init(
                id: 2335323,
                name: "Конфигурация шторки с Mail и ОК",
                meta: self.testCaseMeta
            )
        )
        self.snapshotTest(
            alternativeProviders:[.ok, .mail],
            description: "Mail и ОК",
            testName: #function
        )
    }

    func testBottomSheetOpening() {
        Allure.report(
            .init(
                id: 2315469,
                name: "Проверка открытия шторки",
                meta: self.testCaseMeta
            )
        )
        let bottomSheetOpened = expectation(description: "Шторка открыта")
        given("Создание конфигурации шторки c Mail и ОК") {
            self.bottomSheetConfig = OneTapBottomSheet(
                serviceName: "Test",
                targetActionText: .signIn,
                oneTapButton: .init(),
                onCompleteAuth: nil
            )
        }
        when("Показ шторки") {
            self.bottomSheetViewController = self.show(
                oneTapBottomSheet: self.bottomSheetConfig,
                on: self.viewController
            ) {
                then("Проверка открытой шторки") {
                    assertSnapshot(of: self.bottomSheetViewController, as: .image)
                    XCTAssert(
                        self.bottomSheetViewController.view.frame.maxY < self.window.frame.maxY
                    )
                    XCTAssert(
                        self.bottomSheetViewController.view.frame.minY > self.window.frame.minY
                    )
                    bottomSheetOpened.fulfill()
                }
            }
            self.wait(for: [bottomSheetOpened], timeout: 0.2)
        }
    }

    func testBottomSheetClosing() {
        Allure.report(
            .init(
                id: 2335325,
                name: "Проверка закрытия шторки",
                meta: self.testCaseMeta
            )
        )
        let bottomSheetClosed = expectation(description: #function)
        given("Создание конфигурации шторки") {
            self.bottomSheetConfig = OneTapBottomSheet(
                serviceName: "Test",
                targetActionText: .signIn,
                oneTapButton: .init(),
                onCompleteAuth: nil
            )
        }
        when("Показ и закрытие шторки") {
            self.bottomSheetViewController = self.show(
                oneTapBottomSheet: self.bottomSheetConfig,
                on: self.viewController
            ) {
                self.bottomSheetViewController.dismiss(animated: true) {
                    then("Проверка закрытой шторки") {
                        XCTAssertTrue(
                            self.bottomSheetViewController.view.frame.minY + 1 >= self.window.frame.maxY
                        )
                        bottomSheetClosed.fulfill()
                    }
                }
            }
        }

        self.wait(for: [bottomSheetClosed], timeout: 1)
    }

    func testFailedAuthorization() {
        Allure.report(
            .init(
                id: 2315471,
                name: "Проверка обработки ошибки авторизации и ретрая авторизации",
                meta: self.testCaseMeta
            )
        )
        let mockFailedAuthExpectation = XCTestExpectation(
            description: "Имитация ошибки авторизации"
        )
        let handledErrorExpectation = XCTestExpectation(
            description: "Обработка ошибки авторизации"
        )
        let retryHandledExpectation = expectation(description: "Обработка ретрая")
        var isRetry = false
        given("Конфигурация OneTap, имитация авторизации") {
            self.bottomSheetConfig = OneTapBottomSheet(
                serviceName: "Test",
                targetActionText: .signIn,
                oneTapButton: .init()
            ) { result in
                if case .failure(.unknown) = result {
                    if isRetry {
                        then("Проверка ретрая") {
                            retryHandledExpectation.fulfill()
                        }
                        return
                    }
                    then("Проверка ошибки") {
                        assertSnapshot(of: self.bottomSheetViewController, as: .image)
                        handledErrorExpectation.fulfill()
                    }
                    when("Запуск ретрая") {
                        isRetry = true
                        self.bottomSheetViewController.view.tapOnRetryButton()
                    }
                } else {
                    XCTFail("Wrong failed flow")
                }
            }
            self.mockFailedResponse {
                if !isRetry {
                    assertSnapshot(
                        of: self.bottomSheetViewController,
                        as: .image(precision: 0.997)
                    )
                }
                mockFailedAuthExpectation.fulfill()
            }
        }
        when("Показ шторки и нажатие на 'Sign in'") {
            self.bottomSheetViewController = self.show(
                oneTapBottomSheet: self.bottomSheetConfig,
                on: self.viewController
            ) {
                self.bottomSheetViewController.view.tapOnOneTapControl()
            }
            self.wait(
                for: [
                    mockFailedAuthExpectation,
                    handledErrorExpectation,
                    retryHandledExpectation,
                ],
                timeout: 1
            )
        }
    }

    func testSuccessAuthorization() {
        Allure.report(
            .init(
                id: 2315472,
                name: "Авто закрытие шторки после удачной авторизации, если в конфиге указали autoDismissOnSuccess = true",
                meta: self.testCaseMeta
            )
        )
        let mockSuccessAuthExpectation = XCTestExpectation(
            description: "Имитация успешной авторизации"
        )
        let successResultExpectation = XCTestExpectation(
            description: "Получен результат успешной авторизации"
        )
        given("Конфигурация OneTap, имитация авторизации") {
            self.bottomSheetConfig = OneTapBottomSheet(
                serviceName: "Test",
                targetActionText: .signIn,
                oneTapButton: .init(),
                autoDismissOnSuccess: true
            ) { result in
                if case .success = result {
                    then("Проверка скрытой шторки") {
                        XCTAssertTrue(
                            self.bottomSheetViewController.view.frame.minY + 1 >= self.window.frame.maxY
                        )
                        successResultExpectation.fulfill()
                    }
                }
            }
            self.mockSuccessResponse {
                mockSuccessAuthExpectation.fulfill()
            }
        }
        when("Нажатие на кнопку OneTapBottomSheet") {
            self.bottomSheetViewController = self.show(
                oneTapBottomSheet: self.bottomSheetConfig,
                on: self.viewController
            ) {
                if let control: UIControl = self.bottomSheetViewController.view.findElements({
                    $0.accessibilityIdentifier == AccessibilityIdentifier.OneTapButton.signIn.id
                }).first {
                    control.sendActions(for: .touchUpInside)
                }
            }
        }
        self.wait(
            for: [
                mockSuccessAuthExpectation,
                successResultExpectation,
            ],
            timeout: 1
        )
    }

    func mockFailedResponse(completion: @escaping () -> Void) {
        self.authFlowBuilderMock.serviceAuthFlowHandler = { _, _, _ in
            self.authFlowMock = AuthFlowMock()
            self.authFlowMock.handler = { _, handlerCompletion in
                DispatchQueue.main.asyncAfter(
                    deadline: .now() + self.timeToUpdateViewController
                ) {
                    completion()
                    handlerCompletion(.failure(.webViewAuthSessionFailedToStart))
                }
            }
            return self.authFlowMock
        }
    }

    private func mockSuccessResponse(completion: @escaping () -> Void) {
        self.authFlowBuilderMock.serviceAuthFlowHandler = { _, _, _ in
            self.authFlowMock = AuthFlowMock()
            self.authFlowMock.handler = { _, handlerCompletion in
                completion()
                handlerCompletion(.success(.init(from: .random(), serverProvidedDeviceId: .random)))
            }
            return self.authFlowMock
        }
    }

    private func snapshotTest(
        targetActionText: OneTapBottomSheet.TargetActionText = .signIn,
        alternativeProviders: [OAuthProvider] = [],
        description: String,
        testName: String
    ) {
        let expectation = expectation(description: #function)
        given("Создание конфигурации шторки с: \(description)") {
            self.bottomSheetConfig = OneTapBottomSheet(
                serviceName: "Test",
                targetActionText: targetActionText,
                oneTapButton: .init(),
                oAuthProviderConfiguration: .init(
                    alternativeProviders: alternativeProviders
                ),
                onCompleteAuth: nil
            )
        }
        when("Показ шторки") {
            self.bottomSheetViewController = self.show(
                oneTapBottomSheet: self.bottomSheetConfig,
                on: self.viewController
            ) {
                then("Проверка снапшота шторки") {
                    assertSnapshot(
                        of: self.bottomSheetViewController,
                        as: .image,
                        testName: testName
                    )
                    expectation.fulfill()
                }
            }
        }
        self.wait(for: [expectation], timeout: 0.2)
    }

    private func show(
        oneTapBottomSheet: OneTapBottomSheet,
        on viewController: UIViewController,
        completion: @escaping () -> Void
    ) -> UIViewController {
        let bottomSheetViewController = self.vkid.ui(
            for: oneTapBottomSheet
        ).uiViewController()
        viewController.present(bottomSheetViewController, animated: false) {
            completion()
        }
        return bottomSheetViewController
    }
}
