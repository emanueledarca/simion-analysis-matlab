%% beamevolution_analisys.m
% Analisi 11.3: Evoluzione longitudinale di posizione e dimensioni
% ---------------------------------------------------------------
% Implementa lo schema:
%  1) Per ogni sezione x_k e specie s: calcolare µ_y^(s)(x_k), σ_y^(s)(x_k)
%     (e, se disponibile, µ_z^(s)(x_k), σ_z^(s)(x_k)).
%  2) Tracciare i grafici µ_y^(s)(x) e σ_y^(s)(x) per tutte le specie.
%  3) Eseguire un fit lineare di µ_y^(s)(x) per ottenere a_y^(s), b_y^(s)
%     e confrontare i b_y^(s) (direzione media del fascio).
%
% Richiede sulla path:
%   - +simion/computeBeamEvolutionY.m
%   - +simion/plotBeamEvolutionY.m
%   - +simion/plotBeamEvolutionZ.m  (opzionale, solo per i grafici in Z)

clear; clc; close all;

%% 0) Parametri di input

% Nome del file dentro data_raw/trajectories
inputFileName = 'beamevol.txt';    % <-- cambia qui il file

% SPECIE da analizzare:
%   []              -> tutte le specie (usa "all" nella compute)
%   ["H+","He2+"]   -> solo queste specie, per esempio
SpeciesSel = [];                 % <-- decidi qui il subset

% Parametri numerici per l'analisi
MinCountPerSlice = 20; % minimo N per includere un piano x_k
DoFit            = true;         % eseguire il fit lineare di µ_y(x)
DoPlotsZ         = true;         % se true, prova a fare anche i grafici in Z

% Salvataggio
SaveResults = true;
SaveFigures = true;

% Tag per i file di output (se vuoto viene costruito dal nome del file)
OutputTag = '';

%% 1) Struttura delle cartelle (stile "Trajectories")


scriptsDir = fileparts(mfilename('fullpath'));    % .../Trajectories/matlab/scripts
projRoot   = fileparts(fileparts(scriptsDir));    % .../Trajectories  (sali di 2 livelli)

dataRawDir   = fullfile(projRoot, 'data_raw',   'trajectories');
dataProcRoot = fullfile(projRoot, 'data_processed', 'trajectories');
figRoot      = fullfile(projRoot, 'figures',       'trajectories');

% Sottocartelle specifiche per 11.3
dataProcDir = fullfile(dataProcRoot, '11_3_beam_evolution');
figDir      = fullfile(figRoot,      '11_3_beam_evolution');

if ~exist(dataProcDir, 'dir'); mkdir(dataProcDir); end
if ~exist(figDir,      'dir'); mkdir(figDir);      end

inputPath = fullfile(dataRawDir, inputFileName);

% Controllino veloce
if ~isfile(inputPath)
    error('File di input non trovato:\n  %s', inputPath);
end

%% 2) Preparazione etichette di output

[~, baseName, ~] = fileparts(inputFileName);

if isempty(SpeciesSel)
    speciesArg = "all";
    speciesTag = "allSpecies";
else
    speciesArg = string(SpeciesSel);
    speciesTag = strjoin(speciesArg, '_');
end

if isempty(OutputTag)
    OutputTag = sprintf('%s_%s', baseName, speciesTag);
end

fprintf('===> 11.3 su file "%s"\n', inputPath);
fprintf('     Specie: %s\n', speciesTag);
fprintf('     OutputTag: %s\n\n', OutputTag);

%% 3) Analisi 11.3 — Y: µ_y(x), σ_y(x), fit lineare

% Qui usiamo direttamente la funzione di plot, che internamente chiama
% computeBeamEvolutionY e ci restituisce anche la struct stats.
[figY, stats] = simion.plotBeamEvolutionY(inputPath, ...
    'Species',          speciesArg, ...
    'MinCountPerSlice', MinCountPerSlice, ...
    'DoFit',            DoFit);


FitSummary = stats.FitSummary;

% Stampa "al volo" in command window la tabella con i b_y^(s)
fprintf('\n=== [11.3-3] Fit lineare di µ_y(x) e confronto b_y tra specie ===\n');
disp(FitSummary(:, {'Species','a_y','b_y','theta_y_mean','xMin_fit','xMax_fit'}));

%% 4) (Opzionale) Analisi 11.3 anche in Z: µ_z(x), σ_z(x)

figZ = gobjects(0);

if DoPlotsZ
    try
        figZ = simion.plotBeamEvolutionZ(inputPath, ...
            'Species',          speciesArg, ...
            'MinCountPerSlice', MinCountPerSlice, ...
            'DoFit',            DoFit);
    catch ME
        warning('plotBeamEvolutionZ non eseguito (%s). Procedo solo con Y.', ME.message);
    end
end

%% 5) Salvataggio risultati numerici

if SaveResults
    matFile = fullfile(dataProcDir, sprintf('%s_beamEvolution_stats.mat', OutputTag));
    csvFile = fullfile(dataProcDir, sprintf('%s_beamEvolution_FitSummary.csv', OutputTag));

    save(matFile, 'stats', 'FitSummary', ...
        'inputFileName', 'SpeciesSel', 'MinCountPerSlice');

    writetable(FitSummary, csvFile);

    fprintf('\nRisultati salvati in:\n  %s\n  %s\n', matFile, csvFile);
end

%% 6) Salvataggio figure

if SaveFigures
    % --- Figure in Y ---
    if ~isempty(figY) && all(isgraphics(figY))
        yNames = {'muY_vs_X','sigmaY_vs_X'};
        for i = 1:numel(figY)
            if ~isgraphics(figY(i)), continue; end
            pngFile = fullfile(figDir, sprintf('%s_%s.png', OutputTag, yNames{i}));
            figFile = fullfile(figDir, sprintf('%s_%s.fig', OutputTag, yNames{i}));

            exportgraphics(figY(i), pngFile, 'Resolution', 300);
            savefig(figY(i), figFile);
        end
    end

    % --- Figure in Z (se presenti) ---
    if ~isempty(figZ) && all(isgraphics(figZ))
        zNames = {'muZ_vs_X','sigmaZ_vs_X'};
        for i = 1:numel(figZ)
            if ~isgraphics(figZ(i)), continue; end
            pngFile = fullfile(figDir, sprintf('%s_%s.png', OutputTag, zNames{i}));
            figFile = fullfile(figDir, sprintf('%s_%s.fig', OutputTag, zNames{i}));

            exportgraphics(figZ(i), pngFile, 'Resolution', 300);
            savefig(figZ(i), figFile);
        end
    end
end

fprintf('\n[OK] Analisi 11.3 completata.\n');