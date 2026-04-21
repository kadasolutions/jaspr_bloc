import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';

/// {@template bloc_consumer}
/// [BlocConsumer] exposes a [builder] and [listener] in order react to new states.
///
/// It is useful when you need to both rebuild the UI and execute side effects
/// (like navigation or showing alerts) in response to state changes in a single [Bloc].
///
/// ```dart
/// BlocConsumer<AuthCubit, AuthState>(
///   listener: (context, state) {
///     if (state is AuthFailure) showErrorBanner(state.message);
///   },
///   builder: (context, state) {
///     return state is AuthLoading
///         ? span([], [text('Loading…')])
///         : span([], [text('Welcome')]);
///   },
/// )
/// ```
///
/// Use [buildWhen] and [listenWhen] to decouple when the UI rebuilds from when
/// side effects fire:
///
/// ```dart
/// BlocConsumer<CounterCubit, int>(
///   listenWhen: (previous, current) => current == 0,
///   listener: (context, state) => print('Reset!'),
///   buildWhen: (previous, current) => current.isEven,
///   builder: (context, count) => span([], [text('$count')]),
/// )
/// ```
/// {@endtemplate}
class BlocConsumer<B extends StateStreamable<S>, S> extends StatefulComponent {
  /// {@macro bloc_consumer}
  const BlocConsumer({
    required this.builder,
    required this.listener,
    this.bloc,
    this.buildWhen,
    this.listenWhen,
    super.key,
  });

  /// The [bloc] that the [BlocConsumer] will interact with.
  /// If omitted, it will be looked up via [BlocProvider].
  final B? bloc;

  /// The [builder] function which will be invoked on each UI rebuild.
  final BlocComponentBuilder<S> builder;

  /// The [listener] function which will be invoked on each state change
  /// for side effects.
  final BlocComponentListener<S> listener;

  /// Logic to determine if [builder] should be called.
  final BlocBuilderCondition<S>? buildWhen;

  /// Logic to determine if [listener] should be called.
  final BlocBuilderCondition<S>? listenWhen;

  @override
  State<BlocConsumer<B, S>> createState() => _BlocConsumerState<B, S>();
}

class _BlocConsumerState<B extends StateStreamable<S>, S>
    extends State<BlocConsumer<B, S>> {
  B? _bloc;
  late S _state;
  StreamSubscription<S>? _subscription;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolveBloc();
  }

  @override
  void didUpdateComponent(covariant BlocConsumer<B, S> oldComponent) {
    super.didUpdateComponent(oldComponent);
    if (!identical(oldComponent.bloc, component.bloc)) {
      _resolveBloc(force: true);
    }
  }

  void _resolveBloc({bool force = false}) {
    final newBloc = component.bloc ?? _safeBlocLookup(context);

    // Performance: Avoid re-subscribing if the bloc hasn't changed.
    if (newBloc == null) return;
    if (!force && identical(_bloc, newBloc)) return;

    // Stream Management: Cancel previous subscription before creating a new one.
    _subscription?.cancel();
    _bloc = newBloc;
    _state = _bloc!.state;

    _subscription = _bloc!.stream.listen((nextState) {
      // Guard: a stream event may already be in flight when dispose() cancels
      // the subscription. Calling setState on an unmounted State crashes.
      if (!mounted) return;

      // Logic Sync: We capture the state at the moment of emission to ensure
      // both listener and builder see a consistent 'previousState'.
      final previousState = _state;

      // 1. Side Effects (Listener)
      // Executed first so state changes that trigger navigation or popups
      // happen before or during the UI reconciliation.
      if (component.listenWhen?.call(previousState, nextState) ?? true) {
        component.listener(context, nextState);
      }

      // 2. UI Updates (Builder)
      if (component.buildWhen?.call(previousState, nextState) ?? true) {
        setState(() => _state = nextState);
      } else {
        // Essential: Keep the state updated internally even if we don't rebuild.
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
    // Memory Safety: Prevents subscription leaks in the browser environment.
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    if (_bloc == null) {
      throw Exception(
        'BlocConsumer<$B, $S>: No bloc found. Either pass one via the `bloc:` '
        'parameter, or ensure a BlocProvider<$B> exists above this component.',
      );
    }
    return component.builder(context, _state);
  }
}
