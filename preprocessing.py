import os
import datetime
import pandas as pd

def preprocess_Volumes(month:str, save:bool = True)->pd.DataFrame:
    """
    Function to preprocess the data of the volumes of the futures contracts in a given month.
    Month can be either 'March', 'June', 'September'.
    Output is a DataFrame with the columns 'Date' and 'Volume'.
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

def preprocess_Volumes_Dec(save:bool = True)->pd.DataFrame:
    """
    Function to preprocess the data of the volumes of the futures contracts in December.
    Output is a DataFrame with the columns 'Date' and 'Volume'.
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
        future_volumes = pd.read_csv(os.path.join(data_dir, futures_dir, file_name),
            usecols=['Date', 'VOLUME'], parse_dates=['Date'], dtype={'VOLUME': float})
        # find the last quoted date as the last date where there is a value in the column
        last_date = future_volumes.loc[future_volumes['VOLUME'].notnull(), 'Date'].max()
        # bring it back a month
        # last_date = last_date - pd.DateOffset(months=1)
        # select the needed data
        selected_data = future_volumes.loc[future_volumes['Date'] > prev_date].loc[
            future_volumes['Date'] <= last_date, ['Date', 'VOLUME']]
        # select only the date and the volume
        selected_data = selected_data[['Date', 'VOLUME']]
        selected_data.columns = ['Date', 'Volume']
        # fill the NaN values with 0
        selected_data['Volume'] = selected_data['Volume'].fillna(0)
        # find the dates between the last date and the previous date
        Volumes_Dec = pd.concat([Volumes_Dec, selected_data])
        # update the previous date
        prev_date = last_date

    # save the DataFrame to a csv file without the index
    if save:
        Volumes_Dec.to_csv(os.path.join(output_dir, 'Volumes_December.csv'), index=False)

if __name__ == '__main__':
    preprocess_Volumes('March', save=True)
    preprocess_Volumes('June', save=True)
    preprocess_Volumes('September', save=True)
    preprocess_Volumes_Dec(save=True)