---
title: FAQ ❓
---
## Why are there SI, IEC, and JEDEC standards?

- SI: 1000-based (KB, MB, GB…) common in storage vendors.
- IEC: 1024-based (KiB, MiB…) precise binary units.
- JEDEC: 1024-based but using KB/MB/GB symbols (commonly seen in OS UIs).

## Does `toString()` auto-scale?

Yes. Both `ByteConverter` and `BigByteConverter` choose a best-fit unit.

## When should I use `BigByteConverter`?

When numbers exceed safe double precision or you need exact integer math across very large magnitudes (EB/ZB/YB, EiB/ZiB/YiB).

## How do I force bits or bytes?

Use `useBytes: false` to format in bits, or pass a bit unit in `forceUnit` (e.g., `Mb`, `Kib`). For sizes, `ByteFormatOptions(useBytes: true)` forces bytes.

## Can I localize the decimal separator and spacing?

Yes—use `separator` and `spacer`. You can also choose min/max fraction digits.

## How do I parse inputs with words (e.g., "megabytes")?

Full-form unit names are supported and normalized under the hood.

## How do I keep the wiki in sync?

Use the provided VS Code tasks under Run Task → "Wiki: …" to pull/push changes.

See also: [Troubleshooting](/guides/troubleshooting/) for common issues and fixes.
