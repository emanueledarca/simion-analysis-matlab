% example_ImportAndTof.m
%
% Minimal example: from a SIMION output file to TOF histograms per species.
%
% HOW TO USE:
%   1. Set dataDir and filename below.
%   2. Run this script from a folder that has +simion on the MATLAB path.

clear; clc;

%% === USER INPUT ==========================================================
% Directory that contains your SIMION output file
dataDir = "/path/to/your/simion/output";

% Name of the SIMION output file (txt/csv)
fname  = "run_8keV.txt";

% TOF plot options
mode   = "hist-local";   % "pdf", "hist-global", "hist-local"
nbins  = 60;             % number of bins for histograms

%% === IMPORT DATA =========================================================
fullpath = fullfile(dataDir, fname);
fprintf(">>> Importing SIMION file: %s\n", fullpath);

T = simion.importSimionTofTable(fullpath);

fprintf("   Imported %d rows and %d columns.\n", height(T), width(T));
if ismember("Species", T.Properties.VariableNames)
    fprintf("   Detected %d species.\n", numel(unique(T.Species)));
end

%% === TOF PLOT PER SPECIES ===============================================
fprintf(">>> Plotting TOF per species (%s, %d bins)…\n", mode, nbins);

FitResults = simion.plotTofBySpecies(T, mode, nbins);

% FitResults is a struct (or table) with Gaussian parameters per species.
disp("=== TOF fit results (first few fields) ===");
disp(FitResults);

fprintf("Done.\n");
