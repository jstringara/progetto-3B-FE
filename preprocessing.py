import os
import datetime
import pandas as pd

def preprocess_Volumes_front_Month(month:str, save:bool = True)->pd.DataFrame:
    """
    Function to preprocess the data of the volumes of the futures contracts in a given month.
    Month can be either 'March', 'June', 'September'.
    Input:
    - month: string with the name of the month (either 'March', 'June' or 'September')
    - save: boolean indicating whether to save the output to a csv file or not.
    Output:
    - DataFrame with the columns 'Date' and 'Volume'.
    """
    # check that the month is one of the three possible months
    if month.capitalize() not in ['March', 'June', 'September']:
        raise ValueError('The month should be either "March", "June" or "September".')

    # read the xlsx file 'Volume_extra_futures.xlsx' and store it in a DataFrame
    data_dir = 'Data/'
    # output dir
    output_dir = 'Preprocessed/'

    extra_futures_march = pd.read_excel(
        os.path.join(data_dir, 'Volumes_extra_futures.xlsx'),
        sheet_name=month)

    # select only the dates for the Phase III (2013-2021)
    extra_futures_march = extra_futures_march.loc[
        extra_futures_march['Date'] >= datetime.datetime(2013, 1, 1)]
    extra_futures_march = extra_futures_march.loc[
        extra_futures_march['Date'] < datetime.datetime(2022, 1, 1)]

    # extract the time series of the Month front.
    # This means we find the closest date to the 15th of March for each year

    # initialize variables for the cycle
    column_names = extra_futures_march.columns
    prev_date = datetime.datetime(2013, 1, 1) # only dates after this date will be considered
    Volumes_march = pd.DataFrame()

    for year in range(2013, 2022):
        # find the corresponding column
        col_name = list(filter(lambda x: str(year) in x, column_names))[0]
        # find the last quoted date as the last date where there is a value in the column
        last_date = extra_futures_march.loc[extra_futures_march[col_name].notnull(), 'Date'].max()
        # bring it back a month
        # last_date = last_date - pd.DateOffset(months=1)
        # select the needed data
        selected_data = extra_futures_march.loc[extra_futures_march['Date'] > prev_date].loc[
            extra_futures_march['Date'] <= last_date, ['Date', col_name]]
        selected_data.columns = ['Date', 'Volume']
        # fill the NaN values with 0
        selected_data['Volume'] = selected_data['Volume'].fillna(0)
        # find the dates between the last date and the previous date
        Volumes_march = pd.concat([Volumes_march, selected_data])
        # update the previous date
        prev_date = last_date

    if save:
        # save the DataFrame to a csv file without the index
        Volumes_march.to_csv(os.path.join(output_dir, f'Volumes_{month}.csv'), index=False)

    return Volumes_march

def preprocess_Volumes_Dec(years_offset:int = 0, save:bool = True)->pd.DataFrame:
    """
    Function to preprocess the data of the volumes of the futures contracts in December.
    Input:
    - years_offset: integer with the number of years to go back from the current year.
    - save: boolean indicating whether to save the output to a csv file or not.
    Output:
    - DataFrame with the columns 'Date' and 'Volume'.
    """

    # directory of the data
    data_dir = 'Data/'
    futures_dir = 'Futures/'
    output_dir = 'Preprocessed/'

    # initialize the DataFrame
    Volumes_Dec = pd.DataFrame()
    prev_date = datetime.datetime(2013, 1, 1) # only dates after this date will be considered

    for year in range(2013, 2022):

        # find the corresponding file
        file_name = f'ICE_FUT_{str(year + years_offset)[-2:]}.csv'
        # compute the expiry date (penultimate Monday of December)
        expiry_date = pd.to_datetime(f'{year}-12-01') + pd.DateOffset(months=1, weeks=-2, weekday=0)
        # bring it back a month
        last_date = expiry_date - pd.DateOffset(months=1)
        # open the corresponding file (read the Dates as dates and the VOLUME as float)
        future_volumes = pd.read_csv(os.path.join(data_dir, futures_dir, file_name),
            usecols=['Date', 'OPEN', 'CLOSE', 'VOLUME'], parse_dates=['Date'])
        # select the needed data
        selected_data = future_volumes.loc[future_volumes['Date'] > prev_date].loc[
            future_volumes['Date'] <= last_date, ['Date', 'VOLUME', 'OPEN', 'CLOSE']]
        # select only the date and the volume
        selected_data = pd.DataFrame(
            {
                'Date': selected_data['Date'],
                'Volume': selected_data['VOLUME'], 
                'Open': selected_data['OPEN'],
                'Close': selected_data['CLOSE']
            }
        )
        # fill the NaN value of the open with the corresponding close and take the average
        selected_data['Open'] = selected_data['Open'].fillna(selected_data['Close'])
        selected_data['Price'] = (selected_data['Open'] + selected_data['Close']) / 2
        # fill the NaN values of the volume with 0
        selected_data['Volume'] = selected_data['Volume'].fillna(0)
        # drop the open and close columns
        selected_data = selected_data.drop(columns=['Open', 'Close'])
        # add the expiry date to the DataFrame
        selected_data['Expiry'] = expiry_date
        # add the date to the DataFrame
        Volumes_Dec = pd.concat([Volumes_Dec, selected_data])
        # update the previous date
        prev_date = last_date
    
    # finally, keep only the dates that also have an associated daily price
    daily_dates = pd.read_csv(os.path.join(data_dir, 'Daily_Future.csv'),
        usecols=['Date'], parse_dates=['Date'])
    daily_dates = daily_dates.loc[daily_dates['Date'].isin(Volumes_Dec['Date'])]
    # filter the Volumes_Dec DataFrame
    Volumes_Dec = Volumes_Dec.loc[Volumes_Dec['Date'].isin(daily_dates['Date'])]

    # save the DataFrame to a csv file without the index
    if save:
        Volumes_Dec.to_csv(
            os.path.join(output_dir, f'Volumes_December_{years_offset}.csv'),
            index=False)

    return Volumes_Dec

def preprocess_daily_price(front_dates:pd.Series, save:bool = True)->pd.DataFrame:
    """
    Preprocess the daily price of the futures contracts.
    Input:
    - front_dates: Series with the dates of the front futures contracts.
    - save: boolean indicating whether to save the output to a csv file or not.
    Output:
    - DataFrame with the columns 'Date' and 'Price'.
    """

    # load the data for the daily futures
    data_dir = 'Data/'
    output_dir = 'Preprocessed/'

    daily_price = pd.read_csv(os.path.join(data_dir, 'Daily_Future.csv'),
        usecols=['Date', 'OPEN', 'CLOSE'], parse_dates=['Date'])

    # keep only the dates that are also in the Volumes_dec_front
    daily_price = daily_price.loc[daily_price['Date'].isin(front_dates)]
    # fill the open with the close and take the average
    daily_price['OPEN'] = daily_price['OPEN'].fillna(daily_price['CLOSE'])
    daily_price['Price'] = (daily_price['OPEN'] + daily_price['CLOSE']) / 2
    # drop the open and close columns
    daily_price = daily_price.drop(columns=['OPEN', 'CLOSE'])

    # save the DataFrame to a csv file without the index
    if save:
        daily_price.to_csv(
            os.path.join(output_dir, 'Daily_Future_Price.csv'),
            index=False)
    
    return daily_price

# Bond class
class Bond:

    # class attribute to keep track of the number of bonds that were not found
    __unfound_info = []

    def __init__(self, code, coupon_rate, maturity_date, coupon_frequency, issuer_ticker, parent_ticker):
        """
        Constructor for the Bond class.
        Input:
        - code: string with the code of the bond.
        - coupon_rate: float with the coupon rate of the bond.
        - maturity_date: datetime.date with the maturity date of the bond.
        - coupon_frequency: string with the frequency of the coupon payments.
        - issuer_ticker: string with the ticker of the issuer.
        - parent_ticker: string with the ticker of the parent company.
        """

        # save the attributes
        self.__code = code
        self.__coupon_rate = coupon_rate
        self.__maturity_date = maturity_date
        self.__coupon_frequency = coupon_frequency
        self.__issuer_ticker = issuer_ticker
        self.__parent_ticker = parent_ticker
        # load the data for the bond
        self.__data = self.load_data()
    
    def __repr__(self):
        """
        String representation of the Bond object.
        """
        # create a table with the information of the bond
        return f"""
 --- Bond {self.__code} ---
 Coupon rate: {self.__coupon_rate}
 Maturity date: {self.__maturity_date}
 Coupon frequency: {self.__coupon_frequency} 
 Issuer ticker: {self.__issuer_ticker}   
 Parent ticker: {self.__parent_ticker}
 -------------------"""

    
    def load_data(self)->pd.DataFrame:
        """
        Load the data for the bond from the csv file of the parent company.
        """
        # load the data for the parent company
        data_dir = 'Data/'
        bonds_dir = 'Bonds/'

        parent_data = pd.read_csv(os.path.join(data_dir, bonds_dir, f'{self.__parent_ticker}.csv'),
            parse_dates=['Date'])
        # drop the first and second columns
        parent_data = parent_data.drop(columns=[parent_data.columns[0], parent_data.columns[1]])

        # try to extract the data
        out_df = pd.DataFrame()
        try:
            out_df = parent_data[self.__code]
        except KeyError:
            # add it to the unfound bonds
            Bond.__unfound_info.append(self)
        
        return out_df


# read the bonds from the lis of valid bonds
bonds = pd.read_csv('Data/Bonds/List_Valid_Bonds.csv', parse_dates=['Maturity Date'],
    usecols= ['Instrument', 'Coupon Rate', 'Maturity Date', 'Original Amount Issued',
        'Coupon Frequency', 'Issuer Ticker', 'Parent Ticker'])
# filter for only the bonds listed in the table
issuers_to_keep = ['MT', 'ENEI', 'ENGIE', 'LAFARGE', 'HEIG', 'EDF', 'ENI', 'TTEF', 'EONG', 'CEZP', 'VIE']
bonds = bonds.loc[bonds['Parent Ticker'].isin(issuers_to_keep)]

# create the list of bonds
bonds_list = {

    row['Instrument'] : Bond(
        code = row['Instrument'],
        coupon_rate = row['Coupon Rate'],
        maturity_date = row['Maturity Date'],
        coupon_frequency = row['Coupon Frequency'],
        issuer_ticker = row['Issuer Ticker'],
        parent_ticker = row['Parent Ticker']
    )

    for i, row in bonds.iterrows()
}

if __name__ != '__main__':
    # preprocess the volumes of the futures contracts
    preprocess_Volumes_front_Month('March')
    preprocess_Volumes_front_Month('June')
    preprocess_Volumes_front_Month('September')
    # preprocess the volumes of the futures contracts in December (front, next and second next)
    front_december = preprocess_Volumes_Dec()
    preprocess_Volumes_Dec(years_offset=1)
    preprocess_Volumes_Dec(years_offset=2)
    # preprocess the daily price of the futures contracts
    preprocess_daily_price(front_december['Date'])
