function [S, speciesNames] = splitBySpecies(T)
% SPLITBYSPECIES  Divide la table in sottotable per specie.
%
%   [S, speciesNames] = splitBySpecies(T)
%
%   T deve avere una colonna 'Species' (categorical o string/char).
%
%   Output:
%     S            struct con un campo per specie (nomi validi MATLAB)
%     speciesNames categorical/string con i nomi originali delle specie

if ~ismember('Species', T.Properties.VariableNames)
    error('splitBySpecies:NoSpeciesColumn', ...
        'La table non contiene la colonna "Species".');
end

% Mi assicuro che sia categorical
if ~iscategorical(T.Species)
    T.Species = categorical(T.Species);
end

speciesNames = categories(T.Species);
S            = struct();

for i = 1:numel(speciesNames)
    spName = speciesNames{i};
    mask   = (T.Species == spName);

    % Campo struct con nome MATLAB-safe
    fn = matlab.lang.makeValidName(char(spName));
    S.(fn) = T(mask, :);
end
end