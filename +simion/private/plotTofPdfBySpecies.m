function FitResults = plotTofPdfBySpecies(T, nbins)
% plotTofPdfBySpecies  -  PDF del TOF per specie (linee) + fit gaussiano.
%
%   FitResults = plotTofPdfBySpecies(T, nbins)
%
% INPUT:
%   T     : table con colonne T.TOF (µs), T.Mass, T.Charge, opz. T.Events
%   nbins : numero di bin (opzionale, default 50)
%
% OUTPUT:
%   FitResults(k).species : etichetta "grezza" ("e-", "H+", "He2+", "O6+", ...)
%   FitResults(k).mass    : massa
%   FitResults(k).charge  : carica
%   FitResults(k).mu      : media del fit (ns)
%   FitResults(k).sigma   : sigma del fit (ns)
%   FitResults(k).FWHM    : full width at half maximum (ns)
%   FitResults(k).N       : numero di eventi per specie

    if nargin < 2 || isempty(nbins)
        nbins = 50;
    end

    % Se presente, filtra per tipo di evento
    if ismember("Events", T.Properties.VariableNames)
        T = T(T.Events == 4, :);
    end

    % Rimuovi TOF NaN
    T = T(~isnan(T.TOF), :);

    % µs → ns (adatta se serve altro)
    scale  = 1e3;
    tofAll = T.TOF * scale;

    % Bin globali per tutte le specie
    edges  = linspace(min(tofAll), max(tofAll), nbins + 1);

    % SPECIE DISTINTE (Mass, Charge)
    MC = T{:, {'Mass','Charge'}};
    [speciesMC, ~] = unique(MC, 'rows');
    nspecies = size(speciesMC, 1);

    masses  = speciesMC(:,1);
    charges = speciesMC(:,2);

    cmap   = lines(nspecies);

    figure; hold on;
    leg      = cell(nspecies, 1);
    FitResults = struct([]);
    hLine    = gobjects(nspecies, 1);   % handle delle linee PDF

    for k = 1:nspecies
        mk = masses(k);
        qk = charges(k);

        % Maschera per la specie k-esima
        mask_k = (T.Mass == mk) & (T.Charge == qk);
        tof_k  = T.TOF(mask_k) * scale;

        % PDF da istogramma normalizzato
        [N, ~]  = histcounts(tof_k, edges, 'Normalization', 'pdf');
        centers = edges(1:end-1) + diff(edges)/2;

        % Linea PDF (questa va in legenda)
        hLine(k) = plot(centers, N, 'LineWidth', 1.5, 'Color', cmap(k,:));

        % Fit gaussiano ai dati grezzi
        pd   = fitdist(tof_k, 'Normal');
        xfit = linspace(min(centers), max(centers), 400);
        yfit = pdf(pd, xfit);

        plot(xfit, yfit, '--', 'Color', cmap(k,:), 'LineWidth', 1.5);

        % Nome specie con classifySpecies
        spcat       = classifySpecies(mk, qk);      % es. "O6+"
        speciesRaw  = char(spcat);                  % stringa "liscia"
        speciesName = formatSpeciesForTex(speciesRaw); % per legenda TeX

        leg{k} = speciesName;

        % Salvo parametri del fit
        FitResults(k).species = speciesRaw;  % "e-", "H+", "O6+", ...
        FitResults(k).mass    = mk;
        FitResults(k).charge  = qk;
        FitResults(k).mu      = pd.mu;
        FitResults(k).sigma   = pd.sigma;
        FitResults(k).FWHM    = 2*sqrt(2*log(2)) * pd.sigma;
        FitResults(k).N       = numel(tof_k);
    end

    xlabel('TOF [ns]');
    ylabel('Densità di probabilità');
    title('Distribuzione di TOF per specie (PDF normalizzata)');
    lgd = legend(hLine, leg, 'Location', 'best');   % SOLO le linee PDF
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