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
	write_ng_emissions(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

Function for reporting CO2 emissions of natural gas types across different zones.
"""
function write_ethylene_emissions(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

	T = inputs["T"]     # Number of time steps (hours)
	Z = inputs["Z"]     # Number of zones

	## Emission balance for each zone
	dfEthyleneEmissionBalance = Array{Any}

	rowoffset=3
	for z in 1:Z
	   	dfTemp1 = Array{Any}(nothing, T+rowoffset, 3)
	   	dfTemp1[1,1:size(dfTemp1,2)] = vcat(["Ethylene_Purchase_Emissions", "CSC_Ethylene_Emissions", "CSC_CCS_Ethylene_Emissions"])
	   	dfTemp1[2,1:size(dfTemp1,2)] = repeat([z],size(dfTemp1,2))

		for t in 1:T

			dfTemp1[t+rowoffset,1] = 0
			dfTemp1[t+rowoffset,2] = 0
			dfTemp1[t+rowoffset,3] = 0
			# dfTemp1[t+rowoffset,4] = 0
			if setup["ModelEthylenePurchase"] == 1
            	dfTemp1[t+rowoffset,1] = value.(EP[:eConv_Ethylene_CO2_Emissions][z,t])
			end
			
			

			if setup["ModelEthyleneProduction"] == 1
				dfTemp1[t+rowoffset,2] = value.(EP[:eEthylene_CO2_Emissions_By_Res][2*z-1,t])
				dfTemp1[t+rowoffset,3] = value.(EP[:eEthylene_CO2_Emissions_By_Res][2*z,t]) 
				# dfTemp1[t+rowoffset,2] = value.(EP[:eEthylene_Production_CO2_Emissions_By_Zone][z,t])
				# dfTemp1[t+rowoffset,3] = value.(EP[:eEthylene_CO2_Capture_Per_Zone_Per_Time][z,t])
				# dfTemp1[t+rowoffset,4] = value.(EP[:eEthylene_CO2_Emissions_By_Zone][z,t])
			end
			
		end

		if z==1
			dfEthyleneEmissionBalance =  hcat(vcat(["", "Zone", "AnnualSum"], ["t$t" for t in 1:T]), dfTemp1)
		else
		    dfEthyleneEmissionBalance = hcat(dfEthyleneEmissionBalance, dfTemp1)
		end
	end

	for c in 2:size(dfEthyleneEmissionBalance,2)
		dfEthyleneEmissionBalance[rowoffset,c]=sum(inputs["omega"].*dfEthyleneEmissionBalance[(rowoffset+1):size(dfEthyleneEmissionBalance,1),c])
	end

	dfEthyleneEmissionBalance = DataFrame(dfEthyleneEmissionBalance, :auto)
	CSV.write(string(path,sep,"Ethylene_Emissions_Balance.csv"), dfEthyleneEmissionBalance, writeheader=false)

end