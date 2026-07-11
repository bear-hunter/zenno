import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'package:zenno/canvas/model/viewport_state.dart';
import 'package:zenno/config/router/routes.dart';

/// Opens [canvasId] without creating a second live editor for the same canvas.
///
/// A new destination is pushed normally, preserving Back through a chain of
/// linked canvases. If that canvas already has a mounted editor lower in the
/// route stack, editors above it are closed through their normal guarded Back
/// flow and the existing editor receives [targetViewport]. Rapid duplicate
/// opens are coalesced until the first route has mounted.
Future<T?> openCanvasEditor<T>(
  BuildContext context,
  String canvasId, {
  ViewportState? targetViewport,
}) {
  return CanvasEditorNavigation.open<T>(
    context,
    canvasId,
    targetViewport: targetViewport,
  );
}

/// Coordinates mounted Canvas editor routes and in-flight route pushes.
abstract final class CanvasEditorNavigation {
  static final Map<String, CanvasEditorRouteRegistration> _byCanvasId =
      <String, CanvasEditorRouteRegistration>{};
  static final List<CanvasEditorRouteRegistration> _routeStack =
      <CanvasEditorRouteRegistration>[];
  static final Set<String> _openingCanvasIds = <String>{};

  static CanvasEditorRouteRegistration register({
    required String canvasId,
    required ModalRoute<dynamic> route,
    required bool Function() isMounted,
    required Future<bool> Function() close,
    required void Function(ViewportState viewport) applyViewport,
  }) {
    final CanvasEditorRouteRegistration registration =
        CanvasEditorRouteRegistration._(
          canvasId: canvasId,
          route: route,
          isMounted: isMounted,
          close: close,
          applyViewport: applyViewport,
        );
    final CanvasEditorRouteRegistration? previous = _byCanvasId[canvasId];
    if (previous != null && !previous.isActive) {
      _remove(previous);
    }
    _byCanvasId[canvasId] = registration;
    _routeStack.add(registration);
    return registration;
  }

  static Future<T?> open<T>(
    BuildContext context,
    String canvasId, {
    ViewportState? targetViewport,
  }) async {
    final CanvasEditorRouteRegistration? existing = _activeEditor(canvasId);
    if (existing != null) {
      final int targetIndex = _routeStack.indexOf(existing);
      if (targetIndex < 0) {
        _remove(existing);
      } else {
        final List<CanvasEditorRouteRegistration> above = _routeStack
            .sublist(targetIndex + 1)
            .reversed
            .toList(growable: false);
        for (final CanvasEditorRouteRegistration registration in above) {
          if (!registration.isActive) {
            _remove(registration);
            continue;
          }
          if (!await registration.close()) {
            return null;
          }
        }
        if (existing.isActive && targetViewport != null) {
          existing.applyViewport(targetViewport);
        }
        return null;
      }
    }

    if (!_openingCanvasIds.add(canvasId)) {
      return null;
    }
    try {
      if (!context.mounted) {
        return null;
      }
      return await context.push<T>(
        Routes.canvasPath(canvasId),
        extra: targetViewport,
      );
    } finally {
      _openingCanvasIds.remove(canvasId);
    }
  }

  static CanvasEditorRouteRegistration? _activeEditor(String canvasId) {
    final CanvasEditorRouteRegistration? registration = _byCanvasId[canvasId];
    if (registration == null) {
      return null;
    }
    if (!registration.isActive) {
      _remove(registration);
      return null;
    }
    return registration;
  }

  static void _remove(CanvasEditorRouteRegistration registration) {
    if (identical(_byCanvasId[registration.canvasId], registration)) {
      _byCanvasId.remove(registration.canvasId);
    }
    _routeStack.remove(registration);
  }
}

/// Registration owned by one mounted [CanvasEditorPage] route.
final class CanvasEditorRouteRegistration {
  CanvasEditorRouteRegistration._({
    required this.canvasId,
    required this.route,
    required bool Function() isMounted,
    required Future<bool> Function() close,
    required void Function(ViewportState viewport) applyViewport,
  }) : _isMounted = isMounted,
       _close = close,
       _applyViewport = applyViewport;

  final String canvasId;
  final ModalRoute<dynamic> route;
  final bool Function() _isMounted;
  final Future<bool> Function() _close;
  final void Function(ViewportState viewport) _applyViewport;
  bool _disposed = false;

  bool get isActive => !_disposed && _isMounted() && route.isActive;

  Future<bool> close() => _close();

  void applyViewport(ViewportState viewport) => _applyViewport(viewport);

  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    CanvasEditorNavigation._remove(this);
  }
}
