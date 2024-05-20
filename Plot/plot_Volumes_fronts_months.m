function plot_Volumes_fronts_months(Volumes_fronts_months, grouping)
% plot_Volumes_fronts_months - plot the volume of the EUA futures for the
% different front months
%
% Inputs:
%    Volumes_fronts_months - the volume of the EUA futures for the different
%    front months
%    grouping - the grouping of the different front months

figure;
boxplot(log10(Volumes_fronts_months+1), ...
    grouping, ...
    'Labels', {'March', 'June', 'September', 'December'})
% set the title and grid
title('Volume of EUA Futures')
grid on

end