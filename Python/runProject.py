# runFinalProject_Group3B
#  Group 3B, AY2023-2024
# 
#
# to run:
# > venv\Scripts\activate
# > python runProject.py

import os
import pandas as pd

# preprocess the data
from Preprocess.preprocess import Preprocess

# initialize the preprocessor and load the data
Preprocess()

print(Preprocess() is Preprocess())
