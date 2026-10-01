% Bronwyn Biggs BGGBRO002 -- in partial fulfulment of a EEE4022S research project
% The code has been adapted from Gengan Joachim's GitHub and adapted by Dr M. Y. Abdul Gaffar

% Contains code for processing a measured received signal from a CW ultrasonic radar system.
% The received signal is recorded by the Teensy ADC and saved to a CSV file. The measured signal is then bandpass filtered, notch filtered,
% downmixed to baseband, low-pass filtered, and analysed using a spectrogram to estimate Doppler frequency and target velocity.

clear;
clc;
close all;

fc = 40e3; % Transmitter carrier frequency
c = 343; % Speed of sound in air

%==============================================================
% CHOOSE FILE AND SAMPLING FREQUENCY
% Fs = 100e3;
%fileID = fopen('trolley_test1_0dB_slow.bin', 'r');
%fileID = fopen('trolley_test5_0dB_MED.bin', 'r');
% fileID = fopen('trolley_test8_0dB_FAST.bin', 'r');


% HAND TESTS
Fs=100e3;
%fileID = fopen('hand_test1_0dB_100k.bin', 'r');
%fileID = fopen('hand_test1_0dB_200k.bin', 'r');
%fileID = fopen('hand_test1_0dB_300k.bin', 'r');
fileID = fopen('walking_test1_0dB_100k.bin', 'r');

%Fs = 200e3;
%fileID = fopen('trolley_test1_0dB_200k_MED.bin', 'r');
%fileID = fopen('trolley_test1_0dB_200k_FAST.bin', 'r');
%================================================================

received_signal = fread(fileID, Inf, 'uint16');
fclose(fileID);

%t = (0:length(received_signal)-1) / Fs;
t = (0:length(received_signal)-1)' / Fs;
duration = length(received_signal) / Fs;

fprintf('Sampling frequency: %.2f Hz\n', Fs);
fprintf('Recording duration: %.4f s\n', duration);
fprintf('Number of samples: %d\n', length(received_signal));

% filename = '1V_TESTING_100K_10s_2026-09-28_11-21-35.csv';
% received_signal = readmatrix(filename);
% Fs = 100e3;  % Sampling frequency
% t = (0:length(received_signal)-1) / Fs;
% duration = length(received_signal) / Fs;
% fprintf('Sampling frequency: %.2f Hz\n', Fs);
% fprintf('Recording duration: %.4f s\n', duration);
% fprintf('Number of samples: %d\n', length(received_signal));

%% Load recorded signal from CW ultrasonic radar -- FIGURE 1
% filename = '1V_TESTING_100K_10s_2026-09-28_11-21-35.csv';
% data = readmatrix(filename); % Read the CSV file
% time_us = data(:,1); % Column 1 = time in microseconds 
% received_signal = data(:,2); % Column 2 = ADC value
% 
% % Remove any rows containing invalid or missing data
% valid_indices = ~isnan(time_us) & ~isnan(received_signal);
% time_us = time_us(valid_indices);
% received_signal = received_signal(valid_indices);
% 
% t = time_us * 1e-6; % Convert time from us to s
% 
% sample_interval = mean(diff(t)); 
% Fs = 1 / sample_interval; % Calculate sampling frequency from measured timestamps
% duration = t(end) - t(1); % Calculate duration of measured recording
% 
% fprintf('Measured recording duration: %.4f s\n', duration);
% fprintf('Measured sampling frequency: %.2f Hz\n', Fs);
% fprintf('Number of samples: %d\n', length(received_signal));

% Plot measured time signal
figure;
plot(t*1e3, received_signal); % Change time values from seconds to ms
xlabel('Time (ms)');
ylabel('ADC Value');
title('Measured Received Ultrasonic Signal');
grid on;
xlim([0 1]);

%% Convert to frequency spectrum -- FIGURE 2
N = length(received_signal); % Number of samples in the received signal
Y = fft(received_signal); % Calculate FFT

twoSidedMagnitude = abs(Y/N); % Normalised and find magnitude
frequencyAxis = Fs*(-N/2:N/2-1)/N; % Frequency axis for positive and negative frequencies
twoSidedMagnitude = fftshift(twoSidedMagnitude); % Shift zero frequency to centre

figure;
plot(frequencyAxis/1e3, twoSidedMagnitude);
xlabel('Frequency (kHz)');
ylabel('Magnitude');
title('Frequency Spectrum of Measured Received Signal');
grid on;
xlim([-100 100]);

%% Digital bandpass filter -- FIGURE 3
% Remove any noise outside the 30kHz to 50kHz range
%[b_bandpass, a_bandpass] = butter(4, [30e3 50e3]/(Fs/2), 'bandpass'); % Fs/2 is Nyquist frequency
[b_bandpass, a_bandpass] = butter(4, [30e3 48e3]/(Fs/2), 'bandpass');

bandpassed_signal = filtfilt(b_bandpass, a_bandpass, received_signal);

freq_bandpass = fft(bandpassed_signal);
twoSidedMagnitude_bandpass = abs(freq_bandpass/N);
twoSidedMagnitude_bandpass = fftshift(twoSidedMagnitude_bandpass);

figure;
plot(frequencyAxis/1e3, twoSidedMagnitude_bandpass);
xlabel('Frequency (kHz)');
ylabel('Magnitude');
title('Frequency Spectrum After Bandpass Filter');
grid on;
xlim([-50 50]);


%% Digital notch filter -- NOTCH 4
% Remove the carrier frequency component at 40kHz
[b_notch, a_notch] = butter(4, [39.9e3 40.1e3]/(Fs/2), 'stop');

notched_signal = filtfilt(b_notch, a_notch, bandpassed_signal);

% Frequency spectrum of notched signal -- Figure 4
Y_notched = fft(notched_signal);
twoSidedMagnitude_notched = abs(Y_notched/N);
twoSidedMagnitude_notched = fftshift(twoSidedMagnitude_notched);

figure;
plot(frequencyAxis/1e3, twoSidedMagnitude_notched);
xlabel('Frequency (kHz)');
ylabel('Magnitude');
title('Frequency Spectrum After Notch Filter');
grid on;
xlim([-50 50]);
ylim([0 0.35]);


%% Downmixing
% Before this there are +43k and -43k components
% Multiplication by a sinusoid creates two frequency shifted copies, one at 43.23-40 = +3.23k and 43.23+40 = 83.23k
% Then there are also components at -3.23K and -83.2k due to the negative component
I_beforeLPF = notched_signal.*cos(2*pi*fc*t);
% I and Q have different amplitudes/phases
Q_beforeLPF = notched_signal.*-sin(2*pi*fc*t);

%% Digital low-pass filter -- FIGURE 5
% To isolate Doppler components
cutoffFrequency = 10e3;
[b, a] = butter(5, cutoffFrequency/(Fs/2));
[h, f] = freqz(b, a, 1024, Fs);

figure;
plot(f, 20*log10(abs(h)));
grid on;
title('Frequency Response of Doppler Low-Pass Filter');
xlabel('Frequency (Hz)');
ylabel('Magnitude (dB)');
xlim([0 Fs/2]);

I_afterLPF = filtfilt(b, a, I_beforeLPF);
Q_afterLPF = filtfilt(b, a, Q_beforeLPF);

%% Extract the doppler frequency -- FIGURE 6
% The combination of I and Q causes one of the frequency components to cancel while the other is reinforced
complexBaseband = I_afterLPF + 1i*Q_afterLPF;
% baseband_magnitude = sqrt(I_afterLPF.^2 + Q_afterLPF.^2);
N_baseband = length(complexBaseband);
f_baseband = (-N_baseband/2:N_baseband/2-1)*(Fs/N_baseband);

baseband_FFT = fft(complexBaseband);
baseband_FFTShifted = fftshift(baseband_FFT);

figure;
plot(f_baseband/1e3, abs(baseband_FFTShifted)/N_baseband);
xlabel('Frequency (kHz)', 'fontsize', 12);
ylabel('Magnitude', 'fontsize', 12);
title('FFT Shift of Baseband Signal', 'fontsize', 12);
grid on;
xlim([-5 5]);

%% Spectrogram -- FIGURE 7
%W = 1024; % Window length -- each section used to calculate the spectrogram contains 1024 samples
cpi_duration = 0.01024; % CPI / spectrogram window duration in seconds
W = round(cpi_duration * Fs); % Window length in samples


% The time represented by each window now depends on the measured sampling frequenc
windowDuration_ms = (W/Fs)*1e3;
fprintf('Spectrogram CPI: %.3f s\n', cpi_duration);
fprintf('Spectrogram window length: %d samples\n', W);
fprintf('Spectrogram window duration: %.3f ms\n', windowDuration_ms);

%O = 512; % 50% overlap means consecutive windows overlap by 512 samples
O = round(W/2); % 50% overlap
nfft = 4096; % FFT length -- 4096 point FFT for each 1024 sample window
frequencyResolution = Fs/nfft; % Frequency resolution is determined by Fs/nfft
fprintf('Spectrogram frequency resolution: %.2f Hz\n', frequencyResolution);

w = hamming(W); % Hamming window gradually reduces the signal toward the edges -- reduce spectral leakage
[S, F, T] = spectrogram(complexBaseband, w, O, nfft, Fs, 'centered'); % 'S' contains the complex FFT results for every window
% S_dB = 20*log10(abs(S) + eps); % Convert magnitude to dB
% 'eps' is an extremely small positive number in MATLAB to prevent calculating log10(0)

% Ignore the first and last 50 ms to remove possible recording/filter transients (only applied if the recording is long enough)
trimTime_s = 0.05;
time_indices = (T >= trimTime_s) & (T <= duration - trimTime_s);
T_OfInterest = T(time_indices);
S_OfInterest = S(:, time_indices);

S_OfInterestToPlot = abs(S_OfInterest) / max(abs(S_OfInterest(:))); % Normalise spectrogram
clims = [-50 0]; % dB range displayed by the spectrogram

figure;
imagesc(T_OfInterest, F/1e3, 20*log10(S_OfInterestToPlot + eps), clims);
axis xy;
xlabel('Time (s)');
ylabel('Frequency (kHz)');
title('Spectrogram of Measured Doppler Signal');
colormap('jet'); % Abdul Gaffar
colorbar;
ylim([-5 5]);

%% Doppler frequency to velocity -- FIGURE 8

lambda = c / fc; % Wavelength of transmitted ultrasonic wave (m)
speed_m_per_sec = F * lambda / 2; % Convert Doppler frequency to velocity
speed_km_per_hr = speed_m_per_sec * 3.6; % Convert m/s to km/h
maxSpeed_km_hr = 120;
minSpeed_km_hr = -120;

maxSpeed_ms = maxSpeed_km_hr*1000/3600;
minSpeed_ms = minSpeed_km_hr*1000/3600;

velocity_indices = find((speed_km_per_hr <= maxSpeed_km_hr) & (speed_km_per_hr >= minSpeed_km_hr));
velocity_indices_ms = find((speed_m_per_sec <= maxSpeed_ms) & (speed_m_per_sec >= minSpeed_ms));

SpeedVectorOfInterest = speed_km_per_hr(velocity_indices); % Matrix S contains rows (frequency) and columns (time)
S_OfInterest = S(velocity_indices, time_indices); % Select only the velocity range of interest

SpeedVectorOfInterest_ms = speed_m_per_sec(velocity_indices_ms); % Matrix S contains rows (frequency) and columns (time)
S_OfInterest_ms = S(velocity_indices_ms, time_indices); % Select only the velocity range of interest

S_OfInterestToPlot = abs(S_OfInterest) / max(abs(S_OfInterest(:))); % Normalise spectrogram
S_OfInterestToPlot_ms = abs(S_OfInterest_ms) / max(abs(S_OfInterest_ms(:))); % Normalise spectrogram
clims = [-50 0]; % dB range displayed by the spectrogram

figure;
imagesc(T_OfInterest, SpeedVectorOfInterest, 20*log10(S_OfInterestToPlot + eps), clims);
xlabel('Time (s)');
ylabel('Velocity (km/h)');
title('Spectrogram of Measured Doppler Signal - Velocity');
grid on;
colormap('jet'); % Abdul Gaffar
colorbar;
axis xy;
ylim([-50 50]);

figure;
imagesc(T_OfInterest, SpeedVectorOfInterest_ms, 20*log10(S_OfInterestToPlot_ms + eps), clims);
xlabel('Time (s)');
ylabel('Velocity (m/s)');
title(sprintf('Spectrogram of Measured Doppler Signal - Velocity (Fs=%.0f kHz)', Fs/1e3));
grid on;
colormap('jet'); % Abdul Gaffar
colorbar;
axis xy;
ylim([-8 8]);