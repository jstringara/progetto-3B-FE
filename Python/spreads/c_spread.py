import datetime
from dateutil.relativedelta import relativedelta
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

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
                if df.empty:
                    switch_date = Front['Date'].values[-1]
                else:
                    switch_date = df['Date'].values[0]
                # get the front up to the date when the open interest of the next future is higher
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

    def plot_front_next(self, last_date=datetime.datetime(2021, 12, 31)):

        # filter the data
        Front = self.__C_spread_front[self.__C_spread_front['Date'] < last_date]
        Next = self.__C_spread_next[self.__C_spread_next['Date'] < last_date]

        # plot the C-spread for the front and next futures
        plt.plot(Front['Date'], 100 * Front['C-spread'], label='Front')
        plt.plot(Next['Date'], 100 * Next['C-spread'], label='Next')
        plt.title('C-spread for the front and next futures')
        plt.grid()
        # set the y-axis limits
        plt.ylim([-1, 5])
        # limit the dates to the ones plotted and add 6 months of padding to both sides
        plt.xlim([
            Front['Date'].values[0] - np.timedelta64(180, 'D'),
            Front['Date'].values[-1] + np.timedelta64(180, 'D')
        ])
        plt.xlabel('Date')
        plt.ylabel('C-spread')
        plt.legend()
        plt.show()
    
    def plot_aggregated(self, last_date=datetime.datetime(2021, 12, 31)):
        """
        Plot the aggregated C-spread
        """

        # filter the data
        C_spread = self.__C_spread[self.__C_spread['Date'] < last_date]

        # plot the aggregated C-spread
        plt.plot(C_spread['Date'], 100 * C_spread['C-spread'])
        plt.title('Aggregated C-spread')
        plt.grid()
        # set the y-axis limits
        plt.ylim([-0.6, 3.6])
        # limit the dates to the ones plotted and add 6 months of padding to both sides
        plt.xlim([
            C_spread['Date'].values[0] - np.timedelta64(180, 'D'),
            C_spread['Date'].values[-1] + np.timedelta64(180, 'D')
        ])
        plt.xlabel('Date')
        plt.ylabel('C-spread')
        plt.show()
    
    def save_aggregated(self, method='constant'):
        """
        Save the aggregated C-spread
        """
        self.__C_spread.to_csv(f'C-spread_{method}.csv', index=False)
        