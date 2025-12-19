function latexStr = tableToLatex(Tw, params, outFile, varargin)
% tableToLatex  -  genera una tabella LaTeX "paper-grade" da FitTable wide
%
% USO:
%   tableToLatex(FitTable, ["mu","sigma","FWHM"], "Fit_TOF.tex");
%   tableToLatex(FitTable, "all", "allparams.tex");
%
% INPUT:
%   Tw      - table wide con colonne: species, mu_8, mu_14, ...
%   params  - string/char oppure string array, es. ["mu","sigma"] o "all"
%   outFile - nome file output .tex (opzionale: [] o "" per non salvare)
%
% OPZIONI (name-value):
%   'Caption'  : caption (default "Gaussian fit parameters for each species at different energies.")
%   'Label'    : label   (default "tab:fitparams")
%   'TableEnv' : true/false includi environment table (default true)
%   'Small'    : true/false include \small (default true)

% ---------------- Options ----------------
p = inputParser;
addParameter(p,'Caption',"Gaussian fit parameters for each species at different energies.", @(x)isstring(x)||ischar(x));
addParameter(p,'Label',"tab:fitparams", @(x)isstring(x)||ischar(x));
addParameter(p,'TableEnv',true,@islogical);
addParameter(p,'Small',true,@islogical);
parse(p,varargin{:});
opt = p.Results;

% ---------------- Checks ----------------
if ~istable(Tw)
    error("Tw deve essere una table MATLAB.");
end

varsAll = string(Tw.Properties.VariableNames);
if ~any(varsAll=="species")
    error("La table deve contenere la colonna 'species'.");
end

numVars = varsAll(varsAll ~= "species");

% ---------------- Available params / energies ----------------
baseParams = extractBefore(numVars, "_");
available  = unique(baseParams);

suffix = extractAfter(numVars, "_");
validSuffix = suffix(~ismissing(suffix) & suffix ~= "");
energiesNum = sort(unique(str2double(validSuffix)));
energiesNum = energiesNum(~isnan(energiesNum));
energiesStr = string(energiesNum);

% gestisci "all"
params = string(params);
if numel(params)==1 && lower(params)=="all"
    params = available;
end

% controlla parametri esistano
missing = setdiff(params, available);
if ~isempty(missing)
    error("Parametri non presenti: " + strjoin(missing, ", "));
end

% ---------------- Select columns & energies per param ----------------
keep = "species";
presentEByParam = cell(numel(params),1);

for ip = 1:numel(params)
    pp = params(ip);
    presentE = strings(0,1);

    for ee = energiesStr(:).'
        vname = pp + "_" + ee;
        if any(numVars == vname)
            keep(end+1) = vname; %#ok<AGROW>
            presentE(end+1) = ee; %#ok<AGROW>
        end
    end

    presentEByParam{ip} = presentE;
end

Tsel = Tw(:, keep);

% ---------------- Column spec (SCALAR string) ----------------
nNumCols = width(Tsel)-1;
numSpecParts = repmat("S[table-format=3.2]", 1, nNumCols);
colSpec = strjoin(["l", numSpecParts], " ");

% ---------------- Build headers (GIÀ corretti in math mode) ----------------
row1 = "\textbf{Species}";
row2 = "";
cmidrules = strings(0,1);

colStart = 2; % dopo species

for ip = 1:numel(params)
    pp = params(ip);
    presentE = presentEByParam{ip};
    nE = numel(presentE);

    % ---- nome parametro in latex per header riga 1
    if pp == "mu"
        ppLatex = "\mu";
    elseif pp == "sigma"
        ppLatex = "\sigma";
    else
        ppLatex = pp; % es. FWHM o altro
    end

    % ---- riga 1 con gruppi
    if pp == "FWHM"
        row1 = row1 + " & \multicolumn{" + nE + "}{c}{\textbf{FWHM}}";
    else
        row1 = row1 + " & \multicolumn{" + nE + "}{c}{$\boldsymbol{" + ppLatex + "}$}";
    end

    % ---- cmidrule per il gruppo
    colEnd = colStart + nE - 1;
    cmidrules(end+1) = "\cmidrule(lr){" + colStart + "-" + colEnd + "}"; %#ok<AGROW>
    colStart = colEnd + 1;

    % ---- riga 2: indici corretti in math mode
    for e = presentE(:).'
        if pp == "mu"
            row2 = row2 + " & {$\mu_{" + e + "}$}";
        elseif pp == "sigma"
            row2 = row2 + " & {$\sigma_{" + e + "}$}";
        elseif pp == "FWHM"
            row2 = row2 + " & {FWHM$_{" + e + "}$}";
        else
            row2 = row2 + " & {$" + ppLatex + "_{" + e + "}$}";
        end
    end
end

row1 = row1 + " \\";
row2 = " " + row2 + " \\";

% ---------------- Data rows (2 decimali, species in math) ----------------
rows = strings(height(Tsel),1);

for i = 1:height(Tsel)
    r = strings(1, width(Tsel));

    % species in math mode, preserva eventuali ^{+} ecc
    r(1) = "$\mathrm{" + string(Tsel.species(i)) + "}$";

    for j = 2:width(Tsel)
        v = Tsel{i,j};
        if isnumeric(v)
            if isnan(v)
                r(j) = "--";
            else
                r(j) = sprintf("%.2f", v);
            end
        else
            r(j) = string(v);
        end
    end

    rows(i) = strjoin(r, " & ") + " \\";
end

% ---------------- Assemble tabular safely ----------------
lines = strings(0,1);
lines(end+1) = "\begin{tabular}{" + colSpec + "}";
lines(end+1) = "\toprule";
lines(end+1) = row1;

for k = 1:numel(cmidrules)
    lines(end+1) = cmidrules(k);
end

lines(end+1) = row2;
lines(end+1) = "\midrule";

for k = 1:numel(rows)
    lines(end+1) = rows(k);
end

lines(end+1) = "\bottomrule";
lines(end+1) = "\end{tabular}";

tabularStr = strjoin(lines, newline);

% ---------------- Wrap in table env ----------------
if opt.TableEnv
    outer = strings(0,1);
    outer(end+1) = "\begin{table}[h]";
    outer(end+1) = "\centering";
    if opt.Small
        outer(end+1) = "\small";
    end
    outer(end+1) = "\setlength{\tabcolsep}{6pt}";
    outer(end+1) = "\renewcommand{\arraystretch}{1.15}";
    outer(end+1) = tabularStr;
    outer(end+1) = "\caption{" + string(opt.Caption) + "}";
    outer(end+1) = "\label{" + string(opt.Label) + "}";
    outer(end+1) = "\end{table}";

    latexStr = strjoin(outer, newline);
else
    latexStr = tabularStr;
end

% ---------------- Save ----------------
if nargin >= 3 && ~isempty(outFile) && string(outFile) ~= ""
    fid = fopen(outFile,'w');
    if fid < 0
        error("Impossibile aprire il file di output: " + string(outFile));
    end
    fprintf(fid,"%s",latexStr);
    fclose(fid);
end

end
