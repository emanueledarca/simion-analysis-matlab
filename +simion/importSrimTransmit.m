function [Data, FitResults] = importSrimTransmit(filenames)
% IMPORTSRIMTRANSMIT  Importa file SRIM TRANSMIT_* e calcola i fit gaussiani.
%
%   [Data, FitResults] = simion.importSrimTransmit(filenames)
%
%   filenames : string/cellstr con i nomi dei file TRANSMIT_*.txt
%               (percorso relativo o assoluto).
%
%   Data      : cell array {k} con struct per ciascun file:
%                 .filename, .species, .E_nom_keV, .table (dati grezzi+angoli)
%   FitResults: struct array con campi:
%                 filename, species, energy_nominal_keV, N,
%                 energy_mu_eV, energy_sigma_eV, energy_FWHM_eV,
%                 phi_mu_deg, ..., elev_mu_deg, ..., x_mu_A, ..., ecc.

    if nargin < 1 || isempty(filenames)
        error('Devi specificare almeno un file SRIM TRANSMIT da importare.');
    end

    if ischar(filenames) || isstring(filenames)
        filenames = cellstr(filenames);
    end
    filenames = string(filenames(:));
    nFiles    = numel(filenames);

    Data       = cell(nFiles,1);

    FitTemplate = struct( ...
        'filename'           , "", ...
        'species'            , "", ...
        'energy_nominal_keV' , NaN, ...
        'N'                  , 0, ...
        'energy_mu_eV'       , NaN, ...
        'energy_sigma_eV'    , NaN, ...
        'energy_FWHM_eV'     , NaN, ...
        'phi_mu_deg'         , NaN, ...
        'phi_sigma_deg'      , NaN, ...
        'phi_FWHM_deg'       , NaN, ...
        'elev_mu_deg'        , NaN, ...
        'elev_sigma_deg'     , NaN, ...
        'elev_FWHM_deg'      , NaN, ...
        'x_mu_A'             , NaN, ...
        'x_sigma_A'          , NaN, ...
        'x_FWHM_A'           , NaN, ...
        'y_mu_A'             , NaN, ...
        'y_sigma_A'          , NaN, ...
        'y_FWHM_A'           , NaN, ...
        'z_mu_A'             , NaN, ...
        'z_sigma_A'          , NaN, ...
        'z_FWHM_A'           , NaN);

    FitResults = repmat(FitTemplate, nFiles, 1);

    for k = 1:nFiles
        fname = filenames(k);
        fprintf('\n*** Importo file SRIM %s ***\n', fname);

        % --------- lettura raw ----------
        txt   = fileread(fname);
        lines = regexp(txt, '\r\n|\n', 'split')';
        lines = lines(~cellfun(@isempty, lines));

        % --- header: specie + energia nominale
        idxHeader = find(contains(lines, 'TRIM Calc.'), 1, 'first');
        species = "";
        EkeV    = NaN;

        if ~isempty(idxHeader)
            headerLine = lines{idxHeader};
            tok = regexp(headerLine, 'TRIM Calc\.\=\s*([A-Za-z0-9\+\-]+)\(([0-9\.]+)\s*keV\)', ...
                         'tokens', 'once');
            if ~isempty(tok)
                species = string(strtrim(tok{1}));
                EkeV    = str2double(tok{2});
            else
                species = string(fname);
            end
        else
            species = string(fname);
        end

        % --- righe dati: T/S/B ---
        isData    = ~cellfun(@isempty, regexp(lines, '^[TSB]\s', 'once'));
        dataLines = lines(isData);
        N         = numel(dataLines);

        IonType = repmat(' ', N, 1);
        IonNum  = zeros(N,1);
        Zatom   = zeros(N,1);
        E_eV    = zeros(N,1);
        X_A     = zeros(N,1);
        Y_A     = zeros(N,1);
        Z_A     = zeros(N,1);
        cosX    = zeros(N,1);
        cosY    = zeros(N,1);
        cosZ    = zeros(N,1);

        for i = 1:N
            ln = strtrim(dataLines{i});
            IonType(i) = ln(1);
            lnNums     = ln(2:end);
            lnNums     = strrep(lnNums, ',', '.');

            vals = sscanf(lnNums, '%f');
            if numel(vals) ~= 9
                error('Parsing fallito alla riga %d del file %s', i, fname);
            end

            IonNum(i) = vals(1);
            Zatom(i)  = vals(2);
            E_eV(i)   = vals(3);
            X_A(i)    = vals(4);
            Y_A(i)    = vals(5);
            Z_A(i)    = vals(6);
            cosX(i)   = vals(7);
            cosY(i)   = vals(8);
            cosZ(i)   = vals(9);
        end

        % --- solo trasmessi (T) ---
        maskT = (IonType == 'T');

        IonNumT = IonNum(maskT);
        ZatomT  = Zatom(maskT);
        E_T     = E_eV(maskT);
        X_T     = X_A(maskT);
        Y_T     = Y_A(maskT);
        Z_T     = Z_A(maskT);
        ux      = cosX(maskT);
        uy      = cosY(maskT);
        uz      = cosZ(maskT);

        % rinormalizzo coseni
        r = sqrt(ux.^2 + uy.^2 + uz.^2);
        r(r == 0) = 1;
        ux = ux ./ r;
        uy = uy ./ r;
        uz = uz ./ r;

        % --- angoli centrati su 0 ---
        phi_deg  = rad2deg(atan2(uy, ux));    % [-180,180]
        elev_deg = rad2deg(asin(uz));         % [-90,90]

        % --- table dati ---
        Tdata = table( ...
            IonNumT, ZatomT, ...
            E_T, X_T, Y_T, Z_T, ...
            ux, uy, uz, ...
            phi_deg, elev_deg, ...
            'VariableNames', { ...
                'IonNum','Zatom', ...
                'Energy_eV','X_A','Y_A','Z_A', ...
                'ux','uy','uz', ...
                'Phi_deg','Elev_deg'});

        S = struct();
        S.filename   = fname;
        S.species    = species;
        S.E_nom_keV  = EkeV;
        S.table      = Tdata;

        Data{k} = S;

        % --- fit gaussiani ---
        [muE,sE,fwhmE]   = localGauss(Tdata.Energy_eV);
        [muPhi,sPhi,fPhi]= localGauss(Tdata.Phi_deg);
        [muEl,sEl,fEl]   = localGauss(Tdata.Elev_deg);
        [muX,sX,fX]      = localGauss(Tdata.X_A);
        [muY,sY,fY]      = localGauss(Tdata.Y_A);
        [muZ,sZ,fZ]      = localGauss(Tdata.Z_A);
      
        
        FR = FitTemplate;
        FR.filename           = fname;
        FR.species            = species;
        FR.energy_nominal_keV = EkeV;
        FR.N                  = height(Tdata);

        FR.energy_mu_eV       = muE;
        FR.energy_sigma_eV    = sE;
        FR.energy_FWHM_eV     = fwhmE;

        FR.phi_mu_deg         = muPhi;
        FR.phi_sigma_deg      = sPhi;
        FR.phi_FWHM_deg       = fPhi;

        FR.elev_mu_deg        = muEl;
        FR.elev_sigma_deg     = sEl;
        FR.elev_FWHM_deg      = fEl;

        FR.x_mu_A             = muX;
        FR.x_sigma_A          = sX;
        FR.x_FWHM_A           = fX;

        FR.y_mu_A             = muY;
        FR.y_sigma_A          = sY;
        FR.y_FWHM_A           = fY;

        FR.z_mu_A             = muZ;
        FR.z_sigma_A          = sZ;
        FR.z_FWHM_A           = fZ;

        FitResults(k) = FR;
          
    end
end

% helper interno
function [mu,sigma,FWHM] = localGauss(x)
% Stima "gaussiana" robusta con sigma-clipping iterativo
x = x(:);
x = x(~isnan(x));
if isempty(x)
    mu = NaN; sigma = NaN; FWHM = NaN;
    return;
end

maxIter    = 5;
clipNSigma = 3;   % tiene ~99.7% della parte "core" se fosse davvero gaussiana

mask = true(size(x));
for it = 1:maxIter
    xUse = x(mask);

    mu_new    = mean(xUse);
    sigma_new = std(xUse, 1);

    if sigma_new == 0
        break;
    end

    newMask = abs(x - mu_new) <= clipNSigma * sigma_new;

    % se non cambia più, stop
    if all(newMask == mask)
        break;
    end

    mask  = newMask;
    mu    = mu_new;
    sigma = sigma_new;
end

% se non abbiamo assegnato mu/sigma dentro il loop:
if ~exist('mu','var')
    mu    = mean(x);
    sigma = std(x,1);
end

FWHM = 2*sqrt(2*log(2)) * sigma;
end