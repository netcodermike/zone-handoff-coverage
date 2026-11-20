# Zone Handoff Coverage

Find gaps and overlaps in the assignment schedule for each work zone.

![Sample run from Zone Handoff Coverage](docs/demo.webp)

## Run

Install PowerShell 7 or newer. Run these commands from the repository root.

```sh
pwsh -NoProfile -File app.ps1 sample.json
```

Replace `sample.json` with a JSON file following the same structure. The app prints a JSON report to standard output.

Use a common minute offset and half-open intervals [start, end). Adjacent segments with the same status are merged. Zones are case-sensitive.

## Verify

Run `python check.py` with Python 3.11 or newer after the build step when applicable. The check verifies the bundled scenario and confirms that an invalid input returns an error.
