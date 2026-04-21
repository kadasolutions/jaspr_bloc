import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '_helpers.dart';

class _Repo {
  const _Repo(this.name);
  final String name;
}

void main() {
  testBloc('provides repository to descendants', (tester) async {
    const repo = _Repo('main');

    tester.pumpComponent(
      RepositoryProvider<_Repo>(repository: repo, child: _RepoChild()),
    );
    await tester.pump();

    expect(find.text('main'), findsOneComponent);
  });

  testBloc('of() with listen:false returns the repository value', (
    tester,
  ) async {
    const repo = _Repo('nolisten');

    tester.pumpComponent(
      RepositoryProvider<_Repo>(repository: repo, child: _RepoChild()),
    );
    await tester.pump();

    expect(find.text('nolisten'), findsOneComponent);
  });

  testBloc('throws when no RepositoryProvider ancestor is found', (
    tester,
  ) async {
    tester.pumpComponent(_RepoChild());

    expect(
      tester.takeErrors(),
      contains(
        isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('RepositoryProvider<_Repo> not found'),
        ),
      ),
    );
  });

  testBloc('context.repository returns the correct repository', (tester) async {
    const repo = _Repo('ctx');

    tester.pumpComponent(
      RepositoryProvider<_Repo>(repository: repo, child: _ContextRepoChild()),
    );
    await tester.pump();

    expect(find.text('ctx'), findsOneComponent);
  });

  testBloc(
    'descendants with listen:true rebuild when the repository instance changes',
    (tester) async {
      var builds = 0;
      late _RepoSwapperState swapper;

      tester.pumpComponent(
        _RepoSwapper(
          initial: const _Repo('v1'),
          onState: (s) => swapper = s,
          child: _ListeningRepoChild(onBuild: () => builds++),
        ),
      );
      await tester.pump();
      expect(builds, 1);
      expect(find.text('v1'), findsOneComponent);

      // New instance → updateShouldNotify returns true → dependent rebuilds.
      swapper.swap(const _Repo('v2'));
      await tester.pump();
      expect(builds, 2);
      expect(find.text('v2'), findsOneComponent);

      // Same instance → updateShouldNotify returns false → no extra rebuild.
      swapper.swap(const _Repo('v2'));
      await tester.pump();
      expect(builds, 2);
    },
  );
}

class _RepoSwapper extends StatefulComponent {
  const _RepoSwapper({
    required this.initial,
    required this.child,
    required this.onState,
  });

  final _Repo initial;
  final Component child;
  final void Function(_RepoSwapperState state) onState;

  @override
  State<_RepoSwapper> createState() => _RepoSwapperState();
}

class _RepoSwapperState extends State<_RepoSwapper> {
  late _Repo _repo;

  @override
  void initState() {
    super.initState();
    _repo = component.initial;
    component.onState(this);
  }

  void swap(_Repo newRepo) => setState(() => _repo = newRepo);

  @override
  Component build(BuildContext context) {
    return RepositoryProvider<_Repo>(repository: _repo, child: component.child);
  }
}

class _ListeningRepoChild extends StatelessComponent {
  const _ListeningRepoChild({required this.onBuild});

  final void Function() onBuild;

  @override
  Component build(BuildContext context) {
    onBuild();
    final repo = RepositoryProvider.of<_Repo>(context); // listen: true
    return Component.text(repo.name);
  }
}

class _RepoChild extends StatelessComponent {
  @override
  Component build(BuildContext context) {
    final repo = RepositoryProvider.of<_Repo>(context, listen: false);
    return Component.text(repo.name);
  }
}

class _ContextRepoChild extends StatelessComponent {
  @override
  Component build(BuildContext context) {
    final repo = context.repository<_Repo>();
    return Component.text(repo.name);
  }
}
