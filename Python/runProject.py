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
from statsmodels.regression.linear_model import OLS
# quantile regression
from statsmodels.regression.quantile_regression import QuantReg

# custom imports
from preprocess import Preprocessor
from plots import Plotter
from bootstrap import Bootstrap
from spreads import C_spread, Z_spread

PHASE_III_END = datetime.datetime(2021, 1, 1)
PHASE_IV_END = datetime.datetime(2022, 10, 28)

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

# perform the ADF GLS test on the Risk-Free Rate differences
test_R_diff = DFGLS(R[R['Date'] < PHASE_III_END]['Risk Free Rate'].diff().dropna())
print('\n --- First Difference of the Risk-Free Rate --- \n')
print(test_R_diff.summary())

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

    df = pd.DataFrame(data = {
        'Test': ['q <= 0', 'q <= 1', 'q <= 2'],
        'Trace Statistic': result.lr1,
        'Eigenvalue Statistic': result.lr2,
        'Trace Stat 99%': result.cvt[:, 0],
        'Trace Stat 95%': result.cvt[:, 1],
        'Trace Stat 90%': result.cvt[:, 2],
        'Eig Stat 99%': result.cvm[:, 0],
        'Eig Stat 95%': result.cvm[:, 1],
        'Eig Stat 90%': result.cvm[:, 2]
    })

    print(df.round(2))

    return result

# perform the johansen test
johansen_result = johansen_test(Y.values, -1)

# get the eigenvector corresponding to the largest eigenvalue
cointegration_coefficients = johansen_result.evec[:, 0] / johansen_result.evec[0, 0]

# print the cointegration coefficients
print('\n --- Cointegration Coefficients --- \n')
print(cointegration_coefficients.round(2))

# build the ECT
ect = Y['C-spread'] + cointegration_coefficients[1] * Y['Z-spread'] + cointegration_coefficients[2] * Y['Risk Free Rate']

# build a GARCH(1, 1) model for the variance of the daily price
log_returns = pd.DataFrame({
    'Date': Daily['Date'].values,
    'Log Returns': np.log(Daily['Price']).diff().values
})

# fit the GARCH(1, 1) model
model = arch_model(log_returns['Log Returns'].dropna().values * 10, vol='Garch', p=1, q=1)
fit = model.fit(disp='off')

# print the summary
print('\n --- GARCH(1, 1) Model --- \n')
print(fit.summary())

# create the volatility dataframe
volatility = pd.DataFrame({
    'Date': Daily['Date'].values,
    'Volatility': [np.nan] + fit.conditional_volatility.tolist()
})

# plotter.plot_garch(log_returns['Log Returns'].values, fit)

# build the dataframe for the regression
regression_df = pd.DataFrame({
    'Date': Daily[Daily['Date'] < PHASE_III_END]['Date'].values,
    'Diff C-spread': C[C['Date'] < PHASE_III_END]['C-spread'].diff().values,
    'Diff C-spread Lag 1': C[C['Date'] < PHASE_III_END]['C-spread'].diff().shift(1).values,
    'Diff C-spread Lag 2': C[C['Date'] < PHASE_III_END]['C-spread'].diff().shift(2).values,
    'Diff C-spread Lag 3': C[C['Date'] < PHASE_III_END]['C-spread'].diff().shift(3).values,
    'Diff Z-spread': Z[Z['Date'] < PHASE_III_END]['Z-spread'].diff().values,
    'Diff Risk Free Rate': R[R['Date'] < PHASE_III_END]['Risk Free Rate'].diff().values,
    'ECT Lag 1': ect.shift(1).values,
    'WTI': Extra[Extra['Date'] < PHASE_III_END]['WTI'].values,
    'SPX': Extra[Extra['Date'] < PHASE_III_END]['SPX'].values,
    'VIX': Extra[Extra['Date'] < PHASE_III_END]['VIX'].values,
    'Volatility': volatility[volatility['Date'] < PHASE_III_END]['Volatility'].values,
    '(Intercept)': 1
})
regression_df = regression_df.dropna()

def run_linear_regression(table, regressors_list, dependent_variable, model_name):
    """
    Runs a linear regression on the given table with the given regressors and dependent variable.
    
    Parameters:
    table (pandas.DataFrame): The table containing the data.
    regressors_list (list): The list of regressors to include in the regression.
    dependent_variable (str): The name of the dependent variable.
    """
    X = table[regressors_list]
    Y = table[dependent_variable]

    # fit the linear regression
    model = OLS(Y, X).fit()

    # print the summary
    print(f'\n --- Linear Regression Model {model_name} --- \n')
    print(model.summary())

    return model

# Model VI

# fit the linear regression
model_VI_regressors = ['Diff C-spread Lag 1', 'Diff C-spread Lag 2', 'Diff C-spread Lag 3',
    'Diff Z-spread', 'Diff Risk Free Rate', 'ECT Lag 1', 'WTI', 'SPX', 'VIX',
    'Volatility', '(Intercept)']

model_VI = run_linear_regression(regression_df, model_VI_regressors, 'Diff C-spread', 'VI')

# model I

model_I_regressors = ['Diff C-spread Lag 1', 'Diff C-spread Lag 2', 'Diff C-spread Lag 3',
    'ECT Lag 1', '(Intercept)']

model_I = run_linear_regression(regression_df, model_I_regressors, 'Diff C-spread', 'I')

# model II

model_II_regressors = ['Diff C-spread Lag 1', 'Diff C-spread Lag 2', 'Diff C-spread Lag 3',
    'Diff Z-spread', 'Diff Risk Free Rate', 'ECT Lag 1', '(Intercept)']

model_II = run_linear_regression(regression_df, model_II_regressors, 'Diff C-spread', 'II')

# model III

model_III_regressors = ['WTI', '(Intercept)']

model_III = run_linear_regression(regression_df, model_III_regressors, 'Diff C-spread', 'III')

# model IV

model_IV_regressors = ['Diff C-spread Lag 1', 'Diff C-spread Lag 2', 'Diff C-spread Lag 3',
    'Diff Z-spread', 'Diff Risk Free Rate', 'ECT Lag 1', 'WTI', '(Intercept)']

model_IV = run_linear_regression(regression_df, model_IV_regressors, 'Diff C-spread', 'IV')

# model V
model_V_regressors = ['WTI', 'SPX', 'VIX', 'Volatility', '(Intercept)']

model_V = run_linear_regression(regression_df, model_V_regressors, 'Diff C-spread', 'V')

# build a table to summarize the 6 regressions
def generate_summary(model: OLS, regressors: list)-> list[str]:
    """
    Generates a summary of the model.
    """

    # iterate over the regressors
    out = []
    for regressor in regressors:
        # check if it exists in the model
        coeff = model.params.get(regressor, None)
        pvalue = model.pvalues.get(regressor, None)

        if coeff is None:
            out.append(" " * 6)
            continue
        
        s = f"{coeff:.2f} {'*' * sum([pvalue < level for level in [0.1, 0.05, 0.01]])}"

        # pad the string to be 6 characters
        out.append(f"{s:^6}")

    return out

summary_table = pd.DataFrame({
    'Variable': model_VI_regressors,
    'Model I': generate_summary(model_I, model_VI_regressors),
    'Model II': generate_summary(model_II, model_VI_regressors),
    'Model III': generate_summary(model_III, model_VI_regressors),
    'Model IV': generate_summary(model_IV, model_VI_regressors),
    'Model V': generate_summary(model_V, model_VI_regressors),
    'Model VI': generate_summary(model_VI, model_VI_regressors)
})

print('\n --- Summary Table --- \n')
print(summary_table)

# Robustness Check

# introduce the EWMA volatility
ewma_volatility = np.zeros(len(log_returns))
ewma_volatility[0] = log_returns['Log Returns'].std() ** 2
_lambda = 0.95

for i in range(1, len(log_returns)):
    ewma_volatility[i] = (
        _lambda * ewma_volatility[i - 1] +
        (1 - _lambda) * log_returns['Log Returns'].iloc[i] ** 2
    )

ewma_volatility = pd.DataFrame(
    data = {
        'Date': log_returns['Date'].values,
        'EWMA Volatility': [np.sqrt(vol) for vol in ewma_volatility]
    }
)

# plotter.plot_ewma(log_returns['Log Returns'].values, ewma_volatility['EWMA Volatility'].values)

# copy the regression dataframe
regression_ewma = regression_df.copy()
# swap out the volatility
regression_ewma['Volatility'] = ewma_volatility[
    ewma_volatility['Date'].isin(regression_ewma['Date'])
]['EWMA Volatility'].values

# fit the linear regression
model_ewma = run_linear_regression(regression_df, model_VI_regressors, 'Diff C-spread', 'EWMA')

# PHASE IV model

regression_phase_IV = pd.DataFrame(data = {
    'Date': Daily[Daily['Date'] < PHASE_IV_END]['Date'].values,
    'Diff C-spread': C[C['Date'] < PHASE_IV_END]['C-spread'].diff().values,
    'Diff C-spread Lag 1': C[C['Date'] < PHASE_IV_END]['C-spread'].diff().shift(1).values,
    'Diff C-spread Lag 2': C[C['Date'] < PHASE_IV_END]['C-spread'].diff().shift(2).values,
    'Diff C-spread Lag 3': C[C['Date'] < PHASE_IV_END]['C-spread'].diff().shift(3).values,
    'Diff Z-spread': Z[Z['Date'] < PHASE_IV_END]['Z-spread'].diff().values,
    'Diff Risk Free Rate': R[R['Date'] < PHASE_IV_END]['Risk Free Rate'].diff().values,
    'ECT Lag 1': ect.shift(1).values,
    'WTI': Extra[Extra['Date'] < PHASE_IV_END]['WTI'].values,
    'SPX': Extra[Extra['Date'] < PHASE_IV_END]['SPX'].values,
    'VIX': Extra[Extra['Date'] < PHASE_IV_END]['VIX'].values,
    'Volatility': volatility[volatility['Date'] < PHASE_IV_END]['Volatility'].values,
    '(Intercept)': 1
})
regression_phase_IV = regression_phase_IV.dropna()

# fit the linear regression
model_phase_IV = run_linear_regression(regression_phase_IV, model_IV_regressors, 'Diff C-spread', 'IV Phase IV')

# Quantile Regression

# fit the quantile regression
X = regression_df[model_VI_regressors]
Y = regression_df['Diff C-spread']
qr = {
    q: QuantReg(Y, X).fit(q=q)
    for q in [0.1, 0.2, 0.3, 0.4, 0.6, 0.7, 0.8, 0.9]
}

# print the summary
print('\n --- Quantile Regression Model --- \n')
for q in qr:
    print(f'Quantile {q}')
    print(qr[q].summary())
    print('\n')
