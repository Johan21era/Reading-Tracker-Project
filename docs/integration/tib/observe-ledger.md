# TB-M0 observation ledger (§22.19.1: 7 days; 0 false-green; append-only)

| ISO stamp | mode | generation | bindings | verdict |
|---|---|---|---|---|
| 2026-10-19T01:50:47Z | verify | `81422613610701d8` | binding verified bin/python3.12: fe2572aa0c87557fc41b07afe929ed39ca4020ce78712f5b952fd099ab7da179, binding verified examples/mirage_sidecar.py: dfb19552368c0f16fa7bd12461110273e8016e8cbc598e075ecdcd6065b7a862, binding verified src/miragev10 (tree digest): b5ca1d35267510bcac93534de610747e82ad13f5678641eed7903bf30eacfd61 | GREEN |
| 2026-10-19T01:50:48Z | tamper-drill | `81422613610701d8` | binding mismatch bin/python3.12: manifest fe2572aa0c87557fc41b07afe929ed39ca4020ce78712f5b952fd099ab7da179 != live 498dad454f7e721beefa0dc49d56ac27b96e5b8534eede923affd66cd08eea15, binding verified examples/mirage_sidecar.py: dfb19552368c0f16fa7bd12461110273e8016e8cbc598e075ecdcd6065b7a862, binding verified src/miragev10 (tree digest): b5ca1d35267510bcac93534de610747e82ad13f5678641eed7903bf30eacfd61, tamper refused, quarantine n/a (observe) | GREEN |
