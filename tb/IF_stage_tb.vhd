library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library std;
use std.textio.all;

entity if_stage_tb is
end if_stage_tb;

architecture test of if_stage_tb is

    signal clk            : std_logic := '0';
    signal reset          : std_logic := '0';

    signal load_en        : std_logic := '0';
    signal load_addr      : std_logic_vector(5 downto 0) := (others => '0');
    signal load_data      : std_logic_vector(24 downto 0) := (others => '0');

    signal fetch_en       : std_logic := '0';

    signal if_instruction : std_logic_vector(24 downto 0);
    signal pc_out         : std_logic_vector(5 downto 0);

    signal done           : boolean := false;

    type instr_array_t is array (0 to 63) of std_logic_vector(24 downto 0);

    function string_to_slv25(s : string) return std_logic_vector is
        variable result : std_logic_vector(24 downto 0);
    begin
        for i in 1 to 25 loop
            if s(i) = '1' then
                result(25 - i) := '1';
            else
                result(25 - i) := '0';
            end if;
        end loop;

        return result;
    end function;

begin

    clk_process: process
    begin
        while not done loop
            clk <= '0';
            wait for 5 ns;
            clk <= '1';
            wait for 5 ns;
        end loop;
        wait;
    end process;

    uut: entity work.if_stage
        port map (
            clk            => clk,
            reset          => reset,

            load_en        => load_en,
            load_addr      => load_addr,
            load_data      => load_data,

            fetch_en       => fetch_en,

            if_instruction => if_instruction,
            pc_out         => pc_out
        );

    process
        file instr_file      : text open read_mode is "instructions.txt";
        variable line_buffer : line;
        variable instr_str   : string(1 to 25);

        variable expected    : instr_array_t := (others => (others => '0'));
        variable instr_count : integer := 0;
    begin

        -- TEST 1: Reset PC

        report "IF TEST 1: Reset PC";

        reset    <= '1';
        load_en  <= '0';
        fetch_en <= '0';

        wait for 20 ns;

        reset <= '0';
        wait for 5 ns;

        assert pc_out = "000000"
            report "IF TEST 1 failed: PC did not reset to 0"
            severity error;

        -- TEST 2: Load instructions from instructions.txt

        report "IF TEST 2: Load instructions.txt";

        load_en  <= '1';
        fetch_en <= '0';

        while not endfile(instr_file) loop
            readline(instr_file, line_buffer);
            read(line_buffer, instr_str);

            expected(instr_count) := string_to_slv25(instr_str);

            load_addr <= std_logic_vector(to_unsigned(instr_count, 6));
            load_data <= string_to_slv25(instr_str);

            wait until rising_edge(clk);
            wait for 1 ns;

            instr_count := instr_count + 1;
        end loop;

        load_en <= '0';

        assert instr_count > 0
            report "IF TEST 2 failed: no instructions loaded"
            severity error;

        -- TEST 3: PC should still be 0 during loading

        report "IF TEST 3: PC stayed at 0 during loading";

        assert pc_out = "000000"
            report "IF TEST 3 failed: PC changed during loading"
            severity error;

        -- TEST 4: Reset PC before fetching

        report "IF TEST 4: Reset PC before fetch";

        reset <= '1';
        wait for 20 ns;

        reset <= '0';
        wait for 5 ns;

        assert pc_out = "000000"
            report "IF TEST 4 failed: PC did not reset before fetch"
            severity error;

        assert if_instruction = expected(0)
            report "IF TEST 4 failed: instruction at PC 0 incorrect"
            severity error;

        -- TEST 5: Fetch all loaded instructions in order

        report "IF TEST 5: Fetch instructions in order";

        fetch_en <= '1';

        for i in 1 to instr_count - 1 loop
            wait until rising_edge(clk);
            wait for 1 ns;

            assert pc_out = std_logic_vector(to_unsigned(i, 6))
                report "IF TEST 5 failed: PC incorrect"
                severity error;

            assert if_instruction = expected(i)
                report "IF TEST 5 failed: fetched instruction incorrect"
                severity error;
        end loop;

        -- TEST 6: fetch_en = 0 holds PC

        report "IF TEST 6: fetch_en holds PC";

        fetch_en <= '0';

        wait until rising_edge(clk);
        wait for 1 ns;

        assert pc_out = std_logic_vector(to_unsigned(instr_count - 1, 6))
            report "IF TEST 6 failed: PC changed when fetch_en = 0"
            severity error;

        assert if_instruction = expected(instr_count - 1)
            report "IF TEST 6 failed: instruction changed when fetch_en = 0"
            severity error;

        report "IF stage passed";

        done <= true;
        wait;

    end process;

end test;
