
function fft_analyzer()

clc;
close all;

%% 1. Select audio file

[file, path] = uigetfile( ...
    {'*.wav', 'WAV Audio Files (*.wav)'}, ...
    'Select Audio for FFT Analysis');

if isequal(file, 0)
    disp('No file selected.');
    return;
end

[x, Fs] = audioread(fullfile(path, file));

%% 2. Convert stereo to mono

if size(x, 2) == 2
    x = mean(x, 2);
end

%% 3. Signal information

N = length(x);

fprintf('\n===== SAGE-RF FFT ANALYZER =====\n');
fprintf('File: %s\n', file);
fprintf('Sampling Frequency: %d Hz\n', Fs);
fprintf('Number of Samples: %d\n', N);
fprintf('Frequency Resolution: %.4f Hz\n', Fs/N);

%% 4. Apply Hann window

n = (0:N-1)';

if N > 1
    window = 0.5 - 0.5*cos(2*pi*n/(N-1));
else
    window = 1;
end

windowed_signal = x .* window;

%% 5. Calculate FFT

Y = fft(windowed_signal);

P2 = abs(Y) / sum(window);

P1 = P2(1:floor(N/2)+1);

% Single-sided amplitude spectrum

if rem(N, 2) == 0
    P1(2:end-1) = 2*P1(2:end-1);
else
    P1(2:end) = 2*P1(2:end);
end

f = Fs*(0:floor(N/2))/N;

%% 6. Find dominant frequency

if length(P1) > 1

    [~, index] = max(P1(2:end));

    dominant_frequency = f(index+1);
    dominant_magnitude = P1(index+1);

else

    dominant_frequency = 0;
    dominant_magnitude = 0;

end

fprintf('\n===== DOMINANT FREQUENCY =====\n');

fprintf('Frequency: %.2f Hz\n', dominant_frequency);
fprintf('Magnitude: %.6f\n', dominant_magnitude);

%% 7. Detect prominent frequency peaks

% Find local maxima, excluding DC and frequencies below 20 Hz

if length(P1) >= 3

    local_maxima = ...
        P1(2:end-1) > P1(1:end-2) & ...
        P1(2:end-1) >= P1(3:end);

    candidate_indices = find(local_maxima) + 1;

    candidate_indices = candidate_indices( ...
        f(candidate_indices) >= 20);

else

    candidate_indices = [];

end

% Sort peaks by magnitude

[~, order] = sort(P1(candidate_indices), 'descend');

candidate_indices = candidate_indices(order);

% Select up to 10 peaks, separated by at least 10 Hz

selected_indices = [];

for k = 1:length(candidate_indices)

    current_index = candidate_indices(k);

    if isempty(selected_indices) || ...
       all(abs(f(current_index) - ...
       f(selected_indices)) >= 10)

        selected_indices(end+1) = current_index;

    end

    if length(selected_indices) == 10
        break;
    end

end

%% 8. Display top frequency peaks

fprintf('\n===== TOP FREQUENCY PEAKS =====\n');

fprintf('%-15s %-15s\n', 'Frequency', 'Magnitude');

for k = 1:length(selected_indices)

    idx = selected_indices(k);

    fprintf('%-15.2f %-15.6f\n', ...
        f(idx), P1(idx));

end

%% 9. Plot full frequency spectrum

figure('Name', 'SAGE-RF Full FFT Spectrum');

plot(f, P1);

xlabel('Frequency (Hz)');
ylabel('Magnitude');

title('Full Frequency Spectrum');

grid on;
xlim([0 Fs/2]);

%% 10. Plot low-frequency spectrum

figure('Name', 'SAGE-RF Low Frequency Analysis');

plot(f, P1);

hold on;

% Mark detected peaks

if ~isempty(selected_indices)

    plot(f(selected_indices), ...
         P1(selected_indices), 'ro', ...
         'MarkerSize', 5);

end

xlabel('Frequency (Hz)');
ylabel('Magnitude');

title('Low Frequency Spectrum (20–2000 Hz)');

grid on;
xlim([20 min(2000, Fs/2)]);

hold off;

%% 11. Completion

fprintf('\nFFT Analysis Completed!\n');

end
