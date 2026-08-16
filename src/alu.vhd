library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity alu_unit is
	port(
	instruction : in std_logic_vector (24 downto 0); --intrusction input
	rs1 : in std_logic_vector(127 downto 0); --rs1 input value
	rs2 : in std_logic_vector(127 downto 0); --rs2 input value
	rs3 : in std_logic_vector(127 downto 0); --rs3 input value
	
	rd : out std_logic_vector(127 downto 0); --rd output value
	rd_write_back : out std_logic; --signal for if there is rd writeback
	rd_add : out std_logic_vector(4 downto 0) --rd address output
	);
end alu_unit;

architecture behavioral of alu_unit is	

	constant MAX32 : signed(31 downto 0) := to_signed(2147483647, 32);		   --sets the maximum and minimum signed values allowed for 32 bit int results
    constant MIN32 : signed(31 downto 0) := to_signed(-2147483648, 32);

    constant MAX64 : signed(63 downto 0) := x"7FFFFFFFFFFFFFFF";
    constant MIN64 : signed(63 downto 0) := x"8000000000000000";
	
	function sat_add32(a, b : signed(31 downto 0)) return signed is		--adds two signed 32 bit numbers with saturation
        variable s : signed(32 downto 0);
    begin
        s := resize(a, 33) + resize(b, 33);			   --resize to 33 bits in case of overflow
        if s > resize(MAX32, 33) then
            return MAX32;
        elsif s < resize(MIN32, 33) then
            return MIN32;
        else
            return s(31 downto 0);
        end if;
    end sat_add32;

    function sat_sub32(a, b : signed(31 downto 0)) return signed is		 --subtracts two signed 32 bit numbers with saturation
        variable d : signed(32 downto 0);
    begin
        d := resize(a, 33) - resize(b, 33);				  --resize to 33 bits in case of overflow
        if d > resize(MAX32, 33) then
            return MAX32;
        elsif d < resize(MIN32, 33) then
            return MIN32;
        else
            return d(31 downto 0);
        end if;
    end sat_sub32;

    function sat_add64(a, b : signed(63 downto 0)) return signed is		 --adds two signed 64 bit numbers with saturation
        variable s : signed(64 downto 0);
    begin
        s := resize(a, 65) + resize(b, 65);				--resize to 65 bits in case of overflow
        if s > resize(MAX64, 65) then
            return MAX64;
        elsif s < resize(MIN64, 65) then
            return MIN64;
        else
            return s(63 downto 0);
        end if;
    end sat_add64;

    function sat_sub64(a, b : signed(63 downto 0)) return signed is		 --subtracts two signed 64 bit numbers with saturation
        variable d : signed(64 downto 0);
    begin
        d := resize(a, 65) - resize(b, 65);				--resize to 65 bits in case of overflow
        if d > resize(MAX64, 65) then
            return MAX64;
        elsif d < resize(MIN64, 65) then
            return MIN64;
        else
            return d(63 downto 0);
        end if;
    end sat_sub64;
	
	function count_ones(vec: std_logic_vector(15 downto 0)) return std_logic_vector is --function to help count 1's in 16 bit segments (for CNT1H) 
		variable count : integer := 0; --variable for count 
	begin
		for i in 0 to 15 loop
			if vec(i) = '1' then count := count + 1;
				--check each bit of vec for 1's and then add to count
			end if;
		end loop;
		return std_logic_vector(to_unsigned(count, 16)); --return count in 16bit vector format
	end function;
	
	function saturation(val: signed(17 downto 0)) return std_logic_vector is --function to check for saturation takes 18 bits for overflow values too
	begin
		if val > to_signed(32767, 18) then return std_logic_vector(to_signed(32767, 16)); --if above 32767 returns 32767 in 16bit value vector
		elsif val < to_signed(-32768, 18) then return std_logic_vector(to_signed(-32768, 16)); --if belove -32768 returns -32768 in 16bit value vector
		else return std_logic_vector(val(15 downto 0)); --else just return val in 16bit value vector
		end if;
	end function;
	
	function count_leading_zeros(vec: std_logic_vector(31 downto 0)) return std_logic_vector is --function to help count leading 0's in 32 bit segments (for CLZW)
		variable count : integer := 0; --variable for count
	begin 
		for i in 31 downto 0 loop
			if vec(i) = '1' then
				return std_logic_vector(to_unsigned(count, 32));
				--check each bit of vec for 1's if it is a 1 then end the function and return count
			end if;
			count := count + 1; --increase count if a 0
		end loop;
		return std_logic_vector(to_unsigned(32, 32)); --if all 32 bit is a 0 return unsigned 32 as a 32bit vector
	end function;
	
	
begin				
	rd_add <= instruction(4 downto 0); --rd address from instruction
	process(instruction, rs1, rs2, rs3)
		variable wb : std_logic; --variable for writeback
		variable result : std_logic_vector(127 downto 0); --variable for rd value
		variable sum : signed(17 downto 0);

        variable load_index  : integer range 0 to 7;				  --load index of load immediate
        variable imm16       : std_logic_vector(15 downto 0);		  --immediate value of load immediate
        variable lo16        : integer;								  --helps define which bits inside 128 bit register to modify
        variable hi16        : integer;								  

        variable i           : integer;
        variable base32      : integer;
        variable base64      : integer;

        variable a16         : signed(15 downto 0);				 --selected bit values from rs2
        variable b16         : signed(15 downto 0);				 --selected bit value from rs3
        variable acc32       : signed(31 downto 0);				 --current 32 bit lane from rs1
        variable prod32      : signed(31 downto 0);				 --final saturated output lane
        variable out32       : signed(31 downto 0);				 --output

        variable a32         : signed(31 downto 0);				--selected bit from rs2
        variable b32         : signed(31 downto 0);				--selected bit from rs3
        variable acc64       : signed(63 downto 0);				--current 64 bit lane from rs1
        variable prod64      : signed(63 downto 0);				--product from multiplying
        variable out64       : signed(63 downto 0);				--output
	begin 
		wb := '1'; --set writeback is 1 (default)
		result := (others => '0'); --set result as all 0's first to make sure its cleared
		case instruction(24 downto 23) is --check first two bit for 4.3 equations 
			when "00" | "01" => 
                result := rs1;
                load_index  := to_integer(unsigned(instruction(23 downto 21)));
                imm16       := instruction(20 downto 5);

                lo16 := load_index * 16;
                hi16 := lo16 + 15;

                result(hi16 downto lo16) := imm16;
			when "10" =>
				case instruction(22 downto 20) is

                    -- 000 = Signed Integer Multiply Add Low

                    when "000" =>
                        for i in 0 to 3 loop
                            base32 := i * 32;
                            acc32  := signed(rs1(base32 + 31 downto base32));
                            a16    := signed(rs2(base32 + 15 downto base32));
                            b16    := signed(rs3(base32 + 15 downto base32));
                            prod32 := a16 * b16;										 --multiplies the selected bits for rs2 and rs3
                            out32  := sat_add32(acc32, prod32);							 --adds rs1 from the product of rs2 and rs3
                            result(base32 + 31 downto base32) := std_logic_vector(out32);
                        end loop;

                    -- 001 = Signed Integer Multiply Add High

                    when "001" =>
                        for i in 0 to 3 loop
                            base32 := i * 32;
                            acc32  := signed(rs1(base32 + 31 downto base32));
                            a16    := signed(rs2(base32 + 31 downto base32 + 16));
                            b16    := signed(rs3(base32 + 31 downto base32 + 16));
                            prod32 := a16 * b16;									  --multiplies the selected bits for rs2 and rs3
                            out32  := sat_add32(acc32, prod32);						  --adds rs1 from the product of rs2 and rs3
                            result(base32 + 31 downto base32) := std_logic_vector(out32);
                        end loop;

                    -- 010 = Signed Integer Multiply Subtract Low

                    when "010" =>
                        for i in 0 to 3 loop
                            base32 := i * 32;
                            acc32  := signed(rs1(base32 + 31 downto base32));
                            a16    := signed(rs2(base32 + 15 downto base32));
                            b16    := signed(rs3(base32 + 15 downto base32));
                            prod32 := a16 * b16;									--multiplies the selected bits for rs2 and rs3
                            out32  := sat_sub32(acc32, prod32);						--subtracts rs1 from the product of rs2 and rs3
                            result(base32 + 31 downto base32) := std_logic_vector(out32);
                        end loop;

                    -- 011 = Signed Integer Multiply-Subtract High

                    when "011" =>
                        for i in 0 to 3 loop
                            base32 := i * 32;
                            acc32  := signed(rs1(base32 + 31 downto base32));
                            a16    := signed(rs2(base32 + 31 downto base32 + 16));
                            b16    := signed(rs3(base32 + 31 downto base32 + 16));
                            prod32 := a16 * b16;									   --multiplies the selected bits for rs2 and rs3
                            out32  := sat_sub32(acc32, prod32);						  --subtracts rs1 from the product of rs2 and rs3
                            result(base32 + 31 downto base32) := std_logic_vector(out32);
                        end loop;

                    -- 100 = Signed Long Integer Multiply Add Low

                    when "100" =>
                        for i in 0 to 1 loop
                            base64 := i * 64;
                            acc64  := signed(rs1(base64 + 63 downto base64));
                            a32    := signed(rs2(base64 + 31 downto base64));
                            b32    := signed(rs3(base64 + 31 downto base64));
                            prod64 := a32 * b32;									  --multiplies the selected bits for rs2 and rs3
                            out64  := sat_add64(acc64, prod64);						  --adds rs1 from the product of rs2 and rs3
                            result(base64 + 63 downto base64) := std_logic_vector(out64);
                        end loop;

                    -- 101 = Signed Long Integer Multiply Add High

                    when "101" =>
                        for i in 0 to 1 loop
                            base64 := i * 64;
                            acc64  := signed(rs1(base64 + 63 downto base64));
                            a32    := signed(rs2(base64 + 63 downto base64 + 32));
                            b32    := signed(rs3(base64 + 63 downto base64 + 32));
                            prod64 := a32 * b32;									   --multiplies the selected bits for rs2 and rs3
                            out64  := sat_add64(acc64, prod64);						   --adds rs1 from the product of rs2 and rs3
                            result(base64 + 63 downto base64) := std_logic_vector(out64);
                        end loop;

                    -- 110 = Signed Long Integer Multiply Subtract Low

                    when "110" =>
                        for i in 0 to 1 loop
                            base64 := i * 64;
                            acc64  := signed(rs1(base64 + 63 downto base64));
                            a32    := signed(rs2(base64 + 31 downto base64));
                            b32    := signed(rs3(base64 + 31 downto base64));
                            prod64 := a32 * b32;								   --multiplies the selected bits for rs2 and rs3
                            out64  := sat_sub64(acc64, prod64);					   --subtracts rs1 from the product of rs2 and rs3
                            result(base64 + 63 downto base64) := std_logic_vector(out64);
                        end loop;

                    -- 111 = Signed Long Integer Multiply Subtract High

                    when "111" =>
                        for i in 0 to 1 loop
                            base64 := i * 64;
                            acc64  := signed(rs1(base64 + 63 downto base64));
                            a32    := signed(rs2(base64 + 63 downto base64 + 32));
                            b32    := signed(rs3(base64 + 63 downto base64 + 32));
                            prod64 := a32 * b32;									  --multiplies the selected bits for rs2 and rs3
                            out64  := sat_sub64(acc64, prod64);						  --subtracts rs1 from the product of rs2 and rs3
                            result(base64 + 63 downto base64) := std_logic_vector(out64);
                        end loop;

                    when others =>
                        result := (others => '0');
                        wb   := '0';
                end case;
			when "11" => 
				case instruction(18 downto 15) is --check last 4 bit of opcode
					when "0000" => --NOP 
					wb := '0'; --no rightback to rd
					
					when "0001" => --SHRHI shift right halfword immediate
					for i in 0 to 7 loop
						result(i*16+15 downto i*16) := std_logic_vector(shift_right(unsigned(rs1(i*16+15 downto i*16)), to_integer(unsigned(instruction(13 downto 10)))));
						--loop through each 16bit segment of rs1 and shift right by 4 lsb of rs2 value from instruction code then place into result
					end loop;
					
					when "0010" => --AU	add word unsigned
					for i in 0 to 3 loop
						result(i*32+31 downto i*32) := std_logic_vector(unsigned(rs1(i*32+31 downto i*32)) + unsigned(rs2(i*32+31 downto i*32)));
						--loop through each 32 bit segment of rs1 and rs2 and add them together than place it into result
					end loop;
					
					when "0011" => --CNT1H count 1s in halfword
					for i in 0 to 7 loop
						result(i*16+15 downto i*16) := count_ones(rs1(i*16+15 downto i*16));
						--loop through each 16bit segment of rs1 and count the amount of ones, then place the count into the corresponding spot in result
					end loop;
					
					when "0100" => --AHS add halfword saturated
					for i in 0 to 7 loop
						sum := signed(rs1(i*16+15) & rs1(i*16+15) & rs1(i*16+15 downto i*16)) + signed(rs2(i*16+15) & rs2(i*16+15) & rs2(i*16+15 downto i*16));
						--sign extend 16bit rs1 and rs2 to 18 bit then add them together 
						result(i*16+15 downto i*16) := saturation(sum);
						--put sum through the saturation helper equation then place it in the corresponding spot in result
					end loop;
					
					when "0101" => --OR bitwise logical or
						result := rs1 or rs2;
					
					when "0110" => --BCW brroadcast word
					for i in 0 to 3 loop
						result(i*32+31 downto i*32) := rs1(127 downto 96);
						--paste the 32msb of rs1 into each 32bit segment of result
					end loop;
					
					when "0111" => --MAXWS max signed word
					for i in 0 to 3 loop
						if signed(rs1(i*32+31 downto i*32)) >= signed(rs2(i*32+31 downto i*32)) then
							--loop through each 32bit segment of rs1 and rs2, compare them and place the bigger value in result
							result(i*32+31 downto i*32) := rs1(i*32+31 downto i*32);
						else 
							result(i*32+31 downto i*32) := rs2(i*32+31 downto i*32);
						end if;
					end loop;
					
					when "1000" => --MINWS min signed word
					for i in 0 to 3 loop
						if signed(rs1(i*32+31 downto i*32)) <= signed(rs2(i*32+31 downto i*32)) then
							--loop through each 32bit segment of rs1 and rs2, compare them and place the bigger value in result
							result(i*32+31 downto i*32) := rs1(i*32+31 downto i*32);
						else 
							result(i*32+31 downto i*32) := rs2(i*32+31 downto i*32);
						end if;
					end loop;
					
					when "1001" => --MLHU multiple low unsigned
					for i in 0 to 3 loop
						result(i*32+31 downto i*32) := std_logic_vector(unsigned(rs1(i*32+15 downto i*32)) * unsigned(rs2(i*32+15 downto i*32)));
						--loop through each 32bit segment of rs1 and rs2 then multiply the 16 lsb of rs1 and rs2 then place the 32bit product in result
					end loop;
					
					when "1010" => --MLHCU mulitply low by constant unsigned
					for i in 0 to 3 loop
						result(i*32+31 downto i*32) := std_logic_vector(resize(unsigned(rs1(i*32+15 downto i*32)) * unsigned(instruction(14 downto 10)), 32));
						--loop through each 32bit segment of rs1 and multiply it with the 5bit value of rs2 from the instruction input and place the product in the corresponding 32bit of result
					end loop;
					
					when "1011" => --AND bitwise logical and
						result := rs1 and rs2; 
					
					when "1100" => --CLZW count leading zeros in words
					for i in 0 to 3 loop
						result(i*32+31 downto i*32) := count_leading_zeros(rs1(i*32+31 downto i*32));
						--loop through each 32bit segment and using helper function to count leading zero's then place it into result
					end loop;
					
					when "1101" => --ROTW rotate bits in word
					for i in 0 to 3 loop
						result(i*32+31 downto i*32) := std_logic_vector(unsigned(rs1(i*32+31 downto i*32)) ror to_integer(unsigned(rs2(i*32+4 downto i*32))));
						--loop through each 32 segment of rs1 and rs2, then take the 5lsb of rs2 and ror rs1 by that amount then place it into result
					end loop;
					
					when "1110" => --SFWU subtract from word unsigned
					for i in 0 to 3 loop
						result(i*32+31 downto i*32) := std_logic_vector(unsigned(rs2(i*32+31 downto i*32)) - unsigned(rs1(i*32+31 downto i*32)));
						--loop through each 32 bit segment of rs1 and rs2 and subtract them than place it into result
					end loop;
					
					when "1111" => --SFHS subtract from halfword saturated
					for i in 0 to 7 loop
						sum := signed(rs2(i*16+15) & rs2(i*16+15) & rs2(i*16+15 downto i*16)) - signed(rs1(i*16+15) & rs1(i*16+15) & rs1(i*16+15 downto i*16));
						--sign extend 16bit rs1 and rs2 to 18 bit then subtract them 
						result(i*16+15 downto i*16) := saturation(sum);
						--put sum through the saturation helper equation then place it in the corresponding spot in result
					end loop;
					
					when others => 
						result := (others => '0');
						wb := '0';
				end case;
				
			when others =>
				result := (others => '0');
				wb := '0';
		end case;		
		rd <= result; --rd gets result
		rd_write_back <= wb; --rd_write_back gets wb
	end process;
end behavioral;
	