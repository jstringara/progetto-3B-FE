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

% remove duplicate
OIS_Data = unique(OIS_Data,'rows');

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
THIRTY_360 = 6;
yf = zeros(length(t0), length(offsets)-1);
for i = 1:length(t0)
    yf(i,:) = yearfrac(t0(i), dates(i,2:end), THIRTY_360);
end

% compute the discounts factors curve for each date
DF = zeros(length(t0), length(offsets)-1);

% for dates less than one year, we compute directly
DF(:,1:15) = 1./(1 + OIS_Data{:,2:16} .* yf(:,1:15));

S = yf(:,1:15) .* DF(:,15);


delta_3m=yearfrac(dates(:,7),dates(:,17),THIRTY_360); %delta between 3m and 15m
delta_6m=yearfrac(dates(:,10),dates(:,18),THIRTY_360); %delta between 6m and 18m
delta_9m=yearfrac(dates(:,13),dates(:,19),THIRTY_360); %delta between 9m and 21m

DF(:,16)=(1-OIS_Data{:,17}.*yf(:,6).*DF(:,6))./(1+delta_3m.*OIS_Data{:,17});
DF(:,17)=(1-OIS_Data{:,18}.*yf(:,9).*DF(:,9))./(1+delta_6m.*OIS_Data{:,18});
DF(:,18)=(1-OIS_Data{:,19}.*yf(:,12).*DF(:,12))./(1+delta_9m.*OIS_Data{:,19});








% % for dates greater than one year, we use the previous discounts
for j = 16:length(offsets)-1
    % for each date, get the relevant OIS rate
    R = OIS_Data{:,j+1};
    DF(:,j) = (1 - R .* S) ./ (1 + yf(:,j) .* R);
    % update the sum
    S = S + yf(:,j) .* DF(:,j);
end
