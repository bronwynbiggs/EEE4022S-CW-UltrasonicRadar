# EEE4022S YAG-03 Low-Cost Ultrasonic Radar for short range vehicle speed estimation.
This GitHub repository contains the MATLAB and Arduino code developed for the design and testing of a low-cost ultrasonic radar system for short-range vehicle speed estimation. The project was submitted in partial fulfilment of the academic requirements for a Bachelor of Science degree in Electrical and Computer Engineering at the University of Cape Town in October 2026.

# Data Acquisition
The Arduino script for the Teensy 4.1 configures the ADC to acquire and save signal samples to a binary (.bin) file on a microSD card. These recorded binary files are then used as inputs to the MATLAB speed estimation script.

# MATLAB Speed Estimation
The main MATLAB script for processing recorded data is located at *MATLAB Processing/velocity_extraction.m*

The script takes a recorded binary (.bin) file as input and processes the recorded samples to extract estimated speeds and generates spectrograms to visualize the detected Doppler frequency components and estimated velocity trajectories.

# How to Use:
1. Open *velocity_extraction.m* in MATLAB.
2. Update the file path in the script to point to the binary file you want to process. Example datasets are available in the *Recorded datasets* folder.
3. Enter the video-derived reference speed in the script, in m/s, line 41. This value is used to calculate the performance metrics.
4. Run the MATLAB script.

# Optional Parameter Adjustments
**Spectrogram magnitude scale:** Adjust *clims()* on lines 210 and 248 to change the magnitude scale displayed in the spectrogram plots.
**Maximum expected speed:** Adjust the maximum speed parameter on line 271 to change the upper speed limit used during speed extraction. This can help reject noise and unexpected detections outside the expected speed range.

# Outputs:
The MATLAB script produces the following outputs:
- **Speed estimates:** An array named *estimatedTrolleyVelocity_ms*, containing the extracted speed estimates in m/s.
- **Spectrograms:** Figures showing the received signal's frequency content over time, with frequency and speed axes and estimated velocity trajectories overlaid.
- **Speed statistics:** The estimated mean and maximum speeds, printed in the MATLAB Command Window.
- **Performance metrics:** Results calculated by comparing the estimated speeds with the video-derived reference speed, printed in the MATLAB Command Window.

