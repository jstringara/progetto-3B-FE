function OIS_Data = preprocess_OIS(start_date, end_date)
% PREPROCESS_OIS Preprocess the OIS data
%
% INPUTS:
%   start_date: start date of the data
%   end_date: end date of the data

% load the data
OIS_Data = readtable('Data/OIS_Data.csv');

% convert the dates to datetime
OIS_Data.Date = OIS_Data.Date + calyears(2000);

% fill with previous day and then remove rows with nans
OIS_Data = fillmissing(OIS_Data, 'previous');
OIS_Data = rmmissing(OIS_Data);

% remove duplicate based on the date
OIS_Data = unique(OIS_Data);

% Put the rates into percentages
OIS_Data{:,2:end} = OIS_Data{:,2:end} / 100;

% select only the dates that are between start_date and end_date
OIS_Data = OIS_Data(OIS_Data.Date >= start_date & OIS_Data.Date <= end_date, :);

end