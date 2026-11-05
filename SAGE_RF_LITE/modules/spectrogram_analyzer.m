
function spectrogram_analyzer()

clc;
close all;

%% 1. Select audio file

[file, path] = uigetfile( ...
    {'*.wav', 'WAV Audio Files (*.wav)'}, ...
    'Select Audio File');

if isequal(file, 0)
    disp('No file selected.');
    return;
end

[x, Fs] = audioread(fullfile(path, file));

%% 2. Convert stereo to mono

if size(x, 2) == 2
    x = mean(x, 2);
end

N = length(x);

%% 3. Configure STFT

frameLength = min(2048, N);

hopLength = max(1, floor(frameLength/4));

nfft = 2^nextpow2(frameLength);

% Create Hann window manually

n = (0:frameLength-1)';

if frameLength > 1
    window = 0.5 - 0.5*cos(2*pi*n/(frameLength-1));
else
    window = 1;
end

%% 4. Divide signal into frames

frameStarts = 1:hopLength:(N-frameLength+1);

numFrames = length(frameStarts);

%% 5. Calculate Short-Time Fourier Transform

S = zeros(nfft/2+1, numFrames);

for k = 1:numFrames

    startIndex = frameStarts(k);

    frame = x(startIndex:startIndex+frameLength-1);

    % Apply window

    frame = frame .* window;

    % FFT of current frame

    Y = fft(frame, nfft);

    % Calculate single-sided magnitude

    magnitude = abs(Y(1:nfft/2+1)) / sum(window);

    % Double positive-frequency components

    if rem(nfft, 2) == 0
        magnitude(2:end-1) = 2*magnitude(2:end-1);
    else
        magnitude(2:end) = 2*magnitude(2:end);
    end

    S(:, k) = magnitude;

end

%% 6. Convert magnitude to decibels

S_dB = 20*log10(max(S, 1e-8));

%% 7. Create time and frequency axes

frequencies = Fs*(0:nfft/2)/nfft;

times = (frameStarts + (frameLength-1)/2)/Fs;

%% 8. Display signal information

fprintf('\n===== SAGE-RF SPECTROGRAM ANALYZER =====\n');

fprintf('File: %s\n', file);
fprintf('Sampling Frequency: %d Hz\n', Fs);
fprintf('Duration: %.2f seconds\n', N/Fs);
fprintf('Frame Length: %d samples\n', frameLength);
fprintf('Hop Length: %d samples\n', hopLength);
fprintf('FFT Size: %d\n', nfft);
fprintf('Number of Frames: %d\n', numFrames);

%% 9. Plot spectrogram

figure('Name', 'SAGE-RF Spectrogram Analyzer');

imagesc(times, frequencies, S_dB);

zoom off;
axis normal;

xlim([0 N/Fs]);
ylim([0 min(10000, Fs/2)]);

axis xy;

xlabel('Time (seconds)');
ylabel('Frequency (Hz)');

title('Audio Spectrogram - STFT');

ylim([0 min(10000, Fs/2)]);

colorbar;

colormap(jet);

clim([max(S_dB(:))-80, max(S_dB(:))]);

%% 10. Completion

fprintf('\nSpectrogram Analysis Completed!\n');

end
