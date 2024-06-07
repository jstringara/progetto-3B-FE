import datetime
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from statsmodels.graphics.tsaplots import plot_acf, plot_pacf

# custom imports
from spreads import C_spread, Z_spread

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
        fig, ax = plt.subplots()
        # Volumes of March, June, September and December for PHASE III in log scale
        ax.boxplot(
            [
                np.log10(March['Volume'] + 1),
                np.log10(June['Volume'] + 1),
                np.log10(September['Volume'] + 1),
                np.log10(December[December['Date'] < end_date]['Volume'] + 1)
            ],
            tick_labels=['March', 'June', 'September', 'December']
        )

        ax.set_title('Boxplot of the volumes for different months')
        ax.grid()
        ax.set_xlabel('Months')
        ax.set_ylabel('Volume (log scale)')

        # save the plot as a .png file
        if save:
            fig.savefig('boxplot_months.png')

        plt.show()
    
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
        fig, ax = plt.subplots()
        ax.boxplot(
            [
                np.log10(Front[Front['Date'] < end_date]['Volume'] + 1),
                np.log10(Next[Next['Date'] < end_date]['Volume'] + 1),
                np.log10(Next_2[Next_2['Date'] < end_date]['Volume'] + 1)
            ],
            tick_labels=['Front', 'Next', 'Next_2']
        )

        ax.set_title('Boxplot of the volumes for front, next and next_2 December futures')
        ax.grid()
        ax.set_xlabel('Futures')
        ax.set_ylabel('Volume (log scale)')

        # save the plot as a .png file
        if save:
            fig.savefig('boxplot_december.png')

        plt.show()

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

        fig, ax = plt.subplots()

        # plot the C-spread for the front and next futures
        ax.plot(Front['Date'], 100 * Front['C-spread'], label='Front')
        ax.plot(Next['Date'], 100 * Next['C-spread'], label='Next')
        ax.set_title('C-spread for the front and next futures')
        ax.grid()
        # set the y-axis limits
        ax.set_ylim([-1, 5])
        # limit the dates to the ones plotted and add 6 months of padding to both sides
        ax.set_xlim([
            Front['Date'].values[0] - np.timedelta64(180, 'D'),
            Front['Date'].values[-1] + np.timedelta64(180, 'D')
        ])
        ax.set_xlabel('Date')
        ax.set_ylabel('C-spread')
        ax.legend()

        # save the plot as a .png file
        if save:
            fig.savefig('plot_front_next.png')

        plt.show()

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
        fig, ax = plt.subplots()

        ax.plot(C_spread['Date'], 100 * C_spread['C-spread'])
        ax.set_title('Aggregated C-spread')
        ax.grid()
        # set the y-axis limits
        ax.set_ylim([-0.6, 3.6])
        # limit the dates to the ones plotted and add 6 months of padding to both sides
        ax.set_xlim([
            C_spread['Date'].values[0] - np.timedelta64(180, 'D'),
            C_spread['Date'].values[-1] + np.timedelta64(180, 'D')
        ])
        ax.set_xlabel('Date')
        ax.set_ylabel('C-spread')

        # save the plot as a .png file
        if save:
            fig.savefig('plot_C_spread.png')

        plt.show()

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
        fig, ax = plt.subplots()

        ax.plot(C['Date'], 100 * C['C-spread'], label='C-spread')
        ax.plot(Z['Date'], 100 * Z['Z-spread'], label='Z-spread')
        ax.plot(R['Date'], 100 * R['Risk Free Rate'], label='Risk-free rate')
        ax.set_title('C-spread, Z-spread and risk-free rate')
        ax.grid()
        # set the y-axis limits
        ax.set_ylim([-0.5, 3.6])
        # limit the dates to the ones plotted and add 6 months of padding to both sides
        ax.set_xlim([
            C['Date'].values[0] - np.timedelta64(180, 'D'),
            C['Date'].values[-1] + np.timedelta64(180, 'D')
        ])
        ax.set_xlabel('Date')
        ax.set_ylabel('Rate (%)')
        ax.legend()

        # save the plot as a .png file
        if save:
            fig.savefig('plot_C_Z_R.png')

        plt.show()
    
    def plot_ACF_PACF(self, C_spread:C_spread, Z_spread:Z_spread, R:pd.DataFrame,
        end_date:datetime.datetime=None, save:bool=True)->None:
        """
        Plot the ACF and PACF of the C-spread, Z-spread and risk-free rate up to the end date.
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

        # plot the ACF and PACF of the C-spread, Z-spread and risk-free rate
        fig, axs = plt.subplots(3, 2, figsize=(20, 15))

        # C-spread
        # ACF
        plot_acf(C['C-spread'], ax=axs[0, 0])
        axs[0, 0].set_title('ACF of the C-spread')
        # PACF
        plot_pacf(C['C-spread'], ax=axs[0, 1])
        axs[0, 1].set_title('PACF of the C-spread')

        # Z-spread
        # ACF
        plot_acf(Z['Z-spread'], ax=axs[1, 0])
        axs[1, 0].set_title('ACF of the Z-spread')
        # PACF
        plot_pacf(Z['Z-spread'], ax=axs[1, 1])
        axs[1, 1].set_title('PACF of the Z-spread')

        # Risk-free rate
        # ACF
        plot_acf(R['Risk Free Rate'], ax=axs[2, 0])
        axs[2, 0].set_title('ACF of the Risk-free rate')
        # PACF
        plot_pacf(R['Risk Free Rate'], ax=axs[2, 1])
        axs[2, 1].set_title('PACF of the Risk-free rate')

        # save the plot as a .png file
        if save:
            fig.savefig('plot_ACF_PACF.png')
        
        plt.show()
