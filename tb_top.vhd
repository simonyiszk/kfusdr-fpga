library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity tb_top is
end entity tb_top;

architecture rtl of tb_top is

  signal tx_o                : std_logic;
  signal rx_i                : std_logic := '1';
  signal transmission_done_o : std_logic;
  signal data_received_o     : std_logic;
  signal stop_bit_error_o    : std_logic;
  signal clk                 : std_logic := '0';
  signal areset_n            : std_logic := '0';
  signal over                : std_logic := '0';

begin

  CLK_GEN: process
  begin
    if over = '0' then
      clk <= not clk;
      wait for 5 ns; -- freq = 100 MHz
    else
      wait;
      -- std.env.stop;
    end if;
  end process CLK_GEN;
  -- clk <= not clk after 5 ns;

  L_STIM: process
    variable data_2_send : std_logic_vector(7 downto 0);
  begin
    areset_n <= '0';
    wait for 100 ns;
    areset_n <= '1';
    rx_i <= '0';
    wait for 8.68 us;
    data_2_send := "10010101";
    for i in 0 to 7 loop
      rx_i <= data_2_send(i);
      wait for 8.68 us;
    end loop;
    rx_i <= '1';
    wait for 8.68 us;

    wait until transmission_done_o = '1';

    rx_i <= '0';
    wait for 8.68 us;
    data_2_send := X"FF";
    for i in 0 to 7 loop
      rx_i <= data_2_send(i);
      wait for 8.68 us;
    end loop;
    rx_i <= '1';

    wait until transmission_done_o = '1';
    wait for 10 ns;
    over <= '1';
    report "simulation finished";
    wait;
  end process L_STIM;

  L_DUT: entity work.top
   generic map(
      BAUD_RATE => 115200,
      CLK_FREQ  => 100.0E6
  )
   port map(
      tx                  => tx_o,
      rx                  => rx_i,
      data_received_o     => data_received_o,
      transmission_done_o => transmission_done_o,
      stop_bit_error_o    => stop_bit_error_o,
      clk                 => clk,
      raw_reset_n         => areset_n
  );

end architecture rtl;
