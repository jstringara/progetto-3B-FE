function [dates, DF, zero_rates] =  bootstrapCurves(OIS_Data)
% BOOTSTRAPCURVES computes the discount factors and zero rates for the rates
%
% INPUTS:
%   OIS_Data: table with the OIS rates
%
% OUTPUTS:
%   dates: matrix with the relevant dates
%   DF: matrix with the discount factors
%   zero_rates: matrix with the zero rates

% define the conventions
ACT_365 = 3;
EU_30_360 = 6;

% extract the vector of t_0
t0 = OIS_Data.Date;

% for each date create the corresponding row of the vector
offsets = [calweeks(0:3), calmonths(1:11), calmonths(12:3:21), calyears(2:10)];
dates = NaT(length(t0), length(offsets));

dates = repmat(t0, 1, length(offsets));
dates = dates + repmat(offsets, length(t0), 1);

% move to business days
quoted_dates = dates(:,2:end);
quoted_dates(~isbusday(quoted_dates, eurCalendar())) = ...
    busdate(quoted_dates(~isbusday(quoted_dates, eurCalendar())), 'modifiedfollow', eurCalendar());
dates(:,2:end) = quoted_dates;

% compute the yearfractions (European 30/360 convention)
yf = zeros(length(t0), length(offsets)-1);
yf = yearfrac(repmat(t0, 1, length(offsets)-1), dates(:,2:end), EU_30_360);

% compute the discounts factors curve for each date
DF = zeros(length(t0), length(offsets)-1);

% for dates less than one year, we compute directly
DF(:,1:15) = 1./(1 + OIS_Data{:,2:16} .* yf(:,1:15));

% cases between 1 and 2 years
delta_3m = yf(:,16) - yf(:,6); %delta between 3m and 15m
delta_6m = yf(:,17) - yf(:,9); %delta between 6m and 18m
delta_9m = yf(:,18) - yf(:,12); %delta between 9m and 21m
% compute the discounts factors by taking into account the previous paid ones
DF(:,16)=(1-OIS_Data{:,17}.*yf(:,6).*DF(:,6))./(1+delta_3m.*OIS_Data{:,17});
DF(:,17)=(1-OIS_Data{:,18}.*yf(:,9).*DF(:,9))./(1+delta_6m.*OIS_Data{:,18});
DF(:,18)=(1-OIS_Data{:,19}.*yf(:,12).*DF(:,12))./(1+delta_9m.*OIS_Data{:,19});

% compute the relevant dates and yf for the yearly swaps
delta_yearly = [zeros(length(yf),1), yf(:, [15, 19:end])];
delta_fwd_1y = delta_yearly(:,2:end) - delta_yearly(:,1:end-1);

% initialize the sum for 1y
S = delta_fwd_1y(:,1) .* DF(:,15);

% for dates greater than 2 years (or equal), we use the previous discounts
for j = 19:length(offsets)-1
    % for each date, get the relevant OIS rate
    R = OIS_Data{:,j+1};
    DF(:,j) = (1 - R .* S) ./ (1 + delta_fwd_1y(:,j-17) .* R);
    % update the sum
    S = S + delta_fwd_1y(:,j-17) .* DF(:,j);
end

% finally compute the zero rates
delta_rates = yearfrac(repmat(t0, 1, length(offsets)-1), dates(:,2:end), ACT_365);

zero_rates = -log(DF)./delta_rates;

end