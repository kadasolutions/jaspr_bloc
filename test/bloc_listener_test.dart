import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '_helpers.dart';

void main() {
  testBloc('invokes listener on each state change', (tester) async {
    final cubit = CounterCubit();
    final seen = <int>[];

    tester.pumpComponent(
      BlocProvider<CounterCubit>.value(
        value: cubit,
        child: BlocListener<CounterCubit, int>(
          listener: (_, state) => seen.add(state),
          child: Component.text('child'),
        ),
      ),
    );

    expect(seen, isEmpty);

    cubit.setValue(1);
    await tester.pump();
    cubit.setValue(2);
    await tester.pump();

    expect(seen, [1, 2]);
  });

  testBloc('resubscribes when the explicit bloc: prop changes', (tester) async {
    final cubit1 = CounterCubit();
    final cubit2 = CounterCubit();
    final seen = <int>[];

    tester.pumpComponent(
      BlocListener<CounterCubit, int>(
        bloc: cubit1,
        listener: (_, state) => seen.add(state),
        child: Component.text('child'),
      ),
    );

    cubit1.setValue(1);
    await tester.pump();
    expect(seen, [1]);

    // Replacing the tree disposes the old state, unsubscribing from cubit1.
    tester.pumpComponent(
      BlocListener<CounterCubit, int>(
        bloc: cubit2,
        listener: (_, state) => seen.add(state),
        child: Component.text('child'),
      ),
    );
    await tester.pump();

    cubit2.setValue(10);
    await tester.pump();
    expect(seen, [1, 10]);

    cubit1.setValue(99);
    await tester.pump();
    expect(seen, [1, 10]);
  });

  testBloc('skips listener per listenWhen but advances internal state', (
    tester,
  ) async {
    final cubit = CounterCubit();
    final seen = <int>[];

    tester.pumpComponent(
      BlocProvider<CounterCubit>.value(
        value: cubit,
        child: BlocListener<CounterCubit, int>(
          listenWhen: (previous, current) => previous == 1,
          listener: (_, state) => seen.add(state),
          child: Component.text('child'),
        ),
      ),
    );

    // listenWhen(0, 1) => false: listener skipped, but _state must advance.
    cubit.setValue(1);
    await tester.pump();
    expect(seen, isEmpty);

    // listenWhen(1, 2) => true: only works if _state advanced on the skip.
    cubit.setValue(2);
    await tester.pump();
    expect(seen, [2]);
  });

  testBloc('throws a descriptive error when no bloc is available', (
    tester,
  ) async {
    tester.pumpComponent(
      BlocListener<CounterCubit, int>(
        listener: (_, _) {},
        child: Component.text('child'),
      ),
    );

    expect(
      tester.takeErrors(),
      contains(
        isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('BlocListener<CounterCubit, int>: No bloc found'),
        ),
      ),
    );
  });

  testBloc('does not invoke listener after the component is unmounted', (
    tester,
  ) async {
    final cubit = CounterCubit();
    final seen = <int>[];

    tester.pumpComponent(
      BlocListener<CounterCubit, int>(
        bloc: cubit,
        listener: (_, state) => seen.add(state),
        child: Component.text('child'),
      ),
    );

    cubit.setValue(1);
    await tester.pump();
    expect(seen, [1]);

    // Replacing the tree calls State.dispose, cancelling the subscription.
    tester.pumpComponent(Component.text('replaced'));
    await tester.pump();

    cubit.setValue(2);
    await tester.pump();

    expect(seen, [1]);
  });

  testBloc(
    'resubscribes in-place via didUpdateComponent when bloc: prop changes '
    'through a parent setState',
    (tester) async {
      final cubit1 = CounterCubit();
      final cubit2 = CounterCubit();
      final seen = <int>[];
      late BlocSwapperState<CounterCubit> swapper;

      tester.pumpComponent(
        BlocSwapper<CounterCubit>(
          initial: cubit1,
          onState: (s) => swapper = s,
          builder: (cubit) => BlocListener<CounterCubit, int>(
            bloc: cubit,
            listener: (_, state) => seen.add(state),
            child: Component.text('child'),
          ),
        ),
      );

      cubit1.setValue(1);
      await tester.pump();
      expect(seen, [1]);

      swapper.swap(cubit2);
      await tester.pump();

      // cubit2 fires — new subscription active.
      cubit2.setValue(10);
      await tester.pump();
      expect(seen, [1, 10]);

      // cubit1 was unsubscribed — must not call listener.
      cubit1.setValue(99);
      await tester.pump();
      expect(seen, [1, 10]);
    },
  );
}
