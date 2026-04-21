## 1.1.0

### Breaking

- Bumped `jaspr` to `^0.23.0`. Consumers still on `jaspr` 0.22.x must upgrade
  before updating to this version.
- `MultiRepositoryProvider.providers` now takes `List<RepositoryProviderItem>`
  instead of `List<RepositoryProviderFactory>`. Replace lambda factory functions
  with bare `RepositoryProvider(repository: ...)` instances:
  ```dart
  // Before
  providers: [
    (child) => RepositoryProvider(repository: MyRepo(), child: child),
  ]
  // After
  providers: [
    RepositoryProvider(repository: MyRepo()),
  ]
  ```
  The old `RepositoryProviderFactory` function typedef has been replaced by a
  same-named deprecated class adapter. If you used it only inline (passing a
  lambda directly to `providers:`), wrap the lambda in
  `RepositoryProviderFactory(yourLambda)` for a warning-only migration path.
  If you used it as a type annotation, change the annotation to
  `Component Function(Component child)`. The class will be removed in v2.0.0.

### Added

- `MultiBlocListener` — composes multiple `BlocListener`s without nesting,
  mirroring the flutter_bloc API.
- `BlocObserver` is now re-exported from `package:bloc` for convenience;
  configure it with `Bloc.observer = MyObserver()` without a separate import.

## 1.0.3

### Fixed

- `BlocBuilder`, `BlocListener`, `BlocSelector`, and `BlocConsumer` now guard
  their stream listeners with a `mounted` check. This closes a race where a
  queued state event could fire after `dispose()` cancels the subscription
  and crash with "setState called after dispose" (or invoke a listener with
  a stale context).

## 1.0.2

### Fixed

- Missing-provider errors are now raised with a descriptive message instead
  of a cryptic `LateInitializationError` / `TypeError`. If no bloc can be
  resolved (no explicit `bloc:` and no ancestor `BlocProvider`), `build`
  throws an `Exception` naming the component and the expected bloc type.
- `context.read<B>()` and `context.repository<T>()` now correctly pass
  `listen: false` to the underlying provider lookup. Previously they called
  `dependOnInheritedComponentOfExactType`, which registered the component as
  a dependent despite the documentation stating otherwise.

### Changed

- `_safeBlocLookup` now catches `Exception` instead of everything. Errors
  (e.g. `TypeError`, `AssertionError`) originating from user code during the
  provider lookup are no longer silently swallowed.
- All four consumer components (`BlocBuilder`, `BlocListener`, `BlocConsumer`,
  `BlocSelector`) now use `!identical(oldComponent.bloc, component.bloc)`
  when deciding whether to resubscribe. Bloc instances are compared by
  identity, not equality.
- Removed the `meta` dependency; it was unused.

## 1.0.1

- Internal packaging adjustments.

## 1.0.0

- Initial version.
