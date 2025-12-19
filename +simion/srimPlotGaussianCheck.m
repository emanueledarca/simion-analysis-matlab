function hFig = srimPlotGaussianCheck(xData, fitParams, quantityLabel, ...
                                      speciesLabel, energyLabel, outFolder)
% srimPlotGaussianCheck  Istogramma dati + gaussiana fittata e salvataggio.
%
% INPUT
%   xData         : vettore dei dati (es. elevazione in gradi)
%   fitParams     : struct con almeno campi .mu e .sigma
%                   (opzionale .A per l'ampiezza, se ce l'hai)
%   quantityLabel : etichetta da mettere su asse X (es. 'Elevation [deg]')
%   speciesLabel  : string per la specie (es. 'O+' oppure 'O @ 8 keV')
%   energyLabel   : string tipo '8 keV', '16 keV' ecc.
%   outFolder     : cartella dove salvare la figura
%
% OUTPUT
%   hFig          : handle della figura (se ti serve)

    arguments
        xData (:,1) double
        fitParams struct
        quantityLabel (1,:) char
        speciesLabel (1,:) char
        energyLabel (1,:) char
        outFolder (1,:) char
    end

    % Istogramma (puoi cambiare BinMethod/nbins se vuoi più controllo)
    [N, edges] = histcounts(xData, 'BinMethod', 'fd');  % Freedman–Diaconis
    binCenters = edges(1:end-1) + diff(edges)/2;

    mu    = fitParams.mu;
    sigma = fitParams.sigma;

    % Se hai salvato anche l'ampiezza A, usa quella; altrimenti normalizza "a occhio"
    if isfield(fitParams, 'A')
        A = fitParams.A;
    else
        % scala la gaussiana sull'altezza massima dell'istogramma
        A = max(N);
    end

    gaussY = A * exp(-0.5 * ((binCenters - mu)/sigma).^2);

    % Figura "headless" per salvare senza aprire mille finestre
    hFig = figure('Visible', 'off');
    hold on;

    % Istogramma come bar
    bar(binCenters, N, 'hist');
    % Curva di fit
    plot(binCenters, gaussY, 'LineWidth', 2);

    xlabel(quantityLabel, 'Interpreter', 'none');
    ylabel('Counts');
    title(sprintf('%s – %s – %s', speciesLabel, energyLabel, quantityLabel), ...
          'Interpreter', 'none');
    grid on;
    box on;
    hold off;

    % Assicurati che la cartella esista
    if ~exist(outFolder, 'dir')
        mkdir(outFolder);
    end

    % Nome file "safe"
    baseName = sprintf('%s_%s_%s', speciesLabel, energyLabel, quantityLabel);
    baseName = regexprep(baseName, '\s+', '_');          % spazi -> _
    baseName = regexprep(baseName, '[^\w\-]', '');        % togli caratteri strani

    pngFile = fullfile(outFolder, [baseName '.png']);
    figFile = fullfile(outFolder, [baseName '.fig']);

    % Salva in PNG (alta risoluzione) + formato MATLAB
    exportgraphics(hFig, pngFile, 'Resolution', 300);
    savefig(hFig, figFile);

    % Se non ti serve tenere la figura in giro
    close(hFig);
end