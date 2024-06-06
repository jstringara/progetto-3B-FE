function C_spread = aggregate_C_Spread(Front, C_spread_front, Next, C_spread_next, flag, OpenInterest)
% AGGREGATE_C_SPREAD Aggregate the C-Spread of the front and next December given a rollover strategy
%
% INPUTS:
%   Front: table with the front December contract
%   C_Spread_Front: table with the C-Spread of the front December
%   Next: table with the next December contract
%   C_Spread_Next: table with the C-Spread of the next December
%   flag: flag to indicate the rollover strategy
%       1: Rollover on the 15th of November each year
%       2: Switch when the Open Interest of the Next is higher than the Front
%       3: Switch exactly one month before the expiry of the Front
%       4: Switch exactly one week before the expiry of the Front
%   OpenInterest: table with the Open Interest of the front and next contracts

% build a single time series of the C-Spread
C_spread = table(C_spread_front.Date, zeros(size(C_spread_front.C_Spread)), ...
    'VariableNames', {'Date', 'C_Spread'});

expiries = unique(Front.Expiry);

for expiry = expiries'

    % find the period for the expiry
    selected_dates = Front(Front.Expiry == expiry, :).Date;

    % filter the data for the period
    selected_front = C_spread_front(ismember(C_spread_front.Date, selected_dates), :);
    selected_next = C_spread_next(ismember(C_spread_next.Date, selected_dates), :);

    switch flag

        % rollover strategy 1: Rollover on the 15th of November each year
        case 1
            last_date = datetime(year(expiry), 11, 15);
        
        % rollower strategy 2: Switch when the Open Interest of the Next is higher than the Front
        case 2
            selected_OI = OpenInterest(ismember(OpenInterest.Date, selected_dates), :);

            % find the first date where the Open Interest of the Next is higher than the Front
            last_date = selected_dates(find(selected_OI.Front < selected_OI.Next, 1));

        % rollover strategy 3: Switch exactly one month before the expiry of the Front
        case 3
            last_date = expiry - calmonths(1);

        % rollover strategy 4: Switch exactly one week before the expiry of the Front
        case 4
            last_date = expiry - calweeks(1);

        otherwise
            % throw an error if the flag is not recognized
            error('Flag not recognized');

    end

    % only happens for OI, when the front is always higher than the next
    if isempty(last_date)
        C_spread(ismember(C_spread.Date, selected_dates), :) = selected_front;
        continue;
    end

    % update the C-Spread
    C_spread.C_Spread(C_spread.Date >= selected_dates(1) & C_spread.Date < last_date) = ...
        selected_front.C_Spread(selected_front.Date >= selected_dates(1) & selected_front.Date < last_date);
    C_spread.C_Spread(C_spread.Date >= last_date & C_spread.Date <= selected_dates(end)) = ...
        selected_next.C_Spread(selected_next.Date >= last_date & selected_next.Date <= selected_dates(end));

end
