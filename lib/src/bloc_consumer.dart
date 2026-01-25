import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';

class BlocConsumer<B extends StateStreamable<S>, S> extends StatefulComponent {
  const BlocConsumer({
    required this.builder,
    required this.listener,
    this.bloc,
    this.buildWhen,
    this.listenWhen,
    super.key,
  });

  final B? bloc;
  final BlocComponentBuilder<S> builder;
  final BlocComponentListener<S> listener;
  final BlocBuilderCondition<S>? buildWhen;
  final BlocBuilderCondition<S>? listenWhen;

  @override
  State<BlocConsumer<B, S>> createState() => _BlocConsumerState<B, S>();
}

class _BlocConsumerState<B extends StateStreamable<S>, S>
    extends State<BlocConsumer<B, S>> {
  B? _bloc;
  S? _state;
  StreamSubscription<S>? _subscription;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolveBloc();
  }

  @override
  void didUpdateComponent(covariant BlocConsumer<B, S> oldComponent) {
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
      final shouldBuild =
          component.buildWhen?.call(_state as S, nextState) ?? true;

      if (shouldListen) {
        component.listener(context, nextState);
      }

      if (shouldBuild) {
        setState(() => _state = nextState);
      } else {
        _state = nextState;
      }
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
  Component build(BuildContext context) {
    return component.builder(context, _state as S);
  }
}
