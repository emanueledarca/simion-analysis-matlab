function FitO6 = analyzeTof_O6plus(fname, nbins, xlimUser)
% analyzeTof_O6plus  Importa un file SIMION e fa il plot della TOF per O6+.
%
%   FitO6 = analyzeTof_O6plus("run_8keV.txt");
%
% INPUT:
%   fname    : nome del file SIMION (es. "run_8keV.txt" o ".rec")
%   nbins    : numero di bin per l'istogramma (default 60)
%   xlimUser : [tmin tmax] opzionale per il range TOF (stessi units del file)
%
% OUTPUT:
%   FitO6 : struct con i parametri di fit per O6+ (mu, sigma, FWHM, ...)

if nargin < 2 || isempty(nbins)
    nbins = 60;
end

% 1) Import TOF table
T = simion.importSimionTofTable(fname);

% 2) Filtro la specie: ossigeno (M~16) e carica +6
isO6 = abs(T.Mass - 16) < 0.5 & T.Charge == 6;

T_O6 = T(isO6, :);

if isempty(T_O6)
    warning('Nessun evento trovato per O6+ in "%s".', fname);
    FitO6 = struct([]);
    return;
end

% 3) Se non passi XLim, lo deduco dai dati
if nargin < 3 || isempty(xlimUser)
    tmin = min(T_O6.TOF);
    tmax = max(T_O6.TOF);
    margin = 0.05 * (tmax - tmin);
    xlimUser = [tmin - margin, tmax + margin];
end

% 4) Plot TOF per O6+ con bin locali e fit gaussiano
figure;
FitO6 = simion.plotTFiofBySpecies(T_O6, "hist-local", nbins, ...
    'XLim', xlimUser);

title(sprintf('TOF distribution for O^{6+} (%s)', fname), ...
    'Interpreter', 'tex');
end