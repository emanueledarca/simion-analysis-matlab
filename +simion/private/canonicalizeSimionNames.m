function T = canonicalizeSimionNames(T)
% CANONICALIZESIMIONNAMES
%   Porta gli header della table SIMION a una forma standard.
%
%   Nomi "canonici" che proviamo ad avere:
%   IonN, Events, TOF, Time, Mass, Charge, ...
%   X, Y, Z, Vx, Vy, Vz, KE, KEError
%
%   Usa varie possibili varianti come alias (Ion_N, Ion Number, ecc).

vn = T.Properties.VariableNames;

% --- mappa alias -> nome canonico ---
aliases = struct();

aliases.IonN    = {'IonN','Ion_N','IonNumber','Ion_Number','Ion_N_'};
aliases.Events  = {'Events','EventCount','NumEvents'};
aliases.TOF     = {'TOF','Tof','tof'};
aliases.Time    = {'Time','t','T','time'};

aliases.Mass    = {'Mass','mass','M'};
aliases.Charge  = {'Charge','charge','Q','q'};

aliases.X       = {'X','x','PosX','PositionX'};
aliases.Y       = {'Y','y','PosY','PositionY'};
aliases.Z       = {'Z','z','PosZ','PositionZ'};

aliases.Vx      = {'Vx','vx','VelX','VelocityX'};
aliases.Vy      = {'Vy','vy','VelY','VelocityY'};
aliases.Vz      = {'Vz','vz','VelZ','VelocityZ'};

aliases.KE      = {'KE','Ekin','KineticEnergy'};
aliases.KEError = {'KE_Error','KEError','Ekin_Error','KineticEnergyError'};

canonical = fieldnames(aliases);

for k = 1:numel(canonical)
    canonName   = canonical{k};
    aliasList   = aliases.(canonName);

    % se il nome canonico esiste già, non fare nulla
    vn = T.Properties.VariableNames;
    if any(strcmp(vn, canonName))
        continue;
    end

    % cerca un alias presente
    for j = 1:numel(aliasList)
        alias = aliasList{j};
        if any(strcmp(vn, alias))
            % rinomina in canonico
            T = renamevars(T, alias, canonName);
            break;
        end
    end
end

end