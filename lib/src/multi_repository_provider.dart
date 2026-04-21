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
///     RepositoryProvider(repository: RepoA()),
///     RepositoryProvider(repository: RepoB()),
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

  /// The repository providers to apply to [child]. The first item in the list
  /// becomes the outermost ancestor in the resulting tree.
  final List<RepositoryProviderItem> providers;

  /// The component that will have access to all provided repositories.
  final Component child;

  @override
  Component build(BuildContext context) {
    // Reduce right-to-left so the first provider ends up the outermost
    // ancestor in the final component tree.
    return providers.reversed.fold<Component>(
      child,
      (previousChild, provider) => provider.buildWithChild(previousChild),
    );
  }
}
