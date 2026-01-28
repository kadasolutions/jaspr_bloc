# jaspr_bloc

An integration library for [Jaspr](https://jaspr.site/) and [Bloc](https://bloclibrary.dev/).

This package provides a bridge to use the BLoC state management pattern within Jaspr web applications. The API is designed to mirror [flutter_bloc](https://pub.dev/packages/flutter_bloc), adapted for Jaspr’s component-based system.

## Acknowledgments

This package is made possible by the foundational work of:

- **[Jaspr](https://pub.dev/packages/jaspr)**: Created by [Kilian Schulte](https://github.com/schultek).
- **[Bloc](https://pub.dev/packages/bloc)**: Created by [Felix Angelov](https://github.com/felangel).

## Installation

Add `jaspr_bloc` to your `pubspec.yaml`:

```yaml
dependencies:
  jaspr: ^0.22.1
  bloc: ^9.2.0
  jaspr_bloc:
    git:
      url: https://github.com/kadasolutions/jaspr_bloc.git
```

## API Overview

The library implements the following standard components and extensions:

### Providers

- `BlocProvider` / `BlocProvider.value`
- `RepositoryProvider` / `RepositoryProvider.value`
- `MultiBlocProvider`
- `MultiRepositoryProvider`

### Consumers

- `BlocBuilder`
- `BlocListener`
- `BlocConsumer`
- `BlocSelector`

### Extensions

- `context.read<B>()`
- `context.repository<T>()`

## License

This project is licensed under the **Apache License 2.0**. See the `LICENSE` file for details.
