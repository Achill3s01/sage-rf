function speech_enhancement()
% SAGE-RF Lite
% Module 5: Speech Enhancement
%
% Algorithm:
%   1. Short-Time Fourier Transform (STFT)
%   2. Noise spectrum estimation from a user-selected noise-only interval
%   3. Spectral subtraction
%   4. Spectral flooring
%   5. Inverse STFT using overlap-add reconstruction
%
% Dependencies:
%   MATLAB base functions only.
%   No Signal Processing Toolbox required.

    %% APPLICATION STATE

    audioData = [];
    enhancedData = [];
    Fs = [];
    audioFile = '';

    %% GUI

    fig = uifigure( ...
        'Name', 'SAGE-RF Lite | Speech Enhancement', ...
        'Position', [80 40 1320 850], ...
        'Color', [0.95 0.96 0.98]);

    mainPanel = uipanel(fig, ...
        'Title', 'Speech Enhancement Controls', ...
        'Position', [15 15 310 790], ...
        'BackgroundColor', [0.98 0.98 0.99]);

    % ---------------------------------------------------------
    % TITLE
    % ---------------------------------------------------------

    uilabel(mainPanel, ...
        'Text', 'SAGE-RF Lite', ...
        'Position', [20 735 260 30], ...
        'FontSize', 22, ...
        'FontWeight', 'bold');

    uilabel(mainPanel, ...
        'Text', 'Spectral Subtraction', ...
        'Position', [20 710 260 22], ...
        'FontSize', 13, ...
        'FontColor', [0.25 0.35 0.50]);

    % ---------------------------------------------------------
    % AUDIO INPUT
    % ---------------------------------------------------------

    uilabel(mainPanel, ...
        'Text', '1. AUDIO INPUT', ...
        'Position', [20 665 260 22], ...
        'FontWeight', 'bold');

    uibutton(mainPanel, 'push', ...
        'Text', 'Load Noisy Audio', ...
        'Position', [20 625 260 32], ...
        'ButtonPushedFcn', @loadAudio);

    fileLabel = uilabel(mainPanel, ...
        'Text', 'No audio loaded', ...
        'Position', [20 590 260 28], ...
        'FontSize', 10, ...
        'WordWrap', 'on');

    infoLabel = uilabel(mainPanel, ...
        'Text', 'Sampling rate: --', ...
        'Position', [20 555 260 28], ...
        'FontSize', 10);

    % ---------------------------------------------------------
    % NOISE ESTIMATION
    % ---------------------------------------------------------

    uilabel(mainPanel, ...
        'Text', '2. NOISE ESTIMATION', ...
        'Position', [20 510 260 22], ...
        'FontWeight', 'bold');

    uilabel(mainPanel, ...
        'Text', 'Noise segment start (seconds)', ...
        'Position', [20 478 260 20], ...
        'FontSize', 11);

    noiseStartField = uieditfield(mainPanel, 'numeric', ...
        'Position', [20 450 260 28], ...
        'Value', 0, ...
        'Limits', [0 Inf]);

    uilabel(mainPanel, ...
        'Text', 'Noise segment end (seconds)', ...
        'Position', [20 415 260 20], ...
        'FontSize', 11);

    noiseEndField = uieditfield(mainPanel, 'numeric', ...
        'Position', [20 387 260 28], ...
        'Value', 0.5, ...
        'Limits', [0 Inf]);

    uilabel(mainPanel, ...
        'Text', ['Select a region containing background noise ' ...
                 'but no speech.'], ...
        'Position', [20 350 260 34], ...
        'FontSize', 10, ...
        'FontColor', [0.65 0.25 0.15], ...
        'WordWrap', 'on');

    % ---------------------------------------------------------
    % ENHANCEMENT PARAMETERS
    % ---------------------------------------------------------

    uilabel(mainPanel, ...
        'Text', '3. ENHANCEMENT PARAMETERS', ...
        'Position', [20 305 260 22], ...
        'FontWeight', 'bold');

    uilabel(mainPanel, ...
        'Text', 'Noise reduction strength', ...
        'Position', [20 273 260 20], ...
        'FontSize', 11);

    strengthField = uieditfield(mainPanel, 'numeric', ...
        'Position', [20 245 260 28], ...
        'Value', 1.5, ...
        'Limits', [0.5 4]);

    uilabel(mainPanel, ...
        'Text', 'Spectral floor (0 to 0.5)', ...
        'Position', [20 210 260 20], ...
        'FontSize', 11);

    floorField = uieditfield(mainPanel, 'numeric', ...
        'Position', [20 182 260 28], ...
        'Value', 0.02, ...
        'Limits', [0 0.5]);

    uilabel(mainPanel, ...
        'Text', 'Frame length', ...
        'Position', [20 147 120 20], ...
        'FontSize', 11);

    frameDropdown = uidropdown(mainPanel, ...
        'Items', {'512', '1024', '2048', '4096'}, ...
        'Value', '1024', ...
        'Position', [150 145 130 26]);

    uilabel(mainPanel, ...
        'Text', 'Overlap', ...
        'Position', [20 110 120 20], ...
        'FontSize', 11);

    overlapDropdown = uidropdown(mainPanel, ...
        'Items', {'50', '75'}, ...
        'Value', '75', ...
        'Position', [150 108 130 26]);

    % ---------------------------------------------------------
    % ACTION BUTTONS
    % ---------------------------------------------------------

    processButton = uibutton(mainPanel, 'push', ...
        'Text', 'Apply Noise Reduction', ...
        'Position', [20 58 260 36], ...
        'FontWeight', 'bold', ...
        'BackgroundColor', [0.18 0.42 0.70], ...
        'FontColor', [1 1 1], ...
        'ButtonPushedFcn', @processAudio);

    % ---------------------------------------------------------
    % RESULTS AND PLAYBACK
    % ---------------------------------------------------------

    uilabel(mainPanel, ...
        'Text', '4. OUTPUT', ...
        'Position', [20 17 100 20], ...
        'FontWeight', 'bold');

    uibutton(mainPanel, 'push', ...
        'Text', 'Play Original', ...
        'Position', [115 12 80 28], ...
        'FontSize', 9, ...
        'ButtonPushedFcn', @playOriginal);

    uibutton(mainPanel, 'push', ...
        'Text', 'Play Enhanced', ...
        'Position', [200 12 90 28], ...
        'FontSize', 9, ...
        'ButtonPushedFcn', @playEnhanced);

    % ---------------------------------------------------------
    % VISUALIZATION AREA
    % ---------------------------------------------------------

    axOriginalWave = uiaxes(fig, ...
        'Position', [350 435 455 345]);

    title(axOriginalWave, 'Original Audio');
    xlabel(axOriginalWave, 'Time (s)');
    ylabel(axOriginalWave, 'Amplitude');
    grid(axOriginalWave, 'on');

    axEnhancedWave = uiaxes(fig, ...
        'Position', [835 435 455 345]);

    title(axEnhancedWave, 'Enhanced Audio');
    xlabel(axEnhancedWave, 'Time (s)');
    ylabel(axEnhancedWave, 'Amplitude');
    grid(axEnhancedWave, 'on');

    axOriginalSpec = uiaxes(fig, ...
        'Position', [350 55 455 335]);

    title(axOriginalSpec, 'Original Spectrogram');
    xlabel(axOriginalSpec, 'Time (s)');
    ylabel(axOriginalSpec, 'Frequency (Hz)');

    axEnhancedSpec = uiaxes(fig, ...
        'Position', [835 55 455 335]);

    title(axEnhancedSpec, 'Enhanced Spectrogram');
    xlabel(axEnhancedSpec, 'Time (s)');
    ylabel(axEnhancedSpec, 'Frequency (Hz)');

    % ---------------------------------------------------------
    % STATUS / STATISTICS
    % ---------------------------------------------------------

    statusLabel = uilabel(fig, ...
        'Text', 'Load an audio file to begin.', ...
        'Position', [350 795 940 20], ...
        'FontSize', 11, ...
        'FontWeight', 'bold');

    statsLabel = uilabel(fig, ...
        'Text', 'Processing statistics will appear here.', ...
        'Position', [350 15 940 25], ...
        'FontSize', 10);

    uibutton(fig, 'push', ...
        'Text', 'Export Enhanced WAV', ...
        'Position', [1130 795 160 28], ...
        'ButtonPushedFcn', @saveEnhanced);

    %% CALLBACK: LOAD AUDIO

    function loadAudio(~, ~)

        [file, path] = uigetfile( ...
            {'*.wav', 'WAV Audio Files (*.wav)'}, ...
            'Select Noisy Audio');

        if isequal(file, 0)
            return;
        end

        try
            [newAudio, newFs] = audioread(fullfile(path, file));

            if isempty(newAudio) || isempty(newFs) || ...
                    any(isnan(newAudio(:))) || ...
                    any(isinf(newAudio(:))) || ...
                    isnan(newFs) || isinf(newFs) || newFs <= 0

                error('The selected audio contains invalid data.');
            end

            audioData = newAudio;
            Fs = newFs;
            audioFile = file;
            enhancedData = [];

            duration = size(audioData, 1) / Fs;
            channels = size(audioData, 2);

            noiseStartField.Value = 0;
            noiseEndField.Value = min(0.5, duration);

            fileLabel.Text = file;

            infoLabel.Text = sprintf( ...
                'Fs: %.0f Hz | Duration: %.2f s | Channels: %d', ...
                Fs, duration, channels);

            statusLabel.Text = 'Audio loaded successfully.';

            plotWaveform(axOriginalWave, audioData(:, 1), Fs, ...
                'Original Audio');

            cla(axEnhancedWave);
            cla(axEnhancedSpec);

            L = str2double(frameDropdown.Value);
            overlap = str2double(overlapDropdown.Value) / 100;
            hop = max(1, round(L * (1 - overlap)));

            drawSpectrogram(axOriginalSpec, ...
                audioData(:, 1), Fs, L, hop, 'Original Spectrogram');

            statsLabel.Text = 'Ready for noise reduction.';

        catch ME
            uialert(fig, ME.message, 'Audio Loading Error');
        end
    end

    %% CALLBACK: PROCESS AUDIO

    function processAudio(~, ~)

        if isempty(audioData)
            uialert(fig, 'Load an audio file first.', 'No Audio');
            return;
        end

        duration = size(audioData, 1) / Fs;

        noiseStart = noiseStartField.Value;
        noiseEnd = noiseEndField.Value;

        alpha = strengthField.Value;
        beta = floorField.Value;

        L = str2double(frameDropdown.Value);
        overlap = str2double(overlapDropdown.Value) / 100;
        hop = max(1, round(L * (1 - overlap)));

        % Validate noise interval.

        if isnan(noiseStart) || isnan(noiseEnd) || ...
                isinf(noiseStart) || isinf(noiseEnd) || ...
                noiseStart < 0 || noiseEnd <= noiseStart || ...
                noiseEnd > duration

            uialert(fig, ...
                'Choose a valid noise interval within the audio duration.', ...
                'Invalid Noise Interval');
            return;
        end

        if alpha < 0.5 || alpha > 4 || ...
                beta < 0 || beta > 0.5

            uialert(fig, ...
                'Check the noise reduction strength and spectral floor.', ...
                'Invalid Parameters');
            return;
        end

        processButton.Enable = 'off';
        statusLabel.Text = 'Estimating noise and processing audio...';
        drawnow;

        try
            tic;

            [enhancedData, noiseFrames] = spectralSubtraction( ...
                audioData, Fs, noiseStart, noiseEnd, ...
                alpha, beta, L, hop);

            processingTime = toc;

            originalRMS = sqrt(mean(audioData(:).^2));
            enhancedRMS = sqrt(mean(enhancedData(:).^2));

            if enhancedRMS > 0
                rmsChange = 20 * log10(originalRMS / enhancedRMS);
            else
                rmsChange = Inf;
            end

            plotWaveform(axOriginalWave, audioData(:, 1), Fs, ...
                'Original Audio');

            plotWaveform(axEnhancedWave, enhancedData(:, 1), Fs, ...
                'Enhanced Audio');

            drawSpectrogram(axOriginalSpec, ...
                audioData(:, 1), Fs, L, hop, ...
                'Original Spectrogram');

            drawSpectrogram(axEnhancedSpec, ...
                enhancedData(:, 1), Fs, L, hop, ...
                'Enhanced Spectrogram');

            statsLabel.Text = sprintf( ...
                'Original RMS: %.5f | Enhanced RMS: %.5f | RMS change: %.2f dB | Noise frames: %d | Processing: %.2f s', ...
                originalRMS, enhancedRMS, rmsChange, ...
                noiseFrames, processingTime);

            statusLabel.Text = 'Noise reduction completed.';

            fprintf('\n');
            fprintf('============================================\n');
            fprintf('       SAGE-RF LITE | SPEECH ENHANCEMENT\n');
            fprintf('============================================\n');
            fprintf('File: %s\n', audioFile);
            fprintf('Sampling Frequency: %.0f Hz\n', Fs);
            fprintf('Noise Interval: %.3f - %.3f seconds\n', ...
                noiseStart, noiseEnd);
            fprintf('Algorithm: Spectral Subtraction\n');
            fprintf('Frame Length: %d\n', L);
            fprintf('Hop Length: %d\n', hop);
            fprintf('Reduction Strength: %.2f\n', alpha);
            fprintf('Spectral Floor: %.3f\n', beta);
            fprintf('Noise Frames: %d\n', noiseFrames);
            fprintf('Original RMS: %.6f\n', originalRMS);
            fprintf('Enhanced RMS: %.6f\n', enhancedRMS);
            fprintf('RMS Change: %.3f dB\n', rmsChange);
            fprintf('Processing Time: %.3f seconds\n', ...
                processingTime);
            fprintf('============================================\n');

        catch ME
            enhancedData = [];
            statusLabel.Text = 'Processing failed.';
            uialert(fig, ME.message, 'Processing Error');
        end

        processButton.Enable = 'on';
    end

    %% CALLBACK: PLAY ORIGINAL

    function playOriginal(~, ~)

        if isempty(audioData)
            uialert(fig, 'Load an audio file first.', 'No Audio');
            return;
        end

        sound(audioData, Fs);
    end

    %% CALLBACK: PLAY ENHANCED

    function playEnhanced(~, ~)

        if isempty(enhancedData)
            uialert(fig, ...
                'Apply noise reduction before playing enhanced audio.', ...
                'No Enhanced Audio');
            return;
        end

        sound(enhancedData, Fs);
    end

    %% CALLBACK: EXPORT

    function saveEnhanced(~, ~)

        if isempty(enhancedData)
            uialert(fig, ...
                'Process an audio file before exporting.', ...
                'No Enhanced Audio');
            return;
        end

        [file, path] = uiputfile( ...
            {'*.wav', 'WAV Audio Files (*.wav)'}, ...
            'Export Enhanced Audio', ...
            'enhanced_audio.wav');

        if isequal(file, 0)
            return;
        end

        output = enhancedData;

        % Prevent clipping during WAV export.
        peak = max(abs(output(:)));

        if peak > 1
            output = 0.99 * output / peak;

            uialert(fig, ...
                'Output exceeded the WAV amplitude range and was scaled to prevent clipping.', ...
                'Amplitude Scaling');
        end

        try
            audiowrite(fullfile(path, file), output, Fs);

            statusLabel.Text = ['Exported: ' file];

            fprintf('\nEnhanced audio exported: %s\n', ...
                fullfile(path, file));

        catch ME
            uialert(fig, ME.message, 'Export Error');
        end
    end

end

%% ============================================================
%  CORE DSP: SPECTRAL SUBTRACTION
%  ============================================================

function [y, noiseFrameCount] = spectralSubtraction( ...
    x, Fs, noiseStart, noiseEnd, alpha, beta, L, hop)

    N = size(x, 1);
    channels = size(x, 2);

    % Periodic Hann analysis/synthesis window.
    n = (0:L-1)';
    window = 0.5 - 0.5*cos(2*pi*n/L);

    % Padding permits reconstruction near both signal boundaries.
    paddedLength = N + 2*(L-1);

    starts = 1:hop:(N+L-1);

    % Frame centre times in seconds.
    frameTimes = (starts - (L-1)/2 - 1) / Fs;

    noiseMask = frameTimes >= noiseStart & ...
                frameTimes <= noiseEnd;

    noiseIndices = find(noiseMask);

    noiseFrameCount = numel(noiseIndices);

    if noiseFrameCount < 1
        error(['The selected noise interval contains no usable STFT ' ...
               'frame centres. Increase the interval or change its position.']);
    end

    y = zeros(N, channels);

    % Process each channel independently.
    for ch = 1:channels

        xPad = zeros(paddedLength, 1);
        xPad(L:L+N-1) = x(:, ch);

        % -----------------------------------------------------
        % PASS 1: ESTIMATE NOISE MAGNITUDE SPECTRUM
        % -----------------------------------------------------

        noiseSpectrum = zeros(L, 1);

        for k = 1:noiseFrameCount

            frameIndex = noiseIndices(k);
            startIndex = starts(frameIndex);

            frame = xPad(startIndex:startIndex+L-1);
            frame = frame .* window;

            X = fft(frame, L);

            noiseSpectrum = noiseSpectrum + abs(X);
        end

        noiseSpectrum = noiseSpectrum / noiseFrameCount;

        % -----------------------------------------------------
        % PASS 2: SPECTRAL SUBTRACTION + OVERLAP ADD
        % -----------------------------------------------------

        outputBuffer = zeros(paddedLength, 1);
        normalizationBuffer = zeros(paddedLength, 1);

        for k = 1:numel(starts)

            startIndex = starts(k);

            frame = xPad(startIndex:startIndex+L-1);
            frame = frame .* window;

            X = fft(frame, L);

            magnitude = abs(X);
            phase = angle(X);

            % Magnitude spectral subtraction.
            enhancedMagnitude = magnitude - alpha * noiseSpectrum;

            % Spectral flooring prevents complete suppression.
            enhancedMagnitude = max( ...
                enhancedMagnitude, beta * noiseSpectrum);

            % Preserve the noisy signal phase.
            enhancedSpectrum = enhancedMagnitude .* exp(1i*phase);

            % Inverse FFT.
            enhancedFrame = real(ifft(enhancedSpectrum, L));

            % Synthesis window.
            enhancedFrame = enhancedFrame .* window;

            % Overlap-add.
            indices = startIndex:startIndex+L-1;

            outputBuffer(indices) = ...
                outputBuffer(indices) + enhancedFrame;

            normalizationBuffer(indices) = ...
                normalizationBuffer(indices) + window.^2;
        end

        % Normalize overlapping window contributions.
        outputBuffer = outputBuffer ./ ...
            max(normalizationBuffer, eps);

        % Remove the padding.
        y(:, ch) = outputBuffer(L:L+N-1);
    end

end

%% ============================================================
%  VISUALIZATION: WAVEFORM
%  ============================================================

function plotWaveform(ax, x, Fs, plotTitle)

    cla(ax);

    N = numel(x);

    t = (0:N-1) / Fs;

    % Limit plotted points for long recordings.
    maxPoints = 50000;

    if N > maxPoints
        indices = round(linspace(1, N, maxPoints));
    else
        indices = 1:N;
    end

    plot(ax, t(indices), x(indices), ...
        'LineWidth', 0.8);

    title(ax, plotTitle);
    xlabel(ax, 'Time (seconds)');
    ylabel(ax, 'Amplitude');

    grid(ax, 'on');
    xlim(ax, [0 max(N-1,1)/Fs]);

end

%% ============================================================
%  VISUALIZATION: SPECTROGRAM
%  ============================================================

function drawSpectrogram(ax, x, Fs, L, hop, plotTitle)

    cla(ax);

    N = numel(x);

    % Downsample STFT frame locations for visualization only.
    % This prevents excessive memory use with long recordings.
    visualHop = max(hop, ceil(N/1500));

    n = (0:L-1)';
    window = 0.5 - 0.5*cos(2*pi*n/L);

    xPad = [zeros(L-1, 1); x; zeros(L-1, 1)];

    starts = 1:visualHop:(N+L-1);

    nFrames = numel(starts);

    % One-sided spectrum.
    nBins = floor(L/2) + 1;

    S = zeros(nBins, nFrames);

    frameTimes = zeros(1, nFrames);

    for k = 1:nFrames

        startIndex = starts(k);

        frame = xPad(startIndex:startIndex+L-1);
        frame = frame .* window;

        X = fft(frame, L);

        S(:, k) = abs(X(1:nBins));

        frameTimes(k) = ...
            (startIndex - (L-1)/2 - 1) / Fs;
    end

    frequencies = (0:nBins-1)' * Fs/L;

    magnitudeDB = 20*log10(S + eps);

    imagesc(ax, frameTimes, frequencies, magnitudeDB);

    axis(ax, 'xy');

    title(ax, plotTitle);
    xlabel(ax, 'Time (seconds)');
    ylabel(ax, 'Frequency (Hz)');

    ylim(ax, [0 Fs/2]);

    colormap(ax, 'parula');
    colorbar(ax);

    % Display dynamic range.
    maxDB = max(magnitudeDB(:));

    if isempty(maxDB) || ~isfinite(maxDB)
        maxDB = 0;
    end

    clim(ax, [maxDB-80 maxDB]);

end