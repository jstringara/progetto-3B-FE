% runFinalProject_Group3B
%  Group 3B, AY2023-2024
% 
%
% to run:
% > runFinalProject_Group3B.m

clc
clear all
close all

tic

% fix random seed
rng(42) % the answer to everything in the universe

%% Add the directories to the path

addpath('Data');
addpath('Preprocessed')
addpath('Bootstrap');

%% Point 1) Bootstrap the interest rates curve for each date

OIS_Data = readtable('OIS_Data.csv');

% convert the dates to datetime
OIS_Data.Date = OIS_Data.Date + calyears(2000);

% fill with previous day and then remove rows with nans
OIS_Data = fillmissing(OIS_Data, 'previous');
OIS_Data = rmmissing(OIS_Data);

% remove duplicate
OIS_Data = unique(OIS_Data,'rows');

% Put the rates into percentages
OIS_Data{:,2:end} = OIS_Data{:,2:end} / 100;

% bootstrap the curves
[dates, DF, zrates] = bootstrapCurves(OIS_Data);

plot(dates(698,2:end), zrates(698,:))

%% Point 2) Verify that the front December EUA future is the most liquid one in terms of volume

% load the preprocessed data
Volumes_march_front = readtable('Volumes_March.csv');
Volumes_june_front = readtable('Volumes_June.csv');
Volumes_sept_front = readtable('Volumes_September.csv');
Volumes_dec_front = readtable('Volumes_December_0.csv');

Volumes_fronts_months = [
    Volumes_march_front;
    Volumes_june_front;
    Volumes_sept_front;
    Volumes_dec_front
];

grouping = [
    zeros(height(Volumes_march_front),1);
    ones(height(Volumes_june_front),1);
    2*ones(height(Volumes_sept_front),1);
    3*ones(height(Volumes_dec_front),1)];

figure;
boxplot(log10(Volumes_fronts_months.Volume+1), ...
    grouping, ...
    'Labels', {'March', 'June', 'September', 'December'})
% set the title and grid
title('Volume of EUA Futures')
grid on

% boxplot of the December front and next

% load the preprocessed data
Volumes_dec_1 = readtable('Volumes_December_1.csv');
Volumes_dec_2 = readtable('Volumes_December_2.csv');

Volumes_dec = [Volumes_dec_front; Volumes_dec_1; Volumes_dec_2];

grouping = [
    zeros(height(Volumes_dec_front),1);
    ones(height(Volumes_dec_1),1);
    2*ones(height(Volumes_dec_2),1)];

figure;
boxplot(log10(Volumes_dec.Volume+1), ...
    grouping, ...
    'Labels', {'Front December', 'Next December', 'Second next December'})
% set the title and grid
title('Volume of EUA Futures for December')
grid on
