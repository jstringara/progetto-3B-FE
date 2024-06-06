import os
import datetime
import numpy as np
import pandas as pd

# import the Bond class from the bond.py file
if __name__ == '__main__':
    from bond import Bond
else:
    from preprocess.bond import Bond

# preprocessor
class Preprocessor:
    """
    Class to preprocess the data for the project.
    """

    __instance = None

    def __new__(cls):
        if cls.__instance is None:
            cls.__instance = super(Preprocessor, cls).__new__(cls)
            cls.__instance.__initialized = False
        return cls.__instance

    def __init__(self, data_dir:str = '../Data/', preprocessed_dir:str = 'Preprocess/Preprocessed/',
        futures_dir:str = 'Futures/', bonds_dir:str = 'Bonds/'):
        """
        Constructor for the Preprocessor class.
        """

        if self.__initialized:
            return

        # create module level variables for the dates for Phase III and Phase IV
        self.__PHASE_III_START = datetime.datetime(2013, 1, 1)
        self.__PHASE_III_END = datetime.datetime(2021, 1, 1)
        self.__PHASE_IV_END = datetime.datetime(2022, 10, 28)

        # create a module level variable for the directories
        self.__data_dir = '../Data/'
        self.__preprocessed_dir = os.path.join(os.path.dirname(__file__), 'Preprocessed/')
        self.__futures_dir = 'Futures/'
        self.__bonds_dir = 'Bonds/'

        # save the data inside the object
        self.__data = {}
        # date to consider for the data
        self.__dates = None
        # call the function to find the relevant dates
        self.relevant_dates()

        # check that the directories exist
        if not os.path.exists(self.__data_dir):
            raise FileNotFoundError(f'The directory {self.__data_dir} does not exist.')
        if not os.path.exists(os.path.join(self.__data_dir, self.__futures_dir)):
            raise FileNotFoundError(f'The directory {self.__futures_dir} does not exist.')
        if not os.path.exists(os.path.join(self.__data_dir, self.__bonds_dir)):
            raise FileNotFoundError(f'The directory {self.__bonds_dir} does not exist.')
        # if the preprocessed directory does not exist, create it
        if not os.path.exists(self.__preprocessed_dir):
            os.makedirs(self.__preprocessed_dir)
        
        # load all the data
        self.load_data()

        self.__initialized = True
    
    def load_data(self)->None:
        """
        Load the data from the preprocessed directory.
        """

        # start time
        start_time = datetime.datetime.now()

        # get the dates
        self.relevant_dates()

        # load the data
        self.preprocess_OIS_rates()
        self.preprocess_Volumes_front_Month('March')
        self.preprocess_Volumes_front_Month('June')
        self.preprocess_Volumes_front_Month('September')
        self.preprocess_December()
        self.preprocess_December(years_offset=1)
        self.preprocess_December(years_offset=2)
        self.preprocess_daily_price()
        self.preprocess_bonds()
        self.preprocess_open_interest()
        self.preprocess_extra_variables()

        # end time
        end_time = datetime.datetime.now()

        # print the time taken in seconds
        print(f'Time taken to load the data: {(end_time - start_time).total_seconds()} s')

    def relevant_dates(self):
        """
        Function to find the relevant dates for the data.
        """

        if self.__dates is None:
            # find the common dates between the futures and the daily price
            Daily_Price = self.preprocess_daily_price()
            Front = self.preprocess_December()
            common_dates = set(Daily_Price['Date']).intersection(set(Front['Date']))
            self.__dates = pd.Series(list(common_dates), index=range(len(common_dates)))
        return self.__dates

    def preprocess_Volumes_front_Month(self, month:str, first_date:datetime.datetime = None, 
        last_date:datetime.datetime = None)->pd.DataFrame:
        """
        Function to preprocess the data of the volumes of the futures contracts in a given month.
        Month can be either 'March', 'June', 'September'.
        Input:
        - month: string with the name of the month (either 'March', 'June' or 'September')
        - first_date: datetime object with the first date to consider. Default is the start of Phase III.
        - last_date: datetime object with the last date to consider. Default is the end of Phase III.
        Output:
        - DataFrame with the columns 'Date' and 'Volume'.
        """

        # check if the data has already been loaded
        if self.__data.get('Volumes_' + month) is not None:
            return self.__data['Volumes_' + month]

        # assign the default values for the dates
        first_date = first_date if first_date is not None else self.__PHASE_III_START
        last_date = last_date if last_date is not None else self.__PHASE_III_END

        # check that the month is one of the three possible months
        if month.capitalize() not in ['March', 'June', 'September']:
            raise ValueError('The month should be either "March", "June" or "September".')

        extra_futures = pd.read_excel(
            os.path.join(self.__data_dir, 'Volumes_extra_futures.xlsx'),
            sheet_name=month)

        # select only the dates for the given period
        extra_futures = extra_futures.loc[
            extra_futures['Date'] >= first_date].loc[
            extra_futures['Date'] < last_date]

        # initialize variables for the cycle
        column_names = extra_futures.columns
        prev_date = first_date
        Volumes = pd.DataFrame()

        # iterate over the years in the period
        years = range(first_date.year, last_date.year + 1)

        for year in years:

            # find the corresponding column
            col_name = list(filter(lambda x: str(year) in x, column_names))[0]

            # find the last quoted date as the last date where there is a value in the column
            next_date = extra_futures.loc[extra_futures[col_name].notnull(), 'Date'].max()
            # select the needed data
            selected_data = extra_futures.loc[extra_futures['Date'] > prev_date].loc[
                extra_futures['Date'] <= next_date, ['Date', col_name]]
            selected_data.columns = ['Date', 'Volume']
            # fill the NaN values with 0
            selected_data['Volume'] = selected_data['Volume'].fillna(0)
            # add the selected data to the DataFrame
            Volumes = pd.concat([Volumes, selected_data])
            # update the previous date
            prev_date = next_date

        # save the data inside the object
        self.__data['Volumes_' + month] = Volumes

        # reindex the data
        Volumes = Volumes.reset_index(drop=True)

        return Volumes

    def preprocess_December(self, years_offset:int = 0, first_date:datetime.datetime = None,
        last_date:datetime.datetime = None)->pd.DataFrame:
        """
        Function to preprocess the data of the volumes of the futures contracts in December.
        Input:
        - years_offset: integer with the number of years to go back from the current year.
        - first_date: datetime object with the first date to consider. Default is the start of Phase III.
        - last_date: datetime object with the last date to consider. Default is the end of Phase IV.
        Output:
        - DataFrame with the columns 'Date', 'Volume', 'Price' and 'Expiry'.
        """

        names = {
            0: 'Front',
            1: 'Next',
            2: 'Next_2'
        }

        name = names.get(years_offset)

        if name is None:
            raise ValueError('The years offset should be either 0, 1 or 2.')

        # check if the data has already been loaded
        if self.__data.get(names[years_offset]) is not None:
            return self.__data[names[years_offset]]

        # assign the default values for the dates
        first_date = first_date if first_date is not None else self.__PHASE_III_START
        last_date = last_date if last_date is not None else self.__PHASE_IV_END

        # initialize the DataFrame
        front_Dec = pd.DataFrame()
        prev_date = first_date

        years = range(first_date.year, last_date.year + 1)

        for year in years:

            # find the last quoted date
            file_name = f'ICE_FUT_{str(year)[-2:]}.csv'
            # open the corresponding file (read the Dates as dates and the VOLUME as float)
            front_volumes = pd.read_csv(os.path.join(self.__data_dir, self.__futures_dir, file_name),
                usecols=['Date', 'CLOSE', 'VOLUME'], parse_dates=['Date'])
            # find the last quoted date (expiry date) as the last date where there is a value in the column
            next_date = front_volumes.loc[front_volumes['VOLUME'].notnull(), 'Date'].max()

            # if there is an offset, we need to find the corresponding file
            if years_offset > 0:
                file_name = f'ICE_FUT_{str(year + years_offset)[-2:]}.csv'
                selected_data = pd.read_csv(os.path.join(self.__data_dir, self.__futures_dir, file_name),
                    usecols=['Date', 'CLOSE', 'VOLUME'], parse_dates=['Date'])
            else:
                selected_data = front_volumes
            # find the expiry as the last quoted date
            expiry_date = selected_data.loc[selected_data['CLOSE'].notnull(), 'Date'].max()
            # select the needed data
            selected_data = selected_data.loc[selected_data['Date'] >= prev_date].loc[
                selected_data['Date'] < next_date, ['Date', 'VOLUME', 'CLOSE']]
            # select only the date and the volume
            selected_data = pd.DataFrame(
                {
                    'Date': selected_data['Date'],
                    'Volume': selected_data['VOLUME'], 
                    'Price': selected_data['CLOSE']
                }
            )
            # fill the NaN values of the volume with 0
            selected_data['Volume'] = selected_data['Volume'].fillna(0)
            # add the expiry date to the DataFrame
            selected_data['Expiry'] = expiry_date
            # add the date to the DataFrame
            front_Dec = pd.concat([front_Dec, selected_data])
            # update the previous date
            prev_date = next_date

        # manually adjust the expiries of futures that go beyond the end of the data
        if years_offset == 0:
            front_expiry = datetime.datetime(2022, 12, 19)
            front_Dec.loc[front_Dec['Expiry'] == self.__PHASE_IV_END, 'Expiry'] = front_expiry
        elif years_offset == 1:
            third_from_last_expiry = datetime.datetime(2020, 12, 14)
            penultimate_expiry = datetime.datetime(2021, 12, 20)
            front_expiry = datetime.datetime(2022, 12, 19)
            next_expiry = datetime.datetime(2023, 12, 18)
            front_Dec.loc[(front_Dec['Date'] >= third_from_last_expiry) &
                (front_Dec['Date'] < penultimate_expiry), 'Expiry'] = front_expiry
            front_Dec.loc[front_Dec['Date'] >= penultimate_expiry, 'Expiry'] = next_expiry
        elif years_offset == 2:
            third_from_last_expiry = datetime.datetime(2020, 12, 14)
            penultimate_expiry = datetime.datetime(2021, 12, 20)
            front_expiry = datetime.datetime(2022, 12, 19)
            next_expiry = datetime.datetime(2023, 12, 18)
            next_2_expiry = datetime.datetime(2024, 12, 23)
            front_Dec.loc[(front_Dec['Date'] >= third_from_last_expiry) &
                (front_Dec['Date'] < penultimate_expiry), 'Expiry'] = front_expiry
            front_Dec.loc[(front_Dec['Date'] >= penultimate_expiry) &
                (front_Dec['Date'] < penultimate_expiry), 'Expiry'] = next_expiry
            front_Dec.loc[front_Dec['Date'] >= penultimate_expiry, 'Expiry'] = next_2_expiry
        
        # if the dates are not defined, simply return the data
        if self.__dates is None:
            return front_Dec
        
        # filter the data to only keep the dates in the front
        front_Dec = front_Dec.loc[front_Dec['Date'].isin(self.relevant_dates())]

        # save the data inside the object
        self.__data[name] = front_Dec

        # reindex the data
        front_Dec = front_Dec.reset_index(drop=True)

        return front_Dec

    def preprocess_daily_price(self, first_date:datetime.datetime = None,
            last_date:datetime.datetime = None)->pd.DataFrame:
        """
        Preprocess the daily price of the futures contracts.
        Input:
        - first_date: datetime object with the first date to consider. Default is the start of Phase III.
        - last_date: datetime object with the last date to consider. Default is the end of Phase IV.
        Output:
        - DataFrame with the columns 'Date' and 'Price'.
        """

        if self.__data.get('Daily_Price') is not None:
            return self.__data['Daily_Price']
        
        # assign the default values for the dates
        first_date = first_date if first_date is not None else self.__PHASE_III_START
        last_date = last_date if last_date is not None else self.__PHASE_IV_END

        daily_price = pd.read_csv(os.path.join(self.__data_dir, 'Daily_Future.csv'),
            usecols=['Date', 'CLOSE'], parse_dates=['Date'])

        # rename CLOSE to Price
        daily_price = daily_price.rename(columns={'CLOSE': 'Price'})

        # select only the dates for the given period
        daily_price = daily_price.loc[daily_price['Date'] >= first_date].loc[
            daily_price['Date'] < last_date]
        
        if self.__dates is None:
            return daily_price
        
        # filter the data to only keep the dates in the front
        daily_price = daily_price.loc[daily_price['Date'].isin(self.relevant_dates())]

        # save the data inside the object
        self.__data['Daily_Price'] = daily_price

        # reindex the data
        daily_price = daily_price.reset_index(drop=True)

        return daily_price

    def preprocess_bonds(self, first_date:datetime.datetime = None,
        last_date:datetime.datetime = None)->dict:
        """
        Preprocess the data of the bonds and pass them to matlab.
        Input:
        - first_date: datetime object with the first date to consider. Default is the start of Phase III.
        - last_date: datetime object with the last date to consider. Default is the end of Phase IV.
        Output:
        - dict with the bonds.
        """

        if self.__data.get('Bonds') is not None:
            return self.__data['Bonds']

        # assign the default values for the dates
        first_date = first_date if first_date is not None else self.__PHASE_III_START
        last_date = last_date if last_date is not None else self.__PHASE_IV_END

        # read the bonds from the list of valid bonds
        bonds = pd.read_csv(os.path.join(self.__data_dir, self.__bonds_dir, 'List_Valid_Bonds.csv'),
            parse_dates=['Maturity Date'],
            usecols= ['Instrument', 'Coupon Rate', 'Maturity Date', 'Original Amount Issued',
                'Coupon Frequency', 'Issuer Ticker', 'Parent Ticker'])
        # filter for only the bonds listed in the table
        issuers_to_keep = ["MT", "ENEI", "ENGIE", "LAFARGE", "HEIG", "EDF", "ENI", "TTEF", "MAERS",
            "EONG", "CEZP", "VIE"]
        bonds = bonds.loc[bonds['Parent Ticker'].isin(issuers_to_keep)]
        # use only bond that have that have a volume higher than 500_000_000
        bonds = bonds.loc[bonds['Original Amount Issued'] >= 500_000_000]

        # set the date range for the bonds
        Bond.set_date_range(first_date, last_date)

        # create the dict of bonds
        bonds_list = {

            row['Instrument'] : Bond(
                code = row['Instrument'],
                coupon_rate = row['Coupon Rate'],
                maturity_date = row['Maturity Date'],
                coupon_frequency = row['Coupon Frequency'],
                volume = row['Original Amount Issued'],
                issuer = row['Parent Ticker']
            )

            for i, row in bonds.iterrows()
        }

        # use only the bonds that have data
        bonds_list = {
            key: value
            for key, value in bonds_list.items()
            if not value.is_empty()
        }

        # filter the data to only keep the dates in the front
        _ = [
            value.filter_data(self.relevant_dates())
            for key, value in bonds_list.items()
        ]

        # save the data inside the object
        self.__data['Bonds'] = bonds_list

        return bonds_list

    def preprocess_open_interest(self, first_date:datetime.datetime = None,
        last_date:datetime.datetime = None)->pd.DataFrame:
        """
        Preprocess the data of the open interest of the futures contracts.
        Input:
        - first_date: datetime object with the first date to consider. Default is the start of Phase III.
        - last_date: datetime object with the last date to consider. Default is the end of Phase IV.
        Output:
        - DataFrame with the columns 'Date' and 'Open Interest'.
        """

        if self.__data.get('Open_Interest') is not None:
            return self.__data['Open_Interest']

        # set the default values for the dates
        first_date = first_date if first_date is not None else self.__PHASE_III_START
        last_date = last_date if last_date is not None else self.__PHASE_IV_END

        # load the data for the open interest from the xlsx file
        open_interest = pd.read_excel(os.path.join(self.__data_dir, 'OpenInterest.xlsx'),
            parse_dates=['Date'])

        # filter the data to only keep the dates in the front
        open_interest = open_interest.loc[open_interest['Date'].isin(self.relevant_dates())]

        # loop over the years
        years = range(first_date.year, last_date.year + 1)
        prev_date = first_date
        columns = open_interest.columns

        # modify front to adjust 2014 expiry date
        front = self.preprocess_December().copy()
        front.loc[
            front['Expiry'] == datetime.datetime(2014, 12, 15), 'Expiry'
        ] = datetime.datetime(2014, 12, 12)

        # output DataFrame
        df = pd.DataFrame()

        for year in years:

            # find the corresponding column
            col_front = list(filter(lambda x: str(year) in x, columns))[0]
            col_next = list(filter(lambda x: str(year + 1) in x, columns))[0]

            # corresponding expiry date of the Front
            expiry_date = front.loc[front['Date'].dt.year == year, 'Expiry'].values[0]

            # find the selected data
            selected_data = open_interest.loc[(open_interest['Date'] > prev_date) &
                (open_interest['Date'] <= expiry_date), ['Date', col_front, col_next]]
            selected_data.columns = ['Date', 'Front', 'Next']

            # fill the NaN values with 0
            selected_data['Front'] = selected_data['Front'].fillna(0)

            # add the selected data to the DataFrame
            df = pd.concat([df, selected_data])

            # update the previous date
            prev_date = expiry_date
        
        # save the data inside the object
        self.__data['Open_Interest'] = df

        # reindex the data
        df = df.reset_index(drop=True)

        return df

    def preprocess_extra_variables(self)->pd.DataFrame:
        """
        Preprocess the extra variables.
        Output:
        - DataFrame with the columns 'Date' and 'Extra'.
        """

        if self.__data.get('Extra_Variables') is not None:
            return self.__data['Extra_Variables']

        # load the data for the extra variables
        extra_variables = pd.read_csv(os.path.join(self.__data_dir, 'Extra_Variables.csv'),
            parse_dates=['Date'], usecols=['Date', 'SPX', 'VIX', 'WTI'])

        # filter the data to only keep the dates in the front
        extra_variables = extra_variables.loc[extra_variables['Date'].isin(self.relevant_dates())]

        # fill the values with the previous value
        extra_variables = extra_variables.ffill()

        # take the log returns of SPX and WTI
        extra_variables['SPX'] = np.log(1 + extra_variables['SPX'].pct_change())
        extra_variables['WTI'] = np.log(1 + extra_variables['WTI'].pct_change())

        # save the data inside the object
        self.__data['Extra_Variables'] = extra_variables

        # reindex the data
        extra_variables = extra_variables.reset_index(drop=True)

        return extra_variables

    # preprocess the OIS rates
    def preprocess_OIS_rates(self, first_date:datetime.datetime = None,
        last_date:datetime.datetime = None)->pd.DataFrame:
        """
        Preprocess the data of the OIS rates.
        Input:
        - first_date: datetime object with the first date to consider. Default is the start of Phase III.
        - last_date: datetime object with the last date to consider. Default is the end of Phase IV.
        Output:
        - DataFrame with the columns 'Date' and 'Rate'.
        """

        if self.__data.get('OIS_Data') is not None:
            return self.__data['OIS_Data']

        # set the default values for the dates
        first_date = first_date if first_date is not None else self.__PHASE_III_START
        last_date = last_date if last_date is not None else self.__PHASE_IV_END

        # load the data for the OIS rates
        # the dates use short year format
        OIS_rates = pd.read_csv(os.path.join(self.__data_dir, 'OIS_Data.csv'),
            parse_dates=['Date'], date_format='%d/%m/%y')

        # fill the NaN values with the previous value
        OIS_rates = OIS_rates.ffill()

        # remove duplicates
        OIS_rates = OIS_rates.drop_duplicates()

        # make all columns besides the date in percentage
        OIS_rates.iloc[:, 1:] = OIS_rates.iloc[:, 1:] / 100
        
        # filter the data to only keep the dates in the front
        OIS_rates = OIS_rates.loc[OIS_rates['Date'] >= first_date].loc[
            OIS_rates['Date'] <= last_date]
        
        # save the data inside the object
        self.__data['OIS_Data'] = OIS_rates

        # reindex the data
        OIS_rates = OIS_rates.reset_index(drop=True)

        return OIS_rates
    
    def save_data(self)->None:
        """
        Save the data to the preprocessed directory.
        """

        # save the data (skip the bonds)
        for key, value in self.__data.items():
            if key != 'Bonds':
                value.to_csv(os.path.join(self.__preprocessed_dir, key + '.csv'), index=False)

if __name__ == '__main__':

    preprocess = Preprocessor()

    # create a new instance of the class and check that it is the same as the previous one
    preprocess2 = Preprocessor()
    print(preprocess is preprocess2)

    preprocess.save_data()
