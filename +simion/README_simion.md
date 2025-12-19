# Package `+simion`

Raccolta di funzioni MATLAB per l’analisi dei file di output di SIMION
(ion optics / beam analysis), pensata per l’uso in tesi e nei test di
laboratorio.

Il package fornisce:

- funzioni di **import** verso `table`,
- strumenti per l’analisi del **TOF per specie**,
- funzioni per le **statistiche di fascio** (ingresso/uscita e detector),
- funzioni per l’**evoluzione del fascio** lungo X,
- strumenti per **mappe polari al detector**,
- utilità per esportare i risultati in **LaTeX**,
- una funzione di alto livello `analyzeBeamFile` che automatizza il flusso
  di analisi per un singolo file,
- funzioni per **SRIM** (import + fit + LaTeX).

> Tutte le funzioni “di servizio” sono in `+simion/private` e **non fanno
> parte dell’API pubblica** (nomi e interfacce possono cambiare).

---

## Installazione / Setup

1. Metti la cartella `+simion` in una directory che è (o verrà) aggiunta al
   path MATLAB, ad esempio:

   ```matlab
   addpath('/path/alla/cartella/con/+simion');
   ```

2. Opzionale: aggiungi questa riga al tuo `startup.m` per caricare il
   package automaticamente all’avvio di MATLAB.

3. Gli **script di esempio** (`example_*.m`, `test_importSimion.m`) vanno
   tenuti **fuori** da `+simion`, ad esempio in una cartella `examples/`:

   ```text
   my-project/
     +simion/
       (tutte le funzioni della libreria)
     examples/
       example_ImportAndTof.m
       example_BeamAnalysis.m
       example_BeamAnalysis_MultiEnergy.m
       test_importSimion.m
   ```

---

## Flusso base: da file SIMION a TOF per specie

Esempio minimale: import di un file SIMION e plot del TOF per specie.

```matlab
% Nome del file di output SIMION (txt/csv)
fname = "run_8keV.txt";

% 1) Import "alto livello" per analisi TOF
T = simion.importSimionTofTable(fname);

% 2) Plot TOF per specie con fit gaussiano (bin globali)
FitResults = simion.plotTofBySpecies(T, "pdf", 60);
```

Questa è sostanzialmente la logica di `example_ImportAndTof.m`.

---

## Analisi completa con `analyzeBeamFile`

Per una analisi “end-to-end” di un singolo file:

```matlab
fname = "run_8keV.txt";

results = simion.analyzeBeamFile(fname, ...
    'XTolerance', 1e-3, ...
    'Rcenter',    [37.5 0], ...
    'PolarRmax',  20);

% Campi principali della struct results:
%   results.T                  -> table RAW importata (tutti i record)
%   results.tofFits            -> struct/table con i fit di TOF
%   results.beamStatsInOut     -> stats fascio in ingresso/uscita
%   results.beamStatsDetector  -> stats fascio al detector
%   results.polarMap           -> mappe polari (se abilitate)
```

Di default `analyzeBeamFile` **salva** anche un file `.mat` con gli stessi
risultati, nella forma:

```text
<nome_file>_results.mat   % contiene la struct "results"
```

(Questo comportamento è controllato dai parametri Name–Value interni
alla funzione.)

---

## Funzioni principali

### Import

- `simion.importSimionRecordTable(filename)`  
  Import generico di un file di output SIMION in una `table`.  
  Normalizza i nomi delle colonne (via `canonicalizeSimionNames`) e
  conserva i nomi originali in
  `T.Properties.VariableDescriptions`.

- `simion.importSimionTofTable(filename)`  
  Wrapper specializzato per l’analisi TOF: chiama
  `importSimionRecordTable`, verifica la presenza delle colonne
  necessarie (`TOF`, `Mass`, `Charge`) e riordina le colonne
  mettendo per prime quelle standard.

- `simion.importSrimTransmit(filenames)`  
  Importa uno o più file SRIM del tipo `TRANSMIT_*.txt` e calcola i
  fit gaussiani delle distribuzioni (energia, angoli, posizione).
  Restituisce:
  - `Data`      – cell array di struct con tabella raw + info su specie/energia;
  - `FitResults` – struct array con parametri dei fit (µ, σ, FWHM, ecc.).

---

### Analisi del fascio

- `simion.analyzeBeamFile(filename, ...)`  
  Funzione ad alto livello che:
  1. importa i dati (`importSimionTofTable`),
  2. calcola le **statistiche in ingresso/uscita** (`computeBeamStatsInOut`),
  3. calcola le **statistiche al detector** (`computeBeamStatsAtDetector`),
  4. esegue i **fit di TOF per specie**,
  5. opzionalmente genera **mappe polari** (`plotDetectorPolarMapBySpecies`)
     e grafici di evoluzione del fascio (`plotBeamEvolutionY/Z`),
  6. salva i risultati in un file `.mat`.

- `simion.computeBeamStatsInOut(T, ...)`  
  Calcola le statistiche del fascio **in ingresso** (sorgente) e
  **in uscita** (piano del detector x_out) per ogni specie: numero di
  particelle, µ_y, σ_y, µ_z, σ_z, µ_r, σ_r, ecc.  
  Restituisce una struct `stats` con campi:
  - `SpotBySpecies` – table con una riga per specie;
  - `SeparationY`   – separazioni in y tra coppie di specie;
  - `SeparationR`   – separazioni in r tra coppie di specie.

- `simion.computeBeamStatsAtDetector(T, ...)`  
  Analisi statistica **solo** al piano del detector x_out, utile se non
  interessa l’ingresso. Restituisce una struct con parametri simili
  ma focalizzati sull’uscita.

- `simion.computeBeamEvolutionY(inputArg, ...)`  
  Calcola l’evoluzione longitudinale (lungo X) di µ_y(x), σ_y(x),
  e opzionalmente µ_z(x), σ_z(x) per ogni specie, individuando in modo
  automatico i diversi piani x_k dai dati SIMION.

- `simion.analyzeTofPathCorrelation(T, Lmin, XTol)`  
  Analizza la correlazione **TOF–L** per gli elettroni in due modi:
  1. tutte le particelle con L ≥ Lmin;
  2. tutte le particelle che arrivano al piano x ≈ Xmax.  
  Restituisce due struct (`stats_Lmin`, `stats_det`) con le statistiche
  di queste due popolazioni.

---

### Plot del fascio / TOF / mappe polari

- `simion.plotTofBySpecies(T, mode, nbins, ...)`  
  Entry point unico per i plot di TOF per specie.  
  Usa internamente le funzioni in `private`:
  - `mode = "pdf"`          → `plotTofPdfBySpecies`
  - `mode = "hist-global"`  → `plotTofHistogramBySpecies`
  - `mode = "hist-local"`   → `plotTofHistogramBySpeciesLocalBins`

  Esempio rapido:

  ```matlab
  FitResults = simion.plotTofBySpecies(T, "hist-local", 60);
  ```

- `simion.plotFinalSpotBySpecies(T, ...)`  
  Scatter del “final spot” sul rivelatore, separato per specie.  
  Crea tre figure (XY, XZ, YZ) e restituisce gli axes.

- `simion.plotBeamEvolutionY(inputArg, ...)`  
  Wrapper grafico per `computeBeamEvolutionY`.  
  Restituisce:
  - `figHandles(1)` – µ_y(x) per specie,
  - `figHandles(2)` – σ_y(x) per specie,
  - `stats`         – stessa struct di `computeBeamEvolutionY`.

- `simion.plotBeamEvolutionZ(inputArg, ...)`  
  Come sopra, ma per µ_z(x) e σ_z(x).

- `simion.plotDetectorPolarMapBySpecies(T, ...)`  
  Costruisce una **mappa polare di densità** degli impatti al detector
  nel piano YZ, per specie.  
  Utile per visualizzare la distribuzione angolare spaziale al rivelatore.

---

### Export in LaTeX / combinazione fit

- `simion.beamStatsToLatex(SpotTable, ...)`  
  Esporta le statistiche di fascio (tipicamente `stats.SpotBySpecies`)
  in una tabella LaTeX, con nomi di colonne “paper-ready”.

- `simion.beamSeparationToLatex(stats, ...)`  
  Esporta le S di separazione (`stats.SeparationY` o `stats.SeparationR`)
  in una tabella LaTeX.

- `simion.srimFitResultsToLatex(FitResults, outFile)`  
  Esporta i risultati dei fit SRIM (ritornati da `importSrimTransmit`)
  in una tabella LaTeX compatta, con righe del tipo:

  ```text
  Specie & E_nom [keV] & Quantità & mu & FWHM & unità
  ```

- `simion.tableToLatex(Tw, params, outFile, ...)`  
  Converte una tabella “wide” di fit (es. output di `combineFitStructs`)
  in una tabella LaTeX “paper-grade”.

- `simion.combineFitStructs(fitStructs, labels)`  
  Unisce N struct di fit (per energie diverse) in una singola table wide
  con colonne tipo `mu_8`, `mu_14`, `sigma_8`, ..., `FWHM_20`, ecc.

- `simion.srimPlotGaussianCheck(xData, fitParams, quantityLabel, ...)`  
  Utility per SRIM: istogramma dei dati + curva gaussiana fittata,
  con salvataggio automatico di PNG e FIG.

---

## Esempi inclusi (cartella `examples/`)

- `example_ImportAndTof.m`  
  Import di un file SIMION con `importSimionTofTable` e plot del TOF per
  specie con `plotTofBySpecies`.

- `example_BeamAnalysis.m`  
  Analisi completa di fascio per una singola energia con
  `analyzeBeamFile`, più export delle stats al detector con
  `beamStatsToLatex`.

- `example_BeamAnalysis_MultiEnergy.m`  
  Esecuzione di `analyzeBeamFile` su più file (energie diverse),
  raccolta delle `beamStatsDetector` in una singola tabella e export
  via `beamStatsToLatex`.

- `test_importSimion.m`  
  Script di prova per:
  - `importSimionTofTable`,
  - `splitBySpecies` (in `private`),
  - `plotFinalSpotBySpecies` (proiezioni XY, XZ, YZ).

Questi script **non fanno parte dell’API**: sono solo esempi di utilizzo
da copiare/adattare.

---

## Note finali

- Il package è pensato per essere aggiunto al path MATLAB (o messo in una
  cartella “mylib” caricata all’avvio).
- Le funzioni in `+simion/private` sono interne e possono cambiare senza
  preavviso.
- Per dettagli su opzioni e parametri, usare l’`help` di MATLAB:

  ```matlab
  help simion.nomeFunzione
  ```
