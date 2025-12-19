# Analysis scripts (Trajectories) — README

Questa cartella contiene **script MATLAB** “pronti da lanciare” per analisi specifiche del progetto *Trajectories*, costruiti sopra la libreria **`+simion`** (repo: `simion-analysis-matlab`).

> Nota: questi file sono **script** (non funzioni). In genere si usano copiandoli in `Trajectories/matlab/scripts/` e modificando 2–3 parametri (nome file, specie, ecc.).

---

## Requisiti

- MATLAB (consigliato R2018b+).
- La libreria `+simion` sul MATLAB path (vedi README della repo principale).
- Struttura cartelle in stile *Trajectories* (minimo):

```
Trajectories/
  data_raw/
    trajectories/
    srim10keV/              (per SRIM)
  data_processed/
  figures/
  matlab/
    scripts/                (qui di solito metti questi script)
```

---

## Quick start

1. Assicurati che la repo `simion-analysis-matlab` (o comunque la cartella che contiene `+simion/`) sia sul path:
   ```matlab
   addpath(genpath("/percorso/verso/mylib"))  % oppure lo startup.m
   rehash
   ```

2. Metti questi script in `Trajectories/matlab/scripts/` (o lanciali da lì).

3. Per ogni script, modifica **solo** la sezione “Parametri di input” (inizio file).

---

## Script inclusi

### 1) `detector_analysis.m` — Analisi completa “11.2” (detector + tabelle + salvataggi)

**Cosa fa**
- Carica un file SIMION da `data_raw/trajectories/`.
- Esegue un’analisi completa via `simion.analyzeBeamFile(...)`.
- Salva risultati in `.mat`, copia la tabella LaTeX in `data_processed/tables10keV`, e salva figure in `figures/final10keV`.

**Dove impostare l’input**
- Variabile:
  - `inputFileName` (nome file dentro `data_raw/trajectories/`)

**Parametri principali**
- `SpeciesSel`:
  - `[]` → tutte le specie
  - `["H+","He2+"]` → solo subset
- `XTol` → tolleranza su X per definire il piano detector.
- `Rcenter = [Y0 Z0]` → centro per mappe polari nel piano YZ.
- `polarRmax` → raggio max mappa polare (vuoto = auto).

**Output**
- `data_processed/mat10keV/<prefix>_results.mat`
- `data_processed/tables10keV/<prefix>_beam_stats.tex` (copiato)
- `figures/final10keV/` (figure prodotte da `analyzeBeamFile`)

---

### 2) `beamevolution_analisys.m` — Analisi “11.3” (evoluzione del fascio lungo X)

**Cosa fa**
- Per ogni piano `x_k` e per ogni specie, calcola:
  - `μ_y(x_k)`, `σ_y(x_k)` (e opzionalmente `μ_z`, `σ_z` se disponibili).
- Plotta l’evoluzione lungo X (Y sempre, Z opzionale).
- (Opzionale) Fit lineare di `μ_y(x)` per estrarre slope/intercept per specie.
- Salva risultati in `.mat` e una tabella CSV riassuntiva dei fit.

**Dove impostare l’input**
- `inputFileName` (nome file dentro `data_raw/trajectories/`)

**Parametri principali**
- `SpeciesSel` (come sopra)
- `MinCountPerSlice` → minimo numero di particelle per considerare valido un piano `x_k`
- `DoFit` → abilita fit lineare su `μ_y(x)`
- `DoPlotsZ` → prova a produrre anche grafici in Z
- `SaveResults`, `SaveFigures`
- `OutputTag` → tag per i file di output (vuoto = auto)

**Output**
- `data_processed/trajectories/11_3_beam_evolution/<tag>_beamEvolution_stats.mat`
- `data_processed/trajectories/11_3_beam_evolution/<tag>_beamEvolution_FitSummary.csv`
- `figures/trajectories/11_3_beam_evolution/<tag>_*.{png,fig}`

---

### 3) `electron_tof_analysis.m` — Correlazione TOF–path per elettroni

**Cosa fa**
- Importa un file SIMION (default: `data_raw/trajectories/electron.txt`).
- Esegue `simion.analyzeTofPathCorrelation(T, Lmin)` e crea due scenari:
  - filtro su `L >= Lmin`
  - scenario “detector” (interno alla funzione)
- Salva:
  - `.mat` con le due struct di statistiche,
  - `.csv` e `.tex` di riepilogo,
  - figure (scatter + istogrammi) in PNG/FIG.

**Parametri principali**
- `inputFile` (se vuoi cambiare nome/percorso del file)
- `Lmin` → soglia su path-length (per tagliare outlier/path troppo corti)

**Output**
- `data_processed/tof/electrons/electron_tof_path_stats.mat`
- `data_processed/tof/electrons/electron_tof_path_stats_summary.csv`
- `data_processed/tof/electrons/electron_tof_path_stats_summary.tex`
- `figures/tof/electrons/TOF_Path_fig_*.{png,fig}`

---

### 4) `Import_SRIM_TRANSMIT.m` — Import + fit dei file SRIM `TRANSMIT_*`

**Cosa fa**
- Prende una lista di file SRIM (qui: `H_plus_10keV.txt`, `He_plus_10keV.txt`, …) da:
  - `data_raw/srim10keV/`
- Chiama:
  - `[Data, FitResults] = simion.importSrimTransmit(filepaths)`
  - `simion.srimFitResultsToLatex(FitResults, texFile)` (export tabella)
  - `simion.srimPlotGaussianCheck(...)` (plot di controllo dei fit)
- Converte anche posizioni (Å → mm) e stampa un riepilogo in Command Window.

**Parametri principali**
- `filenames` → elenco file SRIM da importare
- `x0_geom_mm`, `y0_geom_mm` → offset geometrici (se vuoi costruire anche coordinate assolute)

**Output**
- `data_processed/srim10keV/srim_Transmit_FitResults.mat`
- `data_processed/srim10keV/tables/srim_Transmit_FitResults_summary.csv`
- `data_processed/srim10keV/tables/srim_Transmit_FitResults.tex` (se esportato)
- `figures/srim10keV/{energy,phi,elevation,x_pos,y_pos,z_pos}/...`

---

### 5) `ploTof.m` — Plot TOF per specie (script minimal)

**Cosa fa**
- Importa un file SIMION con `simion.importSimionTofTable(fname)`.
- Plotta il TOF per specie con `simion.plotTofBySpecies(...)`.

**Da sistemare prima di usarlo**
- Nel file c’è un `fname` **assoluto** (path personale). Per renderlo portabile:
  - sostituiscilo con un path relativo, oppure costruiscilo con `fullfile(...)`.

**Parametri principali**
- `fname` → file SIMION
- `xlim` → limiti asse X (TOF)
- `nbin` → numero bin istogramma
- `mode` → modalità (es. `"hist-local"`, `"hist-global"`, `"pdf"`, `"interactive"`)

---

## Troubleshooting

- **Errore “Undefined function or variable 'simion'”**
  - `+simion` non è sul path:
    ```matlab
    addpath(genpath("/percorso/verso/la/repo"))
    rehash
    ```

- **File non trovato**
  - Controlla che il file esista davvero nella cartella attesa (es. `data_raw/trajectories/`).
  - Controlla `inputFileName` / `inputFile`.

- **Figure non salvate / cartelle mancanti**
  - Gli script creano `mkdir(...)` automaticamente, ma serve avere i permessi di scrittura dentro `Trajectories/`.

---

## Nota di manutenzione (consigliata)

Se vuoi rendere questi script più “repo-friendly” (Windows/macOS/Linux senza toccare path):
- evita path assoluti (come in `ploTof.m`);
- usa sempre `fullfile(...)`;
- lascia tutti i parametri modificabili in alto (come già fatto negli altri script).
