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
C_spread = table(Daily_Future.Date, zeros(size(Daily_Future.Price)), ...
    'VariableNames', {'Date', 'C_Spread'});

% each year up to the 15th of November we use the front December
% after the 15th of November and up to the front's expiry we use the next December

years = unique(year(Daily_Future.Date));
prev_date = datetime(years(1)-1, 11, 15);

% for each year
for i = 1:length(years)
    value_year = years(i);
    % find the expiry for that year as the expiry with matching year
    expiry_front = Front_December.Expiry(year(Front_December.Date) == value_year);
    expiry_front = expiry_front(1);
    % compute the last front date (15th of November of the same year)
    last_front_date = datetime(value_year, 11, 15);
    % from the previous date to the 15th of November take the front December
    C_spread.C_Spread(C_spread.Date >= prev_date & C_spread.Date < last_front_date) = ...
        C_spread_front.C_Spread(C_spread.Date >= prev_date & C_spread.Date < last_front_date);
    % from the 15th of November to the expiry take the next December
    C_spread.C_Spread(C_spread.Date >= last_front_date & C_spread.Date < expiry_front) = ...
        C_spread_next.C_Spread(C_spread.Date >= last_front_date & C_spread.Date < expiry_front);
    % update the previous date
    prev_date = expiry_front;
end

% compute the Mean and the Standard Deviation of the C-Spread
mean_C_spread = mean(C_spread.C_Spread);
std_C_spread = std(C_spread.C_Spread);

% display the results
disp(['The mean of the C-Spread is: ', num2str(mean_C_spread * 100), '%']);
disp(['The standard deviation of the C-Spread is: ', num2str(std_C_spread * 100), '%']);

%% Plot the C-Spread

plot_C_Z_r(C_spread, risk_free_rate)

%% Load the data of the Bonds

load('Bonds.mat');

% transform the dates into datetime
date_format = 'yyyy-MM-dd';
for i = 1:length(Bonds)
    Bonds{i}.MaturityDate = datetime(convertCharsToStrings(Bonds{i}.MaturityDate), 'Format', date_format);
    Bonds{i}.FirstQuote = datetime(convertCharsToStrings(Bonds{i}.FirstQuote), 'Format', date_format);
    Bonds{i}.CouponDates = datetime(convertCharsToStrings( ...
        mat2cell(Bonds{i}.CouponDates, ones(size(Bonds{i}.CouponDates,1),1), ...
        size(Bonds{i}.CouponDates,2))), ...
        'Format', date_format);
    Bonds{i}.Dates = datetime(convertCharsToStrings( ...
        mat2cell(Bonds{i}.Dates, ones(size(Bonds{i}.Dates,1),1), ...
        size(Bonds{i}.Dates,2))), ...
        'Format', date_format);
end

%% Compute the Z-Spread for each bond

% start a waitbar
h = waitbar(0, 'Computing the Z-Spreads');
tot = length(Bonds);

% group the bonds by issuer
Bonds_By_Issuer = dictionary();

for i = 1:length(Bonds)
    Bonds{i}.Z_Spreads = compute_ZSpread(Bonds{i}, dates_common, zrates_common);
    % update the waitbar
    waitbar(i/tot, h, [num2str(i/tot*100), '%'])
    % group the bonds by issuer
    if isempty(Bonds_By_Issuer(Bonds{i}.Issuer))
        Bonds_By_Issuer(Bonds{i}.Issuer) = {Bonds{i}};
    else
        Bonds_By_Issuer(Bonds{i}.Issuer) = [Bonds_By_Issuer(Bonds{i}.Issuer), Bonds{i}];
    end
end
% close the waitbar
close(h);

%% Compute the Z-Spread for each issuer

% create a table to store the Z-Spreads
Z_spread = table(Daily_Future.Date, zeros(size(Daily_Future.Date)), ...
    'VariableNames', {'Date', 'Z_Spread'});

for i = 1:length(Bonds_By_Issuer.keys)
    % get the issuer
    issuer = Bonds_By_Issuer.keys{i};
    % get the bonds
    bonds = Bonds_By_Issuer(issuer);
    % compute the total volume of bonds traded for each date
    total_volume = zeros(height(Daily_Future), 1);
    for j = 1:length(bonds)
        total_volume = total_volume + bonds{j}.Volume .* (bonds{j}.Z_Spreads ~= 0);
    end
    % aggregate the Z-Spreads
    Z_spread_issuer = zeros(height(Daily_Future), 1);
    for j = 1:length(bonds)
        Z_spread_issuer = Z_spread_issuer + bonds{j}.Volume .* bonds{j}.Z_Spreads;
    end
    % normalize the Z-Spreads by the total volume
    Z_spread_issuer = Z_spread_issuer ./ total_volume;
    % add the Z-Spreads to the table
    Z_spread.Z_Spread = Z_spread.Z_Spread + Z_spread_issuer;
end

% normalize the Z-Spreads by the number of issuers
Z_spread.Z_Spread = Z_spread.Z_Spread ./ length(Bonds_By_Issuer.keys);

%% Plot the Z-Spread

figure;
plot(Daily_Future.Date, 100 * Z_spread.Z_Spread)
hold on
plot(Daily_Future.Date, 100 * risk_free_rate)
ylim([-0.7, 3.7])
xlim([C_spread.Date(1) - calmonths(6), C_spread.Date(end)])

%% Compute the elapsed time

toc