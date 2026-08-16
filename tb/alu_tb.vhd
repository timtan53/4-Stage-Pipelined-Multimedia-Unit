library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.all;

entity alu_tb is
end alu_tb;

architecture behavioral of alu_tb is

    signal instruction    : std_logic_vector(24 downto 0) := (others => '0');
    signal rs1            : std_logic_vector(127 downto 0) := (others => '0');
    signal rs2            : std_logic_vector(127 downto 0) := (others => '0');
    signal rs3            : std_logic_vector(127 downto 0) := (others => '0');

    signal rd             : std_logic_vector(127 downto 0);
    signal rd_write_back  : std_logic;
    signal rd_add         : std_logic_vector(4 downto 0);
	
    procedure apply_test(
        signal instr  : out std_logic_vector(24 downto 0);
        signal r1     : out std_logic_vector(127 downto 0);
        signal r2     : out std_logic_vector(127 downto 0);
        signal r3     : out std_logic_vector(127 downto 0);

        constant i_val  : in std_logic_vector(24 downto 0);
        constant r1_val : in std_logic_vector(127 downto 0);
        constant r2_val : in std_logic_vector(127 downto 0);
        constant r3_val : in std_logic_vector(127 downto 0)
    ) is  
	
    begin
        instr <= i_val;
        r1    <= r1_val;
        r2    <= r2_val;
        r3    <= r3_val;
        wait for 20 ns;
    end procedure;

    -- 4.1 LI helper
    -- bit24 = 0
    -- bits23:21 = load index
    -- bits20:5  = imm16
    -- bits4:0   = rd
	
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

    -- 4.2 R4 helper
    -- bits24:23 = 10
    -- bits22:20 = sub-op
    -- bits19:15 = rs3
    -- bits14:10 = rs2
    -- bits9:5   = rs1
    -- bits4:0   = rd

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

    -- 4.3 helper
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

    UUT : entity work.alu_unit
        port map(
            instruction    => instruction,
            rs1            => rs1,
            rs2            => rs2,
            rs3            => rs3,
            rd             => rd,
            rd_write_back  => rd_write_back,
            rd_add         => rd_add
        );

    process

        procedure check(
            test_name    : in string;
            expected     : in std_logic_vector(127 downto 0);
            expected_wb  : in std_logic
        ) is
        begin
            if rd /= expected or rd_write_back /= expected_wb then
                report "Fail " & test_name severity error;
            end if;
        end procedure;

        procedure check_all(
            test_name    : in string;
            expected     : in std_logic_vector(127 downto 0);
            expected_wb  : in std_logic;
            expected_rda : in std_logic_vector(4 downto 0)
        ) is
        begin
            if rd /= expected or rd_write_back /= expected_wb or rd_add /= expected_rda then
                report "Fail " & test_name severity error;
            end if;
        end procedure;

    begin
        
		-- 4.1 LI TESTS

        -- LI regular: replace lane 2 with 1234
        apply_test(
            instruction, rs1, rs2, rs3,
            make_li("010", x"1234", "00101"),
            x"AAAABBBBCCCCDDDDEEEEFFFF00001111",
            (others => '0'),
            (others => '0')
        );
        check_all(
            "LI regular",
            x"AAAABBBBCCCCDDDDEEEE123400001111",
            '1',
            "00101"
        );

        -- LI edge: highest lane
        apply_test(
            instruction, rs1, rs2, rs3,
            make_li("111", x"ABCD", "00110"),
            x"11112222333344445555666677778888",
            (others => '0'),
            (others => '0')
        );
        check_all(
            "LI highest lane",
            x"ABCD2222333344445555666677778888",
            '1',
            "00110"
        );

        ----------------------------------------------------------------
        -- 4.2 R4 TESTS
        ----------------------------------------------------------------

        -- 000 regular: int add low, 10 + (2*3) = 16
        apply_test(
            instruction, rs1, rs2, rs3,
            make_r4("000", "00000", "00000", "00000", "00111"),
            x"0000000A0000000A0000000A0000000A",
            x"10000002100000021000000210000002",
            x"10000003100000031000000310000003"
        );
        check_all(
            "R4 000 regular",
            x"00000010000000100000001000000010",
            '1',
            "00111"
        );

        -- 000 edge: positive saturation
        apply_test(
            instruction, rs1, rs2, rs3,
            make_r4("000", "00000", "00000", "00000", "01000"),
            x"7FFFFFFF7FFFFFFF7FFFFFFF7FFFFFFF",
            x"00000001000000010000000100000001",
            x"00000001000000010000000100000001"
        );
        check_all(
            "R4 000 saturation",
            x"7FFFFFFF7FFFFFFF7FFFFFFF7FFFFFFF",
            '1',
            "01000"
        );

        -- 001 regular: int add high
        apply_test(
            instruction, rs1, rs2, rs3,
            make_r4("001", "00000", "00000", "00000", "01001"),
            x"0000000A0000000A0000000A0000000A",
            x"00021000000210000002100000021000",
            x"00031000000310000003100000031000"
        );
        check_all(
            "R4 001 regular",
            x"00000010000000100000001000000010",
            '1',
            "01001"
        );

        -- 001 edge: positive saturation
        apply_test(
            instruction, rs1, rs2, rs3,
            make_r4("001", "00000", "00000", "00000", "01010"),
            x"7FFFFFFF7FFFFFFF7FFFFFFF7FFFFFFF",
            x"00010000000100000001000000010000",
            x"00010000000100000001000000010000"
        );
        check_all(
            "R4 001 saturation",
            x"7FFFFFFF7FFFFFFF7FFFFFFF7FFFFFFF",
            '1',
            "01010"
        );

        -- 010 regular: int sub low, 10 - (2*3) = 4
        apply_test(
            instruction, rs1, rs2, rs3,
            make_r4("010", "00000", "00000", "00000", "01011"),
            x"0000000A0000000A0000000A0000000A",
            x"10000002100000021000000210000002",
            x"10000003100000031000000310000003"
        );
        check_all(
            "R4 010 regular",
            x"00000004000000040000000400000004",
            '1',
            "01011"
        );

        -- 010 edge: negative saturation
        apply_test(
            instruction, rs1, rs2, rs3,
            make_r4("010", "00000", "00000", "00000", "01100"),
            x"80000000800000008000000080000000",
            x"00000001000000010000000100000001",
            x"00000001000000010000000100000001"
        );
        check_all(
            "R4 010 saturation",
            x"80000000800000008000000080000000",
            '1',
            "01100"
        );

        -- 011 regular: int sub high
        apply_test(
            instruction, rs1, rs2, rs3,
            make_r4("011", "00000", "00000", "00000", "01101"),
            x"0000000A0000000A0000000A0000000A",
            x"00021000000210000002100000021000",
            x"00031000000310000003100000031000"
        );
        check_all(
            "R4 011 regular",
            x"00000004000000040000000400000004",
            '1',
            "01101"
        );

        -- 011 edge: negative saturation
        apply_test(
            instruction, rs1, rs2, rs3,
            make_r4("011", "00000", "00000", "00000", "01110"),
            x"80000000800000008000000080000000",
            x"00010000000100000001000000010000",
            x"00010000000100000001000000010000"
        );
        check_all(
            "R4 011 saturation",
            x"80000000800000008000000080000000",
            '1',
            "01110"
        );

        -- 100 regular: long add low, 10 + 6 = 16
        apply_test(
            instruction, rs1, rs2, rs3,
            make_r4("100", "00000", "00000", "00000", "01111"),
            x"000000000000000A000000000000000A",
            x"10000000000000021000000000000002",
            x"10000000000000031000000000000003"
        );
        check_all(
            "R4 100 regular",
            x"00000000000000100000000000000010",
            '1',
            "01111"
        );

        -- 100 edge: positive saturation
        apply_test(
            instruction, rs1, rs2, rs3,
            make_r4("100", "00000", "00000", "00000", "10000"),
            x"7FFFFFFFFFFFFFFF7FFFFFFFFFFFFFFF",
            x"00000000000000010000000000000001",
            x"00000000000000010000000000000001"
        );
        check_all(
            "R4 100 saturation",
            x"7FFFFFFFFFFFFFFF7FFFFFFFFFFFFFFF",
            '1',
            "10000"
        );

        -- 101 regular: long add high
        apply_test(
            instruction, rs1, rs2, rs3,
            make_r4("101", "00000", "00000", "00000", "10001"),
            x"000000000000000A000000000000000A",
            x"00000002100000000000000210000000",
            x"00000003100000000000000310000000"
        );
        check_all(
            "R4 101 regular",
            x"00000000000000100000000000000010",
            '1',
            "10001"
        );

        -- 101 edge: positive saturation
        apply_test(
            instruction, rs1, rs2, rs3,
            make_r4("101", "00000", "00000", "00000", "10010"),
            x"7FFFFFFFFFFFFFFF7FFFFFFFFFFFFFFF",
            x"00000001000000000000000100000000",
            x"00000001000000000000000100000000"
        );
        check_all(
            "R4 101 saturation",
            x"7FFFFFFFFFFFFFFF7FFFFFFFFFFFFFFF",
            '1',
            "10010"
        );

        -- 110 regular: long sub low, 10 - 6 = 4
        apply_test(
            instruction, rs1, rs2, rs3,
            make_r4("110", "00000", "00000", "00000", "10011"),
            x"000000000000000A000000000000000A",
            x"10000000000000021000000000000002",
            x"10000000000000031000000000000003"
        );
        check_all(
            "R4 110 regular",
            x"00000000000000040000000000000004",
            '1',
            "10011"
        );

        -- 110 edge: negative saturation
        apply_test(
            instruction, rs1, rs2, rs3,
            make_r4("110", "00000", "00000", "00000", "10100"),
            x"80000000000000008000000000000000",
            x"00000000000000010000000000000001",
            x"00000000000000010000000000000001"
        );
        check_all(
            "R4 110 saturation",
            x"80000000000000008000000000000000",
            '1',
            "10100"
        );

        -- 111 regular: long sub high
        apply_test(
            instruction, rs1, rs2, rs3,
            make_r4("111", "00000", "00000", "00000", "10101"),
            x"000000000000000A000000000000000A",
            x"00000002100000000000000210000000",
            x"00000003100000000000000310000000"
        );
        check_all(
            "R4 111 regular",
            x"00000000000000040000000000000004",
            '1',
            "10101"
        );

        -- 111 edge: negative saturation
        apply_test(
            instruction, rs1, rs2, rs3,
            make_r4("111", "00000", "00000", "00000", "10110"),
            x"80000000000000008000000000000000",
            x"00000001000000000000000100000000",
            x"00000001000000000000000100000000"
        );
        check_all(
            "R4 111 saturation",
            x"80000000000000008000000000000000",
            '1',
            "10110"
        );

        ----------------------------------------------------------------
        -- 4.3 TESTS
        ----------------------------------------------------------------

        -- NOP opcode:0000
        apply_test(instruction, rs1, rs2, rs3, make_op11("0000", "00000", "00000", "00000"), x"FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF", x"FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF", (others => '0'));
        check("NOP wb = 0", (others => '0'), '0');

        apply_test(instruction, rs1, rs2, rs3, make_op11("0000", "00001", "00010", "00100"), (others => '0'), (others => '1'), (others => '1'));
        check("NOP wb = 0", (others => '0'), '0');

        -- SHRHI opcode:0001
        apply_test(instruction, rs1, rs2, rs3, make_op11("0001", "00001", "00010", "00001"), x"00020002000200020002000200020002", x"000F000F000F000F000F000F000F000F", (others => '0'));
        check("SHRHI shift = 1 wb = 1", x"00010001000100010001000100010001", '1');

        apply_test(instruction, rs1, rs2, rs3, make_op11("0001", "10100", "00010", "00001"), x"000F000F000F000F000F000F000F000F", (others => '0'), (others => '0'));
        check("SHRHI shift = 4 wb = 1", x"00000000000000000000000000000000", '1');

        -- AU opcode:0010
        apply_test(instruction, rs1, rs2, rs3, make_op11("0010", "00000", "00000", "00000"), x"FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF", x"00000001000000010000000100000001", (others => '0'));
        check("AU wb = 1", x"00000000000000000000000000000000", '1');

        apply_test(instruction, rs1, rs2, rs3, make_op11("0010", "00000", "00000", "00000"), x"00000001000000020000000300000004", x"00000005000000060000000700000008", (others => '0'));
        check("AU wb = 1", x"00000006000000080000000A0000000C", '1');

        -- CNT1H opcode:0011
        apply_test(instruction, rs1, rs2, rs3, make_op11("0011", "00000", "00000", "00000"), x"FFFF00000001000300070000AAAAF0F0", x"FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF", (others => '0'));
        check("CNT1H wb = 1", x"00100000000100020003000000080008", '1');

        apply_test(instruction, rs1, rs2, rs3, make_op11("0011", "00000", "00000", "00000"), x"00010002000400080010002000040008", (others => '0'), (others => '0'));
        check("CNT1H wb = 1", x"00010001000100010001000100010001", '1');

        -- AHS opcode:0100
        apply_test(instruction, rs1, rs2, rs3, make_op11("0100", "00000", "00000", "00000"), x"00010002000300040005000600070008", x"00010002000300040005000600070008", (others => '0'));
        check("AHS wb = 1", x"0002000400060008000A000C000E0010", '1');

        apply_test(instruction, rs1, rs2, rs3, make_op11("0100", "00000", "00000", "00000"), x"7FFF59287FFF6FFF8000800080008000", x"0001684202433FFFFFFFFFFFFFFFFFFF", (others => '0'));
        check("AHS wb = 1", x"7FFF7FFF7FFF7FFF8000800080008000", '1');

        -- OR opcode:0101
        apply_test(instruction, rs1, rs2, rs3, make_op11("0101", "00000", "00000", "00000"), x"FF00FF00FF00FF00FF00FF00FF00FF00", x"0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F", (others => '0'));
        check("OR wb = 1", x"FF0FFF0FFF0FFF0FFF0FFF0FFF0FFF0F", '1');

        apply_test(instruction, rs1, rs2, rs3, make_op11("0101", "00000", "00000", "00000"), x"12345678123456781234567812345678", x"00000000000000000000000000000000", (others => '0'));
        check("OR wb = 1", x"12345678123456781234567812345678", '1');

        -- BCW opcode:0110
        apply_test(instruction, rs1, rs2, rs3, make_op11("0110", "00000", "00000", "00000"), x"12345678784274282849175294827281", x"FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF", (others => '0'));
        check("BCW wb = 1", x"12345678123456781234567812345678", '1');

        apply_test(instruction, rs1, rs2, rs3, make_op11("0110", "00000", "00000", "00000"), x"12121212174158775521812575887512", (others => '0'), (others => '0'));
        check("BCW wb = 1", x"12121212121212121212121212121212", '1');

        -- MAXWS opcode:0111
        apply_test(instruction, rs1, rs2, rs3, make_op11("0111", "00000", "00000", "00000"), x"00000005000000020000000100000008", x"00000003000000060000000400000008", (others => '0'));
        check("MAXWS wb = 1", x"00000005000000060000000400000008", '1');

        apply_test(instruction, rs1, rs2, rs3, make_op11("0111", "00000", "00000", "00000"), x"FFFFFFFF800000007FFFFFFF00000001", x"000000010000000180000000FFFFFFFF", (others => '0'));
        check("MAXWS wb = 1", x"00000001000000017FFFFFFF00000001", '1');

        -- MINWS opcode:1000
        apply_test(instruction, rs1, rs2, rs3, make_op11("1000", "00000", "00000", "00000"), x"00000005000000020000000100000008", x"00000003000000060000000400000008", (others => '0'));
        check("MINWS wb = 1", x"00000003000000020000000100000008", '1');

        apply_test(instruction, rs1, rs2, rs3, make_op11("1000", "00000", "00000", "00000"), x"FFFFFFFF800000007FFFFFFF00000001", x"000000010000000180000000FFFFFFFF", (others => '0'));
        check("MINWS wb = 1", x"FFFFFFFF8000000080000000FFFFFFFF", '1');

        -- MLHU opcode:1001
        apply_test(instruction, rs1, rs2, rs3, make_op11("1001", "00000", "00000", "00000"), x"00010002000200030003000400040005", x"00050003000600040000000500000006", (others => '0'));
        check("MLHU wb = 1", x"000000060000000C000000140000001E", '1');

        apply_test(instruction, rs1, rs2, rs3, make_op11("1001", "00000", "00000", "00000"), x"FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF", x"0000000000000001FFFFFFFF11111111", (others => '0'));
        check("MLHU wb = 1", x"000000000000FFFFFFFE00011110EEEF", '1');

        -- MLHCU opcode:1010
        apply_test(instruction, rs1, rs2, rs3, make_op11("1010", "00001", "00010", "00100"), x"00010002000300040005000600070008", x"00020003000200020002000200020002", (others => '0'));
        check("MLHCU wb = 1", x"00000002000000040000000600000008", '1');

        apply_test(instruction, rs1, rs2, rs3, make_op11("1010", "00111", "00000", "00000"), x"00000001000000020000000300000004", (others => '0'), (others => '0'));
        check("MLHCU wb = 1", x"000000070000000E000000150000001C", '1');

        -- AND opcode:1011
        apply_test(instruction, rs1, rs2, rs3, make_op11("1011", "00000", "00000", "00000"), x"FF00FF00FF00FF00FF00FF00FF00FF00", x"0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F", (others => '0'));
        check("AND wb = 1", x"0F000F000F000F000F000F000F000F00", '1');

        apply_test(instruction, rs1, rs2, rs3, make_op11("1011", "00000", "00000", "00000"), x"0123456789ABCDEF0123456789ABCDEF", x"FFFFFFFFFFFFFFFF0000000000000000", (others => '0'));
        check("AND wb = 1", x"0123456789ABCDEF0000000000000000", '1');

        -- CLZW opcode:1100
        apply_test(instruction, rs1, rs2, rs3, make_op11("1100", "00000", "00000", "00000"), x"00000000100000000001000000000001", x"10000000100000001000000010000000", (others => '0'));
        check("CLZW wb = 1", x"00000020000000030000000F0000001F", '1');

        apply_test(instruction, rs1, rs2, rs3, make_op11("1100", "00000", "00000", "00000"), x"80000000400000000002003000000098", (others => '0'), (others => '0'));
        check("CLZW wb = 1", x"00000000000000010000000E00000018", '1');

        -- ROTW opcode:1101
        apply_test(instruction, rs1, rs2, rs3, make_op11("1101", "00000", "00000", "00000"), x"10101010101010101010101010101010", x"12000001000000070000002100000010", (others => '0'));
        check("ROTW wb = 1", x"08080808202020200808080810101010", '1');

        apply_test(instruction, rs1, rs2, rs3, make_op11("1101", "00000", "00000", "00000"), x"FFFF0000FFFF0000FFFF0000FFFF0000", x"00000010000000000000000400000002", (others => '0'));
        check("ROTW wb = 1", x"0000FFFFFFFF00000FFFF0003FFFC000", '1');

        -- SFWU opcode:1110
        apply_test(instruction, rs1, rs2, rs3, make_op11("1110", "00000", "00000", "00000"), x"0000000100000002000000010000FFFF", x"000000100000002000000000FFFFFFFF", (others => '0'));
        check("SFWU wb = 1", x"0000000F0000001EFFFFFFFFFFFF0000", '1');

        apply_test(instruction, rs1, rs2, rs3, make_op11("1110", "00000", "00000", "00000"), x"00000005000000040000000A00000002", x"00000064000000640000001900000008", (others => '0'));
        check("SFWU wb = 1", x"0000005F000000600000000F00000006", '1');

        -- SFHS opcode:1111
        apply_test(instruction, rs1, rs2, rs3, make_op11("1111", "00000", "00000", "00000"), x"00010002000300040005000600070008", x"00100020003000400050006000700080", (others => '0'));
        check("SFHS wb = 1", x"000F001E002D003C004B005A00690078", '1');

        apply_test(instruction, rs1, rs2, rs3, make_op11("1111", "00000", "00000", "00000"), x"00014231010010000000FFFF80008982", x"800086218023802100017FFF7FFF7FFF", (others => '0'));
        check("SFHS wb = 1", x"800080008000800000017FFF7FFF7FFF", '1');

        -- rd_add spot checks

        apply_test(instruction, rs1, rs2, rs3, make_op11("0001", "00000", "00000", "00100"), (others => '0'), (others => '0'), (others => '0'));
        if rd_add /= "00100" then
            report "Fail rd_add 4.3" severity error;
        end if;

        apply_test(instruction, rs1, rs2, rs3, make_r4("000", "00001", "00010", "00011", "10101"), (others => '0'), (others => '0'), (others => '0'));
        if rd_add /= "10101" then
            report "Fail rd_add 4.2" severity error;
        end if;

        apply_test(instruction, rs1, rs2, rs3, make_li("001", x"5555", "00011"), (others => '0'), (others => '0'), (others => '0'));
        if rd_add /= "00011" then
            report "Fail rd_add 4.1" severity error;
        end if;

        report "ALL TESTS PASSED";
        wait;
    end process;

end behavioral;