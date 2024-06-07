import datetime
import numpy as np
import pandas as pd
from spreads import C_spread, Z_spread
import matplotlib.pyplot as plt

class Plotter:
    """
    Wrapper class for plotting functions
    """

    def __init__(self):
        self.__PHASE_III_END = datetime.datetime(2021, 1, 1)

    def boxplot_months(self, March:pd.DataFrame, June:pd.DataFrame, September:pd.DataFrame,
        December:pd.DataFrame, end_date:datetime.datetime = None, save:bool=True)->None:
        """
        Plot the boxplot of the volumes for different months up to the end date.
        If the end date is not provided, use the end of Phase III.
        If save is True, save the plot as a .png file.
        """

        # if the end date is not provided, use the end of Phase III
        if end_date is None:
            end_date = self.__PHASE_III_END

        # boxplot of the volumes for the different months
        # Volumes of March, June, September and December for PHASE III in log scale
        plt.boxplot(
            [
                np.log10(March['Volume'] + 1),
                np.log10(June['Volume'] + 1),
                np.log10(September['Volume'] + 1),
                np.log10(December[December['Date'] < end_date]['Volume'] + 1)
            ],
            tick_labels=['March', 'June', 'September', 'December']
        )

        plt.title('Boxplot of the volumes for different months')
        plt.grid()
        plt.xlabel('Months')
        plt.ylabel('Volume (log scale)')
        plt.show()

        # save the plot as a .png file
        if save:
            plt.savefig('boxplot_months.png')
    
    def boxplot_december(self, Front:pd.DataFrame, Next:pd.DataFrame, Next_2:pd.DataFrame,
        end_date:datetime.datetime=None, save:bool=True)->None:
        """
        Plot the boxplot of the volumes for front, next and next_2 December futures up to the end date.
        If the end date is not provided, use the end of Phase III.
        If save is True, save the plot as a .png file.
        """

        if end_date is None:
            end_date = self.__PHASE_III_END

        # Boxplot of the volumes for front, next and next_2 December futures
        plt.boxplot(
            [
                np.log10(Front[Front['Date'] < end_date]['Volume'] + 1),
                np.log10(Next[Next['Date'] < end_date]['Volume'] + 1),
                np.log10(Next_2[Next_2['Date'] < end_date]['Volume'] + 1)
            ],
            tick_labels=['Front', 'Next', 'Next_2']
        )

        plt.title('Boxplot of the volumes for front, next and next_2 December futures')
        plt.grid()
        plt.xlabel('Futures')
        plt.ylabel('Volume (log scale)')
        plt.show()

        # save the plot as a .png file
        if save:
            plt.savefig('boxplot_december.png')

    def plot_front_next(self, C_spread:C_spread, end_date:datetime.datetime=None,
        save:bool=True)->None:
        """
        Plot the C-spread for the front and next futures up to the end date.
        If the end date is not provided, use the end of Phase III.
        """

        if end_date is None:
            end_date = self.__PHASE_III_END

        # filter the data
        Front = C_spread.c_spread_front()
        Next = C_spread.c_spread_next()

        # filter the data
        Front = Front[Front['Date'] < end_date]
        Next = Next[Next['Date'] < end_date]

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

        # save the plot as a .png file
        if save:
            plt.savefig('plot_front_next.png')

    def plot_C_spread(self, C_spread:C_spread, end_date:datetime.datetime=None, save:bool=True)->None:
        """
        Plot the aggregated C-spread up to the end date.
        If the end date is not provided, use the end of Phase III.
        If save is True, save the plot as a .png file.
        """

        if end_date is None:
            end_date = self.__PHASE_III_END

        # get the data
        C_spread = C_spread.c_spread()

        # filter the data
        C_spread = C_spread[C_spread['Date'] < end_date]

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

        # save the plot as a .png file
        if save:
            plt.savefig('plot_C_spread.png')

    def plot_C_Z_R(self, C_spread:C_spread, Z_spread:Z_spread, R:pd.DataFrame,
        end_date:datetime.datetime=None, save:bool=True)->None:
        """
        Plot the C-spread, Z-spread and risk-free rate up to the end date.
        If the end date is not provided, use the end of Phase III.
        If save is True, save the plot as a .png file.
        """

        if end_date is None:
            end_date = self.__PHASE_III_END
        
        # get the data
        C = C_spread.c_spread()
        Z = Z_spread.z_spread()

        # filter the data
        C = C[C['Date'] < end_date]
        Z = Z[Z['Date'] < end_date]
        R = R[R['Date'] < end_date]

        # plot the C-spread, Z-spread and risk-free rate
        plt.plot(C['Date'], 100 * C['C-spread'], label='C-spread')
        plt.plot(Z['Date'], 100 * Z['Z-spread'], label='Z-spread')
        plt.plot(R['Date'], 100 * R['Risk Free Rate'], label='Risk-free rate')
        plt.title('C-spread, Z-spread and risk-free rate')
        plt.grid()
        # set the y-axis limits
        plt.ylim([-0.5, 3.6])
        # limit the dates to the ones plotted and add 6 months of padding to both sides
        plt.xlim([
            C['Date'].values[0] - np.timedelta64(180, 'D'),
            C['Date'].values[-1] + np.timedelta64(180, 'D')
        ])
        plt.xlabel('Date')
        plt.ylabel('Rate (%)')
        plt.legend()
        plt.show()

        # save the plot as a .png file
        if save:
            plt.savefig('plot_C_Z_R.png')
