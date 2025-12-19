function [figHandles, stats] = plotBeamEvolutionY(inputArg, varargin)
% PLOTBEAMEVOLUTIONY
%   Grafici dell'evoluzione longitudinale di µ_y(x) e σ_y(x) per specie.
%
%   [figHandles, stats] = simion.plotBeamEvolutionY(T, ...)
%   [figHandles, stats] = simion.plotBeamEvolutionY(filename, ...)
%
%   inputArg può essere:
%     - una table SIMION
%     - una string/char col path del file SIMION da dare a
%       simion.importSimionTofTable (tramite computeBeamEvolutionY)
%
%   OUTPUT
%     figHandles(1) -> µ_y(x) per specie
%     figHandles(2) -> σ_y(x) per specie
%     stats         -> struct di simion.computeBeamEvolutionY

    % Lasciamo fare tutto alla compute (che importa anche il file se serve)
    stats = simion.computeBeamEvolutionY(inputArg, varargin{:});

    Sp  = stats.SpeciesStats;
    nSp = numel(Sp);

    co = lines(max(nSp,1));  % palette semplice

    figHandles = gobjects(2,1);

    %-------------------------
    % 1) µ_y(x) per specie
    %-------------------------
    figMu = figure;
    figHandles(1) = figMu;
    axMu = axes('Parent', figMu);
    hold(axMu, 'on');

    for k = 1:nSp
        sk = Sp(k);
        x  = sk.X(:);
        y  = sk.muY(:);
        N  = sk.N(:);

        valid = ~isnan(y) & (N > 0);
        if ~any(valid)
            continue;
        end

        plot(axMu, x(valid), y(valid), '-o', ...
            'Color', co(k,:), ...
            'MarkerSize', 4, ...
            'DisplayName', char(sk.Species));
    end

    xlabel(axMu, 'X [mm]');
    ylabel(axMu, '\mu_y [mm]');
    title(axMu, 'Posizione media \mu_y(x) per specie');
    grid(axMu, 'on');
    legend(axMu, 'Location', 'best');
    box(axMu, 'on');

    % Overlay dei fit lineari
    for k = 1:nSp
        sk = Sp(k);
        F  = sk.FitMuY;
        if ~isnan(F.a) && ~isnan(F.b) && ~isnan(F.xMin) && ~isnan(F.xMax)
            xFit = linspace(F.xMin, F.xMax, 100);
            yFit = F.a + F.b * xFit;
            plot(axMu, xFit, yFit, '--', ...
                'Color', co(k,:), ...
                'HandleVisibility', 'off');
        end
    end

    %-------------------------
    % 2) σ_y(x) per specie
    %-------------------------
    figSig = figure;
    figHandles(2) = figSig;
    axSig = axes('Parent', figSig);
    hold(axSig, 'on');

    for k = 1:nSp
        sk = Sp(k);
        x  = sk.X(:);
        s  = sk.sigmaY(:);
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
    ylabel(axSig, '\sigma_y [mm]');
    title(axSig, 'Larghezza \sigma_y(x) per specie');
    grid(axSig, 'on');
    legend(axSig, 'Location', 'best');
    box(axSig, 'on');
end