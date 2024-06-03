function plot_quantile(y, y_quantile_lb, y_quantile_ub, tau_lb, tau_ub)
% plot_quantile plots the quantile regression
%
% Inputs:
%   y: the real y values
%   y_quantile_lb: the quantile regression for tau = tau_lb
%   y_quantile_ub: the quantile regression for tau = tau_ub
%   tau_lb: the lower bound of the quantile
%   tau_ub: the upper bound of the quantile

figure;

% Plot the real y in black
l = length(y);

plot(1:l, y, 'DisplayName', 'y', 'Color', 'k')

hold on

% plot the two quantiles with the same color
plot(1:l, y_quantile_lb, 'DisplayName', ['\tau = ', num2str(tau_lb)])

% get the color of the first line
c = get(gca, 'ColorOrder');

% plot the two quantiles with the same color
plot(1:l, y_quantile_ub, 'DisplayName', ['\tau = ', num2str(tau_ub)], 'Color', c(1, :))

title(['Plot for \tau = ', num2str(tau_lb), ' and \tau = ', num2str(tau_ub)])

legend('Real y', ['\tau = ', num2str(tau_lb)], ['\tau = ', num2str(tau_ub)], 'Location', 'best')

hold off

end