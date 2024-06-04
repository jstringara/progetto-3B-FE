import datetime
from dateutil import relativedelta
from yearfracion import yearfrac
import numpy as np
import pandas as pd

class Bootstrap:
    """
    Bootstrap class to perform bootstrapping on a dataset of OIS rates
    """

    def __init__(self, data):
        """
        Constructor for the Bootstrap class
        :param data: pandas DataFrame containing the OIS rates
        """

        # keep the original data
        self.__OIS_data = data

        # structures to hold the computed values
        self.__dates = None
        self.__yf_30_360 = None
        self.__year_fractions = None
        self.__discount_factors = None
        self.__zero_rates = None

        self.__bootstrap()
    
    def __to_timedelta(self, offset_str:str)->datetime.timedelta:
        """
        Convert a string to a timedelta object
        """

        # get the numeric part of the string
        num_str = ''.join(filter(str.isdigit, offset_str))
        num = int(num_str)

        # get the unit part of the string
        unit = offset_str.replace(num_str, '')

        # convert the unit to a timedelta object
        if unit == 'D':
            return relativedelta.relativedelta(days=num)
        elif unit == 'W':
            return relativedelta.relativedelta(weeks=num)
        elif unit == 'M':
            return relativedelta.relativedelta(months=num)
        elif unit == 'Y':
            return relativedelta.relativedelta(years=num)
        else:
            raise ValueError('Invalid unit in the offset string')

    def dates(self)->pd.DataFrame:
        """
        Compute the dates for the OIS rates
        """

        # check if the dates have already been computed
        if self.__dates is not None:
            return self.__dates

        # offsets list to match the tenors of the OIS rates
        offsets = {
            self.__OIS_data.columns[i]:
                self.__to_timedelta(self.__OIS_data.columns[i].replace('EUREON', ''))
            for i in range(1, len(self.__OIS_data.columns))
        }

        # compute the dates
        dates = pd.DataFrame(columns = self.__OIS_data.columns)
        dates['Date'] = self.__OIS_data['Date']

        # use the offset to calculate the dates
        for i in range(1, len(self.__OIS_data.columns)):
            # sum the offset to the date
            dates[self.__OIS_data.columns[i]] = dates['Date'].apply(
                lambda x: x + offsets[self.__OIS_data.columns[i]])
            # move them to business days
            dates[self.__OIS_data.columns[i]] = dates[self.__OIS_data.columns[i]].apply(
                lambda x: x + pd.tseries.offsets.BDay(0))

        return dates

    def year_fractions(self, convention:str)->pd.DataFrame:
        """
        Compute the year fractions between the dates
        """

        # check that the dates have been computed
        if self.__dates is None:
            self.__dates = self.compute_dates()
        
        # compute the year fractions with the given convention
        d = {
            name: yearfrac(self.__OIS_data['Date'], self.__dates[name], convention).to_list()
            for name in self.__OIS_data.columns[1:]
        }
        d['Date'] = self.__OIS_data['Date'].to_list()


        df = pd.DataFrame(data=d) 
        # reorder the columns
        df = df[self.__OIS_data.columns]

        return df

    def discount_factors(self)->pd.DataFrame:
        """
        Compute the discount factors from the OIS rates
        """

        if self.__discount_factors is not None:
            return self.__discount_factors

        # check that the year fractions have been computed
        if self.__yf_30_360 is None:
            self.__yf_30_360 = self.compute_year_fractions('EU_30_360')

        DF = pd.DataFrame(columns = self.__OIS_data.columns[1:], 
            index = range(len(self.__OIS_data)))

        # for dates less than one year, compute directly
        under_one_year_cols = ['EUREON1W', 'EUREON2W', 'EUREON3W', 'EUREON1M', 'EUREON2M',
            'EUREON3M', 'EUREON4M', 'EUREON5M', 'EUREON6M', 'EUREON7M', 'EUREON8M', 'EUREON9M',
            'EUREON10M', 'EUREON11M', 'EUREON1Y']
        DF[under_one_year_cols] = 1 / (1 + self.__OIS_data[under_one_year_cols].values *
            self.__yf_30_360[under_one_year_cols].values)

        delta_3m = self.__yf_30_360['EUREON15M'].values - self.__yf_30_360['EUREON3M'].values
        delta_6m = self.__yf_30_360['EUREON18M'].values - self.__yf_30_360['EUREON6M'].values
        delta_9m = self.__yf_30_360['EUREON21M'].values - self.__yf_30_360['EUREON9M'].values

        # for dates between one year and two years, compute using the formula
        DF['EUREON15M'] = (1 - self.__OIS_data['EUREON15M'].values * self.__yf_30_360['EUREON3M'].values * \
            DF['EUREON3M'].values) / (1 + self.__OIS_data['EUREON15M'].values * delta_3m)
        DF['EUREON18M']= (1 - self.__OIS_data['EUREON18M'].values * self.__yf_30_360['EUREON6M'].values * \
            DF['EUREON6M'].values) / (1 + self.__OIS_data['EUREON18M'].values * delta_6m)
        DF['EUREON21M'] = (1 - self.__OIS_data['EUREON21M'].values * self.__yf_30_360['EUREON9M'].values * \
            DF['EUREON9M'].values) / (1 + self.__OIS_data['EUREON21M'].values * delta_9m)

        # for yearly dates, compute using the formula
        yearly = ['EUREON2Y', 'EUREON3Y', 'EUREON4Y', 'EUREON5Y', 'EUREON6Y', 'EUREON7Y',
            'EUREON8Y', 'EUREON9Y', 'EUREON10Y']
        # compute the year fractions between the yearly dates
        yearly_delta = self.__yf_30_360[['EUREON1Y', *yearly]].diff(axis=1)
        yearly_delta = yearly_delta.drop(columns='EUREON1Y')

        s = yearly_delta['EUREON2Y'].values * DF['EUREON1Y'].values

        for i, tenor in enumerate(yearly):
            # get the rate
            R = self.__OIS_data[tenor].values 
            DF[tenor] = (1 - R * s) / (1 + R * yearly_delta[tenor].values)
            # update the sum
            s += yearly_delta[tenor].values * DF[tenor].values

        DF['Date'] = self.__OIS_data['Date'].values

        # reorder the columns
        DF = DF[self.__OIS_data.columns]

        return DF

    def zero_rates(self)->pd.DataFrame:
        """
        Compute the zero rates from the discount factors
        """

        if self.__zero_rates is not None:
            return self.__zero_rates

        # check that the discount factors have been computed
        if self.__discount_factors is None:
            self.__discount_factors = self.discount_factors()
        
        # compute the zero rates
        zero_rates = pd.DataFrame(columns = self.__OIS_data.columns)
        zero_rates['Date'] = self.__OIS_data['Date']
        zero_rates[self.__OIS_data.columns[1:]] = - np.log(self.__discount_factors[
            self.__OIS_data.columns[1:]].values) / \
            self.__year_fractions[self.__OIS_data.columns[1:]].values

        return zero_rates

    def __bootstrap(self)->None:
        """
        Perform the bootstrapping of the zero rates
        """

        # compute the dates
        self.__dates = self.dates()

        # compute the year fractions with EU_30_360 convention
        self.__yf_30_360 = self.year_fractions('EU_30_360')

        # compute the Discount Factors
        self.__discount_factors = self.discount_factors()

        # save the year fractions
        self.__year_fractions = self.year_fractions('ACT_365')

        # compute the zero rates
        self.__zero_rates = self.zero_rates()

