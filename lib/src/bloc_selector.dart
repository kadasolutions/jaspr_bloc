import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';

/// {@template bloc_selector}
/// [BlocSelector] is analogous to [BlocBuilder] but allows developers to
/// filter updates by selecting a new value based on the current bloc state.
///
/// Unnecessary builds are prevented by checking if the selected value has changed.
/// If the selected value remains the same, the [builder] will not be called.
/// {@endtemplate}
class BlocSelector<B extends StateStreamable<S>, S, T>
    extends StatefulComponent {
  /// {@macro bloc_selector}
  const BlocSelector({
    required this.selector,
    required this.builder,
    this.bloc,
    super.key,
  });

  /// The [bloc] that the [BlocSelector] will interact with.
  /// If omitted, it will be looked up via [BlocProvider].
  final B? bloc;

  /// The [selector] function which is responsible for returning a selected
  /// value [T] based on the current state [S].
  final T Function(S state) selector;

  /// The [builder] function which will be invoked whenever the selected value
  /// changes.
  final BlocComponentSelector<S, T> builder;

  @override
  State<BlocSelector<B, S, T>> createState() => _BlocSelectorState<B, S, T>();
}

class _BlocSelectorState<B extends StateStreamable<S>, S, T>
    extends State<BlocSelector<B, S, T>> {
  B? _bloc;
  T? _selected;
  StreamSubscription<S>? _subscription;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolveBloc();
  }

  @override
  void didUpdateComponent(covariant BlocSelector<B, S, T> oldComponent) {
    super.didUpdateComponent(oldComponent);
    // If the bloc instance or the selector logic changes, we must re-resolve.
    if (!identical(oldComponent.bloc, component.bloc) ||
        oldComponent.selector != component.selector) {
      _resolveBloc(force: true);
    }
  }

  void _resolveBloc({bool force = false}) {
    final newBloc = component.bloc ?? _safeBlocLookup(context);

    if (newBloc == null) return;
    if (!force && identical(_bloc, newBloc)) return;

    _subscription?.cancel();

    _bloc = newBloc;
    // Perform initial selection
    _selected = component.selector(_bloc!.state);

    _subscription = _bloc!.stream.listen((nextState) {
      final nextSelected = component.selector(nextState);

      // Optimization: Only trigger setState if the selected value changed.
      // Note: This assumes T has a proper operator == implementation.
      if (nextSelected != _selected) {
        setState(() => _selected = nextSelected);
      } else {
        // Sync internal value without rebuilding the UI.
        _selected = nextSelected;
      }
    });
  }

  /// Safety: Prevents runtime exceptions if the Bloc is not found.
  B? _safeBlocLookup(BuildContext context) {
    try {
      return BlocProvider.of<B>(context);
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    // Cleanup: Avoid memory leaks by canceling the stream subscription.
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    // If the component builds before the Bloc is resolved,
    // we must ensure we don't pass a null selected value if T is non-nullable.
    return component.builder(context, _selected as T);
  }
}
