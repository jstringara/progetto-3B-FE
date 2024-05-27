% load and preprocess the OIS data

% load the OIS data
OIS_Data = preprocess_OIS('Data/OIS_Data.csv');

% dates of Phase III
% HACK: change the dates here to match the desired data
phase_III_dates = [datetime(2013, 1, 1), datetime(2022, 1, 1)];

% create the Volumes for March, June and September
Volumes_march_front = preprocessVolumesMonth('March', phase_III_dates(1), phase_III_dates(2));
Volumes_june_front = preprocessVolumesMonth('June', phase_III_dates(1), phase_III_dates(2));
Volumes_sept_front = preprocessVolumesMonth('September', phase_III_dates(1), phase_III_dates(2));

% preprocess the December data
Front_December = preprocessDecember(0, phase_III_dates(1), phase_III_dates(2));
Next_December = preprocessDecember(1, phase_III_dates(1), phase_III_dates(2));
Next_2_December = preprocessDecember(2, phase_III_dates(1), phase_III_dates(2));

% read the daily future
Daily_Future = preprocessDailyFuture(phase_III_dates(1), phase_III_dates(2));

% intersect the dates of Front and Daily_Future
dates = intersect(Front_December.Date, Daily_Future.Date);

% filter the data
Front_December = Front_December(ismember(Front_December.Date, dates), :);
Next_December = Next_December(ismember(Next_December.Date, dates), :);
Next_2_December = Next_2_December(ismember(Next_2_December.Date, dates), :);
Daily_Future = Daily_Future(ismember(Daily_Future.Date, dates), :);

% fill in the OIS_Data to fully match the dates of the future
new_OIS_Data = table('Size', [length(dates), size(OIS_Data, 2)], ...
    'VariableTypes', varfun(@class, OIS_Data, 'OutputFormat', 'cell'));
new_OIS_Data.Properties.VariableNames = OIS_Data.Properties.VariableNames;
new_OIS_Data.Date = dates;
new_OIS_Data{ismember(dates, OIS_Data.Date), 2:end} = OIS_Data{ismember(OIS_Data.Date, dates), 2:end};
new_OIS_Data = fillmissing(new_OIS_Data, 'previous');

% merge the data
OIS_Data = new_OIS_Data;

% preprocess the bonds data
Bonds = preprocessBonds(phase_III_dates(1), phase_III_dates(2));
