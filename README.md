# mylib (+simion) — MATLAB toolbox per analisi SIMION/SRIM

Questa repo contiene una libreria MATLAB organizzata come **package** (`+simion`) con funzioni per importare/analizzare output SIMION e SRIM, fare plot e generare tabelle/LaTeX.

## Struttura della repo
- `+simion/` — funzioni principali (API pubblica) da chiamare come `simion.nomeFunzione(...)`.
- `+simion/private/` — funzioni interne di supporto (non garantite/stabili come API).
- `example/` — script di esempio per import/analisi/plot.

Per l’elenco completo delle funzioni:
- `README_simion.md` (funzioni pubbliche)
- `+simion/private/README_private_simion.md` (funzioni interne)

## Requisiti
- MATLAB R2018b o più recente (in generale funziona anche prima, ma non garantito).
- Nessuna toolbox extra obbligatoria (salvo funzioni che richiedano specifiche toolbox).

## Installazione (consigliata: con Git)
Scegli una cartella dove tieni le tue librerie MATLAB, ad esempio:

- macOS/Linux: `~/MATLAB/`
- Windows: `C:\Users\<tuo_utente>\Documents\MATLAB\`

### macOS/Linux (Terminale)
```bash
cd ~/MATLAB
git clone https://github.com/<TUO_USER>/<NOME_REPO>.git mylib
```

### Windows (PowerShell)
```powershell
cd $HOME\Documents\MATLAB
git clone https://github.com/<TUO_USER>/<NOME_REPO>.git mylib
```

La struttura attesa è tipo:
```
mylib/
  +simion/
  example/
  README_simion.md
```

## Aggiungere la libreria al path di MATLAB

### Opzione A — Caricamento automatico ad ogni avvio (startup.m) [consigliata]
MATLAB esegue automaticamente un file chiamato `startup.m` **se** si trova in una cartella sul MATLAB path (tipicamente la tua `userpath`, cioè `Documents/MATLAB`).

1) In MATLAB, scopri la tua `userpath`:
```matlab
userpath
```

2) Se non esiste già, crea (o modifica) questo file:
- `startup.m` dentro la cartella mostrata da `userpath`

3) Dentro `startup.m` metti (cross-platform Windows/macOS/Linux):

```matlab
% --- mylib startup: aggiunge la repo al MATLAB path (cross-platform)
up = userpath;                         % può contenere più path separati da pathsep
up = strtok(up, pathsep);              % prende il primo
up = strtrim(up);                      % pulizia
repoDir = fullfile(up, "mylib");       % se hai clonato mylib dentro la userpath

if isfolder(repoDir)
    addpath(genpath(repoDir));
end

clear up repoDir
```

4) Riavvia MATLAB e verifica:
```matlab
which simion.importSimionTofTable -all
```

Se vedi un path dentro `.../mylib/+simion/...` sei a posto.

> Nota: con `+simion` basta che **la cartella padre** (cioè `mylib/`) sia sul path. Non serve aggiungere `+simion/` direttamente.

---

### Opzione B — Caricamento “manuale” quando serve (senza startup)
Se non vuoi toccare lo startup, basta aggiungere il path **una volta per sessione**:

```matlab
addpath(genpath("/percorso/assoluto/verso/mylib"))
```

Esempi:
```matlab
% macOS/Linux
addpath(genpath(fullfile(userpath, "mylib")))

% Windows (va bene anche con slash /)
addpath(genpath("C:/Users/<tuo_utente>/Documents/MATLAB/mylib"))
```

Verifica:
```matlab
help simion
```

---

### Opzione C — “Set Path” (GUI MATLAB)
1) Home → **Set Path** → **Add Folder…**
2) Seleziona la cartella `mylib/`
3) **Save**

È comoda, ma meno “riproducibile” rispetto a Git + `startup.m`.

## Primo test rapido
Apri MATLAB e prova un import (adatta i file ai tuoi):

```matlab
T = simion.importSimionTofTable("data/tof_table.txt");
head(T)
```

Oppure lancia uno degli esempi in `example/`.

## Come usare le funzioni
Le funzioni sono in un package chiamato `simion`, quindi si chiamano così:

```matlab
simion.analyzeBeamFile(...)
simion.plotTofBySpecies(...)
simion.srimFitResultsToLatex(...)
```

- Documentazione “pubblica”: vedi `README_simion.md`
- Funzioni interne/non-API: vedi `+simion/private/README_private_simion.md`

## Aggiornare la libreria
Se l’hai clonata con Git:

```bash
cd /percorso/verso/mylib
git pull
```

## Troubleshooting
**Errore: “Undefined function or variable 'simion'”**
- La cartella `mylib/` non è sul path.
- Fai:
```matlab
addpath(genpath("/percorso/verso/mylib"))
rehash
```

**Conflitti di nomi / funzioni duplicate**
- Controlla cosa sta risolvendo MATLAB:
```matlab
which simion.importSimionTofTable -all
```

