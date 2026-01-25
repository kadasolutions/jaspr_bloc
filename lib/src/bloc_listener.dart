import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';

/// Interface for multi-listener support
abstract class BlocListenerItem {
  Component buildWithChild(Component child);
}

/// Listens to bloc state changes and triggers side effects
class BlocListener<B extends StateStreamable<S>, S> extends StatefulComponent
    implements BlocListenerItem {
  const BlocListener({
    required this.listener,
    required this.child,
    this.bloc,
    this.listenWhen,
    super.key,
  });

  final B? bloc;
  final BlocComponentListener<S> listener;
  final Component child;
  final BlocBuilderCondition<S>? listenWhen;

  @override
  Component buildWithChild(Component child) {
    // Returns a new listener wrapping the given child
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
  S? _state;
  StreamSubscription<S>? _subscription;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolveBloc();
  }

  @override
  void didUpdateComponent(covariant BlocListener<B, S> oldComponent) {
    super.didUpdateComponent(oldComponent);
    if (oldComponent.bloc != component.bloc) {
      _resolveBloc(force: true);
    }
  }

  void _resolveBloc({bool force = false}) {
    final newBloc = component.bloc ?? _safeBlocLookup(context);
    if (newBloc == null) return; // provider not mounted yet
    if (!force && identical(_bloc, newBloc)) return;

    _subscription?.cancel();
    _bloc = newBloc;
    _state ??= _bloc!.state;

    _subscription = _bloc!.stream.listen((nextState) {
      final shouldListen =
          component.listenWhen?.call(_state as S, nextState) ?? true;
      if (shouldListen) {
        component.listener(context, nextState);
      }
      _state = nextState;
    });
  }

  B? _safeBlocLookup(BuildContext context) {
    try {
      return BlocProvider.of<B>(context);
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Component build(BuildContext context) => component.child;
}
