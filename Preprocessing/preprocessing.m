% load and preprocess the OIS data

% dates of Phase III
% HACK: change the dates here to match the desired data
phase_III_dates = [datetime(2013, 1, 1), datetime(2022, 1, 1)];
phase_IV_dates = [datetime(2013, 1, 1), datetime(2022, 10, 28)];

% load the OIS data
OIS_Data = preprocess_OIS(phase_IV_dates(1), phase_IV_dates(2));

% create the Volumes for March, June and September
Volumes_march_front = preprocessVolumesMonth('March', phase_IV_dates(1), phase_IV_dates(2));
Volumes_june_front = preprocessVolumesMonth('June', phase_IV_dates(1), phase_IV_dates(2));
Volumes_sept_front = preprocessVolumesMonth('September', phase_IV_dates(1), phase_IV_dates(2));

% preprocess the December data
Front_December = preprocessDecember(0, phase_IV_dates(1), phase_IV_dates(2));
Next_December = preprocessDecember(1, phase_IV_dates(1), phase_IV_dates(2));
Next_2_December = preprocessDecember(2, phase_IV_dates(1), phase_IV_dates(2));

% read the daily future
Daily_Future = preprocessDailyFuture(phase_IV_dates(1), phase_IV_dates(2));

% intersect the dates of Front and Daily_Future
dates = intersect(Front_December.Date, Daily_Future.Date);

% filter the data
Front_December = Front_December(ismember(Front_December.Date, dates), :);
Next_December = Next_December(ismember(Next_December.Date, dates), :);
Next_2_December = Next_2_December(ismember(Next_2_December.Date, dates), :);
Daily_Future = Daily_Future(ismember(Daily_Future.Date, dates), :);

% last expiry for the front is 19th december 2022
front_expiry = datetime(2022, 12, 19);
next_expiry = datetime(2023, 3, 18);
% adjust the expiry dates past the phase IV dates
Front_December.Expiry(Front_December.Expiry == phase_IV_dates(2)) = front_expiry;
Next_December.Expiry(Next_December.Expiry == phase_IV_dates(2)) = next_expiry;

% preprocess the bonds data
Bonds = preprocessBonds(phase_IV_dates(1), phase_IV_dates(2), dates);

% load the open interest data for the front and next contracts
OpenInterest = preprocess_OI( phase_IV_dates(1), phase_IV_dates(2), Front_December);
