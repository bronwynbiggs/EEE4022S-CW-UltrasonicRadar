% Bronwyn Biggs BGGBRO002 -- in partial fulfulment of a EEE4022S research project
% Figure plotting for signal recordings saved to .csv files directly from the bench oscilloscope

% Figure titles, azis titles and ticks will need to be changed depednign on
% the signal being plotted


% Enter the CSV filenames -- needs to be in the same folder
file1 = 'adc_sine_200.csv'; 
% file2 = 'trans_out.csv'; Name of the second file
% file3 = 'trans_conn_out.csv'; % Name of the third file

% Read the data skipping header rows
data1 = readmatrix(file1, 'NumHeaderLines', 2);
%data2 = readmatrix(file2, 'NumHeaderLines', 2);
%data3 = readmatrix(file3, 'NumHeaderLines', 2);

% Convert time to microseconds and offset start to zero
time1 = (data1(:, 1) - data1(1, 1)); volt1 = data1(:, 2);
%time2 = (data2(:, 1) - data2(1, 1)) * 1e6; volt2 = data2(:, 2);
%time3 = (data3(:, 1) - data3(1, 1)) * 1e6; volt3 = data3(:, 2);

% Initialize plot
figure;
plot(time1, volt1, 'b-', 'LineWidth', 1.5, 'DisplayName', 'Injected Input Signal');
hold on;
xticks(0:10000:50000);
yticks(0:500:2500);
grid on;

% plot(time2, volt2, 'r-', 'LineWidth', 1.5, 'DisplayName', 'Clipped 2nd Stage Output');
% plot(time3, volt3, 'k-', 'LineWidth', 1.5, 'DisplayName', 'Clipped 3rd Stage Output');

% Titles and Axis Labels formatted to match reference code defaults
xlabel('Time (s)');
ylabel('Voltage (V)');
title('Receiver Circuit Clipping Validation', 'FontSize', 26);

xlim([0 50000]);
ylim([1000 2500]);
legend('show', 'Location', 'best');
hold off;