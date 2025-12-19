# simion-analysis-matlab (`+simion`) — MATLAB toolbox for SIMION/SRIM analysis

MATLAB toolbox (package `+simion`) to import and analyze **SIMION**/**SRIM** outputs: beam statistics, **TOF–path** correlations, per-species plots, and utilities to export **LaTeX-ready** tables.

---

## Repository layout

- `+simion/` — **public API** (main functions) called as `simion.functionName(...)`.
- `+simion/private/` — internal helpers (**not** a stable API).
- `example/` — small, portable examples (quickstart / import test / basic analysis).
- `scripts/` — “ready-to-run” but more **project-oriented** scripts:
  - `scripts/tof/` — TOF-focused analyses (e.g., O6+).
  - `scripts/trajectories/` — trajectories analyses (beam evolution, detector, SRIM transmit, etc.).
  - scripts README: `scripts/trajectories/README_scripts.md`.

Full function lists:
- `+simion/README_simion.md` (public functions)
- `+simion/private/README_private_simion.md` (internal helpers)

---

## Requirements

- MATLAB R2018b or newer (older versions may work but are not guaranteed).
- No mandatory toolboxes (unless a specific function explicitly requires one).

---

## Installation

### 1) Clone the repository

**macOS/Linux (Terminal)**
```bash
cd ~/MATLAB
git clone https://github.com/emanueledarca/simion-analysis-matlab.git
```

**Windows (PowerShell)**
```powershell
cd $HOME\Documents\MATLAB
git clone https://github.com/emanueledarca/simion-analysis-matlab.git
```

---

## Add the toolbox to the MATLAB path

### Option A — Auto-load on startup (`startup.m`) [recommended]
MATLAB runs a file named `startup.m` automatically if it is located in a folder on the MATLAB path (typically your `userpath`, i.e. `Documents/MATLAB`).

1) In MATLAB, check your `userpath`:
```matlab
userpath
```

2) Create/edit `startup.m` inside the folder returned by `userpath`.

3) Add this block (cross-platform):

```matlab
% --- simion-analysis-matlab startup: add repo to the MATLAB path
up = userpath;                  % may contain multiple paths separated by pathsep
up = strtok(up, pathsep);       % keep the first one
up = strtrim(up);

repoDir = fullfile(up, "simion-analysis-matlab");   % if you cloned inside userpath
if isfolder(repoDir)
    addpath(genpath(repoDir));
end

clear up repoDir
```

4) Restart MATLAB and verify:
```matlab
which simion.importSimionTofTable -all
```

> Note: since this is a `+simion` package, you only need the **repo root** on the MATLAB path.

---

### Option B — Manual load (per session)
```matlab
addpath(genpath("/absolute/path/to/simion-analysis-matlab"))
rehash
```

---

## Quick start (30 seconds)

In MATLAB:

```matlab
which simion.analyzeBeamFile -all
help simion.importSimionTofTable
```

Then run one of the scripts in `example/`.

---

## Using the toolbox

Public functions live in the `simion` package:

```matlab
T = simion.importSimionTofTable("myfile.txt");
simion.plotTofBySpecies(T);
```

---

## Ready-to-run scripts (project-oriented)

See `scripts/` for analyses tailored to common workflows (TOF and trajectories).  
Start from: `scripts/trajectories/README_scripts.md`.

Practical note: some scripts assume a project folder structure like `Trajectories/` (e.g., `data_raw`, `data_processed`, `figures`). If your project differs, edit the paths/parameters in the “inputs” section at the top of each script.

---

## Citation

- `CITATION.cff` (GitHub exposes “Cite this repository” automatically).

---

## Troubleshooting

**Error: “Undefined function or variable 'simion'”**
```matlab
addpath(genpath("/absolute/path/to/simion-analysis-matlab"))
rehash
```

**Name conflicts / duplicated functions**
```matlab
which simion.importSimionTofTable -all
```

---


