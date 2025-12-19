% example_SrimImport.m
%
% Example: import SRIM TRANSMIT_* files, fit energy/angle/position
% distributions and export the fit results to a LaTeX table.
%
% This script uses:
%   - simion.importSrimTransmit
%   - simion.srimFitResultsToLatex
%   - simion.srimPlotGaussianCheck (optional, for visual checks)

clear; clc;

%% === USER INPUT ==========================================================
dataDir = "/path/to/your/srim/output";

% List of SRIM TRANSMIT files to import (edit with your filenames)
srimFiles = {
    "TRANSMIT_O_8keV.txt";
    "TRANSMIT_O_16keV.txt";
    "TRANSMIT_O_48keV.txt";
};

% Output LaTeX file for the fit summary
outLatex = fullfile(dataDir, "srim_fit_results.tex");

% Whether to plot Gaussian checks for each quantity
doPlots = false;

%% === IMPORT AND FIT ======================================================
fullpaths = fullfile(dataDir, srimFiles);

fprintf(">>> Importing SRIM TRANSMIT files…\n");
[Data, FitResults] = simion.importSrimTransmit(fullpaths);

fprintf("   Imported %d SRIM files.\n", numel(Data));
disp("=== SRIM fit results (summary) ===");
disp(FitResults);

%% === EXPORT TO LATEX =====================================================
fprintf(">>> Exporting fit results to LaTeX…\n");
simion.srimFitResultsToLatex(FitResults, outLatex);
fprintf("   LaTeX table written to: %s\n", outLatex);

%% === OPTIONAL: GAUSSIAN CHECK PLOTS ======================================
if doPlots
    fprintf(">>> Generating Gaussian check plots…\n");
    for k = 1:numel(Data)
        dk = Data{k};
        fk = FitResults(k);

        % Example: check energy distribution
        if isfield(dk, "E")
            figure;
            simion.srimPlotGaussianCheck(dk.E, fk.Energy, ...
                sprintf("%s, %g keV", fk.Species, fk.E_nom_keV));
        end
    end
end

fprintf("Done.\n");
