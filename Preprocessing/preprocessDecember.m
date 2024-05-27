function Front = preprocessDecember(offset, start_date, end_date)
% Preprocess the prices and volumes for the December futures
%
% INPUTS:
%   years_offset: number of years to offset the data
%   start_date: start date of the data
%   end_date: end date of the data

% create an empty table to store the data
Front = table('VariableNames', {'Date', 'Price', 'Volume', 'Expiry'}, 'Size', [0, 4], ...
    'VariableTypes', {'datetime', 'double', 'double', 'datetime'});

% loop over the years
years = year(start_date):year(end_date);

% initialize the previous date
prev_date = start_date;

for y = years

    % get the file name of the front (use only the last two digits)
    file_name = ['Data/Futures/ICE_FUT_', num2str(mod(y, 100), '%02d'), '.csv'];

    % load the data, only the date, volume and close columns
    front = readtable(file_name);
    front = front(:, {'Date', 'CLOSE', 'VOLUME'}); % select only the relevant columns
    front.Properties.VariableNames = {'Date', 'Price', 'Volume'}; % rename the columns

    % find the last quoted date of that year 
    last_date = max(front.Date(~isnan(front.Price)));

    % if there is an offset, find the corresponding file
    if offset ~= 0
        offset_file = ['Data/Futures/ICE_FUT_', num2str(mod(y + offset, 100), '%02d'), '.csv'];
        selected_data = readtable(offset_file);
        selected_data = selected_data(:, {'Date', 'CLOSE', 'VOLUME'});
        selected_data.Properties.VariableNames = {'Date', 'Price', 'Volume'};
    else
        selected_data = front;
    end

    % find the expiry date
    expiry_date = max(selected_data.Date(~isnan(selected_data.Price)));

    % select the data
    selected_data = selected_data(selected_data.Date >= prev_date & selected_data.Date < last_date, :);

    % fill the volume with 0
    selected_data.Volume = fillmissing(selected_data.Volume, 'constant', 0);
    % add the expiry date to the data
    selected_data.Expiry = repmat(expiry_date, size(selected_data, 1), 1);

    % add it to the Front table
    Front = [Front; selected_data];

    % update the previous date
    prev_date = last_date;

end

end