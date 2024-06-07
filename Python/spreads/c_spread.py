import datetime
from dateutil.relativedelta import relativedelta
import numpy as np
import pandas as pd

class C_spread:
    """
    C-spread class
    """

    def __init__(self, Front, Next, Daily, Boostrapper, Open_Interest):

        # check that the dimensions agree
        if len(Front) != len(Next) or len(Front) != len(Daily):
            raise ValueError('The dimensions of the Front, Next and Daily dataframes do not agree')

        # Front and Next futures
        self.__Front = Front
        self.__Next = Next
        # daily price
        self.__Daily = Daily
        # Boostrapper object
        self.__Bootstrapper = Boostrapper
        # Open Interest
        self.__Open_Interest = Open_Interest

        # initialize the C-spread for the front and next futures
        self.__C_spread_front = None
        self.__C_spread_next = None
        self.__C_spread = None

    def c_spread_front(self):
        """
        Return the C-spread for the front futures
        """
        return self.__C_spread_front

    def c_spread_next(self):
        """
        Return the C-spread for the next futures
        """
        return self.__C_spread_next
    
    def c_spread(self):
        """
        Return the aggregated C-spread
        """
        return self.__C_spread

    def compute(self):

        # interpolate the zero rates on the Front dates
        front_rate = self.__Bootstrapper.interpolate(self.__Front['Date'], self.__Front['Expiry'])
        next_rate = self.__Bootstrapper.interpolate(self.__Front['Date'], self.__Next['Expiry'])

        # compute the C-spread for the front and next futures
        C_spread_front = np.log(self.__Front['Price'].values / self.__Daily['Price'].values) / \
            front_rate['Year Fraction'].values - front_rate['Risk Free Rate'].values
        C_spread_next = np.log(self.__Next['Price'].values / self.__Daily['Price'].values) / \
            next_rate['Year Fraction'].values - next_rate['Risk Free Rate'].values

        # save the results in a dataframe
        self.__C_spread_front = pd.DataFrame({
            'Date': self.__Front['Date'].values,
            'C-spread': C_spread_front
        })
        self.__C_spread_next = pd.DataFrame({
            'Date': self.__Next['Date'].values,
            'C-spread': C_spread_next
        })

    def aggregate(self, rollover_rule):
        """
        Aggregate the C-spread for the front and next futures given a rollover rule
        Possible rollover rules are:
        - 'constant': switch every year on the 15th of November
        - 'open interest': switch when the open interest of the next future is higher than the front future
        - 'month': switch exactly one month before the expiry of the front future
        - 'week': switch exactly one week before the expiry of the front future
        """

        # check that the rollover rule is valid
        if rollover_rule not in ['constant', 'open interest', 'month', 'week']:
            raise ValueError('Invalid rollover rule')

        # check that the two c-spread have been computed
        if self.__C_spread_front is None or self.__C_spread_next is None:
            self.compute()

        # add the expiry column to the c-spread dataframes
        self.__C_spread_front['Expiry'] = self.__Front['Expiry'].values
        self.__C_spread_next['Expiry'] = self.__Next['Expiry'].values

        # initialize the aggregated C-spread
        C_spread = pd.DataFrame()

        # get the expiry dates
        expiry_dates = self.__C_spread_front['Expiry'].unique()

        # iterate over the expiry dates
        for expiry in expiry_dates:
            # get the data for the current expiry
            Front = self.__C_spread_front[self.__C_spread_front['Expiry'] == expiry]
            Next = self.__C_spread_next[self.__C_spread_next['Date'].isin(Front['Date'].values)]

            # switch the front and next futures according to the rollover rule
            if rollover_rule == 'constant':
                # get the front up to the 15th of November
                C_spread = pd.concat([
                    C_spread,
                    Front[Front['Date'] < datetime.datetime(expiry.year, 11, 15)],
                    Next[Next['Date'] >= datetime.datetime(expiry.year, 11, 15)]
                ])
            elif rollover_rule == 'open interest':
                # get the open interest for the period
                Open_Interest = self.__Open_Interest[
                    self.__Open_Interest['Date'].isin(Front['Date'].values)
                ]
                df = Open_Interest[Open_Interest['Next'] > Open_Interest['Front']]

                # get the switch date
                if df.empty: # no date is found, just use the Front
                    C_spread = pd.concat([C_spread, Front])
                else:
                    switch_date = df['Date'].values[0]
                    C_spread = pd.concat([
                        C_spread,
                        Front[Front['Date'] < switch_date],
                        Next[Next['Date'] >= switch_date]
                    ])
            elif rollover_rule == 'month':
                # get the front up to one month before the expiry
                C_spread = pd.concat([
                    C_spread,
                    Front[Front['Date'] < expiry - relativedelta(months=1)],
                    Next[Next['Date'] >= expiry - relativedelta(months=1)]
                ])
            elif rollover_rule == 'week':
                # get the front up to one week before the expiry
                C_spread = pd.concat([
                    C_spread,
                    Front[Front['Date'] < expiry - np.timedelta64(7, 'D')],
                    Next[Next['Date'] >= expiry - np.timedelta64(7, 'D')]
                ])
        
        # save the results
        self.__C_spread = C_spread

        self.__C_spread.to_csv('C-spread.csv', index=False)
    
    def save_aggregated(self, method='constant'):
        """
        Save the aggregated C-spread
        """
        self.__C_spread.to_csv(f'C-spread_{method}.csv', index=False)
        