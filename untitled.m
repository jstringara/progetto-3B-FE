% runFinalProject_Group3B
%  Group 3B, AY2023-2024
% 
%
% to run:
% > runFinalProject_Group3B.m

clc
clear all
close all

tic

% fix random seed
rng(42) % the answer to everything in the universe

%% Add the directories to the path

addpath('Data');

%% Point 1) Bootstrap the interest rates curve for each date

OIS_Data = readtable('OIS_Data.csv');

% convert the dates to datetime
OIS_Data.Date = OIS_Data.Date + calyears(2000);

% fill with previous day and then remove rows with nans
OIS_Data = fillmissing(OIS_Data, 'previous');
OIS_Data = rmmissing(OIS_Data);

% remove duplicate
OIS_Data = unique(OIS_Data,'rows');

% Put the rates into percentages
OIS_Data{:,2:end} = OIS_Data{:,2:end} / 100;

% extract the vector of t_0
t0 = OIS_Data.Date;

% for each date create the corresponding row of the vector
offsets = [calweeks(0:3), calmonths(1:11), calmonths(12:3:21), calyears(2:10)];
dates = NaT(length(t0), length(offsets));

for i = 1:length(dates)
    dates(i,:) = t0(i) + offsets;
end

% move to business days
dates(~isbusday(dates(:,2:end),eurCalendar())) = ...
    busdate(dates(~isbusday(dates(:,2:end), eurCalendar())), 'modifiedfollow', eurCalendar());

% compute the yearfractions
ACT_360 = 2;
ACT_365 = 3;
THIRTY_360 = 6;
yf = zeros(length(t0), length(offsets)-1);
for i = 1:length(t0)
    yf(i,:) = yearfrac(t0(i), dates(i,2:end), THIRTY_360);
end

% compute the discounts factors curve for each date
DF = zeros(length(t0), length(offsets)-1);

% for dates less than one year, we compute directly
DF(:,1:15) = 1./(1 + OIS_Data{:,2:16} .* yf(:,1:15));

% inizializ the sum for 1y
S = yf(:,1:15) .* DF(:,15);


delta_3m=yearfrac(dates(:,7),dates(:,17),THIRTY_360); %delta between 3m and 15m
delta_6m=yearfrac(dates(:,10),dates(:,18),THIRTY_360); %delta between 6m and 18m
delta_9m=yearfrac(dates(:,13),dates(:,19),THIRTY_360); %delta between 9m and 21m

DF(:,16)=(1-OIS_Data{:,17}.*yf(:,6).*DF(:,6))./(1+delta_3m.*OIS_Data{:,17});
DF(:,17)=(1-OIS_Data{:,18}.*yf(:,9).*DF(:,9))./(1+delta_6m.*OIS_Data{:,18});
DF(:,18)=(1-OIS_Data{:,19}.*yf(:,12).*DF(:,12))./(1+delta_9m.*OIS_Data{:,19});

dates_1y=dates(:,[1,16,20:28]);
delta_fwd_1y=yearfrac(dates_1y(:,1:end-1),dates_1y(:,2:end),THIRTY_360);

S = delta_fwd_1y(:,1).* DF(:,15);



% for dates greater than 2 years (or equal), we use the previous discounts
for j = 19:length(offsets)-1
    % for each date, get the relevant OIS rate
    R = OIS_Data{:,j+1};
    DF(:,j) = (1 - R .* S) ./ (1 + delta_fwd_1y(:,j-17) .* R);
    % update the sum
    S = S + delta_fwd_1y(:,j-17) .* DF(:,j);
end

delta_rates = zeros(length(t0), length(offsets)-1);
for i = 1:length(t0)
    delta_rates(i,:) = yearfrac(t0(i), dates(i,2:end), ACT_365);
end
zrates = zeros(length(t0), length(offsets)-1);
zrates = -log(DF)./delta_rates;


plot(dates(698,2:end),zrates(698,:))

%% Point 2
% import quarterly future volumes 
load('dates_front.mat')
load('Volumes_March.mat')
dates_front = Volumesextrafutures;
dates_March=dates_front(90:2697);
Volumes_March = Volumesextrafutures1;
Volumes_March(isnan(Volumes_March))=0;
Volumes_March=Volumes_March(90:2697,:);
volumes_front_March=[];
dates_March=datetime(dates_March);
dates_start=datetime(dates_March(1));
dates_end=datetime(dates_March(262));
values=[];
for ii=1:10
    j1=find(dates_March>=dates_start,1);
    j2=find(dates_March>=dates_end,1);
    values=Volumes_March(j1:j2-1,ii+1);
    volumes_front_March=[volumes_front_March;values];
    dates_start=dates_start+calyears(1);
    dates_end=dates_end+calyears(1);
    values=[];
end
figure(1)
boxplot(log10(volumes_front_March))

%%
load('Volumes_June.mat')
Dates_June=dates_front(156:2764);
Volumes_June=VolumesextrafuturesS1;
Volumes_June(isnan(Volumes_June))=0;
Volumes_June=Volumes_June(156:2764,:);
volumes_front_June=[];
inputFormat = 'dd-MMM-yyyy'; % Formato con giorno, mese abbreviato e anno
locale = 'it_IT'; % Lingua locale italiana
% Converti le stringhe di data in datetime
Dates_June = datetime(Dates_June, 'InputFormat', inputFormat, 'Locale', locale);
dates_start=datetime(Dates_June(1));
dates_end=datetime('31-May-2013');
values=[];
for ii=1:10
    j1=find(Dates_June>=dates_start,1);
    j2=find(Dates_June>=dates_end,1);
    values=Volumes_June(j1:j2-1,ii+1);
    volumes_front_June=[volumes_front_June;values];
    dates_start=dates_start+calyears(1);
    dates_end=dates_end+calyears(1);
    values=[];
end
figure(2)
boxplot(log10(volumes_front_June+1))

%% 
load('Volumes_Sept.mat')
Dates_Sept=dates_front(222:2852);
Volumes_Sept=volumes_data_sept;
Volumes_Sept(isnan(Volumes_Sept))=0;
Volumes_Sept=Volumes_Sept(222:2852,:);
volumes_front_Sept=[];
inputFormat = 'dd-MMM-yyyy'; % Formato con giorno, mese abbreviato e anno
locale = 'it_IT'; % Lingua locale italiana
% Converti le stringhe di data in datetime
Dates_Sept = datetime(Dates_Sept, 'InputFormat', inputFormat, 'Locale', locale);
dates_start=datetime(Dates_Sept(1));
dates_end=datetime('30-Aug-2013');
values=[];
for ii=1:10
    j1=find(Dates_Sept>=dates_start,1);
    j2=find(Dates_Sept>=dates_end,1);
    values=Volumes_Sept(j1:j2-1,ii+1);
    volumes_front_Sept=[volumes_front_Sept;values];
    dates_start=dates_start+calyears(1);
    dates_end=dates_end+calyears(1);
    values=[];
end
figure(3)
boxplot(log10(volumes_front_Sept+1))


