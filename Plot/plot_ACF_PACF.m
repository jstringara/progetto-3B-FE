function plot_ACF_PACF(table, title)
% plot_ACF_PACF plots the ACF and PACF
%
% INPUTS
% - table: the table with the data

figure;
subplot(2, 1, 1)
autocorr(table)

subplot(2, 1, 2)
parcorr(table)

% set the title equal to the table title
sgtitle(title)

end