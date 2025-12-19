function Tfinal = getFinalHitsByIon(T)
% GETFINALHITSBYION  Estrae un solo record per ogni ion (l'ultimo nel file).
%
%   Tfinal = getFinalHitsByIon(T)
%
%   T deve avere la colonna 'IonN'.
%   Se nel file ci sono più righe per lo stesso IonN (traiettoria),
%   questa funzione tiene SOLO l'ultima riga per ciascun IonN,
%   interpretata come "punto finale" della particella.

if ~ismember('IonN', T.Properties.VariableNames)
    error('getFinalHitsByIon:NoIonN', ...
        'La table non contiene la colonna "IonN".');
end

ion = T.IonN;

% indice dell'ULTIMA occorrenza per ciascun IonN
[~, idxLast] = unique(ion, 'last');

% ordino gli indici per avere un ordine crescente "pulito"
idxLast = sort(idxLast);

Tfinal = T(idxLast, :);
end