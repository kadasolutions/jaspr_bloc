import 'package:bloc/bloc.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '_helpers.dart';

class _StringCubit extends Cubit<String> {
  _StringCubit(super.initial);
  void setValue(String v) => emit(v);
}

void main() {
  testBloc('all listeners receive their respective state changes', (
    tester,
  ) async {
    final counter = CounterCubit();
    final label = _StringCubit('a');
    final intSeen = <int>[];
    final strSeen = <String>[];

    tester.pumpComponent(
      MultiBlocListener(
        listeners: [
          BlocListener<CounterCubit, int>(
            bloc: counter,
            listener: (_, s) => intSeen.add(s),
          ),
          BlocListener<_StringCubit, String>(
            bloc: label,
            listener: (_, s) => strSeen.add(s),
          ),
        ],
        child: Component.text('child'),
      ),
    );

    counter.setValue(1);
    await tester.pump();
    label.setValue('b');
    await tester.pump();
    counter.setValue(2);
    await tester.pump();

    expect(intSeen, [1, 2]);
    expect(strSeen, ['b']);
  });

  testBloc('each listener respects its own listenWhen', (tester) async {
    final cubit = CounterCubit();
    final evenSeen = <int>[];
    final oddSeen = <int>[];

    tester.pumpComponent(
      BlocProvider<CounterCubit>.value(
        value: cubit,
        child: MultiBlocListener(
          listeners: [
            BlocListener<CounterCubit, int>(
              listenWhen: (_, c) => c.isEven,
              listener: (_, s) => evenSeen.add(s),
            ),
            BlocListener<CounterCubit, int>(
              listenWhen: (_, c) => c.isOdd,
              listener: (_, s) => oddSeen.add(s),
            ),
          ],
          child: Component.text('child'),
        ),
      ),
    );

    cubit.setValue(1);
    await tester.pump();
    cubit.setValue(2);
    await tester.pump();
    cubit.setValue(3);
    await tester.pump();

    expect(evenSeen, [2]);
    expect(oddSeen, [1, 3]);
  });

  testBloc('renders the child unchanged', (tester) async {
    tester.pumpComponent(
      MultiBlocListener(listeners: [], child: Component.text('hello')),
    );
    await tester.pump();

    expect(find.text('hello'), findsOneComponent);
  });
}
