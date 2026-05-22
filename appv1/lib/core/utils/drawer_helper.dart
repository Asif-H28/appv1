import 'package:flutter/material.dart';

/// Finds the nearest ancestor [ScaffoldState] that has a drawer.
ScaffoldState? findParentScaffoldWithDrawer(BuildContext context) {
  ScaffoldState? parentScaffold;
  context.visitAncestorElements((element) {
    if (element.widget is Scaffold) {
      final state = (element as StatefulElement).state;
      if (state is ScaffoldState && state.hasDrawer) {
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
