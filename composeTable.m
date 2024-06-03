function T = composeTable(T, model_name, mdl, rows)

% fill the table

% model I, fill the estimates not filled with ''
for i = 1:length(rows)
    % check if the row is present in the model coefficients
    if ismember(rows(i), mdl.Coefficients.Properties.RowNames)
        row_idx = find(mdl.Coefficients.Properties.RowNames == rows(i));
        % approximate the number to 2 decimal places and
        % up to three asterisks to indicate the significance
        s = compose("%.2f", mdl.Coefficients.Estimate(row_idx));
        if mdl.Coefficients.pValue(row_idx) < 0.01
            s = s + "***";
        elseif mdl.Coefficients.pValue(row_idx) < 0.05
            s = s + "**";
        elseif mdl.Coefficients.pValue(row_idx) < 0.1
            s = s + "*";
        end
        T{i, model_name} = s;
    else
        T{i, model_name} = "";
    end
end

% add the number of observations, BIC and AIC
T{'Obs', model_name} = compose("%d", mdl.NumObservations);
T{'BIC', model_name} = compose("%.0f", mdl.ModelCriterion.BIC);
T{'AIC', model_name} = compose("%.0f", mdl.ModelCriterion.AIC);

end