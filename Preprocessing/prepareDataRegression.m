function Y = prepareDataRegression(C_spread, Z_Spread, risk_free_rate, ect, Extra_Variables, ...
    Volatility, last_date)
% prepareDataRegression prepares the data for the regression
%
% INPUTS
% - C_spread: the C-Spread [table]
% - Z_Spread: the Z-Spread [table]
% - risk_free_rate: the risk free rate
% - ect: the error correction term [vector]
% - Extra_Variables: the extra variables [table]
% - Volatility: the volatility [vector]
% - last_date: the last date to consider [datetime]
%
% OUTPUTS
% - Y: the table with the data for the regression [table]

% filter all data to keep only the data before the last date
C_spread = C_spread(C_spread.Date <= last_date, :);
Z_spread = Z_Spread(Z_Spread.Date <= last_date, :);
risk_free_rate = risk_free_rate(risk_free_rate.Date <= last_date, :);
ect = ect(C_spread.Date <= last_date);
Extra_Variables = Extra_Variables(Extra_Variables.Date <= last_date, :);
Volatility = Volatility(C_spread.Date <= last_date);

% build the lagged difference of the C-Spread
Delta_C = [NaN; diff(C_spread.C_Spread)];
Delta_C_lag1 = lagmatrix(Delta_C, 1);
Delta_C_lag2 = lagmatrix(Delta_C, 2);
Delta_C_lag3 = lagmatrix(Delta_C, 3);

Delta_Z = [NaN; diff(Z_spread.Z_Spread)];
Delta_r = [NaN; diff(risk_free_rate.Risk_Free_Rate)];

% lagged value of ect
ect_lag1 = lagmatrix(ect, 1);

Y = table( ...
    Delta_C, ...
    Delta_C_lag1, ...
    Delta_C_lag2, ...
    Delta_C_lag3, ...
    Delta_Z, ...
    Delta_r, ...
    ect_lag1, ...
    Extra_Variables.WTI, ...
    Extra_Variables.SPX, ...
    Extra_Variables.VIX, ...
    Volatility, ...
    'VariableNames', ...
    {'Delta_C', 'Delta_C_lag1', 'Delta_C_lag2', 'Delta_C_lag3', ...
    'Delta_Z', 'Delta_r', 'ect_lag1', 'WTI', 'SPX', 'VIX', 'Volatility'} ...
    );

% remove the NaN values
Y = rmmissing(Y);

end