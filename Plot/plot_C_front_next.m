function plot_C_front_next(C_spread_front, C_spread_next)
% plot_C_front_next: Plot the C-Spread for the front December and next December EUA futures
%
%   INPUT:
%       C_spread_front: C-Spread for the front December EUA futures [table]
%       C_spread_next: C-Spread for the next December EUA futures [table]

figure;
plot(C_spread_front.Date, 100 * C_spread_front.C_Spread, 'b', 'LineWidth', 1.5);
hold on
plot(C_spread_next.Date, 100 * C_spread_next.C_Spread, 'r', 'LineWidth', 1.5);
legend('Front December', 'Next December');
title('C-Spread for the front December and next December EUA futures');
% we bring back the low end of the x-axis to 6 months before the first date
xlim([C_spread_front.Date(1) - calmonths(6), C_spread_front.Date(end)]);
ylim([-1, 5])
xlabel('Date');
ylabel('C-Spread');
datetick('x', 'yyyy', 'keeplimits');
grid on

end