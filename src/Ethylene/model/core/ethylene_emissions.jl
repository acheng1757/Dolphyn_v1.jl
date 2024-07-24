"""
DOLPHYN: Decision Optimization for Low-carbon Power and Hydrogen Networks
Copyright (C) 2022,  Massachusetts Institute of Technology
This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.
This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.
A complete copy of the GNU General Public License v2 (GPLv2) is available
in LICENSE.txt.  Users uncompressing this from an archive may not have
received this license file.  If not, see <http://www.gnu.org/licenses/>.
"""

@doc raw"""
    ng_emissions(EP::Model, inputs::Dict, setup::Dict)

This function creates expression to add the CO2 emissions for natural gas supply chain in each zone, which is subsequently added to the total emissions. 

These include emissions from synthetic natural gas production (if any), as well as combustion of each type of conventional and synthetic natural gas.
"""
function ethylene_emissions(EP::Model, inputs::Dict, setup::Dict)

	println(" -- CO2 Emissions Module for Ethylene")

    ConventionalSC_ethylene_co2_per_tonneethylene = inputs["ConventionalSC_ethylene_co2_per_tonneethylene"]
    Consumption_ethylene_co2_per_tonneethylene= inputs["Consumption_ethylene_co2_per_tonneethylene"]
    

    T = inputs["T"]     # Number of time steps (hours)
	Z = inputs["Z"]     # Number of zones

    if setup["ModelEthylenePurchase"] == 1	
    ##########################################################
    ##CO2 emitted as a result of conventional Ethylene Purchase Consumption
        @expression(EP,eConv_Ethylene_CO2_Emissions[z=1:Z,t=1:T], 
        Consumption_ethylene_co2_per_tonneethylene * EP[:vConv_Ethylene_Demand][t,z])
    end
      
    ######################################################################
    ##CO2 emitted as a result of Ethylene production and consumption

    if setup["ModelEthyleneProduction"] == 1

        dfEthylene = inputs["dfEthylene"]
        Ethylene_RES_ALL = inputs["Ethylene_RES_ALL"]

        tonne_co2_p_tonne_ethane = dfEthylene[!,:tonne_co2_p_tonne_ethane] 
        ConventionalSC_ethylene_co2_per_tonneethylene = inputs["ConventionalSC_ethylene_co2_per_tonneethylene"]
        Consumption_ethylene_co2_per_tonneethylene = inputs["Consumption_ethylene_co2_per_tonneethylene"]
        # tonne_co2_p_tonne_ethane = inputs["tonne_co2_p_tonne_ethane"]

        #CO2 emitted as a result of Ethylene Production
        

        #@expression(EP,eEthylene_CO2_Emissions_By_Plant[k=1:Ethylene_RES_ALL,t=1:T], 
        #Consumption_ethylene_co2_per_tonneethylene * EP[:eEthylene_Prod_Plant][k,t])

        @expression(EP,eEthylene_CO2_Emissions_By_Plant[k=1:Ethylene_RES_ALL,t=1:T], 
        tonne_co2_p_tonne_ethane[k] * EP[:vEthylene_ethanein][k,t])

        @expression(EP,eEthylene_CO2_Emissions_By_Zone[z = 1:Z,t=1:T], 
        sum(eEthylene_CO2_Emissions_By_Plant[k,t] for k in dfEthylene[(dfEthylene[!,:Zone].==z),:R_ID]))

        ##########################################################################
        #Plant CO2 emissions per type of resource (Ethylene emissions) --- Before CCS
        @expression(EP,eEthylene_CO2_Production_By_Plant[k=1:Ethylene_RES_ALL,t=1:T], 
        EP[:eEthylene_CO2_Emissions_By_Plant][k,t])

        ##########################################################################
        #Plant CO2 captured per type of resource defined by CCS rate (Add to captured CO2 balance)
        @expression(EP,eEthylene_CO2_Captured_By_Res[k=1:Ethylene_RES_ALL,t=1:T], 
        dfEthylene[!,:CCS_Rate][k] * EP[:eEthylene_CO2_Production_By_Plant][k,t])

        #Total CO2 capture per zone per time
        @expression(EP, eEthylene_CO2_Capture_Per_Zone_Per_Time[z=1:Z, t=1:T], 
        sum(eEthylene_CO2_Captured_By_Res[k,t] for k in dfEthylene[(dfEthylene[!,:Zone].==z),:R_ID]))

        @expression(EP, eEthylene_CO2_Capture_Per_Time_Per_Zone[t=1:T, z=1:Z], 
        sum(eEthylene_CO2_Captured_By_Res[k,t] for k in dfEthylene[(dfEthylene[!,:Zone].==z),:R_ID]))

        #ADD TO CO2 BALANCE
        EP[:eCaptured_CO2_Balance] += EP[:eEthylene_CO2_Capture_Per_Time_Per_Zone]

        ##########################################################################
        #Plant CO2 emitted per type of resource --- After CCS (Add to CO2 cap policy)
        @expression(EP,eEthylene_CO2_Emissions_By_Res[k=1:Ethylene_RES_ALL,t=1:T], 
        (1 - dfEthylene[!,:CCS_Rate][k]) * EP[:eEthylene_CO2_Production_By_Plant][k,t])

        @expression(EP, eEthylene_Production_CO2_Emissions_By_Zone[z=1:Z, t=1:T], 
        sum(eEthylene_CO2_Emissions_By_Res[k,t] for k in dfEthylene[(dfEthylene[!,:Zone].==z),:R_ID]))


    end

    return EP
end
