ALTER TABLE xxwsh.xxwsh_stock_delivery_info_tmp2 ADD (
  ship_to_weight            NUMBER
 ,ship_to_capacity          NUMBER
 ,carrier_weight            NUMBER
 ,carrier_capacity          NUMBER
);
COMMENT ON COLUMN xxwsh.xxwsh_stock_delivery_info_tmp2.ship_to_weight             IS '���ɐ�i�d�ʁj';
COMMENT ON COLUMN xxwsh.xxwsh_stock_delivery_info_tmp2.ship_to_capacity           IS '���ɐ�i�e�ρj';
COMMENT ON COLUMN xxwsh.xxwsh_stock_delivery_info_tmp2.carrier_weight             IS '�^���Ǝҁi�d�ʁj';
COMMENT ON COLUMN xxwsh.xxwsh_stock_delivery_info_tmp2.carrier_capacity           IS '�^���Ǝҁi�e�ρj';
