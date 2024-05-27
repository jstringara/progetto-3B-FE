function [Dates, Prices] = loadBondData(Bond, start_date, end_date, target_dates)
% LOADBONDDATA Load the bond data
%
% INPUTS:
%   Bond: bond struct
%   start_date: start date of the data
%   end_date: end date of the data
%   target_dates: dates to match

% get the file name
file_name = "Data/Bonds/" + Bond.Issuer + ".csv";

% import options
opts = detectImportOptions(file_name, 'TreatAsEmpty', {'NA'});
% the third column is a datetime
opts.VariableTypes{3} = 'datetime';
% all other columns are double
opts.VariableTypes(4:end) = {'double'};

% load the data
data = readtable(file_name, opts);
data = data(:, 3:end);

% select only the dates that are between start_date and end_date
data = data(data.Date >= start_date & data.Date <= end_date, :);

% access the column with the bond code
selected_data = data(:, ["Date", Bond.Code]);

% select only the target dates
selected_data = selected_data(ismember(selected_data.Date, target_dates), :);

Dates = selected_data.Date;
Prices = selected_data.(Bond.Code);

end