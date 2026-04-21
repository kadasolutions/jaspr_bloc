import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '_helpers.dart';

void main() {
  testBloc('rebuilds only when the selected value changes', (tester) async {
    final cubit = CounterCubit();
    var builds = 0;

    tester.pumpComponent(
      BlocProvider<CounterCubit>.value(
        value: cubit,
        child: BlocSelector<CounterCubit, int, bool>(
          selector: (state) => state.isEven,
          builder: (_, isEven) {
            builds++;
            return Component.text(isEven ? 'even' : 'odd');
          },
        ),
      ),
    );

    expect(find.text('even'), findsOneComponent);
    expect(builds, 1);

    // 0 -> 2: still even — builder must not fire again.
    cubit.setValue(2);
    await tester.pump();
    expect(find.text('even'), findsOneComponent);
    expect(builds, 1);

    // 2 -> 3: parity flips — builder fires.
    cubit.setValue(3);
    await tester.pump();
    expect(find.text('odd'), findsOneComponent);
    expect(builds, 2);
  });

  testBloc('resubscribes when the explicit bloc: prop changes', (tester) async {
    final cubit1 = CounterCubit(1);
    final cubit2 = CounterCubit(10);

    tester.pumpComponent(
      BlocSelector<CounterCubit, int, int>(
        bloc: cubit1,
        selector: (state) => state * 2,
        builder: (_, value) => Component.text('$value'),
      ),
    );
    expect(find.text('2'), findsOneComponent);

    tester.pumpComponent(
      BlocSelector<CounterCubit, int, int>(
        bloc: cubit2,
        selector: (state) => state * 2,
        builder: (_, value) => Component.text('$value'),
      ),
    );
    await tester.pump();
    expect(find.text('20'), findsOneComponent);

    cubit2.setValue(5);
    await tester.pump();
    expect(find.text('10'), findsOneComponent);

    // cubit1 was unsubscribed — its emissions must not affect the display.
    cubit1.setValue(99);
    await tester.pump();
    expect(find.text('10'), findsOneComponent);
  });

  testBloc('re-evaluates with new selector when the selector function changes', (
    tester,
  ) async {
    final cubit = CounterCubit(3);

    // Initial selector: multiply by 2.
    tester.pumpComponent(
      BlocSelector<CounterCubit, int, int>(
        bloc: cubit,
        selector: (state) => state * 2,
        builder: (_, value) => Component.text('$value'),
      ),
    );
    await tester.pump();
    expect(find.text('6'), findsOneComponent);

    // Swap to a different selector: multiply by 10.
    // The component must re-resolve and show the new selected value immediately.
    tester.pumpComponent(
      BlocSelector<CounterCubit, int, int>(
        bloc: cubit,
        selector: (state) => state * 10,
        builder: (_, value) => Component.text('$value'),
      ),
    );
    await tester.pump();
    expect(find.text('30'), findsOneComponent);

    // Subsequent emissions use the new selector.
    cubit.setValue(5);
    await tester.pump();
    expect(find.text('50'), findsOneComponent);
  });

  testBloc('throws a descriptive error when no bloc is available', (
    tester,
  ) async {
    tester.pumpComponent(
      BlocSelector<CounterCubit, int, int>(
        selector: (state) => state,
        builder: (_, value) => Component.text('$value'),
      ),
    );

    expect(
      tester.takeErrors(),
      contains(
        isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('BlocSelector<CounterCubit, int, int>: No bloc found'),
        ),
      ),
    );
  });

  testBloc('does not rebuild after the component is unmounted', (tester) async {
    final cubit = CounterCubit();
    var builds = 0;

    tester.pumpComponent(
      BlocSelector<CounterCubit, int, int>(
        bloc: cubit,
        selector: (state) => state,
        builder: (_, value) {
          builds++;
          return Component.text('$value');
        },
      ),
    );

    cubit.setValue(1);
    await tester.pump();
    final buildsBeforeUnmount = builds;

    // Replacing the tree calls State.dispose, cancelling the subscription.
    tester.pumpComponent(Component.text('replaced'));
    await tester.pump();

    cubit.setValue(2);
    await tester.pump();

    expect(builds, buildsBeforeUnmount);
  });

  testBloc(
    'resubscribes in-place via didUpdateComponent when bloc: prop changes '
    'through a parent setState',
    (tester) async {
      final cubit1 = CounterCubit(1);
      final cubit2 = CounterCubit(10);
      late BlocSwapperState<CounterCubit> swapper;

      tester.pumpComponent(
        BlocSwapper<CounterCubit>(
          initial: cubit1,
          onState: (s) => swapper = s,
          builder: (cubit) => BlocSelector<CounterCubit, int, int>(
            bloc: cubit,
            selector: (state) => state * 2,
            builder: (_, value) => Component.text('$value'),
          ),
        ),
      );
      expect(find.text('2'), findsOneComponent);

      swapper.swap(cubit2);
      await tester.pump();
      expect(find.text('20'), findsOneComponent);

      cubit2.setValue(5);
      await tester.pump();
      expect(find.text('10'), findsOneComponent);

      // cubit1 was unsubscribed — must not affect display.
      cubit1.setValue(99);
      await tester.pump();
      expect(find.text('10'), findsOneComponent);
    },
  );
}
