
function refreshViewer = create_signal_viewer(parent, getAudioFcn)
% CREATE_SIGNAL_VIEWER
% Embedded Signal Viewer for SAGE-RF Lite.
%
% parent      : Panel inside the main application
% getAudioFcn : Returns [audio, sampleRate, fileName]
%
% refreshViewer() updates the viewer using shared application audio.

    bg = [0.055 0.075 0.105];
    panelBg = [0.085 0.12 0.17];
    textMain = [0.91 0.95 0.98];
    textMuted = [0.62 0.73 0.83];
    accent = [0.28 0.72 0.96];

    root = uigridlayout(parent, [3 2]);
    root.RowHeight = {78, '1x', '1x'};
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
    sg.RowHeight = {28, 24};
    sg.ColumnWidth = {'1x', '1x', '1x', 110};
    sg.Padding = [14 8 12 8];
    sg.RowSpacing = 2;
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

    playButton = uibutton(sg, 'push', ...
        'Text', 'Play Audio', ...
        'FontSize', 10, ...
        'FontWeight', 'bold', ...
        'FontColor', [1 1 1], ...
        'BackgroundColor', [0.08 0.43 0.68], ...
        'ButtonPushedFcn', @(src,event) playAudio());

    playButton.Layout.Row = [1 2];
    playButton.Layout.Column = 4;

    statsLabel = uilabel(sg, ...
        'Text', 'Load audio using the toolbar to inspect the signal.', ...
        'FontSize', 9, ...
        'FontColor', textMuted, ...
        'BackgroundColor', panelBg);

    statsLabel.Layout.Row = 2;
    statsLabel.Layout.Column = [1 3];

    %% PLOT AXES

    fullAx = makeAxes(root, 2, 1, ...
        'Full Time-Domain Waveform');

    zoomAx = makeAxes(root, 2, 2, ...
        'Zoomed Waveform - First 0.5 Seconds');

    spectrumAx = makeAxes(root, 3, [1 2], ...
        'Single-Sided Amplitude Spectrum');

    showEmptyState();

    % Return refresh function to main.m
    refreshViewer = @refresh;

    %% AXES CREATION

    function ax = makeAxes(parentGrid, row, col, plotTitle)

        ax = uiaxes(parentGrid);

        ax.Layout.Row = row;
        ax.Layout.Column = col;

        ax.Color = [0.035 0.05 0.075];
        ax.XColor = [0.72 0.81 0.89];
        ax.YColor = [0.72 0.81 0.89];

        ax.GridColor = [0.30 0.39 0.49];
        ax.MinorGridColor = [0.20 0.29 0.39];

        ax.FontSize = 9;

        grid(ax, 'on');

        title(ax, plotTitle, ...
            'Color', textMain, ...
            'FontWeight', 'bold');

        xlabel(ax, 'Time (seconds)');
        ylabel(ax, 'Amplitude');

    end

    %% EMPTY STATE

    function showEmptyState()

        cla(fullAx);
        cla(zoomAx);
        cla(spectrumAx);

        text(fullAx, 0.5, 0.5, ...
            'Load an audio file to begin', ...
            'Units', 'normalized', ...
            'HorizontalAlignment', 'center', ...
            'Color', textMuted);

        text(zoomAx, 0.5, 0.5, ...
            'First 0.5 seconds', ...
            'Units', 'normalized', ...
            'HorizontalAlignment', 'center', ...
            'Color', textMuted);

        text(spectrumAx, 0.5, 0.5, ...
            'Frequency spectrum will appear here', ...
            'Units', 'normalized', ...
            'HorizontalAlignment', 'center', ...
            'Color', textMuted);

        xlabel(fullAx, 'Time (seconds)');
        ylabel(fullAx, 'Amplitude');

        xlabel(zoomAx, 'Time (seconds)');
        ylabel(zoomAx, 'Amplitude');

        xlabel(spectrumAx, 'Frequency (Hz)');
        ylabel(spectrumAx, 'Magnitude');

        title(fullAx, 'Full Time-Domain Waveform');
        title(zoomAx, 'Zoomed Waveform');
        title(spectrumAx, 'Single-Sided Amplitude Spectrum');

        fileLabel.Text = 'No audio loaded';

        statsLabel.Text = ...
            'Load audio using the toolbar to inspect the signal.';

        playButton.Enable = 'off';

    end

    %% REFRESH VIEWER

    function refresh()

        if ~isvalid(parent)
            return;
        end

        [x, Fs, fileName] = getAudioFcn();

        if isempty(x) || isempty(Fs) || ~isfinite(Fs) || Fs <= 0
            showEmptyState();
            return;
        end

        if ~isnumeric(x) || ~isreal(x) || any(~isfinite(x(:)))

            showEmptyState();

            statsLabel.Text = ...
                'Audio data is invalid or contains non-finite values.';

            return;
        end

        % Convert multichannel audio to mono for analysis.
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

        duration = N / Fs;

        t = (0:N-1)' / Fs;

        %% SIGNAL MEASUREMENTS

        peakAmplitude = max(abs(xMono));

        rmsAmplitude = sqrt(mean(xMono.^2));

        %% FULL WAVEFORM

        cla(fullAx);

        plot(fullAx, t, xMono, ...
            'Color', accent, ...
            'LineWidth', 0.8);

        title(fullAx, 'Full Time-Domain Waveform');

        xlabel(fullAx, 'Time (seconds)');
        ylabel(fullAx, 'Amplitude');

        xlim(fullAx, [0 max(duration, 1/Fs)]);

        %% ZOOMED WAVEFORM

        zoomDuration = min(0.5, duration);

        zoomSamples = max(1, min(N, ...
            floor(zoomDuration * Fs)));

        zoomSignal = xMono(1:zoomSamples);

        zoomTime = t(1:zoomSamples);

        cla(zoomAx);

        plot(zoomAx, zoomTime, zoomSignal, ...
            'Color', [0.20 0.82 0.67], ...
            'LineWidth', 0.9);

        title(zoomAx, ...
            'Zoomed Waveform - First 0.5 Seconds');

        xlabel(zoomAx, 'Time (seconds)');
        ylabel(zoomAx, 'Amplitude');

        xlim(zoomAx, [0 max(zoomDuration, 1/Fs)]);

        %% FFT ANALYSIS

        Y = fft(xMono);

        P2 = abs(Y / N);

        P1 = P2(1:floor(N/2)+1);

        if rem(N, 2) == 0

            if numel(P1) > 2
                P1(2:end-1) = 2 * P1(2:end-1);
            end

        elseif numel(P1) > 1

            P1(2:end) = 2 * P1(2:end);

        end

        f = Fs * (0:floor(N/2))' / N;

        %% DOMINANT FREQUENCY

        if numel(P1) > 1

            [~, peakIndex] = max(P1(2:end));

            dominantFrequency = f(peakIndex + 1);

        else

            dominantFrequency = 0;

        end

        %% FREQUENCY SPECTRUM

        cla(spectrumAx);

        plot(spectrumAx, f, P1, ...
            'Color', [0.95 0.66 0.28], ...
            'LineWidth', 0.9);

        title(spectrumAx, ...
            'Single-Sided Amplitude Spectrum');

        xlabel(spectrumAx, 'Frequency (Hz)');
        ylabel(spectrumAx, 'Magnitude');

        xlim(spectrumAx, [0 Fs/2]);

        %% ZOOM DIAGNOSTICS

        zoomMin = min(zoomSignal);

        zoomMax = max(zoomSignal);

        zoomPeak = max(abs(zoomSignal));

        %% UPDATE INFORMATION

        [~, shortName, ext] = fileparts(fileName);

        if isempty(shortName)
            displayName = 'Loaded audio';
        else
            displayName = [shortName ext];
        end

        fileLabel.Text = displayName;

        statsLabel.Text = sprintf( ...
            ['Fs: %g Hz | Duration: %.2f s | Samples: %d | ' ...
             'Channels: %d | Peak: %.4f | RMS: %.4f | ' ...
             'Dominant: %.2f Hz | Zoom min/max/peak: %.4f / %.4f / %.4f'], ...
            Fs, duration, N, size(x,2), ...
            peakAmplitude, rmsAmplitude, ...
            dominantFrequency, zoomMin, zoomMax, zoomPeak);

        playButton.Enable = 'on';

    end

    %% PLAYBACK

    function playAudio()

        [x, Fs] = getAudioFcn();

        if isempty(x) || isempty(Fs)
            return;
        end

        try

            sound(x, Fs);

        catch ME

            uialert(ancestor(parent, 'figure'), ...
                ME.message, ...
                'Playback Error', ...
                'Icon', 'error');

        end

    end

end
