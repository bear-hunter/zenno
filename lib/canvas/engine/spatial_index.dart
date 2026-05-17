import 'package:flutter/widgets.dart';

/// A spatial index over canvas elements, used for viewport culling.
///
/// Maps element ids to their world-space axis-aligned bounds and answers
/// "which elements intersect this rectangle?" without scanning the whole
/// canvas. The committed-layer painter uses [query] to draw only the elements
/// inside the visible world rect, so render cost stays bounded by the viewport
/// rather than by the total element count.
///
/// This is a loose **quadtree**: a recursive spatial partition where each node
/// covers a rectangle and has four child quadrants. An entry is stored in the
/// deepest node that still fully contains it; entries that straddle a child
/// boundary stay at the parent. The tree grows its root outward when an insert
/// falls outside the current world extent, so the canvas is genuinely
/// unbounded. Correctness is the priority here — [query] never misses an
/// intersecting element — with the partitioning as a best-effort speed-up.
///
/// All bounds are in world coordinates. The index does not own or know about
/// [CanvasElement]s; it only tracks ids and rectangles, and the controller
/// keeps it in sync on every add/remove.
class SpatialIndex {
  /// Creates an empty index. The first [insert] seeds the root region.
  SpatialIndex();

  /// Largest number of entries a node holds before it tries to subdivide.
  static const int _nodeCapacity = 8;

  /// Maximum tree depth; past this a node keeps overflowing rather than
  /// splitting, which bounds recursion on degenerate (heavily clustered)
  /// inputs.
  static const int _maxDepth = 12;

  /// Side length of the square region the root covers for the very first
  /// insert. The root expands beyond this as needed.
  static const double _initialRootSize = 4096;

  /// Every id currently in the index, mapped to its stored bounds. The
  /// authoritative record — the tree is a secondary acceleration structure.
  final Map<String, Rect> _bounds = <String, Rect>{};

  /// Root quadtree node, or `null` while the index is empty.
  _QuadNode? _root;

  /// Number of entries in the index.
  int get length => _bounds.length;

  /// Whether the index holds no entries.
  bool get isEmpty => _bounds.isEmpty;

  /// Whether the index holds at least one entry.
  bool get isNotEmpty => _bounds.isNotEmpty;

  /// Inserts (or replaces) the entry [id] with world-space [bounds].
  ///
  /// Re-inserting an existing [id] first removes the stale entry, so the index
  /// can be used as an upsert. The root region is grown to contain [bounds]
  /// when the rectangle falls outside the current extent.
  void insert(String id, Rect bounds) {
    if (_bounds.containsKey(id)) {
      remove(id);
    }
    final Rect normalised = _normalise(bounds);
    _bounds[id] = normalised;

    if (_root == null) {
      _root = _QuadNode(_seedRegion(normalised), 0);
    } else {
      while (!_root!.region.containsRect(normalised)) {
        _root = _root!.grownToward(normalised);
      }
    }
    _root!.insert(id, normalised);
  }

  /// Removes the entry [id] from the index.
  ///
  /// A no-op when [id] is not present. The tree structure is left in place
  /// (nodes are not collapsed); [clear] fully resets it.
  void remove(String id) {
    final Rect? bounds = _bounds.remove(id);
    if (bounds == null || _root == null) {
      return;
    }
    _root!.remove(id, bounds);
  }

  /// Returns the ids of every entry whose bounds intersect [viewport].
  ///
  /// "Intersect" includes touching edges. Order is unspecified. The result is
  /// a superset-free exact answer: an id is returned if and only if its stored
  /// bounds overlap [viewport].
  Iterable<String> query(Rect viewport) {
    final _QuadNode? root = _root;
    if (root == null) {
      return const <String>[];
    }
    final Rect normalised = _normalise(viewport);
    final List<String> hits = <String>[];
    root.query(normalised, hits);
    return hits;
  }

  /// Returns the stored world bounds for [id], or `null` if absent.
  Rect? boundsOf(String id) => _bounds[id];

  /// Removes every entry, resetting the index to empty.
  void clear() {
    _bounds.clear();
    _root = null;
  }

  /// Rebuilds the index from scratch over [entries].
  ///
  /// Equivalent to [clear] followed by an [insert] per entry, but expressed as
  /// one call for the controller's bulk-sync path.
  void rebuild(Iterable<MapEntry<String, Rect>> entries) {
    clear();
    for (final MapEntry<String, Rect> entry in entries) {
      insert(entry.key, entry.value);
    }
  }

  /// Picks the initial square root region around [first].
  ///
  /// Centred on the first entry and at least [_initialRootSize] across, but
  /// always large enough to contain that entry outright.
  static Rect _seedRegion(Rect first) {
    final Offset center = first.center;
    final double half = (_initialRootSize / 2)
        .clamp(first.width, double.infinity)
        .clamp(first.height, double.infinity);
    return Rect.fromCenter(
      center: center,
      width: half * 2,
      height: half * 2,
    );
  }

  /// Returns a finite, non-NaN, normalised copy of [rect].
  ///
  /// Guards the tree against degenerate input (infinite or NaN edges, or a
  /// left/top past right/bottom) which would otherwise break containment math.
  static Rect _normalise(Rect rect) {
    double sanitise(double v) => v.isFinite ? v : 0;
    final double l = sanitise(rect.left);
    final double t = sanitise(rect.top);
    final double r = sanitise(rect.right);
    final double b = sanitise(rect.bottom);
    return Rect.fromLTRB(
      l < r ? l : r,
      t < b ? t : b,
      l < r ? r : l,
      t < b ? b : t,
    );
  }
}

/// One node of the [SpatialIndex] quadtree.
///
/// A node either holds its entries directly (a leaf, or an over-capacity node
/// at [SpatialIndex._maxDepth]) or has subdivided into four [children]
/// quadrants. Entries that span a quadrant boundary are kept on the node
/// itself in [_straddling] rather than pushed to a child.
class _QuadNode {
  /// Creates a leaf node covering [region] at tree depth [depth].
  _QuadNode(this.region, this.depth);

  /// World-space rectangle this node and its subtree are responsible for.
  final Rect region;

  /// Depth of this node below the root (`0` at the root).
  final int depth;

  /// Entries owned directly by this node while it is still a leaf.
  final Map<String, Rect> _entries = <String, Rect>{};

  /// Entries that straddle a child-quadrant boundary, kept here after a split.
  final Map<String, Rect> _straddling = <String, Rect>{};

  /// The four child quadrants once subdivided, else `null` (still a leaf).
  List<_QuadNode>? children;

  /// Whether this node has subdivided into [children].
  bool get _isSplit => children != null;

  /// Inserts [id]/[bounds] into this node's subtree.
  ///
  /// [bounds] is assumed to be contained in [region] (the caller — the index
  /// root, or a parent recursing — guarantees this). A leaf that exceeds
  /// [SpatialIndex._nodeCapacity] subdivides, unless it is already at
  /// [SpatialIndex._maxDepth], in which case it simply keeps the entry.
  void insert(String id, Rect bounds) {
    if (_isSplit) {
      final _QuadNode? child = _childContaining(bounds);
      if (child != null) {
        child.insert(id, bounds);
      } else {
        _straddling[id] = bounds;
      }
      return;
    }

    _entries[id] = bounds;
    if (_entries.length > SpatialIndex._nodeCapacity &&
        depth < SpatialIndex._maxDepth) {
      _subdivide();
    }
  }

  /// Removes [id] (whose [bounds] are known) from this node's subtree.
  void remove(String id, Rect bounds) {
    if (_entries.remove(id) != null) {
      return;
    }
    if (_straddling.remove(id) != null) {
      return;
    }
    if (_isSplit) {
      final _QuadNode? child = _childContaining(bounds);
      if (child != null) {
        child.remove(id, bounds);
      }
    }
  }

  /// Appends to [hits] every id in this subtree whose bounds intersect [area].
  void query(Rect area, List<String> hits) {
    if (!region.intersectsRect(area)) {
      return;
    }
    for (final MapEntry<String, Rect> entry in _entries.entries) {
      if (entry.value.intersectsRect(area)) {
        hits.add(entry.key);
      }
    }
    for (final MapEntry<String, Rect> entry in _straddling.entries) {
      if (entry.value.intersectsRect(area)) {
        hits.add(entry.key);
      }
    }
    final List<_QuadNode>? kids = children;
    if (kids != null) {
      for (final _QuadNode child in kids) {
        child.query(area, hits);
      }
    }
  }

  /// Splits this leaf into four quadrants and redistributes its entries.
  ///
  /// Entries that fully fit one quadrant move down; those straddling a
  /// boundary move into [_straddling] so they are still visited by [query].
  void _subdivide() {
    final double halfW = region.width / 2;
    final double halfH = region.height / 2;
    final double l = region.left;
    final double t = region.top;
    children = <_QuadNode>[
      _QuadNode(Rect.fromLTWH(l, t, halfW, halfH), depth + 1),
      _QuadNode(Rect.fromLTWH(l + halfW, t, halfW, halfH), depth + 1),
      _QuadNode(Rect.fromLTWH(l, t + halfH, halfW, halfH), depth + 1),
      _QuadNode(Rect.fromLTWH(l + halfW, t + halfH, halfW, halfH), depth + 1),
    ];

    final Map<String, Rect> pending = Map<String, Rect>.of(_entries);
    _entries.clear();
    for (final MapEntry<String, Rect> entry in pending.entries) {
      final _QuadNode? child = _childContaining(entry.value);
      if (child != null) {
        child.insert(entry.key, entry.value);
      } else {
        _straddling[entry.key] = entry.value;
      }
    }
  }

  /// Returns the single child quadrant that fully contains [bounds], or `null`
  /// when [bounds] straddles a quadrant boundary.
  _QuadNode? _childContaining(Rect bounds) {
    final List<_QuadNode>? kids = children;
    if (kids == null) {
      return null;
    }
    for (final _QuadNode child in kids) {
      if (child.region.containsRect(bounds)) {
        return child;
      }
    }
    return null;
  }

  /// Returns a new node, double the size of this one, that also contains
  /// [target] — used by the index to grow its root outward.
  ///
  /// The current node becomes one quadrant of the larger node; the larger
  /// node's other three quadrants start empty. Direction is chosen so the new
  /// region extends toward [target].
  _QuadNode grownToward(Rect target) {
    // Extend left/up unless the target lies to the right/below this region.
    final bool extendRight = target.center.dx >= region.center.dx;
    final bool extendDown = target.center.dy >= region.center.dy;

    final double newLeft = extendRight ? region.left : region.left - region.width;
    final double newTop = extendDown ? region.top : region.top - region.height;
    final Rect bigger = Rect.fromLTWH(
      newLeft,
      newTop,
      region.width * 2,
      region.height * 2,
    );

    final _QuadNode parent = _QuadNode(bigger, 0);
    parent._subdivideEmpty();
    // Drop this node's content into the parent so depth restarts cleanly: a
    // freshly grown root re-inserts via the index, so just hand entries up.
    return parent.._absorb(this);
  }

  /// Subdivides this node into four empty quadrants without redistributing.
  void _subdivideEmpty() {
    final double halfW = region.width / 2;
    final double halfH = region.height / 2;
    final double l = region.left;
    final double t = region.top;
    children = <_QuadNode>[
      _QuadNode(Rect.fromLTWH(l, t, halfW, halfH), depth + 1),
      _QuadNode(Rect.fromLTWH(l + halfW, t, halfW, halfH), depth + 1),
      _QuadNode(Rect.fromLTWH(l, t + halfH, halfW, halfH), depth + 1),
      _QuadNode(Rect.fromLTWH(l + halfW, t + halfH, halfW, halfH), depth + 1),
    ];
  }

  /// Re-inserts every entry of [other]'s subtree into this node.
  ///
  /// Used by [grownToward]: when the root doubles, the old subtree's entries
  /// are flattened and re-inserted from the new, larger root so depth and
  /// quadrant assignment are recomputed consistently.
  void _absorb(_QuadNode other) {
    final List<MapEntry<String, Rect>> all = <MapEntry<String, Rect>>[];
    other._collect(all);
    for (final MapEntry<String, Rect> entry in all) {
      insert(entry.key, entry.value);
    }
  }

  /// Appends every (id, bounds) pair in this subtree to [out].
  void _collect(List<MapEntry<String, Rect>> out) {
    out.addAll(_entries.entries);
    out.addAll(_straddling.entries);
    final List<_QuadNode>? kids = children;
    if (kids != null) {
      for (final _QuadNode child in kids) {
        child._collect(out);
      }
    }
  }
}

/// Rectangle containment helper used by the quadtree.
extension _RectContainment on Rect {
  /// Whether this rectangle fully contains [other] (touching edges count).
  bool containsRect(Rect other) {
    return other.left >= left &&
        other.top >= top &&
        other.right <= right &&
        other.bottom <= bottom;
  }

  /// Whether this rectangle intersects [other], counting a shared edge or
  /// corner as touching (unlike [Rect.overlaps], which is strict).
  bool intersectsRect(Rect other) {
    return left <= other.right &&
        right >= other.left &&
        top <= other.bottom &&
        bottom >= other.top;
  }
}
