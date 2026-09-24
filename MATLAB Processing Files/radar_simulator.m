% Bronwy Biggs BGGBRO002 -- in partial fulfulment of a EEE4022S research project
% The code has been adapted from Gengan Joachim's GitHub and adapted by Dr M. Y. Abdul Gaffar

% Contains code for simulating a received signal

clear;
clc;
close all;

%% Synthetic Received Signal for CW Ultrasonic Radar -- Figure 1
fc = 40e3; % Transmitter carrier frequency
c = 343; % Speed of sound in air

target_speed_kmh = 50;
v = target_speed_kmh / 3.6; % Convert to m/s
fd = (2 * v * fc) / c; % Doppler frequency

% Received echo for a target moving TOWARDS the radar
fr = fc + fd;

fprintf('Target speed: %.2f km/h\n', target_speed_kmh);
fprintf('Target speed: %.2f m/s\n', v);
fprintf('Doppler frequency: %.2f Hz\n', fd);
fprintf('Echo frequency: %.2f Hz\n', fr);

% Sampling
Fs = 400e3; % Sampling frequency = 400 kHz (400 000 samples every second OR one sample every 2.5 us)
duration = 1; % Generate the synthetic signal for 5 ms

t = 0:1/Fs:duration-1/Fs; % Start at t=0 with 25us between samples until (5 ms-25 us) giving exactly 5 ms of samples

A_carrier = 10.9/2; % Amplitude of transmitted carrier
A_echo = 0.3; % Amplitude of reflected echo -- MADE UP VALUE

carrier = A_carrier * sin(2*pi*fc*t);
echo = A_echo * sin(2*pi*fr*t);

received_signal = carrier + echo;

% Plotting time signal
figure;
plot(t*1e3, received_signal); % Change time values from us to ms
xlabel('Time (ms)');
ylabel('Amplitude');
title('Synthetic Received Ultrasonic Signal');
grid on;
xlim([0 0.2]);


%% Frequency spectrum -- Figure 2 (double sided)
N = length(received_signal); % Number of samples in the received signal
Y = fft(received_signal); % Calculate FFT

twoSidedMagnitude = abs(Y/N); % Normalised and find magnitude
frequencyAxis = Fs*(-N/2:N/2-1)/N; % Frequency axis for positive and negative frequencies
twoSidedMagnitude = fftshift(twoSidedMagnitude); % Shift zero frequency to centre

figure;
plot(frequencyAxis/1e3, twoSidedMagnitude);
xlabel('Frequency (kHz)');
ylabel('Magnitude');
title('Frequency Spectrum of Received Signal');
grid on;
xlim([-50 50]);


%% 30-50 kHz Bandpass filter -- Figure 3
[b_bandpass, a_bandpass] = butter(4, [30e3 50e3]/(Fs/2), 'bandpass'); % Fs/2 is Nyquist frequency
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

%% 40 kHz notch filter -- Figure 4
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

%% Low-pass filter the mixed signals to isolate Doppler components -- Figure 5
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

%% Extract doppler frequency -- Figure 6
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

%% Spectrogram -- Figure 7
W = 1024; % Window length -- each section used to calculate the spectrogram contains 1024 samples
% each sample is 1/400000 = 2.5 us so 1024 samples correspond to = 2.56 ms

O = 512; % 50% overlap means consecutive windows overlap by 512 samples
nfft = 4096; % FFT length -- 4096 point FFT for each 1024 sample window
% 4096/400000 = 97.7 Hz so the frequency bins go 97.7, 195.4, 293.1 etc

w = hamming(W); % Hamming window gradually reduces the signal toward the edges -- reduce spectral leakage

% Calculate spectrogram
[S, F, T] = spectrogram(complexBaseband, w, O, nfft, Fs, 'centered'); % 'S' contains the complex FFT results for every window
S_dB = 20*log10(abs(S) + eps); % Convert magnitude to dB
% 'eps' is an extremely small positive number in MATLAB to prevent calculating log10(0)

figure;
imagesc(T, F/1e3, S_dB); % Displays the matrix as an image
axis xy;
xlabel('Time (s)');
ylabel('Frequency (kHz)');
title('Spectrogram of Doppler Signal');
colorbar;
ylim([-5 5]);


%% Doppler frequency to velocity -- Figure 8
lambda = c / fc; % Wavelength of transmitted ultrasonic wave (m)
speed_m_per_sec = F * lambda / 2; % Convert Doppler frequency to velocity
speed_km_per_hr = speed_m_per_sec * 3.6; % Convert m/s to km/h

maxSpeed_km_hr = 120;
minSpeed_km_hr = -120;

velocity_indices  = find((speed_km_per_hr <= maxSpeed_km_hr) & (speed_km_per_hr >= minSpeed_km_hr));
% Matrix S contains rows (frequency) and columns (time)
SpeedVectorOfInterest = speed_km_per_hr(velocity_indices);
S_OfInterest = S(velocity_indices, :); %Keeping all columns but using the selected interest rows

S_OfInterestToPlot = abs(S_OfInterest) / max(abs(S_OfInterest(:))); % Normalise spectrogram

clims = [-50 0]; % dB range displayed by the spectrogram
figure;
imagesc(T, SpeedVectorOfInterest, 20*log10(S_OfInterestToPlot + eps), clims);
xlabel('Time (s)');
ylabel('Velocity (km/h)');
title('Spectrogram of Doppler Signal - Velocity');
grid on;
colorbar;
axis xy;