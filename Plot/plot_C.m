function plot_C(C_spread, save_figure)
% plot_C_Z_r plots the C-Spread and the zero rates
%
% INPUTS
%   C_spread: the C-Spread [table]
%   risk_free_rate: the risk free rate
%   save_figure: a boolean to save the figure [boolean]

% plot the C-Spread
figure;
plot(C_spread.Date, 100 * C_spread.C_Spread)
ylim([-0.7, 3.7])
xlim([C_spread.Date(1) - calmonths(6), C_spread.Date(end)+calmonths(6)])
title('C-Spread')
grid on

legend('C-Spread')

if save_figure
    saveas(gcf, 'Results/C_Spread.png')
end

end