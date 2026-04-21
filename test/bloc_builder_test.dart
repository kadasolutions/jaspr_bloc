import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '_helpers.dart';

void main() {
  testBloc(
    'resubscribes and reflects new state when the explicit bloc: prop changes',
    (tester) async {
      final cubit1 = CounterCubit(1);
      final cubit2 = CounterCubit(10);

      tester.pumpComponent(
        BlocBuilder<CounterCubit, int>(
          bloc: cubit1,
          builder: (_, count) => Component.text('$count'),
        ),
      );
      expect(find.text('1'), findsOneComponent);

      tester.pumpComponent(
        BlocBuilder<CounterCubit, int>(
          bloc: cubit2,
          builder: (_, count) => Component.text('$count'),
        ),
      );
      await tester.pump();
      expect(find.text('10'), findsOneComponent);

      cubit2.setValue(20);
      await tester.pump();
      expect(find.text('20'), findsOneComponent);

      // cubit1 was unsubscribed when the tree was replaced.
      cubit1.setValue(99);
      await tester.pump();
      expect(find.text('20'), findsOneComponent);
    },
  );

  testBloc('rebuilds when the cubit emits a new state', (tester) async {
    final cubit = CounterCubit();

    tester.pumpComponent(
      BlocProvider<CounterCubit>.value(
        value: cubit,
        child: BlocBuilder<CounterCubit, int>(
          builder: (_, count) => Component.text('$count'),
        ),
      ),
    );

    expect(find.text('0'), findsOneComponent);

    cubit.setValue(1);
    await tester.pump();

    expect(find.text('1'), findsOneComponent);
    expect(find.text('0'), findsNothing);
  });

  testBloc('syncs internal previousState when buildWhen skips a rebuild', (
    tester,
  ) async {
    final cubit = CounterCubit();

    tester.pumpComponent(
      BlocProvider<CounterCubit>.value(
        value: cubit,
        child: BlocBuilder<CounterCubit, int>(
          buildWhen: (previous, current) => previous == 1,
          builder: (_, count) => Component.text('$count'),
        ),
      ),
    );

    expect(find.text('0'), findsOneComponent);

    // buildWhen(0, 1) => false: skip rebuild, display stays '0'.
    // Internally _state must advance to 1 so the next emission sees prev=1.
    cubit.setValue(1);
    await tester.pump();
    expect(find.text('0'), findsOneComponent);

    // buildWhen(1, 2) => true: rebuild. If _state had not advanced on the
    // previous skip, this would evaluate as buildWhen(0, 2) => false and
    // the display would stay '0', failing the assertion below.
    cubit.setValue(2);
    await tester.pump();
    expect(find.text('2'), findsOneComponent);
  });

  testBloc('throws a descriptive error when no bloc is available', (
    tester,
  ) async {
    tester.pumpComponent(
      BlocBuilder<CounterCubit, int>(
        builder: (_, count) => Component.text('$count'),
      ),
    );

    expect(
      tester.takeErrors(),
      contains(
        isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('BlocBuilder<CounterCubit, int>: No bloc found'),
        ),
      ),
    );
  });

  testBloc('does not rebuild after the component is unmounted', (tester) async {
    final cubit = CounterCubit();
    var builds = 0;

    tester.pumpComponent(
      BlocBuilder<CounterCubit, int>(
        bloc: cubit,
        builder: (_, count) {
          builds++;
          return Component.text('$count');
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

      // BlocSwapper keeps the BlocBuilder element alive and triggers
      // didUpdateComponent when swap() is called — unlike pumpComponent,
      // which deactivates and remounts the entire tree.
      tester.pumpComponent(
        BlocSwapper<CounterCubit>(
          initial: cubit1,
          onState: (s) => swapper = s,
          builder: (cubit) => BlocBuilder<CounterCubit, int>(
            bloc: cubit,
            builder: (_, count) => Component.text('$count'),
          ),
        ),
      );
      expect(find.text('1'), findsOneComponent);

      swapper.swap(cubit2);
      await tester.pump();
      expect(find.text('10'), findsOneComponent);

      // cubit2 emits — the new subscription must fire.
      cubit2.setValue(20);
      await tester.pump();
      expect(find.text('20'), findsOneComponent);

      // cubit1 was unsubscribed in didUpdateComponent — must not affect display.
      cubit1.setValue(99);
      await tester.pump();
      expect(find.text('20'), findsOneComponent);
    },
  );
}
