//
//  File.swift
//  NJPackage
//
//  Created by 정지훈 on 7/1/26.
//

import Foundation

import DomainCatsInterface
import DomainProfileInterface
import FeatureCommonInterface

@MainActor
@Observable
public final class HomeViewModel: NZViewModel {

    public struct State {
        // keychain
        let uuidString: String = UUID().uuidString
        var cats: [Cat] = []
        var individualCode: String = ""
    }

    public enum Action {
        case view(View)
        case network(Network)
        case `internal`(Internal)
        case delegate(Delegate)

        public enum View {
            case onAppear
        }

        public enum Network {

        }

        public enum Internal {

        }

        public enum Delegate {

        }
    }

    public var state: State = State()

    let catsClient: CatsClient
    let profileClient: ProfileClient

    public init(
        catsClient: CatsClient,
        profileClient: ProfileClient
    ) {
        self.catsClient = catsClient
        self.profileClient = profileClient
    }

    public func send(_ action: Action) {
        switch action {
        case let .view(viewAction):
            handleViewAction(viewAction)
        }
    }

    private func handleViewAction(_ action: Action.View) {
        switch action {
        case .onAppear:
            Task {
                do {
                    let cats = try await catsClient.fetchCats(state.individualCode)
                    state.cats = cats
                } catch {

                }
            }
        }

    }
}
