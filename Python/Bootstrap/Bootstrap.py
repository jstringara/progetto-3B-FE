import datetime
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

        # structure to hold the zero rates
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
            return datetime.timedelta(days=num)
        elif unit == 'W':
            return datetime.timedelta(weeks=num)
        elif unit == 'M':
            return datetime.timedelta(months=num)
        elif unit == 'Y':
            return datetime.timedelta(years=num)
        else:
            raise ValueError('Invalid unit in the offset string')

    def __bootstrap(self)->None:
        """
        Perform the bootstrapping of the zero rates
        """

        # offsets list to match the tenors of the OIS rates
        offsets = {
            self.__OIS_data.columns[i]: self.__to_timedelta(self.__OIS_data.columns[i])
            for i in range(1, len(self.__OIS_data.columns))
        }

        print(offsets)

        # # initialize the zero rates DataFrame
        # zero_rates = pd.DataFrame(columns = self.__OIS_data.columns)
        # dates = pd.DataFrame(columns = self.__OIS_data.columns)
        # zero_rates['Date'] = self.__OIS_data['Date']
        # dates['Date'] = self.__OIS_data['Date']

        # use the offset to calculate the dates
