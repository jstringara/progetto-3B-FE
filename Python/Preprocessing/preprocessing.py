import os
import sys
import datetime
import pandas as pd

# import the Bond class from the bond.py file
from bond import Bond

# this is a pointer to the module object instance itself.
this = sys.modules[__name__]

# save the data for checking
this.save_data = __name__ == '__main__'

# create module level variables for the dates for Phase III and Phase IV
this.PHASE_III_START = datetime.datetime(2013, 1, 1)
this.PHASE_III_END = datetime.datetime(2021, 1, 1)
this.PHASE_IV_START = datetime.datetime(2021, 1, 1)
this.PHASE_IV_END = datetime.datetime(2022, 10, 28)

# create a module level variable for the directories
this.data_dir = '../Data/'
this.preprocessed_dir = 'Preprocessed/'
this.futures_dir = 'Futures/'

# check that the directories exist
if not os.path.exists(this.data_dir):
    raise FileNotFoundError(f'The directory {this.data_dir} does not exist.')
# if the preprocessed directory does not exist, create it
if not os.path.exists(this.preprocessed_dir):
    os.makedirs(this.preprocessed_dir)

def preprocess_Volumes_front_Month(month:str, first_date:datetime.datetime = this.PHASE_III_START,
    last_date:datetime.datetime = this.PHASE_III_END)->pd.DataFrame:
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
    # check that the month is one of the three possible months
    if month.capitalize() not in ['March', 'June', 'September']:
        raise ValueError('The month should be either "March", "June" or "September".')

    # read the xlsx file 'Volume_extra_futures.xlsx' and store it in a DataFrame
    data_dir = this.data_dir

    extra_futures = pd.read_excel(
        os.path.join(data_dir, 'Volumes_extra_futures.xlsx'),
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

    return Volumes

def preprocess_December(years_offset:int = 0, first_date:datetime.datetime = this.PHASE_III_START,
    last_date:datetime.datetime = this.PHASE_IV_END)->pd.DataFrame:
    """
    Function to preprocess the data of the volumes of the futures contracts in December.
    Input:
    - years_offset: integer with the number of years to go back from the current year.
    - first_date: datetime object with the first date to consider. Default is the start of Phase III.
    - last_date: datetime object with the last date to consider. Default is the end of Phase IV.
    Output:
    - DataFrame with the columns 'Date', 'Volume', 'Price' and 'Expiry'.
    """

    # directory of the data
    data_dir = this.data_dir
    futures_dir = this.futures_dir

    # initialize the DataFrame
    front_Dec = pd.DataFrame()
    prev_date = first_date

    years = range(first_date.year, last_date.year + 1)

    for year in years:

        # find the last quoted date
        file_name = f'ICE_FUT_{str(year)[-2:]}.csv'
        # open the corresponding file (read the Dates as dates and the VOLUME as float)
        front_volumes = pd.read_csv(os.path.join(data_dir, futures_dir, file_name),
            usecols=['Date', 'CLOSE', 'VOLUME'], parse_dates=['Date'])
        # find the last quoted date (expiry date) as the last date where there is a value in the column
        next_date = front_volumes.loc[front_volumes['VOLUME'].notnull(), 'Date'].max()

        # if there is an offset, we need to find the corresponding file
        if years_offset > 0:
            file_name = f'ICE_FUT_{str(year + years_offset)[-2:]}.csv'
            selected_data = pd.read_csv(os.path.join(data_dir, futures_dir, file_name),
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
    
    return front_Dec

def preprocess_daily_price(first_date:datetime.datetime = this.PHASE_III_START,
    last_date:datetime.datetime = this.PHASE_IV_END)->pd.DataFrame:
    """
    Preprocess the daily price of the futures contracts.
    Input:
    - first_date: datetime object with the first date to consider. Default is the start of Phase III.
    - last_date: datetime object with the last date to consider. Default is the end of Phase IV.
    Output:
    - DataFrame with the columns 'Date' and 'Price'.
    """

    # load the data for the daily futures
    data_dir = this.data_dir

    daily_price = pd.read_csv(os.path.join(data_dir, 'Daily_Future.csv'),
        usecols=['Date', 'CLOSE'], parse_dates=['Date'])

    # rename CLOSE to Price
    daily_price = daily_price.rename(columns={'CLOSE': 'Price'})

    # select only the dates for the given period
    daily_price = daily_price.loc[daily_price['Date'] >= first_date].loc[
        daily_price['Date'] < last_date]

    return daily_price

# read the data of the bonds and pass them to matlab
def preprocess_bonds(front_dates:pd.Series, save:bool = True)->dict[str: Bond]:
    """
    Preprocess the data of the bonds and pass them to matlab.
    """

    # directory of the data
    data_dir = 'Data/'
    bonds_dir = 'Bonds/'
    output_dir = 'Preprocessed/'

    # read the bonds from the list of valid bonds
    bonds = pd.read_csv(os.path.join(data_dir, bonds_dir, 'List_Valid_Bonds.csv'),
        parse_dates=['Maturity Date'],
        usecols= ['Instrument', 'Coupon Rate', 'Maturity Date', 'Original Amount Issued',
            'Coupon Frequency', 'Issuer Ticker', 'Parent Ticker'])
    # filter for only the bonds listed in the table
    issuers_to_keep = ['MT', 'ENEI', 'ENGIE', 'LAFARGE', 'HEIG', 'EDF', 'ENI', 'TTEF', 'MAERS',
        'EONG', 'CEZP', 'VIE']
    bonds = bonds.loc[bonds['Parent Ticker'].isin(issuers_to_keep)]
    # use only bond that have that have a volume higher than 500_000_000
    bonds = bonds.loc[bonds['Original Amount Issued'] >= 500_000_000]

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

    # filter the bonds to only keep the ones that were found
    bonds_list = {key: value for key, value in bonds_list.items() if not value.is_empty()}

    # filter the data to only keep the dates in the front
    _ = [
        value.filter_data(front_dates)
        for key, value in bonds_list.items()
    ]

    # save the dictionary to a .mat file
    if save:
        # convert to a dictionary of structures for matlab use
        bonds_dict = [
            value.to_matlab_cellarray()
            for key, value in bonds_list.items()
        ]
        savemat(os.path.join(output_dir, 'Bonds.mat'), {'Bonds': bonds_dict})

    return bonds_list

# preprocess the volumes of the futures contracts
Volumes_March = preprocess_Volumes_front_Month('March')
Volumes_June = preprocess_Volumes_front_Month('June')
Volumes_Sep = preprocess_Volumes_front_Month('September')

# preprocess the volumes of the futures contracts in December (front, next and second next)
Front = preprocess_December()
Next = preprocess_December(years_offset=1)
Next_2 = preprocess_December(years_offset=2)

# preprocess the daily price of the futures contracts
Daily_Price = preprocess_daily_price()

# keep only the dates in common between the Daily Price and the Futures
common_dates = set(Daily_Price['Date']).intersection(set(Front['Date']))
commond_dates = pd.Series(list(common_dates))

# filter the data to only keep the common dates
Front = Front.loc[Front['Date'].isin(common_dates)]
Next = Next.loc[Next['Date'].isin(common_dates)]
Next_2 = Next_2.loc[Next_2['Date'].isin(common_dates)]
Daily_Price = Daily_Price.loc[Daily_Price['Date'].isin(common_dates)]

# fix the expiries of the front, next and next_2
front_expiry = datetime.datetime(2022, 12, 19)
Front.loc[Front['Expiry'] == this.PHASE_IV_END, 'Expiry'] = front_expiry

front_expiries = Front['Expiry'].unique()
third_from_last_expiry = front_expiries[-3]
penultimate_expiry = front_expiries[-2]
next_expiry = datetime.datetime(2023, 12, 18)
Next.loc[(Next['Date'] >= third_from_last_expiry) & 
    (Next['Date'] < penultimate_expiry), 'Expiry'] = next_expiry
Next.loc[Next['Date'] >= penultimate_expiry, 'Expiry'] = next_expiry

fourth_from_last_expiry = front_expiries[-4]
next_2_expiry = datetime.datetime(2024, 12, 23)
Next_2.loc[(Next_2['Date'] >= fourth_from_last_expiry) &
    (Next_2['Date'] < third_from_last_expiry), 'Expiry'] = front_expiry
Next_2.loc[(Next_2['Date'] >= third_from_last_expiry) &
    (Next_2['Date'] < penultimate_expiry), 'Expiry'] = next_expiry
Next_2.loc[Next_2['Date'] >= penultimate_expiry, 'Expiry'] = next_2_expiry

# # preprocess the bonds
# preprocess_bonds(front_december['Date'])

if this.save_data:
    # save the data
    Volumes_March.to_csv(os.path.join(this.preprocessed_dir, 'Volumes_March.csv'), index=False)
    Volumes_June.to_csv(os.path.join(this.preprocessed_dir, 'Volumes_June.csv'), index=False)
    Volumes_Sep.to_csv(os.path.join(this.preprocessed_dir, 'Volumes_Sep.csv'), index=False)
    Front.to_csv(os.path.join(this.preprocessed_dir, 'Front.csv'), index=False)
    Next.to_csv(os.path.join(this.preprocessed_dir, 'Next.csv'), index=False)
    Next_2.to_csv(os.path.join(this.preprocessed_dir, 'Next_2.csv'), index=False)
    Daily_Price.to_csv(os.path.join(this.preprocessed_dir, 'Daily_Price.csv'), index=False)
