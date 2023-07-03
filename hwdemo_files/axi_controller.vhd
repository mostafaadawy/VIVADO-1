-----------------------------------------------------------------------
-- Title   : AXI Initialisation Controller for Hardware Demo
-- Project : JESD204
-----------------------------------------------------------------------
-- File    : axi_controller.vhd
-- Author  : Xilinx
-----------------------------------------------------------------------
-- Description:
--   BRAM lookup table based Initialisation controller for setting up
--   the JESD204 cores control registers, and providing both 'config'
--   change and Peek/Poke register access controlled by a Vivado
--   VIO module.
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
--
------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity axi_controller is
port(
  clk       : in std_logic;
  rst       : in std_logic;

  -- VIO Interface
  wr_req                : in  std_logic;
  rd_req                : in  std_logic;
  cfg                   : in  std_logic_vector( 2 downto 0);
  cfg_req               : in  std_logic;

  address               : in  std_logic_vector(11 downto 0);
  wr_data               : in  std_logic_vector(31 downto 0);
  rd_data               : out std_logic_vector(31 downto 0);

  -- AXI-Lite Interface
  axi_aresetn           : out std_logic;
  axi_awaddr            : out std_logic_vector(11 downto 0);
  axi_awvalid           : out std_logic;
  axi_awready           : in  std_logic;
  axi_wdata             : out std_logic_vector(31 downto 0);
  axi_wvalid            : out std_logic;
  axi_wready            : in  std_logic;
  axi_bresp             : in  std_logic_vector( 1 downto 0);
  axi_bvalid            : in  std_logic;
  axi_bready            : out std_logic;
  axi_araddr            : out std_logic_vector(11 downto 0);
  axi_arvalid           : out std_logic;
  axi_arready           : in  std_logic;
  axi_rdata             : in  std_logic_vector(31 downto 0);
  axi_rresp             : in  std_logic_vector( 1 downto 0);
  axi_rvalid            : in  std_logic;
  axi_rready            : out std_logic;

  -- Status
  busy_vio              : out std_logic;      -- single access in progress
  busy_cfg              : out std_logic;      -- Config sequence in progress
  init_start            : out std_logic_vector(1 downto 0);      -- Indicaties if it is first run to program both Tx and Rx
  cfg_out               : out std_logic_vector( 2 downto 0);
  status                : out std_logic_vector( 7 downto 0)

  );
end axi_controller;

architecture rtl of axi_controller is


  -------------------------------------------------------------------------------
  -- Initialisation Command look up table
  -------------------------------------------------------------------------------

  -- Command Look-Up Table - implemented in a 1024x16 BRAM
  type t_cmd_rom is array (0 to 1023) of std_logic_vector(15 downto 0);

  -- Command lookup table contains up to 8 config "pages"
  -- Each page contains up to 42 individual AXI write commands
  --
  -- Each AXI write access is controlled by 3 16-bit data entries formatted as :
  --   addr N   : [15:12] = Control    [11:0] = Address offset
  --   addr N+1 : Write Data [31:16]
  --   addr N+2 : Write Data [15:0 ]
  --
  -- Control data MS bit (15) must be set for a command to be executed.
  -- as soon as a Control/Address entry with bit 15 cleared is read, the FSM
  -- will assume the commands are complete (or the page is empty) and will
  -- complete the programming loop.


  --  N   => x"8111",    -- Addr x111            Register 111
  --  N+1 => x"AAAA",    -- Data xBBBB_AAAA      Description
  --  N+2 => x"BBBB",



  signal cmd_rom : t_cmd_rom := (

    --------------------------------------------
    -- config 0
    --
    -- Default set always used on reset - F = 2, K = 16, Scrambling ON
    --
    0   => x"8008",    -- Addr x008             
    1   => x"0000",    -- Data x0000_0001       Enable Lane Alignment
    2   => x"0001",
    
    3   => x"800C",    -- Addr x00C             
    4   => x"0000",    -- Data x0000_0001       [0] Enable Scrambling
    5   => x"0001",

    6   => x"8020",    -- Addr x020             
    7   => x"0000",    -- Data x0000_0001       F (octets per frame) = 2
    8   => x"0001",

    9   => x"8024",    -- Addr x024             
    10  => x"0000",    -- Data x0000_000F       K (Frames per multi) = 16
    11  => x"000F",

    12  => x"8014",    -- Addr x014             Tx Only 
    13  => x"0000",    -- Data x0000_0003       [7:0] ILA multiframes = 4
    14  => x"0003",

    15  => x"880C",    -- Addr x80C            Tx Only
    16  => x"0000",    -- Data x000_0ABC       [15:12] BID = xA  [7:0] DID = xBC
    17  => x"0ABC",    --                       

    21  => x"8818",    -- Addr x818             Tx Only
    22  => x"0000",    -- Data x0000_1234       [7:0] RES1 [15:8] RES2 [28:24] CF
    23  => x"1234",

    24  => x"0000",

    --------------------------------------------
    -- config 1
    --
    -- F = 1, K = 32, Scrambling ON
    --
    128 => x"8008",    -- Addr x008             
    129 => x"0000",    -- Data x0000_0003       Enable Lane Alignment
    130 => x"0301",
    
    131 => x"800C",    -- Addr x00C             
    132 => x"0000",    -- Data x0000_0001       [0] Enable Scrambling
    133 => x"0001",

    134 => x"8020",    -- Addr x020             
    135 => x"0000",    -- Data x0000_0000       [7:0] F (octets per frame) = 1
    136 => x"0000",

    137 => x"8024",    -- Addr x024             
    138 => x"0000",    -- Data x0000_001F       [4:0] K (Frames per multi) = 32
    139 => x"001F",

    140 => x"8014",    -- Addr x014             Tx Only
    141 => x"0000",    -- Data x0000_0007       [7:0] ILA multiframes = 8
    142 => x"0007",
    
    143  => x"880C",    -- Addr x80C             Tx Only
    144  => x"0000",    -- Data x000_0ABC       [15:12] BID = xF  [7:0] DID = xDE
    145  => x"0FDE",    
    
    146 => x"8814",    -- Addr x814             Tx Only
    147 => x"0100",    -- Data x0100_0000       [28:24] CF
    148 => x"0000",

    149 => x"8818",    -- Addr x818             Tx Only
    150 => x"0000",    -- Data x0100_A5F0       [7:0] RES1 [15:8] RES2 
    151 => x"A5F0",

    152 => x"0000",

    --------------------------------------------
    -- config 2
    --
    -- F = 2, K = 16, Scrambling OFF
    --
    256 => x"8008",    -- Addr x008             Rx Config 0
    257 => x"0000",    -- Data x0000_0001       Enable Lane Alignment
    258 => x"0001",
    
    259 => x"800C",    -- Addr x00C             
    260 => x"0000",    -- Data x0000_0001       [0] Disable Scrambling
    261 => x"0000",

    262 => x"8020",    -- Addr x020 
    263 => x"0000",    -- Data x0000_0001       [7:0] F (octets per frame) = 2
    264 => x"0001",

    265 => x"8024",    -- Addr x024  
    266 => x"0000",    -- Data x0000_000F       [4:0] K (Frames per multi) = 16
    267 => x"000F",

    268 => x"8014",    -- Addr x014             Tx Only
    269 => x"0000",    -- Data x0000_0005       [7:0] ILA multiframes = 6
    270 => x"0005",

    271 => x"880C",    -- Addr x80C             Tx Only
    272 => x"0000",    -- Data x0000_0ABE       [15:12] BID = xA  [7:0] DID = xBE
    273 => x"0ABE",    --                       

    274 => x"8814",    -- Addr x814             Tx Only
    275 => x"0200",    -- Data x0200_0000       [28:24] CF
    276 => x"0000",

    277 => x"8818",    -- Addr x818             Tx Only
    278 => x"0000",    -- Data x0000_AABB       [7:0] RES1 [15:8] RES2 
    279 => x"AABB",

    280 => x"0000",

    --------------------------------------------
    -- config 3
    --
    -- F = 1, K = 32, Scrambling OFF
    --
    384 => x"8008",    -- Addr x008             Rx Config 0
    385 => x"0000",    -- Data x0000_0001       Enable Lane Alignment
    386 => x"0001",
    
    387 => x"800C",    -- Addr x008             Rx Config 0
    388 => x"0000",    -- Data x0000_0000       [0] Disable Scrambling
    389 => x"0000",

    390 => x"8020",    -- Addr x020 
    391 => x"0000",    -- Data x0000_0000       [7:0] F (octets per frame) = 1
    392 => x"0000",

    393 => x"8024",    -- Addr x024  
    394 => x"0000",    -- Data x0000_0011       [4:0] K (Frames per multi) = 32
    395 => x"001F",

    396 => x"8014",    -- Addr x014             Tx Only
    397 => x"0000",    -- Data x0000_0003       [7:0] ILA multiframes = 4
    398 => x"0003",

    399 => x"880C",    -- Addr x80C             Tx Only
    400 => x"0000",    -- Data x0000_0FAE       [15:12] BID = xF  [7:0] DID = xAE
    401 => x"0FAE",    --                       

    402 => x"8814",    -- Addr x814             Tx Only
    403 => x"0300",    -- Data x0300_0000       [28:24] CF
    404 => x"0000",

    405 => x"8818",    -- Addr x818             Tx Only
    406 => x"0300",    -- Data x0300_D0B0       [7:0] RES1 [15:8] RES2 
    407 => x"D0B0",

    408 => x"0000",

    --------------------------------------------
    --
    -- (EMPTY)
    --
    512 => x"0000",

    -- default
    others => (others => '0')  -- all undefined locations default to empty
    );


  attribute rom_style : string;
  attribute rom_style of cmd_rom : signal is "block";

  -- Supervisor Controller FSM
  type t_supervisor is (INIT,      START,    LUT_CMD,  LUT_DATA0,
                        LUT_DATA1, LUT_AXI0, LUT_AXI1, S_IDLE,
                        VIO_WR0,   VIO_WR1,  VIO_RD0,  VIO_RD1);
  signal supervisor : t_supervisor := INIT;

  -- AXI individual access FSM
  type t_accessor is (A_IDLE, WR0, WR1, RD0, RD1);
  signal accessor : t_accessor := A_IDLE;

  signal startup      : unsigned( 8 downto 0)         := (others => '0');
  
  signal init_start_i : std_logic_vector(1 downto 0);

  signal rom_addr     : unsigned( 9 downto 0)         := (others => '0');
  signal rom_data     : std_logic_vector(15 downto 0) := (others => '0');

  signal rd_access    : std_logic := '0';
  signal wr_access    : std_logic := '0';
  signal access_busy  : std_logic := '0';

  signal access_addr  : std_logic_vector(11 downto 0) := (others => '0');
  signal access_wdata : std_logic_vector(31 downto 0) := (others => '0');
  signal access_rdata : std_logic_vector(31 downto 0) := (others => '0');

begin

  init_start <= init_start_i;
  
  -- Supervisor State Machine
  p_supervisor : process(clk, rst)
  begin
    if (rst = '1') then

      supervisor   <= INIT;
      rom_addr     <= (others => '0');
      startup      <= (others => '0');
      busy_vio     <= '0';
      busy_cfg     <= '1';
      cfg_out      <= (others => '0');
      rd_data      <= (others => '0');
      init_start_i <= "11"; 

    elsif rising_edge(clk) then

      -- BRAM based Command ROM
      rom_data <= cmd_rom(to_integer(rom_addr));

      -- exit from reset delay counter - 256 clocks
      if startup(8) = '0' then
        startup <= startup + 1;
      end if;

      case supervisor is

        -- On exit from reset, wait before starting AXI register accesses
        when INIT =>
          if startup(8) = '1' then
            supervisor <= START;
            rom_addr   <= unsigned(cfg) & "0000000";  -- select Config ROM page
            cfg_out    <= cfg;
          end if;
          busy_cfg   <= '1';

        -- LUT sequence start
        -- - on exit from reset
        -- - or config change request - the requested LUT page is actioned
        when START =>
          rom_addr   <= rom_addr + 1;
          supervisor <= LUT_CMD;
          busy_cfg   <= '1';

        -- Basic Lookup table sequence - reads Command/Data0/Data1 from 3
        -- consecutive ROM locations (unless Command is NULL)

        -- Get the Command/Address
        when LUT_CMD =>
          rom_addr <= rom_addr + 1;

          if rom_data(15) = '0' then
            -- NULL command, exit
            supervisor <= S_IDLE;
          else
            -- active command, get address and step on
            supervisor <= LUT_DATA0;
          end if;
          access_addr <= rom_data(11 downto 0);

        -- Get the LS 16 bits of data
        when LUT_DATA0 =>

          rom_addr   <= rom_addr + 1;
          supervisor <= LUT_DATA1;

          access_wdata(31 downto 16) <= rom_data;

        -- Get the MS 16 bits of data
        when LUT_DATA1 =>

          supervisor <= LUT_AXI0;

          access_wdata(15 downto 0) <= rom_data;

        -- Request the AXI access by the accessor
        when LUT_AXI0 =>

          wr_access <= '1';
          if access_busy = '1' then
            supervisor <= LUT_AXI1;
          end if;

        -- ... and wait for it to complete
        when LUT_AXI1 =>

          wr_access <= '0';
          if access_busy = '0' then
            supervisor <= LUT_CMD;
            rom_addr   <= rom_addr + 1;
          end if;

        -- IDLE, wait for any VIO Read/Write/config requests
        when S_IDLE =>
          wr_access <= '0';
          rd_access <= '0';
          busy_vio  <= '0';
          busy_cfg  <= '0';
          
          if (init_start_i(0) = '0') then
            init_start_i(1) <= '0';
          end if;

          if (cfg_req = '1' or init_start_i(0) = '1') then
            rom_addr   <= unsigned(cfg) & "0000000";  -- select startup Config ROM page
            cfg_out    <= cfg;
            init_start_i(0) <= not(init_start_i(0));  --Will ensure that both register maps are updated when changing configuration
            init_start_i(1) <= '1';
            supervisor <= START;
          elsif wr_req = '1' then
            supervisor <= VIO_WR0;
          elsif rd_req = '1' then
            supervisor <= VIO_RD0;
          end if;

        -- VIO requested single Write access
        when VIO_WR0 =>
          busy_vio     <= '1';
          wr_access    <= '1';
          access_addr  <= address;
          access_wdata <= wr_data;
          if access_busy = '1' then
            supervisor <= VIO_WR1;
          end if;

        when VIO_WR1 =>
          wr_access <= '0';
          if access_busy = '0' then
            supervisor <= S_IDLE;
          end if;

        -- VIO requested single Read access
        when VIO_RD0 =>
          busy_vio     <= '1';
          rd_access    <= '1';
          access_addr  <= address;
          if access_busy = '1' then
            supervisor <= VIO_RD1;
          end if;

        when VIO_RD1 =>
          rd_access <= '0';
          if access_busy = '0' then
            rd_data    <= access_rdata;
            supervisor <= S_IDLE;
          end if;

      end case;


    end if;
  end process;


  -- AXI interface
  -- State machine for controlling individual writes and reads to and from the
  -- AXI management registers
  p_accessor : process(clk, rst)
  begin
    if (rst = '1') then
      accessor   <= A_IDLE;
      axi_awaddr  <= x"000";
      axi_awvalid <= '0';
      axi_wdata   <= x"00000000";
      axi_wvalid  <= '0';
      axi_bready  <= '0';
      axi_araddr  <= x"000";
      axi_arvalid <= '0';
      axi_rready  <= '0';

      axi_aresetn <= '0';

      access_busy <= '0';

    elsif rising_edge(clk) then

      axi_aresetn <= '1';

      case accessor is

        when A_IDLE =>

          axi_awvalid <= '0';

          axi_wvalid  <= '0';
          axi_bready  <= '0';

          axi_arvalid <= '0';
          axi_rready  <= '0';

          if (wr_access = '1') then
            accessor <= WR0;
          end if;
          if (rd_access = '1') then
            accessor <= RD0;
          end if;

        when WR0 =>
          -- Write address/data phase
          axi_awaddr  <= access_addr;
          axi_awvalid <= '1';
          axi_wdata   <= access_wdata;
          axi_wvalid  <= '1';

          if (axi_awready = '1') then
            accessor    <= WR1;

            axi_awvalid <= '0';
            axi_wvalid  <= '0';
          end if;

        when WR1 =>
          -- response phase
          if axi_bvalid = '1' then
            accessor   <= A_IDLE;
            axi_bready <= '1';
          end if;

        when RD0 =>
          -- Read address phase
          axi_araddr  <= access_addr;
          axi_arvalid <= '1';
          axi_rready  <= '1';

          if axi_arready = '1' then
            accessor <= RD1;
          end if;

        when RD1 =>
          -- Read response phase
          axi_arvalid <= '0';

          if axi_rvalid = '1' then
            accessor     <= A_IDLE;
            axi_rready   <= '0';
            access_rdata <= axi_rdata;
          end if;

      end case;

      -- Generate 'busy' signal
      if accessor = A_IDLE then
        access_busy <= '0';
      else
        access_busy <= '1';
      end if;

    end if;
  end process;

  -- Debug status - encode the states
  debug: process(clk)
  begin
    if rising_edge(clk) then
      case supervisor is
        when INIT      => status(3 downto 0) <= x"0";
        when START     => status(3 downto 0) <= x"1";
        when LUT_CMD   => status(3 downto 0) <= x"2";
        when LUT_DATA0 => status(3 downto 0) <= x"3";
        when LUT_DATA1 => status(3 downto 0) <= x"4";
        when LUT_AXI0  => status(3 downto 0) <= x"5";
        when LUT_AXI1  => status(3 downto 0) <= x"6";
        when S_IDLE    => status(3 downto 0) <= x"7";
        when VIO_WR0   => status(3 downto 0) <= x"8";
        when VIO_WR1   => status(3 downto 0) <= x"9";
        when VIO_RD0   => status(3 downto 0) <= x"A";
        when VIO_RD1   => status(3 downto 0) <= x"B";

        when others    => status(3 downto 0) <= x"F";
      end case;

      case accessor is
        when A_IDLE => status(7 downto 4) <= x"0";
        when WR0    => status(7 downto 4) <= x"1";
        when WR1    => status(7 downto 4) <= x"2";
        when RD0    => status(7 downto 4) <= x"3";
        when RD1    => status(7 downto 4) <= x"4";

        when others => status(7 downto 4) <= x"F";
      end case;

    end if;
  end process;

end rtl;
