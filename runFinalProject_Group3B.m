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

%% Point 1) Bootstrap the interest rates curve for each date

OIS_Data = readtable('OIS_Data.csv');

% convert the dates to datetime
OIS_Data.Date = OIS_Data.Date + calyears(2000);

% fill with previous day and then remove rows with nans
OIS_Data = fillmissing(OIS_Data, 'previous');
OIS_Data = rmmissing(OIS_Data);

% Put the rates into percentages
OIS_Data{:,2:end} = OIS_Data{:,2:end} / 100;

% extract the vector of t_0
t0 = OIS_Data.Date;

% for each date create the corresponding row of the vector
offsets = [calweeks(0:3), calmonths(1:11), calmonths(12:3:21), calyears(2:10)];
dates = NaT(length(t0), length(offsets));

for i = 1:length(dates)
    dates(i,:) = t0(i) + offsets;
end

% move to business days
dates(~isbusday(dates,eurCalendar())) = ...
    busdate(dates(~isbusday(dates, eurCalendar())), 'modifiedfollow', eurCalendar());

% compute the yearfractions
ACT_360 = 3;
yf = zeros(length(t0), length(offsets)-1);
for i = 1:length(t0)
    yf(i,:) = yearfrac(t0(i), dates(i,2:end), ACT_360);
end

% compute the discounts factors curve for each date
DF = zeros(length(t0), length(offsets)-1);

% for dates less than one year, we compute directly
DF(:,1:15) = 1./(1 + OIS_Data{:,2:16} .* yf(:,1:15));

S = yf(:,1:15) .* DF(:,15);

% for dates greater than one year, we use the previous discounts
for j = 16:length(offsets)-1
    % for each date, get the relevant OIS rate
    R = OIS_Data{:,j+1};
    DF(:,j) = (1 - R .* S) ./ (1 + yf(:,j) .* R);
    % update the sum
    S = S + yf(:,j) .* DF(:,j);
end
