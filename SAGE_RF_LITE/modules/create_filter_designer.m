function refreshFilterDesigner = create_filter_designer(parent, getAudioFcn)
% CREATE_FILTER_DESIGNER Embedded FIR/IIR Filter Designer for SAGE-RF Lite.
%
%   refreshFcn = create_filter_designer(parent, getAudioFcn)
%
% Inputs:
%   parent      - Parent UI container supplied by main.m
%   getAudioFcn - Function returning [audio, sampleRate, fileName]
%
% Output:
%   refreshFilterDesigner - Function handle that refreshes the shared audio.
%
% The audio matrix is expected to use MATLAB's standard convention:
% samples in rows and channels in columns.

    if nargin < 2 || isempty(parent) || ~isvalid(parent) || ...
            ~isa(getAudioFcn, 'function_handle')
        error('SAGE:FilterDesigner:InvalidInputs', ...
            'Provide a valid parent UI container and audio getter function handle.');
    end

    % ---------------------------------------------------------------------
    % DSP/UI STATE
    % ---------------------------------------------------------------------
    x = [];
    Fs = [];
    fileName = '';
    y = [];

    filterType = 'Lowpass';
    filterMethod = 'FIR';
    cutoff1 = 1000;
    cutoff2 = 4000;
    filterOrder = 100;

    % ---------------------------------------------------------------------
    % THEME
    % ---------------------------------------------------------------------
    C.bg = [0.055 0.075 0.105];
    C.panel = [0.085 0.13 0.19];
    C.panel2 = [0.075 0.105 0.15];
    C.text = [0.88 0.92 0.97];
    C.muted = [0.60 0.70 0.80];
    C.accent = [0.20 0.68 0.90];
    C.grid = [0.25 0.32 0.40];

    % Clear any previous contents owned by this module.
    delete(parent.Children);

    mainGrid = uigridlayout(parent, [4 1]);
    mainGrid.RowHeight = {45, 125, '1x', 65};
    mainGrid.ColumnWidth = {'1x'};
    mainGrid.Padding = [12 10 12 10];
    mainGrid.RowSpacing = 8;
    mainGrid.BackgroundColor = C.bg;

    % ---------------------------------------------------------------------
    % HEADER
    % ---------------------------------------------------------------------
    header = uipanel(mainGrid, 'BorderType', 'none', ...
        'BackgroundColor', C.panel2);
    header.Layout.Row = 1;
    header.Layout.Column = 1;

    headerGrid = uigridlayout(header, [1 1]);
    headerGrid.Padding = [8 2 8 2];
    headerGrid.BackgroundColor = C.panel2;

    uilabel(headerGrid, 'Text', 'FILTER DESIGNER', ...
        'FontSize', 18, 'FontWeight', 'bold', ...
        'FontColor', C.accent, 'BackgroundColor', C.panel2);

    % ---------------------------------------------------------------------
    % FILTER SETTINGS
    % ---------------------------------------------------------------------
    settingsPanel = uipanel(mainGrid, 'Title', 'Filter Configuration', ...
        'ForegroundColor', C.text, 'BackgroundColor', C.panel, ...
        'BorderColor', C.grid);
    settingsPanel.Layout.Row = 2;
    settingsPanel.Layout.Column = 1;

    settingsGrid = uigridlayout(settingsPanel, [2 5]);
    settingsGrid.RowHeight = {30, 35};
    settingsGrid.ColumnWidth = {'1x','1x','1x','1x','1x'};
    settingsGrid.Padding = [8 8 8 8];
    settingsGrid.ColumnSpacing = 8;
    settingsGrid.BackgroundColor = C.panel;

    labels = {'Filter Type','Method','Cutoff 1 (Hz)', ...
        'Cutoff 2 (Hz)','Filter Order'};
    for k = 1:numel(labels)
        lbl = uilabel(settingsGrid, 'Text', labels{k}, ...
            'FontWeight', 'bold', 'FontColor', C.text, ...
            'HorizontalAlignment', 'center', ...
            'BackgroundColor', C.panel);
        lbl.Layout.Row = 1;
        lbl.Layout.Column = k;
    end

    typeDrop = uidropdown(settingsGrid, ...
        'Items', {'Lowpass','Highpass','Bandpass','Bandstop'}, ...
        'Value', filterType, 'ValueChangedFcn', @updateSettings);
    typeDrop.Layout.Row = 2;
    typeDrop.Layout.Column = 1;

    methodDrop = uidropdown(settingsGrid, ...
        'Items', {'FIR','IIR'}, 'Value', filterMethod, ...
        'ValueChangedFcn', @updateSettings);
    methodDrop.Layout.Row = 2;
    methodDrop.Layout.Column = 2;

    cutoff1Field = uieditfield(settingsGrid, 'numeric', ...
        'Value', cutoff1, 'Limits', [0 Inf], ...
        'ValueChangedFcn', @updateSettings);
    cutoff1Field.Layout.Row = 2;
    cutoff1Field.Layout.Column = 3;

    cutoff2Field = uieditfield(settingsGrid, 'numeric', ...
        'Value', cutoff2, 'Limits', [0 Inf], ...
        'ValueChangedFcn', @updateSettings);
    cutoff2Field.Layout.Row = 2;
    cutoff2Field.Layout.Column = 4;

    orderField = uieditfield(settingsGrid, 'numeric', ...
        'Value', filterOrder, 'Limits', [2 500], ...
        'RoundFractionalValues', 'on', ...
        'ValueChangedFcn', @updateSettings);
    orderField.Layout.Row = 2;
    orderField.Layout.Column = 5;

    % ---------------------------------------------------------------------
    % RESULTS AREA
    % ---------------------------------------------------------------------
    resultsPanel = uipanel(mainGrid, 'Title', 'Filter Analysis', ...
        'ForegroundColor', C.text, 'BackgroundColor', C.bg, ...
        'BorderColor', C.grid);
    resultsPanel.Layout.Row = 3;
    resultsPanel.Layout.Column = 1;

    resultsGrid = uigridlayout(resultsPanel, [2 2]);
    resultsGrid.RowHeight = {'1x','1x'};
    resultsGrid.ColumnWidth = {'1x','1x'};
    resultsGrid.Padding = [8 8 8 8];
    resultsGrid.RowSpacing = 8;
    resultsGrid.ColumnSpacing = 8;
    resultsGrid.BackgroundColor = C.bg;

    axOriginal = makeAxes(resultsGrid, 1, 1, 'Original Signal', ...
        'Time (s)', 'Amplitude');
    axFiltered = makeAxes(resultsGrid, 1, 2, 'Filtered Signal', ...
        'Time (s)', 'Amplitude');
    axFrequency = makeAxes(resultsGrid, 2, 1, 'Frequency Response', ...
        'Frequency (Hz)', 'Magnitude (dB)');
    axComparison = makeAxes(resultsGrid, 2, 2, 'Spectrum Comparison', ...
        'Frequency (Hz)', 'Magnitude');

    % ---------------------------------------------------------------------
    % FOOTER / ACTIONS
    % ---------------------------------------------------------------------
    footer = uipanel(mainGrid, 'BorderType', 'none', ...
        'BackgroundColor', C.panel2);
    footer.Layout.Row = 4;
    footer.Layout.Column = 1;

    footerGrid = uigridlayout(footer, [1 5]);
    footerGrid.ColumnWidth = {'1x','1x','1x','1x','2x'};
    footerGrid.Padding = [5 5 5 5];
    footerGrid.ColumnSpacing = 8;
    footerGrid.BackgroundColor = C.panel2;

    applyButton = uibutton(footerGrid, 'push', 'Text', 'Apply Filter', ...
        'ButtonPushedFcn', @applyFilter);
    applyButton.Layout.Row = 1;
    applyButton.Layout.Column = 1;

    playOriginalButton = uibutton(footerGrid, 'push', ...
        'Text', 'Play Original', 'ButtonPushedFcn', @playOriginal);
    playOriginalButton.Layout.Row = 1;
    playOriginalButton.Layout.Column = 2;

    playFilteredButton = uibutton(footerGrid, 'push', ...
        'Text', 'Play Filtered', 'ButtonPushedFcn', @playFiltered);
    playFilteredButton.Layout.Row = 1;
    playFilteredButton.Layout.Column = 3;

    exportButton = uibutton(footerGrid, 'push', ...
        'Text', 'Export WAV', 'ButtonPushedFcn', @exportFiltered);
    exportButton.Layout.Row = 1;
    exportButton.Layout.Column = 4;

    statusLabel = uilabel(footerGrid, ...
        'Text', 'Waiting for audio...', ...
        'FontColor', C.text, 'HorizontalAlignment', 'center', ...
        'BackgroundColor', C.panel2);
    statusLabel.Layout.Row = 1;
    statusLabel.Layout.Column = 5;

    % IMPORTANT: assign the public output before the initial refresh.
    % main.m stores this returned handle and calls it after audio changes.
    refreshFilterDesigner = @refreshAudio;
    refreshFilterDesigner();

    % =====================================================================
    % NESTED CALLBACKS / DSP HELPERS
    % =====================================================================

    function ax = makeAxes(parentGrid, row, column, plotTitle, xLabel, yLabel)
        ax = uiaxes(parentGrid);
        ax.Layout.Row = row;
        ax.Layout.Column = column;
        ax.Color = C.panel2;
        ax.XColor = C.text;
        ax.YColor = C.text;
        ax.GridColor = C.grid;
        ax.Box = 'on';
        title(ax, plotTitle, 'Color', C.text);
        xlabel(ax, xLabel, 'Color', C.text);
        ylabel(ax, yLabel, 'Color', C.text);
        grid(ax, 'on');
    end

    function updateSettings(~, ~)
        filterType = typeDrop.Value;
        filterMethod = methodDrop.Value;
        cutoff1 = cutoff1Field.Value;
        cutoff2 = cutoff2Field.Value;
        filterOrder = round(orderField.Value);

        filterOrder = min(500, max(2, filterOrder));
        orderField.Value = filterOrder;
    end

    function refreshAudio(varargin)
        try
            [newX, newFs, newFile] = getAudioFcn();

            if isempty(newX) || isempty(newFs)
                x = [];
                Fs = [];
                fileName = '';
                y = [];
                cla(axOriginal);
                cla(axFiltered);
                cla(axFrequency);
                cla(axComparison);
                statusLabel.Text = 'Load an audio file first.';
                return;
            end

            if ~isnumeric(newX) || ~isreal(newX) || ...
                    ~ismatrix(newX) || any(~isfinite(newX(:)))
                error('The shared audio must be a finite, real numeric matrix.');
            end
            if ~isnumeric(newFs) || ~isscalar(newFs) || ...
                    ~isfinite(newFs) || newFs <= 0
                error('The sample rate must be a finite positive scalar.');
            end

            newX = double(newX);
            if isrow(newX) && numel(newX) > 1
                newX = newX(:);
            end

            x = newX;
            Fs = double(newFs);
            if isempty(newFile)
                fileName = 'Audio';
            else
                fileName = char(string(newFile));
            end
            y = [];

            t = (0:size(x,1)-1) / Fs;
            cla(axOriginal);
            plot(axOriginal, t, x(:,1));
            title(axOriginal, 'Original Signal', 'Color', C.text);
            xlabel(axOriginal, 'Time (s)');
            ylabel(axOriginal, 'Amplitude');
            grid(axOriginal, 'on');

            cla(axFiltered);
            cla(axFrequency);
            cla(axComparison);
            statusLabel.Text = ['Loaded: ' fileName];

        catch ME
            statusLabel.Text = 'Audio refresh failed.';
            warning('SAGE:FilterDesignerRefresh', ...
                'Filter Designer refresh failed: %s', ME.message);
        end
    end

    function applyFilter(varargin)
        if isempty(x) || isempty(Fs)
            showAlert('Load audio in the main application first.', 'No Audio');
            return;
        end

        try
            updateSettings([], []);

            nyquist = Fs / 2;
            if ~isfinite(cutoff1) || cutoff1 <= 0 || cutoff1 >= nyquist
                showAlert('Cutoff 1 must be greater than 0 and below Nyquist.', ...
                    'Invalid Cutoff');
                return;
            end

            if any(strcmp(filterType, {'Bandpass','Bandstop'}))
                if ~isfinite(cutoff2) || cutoff2 <= cutoff1 || ...
                        cutoff2 >= nyquist
                    showAlert(['Cutoff 2 must be greater than cutoff 1 ' ...
                        'and below Nyquist.'], 'Invalid Cutoffs');
                    return;
                end
            end

            y = zeros(size(x));
            for channel = 1:size(x,2)
                y(:,channel) = designAndApply(x(:,channel));
            end

            t = (0:size(x,1)-1) / Fs;
            cla(axFiltered);
            plot(axFiltered, t, y(:,1));
            title(axFiltered, 'Filtered Signal', 'Color', C.text);
            xlabel(axFiltered, 'Time (s)');
            ylabel(axFiltered, 'Amplitude');
            grid(axFiltered, 'on');

            plotFrequencyResponse();
            plotSpectrumComparison();
            statusLabel.Text = 'Filter applied successfully.';

        catch ME
            y = [];
            statusLabel.Text = 'Filter failed.';
            showAlert(ME.message, 'Filter Error');
        end
    end

    function out = designAndApply(in)
        if strcmp(filterMethod, 'FIR')
            [b, a] = designFIR(); %#ok<ASGLU>
            % Linear-phase FIR filtering with centered convolution.
            out = conv(in, b(:), 'same');
        else
            [b, a] = designIIR();
            out = filter(b, a, in);
        end
    end

    function [b, a] = designFIR()
        N = filterOrder;
        if mod(N,2) ~= 0
            N = N + 1;
        end

        n = -N/2:N/2;
        window = 0.54 - 0.46*cos(2*pi*(0:N)/N);

        switch filterType
            case 'Lowpass'
                fc = cutoff1 / Fs;
                b = 2*fc*sincLocal(2*fc*n);
            case 'Highpass'
                fc = cutoff1 / Fs;
                b = -2*fc*sincLocal(2*fc*n);
                b(N/2+1) = b(N/2+1) + 1;
            case 'Bandpass'
                f1 = cutoff1 / Fs;
                f2 = cutoff2 / Fs;
                b = 2*f2*sincLocal(2*f2*n) - ...
                    2*f1*sincLocal(2*f1*n);
            case 'Bandstop'
                f1 = cutoff1 / Fs;
                f2 = cutoff2 / Fs;
                b = -2*f2*sincLocal(2*f2*n) + ...
                    2*f1*sincLocal(2*f1*n);
                b(N/2+1) = b(N/2+1) + 1;
            otherwise
                error('Unsupported FIR filter type: %s', filterType);
        end

        b = b .* window;
        a = 1;
    end

    function [b, a] = designIIR()
        % Second-order Butterworth low/high-pass and RBJ-style band biquads.
        switch filterType
            case 'Lowpass'
                K = tan(pi*cutoff1/Fs);
                denominator = 1 + sqrt(2)*K + K^2;
                b = [K^2 2*K^2 K^2] / denominator;
                a = [1, 2*(K^2-1)/denominator, ...
                    (1-sqrt(2)*K+K^2)/denominator];

            case 'Highpass'
                K = tan(pi*cutoff1/Fs);
                denominator = 1 + sqrt(2)*K + K^2;
                b = [1 -2 1] / denominator;
                a = [1, 2*(K^2-1)/denominator, ...
                    (1-sqrt(2)*K+K^2)/denominator];

            case {'Bandpass','Bandstop'}
                center = sqrt(cutoff1*cutoff2);
                bandwidth = cutoff2-cutoff1;
                Q = center / bandwidth;
                omega = 2*pi*center/Fs;
                alpha = sin(omega)/(2*Q);
                cosine = cos(omega);

                if strcmp(filterType, 'Bandpass')
                    b = [alpha 0 -alpha];
                else
                    b = [1 -2*cosine 1];
                end
                a = [1+alpha, -2*cosine, 1-alpha];
                b = b/(1+alpha);
                a = a/(1+alpha);

            otherwise
                error('Unsupported IIR filter type: %s', filterType);
        end
    end

    function plotFrequencyResponse()
        [b, a] = getCoefficients();
        [response, frequency] = freqz(b, a, 2048, Fs);

        cla(axFrequency);
        plot(axFrequency, frequency, ...
            20*log10(max(abs(response), eps)));
        title(axFrequency, 'Frequency Response', 'Color', C.text);
        xlabel(axFrequency, 'Frequency (Hz)');
        ylabel(axFrequency, 'Magnitude (dB)');
        grid(axFrequency, 'on');
        xlim(axFrequency, [0 Fs/2]);
    end

    function [b, a] = getCoefficients()
        if strcmp(filterMethod, 'IIR')
            [b, a] = designIIR();
        else
            [b, a] = designFIR();
        end
    end

    function plotSpectrumComparison()
        nfft = max(2, 2^nextpow2(size(x,1)));
        originalSpectrum = abs(fft(x(:,1), nfft));
        filteredSpectrum = abs(fft(y(:,1), nfft));
        lastBin = floor(nfft/2) + 1;
        bins = 1:lastBin;
        frequency = (bins-1) * Fs/nfft;

        cla(axComparison);
        plot(axComparison, frequency, originalSpectrum(bins), ...
            'DisplayName', 'Original');
        hold(axComparison, 'on');
        plot(axComparison, frequency, filteredSpectrum(bins), ...
            'DisplayName', 'Filtered');
        hold(axComparison, 'off');
        title(axComparison, 'Spectrum Comparison', 'Color', C.text);
        xlabel(axComparison, 'Frequency (Hz)');
        ylabel(axComparison, 'Magnitude');
        legend(axComparison, 'show', 'TextColor', C.text, ...
            'Color', C.panel2, 'EdgeColor', C.grid);
        grid(axComparison, 'on');
        xlim(axComparison, [0 Fs/2]);
    end

    function playOriginal(varargin)
        if isempty(x) || isempty(Fs)
            showAlert('Load audio before playback.', 'No Audio');
            return;
        end
        sound(x, Fs);
    end

    function playFiltered(varargin)
        if isempty(y)
            showAlert('Apply the filter first.', 'No Filtered Audio');
            return;
        end
        sound(y, Fs);
    end

    function exportFiltered(varargin)
        if isempty(y)
            showAlert('Apply the filter before exporting.', ...
                'No Filtered Audio');
            return;
        end

        [file, path] = uiputfile('*.wav', 'Export Filtered Audio');
        if isequal(file, 0)
            return;
        end

        try
            audiowrite(fullfile(path, file), y, Fs);
            statusLabel.Text = 'Filtered WAV exported.';
        catch ME
            showAlert(ME.message, 'Export Error');
        end
    end

    function showAlert(message, alertTitle)
        fig = ancestor(parent, 'figure');
        if ~isempty(fig) && isvalid(fig)
            uialert(fig, message, alertTitle);
        else
            warning('SAGE:FilterDesigner', '%s: %s', alertTitle, message);
        end
    end

    function value = sincLocal(z)
        value = ones(size(z));
        nonzero = abs(z) > 1e-12;
        value(nonzero) = sin(pi*z(nonzero)) ./ (pi*z(nonzero));
    end
end
