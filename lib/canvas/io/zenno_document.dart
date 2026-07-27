import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' show Offset, Rect, Size;

import 'package:zenno/canvas/canvas_controller.dart';
import 'package:zenno/canvas/model/canvas_element.dart';
import 'package:zenno/canvas/model/canvas_layer.dart';
import 'package:zenno/canvas/model/canvas_style.dart';
import 'package:zenno/canvas/model/stroke.dart';
import 'package:zenno/canvas/model/viewport_state.dart';
import 'package:zenno/core/database/tables/canvas_tables.dart';

class ZennoDocument {
  const ZennoDocument({
    required this.version,
    required this.paperStyle,
    required this.viewport,
    required this.layers,
    required this.elements,
  });

  final int version;
  final CanvasPaperStyle paperStyle;
  final ViewportState viewport;
  final List<CanvasLayer> layers;
  final List<CanvasElement> elements;
}

abstract final class ZennoDocumentCodec {
  static const int currentVersion = 1;
  static const String format = 'zenno.canvas';

  static Uint8List encodeController(CanvasController controller) {
    return encodeDocument(
      ZennoDocument(
        version: currentVersion,
        paperStyle: controller.paperStyle,
        viewport: controller.viewport,
        layers: controller.layers,
        elements: controller.elements,
      ),
    );
  }

  static Uint8List encodeDocument(ZennoDocument document) {
    final Map<String, Object?> payload = <String, Object?>{
      'format': format,
      'version': document.version,
      'paperStyle': _paperToJson(document.paperStyle),
      'viewport': _viewportToJson(document.viewport),
      'layers': <Object?>[
        for (final CanvasLayer layer in document.layers) _layerToJson(layer),
      ],
      'elements': <Object?>[
        for (final CanvasElement element in document.elements)
          _elementToJson(element),
      ],
    };
    return Uint8List.fromList(utf8.encode(jsonEncode(payload)));
  }

  static ZennoDocument decodeDocument(Uint8List bytes) {
    final Object? decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map<String, Object?> || decoded['format'] != format) {
      throw const FormatException('Not a Zenno canvas document.');
    }
    final int version = (decoded['version'] as num?)?.toInt() ?? 0;
    if (version < 1 || version > currentVersion) {
      throw FormatException('Unsupported Zenno document version $version.');
    }
    return ZennoDocument(
      version: version,
      paperStyle: _paperFromJson(_map(decoded['paperStyle'])),
      viewport: _viewportFromJson(_map(decoded['viewport'])),
      layers: <CanvasLayer>[
        for (final Object? item in _list(decoded['layers']))
          _layerFromJson(_map(item)),
      ],
      elements: <CanvasElement>[
        for (final Object? item in _list(decoded['elements']))
          _elementFromJson(_map(item)),
      ],
    );
  }

  static Map<String, Object?> _paperToJson(CanvasPaperStyle style) {
    return <String, Object?>{
      'kind': style.kind.name,
      'backgroundColor': style.backgroundColor,
      'gridColor': style.gridColor,
      'gridSpacing': style.gridSpacing,
      'gridOpacity': style.gridOpacity,
      'graphMajorInterval': style.graphMajorInterval,
      'texture': style.texture.name,
      'textureOpacity': style.textureOpacity,
    };
  }

  static CanvasPaperStyle _paperFromJson(Map<String, Object?> json) {
    return CanvasPaperStyle(
      kind: _enumByName(
        BackgroundKind.values,
        json['kind'],
        BackgroundKind.grid,
      ),
      backgroundColor: _int(json['backgroundColor'], 0xFF172331),
      gridColor: _int(json['gridColor'], 0xFFFFFFFF),
      gridSpacing: _double(json['gridSpacing'], 48),
      gridOpacity: _double(json['gridOpacity'], 0.14),
      graphMajorInterval: _int(json['graphMajorInterval'], 4),
      texture: _enumByName(
        PaperTexture.values,
        json['texture'],
        PaperTexture.clean,
      ),
      textureOpacity: _double(json['textureOpacity'], 0.06),
    );
  }

  static Map<String, Object?> _viewportToJson(ViewportState viewport) {
    return <String, Object?>{
      'translation': _offsetToJson(viewport.translation),
      'scale': viewport.scale,
      'rotation': viewport.rotation,
    };
  }

  static ViewportState _viewportFromJson(Map<String, Object?> json) {
    return ViewportState(
      translation: _offsetFromJson(_map(json['translation'])),
      scale: _double(json['scale'], 1),
      rotation: _double(json['rotation'], 0),
    );
  }

  static Map<String, Object?> _layerToJson(CanvasLayer layer) {
    return <String, Object?>{
      'id': layer.id,
      'canvasId': layer.canvasId,
      'name': layer.name,
      'position': layer.position,
      'visible': layer.visible,
      'locked': layer.locked,
      'opacity': layer.opacity,
      'blendMode': layer.blendMode,
      'kind': layer.kind.name,
    };
  }

  static CanvasLayer _layerFromJson(Map<String, Object?> json) {
    return CanvasLayer(
      id: _string(json['id']),
      canvasId: _string(json['canvasId']),
      name: _string(json['name'], 'Layer'),
      position: _double(json['position'], 0),
      visible: _bool(json['visible'], fallback: true),
      locked: _bool(json['locked']),
      opacity: _double(json['opacity'], 1),
      blendMode: _string(json['blendMode'], 'srcOver'),
      kind: _enumByName(
        CanvasLayerKind.values,
        json['kind'],
        CanvasLayerKind.content,
      ),
    );
  }

  static Map<String, Object?> _elementToJson(CanvasElement element) {
    final Map<String, Object?> base = <String, Object?>{
      'id': element.id,
      'zIndex': element.zIndex,
      'layerId': element.layerId,
      'rotation': element.rotation,
    };
    return switch (element) {
      InkElement() => <String, Object?>{
        ...base,
        'type': 'ink',
        'stroke': _strokeToJson(element.stroke),
      },
      ShapeElement() => <String, Object?>{
        ...base,
        'type': 'shape',
        'shapeKind': element.shapeKind,
        'start': _offsetToJson(element.start),
        'end': _offsetToJson(element.end),
        'color': element.color,
        'strokeWidth': element.strokeWidth,
        'arrowBody': element.arrowBody.name,
        'arrowStartHead': element.arrowStartHead.name,
        'arrowEndHead': element.arrowEndHead.name,
        'arrowHeadScale': element.arrowHeadScale,
        'controlPoints': <Object?>[
          for (final Offset point in element.controlPoints)
            _offsetToJson(point),
        ],
        'legacyArrow': element.legacyArrow,
      },
      ImageElement() => <String, Object?>{
        ...base,
        'type': 'image',
        'bounds': _rectToJson(element.placementBounds),
        'sourceFilePath': element.sourceFilePath,
        'intrinsicSize': _sizeToJson(element.intrinsicSize),
      },
      PdfElement() => <String, Object?>{
        ...base,
        'type': 'pdf',
        'bounds': _rectToJson(element.placementBounds),
        'sourceFilePath': element.sourceFilePath,
        'pageNumber': element.pageNumber,
        'pageSize': _sizeToJson(element.pageSize),
      },
      LinkElement() => <String, Object?>{
        ...base,
        'type': 'link',
        'bounds': _rectToJson(element.placementBounds),
        'label': element.label,
        'target': <String, Object?>{
          'targetCanvasId': element.target.targetCanvasId,
          'targetViewport': element.target.targetViewport == null
              ? null
              : _viewportToJson(element.target.targetViewport!),
        },
      },
      TextElement() => <String, Object?>{
        ...base,
        'type': 'text',
        'bounds': _rectToJson(element.placementBounds),
        'text': element.text,
        'color': element.color,
        'fontSize': element.fontSize,
      },
    };
  }

  static CanvasElement _elementFromJson(Map<String, Object?> json) {
    final String id = _string(json['id']);
    final int zIndex = _int(json['zIndex'], 0);
    final String? layerId = json['layerId'] as String?;
    final double rotation = _double(json['rotation'], 0);
    return switch (_string(json['type'])) {
      'ink' => InkElement(
        id: id,
        zIndex: zIndex,
        layerId: layerId,
        rotation: rotation,
        stroke: _strokeFromJson(_map(json['stroke'])),
      ),
      'shape' => ShapeElement(
        id: id,
        zIndex: zIndex,
        layerId: layerId,
        rotation: rotation,
        shapeKind: _int(json['shapeKind'], 0),
        start: _offsetFromJson(_map(json['start'])),
        end: _offsetFromJson(_map(json['end'])),
        color: _int(json['color'], 0xFFFFFFFF),
        strokeWidth: _double(json['strokeWidth'], 4),
        arrowBody: _enumByName(
          ArrowBodyKind.values,
          json['arrowBody'],
          ArrowBodyKind.straight,
        ),
        arrowStartHead: _enumByName(
          ArrowHeadStyle.values,
          json['arrowStartHead'],
          ArrowHeadStyle.none,
        ),
        arrowEndHead: _enumByName(
          ArrowHeadStyle.values,
          json['arrowEndHead'],
          ArrowHeadStyle.filled,
        ),
        arrowHeadScale: _double(json['arrowHeadScale'], 1),
        controlPoints: <Offset>[
          for (final Object? point in _list(json['controlPoints']))
            _offsetFromJson(_map(point)),
        ],
        legacyArrow: _bool(json['legacyArrow'], fallback: true),
      ),
      'image' => ImageElement(
        id: id,
        zIndex: zIndex,
        layerId: layerId,
        rotation: rotation,
        worldBounds: _rectFromJson(_map(json['bounds'])),
        sourceFilePath: _string(json['sourceFilePath']),
        intrinsicSize: _sizeFromJson(_map(json['intrinsicSize'])),
      ),
      'pdf' => PdfElement(
        id: id,
        zIndex: zIndex,
        layerId: layerId,
        rotation: rotation,
        worldBounds: _rectFromJson(_map(json['bounds'])),
        sourceFilePath: _string(json['sourceFilePath']),
        pageNumber: _int(json['pageNumber'], 1),
        pageSize: _sizeFromJson(_map(json['pageSize'])),
      ),
      'link' => _linkFromJson(id, zIndex, layerId, rotation, json),
      'text' => TextElement(
        id: id,
        zIndex: zIndex,
        layerId: layerId,
        rotation: rotation,
        worldBounds: _rectFromJson(_map(json['bounds'])),
        text: _string(json['text']),
        color: _int(json['color'], 0xFFFFFFFF),
        fontSize: _double(json['fontSize'], 22),
      ),
      _ => throw FormatException('Unsupported element type ${json['type']}.'),
    };
  }

  static LinkElement _linkFromJson(
    String id,
    int zIndex,
    String? layerId,
    double rotation,
    Map<String, Object?> json,
  ) {
    final Map<String, Object?> target = _map(json['target']);
    final Object? targetViewport = target['targetViewport'];
    return LinkElement(
      id: id,
      zIndex: zIndex,
      layerId: layerId,
      rotation: rotation,
      worldBounds: _rectFromJson(_map(json['bounds'])),
      label: _string(json['label']),
      target: LinkTarget(
        targetCanvasId: _string(target['targetCanvasId']),
        targetViewport: targetViewport == null
            ? null
            : _viewportFromJson(_map(targetViewport)),
      ),
    );
  }

  static Map<String, Object?> _strokeToJson(Stroke stroke) {
    return <String, Object?>{
      'id': stroke.id,
      'color': stroke.color,
      'width': stroke.width,
      'tool': stroke.tool.name,
      'points': <Object?>[
        for (final StrokePoint point in stroke.points)
          <String, Object?>{
            'x': point.x,
            'y': point.y,
            'pressure': point.pressure,
            'tiltX': point.tiltX,
            'tiltY': point.tiltY,
            'azimuth': point.azimuth,
            'timestampMicros': point.timestampMicros,
            'velocity': point.velocity,
          },
      ],
    };
  }

  static Stroke _strokeFromJson(Map<String, Object?> json) {
    return Stroke(
      id: _string(json['id']),
      points: <StrokePoint>[
        for (final Object? point in _list(json['points']))
          _strokePointFromJson(_map(point)),
      ],
      color: _int(json['color'], 0xFFFFFFFF),
      width: _double(json['width'], 4),
      tool: _enumByName(
        StrokeToolKind.values,
        json['tool'],
        StrokeToolKind.pen,
      ),
    );
  }

  static StrokePoint _strokePointFromJson(Map<String, Object?> json) {
    return StrokePoint(
      _double(json['x'], 0),
      _double(json['y'], 0),
      _double(json['pressure'], 0.5),
      tiltX: _double(json['tiltX'], 0),
      tiltY: _double(json['tiltY'], 0),
      azimuth: _double(json['azimuth'], 0),
      timestampMicros: _int(json['timestampMicros'], 0),
      velocity: _double(json['velocity'], 0),
    );
  }

  static Map<String, Object?> _rectToJson(Rect rect) {
    return <String, Object?>{
      'left': rect.left,
      'top': rect.top,
      'width': rect.width,
      'height': rect.height,
    };
  }

  static Rect _rectFromJson(Map<String, Object?> json) {
    return Rect.fromLTWH(
      _double(json['left'], 0),
      _double(json['top'], 0),
      _double(json['width'], 0),
      _double(json['height'], 0),
    );
  }

  static Map<String, Object?> _offsetToJson(Offset offset) {
    return <String, Object?>{'dx': offset.dx, 'dy': offset.dy};
  }

  static Offset _offsetFromJson(Map<String, Object?> json) {
    return Offset(_double(json['dx'], 0), _double(json['dy'], 0));
  }

  static Map<String, Object?> _sizeToJson(Size size) {
    return <String, Object?>{'width': size.width, 'height': size.height};
  }

  static Size _sizeFromJson(Map<String, Object?> json) {
    return Size(_double(json['width'], 0), _double(json['height'], 0));
  }

  static T _enumByName<T extends Enum>(
    List<T> values,
    Object? value,
    T fallback,
  ) {
    if (value is! String) {
      return fallback;
    }
    for (final T candidate in values) {
      if (candidate.name == value) {
        return candidate;
      }
    }
    return fallback;
  }

  static Map<String, Object?> _map(Object? value) {
    if (value is Map) {
      return value.cast<String, Object?>();
    }
    return const <String, Object?>{};
  }

  static List<Object?> _list(Object? value) {
    if (value is List) {
      return value.cast<Object?>();
    }
    return const <Object?>[];
  }

  static String _string(Object? value, [String fallback = '']) {
    return value is String ? value : fallback;
  }

  static int _int(Object? value, int fallback) {
    return value is num ? value.toInt() : fallback;
  }

  static double _double(Object? value, double fallback) {
    return value is num ? value.toDouble() : fallback;
  }

  static bool _bool(Object? value, {bool fallback = false}) {
    return value is bool ? value : fallback;
  }
}
