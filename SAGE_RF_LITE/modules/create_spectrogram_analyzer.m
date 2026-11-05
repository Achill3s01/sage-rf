function refreshSpectrogram = create_spectrogram_analyzer(parent, getAudioFcn)
% CREATE_SPECTROGRAM_ANALYZER
% Embedded STFT spectrogram analyzer for SAGE-RF Lite.

    %% UI COLORS
    bgColor = [0.075 0.09 0.12];
    panelColor = [0.11 0.13 0.17];
    textColor = [0.90 0.92 0.96];
    mutedColor = [0.60 0.65 0.72];

    %% CLEAR PARENT
    delete(parent.Children);
    parent.BackgroundColor = bgColor;

    %% HEADER
    header = uilabel(parent);
    header.Text = 'SPECTROGRAM ANALYZER';
    header.FontSize = 20;
    header.FontWeight = 'bold';
    header.FontColor = textColor;
    header.Position = [25 650 500 35];

    subtitle = uilabel(parent);
    subtitle.Text = 'Short-Time Fourier Transform (STFT) | Time-Frequency Analysis';
    subtitle.FontSize = 11;
    subtitle.FontColor = mutedColor;
    subtitle.Position = [25 625 650 22];

    %% INFORMATION PANEL
    infoPanel = uipanel(parent);
    infoPanel.Title = 'ANALYSIS INFORMATION';
    infoPanel.BackgroundColor = panelColor;
    infoPanel.ForegroundColor = textColor;
    infoPanel.Position = [25 550 250 60];

    infoLabel = uilabel(infoPanel);
    infoLabel.Text = 'Load an audio file to begin analysis.';
    infoLabel.FontColor = mutedColor;
    infoLabel.FontSize = 11;
    infoLabel.Position = [12 8 225 25];

    %% DISPLAY OPTIONS
    optionsPanel = uipanel(parent);
    optionsPanel.Title = 'DISPLAY OPTIONS';
    optionsPanel.BackgroundColor = panelColor;
    optionsPanel.ForegroundColor = textColor;
    optionsPanel.Position = [290 550 300 60];

    freqLabel = uilabel(optionsPanel);
    freqLabel.Text = 'Frequency range:';
    freqLabel.FontColor = textColor;
    freqLabel.Position = [12 10 105 22];

    freqDropdown = uidropdown(optionsPanel);
    freqDropdown.Items = {'Auto (up to 10 kHz)', 'Full band'};
    freqDropdown.Value = 'Auto (up to 10 kHz)';
    freqDropdown.Position = [125 10 155 25];
    freqDropdown.ValueChangedFcn = @(~,~) refreshDisplay();

    %% SPECTROGRAM AXES
    ax = uiaxes(parent);
    ax.Position = [25 65 900 465];
    ax.BackgroundColor = bgColor;
    ax.XColor = textColor;
    ax.YColor = textColor;
    ax.GridColor = mutedColor;

    xlabel(ax, 'Time (seconds)', 'Color', textColor);
    ylabel(ax, 'Frequency (Hz)', 'Color', textColor);
    title(ax, 'Audio Spectrogram - STFT', ...
        'Color', textColor, 'FontSize', 15);

    grid(ax, 'on');

    %% INITIAL MESSAGE
    showMessage('Load an audio file to view its spectrogram.');

    %% REFRESH CALLBACK
    refreshSpectrogram = @refreshDisplay;

    %% INITIAL REFRESH
    refreshDisplay();

    %% REFRESH SPECTROGRAM
    function refreshDisplay()

        cla(ax);

        [x, Fs, fileName] = getAudioFcn();

        if isempty(x) || isempty(Fs)
            infoLabel.Text = 'No audio loaded.';
            showMessage('Load an audio file to view its spectrogram.');
            return;
        end

        if ~isnumeric(x) || ~isscalar(Fs) || ...
                ~isfinite(Fs) || Fs <= 0
            infoLabel.Text = 'Invalid audio data.';
            showMessage('The audio data or sampling rate is invalid.');
            return;
        end

        %% CONVERT STEREO TO MONO
        if size(x, 2) > 1
            x = mean(x, 2);
        end

        x = double(x(:));
        N = length(x);

        if N == 0 || any(~isfinite(x))
            infoLabel.Text = 'Invalid or empty audio.';
            showMessage('The audio signal is empty or contains invalid values.');
            return;
        end

        %% STFT CONFIGURATION
        frameLength = min(2048, N);
        hopLength = max(1, floor(frameLength / 4));
        nfft = 2^nextpow2(frameLength);

        %% HANN WINDOW
        n = (0:frameLength-1)';

        if frameLength > 1
            window = 0.5 - 0.5*cos(2*pi*n/(frameLength-1));
        else
            window = 1;
        end

        windowSum = sum(window);

        if windowSum <= eps
            window = ones(frameLength, 1);
            windowSum = sum(window);
        end

        %% DIVIDE SIGNAL INTO FRAMES
        frameStarts = 1:hopLength:(N-frameLength+1);
        numFrames = length(frameStarts);

        if numFrames == 0
            infoLabel.Text = 'Unable to create analysis frames.';
            showMessage('Not enough samples to calculate the spectrogram.');
            return;
        end

        %% CALCULATE STFT
        S = zeros(nfft/2+1, numFrames);

        for k = 1:numFrames

            startIndex = frameStarts(k);

            frame = x(startIndex:startIndex+frameLength-1);

            frame = frame .* window;

            Y = fft(frame, nfft);

            magnitude = abs(Y(1:nfft/2+1)) / windowSum;

            if rem(nfft, 2) == 0 && nfft > 1
                magnitude(2:end-1) = 2*magnitude(2:end-1);
            elseif nfft > 1
                magnitude(2:end) = 2*magnitude(2:end);
            end

            S(:, k) = magnitude;

        end

        %% CONVERT TO DECIBELS
        S_dB = 20*log10(max(S, 1e-8));

        %% TIME AND FREQUENCY AXES
        frequencies = (0:nfft/2) * Fs/nfft;
        times = (frameStarts + (frameLength-1)/2) / Fs;

        duration = N/Fs;

        %% FREQUENCY DISPLAY RANGE
        if strcmp(freqDropdown.Value, 'Full band')
            maxFrequency = Fs/2;
        else
            maxFrequency = min(10000, Fs/2);
        end

        %% PLOT SPECTROGRAM
        imagesc(ax, times, frequencies, S_dB);

        axis(ax, 'xy');

        xlim(ax, [0 max(duration, 1/Fs)]);
        ylim(ax, [0 maxFrequency]);

        xlabel(ax, 'Time (seconds)', 'Color', textColor);
        ylabel(ax, 'Frequency (Hz)', 'Color', textColor);

        title(ax, 'Audio Spectrogram - STFT', ...
            'Color', textColor, 'FontSize', 15);

        colormap(ax, parula);
        colorbar(ax);

        %% DECIBEL DISPLAY RANGE
        maxLevel = max(S_dB(:));

        if isfinite(maxLevel)
            clim(ax, [maxLevel-80 maxLevel]);
        end

        %% UPDATE INFORMATION
        if isempty(fileName)
            fileName = 'Loaded audio';
        end

        infoLabel.Text = sprintf( ...
            '%s | Fs: %g Hz | Duration: %.2f s | Frames: %d', ...
            fileName, Fs, duration, numFrames);

    end

    %% DISPLAY MESSAGE
    function showMessage(message)

        cla(ax);

        text(ax, 0.5, 0.5, message, ...
            'Units', 'normalized', ...
            'HorizontalAlignment', 'center', ...
            'VerticalAlignment', 'middle', ...
            'Color', mutedColor, ...
            'FontSize', 13);

        ax.XLim = [0 1];
        ax.YLim = [0 1];

    end

end