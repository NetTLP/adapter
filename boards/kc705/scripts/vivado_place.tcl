open_checkpoint post_syn.dcp

opt_design
power_opt_design
place_design

report_utilization -file post_place_util.txt
report_timing -file post_place_timing.txt -nworst 5
write_checkpoint -force post_place
