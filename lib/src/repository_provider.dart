import 'package:jaspr/jaspr.dart';

import '_inherited_utils.dart';

/// Interface for components that can be used within a [MultiRepositoryProvider].
abstract class RepositoryProviderItem {
  /// Wraps the given [child] with the specific repository provider.
  Component buildWithChild(Component child);
}

/// {@template repository_provider}
/// [RepositoryProvider] is used to provide a repository to its children
/// via `RepositoryProvider.of<T>(context)`.
///
/// It acts as a dependency injection (DI) component so that a single instance
/// of a repository can be provided to multiple blocs within a subtree.
/// {@endtemplate}
class RepositoryProvider<T> extends InheritedComponent
    implements RepositoryProviderItem {
  /// {@macro repository_provider}
  const RepositoryProvider({
    required this.repository,
    Component? child,
    super.key,
  }) : super(child: child ?? const Component.empty());

  /// The repository instance being provided.
  final T repository;

  /// Internal method for [MultiRepositoryProvider] support.
  @override
  Component buildWithChild(Component child) {
    return RepositoryProvider<T>(
      repository: repository,
      key: key,
      child: child,
    );
  }

  /// Retrieves the repository of type [T] from the nearest ancestor
  /// [RepositoryProvider].
  ///
  /// When [listen] is `true` (the default) the calling component is registered
  /// as a dependent and will be notified if the provided repository instance
  /// changes. Pass `listen: false` for one-shot reads that should not
  /// register a dependency. [BlocContextX.repository] uses this internally.
  ///
  /// Throws an [Exception] if no matching provider is found.
  static T of<T>(BuildContext context, {bool listen = true}) {
    final RepositoryProvider<T>? provider = listen
        ? context.dependOnInheritedComponentOfExactType<RepositoryProvider<T>>()
        : peekInherited<RepositoryProvider<T>>(context);
    if (provider == null) {
      throw Exception(
        'RepositoryProvider<$T> not found in context. '
        'Make sure a RepositoryProvider<$T> exists above this component.',
      );
    }
    return provider.repository;
  }

  @override
  bool updateShouldNotify(covariant RepositoryProvider<T> oldComponent) {
    // Repositories are compared by identity: a new instance always triggers
    // a rebuild of dependents, even if its value is logically equivalent.
    return !identical(oldComponent.repository, repository);
  }
}

/// Migration adapter for the old `MultiRepositoryProvider` factory-function API.
///
/// **Deprecated.** Pass [RepositoryProvider] instances directly instead:
///
/// ```dart
/// // Before (deprecated — compile warning):
/// MultiRepositoryProvider(
///   providers: [
///     RepositoryProviderFactory(
///       (child) => RepositoryProvider(repository: MyRepo(), child: child),
///     ),
///   ],
///   child: child,
/// )
///
/// // After (preferred):
/// MultiRepositoryProvider(
///   providers: [
///     RepositoryProvider(repository: MyRepo()),
///   ],
///   child: child,
/// )
/// ```
///
/// Will be removed in v2.0.0.
@Deprecated(
  'Use RepositoryProvider(repository: ...) directly and pass it to '
  'MultiRepositoryProvider.providers without a factory wrapper. '
  'RepositoryProviderFactory will be removed in v2.0.0.',
)
class RepositoryProviderFactory implements RepositoryProviderItem {
  // ignore: deprecated_member_use_from_same_package
  @Deprecated('Use RepositoryProvider(repository: ...) directly.')
  const RepositoryProviderFactory(this._factory);

  final Component Function(Component child) _factory;

  @override
  Component buildWithChild(Component child) => _factory(child);
}
