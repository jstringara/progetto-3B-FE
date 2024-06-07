import datetime
import numpy as np
import pandas as pd
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

