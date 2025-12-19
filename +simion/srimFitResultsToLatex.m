function texStr = srimFitResultsToLatex(FitResults, outFile)
% SRIMFITRESULTSTOLATEX  Esporta i fit SRIM in una tabella LaTeX compatta.
%
%   srimFitResultsToLatex(FitResults)
%   srimFitResultsToLatex(FitResults, 'srim_fits.tex')
%
%   texStr = srimFitResultsToLatex(FitResults, ...) restituisce anche
%   la stringa LaTeX in uscita.
%
% Formato tabella:
%   Specie & E_nom [keV] & Quantità & mu & FWHM & unità
%
% FitResults può essere:
%   - array di struct
%   - table (in tal caso viene convertita in struct array)
%
% Richiede nel preambolo LaTeX:
%   \usepackage{multirow}

    if nargin < 2 || isempty(outFile)
        outFile = 'srim_fits.tex';
    end

    % Accetto sia table che struct array
    if istable(FitResults)
        FRs = table2struct(FitResults);
    else
        FRs = FitResults;
    end

    fid = fopen(outFile, 'w');
    if fid < 0
        error('Impossibile aprire il file di output "%s".', outFile);
    end

    % --- Header LaTeX ----------------------------------------------------
    fprintf(fid, '%% Tabella generata da srimFitResultsToLatex\n');
    fprintf(fid, '\\begin{table}[htbp]\n');
    fprintf(fid, '\\centering\n');
    fprintf(fid, '\\small\n');
    fprintf(fid, '\\begin{tabular}{l c l r r l}\n');
    fprintf(fid, '\\hline\n');
    fprintf(fid, 'Specie & $E_{\\mathrm{nom}}$ [keV] & Quantit\\`a & $\\mu$ & FWHM & unit\\`a\\\\\n');
    fprintf(fid, '\\hline\n');

    % --- Loop su tutti i fit --------------------------------------------
    for k = 1:numel(FRs)
        fr = FRs(k);

        % 1) SPECIE
        if isfield(fr, 'species')
            specie = string(fr.species);
        elseif isfield(fr, 'Species')
            specie = string(fr.Species);
        else
            specie = "???";
        end

        % 2) ENERGIA NOMINALE [keV]
        Enom = getEnergyNominal(fr);

        % 3) COSTRUZIONE METRICHE DALLE COPPIE *_mu_* / *_FWHM_*
        metrics = buildMetricsStructFromMuFwhm(fr);

        if isempty(metrics)
            % Nessuna coppia trovata -> salto questo fit
            continue;
        end

        nRows = numel(metrics);

        % 4) Scrittura righe con multirow (serve \usepackage{multirow})
        for r = 1:nRows
            m = metrics(r);

            if r == 1
                % Prima riga: specie ed energia come multirow
                fprintf(fid, '\\multirow{%d}{*}{%s} & ', nRows, latexEscape(specie));
                if ~isnan(Enom)
                    fprintf(fid, '\\multirow{%d}{*}{%.3g} & ', nRows, Enom);
                else
                    fprintf(fid, '\\multirow{%d}{*}{--} & ', nRows);
                end
            else
                % Righe successive: celle vuote nelle prime due colonne
                fprintf(fid, ' &  & ');
            end

            fprintf(fid, '%s & %.3g & %.3g & %s\\\\\n', ...
                m.label, m.mu, m.fwhm, m.unit);
        end

        fprintf(fid, '\\hline\n');
    end

    % --- Footer LaTeX ----------------------------------------------------
    fprintf(fid, '\\end{tabular}\n');
    fprintf(fid, '\\caption{Fit delle distribuzioni SRIM per energia, angoli e posizione in uscita.}\n');
    fprintf(fid, '\\label{tab:srim_transmit_fits}\n');
    fprintf(fid, '\\end{table}\n');

    fclose(fid);

    if nargout > 0
        fid = fopen(outFile, 'r');
        texStr = fread(fid, '*char')';
        fclose(fid);
    end

    fprintf('Tabella LaTeX salvata in %s\n', outFile);
end

% =====================================================================
function Enom = getEnergyNominal(fr)
% Prova diversi possibili nomi per l'energia nominale [keV]

    candidates = {'E_nom', 'E_nom_keV', 'energy_nominal_keV', 'E0_keV'};
    Enom = NaN;

    for i = 1:numel(candidates)
        f = candidates{i};
        if isfield(fr, f)
            Enom = fr.(f);
            return;
        end
    end
end

% =====================================================================
function metrics = buildMetricsStructFromMuFwhm(fr)
% Costruisce un array di struct con:
%   label, mu, fwhm, unit
% a partire da tutte le coppie *_mu_* / *_FWHM_* trovate.

    metrics = struct('label', {}, 'mu', {}, 'fwhm', {}, 'unit', {});

    fn = fieldnames(fr);
    % tutti i campi che contengono '_mu'
    muMask = contains(fn, '_mu');
    muFields = fn(muMask);

    for i = 1:numel(muFields)
        muField = muFields{i};

        % Trova il FWHM corrispondente sostituendo '_mu' con '_FWHM'
        fwhmField = strrep(muField, '_mu', '_FWHM');

        if ~isfield(fr, fwhmField)
            % nessun FWHM corrispondente -> salto
            continue;
        end

        muVal   = fr.(muField);
        fwhmVal = fr.(fwhmField);

        % Esempio: energy_mu_eV -> base='energy', unit='eV'
        [baseName, unit] = splitBaseAndUnit(muField);

        label = makeNiceLabel(baseName);
        unit  = refineUnit(baseName, unit);

        metrics(end+1) = struct( ...
            'label', label, ...
            'mu',    muVal, ...
            'fwhm',  fwhmVal, ...
            'unit',  unit);
    end
end

% =====================================================================
function [baseName, unit] = splitBaseAndUnit(muField)
% Da un nome tipo 'energy_mu_eV' ricava:
%   baseName = 'energy'
%   unit     = 'eV'   (ultimo pezzo dopo '_')
%
% Funziona anche con cose tipo 'x_mu_A', 'phi_mu_deg', ecc.

    parts = split(string(muField), '_');

    % Trova l'indice di 'mu'
    muIdx = find(parts == "mu", 1, 'first');
    if isempty(muIdx)
        % fallback: base = tutto prima dell'ultimo pezzo, unit = ultimo pezzo
        if numel(parts) >= 2
            baseName = strjoin(parts(1:end-1), '_');
            unit     = parts(end);
        else
            baseName = parts(1);
            unit     = "-";
        end
        return;
    end

    % base: tutto prima di 'mu'
    if muIdx > 1
        baseName = strjoin(parts(1:muIdx-1), '_');
    else
        baseName = "param";
    end

    % unità: ultimo pezzo, se c'è
    if numel(parts) > muIdx
        unit = parts(end);
    else
        unit = "-";
    end
end

% =====================================================================
function label = makeNiceLabel(baseName)
% Trasforma il "baseName" in descrizione leggibile

    s = lower(string(baseName));

    if s == "energy" || contains(s,"ener")
        label = 'Energia';
    elseif s == "phi" || contains(s,"az")
        label = 'azimut';
    elseif s == "elev" || contains(s,"theta") || contains(s,"ang")
        label = 'elevazione';
    elseif s == "x"
        label = 'X spot';
    elseif s == "y"
        label = 'Y spot';
    elseif s == "z"
        label = 'Z spot';
    else
        % fallback: lo scrivo così com'è
        label = baseName;
    end
end

% =====================================================================
function unitOut = refineUnit(baseName, unitIn)
% Prova a rendere l'unità più leggibile, se possibile.

    sUnit = lower(string(unitIn));
    sBase = lower(string(baseName));

    if sUnit == "ev"
        unitOut = 'eV';
    elseif sUnit == "deg"
        unitOut = 'deg';
    elseif sUnit == "a"
        % probabilmente Angstrom
        unitOut = '\si{\angstrom}';
    elseif contains(sBase,"x") || contains(sBase,"y") || contains(sBase,"z")
        % coordinate spaziali: se non chiaro, ipotizziamo mm
        if sUnit == "-" || sUnit == ""
            unitOut = 'mm';
        else
            unitOut = unitIn;
        end
    else
        unitOut = unitIn;
    end
end

% =====================================================================
function s = latexEscape(str)
% Piccola utility per evitare problemi con underscore ecc.
    s = string(str);
    s = replace(s, "_", "\\_");
end