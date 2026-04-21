import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';

/// {@template bloc_builder}
/// [BlocBuilder] handles building a [Component] in response to new states.
///
/// It is the Jaspr equivalent of Flutter Bloc's `BlocBuilder`. It ensures
/// that the UI stays in sync with the business logic provided by a [Bloc] or [Cubit].
///
/// The bloc is resolved from the nearest [BlocProvider] ancestor, or supplied
/// explicitly via the [bloc] parameter:
///
/// ```dart
/// BlocBuilder<CounterCubit, int>(
///   builder: (context, count) {
///     return span([], [text('$count')]);
///   },
/// )
/// ```
///
/// Use [buildWhen] to skip rebuilds when only part of the state matters:
///
/// ```dart
/// BlocBuilder<CounterCubit, int>(
///   buildWhen: (previous, current) => current != previous,
///   builder: (context, count) => span([], [text('$count')]),
/// )
/// ```
/// {@endtemplate}
class BlocBuilder<B extends StateStreamable<S>, S> extends StatefulComponent {
  /// {@macro bloc_builder}
  const BlocBuilder({
    required this.builder,
    this.bloc,
    this.buildWhen,
    super.key,
  });

  /// The [bloc] that the [BlocBuilder] will interact with.
  /// If omitted, [BlocBuilder] will automatically perform a lookup using
  /// [BlocProvider] and the current [BuildContext].
  final B? bloc;

  /// The [builder] function which will be invoked on each component build.
  /// The [builder] takes the [BuildContext] and current [state] and
  /// must return a [Component].
  final BlocComponentBuilder<S> builder;

  /// A function that determines whether or not to rebuild the component
  /// with the latest state.
  final BlocBuilderCondition<S>? buildWhen;

  @override
  State<BlocBuilder<B, S>> createState() => _BlocBuilderState<B, S>();
}

class _BlocBuilderState<B extends StateStreamable<S>, S>
    extends State<BlocBuilder<B, S>> {
  B? _bloc;
  late S _state;
  StreamSubscription<S>? _subscription;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Re-resolve bloc if the provider changes in the tree.
    _resolveBloc();
  }

  @override
  void didUpdateComponent(covariant BlocBuilder<B, S> oldComponent) {
    super.didUpdateComponent(oldComponent);
    // If the explicit bloc instance changes, we must resubscribe.
    if (!identical(oldComponent.bloc, component.bloc)) {
      _resolveBloc(force: true);
    }
  }

  void _resolveBloc({bool force = false}) {
    final newBloc = component.bloc ?? _safeBlocLookup(context);

    // Performance: Skip if the bloc instance hasn't changed.
    if (newBloc == null) return;
    if (!force && identical(_bloc, newBloc)) return;

    // Stream Management: Always cancel existing subscriptions to prevent memory leaks.
    _subscription?.cancel();

    _bloc = newBloc;
    _state = _bloc!.state;

    _subscription = _bloc!.stream.listen((nextState) {
      // Guard: a stream event may already be in flight when dispose() cancels
      // the subscription. Calling setState on an unmounted State crashes.
      if (!mounted) return;

      final previousState = _state;

      // Optimization: Use buildWhen to prevent unnecessary DOM diffing in Jaspr.
      final shouldBuild =
          component.buildWhen?.call(previousState, nextState) ?? true;

      if (shouldBuild) {
        // Trigger Jaspr's reconciliation cycle.
        setState(() => _state = nextState);
      } else {
        // Sync internal state even if UI doesn't update,
        // ensuring the next buildWhen has the correct 'previous' state.
        _state = nextState;
      }
    });
  }

  B? _safeBlocLookup(BuildContext context) {
    try {
      return BlocProvider.of<B>(context);
    } on Exception {
      return null;
    }
  }

  @override
  void dispose() {
    // Lifecycle: Crucial for web applications to clean up subscriptions
    // when the component is unmounted from the DOM.
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    if (_bloc == null) {
      throw Exception(
        'BlocBuilder<$B, $S>: No bloc found. Either pass one via the `bloc:` '
        'parameter, or ensure a BlocProvider<$B> exists above this component.',
      );
    }
    return component.builder(context, _state);
  }
}
