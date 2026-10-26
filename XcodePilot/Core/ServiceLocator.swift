// Copyright (c) 2026 Evgeniy Ivon. All rights reserved.

import Foundation

public enum ServiceLocator: ServiceLocatorProtocol {

    // MARK: - Properties
    private static let locator: Resolver = makeLocator()

    // MARK: - Static func
    public static func resolve<Service>(_ type: Service.Type) -> Service {
        locator.resolve(type)
    }

}

private extension ServiceLocator {

    static func makeLocator() -> Resolver {
        guard NSClassFromString("Dummy") == nil else {
            return ServiceResolver()
        }
        let processService = ProcessService()
        return ServiceResolver()
            .register(UserDefaultsServiceProtocol.self) { _ in UserDefaultsService(with: .standard) }
            .register(TimerSchedulerProtocol.self) { _ in TimerScheduler() }
            .register(ProcessServiceProtocol.self) { _ in processService }
            .register(XcodeBuildServiceProtocol.self) { _ in XcodeBuildService(processService: processService) }
            .register(SimulatorServiceProtocol.self) { _ in SimulatorService(processService: processService) }
            .register(DeviceServiceProtocol.self) { _ in DeviceService(processService: processService) }
            .register(XcodeAppServiceProtocol.self) { _ in XcodeAppService(processService: processService) }
            .register(UserNotificationsServiceProtocol.self) { _ in UserNotificationsService() }
            .register(HotKeyServiceProtocol.self) { _ in HotKeyService() }
            .register(LoginItemServiceProtocol.self) { _ in LoginItemService() }
            .register(SoundServiceProtocol.self) { _ in SoundService() }
    }

}
