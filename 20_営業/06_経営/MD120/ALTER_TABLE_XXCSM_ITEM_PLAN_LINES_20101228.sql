ALTER TABLE xxcsm.xxcsm_item_plan_lines MODIFY (
                     sales_budget         NUMBER(15,0) DEFAULT 0,    -- ������z
                     amount_gross_margin  NUMBER(15,0) DEFAULT 0,    -- �e���v(�V)
                     credit_rate          NUMBER(10,2) DEFAULT 0     -- �|��
);
