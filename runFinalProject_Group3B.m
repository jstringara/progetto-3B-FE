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

% set the python environment
pe = pyenv('Version', 'venv/Scripts/python.exe', 'ExecutionMode', 'OutOfProcess');

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

% plot_C_front_next(C_spread_front, C_spread_next)

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

% plot_C(C_spread)

%% Load the data of the Bonds

load('Bonds.mat');

% transform the dates into datetime
date_format = 'yyyy-MM-dd';

for i = 1:length(Bonds)

    % convert chars to strings
    Bonds{i}.Issuer = string(Bonds{i}.Issuer);
    Bonds{i}.Code = string(Bonds{i}.Code);
    Bonds{i}.MaturityDate = string(Bonds{i}.MaturityDate);
    Bonds{i}.FirstQuote = string(Bonds{i}.FirstQuote);
    Bonds{i}.CouponDates = string(Bonds{i}.CouponDates);
    Bonds{i}.Dates = string(Bonds{i}.Dates);

    % convert the dates to datetime
    Bonds{i}.MaturityDate = datetime(Bonds{i}.MaturityDate, 'InputFormat', date_format);
    Bonds{i}.FirstQuote = datetime(Bonds{i}.FirstQuote, 'InputFormat', date_format);
    Bonds{i}.CouponDates = datetime(Bonds{i}.CouponDates, 'InputFormat', date_format);
    Bonds{i}.Dates = datetime(Bonds{i}.Dates, 'InputFormat', date_format);

    % convert the volume to double
    Bonds{i}.Volume = double(Bonds{i}.Volume);

end

%% Compute the Z-Spread for each bond

% if the z spreads file does not exist, compute the Z-Spreads
if ~isfile('Preprocessed/Z_Spreads.mat')

% start a waitbar
h = waitbar(0, 'Computing the Z-Spreads');
tot = length(Bonds);

% group the bonds by issuer
Bonds_By_Issuer = struct;

for i = 1:length(Bonds)
    % compute the Z-Spread for the bond
    Bonds{i}.Z_Spreads = compute_ZSpread(Bonds{i}, dates_common, zrates_common);
    % update the waitbar
    waitbar(i/tot, h, ['Computing the Z-Spreads: ', num2str(i/tot*100), '%'])
    
    % add the bond to the issuer in the struct
    if isfield(Bonds_By_Issuer, Bonds{i}.Issuer)
        Bonds_By_Issuer.(Bonds{i}.Issuer){end+1} = Bonds{i};
    else
        Bonds_By_Issuer.(Bonds{i}.Issuer) = {Bonds{i}};
    end

end
% close the waitbar
close(h);

%% Compute the Z-Spread for each issuer


    % create a table to store the Z-Spreads
    Z_spread = table(Daily_Future.Date, zeros(size(Daily_Future.Date)), ...
        'VariableNames', {'Date', 'Z_Spread'});

    total_issuers_active = zeros(height(Daily_Future), 1);

    % iterate over the fields of the struct (the issuers)
    for issuer = fields(Bonds_By_Issuer)'
        % get the bonds of the issuer
        bonds = Bonds_By_Issuer.(issuer{1});
        % compute the total volume of bonds traded for each date
        total_volume = zeros(height(Daily_Future), 1);
        Z_spread_issuer = zeros(height(Daily_Future), 1);
        for j = 1:length(bonds)
            % exclude bond with code "XS0877820422" (it has NaN values)
            if bonds{j}.Code == "XS0877820422"
                continue
            end
            Z_spread_issuer = Z_spread_issuer + bonds{j}.Volume .* bonds{j}.Z_Spreads;
            total_volume = total_volume + bonds{j}.Volume .* (bonds{j}.Z_Spreads ~= 0);
        end
        % normalize the Z-Spreads of the issuer by the total volume
        Z_spread_issuer = Z_spread_issuer ./ total_volume;
        % fill the NaN values (no bonds traded)
        Z_spread_issuer(isnan(Z_spread_issuer)) = 0;
        % add the Z-Spreads to the table
        Z_spread.Z_Spread = Z_spread.Z_Spread + Z_spread_issuer;
        % add the number of active issuers
        total_issuers_active = total_issuers_active + (total_volume ~= 0);
    end

    % normalize the Z-Spreads by the number of issuers
    Z_spread.Z_Spread = Z_spread.Z_Spread ./ total_issuers_active;
    Z_spread.Z_Spread(isnan(Z_spread.Z_Spread)) = 0;

    % save the Z-Spreads
    save('Preprocessed/Z_Spreads.mat', 'Z_spread');

else
    % load the Z-Spreads
    load('Preprocessed/Z_Spreads.mat');
end

%% Plot the Z-Spread

plot_C_Z_r(C_spread, Z_spread, risk_free_rate)

%% Mean and Variance of the Z-Spread (only on dates before 2021)

mean_Z_spread = mean(Z_spread.Z_Spread(Z_spread.Date < datetime(2021, 1, 1)));
std_Z_spread = std(Z_spread.Z_Spread(Z_spread.Date < datetime(2021, 1, 1)));

% display the results
disp(['The mean of the Z-Spread is: ', num2str(mean_Z_spread * 100), '%']);
disp(['The standard deviation of the Z-Spread is: ', num2str(std_Z_spread * 100), '%']);

%% Meand and Variance for the interest rates (only on dates before 2021)

% take the 3M interest rate
risk_free_rate = zrates_common(:,7);
risk_free_rate = table(Daily_Future.Date, risk_free_rate, 'VariableNames', {'Date', 'Risk_Free_Rate'});

% mean_zrates = mean(risk_free_rate(dates_common(:,1) < datetime(2021, 1, 1)));
% std_zrates = std(risk_free_rate(dates_common(:,1) < datetime(2021, 1, 1)));

% disp(['The mean of the zero rates is: ', num2str(mean_zrates * 100), '%']);
% disp(['The standard deviation of the zero rates is: ', num2str(std_zrates * 100), '%']);

%% Limit the data to the dates before 2021

C_spread = C_spread(C_spread.Date < datetime(2021, 1, 1), :);
Z_spread = Z_spread(Z_spread.Date < datetime(2021, 1, 1), :);
risk_free_rate = risk_free_rate(dates_common(:,1) < datetime(2021, 1, 1), :);

%% Plot ACF and PACF of the Z-Spread and C-Spread

% plot the ACF and PACF
% plot_ACF_PACF(Z_spread, 'Z-Spread')
% plot_ACF_PACF(C_spread, 'C-Spread')
% plot_ACF_PACF(risk_free_rate, 'Risk-Free Rate')

%% Check that they are all integrated of order 1

% load the python function from the file
econometrics = py.importlib.import_module('econometrics');

% compute the ADF test for the C-Spread
res = econometrics.compute_ADF( ...
    py.dict(Date=py.list(C_spread.Date), C_Spread=py.list(C_spread.C_Spread)), ...
    py.dict(Date=py.list(Z_spread.Date), Z_Spread=py.list(Z_spread.Z_Spread)), ...
    py.dict(Date=py.list(C_spread.Date), Risk_Free_Rate=py.list(risk_free_rate.Risk_Free_Rate)) ...
);

disp(res)

%% Johansen Test to find cointegratin between these three

Y = table( ...
    C_spread.Date, ...
    C_spread.C_Spread, ...
    Z_spread.Z_Spread, ...
    risk_free_rate.Risk_Free_Rate, ...
    'VariableNames', {'Date', 'C_Spread', 'Z_Spread', 'Risk_Free_Rate'} ...
);

% Johansen test
[~,~,stat] = jcitest([Y.C_Spread, Y.Z_Spread, Y.Risk_Free_Rate], Test=["trace" "maxeig"], Display="summary");


%% Compute the Cointegration between the Z-Spread and the C-Spread

rank = 1;
lags = 1;

% create the VECM model
vecmModel = vecm(width(Y)-1, lags, rank);

% Estimate the VECM model
vecmModel = estimate(vecmModel, [Y.C_Spread, Y.Z_Spread, Y.Risk_Free_Rate]);

% Extract the cointegration coefficients
cointegrationCoeff = vecmModel.Cointegration;

% normalize by the first coefficient
cointegrationCoeff = cointegrationCoeff / cointegrationCoeff(1);

% Display the cointegration coefficients
disp('Cointegration Coefficients:');
disp(cointegrationCoeff);

%% Terminate the python environment

pe.terminate;

%% Compute the elapsed time

toc