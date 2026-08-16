library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity id_ex_register_tb is
end id_ex_register_tb;

architecture test of id_ex_register_tb is

    signal clk                : std_logic := '0';
    signal reset              : std_logic := '0';
    signal enable             : std_logic := '0';

    signal id_instruction_in  : std_logic_vector(24 downto 0) := (others => '0');

    signal id_rs1_data_in     : std_logic_vector(127 downto 0) := (others => '0');
    signal id_rs2_data_in     : std_logic_vector(127 downto 0) := (others => '0');
    signal id_rs3_data_in     : std_logic_vector(127 downto 0) := (others => '0');

    signal id_rs1_addr_in     : std_logic_vector(4 downto 0) := (others => '0');
    signal id_rs2_addr_in     : std_logic_vector(4 downto 0) := (others => '0');
    signal id_rs3_addr_in     : std_logic_vector(4 downto 0) := (others => '0');
    signal id_rd_addr_in      : std_logic_vector(4 downto 0) := (others => '0');

    signal ex_instruction_out : std_logic_vector(24 downto 0);

    signal ex_rs1_data_out    : std_logic_vector(127 downto 0);
    signal ex_rs2_data_out    : std_logic_vector(127 downto 0);
    signal ex_rs3_data_out    : std_logic_vector(127 downto 0);

    signal ex_rs1_addr_out    : std_logic_vector(4 downto 0);
    signal ex_rs2_addr_out    : std_logic_vector(4 downto 0);
    signal ex_rs3_addr_out    : std_logic_vector(4 downto 0);
    signal ex_rd_addr_out     : std_logic_vector(4 downto 0);

    constant NOP_INSTR : std_logic_vector(24 downto 0) :=
        "1100000000000000000000000";

begin

    clk <= not clk after 5 ns;

    uut: entity work.id_ex_register
        port map (
            clk                => clk,
            reset              => reset,
            enable             => enable,

            id_instruction_in  => id_instruction_in,

            id_rs1_data_in     => id_rs1_data_in,
            id_rs2_data_in     => id_rs2_data_in,
            id_rs3_data_in     => id_rs3_data_in,

            id_rs1_addr_in     => id_rs1_addr_in,
            id_rs2_addr_in     => id_rs2_addr_in,
            id_rs3_addr_in     => id_rs3_addr_in,
            id_rd_addr_in      => id_rd_addr_in,

            ex_instruction_out => ex_instruction_out,

            ex_rs1_data_out    => ex_rs1_data_out,
            ex_rs2_data_out    => ex_rs2_data_out,
            ex_rs3_data_out    => ex_rs3_data_out,

            ex_rs1_addr_out    => ex_rs1_addr_out,
            ex_rs2_addr_out    => ex_rs2_addr_out,
            ex_rs3_addr_out    => ex_rs3_addr_out,
            ex_rd_addr_out     => ex_rd_addr_out
        );

    process
    begin

        -- TEST 1: Reset should clear data/address outputs and set NOP

        report "ID/EX TEST 1: Reset";

        reset <= '1';
        enable <= '0';
        wait for 10 ns;

        assert ex_instruction_out = NOP_INSTR
            report "ID/EX TEST 1 failed: instruction did not reset to NOP"
            severity error;

        assert ex_rs1_data_out = x"00000000000000000000000000000000"
            report "ID/EX TEST 1 failed: rs1 data not cleared"
            severity error;

        assert ex_rs2_data_out = x"00000000000000000000000000000000"
            report "ID/EX TEST 1 failed: rs2 data not cleared"
            severity error;

        assert ex_rs3_data_out = x"00000000000000000000000000000000"
            report "ID/EX TEST 1 failed: rs3 data not cleared"
            severity error;

        assert ex_rs1_addr_out = "00000"
            report "ID/EX TEST 1 failed: rs1 addr not cleared"
            severity error;

        assert ex_rs2_addr_out = "00000"
            report "ID/EX TEST 1 failed: rs2 addr not cleared"
            severity error;

        assert ex_rs3_addr_out = "00000"
            report "ID/EX TEST 1 failed: rs3 addr not cleared"
            severity error;

        assert ex_rd_addr_out = "00000"
            report "ID/EX TEST 1 failed: rd addr not cleared"
            severity error;

        reset <= '0';
        wait for 10 ns;

        -- TEST 2: Store ID outputs when enable = 1

        report "ID/EX TEST 2: Store values when enable = 1";

        enable <= '1';

        id_instruction_in <= "1000000001000100001100111"; -- simals r7,r3,r2,r1

        id_rs1_data_in <= x"33333333333333333333333333333333";
        id_rs2_data_in <= x"22222222222222222222222222222222";
        id_rs3_data_in <= x"11111111111111111111111111111111";

        id_rs1_addr_in <= "00011"; -- R3
        id_rs2_addr_in <= "00010"; -- R2
        id_rs3_addr_in <= "00001"; -- R1
        id_rd_addr_in  <= "00111"; -- R7

        wait until rising_edge(clk);
        wait for 1 ns;

        assert ex_instruction_out = "1000000001000100001100111"
            report "ID/EX TEST 2 failed: instruction not stored"
            severity error;

        assert ex_rs1_data_out = x"33333333333333333333333333333333"
            report "ID/EX TEST 2 failed: rs1 data not stored"
            severity error;

        assert ex_rs2_data_out = x"22222222222222222222222222222222"
            report "ID/EX TEST 2 failed: rs2 data not stored"
            severity error;

        assert ex_rs3_data_out = x"11111111111111111111111111111111"
            report "ID/EX TEST 2 failed: rs3 data not stored"
            severity error;

        assert ex_rs1_addr_out = "00011"
            report "ID/EX TEST 2 failed: rs1 addr not stored"
            severity error;

        assert ex_rs2_addr_out = "00010"
            report "ID/EX TEST 2 failed: rs2 addr not stored"
            severity error;

        assert ex_rs3_addr_out = "00001"
            report "ID/EX TEST 2 failed: rs3 addr not stored"
            severity error;

        assert ex_rd_addr_out = "00111"
            report "ID/EX TEST 2 failed: rd addr not stored"
            severity error;

        -- TEST 3: enable = 0 should hold old values

        report "ID/EX TEST 3: Hold when enable = 0";

        enable <= '0';

        id_instruction_in <= "0010000100100011010000101"; -- different instruction

        id_rs1_data_in <= x"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA";
        id_rs2_data_in <= x"BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB";
        id_rs3_data_in <= x"CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC";

        id_rs1_addr_in <= "00101";
        id_rs2_addr_in <= "00110";
        id_rs3_addr_in <= "00111";
        id_rd_addr_in  <= "01000";

        wait until rising_edge(clk);
        wait for 1 ns;

        assert ex_instruction_out = "1000000001000100001100111"
            report "ID/EX TEST 3 failed: instruction changed when enable = 0"
            severity error;

        assert ex_rs1_data_out = x"33333333333333333333333333333333"
            report "ID/EX TEST 3 failed: rs1 data changed when enable = 0"
            severity error;

        assert ex_rs2_data_out = x"22222222222222222222222222222222"
            report "ID/EX TEST 3 failed: rs2 data changed when enable = 0"
            severity error;

        assert ex_rs3_data_out = x"11111111111111111111111111111111"
            report "ID/EX TEST 3 failed: rs3 data changed when enable = 0"
            severity error;

        assert ex_rs1_addr_out = "00011"
            report "ID/EX TEST 3 failed: rs1 addr changed when enable = 0"
            severity error;

        assert ex_rs2_addr_out = "00010"
            report "ID/EX TEST 3 failed: rs2 addr changed when enable = 0"
            severity error;

        assert ex_rs3_addr_out = "00001"
            report "ID/EX TEST 3 failed: rs3 addr changed when enable = 0"
            severity error;

        assert ex_rd_addr_out = "00111"
            report "ID/EX TEST 3 failed: rd addr changed when enable = 0"
            severity error;

        -- TEST 4: enable = 1 should update to new values

        report "ID/EX TEST 4: Update with new values";

        enable <= '1';

        id_instruction_in <= "0010000100100011010000101"; -- LI

        id_rs1_data_in <= x"AAAABBBBCCCCDDDDEEEEFFFF00001111";
        id_rs2_data_in <= x"00000000000000000000000000000000";
        id_rs3_data_in <= x"00000000000000000000000000000000";

        id_rs1_addr_in <= "00101";
        id_rs2_addr_in <= "00000";
        id_rs3_addr_in <= "00000";
        id_rd_addr_in  <= "00101";

        wait until rising_edge(clk);
        wait for 1 ns;

        assert ex_instruction_out = "0010000100100011010000101"
            report "ID/EX TEST 4 failed: instruction did not update"
            severity error;

        assert ex_rs1_data_out = x"AAAABBBBCCCCDDDDEEEEFFFF00001111"
            report "ID/EX TEST 4 failed: rs1 data did not update"
            severity error;

        assert ex_rs2_data_out = x"00000000000000000000000000000000"
            report "ID/EX TEST 4 failed: rs2 data did not update"
            severity error;

        assert ex_rs3_data_out = x"00000000000000000000000000000000"
            report "ID/EX TEST 4 failed: rs3 data did not update"
            severity error;

        assert ex_rs1_addr_out = "00101"
            report "ID/EX TEST 4 failed: rs1 addr did not update"
            severity error;

        assert ex_rs2_addr_out = "00000"
            report "ID/EX TEST 4 failed: rs2 addr did not update"
            severity error;

        assert ex_rs3_addr_out = "00000"
            report "ID/EX TEST 4 failed: rs3 addr did not update"
            severity error;

        assert ex_rd_addr_out = "00101"
            report "ID/EX TEST 4 failed: rd addr did not update"
            severity error;

        report "ID/EX register tests passed";
        assert false report "Simulation finished" severity failure;

    end process;

end test;
