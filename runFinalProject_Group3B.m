% runFinalProject_Group3B
%  Group 3B, AY2023-2024
% 
%
% to run:
% > runFinalProject_Group3B.m

clc
clear all
close all

% no warnings
warning('off', 'all')

tic

% fix random seed
rng(42) % the answer to everything in the universe

%% Add the directories to the path

addpath('Data');
addpath('Preprocessed')
addpath('Bootstrap');
addpath('Plot');

%% Point 1) Bootstrap the interest rates curve for each date

OIS_Data = readtable('OIS_Data.csv');

% convert the dates to datetime
OIS_Data.Date = OIS_Data.Date + calyears(2000);

% fill with previous day and then remove rows with nans
OIS_Data = fillmissing(OIS_Data, 'previous');
OIS_Data = rmmissing(OIS_Data);

% remove duplicate based on the date
OIS_Data = unique(OIS_Data);

% Put the rates into percentages
OIS_Data{:,2:end} = OIS_Data{:,2:end} / 100;

% bootstrap the curves
[dates, DF, zrates] = bootstrapCurves(OIS_Data);

% animated_zrates(zrates, dates)

%% Point 2) Verify that the front December EUA future is the most liquid one in terms of volume

% load the preprocessed data
Volumes_march_front = readtable('Volumes_March.csv');
Volumes_june_front = readtable('Volumes_June.csv');
Volumes_sept_front = readtable('Volumes_September.csv');
Front_December = readtable('Front_December.csv');

Volumes_fronts_months = [
    Volumes_march_front.Volume;
    Volumes_june_front.Volume;
    Volumes_sept_front.Volume;
    Front_December.Volume
];

grouping = [
    zeros(height(Volumes_march_front),1);
    ones(height(Volumes_june_front),1);
    2*ones(height(Volumes_sept_front),1);
    3*ones(height(Front_December),1)
];

% plot_Volumes_fronts_months(Volumes_fronts_months, grouping)

% boxplot of the December front and next

% load the preprocessed data
Next_December = readtable('Next_December.csv');
Next_2_December = readtable('Next_2_December.csv');

Volumes_dec = [
    Front_December.Volume;
    Next_December.Volume;
    Next_2_December.Volume
];

grouping = [
    zeros(height(Front_December),1);
    ones(height(Next_December),1);
    2*ones(height(Next_2_December),1)
];

% plot_Volumes_december(Volumes_dec, grouping)

%% Point 3) compute the C-Spread for the EUA futures

% load the preprocessed data of the daily prices
Daily_Future = readtable('Daily_Future.csv');

% TODO: FIX THE DATES AND THE INTERSECTION
% the date should not be an intersection but rather we should use the previous bootstrap
% curve for the dates we do not have
% find the dates common to the daily prices and the dates for which we have
% the interest rates

% build the zero rates matrix
zrates_common = zeros(height(Daily_Future), size(zrates,2));
dates_common = NaT(height(Daily_Future), size(dates,2));

for i=1:height(Daily_Future)
    % check if the date is in the dates
    if ismember(Daily_Future.Date(i), dates(:,1))
        % find the index of the date
        idx = find(dates(:,1) == Daily_Future.Date(i));
        zrates_common(i,:) = zrates(idx,:);
        % copy the dates
        dates_common(i,:) = dates(idx,:);
    else
        % find the previous date
        idx = find(dates(:,1) < Daily_Future.Date(i), 1, 'last');
        % copy the previous date
        zrates_common(i,:) = zrates(idx,:);
        % compute the new dates by adding the difference
        dates_common(i,:) = dates(idx,:) + (Daily_Future.Date(i) - dates(idx,1));
    end
end

% interpolate the risk free rate for the needed expiry
risk_free_rate = zeros(height(Daily_Future),1);

for i=1:height(Daily_Future)
    expiry = Front_December.Expiry(i);
    risk_free_rate(i) = interp1(dates_common(i,2:end), zrates_common(i,:), expiry, 'linear', 'extrap');
end

% compute the C-Spread for the front December and next December
ACT_365 = 3;
C_spread_front = log(Front_December.Price ./ Daily_Future.Price) ./ ...
    yearfrac(Daily_Future.Date, Front_December.Expiry, ACT_365) ...
    - risk_free_rate;

C_spread_next = log(Next_December.Price ./ Daily_Future.Price) ./ ...
    yearfrac(Daily_Future.Date, Next_December.Expiry, ACT_365) ...
    - risk_free_rate;

% create two tables with the C-Spreads
C_spread_front = table(Daily_Future.Date, C_spread_front, 'VariableNames', {'Date', 'C_Spread'});
C_spread_next = table(Daily_Future.Date, C_spread_next, 'VariableNames', {'Date', 'C_Spread'});

%% Plot the two C-Spreads

plot_C_front_next(C_spread_front, C_spread_next)

%% Point 3.b) Compute a single C_spread time series with a roll-over rule

% build a single time series of the C-Spread


%% Plot the C-Spread

plot_C_Z_r(C_spread_front, risk_free_rate)

%% Compute the elapsed time

toc