ALTER TABLE XXCOS.XXCOS_REP_ORDER_LIST MODIFY
              (
                  ORDER_NUMBER                   NUMBER                        --受注番号
                 ,LINE_NUMBER                    NUMBER                        --明細番号
                 ,QUANTITY                       NUMBER(13,2)                  --数量
                 ,DLV_UNIT_PRICE                 NUMBER(13,2)                  --納品単価
                 ,ORDER_AMOUNT                   NUMBER                        --受注金額
              );