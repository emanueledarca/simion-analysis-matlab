function Tw = combineFitStructs(fitStructs, labels)
% combineFitStructs - Unisce N struct Fit in tabella wide, ordinata e stabile.
% -------------------------------------------------------------------------
% ESEMPI D'USO (memo rapido)
%
%   % Ho tre risultati di fit (Fit8, Fit14, Fit20), ciascuno è un array di
%   % struct con almeno il campo 'species' e parametri numerici (mu, sigma,
%   % FWHM, ...). Voglio una tabella "wide" con i suffissi di energia.
%   %
%   fitCell = {Fit8, Fit14, Fit20};
%   labels  = ["8","14","20"];          % questi finiscono come _8,_14,_20
%   Tw = combineFitStructs(fitCell, labels);
%
%   % Risultato: Tw contiene colonne tipo:
%   %   species, mu_8, mu_14, mu_20, sigma_8, sigma_14, ..., FWHM_20, ...
%
%   % NOTA: se uno dei Fit* è vuoto, viene ignorato. Tutti i struct devono
%   % avere il campo 'species' e gli stessi nomi di parametri numerici.
% -------------------------------------------------------------------------
    %----------------------------------------------------------------------
    % 1) Controlli input
    %----------------------------------------------------------------------
    if ~iscell(fitStructs)
        error('fitStructs deve essere una cell array.');
    end

    Nfits = numel(fitStructs);

    if nargin < 2 || isempty(labels)
        labels = string(1:Nfits);
    else
        labels = string(labels);
    end

    if numel(labels) ~= Nfits
        error('labels deve avere lo stesso numero di elementi di fitStructs.');
    end

    %----------------------------------------------------------------------
    % 2) Costruzione tabella LONG
    %----------------------------------------------------------------------
    Tall = table();

    for i = 1:Nfits
        F = fitStructs{i};
        if isempty(F), continue; end

        T = struct2table(F);

        if ~ismember('species', T.Properties.VariableNames)
            error('Ogni struct deve avere una colonna species.');
        end

        T.species = string(T.species);
        T.energy  = repmat(labels(i), height(T), 1);

        Tall = [Tall; T]; %#ok<AGROW>
    end

    if isempty(Tall)
        Tw = table();
        return;
    end

    %----------------------------------------------------------------------
    % 3) Trovo le variabili numeriche da wide-izzare
    %----------------------------------------------------------------------
    allVars = Tall.Properties.VariableNames;
    isNum   = varfun(@isnumeric, Tall, 'OutputFormat','uniform');
    numVars = allVars(isNum);

    % Rimuovo energy, mass, charge
    numVars(strcmp(numVars,'energy')) = [];
    numVars(strcmp(numVars,'mass'  )) = [];
    numVars(strcmp(numVars,'charge')) = [];

    %----------------------------------------------------------------------
    % 4) UNSTACK WIDE – la parte critica
    %----------------------------------------------------------------------
    W = Tall(:, [{'species','energy'}, numVars]);

    % energia come categorical con livelli ordinati
    labStr = string(labels);
    W.energy = categorical(string(W.energy), labStr, 'Ordinal', true);

    Tw = unstack(W, numVars, 'energy', ...
        'VariableNamingRule','preserve');

    %----------------------------------------------------------------------
    % 5) Ripulisci nomi colonna
    %----------------------------------------------------------------------
    names = Tw.Properties.VariableNames;
    newNames = strings(size(names));

    for k = 1:numel(names)
        s = names{k};

        s = regexprep(s, '^energy_', '');
        s = regexprep(s, '__', '_');
        s = regexprep(s, '_$', ''); % togli underscore finali

        newNames(k) = string(s);
    end

    Tw.Properties.VariableNames = cellstr(newNames);

    %----------------------------------------------------------------------
    % 6) Identifico in modo SICURISSIMO la colonna species
    %----------------------------------------------------------------------
    names = Tw.Properties.VariableNames;

    % match esatto o quasi
    idx_species = find(strcmpi(names,'species'));

    if isempty(idx_species)
        error('Colonna species NON trovata dopo unstack -> problema nomi.');
    end

    if numel(idx_species) > 1
        error('Rilevate PIÙ colonne species -> nomi sporchi dopo unstack.');
    end

    %----------------------------------------------------------------------
    % 7) Preparo ordinamento colonne wide
    %----------------------------------------------------------------------
    otherIdx   = setdiff(1:width(Tw), idx_species);
    otherNames = names(otherIdx);

    % estrazione parametro_base e energia
    base = strings(numel(otherNames),1);
    ener = strings(numel(otherNames),1);

    for j = 1:numel(otherNames)
        t = regexp(otherNames{j}, '^(.*)_([^_]+)$', 'tokens','once');
        if isempty(t)
            base(j) = otherNames{j};
            ener(j) = "";
        else
            base(j) = string(t{1});
            ener(j) = string(t{2});
        end
    end

    % indici ordinamento
    [~, baseIdx] = ismember(base, unique(base,'stable'));
    [~, enerIdx] = ismember(ener, labStr);

    [~, sortIdx] = sortrows([baseIdx(:), enerIdx(:)]);

    otherIdxSorted = otherIdx(sortIdx(:));

    %----------------------------------------------------------------------
    % 8) ORDINAMENTO FINALE DELLE COLONNE senza concatenazione pericolosa
    %----------------------------------------------------------------------
    finalOrder = [idx_species; otherIdxSorted(:)];

    Tw = Tw(:, finalOrder);

    %----------------------------------------------------------------------
    % 9) Ordino righe per specie
    %----------------------------------------------------------------------
    Tw = sortrows(Tw, 'species');

end
