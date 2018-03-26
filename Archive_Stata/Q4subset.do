keep if inlist(indicator, "HTC_TST", "HTC_TST_POS", "OVC_SERV", "TX_NET_NEW", "TX_NEW", "VMMC_CIRC")
drop facilityuid facilityprioritization

egen fy2016cumq3 = rowtotal(fy2016q1 fy2016q2 fy2016q3)
order fy2016cumq3, after(fy2016q3)
