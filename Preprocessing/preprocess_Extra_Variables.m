function extra_variables = preprocess_Extra_Variables(dates)

% load the extra variables
extra_variables = readtable('Extra_Variables.csv');

% transform the dates into datetime
% format is weekday full name, month full name day, full year
date_format = 'eeee, MMMM d, yyyy';
extra_variables.Date = string(extra_variables.Date);
extra_variables.Date = datetime(extra_variables.Date, 'InputFormat', date_format);

% filter them by the dates to match the other variables
extra_variables = extra_variables(ismember(extra_variables.Date, dates), :);

% keep only the columns 'SPX', 'VIX', 'WTI'
extra_variables = extra_variables(:, {'Date', 'SPX', 'VIX', 'WTI'});

% use only the dates appearing in the dates vector
extra_variables = extra_variables(ismember(extra_variables.Date, dates), :);

% fill the missing values with the previous value
extra_variables = fillmissing(extra_variables, 'previous');

% take the log return of the SPX and WTI
extra_variables.SPX = log(extra_variables.SPX ./ lagmatrix(extra_variables.SPX, 1));
extra_variables.WTI = log(extra_variables.WTI ./ lagmatrix(extra_variables.WTI, 1));

end