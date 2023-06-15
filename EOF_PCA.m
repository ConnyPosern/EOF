%skript to load a 3D-data set (longitude, latitude, time) and calculate its
%EOF/PCA. I am using a tutorial which you can access under 
%https://www.chadagreene.com/CDT/eof_documentation.html#1

close all; clear;
%load data (data set should be in a .mat format, with 3 dimensions
%(lat=latitude, lon=longitude, t=time) and all double
%example with sea surface temperature data for the Pacific downloaded from 
%https://de.mathworks.com/matlabcentral/fileexchange/61345-eof
% load ('north_atlantic_sst.mat')
load ('PacOcean.mat')

%convert all arrays into double
lat = double(lat);
lon = double(lon);
sst = double(sst); %here you have to put in the name of your sst data array

%convert the time vector into a serial date number
t=datenum(t);

% Calculate the first EOF of sea surface temperatures and its 
% principal component time series: 
[eofmap,pc] = eof(sst,1);

% Plot the first EOF map: 
imagesc(lon,lat,eofmap); 
axis xy image off
% Optional: Use a cmocean colormap:
cmocean('balance','pivot',0)
a=colorbar;
ylabel(a,'sst anomaly °C')

% That's the first EOF of the SST dataset, but since we haven't removed the seasonal cycle, 
% the first EOF primarily represents seasonal variability.  As evidence that the pattern
% above is associated with the seasonal cycle, take a look at the corresponding principal component 
% time series.
figure
plot(t,pc)
axis tight
xlim([datenum('jan 1, 1990') datenum('jan 1, 1995')])
datetick('x','keeplimits')
%
% That looks pretty seasonal to me.  If you prefer to plot the anomaly time series in the common two-color 
% shaded style, use the <https://www.mathworks.com/matlabcentral/fileexchange/61327-anomaly/content/anomaly/html/anomaly_documentation.html
% |anomaly|> function available on File Exchange. 
anomaly(t,pc) 

datestr(t([1 end])) %time range
mean(diff(t)) %time step

figure
imagesc(lon,lat,mean(sst,3)); 
axis xy off
cb = colorbar; 
ylabel(cb,' mean temperature {\circ}C ') 
cmocean thermal

%% Global warming
% Is global warming real?  The <https://www.mathworks.com/matlabcentral/fileexchange/46363 |trend|> function
% lets us easily get the linear trend of temperature from 1950 to 2016. Be sure to multiply the trend by 10*365.25
% to convert from degrees per day to degrees per decade: 

figure
imagescn(lon,lat,10*365.25*trend(sst,t,3))
axis xy off
cb = colorbar; 
ylabel(cb,' temperature trend {\circ}C per decade ') 
cmocean('balance','pivot') 

% Remove the global warming signal
% The global warming trend is interesting, but EOF analysis is all about variablity, not long-term trends, so
% we must remove the trend by <https://www.mathworks.com/matlabcentral/fileexchange/61328-detrend3 |detrend3|>:

sst = detrend3(sst,t); %detrend 3D datasets

%% Remove seasonal cycles 
% If you plot the temperature trend again, you'll see that it's all been reduced to zero, with perhaps a few eps 
% of numerical noise. Now that's an SST dataset that even Anthony Watts would approve of.  
% 
% We have now detrended the SST dataset (which also removed the mean), but it still contains quite a bit of seasonal 
% variability that should be removed before EOF analysis because we're not interested in seasonal signals. A quick way 
% % to remove the seasonal cycle from this monthly dataset is to determine the average SST at each grid cell for any given month. 
% Start by getting the months corresponding to each time step in |t|. We don't need the year or day, so I'll tilde (~) out 
% the |datevec| outputs and only keep the month: 

[~,month,~] = datevec(t); 

% Specifically, that means each time step is associated with one of the 12 months of the year. How many 
% time steps are associated with January? 

sum(month==1)

% There are xx January SST maps in the full dataset, because it's a xx year record. For each month
% of the year, we can compute an average SST map for that month by finding the indices of all the time steps
% associated with that month. Then remove the seasonal signal by subtracting the average of all 67 January 
% SST maps from each January SST map. This is what I mean: 
% Preallocate a 3D matrix of monthly means: 

monthlymeans = nan(length(lat),length(lon),12); 

% Calculate the mean of all maps corresponding to each month, and subtract
% the monthly means from the sst dataset: 
for k = 1:12
   
   % Indices of month k: 
   ind = month==k; 
   
   % Mean SST for month k: 
   monthlymeans(:,:,k) = mean(sst(:,:,ind),3); 
   
   % Subtract the monthly mean: 
%    sst(:,:,ind) = bsxfun(@minus,sst(:,:,ind),monthlymeans(:,:,k));
     sst(:,:,ind) = sst(:,:,ind)-monthlymeans(:,:,k);
end

%% 
% So now our dataset has been detrended, the mean removed, and the seasonal cycle removed. 
% All that's left are the anomalies - things that change, but are not long-term trends
% or short-term annual cycles.  Here's the remaining variance of our anomaly dataset: 

figure
imagescn(lon,lat,var(sst,[],3)); 
axis xy off
colorbar
title('variance of temperature') 
colormap(jet) % jet is inexcusable except for recreating old plots
caxis([0 1])

