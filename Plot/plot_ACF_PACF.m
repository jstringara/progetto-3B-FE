function plot_ACF_PACF(acf, pacf, title)
% plot_ACF_PACF plots the ACF and PACF
%
% INPUTS
% - acf: the ACF [table]
% - pacf: the PACF [table]
% - title: the title of the plot [string]

figure;
subplot(2, 1, 1)
stem(acf.Lags, acf.ACF, 'filled', 'MarkerSize', 3)

% title("ACF")
grid on

subplot(2, 1, 2)
stem(pacf.Lags, pacf.PACF, 'filled', 'MarkerSize', 3)
% title("PACF")
grid on

sgtitle(title)

end