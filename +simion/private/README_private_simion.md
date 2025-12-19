# Cartella `+simion/private`

Questa cartella contiene **funzioni interne** al package `+simion`.
Non costituiscono API pubblica: nomi, firma e comportamento possono
cambiare in qualsiasi momento.

L’utente “normale” dovrebbe utilizzare solo le funzioni documentate in
`README_simion.md` (quelle in `+simion`).

---

## Panoramica delle funzioni interne

### Normalizzazione nomi / specie

- `canonicalizeSimionNames.m`  
  Porta gli header della table SIMION a una forma standard.  
  Cerca di ottenere nomi canonici come:
  `IonN`, `Events`, `TOF`, `Time`, `Mass`, `Charge`,
  `X`, `Y`, `Z`, `Vx`, `Vy`, `Vz`, `KE`, `KEError`, ecc.  
  Gestisce vari alias possibili (es. `Ion Number`, `Ion_N`, ecc.).

- `classifySpecies.m`  
  Prova ad assegnare una specie fisica (es. `"H+"`, `"He2+"`, `"O6+"`,
  `"e-"`) a partire da `Mass` e `Charge` e/o da eventuali colonne
  già presenti. Usata per costruire la colonna `Species`.

- `selectSpecies.m`  
  Filtro comodo per selezionare solo un sottoinsieme di specie da una
  table che contiene la colonna `Species`. Restituisce anche la lista
  di specie effettivamente trovate.

- `splitBySpecies.m`  
  Divide una table con colonna `Species` in una struct di sub-table:
  ogni campo della struct corrisponde a una specie, con nome reso
  MATLAB-safe tramite `matlab.lang.makeValidName`.

---

### Gestione dei “final hits” / piano del detector

- `getInitialHitsByIon.m`  
  Per ogni `IonN` seleziona il **primo** record (tipicamente sorgente /
  primo piano in cui viene registrata la particella).

- `getFinalHitsByIon.m`  
  Per ogni `IonN` seleziona l’**ultimo** record (ultimo piano attraversato
  dalla particella).

- `getDetectorHitsAtXmax.m`  
  Dato un set di final hits, seleziona quelli che arrivano effettivamente
  al piano del detector, definito come X ≈ Xmax con una certa tolleranza
  (parametro `XTolerance` nelle funzioni pubbliche).

Queste tre funzioni sono usate, ad esempio, in:

- `computeBeamStatsInOut`
- `computeBeamStatsAtDetector`
- `plotFinalSpotBySpecies`
- `plotDetectorPolarMapBySpecies`

---

### Plot TOF interni

Tutte queste funzioni **non** vanno chiamate direttamente: esiste un
entry point pubblico che è `simion.plotTofBySpecies`.

- `plotTofHistogramBySpecies.m`  
  Istogrammi di TOF per specie con **bin globali** (stessa binning per
  tutte le specie).

- `plotTofHistogramBySpeciesInteractive.m`  
  Variante interattiva (selezione specie, zoom, ecc.) usata per test
  esplorativi.

- `plotTofHistogramBySpeciesLocalBins.m`  
  Istogrammi di TOF per specie con **bin locali**, adattati alla
  distribuzione di ciascuna specie.

- `plotTofPdfBySpecies.m`  
  Plot della PDF (linea continua) per specie, usando bin globali e
  normalizzazione “da PDF” (area = 1).

---

## Avvertenza

Le funzioni in questa cartella sono pensate **solo** per uso interno
alla libreria:

- non sono versionate come API pubblica;
- possono cambiare firma, nome o comportamento;
- possono essere accorpate o rimosse senza preavviso.

Se ti servono comportamenti simili in uno script personale, è
generalmente preferibile:

1. verificare se esiste già una funzione **pubblica** che copre il caso
   d’uso;
2. in caso contrario, copiare il codice interno in uno script tuo
   (congelando quella versione), invece di fare affidamento sulla
   versione “live” in `+simion/private`.
