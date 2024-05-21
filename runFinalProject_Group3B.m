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

%% Point 2) Verify that the front December EUA future is the most liquid one in terms of volume

% load the preprocessed data
Volumes_march_front = readtable('Volumes_March.csv');
Volumes_june_front = readtable('Volumes_June.csv');
Volumes_sept_front = readtable('Volumes_September.csv');
Volumes_dec_front = readtable('Volumes_December_0.csv');

Volumes_fronts_months = [
    Volumes_march_front.Volume;
    Volumes_june_front.Volume;
    Volumes_sept_front.Volume;
    Volumes_dec_front.Volume
];

grouping = [
    zeros(height(Volumes_march_front),1);
    ones(height(Volumes_june_front),1);
    2*ones(height(Volumes_sept_front),1);
    3*ones(height(Volumes_dec_front),1)
];

% plot_Volumes_fronts_months(Volumes_fronts_months, grouping)

% boxplot of the December front and next

% load the preprocessed data
Volumes_dec_1 = readtable('Volumes_December_1.csv');
Volumes_dec_2 = readtable('Volumes_December_2.csv');

Volumes_dec = [Volumes_dec_front.Volume; Volumes_dec_1.Volume; Volumes_dec_2.Volume];

grouping = [
    zeros(height(Volumes_dec_front),1);
    ones(height(Volumes_dec_1),1);
    2*ones(height(Volumes_dec_2),1)
];

% plot_Volumes_december(Volumes_dec, grouping)

%% Point 3) compute the C-Spread for the EUA futures

% load the preprocessed data of the daily prices
Daily_prices = readtable('Daily_Future_Price.csv');

% % for each date in dates count the number of occurences
% for i=1:height(dates)
%     count = sum(dates(:,1) == dates(i,1));
%     if count > 1
%         disp(['Duplicate date: ', datestr(dates(i,1))] )
%     end
% end

% find the dates common to the daily prices and the dates for which we have
% the interest rates
common_dates = intersect(Daily_prices.Date, dates(:,1));

% find the indices of the common dates in both tables
idx_daily_prices = ismember(Daily_prices.Date, common_dates);
idx_dates = ismember(dates(:,1), common_dates);

% filter the daily prices for the common dates (they are the same for the front)
Daily_prices = Daily_prices(idx_daily_prices,:);
Front = Volumes_dec_front(idx_daily_prices,:);

% filter the interest rates curves for the common dates (same for zero rates)
DF_common = DF(idx_dates,:);
zero_rates_common = zrates(idx_dates,:);
zero_rates_dates_common = dates(idx_dates,2:end);

% interpolate the risk free rate for the needed expiry
risk_free_rate = zeros(height(Daily_prices),1);

ACT_365 = 3;
for i=1:height(Daily_prices)
    expiry = Front.Expiry(i);
    risk_free_rate(i) = interp1(zero_rates_dates_common(i,:), zero_rates_common(i,:), expiry, 'linear', 'extrap');
end

% compute the C-Spread
ACT_365 = 3;
yearfrac(common_dates, Front.Expiry, ACT_365)
C_spread = log(Front.Price ./ Daily_prices.Price) ./ yearfrac(common_dates, Front.Expiry, ACT_365) ...
    - risk_free_rate;

% plot the C-Spread
figure;
plot(common_dates, 100 * C_spread)
title('C-Spread')
grid on

% plot the price
figure;
plot(common_dates, Daily_prices.Price)
hold on
plot(common_dates, Front.Price)
title('Daily Price vs Front Price')
legend('Daily Price', 'Front Price')
grid on

% plot the ratio
figure;
plot(common_dates, Front.Price ./ Daily_prices.Price)
title('Ratio')
grid on
title('Ratio')
legend('Front Price / Daily Price')

figure
plot(common_dates, 100 * log(Front.Price ./ Daily_prices.Price))
title('Log Spread')
grid on

% plot the zero rates
figure;
plot(common_dates, 100 * risk_free_rate)
title('Zero Rates')
grid on
ylim([-0.6, 3.6])
