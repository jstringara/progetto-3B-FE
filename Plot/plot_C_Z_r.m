function plot_C_Z_r(C_spread, risk_free_rate)
% plot_C_Z_r plots the C-Spread and the zero rates
%
% INPUTS
% - C_spread: the C-Spread [table]
% - risk_free_rate: the risk free rate
%

% plot the C-Spread, along with the zero rates
figure;
plot(C_spread.Date, 100 * C_spread.C_Spread)
hold on
plot(C_spread.Date, 100 * risk_free_rate)
ylim([-0.7, 3.7])
% TODO: le dates andiamo indietro di un tot di tre mesi solo sulla start date
xlim([C_spread.Date(1) - calmonths(6), C_spread.Date(end)])
title('C-Spread')
grid on

end