ALTER TABLE xxcsm.xxcsm_item_plan_lines MODIFY (
                     sales_budget         NUMBER(15,0) DEFAULT 0,    -- îÑè„ã‡äz
                     amount_gross_margin  NUMBER(15,0) DEFAULT 0,    -- ëeóòâv(êV)
                     credit_rate          NUMBER(10,2) DEFAULT 0     -- ä|ó¶
);
