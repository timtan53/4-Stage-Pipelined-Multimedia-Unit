library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity id_stage_tb is
end id_stage_tb;

architecture test of id_stage_tb is

    signal clk           : std_logic := '0';

    signal instruction   : std_logic_vector(24 downto 0) := (others => '0');

    signal wb_write_en   : std_logic := '0';
    signal wb_write_addr : std_logic_vector(4 downto 0) := (others => '0');
    signal wb_write_data : std_logic_vector(127 downto 0) := (others => '0');

    signal rs1_data      : std_logic_vector(127 downto 0);
    signal rs2_data      : std_logic_vector(127 downto 0);
    signal rs3_data      : std_logic_vector(127 downto 0);

    signal rs1_addr      : std_logic_vector(4 downto 0);
    signal rs2_addr      : std_logic_vector(4 downto 0);
    signal rs3_addr      : std_logic_vector(4 downto 0);

    signal rd_addr       : std_logic_vector(4 downto 0);

    signal done          : boolean := false;

    -- LI instruction helper

    function make_li(
        load_idx : std_logic_vector(2 downto 0);
        imm16    : std_logic_vector(15 downto 0);
        rda      : std_logic_vector(4 downto 0)
    ) return std_logic_vector is
        variable vec : std_logic_vector(24 downto 0);
    begin
        vec := (others => '0');
        vec(24)           := '0';
        vec(23 downto 21) := load_idx;
        vec(20 downto 5)  := imm16;
        vec(4 downto 0)   := rda;
        return vec;
    end function;

    -- 4.2 instruction helper

    function make_r4(
        subop : std_logic_vector(2 downto 0);
        rs3a  : std_logic_vector(4 downto 0);
        rs2a  : std_logic_vector(4 downto 0);
        rs1a  : std_logic_vector(4 downto 0);
        rda   : std_logic_vector(4 downto 0)
    ) return std_logic_vector is
        variable vec : std_logic_vector(24 downto 0);
    begin
        vec := (others => '0');
        vec(24 downto 23) := "10";
        vec(22 downto 20) := subop;
        vec(19 downto 15) := rs3a;
        vec(14 downto 10) := rs2a;
        vec(9 downto 5)   := rs1a;
        vec(4 downto 0)   := rda;
        return vec;
    end function;

    -- 4.3 instruction helper

    function make_op11(
        opcode : std_logic_vector(3 downto 0);
        rs2a   : std_logic_vector(4 downto 0);
        rs1a   : std_logic_vector(4 downto 0);
        rda    : std_logic_vector(4 downto 0)
    ) return std_logic_vector is
        variable vec : std_logic_vector(24 downto 0);
    begin
        vec(24 downto 23) := "11";
        vec(22 downto 19) := "0000";
        vec(18 downto 15) := opcode;
        vec(14 downto 10) := rs2a;
        vec(9 downto 5)   := rs1a;
        vec(4 downto 0)   := rda;
        return vec;
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

    uut: entity work.id_stage
        port map (
            clk           => clk,

            instruction   => instruction,

            wb_write_en   => wb_write_en,
            wb_write_addr => wb_write_addr,
            wb_write_data => wb_write_data,

            rs1_data      => rs1_data,
            rs2_data      => rs2_data,
            rs3_data      => rs3_data,

            rs1_addr      => rs1_addr,
            rs2_addr      => rs2_addr,
            rs3_addr      => rs3_addr,

            rd_addr       => rd_addr
        );

    process
    begin

        report "ID SETUP: Write initial register values";

        -- R1
        wb_write_en   <= '1';
        wb_write_addr <= "00001";
        wb_write_data <= x"11111111111111111111111111111111";
        wait until rising_edge(clk);
        wait for 1 ns;

        -- R2
        wb_write_addr <= "00010";
        wb_write_data <= x"22222222222222222222222222222222";
        wait until rising_edge(clk);
        wait for 1 ns;

        -- R3
        wb_write_addr <= "00011";
        wb_write_data <= x"33333333333333333333333333333333";
        wait until rising_edge(clk);
        wait for 1 ns;

        -- R5, used to test LI old rd read
        wb_write_addr <= "00101";
        wb_write_data <= x"AAAABBBBCCCCDDDDEEEEFFFF00001111";
        wait until rising_edge(clk);
        wait for 1 ns;

        wb_write_en <= '0';
        wait for 5 ns;

        -- TEST 1: LI decode
        -- For LI, rd is both source and destination.
        -- So rs1_addr should equal rd.

        report "ID TEST 1: LI decode";

        instruction <= make_li("010", x"1234", "00101"); -- li r5, 2, 0x1234
        wait for 10 ns;

        assert rs1_addr = "00101"
            report "ID TEST 1 failed: LI rs1_addr should equal rd"
            severity error;

        assert rs2_addr = "00000"
            report "ID TEST 1 failed: LI rs2_addr should be 0"
            severity error;

        assert rs3_addr = "00000"
            report "ID TEST 1 failed: LI rs3_addr should be 0"
            severity error;

        assert rd_addr = "00101"
            report "ID TEST 1 failed: LI rd_addr incorrect"
            severity error;

        assert rs1_data = x"AAAABBBBCCCCDDDDEEEEFFFF00001111"
            report "ID TEST 1 failed: LI did not read old rd value"
            severity error;

        -- TEST 2: R4 decode
        -- simals r7, r3, r2, r1
        -- rs1 = r3, rs2 = r2, rs3 = r1, rd = r7

        report "ID TEST 2: R4 decode";

        instruction <= make_r4("000", "00001", "00010", "00011", "00111");
        wait for 10 ns;

        assert rs1_addr = "00011"
            report "ID TEST 2 failed: R4 rs1_addr incorrect"
            severity error;

        assert rs2_addr = "00010"
            report "ID TEST 2 failed: R4 rs2_addr incorrect"
            severity error;

        assert rs3_addr = "00001"
            report "ID TEST 2 failed: R4 rs3_addr incorrect"
            severity error;

        assert rd_addr = "00111"
            report "ID TEST 2 failed: R4 rd_addr incorrect"
            severity error;

        assert rs1_data = x"33333333333333333333333333333333"
            report "ID TEST 2 failed: R4 rs1_data incorrect"
            severity error;

        assert rs2_data = x"22222222222222222222222222222222"
            report "ID TEST 2 failed: R4 rs2_data incorrect"
            severity error;

        assert rs3_data = x"11111111111111111111111111111111"
            report "ID TEST 2 failed: R4 rs3_data incorrect"
            severity error;

        -- TEST 3: R3 two-source decode
        -- au r8, r1, r2
        -- rs1 = r1, rs2 = r2, rd = r8

        report "ID TEST 3: R3 two-source decode";

        instruction <= make_op11("0010", "00010", "00001", "01000");
        wait for 10 ns;

        assert rs1_addr = "00001"
            report "ID TEST 3 failed: R3 rs1_addr incorrect"
            severity error;

        assert rs2_addr = "00010"
            report "ID TEST 3 failed: R3 rs2_addr incorrect"
            severity error;

        assert rs3_addr = "00000"
            report "ID TEST 3 failed: R3 rs3_addr should be 0"
            severity error;

        assert rd_addr = "01000"
            report "ID TEST 3 failed: R3 rd_addr incorrect"
            severity error;

        assert rs1_data = x"11111111111111111111111111111111"
            report "ID TEST 3 failed: R3 rs1_data incorrect"
            severity error;

        assert rs2_data = x"22222222222222222222222222222222"
            report "ID TEST 3 failed: R3 rs2_data incorrect"
            severity error;

        -- TEST 4: R3 one-source decode
        -- cnt1h r4, r1
        -- rs1 = r1, rd = r4

        report "ID TEST 4: R3 one-source decode";

        instruction <= make_op11("0011", "00000", "00001", "00100");
        wait for 10 ns;

        assert rs1_addr = "00001"
            report "ID TEST 4 failed: CNT1H rs1_addr incorrect"
            severity error;

        assert rs2_addr = "00000"
            report "ID TEST 4 failed: CNT1H rs2_addr should be 0"
            severity error;

        assert rs3_addr = "00000"
            report "ID TEST 4 failed: CNT1H rs3_addr should be 0"
            severity error;

        assert rd_addr = "00100"
            report "ID TEST 4 failed: CNT1H rd_addr incorrect"
            severity error;

        assert rs1_data = x"11111111111111111111111111111111"
            report "ID TEST 4 failed: CNT1H rs1_data incorrect"
            severity error;

        -- TEST 5: WB write through ID stage register file
        -- Write R6, then decode an instruction that reads R6.

        report "ID TEST 5: WB write into register file";

        wb_write_en   <= '1';
        wb_write_addr <= "00110";
        wb_write_data <= x"66666666666666666666666666666666";

        wait until rising_edge(clk);
        wait for 1 ns;

        wb_write_en <= '0';

        -- R3-style instruction with rs1 = R6
        instruction <= make_op11("0011", "00000", "00110", "01001");
        wait for 10 ns;

        assert rs1_addr = "00110"
            report "ID TEST 5 failed: rs1_addr should be R6"
            severity error;

        assert rs1_data = x"66666666666666666666666666666666"
            report "ID TEST 5 failed: R6 write/read through ID stage failed"
            severity error;

        report "ID stage tb passed.";

        done <= true;
        wait;

    end process;

end test;
