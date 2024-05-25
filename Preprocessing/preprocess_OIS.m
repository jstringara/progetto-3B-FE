function OIS_Data = preprocess_OIS(path)
% PREPROCESS_OIS Preprocess the OIS data
%
% INPUTS:
%   path: path to the OIS data

% load the data
OIS_Data = readtable(path);

% convert the dates to datetime
OIS_Data.Date = OIS_Data.Date + calyears(2000);

% fill with previous day and then remove rows with nans
OIS_Data = fillmissing(OIS_Data, 'previous');
OIS_Data = rmmissing(OIS_Data);

% remove duplicate based on the date
OIS_Data = unique(OIS_Data);

% Put the rates into percentages
OIS_Data{:,2:end} = OIS_Data{:,2:end} / 100;

end