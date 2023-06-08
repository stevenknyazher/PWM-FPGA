library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

entity rainbow_pwm is
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           rgb : out STD_LOGIC_VECTOR(2 downto 0));
end rainbow_pwm;

architecture Behavioral of rainbow_pwm is

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
    signal rainbow_thresh: integer := 2499999;
    signal rainbow_cntr: unsigned(10 downto 0);
    signal duty_rainbow: std_logic_vector(resolution downto 0);
    signal pwm_rainbow_reg: std_logic;
    signal reg_reg, green_reg, blue_reg: std_logic;
    
begin

    pwm4: pwm_enhanced generic map(R => resolution) port map(clk => clk, rst => rst, dvsr => dvsr, duty => duty_rainbow, pwm_out => pwm_rainbow_reg);
    
    process(clk, rst)
    begin
        if rst = '1' then
            counter <= 0;
            clk_50Hz <= '0';
        elsif rising_edge(clk) then
            if counter < rainbow_thresh then
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
            rainbow_cntr <= (others => '0');
        elsif rising_edge(clk_50Hz) then
            if rainbow_cntr < 256*6 then
                rainbow_cntr <= rainbow_cntr + 1;
            else
                rainbow_cntr <= (others => '0');
            end if;
        end if;
    end process;
    
    process(clk_50Hz, rst)
    begin
        if rst = '1' then
            duty_rainbow <= (others => '0');
        elsif rising_edge(clk_50Hz) then
            if rainbow_cntr(10 downto 8) = 0 then
                reg_reg <= '1';
                green_reg <= pwm_rainbow_reg;
                blue_reg <= '0';
                duty_rainbow <= '0' & std_logic_vector(rainbow_cntr(7 downto 0));
            elsif rainbow_cntr(10 downto 8) = 1 then
                reg_reg <= pwm_rainbow_reg;
                green_reg <= '1';
                blue_reg <= '0';
                duty_rainbow <= '0' & (NOT std_logic_vector(rainbow_cntr(7 downto 0)));
            elsif rainbow_cntr(10 downto 8) = 2 then
                reg_reg <= '0';
                green_reg <= '1';
                blue_reg <= pwm_rainbow_reg;
                duty_rainbow <= '0' & std_logic_vector(rainbow_cntr(7 downto 0));
            elsif rainbow_cntr(10 downto 8) = 3 then
                reg_reg <= '0';
                green_reg <= pwm_rainbow_reg;
                blue_reg <= '1';
                duty_rainbow <= '0' & (NOT std_logic_vector(rainbow_cntr(7 downto 0)));
            elsif rainbow_cntr(10 downto 8) = 4 then
                reg_reg <= pwm_rainbow_reg;
                green_reg <= '0';
                blue_reg <= '1';
                duty_rainbow <= '0' & std_logic_vector(rainbow_cntr(7 downto 0));
            elsif rainbow_cntr(10 downto 8) = 5 then
                reg_reg <= '1';
                green_reg <= '0';
                blue_reg <= pwm_rainbow_reg;
                duty_rainbow <= '0' & (NOT std_logic_vector(rainbow_cntr(7 downto 0)));
            else
                reg_reg <= '0';
                green_reg <= '0';
                blue_reg <= '0';
            end if;
        end if;
    end process;

    rgb(0) <= reg_reg;
    rgb(1) <= green_reg;
    rgb(2) <= blue_reg;
    
end Behavioral;
