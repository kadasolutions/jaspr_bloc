![Kadasolutions: Our mission is to turn your digital product ideas into reality.](./banner.png)

# jaspr_bloc

An integration library for [Jaspr](https://jaspr.site/) and [Bloc](https://bloclibrary.dev/).

This package provides a bridge to use the BLoC state management pattern within Jaspr web applications. The API is designed to mirror [flutter_bloc](https://pub.dev/packages/flutter_bloc), adapted for Jaspr's component-based system.

## Acknowledgments

This package is made possible by the foundational work of:

- **[Jaspr](https://pub.dev/packages/jaspr)**: Created by [Kilian Schulte](https://github.com/schultek).
- **[Bloc](https://pub.dev/packages/bloc)**: Created by [Felix Angelov](https://github.com/felangel).

## Installation

Add `jaspr_bloc` to your `pubspec.yaml`:

```yaml
dependencies:
  jaspr: ^0.23.0
  bloc: ^9.2.0
  jaspr_bloc:
    git:
      url: https://github.com/kadasolutions/jaspr_bloc.git
```

## API Overview

### Providers

- `BlocProvider` / `BlocProvider.value`
- `RepositoryProvider` / `RepositoryProvider.value`
- `MultiBlocProvider`
- `MultiRepositoryProvider`

### Consumers

- `BlocBuilder` — rebuilds on every state change (or on `buildWhen`).
- `BlocListener` — fires side effects on state changes without rebuilding.
- `BlocConsumer` — combines `BlocBuilder` and `BlocListener`.
- `BlocSelector` — rebuilds only when a selected slice of state changes.
- `MultiBlocListener` — composes multiple `BlocListener`s without nesting.

### Extensions

- `context.read<B>()` — one-shot lookup, does not subscribe.
- `context.repository<T>()` — one-shot repository lookup.

### Observation

- `BlocObserver` is re-exported from `package:bloc`. Configure it once at
  startup with `Bloc.observer = MyObserver()`.

## License

This project is licensed under the **Apache License 2.0**. See the `LICENSE` file for details.
