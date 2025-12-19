%% Import_SRIM_TRANSMIT.m
% Wrapper per importare i file SRIM TRANSMIT_* e calcolare i fit.
%
% Usa la funzione di libreria:
%   [Data, FitResults] = simion.importSrimTransmit(filenames)
%   simion.srimFitResultsToLatex(FitResults, texFile)
%
% Qui ci occupiamo di:
%   - costruire i path completi dei file SRIM (data_raw/srim)
%   - chiamare le funzioni di libreria
%   - salvare i risultati in data_processed/srim
%   - stampare un riepilogo leggibile in Command Window

clear; clc;


% Offset geometrici (coordinate sorgente in SIMION, in mm)
x0_geom_mm = 4.1;
y0_geom_mm = 37.35;

%% 1) Root del progetto e cartelle

% Questo script si trova in .../Trajectories/matlab/scripts
scriptsDir = fileparts(mfilename('fullpath'));
projRoot   = fileparts(fileparts(scriptsDir));   % .../Trajectories

srimDir    = fullfile(projRoot, 'data_raw',      'srim10keV');
outRootDir = fullfile(projRoot, 'data_processed','srim10keV');
outMatDir  = outRootDir;                        % .mat qui
outTabDir  = fullfile(outRootDir, 'tables');    % tabelle (csv/tex) qui

if ~exist(outMatDir, 'dir'), mkdir(outMatDir); end
if ~exist(outTabDir, 'dir'), mkdir(outTabDir); end
% Cartelle per le figure di controllo dei fit SRIM
figRoot      = fullfile(projRoot, 'figures', 'srim10keV');
figEnergyDir = fullfile(figRoot, 'energy');
figPhiDir    = fullfile(figRoot, 'phi');
figElevDir   = fullfile(figRoot, 'elevation');
figXDir      = fullfile(figRoot, 'x_pos');
figYDir      = fullfile(figRoot, 'y_pos');
figZDir      = fullfile(figRoot, 'z_pos');

if ~exist(figRoot,      'dir'), mkdir(figRoot);      end
if ~exist(figEnergyDir, 'dir'), mkdir(figEnergyDir); end
if ~exist(figPhiDir,    'dir'), mkdir(figPhiDir);    end
if ~exist(figElevDir,   'dir'), mkdir(figElevDir);   end
if ~exist(figXDir,      'dir'), mkdir(figXDir);      end
if ~exist(figYDir,      'dir'), mkdir(figYDir);      end
if ~exist(figZDir,      'dir'), mkdir(figZDir);      end
%% 2) Elenco dei file SRIM da importare (nomi base)

filenames = [
    "H_plus_10keV.txt"
    "He_plus_10keV.txt"
    "He_2plus_10keV.txt"
    "O_6plus_10keV.txt"
    "O_plus_10keV.txt"
];

% Costruisco i path completi
filepaths = strings(size(filenames));
for k = 1:numel(filenames)
    filepaths(k) = fullfile(srimDir, filenames(k));
end

% Controllo rapido che i file esistano
for k = 1:numel(filepaths)
    if ~isfile(filepaths(k))
        error('File SRIM non trovato:\n  %s', filepaths(k));
    end
end

%% 3) Chiamata alla funzione di libreria

[Data, FitResults] = simion.importSrimTransmit(filepaths);

%% 3.5) Stampa riepilogo fit su Command Window + salvataggio in mm

fprintf('\n================ RIEPILOGO FIT SRIM (TRANSMIT_*) ================\n');

nF    = numel(FitResults);
ang2mm = 1e-7;   % 1 Å = 1e-7 mm

% Vettori in mm (relativi e assoluti) per averli comodi in workspace
x_mu_mm_all        = nan(nF,1);
x_mu_geom_mm_all   = nan(nF,1);
x_sigma_mm_all     = nan(nF,1);
x_FWHM_mm_all      = nan(nF,1);

y_mu_mm_all        = nan(nF,1);
y_mu_geom_mm_all   = nan(nF,1);
y_sigma_mm_all     = nan(nF,1);
y_FWHM_mm_all      = nan(nF,1);

z_mu_mm_all        = nan(nF,1);
z_sigma_mm_all     = nan(nF,1);
z_FWHM_mm_all      = nan(nF,1);

for k = 1:nF
    FR    = FitResults(k);
    Tdata = Data{k}.table;  % dati grezzi per i plot

    fprintf('\n=== %s (%.0f keV) ===  N(T) = %d\n', ...
        FR.species, FR.energy_nominal_keV, FR.N);

    % ------------------
    % PLOT DI CONTROLLO
    % ------------------
    speciesLabel = char(FR.species);                    % srimPlotGaussianCheck vuole char
    energyLabel  = sprintf('%.0f keV', FR.energy_nominal_keV);

    % Energia
    fitE.mu    = FR.energy_mu_eV;
    fitE.sigma = FR.energy_sigma_eV;
    simion.srimPlotGaussianCheck(Tdata.Energy_eV, fitE, 'Energy [eV]', ...
                          speciesLabel, energyLabel, figEnergyDir);

    % Phi
    fitPhi.mu    = FR.phi_mu_deg;
    fitPhi.sigma = FR.phi_sigma_deg;
    simion.srimPlotGaussianCheck(Tdata.Phi_deg, fitPhi, 'Phi [deg]', ...
                          speciesLabel, energyLabel, figPhiDir);

    % Elevazione
    fitEl.mu    = FR.elev_mu_deg;
    fitEl.sigma = FR.elev_sigma_deg;
    simion.srimPlotGaussianCheck(Tdata.Elev_deg, fitEl, 'Elevation [deg]', ...
                          speciesLabel, energyLabel, figElevDir);

    % X (posizione SRIM in Å)
    fitX.mu    = FR.x_mu_A;
    fitX.sigma = FR.x_sigma_A;
    simion.srimPlotGaussianCheck(Tdata.X_A, fitX, 'X [Å]', ...
                          speciesLabel, energyLabel, figXDir);

    % Y
    fitY.mu    = FR.y_mu_A;
    fitY.sigma = FR.y_sigma_A;
    simion.srimPlotGaussianCheck(Tdata.Y_A, fitY, 'Y [Å]', ...
                          speciesLabel, energyLabel, figYDir);

    % Z
    fitZ.mu    = FR.z_mu_A;
    fitZ.sigma = FR.z_sigma_A;
    simion.srimPlotGaussianCheck(Tdata.Z_A, fitZ, 'Z [Å]', ...
                          speciesLabel, energyLabel, figZDir);

    % ------------------
    % STAMPA RIEPILOGO COME PRIMA
    % ------------------

    % Energia
    fprintf('  Energia:  mu = %.3e eV,  sigma = %.3e eV,  FWHM = %.3e eV\n', ...
        FR.energy_mu_eV, FR.energy_sigma_eV, FR.energy_FWHM_eV);

    % Angoli
    fprintf('  Phi:      mu = %.3f deg, sigma = %.3f deg, FWHM = %.1f deg\n', ...
        FR.phi_mu_deg, FR.phi_sigma_deg, FR.phi_FWHM_deg);
    fprintf('  Elev:     mu = %.3f deg, sigma = %.3f deg, FWHM = %.1f deg\n', ...
        FR.elev_mu_deg, FR.elev_sigma_deg, FR.elev_FWHM_deg);

    % --- Posizioni SRIM: Å -> mm (relative) ---
    x_mu_mm    = FR.x_mu_A    * ang2mm;
    x_sigma_mm = FR.x_sigma_A * ang2mm;
    x_FWHM_mm  = FR.x_FWHM_A  * ang2mm;

    y_mu_mm    = FR.y_mu_A    * ang2mm;
    y_sigma_mm = FR.y_sigma_A * ang2mm;
    y_FWHM_mm  = FR.y_FWHM_A  * ang2mm;

    z_mu_mm    = FR.z_mu_A    * ang2mm;
    z_sigma_mm = FR.z_sigma_A * ang2mm;
    z_FWHM_mm  = FR.z_FWHM_A  * ang2mm;

    % --- Posizioni assolute in geometria SIMION ---
    x_mu_geom_mm = x0_geom_mm + x_mu_mm;
    y_mu_geom_mm = y0_geom_mm + y_mu_mm;

    % Stampa: mostro sia relativo che assoluto per X/Y, solo relativo per Z
    fprintf('  X:  mu_rel = %.3e mm, mu_geom = %.3e mm, sigma = %.3e mm, FWHM = %.3e mm\n', ...
        x_mu_mm, x_mu_geom_mm, x_sigma_mm, x_FWHM_mm);
    fprintf('  Y:  mu_rel = %.3e mm, mu_geom = %.3e mm, sigma = %.3e mm, FWHM = %.3e mm\n', ...
        y_mu_mm, y_mu_geom_mm, y_sigma_mm, y_FWHM_mm);
    fprintf('  Z:  mu_rel = %.3e mm,           sigma = %.3e mm, FWHM = %.3e mm\n', ...
        z_mu_mm, z_sigma_mm, z_FWHM_mm);

    % Salvo nei vettori "all" (indice k = file k-esimo)
    x_mu_mm_all(k)        = x_mu_mm;
    x_mu_geom_mm_all(k)   = x_mu_geom_mm;
    x_sigma_mm_all(k)     = x_sigma_mm;
    x_FWHM_mm_all(k)      = x_FWHM_mm;

    y_mu_mm_all(k)        = y_mu_mm;
    y_mu_geom_mm_all(k)   = y_mu_geom_mm;
    y_sigma_mm_all(k)     = y_sigma_mm;
    y_FWHM_mm_all(k)      = y_FWHM_mm;

    z_mu_mm_all(k)        = z_mu_mm;
    z_sigma_mm_all(k)     = z_sigma_mm;
    z_FWHM_mm_all(k)      = z_FWHM_mm;
end


fprintf('\n==================== FINE RIEPILOGO SRIM ====================\n');


%% 4) Salvataggio risultati in .mat

matFile = fullfile(outMatDir, 'srim_Transmit_FitResults.mat');
save(matFile, 'Data', 'FitResults');
fprintf('>>> Salvato Data/FitResults in: %s\n', matFile);

%% 5) Salvataggio riassunto in tabella CSV

FitTable = struct2table(FitResults);
csvFile  = fullfile(outTabDir, 'srim_Transmit_FitResults_summary.csv');
writetable(FitTable, csvFile);
fprintf('>>> Salvata tabella riepilogativa CSV in: %s\n', csvFile);

%% 6) Esportazione in LaTeX tramite la funzione di libreria

texFile = fullfile(outTabDir, 'srim_Transmit_FitResults_summary.tex');
simion.srimFitResultsToLatex(FitResults, texFile);
fprintf('>>> Salvata tabella LaTeX in: %s\n', texFile);

fprintf('>>> Import SRIM completato.\n');