function Tdet = getDetectorHitsAtXmax(T, varargin)
% GETDETECTORHITSATXMAX  Seleziona le particelle che arrivano al piano a Xmax.
%
%   Tdet = getDetectorHitsAtXmax(T)
%   Tdet = getDetectorHitsAtXmax(T, 'XTolerance', tol)
%
%   Passi logici:
%     1) prende l'ultimo record per ogni IonN (getFinalHitsByIon)
%     2) calcola Xmax globale
%     3) tiene solo le particelle con X >= Xmax - tol
%
%   Opzioni:
%     'XTolerance'  : tolleranza su X rispetto a Xmax (default 1e-3)

p = inputParser;
addParameter(p, 'XTolerance', 1e-3, @(x) isnumeric(x) && isscalar(x) && x>=0);
parse(p, varargin{:});
tolX = p.Results.XTolerance;

% 1) ultimo punto per ogni ion
Tfinal = getFinalHitsByIon(T);

if ~ismember('X', Tfinal.Properties.VariableNames)
    error('getDetectorHitsAtXmax:NoX', ...
        'La table non contiene la colonna "X".');
end

X = Tfinal.X;
Xmax = max(X);

mask = X >= Xmax - tolX;
Tdet = Tfinal(mask, :);
end