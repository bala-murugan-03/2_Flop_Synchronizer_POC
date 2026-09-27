# Primary 125MHz board clock on PYNQ-Z2 (Pin H16)
create_clock -period 8.000 -name clk_a [get_ports clk_a]

# Secondary asynchronous virtual or routed clock
create_clock -period 6.802 -name clk_b [get_ports clk_b]

# Declare Domain A and Domain B as mutually asynchronous
set_clock_groups -asynchronous -group [get_clocks clk_a] -group [get_clocks clk_b]