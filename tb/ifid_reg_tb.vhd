library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity if_id_register_tb is
end if_id_register_tb;

architecture test of if_id_register_tb is

    signal clk                : std_logic := '0';
    signal reset              : std_logic := '0';
    signal enable             : std_logic := '0';

    signal if_instruction_in  : std_logic_vector(24 downto 0) := (others => '0');
    signal if_pc_in           : std_logic_vector(5 downto 0) := (others => '0');

    signal id_instruction_out : std_logic_vector(24 downto 0);
    signal id_pc_out          : std_logic_vector(5 downto 0);

    constant NOP_INSTR : std_logic_vector(24 downto 0) :=
        "1100000000000000000000000";

begin

    clk <= not clk after 5 ns;

    uut: entity work.if_id_register
        port map (
            clk                => clk,
            reset              => reset,
            enable             => enable,

            if_instruction_in  => if_instruction_in,
            if_pc_in           => if_pc_in,

            id_instruction_out => id_instruction_out,
            id_pc_out          => id_pc_out
        );

    process
    begin

        -- TEST 1: Reset should load NOP and PC = 0

        report "IF/ID TEST 1: Reset";

        reset <= '1';
        enable <= '0';
        wait for 10 ns;

        assert id_instruction_out = NOP_INSTR
            report "IF/ID TEST 1 failed: instruction did not reset to NOP"
            severity error;

        assert id_pc_out = "000000"
            report "IF/ID TEST 1 failed: PC did not reset to 0"
            severity error;

        reset <= '0';
        wait for 10 ns;

        -- TEST 2: enable = 1 should store instruction and PC

        report "IF/ID TEST 2: Store instruction when enable = 1";

        enable <= '1';
        if_instruction_in <= "0010000100100011010000101"; -- example LI
        if_pc_in <= "000011"; -- PC = 3

        wait until rising_edge(clk);
        wait for 1 ns;

        assert id_instruction_out = "0010000100100011010000101"
            report "IF/ID TEST 2 failed: instruction not stored"
            severity error;

        assert id_pc_out = "000011"
            report "IF/ID TEST 2 failed: PC not stored"
            severity error;

        -- TEST 3: enable = 0 should hold old values

        report "IF/ID TEST 3: Hold when enable = 0";

        enable <= '0';
        if_instruction_in <= "1000000001000100001100111"; -- different instruction
        if_pc_in <= "001000"; -- PC = 8

        wait until rising_edge(clk);
        wait for 1 ns;

        assert id_instruction_out = "0010000100100011010000101"
            report "IF/ID TEST 3 failed: instruction changed when enable = 0"
            severity error;

        assert id_pc_out = "000011"
            report "IF/ID TEST 3 failed: PC changed when enable = 0"
            severity error;

        -- TEST 4: enable = 1 should update to new values

        report "IF/ID TEST 4: Update with new instruction";

        enable <= '1';
        if_instruction_in <= "1000000001000100001100111"; -- example R4
        if_pc_in <= "001000"; -- PC = 8

        wait until rising_edge(clk);
        wait for 1 ns;

        assert id_instruction_out = "1000000001000100001100111"
            report "IF/ID TEST 4 failed: instruction did not update"
            severity error;

        assert id_pc_out = "001000"
            report "IF/ID TEST 4 failed: PC did not update"
            severity error;

        report "IF/ID test passed";
        assert false report "Simulation finished" severity failure;

    end process;

end test;
