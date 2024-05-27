function C_spread = compute_C_Spread(Future, Underlying, risk_free_rate)

% compute the C-Spread for the front December and next December
ACT_365 = 3;
C_spread= log(Future.Price ./ Underlying.Price) ./ ...
    yearfrac(Underlying.Date, Future.Expiry, ACT_365) ...
    - risk_free_rate;

% create a table with the C-Spread
C_spread = table(Underlying.Date, C_spread, 'VariableNames', {'Date', 'C_Spread'});

end