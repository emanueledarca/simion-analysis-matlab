function T = importSimionRecordTable(filename)
% IMPORTSIMIONRECORDTABLE  Import generico di un file di output SIMION in una table.
%
%   T = importSimionRecordTable(filename)
%
% Formato atteso (classico output SIMION):
%   (varie righe di header)
%   "Nome col 1","Nome col 2",...,"Nome col N"
%   v11, v12, ..., v1N
%   v21, v22, ..., v2N
%   ...
%
% I nomi originali delle colonne vengono salvati in
%   T.Properties.VariableDescriptions
%
% NOTE:
%   - Riconosce come header SOLO una riga che:
%       * inizia con doppi apici "
%       * contiene almeno una sequenza "," fra i nomi
%     (quindi NON prende "Ions Flown Separately, Comp Quality(3)")
%   - Dopo l'import:
%       * normalizza i nomi (canonicalizeSimionNames)
%       * se ci sono Mass e Charge, aggiunge Species (classifySpecies)

    %--------------------------------------------------------------
    % Apertura file
    %--------------------------------------------------------------
    fid = fopen(filename,'r');
    if fid < 0
        error('Impossibile aprire il file "%s".', filename);
    end

    headerNames = {};
    numCols     = [];
    data        = [];

    %--------------------------------------------------------------
    % 1) Trovo la riga di header con i nomi delle colonne
    %--------------------------------------------------------------
    fseek(fid, 0, 'bof');

    while true
        tline = fgetl(fid);
        if ~ischar(tline)
            break;  % fine file, header non trovato
        end

        tline = strtrim(tline);
        if isempty(tline)
            continue;
        end

        % Cerco una riga tipo: "col1","col2",...,"colN"
        % Deve avere almeno un pattern '","' tra i nomi,
        % così NON scambiamo per header righe tipo
        % "Ions Flown Separately, Comp Quality(3)"
        if startsWith(tline, '"') && contains(tline, '","')
            tokens = regexp(tline, '"([^"]*)"', 'tokens');
            tokens = [tokens{:}];  % flatten cell-of-cell

            headerNames = tokens;
            numCols     = numel(headerNames);
            break;
        end
    end

    if isempty(headerNames)
        fclose(fid);
        error('Non è stato trovato nessun header di colonne nel file "%s".', filename);
    end

    %--------------------------------------------------------------
    % 2) Leggo i dati numerici riga per riga
    %--------------------------------------------------------------
    while true
        tline = fgetl(fid);
        if ~ischar(tline)
            break;  % fine file
        end

        tline = strtrim(tline);
        if isempty(tline)
            continue;
        end

        % Salta righe non numeriche (altri header, "Begin Fly'm", ecc.)
        if startsWith(tline, '"') || startsWith(tline, '-')
            continue;
        end

        % Split per virgole
        parts = strsplit(tline, ',');

        % Deve avere esattamente lo stesso numero di colonne dell'header
        if numel(parts) ~= numCols
            continue;
        end

        % Converto in numeri
        nums = str2double(parts);

        % Se sono TUTTI NaN, chiaramente non è una riga dati → skip
        if all(isnan(nums))
            continue;
        end

        % Riga valida: la aggiungo
        data(end+1,1:numCols) = nums(:).'; %#ok<AGROW>
    end

    fclose(fid);

    if isempty(data)
        error('Nessuna riga dati valida trovata nel file "%s".', filename);
    end

    %--------------------------------------------------------------
    % 3) Costruisco i nomi di variabile MATLAB-safe
    %--------------------------------------------------------------
    varNames = matlab.lang.makeValidName(headerNames, ...
        'ReplacementStyle','delete');

    %--------------------------------------------------------------
    % 4) Creo la table e salvo i nomi originali come descrizioni
    %--------------------------------------------------------------
    T = array2table(data, 'VariableNames', varNames);
    T.Properties.VariableDescriptions = headerNames;

    %--------------------------------------------------------------
    % 5) Normalizzo i nomi SIMION e aggiungo Species (se possibile)
    %--------------------------------------------------------------
    T = canonicalizeSimionNames(T);

    vn = T.Properties.VariableNames;
    if all(ismember({'Mass','Charge'}, vn))
        T.Species = classifySpecies(T.Mass, T.Charge);
    end
end