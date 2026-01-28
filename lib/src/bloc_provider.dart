import 'package:bloc/bloc.dart';
import 'package:jaspr/jaspr.dart';

/// Interface for components that can be used within a `MultiBlocProvider`.
abstract class BlocProviderItem {
  /// Wraps the given [child] with the specific bloc provider.
  Component buildWithChild(Component child);
}

/// Internal [InheritedComponent] that provides the [bloc] to the subtree.
class _BlocInherited<B extends StateStreamable<dynamic>>
    extends InheritedComponent {
  const _BlocInherited({required this.bloc, required super.child});

  final B bloc;

  @override
  bool updateShouldNotify(covariant _BlocInherited<B> oldComponent) {
    // Only notify listeners if the bloc instance itself has changed.
    return !identical(oldComponent.bloc, bloc);
  }
}

/// {@template bloc_provider}
/// A Jaspr component which provides a [Bloc] or [Cubit] to its children
/// via `BlocProvider.of<T>(context)`.
///
/// It handles the lifecycle of the bloc, automatically closing it when
/// the provider is removed from the tree, unless created via [BlocProvider.value].
/// {@endtemplate}
class BlocProvider<B extends StateStreamable<dynamic>> extends StatefulComponent
    implements BlocProviderItem {
  /// The function that creates the bloc.
  final B Function(BuildContext context)? _create;

  /// An existing bloc instance.
  final B? _value;

  /// The component which will have access to the bloc.
  final Component? child;

  /// Whether the bloc should be created lazily. Defaults to `true`.
  final bool lazy;

  /// {@macro bloc_provider}
  /// Takes a [create] function that is responsible for creating the bloc.
  const BlocProvider({
    required B Function(BuildContext context) create,
    this.child,
    this.lazy = true,
    super.key,
  }) : _create = create,
       _value = null;

  /// Provides an existing [value] to the subtree.
  /// Blocs provided this way will not be automatically closed.
  const BlocProvider.value({required B value, this.child, super.key})
    : _value = value,
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
      return BlocProvider<B>.value(value: _value!, key: key, child: child);
    }
  }

  /// Retrieves the nearest [Bloc] of type [B] from the component tree.
  static B of<B extends StateStreamable<dynamic>>(BuildContext context) {
    final provider = context
        .dependOnInheritedComponentOfExactType<_BlocInherited<B>>();
    if (provider == null) {
      throw Exception('BlocProvider: $B not found in context');
    }
    return provider.bloc;
  }

  @override
  State<BlocProvider<B>> createState() => _BlocProviderState<B>();
}

class _BlocProviderState<B extends StateStreamable<dynamic>>
    extends State<BlocProvider<B>> {
  B? _bloc;
  bool _shouldDispose = false;
  bool _initialized = false;

  /// Accessor for the bloc instance, handling lazy initialization.
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
      throw Exception(
        'BlocProvider: No value or create function provided for $B.',
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Handle non-lazy initialization if required.
    if (!_initialized && !component.lazy && component._create != null) {
      _bloc = component._create!(context);
      _shouldDispose = true;
      _initialized = true;
    }
  }

  @override
  void didUpdateComponent(covariant BlocProvider<B> oldComponent) {
    super.didUpdateComponent(oldComponent);
    // Note: Re-creating blocs on component updates is generally avoided
    // to maintain state consistency.
    if (oldComponent._value != component._value) {
      if (_shouldDispose && _bloc is BlocBase) {
        (_bloc as BlocBase).close();
      }
      _bloc = null;
      _initialized = false;
    }
  }

  @override
  void dispose() {
    // Automatic cleanup of the bloc when the provider is disposed.
    if (_shouldDispose && _bloc is BlocBase) {
      (_bloc as BlocBase).close();
    }
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    return _BlocInherited<B>(
      bloc: bloc,
      child: component.child ?? const Component.fragment([]),
    );
  }
}
