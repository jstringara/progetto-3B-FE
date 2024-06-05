function T = summaryModels(mdl_I, mdl_II, mdl_III, mdl_IV, mdl_V, mdl_VI, save_file)
% create the table
Models = ["Model I"; "Model II"; "Model III"; "Model IV"; "Model V"; "Model VI"];
% a row for each regression coefficient of model VI, Obs, BIC and AIC
rows = ["Delta_C_lag1", "Delta_C_lag2", "Delta_C_lag3", "Delta_Z", "Delta_r", "ect_lag1", "WTI", ...
    "SPX", "VIX", "Volatility", "(Intercept)", "Obs", "BIC", "AIC"];
% create the table (it contains only strings)
T = table('Size', [length(rows), length(Models)], 'VariableNames', Models, 'RowNames', rows, ...
    'VariableTypes', repmat({'string'}, 1, length(Models)));

% fill the table
T = composeTable(T, 'Model I', mdl_I, rows);
T = composeTable(T, 'Model II', mdl_II, rows);
T = composeTable(T, 'Model III', mdl_III, rows);
T = composeTable(T, 'Model IV', mdl_IV, rows);
T = composeTable(T, 'Model V', mdl_V, rows);
T = composeTable(T, 'Model VI', mdl_VI, rows);

% escape the row names so that '_' is not interpreted as a subscript
T.Properties.RowNames = strrep(T.Properties.RowNames, '_', '\_');

disp(T)

% save to a csv file
if save_file
    writetable(T, 'Results/RegressionResults.csv', 'WriteRowNames', true)
end

end