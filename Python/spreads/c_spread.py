import datetime
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

class C_spread:
    """
    C-spread class
    """

    def __init__(self, Front, Next, Daily, Boostrapper):

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
        print(Front['Date'].dtype)
        plt.xlim([
            Front['Date'].values[0] - np.timedelta64(180, 'D'),
            Front['Date'].values[-1] + np.timedelta64(180, 'D')
        ])
        plt.xlabel('Date')
        plt.ylabel('C-spread')
        plt.legend()
        plt.show()
        
