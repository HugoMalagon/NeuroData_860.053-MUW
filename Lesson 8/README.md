# Lesson 7 — Reward Prediction from Neural Population Activity

Processing and Interpretation of Neuroscience Data

## Overview

Lesson 7 introduces linear regression models for decoding behavior from neural activity.
Using real recordings from the prelimbic cortex of mice performing a probabilistic choice task, you will learn how to:

- extract firing rates from spike-time matrices

- align neural data to behavioral events

- build single-neuron and multi-neuron regressions

- evaluate prediction accuracy

- compare training vs. testing performance

- identify neurons with the strongest predictive weights

- estimate how prediction improves as population size increases

- perform cross-validated “best neuron” analyses

- By the end of this lesson you will have a full workflow for population-level encoding analysis using supervised regression.

## Learning Goals

By the end of Lesson 7, you will be able to:

### Firing Rate Quantification

- Compute firing rates in user-defined analysis windows tied to behavioral events.

- Build trial-by-trial firing rate vectors for single neurons and firing-rate matrices for populations.

- Handle missing or NaN trials appropriately.

### Single-Neuron Linear Regression

- Fit a linear model (fitlm) 

- Interpret model coefficients, predictions, and accuracy.

- Visualize model fit, scatter plots, and classification thresholds.

### Multi-Neuron Linear Regression

- Combine firing rates from multiple neurons into a multi-predictor linear model.

- Inspect learned weights to determine which neurons contribute most.

- Analyze how model accuracy changes as you add neurons.

### Model Generalization (Training vs. Test Data)

- Split trials into training and testing sets (e.g., 50/50).

- Evaluate overfitting by comparing training vs. test accuracy.

- Plot prediction accuracy as a function of population size.

### Cross-Validation

- Perform K-fold cross-validation to estimate neuron-by-neuron predictive accuracy.

- Identify neurons that reliably encode reward information.

- Compare predictive performance to chance level.

### Prerequisites

- MATLAB (R2019b or newer recommended).

- Concepts from Lessons 5 and 6 (arrays, plotting, firing rates, linear models).

- Understanding of PSTHs and spike-event alignment (from earlier lessons).

## Acknowledgments

This lesson builds on material prepared by Vered Kellner and Hugo Malagon Vina for Processing and Interpretation of Neuroscience Data (860.053-MUW).
It extends their neural encoding and spike-train analysis modules to include supervised regression, population decoding, and model validation.

## Resources Used to Create This Module

- ChatGPT

- MATLAB documentation (linear regression, data handling, statistical modeling)

