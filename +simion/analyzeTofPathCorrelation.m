function [stats_Lmin, stats_det] = analyzeTofPathCorrelation(T, Lmin, XTol)
% ANALYZETOFPATHCORRELATION
%   Analizza la correlazione TOF–L in due modi:
%     1) Tutte le particelle con L >= Lmin (stats_Lmin)
%     2) Tutte le particelle che arrivano al piano più a valle X ≈ Xmax,
%        indipendentemente da L (stats_det)
%
%   USO:
%     [stats_Lmin, stats_det] = analyzeTofPathCorrelation(T)
%     [stats_Lmin, stats_det] = analyzeTofPathCorrelation(T, Lmin)
%     [stats_Lmin, stats_det] = analyzeTofPathCorrelation(T, Lmin, XTol)
%
%   INPUT:
%     T    : table con colonne almeno:
%              IonN, TOF, X, Y, Z
%            e idealmente Mass / Species per filtrare gli e-
%     Lmin : soglia su L per lo scenario 1 (default = -Inf)
%     XTol : tolleranza su Xend per definire Xmax (default auto)
%
%   OUTPUT:
%     stats_Lmin : struct con fit/width usando solo L >= Lmin
%     stats_det  : struct con fit/width usando solo Xend ≈ Xmax
%
%   In entrambi:
%      .ID, .L, .TOF, .Xend
%      .slope, .intercept, .R, .R2
%      .FWHM_TOF, .FWHM_L, .FWHM_TOF_geom, .geom_fraction
%      .Lmin, .XTol, .N_total, .N_used

    % -------------------------------------------------------------
    % Parametri opzionali
    % -------------------------------------------------------------
    if nargin < 2 || isempty(Lmin)
        Lmin = -Inf;
    end
    if nargin < 3
        XTol = [];
    end

    % -------------------------------------------------------------
    % 0) Controllo campi minimi
    % -------------------------------------------------------------
    requiredVars = {'IonN','TOF','X','Y','Z'};
    for k = 1:numel(requiredVars)
        if ~ismember(requiredVars{k}, T.Properties.VariableNames)
            error('La tabella T deve contenere la colonna "%s".', requiredVars{k});
        end
    end

    % -------------------------------------------------------------
    % 0.5) Filtro elettroni (se possibile)
    % -------------------------------------------------------------
    if ismember('Species', T.Properties.VariableNames)
        sp = string(T.Species);
        mask_e = (sp == "e-" | sp == "electron" | sp == "Electron");
    elseif ismember('Mass', T.Properties.VariableNames)
        m = T.Mass;
        mask_e = m < 0.01;  % e- ~5.5e-4 u, ioni molto più pesanti
    else
        warning('analyzeTofPathCorrelation:NoSpeciesInfo', ...
            ['Nessuna colonna Species/Mass: uso tutte le particelle ', ...
             '(nessun filtro specifico per e-).']);
        mask_e = true(height(T),1);
    end

    if ~any(mask_e)
        error(['Nessun elettrone trovato nella tabella T (Species==e- o massa < 0.01). ' ...
               'Controlla il file di input o la definizione delle specie.']);
    end

    T = T(mask_e,:);

    % -------------------------------------------------------------
    % 1) Vettori ID, TOF, X, Y, Z e ordinamento
    % -------------------------------------------------------------
    id = T.IonN;
    t  = T.TOF;
    x  = T.X;
    y  = T.Y;
    z  = T.Z;

    [~, idxSort] = sortrows([id, t]);   % ordina per (ID, TOF)
    id = id(idxSort);
    t  = t(idxSort);
    x  = x(idxSort);
    y  = y(idxSort);
    z  = z(idxSort);

    [g, IDlist] = findgroups(id);

    % path length per particella
    pathFun = @(xg,yg,zg) sum( sqrt(diff(xg).^2 + diff(yg).^2 + diff(zg).^2) );
    L_all   = splitapply(pathFun, x, y, z, g);

    % TOF finale per particella
    lastTimeFun = @(tg) tg(end);
    TOF_all     = splitapply(lastTimeFun, t, g);

    % X finale per particella
    lastXFun = @(xg) xg(end);
    Xend_all = splitapply(lastXFun, x, g);

    N_total = numel(IDlist);

    % -------------------------------------------------------------
    % 1.5) Definizione Xmax e maschera su X (per scenario 2)
    % -------------------------------------------------------------
    Xmax = max(Xend_all);

    if isempty(XTol)
        scaleX = max(1, max(abs(Xend_all)));
        XTol = 1e-6 * scaleX;
    end

    maskX = abs(Xend_all - Xmax) <= XTol;

    % -------------------------------------------------------------
    % 2) Maschere per i due casi
    % -------------------------------------------------------------
    mask_Lmin = (L_all >= Lmin);   % Scenario 1: solo Lmin
    mask_det  = maskX;            % Scenario 2: solo X ≈ Xmax (no Lmin)

    % -------------------------------------------------------------
    % 3) Costruisci le due struct di output
    % -------------------------------------------------------------
    stats_Lmin = buildStats(IDlist, L_all, TOF_all, Xend_all, ...
                            mask_Lmin, Lmin, XTol, N_total, 'L \\geq L_{min}');

    stats_det  = buildStats(IDlist, L_all, TOF_all, Xend_all, ...
                            mask_det, Lmin, XTol, N_total, 'X \\approx X_{max}');

end

% =================================================================
% Funzione helper: costruisce una struct stats e fa il fit+plot
% =================================================================
function stats = buildStats(IDlist, L_all, TOF_all, Xend_all, ...
                            mask, Lmin, XTol, N_total, tag)

    ID   = IDlist(mask);
    L    = L_all(mask);
    TOF  = TOF_all(mask);
    Xend = Xend_all(mask);

    N_used = numel(ID);

    fprintf('\n=== Scenario: %s ===\n', tag);
    fprintf('Particelle totali (e-): %d, usate nel fit: %d\n', ...
            N_total, N_used);

    if N_used < 2
        warning('Troppo poche particelle per il fit (N_used = %d).', N_used);
        stats = struct();
        stats.ID_all        = IDlist;
        stats.L_all         = L_all;
        stats.TOF_all       = TOF_all;
        stats.Xend_all      = Xend_all;

        stats.ID            = ID;
        stats.L             = L;
        stats.TOF           = TOF;
        stats.Xend          = Xend;

        stats.slope         = NaN;
        stats.intercept     = NaN;
        stats.R             = NaN;
        stats.R2            = NaN;
        stats.FWHM_TOF      = NaN;
        stats.FWHM_L        = NaN;
        stats.FWHM_TOF_geom = NaN;
        stats.geom_fraction = NaN;

        stats.Lmin          = Lmin;
        stats.XTol          = XTol;
        stats.N_total       = N_total;
        stats.N_used        = N_used;
        return;
    end

    % Fit lineare TOF = a*L + b
    p = polyfit(L, TOF, 1);
    Lfit = linspace(min(L), max(L), 100);

    % Plot scatter + fit
    figure;
    scatter(L, TOF, '.');
    hold on;
    plot(Lfit, polyval(p, Lfit), 'r-', 'LineWidth', 1.5);
    grid on;
    xlabel('Path length L');
    ylabel('TOF finale');
    title(sprintf('TOF vs L (%s)', tag));

    % Correlazione
    R  = corr(L, TOF);
    R2 = R^2;

    fprintf('--- Fit lineare TOF = a*L + b ---\n');
    fprintf('a (pendenza)   = %.3e (unità TOF / unità L)\n', p(1));
    fprintf('b (intercetta) = %.3e\n', p(2));
    fprintf('R              = %.3f\n', R);
    fprintf('R^2            = %.3f\n', R2);

    % FWHM da sigma
    sigma_t = std(TOF);
    sigma_L = std(L);

    FWHM_TOF = 2*sqrt(2*log(2))*sigma_t;
    FWHM_L   = 2*sqrt(2*log(2))*sigma_L;

    % velocità media dal fit
    v_bar = 1 / p(1);
    FWHM_TOF_geom = FWHM_L / v_bar;
    geom_fraction = min(max(FWHM_TOF_geom / FWHM_TOF, 0), 1);

    fprintf('--- FWHM (%s) ---\n', tag);
    fprintf('FWHM_TOF (misurata)          = %.3e\n', FWHM_TOF);
    fprintf('FWHM_L   (path length)       = %.3e\n', FWHM_L);
    fprintf('FWHM_TOF_geom = FWHM_L/v_bar = %.3e\n', FWHM_TOF_geom);
    fprintf('Quota FWHM spiegata da L     = %.1f %%\n', geom_fraction*100);

    % Istogrammi
    figure;
    subplot(1,2,1);
    histogram(TOF, 60);
    xlabel('TOF finale'); ylabel('Counts');
    title(sprintf('Distribuzione TOF (%s)', tag));

    subplot(1,2,2);
    histogram(L, 60);
    xlabel('Path length L'); ylabel('Counts');
    title(sprintf('Distribuzione L (%s)', tag));

    % Struct di output
    stats = struct();
    stats.ID_all        = IDlist;
    stats.L_all         = L_all;
    stats.TOF_all       = TOF_all;
    stats.Xend_all      = Xend_all;

    stats.ID            = ID;
    stats.L             = L;
    stats.TOF           = TOF;
    stats.Xend          = Xend;

    stats.slope         = p(1);
    stats.intercept     = p(2);
    stats.R             = R;
    stats.R2            = R2;

    stats.FWHM_TOF      = FWHM_TOF;
    stats.FWHM_L        = FWHM_L;
    stats.FWHM_TOF_geom = FWHM_TOF_geom;
    stats.geom_fraction = geom_fraction;

    stats.Lmin          = Lmin;    % solo "informativo": non usato se scenario è Xmax
    stats.XTol          = XTol;
    stats.N_total       = N_total;
    stats.N_used        = N_used;
end