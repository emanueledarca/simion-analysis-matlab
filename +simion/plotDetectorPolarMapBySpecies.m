function [figHandles, mapStruct] = plotDetectorPolarMapBySpecies(T, varargin)
% PLOTDETECTORPOLARMAPBYSPECIES
%   Mappa di densità polare degli impatti al detector nel piano YZ.
%
%   [figHandles, mapStruct] = simion.plotDetectorPolarMapBySpecies(T, ...)
%
% Input:
%   T           table SIMION (es. simion.importSimionTofTable)
%
% Name-Value:
%   'XTolerance'    tolleranza su X per selezionare il piano del detector
%                   (default: 1e-3)
%   'Center'        [Yc Zc] centro geometrico del detector in mm
%                   (default: [37.5 0])
%   'Rmax'          raggio massimo della mappa (default: auto da dati)
%   'NbinsR'        numero di bin radiali (default: 40)
%   'NbinsTheta'    numero di bin angolari (default: 72)
%   'Species'       "all" oppure string/cellstr con specie da plottare
%                   (default: "all")
%
% Output:
%   figHandles      array di handle figure (una per specie)
%   mapStruct       struct con info sui bin e sui conteggi.

    % ------------------------
    % Parse input
    % ------------------------
    p = inputParser;
    p.FunctionName = 'plotDetectorPolarMapBySpecies';

    addRequired(p,'T',@(x) istable(x));
    addParameter(p,'XTolerance',1e-3, @(x) isnumeric(x) && isscalar(x) && x>=0);
    addParameter(p,'Center',[37.5 0], @(v) isnumeric(v) && numel(v)==2);
    addParameter(p,'Rmax',[],         @(x) isempty(x) || (isscalar(x) && x>0));
    addParameter(p,'NbinsR',40,       @(x) isnumeric(x) && isscalar(x) && x>0);
    addParameter(p,'NbinsTheta',72,   @(x) isnumeric(x) && isscalar(x) && x>0);
    addParameter(p,'Species',"all",   @(s) isstring(s) || ischar(s) || iscellstr(s));

    parse(p,T,varargin{:});

    tolX   = p.Results.XTolerance;
    center = p.Results.Center(:).';   % [Yc Zc]
    Rmax   = p.Results.Rmax;
    Nr     = p.Results.NbinsR;
    Nth    = p.Results.NbinsTheta;
    spSel  = p.Results.Species;

    % ------------------------
    % 1) Colpi al detector (X ~ Xmax)
    % ------------------------
    Tdet = getDetectorHitsAtXmax(T, 'XTolerance', tolX);

    if ~ismember('Species', Tdet.Properties.VariableNames)
        error('plotDetectorPolarMapBySpecies:NoSpecies', ...
              'La table non contiene la colonna Species.');
    end

    % Tutte le specie come STRING array
    allSpecies = string(categories(categorical(string(Tdet.Species))));

    % Normalizzo la selezione delle specie
    if ischar(spSel) || iscellstr(spSel)
        spSel = string(spSel);
    end

    if isscalar(spSel) && spSel == "all"
        spList = allSpecies(:);        % tutte le specie
    else
        spList = string(spSel(:));     % specie scelte
    end

    % ------------------------
    % 2) Coordinate polari nel piano YZ
    % ------------------------
    y = Tdet.Y;
    z = Tdet.Z;

    dy = y - center(1);
    dz = z - center(2);
    r  = hypot(dy,dz);

    if isempty(Rmax)
        Rmax = max(r);
    end

    rEdges     = linspace(0, Rmax, Nr+1);
    theta      = atan2(dz, dy);              % [-pi, pi]
    thetaEdges = linspace(-pi, pi, Nth+1);

    % ------------------------
    % 3) Istogrammi per specie
    % ------------------------
    spCat = categorical(string(Tdet.Species));
    countsPerSpecies = cell(numel(spList),1);
    maxCount = 0;

    for k = 1:numel(spList)
        mask = (spCat == categorical(spList(k)));
        [H, ~, ~] = histcounts2( r(mask), theta(mask), ...
                                 rEdges, thetaEdges );
        countsPerSpecies{k} = H;
        maxCount = max(maxCount, max(H(:)));
    end

    % ------------------------
    % 4) Griglia cartesiana (Y,Z) sui BORDI dei bin
    % ------------------------
    [TH_edges, RR_edges] = meshgrid(thetaEdges, rEdges);
    Yedge = center(1) + RR_edges .* cos(TH_edges);
    Zedge = center(2) + RR_edges .* sin(TH_edges);

    % Griglia polare estetica
    nCircles = 6;
    nRays    = 8;
    rGrid    = linspace(Rmax/nCircles, Rmax, nCircles);
    thFine   = linspace(-pi, pi, 361);

    % ------------------------
    % 5) Plot per specie (piano YZ)
    % ------------------------
    figHandles = gobjects(numel(spList),1);

    for k = 1:numel(spList)
        figHandles(k) = figure;
        set(figHandles(k),'Color','k');

        H = countsPerSpecies{k};   % Nr x Nth

        Cpad = nan(Nr+1, Nth+1);
        Cpad(1:Nr, 1:Nth) = H;

        pcolor(Yedge, Zedge, Cpad);
        shading flat;

        colormap(parula);
        caxis([0 maxCount]);
        cb = colorbar;
        cb.Label.String = 'Number of hits';

        ax = gca;
        ax.Color = [0 0 0];
        hold on;
        axis equal;

        xlim(center(1) + Rmax*[-1 1]);
        ylim(center(2) + Rmax*[-1 1]);

        % Cerchi concentrici
        for rr = rGrid
            plot(center(1) + rr*cos(thFine), ...
                 center(2) + rr*sin(thFine), ...
                 'w:', 'LineWidth', 0.7);
        end

        % Raggi radiali
        phiGrid = linspace(-pi, pi, nRays+1);
        for phi = phiGrid
            plot([center(1), center(1)+Rmax*cos(phi)], ...
                 [center(2), center(2)+Rmax*sin(phi)], ...
                 'w:', 'LineWidth', 0.7);
        end

        % Bordo esterno
        plot(center(1) + Rmax*cos(thFine), ...
             center(2) + Rmax*sin(thFine), ...
             'w', 'LineWidth', 1);

        xlabel('Y [mm]');
        ylabel('Z [mm]');
        title(sprintf('Ion impact density - polar map (%s)', char(spList(k))), ...
              'Color','w');

        set(gca,'XColor','w','YColor','w', ...
                'FontSize',12, ...
                'Box','on');
    end

    % ------------------------
    % 6) Struct di output
    % ------------------------
    mapStruct = struct();
    mapStruct.Species    = spList;      % string array
    mapStruct.REdges     = rEdges;
    mapStruct.ThetaEdges = thetaEdges;
    mapStruct.Center     = center;      % [Yc Zc]
    mapStruct.Rmax       = Rmax;
    mapStruct.Counts     = countsPerSpecies;
end