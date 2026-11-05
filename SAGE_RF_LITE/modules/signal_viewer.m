
function signal_viewer()

clc;
close all;

%% 1. Select audio file

[file, path] = uigetfile( ...
    {'*.wav', 'WAV Audio Files (*.wav)'}, ...
    'Select an Audio File');

if isequal(file, 0)
    disp('No file selected.');
    return;
end

filename = fullfile(path, file);

%% 2. Read audio

[x, Fs] = audioread(filename);

% Convert stereo audio to mono
if size(x, 2) == 2
    x_mono = mean(x, 2);
else
    x_mono = x;
end

%% 3. Extract signal information

N = length(x_mono);
duration = N / Fs;
t = (0:N-1) / Fs;

%% 4. Calculate signal measurements

peak_amplitude = max(abs(x_mono));
rms_amplitude = sqrt(mean(x_mono.^2));

fprintf('\n===== SAGE-RF LITE =====\n');

fprintf('File Name: %s\n', file);
fprintf('Sampling Frequency: %d Hz\n', Fs);
fprintf('Duration: %.2f seconds\n', duration);
fprintf('Total Samples: %d\n', N);
fprintf('Number of Channels: %d\n', size(x, 2));

fprintf('\n===== SIGNAL MEASUREMENTS =====\n');

fprintf('Peak Amplitude: %.4f\n', peak_amplitude);
fprintf('RMS Amplitude: %.4f\n', rms_amplitude);

%% 5. Plot full time-domain waveform

figure('Name', 'SAGE-RF Signal Viewer');

plot(t, x_mono);

xlabel('Time (seconds)');
ylabel('Amplitude');
title('Audio Signal - Full Time Domain');

grid on;

%% 6. Plot zoomed waveform (first 0.5 seconds)

zoom_duration = min(0.5, duration);

zoom_samples = max(1, floor(zoom_duration * Fs));

zoom_signal = x_mono(1:zoom_samples);

zoom_time = t(1:zoom_samples);

figure('Name', 'SAGE-RF Zoomed Signal');

plot(zoom_time, zoom_signal);

xlabel('Time (seconds)');
ylabel('Amplitude');

title('Zoomed Audio Waveform - First 0.5 Seconds');

grid on;

%% 7. Diagnose zoomed signal

fprintf('\n===== ZOOMED SIGNAL CHECK =====\n');

fprintf('Minimum: %.8f\n', min(zoom_signal));
fprintf('Maximum: %.8f\n', max(zoom_signal));

fprintf('Peak: %.8f\n', max(abs(zoom_signal)));

%% 8. Perform FFT analysis

Y = fft(x_mono);

P2 = abs(Y/N);

P1 = P2(1:floor(N/2)+1);

% Calculate single-sided amplitude spectrum

if rem(N, 2) == 0

    % Even number of samples
    P1(2:end-1) = 2 * P1(2:end-1);

else

    % Odd number of samples
    P1(2:end) = 2 * P1(2:end);

end

% Frequency axis

f = Fs*(0:floor(N/2))/N;

%% 9. Find dominant frequency

if length(P1) > 1

    [~, index] = max(P1(2:end));

    dominant_frequency = f(index + 1);

else

    dominant_frequency = 0;

end

fprintf('\n===== FREQUENCY ANALYSIS =====\n');

fprintf('Dominant Frequency: %.2f Hz\n', ...
    dominant_frequency);

%% 10. Plot frequency spectrum

figure('Name', 'SAGE-RF FFT Analyzer');

plot(f, P1);

xlabel('Frequency (Hz)');
ylabel('Magnitude');

title('Audio Frequency Spectrum');

grid on;

xlim([0 Fs/2]);

%% 11. Play original audio

disp('Playing original audio...');

sound(x, Fs);

disp('Signal analysis completed!');

end
