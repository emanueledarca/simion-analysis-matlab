function sp = classifySpecies(mass, charge)
% CLASSIFYSPECIES  Assegna un nome "umano" alle specie SIMION
% in base a massa (amu) e carica.
%
%   sp = classifySpecies(Mass, Charge)
%
% Output:
%   sp : categorical con etichette tipo "e-", "H+", "He2+", "O6+", ...
%
% Nota:
% - se una coppia (mass,charge) non corrisponde a nessuna specie nota,
%   viene usata l'etichetta di fallback "m<M>_q<Q>".

mass   = double(mass);
charge = double(charge);

% -------------------------
% Fallback di default
% -------------------------
sp = strings(size(mass));
sp(:) = "m" + string(round(mass)) + "_q" + string(charge);

% Tolleranze sulle masse (in amu)
tol_e = 1e-4;   % per l'elettrone (massa molto piccola)
tol_1 = 0.2;    % per 1, 4, 16 amu

% -------------------------
% Elettrone
% -------------------------
is_e = (abs(mass - 0.00054858) < tol_e) & (charge == -1);
sp(is_e) = "e-";

% -------------------------
% Idrogeno
% -------------------------
is_Hp = (abs(mass - 1.0) < tol_1) & (charge == +1);
sp(is_Hp) = "H+";

% -------------------------
% Elio
% -------------------------
is_He_p = (abs(mass - 4.0) < tol_1) & (charge == +1);
sp(is_He_p) = "He+";

is_He_2p = (abs(mass - 4.0) < tol_1) & (charge == +2);
sp(is_He_2p) = "He2+";

% -------------------------
% Ossigeno
% -------------------------
% O+
is_O_p = (abs(mass - 16.0) < tol_1) & (charge == +1);
sp(is_O_p) = "O+";

% O-
is_O_m = (abs(mass - 16.0) < tol_1) & (charge == -1);
sp(is_O_m) = "O-";

% O6+
is_O_6p = (abs(mass - 16.0) < tol_1) & (charge == +6);
sp(is_O_6p) = "O6+";

% Puoi aggiungere qui eventuali altre specie in futuro...

% Ritorna categorical
sp = categorical(sp);
end