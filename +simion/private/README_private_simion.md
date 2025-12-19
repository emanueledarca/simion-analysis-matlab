# Folder `+simion/private`

This folder contains **internal helper functions** for the `+simion` package.
They are **not** public API: names, signatures, and behavior may change at any time.

Normal users should only rely on the public functions documented in `README_simion.md`
(the ones in `+simion/`).

---

## Internal functions overview

### Column/species normalization

- `canonicalizeSimionNames.m`  
  Normalizes SIMION table headers into a standard set of names such as:
  `IonN`, `Events`, `TOF`, `Time`, `Mass`, `Charge`,
  `X`, `Y`, `Z`, `Vx`, `Vy`, `Vz`, `KE`, `KEError`, etc.  
  Handles multiple aliases (e.g., `Ion Number`, `Ion_N`, ...).

- `classifySpecies.m`  
  Attempts to assign a physical species label (e.g., `"H+"`, `"He2+"`, `"O6+"`, `"e-"`)
  from `Mass`/`Charge` and/or existing columns. Used to build the `Species` column.

- `selectSpecies.m`  
  Convenience filter to keep only a selected subset of species from a table containing `Species`.

- `splitBySpecies.m`  
  Splits a table with a `Species` column into a struct of sub-tables (one per species),
  using MATLAB-safe field names via `matlab.lang.makeValidName`.

---

### “Final hits” / detector plane handling

- `getInitialHitsByIon.m`  
  For each `IonN`, selects the **first** record (typically source / first recorded plane).

- `getFinalHitsByIon.m`  
  For each `IonN`, selects the **last** record (last plane crossed by the particle).

- `getDetectorHitsAtXmax.m`  
  From final hits, selects those actually reaching the detector plane, defined as X ≈ Xmax
  within a tolerance (exposed as `XTolerance` in public functions).

These functions are used, for example, in:
- `computeBeamStatsInOut`
- `computeBeamStatsAtDetector`
- `plotFinalSpotBySpecies`
- `plotDetectorPolarMapBySpecies`

---

### Internal TOF plotting helpers

Do **not** call these directly: the public entry point is `simion.plotTofBySpecies`.

- `plotTofHistogramBySpecies.m` — global bins (same binning for all species).
- `plotTofHistogramBySpeciesInteractive.m` — interactive variant for exploratory analysis.
- `plotTofHistogramBySpeciesLocalBins.m` — local bins (species-adaptive binning).
- `plotTofPdfBySpecies.m` — PDF (continuous line), global bins, normalized to area = 1.

---

## Warning

These functions are meant for internal library use only:

- they are not versioned as public API;
- signatures/names/behavior may change;
- functions may be merged or removed without notice.

If you need similar behavior in a personal script, it is usually better to:
1. check whether a **public** function already covers your use case;
2. otherwise, copy the internal code into your own script (freezing that version),
   instead of depending on the “live” internal implementation.
