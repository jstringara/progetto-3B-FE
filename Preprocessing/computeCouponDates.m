function couponDates = computeCouponDates(Bond)
% COMPUTECOUPONDATES Compute the coupon dates
%
% INPUTS:
%   Bond: bond struct

% compute the coupon duration
coupon_duration = calmonths(12 / Bond.CouponFrequency);

% compute the coupon dates starting from the expiration date
couponDates = Bond.MaturityDate:-coupon_duration:Bond.FirstQuote;

% sort the coupon dates
couponDates = sort(couponDates);

end