import os
import sys
import datetime
from dateutil import relativedelta
import numpy as np
import pandas as pd

# custom import (add parent directory to the path)
if __name__ == '__main__':
    current_dir = os.path.dirname(os.path.abspath(__file__))
    parent_dir = os.path.dirname(current_dir)
    sys.path.insert(0, parent_dir)

from yearfracion import yearfrac

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
        self.__yf_365 = None
        self.__discount_factors = None
        self.__zero_rates = None

        t0 = datetime.datetime.now()
        self.__bootstrap()
        t1 = datetime.datetime.now()
        print(f'Time taken to bootstrap the data: {(t1 - t0).total_seconds()} s')
    
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
        # cast all the columns to float
        df[self.__OIS_data.columns[1:]] = df[self.__OIS_data.columns[1:]].astype(float)

        return df

    def discount_factors(self)->pd.DataFrame:
        """
        Compute the discount factors from the OIS rates
        """

        if self.__discount_factors is not None:
            return self.__discount_factors

        # check that the year fractions have been computed
        if self.__yf_30_360 is None:
            self.__yf_30_360 = self.year_fractions('EU_30_360')

        DF = pd.DataFrame()

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

        # reorder the columns and cast them to float
        DF = DF[self.__OIS_data.columns]
        DF[self.__OIS_data.columns[1:]] = DF[self.__OIS_data.columns[1:]].astype(float)

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

        # check that the year fractions have been computed
        if self.__yf_365 is None:
            self.__yf_365 = self.year_fractions('ACT_365')
        
        # compute the zero rates
        zero_rates = pd.DataFrame()
        zero_rates['Date'] = self.__OIS_data['Date'].values
        zero_rates[self.__OIS_data.columns[1:]] = - np.log(self.__discount_factors[
            self.__OIS_data.columns[1:]].values) / \
            self.__yf_365[self.__OIS_data.columns[1:]].values

        # reorder the columns and cast them to float
        zero_rates = zero_rates[self.__OIS_data.columns]
        zero_rates[self.__OIS_data.columns[1:]] = zero_rates[self.__OIS_data.columns[1:]].astype(float)

        return zero_rates

    def __bootstrap(self)->None:
        """
        Perform the bootstrapping of the zero rates
        """

        # compute the dates
        t0 = datetime.datetime.now()
        self.__dates = self.dates()
        t1 = datetime.datetime.now()
        print(f'Time taken to compute the dates: {(t1 - t0).total_seconds()} s')

        # compute the year fractions with EU_30_360 convention
        t0 = datetime.datetime.now()
        self.__yf_30_360 = self.year_fractions('EU_30_360')
        t1 = datetime.datetime.now()
        print(f'Time taken to compute the year fractions: {(t1 - t0).total_seconds()} s')

        # compute the Discount Factors
        t0 = datetime.datetime.now()
        self.__discount_factors = self.discount_factors()
        t1 = datetime.datetime.now()
        print(f'Time taken to compute the discount factors: {(t1 - t0).total_seconds()} s')

        # save the year fractions
        t0 = datetime.datetime.now()
        self.__year_fractions = self.year_fractions('ACT_365')
        t1 = datetime.datetime.now()
        print(f'Time taken to compute the year fractions: {(t1 - t0).total_seconds()} s')

        # compute the zero rates
        t0 = datetime.datetime.now()
        self.__zero_rates = self.zero_rates()
        t1 = datetime.datetime.now()
        print(f'Time taken to compute the zero rates: {(t1 - t0).total_seconds()} s')

    def __pad_zero_rates(self, target_dates:pd.Series)->pd.DataFrame:
        """
        Pad the zero rates to match the dates
        """

        # check that the zero rates have been computed
        if self.__zero_rates is None:
            self.__zero_rates = self.zero_rates()

        # pad the zero rates
        zero_rates = pd.DataFrame()
        zero_rates['Date'] = target_dates.values

        # fill the zero rates we have
        zero_rates = pd.merge(zero_rates, self.__zero_rates, on='Date', how='left')
        
        # fill the zero rates we don't have
        zero_rates = zero_rates.ffill()

        return zero_rates

    def __pad_yf(self, target_dates:pd.Series)->pd.DataFrame:
        """
        Pad the year fractions to match the dates
        """

        # check that the year fractions have been computed
        if self.__yf_365 is None:
            self.__yf_365 = self.year_fractions('ACT_365')

        # pad the year fractions
        yf = pd.DataFrame()
        yf['Date'] = target_dates.values

        # fill the year fractions we have
        yf = pd.merge(yf, self.__yf_365, on='Date', how='left')

        # fill the year fractions we don't have
        yf = yf.ffill()

        return yf

    def __pad_dates(self, target_dates:pd.Series)->pd.DataFrame:
        """
        Pad the dates to match the zero rates
        """

        # check that the dates have been computed
        if self.__dates is None:
            self.__dates = self.dates()

        # pad the dates
        dates = pd.DataFrame()
        dates['Date'] = target_dates.values

        # fill the dates we have
        dates = pd.merge(dates, self.__dates, on='Date', how='left')

        # fill the dates we don't have taking the same offset as the last date
        for i, row in dates[dates.isnull().any(axis=1)].iterrows():
            # get the previous date
            prev_date = dates.loc[i - 1, 'Date']
            # compute the offset
            offset = row['Date'] - prev_date
            # move all the previous dates by the offset
            dates.iloc[i, 1:] = dates.iloc[i - 1, 1:].apply(lambda x: x + offset)

        return dates

    def interpolate(self, target_dates:pd.Series, target_expiries:pd.Series)->pd.DataFrame:
        """
        Interpolate the zero rates to match the dates and expiries
        - target_dates: pandas Series with the target dates
        - target_expiries: pandas Series with the target expiries
        """

        # check that target_dates and target_expiries have the same length
        if len(target_dates) != len(target_expiries):
            raise ValueError('target_dates and target_expiries must have the same length')

        # pad the data to match the dates
        dates = self.__pad_dates(target_dates)
        yf = self.__pad_yf(target_dates)
        zero_rates = self.__pad_zero_rates(target_dates)

        # interpolate the zero rates by row to match the expiries
        interpolated = pd.DataFrame()
        interpolated['Date'] = target_dates.values
        interpolated['Risk Free Rate'] = np.nan
        interpolated['Year Fraction'] = np.nan

        for i, row in zero_rates.iterrows():
            # get the expiry
            yf_expiry = yearfrac(row['Date'], target_expiries.iloc[i], 'ACT_365')
            # get the corresponding data points as numpy arrays of floats
            xp = yf.iloc[i].values[1:].astype(float)
            fp = row.values[1:].astype(float)
            # interpolate the zero rates
            interpolated.loc[i, 'Risk Free Rate'] = np.interp(
                yf_expiry, xp, fp)
            # save the year fraction
            interpolated.loc[i, 'Year Fraction'] = yf_expiry
        
        return interpolated

# Testing
if __name__ == '__main__':

    from preprocess import Preprocessor

    # initialize the preprocessor and load the data
    preprocessor = Preprocessor()

    # Perform the bootstrap
    bootstrapper = Bootstrap(preprocessor.preprocess_OIS_rates())

    # December futures
    Front = preprocessor.preprocess_December()
    Next = preprocessor.preprocess_December(years_offset=1)

    # interpolate the zero rates on the Front dates
    rate_front = bootstrapper.interpolate(Front['Date'], Front['Expiry'])
    rate_next = bootstrapper.interpolate(Next['Date'], Next['Expiry'])

    # save the interpolated rates inside of this directory
    cur_dir = os.path.dirname(os.path.realpath(__file__))
    rate_front.to_csv(os.path.join(cur_dir, 'rate_front.csv'), index=False)
    rate_next.to_csv(os.path.join(cur_dir, 'rate_next.csv'), index=False)

    print('Bootstraping done!')
