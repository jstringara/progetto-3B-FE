function T = summaryADF(C_spread, Z_spread, risk_free_rate, save_table)
% computeECT follows the Johansen procedure to establish whether the time series are cointegrated
% or not, finds the number of cointegration relationships and the
% cointegration vector
%
% INPUTS:
% C_spread:         C_spread
% Z_spread:         Z_index
% risk_free_rate:   risk free rate three months
% save figure:      flag to save the figure
% print_table:      flag to print the table

% perform the ADF test
[h, pValue_c_spread, stat_c_spread, cValue_c_spread] = adftest(C_spread.C_Spread);
[h_diff, pValue_c_spread_diff, stat_c_spread_diff, cValue_c_spread_diff] = ...
    adftest(diff(C_spread.C_Spread));

[h, pValue_z_spread, stat_z_spread, cValue_z_spread] = adftest(Z_spread.Z_Spread);
[h_diff, pValue_z_spread_diff, stat_z_spread_diff, cValue_z_spread_diff] = ...
    adftest(diff(Z_spread.Z_Spread));

[h, pValue_risk_free_rate, stat_risk_free_rate, cValue_risk_free_rate] = ...
    adftest(risk_free_rate.Risk_Free_Rate);
[h_diff, pValue_risk_free_rate_diff, stat_risk_free_rate_diff, cValue_risk_free_rate_diff] = ...
    adftest(diff(risk_free_rate.Risk_Free_Rate));

% create the table to hold the results
T = table('Size', [6, 2], 'VariableNames', {'P-Value', 'Test Statistic'}, ...
    'RowNames', {'C-Spread', 'C-Spread Diff', 'Z-Spread', 'Z-Spread Diff', 'Risk-Free Rate', 'Risk-Free Rate Diff'}, ...
    'VariableTypes', repmat({'double'}, 1, 2));

% fill the table
T{1, 1} = pValue_c_spread;
T{1, 2} = stat_c_spread;
T{2, 1} = pValue_c_spread_diff;
T{2, 2} = stat_c_spread_diff;
T{3, 1} = pValue_z_spread;
T{3, 2} = stat_z_spread;
T{4, 1} = pValue_z_spread_diff;
T{4, 2} = stat_z_spread_diff;
T{5, 1} = pValue_risk_free_rate;
T{5, 2} = stat_risk_free_rate;
T{6, 1} = pValue_risk_free_rate_diff;
T{6, 2} = stat_risk_free_rate_diff;

% multiply the first column by 100 to get percentages
T{:, 1} = T{:, 1} * 100;

% round all to 2 decimal points
T{:,:} = round(T{:,:}, 2);

disp(T)

if save_table
    writetable(T, 'Results/summaryADF.csv', 'WriteRowNames', true, 'WriteVariableNames', true)
end

end