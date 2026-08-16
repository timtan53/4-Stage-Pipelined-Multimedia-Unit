library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library std;
use std.textio.all;

entity instruction_buffer_tb is
end instruction_buffer_tb;

architecture test of instruction_buffer_tb is

    signal clk            : std_logic := '0';
    signal reset          : std_logic := '0';

    signal load_en        : std_logic := '0';
    signal load_addr      : std_logic_vector(5 downto 0) := (others => '0');
    signal load_data      : std_logic_vector(24 downto 0) := (others => '0');

    signal fetch_en       : std_logic := '0';

    signal current_instr  : std_logic_vector(24 downto 0);
    signal pc_out         : std_logic_vector(5 downto 0);

    type instr_array_t is array (0 to 63) of std_logic_vector(24 downto 0);

    -- Convert 25-character binary string into std_logic_vector(24 downto 0)
    -- Example string: "0010000100100011010000101"

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

    -- Clock: 10 ns period

    clk <= not clk after 5 ns;

    uut: entity work.instruction_buffer
        port map (
            clk           => clk,
            reset         => reset,

            load_en       => load_en,
            load_addr     => load_addr,
            load_data     => load_data,

            fetch_en      => fetch_en,

            current_instr => current_instr,
            pc_out        => pc_out
        );

    process
        file instr_file      : text open read_mode is "instructions.txt";
        variable line_buffer : line;
        variable instr_str   : string(1 to 25);

        variable expected    : instr_array_t := (others => (others => '0'));
        variable instr_count : integer := 0;
    begin

        -- TEST 1: Reset PC

        report "TEST 1: Reset PC";

        reset    <= '1';
        load_en  <= '0';
        fetch_en <= '0';

        wait for 20 ns;

        reset <= '0';
        wait for 5 ns;

        assert pc_out = "000000"
            report "TEST 1 failed: PC did not reset to 0"
            severity error;

        -- TEST 2: Load instructions.txt into instruction buffer

        report "TEST 2: Loading instructions.txt";

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

        report "Finished loading instruction file";

        -- TEST 3: Reset PC again so fetching starts from instruction 0

        report "TEST 3: Reset PC before fetch";

        reset <= '1';
        wait for 20 ns;

        reset <= '0';
        wait for 5 ns;

        assert pc_out = "000000"
            report "TEST 3 failed: PC did not reset before fetch"
            severity error;

        -- TEST 4: Check instruction at PC = 0

        report "TEST 4: Check instruction at PC 0";

        wait for 5 ns;

        assert current_instr = expected(0)
            report "TEST 4 failed: instruction at PC 0 incorrect"
            severity error;

        -- TEST 5: Fetch all loaded instructions in order

        report "TEST 5: Fetch instructions in order";

        fetch_en <= '1';

        for i in 1 to instr_count - 1 loop
            wait until rising_edge(clk);
            wait for 1 ns;

            assert pc_out = std_logic_vector(to_unsigned(i, 6))
                report "TEST 5 failed: PC incorrect"
                severity error;

            assert current_instr = expected(i)
                report "TEST 5 failed: current_instr does not match expected instruction"
                severity error;
        end loop;

        -- TEST 6: fetch_en = 0 should hold PC

        report "TEST 6: fetch_en disabled should hold PC";

        fetch_en <= '0';

        wait until rising_edge(clk);
        wait for 1 ns;

        assert pc_out = std_logic_vector(to_unsigned(instr_count - 1, 6))
            report "TEST 6 failed: PC changed even though fetch_en = 0"
            severity error;

        assert current_instr = expected(instr_count - 1)
            report "TEST 6 failed: current_instr changed unexpectedly"
            severity error;

        report "All Test passed for Instruction buffer";
        wait;

    end process;

end test;
