import 'package:jaspr/jaspr.dart';

/// Looks up an [InheritedComponent] of type [X] without registering a
/// dependency. Returns `null` if no matching ancestor exists.
X? peekInherited<X extends InheritedComponent>(BuildContext context) =>
    context.getElementForInheritedComponentOfExactType<X>()?.component as X?;
