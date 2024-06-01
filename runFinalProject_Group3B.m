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
addpath('Python');
addpath('Plot');
addpath('QR');

% set the python environment
%pe = pyenv('Version', 'venv/Scripts/python.exe', 'ExecutionMode', 'OutOfProcess');

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
    Front_December.Volume
    ];

grouping = [
    zeros(height(Volumes_march_front),1);
    ones(height(Volumes_june_front),1);
    2*ones(height(Volumes_sept_front),1);
    3*ones(height(Front_December),1)
    ];

plot_Volumes_fronts_months(Volumes_fronts_months, grouping)

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

plot_Volumes_december(Volumes_dec, grouping)

%% Point 3) compute the C-Spread for the EUA futures

risk_free_rate = RiskFreeRate(dates, zrates, Front_December.Expiry);

C_spread_front = compute_C_Spread(Front_December, Daily_Future, risk_free_rate);
C_spread_next = compute_C_Spread(Next_December, Daily_Future, risk_free_rate);

%% Plot the two C-Spreads for phase_III_dates

C_spread_Front_phase_III = C_spread_front(C_spread_front.Date < phase_III_dates(2), :);
C_spread_Next_phase_III = C_spread_next(C_spread_next.Date < phase_III_dates(2), :);

plot_C_front_next(C_spread_Front_phase_III, C_spread_Next_phase_III)

%% Point 3.b) Compute a single C_spread time series with roll-over rule of 15th of November

C_spread = aggregate_C_Spread(Front_December, C_spread_front, Next_December, C_spread_next, 1, OpenInterest);

C_spread_phase_III = C_spread(C_spread.Date < phase_III_dates(2), :);

%% Plot the C-Spread

% plot_C(C_spread)

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

plot_C_Z_r(C_spread_phase_III, Z_spread_phase_III, risk_free_rate_phase_III)

%% Point 6.2) Plot ACF and PACF of the Z-Spread and C-Spread

% plot the ACF and PACF
plot_ACF_PACF(Z_spread_phase_III, 'Z-Spread')
plot_ACF_PACF(C_spread_phase_III, 'C-Spread')
plot_ACF_PACF(risk_free_rate_phase_III, 'Risk-Free Rate')

%% Point 6.3) Mean and Variance of all three series for phase III

% C-Spread

% compute the Mean and the Standard Deviation of the C-Spread
mean_C_spread = mean(C_spread_phase_III.C_Spread);
std_C_spread = std(C_spread_phase_III.C_Spread);
% display the results
disp(['The mean of the C-Spread is: ', num2str(mean_C_spread * 100), '%']);
disp(['The standard deviation of the C-Spread is: ', num2str(std_C_spread * 100), '%']);

% Z-Spread

mean_Z_spread = mean(Z_spread_phase_III.Z_Spread);
std_Z_spread = std(Z_spread_phase_III.Z_Spread);

disp(['The mean of the Z-Spread is: ', num2str(mean_Z_spread * 100), '%']);
disp(['The standard deviation of the Z-Spread is: ', num2str(std_Z_spread * 100), '%']);

% Risk-Free Rate

mean_zrates = mean(risk_free_rate_phase_III.Risk_Free_Rate);
std_zrates = std(risk_free_rate_phase_III.Risk_Free_Rate);

disp(['The mean of the zero rates is: ', num2str(mean_zrates * 100), '%']);
disp(['The standard deviation of the zero rates is: ', num2str(std_zrates * 100), '%']);

%% Point 6.4) Check that they are all integrated of order 1

% perform the ADF test
z_spread_res = adftest(Z_spread_phase_III.Z_Spread);
z_spread_res_diff = adftest(diff(Z_spread_phase_III.Z_Spread));

if z_spread_res == 0 && z_spread_res_diff == 1
    disp('The Z-Spread is integrated of order 1')
else
    disp('The Z-Spread is not integrated of order 1')
end

c_spread_res = adftest(C_spread_phase_III.C_Spread);
c_spread_res_diff = adftest(diff(C_spread_phase_III.C_Spread));

if c_spread_res == 0 && c_spread_res_diff == 1
    disp('The C-Spread is integrated of order 1')
else
    disp('The C-Spread is not integrated of order 1')
end

risk_free_rate_res = adftest(risk_free_rate_phase_III.Risk_Free_Rate);
risk_free_rate_res_diff = adftest(diff(risk_free_rate_phase_III.Risk_Free_Rate));

if risk_free_rate_res == 0 && risk_free_rate_res_diff == 1
    disp('The Risk-Free Rate is integrated of order 1')
else
    disp('The Risk-Free Rate is not integrated of order 1')
end

%% Point 7) Johansen Test to find cointegration between these three

Y_joc = table( ...
    C_spread_phase_III.Date, ...
    C_spread_phase_III.C_Spread, ...
    Z_spread_phase_III.Z_Spread, ...
    risk_free_rate_phase_III.Risk_Free_Rate, ...
    'VariableNames', {'Date', 'C_Spread', 'Z_Spread', 'Risk_Free_Rate'} ...
);

Y_joc_mat = [Y_joc.C_Spread, Y_joc.Z_Spread, Y_joc.Risk_Free_Rate];

% Johansen test
[h,pValue,stat,cValue,mles] = jcitest(Y_joc_mat, ...
    Test=["trace" "maxeig"], Display="summary", Model="H2");

params = mles.r1.paramVals;
B = params.B;

% nomalize
B = B / B(1);

% write and plot the cointegration vectors
disp(['{' num2str(B(1)) ', ' num2str(B(2)) ', ' num2str(B(3)) '}'])

ect_phase_III = Y_joc_mat * B;

% test the stationarity of the error correction term
%[h,pValue,stat,cValue,mles] = adftest(ect, 'Display', 'summary');

%% Compute the Cointegration between the Z-Spread and the C-Spread

% build the lagged difference of the C-Spread
Delta_C = [NaN; diff(C_spread.C_Spread)];
Delta_C_phase_III = Delta_C(Daily_Future.Date < phase_III_dates(2));

% plot_ACF_PACF(Delta_C, '\Delta C')

%% Error correction model

Delta_Z = [NaN; diff(Z_spread.Z_Spread)];
Delta_Z_phase_III = [NaN; diff(Z_spread_phase_III.Z_Spread)];
Delta_r = [NaN; diff(risk_free_rate.Risk_Free_Rate)];
Delta_r_phase_III = [NaN; diff(risk_free_rate_phase_III.Risk_Free_Rate)];

% lagged values of Delta_C
Delta_C_lag1_phase_III = lagmatrix(Delta_C_phase_III, 1);
Delta_C_lag2_phase_III = lagmatrix(Delta_C_phase_III, 2);
Delta_C_lag3_phase_III = lagmatrix(Delta_C_phase_III, 3);

% lagged value of ect
ect_lag1_phase_III = lagmatrix(ect_phase_III, 1);

%% GARCh(1,1) model for the variance of the log return of the spot price of the EUA futures

% build a GARCH(1,1) model for the variance of the log return of the spot price
% of the EUA futures

GarchModel = garch(1,1);
GarchModel = estimate(GarchModel,Daily_log_returns);
E = infer(GarchModel,Daily_log_returns);
v = [NaN; E]; % pad with a NaN to match the size of the returns

% plot the variance
figure;
plot(Daily_Future.Date, Daily_log_returns.^2, 'LineWidth', 1.5)
hold on
plot(Daily_Future.Date, v, 'LineWidth', 1.5)
title('Simulated Variance of the Log Returns of the EUA Futures')
legend('Realized Variance', 'GARCH(1,1) Variance')
xlabel('Date')

% use only the phase_III_dates
v_phase_III = v(Daily_Future.Date < phase_III_dates(2));

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

%% Pearson correlation test

% build the matrix to compute the correlation
X = [Extra_Variables.SPX, Extra_Variables.VIX, Extra_Variables.WTI, v];

% delete the nan values
X = rmmissing(X);

[cor_coeff,P_value_coeff] = corrcoef(X);

disp('The matrix correlation coefficients of the extravariables is:')
disp(cor_coeff)
disp('The P-values of the correlation coefficients of the extravariables is:')
disp(P_value_coeff)

%% Error correction model

% filter the extra varibles to use only phase_III_dates
Extra_Variables_phase_III = Extra_Variables(Extra_Variables.Date < phase_III_dates(2), :);

% build the table with the necessary variables
Y_phase_III = table( ...
    Delta_C_lag1_phase_III, ...
    Delta_C_lag2_phase_III, ...
    Delta_C_lag3_phase_III, ...
    Delta_Z_phase_III, ...
    Delta_r_phase_III, ...
    ect_lag1_phase_III, ...
    Extra_Variables_phase_III.WTI, ...
    Extra_Variables_phase_III.SPX, ...
    Extra_Variables_phase_III.VIX, ...
    v_phase_III, ...
    v_ewma_phase_III, ...
    Delta_C_phase_III, ...
    'VariableNames', {'Delta_C_lag1', 'Delta_C_lag2', 'Delta_C_lag3', 'Delta_Z', 'Delta_r', ...
    'ect_lag1', 'log_WTI', 'log_SPX', 'VIX', 'GARCH', 'EWMA', 'Delta_C' } ...
    );

% remove nan values
Y_phase_III = rmmissing(Y_phase_III);

%% General Model with the GARCH variance (Phase III)

% fit the model
mdl = fitlm(Y_phase_III, ...
    'Delta_C ~ Delta_C_lag1 + Delta_C_lag2 + Delta_C_lag3 + Delta_Z + Delta_r + ect_lag1 + log_WTI + log_SPX + VIX + GARCH' ...
);

% print the summary
disp(mdl)

% get the AIC and BIC
AIC = mdl.ModelCriterion.AIC;
BIC = mdl.ModelCriterion.BIC;

% display AIC and BIC
disp(['The AIC of the model is: ', num2str(AIC)]);
disp(['The BIC of the model is: ', num2str(BIC)]);

%% Model 1 with the GARCH variance

% fit the model
mdl = fitlm(Y_phase_III, ...
    'Delta_C ~ Delta_C_lag1 + Delta_C_lag2 + Delta_C_lag3 + ect_lag1' ...
);

% print the summary
disp(mdl)

% get the AIC and BIC
AIC = mdl.ModelCriterion.AIC;
BIC = mdl.ModelCriterion.BIC;

% display AIC and BIC
disp(['The AIC of the model is: ', num2str(AIC)]);
disp(['The BIC of the model is: ', num2str(BIC)]);

%% Model 2

% fit the model
mdl = fitlm(Y_phase_III, ...
    'Delta_C ~ Delta_C_lag1 + Delta_C_lag2 + Delta_C_lag3 + Delta_Z + Delta_r +ect_lag1' ...
);

% print the summary
disp(mdl)

% get the AIC and BIC
AIC = mdl.ModelCriterion.AIC;
BIC = mdl.ModelCriterion.BIC;

% display AIC and BIC
disp(['The AIC of the model is: ', num2str(AIC)]);
disp(['The BIC of the model is: ', num2str(BIC)]);

%% Model 3

% fit the model
mdl = fitlm(Y_phase_III, ...
    'Delta_C ~ log_WTI' ...
);

% print the summary
disp(mdl)

% get the AIC and BIC
AIC = mdl.ModelCriterion.AIC;
BIC = mdl.ModelCriterion.BIC;

% display AIC and BIC
disp(['The AIC of the model is: ', num2str(AIC)]);
disp(['The BIC of the model is: ', num2str(BIC)]);

%% Model 4

% fit the model
mdl = fitlm(Y_phase_III, ...
    'Delta_C ~ Delta_C_lag1 + Delta_C_lag2 + Delta_C_lag3 + Delta_Z + Delta_r +ect_lag1 +log_WTI' ...
);

% print the summary
disp(mdl)

% get the AIC and BIC
AIC = mdl.ModelCriterion.AIC;
BIC = mdl.ModelCriterion.BIC;

% display AIC and BIC
disp(['The AIC of the model is: ', num2str(AIC)]);
disp(['The BIC of the model is: ', num2str(BIC)]);

%% Model 5 with the GARCH variance

% fit the model
mdl = fitlm(Y_phase_III, ...
    'Delta_C ~ log_WTI + log_SPX + VIX + GARCH' ...
);

% print the summary
disp(mdl)

% get the AIC and BIC
AIC = mdl.ModelCriterion.AIC;
BIC = mdl.ModelCriterion.BIC;

% display AIC and BIC
disp(['The AIC of the model is: ', num2str(AIC)]);
disp(['The BIC of the model is: ', num2str(BIC)]);

%% Model with the EWMA variance

mdl = fitlm(Y_phase_III, ...
    'Delta_C ~ Delta_C_lag1 + Delta_C_lag2 + Delta_C_lag3 + Delta_Z + Delta_r + ect_lag1 + log_WTI + log_SPX + VIX + EWMA' ...
);

disp(mdl)

% get the AIC and BIC
AIC = mdl.ModelCriterion.AIC;
BIC = mdl.ModelCriterion.BIC;

disp(['The AIC of the model with EWMA is: ', num2str(AIC)]);
disp(['The BIC of the model with EWMA is: ', num2str(BIC)]);

%% Point 9.c.i) Compute a single C_spread time series with a Open Interest rule

C_spread = aggregate_C_Spread(Front_December, C_spread_front, Next_December, C_spread_next, 2, OpenInterest);

%% Point 9.c.ii) Compute a single C_spread time series with a roll-over rule one month before the expiry

C_spread = aggregate_C_Spread(Front_December, C_spread_front, Next_December, C_spread_next, 3, OpenInterest);

%% Point 9.c.iii) Compute a single C_spread time series with a roll-over rule

C_spread = aggregate_C_Spread(Front_December, C_spread_front, Next_December, C_spread_next, 4, OpenInterest);


%% Quantile regression

y=Delta_C(4:end);
%fi([], 1, 16)
x=[Delta_C_lag1, ...
    Delta_C_lag2, ...
    Delta_C_lag3, ...
    Delta_Z, ...
    Delta_r, ...
    ect_lag1(2:end), ...
    log(extra_variables.WTI(2:end) ./ extra_variables.WTI(1:end-1)), ...
    log(extra_variables.SPX(2:end) ./ extra_variables.SPX(1:end-1)), ...
    extra_variables.VIX(2:end), ...
    v];
x=x(4:end,:);
l = length(y);

figure(6)
plot([1:l], y, 'DisplayName', 'y') % Aggiunge la legenda per y
hold on

% Define color map
colors = lines(5);

for i = 1:4
    figure;
    l = length(y);
    
    % Plot y with black
    plot([1:l], y, 'DisplayName', 'y', 'Color', 'k')
    hold on
    
     % First line (tau = 0.1 * i)
    tau1 = 0.1 * i;
    [estimate1, pvalue1, j1] = qr_standard(x, y, tau1, 'test', 'kernel', 'maxit', 5000, 'tol', 1e-10);
    y_quantile1 = estimate1(1) + x * estimate1(2:11);
    
    % Assign a specific color
    if i == 1
        plot_color = [0, 0.4470, 0.7410]; % Change the color with respect to the map
    else
        plot_color = colors(i, :);
    end
    
    plot([1:l], y_quantile1, 'DisplayName', ['y\_quantile for tau = ', num2str(tau1)], 'Color', plot_color)
    
    % Opposite line (tau = 0.1 * (10 - i))
    tau2 = 0.1 * (10 - i);
    [estimate2, pvalue2, j2] = qr_standard(x, y, tau2, 'test', 'kernel', 'maxit', 5000, 'tol', 1e-10);
    y_quantile2 = estimate2(1) + x * estimate2(2:11);
    
    % Use the same color for the opposite value
    plot([1:l], y_quantile2, 'DisplayName', ['y\_quantile for tau = ', num2str(tau2)], 'Color', plot_color)
    
    legend show % Show the legend
    title(['Plot for tau = ', num2str(tau1), ' and tau = ', num2str(tau2)])
end


%% Compute the elapsed time

toc