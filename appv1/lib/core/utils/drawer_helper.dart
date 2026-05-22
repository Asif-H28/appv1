import 'package:flutter/material.dart';

/// Global key for the teacher main screen scaffold to open the drawer reliably.
final GlobalKey<ScaffoldState> teacherScaffoldKey = GlobalKey<ScaffoldState>();

/// Finds the nearest ancestor [ScaffoldState] that has a drawer.
ScaffoldState? findParentScaffoldWithDrawer(BuildContext context) {
  ScaffoldState? parentScaffold;
  context.visitAncestorElements((element) {
    if (element is StatefulElement && element.state is ScaffoldState) {
      final state = element.state as ScaffoldState;
      if (state.hasDrawer) {
        parentScaffold = state;
        return false; // Stop traversing
      }
    }
    return true; // Continue traversing
  });
  return parentScaffold;
}

/// Opens the drawer of the nearest ancestor [ScaffoldState] that has a drawer.
void openParentDrawer(BuildContext context) {
  // First, try using the global teacher scaffold key
  if (teacherScaffoldKey.currentState != null) {
    teacherScaffoldKey.currentState!.openDrawer();
    return;
  }

  // Fallback to element tree traversal
  final scaffold = findParentScaffoldWithDrawer(context);
  if (scaffold != null) {
    scaffold.openDrawer();
  } else {
    try {
      Scaffold.of(context).openDrawer();
    } catch (_) {
      debugPrint('[drawer_helper] Failed to open drawer: No drawer found in context.');
    }
  }
}
