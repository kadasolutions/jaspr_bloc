import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';

/// {@template multi_repository_provider}
/// Merges multiple [RepositoryProvider] components into one component tree.
///
/// [MultiRepositoryProvider] improves readability and eliminates the need
/// to nest multiple [RepositoryProvider]s.
///
/// ```dart
/// MultiRepositoryProvider(
///   providers: [
///     (child) => RepositoryProvider(repository: RepoA(), child: child),
///     (child) => RepositoryProvider(repository: RepoB(), child: child),
///   ],
///   child: MyComponent(),
/// )
/// ```
/// {@endtemplate}
class MultiRepositoryProvider extends StatelessComponent {
  /// {@macro multi_repository_provider}
  const MultiRepositoryProvider({
    required this.providers,
    required this.child,
    super.key,
  });

  /// The list of [RepositoryProviderFactory] to be applied to the [child].
  final List<RepositoryProviderFactory> providers;

  /// The component that will have access to all provided repositories.
  final Component child;

  @override
  Component build(BuildContext context) {
    // We reduce the list from right to left (reversed).
    // This ensures that the first provider in the list is the outermost
    // ancestor in the final component tree.
    return providers.reversed.fold<Component>(
      child,
      (previousChild, factory) => factory(previousChild),
    );
  }
}
