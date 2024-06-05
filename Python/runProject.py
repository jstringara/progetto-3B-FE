# runFinalProject_Group3B
#  Group 3B, AY2023-2024
# 
#
# to run:
# > venv\Scripts\activate
# > python runProject.py

from preprocess import Preprocessor
from bootstrap import Bootstrap

# initialize the preprocessor and load the data
preprocessor = Preprocessor()

# Perform the bootstrap
bootstrapper = Bootstrap(preprocessor.preprocess_OIS_rates())

# get the Front
Front = preprocessor.preprocess_December()

# interpolate the zero rates on the Front dates
risk_free_rate = bootstrapper.interpolate(Front['Date'], Front['Expiry'])

print(risk_free_rate)
