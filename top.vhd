library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity top is
  generic (
    BAUD_RATE: integer;
    CLK_FREQ: real
  );
  port (
    tx                  : out std_logic;
    rx                  : in std_logic;
    stop_bit_error_o    : out std_logic;
    data_received_o     : out std_logic;
    transmission_done_o : out std_logic;
    clk                 : in std_logic;
    raw_reset_n         : in std_logic
  );
end entity top;

architecture rtl of top is

  signal raw_reset_n_ff1   : std_logic;
  signal raw_reset_n_ff2   : std_logic;
  signal areset_n          : std_logic;
  signal data_in           : std_logic_vector (7 downto 0);
  signal data_out          : std_logic_vector (7 downto 0);
  signal data_received     : std_logic;
  signal transmission_done : std_logic;
  signal data_received_ack : std_logic;
  signal transmit          : std_logic;
  type fsm_state_t is (idle, receive, send);
  signal fsm_state : fsm_state_t;
  
begin

  L_ECHO_FSM: process(clk, areset_n)
  begin
    if areset_n = '0' then
      fsm_state <= idle;
      data_in <= (others => '0');
      data_received_ack <= '0';
      transmit <= '0';
    elsif rising_edge(clk) then
      case fsm_state is
        when idle =>
          if data_received = '1' then
            fsm_state <= receive;
            data_received_ack <= '1';
          end if;

        when receive =>
          data_received_ack <= '0';
          data_in <= data_out;
          transmit <= '1';
          if transmission_done = '0' then
            fsm_state <= send;
          end if;

        when send =>
          if transmission_done = '1' then
            transmit <= '0';
            fsm_state <= idle;
          end if;

        when others =>
          fsm_state <= idle;

      end case;
    end if;
  end process L_ECHO_FSM;

  L_UART: entity work.uart
    generic map(
      BAUD_RATE => BAUD_RATE,
      CLK_FREQ  => CLK_FREQ
    )
    port map(
      tx_o                => tx,
      rx_i                => rx,
      data_in_i           => data_in,
      transmit_i          => transmit,
      transmission_done_o => transmission_done,
      data_out_o          => data_out,
      data_received_o     => data_received,
      data_received_ack_i => data_received_ack,
      stop_bit_error_o    => stop_bit_error_o,
      clk                 => clk,
      areset_n            => areset_n
    );
  
  L_RESET_SYNC: process(clk, raw_reset_n)
  begin
    if raw_reset_n = '0' then
      raw_reset_n_ff1 <= '0';
      raw_reset_n_ff2 <= '0';
      areset_n <= '0';
    elsif rising_edge(clk) then
      raw_reset_n_ff1 <= '1';
      raw_reset_n_ff2 <= raw_reset_n_ff1;
      areset_n <= raw_reset_n_ff2;
    end if;
  end process L_RESET_SYNC;

  data_received_o <= data_received;
  transmission_done_o <= transmission_done;
  
end architecture rtl;
