function T = importSimionTofTable(filename)
% IMPORTSIMIONTOFTABLE  Import "specializzato" per l'analisi TOF da SIMION.
%
%   T = importSimionTofTable(filename)
%
% Wrapper di alto livello:
%   - usa simion.importSimionRecordTable per leggere QUALSIASI output SIMION
%     (già con nomi canonici e colonna Species se possibile)
%   - controlla che almeno TOF, Mass, Charge siano presenti
%   - riordina le colonne mettendo per prime quelle "canoniche"
%
% Se le colonne necessarie per il TOF mancano -> errore esplicito.

%--------------------------------------------------------------
% 1) Import generico (già normalizzato)
%--------------------------------------------------------------
% NOTA: deve essere il nome completo del package
T = simion.importSimionRecordTable(filename);

%--------------------------------------------------------------
% 2) Controllo colonne minime per analisi TOF
%--------------------------------------------------------------
required = {'TOF','Mass','Charge'};
missing  = setdiff(required, T.Properties.VariableNames);

if ~isempty(missing)
    error('importSimionTofTable:MissingColumns', ...
        'Il file "%s" non contiene le colonne richieste per il TOF: %s', ...
        filename, strjoin(missing, ', '));
end

%--------------------------------------------------------------
% 3) (opzionale) riordino le colonne mettendo prima quelle standard
%--------------------------------------------------------------
canonicalOrder = {'IonN','Events','TOF','Mass','Charge', ...
    'X','Y','Z','Vx','Vy','Vz', ...
    'KE','KEError','KE_err', ...   % uno dei tre, a seconda del file
    'Species'};

vn    = T.Properties.VariableNames;
first = intersect(canonicalOrder, vn, 'stable');
other = setdiff(vn, first, 'stable');
T     = T(:, [first, other]);
end