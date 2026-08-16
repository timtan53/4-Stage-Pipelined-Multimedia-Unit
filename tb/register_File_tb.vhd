library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity register_file_tb is
end register_file_tb;

architecture test of register_file_tb is

    signal clk         : std_logic := '0';
    signal write_en    : std_logic := '0';

    signal read_addr1  : std_logic_vector(4 downto 0) := (others => '0');
    signal read_addr2  : std_logic_vector(4 downto 0) := (others => '0');
    signal read_addr3  : std_logic_vector(4 downto 0) := (others => '0');
    signal write_addr  : std_logic_vector(4 downto 0) := (others => '0');

    signal write_data  : std_logic_vector(127 downto 0) := (others => '0');

    signal read_data1  : std_logic_vector(127 downto 0);
    signal read_data2  : std_logic_vector(127 downto 0);
    signal read_data3  : std_logic_vector(127 downto 0);

begin

    -- Clock generation: 10 ns period

    clk <= not clk after 5 ns;

    uut: entity work.register_file
        port map (
            clk        => clk,
            write_en   => write_en,

            read_addr1 => read_addr1,
            read_addr2 => read_addr2,
            read_addr3 => read_addr3,
            write_addr => write_addr,

            write_data => write_data,

            read_data1 => read_data1,
            read_data2 => read_data2,
            read_data3 => read_data3
        );

    process
    begin

        -- TEST 1: Initial registers should be zero

        report "TEST 1: Initial registers should be zero";

        read_addr1 <= "00000"; -- R0
        read_addr2 <= "00001"; -- R1
        read_addr3 <= "00010"; -- R2

        wait for 10 ns;

        assert read_data1 = x"00000000000000000000000000000000"
            report "TEST 1 failed: R0 is not zero"
            severity error;

        assert read_data2 = x"00000000000000000000000000000000"
            report "TEST 1 failed: R1 is not zero"
            severity error;

        assert read_data3 = x"00000000000000000000000000000000"
            report "TEST 1 failed: R2 is not zero"
            severity error;

        -- TEST 2: Write to R5 and read back through read port 1

        report "TEST 2: Write to R5 and read through port 1";

        write_en   <= '1';
        write_addr <= "00101"; -- R5
        write_data <= x"AAAABBBBCCCCDDDDEEEEFFFF00001111";

        wait until rising_edge(clk);
        wait for 1 ns;

        write_en <= '0';

        read_addr1 <= "00101"; -- R5

        wait for 10 ns;

        assert read_data1 = x"AAAABBBBCCCCDDDDEEEEFFFF00001111"
            report "TEST 2 failed: R5 did not store correct value"
            severity error;

        -- TEST 3: Write to R6 and R7, then test all three read ports

        report "TEST 3: Three read ports";

        -- Write R6
        write_en   <= '1';
        write_addr <= "00110"; -- R6
        write_data <= x"11112222333344445555666677778888";

        wait until rising_edge(clk);
        wait for 1 ns;

        -- Write R7
        write_addr <= "00111"; -- R7
        write_data <= x"9999AAAABBBBCCCCDDDDEEEEFFFF0000";

        wait until rising_edge(clk);
        wait for 1 ns;

        write_en <= '0';

        -- Read R5, R6, and R7 at the same time
        read_addr1 <= "00101"; -- R5
        read_addr2 <= "00110"; -- R6
        read_addr3 <= "00111"; -- R7

        wait for 10 ns;

        assert read_data1 = x"AAAABBBBCCCCDDDDEEEEFFFF00001111"
            report "TEST 3 failed: read port 1 incorrect"
            severity error;

        assert read_data2 = x"11112222333344445555666677778888"
            report "TEST 3 failed: read port 2 incorrect"
            severity error;

        assert read_data3 = x"9999AAAABBBBCCCCDDDDEEEEFFFF0000"
            report "TEST 3 failed: read port 3 incorrect"
            severity error;

        -- TEST 4: write_en = 0 should prevent writing

        report "TEST 4: write_en = 0 prevents writing";

        write_en   <= '0';
        write_addr <= "00101"; -- try to overwrite R5
        write_data <= x"FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF";

        wait until rising_edge(clk);
        wait for 1 ns;

        read_addr1 <= "00101"; -- R5

        wait for 10 ns;

        assert read_data1 = x"AAAABBBBCCCCDDDDEEEEFFFF00001111"
            report "TEST 4 failed: R5 changed even though write_en was 0"
            severity error;

        -- TEST 5: Boundary test, write to R31

        report "TEST 5: Write to boundary register R31";

        write_en   <= '1';
        write_addr <= "11111"; -- R31
        write_data <= x"123456789ABCDEF01122334455667788";

        wait until rising_edge(clk);
        wait for 1 ns;

        write_en <= '0';

        read_addr1 <= "11111"; -- R31

        wait for 10 ns;

        assert read_data1 = x"123456789ABCDEF01122334455667788"
            report "TEST 5 failed: R31 did not store correct value"
            severity error;

        -- TEST 6: Make sure previous register R5 was not changed

        report "TEST 6: Check R5 remains unchanged after other writes";

        read_addr1 <= "00101"; -- R5

        wait for 10 ns;

        assert read_data1 = x"AAAABBBBCCCCDDDDEEEEFFFF00001111"
            report "TEST 6 failed: R5 changed unexpectedly"
            severity error;

        -- TEST 7: Read same register from all three ports

        report "TEST 7: Read same register from all three ports";

        read_addr1 <= "11111"; -- R31
        read_addr2 <= "11111"; -- R31
        read_addr3 <= "11111"; -- R31

        wait for 10 ns;

        assert read_data1 = x"123456789ABCDEF01122334455667788"
            report "TEST 7 failed: read port 1 did not read R31 correctly"
            severity error;

        assert read_data2 = x"123456789ABCDEF01122334455667788"
            report "TEST 7 failed: read port 2 did not read R31 correctly"
            severity error;

        assert read_data3 = x"123456789ABCDEF01122334455667788"
            report "TEST 7 failed: read port 3 did not read R31 correctly"
            severity error;

        -- TEST 8: R0 should always stay zero

        report "TEST 8: R0 is hardwired to zero";

        -- Try to write a nonzero value into R0
        write_en   <= '1';
        write_addr <= "00000"; -- R0
        write_data <= x"FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF";

        wait until rising_edge(clk);
        wait for 1 ns;

        write_en <= '0';

        -- Read R0 from all three read ports
        read_addr1 <= "00000";
        read_addr2 <= "00000";
        read_addr3 <= "00000";

        wait for 10 ns;

        assert read_data1 = x"00000000000000000000000000000000"
            report "TEST 8 failed: R0 changed on read port 1"
            severity error;

        assert read_data2 = x"00000000000000000000000000000000"
            report "TEST 8 failed: R0 changed on read port 2"
            severity error;

        assert read_data3 = x"00000000000000000000000000000000"
            report "TEST 8 failed: R0 changed on read port 3"
            severity error;	

        -- Done

        report "All Register file simulations passed";

        assert false report "Simulation finished" severity failure;

    end process;

end test;
