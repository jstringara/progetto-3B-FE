# runFinalProject_Group3B
#  Group 3B, AY2023-2024
# 
#
# to run:
# > venv\Scripts\activate
# > python runProject.py

import numpy as np
from matplotlib import pyplot as plt

# custom imports
from preprocess import Preprocessor
from plots import Plotter
from bootstrap import Bootstrap
from spreads import C_spread, Z_spread

# initialize the plotter
plotter = Plotter()

# initialize the preprocessor and load the data
preprocessor = Preprocessor()

# Boxplot of the volumes for different months

# get the data
Volumes_march = preprocessor.preprocess_Volumes_front_Month('March')
Volumes_june = preprocessor.preprocess_Volumes_front_Month('June')
Volumes_september = preprocessor.preprocess_Volumes_front_Month('September')

# get the December futures data
Front = preprocessor.preprocess_December()
Next = preprocessor.preprocess_December(years_offset=1)
Next_2 = preprocessor.preprocess_December(years_offset=2)

# get the daily prices
Daily = preprocessor.preprocess_daily_price()

# get the open interest
Open_Interest = preprocessor.preprocess_open_interest()

# Perform the bootstrap
bootstrapper = Bootstrap(preprocessor.preprocess_OIS_rates())

# boxplot of the volumes for the different months
# plotter.boxplot_months(Volumes_march, Volumes_june, Volumes_september, Front)

# boxplot of the volumes for the front, next and next_2 December futures
# plotter.boxplot_december(Front, Next, Next_2)

# instantiate the C-spread object
C_spread = C_spread(Front, Next, Daily, bootstrapper, Open_Interest)

# compute the C-spread
C_spread.compute()

# plot the front and next C-spread
# plotter.plot_front_next(C_spread)

# aggregate the C-spread with the 'constant' rollover rule
C_spread.aggregate('constant')

# plot the aggregated C-spread
# plotter.plot_C_spread(C_spread)

# get the bonds list
bonds = preprocessor.preprocess_bonds()

# instantiate the Z-spread object
z_spread = Z_spread(bonds, bootstrapper)

# compute the Z-spread
z_spreads = z_spread.compute()

# plot the C-spread, along with the Z-spread and the risk-free rate
C = C_spread.c_spread()
Z = z_spread.z_spread()
R = bootstrapper.interpolate(Front['Date'], Front['Expiry'])

# filter to only use the dates up to the end of Phase III
C = C[C['Date'] < PHASE_III_END]
Z = Z[Z['Date'] < PHASE_III_END]
R = R[R['Date'] < PHASE_III_END]

# plot the C-spread, Z-spread and risk-free rate
plt.plot(C['Date'], 100 * C['C-spread'], label='C-spread')
plt.plot(Z['Date'], 100 * Z['Z-spread'], label='Z-spread')
plt.plot(R['Date'], 100 * R['Risk Free Rate'], label='Risk-free rate')

plt.title('C-spread, Z-spread and risk-free rate')
plt.grid()

plt.xlabel('Date')
plt.ylabel('Rate (%)')

plt.legend()

# pad the dates to make the plot more readable
plt.xlim([C['Date'].values[0] - np.timedelta64(180, 'D'), C['Date'].values[-1] + np.timedelta64(180, 'D')])
plt.ylim([-0.5, 3.6])

plt.show()

