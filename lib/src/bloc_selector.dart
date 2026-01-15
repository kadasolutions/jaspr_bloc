import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';

class BlocSelector<B extends StateStreamable<S>, S, T>
    extends StatefulComponent {
  const BlocSelector({
    required this.selector,
    required this.builder,
    this.bloc,
    super.key,
  });

  final B? bloc;
  final T Function(S state) selector;
  final BlocComponentSelector<S, T> builder;

  @override
  State<BlocSelector<B, S, T>> createState() => _BlocSelectorState<B, S, T>();
}

class _BlocSelectorState<B extends StateStreamable<S>, S, T>
    extends State<BlocSelector<B, S, T>> {
  late B _bloc;
  late T _selected;
  StreamSubscription<S>? _subscription;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolveBloc();
  }

  @override
  void didUpdateComponent(covariant BlocSelector<B, S, T> oldComponent) {
    super.didUpdateComponent(oldComponent);

    if (oldComponent.bloc != component.bloc ||
        oldComponent.selector != component.selector) {
      _resolveBloc(force: true);
    }
  }

  void _resolveBloc({bool force = false}) {
    final newBloc = component.bloc ?? BlocProvider.of<B>(context);

    if (!force && identical(_bloc, newBloc)) return;

    // Cancel old subscription
    _subscription?.cancel();

    // Update bloc and selected value
    _bloc = newBloc;
    _selected = component.selector(_bloc.state);

    // Subscribe to state changes
    _subscription = _bloc.stream.listen((nextState) {
      final nextSelected = component.selector(nextState);

      if (nextSelected != _selected) {
        setState(() => _selected = nextSelected);
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
    return component.builder(context, _selected);
  }
}
