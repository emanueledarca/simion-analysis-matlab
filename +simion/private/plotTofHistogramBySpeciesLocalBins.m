function FitResults = plotTofHistogramBySpeciesLocalBins(T, nbins, xlimUser, ylimUser)
% plotTofHistogramBySpeciesLocalBins
%   Istogramma PDF del TOF per specie (Mass,Charge), con bin calcolati
%   sul proprio intervallo [min,max], + fit gaussiano.
%
%   Extra:
%   - usa solo le particelle che si schiantano in fondo al rivelatore
%     (X == max(T.X), se la colonna X esiste).
%   - consente di specificare limiti degli assi:
%       xlimUser = [xmin xmax], ylimUser = [ymin ymax]
%     Se omessi o vuoti, l'asse corrispondente va in autoscale.
%     In ogni caso xmin >= 0 e ymin >= 0.
%
%   FitResults = plotTofHistogramBySpeciesLocalBins(T, nbins, xlimUser, ylimUser)

    if nargin < 2 || isempty(nbins)
        nbins = 50;
    end
    if nargin < 3
        xlimUser = [];
    end
    if nargin < 4
        ylimUser = [];
    end

    % Se c'è la colonna Events, tieni solo quelli con Events == 4
    if ismember("Events", T.Properties.VariableNames)
        T = T(T.Events == 4, :);
    end

    % Se c'è la colonna X, tieni solo gli impatti "in fondo": X == max(X)
    if ismember("X", T.Properties.VariableNames)
        xmax = max(T.X);
        T    = T(T.X == xmax, :);

        if isempty(T)
            warning('Nessuna particella con X == max(X). Niente da plottare.');
            FitResults = struct([]);
            return;
        end
    end

    % Rimuovi TOF NaN
    T = T(~isnan(T.TOF), :);

    % Scala TOF: s -> ns (adatta se necessario)
    scale = 1e3;  % T.TOF in µs -> ns (se in s, cambia scala!)

    % Controllo presenza della carica
    if ~ismember("Charge", T.Properties.VariableNames)
        error('La tabella T deve contenere la colonna Charge per distinguere le specie.');
    end

    % Identifica le specie come coppie (Mass, Charge)
    MC = T{:, {'Mass','Charge'}};
    [speciesMC, ~, idxSpecies] = unique(MC, 'rows');
    nspecies = size(speciesMC, 1);

    cmap = lines(nspecies);

    fig = figure('WindowStyle','normal');
    set(fig, 'Color', 'w');   % sfondo bianco pulito
    hold on;

    FitResults = struct([]);
    hBar       = gobjects(0);   % handles effettivamente plottati per la legenda
    leg        = {};            % etichette corrispondenti (in TeX)

    % Per autoscale: massimi globali X (ns) e Y (PDF)
    globalXmax = 0;
    globalYmax = 0;

    for k = 1:nspecies

        mk = speciesMC(k,1);   % massa
        qk = speciesMC(k,2);   % carica

        idx   = (idxSpecies == k);
        tof_k = T.TOF(idx) * scale;   % TOF di quella specie in ns

        if numel(tof_k) < 2
            warning('Specie %d (M=%.3g, q=%.0f) ha meno di 2 eventi, salto.', ...
                    k, mk, qk);
            continue;
        end

        % --- BIN PER SPECIE: edges_k dipende solo da tof_k ---
        edges_k = linspace(min(tof_k), max(tof_k), nbins + 1);
        [N, ~]  = histcounts(tof_k, edges_k, 'Normalization', 'pdf');
        centers = edges_k(1:end-1) + diff(edges_k)/2;

        % Colori: barra leggermente trasparente + bordo un po' più scuro
        baseColor  = cmap(k,:);
        

        % Istogramma (rettangoli) - QUESTO va in legenda
        hB = bar(centers, N, ...
                 'FaceColor', baseColor, ...
                 'FaceAlpha', 0.5, ...      % più trasparente per overlay
                 'LineWidth', 0.2);          % bordo visibile su bianco

        % Fit gaussiano sui dati grezzi della specie (NO legenda)
        pd   = fitdist(tof_k, 'Normal');
        xfit = linspace(min(tof_k), max(tof_k), 400);
        yfit = pdf(pd, xfit);

        % Curva del fit: stessa tinta, linea piena più spessa
        plot(xfit, yfit, '-', ...
             'Color', baseColor, ...
             'LineWidth', 2.0, ...
             'HandleVisibility', 'off');  % non compare in legenda

        % Aggiorna limiti auto globali
        globalXmax = max(globalXmax, max(xfit));
        globalYmax = max([globalYmax, max(N), max(yfit)]);

        % Nome specie via classifySpecies globale
        spcat        = classifySpecies(mk, qk);     % es. "O6+"
        speciesRaw   = char(spcat);                 % "O6+"
        speciesNameT = formatSpeciesForTex(speciesRaw);  % "O^{6+}"

        % Salva handle e label per la legenda
        hBar(end+1) = hB;        %#ok<AGROW>
        leg{end+1}  = speciesNameT;

        % Salva risultati del fit
        FitResults(k).species     = speciesRaw;     % "O6+"
        FitResults(k).species_tex = speciesNameT;   % "O^{6+}"
        FitResults(k).mass        = mk;
        FitResults(k).charge      = qk;
        FitResults(k).mu          = pd.mu;    % ns
        FitResults(k).sigma       = pd.sigma; % ns
        FitResults(k).FWHM        = 2*sqrt(2*log(2)) * pd.sigma; % ns
        FitResults(k).N           = numel(tof_k);
        FitResults(k).binEdges    = edges_k;
        FitResults(k).binCenters  = centers;
        FitResults(k).pdfValues   = N;
    end

    xlabel('TOF [ns]');
    ylabel('Probability Density');
    title('TOF Distribution by species');

    if ~isempty(hBar)
        lgd = legend(hBar, leg, 'Location', 'best');
        set(lgd, 'Interpreter', 'tex');
        set(lgd, 'Box', 'off');           % legenda più pulita su bianco
    end

    % ------------------- LIMITE ASSI -------------------
    if ~isempty(hBar) && globalXmax > 0 && globalYmax > 0

        % X auto: [0, globalXmax]
        xMinAuto = 0;
        xMaxAuto = globalXmax;

        % Y auto: [0, globalYmax * 1.05] (leggero margine)
        yMinAuto = 0;
        yMaxAuto = globalYmax * 1.05;

        % X-limits
        if ~isempty(xlimUser) && numel(xlimUser) == 2
            xVals = sort(xlimUser(:).');
            xMin  = max(0, xVals(1));   % niente negativi
            xMax  = max(xVals(2), xMin);
            xlim([xMin, xMax]);
        else
            xlim([xMinAuto, xMaxAuto]);
        end

        % Y-limits
        if ~isempty(ylimUser) && numel(ylimUser) == 2
            yVals = sort(ylimUser(:).');
            yMin  = max(0, yVals(1));   % niente negativi
            yMax  = max(yVals(2), yMin);
            ylim([yMin, yMax]);
        else
            ylim([yMinAuto, yMaxAuto]);
        end
    end
    % ---------------------------------------------------

    % Estetica assi: griglia leggera su bianco
    ax = gca;
    ax.Box       = 'on';
    ax.LineWidth = 1.0;
    ax.FontSize  = 12;
    grid on;
    ax.GridColor = [0.7 0.7 0.7];
    ax.GridAlpha = 0.3;

    hold off;
end

% -------------------------------------------------------------------------
function s_tex = formatSpeciesForTex(s_raw)
% Converte etichette tipo "O6+" in TeX: "O^{6+}".
% Se non riconosce il formato, restituisce la stringa così com'è.

    switch s_raw
        case 'e-'
            s_tex = 'e^{-}';
        case 'H+'
            s_tex = 'H^{+}';
        case 'He+'
            s_tex = 'He^{+}';
        case 'He2+'
            s_tex = 'He^{2+}';
        case 'O+'
            s_tex = 'O^{+}';
        case 'O-'
            s_tex = 'O^{-}';
        case 'O6+'
            s_tex = 'O^{6+}';
        otherwise
            % Pattern generico tipo "O6+" → "O^{6+}"
            expr = '([A-Za-z]+)([0-9]+[+-])';
            tokens = regexp(s_raw, expr, 'tokens', 'once');
            if ~isempty(tokens)
                s_tex = sprintf('%s^{%s}', tokens{1}, tokens{2});
            else
                s_tex = s_raw;
            end
    end
end