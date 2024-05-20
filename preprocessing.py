import os
import datetime
import pandas as pd

def preprocess_Volumes(month:str, save:bool = True)->pd.DataFrame:
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
        file_name = f'ICE_FUT_{str(year)[-2:]}.csv'
        # open the corresponding file (read the Dates as dates and the VOLUME as float)
        future_volumes_front = pd.read_csv(os.path.join(data_dir, futures_dir, file_name),
            usecols=['Date', 'OPEN', 'CLOSE', 'VOLUME'], parse_dates=['Date'])
        # find the last quoted date as the last date where there is a value in the column
        last_date = future_volumes_front.loc[future_volumes_front['VOLUME'].notnull(), 'Date'].max()
        # bring it back a month
        # last_date = last_date - pd.DateOffset(months=1)
        # if there is an offset, get the date 
        if years_offset > 0:
            # find the file from which to get the data
            file_name = f'ICE_FUT_{str(year + years_offset)[-2:]}.csv'
            # open the corresponding file (read the Dates as dates and the VOLUME as float)
            future_volumes = pd.read_csv(os.path.join(data_dir, futures_dir, file_name),
                usecols=['Date', 'OPEN', 'CLOSE', 'VOLUME'], parse_dates=['Date'])
        else :
            future_volumes = future_volumes_front
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
        # fill the NaN value of the open with the corresponding close
        selected_data['Open'] = selected_data['Open'].fillna(selected_data['Close'])
        # take the average of the open and close
        selected_data['Price'] = (selected_data['Open'] + selected_data['Close']) / 2
        # fill the NaN values of the volume with 0
        selected_data['Volume'] = selected_data['Volume'].fillna(0)
        # drop the open and close columns
        selected_data = selected_data.drop(columns=['Open', 'Close'])
        # find the dates between the last date and the previous date
        Volumes_Dec = pd.concat([Volumes_Dec, selected_data])
        # update the previous date
        prev_date = last_date

    # save the DataFrame to a csv file without the index
    if save:
        Volumes_Dec.to_csv(os.path.join(output_dir, f'Volumes_December_{years_offset}.csv'), index=False)

# if __name__ == '__main__':
preprocess_Volumes('March', save=True)
preprocess_Volumes('June', save=True)
preprocess_Volumes('September', save=True)
Volumes_dec_front = preprocess_Volumes_Dec(save=True)
preprocess_Volumes_Dec(years_offset=1, save=True)
preprocess_Volumes_Dec(years_offset=2, save=True)

# # load the data for the daily futures
# data_dir = 'Data/'
# futures_dir = 'Futures/'
# output_dir = 'Preprocessed/'

# # initialize the DataFrame
# Volumes_daily = pd.DataFrame()

# daily_price = pd.read_csv(os.path.join(data_dir, 'Daily_Future.csv'),
#     parse_dates=['Date'])

# # find only the dates
