function T = summaryTable(C_spread, Z_spread, risk_free_rate, save_table)
% summaryTable - This function takes in the three input arguments and
% calculates the mean and standard deviation of each of the three input
%
% Inputs:
%   C_spread - A table containing the C-Spread values
%   Z_spread - A table containing the Z-Spread values
%   risk_free_rate - A table containing the Risk-Free Rate values
%   save_table - A boolean to save the table as a .csv file

% C-Spread
mean_C_spread = mean(C_spread.C_Spread);
std_C_spread = std(C_spread.C_Spread);

% Z-Spread
mean_Z_spread = mean(Z_spread.Z_Spread);
std_Z_spread = std(Z_spread.Z_Spread);

% Risk-Free Rate
mean_zrates = mean(risk_free_rate.Risk_Free_Rate);
std_zrates = std(risk_free_rate.Risk_Free_Rate);

% display the results as a table (strings)
T = table('Size', [2, 3], 'VariableNames', {'C_Spread', 'Z_Spread', 'Risk_Free_Rate'}, ...
    'RowNames', {'Mean', 'Standard Deviation'}, 'VariableTypes', repmat({'double'}, 1, 3));

T{1, 1} = mean_C_spread;
T{2, 1} = std_C_spread;
T{1, 2} = mean_Z_spread;
T{2, 2} = std_Z_spread;
T{1, 3} = mean_zrates;
T{2, 3} = std_zrates;

% multiply the values by 100 to get percentages
T{:,:} = T{:,:} * 100;
T{:,:} = round(T{:,:}, 2);

% display the table with only 2 decimal points
disp(T)

% save the table as a .csv file
if save_table
    % save the table as a .csv file only up to 2 decimal points
    writetable(T, 'Results/summaryTable.csv', 'WriteRowNames', true, 'WriteVariableNames', true)
end

end