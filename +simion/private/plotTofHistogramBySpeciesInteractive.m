function FitResults = plotTofHistogramBySpeciesInteractive(T, nbins)
% plotTofHistogramBySpeciesInteractive
%   Let the user choose which species to plot, by index.
%   The function:
%     - lists all (Mass, Charge) species in T with an index;
%     - asks how many species to plot;
%     - asks for the indices of those species;
%     - filters T accordingly;
%     - calls plotTofHistogramBySpeciesLocalBins on the subset.
%
%   FitResults = plotTofHistogramBySpeciesInteractive(T, nbins)
%
% INPUT:
%   T      - table with at least: TOF, Mass, Charge (+ optional Events, X)
%   nbins  - number of bins per species (passed to the plotting function)
%
% OUTPUT:
%   FitResults - struct array returned by plotTofHistogramBySpeciesLocalBins

    if nargin < 2 || isempty(nbins)
        nbins = 50;
    end

    % Basic checks
    varsNeeded = {'TOF','Mass','Charge'};
    for v = 1:numel(varsNeeded)
        if ~ismember(varsNeeded{v}, T.Properties.VariableNames)
            error('Table T must contain column "%s".', varsNeeded{v});
        end
    end

    % Compute the available species (Mass, Charge)
    MC = T{:, {'Mass','Charge'}};
    [speciesMC, ~] = unique(MC, 'rows');
    nspecies = size(speciesMC, 1);

    epsMass   = 1e-3;
    epsCharge = 0.5;

    fprintf('\nAvailable species in the dataset (you will select them by INDEX):\n');
    for k = 1:nspecies
        mk = speciesMC(k,1);
        qk = speciesMC(k,2);

        % Usa il classificatore globale
        spcat  = classifySpecies(mk, qk);    % categorical, tipo "O6+"
        namek  = char(spcat);                % converti in char/string per fprintf

        fprintf('  %2d) Mass = %.5g   Charge = %.3g   ->   %s\n', ...
            k, mk, qk, namek);
    end
    fprintf('\n');
    % Ask how many species to plot
    nsel = input('How many species do you want to plot? ');
    if isempty(nsel) || ~isscalar(nsel) || nsel < 1
        warning('No valid number of species provided. Aborting.');
        FitResults = struct([]);
        return;
    end

    % Ask for indices of each species
    selIdx = zeros(nsel,1);
    for i = 1:nsel
        while true
            prompt = sprintf('  Index of species #%d (1..%d): ', i, nspecies);
            idx_i  = input(prompt);

            if isempty(idx_i) || ~isscalar(idx_i) || ~isnumeric(idx_i)
                fprintf('    Invalid input. Please enter a single integer.\n');
                continue;
            end

            idx_i = round(idx_i);
            if idx_i < 1 || idx_i > nspecies
                fprintf('    Invalid index. Please choose an integer between 1 and %d.\n', nspecies);
                continue;
            end

            selIdx(i) = idx_i;
            break;
        end
    end

    
    % Remove duplicates (if any)
    selIdx = unique(selIdx);

    % Build selection mask
    mask = false(height(T), 1);
    for i = 1:numel(selIdx)
        k  = selIdx(i);
        mk = speciesMC(k,1);
        qk = speciesMC(k,2);

        mask_i = abs(T.Mass - mk) < epsMass & ...
                 abs(T.Charge - qk) < epsCharge;

        mask = mask | mask_i;
    end

    Tsel = T(mask, :);

    if isempty(Tsel)
        warning('No events match the selected species. Nothing to plot.');
        FitResults = struct([]);
        return;
    end

    fprintf('\nSelected events: %d out of %d total.\n', height(Tsel), height(T));

    % Call your main plotting function
    FitResults = plotTofHistogramBySpeciesLocalBins(Tsel, nbins);
end

% -------------------------------------------------------------------------
