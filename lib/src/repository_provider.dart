import 'package:jaspr/jaspr.dart';

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
  }) : super(child: child ?? const Component.fragment([]));

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

  /// Retrieves the repository of type [T] from the nearest ancestor [RepositoryProvider].
  ///
  /// If the repository is not found, this will throw an [Exception].
  static T of<T>(BuildContext context) {
    final provider = context
        .dependOnInheritedComponentOfExactType<RepositoryProvider<T>>();
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
    // Identity check is usually sufficient for repositories.
    return !identical(oldComponent.repository, repository);
  }
}
