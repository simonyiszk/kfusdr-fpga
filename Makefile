workdir := ./workdir

simulate_uart :
	ghdl -a --workdir=$(workdir) uart.vhd tb_uart.vhd
	ghdl --elab-run --workdir=$(workdir) tb_uart --wave=$(workdir)/wave.ghw --assert-level=error

view_uart : simulate_uart
	gtkwave $(workdir)/wave.ghw

simulate_top :
	ghdl -a --workdir=$(workdir) uart.vhd top.vhd tb_top.vhd
	ghdl --elab-run --workdir=$(workdir) tb_top --wave=$(workdir)/wave.ghw --assert-level=error

view_top : simulate_top
	gtkwave $(workdir)/wave.ghw
