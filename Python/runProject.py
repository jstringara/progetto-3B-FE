# runFinalProject_Group3B
#  Group 3B, AY2023-2024
# 
#
# to run:
# > venv\Scripts\activate
# > python runProject.py

import numpy as np
from matplotlib import pyplot as plt
from statsmodels.graphics.tsaplots import plot_acf, plot_pacf

# custom imports
from preprocess import Preprocessor
from plots import Plotter
from bootstrap import Bootstrap
from spreads import C_spread, Z_spread

# initialize the plotter
plotter = Plotter()

# initialize the preprocessor and load the data
preprocessor = Preprocessor()

# load the OIS rates
OIS_rates = preprocessor.preprocess_OIS_rates()

# Get the volumes for the different months
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
bootstrapper = Bootstrap(OIS_rates)

# boxplot of the volumes for the different months
# plotter.boxplot_months(Volumes_march, Volumes_june, Volumes_september, Front)

# boxplot of the volumes for the front, next and next_2 December futures
# plotter.boxplot_december(Front, Next, Next_2)

# instantiate the C-spread object
c_spread = C_spread(Front, Next, Daily, bootstrapper, Open_Interest)

# compute the C-spread
c_spread.compute()

# plot the front and next C-spread
# plotter.plot_front_next(c_spread)

# aggregate the C-spread with the 'constant' rollover rule
c_spread.aggregate('constant')

# plot the aggregated C-spread
# plotter.plot_C_spread(c_spread)

# get the bonds list
bonds = preprocessor.preprocess_bonds()

# instantiate the Z-spread object
z_spread = Z_spread(bonds, bootstrapper)

# compute the Z-spread
z_spreads = z_spread.compute()

# compute the risk free rate
R = bootstrapper.interpolate(Front['Date'], Front['Expiry'])

# plot the C-spread, Z-spread and the Risk Free Rate
# plotter.plot_C_Z_R(c_spread, z_spread, R)

# impose the Risk Free Rate to be the 3-month OIS rate
R = OIS_rates[['Date', 'EUREON3M']]
# rename the columns
R.columns = ['Date', 'Risk Free Rate']

# plot the ACF and PACF of the three spreads
plotter.plot_ACF_PACF(c_spread, z_spread, R)
