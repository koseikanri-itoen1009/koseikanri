ALTER TABLE xxcos.xxcos_rep_direct_list MODIFY
  (
     order_number            NUMBER       -- �󒍔ԍ�
    ,order_line_no           NUMBER       -- �󒍖���No.
    ,line_no                 NUMBER       -- ����No.
    ,order_quantity          NUMBER(13,2) -- �󒍐�
    ,deliver_actual_quantity NUMBER(13,2) -- �o�׎��ѐ�
    ,output_quantity         NUMBER(13,2) -- ���ِ�
  );
