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
