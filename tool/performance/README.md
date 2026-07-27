# Zenno performance baselines

These scenarios use deterministic synthetic canvas data. They never open or
modify production notes.

Run the structural fixture checks with the normal test suite:

```sh
flutter test test/performance/canvas_performance_baseline_test.dart
```

Record the opt-in host micro-baselines:

```sh
flutter test \
  --dart-define=ZENNO_PERF_BASELINE=true \
  --reporter expanded \
  test/performance/canvas_performance_baseline_test.dart
```

Each measurement is emitted as one `ZENNO_PERF` JSON object. Preserve the
following context with any captured output:

- Git revision
- Flutter version
- host or device model
- build mode
- scenario name
- minimum, median, and maximum microseconds
- structural facts such as total elements and visible spatial hits

Wall-clock values are comparison evidence, not CI assertions. Later
optimization phases add structural regression assertions for candidate counts,
widget rebuild isolation, persistence writes, database queries, and raster
memory. Final frame-time validation runs in profile mode on the Galaxy Tab S9
FE using the same synthetic document shapes.
