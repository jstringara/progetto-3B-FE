function Daily_Future = preprocessDailyFuture(start_date, end_date)
% Preprocess the daily prices
%
% INPUTS:
%   start_date: start date of the data
%   end_date: end date of the data

% read the table
Daily_Future = readtable('Data/Daily_Future.csv');
Daily_Future = Daily_Future(:, {'Date', 'CLOSE'}); % select only the relevant columns
Daily_Future.Properties.VariableNames = {'Date', 'Price'}; % rename the columns

% filter to only keep the dates between start_date and end_date
Daily_Future = Daily_Future(Daily_Future.Date >= start_date & Daily_Future.Date <= end_date, :);

end