% Bronwyn Biggs BGGBRO002 -- in partial fulfulment of a EEE4022S research project

% Bandpass Filter Frequency Response 
clc; clear; close all;

%% 1. Data Definition
f_kHz = [0.1, 2, 5, 10, 15, 16, 17, 18, 20, 22, 24, 26, 28, 30, ...
         32, 33, 34, 36, 38, 40, 42, 44, 46, 47, 48, 50, 52, 54, ...
         56, 58, 60, 65, 70, 75, 80, 85, 90, 100]; % Frequency in kHz

Vout_V = [0.04, 0.04, 0.08, 0.28, 0.62, 0.68, 0.78, 0.86, 1.01, 1.13, ...
          1.23, 1.31, 1.37, 1.43, 1.47, 1.49, 1.49, 1.51, 1.51, 1.49, ...
          1.47, 1.43, 1.37, 1.35, 1.33, 1.27, 1.23, 1.19, 1.13, 1.09, ...
          1.03, 0.96, 0.90, 0.86, 0.84, 0.82, 0.80, 0.80]; % Output Peak (V)

gain_linear = [2, 2, 4, 14, 31, 34, 39, 43, 50.5, 56.5, 61.5, 65.5, ...
              68.5, 71.5, 73.5, 74.5, 74.5, 75.5, 75.5, 74.5, 73.5, ...
              71.5, 68.5, 67.5, 66.5, 63.5, 61.5, 59.5, 56.5, 54.5, ...
              51.5, 48, 45, 43, 42, 41, 40, 40]; % Gain (V/V)

gain_dB = [6.02, 6.02, 12.04, 22.92, 29.83, 30.63, 31.82, 32.67, 34.07, ...
          35.04, 35.78, 36.32, 36.71, 37.09, 37.33, 37.44, 37.44, 37.56, ...
          37.56, 37.44, 37.33, 37.09, 36.71, 36.59, 36.46, 36.06, 35.78, ...
          35.49, 35.04, 34.73, 34.24, 33.62, 33.06, 32.67, 32.46, 32.26, 32.04, 32.04]; % Gain (dB)

%% 2. Figure 1: Decibel Gain vs Frequency (Bode Plot)
figure('Name', 'Gain in dB', 'Color', 'w');
semilogx(f_kHz, gain_dB, '-o', 'LineWidth', 1, ...
    'MarkerSize', 5, 'MarkerFaceColor', 'none', 'Color', 'b');
grid on;
title('Frequency Response (Gain in dB)', 'FontSize', 26);
xlabel('Frequency (kHz)', 'FontSize', 26);
ylabel('Gain (dB)', 'FontSize', 26);
set(gca, 'FontSize', 26);
xlim([1 100]);
ylim([5 50]);

%% 3. Figure 2: Linear Gain vs Frequency
figure('Name', 'Linear Gain', 'Color', 'r');
plot(f_kHz, gain_linear, '-o', 'LineWidth', 1, ...
    'MarkerSize', 5, 'MarkerFaceColor', 'none', 'Color', 'r');
grid on;
title('Frequency Response (Linear Gain)', 'FontSize', 26);
xlabel('Frequency (kHz)', 'FontSize', 26);
ylabel('Gain (V/V)', 'FontSize', 26);
set(gca, 'FontSize', 26);
ylim([0 100]);

%% 4. Figure 3: Output Peak Voltage vs Frequency (Linear Scale)
figure('Name', 'Output Voltage', 'Color', 'w');
plot(f_kHz, Vout_V, '-o', ...
     'LineWidth', 1, ...
     'MarkerSize', 5, ...
     'MarkerFaceColor', 'none', ...
     'Color', [0.8500 0.3250 0.0980]);
grid on;
title('Output Peak Voltage vs Frequency', 'FontSize', 26);
xlabel('Frequency (kHz)', 'FontSize', 26);
ylabel('Output Peak Voltage (V)', 'FontSize', 26);
set(gca, 'FontSize', 26);
ylim([0 1.9]);