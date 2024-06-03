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
addpath('Bootstrap');
addpath('Spreads');
addpath('Summaries')
addpath('Python');
addpath('Plot');
addpath('Regression');
addpath('QR');

%% Preprocces and data loading

% ***: Preprocessing is slow as hell, it takes 11 seconds to load the data
preprocessing; % run the preprocessing script

%% Point 1) Bootstrap the interest rates curve for each date

% bootstrap the curves
[dates, DF, zrates] = bootstrapCurves(OIS_Data);

% fill in the zrates to match the front dates
[dates, zrates] = fill_zrates(zrates, dates, Daily_Future.Date);

% animated_zrates(zrates, dates)

%% Point 2) Verify that the front December EUA future is the most liquid one in terms of volume

Volumes_fronts_months = [
    Volumes_march_front.Volume;
    Volumes_june_front.Volume;
    Volumes_sept_front.Volume;
    Front_December(Front_December.Date < phase_III_dates(2), :).Volume
];

grouping = [
    zeros(height(Volumes_march_front),1);
    ones(height(Volumes_june_front),1);
    2*ones(height(Volumes_sept_front),1);
    3*ones(height(Front_December(Front_December.Date < phase_III_dates(2), :)),1)
    ];

plot_Volumes_fronts_months(Volumes_fronts_months, grouping, true)

% boxplot of the December front and next

Volumes_dec = [
    Front_December(Front_December.Date < phase_III_dates(2), :).Volume;
    Next_December(Next_December.Date < phase_III_dates(2), :).Volume;
    Next_2_December(Next_2_December.Date < phase_III_dates(2), :).Volume
    ];

grouping = [
    zeros(height(Front_December(Front_December.Date < phase_III_dates(2),:)), 1);
    ones(height(Next_December(Next_December.Date < phase_III_dates(2),:)), 1);
    2*ones(height(Next_2_December(Next_2_December.Date < phase_III_dates(2),:)), 1)
    ];

plot_Volumes_december(Volumes_dec, grouping, true)

%% Point 3) compute the C-Spread for the EUA futures

risk_free_rate = RiskFreeRate(dates, zrates, Front_December.Expiry);
risk_free_rate_next = RiskFreeRate(dates, zrates, Next_December.Expiry);

C_spread_front = compute_C_Spread(Front_December, Daily_Future, risk_free_rate);
C_spread_next = compute_C_Spread(Next_December, Daily_Future, risk_free_rate_next);

%% Plot the two C-Spreads for phase_III_dates

C_spread_Front_phase_III = C_spread_front(C_spread_front.Date < phase_III_dates(2), :);
C_spread_Next_phase_III = C_spread_next(C_spread_next.Date < phase_III_dates(2), :);

plot_C_front_next(C_spread_Front_phase_III, C_spread_Next_phase_III, true);

%% Point 3.b) Compute a single C_spread time series with roll-over rule of 15th of November

C_spread = aggregate_C_Spread(Front_December, C_spread_front, Next_December, C_spread_next, 1, OpenInterest);

C_spread_phase_III = C_spread(C_spread.Date < phase_III_dates(2), :);

%% Plot the C-Spread

plot_C(C_spread, true)

%% Point 4) Compute the Z-Spread time series

Z_spread = compute_ZSpread(Bonds, dates, zrates);
Z_spread_phase_III = Z_spread(Z_spread.Date < phase_III_dates(2), :);

%% Point 5) The Risk Free Rate is the 3M interest rate

% take the 3M interest rate
risk_free_rate = zrates(:,7);
risk_free_rate = table(Daily_Future.Date, risk_free_rate, 'VariableNames', {'Date', 'Risk_Free_Rate'});

% filter the dates
risk_free_rate_phase_III = risk_free_rate(risk_free_rate.Date < phase_III_dates(2), :);

%% Point 6.1) Plot the C-Spread, Z-Spread and the Risk-Free Rate

plot_C_Z_r(C_spread_phase_III, Z_spread_phase_III, risk_free_rate_phase_III, true)

%% Point 6.2) Plot ACF and PACF of the Z-Spread and C-Spread

% plot the ACF and PACF
plot_ACF_PACF(Z_spread_phase_III, 'Z-Spread', true)
plot_ACF_PACF(C_spread_phase_III, 'C-Spread', true)
plot_ACF_PACF(risk_free_rate_phase_III, 'Risk-Free Rate', true)

%% Point 6.3) Mean and Variance of all three series for phase III

summaryTable(C_spread_phase_III, Z_spread_phase_III, risk_free_rate_phase_III, true);

%% Point 6.4) Check that they are all integrated of order 1

summaryADF(C_spread_phase_III, Z_spread_phase_III, risk_free_rate_phase_III, true);

%% Point 7) Johansen Test to find cointegration between these three

ect_phase_III = computeECT(C_spread_phase_III, Z_spread_phase_III, risk_free_rate_phase_III, true, true);

% test the stationarity of the error correction term
%[h,pValue,stat,cValue,mles] = adftest(ect, 'Display', 'summary');

%% Point 8.1) GARCh(1,1) model for the variance of the log return of the spot price of the EUA futures

% build a GARCH(1,1) model for the variance of the log return of the spot price
% of the EUA futures
GarchModel = garch(1, 1);
GarchModel = estimate(GarchModel, Daily_log_returns);
E = infer(GarchModel, Daily_log_returns);
v_garch = [NaN; E]; % pad with a NaN to match the size of the returns

% plot the variance
figure;
plot(Daily_Future.Date, Daily_log_returns.^2, 'LineWidth', 1.5)
hold on
plot(Daily_Future.Date, v_garch, 'LineWidth', 1.5)
title('Simulated Variance of the Log Returns of the EUA Futures')
legend('Realized Variance', 'GARCH(1,1) Variance')
xlabel('Date')

%% Point 8.2) Plot the ACF and PACF of Delta C

Delta_C = [NaN; diff(C_spread.C_Spread)];

plot_ACF_PACF(Delta_C, '\Delta C', true)

%% Point 8.3) Pearson correlation test

performPearsonTest(Extra_Variables, v_garch, true);

%% Point 8.4) Error correction model

Y_phase_III = prepareDataRegression(C_spread, Z_spread, risk_free_rate, ect_phase_III, ...
    Extra_Variables, v_garch, phase_III_dates(2));

% fit the model
mdl_VI = fitlm(Y_phase_III, ...
    'Delta_C ~ Delta_C_lag1 + Delta_C_lag2 + Delta_C_lag3 + Delta_Z + Delta_r + ect_lag1 + WTI + SPX + VIX + Volatility' ...
);

%% Point 8.5 Various models

%% Model I

% fit the model
mdl_I = fitlm(Y_phase_III, 'Delta_C ~ Delta_C_lag1 + Delta_C_lag2 + Delta_C_lag3 + ect_lag1');

%% Model II

% fit the model
mdl_II = fitlm(Y_phase_III, ...
    'Delta_C ~ Delta_C_lag1 + Delta_C_lag2 + Delta_C_lag3 + Delta_Z + Delta_r +ect_lag1');

%% Model III

% fit the model
mdl_III = fitlm(Y_phase_III, 'Delta_C ~ WTI');

%% Model IV

% fit the model
mdl_IV = fitlm(Y_phase_III, ...
    'Delta_C ~ Delta_C_lag1 + Delta_C_lag2 + Delta_C_lag3 + Delta_Z + Delta_r +ect_lag1 + WTI');

%% Model V

% fit the model
mdl_V = fitlm(Y_phase_III, 'Delta_C ~ WTI + SPX + VIX + Volatility');

%% Results table of all the 6 models

summaryModels(mdl_I, mdl_II, mdl_III, mdl_IV, mdl_V, mdl_VI, true);

%% EWMA model

% compute the EWMA
lambda = 0.95;
v_ewma = zeros(length(Daily_log_returns), 1);
v_ewma(1) = var(Daily_log_returns, 'omitnan');

for i = 2:length(Daily_log_returns)
    v_ewma(i) = lambda * v_ewma(i-1) + (1 - lambda) * Daily_log_returns(i)^2;
end

% plot the variance
figure;
plot(Daily_Future.Date, Daily_log_returns.^2, 'LineWidth', 1.5)
hold on
plot(Daily_Future.Date, v_ewma, 'LineWidth', 1.5)
title('EWMA Variance of the Log Returns of the EUA Futures')
legend('Realized Variance', 'EWMA Variance')
xlabel('Date')

% use only the phase_III_dates
v_ewma_phase_III = v_ewma(Daily_Future.Date < phase_III_dates(2));

%% Point 9.a) Robustness check with the EWMA variance

Y_phase_III = prepareDataRegression(C_spread, Z_spread, risk_free_rate, ect_phase_III, ...
    Extra_Variables, v_ewma, phase_III_dates(2));

mdl = fitlm(Y_phase_III, ...
    'Delta_C ~ Delta_C_lag1 + Delta_C_lag2 + Delta_C_lag3 + Delta_Z + Delta_r + ect_lag1 + WTI + SPX + VIX + Volatility' ...
);

disp(mdl)

% get the AIC and BIC
AIC = mdl.ModelCriterion.AIC;
BIC = mdl.ModelCriterion.BIC;

disp(['The AIC of the model with EWMA is: ', num2str(AIC)]);
disp(['The BIC of the model with EWMA is: ', num2str(BIC)]);

%% Point 9.b) Use Phase IV

%% Point 9.b.1) Estimate the error correction term for phase IV

ect_phase_IV = computeECT(C_spread, Z_spread, risk_free_rate, false, false);

%% Point 9.b.2) Estimate the error correction model for phase IV

Y_phase_IV = prepareDataRegression(C_spread, Z_spread, risk_free_rate, ect_phase_IV, ...
    Extra_Variables, v_garch, phase_IV_dates(2));

mdl = fitlm(Y_phase_IV, ...
    'Delta_C ~ Delta_C_lag1 + Delta_C_lag2 + Delta_C_lag3 + Delta_Z + Delta_r + ect_lag1 + WTI + SPX + VIX + Volatility' ...
);

disp(mdl)

% get the AIC and BIC
AIC = mdl.ModelCriterion.AIC;
BIC = mdl.ModelCriterion.BIC;

disp(['The AIC of the model for phase IV is: ', num2str(AIC)]);
disp(['The BIC of the model for phase IV is: ', num2str(BIC)]);

%% Point 9.c.i) Switch with Open Interest roll-over rule

C_spread = aggregate_C_Spread(Front_December, C_spread_front, Next_December, C_spread_next, 2, OpenInterest);

% compute the ECT
ect_phase_III = computeECT(C_spread, Z_spread, risk_free_rate, false, false);

% compute the regression
Y_phase_III = prepareDataRegression(C_spread, Z_spread, risk_free_rate, ect_phase_III, ...
    Extra_Variables, v_garch, phase_III_dates(2));

mdl = fitlm(Y_phase_III, ...
    'Delta_C ~ Delta_C_lag1 + Delta_C_lag2 + Delta_C_lag3 + Delta_Z + Delta_r + ect_lag1 + WTI + SPX + VIX + Volatility' ...
);

disp(mdl)

% get the AIC and BIC
AIC = mdl.ModelCriterion.AIC;
BIC = mdl.ModelCriterion.BIC;

disp(['The AIC of the model for phase IV is: ', num2str(AIC)]);
disp(['The BIC of the model for phase IV is: ', num2str(BIC)]);

%% Point 9.c.ii) Compute a single C_spread time series with a roll-over rule one month before the expiry

C_spread = aggregate_C_Spread(Front_December, C_spread_front, Next_December, C_spread_next, 3, OpenInterest);

% compute the ECT
ect_phase_III = computeECT(C_spread, Z_spread, risk_free_rate, false, false);

% compute the regression
Y_phase_III = prepareDataRegression(C_spread, Z_spread, risk_free_rate, ect_phase_III, ...
    Extra_Variables, v_garch, phase_III_dates(2));

mdl = fitlm(Y_phase_III, ...
    'Delta_C ~ Delta_C_lag1 + Delta_C_lag2 + Delta_C_lag3 + Delta_Z + Delta_r + ect_lag1 + WTI + SPX + VIX + Volatility' ...
);

disp(mdl)

% get the AIC and BIC
AIC = mdl.ModelCriterion.AIC;
BIC = mdl.ModelCriterion.BIC;

disp(['The AIC of the model for phase IV is: ', num2str(AIC)]);
disp(['The BIC of the model for phase IV is: ', num2str(BIC)]);

%% Point 9.c.iii) Compute a single C_spread time series with a roll-over rule

C_spread = aggregate_C_Spread(Front_December, C_spread_front, Next_December, C_spread_next, 4, OpenInterest);

% compute the ECT
ect_phase_III = computeECT(C_spread, Z_spread, risk_free_rate, false, false);

% compute the regression
Y_phase_III = prepareDataRegression(C_spread, Z_spread, risk_free_rate, ect_phase_III, ...
    Extra_Variables, v_garch, phase_III_dates(2));

mdl = fitlm(Y_phase_III, ...
    'Delta_C ~ Delta_C_lag1 + Delta_C_lag2 + Delta_C_lag3 + Delta_Z + Delta_r + ect_lag1 + WTI + SPX + VIX + Volatility' ...
);

disp(mdl)

% get the AIC and BIC
AIC = mdl.ModelCriterion.AIC;
BIC = mdl.ModelCriterion.BIC;

disp(['The AIC of the model for phase IV is: ', num2str(AIC)]);
disp(['The BIC of the model for phase IV is: ', num2str(BIC)]);

%% Point 10) Quantile regression

%% Point 10.1) Model VI

% construct the table for the quantile regression
Y_qr = prepareDataRegression(C_spread, Z_spread, risk_free_rate, ect_phase_III, ...
    Extra_Variables, v_garch, phase_III_dates(2));

% estimate the quantile regression
estimateQR(Y_qr, true);

%% Compute the elapsed time

toc