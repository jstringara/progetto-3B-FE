function ZSpreads = compute_ZSpread(Bond, dates, zrates)
% compute_ZSpread computes the Z-Spread for a given bond
%
% INPUTS
% - Bond: the bond [structure]
% - dates: the dates [matrix]
% - zrates: the zero rates [matrix]

% compute the Z-Spread
ZSpreads = zeros(height(dates), 1);

% TODO: parallelize this using fsolve instead of fzero

for i=1:height(dates)

    % set to 0 the Z-spread if the bond is not active
    if isnan(Bond.Prices(i)) 
        ZSpreads(i) = 0;
    % there is a valid price
    else
        % find the zrates on the coupon dates which are bigger than the last NaN value
        coupon_dates = Bond.CouponDates(Bond.CouponDates >= dates(i,1));
        %compute zero rates on the valid coupon dates
        zrates_coupons = interp1(dates(i,2:end), zrates(i,:), coupon_dates, 'nearest', 'extrap');
        % set the zrates before the first date to 0
        zrates_coupons(coupon_dates < dates(i,2)) = 0;
        % compute the yearfractions
        EU_30_360 = 6;
        yf_coupon = yearfrac([dates(i,1); coupon_dates(1:end-1)], coupon_dates, EU_30_360);
        yf = yearfrac(dates(i,1), coupon_dates, EU_30_360);
        % any yeafraction is less than 0.01, set the Z-spread to 0
        % # TODO: sistemare la condizione. Il vecchio era se qualunque yf è minore di 0.01
        if max(yf) < 0.075
            ZSpreads(i) = 0;
            continue;
        end
        % % if the yf is 0, set the Z-spread to 0
        % if any(yf == 0)
        %     ZSpreads(i) = 0;
        %     continue;
        % end
        % compute the coupons
        coupons = Bond.CouponRate * yf_coupon;
        coupons(end) = coupons(end) + 100; % add the principal at the end
        % compute the price as a function of the z-spread
        price = @(z) coupons' * exp( (- z - zrates_coupons) .* yf);
        % compute the Z-spread using fzero (start from the previous value)
        prev = 0;
        if i > 1
            prev = ZSpreads(i-1);
        end
        ZSpreads(i) = fzero(@(z) price(z) - Bond.Prices(i), prev);
    end

end