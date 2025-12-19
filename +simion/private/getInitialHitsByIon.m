function Tin = getInitialHitsByIon(T)
% GETINITIALHITSBYION  Restituisce il record iniziale per ogni IonN.
%
% Assunzione: le righe per ogni IonN sono in ordine temporale (o di
% sezione) e la *prima* occorrenza di ciascun IonN corrisponde allo
% stato "di ingresso" (sorgente).

if ~ismember('IonN', T.Properties.VariableNames)
    error('getInitialHitsByIon:MissingIonN', ...
        'La table deve contenere la colonna IonN.');
end

ion = T.IonN;
[~, idxFirst] = unique(ion, 'first');
idxFirst = sort(idxFirst);  % per mantenere un ordine "sensato"
Tin = T(idxFirst, :);
end