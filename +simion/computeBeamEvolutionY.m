function stats = computeBeamEvolutionY(inputArg, varargin)
% COMPUTEBEAMEVOLUTIONY
%   Evoluzione longitudinale di posizione media e larghezza in Y (e Z)
%   per ogni specie, lungo l'asse X.
%
%   Le sezioni x_k NON vengono fissate a priori, ma ricavate in automatico
%   dai dati: si cercano gruppi di X separati da "grossi" salti (tipico
%   caso: file SIMION registrato solo sui piani x_k tramite marker).
%
%   % Caso 1: passi direttamente la TABLE SIMION
%   stats = simion.computeBeamEvolutionY(T)
%
%   % Caso 2: passi il NOME FILE (chiama lui importSimionTofTable)
%   stats = simion.computeBeamEvolutionY('data_raw/trajectories/beamevol.txt')
%
%   Opzioni Name-Value:
%     'Species'          : "all" (default) oppure lista di specie
%     'MinCountPerSlice' : minimo numero di punti per includere un piano x_k
%     'DoFit'            : esegue il fit lineare di µ_y(x) (default: true)
%
%   OUTPUT (struct "stats")
%     stats.SpeciesStats : struct array, uno per specie, con campi:
%         - Species  : nome specie (string)
%         - X        : centri dei piani x_k (in mm)
%         - N        : numero di punti in ciascun piano
%         - muY      : posizione media in Y per piano
%         - sigmaY   : RMS in Y per piano
%         - muZ      : (se presente) posizione media in Z
%         - sigmaZ   : (se presente) RMS in Z
%         - FitMuY   : struct con fit lineare
%             · a      : intercetta
%             · b      : pendenza (≈ θ_y,mean)
%             · theta  : alias di b
%             · xMin   : X min usato nel fit
%             · xMax   : X max usato nel fit
%
%     stats.FitSummary  : table riassuntiva (una riga per specie) con:
%         Species, a_y, b_y, theta_y_mean, xMin_fit, xMax_fit

    %-------------------------
    % 0) Gestione input: table o filename
    %-------------------------
    filename = '';

    if istable(inputArg)
        T = inputArg;
    elseif ischar(inputArg) || isstring(inputArg)
        filename = char(inputArg);
        T = simion.importSimionTofTable(filename);
    else
        error('computeBeamEvolutionY:BadInput', ...
              'Il primo argomento deve essere una table o un filename (char/string).');
    end

    if ~istable(T)
        error('computeBeamEvolutionY:NotATable', ...
              'Import fallito: il risultato non è una table.');
    end

    % Colonne minime richieste
    reqVars = {'X','Y','Species'};
    for v = reqVars
        if ~ismember(v{1}, T.Properties.VariableNames)
            error('computeBeamEvolutionY:MissingColumn', ...
                  'La table deve contenere la colonna "%s".', v{1});
        end
    end

    hasZ = ismember('Z', T.Properties.VariableNames);

    %-------------------------
    % 1) Parser delle opzioni
    %-------------------------
    p = inputParser;
    p.FunctionName = 'computeBeamEvolutionY';

    addParameter(p, 'Species', "all", ...
        @(s) isstring(s) || ischar(s) || iscellstr(s));

    addParameter(p, 'MinCountPerSlice', 10, ...
        @(n) isnumeric(n) && isscalar(n) && n >= 1);

    addParameter(p, 'DoFit', true, ...
        @(b) islogical(b) && isscalar(b));

    parse(p, varargin{:});

    spSel    = p.Results.Species;
    minCount = p.Results.MinCountPerSlice;
    doFit    = p.Results.DoFit;

    %-------------------------
    % 2) Filtro specie
    %-------------------------
    Tloc = T;
    Tloc.Species = categorical(string(Tloc.Species));

    if ~(isstring(spSel) && isscalar(spSel) && spSel == "all")
        spListReq = string(spSel(:));
        mask      = ismember(Tloc.Species, categorical(spListReq));
        Tloc      = Tloc(mask,:);
        if isempty(Tloc)
            error('computeBeamEvolutionY:EmptyAfterFilter', ...
                  'Nessun record rimasto dopo il filtro sulle specie.');
        end
    end

    %-------------------------
    % 3) Trova automaticamente i piani x_k dai dati
    %-------------------------
    Xall = sort(Tloc.X);
    xMinAll = Xall(1);
    xMaxAll = Xall(end);
    if xMinAll == xMaxAll
        error('computeBeamEvolutionY:DegenerateX', ...
              'Tutti i punti hanno lo stesso X: impossibile definire piani distinti.');
    end

    % idea: i marker producono "bande" di X separate da grossi salti.
    % cerchiamo i salti grandi nella sequenza ordinata.
    dx      = diff(Xall);
    rangeX  = xMaxAll - xMinAll;
    gapThr  = 0.1 * rangeX;   % 10% dell'intervallo totale: becca i gap grossi

    breakIdx = find(dx > gapThr);   % indici dove inizia un nuovo gruppo

    if isempty(breakIdx)
        % nessun grande salto: consideriamo un unico "piano" aggregato
        idxStart = 1;
        idxEnd   = numel(Xall);
    else
        idxStart = [1; breakIdx+1];
        idxEnd   = [breakIdx; numel(Xall)];
    end

    nXSlices = numel(idxStart);
    xCenters = zeros(nXSlices,1);
    xEdges   = zeros(nXSlices+1,1);

    for i = 1:nXSlices
        xCluster = Xall(idxStart(i):idxEnd(i));
        xCenters(i) = mean(xCluster);

        if i == 1
            xEdges(1) = min(xCluster) - 1e-6;
        end
        if i == nXSlices
            xEdges(end) = max(xCluster) + 1e-6;
        end
        if i < nXSlices
            xNext   = Xall(idxStart(i+1):idxEnd(i+1));
            xEdges(i+1) = 0.5*(max(xCluster) + min(xNext));
        end
    end

    speciesNames = categories(Tloc.Species);
    nSp          = numel(speciesNames);

    %-------------------------
    % 4) Loop sulle specie
    %-------------------------
    SpeciesStats   = struct([]);        % inizializzato al primo giro
    fitSummaryRows = cell(nSp,6);       % una riga per specie

    for k = 1:nSp
        spName = speciesNames{k};
        maskSp = (Tloc.Species == spName);
        Tk     = Tloc(maskSp,:);

        Xs = Tk.X;
        Ys = Tk.Y;
        if hasZ
            Zs = Tk.Z;
        else
            Zs = [];
        end

        N      = zeros(nXSlices,1);
        muY    = nan(nXSlices,1);
        sigmaY = nan(nXSlices,1);

        if hasZ
            muZ    = nan(nXSlices,1);
            sigmaZ = nan(nXSlices,1);
        else
            muZ    = [];
            sigmaZ = [];
        end

        % --- Binning per piani x_k (usando xEdges e xCenters auto) ---
        for ix = 1:nXSlices
            xL = xEdges(ix);
            xR = xEdges(ix+1);

            if ix < nXSlices
                inBin = (Xs >= xL) & (Xs <  xR);
            else
                inBin = (Xs >= xL) & (Xs <= xR);
            end

            if ~any(inBin)
                continue;
            end

            yk = Ys(inBin);
            N(ix) = numel(yk);

            if N(ix) < minCount
                continue;   % troppo pochi punti: lascio NaN
            end

            my    = mean(yk);
            dy    = yk - my;
            sig_y = sqrt(mean(dy.^2));   % RMS (1/N)

            muY(ix)    = my;
            sigmaY(ix) = sig_y;

            if hasZ
                zk    = Zs(inBin);
                mz    = mean(zk);
                dz    = zk - mz;
                sig_z = sqrt(mean(dz.^2));

                muZ(ix)    = mz;
                sigmaZ(ix) = sig_z;
            end
        end

        %-------------------------
        % 5) Fit lineare µ_y(x)
        %-------------------------
        FitMuY = struct('a', NaN, 'b', NaN, 'theta', NaN, ...
                        'xMin', NaN, 'xMax', NaN);

        if doFit
            validMask = ~isnan(muY) & (N >= minCount);
            xFit      = xCenters(validMask);
            yFit      = muY(validMask);

            if numel(xFit) >= 2
                pfit   = polyfit(xFit, yFit, 1);  % µ_y ≈ a + b x
                b_y    = pfit(1);
                a_y    = pfit(2);
                theta  = b_y;    % per piccoli angoli θ ≈ tanθ ≈ b

                FitMuY.a     = a_y;
                FitMuY.b     = b_y;
                FitMuY.theta = theta;
                FitMuY.xMin  = min(xFit);
                FitMuY.xMax  = max(xFit);
            end
        end

        %-------------------------
        % 6) Struct per questa specie
        %-------------------------
        spStruct = struct();
        spStruct.Species = string(spName);
        spStruct.X       = xCenters(:);
        spStruct.N       = N;
        spStruct.muY     = muY;
        spStruct.sigmaY  = sigmaY;
        spStruct.muZ     = muZ;
        spStruct.sigmaZ  = sigmaZ;
        spStruct.FitMuY  = FitMuY;

        if k == 1
            SpeciesStats = repmat(spStruct, nSp, 1);
        end
        SpeciesStats(k) = spStruct;

        fitSummaryRows(k,:) = { string(spName), ...
                                FitMuY.a, FitMuY.b, FitMuY.theta, ...
                                FitMuY.xMin, FitMuY.xMax };
    end

    %-------------------------
    % 7) Tabella riassuntiva dei fit
    %-------------------------
    FitSummary = cell2table(fitSummaryRows, ...
        'VariableNames', {'Species','a_y','b_y','theta_y_mean', ...
                          'xMin_fit','xMax_fit'});

    %-------------------------
    % 8) Output finale
    %-------------------------
    stats = struct();
    stats.SpeciesStats     = SpeciesStats;
    stats.FitSummary       = FitSummary;
    stats.MinCountPerSlice = minCount;
    stats.NumXSlices       = nXSlices;
    stats.XEdges           = xEdges;
    stats.XCenters         = xCenters;
    stats.SpeciesList      = speciesNames;

    if ~isempty(filename)
        stats.FileName = filename;
    else
        stats.FileName = '';
    end
end