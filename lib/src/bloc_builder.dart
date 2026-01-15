import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';

class BlocBuilder<B extends StateStreamable<S>, S> extends StatefulComponent {
  const BlocBuilder({
    required this.builder,
    this.bloc,
    this.buildWhen,
    super.key,
  });

  final B? bloc;
  final BlocComponentBuilder<S> builder;
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
    _resolveBloc();
  }

  @override
  void didUpdateComponent(covariant BlocBuilder<B, S> oldComponent) {
    super.didUpdateComponent(oldComponent);
    if (oldComponent.bloc != component.bloc) {
      _resolveBloc(force: true);
    }
  }

  void _resolveBloc({bool force = false}) {
    final newBloc = component.bloc ?? BlocProvider.of<B>(context);

    if (!force && _bloc != null && identical(_bloc, newBloc)) return;

    _subscription?.cancel();

    _bloc = newBloc;
    _state = _bloc!.state;

    _subscription = _bloc!.stream.listen((nextState) {
      final shouldBuild = component.buildWhen?.call(_state, nextState) ?? true;
      if (shouldBuild) {
        setState(() => _state = nextState);
      } else {
        _state = nextState;
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    return component.builder(context, _state);
  }
}
