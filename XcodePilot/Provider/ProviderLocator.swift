// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import Foundation

public enum ProviderLocator: ServiceLocatorProtocol {

    // MARK: - Properties
    private static let locator: Resolver = makeLocator()

    // MARK: - Public methods
    public static func resolve<Service>(_ type: Service.Type) -> Service {
        locator.resolve(type)
    }

}

private extension ProviderLocator {

    static func makeLocator() -> Resolver {
        guard NSClassFromString("Dummy") == nil else {
            return ServiceResolver()
        }
        return ServiceResolver()
            .register(PreferencesProviderProtocol.self) { _ in
                PreferencesProvider(
                    userDefaultsService: ServiceLocator.resolve(UserDefaultsServiceProtocol.self),
                    processService: ServiceLocator.resolve(ProcessServiceProtocol.self),
                    loginItemService: ServiceLocator.resolve(LoginItemServiceProtocol.self)
                )
            }
            .register(TimerSchedulerProtocol.self) { _ in
                ServiceLocator.resolve(TimerSchedulerProtocol.self)
            }
            .register(HotKeyServiceProtocol.self) { _ in
                ServiceLocator.resolve(HotKeyServiceProtocol.self)
            }
            .register(XcodeProviderProtocol.self) { resolver in
                XcodeProvider(
                    xcodeAppService: ServiceLocator.resolve(XcodeAppServiceProtocol.self),
                    preferencesProvider: resolver.resolve(PreferencesProviderProtocol.self)
                )
            }
            .register(DevicesProviderProtocol.self) { _ in
                DevicesProvider(
                    simulatorService: ServiceLocator.resolve(SimulatorServiceProtocol.self),
                    deviceService: ServiceLocator.resolve(DeviceServiceProtocol.self),
                    xcodeAppService: ServiceLocator.resolve(XcodeAppServiceProtocol.self)
                )
            }
            .register(ProjectProviderProtocol.self) { resolver in
                ProjectProvider(
                    xcodeBuildService: ServiceLocator.resolve(XcodeBuildServiceProtocol.self),
                    xcodeAppService: ServiceLocator.resolve(XcodeAppServiceProtocol.self),
                    userDefaultsService: ServiceLocator.resolve(UserDefaultsServiceProtocol.self),
                    preferencesProvider: resolver.resolve(PreferencesProviderProtocol.self)
                )
            }
            .register(RunProviderProtocol.self) { resolver in
                RunProvider(
                    processService: ServiceLocator.resolve(ProcessServiceProtocol.self),
                    simulatorService: ServiceLocator.resolve(SimulatorServiceProtocol.self),
                    deviceService: ServiceLocator.resolve(DeviceServiceProtocol.self),
                    xcodeAppService: ServiceLocator.resolve(XcodeAppServiceProtocol.self),
                    preferencesProvider: resolver.resolve(PreferencesProviderProtocol.self)
                )
            }
            .register(BuildProviderProtocol.self) { resolver in
                BuildProvider(
                    xcodeBuildService: ServiceLocator.resolve(XcodeBuildServiceProtocol.self),
                    userDefaultsService: ServiceLocator.resolve(UserDefaultsServiceProtocol.self),
                    userNotificationsService: ServiceLocator.resolve(UserNotificationsServiceProtocol.self),
                    soundService: ServiceLocator.resolve(SoundServiceProtocol.self),
                    runProvider: resolver.resolve(RunProviderProtocol.self),
                    preferencesProvider: resolver.resolve(PreferencesProviderProtocol.self),
                    appStateRepository: RepositoryLocator.resolve(AppStateRepository.self)
                )
            }
    }

}
