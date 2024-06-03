function T = performPearsonTest(Extra_Variables, variance, save_table)
% performPearsonTest performs the Pearson test on the extra variables and the variance of the GARCH model
%
% INPUTS:
%   - Extra_Variables: table containing the extra variables
%   - variance: variance of the GARCH model
%   - save_table: boolean to save the table in a .csv file

% build the matrix to compute the correlation
X = [Extra_Variables.SPX, Extra_Variables.VIX, Extra_Variables.WTI, variance];

% delete the nan values
X = rmmissing(X);

[coeff, pValue] = corrcoef(X);

% create the Table to hold the results
T = table('Size', [4, 4], 'VariableTypes', {'string', 'string', 'string', 'string'}, ...
    'VariableNames', {'SPX', 'VIX', 'WTI', 'Variance'}, 'RowNames', {'SPX', 'VIX', 'WTI', 'Variance'});

% fill the table with the correlation coefficients (only the lower triangular part)
for i = 1:4
    for j = 1:4
        if i >= j
            % add the number rounded to 2 decimal places
            T{i, j} = string(round(coeff(i, j), 2));
            % add asterisks given the p-value
            if pValue(i, j) < 0.1
                T{i, j} = T{i, j} + join(repmat("*", 1, sum(pValue(i,j) < [0.1 0.05 0.01])), "");
            end
        else
            T{i, j} = "";
        end
    end
end

% display the results
disp(T)

% save the table in a .csv file
if save_table
    writetable(T, 'Results/PearsonTest.csv', 'WriteRowNames', true);
end

end