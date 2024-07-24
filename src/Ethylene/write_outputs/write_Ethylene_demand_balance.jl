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
	write_ng_demand_balance(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

Function for reporting the natural gas balance of resources across different zones with time for each type of fuels.
"""
function write_Ethylene_demand_balance(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)
	
	T = inputs["T"]     # Number of time steps (hours)
	Z = inputs["Z"]     # Number of zones

	###########################################################################################
	## Ethylene balance for each zone
	dfEthyleneBalance = Array{Any}
	rowoffset=3

	for z in 1:Z
		dfTemp1_Ethylene = Array{Any}(nothing, T+rowoffset, 4)
		dfTemp1_Ethylene[1,1:size(dfTemp1_Ethylene,2)] = ["Ethylene_Purchase", "CSC_Ethylene", "CSC_CCS_Ethylene", "Ethylene_Demand"]
		dfTemp1_Ethylene[2,1:size(dfTemp1_Ethylene,2)] = repeat([z],size(dfTemp1_Ethylene,2))

		for t in 1:T

			dfTemp1_Ethylene[t+rowoffset,1] = 0
			dfTemp1_Ethylene[t+rowoffset,2] = 0
			dfTemp1_Ethylene[t+rowoffset,3] = 0
			dfTemp1_Ethylene[t+rowoffset,4] = 0
			
			if setup["ModelEthylenePurchase"] == 1
            	dfTemp1_Ethylene[t+rowoffset,1] = value.(EP[:vConv_Ethylene_Demand][t,z])
			end

			
			# dfTemp1_Ethylene[t+rowoffset,4] = value.(EP[:eEthylene_Prod_Plant][4,t]) # 0
			# dfTemp1_Ethylene[t+rowoffset,5] = 0
			if setup["ModelEthyleneProduction"] == 1
				dfTemp1_Ethylene[t+rowoffset,2] = value.(EP[:eEthylene_Prod_Plant][2*z-1,t]) # value.(EP[:eEthylene_Prod][t,z])
				dfTemp1_Ethylene[t+rowoffset,3] = value.(EP[:eEthylene_Prod_Plant][2*z,t]) 
			end

			dfTemp1_Ethylene[t+rowoffset,4] = -inputs["Ethylene_Demand"][t,z]
			


		end

		if z==1
			dfEthyleneBalance =  hcat(vcat(["", "Zone", "AnnualSum"], ["t$t" for t in 1:T]), dfTemp1_Ethylene)
		else
			dfEthyleneBalance = hcat(dfEthyleneBalance, dfTemp1_Ethylene)
		end
	end

	for c in 2:size(dfEthyleneBalance,2)
		dfEthyleneBalance[rowoffset,c]=sum(inputs["omega"].*dfEthyleneBalance[(rowoffset+1):size(dfEthyleneBalance,1),c])
		
	end

	dfEthyleneBalance = DataFrame(dfEthyleneBalance, :auto)
	
	CSV.write(string(path,sep,"Ethylene_Balance.csv"), dfEthyleneBalance, writeheader=false)

end
