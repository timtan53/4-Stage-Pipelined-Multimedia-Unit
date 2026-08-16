library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity id_ex_register is
    port (
        clk                : in  std_logic;
        reset              : in  std_logic;
        enable             : in  std_logic;

        -- Inputs from ID stage
        id_instruction_in  : in  std_logic_vector(24 downto 0);

        id_rs1_data_in     : in  std_logic_vector(127 downto 0);
        id_rs2_data_in     : in  std_logic_vector(127 downto 0);
        id_rs3_data_in     : in  std_logic_vector(127 downto 0);

        id_rs1_addr_in     : in  std_logic_vector(4 downto 0);
        id_rs2_addr_in     : in  std_logic_vector(4 downto 0);
        id_rs3_addr_in     : in  std_logic_vector(4 downto 0);
        id_rd_addr_in      : in  std_logic_vector(4 downto 0);

        -- Outputs to EX stage
        ex_instruction_out : out std_logic_vector(24 downto 0);

        ex_rs1_data_out    : out std_logic_vector(127 downto 0);
        ex_rs2_data_out    : out std_logic_vector(127 downto 0);
        ex_rs3_data_out    : out std_logic_vector(127 downto 0);

        ex_rs1_addr_out    : out std_logic_vector(4 downto 0);
        ex_rs2_addr_out    : out std_logic_vector(4 downto 0);
        ex_rs3_addr_out    : out std_logic_vector(4 downto 0);
        ex_rd_addr_out     : out std_logic_vector(4 downto 0)
    );
end id_ex_register;

architecture behavioral of id_ex_register is

    constant NOP_INSTR : std_logic_vector(24 downto 0) :=
        "1100000000000000000000000";

begin

    process(clk, reset)
    begin
        if reset = '1' then
            ex_instruction_out <= NOP_INSTR;

            ex_rs1_data_out    <= (others => '0');
            ex_rs2_data_out    <= (others => '0');
            ex_rs3_data_out    <= (others => '0');

            ex_rs1_addr_out    <= (others => '0');
            ex_rs2_addr_out    <= (others => '0');
            ex_rs3_addr_out    <= (others => '0');
            ex_rd_addr_out     <= (others => '0');

        elsif rising_edge(clk) then
            if enable = '1' then
                ex_instruction_out <= id_instruction_in;

                ex_rs1_data_out    <= id_rs1_data_in;
                ex_rs2_data_out    <= id_rs2_data_in;
                ex_rs3_data_out    <= id_rs3_data_in;

                ex_rs1_addr_out    <= id_rs1_addr_in;
                ex_rs2_addr_out    <= id_rs2_addr_in;
                ex_rs3_addr_out    <= id_rs3_addr_in;
                ex_rd_addr_out     <= id_rd_addr_in;
            end if;
        end if;
    end process;

end behavioral;
