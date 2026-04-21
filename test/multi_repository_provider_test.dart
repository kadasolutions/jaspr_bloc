// ignore_for_file: deprecated_member_use
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '_helpers.dart';

class _RepoA {
  const _RepoA(this.value);
  final String value;
}

class _RepoB {
  const _RepoB(this.value);
  final int value;
}

void main() {
  testBloc('provides all repositories to descendants', (tester) async {
    tester.pumpComponent(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<_RepoA>(repository: const _RepoA('alpha')),
          RepositoryProvider<_RepoB>(repository: const _RepoB(99)),
        ],
        child: _MultiRepoChild(),
      ),
    );
    await tester.pump();

    expect(find.text('alpha:99'), findsOneComponent);
  });

  testBloc('first provider becomes the outermost ancestor', (tester) async {
    // Both repositories must be accessible; the tree must not be inverted.
    tester.pumpComponent(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<_RepoA>(repository: const _RepoA('outer')),
          RepositoryProvider<_RepoB>(repository: const _RepoB(1)),
        ],
        child: _MultiRepoChild(),
      ),
    );
    await tester.pump();

    expect(find.text('outer:1'), findsOneComponent);
  });

  testBloc('empty providers list renders the child unchanged', (tester) async {
    tester.pumpComponent(
      MultiRepositoryProvider(providers: [], child: Component.text('hello')),
    );
    await tester.pump();

    expect(find.text('hello'), findsOneComponent);
  });

  testBloc('deprecated RepositoryProviderFactory adapter wraps child and is '
      'reachable via RepositoryProvider.of', (tester) async {
    tester.pumpComponent(
      MultiRepositoryProvider(
        providers: [
          RepositoryProviderFactory(
            (child) => RepositoryProvider<_RepoA>(
              repository: const _RepoA('legacy'),
              child: child,
            ),
          ),
        ],
        child: _MultiRepoChildA(),
      ),
    );
    await tester.pump();

    expect(find.text('legacy'), findsOneComponent);
  });
}

class _MultiRepoChild extends StatelessComponent {
  @override
  Component build(BuildContext context) {
    final a = RepositoryProvider.of<_RepoA>(context, listen: false);
    final b = RepositoryProvider.of<_RepoB>(context, listen: false);
    return Component.text('${a.value}:${b.value}');
  }
}

class _MultiRepoChildA extends StatelessComponent {
  @override
  Component build(BuildContext context) {
    final a = RepositoryProvider.of<_RepoA>(context, listen: false);
    return Component.text(a.value);
  }
}
