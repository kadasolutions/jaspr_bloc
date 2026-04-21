import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '_helpers.dart';

void main() {
  testBloc('rebuilds builder and invokes listener on each state change', (
    tester,
  ) async {
    final cubit = CounterCubit();
    final seen = <int>[];

    tester.pumpComponent(
      BlocProvider<CounterCubit>.value(
        value: cubit,
        child: BlocConsumer<CounterCubit, int>(
          listener: (_, state) => seen.add(state),
          builder: (_, state) => Component.text('$state'),
        ),
      ),
    );

    expect(find.text('0'), findsOneComponent);
    expect(seen, isEmpty);

    cubit.setValue(1);
    await tester.pump();
    expect(find.text('1'), findsOneComponent);
    expect(seen, [1]);
  });

  testBloc('respects buildWhen and listenWhen independently', (tester) async {
    final cubit = CounterCubit();
    final seen = <int>[];
    var builds = 0;

    tester.pumpComponent(
      BlocProvider<CounterCubit>.value(
        value: cubit,
        child: BlocConsumer<CounterCubit, int>(
          buildWhen: (previous, current) => current.isEven,
          listenWhen: (previous, current) => current.isOdd,
          listener: (_, state) => seen.add(state),
          builder: (_, state) {
            builds++;
            return Component.text('$state');
          },
        ),
      ),
    );

    expect(builds, 1);
    expect(seen, isEmpty);

    // 1 is odd: listener fires, builder skipped (display stays '0').
    cubit.setValue(1);
    await tester.pump();
    expect(find.text('0'), findsOneComponent);
    expect(seen, [1]);
    expect(builds, 1);

    // 2 is even: listener skipped, builder fires.
    cubit.setValue(2);
    await tester.pump();
    expect(find.text('2'), findsOneComponent);
    expect(seen, [1]);
    expect(builds, 2);
  });

  testBloc(
    'tracks previousState correctly when buildWhen and listenWhen are stateful',
    (tester) async {
      final cubit = CounterCubit();
      final seen = <int>[];
      var builds = 0;

      tester.pumpComponent(
        BlocProvider<CounterCubit>.value(
          value: cubit,
          child: BlocConsumer<CounterCubit, int>(
            // listenWhen fires only when previous == 1.
            listenWhen: (previous, current) => previous == 1,
            // buildWhen fires only when previous == 2.
            buildWhen: (previous, current) => previous == 2,
            listener: (_, state) => seen.add(state),
            builder: (_, state) {
              builds++;
              return Component.text('$state');
            },
          ),
        ),
      );
      expect(builds, 1);

      // Emit 1: listenWhen(0,1)=false, buildWhen(0,1)=false → nothing fires,
      //         _state must advance to 1.
      cubit.setValue(1);
      await tester.pump();
      expect(seen, isEmpty);
      expect(builds, 1);

      // Emit 2: listenWhen(1,2)=true → listener fires, buildWhen(1,2)=false →
      //         builder skipped, _state must advance to 2.
      cubit.setValue(2);
      await tester.pump();
      expect(seen, [2]);
      expect(builds, 1);

      // Emit 3: listenWhen(2,3)=false, buildWhen(2,3)=true → builder fires.
      cubit.setValue(3);
      await tester.pump();
      expect(seen, [2]);
      expect(builds, 2);
      expect(find.text('3'), findsOneComponent);
    },
  );

  testBloc('resubscribes when the explicit bloc: prop changes', (tester) async {
    final cubit1 = CounterCubit(1);
    final cubit2 = CounterCubit(10);
    final seen = <int>[];

    tester.pumpComponent(
      BlocConsumer<CounterCubit, int>(
        bloc: cubit1,
        listener: (_, state) => seen.add(state),
        builder: (_, state) => Component.text('$state'),
      ),
    );
    expect(find.text('1'), findsOneComponent);

    // Replacing the tree disposes the old state, unsubscribing from cubit1.
    tester.pumpComponent(
      BlocConsumer<CounterCubit, int>(
        bloc: cubit2,
        listener: (_, state) => seen.add(state),
        builder: (_, state) => Component.text('$state'),
      ),
    );
    await tester.pump();
    expect(find.text('10'), findsOneComponent);

    cubit2.setValue(20);
    await tester.pump();
    expect(find.text('20'), findsOneComponent);
    expect(seen, [20]);

    cubit1.setValue(99);
    await tester.pump();
    expect(find.text('20'), findsOneComponent);
    expect(seen, [20]);
  });

  testBloc('throws a descriptive error when no bloc is available', (
    tester,
  ) async {
    tester.pumpComponent(
      BlocConsumer<CounterCubit, int>(
        listener: (_, _) {},
        builder: (_, state) => Component.text('$state'),
      ),
    );

    expect(
      tester.takeErrors(),
      contains(
        isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('BlocConsumer<CounterCubit, int>: No bloc found'),
        ),
      ),
    );
  });

  testBloc('does not rebuild or notify after the component is unmounted', (
    tester,
  ) async {
    final cubit = CounterCubit();
    final seen = <int>[];
    var builds = 0;

    tester.pumpComponent(
      BlocConsumer<CounterCubit, int>(
        bloc: cubit,
        listener: (_, state) => seen.add(state),
        builder: (_, state) {
          builds++;
          return Component.text('$state');
        },
      ),
    );

    cubit.setValue(1);
    await tester.pump();
    final buildsBeforeUnmount = builds;
    final seenBeforeUnmount = List<int>.from(seen);

    // Replacing the tree calls State.dispose, cancelling the subscription.
    tester.pumpComponent(Component.text('replaced'));
    await tester.pump();

    cubit.setValue(2);
    await tester.pump();

    expect(builds, buildsBeforeUnmount);
    expect(seen, seenBeforeUnmount);
  });

  testBloc(
    'resubscribes in-place via didUpdateComponent when bloc: prop changes '
    'through a parent setState',
    (tester) async {
      final cubit1 = CounterCubit(1);
      final cubit2 = CounterCubit(10);
      final seen = <int>[];
      late BlocSwapperState<CounterCubit> swapper;

      tester.pumpComponent(
        BlocSwapper<CounterCubit>(
          initial: cubit1,
          onState: (s) => swapper = s,
          builder: (cubit) => BlocConsumer<CounterCubit, int>(
            bloc: cubit,
            listener: (_, state) => seen.add(state),
            builder: (_, state) => Component.text('$state'),
          ),
        ),
      );
      expect(find.text('1'), findsOneComponent);

      swapper.swap(cubit2);
      await tester.pump();
      expect(find.text('10'), findsOneComponent);

      cubit2.setValue(20);
      await tester.pump();
      expect(find.text('20'), findsOneComponent);
      expect(seen, [20]);

      // cubit1 was unsubscribed — must not rebuild or notify.
      cubit1.setValue(99);
      await tester.pump();
      expect(find.text('20'), findsOneComponent);
      expect(seen, [20]);
    },
  );
}
