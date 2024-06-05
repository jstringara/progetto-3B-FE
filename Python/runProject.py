# runFinalProject_Group3B
#  Group 3B, AY2023-2024
# 
#
# to run:
# > venv\Scripts\activate
# > python runProject.py

import datetime
import numpy as np
from matplotlib import pyplot as plt

# custom imports
from preprocess import Preprocessor
from bootstrap import Bootstrap
from spreads import C_spread

# define variables
PHASE_III_END = datetime.datetime(2021, 1, 1)

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

# boxplot of the volumes for the different months
# Volumes of March, June, September and December for PHASE III in log scale
plt.boxplot(
    [
        np.log10(Volumes_march['Volume'] + 1),
        np.log10(Volumes_june['Volume'] + 1),
        np.log10(Volumes_september['Volume'] + 1),
        np.log10(Front[Front['Date'] < PHASE_III_END]['Volume'] + 1)
    ],
    tick_labels=['March', 'June', 'September', 'December']
)

plt.title('Boxplot of the volumes for different months')
plt.grid()
plt.xlabel('Months')
plt.ylabel('Volume (log scale)')
plt.show()

# Boxplot of the volumes for front, next and next_2 December futures
plt.boxplot(
    [
        np.log10(Front[Front['Date'] < PHASE_III_END]['Volume'] + 1),
        np.log10(Next[Next['Date'] < PHASE_III_END]['Volume'] + 1),
        np.log10(Next_2[Next_2['Date'] < PHASE_III_END]['Volume'] + 1)
    ],
    tick_labels=['Front', 'Next', 'Next_2']
)

plt.title('Boxplot of the volumes for front, next and next_2 December futures')
plt.grid()
plt.xlabel('Futures')
plt.ylabel('Volume (log scale)')
plt.show()

# Perform the bootstrap
bootstrapper = Bootstrap(preprocessor.preprocess_OIS_rates())

# compute the C-spread
C_spread = C_spread(Front, Next, Daily, bootstrapper)

# compute the C-spread
C_spread.compute()

C_spread.plot_front_next()


