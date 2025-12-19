function FitResults = plotTofBySpecies(T, mode, nbins, varargin)
% plotTofBySpecies  -  Entry point unico per i plot di TOF per specie.
%
%   FitResults = plotTofBySpecies(T)
%   FitResults = plotTofBySpecies(T, mode)
%   FitResults = plotTofBySpecies(T, mode, nbins, ...)
%
% INPUT:
%   T     : table SIMION con almeno: TOF, Mass, Charge
%           (opzionali: Events, X - usati da alcune funzioni).
%
%   mode  : (opzionale) stringa/char che sceglie "come" plottare:
%           - "pdf"         : PDF con linee, bin globali
%                             -> chiama plotTofPdfBySpecies
%           - "hist-global" : istogrammi con bin globali
%                             -> chiama plotTofHistogramBySpecies
%           - "hist-local"  : istogrammi con bin locali per specie,
%                             usa solo X == max(X) se la colonna esiste,
%                             permette limiti degli assi
%                             -> chiama plotTofHistogramBySpeciesLocalBins
%           - "interactive" : elenca le specie, te le fa scegliere,
%                             poi chiama plotTofHistogramBySpeciesLocalBins
%                             -> chiama plotTofHistogramBySpeciesInteractive
%
%           Se omesso, default = "pdf".
%
%   nbins : (opzionale) numero di bin per specie (default 50).
%
%   NOTA di comodità:
%       plotTofBySpecies(T, 60)
%   viene interpretato come:
%       plotTofBySpecies(T, "pdf", 60)
%
% OPZIONI (name-value) per mode == "hist-local":
%   'XLim' : [xmin xmax] in ns   (default [] -> autoscale, xmin >= 0)
%   'YLim' : [ymin ymax] in PDF  (default [] -> autoscale, ymin >= 0)
%
% OUTPUT:
%   FitResults : struct array con i risultati del fit restituiti dalla
%                funzione sottostante (vedi help delle singole funzioni).
%
% ESEMPI:
%   % 1) PDF con linee e bin globali, 50 bin di default
%   Fit_pdf = simion.plotTofBySpecies(T);
%
%   % 2) PDF con linee, 60 bin
%   Fit_pdf = simion.plotTofBySpecies(T, "pdf", 60);
%
%   % 3) Istogrammi con bin globali
%   Fit_histG = simion.plotTofBySpecies(T, "hist-global", 60);
%
%   % 4) Istogrammi con bin locali, con limiti in x
%   Fit_histL = simion.plotTofBySpecies(T, "hist-local", 60, ...
%                                       'XLim', [10 40]);
%
%   % 5) Versione interattiva: scegli specie da plottare
%   Fit_int = simion.plotTofBySpecies(T, "interactive", 60);

    % -----------------------------
    % Normalizzazione input
    % -----------------------------
    if nargin < 2 || isempty(mode)
        % Nessun 'mode' esplicito: default "pdf"
        mode = "pdf";
        % nbins può arrivare come terzo argomento oppure mancare
    elseif isnumeric(mode)
        % Chiamata del tipo plotTofBySpecies(T, 60)
        nbins = mode;
        mode  = "pdf";
    end

    if nargin < 3 || isempty(nbins)
        nbins = 50;
    end

    mode = string(mode);

    % -----------------------------
    % Dispatch a seconda del mode
    % -----------------------------
    switch mode

        case "pdf"
            % Linee, bin globali
            FitResults = plotTofPdfBySpecies(T, nbins);

        case "hist-global"
            % Istogrammi, bin globali
            FitResults = plotTofHistogramBySpecies(T, nbins);

        case "hist-local"
            % Istogrammi, bin locali per specie.
            %
            % Qui gestiamo le opzioni 'XLim' e 'YLim' via inputParser,
            % poi le passiamo a plotTofHistogramBySpeciesLocalBins.

            p = inputParser;
            addParameter(p, 'XLim', [], @(x) isempty(x) || ...
                                        (isnumeric(x) && numel(x)==2));
            addParameter(p, 'YLim', [], @(x) isempty(x) || ...
                                        (isnumeric(x) && numel(x)==2));
            parse(p, varargin{:});

            xlimUser = p.Results.XLim;
            ylimUser = p.Results.YLim;

            FitResults = plotTofHistogramBySpeciesLocalBins( ...
                             T, nbins, xlimUser, ylimUser);

        case "interactive"
            % Versione interattiva: elenca le specie e chiede quali plottare.
            if ~isempty(varargin)
                warning(['plotTofBySpecies(mode=""interactive""): ' ...
                         'argomenti name-value extra ignorati.']);
            end

            FitResults = plotTofHistogramBySpeciesInteractive(T, nbins);

        otherwise
            error('plotTofBySpecies: mode "%s" non riconosciuto.', mode);
    end
end
