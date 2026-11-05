function filter_designer()

clc;

%% SAGE-RF FILTER DESIGNER

% Application state
x = [];
y = [];
Fs = [];
fileName = '';

filterType = 'Low-Pass';
designType = 'FIR - Window Method';

b = [];
a = [];

filterOrder = 100;
fc1 = 1000;
fc2 = 3000;

%% Create main window

fig = uifigure( ...
    'Name', 'SAGE-RF | Filter Designer', ...
    'Position', [100 80 1150 760], ...
    'Color', [0.10 0.11 0.14]);

uilabel(fig, ...
    'Text', 'SAGE-RF  |  DIGITAL FILTER DESIGNER', ...
    'Position', [30 710 1000 35], ...
    'FontSize', 22, ...
    'FontWeight', 'bold', ...
    'FontColor', [0.2 0.7 1]);

uilabel(fig, ...
    'Text', 'Audio filtering and frequency-response analysis', ...
    'Position', [32 685 900 22], ...
    'FontSize', 12, ...
    'FontColor', [0.75 0.78 0.82]);

%% Create application pages

p1 = uipanel(fig, ...
    'Position', [25 35 1100 635], ...
    'BackgroundColor', [0.14 0.15 0.19], ...
    'BorderType', 'none');

p2 = uipanel(fig, ...
    'Position', [25 35 1100 635], ...
    'BackgroundColor', [0.14 0.15 0.19], ...
    'BorderType', 'none', ...
    'Visible', 'off');

p3 = uipanel(fig, ...
    'Position', [25 35 1100 635], ...
    'BackgroundColor', [0.14 0.15 0.19], ...
    'BorderType', 'none', ...
    'Visible', 'off');

p4 = uipanel(fig, ...
    'Position', [25 35 1100 635], ...
    'BackgroundColor', [0.14 0.15 0.19], ...
    'BorderType', 'none', ...
    'Visible', 'off');

%% PAGE 1 - AUDIO INPUT AND FILTER SELECTION

uilabel(p1, ...
    'Text', '01  |  AUDIO INPUT', ...
    'Position', [45 550 600 35], ...
    'FontSize', 19, ...
    'FontWeight', 'bold', ...
    'FontColor', 'white');

uilabel(p1, ...
    'Text', 'Load an audio file to begin processing.', ...
    'Position', [45 510 700 25], ...
    'FontColor', [0.75 0.78 0.82]);

fileLabel = uilabel(p1, ...
    'Text', 'No audio file selected', ...
    'Position', [45 435 800 35], ...
    'FontSize', 14, ...
    'FontColor', [0.3 0.75 1]);

uibutton(p1, 'push', ...
    'Text', 'Browse Audio File', ...
    'Position', [45 475 190 42], ...
    'FontSize', 14, ...
    'ButtonPushedFcn', @loadAudio);

uilabel(p1, ...
    'Text', 'SELECT FILTER TYPE', ...
    'Position', [45 350 400 30], ...
    'FontSize', 14, ...
    'FontWeight', 'bold', ...
    'FontColor', 'white');

filterDropdown = uidropdown(p1, ...
    'Items', {'Low-Pass', 'High-Pass', ...
              'Band-Pass', 'Band-Stop'}, ...
    'Value', 'Low-Pass', ...
    'Position', [45 305 300 40], ...
    'FontSize', 14, ...
    'ValueChangedFcn', @filterChanged);

uilabel(p1, ...
    'Text', ['Low-Pass: removes higher frequencies.' newline ...
             'High-Pass: removes lower frequencies.' newline ...
             'Band-Pass: keeps a selected frequency range.' newline ...
             'Band-Stop: removes a selected frequency range.'], ...
    'Position', [45 190 750 95], ...
    'FontSize', 13, ...
    'FontColor', [0.8 0.82 0.86]);

uibutton(p1, 'push', ...
    'Text', 'Next  >', ...
    'Position', [930 35 130 45], ...
    'FontSize', 14, ...
    'ButtonPushedFcn', @goToDesign);

%% PAGE 2 - FIR / IIR SELECTION

uilabel(p2, ...
    'Text', '02  |  FILTER DESIGN METHOD', ...
    'Position', [45 550 800 35], ...
    'FontSize', 19, ...
    'FontWeight', 'bold', ...
    'FontColor', 'white');

uilabel(p2, ...
    'Text', 'Choose how the digital filter will be designed.', ...
    'Position', [45 510 800 25], ...
    'FontColor', [0.75 0.78 0.82]);

designDropdown = uidropdown(p2, ...
    'Items', {'FIR - Window Method', 'IIR - Biquad'}, ...
    'Value', 'FIR - Window Method', ...
    'Position', [45 440 350 45], ...
    'FontSize', 14, ...
    'ValueChangedFcn', @designChanged);

uilabel(p2, ...
    'Text', ['FIR FILTER' newline ...
             'Finite Impulse Response filter.' newline ...
             'Uses a Hamming window and provides linear phase.' newline newline ...
             'IIR FILTER' newline ...
             'Infinite Impulse Response filter.' newline ...
             'Uses a second-order biquad design.'], ...
    'Position', [45 245 800 165], ...
    'FontSize', 14, ...
    'FontColor', [0.8 0.82 0.86]);

uibutton(p2, 'push', ...
    'Text', '<  Back', ...
    'Position', [45 35 130 45], ...
    'FontSize', 14, ...
    'ButtonPushedFcn', @(src,event) showPage(1));

uibutton(p2, 'push', ...
    'Text', 'Next  >', ...
    'Position', [930 35 130 45], ...
    'FontSize', 14, ...
    'ButtonPushedFcn', @goToConfiguration);

%% PAGE 3 - FILTER CONFIGURATION

uilabel(p3, ...
    'Text', '03  |  FILTER CONFIGURATION', ...
    'Position', [45 550 800 35], ...
    'FontSize', 19, ...
    'FontWeight', 'bold', ...
    'FontColor', 'white');

uilabel(p3, ...
    'Text', 'Configure the frequency limits and filter parameters.', ...
    'Position', [45 510 800 25], ...
    'FontColor', [0.75 0.78 0.82]);

uilabel(p3, ...
    'Text', 'Lower / Cutoff Frequency (Hz)', ...
    'Position', [45 420 350 25], ...
    'FontColor', 'white');

cutoff1Field = uieditfield(p3, 'numeric', ...
    'Position', [45 375 250 40], ...
    'Value', 1000);

upperLabel = uilabel(p3, ...
    'Text', 'Upper Cutoff Frequency (Hz)', ...
    'Position', [45 315 350 25], ...
    'FontColor', 'white');

cutoff2Field = uieditfield(p3, 'numeric', ...
    'Position', [45 270 250 40], ...
    'Value', 3000);

uilabel(p3, ...
    'Text', 'FIR Filter Order', ...
    'Position', [500 420 300 25], ...
    'FontColor', 'white');

orderField = uieditfield(p3, 'numeric', ...
    'Position', [500 375 250 40], ...
    'Value', 100);

configInfo = uilabel(p3, ...
    'Text', 'FIR order controls the number of filter coefficients.', ...
    'Position', [500 325 500 45], ...
    'FontColor', [0.75 0.78 0.82]);

statusLabel = uilabel(p3, ...
    'Text', '', ...
    'Position', [45 130 900 35], ...
    'FontColor', [1 0.6 0.3], ...
    'FontSize', 12);

uibutton(p3, 'push', ...
    'Text', '<  Back', ...
    'Position', [45 35 130 45], ...
    'FontSize', 14, ...
    'ButtonPushedFcn', @(src,event) showPage(2));

uibutton(p3, 'push', ...
    'Text', 'Apply Filter  >', ...
    'Position', [900 35 160 45], ...
    'FontSize', 14, ...
    'ButtonPushedFcn', @applyFilter);

%% PAGE 4 - RESULTS AND ANALYSIS

uilabel(p4, ...
    'Text', '04  |  FILTER RESULTS', ...
    'Position', [30 585 800 30], ...
    'FontSize', 19, ...
    'FontWeight', 'bold', ...
    'FontColor', 'white');

axResponse = uiaxes(p4, ...
    'Position', [35 345 1030 220], ...
    'BackgroundColor', [0.09 0.10 0.13]);

title(axResponse, 'Frequency Response');
xlabel(axResponse, 'Frequency (Hz)');
ylabel(axResponse, 'Magnitude (dB)');
grid(axResponse, 'on');

axOriginal = uiaxes(p4, ...
    'Position', [35 75 500 230], ...
    'BackgroundColor', [0.09 0.10 0.13]);

title(axOriginal, 'Original Audio');
xlabel(axOriginal, 'Time (seconds)');
ylabel(axOriginal, 'Amplitude');
grid(axOriginal, 'on');

axFiltered = uiaxes(p4, ...
    'Position', [565 75 500 230], ...
    'BackgroundColor', [0.09 0.10 0.13]);

title(axFiltered, 'Filtered Audio');
xlabel(axFiltered, 'Time (seconds)');
ylabel(axFiltered, 'Amplitude');
grid(axFiltered, 'on');

uibutton(p4, 'push', ...
    'Text', 'Play Original', ...
    'Position', [35 20 135 40], ...
    'ButtonPushedFcn', @playOriginal);

uibutton(p4, 'push', ...
    'Text', 'Play Filtered', ...
    'Position', [185 20 135 40], ...
    'ButtonPushedFcn', @playFiltered);

uibutton(p4, 'push', ...
    'Text', 'Save WAV', ...
    'Position', [335 20 120 40], ...
    'ButtonPushedFcn', @saveAudio);

uibutton(p4, 'push', ...
    'Text', '<  Back to Settings', ...
    'Position', [900 20 165 40], ...
    'ButtonPushedFcn', @(src,event) showPage(3));

%% INITIAL PAGE

showPage(1);

%% =========================================================
% NAVIGATION
% ==========================================================

    function showPage(pageNumber)

        p1.Visible = 'off';
        p2.Visible = 'off';
        p3.Visible = 'off';
        p4.Visible = 'off';

        switch pageNumber

            case 1
                p1.Visible = 'on';

            case 2
                p2.Visible = 'on';

            case 3
                p3.Visible = 'on';

            case 4
                p4.Visible = 'on';

        end

    end

%% =========================================================
% LOAD AUDIO
% ==========================================================

    function loadAudio(~,~)

        [file,path] = uigetfile( ...
            {'*.wav', 'WAV Audio Files (*.wav)'}, ...
            'Select Audio File');

        if isequal(file,0)
            return;
        end

        try

            [newAudio,newFs] = audioread(fullfile(path,file));

            % Validate loaded audio

            if isempty(newAudio) || size(newAudio,1) < 2
                error('The selected audio file is empty or too short.');
            end

            if ~isfinite(newFs) || newFs <= 0
                error('Invalid sampling frequency in audio file.');
            end

            if any(~isfinite(newAudio(:)))
                error('Audio contains invalid numerical values.');
            end

            % Update application state only after successful loading

            x = newAudio;
            Fs = newFs;
            fileName = file;

            % Clear previous filtered output

            y = [];
            b = [];
            a = [];

            fileLabel.Text = sprintf( ...
                '%s  |  %.2f seconds  |  %g Hz', ...
                file, size(x,1)/Fs, Fs);

            fprintf('\nLoaded: %s\n',file);
            fprintf('Sampling Frequency: %g Hz\n',Fs);
            fprintf('Duration: %.2f seconds\n',size(x,1)/Fs);

        catch ME

            uialert(fig,ME.message,'Audio Loading Error');

        end

    end

%% =========================================================
% FILTER SELECTION
% ==========================================================

    function filterChanged(~,~)

        filterType = filterDropdown.Value;

    end

    function designChanged(~,~)

        designType = designDropdown.Value;

        if strcmp(designType,'FIR - Window Method')

            orderField.Enable = 'on';

            configInfo.Text = ...
                'FIR order controls the number of filter coefficients.';

        else

            orderField.Enable = 'off';

            configInfo.Text = ...
                'IIR uses a fixed second-order biquad design.';

        end

    end

%% =========================================================
% NAVIGATION CALLBACKS
% ==========================================================

    function goToDesign(~,~)

        if isempty(x)

            uialert(fig, ...
                'Please load an audio file first.', ...
                'Missing Audio');

            return;

        end

        filterType = filterDropdown.Value;

        showPage(2);

    end

    function goToConfiguration(~,~)

        designType = designDropdown.Value;

        updateConfigurationFields();

        showPage(3);

    end

    function updateConfigurationFields()

        if strcmp(filterType,'Low-Pass') || ...
           strcmp(filterType,'High-Pass')

            cutoff2Field.Visible = 'off';
            upperLabel.Visible = 'off';

        else

            cutoff2Field.Visible = 'on';
            upperLabel.Visible = 'on';

        end

        if strcmp(designType,'FIR - Window Method')

            orderField.Enable = 'on';

        else

            orderField.Enable = 'off';

        end

    end

%% =========================================================
% APPLY FILTER
% ==========================================================

    function applyFilter(~,~)

        if isempty(x)
            return;
        end

        % Always read the current GUI selections

        filterType = filterDropdown.Value;
        designType = designDropdown.Value;

        fc1 = cutoff1Field.Value;
        fc2 = cutoff2Field.Value;

        % Validate first cutoff

        if ~isscalar(fc1) || ~isfinite(fc1) || ...
                fc1 <= 0 || fc1 >= Fs/2

            uialert(fig, ...
                'Cutoff frequency must be greater than zero and below Nyquist frequency.', ...
                'Invalid Frequency');

            return;

        end

        % Validate second cutoff for band filters

        if strcmp(filterType,'Band-Pass') || ...
           strcmp(filterType,'Band-Stop')

            if ~isscalar(fc2) || ~isfinite(fc2) || ...
                    fc2 <= fc1 || fc2 >= Fs/2

                uialert(fig, ...
                    'Upper cutoff must be greater than lower cutoff and below Nyquist.', ...
                    'Invalid Frequency Range');

                return;

            end

        end

        % Design and apply filter

        statusLabel.Text = 'Designing and applying filter...';

        drawnow;

        try

            if strcmp(designType,'FIR - Window Method')

                filterOrder = orderField.Value;

                if ~isscalar(filterOrder) || ...
                   ~isfinite(filterOrder) || ...
                   filterOrder < 2 || ...
                   filterOrder > 2000 || ...
                   filterOrder ~= floor(filterOrder)

                    uialert(fig, ...
                        'FIR order must be an integer between 2 and 2000.', ...
                        'Invalid Order');

                    statusLabel.Text = '';
                    return;

                end

                % Even order gives an integer linear-phase group delay

                if rem(filterOrder,2) ~= 0
                    filterOrder = filterOrder + 1;
                end

                [newB,newA] = designFIR( ...
                    filterType,Fs,fc1,fc2,filterOrder);

            else

                filterOrder = 2;

                [newB,newA] = designIIR( ...
                    filterType,Fs,fc1,fc2);

            end

            % Apply the filter independently to every channel

            newY = filter(newB,newA,x);

            if any(~isfinite(newY(:)))
                error('Filtering produced invalid numerical values.');
            end

            % Store the successful result

            b = newB;
            a = newA;
            y = newY;

            %% FREQUENCY RESPONSE

            % Frequency samples are used for plotting resolution,
            % not assumptions about the input audio.

            w = linspace(0,pi,4096);

            H = evaluateResponse(b,a,w);

            freq = w*Fs/(2*pi);

            magnitudeDB = 20*log10(max(abs(H),1e-8));

            cla(axResponse);

            plot(axResponse,freq,magnitudeDB, ...
                'LineWidth',1.4);

            title(axResponse, ...
                [filterType ' | ' designType]);

            xlabel(axResponse,'Frequency (Hz)');
            ylabel(axResponse,'Magnitude (dB)');

            xlim(axResponse,[0 Fs/2]);
            ylim(axResponse,[-100 10]);

            grid(axResponse,'on');

            %% WAVEFORM DISPLAY

            % Convert multichannel audio to mono for visualization.
            % The actual filtering and RMS calculations use all channels.

            originalMono = mean(x,2);
            filteredMono = mean(y,2);

            % Display an initial segment of the recording.
            % This is only a visualization window; the entire signal
            % has already been filtered.

            numberOfSamples = size(x,1);

            displaySamples = min( ...
                numberOfSamples,round(0.5*Fs));

            indices = 1:displaySamples;

            time = (indices-1)/Fs;

            % Original waveform

            cla(axOriginal);

            plot(axOriginal,time,originalMono(indices), ...
                'LineWidth',1);

            title(axOriginal,'Original Audio');
            xlabel(axOriginal,'Time (seconds)');
            ylabel(axOriginal,'Amplitude');

            grid(axOriginal,'on');

            % Filtered waveform

            cla(axFiltered);

            plot(axFiltered,time,filteredMono(indices), ...
                'LineWidth',1);

            if strcmp(designType,'FIR - Window Method')

                title(axFiltered, ...
                    'Filtered Audio (FIR group delay included)');

            else

                title(axFiltered,'Filtered Audio');

            end

            xlabel(axFiltered,'Time (seconds)');
            ylabel(axFiltered,'Amplitude');

            grid(axFiltered,'on');

            %% RMS MEASUREMENTS

            % Aggregate RMS across all samples and channels

            originalRMS = sqrt(mean(x(:).^2));

            filteredRMS = sqrt(mean(y(:).^2));

            %% TERMINAL OUTPUT

            fprintf('\n===== FILTER RESULTS =====\n');

            fprintf('File: %s\n',fileName);
            fprintf('Filter: %s\n',filterType);
            fprintf('Design: %s\n',designType);
            fprintf('Filter Order: %d\n',filterOrder);
            fprintf('Original RMS: %.6f\n',originalRMS);
            fprintf('Filtered RMS: %.6f\n',filteredRMS);

            fprintf('================================\n');

            statusLabel.Text = 'Filter applied successfully.';

            showPage(4);

        catch ME

            statusLabel.Text = 'Filter operation failed.';

            uialert(fig,ME.message,'Filter Error');

        end

    end

%% =========================================================
% AUDIO PLAYBACK
% ==========================================================

    function playOriginal(~,~)

        if ~isempty(x)

            % sound preserves the signal's original amplitude.
            % Unlike soundsc, it does not independently normalize it.

            sound(x,Fs);

        end

    end

    function playFiltered(~,~)

        if ~isempty(y)

            sound(y,Fs);

        end

    end

%% =========================================================
% EXPORT FILTERED AUDIO
% ==========================================================

    function saveAudio(~,~)

        if isempty(y)
            return;
        end

        [file,path] = uiputfile( ...
            '*.wav', ...
            'Save Filtered Audio', ...
            'SAGE_RF_filtered.wav');

        if isequal(file,0)
            return;
        end

        try

            outputAudio = y;

            % WAV export requires values within [-1,1].
            % Scale the entire output only if clipping would occur.

            peak = max(abs(outputAudio(:)));

            if peak > 1

                outputAudio = outputAudio/peak;

                fprintf(['\nExport warning: Output exceeded the ' ...
                         'WAV amplitude range and was scaled.\n']);

            end

            audiowrite(fullfile(path,file),outputAudio,Fs);

            uialert(fig, ...
                'Filtered audio exported successfully.', ...
                'Export Complete');

        catch ME

            uialert(fig,ME.message,'Export Error');

        end

    end

end


%% =========================================================
% FIR FILTER DESIGN - HAMMING WINDOW
% ==========================================================

function [b,a] = designFIR(type,Fs,f1,f2,order)

% Validate filter order

if ~isscalar(order) || ~isfinite(order) || ...
        order < 2 || order ~= floor(order)

    error('FIR order must be an integer greater than or equal to 2.');

end

% The implementation uses an even order

if rem(order,2) ~= 0
    error('FIR filter order must be even.');
end

M = order;

m = (-M/2:M/2)';

% Hamming window

window = 0.54 - 0.46*cos(2*pi*(0:M)'/M);

% Low-pass impulse response at the lower cutoff

lp1 = lowpassImpulse(f1,Fs,m);

delta = double(m==0);

switch type

    case 'Low-Pass'

        h = lp1;

    case 'High-Pass'

        h = delta-lp1;

    case 'Band-Pass'

        lp2 = lowpassImpulse(f2,Fs,m);

        h = lp2-lp1;

    case 'Band-Stop'

        lp2 = lowpassImpulse(f2,Fs,m);

        h = delta-(lp2-lp1);

    otherwise

        error('Unsupported FIR filter type.');

end

% Apply window

h = h.*window;

b = h(:)';
a = 1;

%% Normalize passband gain

switch type

    case {'Low-Pass','Band-Stop'}

        referenceFrequency = 0;

    case 'High-Pass'

        referenceFrequency = Fs/2;

    case 'Band-Pass'

        referenceFrequency = sqrt(f1*f2);

    otherwise

        error('Unsupported FIR filter type.');

end

omega = 2*pi*referenceFrequency/Fs;

gain = abs(sum(b.*exp(-1i*(0:M)*omega)));

if ~isfinite(gain) || gain < 1e-12

    error('FIR normalization failed. Check the cutoff frequencies and order.');

end

b = b/gain;

end


%% =========================================================
% IDEAL LOW-PASS IMPULSE RESPONSE
% ==========================================================

function h = lowpassImpulse(fc,Fs,m)

normalizedCutoff = fc/Fs;

argument = 2*normalizedCutoff*m;

h = 2*normalizedCutoff*customSinc(argument);

end


%% =========================================================
% CUSTOM SINC FUNCTION
% ==========================================================

function y = customSinc(x)

y = ones(size(x));

index = abs(x)>1e-12;

y(index) = sin(pi*x(index))./(pi*x(index));

end


%% =========================================================
% IIR SECOND-ORDER BIQUAD DESIGN
% ==========================================================

function [b,a] = designIIR(type,Fs,f1,f2)

%% INPUT VALIDATION

if ~isscalar(Fs) || ~isfinite(Fs) || Fs <= 0

    error('Sampling frequency must be a positive finite scalar.');

end

if ~ismember(type, ...
        {'Low-Pass','High-Pass','Band-Pass','Band-Stop'})

    error('Unsupported IIR filter type.');

end

if ~isscalar(f1) || ~isfinite(f1) || f1 <= 0 || f1 >= Fs/2

    error('Cutoff frequency must be between 0 and Nyquist.');

end

if strcmp(type,'Band-Pass') || strcmp(type,'Band-Stop')

    if ~isscalar(f2) || ~isfinite(f2) || ...
            f2 <= f1 || f2 >= Fs/2

        error(['Upper cutoff must be greater than lower cutoff ' ...
               'and below Nyquist.']);

    end

end

%% LOW-PASS AND HIGH-PASS
% Second-order Butterworth response

if strcmp(type,'Low-Pass') || strcmp(type,'High-Pass')

    fc = f1;

    Q = 1/sqrt(2);

    w0 = 2*pi*fc/Fs;

    alpha = sin(w0)/(2*Q);

    c = cos(w0);

    switch type

        case 'Low-Pass'

            b0 = (1-c)/2;
            b1 = 1-c;
            b2 = (1-c)/2;

        case 'High-Pass'

            b0 = (1+c)/2;
            b1 = -(1+c);
            b2 = (1+c)/2;

    end

    a0 = 1+alpha;

    a1 = -2*c;
    a2 = 1-alpha;

    b = [b0 b1 b2]/a0;

    a = [1 a1/a0 a2/a0];


%% BAND-PASS AND BAND-STOP
% Prewarped analog prototype + bilinear transform

else

    % Prewarp digital cutoff frequencies.
    % Bilinear transform:
    % s = 2*(1-z^-1)/(1+z^-1)

    Omega1 = 2*tan(pi*f1/Fs);

    Omega2 = 2*tan(pi*f2/Fs);

    % Analog centre frequency and bandwidth

    Omega0 = sqrt(Omega1*Omega2);

    B = Omega2-Omega1;

    % Denominator coefficients

    d0 = 4 + 2*B + Omega0^2;

    d1 = -8 + 2*Omega0^2;

    d2 = 4 - 2*B + Omega0^2;

    switch type

        case 'Band-Pass'

            % H(s) = B*s / (s^2 + B*s + Omega0^2)

            b0 = 2*B;
            b1 = 0;
            b2 = -2*B;

        case 'Band-Stop'

            % H(s) = (s^2 + Omega0^2) ...
            %        / (s^2 + B*s + Omega0^2)

            b0 = 4 + Omega0^2;

            b1 = -8 + 2*Omega0^2;

            b2 = 4 + Omega0^2;

    end

    % Normalize coefficients

    b = [b0 b1 b2]/d0;

    a = [1 d1/d0 d2/d0];

end

%% IIR STABILITY CHECK

poles = roots(a);

if any(abs(poles) >= 1)

    error('Designed IIR filter is unstable.');

end

end


%% =========================================================
% FREQUENCY RESPONSE CALCULATION
% ==========================================================

function H = evaluateResponse(b,a,w)

% Ensure row-vector coefficients

b = b(:).';

a = a(:).';

% Calculate numerator and denominator

numerator = zeros(size(w));

denominator = zeros(size(w));

for k = 1:length(b)

    numerator = numerator + ...
        b(k)*exp(-1i*(k-1)*w);

end

for k = 1:length(a)

    denominator = denominator + ...
        a(k)*exp(-1i*(k-1)*w);

end

% Frequency response

H = numerator./denominator;

end