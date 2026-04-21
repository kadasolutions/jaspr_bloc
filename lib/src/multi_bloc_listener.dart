import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';

/// {@template multi_bloc_listener}
/// Merges multiple [BlocListener] components into one component tree.
///
/// [MultiBlocListener] improves readability and eliminates the need to nest
/// multiple [BlocListener]s.
///
/// ```dart
/// MultiBlocListener(
///   listeners: [
///     BlocListener<BlocA, BlocAState>(
///       listener: (context, state) {},
///     ),
///     BlocListener<BlocB, BlocBState>(
///       listener: (context, state) {},
///     ),
///   ],
///   child: MyComponent(),
/// )
/// ```
/// {@endtemplate}
class MultiBlocListener extends StatelessComponent {
  /// {@macro multi_bloc_listener}
  const MultiBlocListener({
    required this.listeners,
    required this.child,
    super.key,
  });

  /// The [BlocListener]s to be applied to the [child].
  /// The first item in the list becomes the outermost ancestor in the tree.
  final List<BlocListenerItem> listeners;

  /// The component that will have access to all provided listeners.
  final Component child;

  @override
  Component build(BuildContext context) {
    return listeners.reversed.fold<Component>(
      child,
      (child, listener) => listener.buildWithChild(child),
    );
  }
}
