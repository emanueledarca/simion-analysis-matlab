% example_BeamAnalysis.m
%
% End-to-end beam analysis for a single SIMION output file using
% simion.analyzeBeamFile.
%
% The script:
%   - imports the SIMION file
%   - computes beam statistics at source and detector
%   - fits TOF distributions per species
%   - optionally generates plots (depending on analyzeBeamFile options)
%   - saves a results .mat file in the same folder as the input

clear; clc;

%% === USER INPUT ==========================================================
dataDir = "/path/to/your/simion/output";
fname   = "run_8keV.txt";

% Detector / polar map configuration
XTolerance = 1e-3;      % tolerance on X to decide if a hit is at the detector
Rcenter    = [37.5 0];  % center (Y0, Z0) for polar map, in mm (example value)
PolarRmax  = 20;        % max radius for polar map (mm)

%% === RUN ANALYSIS ========================================================
fullpath = fullfile(dataDir, fname);
fprintf(">>> Running analyzeBeamFile on: %s\n", fullpath);

results = simion.analyzeBeamFile(fullpath, ...
    "XTolerance", XTolerance, ...
    "Rcenter",    Rcenter, ...
    "PolarRmax",  PolarRmax);

fprintf("   Analysis done.\n");

%% === INSPECT MAIN RESULTS ===============================================
% The 'results' struct typically contains:
%   - results.T                 : imported SIMION table
%   - results.tofFits           : TOF fit results per species
%   - results.beamStatsInOut    : stats at source / detector plane
%   - results.beamStatsDetector : stats at detector only
%   - results.polarMap          : data for polar plots (if enabled)
%
% Here we just print a few summaries.

if isfield(results, "beamStatsInOut")
    disp("=== Beam stats (In / Out) ===");
    disp(results.beamStatsInOut.SpotBySpecies);
end

if isfield(results, "beamStatsDetector")
    disp("=== Beam stats at detector ===");
    disp(results.beamStatsDetector.SpotBySpecies);
end

if isfield(results, "tofFits")
    disp("=== TOF fit results ===");
    disp(results.tofFits);
end

%% === OPTIONAL: EXPORT BEAM STATS TO LATEX ===============================
% If you want a LaTeX table for the detector statistics, you can do:

exportLatex = false;   % set to true to enable LaTeX export

if exportLatex && isfield(results, "beamStatsDetector")
    outDir  = dataDir;
    outFile = fullfile(outDir, "beam_stats_detector.tex");

    simion.beamStatsToLatex(results.beamStatsDetector.SpotBySpecies, ...
        "OutFile", outFile);

    fprintf("LaTeX table written to: %s\n", outFile);
end

fprintf("Done.\n");
