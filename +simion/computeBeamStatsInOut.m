function stats = computeBeamStatsInOut(T, varargin)
% COMPUTEBEAMSTATSINOUT
%   Analisi statistica del fascio in ingresso (sorgente) e in uscita
%   (piano del detector x_out) per ogni specie.
%
%   stats = simion.computeBeamStatsInOut(T)
%   stats = simion.computeBeamStatsInOut(T, 'XTolerance', tol, 'Rcenter', [y0 z0])
%
%   INPUT
%     T : table con i record SIMION per tutte le sezioni x_k, contenente
%         almeno le colonne:
%           IonN, X, Y, Z, Species
%
%   OPZIONI (Name-Value)
%     'XTolerance' : tolleranza su X rispetto a Xmax per definire x_out
%                    (default 1e-3)
%     'Rcenter'    : [y0 z0] centro per definire r = sqrt((Y-y0)^2 + (Z-z0)^2)
%                    (default [0 0])
%
%   OUTPUT (struct "stats")
%     stats.SpotBySpecies : table con una riga per specie s, colonne:
%         Species
%         N0        : numero di particelle all'ingresso (IonN unici)
%         Ndet      : numero di particelle che arrivano a x_out
%         T_eff     : efficienza T^(s) = Ndet / N0
%
%         mu_y_in,  sigma_y_in
%         mu_y_out, sigma_y_out
%
%         mu_z_in,  sigma_z_in
%         mu_z_out, sigma_z_out
%
%         mu_r_in,  sigma_r_in
%         mu_r_out, sigma_r_out
%
%         R_y       : fattore di crescita sigma_y_out / sigma_y_in
%
%     stats.SeparationY : table con una riga per ogni coppia (s1,s2), colonne:
%         Species1, Species2, S_y    (separazione in y in uscita)
%
%     stats.SeparationR : table analoga per r in uscita:
%         Species1, Species2, S_r
%
%   NOTE
%     - Le deviazioni standard sono calcolate con std(x,1) (normalizzazione 1/N).
%     - Ingresso = primo record per ciascun IonN (getInitialHitsByIon).
%     - Uscita   = colpi sul piano x_out = Xmax (getDetectorHitsAtXmax).
%
%   ESEMPIO
%     T = simion.importSimionTofTable("14keV.txt");
%     stats = simion.computeBeamStatsInOut(T, ...
%                 'XTolerance', 1e-3, ...
%                 'Rcenter', [37.5 0]);
%
%     stats.SpotBySpecies
%     stats.SeparationY

    %-------------------------
    % 0) Parsing input
    %-------------------------
    p = inputParser;
    addParameter(p, 'XTolerance', 1e-3, @(x) isnumeric(x) && isscalar(x) && x>=0);
    addParameter(p, 'Rcenter',   [0 0], @(x) isnumeric(x) && numel(x)==2);
    parse(p, varargin{:});

    tolX    = p.Results.XTolerance;
    rCenter = p.Results.Rcenter(:).';

    %-------------------------
    % 1) Controllo colonne minime
    %-------------------------
    needed = {'IonN','X','Y','Z','Species'};
    if ~all(ismember(needed, T.Properties.VariableNames))
        error('computeBeamStatsInOut:MissingColumns', ...
              'T deve contenere le colonne: %s.', strjoin(needed, ', '));
    end

    % Species come categorical pulito
    if iscategorical(T.Species)
        speciesVec = T.Species;
    else
        speciesVec = categorical(string(T.Species));
        T.Species  = speciesVec;
    end
    speciesAll = categories(speciesVec);
    nSp        = numel(speciesAll);

    %-------------------------
    % 2) Fascio in ingresso: primo record per IonN
    %-------------------------
    Tin = getInitialHitsByIon(T);   % helper in +simion/private

    if iscategorical(Tin.Species)
        speciesIn = Tin.Species;
    else
        speciesIn = categorical(string(Tin.Species));
        Tin.Species = speciesIn;
    end

    % N0 per specie = numero di IonN in Tin
    N0 = zeros(nSp,1);
    for k = 1:nSp
        sp = speciesAll{k};
        mask = (speciesIn == sp);
        ionsSp = unique(Tin.IonN(mask));
        N0(k)  = numel(ionsSp);
    end

    % Statistiche in ingresso
    mu_y_in    = NaN(nSp,1);
    sigma_y_in = NaN(nSp,1);
    mu_z_in    = NaN(nSp,1);
    sigma_z_in = NaN(nSp,1);
    mu_r_in    = NaN(nSp,1);
    sigma_r_in = NaN(nSp,1);

    y0 = rCenter(1);
    z0 = rCenter(2);

    for k = 1:nSp
        sp = speciesAll{k};
        Tk = Tin(speciesIn == sp, :);
        if isempty(Tk), continue; end

        y = Tk.Y;
        z = Tk.Z;
        r = hypot(y - y0, z - z0);

        mu_y_in(k)    = mean(y);
        sigma_y_in(k) = std(y, 1);

        mu_z_in(k)    = mean(z);
        sigma_z_in(k) = std(z, 1);

        mu_r_in(k)    = mean(r);
        sigma_r_in(k) = std(r, 1);
    end

    %-------------------------
    % 3) Fascio in uscita: colpi al piano x_out
    %-------------------------
    Tdet = getDetectorHitsAtXmax(T, 'XTolerance', tolX);  % helper esistente

    if isempty(Tdet)
        warning('computeBeamStatsInOut:EmptyDetectorSet', ...
                'Nessuna particella trovata al piano Xmax (tol = %g).', tolX);
        stats = struct( ...
            'SpotBySpecies', table(), ...
            'SeparationY',   table(), ...
            'SeparationR',   table());
        return;
    end

    if iscategorical(Tdet.Species)
        speciesDet = Tdet.Species;
    else
        speciesDet = categorical(string(Tdet.Species));
        Tdet.Species = speciesDet;
    end

    % Ndet per specie
    Ndet = zeros(nSp,1);
    for k = 1:nSp
        sp = speciesAll{k};
        Ndet(k) = sum(speciesDet == sp);
    end

    % Statistiche in uscita
    mu_y_out    = NaN(nSp,1);
    sigma_y_out = NaN(nSp,1);
    mu_z_out    = NaN(nSp,1);
    sigma_z_out = NaN(nSp,1);
    mu_r_out    = NaN(nSp,1);
    sigma_r_out = NaN(nSp,1);

    for k = 1:nSp
        sp = speciesAll{k};
        Tk = Tdet(speciesDet == sp, :);
        if isempty(Tk), continue; end

        y = Tk.Y;
        z = Tk.Z;
        r = hypot(y - y0, z - z0);

        mu_y_out(k)    = mean(y);
        sigma_y_out(k) = std(y, 1);

        mu_z_out(k)    = mean(z);
        sigma_z_out(k) = std(z, 1);

        mu_r_out(k)    = mean(r);
        sigma_r_out(k) = std(r, 1);
    end

    %-------------------------
    % 4) Efficienza T^(s) e fattore di crescita R_y
    %-------------------------
    T_eff = zeros(nSp,1);
    nonzero = N0 > 0;
    T_eff(nonzero) = Ndet(nonzero) ./ N0(nonzero);

    R_y = NaN(nSp,1);
    validRy = sigma_y_in > 0 & ~isnan(sigma_y_out);
    R_y(validRy) = sigma_y_out(validRy) ./ sigma_y_in(validRy);

    %-------------------------
    % 5) Tabella riassuntiva per specie
    %-------------------------
    Species = string(speciesAll(:));

    SpotBySpecies = table( ...
        Species, N0, Ndet, T_eff, ...
        mu_y_in,    sigma_y_in, ...
        mu_y_out,   sigma_y_out, ...
        mu_z_in,    sigma_z_in, ...
        mu_z_out,   sigma_z_out, ...
        mu_r_in,    sigma_r_in, ...
        mu_r_out,   sigma_r_out, ...
        R_y, ...
        'VariableNames', { ...
            'Species', 'N0', 'Ndet', 'T_eff', ...
            'mu_y_in',    'sigma_y_in', ...
            'mu_y_out',   'sigma_y_out', ...
            'mu_z_in',    'sigma_z_in', ...
            'mu_z_out',   'sigma_z_out', ...
            'mu_r_in',    'sigma_r_in', ...
            'mu_r_out',   'sigma_r_out', ...
            'R_y'});

    %-------------------------
    % 6) Misure di separazione in uscita (S_y, S_r)
    %-------------------------
    pairs_i = [];
    pairs_j = [];
    S_y = [];
    S_r = [];

    for i = 1:nSp-1
        for j = i+1:nSp
            % Sy out
            numY = abs(mu_y_out(i) - mu_y_out(j));
            denY = sqrt(sigma_y_out(i)^2 + sigma_y_out(j)^2);
            if denY > 0 && ~isnan(numY)
                Sy_ij = numY / denY;
            else
                Sy_ij = NaN;
            end

            % Sr out
            numR = abs(mu_r_out(i) - mu_r_out(j));
            denR = sqrt(sigma_r_out(i)^2 + sigma_r_out(j)^2);
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
    % 7) Impacchetto nell'output
    %-------------------------
    stats = struct( ...
        'SpotBySpecies', SpotBySpecies, ...
        'SeparationY',   SeparationY, ...
        'SeparationR',   SeparationR);
end