% load and preprocess the OIS data

% dates of Phase III
% HACK: change the dates here to match the desired data
phase_III_dates = [datetime(2013, 1, 1), datetime(2021, 1, 1)];
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

% Fix front expiries
front_expiry = datetime(2022, 12, 19);
% adjust the expiry dates past the phase IV dates
Front_December.Expiry(Front_December.Expiry == phase_IV_dates(2)) = front_expiry;

% adjust the Next expiry dates
front_expiries = unique(Front_December.Expiry);
third_from_last_expiry = front_expiries(end-2);
penultimate_expiry = front_expiries(end-1);
next_expiry = datetime(2023, 12, 18);
% adjust the expiry of the next
Next_December.Expiry(Next_December.Date >= third_from_last_expiry & Next_December.Date < penultimate_expiry) ...
    = front_expiry;
Next_December.Expiry(Next_December.Date >= penultimate_expiry) ...
    = next_expiry;

% adjust the Next 2 expiry dates
fourth_from_last_expiry = front_expiries(end-3);
next_2_expiry = datetime(2024, 12, 23);
% adjust the expiry of the next
Next_2_December.Expiry(Next_2_December.Date >= fourth_from_last_expiry & Next_2_December.Date < third_from_last_expiry) ...
    = front_expiry;
Next_2_December.Expiry(Next_2_December.Date >= third_from_last_expiry & Next_2_December.Date < penultimate_expiry) ...
    = next_expiry;
Next_2_December.Expiry(Next_2_December.Date >= penultimate_expiry) ...
    = next_2_expiry;

% preprocess the bonds data
Bonds = preprocessBonds(phase_IV_dates(1), phase_IV_dates(2), dates);

% load the open interest data for the front and next contracts
OpenInterest = preprocess_OI( phase_IV_dates(1), phase_IV_dates(2), Front_December);

% load the extra variables
Extra_Variables = preprocess_Extra_Variables(Daily_Future.Date);

% take the log return of the daily future
Daily_log_returns = log(Daily_Future.Price ./ lagmatrix(Daily_Future.Price, 1));

clear front_expiry next_expiry dates
