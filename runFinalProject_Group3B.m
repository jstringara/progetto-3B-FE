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
addpath('Preprocessing');
addpath('Preprocessed')
addpath('Bootstrap');
addpath('Python');
addpath('Plot');

% set the python environment
pe = pyenv('Version', 'venv/Scripts/python.exe', 'ExecutionMode', 'OutOfProcess');

%% Preprocces and data loading

% ***: Preprocessing is slow as hell, it takes 11 seconds to load the data
preprocessing; % run the preprocessing script

%% Point 1) Bootstrap the interest rates curve for each date

% bootstrap the curves
[dates, DF, zrates] = bootstrapCurves(OIS_Data);

% animated_zrates(zrates, dates)

%% Point 2) Verify that the front December EUA future is the most liquid one in terms of volume

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

risk_free_rate = RiskFreeRate(dates, zrates, Daily_Future.Date);

C_spread_front = compute_C_Spread(Front_December, Daily_Future, risk_free_rate);
C_spread_next = compute_C_Spread(Next_December, Daily_Future, risk_free_rate);

%% Plot the two C-Spreads

% plot_C_front_next(C_spread_front, C_spread_next)

%% Point 3.b) Compute a single C_spread time series with a roll-over rule

% ***: this part is not really pretty, could be put into a function but it does not make a lot of sense

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

% plot_C_Z_r(C_spread, Z_spread, risk_free_rate)

%% Mean and Variance of the Z-Spread (only on dates before 2021)

%mean_Z_spread = mean(Z_spread.Z_Spread(Z_spread.Date < datetime(2021, 1, 1)));
%std_Z_spread = std(Z_spread.Z_Spread(Z_spread.Date < datetime(2021, 1, 1)));

%% Mean and Variance of the Z-Spread (only on dates before 2022)
mean_Z_spread = mean(Z_spread.Z_Spread(Z_spread.Date < datetime(2022, 1, 1)));
std_Z_spread = std(Z_spread.Z_Spread(Z_spread.Date < datetime(2022, 1, 1)));

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

%C_spread = C_spread(C_spread.Date < datetime(2021, 1, 1), :);
%Z_spread = Z_spread(Z_spread.Date < datetime(2021, 1, 1), :);
%risk_free_rate = risk_free_rate(dates_common(:,1) < datetime(2021, 1, 1), :);

%% Limit the data to the dates before October 2022

C_spread = C_spread(C_spread.Date <= datetime(2022,10,31), :);
Z_spread = Z_spread(Z_spread.Date <= datetime(2022,10,31), :);
risk_free_rate = risk_free_rate(dates_common(:, 1) < datetime(2022, 10, 31), :);

%% Plot ACF and PACF of the Z-Spread and C-Spread

% plot the ACF and PACF
% plot_ACF_PACF(Z_spread, 'Z-Spread')
% plot_ACF_PACF(C_spread, 'C-Spread')
% plot_ACF_PACF(risk_free_rate, 'Risk-Free Rate')

%% Check that they are all integrated of order 1

% load the python function from the file
econometrics = py.importlib.import_module('Python.econometrics');

% compute the ADF test for the C-Spread
res = econometrics.compute_ADF( ...
    py.dict(Date=py.list(C_spread.Date), C_Spread=py.list(C_spread.C_Spread)), ...
    py.dict(Date=py.list(Z_spread.Date), Z_Spread=py.list(Z_spread.Z_Spread)), ...
    py.dict(Date=py.list(C_spread.Date), Risk_Free_Rate=py.list(risk_free_rate.Risk_Free_Rate)) ...
);

disp(res)

%% Johansen Test to find cointegratin between these three

% C_spread.C_Spread = C_spread.C_Spread(Z_spread.Date);
% risk_free_rate.Risk_Free_Rate = risk_free_rate.Risk_Free_Rate(Z_spread.Date);
% C_spread.Date = C_spread.Date(Z_spread.Date);
% risk_free_rate.Date = risk_free_rate.Date(Z_spread.Date);
Y = table( ...
    C_spread.Date, ...
    C_spread.C_Spread, ...
    Z_spread.Z_Spread, ...
    risk_free_rate.Risk_Free_Rate, ...
    'VariableNames', {'Date', 'C_Spread', 'Z_Spread', 'Risk_Free_Rate'} ...
);

Y_mat = [Y.C_Spread, Y.Z_Spread, Y.Risk_Free_Rate];

% Johansen test
[h,pValue,stat,cValue,mles] = jcitest(Y_mat, ...
    Test=["trace" "maxeig"], Display="summary", Model="H2");

params = mles.r1.paramVals;
B = params.B;

% nomalize
B = B / B(1);

% write and plot the cointegration vectors
disp(B')

ect = Y_mat * B;

% test the stationarity of the error correction term
%[h,pValue,stat,cValue,mles] = adftest(ect, 'Display', 'summary');

%% Compute the Cointegration between the Z-Spread and the C-Spread

% build the lagged difference of the C-Spread
Delta_C = diff(C_spread.C_Spread);

plot_ACF_PACF(Delta_C, 'Delta_C')

%% Error correction model

Delta_Z = diff(Z_spread.Z_Spread);
Delta_r = diff(risk_free_rate.Risk_Free_Rate);

% lagged values of Delta_C
Delta_C_lag1 = lagmatrix(Delta_C, 1);
Delta_C_lag2 = lagmatrix(Delta_C, 2);
Delta_C_lag3 = lagmatrix(Delta_C, 3);

% lagged value of ect
ect_lag1 = lagmatrix(ect, 1);

% load the extra variables
extra_variables = readtable('Extra_Variables.csv');

% transform the dates into datetime
% format is weekday full name, month full name day, full year
date_format = 'eeee, MMMM d, yyyy';
extra_variables.Date = string(extra_variables.Date);
extra_variables.Date = datetime(extra_variables.Date, 'InputFormat', date_format);

% filter them by the dates to match the other variables
extra_variables = extra_variables(ismember(extra_variables.Date, C_spread.Date), :);

% keep only the columns 'SPX', 'VIX', 'WTI'
extra_variables = extra_variables(:, {'Date', 'SPX', 'VIX', 'WTI'});

% fill the missing values with the previous value
% HACK: there was a negative price for the WTI, we manually set it to NaN
extra_variables = fillmissing(extra_variables, 'previous');

%% GARCh(1,1) model for the variance of the log return of the spot price of the EUA futures

% build a GARCH(1,1) model for the variance of the log return of the spot price
% of the EUA futures

% filter the Daily_Future to match the dates of the extra variables
Daily_Future = Daily_Future(ismember(Daily_Future.Date, extra_variables.Date), :);

% take the log return of the spot price
log_returns = log(Daily_Future.Price(2:end) ./ Daily_Future.Price(1:end-1));

% fit the GARCH(1,1) model
mdl = garch(1,1);

% estimate the parameters
estMdl = estimate(mdl, log_returns(2:end), E0=log_returns(1));

% simulate the variance
numObs = length(log_returns);

% simulate the unconditional variance
v = simulate(estMdl, numObs, 'NumPaths', 1000);

% take the mean of the simulated variance
v = mean(v, 2);

% plot the variance
figure;
plot(Daily_Future.Date(2:end), log_returns.^2, 'LineWidth', 1.5)
hold on
plot(Daily_Future.Date(2:end), v, 'LineWidth', 1.5)
title('Simulated Variance of the Log Returns of the EUA Futures')
legend('Realized Variance', 'GARCH(1,1) Variance')
xlabel('Date')

%% EWMA model

% compute the EWMA
lambda = 0.95;
v_ewma = zeros(length(log_returns), 1);
v_ewma(1) = var(log_returns);

for i = 2:length(log_returns)
    v_ewma(i) = lambda * v_ewma(i-1) + (1 - lambda) * log_returns(i)^2;
end

% plot the variance
figure;
plot(Daily_Future.Date(2:end), log_returns.^2, 'LineWidth', 1.5)
hold on
plot(Daily_Future.Date(2:end), v_ewma, 'LineWidth', 1.5)
title('EWMA Variance of the Log Returns of the EUA Futures')
legend('Realized Variance', 'EWMA Variance')
xlabel('Date')

%% Error correction model

% build the table with the variables
Y = table( ...
    Delta_C_lag1, ...
    Delta_C_lag2, ...
    Delta_C_lag3, ...
    Delta_Z, ...
    Delta_r, ...
    ect_lag1(2:end), ...
    log(extra_variables.WTI(2:end) ./ extra_variables.WTI(1:end-1)), ...
    log(extra_variables.SPX(2:end) ./ extra_variables.SPX(1:end-1)), ...
    extra_variables.VIX(2:end), ...
    v, ...
    v_ewma, ...
    Delta_C, ...
    'VariableNames', {'Delta_C_lag1', 'Delta_C_lag2', 'Delta_C_lag3', 'Delta_Z', 'Delta_r', ...
    'ect_lag1', 'log_WTI', 'log_SPX', 'VIX', 'GARCH', 'EWMA', 'Delta_C' } ...
);

% remove nan values
Y = rmmissing(Y);

%% Model with the GARCH variance

% fit the model
mdl = fitlm(Y, ...
'Delta_C ~ Delta_C_lag1 + Delta_C_lag2 + Delta_C_lag3 + Delta_Z + Delta_r + ect_lag1 + log_WTI + log_SPX + VIX + GARCH', ...
'Intercept', false);

% print the summary
disp(mdl)

% get the AIC and BIC
AIC = mdl.ModelCriterion.AIC;
BIC = mdl.ModelCriterion.BIC;

%% Model with the EWMA variance

disp(['The AIC of the model is: ', num2str(AIC)]);
disp(['The BIC of the model is: ', num2str(BIC)]);
mdl = fitlm(Y, ...
'Delta_C ~ Delta_C_lag1 + Delta_C_lag2 + Delta_C_lag3 + Delta_Z + Delta_r + ect_lag1 + log_WTI + log_SPX + VIX + EWMA', ...
'Intercept', false);

disp(mdl)

% get the AIC and BIC
AIC = mdl.ModelCriterion.AIC;
BIC = mdl.ModelCriterion.BIC;

disp(['The AIC of the model with EWMA is: ', num2str(AIC)]);
disp(['The BIC of the model with EWMA is: ', num2str(BIC)]);

%% Terminate the python environment

pe.terminate;

%% Compute the elapsed time

toc