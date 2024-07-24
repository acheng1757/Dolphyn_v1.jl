"""
DOLPHYN: Decision Optimization for Low-carbon for Power and Hydrogen Networks
Copyright (C) 2021,  Massachusetts Institute of Technology
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
    syn_ng_resources(EP::Model, inputs::Dict, setup::Dict)

This module creates decision variables, expressions, and constraints related to synthetic gas resources.

This module defines the power consumption decision variable $x_{f,t}^{\textrm{E,Syn}} \forall f\in \mathcal{F}, t \in \mathcal{T}$, representing power consumed by synthetic gas resource $f$ at time period $t$.

The variable defined in this file named after ```vSyn_NG_Power_in``` cover variable $x_{f,t}^{E,Syn}$.

This module defines the hydrogen consumption decision variable $x_{f,t}^{\textrm{H,Syn}} \forall f\in \mathcal{F}, t \in \mathcal{T}$, representing hydrogen consumed by synthetic gas resource $f$ at time period $t$.

The variable defined in this file named after ```vSyn_NG_H2in``` cover variable $x_{f,t}^{H,Syn}$.

This module defines the synthetic gasoline, jetgas, and diesel production decision variables $x_{f,t}^{\textrm{Gasoline,Syn}} \forall f\in \mathcal{F}, t \in \mathcal{T}$, $x_{f,t}^{\textrm{Jetgas,Syn}} \forall f\in \mathcal{F}, t \in \mathcal{T}$, $x_{f,t}^{\textrm{Diesel,Syn}} \forall f\in \mathcal{F}, t \in \mathcal{T}$ representing  synthetic gasoline, jetgas, and diesel produced by resource $f$ at time period $t$.

The variables defined in this file named after ```vSyn_NG_Prod_Gasoline``` cover variable $x_{f,t}^{Gasoline,Syn}$, ```vSyn_NG_Prod_Jetgas``` cover variable $x_{f,t}^{Jetgas,Syn}$, and ```vSyn_NG_Prod``` cover variable $x_{f,t}^{Diesel,Syn}$.

**Maximum CO2 input to synthetic gas resource**

```math
\begin{equation*}
	x_{f,t}^{\textrm{C,Syn}} \leq  y_{f}^{\textrm{C,Syn}} \quad \forall f \in \mathcal{F}, t \in \mathcal{T}
\end{equation*}
```
"""
function ethylene_production_resources(EP::Model, inputs::Dict, setup::Dict)

	println(" -- Ethylene Production Resources")
	# @expression(EP, eEthyleneBalance[t=1:T, z=1:Z], 0)
	dfEthylene = inputs["dfEthylene"]
    
	T = inputs["T"]     # Number of time steps (hours)
	Z = inputs["Z"]     # Number of zones

	Ethylene_RES_ALL = inputs["Ethylene_RES_ALL"]

	####Variables####
	#Define variables needed across both commit and no commit sets
    
    #Amount of Ethylene Produced in tonne
	@variable(EP, vEthylene_Prod[k = 1:Ethylene_RES_ALL, t = 1:T] >= 0 )

    #Power Required by Ethylene Resource
    @variable(EP, vEthylene_Power_in[k = 1:Ethylene_RES_ALL, t = 1:T] >= 0 )

    #Hydrogen Produced by Ethylene Resource
    @variable(EP, vEthylene_H2out[k = 1:Ethylene_RES_ALL, t = 1:T] >= 0 )

	#Natural Gas Consumed Ethylene Production Resource
	@variable(EP, vEthylene_NG_in[k = 1:Ethylene_RES_ALL, t = 1:T] >= 0 )
	

	#################################################################################################################

	###Expressions###
	@expression(EP, eEthylene_Prod_Plant[k = 1:Ethylene_RES_ALL, t=1:T], vEthylene_Prod[k,t])

    # Ethylene Balance Expression
    @expression(EP, eEthylene_Prod[t=1:T, z=1:Z],
		sum(EP[:eEthylene_Prod_Plant][k,t] for k in intersect(1:Ethylene_RES_ALL, dfEthylene[dfEthylene[!,:Zone].==z,:][!,:R_ID])))


	EP[:eEthyleneBalance] += eEthylene_Prod
	

	##################################################################################################################


	#Power Balance Expression

	#@expression(EP, eEthylene_NG_Cons_cost[t=1:T, z=1:Z],
	# 	sum(EP[:vEthylene_Power_in][k,t] for k in intersect(1:Ethylene_RES_ALL, dfEthylene[dfEthylene[!,:Zone].==z,:][!,:R_ID]))) 



	@expression(EP, eEthylene_Power_Cons[t=1:T, z=1:Z],
		sum(EP[:vEthylene_Power_in][k,t] for k in intersect(1:Ethylene_RES_ALL, dfEthylene[dfEthylene[!,:Zone].==z,:][!,:R_ID]))) 

	EP[:ePowerBalance] += -eEthylene_Power_Cons
		
	#Power consumption associated with Ethylene Production in each time step 
	@constraints(EP, begin
	[k in 1:Ethylene_RES_ALL, t = 1:T], EP[:vEthylene_Power_in][k,t] == EP[:vEthylene_ethanein][k,t] * dfEthylene[!,:mwh_p_tonne_ethane][k]
	end)

	##################################################################################################################

	# Hydrogen Balance Expression
	@expression(EP, eEthylene_H2_Prod[t=1:T, z=1:Z],
	sum(EP[:vEthylene_H2out][k,t] for k in intersect(1:Ethylene_RES_ALL, dfEthylene[dfEthylene[!,:Zone].==z,:][!,:R_ID])))

	EP[:eH2Balance] += eEthylene_H2_Prod

	# Hydrogen Production
	@constraints(EP, begin
	[k in 1:Ethylene_RES_ALL, t = 1:T], EP[:vEthylene_H2out][k,t] == EP[:vEthylene_ethanein][k,t] * dfEthylene[!,:tonnes_h2_p_tonne_ethane][k]
	end)
	
	################################################################################################################

	# Natural Gas Balance Expression

	@expression(EP, eEthylene_NG_Cons[t=1:T, z=1:Z],
	sum(EP[:vEthylene_NG_in][k,t] for k in intersect(1:Ethylene_RES_ALL, dfEthylene[dfEthylene[!,:Zone].==z,:][!,:R_ID])))

	EP[:eNGBalance] -= eEthylene_NG_Cons

	# NG usage
	@constraints(EP, begin 
	[k in 1:Ethylene_RES_ALL, t = 1:T], EP[:vEthylene_NG_in][k,t] == EP[:vEthylene_ethanein][k,t] * dfEthylene[!,:mmbtu_ng_p_tonne_ethane][k]
	end)

	# Cost of Natural Gas consumed in Ethylene Production

	@expression(EP,eNG_Cons_cost_per_time[k in 1:Ethylene_RES_ALL, t = 1:T], EP[:vEthylene_NG_in][k,t]*dfEthylene[!,:ng_cost_p_mmbtu_ng][k])

	@expression(EP,eNG_Cons_cost_per_type[k in 1:Ethylene_RES_ALL], sum(EP[:eNG_Cons_cost_per_time][k,t] for t in 1:T))

	@expression(EP,eNG_Cons_cost, sum(EP[:eNG_Cons_cost_per_type][k] for k in 1:Ethylene_RES_ALL))
	# Add term to objective function expression
	EP[:eObj] += EP[:eNG_Cons_cost]


	###Constraints###
	
	# Ethylene Production Equal to Ethane in * Conversion factor 
	@constraints(EP, begin 
	[k in 1:Ethylene_RES_ALL, t = 1:T], EP[:vEthylene_Prod][k,t] == EP[:vEthylene_ethanein][k,t] * dfEthylene[!,:tonne_ethylene_p_tonne_ethane][k]
	end)

	

    # Production must be smaller than available capacity
	@constraints(EP, begin 
	[k in 1:Ethylene_RES_ALL, t=1:T], EP[:vEthylene_Prod][k,t] <= EP[:vCapacity_Ethylene_per_type][k] 
	end)
	
	return EP
end
