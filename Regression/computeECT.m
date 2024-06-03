function ect = computeECT(C_spread, Z_spread, risk_free_rate, save_figure, print_table)

Y_joc = table( ...
    C_spread.Date, ...
    C_spread.C_Spread, ...
    Z_spread.Z_Spread, ...
    risk_free_rate.Risk_Free_Rate, ...
    'VariableNames', {'Date', 'C_Spread', 'Z_Spread', 'Risk_Free_Rate'} ...
);

Y_joc_mat = [Y_joc.C_Spread, Y_joc.Z_Spread, Y_joc.Risk_Free_Rate];

% Johansen test
[h, pValue,stat, cValue, mles] = jcitest(Y_joc_mat, ...
    Test=["trace" "maxeig"], Display = 'off', Model="H2");

% create the table to hold the results
T = table('Size', [3, 4], 'VariableNames', {'Trace', 'MaxEigen', 'Trace Critical Value', ...
    'MaxEigen Critical Value'}, 'RowNames', {'q <= 0', 'q <= 1', 'q <= 2'}, ...
    'VariableTypes', {'string', 'string', 'string', 'string'});

% trace statistic
T.Trace = string(round(stat{1, 1:3}, 2))';

% add asterisks
for i = 1:3
    if pValue{1, i} < 0.1
        T.Trace(i, 1) = T.Trace(i, 1) + join(repmat("*", 1, sum(pValue{1, i} < [0.1 0.05 0.01])), "");
    end
end

% critical values
T{:, 3} = string(round(cValue{1, 1:3}, 2))';

T.MaxEigen = string(round(stat{2, 1:3}, 2))';

% add asterisks
for i = 1:3
    if pValue{2, i} < 0.1
        T.MaxEigen(i, 1) = T.MaxEigen(i, 1) + join(repmat("*", 1, sum(pValue{2, i} < [0.1 0.05 0.01])), "");
    end
end

% critical values
T{:, 4} = string(round(cValue{2, 1:3}, 2))';

if print_table
    disp(T)
end

% save the table
if save_figure
    writetable(T, 'Results/johansen_test.csv', 'WriteRowNames', true)
end

params = mles.r1.paramVals;
B = params.B;

% normalize
B = B / B(1);

% create a table to show the cointegration vector
T = table('Size', [1, 3], 'VariableNames', {'C_Spread', 'Z_Spread', 'Risk_Free_Rate'}, ...
    'RowNames', {'Cointegration_Vector'}, 'VariableTypes', {'double', 'double', 'double'});
T{1,:} = round(B', 2);

if print_table
    disp(T)
end

if save_figure
    writetable(T, 'Results/cointegration_vector.csv', 'WriteRowNames', true)
end

ect = Y_joc_mat * B;

end
