library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity id_stage is
    port (
        clk           : in  std_logic;

        instruction   : in  std_logic_vector(24 downto 0);

        -- write-back inputs from WB stage
        wb_write_en   : in  std_logic;
        wb_write_addr : in  std_logic_vector(4 downto 0);
        wb_write_data : in  std_logic_vector(127 downto 0);

        -- outputs to ID/EX register
        rs1_data      : out std_logic_vector(127 downto 0);
        rs2_data      : out std_logic_vector(127 downto 0);
        rs3_data      : out std_logic_vector(127 downto 0);

        rs1_addr      : out std_logic_vector(4 downto 0);
        rs2_addr      : out std_logic_vector(4 downto 0);
        rs3_addr      : out std_logic_vector(4 downto 0);

        rd_addr       : out std_logic_vector(4 downto 0)
    );
end id_stage;

architecture structural of id_stage is

    signal read_addr1_sig : std_logic_vector(4 downto 0);
    signal read_addr2_sig : std_logic_vector(4 downto 0);
    signal read_addr3_sig : std_logic_vector(4 downto 0);

begin

    process(instruction)
    begin
        -- default values
        read_addr1_sig <= (others => '0');
        read_addr2_sig <= (others => '0');
        read_addr3_sig <= (others => '0');

        rd_addr <= instruction(4 downto 0);

        case instruction(24 downto 23) is

            -- LI instruction
            -- rd is both source and destination.
            -- So read_addr1 must read old rd.

            when "00" | "01" =>
                read_addr1_sig <= instruction(4 downto 0);
                read_addr2_sig <= (others => '0');
                read_addr3_sig <= (others => '0');

            -- R4 instruction
            -- [19:15] = rs3
            -- [14:10] = rs2
            -- [9:5]   = rs1
            -- [4:0]   = rd

            when "10" =>
                read_addr1_sig <= instruction(9 downto 5);
                read_addr2_sig <= instruction(14 downto 10);
                read_addr3_sig <= instruction(19 downto 15);

            -- R3 instruction
            -- [14:10] = rs2 field
            -- [9:5]   = rs1
            -- [4:0]   = rd

            when "11" =>
                read_addr1_sig <= instruction(9 downto 5);
                read_addr2_sig <= instruction(14 downto 10);
                read_addr3_sig <= (others => '0');

            when others =>
                read_addr1_sig <= (others => '0');
                read_addr2_sig <= (others => '0');
                read_addr3_sig <= (others => '0');
        end case;
    end process;

    rs1_addr <= read_addr1_sig;
    rs2_addr <= read_addr2_sig;
    rs3_addr <= read_addr3_sig;

    -- Register file instance

    U_REG_FILE: entity work.register_file
        port map (
            clk        => clk,
            write_en   => wb_write_en,

            read_addr1 => read_addr1_sig,
            read_addr2 => read_addr2_sig,
            read_addr3 => read_addr3_sig,
            write_addr => wb_write_addr,

            write_data => wb_write_data,

            read_data1 => rs1_data,
            read_data2 => rs2_data,
            read_data3 => rs3_data
        );

end structural;
