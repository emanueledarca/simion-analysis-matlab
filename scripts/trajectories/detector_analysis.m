%% detector_analysis.m
% Analisi completa per la sezione 11.2 a partire da un file SIMION.
% Usa la libreria +simion (mylib) e salva risultati e figure
% dentro la struttura Trajectories/ (data_processed, figures).

%% 0) Parametri di input

% Nome del file dentro data_raw/trajectories
inputFileName = 'filename.txt';   % <-- cambia qui se usi altri file

% SPECIE da analizzare:
%   - []           -> tutte le specie (usa il default "all" di analyzeBeamFile)
%   - ["H+","He2+"] -> solo queste specie, per esempio
SpeciesSel = [];                 % <-- qui decidi il subset

% Tolleranza su X per definire il piano del detector
XTol = 1e-3;

% Centro per il raggio polare nel piano YZ (coerente con geometria SIMION)
Rcenter = [0 0];             % [Y0 Z0] mm  (modifica se cambi setup)

% Raggio massimo per la mappa polare (lascia [] per auto)
polarRmax = [];

%% 1) Trovo la root del progetto (cartella Trajectories)

thisDir  = fileparts(mfilename('fullpath'));    % .../matlab/scipts
projRoot = fileparts(fileparts(thisDir));       % -> .../Trajectories

% Cartelle secondo il tree DA CAMBIARE IN BASE ALLA PROPRIA STRUTTURA
rawTrajDir = fullfile(projRoot, 'data_raw', 'trajectories'); % dove ci sono i dati
matDir     = fullfile(projRoot, 'data_processed', 'mat10keV'); %dove salvare
tabDir     = fullfile(projRoot, 'data_processed', 'tables10keV'); %dove salbare
figDir     = fullfile(projRoot, 'figures', 'final10keV'); %dove salvare

% Creo le cartelle di output se mancano
if ~exist(matDir, 'dir'), mkdir(matDir); end
if ~exist(tabDir, 'dir'), mkdir(tabDir); end
if ~exist(figDir, 'dir'), mkdir(figDir); end

%% 2) Costruisco il percorso del file di input

inFile = fullfile(rawTrajDir, inputFileName);
if ~isfile(inFile) %[output:group:991a1b8d]
    error('detector_analysis:FileNotFound', ... %[output:36ac7323]
          'File di input non trovato:\n  %s', inFile); %[output:36ac7323]
end %[output:group:991a1b8d]

[~, baseName, ~] = fileparts(inFile);
filePrefix = sprintf('sec11_2_%s', baseName);

fprintf('>>> Analisi 11.2 per file: %s\n', inFile);
fprintf('    Prefix output: %s\n', filePrefix);

if isempty(SpeciesSel)
    fprintf('    SpeciesSel: tutte le specie (default "all")\n');
else
    fprintf('    SpeciesSel: %s\n', strjoin(string(SpeciesSel), ', '));
end

%% 3) Analisi completa con la libreria SIMION

if isempty(SpeciesSel)
    % Caso "all": lascio che analyzeBeamFile usi il suo default "all"
    results = simion.analyzeBeamFile(inFile, ...
        'XTolerance',  XTol, ...
        'Rcenter',     Rcenter, ...
        'OutputDir',   figDir, ...      % PNG + .tex finiscono qui
        'SaveFigures', true, ...
        'FilePrefix',  filePrefix, ...
        'PolarRmax',   polarRmax);
else
    % Caso subset di specie
    results = simion.analyzeBeamFile(inFile, ...
        'XTolerance',  XTol, ...
        'Rcenter',     Rcenter, ...
        'OutputDir',   figDir, ...
        'SaveFigures', true, ...
        'FilePrefix',  filePrefix, ...
        'PolarRmax',   polarRmax, ...
        'Species',     SpeciesSel);
end

%% 4) Salvo la struct dei risultati in .mat (data_processed/mat)
%   (senza figure per evitare file enormi)

resultsToSave = results;
fldToDrop = intersect(fieldnames(resultsToSave), ...
    {'SpotFigures','PolarFigures'});

for k = 1:numel(fldToDrop)
    resultsToSave = rmfield(resultsToSave, fldToDrop{k});
end

matFile = fullfile(matDir, [filePrefix '_results.mat']);
save(matFile, '-struct', 'resultsToSave');
fprintf('    -> Salvato MAT: %s\n', matFile);

%% 5) Copio la tabella LaTeX in data_processed/tables

if isfield(results, 'LatexFile') && isfile(results.LatexFile)
    [~, ~, texExt] = fileparts(results.LatexFile);
    texDest = fullfile(tabDir, [filePrefix '_beam_stats' texExt]);
    copyfile(results.LatexFile, texDest, 'f');
    fprintf('    -> Copiato LaTeX in: %s\n', texDest);
else
    warning('detector_analysis:NoLatexFile', ...
        'Nessun file LaTeX trovato in results.LatexFile.');
end

%% 6) Salvo anche la SpotTable in CSV (se presente)

if isfield(results, 'SpotTable') && istable(results.SpotTable)
    csvFile = fullfile(tabDir, [filePrefix '_spotTable.csv']);
    writetable(results.SpotTable, csvFile);
    fprintf('    -> Salvata SpotTable CSV: %s\n', csvFile);
end

%% 7) Stampo al volo le tabelle importanti in Command Window

% Tabella dei parametri (quella con R_y, ecc.)
if isfield(results, 'SpotTable') && istable(results.SpotTable)
    fprintf('\n=== Spot / parametri per specie (incl. R_y) ===\n');
    disp(results.SpotTable);
else
    warning('detector_analysis:NoSpotTable', ...
        'results.SpotTable non presente o non è una table.');
end

% Tabella delle S_y (se esiste)
if isfield(results, 'SeparationY') && istable(results.SeparationY)
    fprintf('\n=== Fattori di separazione S_y tra specie ===\n');
    disp(results.SeparationY);
else
    warning('detector_analysis:NoSeparationY', ...
        'results.SeparationY non presente o non è una table.');
end

% Tabella delle S_r (se esiste)
if isfield(results, 'SeparationR') && istable(results.SeparationR)
    fprintf('\n=== Fattori di separazione S_r tra specie ===\n');
    disp(results.SeparationR);
else
    warning('detector_analysis:NoSeparationR', ...
        'results.SeparationR non presente o non è una table.');
end

fprintf('\n>>> Analisi 11.2 completata.\n');
fprintf('    Figures in: %s\n', figDir);
fprintf('    Tables in:  %s\n', tabDir);
fprintf('    MAT in:     %s\n', matDir);

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"onright","rightPanelPercent":24.3}
%---
%[output:36ac7323]
%   data: {"dataType":"error","outputData":{"errorType":"runtime","text":"File di input non trovato:\n  \/private\/var\/folders\/dx\/2dj1g8s934jcj939450w80kr0000gn\/data_raw\/trajectories\/H_He2+.txt"}}
%---
