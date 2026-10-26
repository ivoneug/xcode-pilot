# CLAUDE.md

Руководство для Claude Code по работе с проектом **Xcode Pilot** — macOS-приложение в строке меню,
которое собирает, запускает, тестирует и архивирует Xcode-проекты через `xcodebuild`, `simctl` и
`devicectl`, не открывая Xcode.

Архитектура, кодстайл и обвязка сборки взяты из шаблона, на котором сделан ClutterCut
(`~/Development/Swift/ClutterCut`), и адаптированы под macOS. Отступать от них без причины не нужно.

---

## 1. Стек и структура

- SwiftUI + Combine + AppKit (статус-айтем, поповер, `NSTextView` для логов), минимальная цель —
  **macOS 14.0**. Значение продублировано в `Scripts/xcodegen/project.yml` (`deploymentTarget` и
  `MACOSX_DEPLOYMENT_TARGET`) — при подъёме версии правь оба места.
- Swift 5 language mode. Координаторы и ViewModel помечены `@MainActor`.
- Проект **генерируемый**: `.xcodeproj` не редактируется руками, в git не попадает.
- Внешних зависимостей нет. Приложение без песочницы: оно запускает `xcodebuild` на любых проектах.
- `LSUIElement = YES`: нет иконки в Dock и видимого главного меню.

```
XcodePilot/
  App/            MainApp, AppDelegate, DelegateProxy (статус-бар, уведомления)
  Flows/          экраны: Coordinator + ViewModel + ViewModelFactory + View + View/ подкомпоненты
                  Root (координатор панели), StatusBar (иконка, меню, поповер), Panel, Devices,
                  Settings, Export
  Provider/       бизнес-логика фич, ProviderLocator
  Repositories/   долгоживущее состояние оболочки (AppStateRepository), RepositoryLocator
  Core/           инфраструктура: сервисы (процессы, xcodebuild, simctl, devicectl, Xcode.app,
                  UserDefaults, уведомления, хоткеи), Parsers/, DI-контейнер, ServiceLocator
  Models/         Plain / DTOModels / Mappers
  Common/         Extensions, Helpers, UIComponents, CommonConstants
  Resources/      Assets (Colors/Images.xcassets), Localization/*.lproj, Generated/, Plist
UnitTests/        тесты парсеров, мапперов, аргументов xcodebuild
Scripts/          generateProject.sh, xcodegen/, SwiftGen/, project.env, templates/
```

## 2. Команды

Генерация проекта (после изменения структуры файлов, ресурсов, строк — **обязательно**):

```bash
cd Scripts && ./generateProject.sh
```

Линт (тот же запуск, что в postCompile-скрипте таргета):

```bash
swiftlint
```

Сборка и тесты — **всегда** с отдельным `-derivedDataPath` вне репозитория:

```bash
xcodebuild -project XcodePilot.xcodeproj -scheme XcodePilot -destination 'platform=macOS,arch=arm64' -derivedDataPath ~/Library/Developer/Xcode/DerivedData/XcodePilot-agent build
```

```bash
xcodebuild -project XcodePilot.xcodeproj -scheme XcodePilot -destination 'platform=macOS,arch=arm64' -derivedDataPath ~/Library/Developer/Xcode/DerivedData/XcodePilot-agent test
```

Тесты хостятся в приложении; при запуске под XCTest (`AppInfo.isRunningTests`) статус-айтем,
хоткеи и провайдеры не создаются.

Проверять приложение на своих проектах пользователя агенту не нужно: для экспериментов собирай
отдельный тестовый проект во временной папке, а `xcodebuild -showdestinations` и т.п. запускай с
`-derivedDataPath`, иначе в DerivedData пользователя появятся лишние папки.

## 3. Архитектура: слои и их обязанности

Поток зависимостей строго односторонний:

```
View → ViewModel → Provider → Core Service / Repository
         ↑
    Coordinator (владеет ViewModel'ями, маршрутизация)
```

- **View** — только верстка и вызовы методов ViewModel. AppKit-оболочка статус-бара
  (`StatusBarController`, `StatusIconRenderer`, `StatusMenuBuilder`) — тоже View-слой.
- **ViewModel** — `@MainActor final class ...: ObservableObject` (или `IdentifiableObject`).
  Состояние — `@Published private(set)`, наружу — методы-интенты (`start(_:)`, `copy(_:)`).
  Если ViewModel не помещается в 400 строк, интенты выносятся в `XViewModel+Actions.swift`.
- **ViewModelFactory** — `enum XViewModelFactory { static func build(with navigation:) -> XViewModel }`,
  резолвит зависимости через `@Dependency` и передаёт в `init`.
- **Coordinator** — `RootCoordinator`: владеет `@Published` дочерними ViewModel'ями, подписан на
  `navigation` и создаёт/обнуляет модели. Переключение поповер ↔ окно — тоже через него (`isDetached`).
- **Provider** — фича-логика: `ProjectProvider` (выбор проекта/схемы/destination и их сохранение),
  `BuildProvider` (xcodebuild, парсинг, xcresult, уведомления), `RunProvider` (установка и запуск
  на симуляторе/устройстве/Mac, консоль), `DevicesProvider`, `XcodeProvider`, `PreferencesProvider`.
  Всегда пара `XProvider` + `XProviderProtocol`. Состояние отдаётся свойствами и
  `publisher: AnyPublisher<Void, Never>`, который стреляет при каждом изменении.
- **Core Service** — инфраструктура, тоже пара «класс + протокол». Чистые функции без состояния
  (`XcodeBuildArguments`, `Core/Parsers/*`) — `enum` со `static`-методами, покрыты тестами.
- **Repository** — `AppStateRepository`: видна ли панель, запросы показать её (из уведомлений и хоткея).

## 4. Dependency Injection

Три локатора, каждый — `enum` с `ServiceLocatorProtocol`: `ServiceLocator` (Core),
`ProviderLocator` (провайдеры, их зависимости берутся из `ServiceLocator.resolve(...)` или из
`resolver` для других провайдеров), `RepositoryLocator`.

- `ServiceResolver.register` строит экземпляр сразу, поэтому зависимость регистрируется **раньше**
  того, кто её использует.
- Новый сервис/провайдер обязательно регистрируется в соответствующем `makeLocator()`.
- В коде зависимости достаются `@Dependency` / `@RepositoryDependency`; предпочтительно — в фабрике.

## 5. Навигация

- `RootCoordinator.NavigationEvent` + `CurrentValueSubject<NavigationEvent?, Never>`, который
  координатор прокидывает во ViewModel через фабрики. ViewModel делает только `navigation.send(...)`.
- В View — `.navigation(model: $coordinator.someViewModel, mode: .push() / .modalPresent())`.
  `NavigationStack` в поповере не показывает тулбар, поэтому у вложенных экранов своя кнопка «Назад».

## 6. Combine и конкурентность

- Подписки — в `private var cancellables`, вся привязка — в `bindPublishers()`, вызываемом из `init`;
  `[weak self]` в `sink`; UI — `.receive(on: DispatchQueue.main)` или `.throttle(..., scheduler: DispatchQueue.main)`.
- Состояние провайдеров меняется только на главном потоке (`@MainActor`-методы, `Task { @MainActor in }`).
- Вывод процессов читается `ProcessService.stream` (stdout+stderr в одном пайпе, пачками строк),
  парсится в `Task.detached` и применяется на главном потоке пачками.
- Отмена процесса — `ProcessHandle.cancel()`: SIGINT (xcodebuild завершается штатно, simctl/devicectl
  пробрасывают сигнал приложению), затем SIGTERM и SIGKILL.

## 7. Кодстайл

Проверяется SwiftLint (`.swiftlint.yml` скопирован из шаблона, whitelist-политика, большинство правил — `error`).

- Хедер файла: `// Copyright (c) <ГОД> Evgeniy Ivon. All rights reserved.` (`Scripts/templates/IDETemplateMacros.plist`).
- Запрещены `!`, `as!`, `try!`, файлы > 400 строк. `return` после `guard`/`if` — всегда с новой
  строки, `case` в `switch` — тело с новой строки.
- Длина строки: warning 140, error 150. Импорты отсортированы (`@testable import` идёт первым).
- Секции через `// MARK: -`: `Nested types` → `Properties` → `Computed properties` → `Init/Deinit` →
  `Internal methods` → `Private methods`; во View — `Properties` → `Computed properties` → `Layout`.
- Магические числа и строки — в `private enum Constants` в конце файла.
- Соответствия протоколам — в отдельных `extension` с `// MARK: - XProtocol`.
- `final class` по умолчанию; `private(set)` для наружу-читаемого состояния.
- Отступы — только `Margin.x4`, `Margin.x(3)`, без хардкода.
- Комментарии и док-строки в коде — **только на английском**.

## 8. Ресурсы (SwiftGen)

- `Resources/Generated/` (Colors, Images, Localizations) — генерируется, в git не попадает.
  Шаблоны в `Scripts/SwiftGen/Templates` адаптированы под AppKit (`nsColor`, `nsImage`).
- Цвета — только `Colors.x.color` / `Colors.x.nsColor` (light/dark варианты в `Colors.xcassets`).
  SF Symbols — `Image(systemName:)`.
- Строки — только `Localizations.…`. Источник — `Resources/Localization/en.lproj/Localizable.strings`,
  вторая локаль — `ru`. Набор ключей и плейсхолдеры (`%@`, `%d`) в обеих локалях обязаны совпадать.
  Строки со счётчиком — в `Localizable.stringsdict` (ru: `one`/`few`/`many`/`other`).
- Ключи — дот-нотация по экрану: `toolbar.scheme`, `settings.build.xcode`.
- Строки, которые xcodebuild или Xcode печатают сами (меню Window у Xcode, вывод компилятора), не локализуются.

## 9. Данные и внешние инструменты

- Выводы инструментов в JSON декодируются в `*ResponseDTO` (`Models/DTOModels`) и конвертируются в
  доменные модели мапперами `convertToPlain()` (`Models/Mappers`). Наружу из сервисов DTO не отдаём.
- `xcodebuild -showdestinations` JSON не умеет — его разбирает `DestinationParser`.
- Ошибки: живой парсинг лога (`BuildOutputParser`) + после сборки `xcresulttool get build-results`;
  `IssueMerger` берёт список из `.xcresult` (номера строк там с нуля — маппер прибавляет единицу)
  и сохраняет фрагменты кода из лога.
- UserDefaults — только через `UserDefaultsServiceProtocol` (`getModel`/`saveModel`), ключи — в
  `UserDefaultsKey` с префиксом `xp.`. Новые поля `Preferences` декодируются через `decodeIfPresent`.
- Архивы пишутся в `~/Library/Developer/Xcode/Archives/<дата>/`, чтобы их видел Organizer.
- Organizer и Devices and Simulators открываются нажатием пунктов меню Window у Xcode через
  Accessibility API — другого способа Xcode не даёт. Подпись командой разработчика нужна, чтобы
  разрешение не сбрасывалось после каждой пересборки.

## 10. Git

- Ветка по умолчанию — `main`. Сообщения коммитов — на английском, Conventional Commits, с маленькой
  буквы, в прошедшем времени, без точки: `feat: added archive export`, `fix: fixed destination parsing`.
- Типы: `feat`, `fix`, `chore` (конфиги, скрипты), `test`, `docs`.
- Одна логическая правка — один коммит; `git add` конкретных файлов.
- `.xcodeproj` и `Resources/Generated` — артефакты генерации, в коммит не попадают.
- Пуш — только по явной просьбе.

## 11. Чек-лист для нового экрана

1. `Flows/<Name>/` → `<Name>View.swift`, `<Name>ViewModel.swift`, `<Name>ViewModelFactory.swift`,
   подкомпоненты в `Flows/<Name>/View/`.
2. Нужна логика — `Provider/<Name>/` (`XProvider` + `XProviderProtocol`), регистрация в `ProviderLocator`.
3. Событие навигации — кейс в `RootCoordinator.NavigationEvent` + ветка в `bindPublishers()` +
   `.navigation(model:mode:)` в `RootCoordinatorView`.
4. Строки → `en.lproj` и `ru.lproj`; цвета → `Colors.xcassets`.
5. `cd Scripts && ./generateProject.sh`, затем `swiftlint` и тесты.
