import datetime
import pandas as pd
from typing import overload

@overload
def yearfrac(first_date:pd.Series, second_date:datetime.datetime, convention:str)->pd.Series:
    pass

@overload
def yearfrac(first_date:datetime.datetime, second_date:pd.Series, convention:str)->pd.Series:
    pass

@overload
def yearfrac(first_date:pd.Series, second_date:pd.Series, convention:str)->pd.Series:
    pass

def yearfrac(first_date:datetime.datetime | pd.Series, second_date:datetime.datetime | pd.Series,
    convention:str)->float:

    """
    Calculate the year fraction between two dates or two series of dates
    """

    if isinstance(first_date, datetime.datetime) and isinstance(second_date, datetime.datetime):
        return __yearfrac(first_date, second_date, convention)

    if isinstance(first_date, pd.Series) and isinstance(second_date, datetime.datetime):

        # create the output series with the same length as the input series
        out = pd.Series(index=first_date.index)

        for i in range(len(first_date)):
            out.iloc[i] = __yearfrac(first_date.iloc[i], second_date, convention)

        return pd.Series(out)

    if isinstance(first_date, datetime.datetime) and isinstance(second_date, pd.Series):
    
        out = pd.Series(index=second_date.index)

        for i in range(len(second_date)):
            out.iloc[i] = __yearfrac(first_date, second_date.iloc[i], convention)

        return pd.Series(out)

    if isinstance(first_date, pd.Series) and isinstance(second_date, pd.Series):

        # check if the two series have the same length
        if len(first_date) != len(second_date):
            raise ValueError('The two series must have the same length')
        
        out = pd.Series(index=range(len(first_date)))

        for i in range(len(first_date)):
            out.iloc[i] = __yearfrac(first_date.iloc[i], second_date.iloc[i], convention)

        return pd.Series(out)

def __yearfrac(first_date:datetime.datetime, second_date:datetime.datetime, convention:str)->float:

    # get the convention
    if convention.upper() == 'EU_30_360':
        return __EU_30_360(first_date, second_date)
    elif convention.upper() == 'ACT_360':
        return __ACT_360(first_date, second_date)
    elif convention.upper() == 'ACT_365':
        return __ACT_365(first_date, second_date)
    else:
        raise ValueError('Invalid convention')


def __EU_30_360(first_date:datetime.datetime, second_date:datetime.datetime)->float:
    """
    Calculate the year fraction with EU_30_360 convention
    """

    # get the years and months
    years = second_date.year - first_date.year
    months = second_date.month - first_date.month

    # get the days
    if first_date.day == 31:
        first_date = first_date.replace(day=30)
    if second_date.day == 31:
        second_date = second_date.replace(day=30)

    days = second_date.day - first_date.day

    # calculate the year fraction
    return years + months / 12 + days / 360

def __ACT_360(first_date:datetime.datetime, second_date:datetime.datetime)->float:
    """
    Calculate the year fraction with ACT_360 convention
    """

    # calculate the year fraction
    return (second_date - first_date).days / 360

def __ACT_365(first_date:datetime.datetime, second_date:datetime.datetime)->float:
    """
    Calculate the year fraction with ACT_365 convention
    """

    # calculate the year fraction
    return (second_date - first_date).days / 365
