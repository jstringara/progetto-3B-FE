import os
import datetime
from dateutil.relativedelta import relativedelta
from scipy.optimize import root_scalar
import numpy as np
import pandas as pd

# custom imports
from yearfracion import yearfrac

# Bond class
class Bond:

    # class attribute to keep track of the number of bonds that were not found
    __unfound_info = []
    # date range for the data
    __start_date = None
    __end_date = None
    # dict to hold already loaded data
    __loaded_data = {}

    def __init__(self, code, coupon_rate, maturity_date, coupon_frequency, volume, issuer):
        """
        Constructor for the Bond class.
        Input:
        - code: string with the code of the bond.
        - coupon_rate: float with the coupon rate of the bond.
        - maturity_date: datetime.date with the maturity date of the bond.
        - coupon_frequency: string with the frequency of the coupon payments.
        - issuer: string with the ticker of the issuer.
        """

        # check if the start and end dates are set
        if Bond.__start_date is None or Bond.__end_date is None:
            raise ValueError('The start and end dates are not set.')

        # save the attributes
        self.__code = code
        self.__coupon_rate = coupon_rate
        self.__maturity_date = maturity_date
        self.__coupon_frequency = coupon_frequency
        self.__issuer = issuer
        self.__volume = volume
        # load the data for the bond
        self.__data = self.load_data()
        # find the first quoted date
        self.__first_quote = self.__find_first_quote()
        # compute the coupons 
        self.__coupon_dates = self.__compute_coupon_dates()

        # if no data was found, add it to the list of unfound bonds
        if self.__data.empty:
            self.__unfound_info.append(self)

        # initialize the z-spread
        self.__z_spread = None
    
    @classmethod
    def get_unfound_info(cls):
        """
        Return the list of bonds that were not found.
        """
        return cls.__unfound_info

    @classmethod
    def set_date_range(cls, start_date:datetime.date, end_date:datetime.date)->None:
        """
        Set the date range for the data.
        Input:
        - start_date: datetime.date with the start date.
        - end_date: datetime.date with the end date.
        """
        cls.__start_date = start_date
        cls.__end_date = end_date
    
    def __repr__(self)->str:
        """
        String representation of the Bond object.
        """
        # create a table with the information of the bond
        return f"""
  --- Bond {self.__code} ---
  Coupon rate: {self.__coupon_rate}%
  Maturity date: {self.__maturity_date.strftime("%Y-%m-%d")}
  Coupon frequency: {self.__coupon_frequency} 
  Volume: {self.__volume}
  Issuer ticker: {self.__issuer}
  First quote: { self.__first_quote.strftime("%Y-%m-%d") if not pd.isnull(self.__first_quote) else 'Not found'}
  Status: {'Found' if not self.__data.empty else 'Not found'}
  Number of coupon payments: {len(self.__coupon_dates)}
  Coupon dates: {" ".join([date.strftime('%Y-%m-%d') for date in self.__coupon_dates])}
  -------------------
  """

    def is_empty(self)->bool:
        """
        Check if the data of the bond is empty.
        """
        return self.__data.empty
    
    # magic method for the length of the bond
    def __len__(self)->int:
        """
        Get the length of the bond.
        """
        return len(self.__data)
    
    def load_data(self)->pd.DataFrame:
        """
        Load the data for the bond from the csv file of the parent company.
        """
        # load the data for the parent company
        data_dir = '../Data/'
        bonds_dir = 'Bonds/'

        # check if the data was already loaded
        if self.__issuer in self.__loaded_data:
            parent_data = self.__loaded_data[self.__issuer]
        # otherwise, load the data and save it
        else:
            parent_data = pd.read_csv(os.path.join(data_dir, bonds_dir, f'{self.__issuer}.csv'),
                parse_dates=['Date'], dayfirst=False)
            # drop the first and second columns
            parent_data = parent_data.drop(columns=[parent_data.columns[0], parent_data.columns[1]])
            self.__loaded_data[self.__issuer] = parent_data

        # try to extract the data
        out_df = pd.DataFrame()
        try:
            out_df = parent_data[['Date', self.__code]]
            # select only the dates that are in the range
            out_df = out_df.loc[out_df['Date'] > self.__start_date]
            out_df = out_df.loc[out_df['Date'] < self.__end_date]
        except KeyError:
            # add it to the unfound bonds
            self.__unfound_info.append(self)

        # if the data is empty, raise an error
        try:
            if out_df.empty:
                raise ValueError('The data is empty.')
        except ValueError as e:
            # put it into the list of unfound bonds
            self.__unfound_info.append(self)
        
        # reindex the data
        out_df = out_df.reset_index(drop=True)

        return out_df

    def __find_first_quote(self)->datetime.date:
        """
        Find the first date where the bond was quoted.
        """
        # if the data is empty, return None
        if self.__data.empty:
            return None
        # find the first date where the bond was quoted
        first_quote = self.__data.loc[self.__data[self.__code].notnull(), 'Date'].min()
        return first_quote
    
    def __compute_coupon_dates(self)->list[datetime.date]:
        """
        Compute the dates of the coupon payments using the frequency of the coupon and the maturity date.
        """

        if pd.isnull(self.__first_quote):
            return []

        # find the time difference between coupons (in months)
        time_step = relativedelta(months = 12 // int(self.__coupon_frequency))

        # compute the coupon dates
        coupon_dates = []
        i = 0
        while self.__maturity_date - i * time_step > self.__first_quote:
            coupon_dates.append(self.__maturity_date - i * time_step)
            i += 1

        # sort the coupon dates
        coupon_dates.sort()

        # if there are no coupon dates, add the maturity date
        if not coupon_dates:
            coupon_dates.append(self.__maturity_date)

        return coupon_dates

    def code(self)->str:
        """
        Return the code of the bond.
        """
        return self.__code

    def issuer(self)->str:
        """
        Return the issuer of the bond.
        """
        return self.__issuer

    def show_data(self)->None:
        """
        Show the data of the bond.
        """
        print(self.__data)

    def filter_data(self, dates:pd.Series)->None:
        """
        Filter the data of the bond to only keep the dates in the list.
        Input:
        - dates: Series with the dates to keep.
        Output:
        - DataFrame with the filtered data.
        """
        self.__data = self.__data.loc[self.__data['Date'].isin(dates)]

    def __compute_cash_flows(self, target_date:datetime.date)->pd.DataFrame:
        """
        Compute the cash flows of the bond at the target date.
        """

        # filter the coupon dates, only keep ones after the target date
        coupon_dates = [target_date] + [
            date
            for date in self.__coupon_dates
            if date >= target_date
        ]

        # compute the cash flows
        cash_flows = [
            self.__coupon_rate * yearfrac(date, coupon_dates[i+1], 'EU_30_360')
            for i, date in enumerate(coupon_dates[:-1])
        ]

        # add the principal
        cash_flows[-1] += 100

        return pd.DataFrame({
            'Date': coupon_dates[1:],
            'Cash Flow': cash_flows
        })

    def z_spread(self, bootstrapper)->pd.DataFrame:
        """
        Compute the Z-spread of the bond.
        Input:
        - bootstrapper: Bootstrapper object with the OIS rates.
        """

        # if already computed, return
        if self.__z_spread is not None:
            return self.__z_spread

        z_spread = pd.DataFrame()
        z_spread['Date'] = self.__data['Date']

        # wherever we don't have data, we put 0 (float)
        z_spread[self.__code] = 0.0

        # pad the zero rates. HACK this relies on pseudo-private method
        yf = bootstrapper._Bootstrap__pad_yf(self.__data['Date'])
        zero_rates = bootstrapper._Bootstrap__pad_zero_rates(self.__data['Date'])

        # iterate over the data
        for i, row in self.__data.dropna().iterrows():

            target_date = row['Date']

            # compute the cash flows
            cash_flows = self.__compute_cash_flows(target_date)

            # compute the dates
            x = yearfrac(target_date, cash_flows['Date'], 'ACT_365').values.astype(float)

            # check that the max be less than 0.0075
            if np.max(x) < 0.075:
                continue

            # get the zero rates for the date
            xp = yf[yf['Date'] == target_date].iloc[0, 1:].values.astype(float)
            fp = zero_rates[zero_rates['Date'] == target_date].iloc[0, 1:].values.astype(float)

            # interpolate the zero rates
            f = np.interp(x, xp, fp)

            # find the previous value of the z-spread
            try:
                prev_z = z_spread[z_spread['Date'] < target_date].iloc[-1, 1]
            except IndexError: # catch in case we have to start from the first date
                prev_z = 0.0

            # find the z-spread that makes the price equal to the bond price
            z = root_scalar(lambda z:
                np.sum(cash_flows['Cash Flow'].values * np.exp( (-z -f) * x)) 
                -
                row[self.__code],
                x0 = prev_z, x1 = prev_z + 0.01, method='secant'
            ).root

            z_spread.loc[z_spread['Date'] == target_date, self.__code] = z

        # rename the column
        z_spread = z_spread.rename(columns={self.__code: 'Z-spread'})
        # add the volume
        z_spread['Volume'] = self.__volume * (z_spread['Z-spread'] != 0).astype(int)
        
        # save the z-spread
        self.__z_spread = z_spread

        return z_spread
    