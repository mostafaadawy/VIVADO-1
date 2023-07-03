----------------------------------------------------------------------------
-- Title      : IIC Controller for VC709 clock setup
-- Project    : JESD204
-----------------------------------------------------------------------
-- File       : iic_controller.vhd
-- Author     : Xilinx
-----------------------------------------------------------------------
-- Description:
--   This module generates IIC commands to set up the Si570 and Si5326
--   Clock generation on the VC705 board to provide GT reference
--   clock
--
-----------------------------------------------------------------------
-- (c) Copyright 2012-2013 Xilinx, Inc. All rights reserved.
--
-- This file contains confidential and proprietary information
-- of Xilinx, Inc. and is protected under U.S. and
-- international copyright and other intellectual property
-- laws.
--
-- DISCLAIMER
-- This disclaimer is not a license and does not grant any
-- rights to the materials distributed herewith. Except as
-- otherwise provided in a valid license issued to you by
-- Xilinx, and to the maximum extent permitted by applicable
-- law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
-- WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
-- AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
-- BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
-- INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
-- (2) Xilinx shall not be liable (whether in contract or tort,
-- including negligence, or under any other theory of
-- liability) for any loss or damage of any kind or nature
-- related to, arising under or in connection with these
-- materials, including for any direct, or any indirect,
-- special, incidental, or consequential loss or damage
-- (including loss of data, profits, goodwill, or any type of
-- loss or damage suffered as a result of any action brought
-- by a third party) even if such damage or loss was
-- reasonably foreseeable or Xilinx had been advised of the
-- possibility of the same.
--
-- CRITICAL APPLICATIONS
-- Xilinx products are not designed or intended to be fail-
-- safe, or for use in any application requiring fail-safe
-- performance, such as life-support or safety devices or
-- systems, Class III medical devices, nuclear facilities,
-- applications related to the deployment of airbags, or any
-- other applications that could lead to death, personal
-- injury, or severe property or environmental damage
-- (individually and collectively, "Critical
-- Applications"). Customer assumes the sole risk and
-- liability of any use of Xilinx products in Critical
-- Applications, subject only to applicable laws and
-- regulations governing limitations on product liability.
--
-- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
-- PART OF THIS FILE AT ALL TIMES.
-----------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library unisim;
use unisim.vcomponents.all;

entity iic_controller is
port (
  reset   : in std_logic;
  clk100  : in std_logic;    -- 100 MHz system clock
  iic_sda : inout std_logic;
  iic_scl : inout std_logic;
  status  : out std_logic_vector(3 downto 0);
  done    : out std_logic
  );
end iic_controller;


architecture rtl of iic_controller is

  -- AXI IIC controller component (from EDK)
  component axi_iic_0
  port (
    S_AXI_ACLK    : in  std_logic;
    S_AXI_ARESETN : in  std_logic;
    IIC2INTC_Irpt : out std_logic;
    S_AXI_AWADDR  : in  std_logic_vector(8 downto 0);
    S_AXI_AWVALID : in  std_logic;
    S_AXI_AWREADY : out std_logic;
    S_AXI_WDATA   : in  std_logic_vector(31 downto 0);
    S_AXI_WSTRB   : in  std_logic_vector(3 downto 0);
    S_AXI_WVALID  : in  std_logic;
    S_AXI_WREADY  : out std_logic;
    S_AXI_BRESP   : out std_logic_vector(1 downto 0);
    S_AXI_BVALID  : out std_logic;
    S_AXI_BREADY  : in  std_logic;
    S_AXI_ARADDR  : in  std_logic_vector(8 downto 0);
    S_AXI_ARVALID : in  std_logic;
    S_AXI_ARREADY : out std_logic;
    S_AXI_RDATA   : out std_logic_vector(31 downto 0);
    S_AXI_RRESP   : out std_logic_vector(1 downto 0);
    S_AXI_RVALID  : out std_logic;
    S_AXI_RREADY  : in  std_logic;
    Sda_I         : in  std_logic;
    Sda_O         : out std_logic;
    Sda_T         : out std_logic;
    Scl_I         : in  std_logic;
    Scl_O         : out std_logic;
    Scl_T         : out std_logic;
    Gpo           : out std_logic_vector(0 downto 0)
    );
  end component;

  -- Set the depth (address width) of the command ROM.
  -- The data width is fixed but the address width could change to account for
  -- more commands.
  constant LUT_AWIDTH : integer := 7;   -- 128 max

  -- Command Look-Up Table - implemented in LUTs (Distributed ROM)
  type t_cmd_rom is array (0 to (2**LUT_AWIDTH)-1) of std_logic_vector(31 downto 0);

  -------------------------------------------------------------------------------
  -- Command look up table format
  -------------------------------------------------------------------------------
  --
  -- The total number of IIC commands is indicated in the first entry.
  -- Each subsequent entry indicates the AXI IIC core target address and target data.
  --
  -- Refer to AXI IIC core DS756 for addresses and tx_fifo format.
  --
  -- for example,
  --  - entry 1 writes 0x0001 to address 0x100
  --  - entry 2 writes 0x01e8 to address 0x108
  --
  -- AXI IIC controller registers :
  -- x0100 - Control Register
  -- x0108 - Tx FIFO          bit 8 = Start, Bit 9 = Stop, 7:0 = Data

  signal cmd_rom : t_cmd_rom := (
    0  => X"0000_0053",  -- Total IIC commands in table
    --
    1  => X"0100_0001",  -- enable AXI IIC core
    -----------------------------------------------
    -- PCA9548 IIC switch                 Addr = 74
    -----------------------------------------------
    2  => X"0108_01e8",  -- addr = 74 (shifted up 1 bit - bit 0 = rw)
    3  => X"0108_0281",  -- channels 0 and 7 enabled (Si570 and Si5326)
    
    -----------------------------------------------
    -- Si570 Programmable Oscillator      Addr = 5D
    -----------------------------------------------
    -- Set up the Si570 for nominally the required
    -- REFCLK frequency
    -- (using values from the Si Labs Programmable
    -- Oscillator Calculator software)
    -- These values will not give fully accurate
    -- output frequency - for full accuracy the
    -- RFREQ value for the factory default frequency
    -- (156.25 MHZ) must be read back and a new
    -- RFREQ value calculated - this is beyond the
    -- scope of this simple demo example.
    --
    -- freeze current freq
    4 => X"0108_01ba",
    5 => X"0108_0089",
    6 => X"0108_0210",
    ---- set RFREQ for ~250.0 MHz
    7 => X"0108_01ba",  -- device address
    8 => X"0108_0007",  -- reg address
    9 => X"0108_0020",
    10 => X"0108_00C2",  -- data (burst)
    11 => X"0108_00BC",
    12 => X"0108_0001",
    13 => X"0108_001E",
    14 => X"0108_02B8",
    ---- unfreeze the DCO
    15 => X"0108_01ba",
    16 => X"0108_0089",
    17 => X"0108_0200",
    ---- set new freq bit
    18 => X"0108_01ba",
    19 => X"0108_0087",
    20 => X"0108_0240",
    --
    
    -----------------------------------------------
    -- Si5326 Jitter Attenuator           Addr = 68
    -----------------------------------------------
    21  => X"0108_01d0",
    22  => X"0108_0088",
    23  => X"0108_0280",  --reset Si5324
    
    24  => X"0108_01d0",
    25  => X"0108_0088",
    26  => X"0108_0200",
    
    27  => X"0108_01d0",  -- setup Si5324 for
    28  => X"0108_0000",  -- bypass mode
    29  => X"0108_0214",

    30  => X"0108_01d0",
    31  => X"0108_0002",
    32  => X"0108_02A2",

    33  => X"0108_01d0",
    34  => X"0108_0003",
    35  => X"0108_0215",

    36  => X"0108_01d0",
    37  => X"0108_0004",
    38  => X"0108_0292",

    39  => X"0108_01d0",
    40  => X"0108_000A",
    41  => X"0108_0208",

    42  => X"0108_01d0",
    43  => X"0108_000B",
    44  => X"0108_0242",

    45  => X"0108_01d0",
    46  => X"0108_0013",
    47  => X"0108_0229",

    48  => X"0108_01d0",
    49  => X"0108_0014",
    50  => X"0108_023E",

    51  => X"0108_01d0",
    52  => X"0108_0019",
    53  => X"0108_02E0",

    54  => X"0108_01d0",
    55  => X"0108_0021",
    56  => X"0108_0201",

    57  => X"0108_01d0",
    58  => X"0108_0024",
    59  => X"0108_0201",

    60  => X"0108_01d0",
    61  => X"0108_0028",
    62  => X"0108_0220",

    63  => X"0108_01d0",
    64  => X"0108_0029",
    65  => X"0108_0202",

    66  => X"0108_01d0",
    67  => X"0108_002A",
    68  => X"0108_0225",

    69  => X"0108_01d0",
    70  => X"0108_002D",
    71  => X"0108_027C",

    72  => X"0108_01d0",
    73  => X"0108_0030",
    74  => X"0108_027C",

	75  => X"0108_01d0", 
    76  => X"0108_0089",  
    77  => X"0108_0201",

    78  => X"0108_01d0",
    79  => X"0108_0011",
    80  => X"0108_0280",
	
    81  => X"0108_01d0",
    82  => X"0108_0088",
    83  => X"0108_0240",

    others => (others => '0')
  );



  type state_type is (START, IDLE, AXI_WRITE, AXI_RESP, FINISH, READ0_AXI, READ1_AXI, AXI_WRITE0);
  signal axi_state : state_type := START;

  signal lut_address    : unsigned(LUT_AWIDTH-1 downto 0);
  signal lut_commands   : unsigned(LUT_AWIDTH-1 downto 0);
  signal lut_data       : std_logic_vector(31 downto 0);

  signal axi_areset_n   : std_logic;
  signal iic2intc_irpt  : std_logic;
  signal s_axi_awaddr   : std_logic_vector(8 downto 0);
  signal s_axi_awvalid  : std_logic;
  signal s_axi_awready  : std_logic;
  signal s_axi_wdata    : std_logic_vector(31 downto 0);
  signal s_axi_wstrb    : std_logic_vector( 3 downto 0);
  signal s_axi_wvalid   : std_logic;
  signal s_axi_wready   : std_logic;
  signal s_axi_bresp    : std_logic_vector( 1 downto 0);
  signal s_axi_bvalid   : std_logic;
  signal s_axi_bready   : std_logic;
  signal s_axi_araddr   : std_logic_vector(8 downto 0);
  signal s_axi_arvalid  : std_logic;
  signal s_axi_arready  : std_logic;
  signal s_axi_rdata    : std_logic_vector(31 downto 0);
  signal s_axi_rresp    : std_logic_vector( 1 downto 0);
  signal s_axi_rvalid   : std_logic;
  signal s_axi_rready   : std_logic;

  signal sda_o          : std_logic;
  signal scl_o          : std_logic;
  signal sda_t          : std_logic;
  signal scl_t          : std_logic;
  signal sda_i          : std_logic;
  signal scl_i          : std_logic;

  signal rdata          : std_logic_vector(31 downto 0);
  
begin

  -- Synchronous read on rom to improve timing
  process(clk100)
  begin
    if rising_edge(clk100) then
      -- register rom data output
      lut_data <= cmd_rom(to_integer(lut_address));
    end if;
  end process;

  -------------------------------------------------------------------------------
  -- State machine for controlling writes to the AXI IIC core

  p_mgmnt_states : process(clk100, reset)
  begin
    if (reset = '1') then
      axi_state     <= START;
      s_axi_awaddr  <= (others => '0');
      s_axi_awvalid <= '0';
      s_axi_wstrb   <= (others => '0');
      s_axi_wvalid  <= '0';
      s_axi_bready  <= '0';
      s_axi_araddr  <= (others => '0');
      s_axi_arvalid <= '0';
      s_axi_rready  <= '0';
      lut_address   <= (others => '0');
      done          <= '0';

    elsif rising_edge(clk100) then

      case axi_state is

        when START =>
          -- Read the command count from location 0 in the LUT
          if (lut_address = 1) then
            axi_state  <= IDLE;
          end if;
          lut_commands <= unsigned(lut_data(LUT_AWIDTH-1 downto 0));
          lut_address  <= to_unsigned(1, lut_address'length);
          done         <= '0';

        when IDLE  =>
          -- write
          s_axi_awaddr   <= (others => '0');
          s_axi_awvalid  <= '0';
          s_axi_wstrb    <= (others => '0');
          s_axi_wvalid   <= '0';
          s_axi_bready   <= '0';
          -- read
          s_axi_araddr   <= (others => '0');
          s_axi_arvalid  <= '0';
          s_axi_rready   <= '0';
          done           <= '0';

          if (lut_commands = 0) then
            axi_state <= FINISH;
          else
            axi_state <= READ0_AXI;
          end if;

        when READ0_AXI   =>
          s_axi_araddr(8 downto 0) <= "100000100";
          s_axi_arvalid <= '1';
          s_axi_rready  <= '1';
          if s_axi_arready = '1' then
            axi_state <= READ1_AXI;
          end if;

        when READ1_AXI =>
          -- Read response phase
          s_axi_arvalid <= '0';

          if s_axi_rvalid = '1' then
            axi_state     <= AXI_WRITE0;
            s_axi_rready  <= '0';
            rdata         <= s_axi_rdata;
          end if;

       when AXI_WRITE0 =>
         if ( (lut_data(8) = '1') and (rdata(7) = '1') and (rdata(2) = '0') ) or ( (lut_data(8) = '0') ) then

           -- Write operation, post address and data
           axi_state                 <= AXI_WRITE;
           s_axi_awaddr(8 downto 0) <= lut_data(24 downto 16);
           s_axi_awvalid             <= '1';
           s_axi_wdata(15 downto 0)  <= lut_data(15 downto 0);
           s_axi_wstrb               <= (others => '1');
           s_axi_wvalid              <= '1';

         else
         --I can add the read stuff here to reduce by a cycle no need to go to read0
           axi_state <= READ0_AXI;
         end if;

        when AXI_WRITE  =>
          if (s_axi_wready = '1') and (s_axi_awready = '1') then
            axi_state      <= AXI_RESP;
            s_axi_wstrb    <= (others => '0');
            s_axi_awvalid  <= '0';
            s_axi_wvalid   <= '0';
            s_axi_bready   <= '1';
            lut_commands   <= lut_commands - 1;
            lut_address    <= lut_address + 1;
          end if;

        when AXI_RESP =>
          if (s_axi_bvalid = '1') then
            axi_state    <= IDLE;
            s_axi_bready <= '0';
          end if;

        when FINISH =>
          -- all commands executed, flag complete and hibernate
          done <= '1';
      end case;
    end if;
  end process;

  -------------------------------------------------------------------------------
  -- IIC control - uses AXI IIC controller

  axi_areset_n <= not reset;

  iic_ctrl : axi_iic_0
  port map (
    S_AXI_ACLK    => clk100,
    S_AXI_ARESETN => axi_areset_n,
    IIC2INTC_Irpt => iic2intc_irpt,
    -- write port
    S_AXI_AWADDR  => s_axi_awaddr,
    S_AXI_AWVALID => s_axi_awvalid,
    S_AXI_AWREADY => s_axi_awready,
    S_AXI_WDATA   => s_axi_wdata,
    S_AXI_WSTRB   => s_axi_wstrb,
    S_AXI_WVALID  => s_axi_wvalid,
    S_AXI_WREADY  => s_axi_wready,
    S_AXI_BRESP   => s_axi_bresp,
    S_AXI_BVALID  => s_axi_bvalid,
    S_AXI_BREADY  => s_axi_bready,
    -- read port
    S_AXI_ARADDR  => s_axi_araddr,
    S_AXI_ARVALID => s_axi_arvalid,
    S_AXI_ARREADY => s_axi_arready,
    S_AXI_RDATA   => s_axi_rdata,
    S_AXI_RRESP   => s_axi_rresp,
    S_AXI_RVALID  => s_axi_rvalid,
    S_AXI_RREADY  => s_axi_rready,
    -- extra status signals
    Sda_I         => sda_i,
    Sda_O         => sda_o,
    Sda_T         => sda_t,
    Scl_I         => scl_i,
    Scl_O         => scl_o,
    Scl_T         => scl_t,
    Gpo           => open
    );

  -- tristate buffers for IIC interface
  -- Instantiate Primitives to support OOC synthesis flow
  sda_iobuf_gen : IOBUF
  port map (
    O  => sda_i,
    IO => iic_sda,
    I  => sda_o,
    T  => sda_t
    );

  scl_iobuf_gen : IOBUF
  port map (
    O  => scl_i,
    IO => iic_scl,
    I  => scl_o,
    T  => scl_t
    );

  -- Debug status - encode the states
  debug: process(clk100)
  begin
    if rising_edge(clk100) then
      case axi_state is
        when START      => status <= x"0";
        when IDLE       => status <= x"1";
        when READ0_AXI  => status <= x"2";
        when READ1_AXI  => status <= x"3";
        when AXI_WRITE0 => status <= x"4";
        when AXI_WRITE  => status <= x"5";
        when AXI_RESP   => status <= x"6";
        when FINISH     => status <= x"7";
        when others => status <= x"F";
      end case;
    end if;
  end process;
end rtl;

