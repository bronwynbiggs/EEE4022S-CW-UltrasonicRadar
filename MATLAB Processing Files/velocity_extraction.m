% Bronwyn Biggs BGGBRO002 -- in partial fulfulment of a EEE4022S research project
% The code has been adapted from Gengan Joachim's GitHub and adapted by Dr M. Y. Abdul Gaffar
 
% WHAT THIS PROGRAM DOES:
% An ultrasonic transmitter sends out a constant 40 kHz ultrasonic tone (a "CW" = continuous wave radar)
% When the tone bounces off a moving object its frequency shifts slightly
% This shift is called the "Doppler shift", and it tells us how fast the object is moving
% A microphone picks up the echo and a Teensy 4.1 microocntroller board records it to a binary file
% This script then:
%   1. Imports the recorded binary file
%   2. Cleans it with bandpass and notch filters to remove noise and
%   spectral leakage
%   3. Moves the signal down to near 0 Hz (quadrature downmixing) so the Doppler shift is easy to see
%   4. Makes a spectrogram, both frequency vs time and speed vs time
%   5. Converts frequency to speed and finds the vehicle's speed over time
%   6. Compares the result to a known reference speed and calculates the error


% Bronwyn Biggs BGGBRO002 -- in partial fulfulment of a EEE4022S research project
% The code has been adapted from Gengan Joachim's GitHub and adapted by Dr M. Y. Abdul Gaffar

% Contains code for processing a measured received signal from a CW ultrasonic radar system.
% The received signal is recorded by the Teensy ADC and saved to a CSV file. The measured signal is then bandpass filtered, notch filtered,
% downmixed to baseband, low-pass filtered, and analysed using a spectrogram to estimate Doppler frequency and target velocity.

clear; % Delete all old variables from memory
clc; % Clear the command window text
close all; % Close any figures that are still open
 
fc = 40e3; % Transmitter carrier frequency = 40 kHz
c = 343; % Speed of sound (m/s)

%% CHOOSE FILE AND SAMPLING FREQUENCY
Fs=100e3; % Sampling frequency (100,000 measurements every second)
 
% Open the recorded data file so we can read it ('r' = read mode)
% 'fullfile' joins the folder name and file name
fileID = fopen(fullfile('11_10 Vehicle Tests', '11_10_VEHICLE_test_1_100k_20kmh_5s.bin'), 'r');
 
% Video-derived speed, used later for performance metrics
referenceSpeed_ms = 5.41;

received_signal = fread(fileID, Inf, 'uint16'); % Read every value in the file as 16-bit whole numbers
fclose(fileID); % Close the file when done reading 

% Time axis: sample number divided by sampling rate gives the time of each sample in seconds
% The ' at the end turns the row into a column so it matches the signal's shape
t = (0:length(received_signal)-1)' / Fs;
duration = length(received_signal) / Fs; % Total recording length in seconds
 
% Print basic information about the recording to the command window
fprintf('Sampling frequency: %.2f Hz\n', Fs);
fprintf('Recording duration: %.4f s\n', duration);
fprintf('Number of samples: %d\n', length(received_signal));
 
% Plot measured time signal -- FIGURE 1
figure;
plot(t*1e3, received_signal); % Multiply by 1000 to change time from seconds to ms
xlabel('Time (ms)');
ylabel('ADC Value'); 
title('Measured Received Ultrasonic Signal');
grid on;
xlim([0 1]);% Only show 0 to 1 ms so the wave is visible


%% Convert to frequency spectrum -- FIGURE 2
% FFT shows which frequencies are inside the signal
N = length(received_signal); % Number of samples in the received signal
Y = fft(received_signal); % Calculate the FFT
 
twoSidedMagnitude = abs(Y/N); % Normalised and find magnitude
frequencyAxis = Fs*(-N/2:N/2-1)/N; % Frequency axis for positive and negative frequencies
twoSidedMagnitude = fftshift(twoSidedMagnitude); % Shift zero frequency to centre
 
% figure;
% plot(frequencyAxis/1e3, twoSidedMagnitude);
% xlabel('Frequency (kHz)');
% ylabel('Magnitude');
% title('Frequency Spectrum of Measured Received Signal');
% grid on;
% xlim([-100 100]);

%% Digital bandpass filter -- FIGURE 3
% Remove any noise outside the 30kHz to 50kHz range
[b_bandpass, a_bandpass] = butter(4, [30e3 48e3]/(Fs/2), 'bandpass'); % Fs/2 is Nyquist frequency

% filtfilt applies the filter forwards and then backwards so the signal is not delayed in time
bandpassed_signal = filtfilt(b_bandpass, a_bandpass, received_signal);

% FFT of the filtered signal so we can check the filter worked
freq_bandpass = fft(bandpassed_signal);
twoSidedMagnitude_bandpass = abs(freq_bandpass/N);
twoSidedMagnitude_bandpass = fftshift(twoSidedMagnitude_bandpass);

% figure;
% plot(frequencyAxis/1e3, twoSidedMagnitude_bandpass);
% xlabel('Frequency (kHz)');
% ylabel('Magnitude');
% title('Frequency Spectrum After Bandpass Filter');
% grid on;
% xlim([-50 50]);

%% Digital notch filter -- FIGURE 4
% Remove the carrier frequency component at 40kHz
[b_notch, a_notch] = butter(4, [39.9e3 40.1e3]/(Fs/2), 'stop');

notched_signal = filtfilt(b_notch, a_notch, bandpassed_signal);

% FFT of the filtered signal so we can check the filter worked
Y_notched = fft(notched_signal);
twoSidedMagnitude_notched = abs(Y_notched/N);
twoSidedMagnitude_notched = fftshift(twoSidedMagnitude_notched);

% figure;
% plot(frequencyAxis/1e3, twoSidedMagnitude_notched);
% xlabel('Frequency (kHz)');
% ylabel('Magnitude');
% title('Frequency Spectrum After Notch Filter');
% grid on;
% xlim([-50 50]);
% ylim([0 0.35]);


%% Downmixing
% Before this there are +43k and -43k components
% Multiplication by a sinusoid creates two frequency shifted copies, one at 43.23-40 = +3.23k and 43.23+40 = 83.23k
% Then there are also components at -3.23K and -83.2k due to the negative component

% I and Q have different amplitudes/phases
I_beforeLPF = notched_signal.*cos(2*pi*fc*t);
Q_beforeLPF = notched_signal.*-sin(2*pi*fc*t);

%% Digital low-pass filter -- FIGURE 5
% To isolate Doppler components
cutoffFrequency = 10e3;
[b, a] = butter(5, cutoffFrequency/(Fs/2));
[h, f] = freqz(b, a, 1024, Fs);

% figure;
% plot(f, 20*log10(abs(h)));
% grid on;
% title('Frequency Response of Doppler Low-Pass Filter');
% xlabel('Frequency (Hz)');
% ylabel('Magnitude (dB)');
% xlim([0 Fs/2]);

% Apply the low-pass filter to both I and Q
I_afterLPF = filtfilt(b, a, I_beforeLPF);
Q_afterLPF = filtfilt(b, a, Q_beforeLPF);

%% Extract the doppler frequency -- FIGURE 6
% Combine I and Q into one complex number: I + jQ 
complexBaseband = I_afterLPF + 1i*Q_afterLPF;

N_baseband = length(complexBaseband); % Number of samples in the baseband signal
f_baseband = (-N_baseband/2:N_baseband/2-1)*(Fs/N_baseband); % Frequency axis for the plot
 
baseband_FFT = fft(complexBaseband); % Frequency content of the baseband signal
baseband_FFTShifted = fftshift(baseband_FFT); % Put 0 Hz in the middle
 
% figure;
% plot(f_baseband/1e3, abs(baseband_FFTShifted)/N_baseband);
% xlabel('Frequency (kHz)', 'fontsize', 12);
% ylabel('Magnitude', 'fontsize', 12);
% title('FFT Shift of Baseband Signal', 'fontsize', 12);
% grid on;
% xlim([-5 5]);

%% Spectrogram -- FIGURE 7
cpi_duration = 0.01024; % Length of each window in seconds (CPI = coherent processing interval)
W_temp = round(cpi_duration * Fs); % Convert that time into a number of samples
W = 2^nextpow2(W_temp); % Round up to a power of 2 (e.g. 1024), which makes the FFT faster

% The time represented by each window now depends on the measured sampling
% frequency
windowDuration_ms = (W/Fs)*1e3;

%O = 512; % 50% overlap means consecutive windows overlap by 512 samples
O = round(W/2); % 50% overlap

nfft = 4*W; % FFT length is 4 times the window and zero padding gives a smoother picture

frequencyResolution = Fs/nfft; % Smallest frequency step we can see
 
% Print the spectrogram settings
fprintf('Spectrogram CPI requested: %.5f s\n', cpi_duration);
fprintf('Original window length: %d samples\n', W_temp);
fprintf('Rounded window length: %d samples\n', W);
fprintf('Spectrogram window duration: %.3f ms\n', windowDuration_ms);
fprintf('Overlap: %d samples (50%%)\n', O);
fprintf('NFFT: %d\n', nfft);
fprintf('Spectrogram frequency resolution: %.2f Hz\n', frequencyResolution);
 
w = hamming(W); % Hamming window fades the signal in and out at the edges of each piece to reduce "spectral leakage" (smearing)

% S = complex FFT result for every window (rows = frequency, columns = time)
% F = list of frequencies for the rows
% T = list of times for the columns
% 'centered' = show negative and positive frequencies with 0 Hz in the middle
[S, F, T] = spectrogram(complexBaseband, w, O, nfft, Fs, 'centered');

 
% Ignore the first and last 50 ms because filters often cause glitches at the ends of a recording
trimTime_s = 0.05;
time_indices = (T >= trimTime_s) & (T <= duration - trimTime_s); % True for every time we want to keep
T_OfInterest = T(time_indices); % Keep only those times
S_OfInterest = S(:, time_indices); % Keep only those columns of the spectrogram
 
S_OfInterestToPlot = abs(S_OfInterest) / max(abs(S_OfInterest(:))); % Take magnitude and divide by the biggest value so the max = 1
clims = [-30 0]; % Colour range in dB from -30 dB (weak) to 0 dB (strongest)
 
% Draw the spectrogram frequency vs time
figure;
imagesc(T_OfInterest, F/1e3, 20*log10(S_OfInterestToPlot + eps), clims); % 20*log10 converts to decibels
axis xy; 
xlabel('Time (s)');
ylabel('Frequency (kHz)');
title('Spectrogram of Measured Doppler Signal');
colormap('jet'); % Abdul Gaffar
colorbar; 
ylim([-2 2]); 
xlim([0 5]);


%% Doppler frequency to velocity -- FIGURE 8
lambda = c / fc; % Wavelength of transmitted ultrasonic wave (m)
speed_m_per_sec = F * lambda / 2; % Convert Doppler frequency to velocity
speed_km_per_hr = speed_m_per_sec * 3.6; % Convert m/s to km/h
maxSpeed_km_hr = 120;
minSpeed_km_hr = -120;

% Same limits converted to m/s
maxSpeed_ms = maxSpeed_km_hr*1000/3600;
minSpeed_ms = minSpeed_km_hr*1000/3600;

% find() gives the row numbers of the speeds that are inside limits
velocity_indices = find((speed_km_per_hr <= maxSpeed_km_hr) & (speed_km_per_hr >= minSpeed_km_hr));
velocity_indices_ms = find((speed_m_per_sec <= maxSpeed_ms) & (speed_m_per_sec >= minSpeed_ms));

SpeedVectorOfInterest = speed_km_per_hr(velocity_indices); % Matrix S contains rows (frequency) and columns (time)
S_OfInterest = S(velocity_indices, time_indices); % Select only the velocity range of interest

SpeedVectorOfInterest_ms = speed_m_per_sec(velocity_indices_ms); % Matrix S contains rows (frequency) and columns (time)
S_OfInterest_ms = S(velocity_indices_ms, time_indices); % Select only the velocity range of interest

S_OfInterestToPlot = abs(S_OfInterest) / max(abs(S_OfInterest(:))); % Normalise spectrogram
S_OfInterestToPlot_ms = abs(S_OfInterest_ms) / max(abs(S_OfInterest_ms(:))); % Normalise spectrogram
clims = [-30 0]; % dB range displayed by the spectrogram

figure;
imagesc(T_OfInterest, SpeedVectorOfInterest, 20*log10(S_OfInterestToPlot + eps), clims);
xlabel('Time (s)');
ylabel('Velocity (km/h)');
title('Spectrogram of Measured Doppler Signal - Velocity (VEHICLE 10km/h)');
grid on;
colormap('jet'); % Abdul Gaffar
colorbar;
axis xy;
ylim([-40 40]);

%% Velocity Extraction 

%% STEP 1: Convert the velocity spectrogram to relative dB
spectrogramMagnitude = abs(S_OfInterest_ms); % Calculate the magnitude of the complex spectrogram values. 
maximumSpectrogramMagnitude = max(spectrogramMagnitude(:)); % Find the strongest magnitude anywhere in the selected velocity spectrogram. 
normalisedSpectrogramMagnitude = spectrogramMagnitude / maximumSpectrogramMagnitude; % Normalise all spectrogram magnitudes relative to the strongest return. 
spectrogramMagnitude_dB = 20*log10(normalisedSpectrogramMagnitude + eps); % Convert the normalised magnitude to dB and add eps to avoid log10(0). 

%% STEP 2: Define the trolley velocity search region
minimumMotionSpeed_ms = 0.25; % Set the minimum absolute radial speed that will be treated as trolley motion. 
maximumTrolleySpeed_ms = 6.0; % Set the largest radial trolley speed expected in the experiment. 
validVelocityMask = (abs(SpeedVectorOfInterest_ms) >= minimumMotionSpeed_ms) & (abs(SpeedVectorOfInterest_ms) <= maximumTrolleySpeed_ms); % Keep velocity bins outside the near-zero clutter region. Also keep only velocity bins within the expected trolley speed range. 
validVelocityIndices = find(validVelocityMask); % Convert the logical search mask into velocity-bin indices for later use. 

%% STEP 3: Extract the strongest Doppler ridge at each time instant
numberOfTimeBins = length(T_OfInterest); % Determine how many spectrogram time bins must be processed. 
rawTrolleyVelocity_ms = nan(1, numberOfTimeBins); % Pre-allocate the raw velocity estimate and initialise all entries as NaN. 
peakLevel_dB = nan(1, numberOfTimeBins); % Pre-allocate a vector to store the detected peak level in each time bin. 
for timeIndex = 1:numberOfTimeBins % Process one spectrogram time bin at a time. 
    currentSpectrum_dB = spectrogramMagnitude_dB(validVelocityIndices, timeIndex); % Extract only the allowed trolley-velocity bins at the current time. 
    [peakLevel_dB(timeIndex), localPeakIndex] = max(currentSpectrum_dB); % Find the strongest Doppler return in the allowed velocity range. 
    selectedVelocityIndex = validVelocityIndices(localPeakIndex); % Convert the local peak index back to the original spectrogram row index. 
    rawTrolleyVelocity_ms(timeIndex) = SpeedVectorOfInterest_ms(selectedVelocityIndex); % Store the radial velocity corresponding to the detected peak. 
end % Finish processing all spectrogram time bins. 

%% STEP 4: Reject weak detections
minimumPeakLevel_dB = -10; % Define the weakest relative peak level that will be accepted as a trolley detection. 
weakDetectionMask = peakLevel_dB < minimumPeakLevel_dB; % Identify time bins in which the strongest detected return is below the required level. 
rawTrolleyVelocity_ms(weakDetectionMask) = NaN; % Reject weak detections by replacing their velocity estimates with NaN. 

%% STEP 5: Remove isolated velocity outliers
medianFilterLength = 5; % Choose the number of neighbouring velocity estimates used by the moving-median filter. 
filteredTrolleyVelocity_ms = movmedian(rawTrolleyVelocity_ms, medianFilterLength, 'omitnan'); % Remove short isolated velocity spikes while ignoring rejected NaN detections. 

%% STEP 6: Smooth the extracted velocity trajectory
meanFilterLength = 5; % Choose the number of neighbouring samples used to smooth the extracted velocity trajectory. 
estimatedTrolleyVelocity_ms = movmean(filteredTrolleyVelocity_ms, meanFilterLength, 'omitnan'); % Smooth the filtered velocity estimates while ignoring missing detections. 

%% STEP 7: Overlay the extracted velocity on the measured spectrogram -- FIGURE 9
figure; % Open a new figure for the velocity spectrogram and extracted trolley trajectory. 
imagesc(T_OfInterest, SpeedVectorOfInterest_ms, 20*log10(S_OfInterestToPlot_ms + eps), clims); % Display the measured velocity spectrogram using the existing dB colour limits. 
axis xy; % Place negative velocity at the bottom and positive velocity at the top of the plot. 
hold on; % Keep the spectrogram visible so that the extracted velocity can be overlaid. 
plot(T_OfInterest, estimatedTrolleyVelocity_ms, 'w', 'LineWidth', 2); % Plot the extracted trolley radial velocity as a white line over the spectrogram. 
xlabel('Time (s)'); % Label the horizontal axis in seconds. 
ylabel('Velocity (m/s)'); % Label the vertical axis in metres per second. 


title(sprintf('Extracted Radial Velocity \n (Speedometer Velocity \\approx 5km/h)'), 'FontSize', 26'); % Give the verification figure a descriptive title. 
grid on; % Add a grid to assist with reading time and velocity values. 
colormap('jet'); % Use the same colour map as the existing spectrogram plots. 
colorbar; % Display the relative spectrogram magnitude scale. 

set(gca, 'FontSize', 26, 'TickDir', 'out', 'TickLength', [0.015 0.015]);
xticks(0:1:5);
yticks(-5:1:5);
grid on;
colormap('jet'); % Abdul Gaffar
cb = colorbar;
cb.FontSize = 26;  % Colour bar tick values
axis xy;
ylim([-5 5]);

%% Step 8 - Calculate summary velocity measures

approachingVelocity_ms = estimatedTrolleyVelocity_ms(estimatedTrolleyVelocity_ms > minimumMotionSpeed_ms); % Select valid positive radial velocities while the trolley is approaching

edianApproachingVelocity_ms = median(approachingVelocity_ms, 'omitnan'); % The middle speed
maximumApproachingVelocity_ms = max(approachingVelocity_ms, [], 'omitnan'); % The highest speed reached

% Print the summary results
fprintf('\n--- Extracted Human velocity results ---\n');
fprintf('Median approaching radial velocity: %.2f m/s\n', medianApproachingVelocity_ms);
fprintf('Maximum approaching radial velocity: %.2f m/s\n', maximumApproachingVelocity_ms);
fprintf('Median approaching radial velocity: %.2f km/h\n', medianApproachingVelocity_ms * 3.6);

numberOfSpeedPoints = sum(~isnan(estimatedTrolleyVelocity_ms));
fprintf('Number of velocity points: %d\n', numberOfSpeedPoints);


%% Step 9 - Calculate MAE and standard deviation
% Calculate the absolute error for each estimated velocity point
MAE_each_ms = abs(estimatedTrolleyVelocity_ms - referenceSpeed_ms);

% Calculate the mean absolute error, ignoring NaN values
MAE_ms = mean(MAE_each_ms, 'omitnan');

% Convert the MAE to km/h
MAE_kmh = MAE_ms * 3.6;

% Calculate the standard deviation of the estimated velocities
standardDeviation_ms = std(estimatedTrolleyVelocity_ms, 'omitnan');

% Convert the standard deviation to km/h
standardDeviation_kmh = standardDeviation_ms * 3.6;

% Display the results
fprintf('\n--- Velocity Estimation Error Results ---\n');
fprintf('Reference speed: %.2f m/s\n', referenceSpeed_ms);
fprintf('Mean Absolute Error (MAE): %.3f m/s\n', MAE_ms);
fprintf('Mean Absolute Error (MAE): %.3f km/h\n', MAE_kmh);
fprintf('Standard deviation: %.3f m/s\n', standardDeviation_ms);
fprintf('Standard deviation: %.3f km/h\n', standardDeviation_kmh);