import pandas as pd
import os
import datetime

# Bond class
class Bond:

    # class attribute to keep track of the number of bonds that were not found
    __unfound_info = []
    # class attribute (we only want data for Phase III)
    __start_date = datetime.datetime(2013, 1, 1)
    __end_date = datetime.datetime(2021, 12, 31)

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
        # find the first quoted date
        self.__first_quote = self.__find_first_quote()
        # compute the coupons 
        self.__coupon_dates = self.__compute_coupon_dates()

        # if no data was found, add it to the list of unfound bonds
        if self.__data.empty:
            self.__unfound_info.append(self)
    
    @classmethod
    def get_unfound_info(cls):
        """
        Return the list of bonds that were not found.
        """
        return cls.__unfound_info
    
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
  Issuer ticker: {self.__issuer_ticker}   
  Parent ticker: {self.__parent_ticker}
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
        data_dir = 'Data/'
        bonds_dir = 'Bonds/'

        parent_data = pd.read_csv(os.path.join(data_dir, bonds_dir, f'{self.__parent_ticker}.csv'),
            parse_dates=['Date'], dayfirst=False)
        # drop the first and second columns
        parent_data = parent_data.drop(columns=[parent_data.columns[0], parent_data.columns[1]])

        # try to extract the data
        out_df = pd.DataFrame()
        try:
            out_df = parent_data[['Date', self.__code]]
            # select only the dates that are in the range of the bond
            out_df = out_df.loc[out_df['Date'] >= self.__start_date]
            out_df = out_df.loc[out_df['Date'] <= self.__end_date]
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

        # compute the time difference (expressed in months) between the first quote and the maturity date
        time_diff = self.__maturity_date.to_period('M') - self.__first_quote.to_period('M')
        time_diff = time_diff.n

        # find the time difference between coupons (in months)
        coupon_time_diff = 12 // self.__coupon_frequency

        # compute the number of coupons that are paid over the life of the bond
        num_coupons = time_diff // coupon_time_diff

        # compute the coupon dates
        coupon_dates = [
            self.__maturity_date - pd.DateOffset(months=coupon_time_diff * i)
            for i in reversed(range(num_coupons))
        ]
        coupon_dates.sort()

        # # move to business days if the date is not a business day
        # for i, date in enumerate(coupon_dates):
        #     if date.weekday() in [5, 6]:
        #         coupon_dates[i] = date - pd.DateOffset(weekday=0)

        return coupon_dates

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

    def to_matlab_cellarray(self)->dict:
        """
        Convert the data of the bond to a Matlab cell array.
        """
        # convert the data to a dictionary
        data_dict = {
            'Code': self.__code,
            'CouponRate': self.__coupon_rate,
            'MaturityDate': self.__maturity_date.strftime('%Y-%m-%d'),
            'CouponFrequency': self.__coupon_frequency,
            'IssuerTicker': self.__issuer_ticker,
            'ParentTicker': self.__parent_ticker,
            'FirstQuote': self.__first_quote.strftime('%Y-%m-%d') if not pd.isnull(self.__first_quote) else '',
            'CouponDates': [date.strftime('%Y-%m-%d') for date in self.__coupon_dates],
            'Dates': self.__data['Date'].dt.strftime('%Y-%m-%d').tolist(),
            'Prices': self.__data[self.__code]
        }

        return data_dict

