
clc;
clear;
close all;

%% SAGE-RF LITE
% Module 1: Signal Generation and Analysis

%% 1. Generate a test signal

Fs = 8000;          % Sampling frequency
duration = 2;       % Duration in seconds

t = 0:1/Fs:duration-1/Fs;

% Three frequency components
f1 = 300;
f2 = 1000;
f3 = 1800;

x = sin(2*pi*f1*t) ...
    + 0.7*sin(2*pi*f2*t) ...
    + 0.5*sin(2*pi*f3*t);

%% 2. Add background noise

noise = 0.2 * randn(size(x));

noisy_signal = x + noise;

%% 3. Display signal information

fprintf('\n===== SAGE-RF LITE =====\n');

fprintf('Sampling Frequency: %d Hz\n', Fs);
fprintf('Duration: %.2f seconds\n', duration);
fprintf('Total Samples: %d\n', length(x));

%% 4. Plot time-domain waveform

figure('Name', 'SAGE-RF Signal Viewer');

plot(t, noisy_signal);

xlabel('Time (seconds)');
ylabel('Amplitude');

title('Noisy Input Signal');

grid on;

%% 5. Perform FFT

N = length(noisy_signal);

Y = fft(noisy_signal);

% Calculate single-sided amplitude spectrum

P2 = abs(Y/N);

P1 = P2(1:N/2+1);

P1(2:end-1) = 2*P1(2:end-1);

% Frequency axis

f = Fs*(0:N/2)/N;

%% 6. Plot frequency spectrum

figure('Name', 'SAGE-RF FFT Analyzer');

plot(f, P1);

xlabel('Frequency (Hz)');
ylabel('Magnitude');

title('Single-Sided Amplitude Spectrum');

grid on;

xlim([0 Fs/2]);

%% 7. Display expected frequency components

fprintf('\nExpected Frequency Components:\n');

fprintf('%d Hz\n', f1);
fprintf('%d Hz\n', f2);
fprintf('%d Hz\n', f3);

fprintf('\nSignal analysis completed!\n');
