
function refreshSpeechEnhancement = create_speech_enhancement(parent, getAudioFcn)
% CREATE_SPEECH_ENHANCEMENT
% SAGE-RF Lite - Integrated Speech Enhancement Module
%
% Features:
%   STFT spectral subtraction
%   Noise spectrum estimation
%   Spectral flooring
%   Overlap-add reconstruction
%   Multichannel audio support
%   Waveform and spectrogram visualization
%   Audio playback and WAV export
%
% Requires MATLAB base functions only.

    if nargin ~= 2 || ~isgraphics(parent) || ...
            ~isa(getAudioFcn, 'function_handle')
        error('SAGE:SpeechEnhancement:InvalidInput', ...
            'Valid parent container and audio getter required.');
    end

    %% DATA

    audioData = [];
    enhancedData = [];
    Fs = [];
    audioFile = '';

    %% THEME

    C.bg = [0.055 0.075 0.105];
    C.panel = [0.085 0.115 0.165];
    C.panel2 = [0.075 0.105 0.15];
    C.text = [0.85 0.90 0.96];
    C.white = [0.96 0.98 1.00];
    C.muted = [0.58 0.70 0.83];
    C.accent = [0.08 0.43 0.68];

    %% MAIN LAYOUT

    root = uigridlayout(parent, [1 2]);
    root.ColumnWidth = {280, '1x'};
    root.RowHeight = {'1x'};
    root.Padding = [0 0 0 0];
    root.ColumnSpacing = 14;
    root.BackgroundColor = C.bg;

    %% LEFT CONTROL PANEL

    controls = uipanel(root, ...
        'BorderType', 'none', ...
        'BackgroundColor', C.panel);

    controls.Layout.Row = 1;
    controls.Layout.Column = 1;

    cg = uigridlayout(controls, [19 1]);

    cg.ColumnWidth = {'1x'};

    % Explicit heights ensure that all controls and buttons fit.
    cg.RowHeight = { ...
        30, 18, 26, 22, ...
        20, ...
        18, 30, ...
        18, 30, ...
        18, 30, ...
        18, 30, ...
        18, 30, ...
        18, 30, ...
        40, ...
        80};

    cg.Padding = [14 8 14 8];
    cg.RowSpacing = 4;
    cg.BackgroundColor = C.panel;

    %% TITLE

    heading = uilabel(cg, ...
        'Text', 'SPEECH ENHANCEMENT', ...
        'FontSize', 14, ...
        'FontWeight', 'bold', ...
        'FontColor', [0.28 0.72 0.96], ...
        'BackgroundColor', C.panel);

    heading.Layout.Row = 1;

    subheading = uilabel(cg, ...
        'Text', 'STFT spectral subtraction', ...
        'FontSize', 10, ...
        'FontColor', C.muted, ...
        'BackgroundColor', C.panel);

    subheading.Layout.Row = 2;

    fileLabel = uilabel(cg, ...
        'Text', 'No audio loaded', ...
        'FontSize', 10, ...
        'FontColor', C.white, ...
        'WordWrap', 'on', ...
        'BackgroundColor', C.panel2);

    fileLabel.Layout.Row = 3;

    infoLabel = uilabel(cg, ...
        'Text', 'Fs: -- | Duration: --', ...
        'FontSize', 9, ...
        'FontColor', C.muted, ...
        'BackgroundColor', C.panel);

    infoLabel.Layout.Row = 4;

    sectionLabel = uilabel(cg, ...
        'Text', 'NOISE REDUCTION SETTINGS', ...
        'FontSize', 9, ...
        'FontWeight', 'bold', ...
        'FontColor', C.muted, ...
        'BackgroundColor', C.panel);

    sectionLabel.Layout.Row = 5;

    %% NOISE START

    makeLabel(cg, 'Noise start (seconds)', 6);

    noiseStartField = uieditfield(cg, 'numeric', ...
        'Value', 0, ...
        'Limits', [0 Inf]);

    noiseStartField.Layout.Row = 7;

    %% NOISE END

    makeLabel(cg, 'Noise end (seconds)', 8);

    noiseEndField = uieditfield(cg, 'numeric', ...
        'Value', 0.5, ...
        'Limits', [0 Inf]);

    noiseEndField.Layout.Row = 9;

    %% REDUCTION STRENGTH

    makeLabel(cg, 'Reduction strength (0.5 - 4)', 10);

    strengthField = uieditfield(cg, 'numeric', ...
        'Value', 1.5, ...
        'Limits', [0.5 4]);

    strengthField.Layout.Row = 11;

    %% SPECTRAL FLOOR

    makeLabel(cg, 'Spectral floor (0 - 0.5)', 12);

    floorField = uieditfield(cg, 'numeric', ...
        'Value', 0.02, ...
        'Limits', [0 0.5]);

    floorField.Layout.Row = 13;

    %% FRAME LENGTH

    makeLabel(cg, 'Frame length', 14);

    frameDropdown = uidropdown(cg, ...
        'Items', {'512','1024','2048','4096'}, ...
        'Value', '1024');

    frameDropdown.Layout.Row = 15;

    %% OVERLAP

    makeLabel(cg, 'Overlap percentage', 16);

    overlapDropdown = uidropdown(cg, ...
        'Items', {'50','75'}, ...
        'Value', '75');

    overlapDropdown.Layout.Row = 17;

    %% APPLY BUTTON

    processButton = uibutton(cg, 'push', ...
        'Text', 'APPLY REDUCTION', ...
        'FontSize', 11, ...
        'FontWeight', 'bold', ...
        'BackgroundColor', C.accent, ...
        'FontColor', [1 1 1], ...
        'ButtonPushedFcn', @processAudio);

    processButton.Layout.Row = 18;

    %% BOTTOM ACTION BUTTONS

    outputPanel = uipanel(cg, ...
        'BorderType', 'none', ...
        'BackgroundColor', C.panel);

    outputPanel.Layout.Row = 19;

    og = uigridlayout(outputPanel, [2 2]);

    og.RowHeight = {36, 36};
    og.ColumnWidth = {'1x','1x'};
    og.Padding = [0 0 0 0];
    og.RowSpacing = 6;
    og.ColumnSpacing = 6;
    og.BackgroundColor = C.panel;

    playOriginalButton = uibutton(og, 'push', ...
        'Text', 'Play Original', ...
        'FontSize', 10, ...
        'ButtonPushedFcn', @playOriginal);

    playOriginalButton.Layout.Row = 1;
    playOriginalButton.Layout.Column = 1;

    playEnhancedButton = uibutton(og, 'push', ...
        'Text', 'Play Enhanced', ...
        'FontSize', 10, ...
        'ButtonPushedFcn', @playEnhanced);

    playEnhancedButton.Layout.Row = 1;
    playEnhancedButton.Layout.Column = 2;

    exportButton = uibutton(og, 'push', ...
        'Text', 'Export WAV', ...
        'FontSize', 10, ...
        'ButtonPushedFcn', @saveEnhanced);

    exportButton.Layout.Row = 2;
    exportButton.Layout.Column = 1;

    refreshButton = uibutton(og, 'push', ...
        'Text', 'Refresh Audio', ...
        'FontSize', 10, ...
        'ButtonPushedFcn', @(~,~) refreshAudio());

    refreshButton.Layout.Row = 2;
    refreshButton.Layout.Column = 2;

    %% RIGHT VISUALIZATION AREA

    visual = uipanel(root, ...
        'BorderType', 'none', ...
        'BackgroundColor', C.bg);

    visual.Layout.Row = 1;
    visual.Layout.Column = 2;

    vg = uigridlayout(visual, [3 2]);

    vg.RowHeight = {30, '1x', '1x'};
    vg.ColumnWidth = {'1x','1x'};
    vg.Padding = [0 0 0 0];
    vg.RowSpacing = 10;
    vg.ColumnSpacing = 10;
    vg.BackgroundColor = C.bg;

    %% STATUS

    statusLabel = uilabel(vg, ...
        'Text', 'Load audio using the main toolbar.', ...
        'FontSize', 11, ...
        'FontWeight', 'bold', ...
        'FontColor', C.text, ...
        'BackgroundColor', C.bg);

    statusLabel.Layout.Row = 1;
    statusLabel.Layout.Column = 1;

    statsLabel = uilabel(vg, ...
        'Text', 'Waiting for shared audio.', ...
        'FontSize', 9, ...
        'FontColor', C.muted, ...
        'HorizontalAlignment', 'right', ...
        'BackgroundColor', C.bg);

    statsLabel.Layout.Row = 1;
    statsLabel.Layout.Column = 2;

    %% FOUR AXES

    axOriginalWave = makeAxes(vg, 2, 1, ...
        'Original Waveform');

    axEnhancedWave = makeAxes(vg, 2, 2, ...
        'Enhanced Waveform');

    axOriginalSpec = makeAxes(vg, 3, 1, ...
        'Original Spectrogram');

    axEnhancedSpec = makeAxes(vg, 3, 2, ...
        'Enhanced Spectrogram');

    %% INITIALIZE

    refreshSpeechEnhancement = @refreshAudio;

    refreshAudio();

    %% LOCAL UI FUNCTIONS

    function makeLabel(parentGrid, labelText, row)

        h = uilabel(parentGrid, ...
            'Text', labelText, ...
            'FontSize', 9, ...
            'FontWeight', 'bold', ...
            'FontColor', C.muted, ...
            'BackgroundColor', C.panel);

        h.Layout.Row = row;

    end

    function ax = makeAxes(parentGrid, row, column, plotTitle)

        ax = uiaxes(parentGrid);

        ax.Layout.Row = row;
        ax.Layout.Column = column;

        ax.Color = C.panel2;
        ax.XColor = C.muted;
        ax.YColor = C.muted;
        ax.GridColor = [0.28 0.36 0.45];
        ax.FontSize = 10;

        title(ax, plotTitle, ...
            'Color', C.white);

        xlabel(ax, 'Time (seconds)', ...
            'Color', C.muted);

        ylabel(ax, 'Amplitude / Frequency', ...
            'Color', C.muted);

        grid(ax, 'on');

    end

    %% REFRESH SHARED AUDIO

    function refreshAudio()

        try

            [newAudio, newFs, newName] = getAudioFcn();

            if isempty(newAudio)

                audioData = [];
                enhancedData = [];
                Fs = [];
                audioFile = '';

                fileLabel.Text = 'No audio loaded';
                infoLabel.Text = 'Fs: -- | Duration: --';

                statusLabel.Text = ...
                    'Load audio using the main toolbar.';

                statsLabel.Text = 'Waiting for shared audio.';

                cla(axOriginalWave);
                cla(axEnhancedWave);
                cla(axOriginalSpec);
                cla(axEnhancedSpec);

                return;

            end

            if ~isnumeric(newAudio) || ...
                    ~isreal(newAudio) || ...
                    isempty(newAudio) || ...
                    any(~isfinite(newAudio(:))) || ...
                    isempty(newFs) || ...
                    ~isfinite(newFs) || newFs <= 0

                error('Invalid shared audio data or sampling rate.');

            end

            audioData = newAudio;
            Fs = newFs;
            audioFile = newName;

            enhancedData = [];

            duration = size(audioData,1)/Fs;

            fileLabel.Text = audioFile;

            infoLabel.Text = sprintf( ...
                'Fs: %.0f Hz | %.2f s | %d channel(s)', ...
                Fs, duration, size(audioData,2));

            noiseStartField.Value = 0;
            noiseEndField.Value = min(0.5, duration);

            L = str2double(frameDropdown.Value);

            overlap = str2double(overlapDropdown.Value)/100;

            hop = max(1, round(L*(1-overlap)));

            plotWaveform(axOriginalWave, ...
                audioData(:,1), Fs, 'Original Waveform');

            cla(axEnhancedWave);
            cla(axEnhancedSpec);

            drawSpectrogram(axOriginalSpec, ...
                audioData(:,1), Fs, L, hop, ...
                'Original Spectrogram');

            statusLabel.Text = ...
                'Shared audio loaded. Select a noise-only interval.';

            statsLabel.Text = 'Ready for noise reduction.';

        catch ME

            statusLabel.Text = 'Could not refresh shared audio.';

            warning('SAGE:SpeechEnhancementRefresh', ...
                '%s', ME.message);

        end

    end

    %% PROCESS AUDIO

    function processAudio(~,~)

        if isempty(audioData)

            uialert(ancestor(parent,'figure'), ...
                'Load audio using the main toolbar first.', ...
                'No Audio');

            return;

        end

        duration = size(audioData,1)/Fs;

        noiseStart = noiseStartField.Value;
        noiseEnd = noiseEndField.Value;

        alpha = strengthField.Value;
        beta = floorField.Value;

        L = str2double(frameDropdown.Value);

        overlap = str2double(overlapDropdown.Value)/100;

        hop = max(1, round(L*(1-overlap)));

        %% VALIDATION

        if ~isfinite(noiseStart) || ...
                ~isfinite(noiseEnd) || ...
                noiseStart < 0 || ...
                noiseEnd <= noiseStart || ...
                noiseEnd > duration

            uialert(ancestor(parent,'figure'), ...
                'Select a valid noise-only interval within the audio duration.', ...
                'Invalid Noise Interval');

            return;

        end

        processButton.Enable = 'off';

        statusLabel.Text = ...
            'Processing audio. Please wait...';

        statsLabel.Text = 'Running STFT spectral subtraction...';

        drawnow;

        try

            timerValue = tic;

            [result, noiseFrames] = spectralSubtraction( ...
                audioData, Fs, noiseStart, noiseEnd, ...
                alpha, beta, L, hop);

            processingTime = toc(timerValue);

            enhancedData = result;

            %% RMS STATISTICS

            originalRMS = sqrt(mean(audioData(:).^2));

            enhancedRMS = sqrt(mean(enhancedData(:).^2));

            if originalRMS > 0 && enhancedRMS > 0

                rmsChange = 20*log10(originalRMS/enhancedRMS);

            else

                rmsChange = Inf;

            end

            %% UPDATE WAVEFORMS

            plotWaveform(axOriginalWave, ...
                audioData(:,1), Fs, 'Original Waveform');

            plotWaveform(axEnhancedWave, ...
                enhancedData(:,1), Fs, 'Enhanced Waveform');

            %% UPDATE SPECTROGRAMS

            drawSpectrogram(axOriginalSpec, ...
                audioData(:,1), Fs, L, hop, ...
                'Original Spectrogram');

            drawSpectrogram(axEnhancedSpec, ...
                enhancedData(:,1), Fs, L, hop, ...
                'Enhanced Spectrogram');

            %% UPDATE STATUS

            statsLabel.Text = sprintf( ...
                'RMS %.5f -> %.5f | Change %.2f dB | Noise frames %d | %.2f s', ...
                originalRMS, enhancedRMS, ...
                rmsChange, noiseFrames, processingTime);

            statusLabel.Text = ...
                'Noise reduction completed successfully.';

            %% COMMAND WINDOW REPORT

            fprintf('\nSAGE-RF Lite | Speech Enhancement\n');

            fprintf('File: %s\n', audioFile);

            fprintf('Sampling rate: %.0f Hz\n', Fs);

            fprintf('Channels: %d\n', size(audioData,2));

            fprintf('Noise interval: %.3f - %.3f seconds\n', ...
                noiseStart, noiseEnd);

            fprintf('Noise frames: %d\n', noiseFrames);

            fprintf('Frame length: %d\n', L);

            fprintf('Hop length: %d\n', hop);

            fprintf('Strength: %.2f\n', alpha);

            fprintf('Spectral floor: %.3f\n', beta);

            fprintf('Processing time: %.3f seconds\n', ...
                processingTime);

            fprintf('RMS change: %.2f dB\n\n', rmsChange);

        catch ME

            enhancedData = [];

            statusLabel.Text = 'Processing failed.';

            uialert(ancestor(parent,'figure'), ...
                ME.message, 'Processing Error');

        end

        processButton.Enable = 'on';

    end

    %% PLAY ORIGINAL

    function playOriginal(~,~)

        if isempty(audioData)

            uialert(ancestor(parent,'figure'), ...
                'Load audio first.', 'No Audio');

            return;

        end

        sound(audioData, Fs);

    end

    %% PLAY ENHANCED

    function playEnhanced(~,~)

        if isempty(enhancedData)

            uialert(ancestor(parent,'figure'), ...
                'Apply reduction before playback.', ...
                'No Enhanced Audio');

            return;

        end

        sound(enhancedData, Fs);

    end

    %% EXPORT WAV

    function saveEnhanced(~,~)

        if isempty(enhancedData)

            uialert(ancestor(parent,'figure'), ...
                'Process audio before exporting.', ...
                'No Enhanced Audio');

            return;

        end

        [file, path] = uiputfile( ...
            {'*.wav','WAV Audio Files (*.wav)'}, ...
            'Export Enhanced Audio', ...
            'enhanced_audio.wav');

        if isequal(file,0)
            return;
        end

        output = enhancedData;

        peak = max(abs(output(:)));

        if peak > 1

            output = 0.99*output/peak;

        end

        try

            audiowrite(fullfile(path,file), output, Fs);

            statusLabel.Text = ['Exported: ' file];

        catch ME

            uialert(ancestor(parent,'figure'), ...
                ME.message, 'Export Error');

        end

    end

end


%% ============================================================
%  STFT SPECTRAL SUBTRACTION
%  ============================================================

function [y, noiseFrameCount] = spectralSubtraction( ...
    x, Fs, noiseStart, noiseEnd, alpha, beta, L, hop)

    N = size(x,1);
    channels = size(x,2);

    n = (0:L-1)';

    % Periodic Hann window
    window = 0.5 - 0.5*cos(2*pi*n/L);

    % Padding for centred reconstruction
    paddedLength = N + 2*(L-1);

    starts = 1:hop:(N+L-1);

    frameTimes = ...
        (starts - (L-1)/2 - 1)/Fs;

    % Select noise-only frames
    noiseIndices = find( ...
        frameTimes >= noiseStart & ...
        frameTimes <= noiseEnd);

    noiseFrameCount = numel(noiseIndices);

    if noiseFrameCount < 1

        error(['No usable STFT frames in the selected noise interval. ' ...
            'Increase the interval or adjust its position.']);

    end

    y = zeros(N,channels);

    %% PROCESS EACH CHANNEL

    for ch = 1:channels

        xPad = zeros(paddedLength,1);

        xPad(L:L+N-1) = x(:,ch);

        %% ESTIMATE NOISE SPECTRUM

        noiseSpectrum = zeros(L,1);

        for k = 1:noiseFrameCount

            startIndex = starts(noiseIndices(k));

            frame = xPad( ...
                startIndex:startIndex+L-1).*window;

            noiseSpectrum = ...
                noiseSpectrum + abs(fft(frame,L));

        end

        noiseSpectrum = noiseSpectrum/noiseFrameCount;

        %% OVERLAP-ADD RECONSTRUCTION

        outputBuffer = zeros(paddedLength,1);

        normalizationBuffer = zeros(paddedLength,1);

        for k = 1:numel(starts)

            startIndex = starts(k);

            frame = xPad( ...
                startIndex:startIndex+L-1).*window;

            X = fft(frame,L);

            magnitude = abs(X);

            phase = angle(X);

            % Magnitude spectral subtraction
            enhancedMagnitude = max( ...
                magnitude-alpha*noiseSpectrum, ...
                beta*noiseSpectrum);

            % Preserve noisy phase
            enhancedSpectrum = ...
                enhancedMagnitude.*exp(1i*phase);

            enhancedFrame = ...
                real(ifft(enhancedSpectrum,L)).*window;

            indices = startIndex:startIndex+L-1;

            outputBuffer(indices) = ...
                outputBuffer(indices)+enhancedFrame;

            normalizationBuffer(indices) = ...
                normalizationBuffer(indices)+window.^2;

        end

        % Normalize overlap-add
        outputBuffer = outputBuffer ./ ...
            max(normalizationBuffer,eps);

        % Remove padding
        y(:,ch) = outputBuffer(L:L+N-1);

    end

end


%% ============================================================
%  WAVEFORM PLOT
%  ============================================================

function plotWaveform(ax, x, Fs, plotTitle)

    cla(ax);

    N = numel(x);

    t = (0:N-1)/Fs;

    maxPoints = 50000;

    if N > maxPoints

        indices = round(linspace(1,N,maxPoints));

    else

        indices = 1:N;

    end

    plot(ax, t(indices), x(indices), ...
        'LineWidth', 0.8);

    title(ax, plotTitle, ...
        'Color', [0.96 0.98 1.00]);

    xlabel(ax, 'Time (seconds)');

    ylabel(ax, 'Amplitude');

    grid(ax,'on');

    if N > 1

        xlim(ax, [0 (N-1)/Fs]);

    end

end


%% ============================================================
%  SPECTROGRAM PLOT
%  ============================================================

function drawSpectrogram(ax, x, Fs, L, hop, plotTitle)

    cla(ax);

    N = numel(x);

    % Limit displayed frames for performance
    visualHop = max(hop, ceil(N/1500));

    n = (0:L-1)';

    window = 0.5-0.5*cos(2*pi*n/L);

    xPad = [zeros(L-1,1); x; zeros(L-1,1)];

    starts = 1:visualHop:(N+L-1);

    nBins = floor(L/2)+1;

    S = zeros(nBins,numel(starts));

    frameTimes = zeros(1,numel(starts));

    for k = 1:numel(starts)

        startIndex = starts(k);

        frame = xPad( ...
            startIndex:startIndex+L-1).*window;

        X = fft(frame,L);

        S(:,k) = abs(X(1:nBins));

        frameTimes(k) = ...
            (startIndex-(L-1)/2-1)/Fs;

    end

    frequencies = (0:nBins-1)'*Fs/L;

    magnitudeDB = 20*log10(S+eps);

    imagesc(ax, frameTimes, frequencies, magnitudeDB);

    axis(ax,'xy');

    title(ax, plotTitle, ...
        'Color', [0.96 0.98 1.00]);

    xlabel(ax, 'Time (seconds)');

    ylabel(ax, 'Frequency (Hz)');

    ylim(ax, [0 Fs/2]);

    colormap(ax,'parula');

    colorbar(ax);

    maxDB = max(magnitudeDB(:));

    if isempty(maxDB) || ~isfinite(maxDB)
        maxDB = 0;
    end

    caxis(ax, [maxDB-80 maxDB]);

end
