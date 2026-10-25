% Bronwyn Biggs BGGBRO002 -- in partial fulfulment of a EEE4022S research project
% Graph plotter for MAE values over different speed categroies

%% MAE Analysis: Indoor Trolley and Vehicle Tests
clear; clc; close all;

%% 1. Indoor trolley tests
% Enter the MAE for each of the 10 trials in each category (m/s).
maeSlow   = [1.07 1.15 1.15 1.25 1.36 1.26 1.27 1.26 1.26 1.26];
maeMedium = [1.78 1.57 1.62 1.99 1.88 1.81 1.88 1.88 1.91 1.88];
maeFast   = [2.62 2.97 3.16 3.31 2.97 3.24 3.53 3.14 3.05 3.77];

figure('Color','w');
hold on;

plot(1:numel(maeSlow), maeSlow, '-o', ...
    'LineWidth',1.2,'MarkerSize',5);

plot(1:numel(maeMedium), maeMedium, '-s', ...
    'LineWidth',1.2,'MarkerSize',5);

plot(1:numel(maeFast), maeFast, '-^', ...
    'LineWidth',1.2,'MarkerSize',5);

xlabel('Trial Number');
ylabel('Mean Absolute Error (m/s)');
title('Indoor Trolley Speed Estimation Error');

legend('Slow','Medium','Fast','Location','best');
ylim([0 6]);
xlim([1 10]);
xticks(2:2:10);
yticks(0:2:6);
grid on;
box on;
hold off;


%% 2. Vehicle tests — three horizontal subplots

% Enter the MAE values for each vehicle test (m/s).
maeVehicle5  = [0.785 0.475 0.501 0.355 0.632];  % 5 km/h tests
maeVehicle10 = [0.859 0.649 0.625 0.722 0.801];  % 10 km/h tests
maeVehicle20 = [5.057 5.163 2.624 4.659 4.120];  % 20 km/h tests

%% Vehicle tests — single plot with three lines

figure('Color','w');
hold on;

plot(1:numel(maeVehicle5), maeVehicle5, '-o', ...
    'LineWidth',1.2,'MarkerSize',5);

plot(1:numel(maeVehicle10), maeVehicle10, '-s', ...
    'LineWidth',1.2,'MarkerSize',5);

plot(1:numel(maeVehicle20), maeVehicle20, '-^', ...
    'LineWidth',1.2,'MarkerSize',5);

xlabel('Trial Number');
ylabel('Mean Absolute Error (m/s)');
title('Vehicle Speed Estimation Error');

legend('5 km/h','10 km/h','20 km/h','Location','best');

grid on;
box on;
hold off;