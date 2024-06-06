import datetime
import pandas as pd
import numpy as np

class Z_spread:
    """
    Z-spread class
    """

    def __init__(self, bonds, Bootstrapper):

        # save the bonds
        self.__bonds = bonds

        # aggregate the bonds by issuer
        self.__aggregate_bonds_by_issuer()

        # save the Bootstrapper object
        self.__Bootstrapper = Bootstrapper

        # Z-spread by issuer
        self.__z_spreads_by_issuer = None

        # Z-spread
        self.__z_spread = None

    def __aggregate_bonds_by_issuer(self)->None:
        """
        Aggregate the bonds by issuer
        """

        self.__bonds_by_issuer = {}

        # cycle over the bonds and aggregate by issuer
        for bond in self.__bonds:

            issuer = self.__bonds[bond].issuer()

            # initialize the list of bonds for the issuer
            if issuer not in self.__bonds_by_issuer:
                self.__bonds_by_issuer[issuer] = []

            self.__bonds_by_issuer[issuer].append(self.__bonds[bond])
    
    def __compute_by_issuer(self)->None:
        """
        Compute the Z-spread by issuer
        """

        z_spreads_by_issuer = {}

        # cycle over the issuers
        for issuer in self.__bonds_by_issuer:

            # initialize the z_spread of the issuer
            z_spread = pd.DataFrame(columns=['Z-spread', 'Volume Traded'])
            z_spread['Z-spread'] = np.zeros(len(self.__bonds_by_issuer[issuer][0].dates()))
            z_spread['Volume Traded'] = np.zeros(len(self.__bonds_by_issuer[issuer][0].dates()))

            print(f'Computing Z-spread for issuer {issuer}')
            print(z_spread.shape)

            # get the list of bonds for the issuer
            bonds = self.__bonds_by_issuer[issuer]

            for bond in bonds:

                t0 = datetime.datetime.now()
                z_spread_bond = bond.z_spread(self.__Bootstrapper)
                t1 = datetime.datetime.now()
                print(f'{bond.code()}: {t1 - t0} seconds')

                # multiply by the Volume
                z_spread['Z-spread'] += z_spread_bond['Z-spread'].values * z_spread_bond['Volume'].values
                z_spread['Volume Traded'] += z_spread_bond['Volume'].values
            
            # normalize the Z-spread by the Volume traded (in case the Volume is 0, set the Z-spread to 0)
            z_spread['Z-spread'] /= z_spread['Volume Traded']
            z_spread['Z-spread'] = z_spread['Z-spread'].fillna(0)

            z_spreads_by_issuer[issuer] = z_spread['Z-spread'].values
        
        # add the date
        z_spreads_by_issuer['Date'] = self.__bonds_by_issuer[issuer][0].dates().values

        self.__z_spreads_by_issuer = pd.DataFrame(data=z_spreads_by_issuer)

    def compute(self):
        """
        Compute the Z-spread for the bonds.
        """

        if self.__z_spreads_by_issuer is not None:
            return

        t0 = datetime.datetime.now()

        # compute the Z-spread by issuer
        self.__compute_by_issuer()

        # sum the Z-spreads and normalize by the number of issuers trading that day
        self.__z_spread = pd.DataFrame(columns=['Date', 'Z-spread'])

        self.__z_spread['Z-spread'] = self.__z_spreads_by_issuer.drop(columns=['Date']).apply(
            lambda x: np.sum(x) / np.count_nonzero(x), axis=1
        )

        self.__z_spread['Date'] = self.__z_spreads_by_issuer['Date'].values

        t1 = datetime.datetime.now()

        # print the time taken to compute the Z-spread in seconds
        print(f'Time taken to compute the Z-spread: {t1 - t0} seconds')


