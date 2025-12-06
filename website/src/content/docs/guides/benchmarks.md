---
title: Benchmarks
---
Microbenchmarks measured on this machine.

- OS: windows
- CPU cores: 12
- Dart: 3.9.2
- Seed: 1337
- Iterations: 20000
- Warmup: 2000
- Rounds: 3
- Best-of: 2

## Core operations
Competitor for humanize: `filesize`
| Task | ByteConverter (ops/s) | filesize (ops/s) |
| --- | --- | --- |
| Humanize (SI, bytes) | 3.3M | 4.0M |
| Humanize (SI, bytes, locale+grouping) | 2.1M | — |
| Humanize (IEC, bits) | 2.1M | — |
| Parse (sizes) | 574.7k | — |
| Rate humanize (/min) | 6.1M | — |
| Compound (mixed units) | 480.3k | — |
| BigByteConverter humanize | 2.3M | — |
| Humanize localized (en) | 1.5M | — |
| Pattern formatting | 638.6k | — |


## Streaming quantiles
| Task | Throughput (ops/s) |
| --- | --- |
| P² ingest ops/s | 1.3M |
| TDigest ingest ops/s | 78.9k |


## Competitor coverage
| Feature | ByteConverter | Competitor(s) | Included? |
| --- | --- | --- | --- |
| Humanize (SI, bytes) | Yes | `filesize` | Yes |
| Humanize (IEC, bits) | Yes | — | — |
| Pattern formatting | Yes | — | — |
| Compound formatting | Yes | — | — |
| Parsing sizes | Yes | — | — |
| Parsing data rates | Yes | — | — |
| Rate humanize | Yes | — | — |
| BigInt precision | Yes | — | — |
| Streaming quantiles | Yes (P², TDigest) | — (external TDigest libs may exist) | Compared internal P² vs TDigest |


## Notes
- Methodology: median of ROUNDS timed rounds over ITERATIONS iterations, after ~WARMUP warmup calls; overall result is best-of BESTOF runs.
- Values: ROUNDS=3, ITERATIONS=20000, WARMUP=2000, BESTOF=2, SEED=1337
- The competitor `filesize` is a focused formatter for SI bytes and returns a string; it does not handle IEC bits, compound, parsing, or rates.
- ByteConverter supports many options (IEC/SI/JEDEC, bits/bytes, locale/grouping, NBSP, fixed width, patterns, compound, parsing, rates, BigInt). Some options (e.g., locale/grouping) add overhead as shown in the locale+grouping row.
- Microbenchmarks can vary across machines and runs. Consider running this script locally to compare on your environment.
- Repro tips (Windows): use High Performance/Ultimate power plan, plug in AC power on laptops, close background apps, and run a few times (best-of) to reduce scheduler noise.
