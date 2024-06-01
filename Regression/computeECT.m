function ect = computeECT(C_spread, Z_spread, risk_free_rate)

Y_joc = table( ...
    C_spread.Date, ...
    C_spread.C_Spread, ...
    Z_spread.Z_Spread, ...
    risk_free_rate.Risk_Free_Rate, ...
    'VariableNames', {'Date', 'C_Spread', 'Z_Spread', 'Risk_Free_Rate'} ...
);

Y_joc_mat = [Y_joc.C_Spread, Y_joc.Z_Spread, Y_joc.Risk_Free_Rate];

% Johansen test
[h,pValue,stat,cValue,mles] = jcitest(Y_joc_mat, ...
    Test=["trace" "maxeig"], Display="summary", Model="H2");

params = mles.r1.paramVals;
B = params.B;

% normalize
B = B / B(1);

% write and plot the cointegration vectors
disp(['{' num2str(B(1)) ', ' num2str(B(2)) ', ' num2str(B(3)) '}'])

ect = Y_joc_mat * B;

end
