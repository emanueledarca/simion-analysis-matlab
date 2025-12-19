function stats = computeBeamStatsAtDetector(T, varargin)
% COMPUTEBEAMSTATSATDETECTOR
%   Analisi statistica al piano di uscita x = x_out per ogni specie.
%
%   stats = simion.computeBeamStatsAtDetector(T)
%   stats = simion.computeBeamStatsAtDetector(T, 'XTolerance', tol, ...)
%
%   INPUT
%     T : table con i record SIMION per tutte le sezioni x_k, contenente
%         almeno le colonne:
%           IonN, X, Y, Z, Species
%
%   OPZIONI (Name-Value)
%     'XTolerance' : tolleranza su X rispetto a Xmax per definire x_out
%                    (default 1e-3)
%     'Rcenter'    : [y0 z0] centro per definire il r = sqrt((Y-y0)^2 + (Z-z0)^2)
%                    (default [0 0])
%     'SigmaYin'   : informazioni sulla sigma iniziale in y per calcolare
%                    il fattore di crescita R_y. Può essere:
%                    - [] (default)  -> R_y riempito con NaN
%                    - table con variabili: Species, SigmaYin
%                      dove Species è string/categorical, SigmaYin è numerico
%
%   OUTPUT (struct "stats")
%     stats.SpotBySpecies : table con una riga per specie s, colonne:
%         Species
%         N0        : numero di particelle lanciate (uniche IonN) per specie
%         Ndet      : numero di particelle che arrivano a x_out
%         T_eff     : efficienza di trasmissione T^(s) = Ndet / N0
%         mu_y,  sigma_y
%         mu_z,  sigma_z
%         mu_r,  sigma_r
%         R_y      : fattore di crescita σ_y,out / σ_y,in (se SigmaYin fornita)
%
%     stats.SeparationY : table con una riga per ogni coppia (s1,s2), colonne:
%         Species1, Species2, S_y
%
%     stats.SeparationR : analogo per r (Species1, Species2, S_r)
%
%   NOTE
%     - Le deviazioni standard sono calcolate con normalizzazione 1/N
%       (std(x,1)), in accordo con le eq. (13)-(14) degli appunti.
%     - x_out viene definito come Xmax globale del dataset.
%
%   RIFERIMENTO TEORICO
%     Sezione 11.2 "Analisi al piano di uscita" degli appunti:
%     µ_y,out, σ_y,out, fattore R_y, efficienza T^(s), separazione S_y.
%
%   ESEMPIO
%     T = simion.importSimionTofTable("14keV.txt");
%     stats = simion.computeBeamStatsAtDetector(T, ...
%                 'XTolerance', 1e-3, ...
%                 'Rcenter', [37.5 0], ...
%                 'SigmaYin', sourceTable);
%
%     stats.SpotBySpecies
%     stats.SeparationY

    %-------------------------
    % 0) Parsing input
    %-------------------------
    p = inputParser;
    addParameter(p, 'XTolerance', 1e-3, @(x) isnumeric(x) && isscalar(x) && x>=0);
    addParameter(p, 'Rcenter',   [0 0], @(x) isnumeric(x) && numel(x)==2);
    addParameter(p, 'SigmaYin',  [],    @(x) true);  % controllo dentro
    parse(p, varargin{:});

    tolX      = p.Results.XTolerance;
    rCenter   = p.Results.Rcenter(:).';
    SigmaYin  = p.Results.SigmaYin;

    %-------------------------
    % 1) Controllo colonne minime
    %-------------------------
    needed = {'IonN','X','Y','Z','Species'};
    if ~all(ismember(needed, T.Properties.VariableNames))
        error('computeBeamStatsAtDetector:MissingColumns', ...
              'T deve contenere le colonne: %s.', strjoin(needed, ', '));
    end

    % Assicuro che Species sia qualcosa di ragionevole
    if iscategorical(T.Species)
        speciesAll = categories(T.Species);
        speciesVec = categorical(T.Species);
    else
        speciesVec = categorical(string(T.Species));
        speciesAll = categories(speciesVec);
    end
    nSp = numel(speciesAll);

    %-------------------------
    % 2) Conta N0 per specie (tutte le particelle lanciate)
    %-------------------------
    IonN = T.IonN;
    N0   = zeros(nSp,1);

    for k = 1:nSp
        sp = speciesAll{k};
        maskSp = (speciesVec == sp);
        ionsSp = unique(IonN(maskSp));
        N0(k)  = numel(ionsSp);
    end

    %-------------------------
    % 3) Seleziono i colpi al piano di uscita (x_out = Xmax)
    %-------------------------
    Tdet = getDetectorHitsAtXmax(T, 'XTolerance', tolX);
    if isempty(Tdet)
        warning('computeBeamStatsAtDetector:EmptyDetectorSet', ...
                'Nessuna particella trovata al piano Xmax (tol = %g).', tolX);
        stats = struct( ...
            'SpotBySpecies', table(), ...
            'SeparationY',   table(), ...
            'SeparationR',   table());
        return;
    end

    % Allineo il tipo di Species anche in Tdet
    if iscategorical(Tdet.Species)
        speciesDet = categorical(Tdet.Species);
    else
        speciesDet = categorical(string(Tdet.Species));
    end
    Tdet.Species = speciesDet;

    %-------------------------
    % 4) Statistiche per specie
    %-------------------------
    mu_y    = NaN(nSp,1);
    sigma_y = NaN(nSp,1);
    mu_z    = NaN(nSp,1);
    sigma_z = NaN(nSp,1);
    mu_r    = NaN(nSp,1);
    sigma_r = NaN(nSp,1);
    Ndet    = zeros(nSp,1);

    y0 = rCenter(1);
    z0 = rCenter(2);

    for k = 1:nSp
        sp = speciesAll{k};
        maskDet = (Tdet.Species == sp);
        Tk      = Tdet(maskDet, :);
        Ndet(k) = height(Tk);

        if Ndet(k) == 0
            continue;  % rimane tutto NaN, T_eff = 0
        end

        y = Tk.Y;
        z = Tk.Z;

        mu_y(k)    = mean(y);
        sigma_y(k) = std(y, 1);   % 1 -> divide per N

        mu_z(k)    = mean(z);
        sigma_z(k) = std(z, 1);

        r = hypot(y - y0, z - z0);
        mu_r(k)    = mean(r);
        sigma_r(k) = std(r, 1);
    end

    % Efficienza di trasmissione T^(s)
    T_eff = zeros(nSp,1);
    nonzero = N0 > 0;
    T_eff(nonzero) = Ndet(nonzero) ./ N0(nonzero);

    %-------------------------
    % 5) Fattore di crescita R_y (se SigmaYin fornita)
    %-------------------------
    R_y = NaN(nSp,1);

    if ~isempty(SigmaYin)
        % Ci aspettiamo una table con variabili: Species, SigmaYin
        if istable(SigmaYin) && all(ismember({'Species','SigmaYin'}, SigmaYin.Properties.VariableNames))
            if iscategorical(SigmaYin.Species)
                spIn = string(categories(SigmaYin.Species));
                % attenzione: se è categorical con più livelli non usati
                spIn = string(SigmaYin.Species);
            else
                spIn = string(SigmaYin.Species);
            end
            sigIn = SigmaYin.SigmaYin;
        else
            warning('computeBeamStatsAtDetector:SigmaYinFormat', ...
                'SigmaYin dovrebbe essere una table con colonne {Species, SigmaYin}. R_y verrà lasciato NaN.');
            spIn = strings(0,1);
            sigIn = [];
        end

        % Map species -> sigma_y,in
        for k = 1:nSp
            spStr = string(speciesAll{k});
            idx   = find(spIn == spStr, 1);
            if ~isempty(idx) && sigIn(idx) > 0 && ~isnan(sigma_y(k))
                R_y(k) = sigma_y(k) ./ sigIn(idx);
            end
        end
    end

    %-------------------------
    % 6) Costruisco la tabella per specie
    %-------------------------
    Species = string(speciesAll(:));  % colonna string per leggibilità

    SpotBySpecies = table( ...
        Species, N0, Ndet, T_eff, ...
        mu_y, sigma_y, ...
        mu_z, sigma_z, ...
        mu_r, sigma_r, ...
        R_y, ...
        'VariableNames', { ...
            'Species', 'N0', 'Ndet', 'T_eff', ...
            'mu_y', 'sigma_y', ...
            'mu_z', 'sigma_z', ...
            'mu_r', 'sigma_r', ...
            'R_y'});

    %-------------------------
    % 7) Separazione fra specie (S_y e S_r)
    %-------------------------
    % Usiamo le formule:
    %   S_u = |mu_u(s1) - mu_u(s2)| / sqrt( sigma_u(s1)^2 + sigma_u(s2)^2 )
    %
    pairs_i = [];
    pairs_j = [];
    S_y     = [];
    S_r     = [];

    for i = 1:nSp-1
        for j = i+1:nSp
            % Sy
            numY = abs(mu_y(i) - mu_y(j));
            denY = sqrt(sigma_y(i)^2 + sigma_y(j)^2);

            if denY > 0 && ~isnan(numY)
                Sy_ij = numY / denY;
            else
                Sy_ij = NaN;
            end

            % Sr
            numR = abs(mu_r(i) - mu_r(j));
            denR = sqrt(sigma_r(i)^2 + sigma_r(j)^2);

            if denR > 0 && ~isnan(numR)
                Sr_ij = numR / denR;
            else
                Sr_ij = NaN;
            end

            pairs_i(end+1,1) = i; %#ok<AGROW>
            pairs_j(end+1,1) = j; %#ok<AGROW>
            S_y(end+1,1)     = Sy_ij; %#ok<AGROW>
            S_r(end+1,1)     = Sr_ij; %#ok<AGROW>
        end
    end

    if isempty(pairs_i)
        SeparationY = table();
        SeparationR = table();
    else
        Species1 = Species(pairs_i);
        Species2 = Species(pairs_j);

        SeparationY = table( ...
            Species1, Species2, S_y, ...
            'VariableNames', {'Species1','Species2','S_y'});

        SeparationR = table( ...
            Species1, Species2, S_r, ...
            'VariableNames', {'Species1','Species2','S_r'});
    end

    %-------------------------
    % 8) Impacchetto nell'output
    %-------------------------
    stats = struct( ...
        'SpotBySpecies', SpotBySpecies, ...
        'SeparationY',   SeparationY, ...
        'SeparationR',   SeparationR);
end