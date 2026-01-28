import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';

/// {@template multi_bloc_provider}
/// Merges multiple [BlocProvider] components into one component tree.
///
/// It improves readability and eliminates the need to nest multiple [BlocProvider]s.
/// {@endtemplate}
class MultiBlocProvider extends StatelessComponent {
  const MultiBlocProvider({
    required this.providers,
    required this.child,
    super.key,
  });

  final List<BlocProviderItem> providers;
  final Component child;

  @override
  Component build(BuildContext context) {
    Component tree = child;

    // Correctly returning a single Component tree
    for (final provider in providers.reversed) {
      tree = provider.buildWithChild(tree);
    }

    return tree;
  }
}
