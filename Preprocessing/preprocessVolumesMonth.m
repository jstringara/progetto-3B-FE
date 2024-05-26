function Volumes = preprocessVolumesMonth(month_name, start_date, end_date)
% Preprocess the volumes for a given month
%
% INPUTS:
%   month_name: name of the month
%   start_date: start date of the data
%   end_date: end date of the data

% load teh excel file
filename = 'Data/Volumes_extra_futures.xlsx';

% create the options for the readtable function
opts = detectImportOptions(filename, 'Sheet', month_name, 'TreatAsEmpty', {'NA'});

% the first column is a datetime
opts.VariableTypes{1} = 'datetime';
% all other columns are double
opts.VariableTypes(2:end) = {'double'};

% load the sheet corresponding to the month name (treat all columns as double)
Sheet_Data = readtable(filename, opts, 'Sheet', month_name);

% filter to only keep the dates between start_date and end_date
Sheet_Data = Sheet_Data(Sheet_Data.Date >= start_date & Sheet_Data.Date <= end_date, :);

% save the column names
column_names = Sheet_Data.Properties.VariableNames;

% get the years on which to loop
years = year(start_date):year(end_date);
prev_date = start_date;

Volumes = table('VariableNames', {'Date', 'Volume'}, 'Size', [0, 2], ...
    'VariableTypes', {'datetime', 'double'});

% loop over the years
for y = years
    % find the corresponding column
    column_name = column_names{contains(column_names, num2str(y))};
    % find the last quoted date (the last date with a non-NaN value)
    last_date = max(Sheet_Data.Date(~isnan(Sheet_Data.(column_name))));

    % from the sheet data take only the date and column_name columns
    selected_data = Sheet_Data(:, {'Date', column_name});
    
    selected_data = selected_data(selected_data.Date > prev_date & selected_data.Date <= last_date, :);
    % fill the missing values with the zero
    selected_data.(column_name) = fillmissing(selected_data.(column_name), 'constant', 0);
    % add it to the Volumes table
    % make it a table with two columns: Date and Volume
    selected_data = table(selected_data.Date, selected_data.(column_name), ...
        'VariableNames', {'Date', 'Volume'});
    % add it to the Volumes table
    Volumes = [Volumes; selected_data];
    % update the previous date
    prev_date = last_date;
end

end