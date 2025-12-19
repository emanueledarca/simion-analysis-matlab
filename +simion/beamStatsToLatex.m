function beamStatsToLatex(SpotTable, varargin)
% BEAMSTATSTOLATEX  Esporta le statistiche di fascio in una tabella LaTeX.
%
%   simion.beamStatsToLatex(SpotTable)
%   simion.beamStatsToLatex(SpotTable, 'Filename', 'beam_stats.tex', ...)
%
% Input:
%   SpotTable   table, tipicamente stats.SpotBySpecies restituita da
%               simion.computeBeamStatsInOut.
%
% Name-Value:
%   'Filename'  nome file .tex di output (default: 'beam_stats.tex')
%   'Columns'   nomi delle colonne da includere (cellstr/string array).
%               Default:
%                 {'Species','N0','Ndet','T_eff', ...
%                  'mu_y_in','sigma_y_in', ...
%                  'mu_y_out','sigma_y_out','R_y'}
%   'NumFormat' formato numerico tipo sprintf (default: '%.3g')

    % ---------------------------
    % Parse input
    % ---------------------------
    p = inputParser;
    p.FunctionName = 'beamStatsToLatex';

    addRequired(p,'SpotTable',@(t) istable(t));
    addParameter(p,'Filename','beam_stats.tex', ...
        @(s) ischar(s) || isstring(s));
    addParameter(p,'Columns',[], ...
        @(c) isempty(c) || isstring(c) || iscellstr(c));
    addParameter(p,'NumFormat','%.3g', ...
        @(s) ischar(s) || isstring(s));

    parse(p,SpotTable,varargin{:});

    T = SpotTable;
    filename  = char(p.Results.Filename);
    numFormat = char(p.Results.NumFormat);

    % Colonne di default se non specificate
    if isempty(p.Results.Columns)
        cols = {'Species','N0','Ndet','T_eff', ...
                'mu_y_in','sigma_y_in', ...
                'mu_y_out','sigma_y_out','R_y'};
    else
        cols = cellstr(p.Results.Columns);
    end

    % Controllo colonne
    missing = setdiff(cols, T.Properties.VariableNames);
    if ~isempty(missing)
        error('beamStatsToLatex:MissingColumns', ...
              'Colonne non trovate nella tabella: %s', strjoin(missing, ', '));
    end

    % Sottotabella
    Tsub = T(:, cols);

    % ---------------------------
    % Header "belli" in LaTeX
    % ---------------------------
    niceHeaders = cols;  % di base uso i nomi delle variabili

    % Mappa nomi -> header LaTeX
    m = containers.Map( ...
        {'Species','N0','Ndet','T_eff', ...
         'mu_y_in','sigma_y_in','mu_y_out','sigma_y_out', ...
         'mu_z_in','sigma_z_in','mu_z_out','sigma_z_out', ...
         'mu_r_in','sigma_r_in','mu_r_out','sigma_r_out', ...
         'R_y'}, ...
        {'Species', ...
         '$N_0$', '$N_{\text{det}}$', '$T^{(s)}$', ...
         '$\mu_{y,\text{in}}$',  '$\sigma_{y,\text{in}}$', ...
         '$\mu_{y,\text{out}}$', '$\sigma_{y,\text{out}}$', ...
         '$\mu_{z,\text{in}}$',  '$\sigma_{z,\text{in}}$', ...
         '$\mu_{z,\text{out}}$', '$\sigma_{z,\text{out}}$', ...
         '$\mu_{r,\text{in}}$',  '$\sigma_{r,\text{in}}$', ...
         '$\mu_{r,\text{out}}$', '$\sigma_{r,\text{out}}$', ...
         '$R_y$'} );

    for k = 1:numel(niceHeaders)
        key = niceHeaders{k};
        if isKey(m, key)
            niceHeaders{k} = m(key);
        end
    end

    % ---------------------------
    % Scrittura file LaTeX
    % ---------------------------
    fid = fopen(filename,'w');
    if fid < 0
        error('beamStatsToLatex:FileOpen', ...
              'Impossibile aprire il file "%s" in scrittura.', filename);
    end

    cleaner = onCleanup(@() fclose(fid));  % chiude il file anche se c'è un errore

    nCols = width(Tsub);

    % Prefisso tabella (puoi personalizzarlo)
    fprintf(fid, '%% Tabella generata da simion.beamStatsToLatex\n');
    fprintf(fid, '\\begin{table}[ht]\n');
    fprintf(fid, '\\centering\n');
    fprintf(fid, '\\begin{tabular}{%s}\n', ['l', repmat('c',1,nCols-1)]);
    fprintf(fid, '\\toprule\n');

    % Header
    for j = 1:nCols
        fprintf(fid, '%s', niceHeaders{j});
        if j < nCols
            fprintf(fid, ' & ');
        else
            fprintf(fid, ' \\\\\n');
        end
    end
    fprintf(fid, '\\midrule\n');

    % Righe
    nRows = height(Tsub);
    for iRow = 1:nRows
        for j = 1:nCols
            val = Tsub{iRow,j};

            if isnumeric(val)
                if numel(val) == 1
                    if isnan(val)
                        str = '--';
                    else
                        str = sprintf(numFormat, val);
                    end
                else
                    % vettori: li stampo tra parentesi
                    str = sprintf(numFormat, val(1));
                    for kk = 2:numel(val)
                        str = [str, ',', sprintf(numFormat, val(kk))]; %#ok<AGROW>
                    end
                    str = ['[', str, ']'];
                end
            elseif isstring(val) || ischar(val)
                str = char(val);
            elseif iscategorical(val)
                str = char(string(val));
            else
                % fallback generico
                str = char(string(val));
            end

            fprintf(fid, '%s', str);

            if j < nCols
                fprintf(fid, ' & ');
            else
                fprintf(fid, ' \\\\\n');
            end
        end
    end

    fprintf(fid, '\\bottomrule\n');
    fprintf(fid, '\\end{tabular}\n');
    fprintf(fid, '\\end{table}\n');

    % fclose(fid) lo fa il onCleanup
end