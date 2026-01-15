import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';

/// Provides multiple repositories at once.
///
/// Repositories are applied from last to first in the list,
/// so the first provider in the list is the outermost.

class MultiRepositoryProvider extends StatelessComponent {
  const MultiRepositoryProvider({
    required this.providers,
    required this.child,
    super.key,
  });

  final List<RepositoryProviderFactory> providers;
  final Component child;

  @override
  Component build(BuildContext context) {
    // We reduce the list from right to left, wrapping the child at each step
    return providers.reversed.fold<Component>(
      child,
      (previousChild, factory) => factory(previousChild),
    );
  }
}
