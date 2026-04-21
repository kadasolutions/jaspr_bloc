/// A Jaspr port of the `flutter_bloc` state management primitives.
///
/// Provides [BlocProvider], [RepositoryProvider], and their `Multi*`
/// counterparts for dependency injection, together with [BlocBuilder],
/// [BlocListener], [BlocConsumer], and [BlocSelector] for reacting to
/// bloc state changes in the component tree. The [BlocContextX] extension
/// adds `context.read` and `context.repository` shortcuts.
///
/// [BlocObserver] is re-exported from `package:bloc` for convenience —
/// configure it once at startup via `Bloc.observer = MyObserver()`.
library;

export 'package:bloc/bloc.dart' show BlocObserver;

export 'src/bloc_builder.dart';
export 'src/bloc_consumer.dart';
export 'src/bloc_listener.dart';
export 'src/bloc_provider.dart';
export 'src/bloc_selector.dart';
export 'src/build_context_extension.dart';
export 'src/multi_bloc_listener.dart';
export 'src/multi_bloc_provider.dart';
export 'src/multi_repository_provider.dart';
export 'src/repository_provider.dart';
export 'src/typedefs.dart';
