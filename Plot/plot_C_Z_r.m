function plot_C_Z_r(dates, C_spread, risk_free_rate)
% plot_C_Z_r plots the C-Spread and the zero rates
%
% INPUTS
% - dates: the dates for which we have the interest rates
% - C_spread: the C-Spread
% - risk_free_rate: the risk free rate
%

% plot the C-Spread, along with the zero rates
figure;
plot(dates, 100 * C_spread)
hold on
plot(dates, 100 * risk_free_rate)
ylim([-0.7, 3.7])
% TODO: le dates andiamo indietro di un tot di tre mesi solo sulla start date
xlim([dates(1) - calmonths(6), dates(end)])
title('C-Spread')
grid on

end