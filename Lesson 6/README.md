# Lesson 6 — Understanding and Visualizing Signals in Neuroscience

Processing and Interpretation of Neuroscience Data

## Overview

Lesson 6 introduces fundamental signal-processing concepts used throughout neuroscience data analysis. Through hands-on MATLAB exercises, you will explore how sampling frequency affects the fidelity of signals, learn to detect peaks, compute power spectra, apply filters, quantify events, and perform basic statistical comparisons. You will also work with real neuronal spiking data using tools from the mlib6 toolbox.

The lesson combines conceptual explanations with guided MATLAB code cells and individual exercises, encouraging intuition-building through visualization and experimentation.

## Learning Goals

By the end of Lesson 6, you will be able to:

### Signal Fundamentals

- Explain the relationship between sampling frequency, signal reconstruction, and aliasing.

- Identify when a signal becomes distorted due to insufficient sampling.

### Signal Visualization & Features

Plot time-series signals and visually describe their structure.

Detect peaks in noisy signals using MATLAB’s findpeaks function, adjusting thresholds and constraints.

Understand how noise influences feature detection.

### Frequency-Domain Analysis

Compute and interpret the Power Spectral Density (PSD) of a signal.

Identify dominant oscillatory components in the frequency domain.

### Filtering

Apply basic filters (e.g., low-pass, high-pass) to isolate relevant components of a signal.

Compare filtered and unfiltered traces and interpret their differences.

### Statistics for Signal Comparison

Run paired and unpaired t-tests.

Perform one-way ANOVA.

Visualize group comparisons with boxplots and annotate significance.

### Spike Data: Raster Plots & PSTHs

Use the legacy mlib6 toolbox to load and visualize neuronal spike trains.

Generate raster plots and peristimulus time histograms (PSTHs).

Interpret neuronal responses to events or task actions.

Identify neurons responsive to reward or cue-related epochs.

## Prerequisites

MATLAB (R2019b or newer recommended).

mlib6 toolbox (included in the lesson folder — be sure to Add to Path in MATLAB).

Basic familiarity with MATLAB Live Scripts.

Concepts covered in Lesson 5 (arrays, plotting, basic operations).

## How to Use This Module

Open Lesson6_Students_LiveScript.mlx in MATLAB.

Use F9 to run each code section sequentially.

Visualize outputs in the Live Editor figure panels.

For each Question and Exercise (e.g., L6-Q1.1, L6-E.2), write your answers in a separate script.

For PSTH/raster analysis:

Ensure the folder mlib6 is added to your MATLAB path.

Explore the documentation using help mraster and help mpsth.

## Acknowledgments

This lesson is adapted from material prepared by Vered Kellner and Hugo Malagon Vina for Processing and Interpretation of Neuroscience Data (860.053-MUW). It extends the Day 5 module into real-world signal processing, neuronal feature detection, and event-related analyses.

## Resources Used to Create This Module

ChatGPT

MATLAB documentation (signal processing, PSD estimation, filtering)

mlib6 toolbox for spike-data analysis

https://de.mathworks.com/matlabcentral/fileexchange/37339-mlib-toolbox-for-analyzing-spike-data

https://uk.mathworks.com/learn/tutorials/matlab-onramp.html
