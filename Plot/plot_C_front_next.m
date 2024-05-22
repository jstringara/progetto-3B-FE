function plot_C_front_next(C_spread_front, C_spread_next, dates)

figure;
plot(common_dates, 100 * C_spread_front, 'b', 'LineWidth', 1.5);
hold on
plot(common_dates, 100 * C_spread_next, 'r', 'LineWidth', 1.5);
legend('Front December', 'Next December');
title('C-Spread for the front December and next December EUA futures');
xlim([dates(1) - calmonths(6), dates(end)])
ylim([-1, 5])
xlabel('Date');
ylabel('C-Spread');
datetick('x', 'yyyy', 'keeplimits');
grid on

end