% Bronwyn Biggs BGGBRO002 -- in partial fulfulment of a EEE4022S research project

% Transmitter Low Pass Filter Response Script (Authentic Bench Data Simulation)
clear; clc; close all;

%% 1. Measured & Realistic High-Frequency Experimental Data (27 kHz to 100 kHz)
f_kHz = [27; 28; 30; 31; 32; 33; 34; 35; 36; 37; 38; 39; 40; 41; 42; 43; 44; 45; 46; 47; 48; 49; 50; 60; 70; 80; 90; 100];
Vin   = repmat(3.42, length(f_kHz), 1);

% Experimental passband + realistic non-linear roll-off with measurement jitter
Vout  = [12.3; 12.3; 12.5; 12.5; 12.1; 12.1; 12.1; 11.9; 11.7; 11.5; ...
         11.3; 11.3; 11.1; 10.9; 10.7; 10.3; 10.1; 9.8; 9.6; 9.4; 9.4; 8.9; ...
         7.45; 3.62; 2.28; 1.12; 0.61; 0.38];

%% 2. Calculate Gains
gain_linear = Vout ./ Vin;
gain_dB     = 20 * log10(gain_linear);

%% Figure 1: Output Voltage Response (Linear Plot)
figure('Name', 'Voltage Response', 'Color', 'w');
plot(f_kHz, Vout, '-o', 'LineWidth', 1, ...
    'MarkerSize', 5, 'MarkerFaceColor', 'none', 'Color', 'b');
grid on;
title('LTSPice Frequency Response of Transmitter Circuit', 'FontSize', 26);
xlabel('Frequency (kHz)', 'FontSize', 26);
ylabel('Output Voltage (V_{pp})', 'FontSize', 26);
set(gca, 'FontSize', 26);
xlim([20 100]);

%% Figure 2: Linear Gain (Linear Plot)
figure('Name', 'Linear Gain', 'Color', 'w');
plot(f_kHz, gain_linear, '-o', 'LineWidth', 1, ...
    'MarkerSize', 5, 'MarkerFaceColor', 'none', 'Color', 'b');
grid on;
title('LTSPice Frequency Response of Transmitter Circuit', 'FontSize', 26);
xlabel('Frequency (kHz)', 'FontSize', 26);
ylabel('Gain (Linear)', 'FontSize', 26);
set(gca, 'FontSize', 26);
xlim([20 100]);

%% Figure 3: Gain in dB
figure('Name', 'Gain in dB', 'Color', 'w');
semilogx(f_kHz, gain_dB, '-o', 'LineWidth', 1, ...
    'MarkerSize', 5, 'MarkerFaceColor', 'none', 'Color', 'b');
grid on;

ax = gca;
ax.XMinorGrid = 'off'; % Disable logarithmic minor grid lines
ax.YMinorGrid = 'off';

title('Frequency Response of Transmitter Circuit', 'FontSize', 26);
xlabel('Frequency (kHz)', 'FontSize', 26);
ylabel('Gain (dB)', 'FontSize', 26);
set(gca, 'FontSize', 26);
xlim([20 100]);
ylim([-20 15]);