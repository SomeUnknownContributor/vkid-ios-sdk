//
// Copyright (c) 2023 - present, LLC “V Kontakte”
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

import Foundation
import UIKit
import VKIDCore

internal enum AuthProviderError: Error {
    case failedToOpenProvider
    case providerNotResponded
    case badResponse
    case cancelled
}

internal final class AuthByProviderFlow: Component, AuthFlow {
    struct Dependencies: Dependency {
        let appInteropHandler: AppInteropCompositeHandling
        let appInteropOpener: AppInteropURLOpening
        let authProvidersFetcher: AuthProviderFetcher
        let appCredentials: AppCredentials
        let authConfig: ExtendedAuthConfiguration
        let authContext: AuthContext
        let analytics: Analytics<TypeRegistrationItemNamespace>
        let responseParser: AuthCodeResponseParser
        let authURLBuilder: AuthURLBuilder
        let api: VKAPI<OAuth2>
        let logger: Logging
        let deviceId: DeviceId
    }

    let deps: Dependencies

    private var callbackHandler: ClosureBasedURLHandler?
    private var appStateObserver: AnyObject?

    init(deps: Dependencies) {
        self.deps = deps
    }

    func authorize(
        with presenter: UIKitPresenter,
        completion: @escaping AuthFlowResultCompletion
    ) {
        self.deps.authProvidersFetcher.fetch { [weak self] result in
            guard let self else {
                return
            }
            switch result {
            case .success(let providers):
                self.authorize(
                    using: providers,
                    pkceSecrets: self.deps.authConfig.pkceSecrets,
                    completion: completion
                )
            case .failure(let error):
                completion(.failure(.providersFetchingFailed(error)))
            }
        }
    }

    private func authorize(
        using providers: [AuthProvider],
        pkceSecrets: PKCESecretsWallet,
        completion: @escaping AuthFlowResultCompletion
    ) {
        guard let provider = providers.first else {
            self.deps.logger.warning("Can't open any provider")
            self.deps.analytics.noAuthProvider.send()
            completion(.failure(.noAvailableProviders))
            return
        }
        self.goToProviderForAuthCode(
            provider,
            pkceSecrets: pkceSecrets
        ) { [weak self] response in
            guard let self else {
                return
            }
            switch response {
            case.success(let response):
                self.exchangeCode(
                    using: self.deps.authConfig.codeExchanger,
                    authCodeResponse: response,
                    redirectURI: redirectURL(
                        for: self.deps.appCredentials.clientId
                    ).absoluteString,
                    pkceSecrets: self.deps.authConfig.pkceSecrets,
                    completion: completion
                )
            case .failure(let error):
                switch error {
                case .badResponse, .cancelled, .providerNotResponded:
                    completion(.failure(.authByProviderFailed(error)))
                case .failedToOpenProvider:
                    self.authorize(
                        using: Array(providers.dropFirst()),
                        pkceSecrets: pkceSecrets,
                        completion: completion
                    )
                }
            }
        }
    }

    private func goToProviderForAuthCode(
        _ provider: AuthProvider,
        pkceSecrets: PKCESecretsWallet,
        completion: @escaping (Result<AuthCodeResponse, AuthProviderError>) -> Void
    ) {
        let providerUniversalLink: URL
        do {
            providerUniversalLink = try self.deps.authURLBuilder.buildProviderAuthURL(
                baseURL: provider.universalLink,
                authContext: self.deps.authContext,
                secrets: pkceSecrets,
                credentials: self.deps.appCredentials,
                scope: self.deps.authConfig.scope,
                deviceId: self.deps.deviceId.description
            )
        } catch {
            self.deps.logger.error("Failed to open provider \(error)")
            completion(.failure(.failedToOpenProvider))
            return
        }

        self.onHandleCallbackURLFromProvider { [weak self] url in
            guard let self else {
                completion(.failure(.cancelled))
                return false
            }
            self.cleanup()
            completion(self.handleProviderCallbackURL(url))
            return true
        }
        self.onReturnFromProviderWithoutAuthCode {
            completion(.failure(.providerNotResponded))
        }

        let providerDeepLink = self.authProviderDeepLink(
            from: providerUniversalLink,
            scheme: provider.deepLinkScheme
        )
        self.deps.appInteropOpener.openApp(
            universalLink: providerUniversalLink,
            fallbackDeepLink: providerDeepLink
        ) { [weak self] opened in
            if opened {
                self?.deps.analytics.authProviderUsed.send()
            } else {
                self?.cleanup()
                completion(.failure(.failedToOpenProvider))
            }
        }
    }

    private func handleProviderCallbackURL(_ url: URL) -> Result<AuthCodeResponse, AuthProviderError> {
        do {
            let response = try self.deps.responseParser.parseAuthCodeResponse(from: url)
            let method = try self.deps.responseParser.parseCallbackMethod(from: url)
            guard method == URLQueryItem.authProviderMethod.value else {
                return .failure(.badResponse)
            }
            return .success(response)
        } catch {
            return .failure(.badResponse)
        }
    }

    private func authProviderDeepLink(from url: URL, scheme: String) -> URL? {
        if var components = URLComponents(
            url: url,
            resolvingAgainstBaseURL: false
        ) {
            components.scheme = scheme
            return components.url
        }
        return nil
    }

    func onHandleCallbackURLFromProvider(_ handler: @escaping (URL) -> Bool) {
        let urlHandler = ClosureBasedURLHandler(closure: handler)
        self.callbackHandler = urlHandler
        self.deps.appInteropHandler.attach(handler: urlHandler)
    }

    func onReturnFromProviderWithoutAuthCode(_ handler: @escaping () -> Void) {
        self.appStateObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.cleanup()

            DispatchQueue
                .main
                .asyncAfter(
                    deadline: .now() + 0.5,
                    execute: handler
                )
        }
    }

    private func cleanup() {
        self.appStateObserver.map(NotificationCenter.default.removeObserver)
        self.appStateObserver = nil
        self.callbackHandler.map(self.deps.appInteropHandler.detach(handler:))
        self.callbackHandler = nil
    }
}
