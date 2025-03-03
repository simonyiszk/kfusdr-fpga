library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.MATH_REAL.all;

entity uart is
  generic(
    BAUD_RATE : integer;
    CLK_FREQ  : real
    -- parity : ???
  );
  port (
    tx_o                : out std_logic;
    rx_i                : in  std_logic;
    data_in_i           : in  std_logic_vector(7 downto 0);
    transmit_i          : in  std_logic;
    transmission_done_o : out std_logic;
    data_out_o          : out std_logic_vector(7 downto 0);
    data_received_o     : out std_logic;
    data_received_ack_i : in  std_logic;
    stop_bit_error_o    : out std_logic;
    clk                 : in  std_logic;
    areset_n            : in  std_logic
  );
end entity uart;

architecture rtl of uart is

  constant CLK_PULSES_PER_BAUD : integer := integer(CLK_FREQ / real(BAUD_RATE));
  type tx_fsm_state_t is (tx_idle, tx_start_bit, tx_data_bits, tx_stop_bit, tx_done);
  signal tx_fsm_state : tx_fsm_state_t;
  type rx_fsm_state_t is (rx_idle, rx_start_bit, rx_data_bits, rx_stop_bit, rx_done);
  signal rx_fsm_state : rx_fsm_state_t;
  signal rx_filter    : std_logic_vector(CLK_PULSES_PER_BAUD / 2 downto 0);
  signal rx_int       : std_logic;
  
begin
  
  L_TX_FSM: process(clk, areset_n)
    variable baud_cntr : integer range 0 to CLK_PULSES_PER_BAUD - 1;
    variable bit_cntr  : integer range 0 to 7;
  begin
    if areset_n = '0' then
      tx_fsm_state <= tx_idle;
      tx_o <= '1';
      transmission_done_o <= '1';
    elsif rising_edge(clk) then
      case tx_fsm_state is
        when tx_idle =>
          tx_o <= '1';
          if transmit_i = '1' then
            transmission_done_o <= '0';
            baud_cntr := 0;
            tx_fsm_state <= tx_start_bit;
          end if;

        when tx_start_bit =>
          tx_o <= '0';
          baud_cntr := baud_cntr + 1;
          if baud_cntr = CLK_PULSES_PER_BAUD - 1 then
            baud_cntr := 0;
            bit_cntr := 0;
            tx_fsm_state <= tx_data_bits;
          end if;

        when tx_data_bits =>
          tx_o <= data_in_i(bit_cntr);
          baud_cntr := baud_cntr + 1;
          if baud_cntr = CLK_PULSES_PER_BAUD - 1 then
            baud_cntr := 0;
            if bit_cntr < 7 then
              bit_cntr := bit_cntr + 1;
              tx_fsm_state <= tx_data_bits;
            else
              bit_cntr := 0;
              tx_fsm_state <= tx_stop_bit;
            end if;
          end if;

        when tx_stop_bit =>
          tx_o <= '1';
          baud_cntr := baud_cntr + 1;
          if baud_cntr = CLK_PULSES_PER_BAUD - 1 then
            baud_cntr := 0;
            tx_fsm_state <= tx_done;
          end if;

        when tx_done =>
          transmission_done_o <= '1';
          if transmit_i = '0' then
            tx_fsm_state <= tx_idle;
          end if;

        when others =>
          tx_fsm_state <= tx_idle;

      end case;
    end if;
  end process L_TX_FSM;
  
  L_RX_FILT: process(clk, areset_n)
  begin
    if areset_n = '0' then
      rx_filter <= (others => '0');
    elsif rising_edge(clk) then
      rx_filter <= rx_filter(rx_filter'left - 1 downto rx_filter'right) & rx_i;    
    end if;
  end process L_RX_FILT;
  rx_int <= '0' when unsigned(rx_filter) = 0 else '1';

  L_RX_FSM: process(clk, areset_n)
    variable baud_cntr : integer range 0 to CLK_PULSES_PER_BAUD - 1;
    variable bit_cntr : integer range 0 to 7;
  begin
    if areset_n = '0' then
      rx_fsm_state <= rx_idle;
      data_out_o <= (others => '0');
      data_received_o <= '0';
    elsif rising_edge(clk) then
      case rx_fsm_state is
        when rx_idle =>
          data_received_o <= '0';
          if rx_int = '0' then
            rx_fsm_state <= rx_start_bit;
            baud_cntr := 0;
          end if;

        when rx_start_bit =>
          baud_cntr := baud_cntr + 1;
          if baud_cntr = CLK_PULSES_PER_BAUD - 1 then
            baud_cntr := 0;
            bit_cntr := 0;
            rx_fsm_state <= rx_data_bits;
          end if;

        when rx_data_bits =>
          baud_cntr := baud_cntr + 1;
          if baud_cntr = CLK_PULSES_PER_BAUD - 1 then
            baud_cntr := 0;
            data_out_o(bit_cntr) <= rx_int;
            if bit_cntr < 7 then
              bit_cntr := bit_cntr + 1;
              rx_fsm_state <= rx_data_bits;
            else
              bit_cntr := 0;
              rx_fsm_state <= rx_stop_bit;
            end if;
          end if;

        when rx_stop_bit =>
          baud_cntr := baud_cntr + 1;
          if baud_cntr = CLK_PULSES_PER_BAUD - 1 then
            stop_bit_error_o <= not rx_int;
            data_received_o <= '1';
            rx_fsm_state <= rx_done;
          end if;

        when rx_done =>
          if data_received_ack_i = '1' then
            rx_fsm_state <= rx_idle;
            data_received_o <= '0';
          end if;

        when others =>
          

      end case;
    end if;
  end process L_RX_FSM;

end architecture rtl;
