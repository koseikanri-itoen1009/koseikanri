ALTER TABLE XXCOS.XXCOS_REP_DELI_REQ MODIFY
  (
    ORDER_LINE_NUMBER              NUMBER,                           --受注明細番号
    CONTENT                        NUMBER,                           --入数
    SHIPMENT_QUANTITY              NUMBER                            --出荷数量
  );