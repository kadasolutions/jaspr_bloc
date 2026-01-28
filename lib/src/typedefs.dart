import 'package:jaspr/jaspr.dart';

/// Signature for the [builder] function which takes the [BuildContext] and
/// the current [state] and must return a [Component].
typedef BlocComponentBuilder<S> =
    Component Function(BuildContext context, S state);

/// Signature for the [buildWhen] and [listenWhen] functions which take the
/// [previous] state and the [current] state and determine whether to
/// rebuild or trigger a listener.
typedef BlocBuilderCondition<S> = bool Function(S previous, S current);

/// Signature for the [listener] function which takes the [BuildContext] and
/// the [state] and is used for side effects (navigation, alerts, etc.).
typedef BlocComponentListener<S> = void Function(BuildContext context, S state);

/// Signature for the [builder] function in a [BlocSelector].
/// It takes the [BuildContext] and the selected [value] of type [T].
typedef BlocComponentSelector<S, T> =
    Component Function(BuildContext context, T value);

/// A function signature that takes a [child] component and returns a new
/// component wrapping that child. Primarily used in [MultiRepositoryProvider].
typedef RepositoryProviderFactory = Component Function(Component child);
