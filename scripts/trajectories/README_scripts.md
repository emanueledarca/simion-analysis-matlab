# Analysis scripts (`scripts/`) — README

This folder contains MATLAB **scripts** (not functions) meant to be run directly for common analyses.
They are built on top of the **`+simion`** toolbox in this repository.

> Note: these are project-oriented scripts. They typically assume a project folder layout
> (e.g., `Trajectories/` with `data_raw/`, `data_processed/`, `figures/`). If your layout differs,
> edit the “inputs/paths” section at the top of each script.

---

## Requirements

- MATLAB (recommended R2018b+).
- This repository added to the MATLAB path (see the repo `README.md`).

---

## Quick start

1) Add this repo to the MATLAB path (or use `startup.m`):
```matlab
addpath(genpath("/absolute/path/to/simion-analysis-matlab"))
rehash
```

2) Run scripts from within your project folder, or adapt the paths at the top of the script.

---

## Scripts included

## `scripts/trajectories/`

### `detector_analysis.m` — “full” detector + LaTeX + figures workflow
**What it does**
- Loads a SIMION file from a trajectories folder.
- Runs `simion.analyzeBeamFile(...)`.
- Saves `.mat` outputs, exports LaTeX tables, and writes figures.

**Typical inputs to edit**
- `inputFileName` (the SIMION file name)
- optional: `SpeciesSel`, `XTol`, `Rcenter`, `polarRmax`

---

### `beamevolution_analisys.m` — beam evolution along X
**What it does**
- Computes per-plane evolution: µ_y(x), σ_y(x) (and optionally µ_z/σ_z).
- Optional linear fit of µ_y(x) per species (slope/intercept).
- Saves `.mat` + summary CSV + figures.

**Typical inputs to edit**
- `inputFileName`
- `SpeciesSel`
- `MinCountPerSlice`, `DoFit`, `SaveResults`, `SaveFigures`

---

### `electron_tof_analysis.m` — electron TOF–path correlation
**What it does**
- Imports an electron dataset.
- Computes TOF–L correlation with `simion.analyzeTofPathCorrelation(...)`.
- Saves `.mat` + CSV + LaTeX summary + figures.

**Typical inputs to edit**
- `inputFile` and `Lmin`

---

### `Import_SRIM_TRANSMIT.m` — SRIM `TRANSMIT_*` import + Gaussian fits
**What it does**
- Imports a list of SRIM transmit files.
- Runs `simion.importSrimTransmit(...)`.
- Exports a LaTeX table and plots fit checks.

**Typical inputs to edit**
- `filenames` (SRIM files list)
- optional geometry offsets if you use them

---

### `ploTof.m` — minimal TOF plotting script
**What it does**
- Imports a SIMION file with `simion.importSimionTofTable`.
- Calls `simion.plotTofBySpecies`.

**Important**
- Remove any absolute paths and replace them with `fullfile(...)` or project-relative paths.

---

## `scripts/tof/`

### `analyze_tof_o6plus.m` — O6+ TOF analysis
A TOF-focused script (naming and parameters depend on the current workflow).
Open the file and edit the “inputs” section at the top.

---

## Troubleshooting

**Error: “Undefined function or variable 'simion'”**
```matlab
addpath(genpath("/absolute/path/to/simion-analysis-matlab"))
rehash
```

**File not found**
- Verify your input file exists in the expected folder.
- Check the path variables at the top of the script.

---

## Maintenance note

To keep these scripts portable across machines/OS:
- avoid absolute paths;
- prefer `fullfile(...)`;
- keep all editable parameters grouped at the top of each script.
