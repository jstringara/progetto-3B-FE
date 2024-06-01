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
years = unique(year(C_spread_front.Date));

% apply the different rollover strategies
switch flag

    % rollover strategy 1: Rollover on the 15th of November each year
    case 1
        % each year up to the 15th of November we use the front December
        % after the 15th of November and up to the front's expiry we use the next December

        prev_date = datetime(years(1)-1, 11, 15);

        % for each year
        for i = 1:length(years)

            value_year = years(i);

            % find the expiry for that year as the expiry with matching year
            expiry_front = Front.Expiry(year(Front.Date) == value_year);
            expiry_front = expiry_front(1);

            % compute the last front date (15th of November of the same year)
            last_front_date = datetime(value_year, 11, 15);

            % from the previous date to the 15th of November take the front December
            C_spread.C_Spread(C_spread.Date >= prev_date & C_spread.Date < last_front_date) = ...
                C_spread_front.C_Spread(C_spread.Date >= prev_date & C_spread.Date < last_front_date);
            % from the 15th of November to the expiry take the next December
            C_spread.C_Spread(C_spread.Date >= last_front_date & C_spread.Date < expiry_front) = ...
                C_spread_next.C_Spread(C_spread.Date >= last_front_date & C_spread.Date < expiry_front);

            % update the previous date
            prev_date = expiry_front;

        end
    
    % rollover strategy 2: Switch when the Open Interest of the Next is higher than the Front
    case 2

        % each year up to the front open interest bigger than the next one
        prev_date = datetime(years(1), 1, 1);
        change_dates = OpenInterest.Date(find(OpenInterest.Front < OpenInterest.Next));
        
        % for each year
        for i = 1:length(years)

            value_year = years(i);

            % find the expiry for that year as the expiry with matching year
            expiry_front = Front.Expiry(year(Front.Date) == value_year);
            expiry_front = expiry_front(1);

            % computing last front date
            index_front_date = find(year(change_dates) == value_year,1);
            last_front_date = change_dates(index_front_date);

            % if no date is found, just use the front December
            if isempty(index_front_date)
                C_spread.C_Spread(C_spread.Date >= prev_date & C_spread.Date < expiry_front) = ...
                    C_spread_front.C_Spread(C_spread.Date >= prev_date & C_spread.Date < expiry_front);
            else
                % take the front until the last front date
                C_spread.C_Spread(C_spread.Date >= prev_date & C_spread.Date < last_front_date) = ...
                    C_spread_front.C_Spread(C_spread.Date >= prev_date & C_spread.Date < last_front_date);
                % from the last front date to the expiry take the next December
                C_spread.C_Spread(C_spread.Date >= last_front_date & C_spread.Date < expiry_front) = ...
                    C_spread_next.C_Spread(C_spread.Date >= last_front_date & C_spread.Date < expiry_front);
            end

            % update the previous date
            prev_date = expiry_front;
        
        end

    % rollover strategy 3: Switch exactly one month before the expiry of the Front
    case 3

        prev_date = Front.Expiry(1) - calmonths(1) - calyears(1);
        
        % for each year
        for i = 1:length(years)
            value_year = years(i);

            % find the expiry for that year as the expiry with matching year
            expiry_front = Front.Expiry(year(Front.Date) == value_year);
            expiry_front = expiry_front(1);

            % compute the last front date exactly one month before the expiry
            last_front_date = expiry_front-calmonths(1);

            % from the previous date to one month before the expiry take the front December
            C_spread.C_Spread(C_spread.Date >= prev_date & C_spread.Date < last_front_date) = ...
                C_spread_front.C_Spread(C_spread.Date >= prev_date & C_spread.Date < last_front_date);
            % from the last front date to the expiry take the next December
            C_spread.C_Spread(C_spread.Date >= last_front_date & C_spread.Date < expiry_front) = ...
                C_spread_next.C_Spread(C_spread.Date >= last_front_date & C_spread.Date < expiry_front);

            % update the previous date
            prev_date = expiry_front;

        end
    
    % rollover strategy 4: Switch exactly one week before the expiry of the Front
    case 4

        prev_date = Front.Expiry(1) - calweeks(1) - calyears(1);
        
        % for each year
        for i = 1:length(years)

            value_year = years(i);

            % find the expiry for that year as the expiry with matching year
            expiry_front = Front.Expiry(year(Front.Date) == value_year);
            expiry_front = expiry_front(1);

            % compute the last front date as one week before the expiry
            last_front_date = expiry_front - calweeks(1);

            % from the previous date to one week before the expiry take the front December
            C_spread.C_Spread(C_spread.Date >= prev_date & C_spread.Date < last_front_date) = ...
                C_spread_front.C_Spread(C_spread.Date >= prev_date & C_spread.Date < last_front_date);
            % from one week before the expiry to the expiry take the next December
            C_spread.C_Spread(C_spread.Date >= last_front_date & C_spread.Date < expiry_front) = ...
                C_spread_next.C_Spread(C_spread.Date >= last_front_date & C_spread.Date < expiry_front);

            % update the previous date
            prev_date = expiry_front;

        end

    otherwise
        % throw an error if the flag is not recognized
        error('Flag not recognized');
end
