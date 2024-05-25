# ADF GLS Test
from arch.unitroot import DFGLS
# Johansen Test
from statsmodels.tsa.vector_ar.vecm import coint_johansen
import pandas as pd

def compute_ADF(C_Spread_dict, Z_Spread_dict, risk_free_dict):
    """
    This function computes the ADF GLS test for the C-Spread, Z-Spread, and Risk-Free Rate.
    """

    # convert the dictionary to a pandas dataframe
    C_Spread = pd.DataFrame.from_dict(C_Spread_dict)
    Z_Spread = pd.DataFrame.from_dict(Z_Spread_dict)
    risk_free = pd.DataFrame.from_dict(risk_free_dict)

    # string to output the results
    output = ''

    # calculate the ADF GLS test
    test = DFGLS(C_Spread['C_Spread'])

    # print the results
    output += '\n --- C-Spread --- \n'
    output += test.summary().as_text()

    # test the first difference
    test_diff = DFGLS(C_Spread['C_Spread'].diff().dropna())

    # print the results
    output += '\n --- First Difference of the C-Spread --- \n'
    output += test_diff.summary().as_text()

    # calculate the ADF GLS test
    test = DFGLS(Z_Spread['Z_Spread'])

    # print the results
    output += '\n --- Z-Spread --- \n'
    output += test.summary().as_text()

    # test the first difference
    test_diff = DFGLS(Z_Spread['Z_Spread'].diff().dropna())

    # print the results
    output += '\n --- First Difference of the Z-Spread --- \n'

    output += test_diff.summary().as_text()

    # calculate the ADF GLS test
    test = DFGLS(risk_free['Risk_Free_Rate'])

    # print the results
    output += '\n --- Risk-Free Rate --- \n'
    output += test.summary().as_text()

    # test the first difference
    test_diff = DFGLS(risk_free['Risk_Free_Rate'].diff().dropna())

    # print the results
    output += '\n --- First Difference of the Risk-Free Rate --- \n'

    output += test_diff.summary().as_text()

    return output
