import 'package:jaspr/jaspr.dart';

/// Provides a repository of type [T] to the component tree below it.
class RepositoryProvider<T> extends InheritedComponent {
  /// [child] is optional if this provider is used inside a MultiRepositoryProvider.
  const RepositoryProvider({
    required this.repository,
    Component? child,
    super.key,
  }) : super(child: child ?? const Component.fragment([]));

  /// The repository instance being provided.
  final T repository;

  /// Retrieves the repository of type [T] from the nearest ancestor [RepositoryProvider].
  static T of<T>(BuildContext context) {
    final provider = context.dependOnInheritedComponentOfExactType<RepositoryProvider<T>>();
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
    return oldComponent.repository != repository;
  }
}
