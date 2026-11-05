
function filter_designer()

clc;

%% SAGE-RF FILTER DESIGNER - GUI VERSION

% Application state
x = [];
y = [];
Fs = [];
fileName = '';
filterType = 'Low-Pass';
designType = 'FIR';
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

% Header
header = uilabel(fig, ...
    'Text', 'SAGE-RF  |  DIGITAL FILTER DESIGNER', ...
    'Position', [30 710 1000 35], ...
    'FontSize', 22, ...
    'FontWeight', 'bold', ...
    'FontColor', [0.2 0.7 1]);

subtitle = uilabel(fig, ...
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

uilabel(p3, ...
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

        [file, path] = uigetfile( ...
            {'*.wav', 'WAV Audio Files (*.wav)'}, ...
            'Select Audio File');

        if isequal(file,0)
            return;
        end

        try

            [newAudio, newFs] = audioread(fullfile(path,file));

            x = newAudio;
            Fs = newFs;
            fileName = file;

            fileLabel.Text = sprintf( ...
                '%s  |  %.2f seconds  |  %d Hz', ...
                file, length(x)/Fs, Fs);

            fprintf('\nLoaded: %s\n', file);
            fprintf('Sampling Frequency: %d Hz\n', Fs);
            fprintf('Duration: %.2f seconds\n', length(x)/Fs);

        catch ME

            uialert(fig, ME.message, 'Audio Loading Error');

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

        if strcmp(designType, 'FIR - Window Method')

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

            uialert(fig, 'Please load an audio file first.', ...
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

            upperLabel = findobj(p3, ...
                'Text', 'Upper Cutoff Frequency (Hz)');

            upperLabel.Visible = 'off';

        else

            cutoff2Field.Visible = 'on';

            upperLabel = findobj(p3, ...
                'Text', 'Upper Cutoff Frequency (Hz)');

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

        fc1 = cutoff1Field.Value;
        fc2 = cutoff2Field.Value;

        if ~isfinite(fc1) || fc1 <= 0 || fc1 >= Fs/2

            uialert(fig, ...
                'Cutoff frequency must be between 0 and Nyquist frequency.', ...
                'Invalid Frequency');

            return;

        end

        if strcmp(filterType,'Band-Pass') || ...
           strcmp(filterType,'Band-Stop')

            if ~isfinite(fc2) || fc2 <= fc1 || fc2 >= Fs/2

                uialert(fig, ...
                    'Upper cutoff must be greater than lower cutoff and below Nyquist.', ...
                    'Invalid Frequency Range');

                return;

            end

        end

        statusLabel.Text = 'Designing and applying filter...';

        drawnow;

        try

            if strcmp(designType,'FIR - Window Method')

                filterOrder = orderField.Value;

                if ~isfinite(filterOrder) || ...
                   filterOrder < 2 || ...
                   filterOrder > 2000 || ...
                   filterOrder ~= floor(filterOrder)

                    uialert(fig, ...
                        'FIR order must be an integer between 2 and 2000.', ...
                        'Invalid Order');

                    statusLabel.Text = '';
                    return;

                end

                if rem(filterOrder,2) ~= 0
                    filterOrder = filterOrder + 1;
                end

                [b,a] = designFIR(filterType,Fs, ...
                    fc1,fc2,filterOrder);

            else

                filterOrder = 2;

                [b,a] = designIIR(filterType,Fs,fc1,fc2);

            end

            % Apply filter to every audio channel

            y = filter(b,a,x);

            % Plot frequency response

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

            % Convert stereo to mono for waveform display

            originalMono = mean(x,2);
            filteredMono = mean(y,2);

            % Find where actual audio starts

            envelope = max(abs(x),[],2);

            threshold = 0.01*max(envelope);

            firstActive = find(envelope > threshold,1,'first');

            if isempty(firstActive)
                firstActive = 1;
            end

            startIndex = firstActive;

            endIndex = min(length(x), ...
                startIndex + round(0.5*Fs)-1);

            indices = startIndex:endIndex;

            time = (indices-startIndex)/Fs;

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

            title(axFiltered,'Filtered Audio');
            xlabel(axFiltered,'Time (seconds)');
            ylabel(axFiltered,'Amplitude');

            grid(axFiltered,'on');

            % Measurements

            originalRMS = sqrt(mean(x(:).^2));
            filteredRMS = sqrt(mean(y(:).^2));

            fprintf('\n===== FILTER RESULTS =====\n');

            fprintf('File: %s\n',fileName);
            fprintf('Filter: %s\n',filterType);
            fprintf('Design: %s\n',designType);
            fprintf('Filter Order: %d\n',filterOrder);
            fprintf('Original RMS: %.6f\n',originalRMS);
            fprintf('Filtered RMS: %.6f\n',filteredRMS);

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
            soundsc(x,Fs);
        end

    end

    function playFiltered(~,~)

        if ~isempty(y)
            soundsc(y,Fs);
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

            % Prevent clipping when exporting

            outputAudio = y;

            peak = max(abs(outputAudio(:)));

            if peak > 1
                outputAudio = outputAudio/peak;
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

M = order;

m = (-M/2:M/2)';

window = 0.54 - 0.46*cos(2*pi*(0:M)'/M);

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

end

h = h.*window;

b = h(:)';
a = 1;

% Normalize passband gain

switch type

    case {'Low-Pass','Band-Stop'}
        referenceFrequency = 0;

    case 'High-Pass'
        referenceFrequency = Fs/2;

    case 'Band-Pass'
        referenceFrequency = sqrt(f1*f2);

end

omega = 2*pi*referenceFrequency/Fs;

gain = abs(sum(b.*exp(-1i*(0:M)*omega)));

if gain > 1e-12
    b = b/gain;
end

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

if strcmp(type,'Low-Pass') || strcmp(type,'High-Pass')

    fc = f1;

    Q = 1/sqrt(2);

else

    fc = sqrt(f1*f2);

    Q = fc/(f2-f1);

end

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

    case 'Band-Pass'

        b0 = alpha;
        b1 = 0;
        b2 = -alpha;

    case 'Band-Stop'

        b0 = 1;
        b1 = -2*c;
        b2 = 1;

end

a0 = 1+alpha;

a1 = -2*c;
a2 = 1-alpha;

b = [b0 b1 b2]/a0;

a = [1 a1/a0 a2/a0];

end


%% =========================================================
% FREQUENCY RESPONSE CALCULATION
% ==========================================================

function H = evaluateResponse(b,a,w)

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

H = numerator./denominator;

end
