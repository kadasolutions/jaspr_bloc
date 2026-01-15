import 'package:jaspr/jaspr.dart';

typedef BlocComponentBuilder<S> =
    Component Function(BuildContext context, S state);

typedef BlocBuilderCondition<S> = bool Function(S previous, S current);

typedef BlocComponentListener<S> = void Function(BuildContext context, S state);

typedef BlocComponentSelector<S, T> =
    Component Function(BuildContext context, T value);

typedef RepositoryProviderFactory = Component Function(Component child);
