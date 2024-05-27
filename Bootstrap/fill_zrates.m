function [new_dates, new_zrates] = fill_zrates(zrates, dates, target_dates)
% FILL_ZRATES Fill the zero rates
%
% INPUTS
% - zrates: the zero rates [matrix]
% - dates: the dates [matrix]
% - target_dates: the target dates [vector]

% new zero rates and dates
new_dates = NaT(length(target_dates), size(dates, 2));
new_zrates = zeros(length(target_dates), size(zrates, 2));

% fill in the data
for i = 1:length(target_dates)
    % if the date is found, copy the data
    idx = find(dates(:,1) == target_dates(i));
    if ~isempty(idx)
        new_dates(i,:) = dates(idx,:);
        new_zrates(i,:) = zrates(idx,:);
    % if the date is not found, fill the zero rates with the previous value
    else
        % fill the rates with the previous value
        new_zrates(i,:) = new_zrates(i-1,:);
        % the dates are the same but moved by the difference
        new_dates(i,:) = new_dates(i-1,:) + (target_dates(i) - target_dates(i-1));
    end
end 

end