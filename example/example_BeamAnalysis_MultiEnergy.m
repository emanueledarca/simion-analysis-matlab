% example_BeamAnalysis_MultiEnergy.m
%
% Example: run simion.analyzeBeamFile on multiple SIMION output files
% (e.g. different energies) and collect the detector stats in one table.
%
% You can then export the combined table to LaTeX if needed.

clear; clc;

%% === USER INPUT ==========================================================
dataDir = "/path/to/your/simion/output";

% List of files and labels (e.g. nominal energies)
files = {
    "run_8keV.txt",   "8 keV";
    "run_16keV.txt",  "16 keV";
    "run_48keV.txt",  "48 keV";
};

XTolerance = 1e-3;
Rcenter    = [37.5 0];
PolarRmax  = 20;

%% === LOOP OVER FILES =====================================================
nFiles   = size(files, 1);
results  = struct([]);
allStats = cell(nFiles, 1);

for k = 1:nFiles
    fname  = files{k, 1};
    label  = files{k, 2};
    fpath  = fullfile(dataDir, fname);

    fprintf("\n>>> [%d/%d] Analyzing file: %s (%s)\n", ...
        k, nFiles, fpath, label);

    results(k).label = label;
    results(k).file  = fpath;

    results(k).analysis = simion.analyzeBeamFile(fpath, ...
        "XTolerance", XTolerance, ...
        "Rcenter",    Rcenter, ...
        "PolarRmax",  PolarRmax);

    % Extract detector stats table if present
    if isfield(results(k).analysis, "beamStatsDetector")
        statsDet = results(k).analysis.beamStatsDetector.SpotBySpecies;
        % Add a column with the energy label
        statsDet.EnergyLabel = repmat(string(label), height(statsDet), 1);
        allStats{k} = statsDet;
    else
        warning("No beamStatsDetector found for file: %s", fpath);
    end
end

%% === BUILD SINGLE TABLE WITH ALL ENERGIES ===============================
hasStats = ~cellfun(@isempty, allStats);
if any(hasStats)
    CombinedStats = vertcat(allStats{hasStats});
    disp("=== Combined detector stats (all energies) ===");
    disp(CombinedStats);
else
    warning("No detector stats available to combine.");
    CombinedStats = table();
end

%% === OPTIONAL: EXPORT TO LATEX ==========================================
exportLatex = false;  % set to true to enable

if exportLatex && ~isempty(CombinedStats)
    outFile = fullfile(dataDir, "beam_stats_detector_multi_energy.tex");

    simion.beamStatsToLatex(CombinedStats, "OutFile", outFile);

    fprintf("LaTeX table written to: %s\n", outFile);
end

fprintf("\nDone.\n");
