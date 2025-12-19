function [figHandles, stats] = plotBeamEvolutionZ(inputArg, varargin)
% PLOTBEAMEVOLUTIONZ
%   Grafici dell'evoluzione longitudinale di µ_z(x) e σ_z(x) per specie.
%
%   [figHandles, stats] = simion.plotBeamEvolutionZ(T, ...)
%   [figHandles, stats] = simion.plotBeamEvolutionZ(filename, ...)
%
%   inputArg può essere:
%     - una table SIMION
%     - una string/char col path del file SIMION
%
%   OUTPUT
%     figHandles(1) -> µ_z(x) per specie
%     figHandles(2) -> σ_z(x) per specie
%     stats         -> struct di simion.computeBeamEvolutionY

    % Riuso i conti già fatti (import compreso)
    stats = simion.computeBeamEvolutionY(inputArg, varargin{:});

    Sp  = stats.SpeciesStats;
    nSp = numel(Sp);

    % Controllo che ci sia davvero Z
    hasZ = false;
    for k = 1:nSp
        if ~isempty(Sp(k).muZ)
            hasZ = true;
            break;
        end
    end
    if ~hasZ
        error('plotBeamEvolutionZ:NoZ', ...
              'I dati non contengono coordinate Z: impossibile plottare µ_z e σ_z.');
    end

    co = lines(max(nSp,1));

    figHandles = gobjects(2,1);

    %-------------------------
    % 1) µ_z(x) per specie
    %-------------------------
    figMu = figure;
    figHandles(1) = figMu;
    axMu = axes('Parent', figMu);
    hold(axMu, 'on');

    for k = 1:nSp
        sk = Sp(k);
        x  = sk.X(:);
        z  = sk.muZ(:);
        N  = sk.N(:);

        valid = ~isnan(z) & (N > 0);
        if ~any(valid)
            continue;
        end

        plot(axMu, x(valid), z(valid), '-o', ...
            'Color', co(k,:), ...
            'MarkerSize', 4, ...
            'DisplayName', char(sk.Species));
    end

    xlabel(axMu, 'X [mm]');
    ylabel(axMu, '\mu_z [mm]');
    title(axMu, 'Posizione media \mu_z(x) per specie');
    grid(axMu, 'on');
    legend(axMu, 'Location', 'best');
    box(axMu, 'on');

    %-------------------------
    % 2) σ_z(x) per specie
    %-------------------------
    figSig = figure;
    figHandles(2) = figSig;
    axSig = axes('Parent', figSig);
    hold(axSig, 'on');

    for k = 1:nSp
        sk = Sp(k);
        x  = sk.X(:);
        s  = sk.sigmaZ(:);
        N  = sk.N(:);

        valid = ~isnan(s) & (N > 0);
        if ~any(valid)
            continue;
        end

        plot(axSig, x(valid), s(valid), '-o', ...
            'Color', co(k,:), ...
            'MarkerSize', 4, ...
            'DisplayName', char(sk.Species));
    end

    xlabel(axSig, 'X [mm]');
    ylabel(axSig, '\sigma_z [mm]');
    title(axSig, 'Larghezza \sigma_z(x) per specie');
    grid(axSig, 'on');
    legend(axSig, 'Location', 'best');
    box(axSig, 'on');
end