# runFinalProject_Group3B
#  Group 3B, AY2023-2024
# 
#
# to run:
# > venv\Scripts\activate
# > python runProject.py

import os
import pandas as pd

data_dir = "Data/"

# load the bootstrap data
OIS_Data = pd.read_csv(os.path.join(data_dir, 'OIS_Data.csv'), parse_dates=['Date'])

