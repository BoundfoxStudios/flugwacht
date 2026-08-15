# Bundled data

## `airlines.csv`

A byte-identical copy of
[`vradarserver/standing-data`](https://github.com/vradarserver/standing-data),
`airlines/schema-01/airlines.csv` on branch `main`, licensed CC0 1.0 — the
UTF-8 byte order mark upstream writes is part of the copy.

`AirlineDirectory` reads the file from the asset bundle and answers the
IATA→ICAO question the callsigns are built from. The route and airport files of
the same dataset are deliberately not bundled; they are fetched per flight.

The `Airline Directory` workflow
([`.github/workflows/airline-directory.yml`](../../../.github/workflows/airline-directory.yml))
compares this copy with upstream once a day and opens a pull request when the
two differ. Upstream changes the file roughly monthly. To refresh it by hand:

```sh
curl -o app/assets/data/airlines.csv \
  https://raw.githubusercontent.com/vradarserver/standing-data/main/airlines/schema-01/airlines.csv
```
