function ax = plotFinalSpotBySpecies(T, varargin)
% PLOTFINALSPOTBYSPECIES
%   Scatter del "final spot" sul rivelatore (piano a Xmax), separato per specie.
%
%   ax = plotFinalSpotBySpecies(T)
%   ax = plotFinalSpotBySpecies(T, 'XTolerance', tol, 'MarkerSize', ms, 'Species', sp)
%
%   LOGICA FISICA:
%     1) si prende l'ULTIMO record per ogni ion (getFinalHitsByIon, in private)
%     2) si selezionano solo le particelle che arrivano al piano del
%        rivelatore, definito come Xmax globale, con una tolleranza tol
%        (getDetectorHitsAtXmax, in private)
%     3) opzionalmente si filtrano le specie richieste (selectSpecies, in private)
%     4) si plottano tre proiezioni, ognuna in UNA FIGURA DEDICATA:
%           - XY (vista frontale)
%           - XZ (profilo verticale)
%           - YZ (profilo laterale)
%        colorando per specie.
%
%   Richiede che T contenga almeno:
%       IonN, X, Y, Z, Species
%
%   OPZIONI (Name-Value):
%     'XTolerance' : tolleranza su X rispetto a Xmax (default 1e-3)
%     'MarkerSize' : dimensione marker scatter (default 10)
%     'Species'    : quali specie plottare:
%                      []          -> tutte (default)
%                      'all'       -> tutte
%                      "H+"        -> solo H+
%                      ["H+","He2+"] o {'H+','He2+'} -> elenco di specie
%
%   OUTPUT:
%     ax : vettore di 3 handle agli axes [axXY, axXZ, axYZ]
%          (vuoto se non ci sono dati da plottare)

    %-------------------------
    % 0) Parsing input
    %-------------------------
    p = inputParser;
    addParameter(p, 'XTolerance', 1e-3, @(x) isnumeric(x) && isscalar(x) && x>=0);
    addParameter(p, 'MarkerSize', 10,  @(x) isnumeric(x) && isscalar(x) && x>0);
    addParameter(p, 'Species',   [],  @(x) true); % controllo dettagliato in selectSpecies
    parse(p, varargin{:});

    tolX       = p.Results.XTolerance;
    markerSize = p.Results.MarkerSize;
    speciesOpt = p.Results.Species;

    % Controllo colonne minime
    needed = {'IonN','X','Y','Z','Species'};
    if ~all(ismember(needed, T.Properties.VariableNames))
        error('plotFinalSpotBySpecies:MissingColumns', ...
              'T deve contenere le colonne: %s.', strjoin(needed, ', '));
    end

    %-------------------------
    % 1) Seleziono i colpi sul rivelatore (Xmax)
    %-------------------------
    Tdet = getDetectorHitsAtXmax(T, 'XTolerance', tolX);

    if isempty(Tdet)
        warning('plotFinalSpotBySpecies:EmptyDetectorSet', ...
                'Nessuna particella trovata al piano Xmax (tol=%g).', tolX);
        ax = [];
        return;
    end

    %-------------------------
    % 2) Filtro le specie, se richiesto
    %-------------------------
    [Tdet, speciesNames] = selectSpecies(Tdet, speciesOpt);

    if isempty(Tdet)
        warning('plotFinalSpotBySpecies:NoSpeciesAfterFilter', ...
               'Nessuna delle specie richieste è presente al piano Xmax.');
        ax = [];
        return;
    end

    % Mi assicuro che Species sia categorical "pulito"
    if ~iscategorical(Tdet.Species)
        Tdet.Species = categorical(Tdet.Species);
    end

    %-------------------------
    % 3) Split per specie (struct S con un campo per specie)
    %-------------------------
    [S, ~] = splitBySpecies(Tdet);  % speciesNames già li abbiamo
    nSp    = numel(speciesNames);

    % Colori consistenti su tutte le figure
    co = lines(max(nSp,1));

    %-------------------------
    % 4) Helper interno: crea UNA figura per un piano
    %-------------------------
    function axh = makePlaneFig(plane)
        % Crea figure + axes
        fig = figure;
        axh = axes('Parent', fig);
        hold(axh, 'on');

        for k = 1:nSp
            spName = speciesNames{k};
            fn     = matlab.lang.makeValidName(char(spName));
            Tk     = S.(fn);

            switch plane
                case "XY"
                    x = Tk.X; y = Tk.Y;
                    xlabelStr = 'X [mm]'; ylabelStr = 'Y [mm]';
                    titleStr  = 'XY @ X_{max}';
                case "XZ"
                    x = Tk.X; y = Tk.Z;
                    xlabelStr = 'X [mm]'; ylabelStr = 'Z [mm]';
                    titleStr  = 'XZ @ X_{max}';
                case "YZ"
                    x = Tk.Y; y = Tk.Z;
                    xlabelStr = 'Y [mm]'; ylabelStr = 'Z [mm]';
                    titleStr  = 'YZ @ X_{max}';
                otherwise
                    error('Piano non riconosciuto: %s', plane);
            end

            scatter(axh, x, y, markerSize, co(k,:), 'filled', ...
                'DisplayName', char(spName));
            xlabel(axh, xlabelStr);
            ylabel(axh, ylabelStr);
        end

        axis(axh,'equal');
        grid(axh,'on');
        title(axh, titleStr);

        % Legenda su ogni figura (oppure solo su una, se preferisci)
        legend(axh, 'show', 'Location', 'bestoutside');
    end

    %-------------------------
    % 5) Creo le tre figure separate
    %-------------------------
    ax(1) = makePlaneFig("XY");
    ax(2) = makePlaneFig("XZ");
    ax(3) = makePlaneFig("YZ");
end