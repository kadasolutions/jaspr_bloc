import 'package:bloc/bloc.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';

/// Extends [BuildContext] to provide easy access to Blocs and Repositories
/// directly from the context.
extension BlocContextX on BuildContext {
  /// Looks up a [Bloc] or [Cubit] instance of type [B] without subscribing
  /// the calling component to provider changes.
  ///
  /// Equivalent to `BlocProvider.of<B>(context, listen: false)`. Use this in
  /// event handlers and other one-shot lookups where you do not want the
  /// component to be marked as a dependent of the provider.
  ///
  /// ```dart
  /// button(
  ///   onClick: () => context.read<CounterCubit>().increment(),
  ///   [text('+')],
  /// )
  /// ```
  B read<B extends StateStreamable<dynamic>>() {
    return BlocProvider.of<B>(this, listen: false);
  }

  /// Looks up a repository of type [T] from the nearest ancestor
  /// [RepositoryProvider] without subscribing to changes.
  ///
  /// Equivalent to `RepositoryProvider.of<T>(context, listen: false)`.
  ///
  /// ```dart
  /// final repo = context.repository<UserRepository>();
  /// ```
  T repository<T>() {
    return RepositoryProvider.of<T>(this, listen: false);
  }
}
