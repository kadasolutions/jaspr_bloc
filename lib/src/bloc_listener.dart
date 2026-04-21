import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';

/// Interface for components that can be used within a MultiBlocListener.
abstract class BlocListenerItem {
  /// Wraps the given [child] with the specific listener component.
  Component buildWithChild(Component child);
}

/// {@template bloc_listener}
/// [BlocListener] is a [Component] which takes a [BlocComponentListener] and
/// an optional [bloc] and invokes the [listener] in response to state changes
/// in the bloc.
///
/// It should be used for functionality that needs to occur once per state change
/// such as navigation, showing a snackbar, etc.
/// {@endtemplate}
class BlocListener<B extends StateStreamable<S>, S> extends StatefulComponent
    implements BlocListenerItem {
  /// {@macro bloc_listener}
  const BlocListener({
    required this.listener,
    Component? child,
    this.bloc,
    this.listenWhen,
    super.key,
  }) : child = child ?? const Component.empty();

  /// The [bloc] that the [BlocListener] will interact with.
  /// If omitted, [BlocListener] will automatically perform a lookup using
  /// [BlocProvider] and the current [BuildContext].
  final B? bloc;

  /// The [BlocComponentListener] which will be called on every state change.
  /// This is the ideal place for side effects.
  final BlocComponentListener<S> listener;

  /// The [Component] which will be rendered.
  ///
  /// Defaults to an empty fragment when used inside [MultiBlocListener] where
  /// the real child is injected via [buildWithChild].
  final Component child;

  /// An optional [listenWhen] can be implemented for more granular control
  /// over when [listener] is called.
  final BlocBuilderCondition<S>? listenWhen;

  @override
  Component buildWithChild(Component child) {
    return BlocListener<B, S>(
      key: key,
      bloc: bloc,
      listener: listener,
      listenWhen: listenWhen,
      child: child,
    );
  }

  @override
  State<BlocListener<B, S>> createState() => _BlocListenerState<B, S>();
}

class _BlocListenerState<B extends StateStreamable<S>, S>
    extends State<BlocListener<B, S>> {
  B? _bloc;
  late S _state;
  StreamSubscription<S>? _subscription;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolveBloc();
  }

  @override
  void didUpdateComponent(covariant BlocListener<B, S> oldComponent) {
    super.didUpdateComponent(oldComponent);
    // Re-resolve if the bloc instance is replaced.
    if (!identical(oldComponent.bloc, component.bloc)) {
      _resolveBloc(force: true);
    }
  }

  void _resolveBloc({bool force = false}) {
    final newBloc = component.bloc ?? _safeBlocLookup(context);

    // Efficiency: Do not re-subscribe if the bloc hasn't changed.
    if (newBloc == null) return;
    if (!force && identical(_bloc, newBloc)) return;

    _subscription?.cancel();
    _bloc = newBloc;

    // Snapshot: Always sync with the current bloc state during initialization/update.
    _state = _bloc!.state;

    _subscription = _bloc!.stream.listen((nextState) {
      // Guard: a stream event may already be in flight when dispose() cancels
      // the subscription. Invoking the listener with a stale context is unsafe.
      if (!mounted) return;

      final previousState = _state;

      // Control: Evaluate whether the side effect should trigger.
      final shouldListen =
          component.listenWhen?.call(previousState, nextState) ?? true;

      if (shouldListen) {
        component.listener(context, nextState);
      }

      // Sync: Update tracked state for the next transition calculation.
      _state = nextState;
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
    // Cleanup: Essential to prevent async callbacks after component is unmounted.
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    if (_bloc == null) {
      throw Exception(
        'BlocListener<$B, $S>: No bloc found. Either pass one via the `bloc:` '
        'parameter, or ensure a BlocProvider<$B> exists above this component.',
      );
    }
    return component.child;
  }
}
