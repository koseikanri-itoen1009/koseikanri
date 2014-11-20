CREATE OR REPLACE FORCE VIEW XXCFF_LEASED_ASSETS_V
(
LEASE_CLASS                  --リース種別コード
,LEASE_CLASS_NAME            --リース種別
,CONTRACT_NUMBER             --契約番号
,LEASE_TYPE                  --リース区分
,LEASE_TYPE_NAME
,LEASE_COMPANY               --リース会社コード
,PAYMENT_FREQUENCY           --支払回数
,PAYMENT_TYPE                --頻度
,CONTRACT_DATE               --契約日
,LEASE_START_DATE            --リース開始日
,LEASE_END_DATE              --リース終了日
,LEASE_KIND                  --リース種類
,CONTRACT_LINE_NUM           --契約枝番
,FIRST_INSTALLATION_ADDRESS  --初回設置場所
,FIRST_INSTALLATION_PLACE    --初回設置先
,EXPIRATION_DATE             --満了日
,CANCELLATION_DATE           --中途解約日
,ORIGINAL_COST               --取得価額
,FIRST_CHARGE                --初回月額リース（税抜）
,FIRST_TAX_CHARGE            --初回月額消費税額
,FIRST_TOTAL_CHARGE          --初回月額リース（税込）
,SECOND_CHARGE               --２回目以降月額リース料（税抜）
,SECOND_TAX_CHARGE           --２回目以降月額消費税額
,SECOND_TOTAL_CHARGE         --２回目以降月額リース（税込）
,FIRST_DEDUCTION             --月額リース控除額（税抜）
,FIRST_TAX_DEDUCTION         --月額リース控除消費税額
,FIRST_TOTAL_DEDUCTION       --月額リース控除額（税込）
,GROSS_CHARGE                --リース料総額（税抜）
,GROSS_TAX_CHARGE            --リース消費税総額
,GROSS_TOTAL_CHARGE          --リース料総額（税込）
,GROSS_DEDUCTION             --控除額総額（税抜）
,GROSS_TAX_DEDUCTION         --控除額消費税総額
,GROSS_TOTAL_DEDUCTION       --控除額総額（税込）
,DEPARTMENT_CODE             --管理部門コード
,OWNER_COMPANY               --本社/工場区分
,OBJECT_CODE                 --物件コード
,CHASSIS_NUMBER              --車台番号
,RE_LEASE_TIMES              --再リース回数
,AGE_TYPE                    --年式
,MODEL                       --機種
,SERIAL_NUMBER               --機番
,MANUFACTURER_NAME           --メーカー名（製造者名）
,INSTALLATION_ADDRESS        --現設置場所
,INSTALLATION_PLACE          --現設置先
,CANCELLATION_TYPE           --中途解約区分
,CANCELLATION_TYPE_NAME      --中途解約区分名称
,BOND_ACCEPTANCE_DATE        --証書受領日
,OBJECT_STATUS               --物件ステータス
,SEGMENT2_DESC               --管理部門
,LEASE_CLASS_CODE            --リース種別
,LEASE_COMPANY_CODE          --リース会社コード
,LEASE_COMPANY_NAME          --リース会社
,LAST_UPDATE_DATE            --最終更新日
,LAST_UPDATED_BY             --最終更新者
,CREATED_BY                  --作成者
,CREATION_DATE               --作成日
,LAST_UPDATE_LOGIN           --最終更新ログイン
)
AS 
SELECT  XOH.LEASE_CLASS                 --リース種別コード
       ,XLCV.LEASE_CLASS_NAME           --リース種別
       ,CON.CONTRACT_NUMBER             --契約番号
       ,XOH.LEASE_TYPE                  --リース区分
       ,XLTV.LEASE_TYPE_NAME            --リース区分名称
       ,CON.LEASE_COMPANY               --リース会社コード
       ,CON.PAYMENT_FREQUENCY           --支払回数
       ,CON.PAYMENT_TYPE                --頻度
       ,CON.CONTRACT_DATE               --契約日
       ,CON.LEASE_START_DATE            --リース開始日
       ,CON.LEASE_END_DATE              --リース終了日
       ,CON.LEASE_KIND                  --リース種類
       ,CON.CONTRACT_LINE_NUM           --契約枝番
       ,CON.FIRST_INSTALLATION_ADDRESS  --初回設置場所
       ,CON.FIRST_INSTALLATION_PLACE    --初回設置先
       ,CON.EXPIRATION_DATE             --満了日
       ,CON.CANCELLATION_DATE           --中途解約日
       ,CON.ORIGINAL_COST               --取得価額
       ,CON.FIRST_CHARGE                --初回月額リース（税抜）
       ,CON.FIRST_TAX_CHARGE            --初回月額消費税額
       ,CON.FIRST_TOTAL_CHARGE          --初回月額リース（税込）
       ,CON.SECOND_CHARGE               --２回目以降月額リース料（税抜）
       ,CON.SECOND_TAX_CHARGE           --２回目以降月額消費税額
       ,CON.SECOND_TOTAL_CHARGE         --２回目以降月額リース（税込）
       ,CON.FIRST_DEDUCTION             --月額リース控除額（税抜）
       ,CON.FIRST_TAX_DEDUCTION         --月額リース控除消費税額
       ,CON.FIRST_TOTAL_DEDUCTION       --月額リース控除額（税込）
       ,CON.GROSS_CHARGE                --リース料総額（税抜）
       ,CON.GROSS_TAX_CHARGE            --リース消費税総額
       ,CON.GROSS_TOTAL_CHARGE          --リース料総額（税込）
       ,CON.GROSS_DEDUCTION             --控除額総額（税抜）
       ,CON.GROSS_TAX_DEDUCTION         --控除額消費税総額
       ,CON.GROSS_TOTAL_DEDUCTION       --控除額総額（税込）
       ,XOH.DEPARTMENT_CODE             --管理部門コード
       ,XOH.OWNER_COMPANY               --本社/工場区分
       ,XOH.OBJECT_CODE                 --物件コード
       ,XOH.CHASSIS_NUMBER              --車台番号
       ,XOH.RE_LEASE_TIMES              --再リース回数
       ,XOH.AGE_TYPE                    --年式
       ,XOH.MODEL                       --機種
       ,XOH.SERIAL_NUMBER               --機番
       ,XOH.MANUFACTURER_NAME           --メーカー名（製造者名）
       ,XOH.INSTALLATION_ADDRESS        --現設置場所
       ,XOH.INSTALLATION_PLACE          --現設置先
       ,XOH.CANCELLATION_TYPE           --中途解約区分
       ,XCTV.CANCELLATION_TYPE_NAME     --中途解約区分名称
       ,XOH.BOND_ACCEPTANCE_DATE        --証書受領日
       ,XOH.OBJECT_STATUS AS  SEGMENT2_DESC--物件ステータス
       ,XDV.DEPARTMENT_NAME              --管理部門
       ,XLCV.LEASE_CLASS_CODE           --リース種類
       ,CON.LEASE_COMPANY_CODE        --リース会社
       ,CON.LEASE_COMPANY_NAME        --リース会社名
       ,XOH.LAST_UPDATE_DATE          --最終更新日
       ,XOH.LAST_UPDATED_BY           --最終更新者
       ,XOH.CREATED_BY                --作成者
       ,XOH.CREATION_DATE             --作成日
       ,XOH.LAST_UPDATE_LOGIN         --最終更新ログイン
FROM    XXCFF_OBJECT_HEADERS      XOH    --リース物件
       ,XXCFF_DEPARTMENT_V        XDV   --事業所マスタVIEW
       ,XXCFF_LEASE_CLASS_V       XLCV   --リース種別ビュー
       ,XXCFF_LEASE_TYPE_V        XLTV   --リース区分ビュー
       ,XXCFF_CANCELLATION_TYPE_V XCTV   --リース解約区分ビュー
       ,(SELECT  XCH.LEASE_CLASS                 --リース種別コード
                ,XCH.RE_LEASE_TIMES
                ,XCH.CONTRACT_NUMBER             --契約番号
--                ,XCH.LEASE_TYPE                  --リース区分
                ,XCH.LEASE_COMPANY               --リース会社コード
                ,XCH.PAYMENT_FREQUENCY           --支払回数
                ,XCH.PAYMENT_TYPE                --頻度
                ,XCH.CONTRACT_DATE               --契約日
                ,XCH.LEASE_START_DATE            --リース開始日
                ,XCH.LEASE_END_DATE              --リース終了日
                ,XCL.OBJECT_HEADER_ID
                ,XCL.LEASE_KIND                  --リース種類
                ,XCL.CONTRACT_LINE_NUM           --契約枝番
                ,XCL.FIRST_INSTALLATION_ADDRESS  --初回設置場所
                ,XCL.FIRST_INSTALLATION_PLACE    --初回設置先
                ,XCL.EXPIRATION_DATE             --満了日
                ,XCL.CANCELLATION_DATE           --中途解約日
                ,XCL.ORIGINAL_COST               --取得価額
                ,XCL.FIRST_CHARGE                --初回月額リース（税抜）
                ,XCL.FIRST_TAX_CHARGE            --初回月額消費税額
                ,XCL.FIRST_TOTAL_CHARGE          --初回月額リース（税込）
                ,XCL.SECOND_CHARGE               --２回目以降月額リース料（税抜）
                ,XCL.SECOND_TAX_CHARGE           --２回目以降月額消費税額
                ,XCL.SECOND_TOTAL_CHARGE         --２回目以降月額リース（税込）
                ,XCL.FIRST_DEDUCTION             --月額リース控除額（税抜）
                ,XCL.FIRST_TAX_DEDUCTION         --月額リース控除消費税額
                ,XCL.FIRST_TOTAL_DEDUCTION       --月額リース控除額（税込）
                ,XCL.GROSS_CHARGE                --リース料総額（税抜）
                ,XCL.GROSS_TAX_CHARGE            --リース消費税総額
                ,XCL.GROSS_TOTAL_CHARGE          --リース料総額（税込）
                ,XCL.GROSS_DEDUCTION             --控除額総額（税抜）
                ,XCL.GROSS_TAX_DEDUCTION         --控除額消費税総額
                ,XCL.GROSS_TOTAL_DEDUCTION       --控除額総額（税込）
                ,XLCOV.LEASE_COMPANY_CODE        --リース会社
                ,XLCOV.LEASE_COMPANY_NAME        --リース会社名
         FROM    XXCFF_CONTRACT_HEADERS XCH      --リース契約
                ,XXCFF_CONTRACT_LINES   XCL      --リース契約明細
                ,XXCFF_LEASE_COMPANY_V  XLCOV    --リース会社ビュー
         WHERE   XCH.CONTRACT_HEADER_ID   = XCL.CONTRACT_HEADER_ID
         AND     XCH.LEASE_COMPANY        = XLCOV.LEASE_COMPANY_CODE) CON
WHERE XOH.OBJECT_HEADER_ID     = CON.OBJECT_HEADER_ID(+)
AND   XOH.RE_LEASE_TIMES       = CON.RE_LEASE_TIMES(+)
AND   XOH.DEPARTMENT_CODE      = XDV.DEPARTMENT_CODE(+)
AND   XOH.LEASE_CLASS          = XLCV.LEASE_CLASS_CODE
AND   XOH.LEASE_TYPE           = XLTV.LEASE_TYPE_CODE
AND   XOH.CANCELLATION_TYPE    = XCTV.CANCELLATION_TYPE_CODE(+)
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.LEASE_CLASS IS                 'リース種別コード'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.LEASE_CLASS_NAME IS            'リース種別'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.CONTRACT_NUMBER IS             '契約番号'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.LEASE_TYPE IS                  'リース区分'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.LEASE_TYPE_NAME IS             'リース区分名称'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.LEASE_COMPANY IS               'リース会社コード'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.PAYMENT_FREQUENCY IS           '支払回数'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.PAYMENT_TYPE IS                '頻度'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.CONTRACT_DATE IS               '契約日'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.LEASE_START_DATE IS            'リース開始日'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.LEASE_END_DATE IS              'リース終了日'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.LEASE_KIND IS                  'リース種類'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.CONTRACT_LINE_NUM IS           '契約枝番'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.FIRST_INSTALLATION_ADDRESS IS  '初回設置場所'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.FIRST_INSTALLATION_PLACE IS    '初回設置先'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.EXPIRATION_DATE IS             '満了日'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.CANCELLATION_DATE IS           '中途解約日'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.ORIGINAL_COST IS               '取得価額'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.FIRST_CHARGE IS                '初回月額リース（税抜）'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.FIRST_TAX_CHARGE IS            '初回月額消費税額'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.FIRST_TOTAL_CHARGE IS          '初回月額リース（税込）'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.SECOND_CHARGE IS               '２回目以降月額リース料（税抜）'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.SECOND_TAX_CHARGE IS           '２回目以降月額消費税額'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.SECOND_TOTAL_CHARGE IS         '２回目以降月額リース（税込）'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.FIRST_DEDUCTION IS             '月額リース控除額（税抜）'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.FIRST_TAX_DEDUCTION IS         '月額リース控除消費税額'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.FIRST_TOTAL_DEDUCTION IS       '月額リース控除額（税込）'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.GROSS_CHARGE IS                'リース料総額（税抜）'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.GROSS_TAX_CHARGE IS            'リース消費税総額'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.GROSS_TOTAL_CHARGE IS          'リース料総額（税込）'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.GROSS_DEDUCTION IS             '控除額総額（税抜）'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.GROSS_TAX_DEDUCTION IS         '控除額消費税総額'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.GROSS_TOTAL_DEDUCTION IS       '控除額総額（税込）'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.DEPARTMENT_CODE IS             '管理部門コード'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.OWNER_COMPANY IS               '本社/工場区分'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.OBJECT_CODE IS                 '物件コード'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.CHASSIS_NUMBER IS              '車台番号'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.RE_LEASE_TIMES IS              '再リース回数'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.AGE_TYPE IS                    '年式'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.MODEL IS                       '機種'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.SERIAL_NUMBER IS               '機番'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.MANUFACTURER_NAME IS           'メーカー名（製造者名）'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.INSTALLATION_ADDRESS IS        '現設置場所'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.INSTALLATION_PLACE IS          '現設置先'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.CANCELLATION_TYPE IS           '中途解約区分'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.CANCELLATION_TYPE_NAME IS      '中途解約区分名称'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.BOND_ACCEPTANCE_DATE IS        '証書受領日'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.OBJECT_STATUS IS               '物件ステータス'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.SEGMENT2_DESC IS              '管理部門'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.LEASE_CLASS_CODE IS           'リース種別'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.LEASE_COMPANY_CODE IS        'リース会社コード'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.LEASE_COMPANY_NAME IS        'リース会社'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.LAST_UPDATE_DATE IS '最終更新日'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.LAST_UPDATED_BY IS '最終更新者'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.CREATED_BY IS '作成者'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.CREATION_DATE IS '作成日'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.LAST_UPDATE_LOGIN IS '最終更新ログイン'
/
COMMENT ON TABLE XXCFF_LEASED_ASSETS_V IS 'リース資産一覧画面ビュー'
/
