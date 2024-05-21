function animated_zrates(zrates, dates)

% animation with slider for the zero rates
figure;
for i=1:size(zrates,1)
    plot(dates(i,2:end), 100 * zrates(i,:))
    title_str = sprintf('Zero rates for date %s', dates(i,1));
    title(title_str)
    xlabel('Dates')
    ylabel('Rates (%)')
    grid on
    ylim([-0.6, 3.6])
    pause(0.1)
end

end