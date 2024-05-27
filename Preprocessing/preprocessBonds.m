function Bonds = preprocessBonds(start_date, end_date, target_dates)
% PREPROCESSBONDS Preprocess the bonds data
%
% INPUTS:
%   start_date: start date of the data
%   end_date: end date of the data
%   target_dates: dates to match

% load the list of valid bonds
list_valid_bonds = readtable('Data/Bonds/List_Valid_Bonds.csv');

% drop the first column
list_valid_bonds = list_valid_bonds(:, 2:end);

% keep only the interesting columns
list_valid_bonds = list_valid_bonds(:, ...
    {'Instrument', 'CouponRate', 'MaturityDate', ...
    'OriginalAmountIssued', 'CouponFrequency', 'ParentTicker'});

% cast to string
list_valid_bonds.Instrument = string(list_valid_bonds.Instrument);
list_valid_bonds.ParentTicker = string(list_valid_bonds.ParentTicker);

% keep only the companies in the table
issuers_to_keep = ["MT", "ENEI", "ENGIE", "LAFARGE", "HEIG", "EDF", "ENI", "TTEF", "MAERS", ...
        "EONG", "CEZP", "VIE"];
list_valid_bonds = list_valid_bonds(ismember(list_valid_bonds.ParentTicker, issuers_to_keep), :);

% keep only bonds with more than 500 million issued
list_valid_bonds = list_valid_bonds(list_valid_bonds.OriginalAmountIssued >= 500 * 10^6, :);

% load the bonds data
Bonds = {};
Unfound_Bonds = {};

Issuers_data = struct(); % struct to store the data for each issuer (to avoid loading the same data multiple times)

for i = 1:size(list_valid_bonds, 1)

    % create the Bond struct
    Bond = struct();
    Bond.Code = list_valid_bonds.Instrument(i);
    Bond.CouponRate = list_valid_bonds.CouponRate(i);
    Bond.MaturityDate = list_valid_bonds.MaturityDate(i);
    Bond.CouponFrequency = list_valid_bonds.CouponFrequency(i);
    Bond.Volume = list_valid_bonds.OriginalAmountIssued(i);
    Bond.Issuer = list_valid_bonds.ParentTicker(i);

    % load the data (if available)
    try
        [Bond.Dates, Bond.Prices, Issuers_data] = ...
            loadBondData(Bond, Issuers_data, start_date, end_date, target_dates);
    catch
        Bond.Dates = [];
        Bond.Prices = [];
    end

    % if the data is empty, add it to the Unfound_Bonds
    if isempty(Bond.Dates)
        Unfound_Bonds = [Unfound_Bonds; Bond];
        continue;
    end

    % compute the first quote date (the first date with a non-NaN price)
    Bond.FirstQuote = min(Bond.Dates(~isnan(Bond.Prices)));
    
    % compute the coupon dates
    Bond.CouponDates = computeCouponDates(Bond);

    % add the Bond to the Bonds cell array
    Bonds = [Bonds; Bond];

end

end