library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.all;

entity pipeline is
	port(
		clk :  in std_logic;
		reset : in std_logic;
		load_en : in std_logic;
		load_addr : in std_logic_vector(5 downto 0);
		load_data : in std_logic_vector(24 downto 0);
		fetch_en : in std_logic;
		
		a_if_instruction : out std_logic_vector(24 downto 0);
        	a_if_pc : out std_logic_vector(5 downto 0);
        	a_if_id_instruction : out std_logic_vector(24 downto 0);
        	a_id_rs1_addr : out std_logic_vector(4 downto 0);
        	a_id_rs2_addr : out std_logic_vector(4 downto 0);
        	a_id_rs3_addr : out std_logic_vector(4 downto 0);
        	a_id_rd_addr : out std_logic_vector(4 downto 0);
        	a_id_rs1_data : out std_logic_vector(127 downto 0);
        	a_id_rs2_data : out std_logic_vector(127 downto 0);
        	a_id_rs3_data : out std_logic_vector(127 downto 0);
        	a_id_ex_instruction : out std_logic_vector(24 downto 0);
            	a_id_ex_rs1_data : out std_logic_vector(127 downto 0);
        	a_id_ex_rs2_data : out std_logic_vector(127 downto 0);
        	a_id_ex_rs3_data : out std_logic_vector(127 downto 0);
        	a_id_ex_rs1_addr : out std_logic_vector(4 downto 0);
        	a_id_ex_rs2_addr : out std_logic_vector(4 downto 0);
        	a_id_ex_rs3_addr : out std_logic_vector(4 downto 0);
        	a_ex_sel_rs1 : out std_logic;
        	a_ex_sel_rs2 : out std_logic;
        	a_ex_sel_rs3 : out std_logic;
            	a_ex_data_rs1 : out std_logic_vector(127 downto 0);
        	a_ex_data_rs2 : out std_logic_vector(127 downto 0);
        	a_ex_data_rs3 : out std_logic_vector(127 downto 0);
        	a_ex_alu_result : out std_logic_vector(127 downto 0);
        	a_ex_rd_addr : out std_logic_vector(4 downto 0);
        	a_ex_rd_wb : out std_logic;
        	a_ex_wb_rd_data : out std_logic_vector(127 downto 0);
        	a_ex_wb_rd_addr : out std_logic_vector(4 downto 0);
        	a_ex_wb_rd_wb : out std_logic;
        	a_wb_reg_file_data : out std_logic_vector(127 downto 0);
        	a_wb_reg_file_addr : out std_logic_vector(4 downto 0);
        	a_wb_reg_file_en : out std_logic
    );
end pipeline;

architecture structural of pipeline is
	--IF stage signals
	signal if_instruction : std_logic_vector(24 downto 0);
	signal if_pc : std_logic_vector(5 downto 0);

	--IF/ID reg signals
    	signal if_id_instruction : std_logic_vector(24 downto 0);
    	signal if_id_pc : std_logic_vector(5 downto 0);

	--ID stage signals
    	signal id_rs1_data : std_logic_vector(127 downto 0);
    	signal id_rs2_data : std_logic_vector(127 downto 0);
    	signal id_rs3_data : std_logic_vector(127 downto 0);
    	signal id_rs1_addr : std_logic_vector(4 downto 0);
    	signal id_rs2_addr : std_logic_vector(4 downto 0);
    	signal id_rs3_addr : std_logic_vector(4 downto 0);
    	signal id_rd_addr : std_logic_vector(4 downto 0);
	--Write back signals from WB stage
	signal wb_write_en : std_logic;
    	signal wb_write_addr : std_logic_vector(4 downto 0);
    	signal wb_write_data : std_logic_vector(127 downto 0);
	
	--ID/EXE reg signals
    	signal id_ex_instruction : std_logic_vector(24 downto 0);
    	signal id_ex_rs1_data : std_logic_vector(127 downto 0);
    	signal id_ex_rs2_data : std_logic_vector(127 downto 0);
    	signal id_ex_rs3_data : std_logic_vector(127 downto 0);
    	signal id_ex_rs1_addr : std_logic_vector(4 downto 0);
    	signal id_ex_rs2_addr : std_logic_vector(4 downto 0);
    	signal id_ex_rs3_addr : std_logic_vector(4 downto 0);
    	signal id_ex_rd_addr : std_logic_vector(4 downto 0);

	--EX stage signals
    	signal ex_rd_data : std_logic_vector(127 downto 0);
    	signal ex_rd_addr : std_logic_vector(4 downto 0);
    	signal ex_rd_wb : std_logic;
    	signal ex_sel_rs1 : std_logic;
    	signal ex_sel_rs2 : std_logic;
    	signal ex_sel_rs3 : std_logic;
    	signal ex_data_rs1 : std_logic_vector(127 downto 0);
    	signal ex_data_rs2 : std_logic_vector(127 downto 0);
    	signal ex_data_rs3 : std_logic_vector(127 downto 0);
    	signal ex_alu_result : std_logic_vector(127 downto 0);
	--Forwading data from EX/WB reg
	signal fwd_data : std_logic_vector(127 downto 0);
    	signal fwd_addr : std_logic_vector(4 downto 0);
    	signal fwd_wb : std_logic;

	--EX/WB reg signals
	signal ex_wb_rd_data : std_logic_vector(127 downto 0);
    	signal ex_wb_rd_addr : std_logic_vector(4 downto 0);
   	signal ex_wb_rd_wb : std_logic;


	--WB stage signals
    	signal wb_reg_file_data : std_logic_vector(127 downto 0);
    	signal wb_reg_file_addr : std_logic_vector(4 downto 0);

begin
	u_if_stage : entity if_stage
		port map(
			clk => clk,
			reset => reset,
			load_en => load_en,
            		load_addr => load_addr,
            		load_data => load_data,
            		fetch_en => fetch_en,
            		if_instruction => if_instruction,
            		pc_out => if_pc
        	);
	
	u_if_id_reg : entity if_id_register
		port map(
            		clk => clk,
            		reset => reset,
            		enable => '1',
            		if_instruction_in => if_instruction,
            		if_pc_in => if_pc,
            		id_instruction_out => if_id_instruction,
            		id_pc_out => if_id_pc
        	);

	u_id_stage : entity id_stage
        	port map(
            		clk => clk,
            		instruction => if_id_instruction,
            		wb_write_en => wb_write_en,
            		wb_write_addr => wb_write_addr,
            		wb_write_data => wb_write_data,
            		rs1_data => id_rs1_data,
            		rs2_data => id_rs2_data,
            		rs3_data => id_rs3_data,
            		rs1_addr => id_rs1_addr,
            		rs2_addr => id_rs2_addr,
            		rs3_addr => id_rs3_addr,
            		rd_addr => id_rd_addr
        	);

	u_id_ex_reg : entity id_ex_register
        	port map(
            		clk => clk,
            		reset => reset,
            		enable => '1',
            		id_instruction_in => if_id_instruction,
            		id_rs1_data_in => id_rs1_data,
            		id_rs2_data_in => id_rs2_data,
            		id_rs3_data_in => id_rs3_data,
            		id_rs1_addr_in => id_rs1_addr,
            		id_rs2_addr_in => id_rs2_addr,
            		id_rs3_addr_in => id_rs3_addr,
            		id_rd_addr_in => id_rd_addr,
            		ex_instruction_out => id_ex_instruction,
            		ex_rs1_data_out => id_ex_rs1_data,
            		ex_rs2_data_out => id_ex_rs2_data,
            		ex_rs3_data_out => id_ex_rs3_data,
            		ex_rs1_addr_out => id_ex_rs1_addr,
            		ex_rs2_addr_out => id_ex_rs2_addr,
            		ex_rs3_addr_out => id_ex_rs3_addr,
            		ex_rd_addr_out => id_ex_rd_addr
        	);

	u_execute_stage : entity execute_stage
        	port map(
            		id_ex_instruction => id_ex_instruction,
            		id_ex_rs1_data => id_ex_rs1_data,
            		id_ex_rs2_data => id_ex_rs2_data,
            		id_ex_rs3_data => id_ex_rs3_data,
            		id_ex_rs1_address => id_ex_rs1_addr,
            		id_ex_rs2_address => id_ex_rs2_addr,
            		id_ex_rs3_address => id_ex_rs3_addr,
            		ex_wb_fwd_data => fwd_data,
            		ex_wb_fwd_address => fwd_addr,
            		ex_wb_fwd_wb => fwd_wb,
            		output_rd_data => ex_rd_data,
            		output_rd_address => ex_rd_addr,
            		output_rd_wb => ex_rd_wb,
            		sel_rs1 => ex_sel_rs1,
            		sel_rs2 => ex_sel_rs2,
            		sel_rs3 => ex_sel_rs3,
            		data_rs1 => ex_data_rs1,
            		data_rs2 => ex_data_rs2,
            		data_rs3 => ex_data_rs3,
            		alu_result => ex_alu_result
        	);

	u_ex_wb_reg : entity ex_wb_register
       		port map(
            		clk => clk,
            		reset => reset,
            		input_rd_data => ex_rd_data,
            		input_rd_address => ex_rd_addr,
            		input_rd_wb => ex_rd_wb,
            		output_rd_data => ex_wb_rd_data,
            		output_rd_address => ex_wb_rd_addr,
            		output_rd_wb => ex_wb_rd_wb
        	);

	--Forward data from EX/WB reg to execute stage
	fwd_data <= ex_wb_rd_data;
    	fwd_addr <= ex_wb_rd_addr;
    	fwd_wb <= ex_wb_rd_wb;

	u_write_back_stage : entity write_back_stage
        	port map(
            		ex_wb_rd_data => ex_wb_rd_data,
            		ex_wb_rd_address => ex_wb_rd_addr,
            		reg_file_data => wb_reg_file_data,
            		reg_file_address => wb_reg_file_addr
        	);

	--Signals to connect WB to ID reg file
	wb_write_en <= ex_wb_rd_wb;
    	wb_write_addr <= ex_wb_rd_addr;
    	wb_write_data <= ex_wb_rd_data;	

	--Signals for result file
	a_if_instruction <= if_instruction;
    	a_if_pc <= if_pc;
    	a_if_id_instruction <= if_id_instruction;
    	a_id_rs1_addr <= id_rs1_addr;
    	a_id_rs2_addr <= id_rs2_addr;
    	a_id_rs3_addr <= id_rs3_addr;
    	a_id_rd_addr <= id_rd_addr;
    	a_id_rs1_data <= id_rs1_data;
    	a_id_rs2_data <= id_rs2_data;
    	a_id_rs3_data <= id_rs3_data;
    	a_id_ex_instruction <= id_ex_instruction;
        a_id_ex_rs1_data <= id_ex_rs1_data;
    	a_id_ex_rs2_data <= id_ex_rs2_data;
    	a_id_ex_rs3_data <= id_ex_rs3_data;
    	a_id_ex_rs1_addr <= id_ex_rs1_addr;
    	a_id_ex_rs2_addr <= id_ex_rs2_addr;
    	a_id_ex_rs3_addr <= id_ex_rs3_addr;
    	a_ex_sel_rs1 <= ex_sel_rs1;
    	a_ex_sel_rs2 <= ex_sel_rs2;
    	a_ex_sel_rs3 <= ex_sel_rs3;
        a_ex_data_rs1 <= ex_data_rs1;
    	a_ex_data_rs2 <= ex_data_rs2;
    	a_ex_data_rs3 <= ex_data_rs3; 
    	a_ex_alu_result <= ex_alu_result;
    	a_ex_rd_addr <= ex_rd_addr;
    	a_ex_rd_wb <= ex_rd_wb;
    	a_ex_wb_rd_data <= ex_wb_rd_data;
    	a_ex_wb_rd_addr <= ex_wb_rd_addr;
   		a_ex_wb_rd_wb <= ex_wb_rd_wb;
    	a_wb_reg_file_data <= wb_reg_file_data;
    	a_wb_reg_file_addr <= wb_reg_file_addr;
    	a_wb_reg_file_en <= ex_wb_rd_wb;

end structural;
