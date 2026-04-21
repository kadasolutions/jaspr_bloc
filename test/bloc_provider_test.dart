import 'package:bloc/bloc.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '_helpers.dart';

class _ClosableCubit extends Cubit<int> {
  _ClosableCubit([super.initial = 0]);

  bool closed = false;

  @override
  Future<void> close() async {
    closed = true;
    return super.close();
  }

  void setValue(int v) => emit(v);
}

void main() {
  testBloc('provides bloc to descendants via BlocProvider.of', (tester) async {
    final cubit = CounterCubit(42);

    tester.pumpComponent(
      BlocProvider<CounterCubit>.value(value: cubit, child: _ReadChild()),
    );
    await tester.pump();

    expect(find.text('42'), findsOneComponent);
  });

  testBloc('creates bloc via factory and provides it', (tester) async {
    tester.pumpComponent(
      BlocProvider<CounterCubit>(
        create: (_) => CounterCubit(7),
        child: _ReadChild(),
      ),
    );
    await tester.pump();

    expect(find.text('7'), findsOneComponent);
  });

  testBloc('closes the bloc on dispose when created via factory', (
    tester,
  ) async {
    final cubit = _ClosableCubit();

    tester.pumpComponent(
      BlocProvider<_ClosableCubit>(
        create: (_) => cubit,
        child: Component.text('child'),
      ),
    );
    await tester.pump();
    expect(cubit.closed, isFalse);

    // Replacing the root disposes the old provider.
    tester.pumpComponent(Component.text('replaced'));
    await tester.pump();

    expect(cubit.closed, isTrue);
  });

  testBloc('does NOT close the bloc when created via .value', (tester) async {
    final cubit = _ClosableCubit();

    tester.pumpComponent(
      BlocProvider<_ClosableCubit>.value(
        value: cubit,
        child: Component.text('child'),
      ),
    );
    await tester.pump();

    tester.pumpComponent(Component.text('replaced'));
    await tester.pump();

    expect(cubit.closed, isFalse);
  });

  testBloc('throws when no BlocProvider ancestor is found', (tester) async {
    tester.pumpComponent(_ReadChild());

    expect(
      tester.takeErrors(),
      contains(
        isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('BlocProvider.of<CounterCubit>: No provider found'),
        ),
      ),
    );
  });

  testBloc('context.read returns bloc without registering dependency', (
    tester,
  ) async {
    final cubit = CounterCubit(5);

    tester.pumpComponent(
      BlocProvider<CounterCubit>.value(value: cubit, child: _ReadChild()),
    );
    await tester.pump();

    expect(find.text('5'), findsOneComponent);
  });

  testBloc('lazy:false creates the bloc eagerly before any descendant access', (
    tester,
  ) async {
    var createCount = 0;

    tester.pumpComponent(
      BlocProvider<CounterCubit>(
        lazy: false,
        create: (_) {
          createCount++;
          return CounterCubit(99);
        },
        child: Component.text('no-read'),
      ),
    );
    await tester.pump();

    // The factory must have been called even though no descendant read the bloc.
    expect(createCount, 1);
  });

  testBloc('replaces .value bloc and descendants see the new instance', (
    tester,
  ) async {
    final cubit1 = CounterCubit(10);
    final cubit2 = CounterCubit(20);

    tester.pumpComponent(
      BlocProvider<CounterCubit>.value(value: cubit1, child: _ReadChild()),
    );
    await tester.pump();
    expect(find.text('10'), findsOneComponent);

    // Swap the value prop on the same provider.
    tester.pumpComponent(
      BlocProvider<CounterCubit>.value(value: cubit2, child: _ReadChild()),
    );
    await tester.pump();
    expect(find.text('20'), findsOneComponent);
  });

  testBloc(
    'binding regression: pumpComponent calls State.dispose on replaced root',
    (tester) async {
      var disposed = false;
      tester.pumpComponent(DisposalSentinel(onDisposed: () => disposed = true));
      expect(disposed, isFalse);

      tester.pumpComponent(Component.text('replaced'));

      expect(
        disposed,
        isTrue,
        reason:
            'ImprovedTestBinding must call State.dispose when replacing the '
            'root. If this fails, _deactivateDown/_unmountUp in _helpers.dart '
            'no longer works with the current jaspr_test version and every '
            'subscription-lifecycle test is a false positive.',
      );
    },
  );

  // Note: unlike flutter_bloc, lazy:true here defers creation to the provider's
  // own build() call rather than to a descendant read. The meaningful difference
  // between lazy:true and lazy:false is lifecycle ordering: lazy:false creates
  // the bloc in didChangeDependencies (before build), lazy:true creates it
  // inside build(). Both create it before any descendant has a chance to read.
  // A test for "not created until descendant reads" would be incorrect.

  testBloc('swaps .value bloc in-place via didUpdateComponent', (tester) async {
    final cubit1 = CounterCubit(10);
    final cubit2 = CounterCubit(20);
    late BlocSwapperState<CounterCubit> swapper;

    tester.pumpComponent(
      BlocSwapper<CounterCubit>(
        initial: cubit1,
        onState: (s) => swapper = s,
        builder: (cubit) =>
            BlocProvider<CounterCubit>.value(value: cubit, child: _ReadChild()),
      ),
    );
    await tester.pump();
    expect(find.text('10'), findsOneComponent);

    swapper.swap(cubit2);
    await tester.pump();
    expect(find.text('20'), findsOneComponent);
  });

  testBloc(
    'transitioning from create to .value in-place closes the created bloc',
    (tester) async {
      final createdCubit = _ClosableCubit(1);
      final valueCubit = _ClosableCubit(2);
      late BlocSwapperState<bool> swapper;

      tester.pumpComponent(
        BlocSwapper<bool>(
          initial: true,
          onState: (s) => swapper = s,
          builder: (useCreate) => useCreate
              ? BlocProvider<_ClosableCubit>(
                  create: (_) => createdCubit,
                  child: _ClosableCubitReadChild(),
                )
              : BlocProvider<_ClosableCubit>.value(
                  value: valueCubit,
                  child: _ClosableCubitReadChild(),
                ),
        ),
      );
      await tester.pump();
      expect(find.text('1'), findsOneComponent);
      expect(createdCubit.closed, isFalse);

      swapper.swap(false);
      await tester.pump();
      expect(find.text('2'), findsOneComponent);
      expect(createdCubit.closed, isTrue);
      expect(valueCubit.closed, isFalse);
    },
  );
}

class _ClosableCubitReadChild extends StatelessComponent {
  @override
  Component build(BuildContext context) {
    final cubit = BlocProvider.of<_ClosableCubit>(context, listen: false);
    return Component.text('${cubit.state}');
  }
}

/// A leaf component that reads the cubit state once via [BlocProvider.of].
class _ReadChild extends StatelessComponent {
  @override
  Component build(BuildContext context) {
    final cubit = BlocProvider.of<CounterCubit>(context, listen: false);
    return Component.text('${cubit.state}');
  }
}
