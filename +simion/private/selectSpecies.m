function [Tout, speciesUsed] = selectSpecies(T, speciesOpt)
% SELECTSPECIES  Filtra la table in base alle specie richieste.
%
%   [Tout, speciesUsed] = selectSpecies(T, speciesOpt)
%
%   T deve avere una colonna 'Species'.
%
%   speciesOpt può essere:
%     - [] oppure "all" / 'all'  -> nessun filtro (tutte le specie)
%     - string       es: "H+"
%     - char         es: 'H+'
%     - string array es: ["H+","He2+"]
%     - cellstr      es: {'H+','He2+'}
%     - categorical  (categorie da selezionare)
%
%   Output:
%     Tout        : sotto-table con solo le specie richieste
%     speciesUsed : nomi delle specie effettivamente presenti in Tout
%
%   Se le specie richieste non esistono nella table:
%     - Tout è vuota
%     - speciesUsed è string array vuoto
%     - viene emesso un warning.

if ~ismember('Species', T.Properties.VariableNames)
    error('selectSpecies:NoSpeciesColumn', ...
        'La table non contiene la colonna "Species".');
end

% Se non c'è nessuna richiesta specifica -> tutte le specie
if nargin < 2 || isempty(speciesOpt) ...
        || (ischar(speciesOpt)   && strcmpi(speciesOpt,'all')) ...
        || (isstring(speciesOpt) && any(strcmpi(speciesOpt,"all")))
    % Mi assicuro solo che Species sia categorical
    if ~iscategorical(T.Species)
        T.Species = categorical(T.Species);
    end
    Tout        = T;
    speciesUsed = categories(T.Species);
    return;
end

% Porto speciesOpt a string array "pulito"
if ischar(speciesOpt)
    speciesNames = string({speciesOpt});
elseif isstring(speciesOpt)
    speciesNames = speciesOpt;
elseif iscellstr(speciesOpt)
    speciesNames = string(speciesOpt);
elseif iscategorical(speciesOpt)
    speciesNames = string(categories(speciesOpt));
else
    error('selectSpecies:BadType', ...
        'Tipo non valido per speciesOpt.');
end

% Mi assicuro che la colonna Species sia categorical
if ~iscategorical(T.Species)
    T.Species = categorical(T.Species);
end

spCat      = T.Species;
allCatsStr = string(categories(spCat));

% Intersezione fra richieste e specie esistenti
wanted = intersect(allCatsStr, speciesNames, 'stable');

if isempty(wanted)
    warning('selectSpecies:NoMatch', ...
        'Nessuna delle specie richieste è presente nella table.');
    Tout        = T([],:);   % table vuota con stesse colonne
    speciesUsed = string([]);
    return;
end

mask = ismember(string(spCat), wanted);
Tout = T(mask, :);

% Specie effettivamente presenti dopo il filtro
spSub       = removecats(spCat(mask));
speciesUsed = categories(spSub);
end