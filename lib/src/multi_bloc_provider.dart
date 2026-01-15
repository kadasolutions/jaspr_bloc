import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';

/// Provides multiple [BlocProvider]s at once, wrapping the [child].
///
/// Providers are applied from last to first in the list,
/// so the first provider in the list is the outermost.
/// This matches the behavior of `flutter_bloc`'s MultiBlocProvider.
class MultiBlocProvider extends StatelessComponent {
  const MultiBlocProvider({
    required this.providers,
    required this.child,
    super.key,
  });

  /// The list of [BlocProviderItem]s to provide.
  final List<BlocProviderItem> providers;

  /// The child component that will have access to the blocs.
  final Component child;

  @override
  Component build(BuildContext context) {
    Component tree = child;

    // Wrap child with providers from last to first (same as flutter_bloc)
    for (final provider in providers.reversed) {
      tree = provider.buildWithChild(tree);
    }

    return tree;
  }
}
