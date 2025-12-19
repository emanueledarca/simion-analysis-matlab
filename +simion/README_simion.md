# Package `+simion`

Collection of MATLAB functions to analyze SIMION output files (ion optics / beam analysis), designed for thesis work and laboratory/testing pipelines.

This package provides:

- **import** functions returning `table`s,
- **TOF-by-species** analysis tools,
- **beam statistics** (in/out and detector),
- **beam evolution** along X,
- **detector polar maps**,
- utilities to export results to **LaTeX**,
- a high-level `analyzeBeamFile` function to automate a single-file workflow,
- **SRIM** utilities (import + Gaussian fits + LaTeX export).

> All “service” functions live in `+simion/private` and are **not part of the public API**
> (names and interfaces may change).

---

## Installation / Setup

1. Place the repo root (the folder that contains `+simion/`) somewhere you can add to the MATLAB path:

   ```matlab
   addpath('/path/to/repo-root');   % the folder that contains +simion/
   ```

2. Optional: add the same `addpath(...)` line to your `startup.m` to auto-load the package at MATLAB startup.

3. Example scripts (`example_*.m`, `test_importSimion.m`) should live **outside** `+simion/`, e.g.:

   ```text
   my-project/
     +simion/
       (library functions)
     examples/
       example_ImportAndTof.m
       example_BeamAnalysis.m
       example_BeamAnalysis_MultiEnergy.m
       test_importSimion.m
   ```

---

## Basic workflow: SIMION file → per-species TOF

Minimal example: import a SIMION output file and plot TOF by species.

```matlab
fname = "run_8keV.txt";

% 1) High-level import for TOF analysis
T = simion.importSimionTofTable(fname);

% 2) Plot per-species TOF with Gaussian fits (global bins)
FitResults = simion.plotTofBySpecies(T, "pdf", 60);
```

This is essentially what `example_ImportAndTof.m` does.

---

## Full analysis with `analyzeBeamFile`

End-to-end analysis of a single file:

```matlab
fname = "run_8keV.txt";

results = simion.analyzeBeamFile(fname, ...
    'XTolerance', 1e-3, ...
    'Rcenter',    [37.5 0], ...
    'PolarRmax',  20);

% Main fields in results:
%   results.T                  -> raw imported table (all records)
%   results.tofFits            -> TOF fit results
%   results.beamStatsInOut     -> in/out beam stats
%   results.beamStatsDetector  -> detector stats
%   results.polarMap           -> polar maps (if enabled)
```

By default, `analyzeBeamFile` also saves a `.mat` file:

```text
<filename>_results.mat   % contains the "results" struct
```

(Controlled via Name–Value parameters inside the function.)

---

## Main functions

### Import

- `simion.importSimionRecordTable(filename)`  
  Generic SIMION import into a `table`.  
  Normalizes column names (via `canonicalizeSimionNames`) and stores the original names in
  `T.Properties.VariableDescriptions`.

- `simion.importSimionTofTable(filename)`  
  TOF-oriented wrapper: calls `importSimionRecordTable`, checks for required columns
  (`TOF`, `Mass`, `Charge`), and reorders columns putting standard ones first.

- `simion.importSrimTransmit(filenames)`  
  Imports one or more SRIM `TRANSMIT_*.txt` files and fits Gaussian distributions
  (energy, angles, position). Returns:
  - `Data` — cell array of structs with raw tables + species/energy info;
  - `FitResults` — struct array with fit parameters (µ, σ, FWHM, etc.).

---

### Beam analysis

- `simion.analyzeBeamFile(filename, ...)`  
  High-level function that:
  1. imports data (`importSimionTofTable`),
  2. computes **in/out stats** (`computeBeamStatsInOut`),
  3. computes **detector stats** (`computeBeamStatsAtDetector`),
  4. performs **TOF fits per species**,
  5. optionally generates **polar maps** (`plotDetectorPolarMapBySpecies`) and beam evolution plots (`plotBeamEvolutionY/Z`),
  6. saves results to `.mat`.

- `simion.computeBeamStatsInOut(T, ...)`  
  Computes beam stats at the **entrance** (source) and **exit** (detector plane `x_out`) per species:
  counts, µ_y, σ_y, µ_z, σ_z, µ_r, σ_r, etc. Returns a struct with:
  - `SpotBySpecies` — one row per species,
  - `SeparationY` — Y separations between species pairs,
  - `SeparationR` — radial separations between species pairs.

- `simion.computeBeamStatsAtDetector(T, ...)`  
  Statistics at the detector plane only (useful if entrance stats are not needed).

- `simion.computeBeamEvolutionY(inputArg, ...)`  
  Computes longitudinal evolution along X of µ_y(x), σ_y(x) (and optionally µ_z(x), σ_z(x)) per species,
  automatically detecting the x-planes from SIMION data.

- `simion.analyzeTofPathCorrelation(T, Lmin, XTol)`  
  Analyzes the electron **TOF–L** correlation in two selections:
  1. all particles with L ≥ Lmin;
  2. all particles reaching the plane x ≈ Xmax.  
  Returns two structs (`stats_Lmin`, `stats_det`) with summary stats.

---

### Beam / TOF / polar plots

- `simion.plotTofBySpecies(T, mode, nbins, ...)`  
  Single entry point for per-species TOF plots. Internally uses `private` helpers:
  - `mode = "pdf"`         → `plotTofPdfBySpecies`
  - `mode = "hist-global"` → `plotTofHistogramBySpecies`
  - `mode = "hist-local"`  → `plotTofHistogramBySpeciesLocalBins`

  Example:
  ```matlab
  FitResults = simion.plotTofBySpecies(T, "hist-local", 60);
  ```

- `simion.plotFinalSpotBySpecies(T, ...)`  
  Scatter of the final spot at the detector, split by species (XY, XZ, YZ).

- `simion.plotBeamEvolutionY(inputArg, ...)` / `simion.plotBeamEvolutionZ(inputArg, ...)`  
  Plot wrappers around `computeBeamEvolutionY`, producing µ and σ evolution plots.

- `simion.plotDetectorPolarMapBySpecies(T, ...)`  
  Builds a per-species polar density map of impacts on the detector in the YZ plane.

---

### LaTeX export / fit combination

- `simion.beamStatsToLatex(SpotTable, ...)`  
  Exports beam statistics (typically `stats.SpotBySpecies`) to a LaTeX table.

- `simion.beamSeparationToLatex(stats, ...)`  
  Exports separation tables (`stats.SeparationY` / `stats.SeparationR`) to LaTeX.

- `simion.srimFitResultsToLatex(FitResults, outFile)`  
  Exports SRIM fit results to a compact LaTeX table.

- `simion.tableToLatex(Tw, params, outFile, ...)`  
  Converts a “wide” fit table (e.g., from `combineFitStructs`) into a paper-ready LaTeX table.

- `simion.combineFitStructs(fitStructs, labels)`  
  Merges multiple fit structs (e.g., different energies) into a single wide table.

- `simion.srimPlotGaussianCheck(xData, fitParams, quantityLabel, ...)`  
  SRIM utility: histogram + fitted Gaussian, with optional PNG/FIG saving.

---

## Included examples (`example/`)

- `example_ImportAndTof.m` — import + per-species TOF plot.
- `example_BeamAnalysis.m` — full analysis of a single energy via `analyzeBeamFile`.
- `example_BeamAnalysis_MultiEnergy.m` — multi-energy loop + combined LaTeX export.
- `test_importSimion.m` — import sanity checks + final-spot plots.

These scripts are **not** API: they are usage examples to copy/adapt.

---

## Notes

- Functions in `+simion/private` are internal and may change without notice.
- For details on parameters and options, use MATLAB help:

  ```matlab
  help simion.functionName
  ```
