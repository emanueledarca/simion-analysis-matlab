% test_importSimion.m
%
% Simple smoke-test for SIMION import functions.
% The script:
%   - imports a SIMION output file with importSimionRecordTable
%   - prints basic info about the table and variable names
%   - optionally makes a quick TOF plot if TOF and Species are present

clear; clc;

%% === USER INPUT ==========================================================
dataDir = "/path/to/your/simion/output";
fname   = "run_test.txt";

%% === IMPORT RAW TABLE ====================================================
fullpath = fullfile(dataDir, fname);
fprintf(">>> Importing SIMION file: %s\n", fullpath);

T = simion.importSimionRecordTable(fullpath);

fprintf("   Imported %d rows and %d columns.\n", height(T), width(T));
disp("=== Variable names ===");
disp(T.Properties.VariableNames.');

%% === QUICK CHECKS ========================================================
% Show the first few rows
disp("=== First 5 rows ===");
disp(T(1:min(5, height(T)), :));

% If TOF and Species exist, make a quick TOF plot using the public API
if ismember("TOF",     T.Properties.VariableNames) && ...
   ismember("Species", T.Properties.VariableNames)

    fprintf(">>> Plotting TOF per species (pdf mode)…\n");
    simion.plotTofBySpecies(T, "pdf", 80);
else
    fprintf("No TOF/Species columns found, skipping TOF plot.\n");
end

fprintf("Done.\n");
