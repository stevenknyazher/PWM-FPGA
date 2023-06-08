library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

entity sine_pwm is
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           rgb : out STD_LOGIC_VECTOR(2 downto 0));
end sine_pwm;

architecture Behavioral of sine_pwm is

    component pwm_enhanced is
        Generic (
            R: integer := 8
        );
        Port ( clk : in STD_LOGIC;
               rst : in STD_LOGIC;
               dvsr : in STD_LOGIC_VECTOR (31 downto 0);
               duty : in STD_LOGIC_VECTOR (R downto 0);
               pwm_out : out STD_LOGIC);
    end component;
    
    constant resolution : integer := 8;
    constant dvsr: STD_LOGIC_VECTOR (31 downto 0) := STD_LOGIC_VECTOR(to_unsigned(4882, 32));   -- sysclk/(2*R*100Hz)
    
    signal counter: integer;
    signal clk_50Hz: std_logic;
    constant sin_thresh: integer := 2499999;
    
    signal duty_sin: STD_LOGIC_VECTOR (resolution downto 0);
    signal pwm_sin_reg: STD_LOGIC;
    
    -- ROM containing sin values
    signal addr: unsigned(resolution-1  downto 0);

    subtype addr_range is integer range 0 to 2**resolution - 1;

    type rom_type is array (addr_range) of unsigned(resolution - 1 downto 0);

function init_rom return rom_type is

    variable rom_v : rom_type;
    variable angle : real;
    variable sin_scaled : real;
    
begin

    for i in addr_range loop
        angle := real(i) * ((2.0 * MATH_PI) / 2.0**resolution);
        sin_scaled := (1.0 + sin(angle)) * (2.0**resolution - 1.0) / 2.0;
        rom_v(i) := to_unsigned(integer(round(sin_scaled)), resolution);
    end loop;
    
    return rom_v;
    
end init_rom;

constant rom : rom_type := init_rom;
signal sin_data: unsigned(resolution-1 downto 0);
    
begin

    pwm2: pwm_enhanced generic map(R => resolution) port map(clk => clk, rst => rst, dvsr => dvsr, duty => duty_sin, pwm_out => pwm_sin_reg);
    
    process(clk, rst)
    begin
        if rst = '1' then
            counter <= 0;
            clk_50Hz <= '0';
        elsif rising_edge(clk) then
            if counter < sin_thresh then
                counter <= counter + 1;
            else
                counter <= 0;
                clk_50Hz <= NOT clk_50Hz;
            end if;
        end if;
    end process;
    
    process(clk_50Hz, rst)
    begin
        if rst = '1' then
            duty_sin <= (others => '0');
        elsif rising_edge(clk_50Hz) then
            if unsigned(duty_sin) <= 2**resolution then
                addr <= unsigned(addr) + 1;
                sin_data <= rom(to_integer(addr));
                duty_sin <= '0' & std_logic_vector(unsigned(sin_data));
            else
                duty_sin <= (others => '0');
            end if;
        end if;
    end process;

    rgb(0) <= pwm_sin_reg;
    rgb(1) <= '0';
    rgb(2) <= '0';
    
end Behavioral;
