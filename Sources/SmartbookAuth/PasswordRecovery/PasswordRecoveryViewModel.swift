//
//  PasswordRecoveryViewModel.swift
//
//
//  Created by Anton Tsikhanau on 18.11.23.
//

import RxCocoa
import RxSwift
import UIKit


protocol PasswordRecoveryViewModelProtocol {
    var title: Driver<String> { get }
    var description: Driver<String> { get }
    var formTitle: Driver<String> { get }
    var actionButtonTitle: Driver<String> { get }
    var emailValidationResult: Driver<ValidationResult> { get }
    var isButtonEnabled: Driver<Bool> { get }
    var error: Driver<Error> { get }
    var isFormHidden: Driver<Bool> { get }
    var isLoading: Driver<Bool> { get }

    var flowCompleted: Driver<Void> { get }

    var actionButtonTap: AnyObserver<Void> { get }
    var email: AnyObserver<String> { get }
}

final class PasswordRecoveryViewModel {
    enum State {
        case enterEmail
        case loading
        case checkEmail
    }

    private let disposeBag = DisposeBag()
    private let authorizationService: AuthorizationServiceProtocol
    private let state = BehaviorRelay(value: State.enterEmail)
    private let actionButtonTapSubject = PublishSubject<Void>()
    private let emailSubject = BehaviorSubject(value: "")
    private let emailValidator = Validators.email
    private let errorSubject = PublishSubject<Error>()
    private let flowCompletedSubject = PublishSubject<Void>()

    let formTitle = Driver.just(R.string.localizable.email())
    private(set) lazy var emailValidationResult = {
        emailSubject
            .skip(1)
            .debounce(.milliseconds(500), scheduler: MainScheduler.instance)
            .map { [unowned self] email in
                emailValidator.validate(email)
            }
            .asDriver(onErrorJustReturn: .success)
    }()


    init(authorizationService: AuthorizationServiceProtocol) {
        self.authorizationService = authorizationService
        bindObservables()
    }
}

private extension PasswordRecoveryViewModel {
    func bindObservables() {
        let resetPasswordTapped = actionButtonTapSubject
            .withLatestFrom(state)
            .filter { $0 == .enterEmail }

        let checkEmailClientTapped = actionButtonTapSubject
            .withLatestFrom(state)
            .filter { $0 == .checkEmail }

        disposeBag.insert {
            resetPasswordTapped
                .mapTo(State.loading)
                .bind(to: state)

            state
                .filter { $0 == .loading}
                .withLatestFrom(emailSubject)
                .withUnretained(self)
                .flatMapLatest { owner, email in
                    owner.authorizationService.forgotPassword(email: email)
                        .debug()
                }
                .catch { [weak self] error in
                    self?.state.accept(.enterEmail)
                    self?.errorSubject.onNext(error)
                    return .error(error)
                }
                .retry()
                .mapTo(State.checkEmail)
                .bind(to: state)


            checkEmailClientTapped
                .subscribe(onNext: { [unowned self] _ in
                    let mailURL = URL(string: "message://")!
                    if UIApplication.shared.canOpenURL(mailURL) {
                        UIApplication.shared.open(mailURL)
                    }
                    flowCompletedSubject.onNext(())
                })
        }
    }
}

extension PasswordRecoveryViewModel: PasswordRecoveryViewModelProtocol {
    var title: Driver<String> {
        state.compactMap {
            switch $0 {
            case .enterEmail:
                R.string.localizable.passwordRecovery()
            case .checkEmail:
                R.string.localizable.checkYourEmail()
            case .loading:
                nil
            }
        }
        .asDriverOnErrorJustComplete()
    }
    var description: Driver<String> {
        state.compactMap {
            switch $0 {
            case .enterEmail:
                R.string.localizable.enterYourEmail()
            case .checkEmail:
                R.string.localizable.weHaveSentRecoveryEmail()
            case .loading:
                nil
            }
        }
        .asDriverOnErrorJustComplete()
    }
    var actionButtonTitle: Driver<String> {
        state.compactMap {
            switch $0 {
            case .enterEmail:
                R.string.localizable.continue()
            case .checkEmail:
                R.string.localizable.letsCheck()
            case .loading:
                nil
            }
        }
        .asDriverOnErrorJustComplete()
    }
    var error: Driver<Error> {
        errorSubject.asDriverOnErrorJustComplete()
    }
    var isFormHidden: Driver<Bool> {
        state
            .map { $0 != .enterEmail }
            .asDriverOnErrorJustComplete()
    }
    var flowCompleted: Driver<Void> {
        flowCompletedSubject.asDriverOnErrorJustComplete()
    }

    var actionButtonTap: AnyObserver<Void> {
        actionButtonTapSubject.asObserver()
    }
    var email: AnyObserver<String> {
        emailSubject.asObserver()
    }
    var isButtonEnabled: Driver<Bool> {
        emailValidationResult.map(\.isValid).startWith(false)
    }
    var isLoading: Driver<Bool> {
        state
            .map { $0 == .loading }
            .asDriverOnErrorJustComplete()
    }
}