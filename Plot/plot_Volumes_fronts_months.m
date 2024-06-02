function plot_Volumes_fronts_months(Volumes_fronts_months, grouping, save_figure)
% plot_Volumes_fronts_months - plot the volume of the EUA futures for the
% different front months
%
% Inputs:
%    Volumes_fronts_months - the volume of the EUA futures for the different
%    front months
%    grouping - the grouping of the different front months
%    save_figure - a boolean to save the figure

figure;
boxplot(log10(Volumes_fronts_months+1), ...
    grouping, ...
    'Labels', {'March', 'June', 'September', 'December'})
% set the title and grid
title('Volume of EUA Futures')
grid on

% if save_figure is true, save the figure
if save_figure
    saveas(gcf, 'Results/Volume_of_EUA_Futures.png')
end

end