function plot_Volumes_december(Volumes_dec, grouping)
% plot_Volumes_december - plot the volume of the EUA futures for the
% different December months (front, next, second next)
%
% Inputs:
%    Volumes_dec - the volume of the EUA futures for the different
%    December months
%    grouping - the grouping of the different December months

figure;
boxplot(log10(Volumes_dec+1), ...
    grouping, ...
    'Labels', {'Front December', 'Next December', 'Second next December'})
% set the title and grid
title('Volume of EUA Futures for December')
grid on

end