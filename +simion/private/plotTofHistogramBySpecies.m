function FitResults = plotTofHistogramBySpecies(T, nbins)
% plotTofHistogramBySpecies  -  PDF del TOF per specie con istogrammi + fit.
%
%   FitResults = plotTofHistogramBySpecies(T, nbins)
%
% INPUT:
%   T     - table con almeno: TOF, Mass, Charge (+ opzionale Events)
%   nbins - numero di bin globale usato per tutte le specie
%
% OUTPUT:
%   FitResults - struct array con parametri del fit per ciascuna specie.

    if nargin < 2 || isempty(nbins)
        nbins = 50;
    end

    % Se presente, tieni solo un certo tipo di evento (es. Events == 4)
    if ismember("Events", T.Properties.VariableNames)
        T = T(T.Events == 4, :);
    end

    % Rimuovi TOF NaN
    T = T(~isnan(T.TOF), :);

    % Scala TOF in ns (se in µs -> 1e3, se in qualcos'altro adatta)
    scale = 1e3;
    tofAll = T.TOF * scale;

    % Bin globali per tutte le specie (così le PDF sono confrontabili)
    edges  = linspace(min(tofAll), max(tofAll), nbins + 1);

    % --- SPECIE DISTINTE (Mass, Charge) ---
    MC = T{:, {'Mass','Charge'}};
    [speciesMC, ~] = unique(MC, 'rows');
    nspecies = size(speciesMC, 1);

    masses  = speciesMC(:,1);
    charges = speciesMC(:,2);

    cmap   = lines(nspecies);

    figure; hold on;
    leg       = cell(nspecies, 1);
    hBar      = gobjects(nspecies, 1);   % handle istogrammi
    FitResults = struct([]);

    for k = 1:nspecies
        mk = masses(k);
        qk = charges(k);

        % Maschera per la specie k-esima
        mask_k = (T.Mass == mk) & (T.Charge == qk);
        tof_k  = T.TOF(mask_k) * scale;

        % Istogramma normalizzato a PDF
        [N, ~]  = histcounts(tof_k, edges, 'Normalization', 'pdf');
        centers = edges(1:end-1) + diff(edges)/2;

        % Istogramma (rettangoli) – questo va in legenda
        hBar(k) = bar(centers, N, ...
                      'FaceColor', cmap(k,:), ...
                      'FaceAlpha', 0.5, ...
                      'EdgeColor', 'none');

        % Fit gaussiano sui dati grezzi (TOF)
        pd   = fitdist(tof_k, 'Normal');
        xfit = linspace(min(centers), max(centers), 400);
        yfit = pdf(pd, xfit);

        % Curva del fit
        plot(xfit, yfit, '--', 'Color', cmap(k,:), 'LineWidth', 2);

        % =========================
        %  NOME SPECIE con classifySpecies
        % =========================
        spcat       = classifySpecies(mk, qk);   % es. "e-", "H+", "O6+"
        speciesRaw  = char(spcat);              % stringa "liscia"
        speciesName = formatSpeciesForTex(speciesRaw);  % per legenda TeX

        leg{k} = speciesName;

        % Salva risultati del fit
        FitResults(k).species = speciesRaw;  % es. "O6+"
        FitResults(k).mass    = mk;
        FitResults(k).charge  = qk;
        FitResults(k).mu      = pd.mu;
        FitResults(k).sigma   = pd.sigma;
        FitResults(k).FWHM    = 2*sqrt(2*log(2)) * pd.sigma;
        FitResults(k).N       = numel(tof_k);
    end

    xlabel('TOF [ns]');
    ylabel('Probability Density');
    title('TOF Distribution by species');
    lgd = legend(hBar, leg, 'Location', 'best');   % <-- SOLO istogrammi
    set(lgd, 'Interpreter', 'tex');
    grid on;
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
            % Prova a parsare pattern generico tipo "X6+"
            % (lettere + numero + segno)
            expr = '([A-Za-z]+)([0-9]+[+-])';
            tokens = regexp(s_raw, expr, 'tokens', 'once');
            if ~isempty(tokens)
                s_tex = sprintf('%s^{%s}', tokens{1}, tokens{2});
            else
                s_tex = s_raw;
            end
    end
end