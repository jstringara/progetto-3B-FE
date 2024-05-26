% load and preprocess the OIS data

% load the OIS data
OIS_Data = preprocess_OIS('Data/OIS_Data.csv');

% dates of Phase III
phase_III_dates = [datetime(2013, 1, 1), datetime(2021, 1, 1)];

% create the Volumes for March, June and September
Volumes_march_front = preprocessVolumesMonth('March', phase_III_dates(1), phase_III_dates(2));
Volumes_june_front = preprocessVolumesMonth('June', phase_III_dates(1), phase_III_dates(2));
Volumes_sept_front = preprocessVolumesMonth('September', phase_III_dates(1), phase_III_dates(2));