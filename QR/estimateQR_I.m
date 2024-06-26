function T = estimateQR_I(Y, save_file)
% estimateQR estimates the quantile regression for the dataset Y
%
% Inputs:
%   Y: dataset with the following variables
%       - Delta_C: the change in the spread
%       - Delta_C_lag1: the change in the spread at t-1
%       - Delta_C_lag2: the change in the spread at t-2
%       - Delta_C_lag3: the change in the spread at t-3
%       - ect_lag1: the error correction term at t-1

% create the matrices for the quantile regression
y = Y.Delta_C;

x = [
    Y.Delta_C_lag1, Y.Delta_C_lag2, Y.Delta_C_lag3, Y.ect_lag1
];

% estimate matrix to store the estimates
estimates = zeros(width(x) + 1, 8);
pvalues = zeros(width(x) + 1, 8);

% for quantiles 0.1, 0.2, ..., 0.8, 0.9
for i = 1:4

    % First bound (tau = 0.1 * i)
    tau_lb = 0.1 * i;
    [estimate_lb, pvalue_lb, j_lb] = qr_standard(x, y, tau_lb, 'test', 'kernel', 'maxit', 5000, 'tol', 1e-10);
    y_quantile_lb = estimate_lb(1) + x * estimate_lb(2:end);

    % save the estimate and pvalue in the appropriate column of the matrix
    estimates(:, i) = estimate_lb;
    pvalues(:, i) = pvalue_lb;

    % Opposite line (tau = 0.1 * (10 - i))
    tau_ub = 0.1 * (10 - i);
    [estimate_ub, pvalue_ub, j_ub] = qr_standard(x, y, tau_ub, 'test', 'kernel', 'maxit', 5000, 'tol', 1e-10);
    y_quantile_ub = estimate_ub(1) + x * estimate_ub(2:end);

    % save the estimate and pvalue in the appropriate column of the matrix
    estimates(:, 9 - i) = estimate_ub;
    pvalues(:, 9 - i) = pvalue_ub;

    % plot the quantile regression
    plot_quantile(y, y_quantile_lb, y_quantile_ub, tau_lb, tau_ub)

end

T = table('Size', [size(estimates,1), size(estimates,2)], 'VariableNames', {'0.1', '0.2', '0.3', '0.4', '0.6', '0.7', '0.8', '0.9'}, ...
    'RowNames', {'(Intercept)', 'Delta_C_lag1', 'Delta_C_lag2', 'Delta_C_lag3', 'ect_lag1'}, ...
    'VariableTypes', repmat({'string'}, 1, 8));

% fill the table
for i = 1:size(estimates,1)
    for j = 1:size(estimates, 2)
        T{i, j} = string(round(estimates(i, j), 2));
        if pvalues(i, j) < 0.1
            T{i, j} = T{i, j} + join(repmat("*", 1, sum(pvalues(i,j) < [0.1 0.05 0.01])), "");
        end
    end
end

% escape the row names so that '_' is not interpreted as a subscript
T.Properties.RowNames = strrep(T.Properties.RowNames, '_', '\_');

disp(T)

if save_file
    writetable(T, 'Results/QuantileRegression_I.csv', 'WriteRowNames', true)
end

end