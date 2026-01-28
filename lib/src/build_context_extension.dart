import 'package:bloc/bloc.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';

/// Extends [BuildContext] to provide easy access to Blocs and Repositories
/// directly from the context.
extension BlocContextX on BuildContext {
  /// Looks up a [Bloc] or [Cubit] instance of type [B].
  ///
  /// This is equivalent to `BlocProvider.of<B>(context)`.
  /// It does not set up a dependency (the component won't rebuild
  /// when the state changes), making it ideal for calling methods
  /// in event handlers.
  ///
  /// ```dart
  /// button(
  ///   onClick: () => context.read<CounterCubit>().increment(),
  ///   [text('+')],
  /// )
  /// ```
  B read<B extends StateStreamable<dynamic>>() {
    return BlocProvider.of<B>(this);
  }

  /// Looks up a repository of type [T] from the nearest ancestor [RepositoryProvider].
  ///
  /// This is equivalent to `RepositoryProvider.of<T>(context)`.
  ///
  /// ```dart
  /// final repo = context.repository<UserRepository>();
  /// ```
  T repository<T>() {
    return RepositoryProvider.of<T>(this);
  }
}
