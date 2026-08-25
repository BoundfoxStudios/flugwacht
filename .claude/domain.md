# Domain Reference

Binding domain knowledge. The
product is a deliberately minimal tracker for individually added flights; the
one question that matters is "Where are they right now, and when will they
arrive?" – a feature that does not serve it does not belong in the app.

## Fix Normalization (binding)

- `alt_baro` is not always a number: on the ground readsb sends the string
  `"ground"`. The displayed altitude is `alt_baro` (barometric, what ATC and
  flight levels mean), never `alt_geom`.
- Direction is `track` (movement over ground), never `heading` – the nose
  points 10–15° off in a jetstream, and `heading` is not always present.
- Position age is relative: `seen_pos` (seconds) plus the server's `now`
  yields the absolute UTC timestamp. Always use the server time, never the
  local clock, or clock skew leaks into the model.
- Callsigns arrive padded to 8 characters with spaces – always trim before
  any comparison.

## Identity

- The hex address identifies the airframe, not the flight: the same aircraft
  flies further legs the same day. Every hex query cross-checks the returned
  callsign against the expected one; on mismatch the app falls back to the
  callsign search.
- Flight number and callsign are different things (LH400 flies as DLH400);
  an IATA→ICAO airline mapping bridges them. Ryanair, Wizz, and easyJet use
  callsigns unrelated to the flight number – entry by registration or hex is
  the always-available escape hatch, with a UI hint when such an airline is
  detected.
- Stored identity forms and the marketing-digit rule: see the Callsigns
  section in `CLAUDE.md`.

## Route

- Route is not ADS-B data: a transponder sends no origin or destination. The
  route is looked up by callsign in `vradarserver/standing-data` (local copy
  preferred: no network, no latency, no limit), resolved once per flight and
  cached for its duration. Position and route are two different data paths:
  one high-frequency and volatile, one resolved once.
- The dataset holds the planned route only: diversions never appear, charter
  and private flights are often missing entirely. "Route unknown" is a
  regular state, never an error – saving such a flight stays possible, it
  just gets no arrival estimate.
- The dataset's airport column is the aircraft's whole rotation, not one leg:
  CFG1402 reads `EDDF-GCLP-GCFV-EDDF` and actually goes to GCFV. The route is
  the column's first and last entry, so a rotation returning home would name
  its origin as the destination. Which leg was booked is not derivable from
  the data – the same callsign covers every leg – so the app offers the
  chain's consecutive legs and takes the answer from the only source that
  knows it, the user. Until a leg is picked the flight has no route. A chain
  that does not return home keeps its first and last entry, and a repeated
  airport collapses into one, which leaves DLH8985 (`EGTE-EGTE-EGTE`) with a
  single airport and no route (#240, #300).

## Coverage Gaps

Coverage comes from private ground receivers. Over oceans, deserts, and polar
regions the trail breaks off, often for 1–2 hours, and comes back on its own;
this hits all three sources alike. A gap is the regular "no signal" state and
is never presented as an error UI.

## State Machine

- planned → waiting → live ⇄ no signal → ended | missed. The state is derived
  from the flight's facts and the clock at every evaluation, never stored.
- Flight-day window: 00:00 local on the departure day until 24:00 local on
  the following day (nominal 48 h, night flights included), half-open,
  recomputed from calendar components at every evaluation so it crosses
  midnight and DST by construction. The window is deliberately device-local;
  its width absorbs time-zone offsets.
- The live → no signal threshold is generous (15 min) so normal gaps do not
  flicker the display; a position timestamped in the future counts as fresh.
- Approved deviation from the original concept: a landing ends a flight early
  (ever airborne + last known on ground → ended) instead of waiting for the
  window end.
- A landing the app did not witness ends the flight too: without signal, past
  the arrival its last fix pointed at, an airborne flight is ended (#307). The
  app polls in the foreground only and the sources answer for the present
  alone, so the few minutes an aircraft still transmits while it rolls are
  gone for good once they pass unwatched. Both endings are the same state and
  are told apart by the landing timestamp, which only the witnessed one has;
  without it every surface says "probably landed" rather than naming a time.
- An ended flight is normally not polled, with one exception: a landing the
  app only inferred keeps being asked for two hours past that arrival. A fix
  from the ground turns the inference into a witnessed landing, an airborne
  one takes it back. The bound is what keeps the next day's leg of the same
  callsign, which the 48 h window still covers, out of the answer.

## Arrival Estimate

Remaining great-circle distance to the destination divided by ground speed.
It is deliberately rough (no approach procedures, holding, or taxi time), so
it is labeled vaguely ("Ankunft ca.", "~14:32" on stale data) and never
pretends minute precision. Shown in the destination's local time and the
user's time. No route, no estimate – and with no estimate there is no inferred
landing either, so such a flight stays without signal until its window ends.

The estimate is anchored on the fix, not the clock, which is what lets it
outlive the signal. A fix that repeats a moment the flight already stores
therefore never replaces the stored one: readsb answers with bare coordinates
once the fresh fields age out, and taking that would drop the ground speed the
estimate is built on right before the aircraft disappears.

## Sources

- Exactly one active source, chosen by the user – no merging, no parallel
  queries, no failover. The three sources (adsb.lol, adsb.fi, airplanes.live)
  are field-identical readsb aggregators and differ only in receiver
  coverage; the switcher exists for manual comparison.
- Trail points belong to the flight, not the source, and each carries its
  source ID – the trail survives switching and can be colored per source.
- A switch takes effect at once: the poll cadence a flight was running at
  belongs to the source it asked, so choosing another one makes every flight
  due immediately instead of waiting out the former source's interval.
- Rate limit: 1 request per second per source.
- Attribution is visible: the active source is named, plus © OpenStreetMap
  (and © OpenMapTiles while the reduced style renders). The sources are free
  for private, non-commercial use (adsb.lol under ODbL), run by volunteers,
  no SLA.
- Rejected forever, never reintroduce: OpenSky Network (too coarse, credit
  budget too small, no callsign endpoint), an own ADS-B receiver, historical
  tracks (the sources are live snapshots; no after-the-fact retrieval), paid
  or satellite sources.

## Standing Boundaries

Core tracking stays local on the device: no backend, no server, no accounts.
A backend exists only as an optional expansion stage the user explicitly opts
into (#150); the local-only default always keeps working, and starting that
stage is Manu's explicit call.
