CREATE OR REPLACE VIEW APPS.XXCFF_LEASE_CONTRACT_DTL_INS_V
(
 CONTRACT_LINE_ID             -- _ñ¾×àhc
,CONTRACT_HEADER_ID           -- _ñàhc
,CONTRACT_LINE_NUM            -- _ñ}Ô
--yE_{Ò®_10871zMOD START Nakano
,TAX_CODE                     -- ÅàR[h
,TAX_NAME                     -- ÅàEv
--yE_{Ò®_10871zMOD END Nakano
,OBJECT_HEADER_ID             -- ¨àhc
,OBJECT_CODE                  -- ¨R[h
,DEPARTMENT_NAME              -- Çå¼
,ASSET_CATEGORY               -- YíÞ
,CATEGORY_NAME                -- YíÞ¼
,FIRST_INSTALLATION_PLACE     -- ñÝuæ
,FIRST_INSTALLATION_ADDRESS   -- ñÝuê
,CONTRACT_STATUS              -- _ñXe[^X
,CONTRACT_STATUS_NAME         -- _ñXe[^X¼
,FIRST_CHARGE                 -- ñz[X¿E[X¿
,FIRST_TAX_CHARGE             -- ñzÁïÅE[X¿
,FIRST_TOTAL_CHARGE           -- ñvE[X¿
,SECOND_CHARGE                -- 2ñÚÈ~z[X¿E[X¿
,SECOND_TAX_CHARGE            -- 2ñÚÈ~zÁïÅE[X¿
,SECOND_TOTAL_CHARGE          -- 2ñÚÈ~vE[X¿
,FIRST_DEDUCTION              -- ñz[XETz
,FIRST_TAX_DEDUCTION          -- ñzÁïÅETz
,FIRST_TOTAL_DEDUCTION        -- ñvETz
,SECOND_DEDUCTION             -- 2ñÚÈ~z[X¿ETz
,SECOND_TAX_DEDUCTION         -- 2ñÚÈ~zÁïÅETz
,SECOND_TOTAL_DEDUCTION       -- 2ñÚÈ~vETz
,FIRST_AFTER_DEDUCTION        -- ñz[XETã
,FIRST_TAX_AFTER_DEDUCTION    -- ñzÁïÅETã
,FIRST_TOTAL_AFTER_DEDUCTION  -- ñvETã
,SECOND_AFTER_DEDUCTION       -- 2ñÚÈ~z[X¿ETã
,SECOND_TAX_AFTER_DEDUCTION   -- 2ñÚÈ~zÁïÅETã
,SECOND_TOTAL_AFTER_DEDUCTION -- 2ñÚÈ~vETã
,GROSS_CHARGE                 -- z[X¿E[X¿
,GROSS_TAX_CHARGE             -- zÁïÅE[X¿
,GROSS_TOTAL_CHARGE           -- zvE[X¿
,GROSS_DEDUCTION              -- z[X¿ETz
,GROSS_TAX_DEDUCTION          -- zÁïÅETz
,GROSS_TOTAL_DEDUCTION        -- zvETz
,GROSS_AFTER_DEDUCTION        -- z[X¿ETã
,GROSS_TAX_AFTER_DEDUCTION    -- zÁïÅETã
,GROSS_TOTAL_AFTER_DEDUCTION  -- zvETã
,ESTIMATED_CASH_PRICE         -- ©Ï»àwü¿z
,PRESENT_VALUE_DISCOUNT_RATE  -- »Ý¿lø¦
,PRESENT_VALUE                -- »Ý¿l
,PRESENT_VALUE_STANDARD       -- A^@
,LIFE_IN_MONTHS               -- @èÏpN
,LIFE_IN_MONTHS_STANDARD      -- C^B
,LEASE_KIND                   -- [XíÞ
,LEASE_KIND_NAME              -- [XíÞ¼
,ORIGINAL_COST                -- æ¾¿z
,CALC_INTERESTED_RATE         -- vZq¦
,PAYMENT_YEARS                -- N
,CREATED_BY                   -- ì¬Ò
,CREATION_DATE                -- ì¬ú
,LAST_UPDATED_BY              -- ÅIXVÒ
,LAST_UPDATE_DATE             -- ÅIXVú
,LAST_UPDATE_LOGIN            -- ÅIXVOC
,REQUEST_ID                   -- vID
,PROGRAM_APPLICATION_ID       -- ºÝ¶ÚÝÄ¥ÌßÛ¸Þ×Ñ¥±ÌßØ¹°¼®ÝID
,PROGRAM_ID                   -- ºÝ¶ÚÝÄ¥ÌßÛ¸Þ×ÑID
,PROGRAM_UPDATE_DATE          -- ÌßÛ¸Þ×ÑXVú
,ROW_ID                       -- ROWID
,OBJECT_UPDATE_DATE           -- ¨wb_ÅIXVú
,PLAN_UPDATE_DATE             -- x¥væÅIXVú
)
AS
SELECT XCL.CONTRACT_LINE_ID                                        AS CONTRACT_LINE_ID
      ,XCL.CONTRACT_HEADER_ID                                      AS CONTRACT_HEADER_ID
      ,XCL.CONTRACT_LINE_NUM                                       AS CONTRACT_LINE_NUM
--yE_{Ò®_10871zMOD START Nakano
      ,NVL(XCL.TAX_CODE, XCH.TAX_CODE)                             AS TAX_CODE
      ,NVL(ATC2.DESCRIPTION, ATC1.DESCRIPTION)                     AS TAX_NAME
--yE_{Ò®_10871zMOD END Nakano
      ,XCL.OBJECT_HEADER_ID                                        AS OBJECT_HEADER_ID
      ,XOH.OBJECT_CODE                                             AS OBJECT_CODE
      ,XDV.DEPARTMENT_NAME                                         AS DEPARTMENT_NAME
      ,XCL.ASSET_CATEGORY                                          AS ASSET_CATEGORY
      ,XCV.CATEGORY_NAME                                           AS CATEGORY_NAME
      ,XCL.FIRST_INSTALLATION_PLACE                                AS FIRST_INSTALLATION_PLACE
      ,XCL.FIRST_INSTALLATION_ADDRESS                              AS FIRST_INSTALLATION_ADDRESS
      ,XCL.CONTRACT_STATUS                                         AS CONTRACT_STATUS
      ,XCS.CONTRACT_STATUS_NAME                                    AS CONTRACT_STATUS_NAME
      ,XCL.FIRST_CHARGE                                            AS FIRST_CHARGE
      ,XCL.FIRST_TAX_CHARGE                                        AS FIRST_TAX_CHARGE
      ,XCL.FIRST_TOTAL_CHARGE                                      AS FIRST_TOTAL_CHARGE
      ,XCL.SECOND_CHARGE                                           AS SECOND_CHARGE
      ,XCL.SECOND_TAX_CHARGE                                       AS SECOND_TAX_CHARGE
      ,XCL.SECOND_TOTAL_CHARGE                                     AS SECOND_TOTAL_CHARGE
      ,XCL.FIRST_DEDUCTION                                         AS FIRST_DEDUCTION
      ,XCL.FIRST_TAX_DEDUCTION                                     AS FIRST_TAX_DEDUCTION
      ,XCL.FIRST_TOTAL_DEDUCTION                                   AS FIRST_TOTAL_DEDUCTION
      ,XCL.SECOND_DEDUCTION                                        AS SECOND_DEDUCTION
      ,XCL.SECOND_TAX_DEDUCTION                                    AS SECOND_TAX_DEDUCTION
      ,XCL.SECOND_TOTAL_DEDUCTION                                  AS SECOND_TOTAL_DEDUCTION
      ,XCL.FIRST_CHARGE        - XCL.FIRST_DEDUCTION               AS FIRST_AFTER_DEDUCTION
      ,XCL.FIRST_TAX_CHARGE    - XCL.FIRST_TAX_DEDUCTION           AS FIRST_TAX_AFTER_DEDUCTION
      ,XCL.FIRST_TOTAL_CHARGE  - XCL.FIRST_TOTAL_DEDUCTION         AS FIRST_TOTAL_AFTER_DEDUCTION
      ,XCL.SECOND_CHARGE       - XCL.SECOND_DEDUCTION              AS SECOND_AFTER_DEDUCTION
      ,XCL.SECOND_TAX_CHARGE   - XCL.SECOND_TAX_DEDUCTION          AS SECOND_TAX_AFTER_DEDUCTION
      ,XCL.SECOND_TOTAL_CHARGE - XCL.SECOND_TOTAL_DEDUCTION        AS SECOND_TOTAL_AFTER_DEDUCTION
      ,XCL.GROSS_CHARGE                                            AS GROSS_CHARGE
      ,XCL.GROSS_TAX_CHARGE                                        AS GROSS_TAX_CHARGE
      ,XCL.GROSS_TOTAL_CHARGE                                      AS GROSS_TOTAL_CHARGE
      ,XCL.GROSS_DEDUCTION                                         AS GROSS_DEDUCTION
      ,XCL.GROSS_TAX_DEDUCTION                                     AS GROSS_TAX_DEDUCTION
      ,XCL.GROSS_TOTAL_DEDUCTION                                   AS GROSS_TOTAL_DEDUCTION
      ,XCL.GROSS_CHARGE       - XCL.GROSS_DEDUCTION                AS GROSS_AFTER_DEDUCTION
      ,XCL.GROSS_TAX_CHARGE   - XCL.GROSS_TAX_DEDUCTION            AS GROSS_TAX_AFTER_DEDUCTION
      ,XCL.GROSS_TOTAL_CHARGE - XCL.GROSS_TOTAL_DEDUCTION          AS GROSS_TOTAL_AFTER_DEDUCTION
      ,XCL.ESTIMATED_CASH_PRICE                                    AS ESTIMATED_CASH_PRICE
      ,XCL.PRESENT_VALUE_DISCOUNT_RATE * 100                       AS PRESENT_VALUE_DISCOUNT_RATE
      ,XCL.PRESENT_VALUE                                           AS PRESENT_VALUE
--yE_{Ò®_14830zMOD START Maeda
      --,ROUND(XCL.PRESENT_VALUE / XCL.ESTIMATED_CASH_PRICE * 100)   AS PRESENT_VALUE_STANDARD
      ,DECODE(LC.ATT7,'2',0,ROUND(XCL.PRESENT_VALUE / XCL.ESTIMATED_CASH_PRICE * 100))
                                                                   AS PRESENT_VALUE_STANDARD
--yE_{Ò®_14830zMOD END Maeda   
      ,XCL.LIFE_IN_MONTHS                                          AS LIFE_IN_MONTHS
--yE_{Ò®_14830zMOD START Maeda
      --,ROUND(XCH.PAYMENT_YEARS / XCL.LIFE_IN_MONTHS * 100)         AS LIFE_IN_MONTHS_STANDARD
      ,DECODE(LC.ATT7,'2',0,ROUND(XCH.PAYMENT_YEARS / XCL.LIFE_IN_MONTHS * 100) )
                                                                   AS LIFE_IN_MONTHS_STANDARD
--yE_{Ò®_14830zMOD END Maeda   
      ,XCL.LEASE_KIND                                              AS LEASE_KIND
      ,XLK.LEASE_KIND_NAME                                         AS LEASE_KIND_NAME
      ,XCL.ORIGINAL_COST                                           AS ORIGINAL_COST
      ,XCL.CALC_INTERESTED_RATE * 100                              AS CALC_INTERESTED_RATE
      ,XCH.PAYMENT_YEARS                                           AS PAYMENT_YEARS
      ,XCL.CREATED_BY                                              AS CREATED_BY
      ,XCL.CREATION_DATE                                           AS CREATION_DATE
      ,XCL.LAST_UPDATED_BY                                         AS LAST_UPDATED_BY
      ,XCL.LAST_UPDATE_DATE                                        AS LAST_UPDATE_DATE
      ,XCL.LAST_UPDATE_LOGIN                                       AS LAST_UPDATE_LOGIN
      ,XCL.REQUEST_ID                                              AS REQUEST_ID
      ,XCL.PROGRAM_APPLICATION_ID                                  AS PROGRAM_APPLICATION_ID
      ,XCL.PROGRAM_ID                                              AS PROGRAM_ID
      ,XCL.PROGRAM_UPDATE_DATE                                     AS PROGRAM_UPDATE_DATE
      ,XCL.ROWID                                                   AS ROW_ID
      ,XOH.LAST_UPDATE_DATE                                        AS OBJECT_UPDATE_DATE
      ,XPP.PLAN_UPDATE_DATE                                        AS PLAN_UPDATE_DATE
FROM   XXCFF_CONTRACT_HEADERS  XCH
      ,XXCFF_CONTRACT_LINES    XCL
      ,XXCFF_OBJECT_HEADERS    XOH
      ,XXCFF_DEPARTMENT_V      XDV
      ,XXCFF_CATEGORY_V        XCV
      ,XXCFF_CONTRACT_STATUS_V XCS
      ,XXCFF_LEASE_KIND_V      XLK
      ,(SELECT MAX(LAST_UPDATE_DATE) AS PLAN_UPDATE_DATE
              ,CONTRACT_LINE_ID
        FROM  XXCFF_PAY_PLANNING
        GROUP BY CONTRACT_LINE_ID) XPP
--yE_{Ò®_14830zADD START Maeda
      ,(SELECT FLV.LOOKUP_CODE LEASE_CLASS
            ,FLV.ATTRIBUTE7    ATT7  -- [X»è
        FROM
            FND_LOOKUP_VALUES  FLV
        WHERE
             FLV.LOOKUP_TYPE  = 'XXCFF1_LEASE_CLASS_CHECK'
       AND   FLV.LANGUAGE     = 'JA') LC
--yE_{Ò®_14830zADD END Maeda   
--yE_{Ò®_10871zMOD START Nakano
       ,AP_TAX_CODES           ATC1
       ,AP_TAX_CODES           ATC2
--yE_{Ò®_10871zMOD END Nakano
 WHERE XCH.CONTRACT_HEADER_ID = XCL.CONTRACT_HEADER_ID
 AND   XCL.OBJECT_HEADER_ID   = XOH.OBJECT_HEADER_ID
 AND   XCL.CONTRACT_LINE_ID   = XPP.CONTRACT_LINE_ID
 AND   XOH.DEPARTMENT_CODE    = XDV.DEPARTMENT_CODE
 AND   XCL.ASSET_CATEGORY     = XCV.CATEGORY_CODE
 AND   XCL.CONTRACT_STATUS    = XCS.CONTRACT_STATUS_CODE
 AND   XCL.LEASE_KIND         = XLK.LEASE_KIND_CODE
--yE_{Ò®_10871zMOD START Nakano
 AND   XCH.TAX_CODE      = ATC1.NAME(+)
 AND   XCL.TAX_CODE      = ATC2.NAME(+)
--yE_{Ò®_10871zMOD END Nakano
--yE_{Ò®_14830zADD START Maeda
 AND   LC.LEASE_CLASS = XCH.LEASE_CLASS
--yE_{Ò®_14830zADD END Maeda 
;
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.CONTRACT_LINE_ID             IS '_ñ¾×àhc';
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.CONTRACT_HEADER_ID           IS '_ñàhc';
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.CONTRACT_LINE_NUM            IS '_ñ}Ô';
--yE_{Ò®_10871zMOD START Nakano
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.TAX_CODE                     IS 'ÅàR[h';
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.TAX_NAME                     IS 'ÅàEv';
--yE_{Ò®_10871zMOD END Nakano
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.OBJECT_HEADER_ID             IS '¨àhc';
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.OBJECT_CODE                  IS '¨R[h';
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.DEPARTMENT_NAME              IS 'Çå¼';
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.ASSET_CATEGORY               IS 'YíÞ';
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.CATEGORY_NAME                IS 'YíÞ¼';
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.FIRST_INSTALLATION_PLACE     IS 'ñÝuæ';
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.FIRST_INSTALLATION_ADDRESS   IS 'ñÝuê';
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.CONTRACT_STATUS              IS '_ñXe[^X';
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.CONTRACT_STATUS_NAME         IS '_ñXe[^X¼';
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.FIRST_CHARGE                 IS 'ñz[X¿E[X¿';
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.FIRST_TAX_CHARGE             IS 'ñzÁïÅE[X¿';
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.FIRST_TOTAL_CHARGE           IS 'ñvE[X¿';
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.SECOND_CHARGE                IS '2ñÚÈ~z[X¿E[X¿';
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.SECOND_TAX_CHARGE            IS '2ñÚÈ~zÁïÅE[X¿';
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.SECOND_TOTAL_CHARGE          IS '2ñÚÈ~vE[X¿';
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.FIRST_DEDUCTION              IS 'ñz[XETz';
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.FIRST_TAX_DEDUCTION          IS 'ñzÁïÅETz';
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.FIRST_TOTAL_DEDUCTION        IS 'ñvETz';
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.SECOND_DEDUCTION             IS '2ñÚÈ~z[X¿ETz';
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.SECOND_TAX_DEDUCTION         IS '2ñÚÈ~zÁïÅETz';
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.SECOND_TOTAL_DEDUCTION       IS '2ñÚÈ~vETz';
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.FIRST_AFTER_DEDUCTION        IS 'ñz[XETã';
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.FIRST_TAX_AFTER_DEDUCTION    IS 'ñzÁïÅETã';
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.FIRST_TOTAL_AFTER_DEDUCTION  IS 'ñvETã';
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.SECOND_AFTER_DEDUCTION       IS '2ñÚÈ~z[X¿ETã';
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.SECOND_TAX_AFTER_DEDUCTION   IS '2ñÚÈ~zÁïÅETã';
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.SECOND_TOTAL_AFTER_DEDUCTION IS '2ñÚÈ~vETã';
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.GROSS_CHARGE                 IS 'z[X¿E[X¿';
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.GROSS_TAX_CHARGE             IS 'zÁïÅE[X¿';
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.GROSS_TOTAL_CHARGE           IS 'zvE[X¿';
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.GROSS_DEDUCTION              IS 'z[X¿ETz';
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.GROSS_TAX_DEDUCTION          IS 'zÁïÅETz';
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.GROSS_TOTAL_DEDUCTION        IS 'zvETz';
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.GROSS_AFTER_DEDUCTION        IS 'z[X¿ETã';
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.GROSS_TAX_AFTER_DEDUCTION    IS 'zÁïÅETã';
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.GROSS_TOTAL_AFTER_DEDUCTION  IS 'zvETã';
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.ESTIMATED_CASH_PRICE         IS '©Ï»àwü¿z';
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.PRESENT_VALUE_DISCOUNT_RATE  IS '»Ý¿lø¦';
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.PRESENT_VALUE                IS '»Ý¿l';
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.PRESENT_VALUE_STANDARD       IS 'A^@';
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.LIFE_IN_MONTHS               IS '@èÏpN';
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.LIFE_IN_MONTHS_STANDARD      IS 'C^B';
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.LEASE_KIND                   IS '[XíÞ';
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.LEASE_KIND_NAME              IS '[XíÞ¼';
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.ORIGINAL_COST                IS 'æ¾¿z';
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.CALC_INTERESTED_RATE         IS 'vZq¦';
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.PAYMENT_YEARS                IS 'N';
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.CREATED_BY                   IS 'ì¬Ò';
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.CREATION_DATE                IS 'ì¬ú';
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.LAST_UPDATED_BY              IS 'ÅIXVÒ';
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.LAST_UPDATE_DATE             IS 'ÅIXVú';
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.LAST_UPDATE_LOGIN            IS 'ÅIXVOC';
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.REQUEST_ID                   IS 'vID';
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.PROGRAM_APPLICATION_ID       IS 'ºÝ¶ÚÝÄ¥ÌßÛ¸Þ×Ñ¥±ÌßØ¹°¼®ÝID';
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.PROGRAM_ID                   IS 'ºÝ¶ÚÝÄ¥ÌßÛ¸Þ×ÑID';
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.PROGRAM_UPDATE_DATE          IS 'ÌßÛ¸Þ×ÑXVú';
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.ROW_ID                       IS 'ROW_ID';
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.OBJECT_UPDATE_DATE           IS '¨wb_ÅIXVú';
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.PLAN_UPDATE_DATE             IS 'x¥væÅIXVú';
COMMENT ON TABLE XXCFF_LEASE_CONTRACT_DTL_INS_V IS '[X_ño^æÊ¾×r[';
