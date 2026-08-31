# Repository Instructions

- Treat `deploy/winner-4096.yaml` as the measured incumbent.
- Keep the model revision, eight-H100 ceiling, trace, timestamps, request count, and TTFT/ITL thresholds fixed for direct comparisons.
- Create one direct `deploy/<candidate>.yaml` per candidate and change one independently testable lever.
- Follow the optimization workflow from a Dynamo source checkout; this repository records the experiment and its reproducible inputs, not a copy of NVIDIA's skillpack.
- Promote only audited, zero-error strict-goodput improvements.
- Never commit credentials, cluster identifiers, raw HTTP traces, pod logs, node names, IPs, UIDs, or local artifact directories.
- Add only reviewed aggregate results to `results/reference-results.json` and run `./scripts/validate-repository.sh` before committing.
