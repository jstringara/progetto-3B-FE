function rfr = RiskFreeRate(dates, zero_rates, target_dates)
% RISKFREERATE Compute the risk free rate
%
% INPUTS:
%   dates: dates of the zero rates [NxM matrix] the first column is the initial date
%   zero_rates: zero rates [NxM matrix]
%   target_dates: dates for which to compute the risk free rate [Nx1 vector]

% interpolate the risk free rate for the needed expiry
rfr = zeros(height(target_dates), 1);

for i=1:height(target_dates)
    expiry = target_dates(i);
    rfr(i) = interp1(dates(i,2:end), zero_rates(i,:), expiry, 'linear', 'extrap');
    % if the date is before the first date, use the first rate
    if expiry < dates(i,2)
        rfr(i) = zero_rates(i,1);
    % if the date is after the last date, use the last rate
    elseif expiry > dates(i,end)
        rfr(i) = zero_rates(i,end);
end

end