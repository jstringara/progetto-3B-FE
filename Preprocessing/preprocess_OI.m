function OpenInterest = preprocess_OI(start_date, end_date, Front)
% PREPROCESS_OI Preprocess the Open Interest data
%
% INPUTS:
%   start_date: start date of the data
%   end_date: end date of the data
%   Front: front contract
%   Next: next contract

% import options
opts = detectImportOptions('Data/OpenInterest.xlsx', 'TreatAsEmpty', {'NA'});
% the first column is a datetime
opts.VariableTypes{1} = 'datetime';
% all other columns are double
opts.VariableTypes(2:end) = {'double'};
    
% load the data
data = readtable('Data/OpenInterest.xlsx', opts);

% filter to only use relevant dates
data = data(ismember(data.Date, Front.Date),:);
column_names = data.Properties.VariableNames;

% create the OpenInterest table
OpenInterest = table('Size', [size(data, 1), 3], ...
    'VariableTypes', {'datetime', 'double', 'double'}, ...
    'VariableNames', {'Date', 'Front', 'Next'});
OpenInterest.Date = data.Date;

% build the open interest for the front
years = year(start_date):year(end_date);
prev_date = start_date;

% solve problems with 2014 expiry
Front.Expiry(Front.Expiry==datetime(2014,12,15))=datetime(2014,12,12);

% loop over the years
for y = years

    % find the corresponding column in the data
    col_front = find(contains(column_names, num2str(y)), 1);
    col_next = find(contains(column_names, num2str(y + 1)), 1);

    % find the corresponding expiry date
    expiry_idx = find(Front.Expiry > prev_date, 1);

    % select the data
    selected_data = data(data.Date > prev_date & data.Date <= Front.Expiry(expiry_idx), :);

    % add the data to the OpenInterest table
    OpenInterest.Front(ismember(OpenInterest.Date, selected_data.Date)) = selected_data{:, col_front};
    OpenInterest.Next(ismember(OpenInterest.Date, selected_data.Date)) = selected_data{:, col_next};

    % fill the missing values with 0
    OpenInterest.Front = fillmissing(OpenInterest.Front, 'constant', 0);
    OpenInterest.Next = fillmissing(OpenInterest.Next, 'constant', 0);

    % update the previous date
    prev_date = Front.Expiry(expiry_idx);

end
    
end