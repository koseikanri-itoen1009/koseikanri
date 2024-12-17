ALTER TABLE xxwsh.xxwsh_stock_delivery_info_tmp2 ADD (
  ship_to_weight            NUMBER
 ,ship_to_capacity          NUMBER
 ,carrier_weight            NUMBER
 ,carrier_capacity          NUMBER
);
COMMENT ON COLUMN xxwsh.xxwsh_stock_delivery_info_tmp2.ship_to_weight             IS '入庫先（重量）';
COMMENT ON COLUMN xxwsh.xxwsh_stock_delivery_info_tmp2.ship_to_capacity           IS '入庫先（容積）';
COMMENT ON COLUMN xxwsh.xxwsh_stock_delivery_info_tmp2.carrier_weight             IS '運送業者（重量）';
COMMENT ON COLUMN xxwsh.xxwsh_stock_delivery_info_tmp2.carrier_capacity           IS '運送業者（容積）';
