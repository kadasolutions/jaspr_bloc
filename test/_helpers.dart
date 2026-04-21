import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_test/jaspr_test.dart';
// TestComponentsBinding lives in a private src/ path. This is intentional:
// jaspr_test ^0.23.0 does not expose the class publicly. If a future
// jaspr_test upgrade breaks this import, move ImprovedTestBinding's logic
// into a standalone binding that doesn't extend TestComponentsBinding.
// ignore: implementation_imports
import 'package:jaspr_test/src/binding.dart';

class CounterCubit extends Cubit<int> {
  CounterCubit([super.initial = 0]);

  void setValue(int value) => emit(value);
}

/// Drop-in replacement for [TestComponentsBinding] that fixes two issues with
/// the stock binding:
///
/// 1. **Proper unmounting**: [attachRootComponent] now deactivates and unmounts
///    the previous root tree before mounting the next one, so [State.dispose]
///    (and therefore subscription cancellation) is always called.
///
/// 2. **Error propagation**: [reportBuildError] captures errors in a list
///    instead of writing to stderr. Use [takeErrors] to assert on them, or rely
///    on [BlocTester.pump] which calls [assertNoErrors] automatically so
///    unexpected build errors fail the test.
class ImprovedTestBinding extends TestComponentsBinding {
  ImprovedTestBinding() : super('/', true);

  final List<Object> _buildErrors = [];

  @override
  void reportBuildError(Element element, Object error, StackTrace stackTrace) {
    _buildErrors.add(error);
  }

  /// Removes and returns all build errors accumulated since the last call.
  List<Object> takeErrors() {
    final errors = List<Object>.from(_buildErrors);
    _buildErrors.clear();
    return errors;
  }

  /// Fails the test if any build errors have been captured.
  void assertNoErrors() {
    if (_buildErrors.isNotEmpty) {
      fail('Unexpected build error: ${_buildErrors.first}');
    }
  }

  @override
  void attachRootComponent(Component app) {
    // Fix: properly dispose the old root before mounting the new one.
    // The stock implementation discards the old root without calling
    // State.dispose, leaving stream subscriptions alive.
    final oldRoot = rootElement;
    if (oldRoot != null) {
      _deactivateDown(oldRoot);
      _unmountUp(oldRoot);
    }
    super.attachRootComponent(app);
  }

  // Deactivate parent-first (mirrors _InactiveElements._deactivateRecursively).
  static void _deactivateDown(Element element) {
    element.deactivate();
    element.visitChildren(_deactivateDown);
  }

  // Unmount children-first (mirrors _InactiveElements._unmount).
  static void _unmountUp(Element element) {
    element.visitChildren(_unmountUp);
    element.unmount();
  }
}

/// A test-scoped handle to [ImprovedTestBinding] returned by [testBloc].
class BlocTester {
  BlocTester._(this._binding);

  final ImprovedTestBinding _binding;

  void pumpComponent(Component component) {
    _binding.attachRootComponent(component);
  }

  /// Processes all pending async events (stream deliveries, microtasks) and
  /// then asserts that no unexpected build errors occurred.
  ///
  /// If you are explicitly testing that a build throws, call [takeErrors]
  /// instead of this method.
  Future<void> pump() async {
    await pumpEventQueue();
    _binding.assertNoErrors();
  }

  /// Returns all build errors captured since the last call. Clears the
  /// internal list. Use this in tests that assert on thrown errors.
  List<Object> takeErrors() => _binding.takeErrors();
}

/// A wrapper component that keeps its child element alive across value changes,
/// triggering [State.didUpdateComponent] on the child instead of unmounting it.
///
/// Use this in tests that need to verify in-place prop changes (as opposed to
/// [BlocTester.pumpComponent], which replaces the entire element tree).
///
/// ```dart
/// late BlocSwapperState<CounterCubit> swapper;
/// tester.pumpComponent(
///   BlocSwapper<CounterCubit>(
///     initial: cubit1,
///     onState: (s) => swapper = s,
///     builder: (cubit) => BlocBuilder<CounterCubit, int>(
///       bloc: cubit,
///       builder: (_, count) => Component.text('$count'),
///     ),
///   ),
/// );
/// swapper.swap(cubit2); // triggers didUpdateComponent on BlocBuilder
/// await tester.pump();
/// ```
class BlocSwapper<T> extends StatefulComponent {
  const BlocSwapper({
    required this.initial,
    required this.builder,
    required this.onState,
    super.key,
  });

  final T initial;
  final Component Function(T value) builder;
  final void Function(BlocSwapperState<T> state) onState;

  @override
  State<BlocSwapper<T>> createState() => BlocSwapperState<T>();
}

/// Tracks whether [State.dispose] was called on this component.
///
/// Mount it, replace the root with [BlocTester.pumpComponent], then assert
/// [disposed]. This is a binding regression guard: if [ImprovedTestBinding]
/// stops calling [State.dispose] when replacing roots, every subscription-
/// lifecycle test becomes a false positive.
class DisposalSentinel extends StatefulComponent {
  const DisposalSentinel({required this.onDisposed, super.key});

  final void Function() onDisposed;

  @override
  State<DisposalSentinel> createState() => _DisposalSentinelState();
}

class _DisposalSentinelState extends State<DisposalSentinel> {
  @override
  void dispose() {
    component.onDisposed();
    super.dispose();
  }

  @override
  Component build(BuildContext context) => const Component.empty();
}

class BlocSwapperState<T> extends State<BlocSwapper<T>> {
  late T _value;

  @override
  void initState() {
    super.initState();
    _value = component.initial;
    component.onState(this);
  }

  void swap(T newValue) => setState(() => _value = newValue);

  @override
  Component build(BuildContext context) => component.builder(_value);
}

/// Like [testComponents] from jaspr_test but backed by [ImprovedTestBinding],
/// so [pumpComponent] properly disposes old roots and build errors are
/// surfaced through [BlocTester.pump] / [BlocTester.takeErrors] instead of
/// going silently to stderr.
void testBloc(
  String description,
  FutureOr<void> Function(BlocTester tester) callback, {
  bool? skip,
  Timeout? timeout,
}) {
  test(
    description,
    () async {
      final binding = ImprovedTestBinding();
      final tester = BlocTester._(binding);
      await binding.runTest(() async {
        await callback(tester);
      });
    },
    skip: skip,
    timeout: timeout,
  );
}
