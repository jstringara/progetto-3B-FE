function plot_C_Z_r(C_spread, Z_spread, risk_free_rate)
% plot_C_Z_r plots the C-Spread and the zero rates
%
% INPUTS
% - C_spread: the C-Spread [table]
% - Z_spread: the Z-Spread [table]
% - risk_free_rate: the risk free rate
%

% plot the C-Spread, along with the zero rates
figure;
plot(C_spread.Date, 100 * C_spread.C_Spread, 'blue')
hold on
% plot the Z-Spread in orange (#D95319)
plot(Z_spread.Date, 100 * Z_spread.Z_Spread, ...
    'Color', [0.8500 0.3250 0.0980])
plot(C_spread.Date, 100 * risk_free_rate.Risk_Free_Rate, 'black')
hold on
% only keep date between the first recorded and the last of 2021
xlim([C_spread.Date(1) - calmonths(6), C_spread.Date(end) + calmonths(6)])
% only keep date between the first recorded and october 2022
% xlim([C_spread.Date(1) - calmonths(6), datetime(2022, 10, 31)])
ylim([-0.7, 3.7])
title('C-Spread')
grid on

legend('C-Spread', 'Z-Spread', 'Risk-Free Rate')

end