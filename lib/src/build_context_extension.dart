import 'package:bloc/bloc.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';

extension BuildContextX on BuildContext {
  /// Read a bloc without listening (like `context.read` in flutter_bloc)
  B read<B extends StateStreamable<dynamic>>() {
    return BlocProvider.of<B>(this);
  }

  /// Read a repository
  T repository<T>() {
    return RepositoryProvider.of<T>(this);
  }
}
