# runFinalProject_Group3B
#  Group 3B, AY2023-2024
# 
#
# to run:
# > venv\Scripts\activate
# > python runProject.py

import numpy as np
import pandas as pd
import datetime
from matplotlib import pyplot as plt
from arch import arch_model
from arch.unitroot import DFGLS
from statsmodels.tsa.vector_ar.vecm import coint_johansen, VECM
from statsmodels.graphics.tsaplots import plot_acf, plot_pacf

# custom imports
from preprocess import Preprocessor
from plots import Plotter
from bootstrap import Bootstrap
from spreads import C_spread, Z_spread

PHASE_III_END = datetime.datetime(2021, 1, 1)

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

# get the extra variables
Extra = preprocessor.preprocess_extra_variables()

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

C = c_spread.c_spread()

# plot the aggregated C-spread
# plotter.plot_C_spread(c_spread)

# get the bonds list
bonds = preprocessor.preprocess_bonds()

# instantiate the Z-spread object
z_spread = Z_spread(bonds, bootstrapper)

z_spread.compute()

Z = z_spread.z_spread()

# compute the risk free rate
R = bootstrapper.interpolate(Front['Date'], Front['Expiry'])

# plot the C-spread, Z-spread and the Risk Free Rate
# plotter.plot_C_Z_R(c_spread, z_spread, R)

# impose the Risk Free Rate to be the 3-month OIS rate
R = pd.DataFrame()
R['Date'] = Front['Date'].values
R = pd.merge(R, OIS_rates[['Date', 'EUREON3M']], on='Date', how='left')
R = R.ffill()
# rename the columns
R.columns = ['Date', 'Risk Free Rate']

# plot the ACF and PACF of the three spreads
# plotter.plot_ACF_PACF(c_spread, z_spread, R)

# perform the ADF GLS test on the C-spread
test_C = DFGLS(C[C['Date'] < PHASE_III_END]['C-spread'])
print('\n --- C-Spread --- \n')
print(test_C.summary())

# perform the ADF GLS test on the C-spread differences
test_C_diff = DFGLS(C[C['Date'] < PHASE_III_END]['C-spread'].diff().dropna())
print('\n --- First Difference of the C-Spread --- \n')
print(test_C_diff.summary())

# perform the ADF GLS test on the Z-spread
test_Z = DFGLS(Z[Z['Date'] < PHASE_III_END]['Z-spread'])
print('\n --- Z-Spread --- \n')
print(test_Z.summary())

# perform the ADF GLS test on the Z-spread differences
test_Z_diff = DFGLS(Z[Z['Date'] < PHASE_III_END]['Z-spread'].diff().dropna())
print('\n --- First Difference of the Z-Spread --- \n')
print(test_Z_diff.summary())

# perform the ADF GLS test on the Risk-Free Rate
test_R = DFGLS(R[R['Date'] < PHASE_III_END]['Risk Free Rate'])
print('\n --- Risk-Free Rate --- \n')
print(test_R.summary())

# perform the johansen test on the C-spread, Z-spread and Risk-Free Rate
Y = pd.DataFrame({
    'C-spread': C[C['Date'] < PHASE_III_END]['C-spread'].values,
    'Z-spread': Z[Z['Date'] < PHASE_III_END]['Z-spread'].values,
    'Risk Free Rate': R[R['Date'] < PHASE_III_END]['Risk Free Rate'].values
})

def johansen_test(data, det_order, k_ar_diff=1):
    """
    Performs the Johansen cointegration test and prints the results.
    
    Parameters:
    data (numpy.ndarray): The time series data for the cointegration test.
    det_order (int): The order of the deterministic terms.
                     -1: No constant or trend.
                      0: Constant term only.
                      1: Constant and trend terms.
    k_ar_diff (int): The number of lags to include in the VAR model.
    """
    result = coint_johansen(data, det_order, k_ar_diff)
    
    # print the matrix
    print('\n --- Johansen Cointegration Test --- \n')
    for i, row in enumerate(zip(result.lr1, result.lr2)):
        print(f'q <= {i}: {row[0]:.2f} {row[1]:.2f}')

    return result

# perform the johansen test
johansen_result = johansen_test(Y, det_order=-1)

# build a GARCH(1, 1) model for the variance of the daily price
log_returns = np.log(Daily['Price']/Daily['Price'].shift(1)).dropna()

# fit the GARCH(1, 1) model
model = arch_model(log_returns, vol='Garch', p=1, q=1)
fit = model.fit()

# print the summary
print('\n --- GARCH(1, 1) Model --- \n')
print(fit.summary())

plotter.plot_garch(log_returns, fit)

# build the VECM model
endog = pd.DataFrame({
    'C-spread': C[C['Date'] < PHASE_III_END]['C-spread'].values,
    'Z-spread': Z[Z['Date'] < PHASE_III_END]['Z-spread'].values,
    'Risk Free Rate': R[R['Date'] < PHASE_III_END]['Risk Free Rate'].values
})

