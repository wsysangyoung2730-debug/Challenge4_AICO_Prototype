import Combine
import Foundation

@MainActor
final class AnonymousSessionState: ObservableObject {
    private enum Key {
        static let isAnonymousUser = "aico.isAnonymousUser"
        static let hasSeenServiceIntro = "aico.hasSeenServiceIntro"
        static let hasSeenHomeTutorial = "aico.hasSeenHomeTutorial"
        static let hasSeenRecordingTutorial = "aico.hasSeenRecordingTutorial"
    }

    private let defaults: UserDefaults

    @Published var isAnonymousUser: Bool {
        didSet { defaults.set(isAnonymousUser, forKey: Key.isAnonymousUser) }
    }

    @Published var hasSeenServiceIntro: Bool {
        didSet { defaults.set(hasSeenServiceIntro, forKey: Key.hasSeenServiceIntro) }
    }

    @Published var hasSeenHomeTutorial: Bool {
        didSet { defaults.set(hasSeenHomeTutorial, forKey: Key.hasSeenHomeTutorial) }
    }

    @Published var hasSeenRecordingTutorial: Bool {
        didSet { defaults.set(hasSeenRecordingTutorial, forKey: Key.hasSeenRecordingTutorial) }
    }

    @Published var hasPlayedHomeBadgeAnimationThisSession = false

    @Published var hasPlayedHomeHeroAnimationThisSession = false

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.isAnonymousUser = defaults.object(forKey: Key.isAnonymousUser) as? Bool ?? true
        self.hasSeenServiceIntro = defaults.bool(forKey: Key.hasSeenServiceIntro)
        self.hasSeenHomeTutorial = defaults.bool(forKey: Key.hasSeenHomeTutorial)
        self.hasSeenRecordingTutorial = defaults.bool(forKey: Key.hasSeenRecordingTutorial)
    }

    func completeServiceIntro() {
        isAnonymousUser = true
        hasSeenServiceIntro = true
    }

    func completeHomeTutorial() {
        hasSeenHomeTutorial = true
    }

    func completeRecordingTutorial() {
        hasSeenRecordingTutorial = true
    }
}
