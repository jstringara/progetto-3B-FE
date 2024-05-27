function Z_spread = compute_ZSpread(Bonds, dates, zrates)
% COMPUTE_ZSPREAD Compute the Z-Spreads for the bonds
%
% INPUTS
% - Bonds: the bonds [cell array]
% - dates: the dates [matrix]
% - zrates: the zero rates [matrix]

% if the z-spreads file already exist, load it and return
if isfile('Z_Spreads.mat')
    load('Z_Spreads.mat');
    return
end

% start a waitbar
h = waitbar(0, 'Computing the Z-Spreads');
tot = length(Bonds);

% group the bonds by issuer
Bonds_By_Issuer = struct;

for i = 1:length(Bonds)
    % compute the Z-Spread for the bond
    Bonds{i}.Z_Spreads = compute_ZSpread_Bond(Bonds{i}, dates, zrates);
    % update the waitbar
    waitbar(i/tot, h, ['Computing the Z-Spreads: ', num2str(i/tot*100), '%'])
    
    % add the bond to the issuer in the struct
    if isfield(Bonds_By_Issuer, Bonds{i}.Issuer)
        Bonds_By_Issuer.(Bonds{i}.Issuer){end+1} = Bonds{i};
    else
        Bonds_By_Issuer.(Bonds{i}.Issuer) = {Bonds{i}};
    end
end
% close the waitbar
close(h);

% Compute the Z-Spread for each issuer

% create a table to store the Z-Spreads
Z_spread = table(Bonds{1}.Dates, zeros(size(Bonds{1}.Dates)), ...
    'VariableNames', {'Date', 'Z_Spread'});
  
% number of issuers active for each date
total_issuers_active = zeros(size(Bonds{1}.Dates));

% iterate over the fields of the struct (the issuers)
for issuer = fields(Bonds_By_Issuer)'

    % get the bonds of the issuer
    bonds = Bonds_By_Issuer.(issuer{1});

    % compute the total volume of bonds traded for each date
    total_volume = zeros(size(Bonds{1}.Dates));
    Z_spread_issuer = zeros(size(Bonds{1}.Dates));
    for j = 1:length(bonds)
        % exclude bond with code "XS0877820422" (it has NaN values)
        if bonds{j}.Code == "XS0877820422"
            continue
        end
        Z_spread_issuer = Z_spread_issuer + bonds{j}.Volume .* bonds{j}.Z_Spreads;
        total_volume = total_volume + bonds{j}.Volume .* (bonds{j}.Z_Spreads ~= 0);
    end

    % normalize the Z-Spreads of the issuer by the total volume
    Z_spread_issuer = Z_spread_issuer ./ total_volume;
    % fill the NaN values (no bonds traded)
    Z_spread_issuer(isnan(Z_spread_issuer)) = 0;
    % add the Z-Spreads to the table
    Z_spread.Z_Spread = Z_spread.Z_Spread + Z_spread_issuer;
    % add the number of active issuers
    total_issuers_active = total_issuers_active + (total_volume ~= 0);
end

% normalize the Z-Spreads by the number of issuers
Z_spread.Z_Spread = Z_spread.Z_Spread ./ total_issuers_active;
Z_spread.Z_Spread(isnan(Z_spread.Z_Spread)) = 0;

% save the Z-Spreads
save('Z_Spreads.mat', 'Z_spread');

end