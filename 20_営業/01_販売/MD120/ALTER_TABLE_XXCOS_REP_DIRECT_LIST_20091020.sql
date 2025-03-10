ALTER TABLE xxcos.xxcos_rep_direct_list MODIFY
  (
     order_number            NUMBER       -- 受注番号
    ,order_line_no           NUMBER       -- 受注明細No.
    ,line_no                 NUMBER       -- 明細No.
    ,order_quantity          NUMBER(13,2) -- 受注数
    ,deliver_actual_quantity NUMBER(13,2) -- 出荷実績数
    ,output_quantity         NUMBER(13,2) -- 差異数
  );
