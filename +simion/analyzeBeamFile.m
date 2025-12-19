function results = analyzeBeamFile(filename, varargin)
% ANALYZEBEAMFILE  Analisi completa del fascio per un file SIMION.
%
%   results = simion.analyzeBeamFile(filename)
%   results = simion.analyzeBeamFile(filename, 'Name',Value,...)
%
% INPUT
%   filename    percorso del file SIMION (txt/csv) da analizzare
%
% NAME–VALUE
%   'XTolerance'    tolleranza su X per definire x_out (default: 1e-3)
%
%   'Rcenter'       [y0 z0] per r = sqrt((Y-y0)^2+(Z-z0)^2)
%                   (default: [37.5 0])
%
%   'Species'       "all" (default) oppure string/cellstr con le specie
%                   da considerare (es. "H+" oppure ["H+","He2+"])
%
%   'OutputDir'     cartella per PNG e .tex
%                   (default: cartella del file, o pwd se vuota)
%
%   'SaveFigures'   true/false, se salvare automaticamente le figure in PNG
%                   (default: true)
%
%   'FilePrefix'    prefisso per i nomi dei file di output
%                   (default: nome file senza estensione)
%
%   'PolarRmax'     raggio massimo [mm] per la mappa polare nel piano YZ.
%                   Se vuoto ([]), usa il default della funzione di plot
%                   (cioè auto da dati).
%
% OUTPUT (struct "results")
%   results.File          : nome file di input
%   results.OutputDir     : cartella di output effettiva
%   results.SpeciesUsed   : specie effettivamente usate
%   results.T             : table completa importata (già filtrata per specie)
%   results.Stats         : struct da computeBeamStatsInOut
%   results.SpotTable     : stats.SpotBySpecies
%   results.SeparationY   : stats.SeparationY
%   results.SeparationR   : stats.SeparationR
%   results.SpotFigures   : handle figure spot (per specie/proiezione)
%   results.PolarFigures  : handle figure polar map (per specie)
%   results.PolarMap      : struct mapStruct dalle mappe polari
%   results.LatexFile     : percorso del .tex generato

    % -----------------------------
    % 0) Parse input
    % -----------------------------
    p = inputParser;
    p.FunctionName = 'analyzeBeamFile';

    addRequired( p, 'filename',   @(s) ischar(s) || isstring(s) );
    addParameter(p, 'XTolerance', 1e-3, @(x) isnumeric(x) && isscalar(x) && x>=0 );
    addParameter(p, 'Rcenter',    [37.5 0], @(v) isnumeric(v) && numel(v)==2 );
    addParameter(p, 'Species',    "all", ...
                    @(s) isstring(s) || ischar(s) || iscellstr(s));
    addParameter(p, 'OutputDir',  '', @(s) ischar(s) || isstring(s) );
    addParameter(p, 'SaveFigures', true, @(b) islogical(b) && isscalar(b) );
    addParameter(p, 'FilePrefix',  '', @(s) ischar(s) || isstring(s) );
    addParameter(p, 'PolarRmax',   [], ...
                    @(x) isempty(x) || (isnumeric(x) && isscalar(x) && x>0) );

    parse(p, filename, varargin{:});

    filename   = char(p.Results.filename);
    XTol       = p.Results.XTolerance;
    Rcenter    = p.Results.Rcenter(:).';      % [y0 z0]
    spSel      = p.Results.Species;
    outDirIn   = char(p.Results.OutputDir);
    saveFigs   = p.Results.SaveFigures;
    filePrefix = char(p.Results.FilePrefix);
    PolarRmax  = p.Results.PolarRmax;

    % Normalizzo la selezione specie in string array
    if ischar(spSel) || isstring(spSel)
        spSel = string(spSel);
    else
        spSel = string(spSel(:));
    end

    % -----------------------------
    % 1) Cartella e prefisso output
    % -----------------------------
    [fpath, fname, ~] = fileparts(filename);

    if isempty(outDirIn)
        outDir = fpath;
    else
        outDir = outDirIn;
    end
    if isempty(outDir)
        outDir = pwd;
    end
    if ~exist(outDir,'dir')
        mkdir(outDir);
    end

    if isempty(filePrefix)
        filePrefix = fname;
    end

    % -----------------------------
    % 2) Import dati SIMION
    % -----------------------------
    T = simion.importSimionTofTable(filename);

    % -----------------------------
    % 3) Filtro per specie (se richiesto)
    % -----------------------------
    if ~(isscalar(spSel) && spSel == "all")
        if ~ismember('Species', T.Properties.VariableNames)
            error('analyzeBeamFile:NoSpecies', ...
                  'La table non contiene la colonna Species.');
        end

        spCat = categorical(string(T.Species));
        mask  = ismember(spCat, categorical(spSel));
        T     = T(mask,:);

        if isempty(T)
            error('analyzeBeamFile:EmptyAfterFilter', ...
                  'Nessun record rimasto dopo il filtro Species = %s.', ...
                  strjoin(spSel, ', '));
        end
    end

    % -----------------------------
    % 4) Statistiche in/out per specie
    % -----------------------------
    stats = simion.computeBeamStatsInOut(T, ...
                'XTolerance', XTol, ...
                'Rcenter',   Rcenter);

    Spot = stats.SpotBySpecies;

    % -----------------------------
    % 5) Plot spot finale (XY, XZ, YZ)
    % -----------------------------
    % Assumo che plotFinalSpotBySpecies accetti 'XTolerance' e 'Species'
    figSpot = simion.plotFinalSpotBySpecies(T, ...
                    'XTolerance', XTol, ...
                    'Species',   spSel);

    % -----------------------------
    % 6) Mappe polari nel piano YZ
    % -----------------------------
    polarArgs = { ...
        'XTolerance', XTol, ...
        'Center',     Rcenter, ...
        'Species',    spSel };

    if ~isempty(PolarRmax)
        polarArgs = [polarArgs, {'Rmax', PolarRmax}];
    end

    [figPolar, mapStruct] = simion.plotDetectorPolarMapBySpecies(T, polarArgs{:});

    % -----------------------------
    % 7) Esporta tabella in LaTeX
    % -----------------------------
    texFile = fullfile(outDir, sprintf('%s_beam_stats.tex', filePrefix));
    simion.beamStatsToLatex(Spot, 'Filename', texFile);
    
    % Tabelle LaTeX di separazione (opzionali ma utili)
    texSepY = simion.beamSeparationToLatex(stats, ...
        'Dimension', 'y', ...
        'Filename', fullfile(outDir, sprintf('%s_sep_y.tex', filePrefix)));

    texSepR = simion.beamSeparationToLatex(stats, ...
        'Dimension', 'r', ...
        'Filename', fullfile(outDir, sprintf('%s_sep_r.tex', filePrefix)));

    % Aggiorna struct dei risultati
    results.LatexFileSpot  = texFile;   % tabella SpotBySpecies
    results.LatexFileSepY  = texSepY;   % separazioni in y
    results.LatexFileSepR  = texSepR;   % separazioni in r

    
    % -----------------------------
    % 8) Salva PNG (se richiesto)
    % -----------------------------
    if saveFigs
        % Spot: una o più figure (dipende dall'implementazione)
        for k = 1:numel(figSpot)
            if ishghandle(figSpot(k))
                pngName = fullfile(outDir, ...
                    sprintf('%s_spot_%d.png', filePrefix, k));
                exportgraphics(figSpot(k), pngName, 'Resolution', 300);
            end
        end

        % Polar map: una figura per specie
        for k = 1:numel(figPolar)
            if ishghandle(figPolar(k))
                spName = '';
                if isfield(mapStruct, 'Species') && numel(mapStruct.Species) >= k
                    spName = char(mapStruct.Species(k));
                else
                    spName = sprintf('sp%d', k);
                end
                pngName = fullfile(outDir, ...
                    sprintf('%s_polar_%s.png', filePrefix, spName));
                exportgraphics(figPolar(k), pngName, 'Resolution', 300);
            end
        end
    end

    % -----------------------------
    % 9) Struct di output
    % -----------------------------
    results = struct();
    results.File         = filename;
    results.OutputDir    = outDir;
    results.SpeciesUsed  = spSel;
    results.T            = T;
    results.Stats        = stats;
    results.SpotTable    = Spot;
    results.SeparationY  = stats.SeparationY;
    results.SeparationR  = stats.SeparationR;
    results.SpotFigures  = figSpot;
    results.PolarFigures = figPolar;
    results.PolarMap     = mapStruct;
    results.LatexFile    = texFile;
end