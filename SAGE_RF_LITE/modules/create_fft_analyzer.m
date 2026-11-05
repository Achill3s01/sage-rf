
function refreshFFT = create_fft_analyzer(parent, getAudioFcn)
% CREATE_FFT_ANALYZER
% Embedded FFT Analyzer for SAGE-RF Lite.
%
% parent      : Workspace panel in main application
% getAudioFcn : Returns [audio, sampleRate, fileName]
%
% refreshFFT() refreshes the analysis using shared application audio.

    %% COLORS

    bg = [0.055 0.075 0.105];
    panelBg = [0.085 0.12 0.17];
    axisBg = [0.035 0.05 0.075];

    textMain = [0.91 0.95 0.98];
    textMuted = [0.62 0.73 0.83];

    blue = [0.28 0.72 0.96];
    orange = [0.95 0.66 0.28];

    %% MAIN LAYOUT

    root = uigridlayout(parent, [3 2]);

    root.RowHeight = {85, '1x', '1x'};
    root.ColumnWidth = {'1x', '1x'};

    root.Padding = [0 0 0 0];
    root.RowSpacing = 12;
    root.ColumnSpacing = 12;

    root.BackgroundColor = bg;

    %% SUMMARY PANEL

    summary = uipanel(root, ...
        'BorderType', 'line', ...
        'BorderColor', [0.16 0.23 0.31], ...
        'BackgroundColor', panelBg);

    summary.Layout.Row = 1;
    summary.Layout.Column = [1 2];

    sg = uigridlayout(summary, [2 4]);

    sg.RowHeight = {25, 25};
    sg.ColumnWidth = {'1x', '1x', '1x', 115};

    sg.Padding = [14 8 12 8];
    sg.RowSpacing = 3;
    sg.ColumnSpacing = 10;

    sg.BackgroundColor = panelBg;

    fileLabel = uilabel(sg, ...
        'Text', 'No audio loaded', ...
        'FontSize', 12, ...
        'FontWeight', 'bold', ...
        'FontColor', textMain, ...
        'BackgroundColor', panelBg);

    fileLabel.Layout.Row = 1;
    fileLabel.Layout.Column = [1 3];

    refreshButton = uibutton(sg, 'push', ...
        'Text', 'Refresh FFT', ...
        'FontSize', 10, ...
        'FontWeight', 'bold', ...
        'FontColor', [1 1 1], ...
        'BackgroundColor', [0.08 0.43 0.68], ...
        'ButtonPushedFcn', @(src,event) refresh());

    refreshButton.Layout.Row = [1 2];
    refreshButton.Layout.Column = 4;

    statsLabel = uilabel(sg, ...
        'Text', 'Load audio using the main toolbar.', ...
        'FontSize', 9, ...
        'FontColor', textMuted, ...
        'BackgroundColor', panelBg);

    statsLabel.Layout.Row = 2;
    statsLabel.Layout.Column = [1 3];

    %% FULL SPECTRUM AXIS

    fullAx = createAxes(root, 2, [1 2], ...
        'Full Frequency Spectrum');

    %% LOW FREQUENCY AXIS

    lowAx = createAxes(root, 3, 1, ...
        'Low Frequency Spectrum (20-2000 Hz)');

    %% PEAK TABLE

    peakPanel = uipanel(root, ...
        'Title', '  DETECTED FREQUENCY PEAKS', ...
        'FontSize', 9, ...
        'FontWeight', 'bold', ...
        'ForegroundColor', [0.55 0.72 0.85], ...
        'BackgroundColor', panelBg, ...
        'BorderColor', [0.16 0.23 0.31]);

    peakPanel.Layout.Row = 3;
    peakPanel.Layout.Column = 2;

    peakGrid = uigridlayout(peakPanel, [1 1]);

    peakGrid.Padding = [8 8 8 8];
    peakGrid.BackgroundColor = panelBg;

    peakTable = uitable(peakGrid);

    peakTable.ColumnName = {'No.', 'Frequency (Hz)', 'Magnitude'};
    peakTable.ColumnWidth = {45, 110, '1x'};

    peakTable.RowName = {};

    peakTable.Data = cell(0, 3);

    peakTable.BackgroundColor = [axisBg; panelBg];

    %% EMPTY STATE

    showEmptyState();

    %% RETURN REFRESH FUNCTION

    refreshFFT = @refresh;

    %% AXIS CREATION

    function ax = createAxes(parentGrid, row, col, plotTitle)

        ax = uiaxes(parentGrid);

        ax.Layout.Row = row;
        ax.Layout.Column = col;

        ax.Color = axisBg;

        ax.XColor = [0.72 0.81 0.89];
        ax.YColor = [0.72 0.81 0.89];

        ax.GridColor = [0.30 0.39 0.49];

        ax.FontSize = 9;

        grid(ax, 'on');

        title(ax, plotTitle, ...
            'Color', textMain, ...
            'FontWeight', 'bold');

        xlabel(ax, 'Frequency (Hz)');
        ylabel(ax, 'Magnitude');

    end

    %% EMPTY STATE

    function showEmptyState()

        cla(fullAx);
        cla(lowAx);

        text(fullAx, 0.5, 0.5, ...
            'Load an audio file to begin FFT analysis', ...
            'Units', 'normalized', ...
            'HorizontalAlignment', 'center', ...
            'Color', textMuted);

        text(lowAx, 0.5, 0.5, ...
            'Low frequency spectrum will appear here', ...
            'Units', 'normalized', ...
            'HorizontalAlignment', 'center', ...
            'Color', textMuted);

        title(fullAx, 'Full Frequency Spectrum');
        title(lowAx, 'Low Frequency Spectrum (20-2000 Hz)');

        xlabel(fullAx, 'Frequency (Hz)');
        ylabel(fullAx, 'Magnitude');

        xlabel(lowAx, 'Frequency (Hz)');
        ylabel(lowAx, 'Magnitude');

        fileLabel.Text = 'No audio loaded';

        statsLabel.Text = 'Load audio using the main toolbar.';

        peakTable.Data = cell(0, 3);

    end

    %% REFRESH FFT ANALYSIS

    function refresh()

        if ~isvalid(parent)
            return;
        end

        [x, Fs, fileName] = getAudioFcn();

        if isempty(x) || isempty(Fs) || ...
                ~isnumeric(x) || ~isreal(x) || ...
                ~isfinite(Fs) || Fs <= 0 || ...
                any(~isfinite(x(:)))

            showEmptyState();
            return;

        end

        %% CONVERT STEREO TO MONO

        if size(x, 2) > 1
            xMono = mean(x, 2);
        else
            xMono = x;
        end

        N = length(xMono);

        if N < 1
            showEmptyState();
            return;
        end

        %% SIGNAL INFORMATION

        frequencyResolution = Fs / N;

        %% APPLY HANN WINDOW

        n = (0:N-1)';

        if N > 1

            window = 0.5 - 0.5*cos(2*pi*n/(N-1));

        else

            window = 1;

        end

        windowedSignal = xMono .* window;

        %% CALCULATE FFT

        Y = fft(windowedSignal);

        P2 = abs(Y) / sum(window);

        P1 = P2(1:floor(N/2)+1);

        %% SINGLE-SIDED AMPLITUDE SPECTRUM

        if rem(N, 2) == 0

            if numel(P1) > 2
                P1(2:end-1) = 2 * P1(2:end-1);
            end

        else

            if numel(P1) > 1
                P1(2:end) = 2 * P1(2:end);
            end

        end

        f = Fs*(0:floor(N/2))'/N;

        %% DOMINANT FREQUENCY

        if numel(P1) > 1

            [dominantMagnitude, index] = max(P1(2:end));

            dominantFrequency = f(index+1);

        else

            dominantFrequency = 0;
            dominantMagnitude = 0;

        end

        %% DETECT PROMINENT FREQUENCY PEAKS

        if numel(P1) >= 3

            localMaxima = ...
                P1(2:end-1) > P1(1:end-2) & ...
                P1(2:end-1) >= P1(3:end);

            candidateIndices = find(localMaxima) + 1;

            candidateIndices = candidateIndices( ...
                f(candidateIndices) >= 20);

        else

            candidateIndices = [];

        end

        %% SORT PEAKS BY MAGNITUDE

        [~, order] = sort( ...
            P1(candidateIndices), 'descend');

        candidateIndices = candidateIndices(order);

        %% SELECT UP TO 10 PEAKS
        % Maintain at least 10 Hz separation.

        selectedIndices = [];

        for k = 1:numel(candidateIndices)

            currentIndex = candidateIndices(k);

            if isempty(selectedIndices) || ...
                    all(abs(f(currentIndex) - ...
                    f(selectedIndices)) >= 10)

                selectedIndices(end+1) = currentIndex; %#ok<AGROW>

            end

            if numel(selectedIndices) == 10
                break;
            end

        end

        %% UPDATE FULL SPECTRUM

        cla(fullAx);

        % Limit displayed points for smoother GUI rendering.
        % Calculations above still use the complete FFT.

        displayStep = max(1, ceil(numel(f)/200000));

        displayIndices = 1:displayStep:numel(f);

        plot(fullAx, ...
            f(displayIndices), ...
            P1(displayIndices), ...
            'Color', blue, ...
            'LineWidth', 0.8);

        title(fullAx, 'Full Frequency Spectrum');

        xlabel(fullAx, 'Frequency (Hz)');
        ylabel(fullAx, 'Magnitude');

        xlim(fullAx, [0 Fs/2]);

        %% UPDATE LOW FREQUENCY SPECTRUM

        cla(lowAx);

        lowLimit = min(2000, Fs/2);

        lowIndices = find(f >= 20 & f <= lowLimit);

        if ~isempty(lowIndices)

            plot(lowAx, ...
                f(lowIndices), ...
                P1(lowIndices), ...
                'Color', orange, ...
                'LineWidth', 0.9);

            hold(lowAx, 'on');

            % Mark selected peaks within the low-frequency range.
            if ~isempty(selectedIndices)

                lowPeakIndices = selectedIndices( ...
                    f(selectedIndices) <= lowLimit);

                if ~isempty(lowPeakIndices)

                    plot(lowAx, ...
                        f(lowPeakIndices), ...
                        P1(lowPeakIndices), ...
                        'ro', ...
                        'MarkerSize', 5, ...
                        'LineWidth', 1.1);

                end

            end

            hold(lowAx, 'off');

        else

            text(lowAx, 0.5, 0.5, ...
                'No frequency bins in the 20 Hz to 2000 Hz range', ...
                'Units', 'normalized', ...
                'HorizontalAlignment', 'center', ...
                'Color', textMuted);

        end

        title(lowAx, 'Low Frequency Spectrum (20-2000 Hz)');

        xlabel(lowAx, 'Frequency (Hz)');
        ylabel(lowAx, 'Magnitude');

        if lowLimit > 20
            xlim(lowAx, [20 lowLimit]);
        end

        %% UPDATE PEAK TABLE

        peakData = cell(numel(selectedIndices), 3);

        for k = 1:numel(selectedIndices)

            idx = selectedIndices(k);

            peakData{k, 1} = k;
            peakData{k, 2} = f(idx);
            peakData{k, 3} = P1(idx);

        end

        peakTable.Data = peakData;

        %% UPDATE SUMMARY

        [~, shortName, ext] = fileparts(fileName);

        if isempty(shortName)
            displayName = 'Loaded audio';
        else
            displayName = [shortName ext];
        end

        fileLabel.Text = displayName;

        statsLabel.Text = sprintf( ...
            ['Fs: %g Hz | Samples: %d | Channels: %d | ' ...
             'Resolution: %.4f Hz | Dominant: %.2f Hz | ' ...
             'Magnitude: %.6f'], ...
            Fs, N, size(x,2), ...
            frequencyResolution, ...
            dominantFrequency, dominantMagnitude);

    end

end
