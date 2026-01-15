import 'package:bloc/bloc.dart';
import 'package:jaspr/jaspr.dart';

abstract class BlocProviderItem {
  Component buildWithChild(Component child);
}

class _BlocInherited<B extends StateStreamable<dynamic>> extends InheritedComponent {
  const _BlocInherited({required this.bloc, required super.child});

  final B bloc;

  @override
  bool updateShouldNotify(covariant _BlocInherited<B> oldComponent) {
    return oldComponent.bloc != bloc;
  }
}

class BlocProvider<B extends StateStreamable<dynamic>> extends StatefulComponent implements BlocProviderItem {
  final B Function(BuildContext context)? _create;
  final B? _value;
  final Component? child;
  final bool lazy;

  const BlocProvider({
    required B Function(BuildContext context) create,
    this.child,
    this.lazy = true,
    super.key,
  }) : _create = create,
       _value = null;

  const BlocProvider.value({
    required B value,
    this.child,
    super.key,
  }) : _value = value,
       _create = null,
       lazy = false;

  @override
  Component buildWithChild(Component child) {
    if (_create != null) {
      return BlocProvider<B>(
        create: _create,
        lazy: lazy,
        key: key,
        child: child,
      );
    } else {
      return BlocProvider<B>.value(
        value: _value!,
        key: key,
        child: child,
      );
    }
  }

  static B of<B extends StateStreamable<dynamic>>(BuildContext context) {
    final provider = context.dependOnInheritedComponentOfExactType<_BlocInherited<B>>();
    if (provider == null) {
      throw Exception('BlocProvider: $B not found in context');
    }
    return provider.bloc;
  }

  @override
  State<BlocProvider<B>> createState() => _BlocProviderState<B>();
}

class _BlocProviderState<B extends StateStreamable<dynamic>> extends State<BlocProvider<B>> {
  B? _bloc;
  bool _shouldDispose = false;
  bool _initialized = false;

  B get bloc {
    if (!_initialized) {
      _bloc = _createBlocIfNeeded();
      _initialized = true;
    }
    return _bloc!;
  }

  B _createBlocIfNeeded() {
    if (component._value != null) {
      _shouldDispose = false;
      return component._value!;
    } else if (component._create != null) {
      _shouldDispose = true;
      return component._create!(context);
    } else {
      throw Exception('BlocProvider: No value or create function provided for $B.');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Ensure eager blocs are created when dependencies are ready
    if (!_initialized && !component.lazy && component._create != null) {
      _bloc = component._create!(context);
      _shouldDispose = true;
      _initialized = true;
    }
  }

  @override
  void didUpdateComponent(covariant BlocProvider<B> oldComponent) {
    super.didUpdateComponent(oldComponent);

    // If the bloc provider changed, recreate bloc if needed
    final oldBloc = oldComponent._value ?? oldComponent._create?.call(context);
    final newBloc = component._value ?? component._create?.call(context);

    if (oldBloc != newBloc) {
      if (_shouldDispose && _bloc is BlocBase) {
        (_bloc as BlocBase).close();
      }
      _bloc = null;
      _initialized = false;
    }
  }

  @override
  void dispose() {
    if (_shouldDispose && _bloc is BlocBase) {
      (_bloc as BlocBase).close();
    }
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    final activeBloc = bloc;
    return _BlocInherited<B>(
      bloc: activeBloc,
      child: component.child ?? const Component.fragment([]),
    );
  }
}
