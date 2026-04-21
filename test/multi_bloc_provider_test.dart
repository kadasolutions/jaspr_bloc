import 'package:bloc/bloc.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '_helpers.dart';

class _StringCubit extends Cubit<String> {
  _StringCubit(super.initial);
}

void main() {
  testBloc('provides all blocs to descendants', (tester) async {
    final counter = CounterCubit(1);
    final label = _StringCubit('hello');

    tester.pumpComponent(
      MultiBlocProvider(
        providers: [
          BlocProvider<CounterCubit>.value(value: counter),
          BlocProvider<_StringCubit>.value(value: label),
        ],
        child: _MultiReadChild(),
      ),
    );
    await tester.pump();

    expect(find.text('1:hello'), findsOneComponent);
  });

  testBloc('first provider becomes the outermost ancestor', (tester) async {
    final a = CounterCubit(10);

    tester.pumpComponent(
      MultiBlocProvider(
        providers: [BlocProvider<CounterCubit>.value(value: a)],
        child: BlocBuilder<CounterCubit, int>(
          builder: (_, v) => Component.text('$v'),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('10'), findsOneComponent);
  });

  testBloc('empty providers list renders the child unchanged', (tester) async {
    tester.pumpComponent(
      MultiBlocProvider(providers: [], child: Component.text('hello')),
    );
    await tester.pump();

    expect(find.text('hello'), findsOneComponent);
  });
}

class _MultiReadChild extends StatelessComponent {
  @override
  Component build(BuildContext context) {
    final n = BlocProvider.of<CounterCubit>(context, listen: false).state;
    final s = BlocProvider.of<_StringCubit>(context, listen: false).state;
    return Component.text('$n:$s');
  }
}
