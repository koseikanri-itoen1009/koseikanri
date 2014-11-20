CREATE OR REPLACE FORCE VIEW APPS.XXPO_SECURITY_SUPPLY_V
(SECURITY_CLASS,USER_ID,PERSON_ID,PERSON_CLASS,VENDOR_CODE,VENDOR_SITE_CODE,WHSE_CODE,SEGMENT1,FREQUENT_WHSE_CODE)
AS
SELECT /*伊藤園ユーザ*/
       '1'                        AS SECURITY_CLASS         -- セキュリティ区分
      ,FU.USER_ID                 AS USER_ID                -- ログインユーザID
      ,PAP.PERSON_ID              AS PERSON_ID              -- 従業員ID
      ,PAP.ATTRIBUTE3             AS PERSON_CLASS           -- 従業員区分
      ,TO_CHAR(NULL)              AS VENDOR_CODE            -- 仕入先コード
      ,TO_CHAR(NULL)              AS VENDOR_SITE_CODE       -- 仕入先サイトコード
      ,TO_CHAR(NULL)              AS WHSE_CODE              -- 倉庫コード
      ,TO_CHAR(NULL)              AS SEGMENT1               -- 保管倉庫コード
      ,TO_CHAR(NULL)              AS FREQUENT_WHSE_CODE     -- 主要保管倉庫コード
FROM   FND_USER                  FU
      ,PER_ALL_PEOPLE_F          PAP
WHERE  FU.EMPLOYEE_ID             = PAP.PERSON_ID
AND    PAP.ATTRIBUTE3             = '1'     -- 内部従業員
AND    TRUNC(SYSDATE)  BETWEEN TRUNC(PAP.EFFECTIVE_START_DATE)
                           AND TRUNC(PAP.EFFECTIVE_END_DATE)
UNION
SELECT /*パッカー・外注工場*/
       '2'                        AS SECURITY_CLASS         -- セキュリティ区分
      ,FU.USER_ID                 AS USER_ID                -- ログインユーザID
      ,PAP.PERSON_ID              AS PERSON_ID              -- 従業員ID
      ,PAP.ATTRIBUTE3             AS PERSON_CLASS           -- 従業員区分
      ,PAP.ATTRIBUTE4             AS VENDOR_CODE            -- 仕入先コード
      ,PAP.ATTRIBUTE6             AS VENDOR_SITE_CODE       -- 仕入先サイトコード
      ,TO_CHAR(NULL)              AS WHSE_CODE              -- 倉庫コード
      ,TO_CHAR(NULL)              AS SEGMENT1               -- 保管倉庫コード
      ,TO_CHAR(NULL)              AS FREQUENT_WHSE_CODE     -- 主要保管倉庫コード
FROM   FND_USER                  FU
      ,PER_ALL_PEOPLE_F          PAP
WHERE  FU.EMPLOYEE_ID             = PAP.PERSON_ID
AND    PAP.ATTRIBUTE3             = '2'     -- 外部従業員
AND    TRUNC(SYSDATE)  BETWEEN TRUNC(PAP.EFFECTIVE_START_DATE)
                           AND TRUNC(PAP.EFFECTIVE_END_DATE)
UNION
SELECT /*東洋埠頭-通常*/
       '3'                        AS SECURITY_CLASS         -- セキュリティ区分
      ,FU.USER_ID                 AS USER_ID                -- ログインユーザID
      ,PAP.PERSON_ID              AS PERSON_ID              -- 従業員ID
      ,PAP.ATTRIBUTE3             AS PERSON_CLASS           -- 従業員区分
      ,TO_CHAR(NULL)              AS VENDOR_CODE            -- 仕入先コード
      ,TO_CHAR(NULL)              AS VENDOR_SITE_CODE       -- 仕入先サイトコード
      ,XILV.WHSE_CODE             AS WHSE_CODE              -- 倉庫コード
      ,XILV.SEGMENT1              AS SEGMENT1               -- 保管倉庫コード
      ,XILV.FREQUENT_WHSE_CODE    AS FREQUENT_WHSE_CODE     -- 主要保管倉庫コード
FROM   FND_USER                  FU
      ,PER_ALL_PEOPLE_F          PAP
      ,XXCMN_ITEM_LOCATIONS_V    XILV
WHERE  FU.EMPLOYEE_ID                                   = PAP.PERSON_ID
AND    PAP.ATTRIBUTE3                                   = '2'                      -- 外部従業員
AND    TRUNC(SYSDATE)  BETWEEN TRUNC(PAP.EFFECTIVE_START_DATE)
                           AND TRUNC(PAP.EFFECTIVE_END_DATE)
AND    PAP.ATTRIBUTE4                                   = XILV.PURCHASE_CODE       -- 仕入先が等しい
AND    NVL(PAP.ATTRIBUTE6,NVL(XILV.PURCHASE_SITE_CODE,'ZZZZZZZZZZ'))      = NVL(XILV.PURCHASE_SITE_CODE,'ZZZZZZZZZZ')  -- 仕入先サイトが等しい
UNION
SELECT /*東洋埠頭-関連倉庫*/
       '3'                        AS SECURITY_CLASS         -- セキュリティ区分
      ,FU.USER_ID                 AS USER_ID                -- ログインユーザID
      ,PAP.PERSON_ID              AS PERSON_ID              -- 従業員ID
      ,PAP.ATTRIBUTE3             AS PERSON_CLASS           -- 従業員区分
      ,TO_CHAR(NULL)              AS VENDOR_CODE            -- 仕入先コード
      ,TO_CHAR(NULL)              AS VENDOR_SITE_CODE       -- 仕入先サイトコード
      ,XILV2.WHSE_CODE            AS WHSE_CODE              -- 倉庫コード
      ,XILV2.SEGMENT1             AS SEGMENT1               -- 保管倉庫コード
      ,XILV2.FREQUENT_WHSE_CODE   AS FREQUENT_WHSE_CODE     -- 主要保管倉庫コード
FROM   FND_USER                  FU
      ,PER_ALL_PEOPLE_F          PAP
      ,XXCMN_ITEM_LOCATIONS_V    XILV1
      ,XXCMN_ITEM_LOCATIONS_V    XILV2
WHERE  FU.EMPLOYEE_ID                                    = PAP.PERSON_ID
AND    PAP.ATTRIBUTE3                                    = '2'                       -- 外部従業員
AND    TRUNC(SYSDATE)  BETWEEN TRUNC(PAP.EFFECTIVE_START_DATE)
                           AND TRUNC(PAP.EFFECTIVE_END_DATE)
AND    PAP.ATTRIBUTE4                                    = XILV1.PURCHASE_CODE       -- 仕入先が等しい
AND    NVL(PAP.ATTRIBUTE6,NVL(XILV1.PURCHASE_SITE_CODE,'ZZZZZZZZZZ'))      = NVL(XILV1.PURCHASE_SITE_CODE,'ZZZZZZZZZZ')  -- 仕入先サイトが等しい
AND    XILV1.SEGMENT1                                    = XILV2.FREQUENT_WHSE_CODE  -- 主要倉庫コード対象となっている
AND    XILV2.SEGMENT1                                    <> XILV2.FREQUENT_WHSE_CODE -- 自分自身を親としていないもの
UNION
SELECT /*外部倉庫・資材メーカ*/
       '4'                        AS SECURITY_CLASS         -- セキュリティ区分
      ,FU.USER_ID                 AS USER_ID                -- ログインユーザID
      ,PAP.PERSON_ID              AS PERSON_ID              -- 従業員ID
      ,PAP.ATTRIBUTE3             AS PERSON_CLASS           -- 従業員区分
      ,TO_CHAR(NULL)              AS VENDOR_CODE            -- 仕入先コード
      ,TO_CHAR(NULL)              AS VENDOR_SITE_CODE       -- 仕入先サイトコード
      ,XILV.WHSE_CODE             AS WHSE_CODE              -- 倉庫コード
      ,XILV.SEGMENT1              AS SEGMENT1               -- 保管倉庫コード
      ,XILV.FREQUENT_WHSE_CODE    AS FREQUENT_WHSE_CODE     -- 主要保管倉庫コード
FROM   FND_USER                  FU
      ,PER_ALL_PEOPLE_F          PAP
      ,XXCMN_ITEM_LOCATIONS_V    XILV
WHERE  FU.EMPLOYEE_ID                                   = PAP.PERSON_ID
AND    PAP.ATTRIBUTE3                                   = '2'                      -- 外部従業員
AND    TRUNC(SYSDATE)  BETWEEN TRUNC(PAP.EFFECTIVE_START_DATE)
                           AND TRUNC(PAP.EFFECTIVE_END_DATE)
AND    PAP.ATTRIBUTE4                                   = XILV.PURCHASE_CODE       -- 仕入先が等しい
AND    NVL(PAP.ATTRIBUTE6,NVL(XILV.PURCHASE_SITE_CODE,'ZZZZZZZZZZ'))      = NVL(XILV.PURCHASE_SITE_CODE,'ZZZZZZZZZZ')  -- 仕入先サイトが等しい
/
COMMENT ON COLUMN XXPO_SECURITY_SUPPLY_V.SECURITY_CLASS         IS 'セキュリティ区分'
/
COMMENT ON COLUMN XXPO_SECURITY_SUPPLY_V.USER_ID                IS 'ログインユーザID'
/
COMMENT ON COLUMN XXPO_SECURITY_SUPPLY_V.PERSON_ID              IS '従業員ID'
/
COMMENT ON COLUMN XXPO_SECURITY_SUPPLY_V.PERSON_CLASS           IS '従業員区分'
/
COMMENT ON COLUMN XXPO_SECURITY_SUPPLY_V.VENDOR_CODE            IS '仕入先コード'
/
COMMENT ON COLUMN XXPO_SECURITY_SUPPLY_V.VENDOR_SITE_CODE       IS '仕入先サイトコード'
/
COMMENT ON COLUMN XXPO_SECURITY_SUPPLY_V.WHSE_CODE              IS '倉庫コード'
/
COMMENT ON COLUMN XXPO_SECURITY_SUPPLY_V.SEGMENT1               IS '保管倉庫コード'
/
COMMENT ON COLUMN XXPO_SECURITY_SUPPLY_V.FREQUENT_WHSE_CODE     IS '主要保管倉庫コード'
/
COMMENT ON TABLE  XXPO_SECURITY_SUPPLY_V                        IS 'XXPO有償支給セキュリティVIEW'
/
