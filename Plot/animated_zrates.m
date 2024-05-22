function animated_zrates(zrates, dates)
% animated_zrates plots the zero rates for each date
%
% INPUTS
% - zrates: the zero rates
% - dates: the dates for which we have the interest rates

% animation for the zero rates
figure;
% create the annotation for the difference between the 3M and 1Y zero rates
spread_box = ...
    annotation('textbox', [0.15, 0.8, 0.1, 0.1], 'String', 'Spread 3M-1Y: ', 'FitBoxToText', 'on');

for i=1:size(zrates,1)
    plot(dates(i,2:end), 100 * zrates(i,:))
    % if we are not at the first iteration
    if i > 1
        % show the previous plot in dashed line
        hold on
        plot(dates(i-1,2:end), 100 * zrates(i-1,:), '--')
    hold off
    end
    % plot the difference between the 3M and 1Y zero rates
    diff = 100 * (zrates(i,3) - zrates(i,5));
    diff_str = sprintf( 'Spread 3M-1Y: %.2f%%', diff);
    set(spread_box, 'String', diff_str)
    title_str = sprintf('Zero rates for date %s', dates(i,1));
    title(title_str)
    xlabel('Dates')
    ylabel('Rates (%)')
    legend('Current', 'Previous')
    grid on
    ylim([-1, 4])
    pause(0.0000001)
end

end