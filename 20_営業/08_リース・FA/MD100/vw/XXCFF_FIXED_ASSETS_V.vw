CREATE OR REPLACE FORCE VIEW XXCFF_FIXED_ASSETS_V
(
ASSET_ID,                      --資産ID
ASSET_NUMBER,                  --資産番号
BOOK_TYPE_CODE,                --台帳名
COST,                          --取得価額
ADJUSTED_RECOVERABLE_COST,     --償却対象額
DEPRN_RESERVE,                 --純帳簿価額
-- ADD E_本稼動_04156 2010/08/04 Start
LAST_FISCAL_YEAR,              --台帳最新会計年度
DEPRN_FISCAL_YEAR,             --最終償却時会計年度
-- ADD E_本稼動_04156 2010/08/04 End
YTD_DEPRN,                     --年償却累計額
TOTAL_AMOUNT,                  --償却累計額
--
-- Modify E_本稼動_14502 2017/12/14 Start
MONTH_DEPRN,                   --当月償却累計額
BONUS_DEPRN_AMOUNT,            --ﾎﾞｰﾅｽ償却
BONUS_YTD_DEPRN,               --ﾎﾞｰﾅｽ年償却累計額
BONUS_DEPRN_RESERVE,           --ﾎﾞｰﾅｽ償却累計額
-- Modify E_本稼動_14502 2017/12/14 End
--
PERIOD_NAME,                   --減価償却対象期間
ORIGINAL_COST,                 --当初取得価額
SALVAGE_VALUE,                 --残存価額
DATE_PLACED_IN_SERVICE,        --事業供用日
CATEGORY_CODE,                 --カテ_種類CODE
CATEGORY_NAME,                 --カテ_種類DESC
DCLR_DPRN_CODE,                --カテ_償却申告CODE
DCLR_DPRN_NAME,                --カテ_償却申告DESC
ASSET_ACCOUNT_CODE,            --カテ_資産勘定CODE
ASSET_ACCOUNT_NAME,            --カテ_資産勘定DESC
ACCOUNT_CODE,                  --カテ_償却科目CODE
ACCOUNT_NAME,                  --カテ_償却科目DESC
SEGMENT5,                      --カテ_耐用年数CODE
SEGMENT5_DESC,                 --カテ_耐用年数DESC
DPRN_METHOD_CODE,              --カテ_償却方法CODE
DPRN_METHOD_NAME,              --カテ_償却方法DESC
LEASE_CLASS_CODE,              --カテ_リース種別CODE
LEASE_CLASS_NAME,              --カテ_リース種別DESC
DCLR_PLACE_CODE,               --ロケ_申告地CODE
DCLR_PLACE_NAME,               --ロケ_申告地DESC
DEPARTMENT_CODE,               --ロケ_管理部門CODE
DEPARTMENT_NAME,               --ロケ_管理部門DESC
MNG_PLACE_CODE,                --ロケ_事業所CODE
MNG_PLACE_NAME,                --ロケ_事業所DESC
PLACE_CODE,                    --ロケ_場所CODE
PLACE_NAME,                    --ロケ_場所DESC
OWNER_COMPANY_CODE,            --ロケ_本社工場区分CODE
OWNER_COMPANY_NAME,            --ロケ_本社工場区分DESC
ACC_COMPANY_CODE,              --会計_会社CODE
ACC_COMPANY_NAME,              --会計_会社DESC
ACC_DEPARTMENT_CODE,           --会計_部門CODE
ACC_DEPARTMENT_NAME,           --会計_部門DESC
ACC_DPRN_ACCOUNT_CODE,         --会計_勘定科目CODE
ACC_DPRN_ACCOUNT_NAME,         --会計_勘定科目DESC
ACC_DPRN_SUB_ACCOUNT_CODE,     --会計_補助科目CODE
ACC_DPRN_SUB_ACCOUNT_NAME,     --会計_補助科目DESC
ACC_DPRN_CUSTOMER_CODE,        --会計_顧客コードCODE
ACC_DPRN_CUSTOMER_NAME,        --会計_顧客コードDESC
ACC_DPRN_ENTERPRISE_CODE,      --会計_企業コードCODE
ACC_DPRN_ENTERPRISE_NAME,      --会計_企業コードDESC
ACC_DPRN_RESERVE1_CODE,        --会計_予備1CODE
ACC_DPRN_RESERVE1_NAME,        --会計_予備1DESC
ACC_DPRN_RESERVE2_CODE,        --会計_予備2CODE
ACC_DPRN_RESERVE2_NAME,        --会計_予備2DESC
CODE_COMBINATION_ID,           --減価償却ID
DESCRIPTION,                   --摘要
CURRENT_UNITS,                 --単位
DEPRN_METHOD_CODE,             --償却方法
--
-- Modify E_本稼動_14502 2017/12/14 Start
RATE,                          --償却率(普通償却率)
-- Modify E_本稼動_14502 2017/12/14 End
--
LIFE_IN_YEAR,                  --耐用年数_年
LIFE_IN_MONTHS,                --耐用年数_月
RESERVE1_CODE1,                --予備1
RESERVE1_CODE2,                --予備2
ATTRIBUTE1,                    --更新用事業供用日
ATTRIBUTE2,                    --取得日
ATTRIBUTE3,                    --構造
ATTRIBUTE4,                    --細目
ATTRIBUTE5,                    --圧縮記帳・控除方式
ATTRIBUTE6,                    --圧縮控除額
ATTRIBUTE7,                    --圧縮後取得価額
ATTRIBUTE8,                    --資産グループ番号
ATTRIBUTE9,                    --減損計算期間履歴
ATTRIBUTE10,                   --物件コード
ATTRIBUTE11,                   --リース資産
ATTRIBUTE12,                   --開示セグメント
ATTRIBUTE13,                   --面積
--
-- Modify E_本稼動_14502 2017/12/14 Start
ATTRIBUTE17,                   --IFRS不動産取得税
ATTRIBUTE18,                   --IFRS借入コスト
ATTRIBUTE19,                   --IFRSその他
ATTRIBUTE22,                   --固定資産資産番号
ATTRIBUTE23,                   --IFRS対象資産番号
-- Modify E_本稼動_14502 2017/12/14 End
--
LAST_UPDATE_DATE,              --最終更新日
LAST_UPDATED_BY,               --最終更新者
CREATED_BY,                    --作成者
CREATION_DATE,                 --作成日
--
-- Modify E_本稼動_14502 2017/12/14 Start
--LAST_UPDATE_LOGIN              --最終更新ログイン
LAST_UPDATE_LOGIN,              --最終更新ログイン
-- Modify E_本稼動_14502 2017/12/14 End
--
-- Modify E_本稼動_14502 2017/12/14 Start
KISYU_BOKA,                       -- 期首帳簿価額
YEAR_ADD_AMOUNT,                  -- 期中増加額
ADD_AMOUNT,                       -- 当期増加額
YEAR_DEL_AMOUNT,                  -- 期中減少額
DELETE_AMOUNT,                    -- 当期減少額
DEPRN_RESERVE_12                  -- 期末純帳簿価額
-- Modify E_本稼動_14502 2017/12/14 End
)
AS 
-- Modify 2009.08.19 Ver1.1 Start
--  SELECT MAIN.ASSET_ID                AS ASSET_ID--資産ID
  SELECT
         /*+   
-- Modify E_最終移行リハ_00469 2009.10.13 Start
           LEADING(MAIN) --LEADING(MAIN.B)
-- Modify E_最終移行リハ_00469 2009.10.13 End
           USE_NL(MAIN C FC D FA FL CC)
           INDEX(FBC      FA_BOOK_CONTROLS_U1)
           INDEX(C.B      FA_ADDITIONS_B_U1)
           INDEX(C.T      FA_ADDITIONS_TL_U1)
           INDEX(D        FA_DISTRIBUTION_HISTORY_N2)
           INDEX(FA       FA_ASSET_KEYWORDS_U1)
           INDEX(CC.GCC   GL_CODE_COMBINATIONS_U1) 
           INDEX(FC.FCB.T FA_CATEGORIES_TL_U1)
           INDEX(FC.FCB.B FA_CATEGORIES_B_U1)
           INDEX(FL.FLC   FA_LOCATIONS_U1)
         */
       MAIN.ASSET_ID                AS ASSET_ID--資産ID
-- Modify 2009.08.19 Ver1.1 End
      ,C.ASSET_NUMBER               AS ASSET_NUMBER--資産番号
      ,MAIN.BOOK_TYPE_CODE          AS BOOK_TYPE_CODE--台帳名
      ,MAIN.COST                    AS COST--取得価額
      ,MAIN.ADJUSTED_RECOVERABLE_COST  AS ADJUSTED_RECOVERABLE_COST--償却対象額
      ,MAIN.DEPRN_RESERVE           AS DEPRN_RESERVE--純帳簿価額
--
-- Modify E_本稼動_04156 2010/08/04 Start
      ,MAIN.LAST_FISCAL_YEAR        AS LAST_FISCAL_YEAR  --台帳の最新会計年度
      ,MAIN.DEPRN_FISCAL_YEAR       AS DEPRN_FISCAL_YEAR --資産の最終償却時の会計年度
      ,CASE
         WHEN (MAIN.LAST_FISCAL_YEAR = MAIN.DEPRN_FISCAL_YEAR) THEN
           MAIN.YTD_DEPRN
         ELSE
           0
         END YTD_DEPRN                                       --年償却累計額
      --,MAIN.YTD_DEPRN               AS YTD_DEPRN--年償却累計額
-- Modify E_本稼動_04156 2010/08/04 End
--
      ,MAIN.TOTAL_AMOUNT            AS TOTAL_AMOUNT--償却累計額
--
-- Modify E_本稼動_14502 2017/12/14 Start
      ,MAIN.MONTH_DEPRN                 AS MONTH_DEPRN                      -- 当月償却累計額
      ,MAIN.BONUS_DEPRN_AMOUNT          AS BONUS_DEPRN_AMOUNT               -- ﾎﾞｰﾅｽ償却
      ,MAIN.BONUS_YTD_DEPRN             AS BONUS_YTD_DEPRN                  -- ﾎﾞｰﾅｽ年償却累計額
      ,MAIN.BONUS_DEPRN_RESERVE         AS BONUS_DEPRN_RESERVE              -- ﾎﾞｰﾅｽ償却累計額
-- Modify E_本稼動_14502 2017/12/14 end
--
-- Modify 2009.08.19 Ver1.1 Start
--      ,FDP.PERIOD_NAME              AS PERIOD_NAME--減価償却対象期間
      ,MAIN.PERIOD_NAME             AS PERIOD_NAME--減価償却対象期間
-- Modify 2009.08.19 Ver1.1 End
      ,MAIN.ORIGINAL_COST           AS ORIGINAL_COST--当初取得価額
      ,MAIN.SALVAGE_VALUE           AS SALVAGE_VALUE--残存価額
      ,MAIN.DATE_PLACED_IN_SERVICE  AS DATE_PLACED_IN_SERVICE--事業供用日
      ,FC.SEGMENT1                  AS CATEGORY_CODE--カテ_種類CODE
      ,FC.SEGMENT1_DESC             AS CATEGORY_NAME--カテ_種類DESC
      ,FC.SEGMENT2                  AS DCLR_DPRN_CODE--カテ_償却申告CODE
      ,FC.SEGMENT2_DESC             AS DCLR_DPRN_NAME--カテ_償却申告DESC
      ,FC.SEGMENT3                  AS ASSET_ACCOUNT_CODE--カテ_資産勘定CODE
      ,FC.SEGMENT3_DESC             AS ASSET_ACCOUNT_NAME--カテ_資産勘定DESC
      ,FC.SEGMENT4                  AS ACCOUNT_CODE--カテ_償却科目CODE
      ,FC.SEGMENT4_DESC             AS ACCOUNT_NAME--カテ_償却科目DESC
      ,FC.SEGMENT5                  AS SEGMENT5--カテ_耐用年数CODE
      ,FC.SEGMENT5_DESC             AS SEGMENT5_DESC--カテ_耐用年数DESC
      ,FC.SEGMENT6                  AS DPRN_METHOD_CODE--カテ_償却方法CODE
      ,FC.SEGMENT6_DESC             AS DPRN_METHOD_NAME--カテ_償却方法DESC
      ,FC.SEGMENT7                  AS LEASE_CLASS_CODE--カテ_リース種別CODE
      ,FC.SEGMENT7_DESC             AS LEASE_CLASS_NAME--カテ_リース種別DESC
      ,FL.SEGMENT1                  AS DCLR_PLACE_CODE--ロケ_申告地CODE
      ,FL.SEGMENT1_DESC             AS DCLR_PLACE_NAME--ロケ_申告地DESC
      ,FL.SEGMENT2                  AS DEPARTMENT_CODE--ロケ_管理部門CODE
      ,FL.SEGMENT2_DESC             AS DEPARTMENT_NAME--ロケ_管理部門DESC
      ,FL.SEGMENT3                  AS MNG_PLACE_CODE--ロケ_事業所CODE
      ,FL.SEGMENT3_DESC             AS MNG_PLACE_NAME--ロケ_事業所DESC
      ,FL.SEGMENT4                  AS PLACE_CODE--ロケ_場所CODE
      ,FL.SEGMENT4                  AS PLACE_NAME--ロケ_場所DESC
      ,FL.SEGMENT5                  AS OWNER_COMPANY_CODE--ロケ_本社工場区分CODE
      ,FL.SEGMENT5_DESC             AS OWNER_COMPANY_NAME--ロケ_本社工場区分DESC
      ,CC.SEGMENT1                  AS ACC_COMPANY_CODE--会計_会社CODE
      ,CC.SEGMENT1_DESC             AS ACC_COMPANY_NAME--会計_会社DESC
      ,CC.SEGMENT2                  AS ACC_DEPARTMENT_CODE--会計_部門CODE
      ,CC.SEGMENT2_DESC             AS ACC_DEPARTMENT_NAME--会計_部門DESC
      ,CC.SEGMENT3                  AS ACC_DPRN_ACCOUNT_CODE--会計_勘定科目CODE
      ,CC.SEGMENT3_DESC             AS ACC_DPRN_ACCOUNT_NAME--会計_勘定科目DESC
      ,CC.SEGMENT4                  AS ACC_DPRN_SUB_ACCOUNT_CODE--会計_補助科目CODE
      ,CC.SEGMENT4_DESC             AS ACC_DPRN_SUB_ACCOUNT_NAME--会計_補助科目DESC
      ,CC.SEGMENT5                  AS ACC_DPRN_CUSTOMER_CODE--会計_顧客コードCODE
      ,CC.SEGMENT5_DESC             AS ACC_DPRN_CUSTOMER_NAME--会計_顧客コードDESC
      ,CC.SEGMENT6                  AS ACC_DPRN_ENTERPRISE_CODE--会計_企業コードCODE
      ,CC.SEGMENT6_DESC             AS ACC_DPRN_ENTERPRISE_NAME--会計_企業コードDESC
      ,CC.SEGMENT7                  AS ACC_DPRN_RESERVE1_CODE--会計_予備1CODE
      ,CC.SEGMENT7_DESC             AS ACC_DPRN_RESERVE1_NAME--会計_予備1DESC
      ,CC.SEGMENT8                  AS ACC_DPRN_RESERVE2_CODE--会計_予備2CODE
      ,CC.SEGMENT8_DESC             AS ACC_DPRN_RESERVE2_NAME--会計_予備2DESC
      ,D.CODE_COMBINATION_ID        AS CODE_COMBINATION_ID--減価償却ID
      ,C.DESCRIPTION                AS DESCRIPTION--摘要
      ,C.CURRENT_UNITS              AS CURRENT_UNITS--単位
      ,MAIN.DEPRN_METHOD_CODE       AS DEPRN_METHOD_CODE--償却方法
--
-- Modify E_本稼動_14502 2017/12/14 Start
      ,MAIN.BASIC_RATE * 100            AS RATE                             -- 償却率(普通償却率)
-- Modify E_本稼動_14502 2017/12/14 End
--
      ,MAIN.LIFE_IN_YEAR            AS LIFE_IN_YEAR--耐用年数_年
      ,MAIN.LIFE_IN_MONTHS          AS LIFE_IN_MONTHS--耐用年数_月
      ,FA.SEGMENT1                  AS RESERVE1_CODE1  --予備1
      ,FA.SEGMENT2                  AS RESERVE1_CODE2  --予備2
      ,C.ATTRIBUTE1                 AS ATTRIBUTE1--更新用事業供用日
      ,C.ATTRIBUTE2                 AS ATTRIBUTE2--取得日
      ,C.ATTRIBUTE3                 AS ATTRIBUTE3--構造
      ,C.ATTRIBUTE4                 AS ATTRIBUTE4--細目
      ,C.ATTRIBUTE5                 AS ATTRIBUTE5--"圧縮記帳・控除方式"
      ,C.ATTRIBUTE6                 AS ATTRIBUTE6--圧縮控除額
      ,C.ATTRIBUTE7                 AS ATTRIBUTE7--圧縮後取得価額
      ,C.ATTRIBUTE8                 AS ATTRIBUTE8--資産グループ番号
      ,C.ATTRIBUTE9                 AS ATTRIBUTE9--減損計算期間履歴
      ,C.ATTRIBUTE10                AS ATTRIBUTE10--物件コード
      ,C.ATTRIBUTE11                AS ATTRIBUTE11--リース資産
      ,C.ATTRIBUTE12                AS ATTRIBUTE12--開示セグメント
      ,C.ATTRIBUTE13                AS ATTRIBUTE13--面積
--
-- Modify E_本稼動_14502 2017/12/14 Start
      ,C.ATTRIBUTE17                    AS ATTRIBUTE17                      -- IFRS不動産取得税
      ,C.ATTRIBUTE18                    AS ATTRIBUTE18                      -- IFRS借入コスト
      ,C.ATTRIBUTE19                    AS ATTRIBUTE19                      -- IFRSその他
      ,C.ATTRIBUTE22                    AS ATTRIBUTE22                      -- 固定資産資産番号
      ,C.ATTRIBUTE23                    AS ATTRIBUTE23                      -- IFRS対象資産番号
-- Modify E_本稼動_14502 2017/12/14 End
--
      ,C.LAST_UPDATE_DATE           AS LAST_UPDATE_DATE--最終更新日
      ,C.LAST_UPDATED_BY            AS LAST_UPDATED_BY--最終更新者
      ,C.CREATED_BY                 AS CREATED_BY--作成者
      ,C.CREATION_DATE              AS CREATION_DATE--作成日
      ,C.LAST_UPDATE_LOGIN          AS LAST_UPDATE_LOGIN--最終更新ログイン
--
-- Modify E_本稼動_14502 2018/01/12 Start
      ,CASE
         WHEN (NVL(KISYU.KISYU_BOKA, 0) = 0)
         AND  (TO_CHAR(MAIN.DATE_PLACED_IN_SERVICE,'YYYYMM') <= TO_CHAR(MAIN.CALENDAR_PERIOD_CLOSE_DATE,'YYYYMM')) THEN
           CASE
             WHEN (MAIN.LAST_FISCAL_YEAR = MAIN.DEPRN_FISCAL_YEAR) THEN
               MAIN.YTD_DEPRN + MAIN.DEPRN_RESERVE            --過去年度の資産を当年に資産追加した場合、期首簿価が取れないので、-期末純帳簿価額＋年償却累計額で算出
             ELSE
               MAIN.DEPRN_RESERVE
             END
         ELSE
           NVL(KISYU.KISYU_BOKA, 0)
         END                            AS KISYU_BOKA                       -- 期首帳簿価額
-- Modify E_本稼動_14502 2018/01/12 End
--
-- Modify E_本稼動_14502 2017/12/14 Start
      ,CASE
         WHEN (TO_CHAR(MAIN.DATE_PLACED_IN_SERVICE, 'YYYYMM') <= TO_CHAR(MAIN.CALENDAR_PERIOD_CLOSE_DATE, 'YYYYMM'))
         AND  (TO_CHAR(MAIN.DATE_PLACED_IN_SERVICE, 'YYYYMM') >= TO_CHAR(MAIN.CALENDAR_PERIOD_OPEN_DATE , 'YYYYMM')) THEN
           MAIN.COST
         ELSE
           0
         END                            AS YEAR_ADD_AMOUNT                  -- 期中増加額
      ,CASE
         WHEN (TO_CHAR(MAIN.DATE_PLACED_IN_SERVICE, 'YYYYMM') = TO_CHAR(MAIN.CALENDAR_PERIOD_CLOSE_DATE, 'YYYYMM')) THEN
           MAIN.COST
         ELSE
           0
         END                            AS ADD_AMOUNT                       -- 当期増加額
      ,CASE
         WHEN (TO_CHAR(MAIN.DATE_RETIRED, 'YYYYMM') <= TO_CHAR(MAIN.CALENDAR_PERIOD_CLOSE_DATE, 'YYYYMM'))
         AND  (TO_CHAR(MAIN.DATE_RETIRED, 'YYYYMM') >= TO_CHAR(MAIN.CALENDAR_PERIOD_OPEN_DATE, 'YYYYMM')) THEN
           MAIN.NBV_RETIRED     -- 除売却帳簿価額
         ELSE
           0
         END                            AS YEAR_DEL_AMOUNT                  -- 期中減少額
      ,CASE
        WHEN (TO_CHAR(MAIN.DATE_RETIRED, 'YYYYMM') = TO_CHAR(MAIN.CALENDAR_PERIOD_CLOSE_DATE, 'YYYYMM')) THEN
          MAIN.NBV_RETIRED      -- 除売却帳簿価額
        ELSE
          0
        END                             AS DELETE_AMOUNT                    -- 当期減少額
      ,MAIN.DEPRN_RESERVE               AS DEPRN_RESERVE_12                 -- 期末純帳簿価額
-- Modify E_本稼動_14502 2017/12/14 End
--
-- Modify 2009.08.19 Ver1.1 Start
--FROM   FA_BOOK_CONTROLS          FBC  -- 資産台帳
--      ,FA_ADDITIONS              C    -- 資産詳細
FROM   FA_ADDITIONS              C    -- 資産詳細
-- Modify 2009.08.19 Ver1.1 End
      ,FA_DISTRIBUTION_HISTORY   D    -- 資産割当
-- Modify 2009.08.19 Ver1.1 Start
--      ,FA_DEPRN_PERIODS          FDP  -- 減価償却期間
-- Modify 2009.08.19 Ver1.1 End
      ,XXCFF_FA_CATEGORY_V       FC   -- 資産カテゴリマスタ
      ,XXCFF_FA_LOCATION_V       FL   -- 事業所マスタ
      ,XXCFF_FA_CCID_V           CC   -- 勘定科目体系マスタ
      ,FA_ASSET_KEYWORDS         FA
-- Modify 2009.08.19 Ver1.1 Start
--      ,(SELECT  B.ASSET_ID                     AS ASSET_ID--資産ID
-- Modify E_本稼動_14502 2018/01/16 Start
--      ,(SELECT  /*+ USE_NL(FBC B FDP FDS FDS_MAX)
--                    INDEX( FDP FA_DEPRN_PERIODS_U3)
--                */
      ,(SELECT  /*+ USE_NL(FBC B FDP FDS FDS_MAX)
                    INDEX( B FA_BOOKS_N1)
                    INDEX( FDP FA_DEPRN_PERIODS_U3)
                */
-- Modify E_本稼動_14502 2018/01/16 End
                B.ASSET_ID                     AS ASSET_ID--資産ID
-- Modify 2009.08.19 Ver1.1 End
               ,B.BOOK_TYPE_CODE               AS BOOK_TYPE_CODE--台帳名
               ,B.COST                         AS COST--取得価額
               ,B.ADJUSTED_RECOVERABLE_COST    AS ADJUSTED_RECOVERABLE_COST--償却対象額
               ,DECODE(SIGN(B.COST - NVL(FDS.DEPRN_RESERVE, 0)),1,B.COST - NVL(FDS.DEPRN_RESERVE, 0),0) AS DEPRN_RESERVE--純帳簿価額
               ,FDS.YTD_DEPRN                  AS YTD_DEPRN--年償却累計額
--
-- Modify E_本稼動_14502 2017/12/14 Start
--               ,FDS.DEPRN_RESERVE               AS TOTAL_AMOUNT--償却累計額
               ,FDS.TOTAL_AMOUNT               AS TOTAL_AMOUNT--償却累計額
               ,FDS.DEPRN_AMOUNT                    AS MONTH_DEPRN                          -- 当月償却累計額
               ,FDS.BONUS_DEPRN_AMOUNT                                                      -- ﾎﾞｰﾅｽ償却
               ,FDS.BONUS_YTD_DEPRN                                                         -- ﾎﾞｰﾅｽ年償却累計額
               ,FDS.BONUS_DEPRN_RESERVE                                                     -- ﾎﾞｰﾅｽ償却累計額
-- Modify E_本稼動_14502 2017/12/14 End
--
               ,B.ORIGINAL_COST                AS ORIGINAL_COST--当初取得価額
               ,B.SALVAGE_VALUE                AS SALVAGE_VALUE--残存価額
               ,B.DATE_PLACED_IN_SERVICE       AS DATE_PLACED_IN_SERVICE--事業供用日
               ,B.DEPRN_METHOD_CODE            AS DEPRN_METHOD_CODE--償却方法
--
-- Modify E_本稼動_14502 2017/12/14 Start
               ,B.BASIC_RATE                        AS BASIC_RATE                           -- 償却率(普通償却率)
-- Modify E_本稼動_14502 2017/12/14 End
--
               ,NVL(TRUNC(B.LIFE_IN_MONTHS/12),0)  AS LIFE_IN_YEAR--耐用年数_年
               ,NVL(  MOD(B.LIFE_IN_MONTHS,12),0)  AS LIFE_IN_MONTHS--耐用年数_月
               ,FDS.PERIOD_COUNTER           AS PERIOD_COUNTER
-- Modify 2009.08.19 Ver1.1 Start
               ,FDP.PERIOD_NAME              AS PERIOD_NAME
-- Modify 2009.08.19 Ver1.1 End
--
-- Add E_本稼動_04156 2010/08/04 Start
               ,FDP.FISCAL_YEAR              AS LAST_FISCAL_YEAR                         --台帳の最新会計年度
               ,(SELECT /*+ 
                            INDEX( FDP_FISCAL FA_DEPRN_PERIODS_U3)
                        */
                        FDP_FISCAL.FISCAL_YEAR
                 FROM APPS.FA_DEPRN_PERIODS FDP_FISCAL
                 WHERE B.BOOK_TYPE_CODE   = FDP_FISCAL.BOOK_TYPE_CODE
                 AND   FDS.PERIOD_COUNTER = FDP_FISCAL.PERIOD_COUNTER) DEPRN_FISCAL_YEAR --最終償却時の会計年度
-- Add E_本稼動_04156 2010/08/04 End
--
-- Modify E_本稼動_14502 2017/12/14 Start
               ,FDP1.CALENDAR_PERIOD_OPEN_DATE                                              -- （減価償却期間）当年度開始日
               ,FDP1.PERIOD_COUNTER                                                         -- （減価償却期間）当年度開始の期間番号
               ,FDP.CALENDAR_PERIOD_CLOSE_DATE                                              -- （減価償却期間）当月末日
               ,FDP.PERIOD_COUNTER                                                          -- （減価償却期間）当月の期間番号
               ,RET.DATE_RETIRED                                                            -- 除売却日
               ,RET.NBV_RETIRED                                                             -- 除売却帳簿価額
               ,B.PERIOD_COUNTER_FULLY_RETIRED                                              -- 全除売却実施した期間ＩＤ
               ,FDP1.PERIOD_COUNTER                 AS PERIOD_COUNTER1                      -- 当年度開始の期間ＩＤ
               ,FDP1.FISCAL_YEAR                    AS FISCAL_YEAR                          -- 当年度開始の期間ＩＤ
-- Modify E_本稼動_14502 2017/12/14 End
--
        FROM    FA_BOOKS                  B    -- 資産台帳情報
--
              ,(SELECT  FDSY.DEPRN_RESERVE
-- Modify E_本稼動_14502 2017/12/14 Start
                       ,FDSY.DEPRN_AMOUNT               AS DEPRN_AMOUNT-- 当月償却額
-- Modify E_本稼動_14502 2017/12/14 End
--
                       ,FDSY.YTD_DEPRN                  AS YTD_DEPRN--年償却累計額
                       ,FDSY.DEPRN_RESERVE              AS TOTAL_AMOUNT--償却累計額
--
-- Modify E_本稼動_14502 2017/12/14 Start
                       ,FDSY.BONUS_DEPRN_AMOUNT         -- ﾎﾞｰﾅｽ償却
                       ,FDSY.BONUS_YTD_DEPRN            -- ﾎﾞｰﾅｽ年償却累計額
                       ,FDSY.BONUS_DEPRN_RESERVE        -- ﾎﾞｰﾅｽ年償却累計額
-- Modify E_本稼動_14502 2017/12/14 End
--
                       ,FDSY.PERIOD_COUNTER
                       ,FDSY.ASSET_ID
                       ,FDSY.BOOK_TYPE_CODE
                 FROM   FA_DEPRN_SUMMARY  FDSY
                 WHERE  FDSY.DEPRN_SOURCE_CODE   = 'DEPRN') FDS  -- 減価償却サマリ
              ,(SELECT MAX(FDSY.PERIOD_COUNTER) PERIOD_COUNTER
                      ,FDSY.ASSET_ID
                      ,FDSY.BOOK_TYPE_CODE
                FROM   FA_DEPRN_SUMMARY  FDSY
                GROUP BY FDSY.ASSET_ID
                        ,FDSY.BOOK_TYPE_CODE) FDS_MAX
-- Modify 2009.08.19 Ver1.1 Start
              ,FA_BOOK_CONTROLS          FBC  -- 資産台帳マスタ
              ,FA_DEPRN_PERIODS          FDP  -- 減価償却期間
-- Modify 2009.08.19 Ver1.1 End
--
-- Modify E_本稼動_14502 2017/12/14 Start
              ,FA_DEPRN_PERIODS          FDP1 -- 減価償却期間 年始
                -- 除売却情報
              ,(SELECT /*+
                           INDEX( FR FA_RETIREMENTS_N1)
                       */
                       FR.ASSET_ID                  -- 資産ID
                      ,FR.BOOK_TYPE_CODE            -- 台帳
                      ,FR.NBV_RETIRED               -- 除売却帳簿価額
                      ,FR.DATE_RETIRED              -- 除売却日
                      ,FR.TRANSACTION_HEADER_ID_IN  -- 取引ID
                FROM   FA_RETIREMENTS FR
                WHERE  EXISTS (
                                SELECT 1
                                FROM   FA_BOOK_CONTROLS          FBC2  -- 資産台帳マスタ
                                WHERE  1 = 1
                                AND    FBC2.BOOK_TYPE_CODE = FR.BOOK_TYPE_CODE
                                AND    FBC2.DISTRIBUTION_SOURCE_BOOK  IN ( FND_PROFILE.VALUE('XXCFF1_FIXED_ASSETS_BOOKS')
                                                                          ,FND_PROFILE.VALUE('XXCFF1_FIXED_IFRS_ASSET_REGISTER'))
                              )
               ) RET
-- Modify E_本稼動_14502 2017/12/14 End
--
        WHERE  B.BOOK_TYPE_CODE        = FDS_MAX.BOOK_TYPE_CODE-- 台帳名
        AND    B.TRANSACTION_HEADER_ID_OUT IS NULL  -- 最新の台帳データ
        AND    B.ASSET_ID              = FDS_MAX.ASSET_ID -- 資産ID
-- Modify 2009.08.19 Ver1.1 Start
--
-- Modify E_本稼動_14502 2017/12/14 Start
--        AND   B.PERIOD_COUNTER_FULLY_RETIRED IS NULL  -- 除・売却済みの固定資産は対象外
        AND    NVL(B.PERIOD_COUNTER_FULLY_RETIRED,9999999) >= FDP1.PERIOD_COUNTER                   --★ 当年度以降の除売却データは出力する。
-- Modify E_本稼動_14502 2017/12/14 End
--
        AND   FBC.BOOK_TYPE_CODE           = B.BOOK_TYPE_CODE
--
-- Modify E_本稼動_14502 2017/12/14 Start
--        AND   FBC.DISTRIBUTION_SOURCE_BOOK = FND_PROFILE.VALUE('XXCFF1_FIXED_ASSETS_BOOKS')        
        AND    FBC.DISTRIBUTION_SOURCE_BOOK                 IN (FND_PROFILE.VALUE('XXCFF1_FIXED_ASSETS_BOOKS')  ,
                                                                FND_PROFILE.VALUE('XXCFF1_FIXED_IFRS_ASSET_REGISTER')) --★ IFRS台帳も表示
-- Modify E_本稼動_14502 2017/12/14 End
--
        AND   FBC.BOOK_TYPE_CODE           = FDP.BOOK_TYPE_CODE
        AND   FBC.LAST_PERIOD_COUNTER      = FDP.PERIOD_COUNTER
-- Modify 2009.08.19 Ver1.1 End
        AND   FDS.PERIOD_COUNTER(+)    =  FDS_MAX.PERIOD_COUNTER
        AND   FDS.ASSET_ID(+)          =  FDS_MAX.ASSET_ID
--
-- Modify E_本稼動_14502 2017/12/14 Start
--        AND   FDS.BOOK_TYPE_CODE(+)    =  FDS_MAX.BOOK_TYPE_CODE) MAIN -- 償却
        AND    FDS.BOOK_TYPE_CODE(+)                        = FDS_MAX.BOOK_TYPE_CODE
        AND    FDP.BOOK_TYPE_CODE                           = FDP1.BOOK_TYPE_CODE
        AND    FDP.FISCAL_YEAR                              = FDP1.FISCAL_YEAR
        AND    FDP1.PERIOD_NUM                              = 1                                     -- 年始
        AND    B.ASSET_ID                                   = RET.ASSET_ID (+)                      -- 除売却の結合
        AND    B.BOOK_TYPE_CODE                             = RET.BOOK_TYPE_CODE (+)                -- 除売却の結合
        AND    B.TRANSACTION_HEADER_ID_IN                   = RET.TRANSACTION_HEADER_ID_IN (+)      -- 除売却の結合
       ) MAIN -- 償却
      ,(SELECT  /*+
                    INDEX( FB FA_BOOKS_N1)
                */
                FDS.ASSET_ID
               ,FDS.BOOK_TYPE_CODE
               ,FDP_FISCAL.FISCAL_YEAR + 1    AS FISCAL_YEAR      -- 年度
               ,FDP_FISCAL.PERIOD_CLOSE_DATE                      -- 前年クローズ日
               ,(FB.COST - FDS.DEPRN_RESERVE) AS KISYU_BOKA       -- 期首簿価
               ,FB.COST                       AS KISYU_COST       -- 期首取得価額
               ,FDS.DEPRN_RESERVE                                 -- 期首原価取得累計額
        FROM    APPS.FA_DEPRN_SUMMARY  FDS
               ,APPS.FA_DEPRN_PERIODS  FDP_FISCAL
               ,APPS.FA_BOOKS          FB
        WHERE   1 = 1
        AND     EXISTS (
                        SELECT 1
                        FROM   FA_BOOK_CONTROLS          FBC3  -- 資産台帳マスタ
                        WHERE  1 = 1
                        AND    FBC3.BOOK_TYPE_CODE = FDS.BOOK_TYPE_CODE
                        AND    FBC3.DISTRIBUTION_SOURCE_BOOK  IN ( FND_PROFILE.VALUE('XXCFF1_FIXED_ASSETS_BOOKS')
                                                                  ,FND_PROFILE.VALUE('XXCFF1_FIXED_IFRS_ASSET_REGISTER'))
                       )
        AND     FDS.BOOK_TYPE_CODE                 = FDP_FISCAL.BOOK_TYPE_CODE
        AND     FDS.PERIOD_COUNTER                 = FDP_FISCAL.PERIOD_COUNTER
        AND     FDS.DEPRN_SOURCE_CODE              = 'DEPRN'
        AND     FB.ASSET_ID                        = FDS.ASSET_ID
        AND     FB.BOOK_TYPE_CODE                  = FDS.BOOK_TYPE_CODE
        AND     FDP_FISCAL.PERIOD_NUM              = 12
        AND     FB.DATE_EFFECTIVE                 <= FDP_FISCAL.PERIOD_CLOSE_DATE
        AND     NVL(FB.DATE_INEFFECTIVE ,SYSDATE) >= FDP_FISCAL.PERIOD_CLOSE_DATE
       ) KISYU
-- Modify E_本稼動_14502 2017/12/14 End
--
-- Modify 2009.08.19 Ver1.1 Start
--WHERE  FBC.DISTRIBUTION_SOURCE_BOOK    =  FND_PROFILE.VALUE('XXCFF1_FIXED_ASSETS_BOOKS')
--AND    FBC.BOOK_TYPE_CODE              = MAIN.BOOK_TYPE_CODE -- 台帳名
--AND    MAIN.ASSET_ID                   = C.ASSET_ID -- 	資産ID
WHERE  MAIN.ASSET_ID           = C.ASSET_ID -- 資産ID
-- Modify 2009.08.19 Ver1.1 End
AND    D.TRANSACTION_HEADER_ID_OUT IS NULL  -- 最新の割当データ
AND    MAIN.ASSET_ID           = D.ASSET_ID -- 資産ID
-- Modify 2009.08.19 Ver1.1 Start
--AND    FBC.LAST_PERIOD_COUNTER = FDP.PERIOD_COUNTER -- カレンダID
--AND    FBC.BOOK_TYPE_CODE      = FDP.BOOK_TYPE_CODE -- 台帳名
-- Modify 2009.08.19 Ver1.1 End
AND    C.ASSET_CATEGORY_ID     = FC.CATE_CCID -- 資産カテゴリID
AND    D.LOCATION_ID           = FL.LOCATION_ID -- 事業所ID
AND    D.CODE_COMBINATION_ID   = CC.CCID-- 会計セグメントID
-- Modify E_本稼動_13168 2015/08/28 Start
--AND    C.ASSET_KEY_CCID        = FA.CODE_COMBINATION_ID
AND    C.ASSET_KEY_CCID        = FA.CODE_COMBINATION_ID(+)
-- Modify E_本稼動_13168 2015/08/28 End
--
-- Modify E_本稼動_14502 2017/12/14 Start
AND    MAIN.ASSET_ID           = KISYU.ASSET_ID(+)  
AND    MAIN.BOOK_TYPE_CODE     = KISYU.BOOK_TYPE_CODE(+)        --★追加：除売却の結合
AND    MAIN.FISCAL_YEAR        = KISYU.FISCAL_YEAR(+)
-- Modify E_本稼動_14502 2017/12/14 END
;
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ASSET_ID IS '資産ID';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ASSET_NUMBER IS '資産番号';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.BOOK_TYPE_CODE IS '台帳名';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.COST IS '取得価額';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ADJUSTED_RECOVERABLE_COST IS '償却対象額';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.DEPRN_RESERVE IS '純帳簿価額';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.LAST_FISCAL_YEAR IS '台帳最新会計年度';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.DEPRN_FISCAL_YEAR IS '最終償却時会計年度';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.YTD_DEPRN IS '年償却累計額';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.TOTAL_AMOUNT IS '償却累計額';
--
-- Modify E_本稼動_14502 2017/12/14 Start
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.MONTH_DEPRN IS '当月償却累計額';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.BONUS_DEPRN_AMOUNT IS 'ﾎﾞｰﾅｽ償却';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.BONUS_YTD_DEPRN IS 'ﾎﾞｰﾅｽ年償却累計額';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.BONUS_DEPRN_RESERVE IS 'ﾎﾞｰﾅｽ償却累計額';
-- Modify E_本稼動_14502 2017/12/14 End
--
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.PERIOD_NAME IS '減価償却対象期間';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ORIGINAL_COST IS '当初取得価額';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.SALVAGE_VALUE IS '残存価額';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.DATE_PLACED_IN_SERVICE IS '事業供用日';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.CATEGORY_CODE IS 'カテ_種類CODE';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.CATEGORY_NAME IS 'カテ_種類DESC';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.DCLR_DPRN_CODE IS 'カテ_償却申告CODE';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.DCLR_DPRN_NAME IS 'カテ_償却申告DESC';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ASSET_ACCOUNT_CODE IS 'カテ_資産勘定CODE';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ASSET_ACCOUNT_NAME IS 'カテ_資産勘定DESC';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ACCOUNT_CODE IS 'カテ_償却科目CODE';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ACCOUNT_NAME IS 'カテ_償却科目DESC';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.SEGMENT5 IS 'カテ_耐用年数CODE';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.SEGMENT5_DESC IS 'カテ_耐用年数DESC';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.DPRN_METHOD_CODE IS 'カテ_償却方法CODE';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.DPRN_METHOD_NAME IS 'カテ_償却方法DESC';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.LEASE_CLASS_CODE IS 'カテ_リース種別CODE';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.LEASE_CLASS_NAME IS 'カテ_リース種別DESC';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.DCLR_PLACE_CODE IS 'ロケ_申告地CODE';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.DCLR_PLACE_NAME IS 'ロケ_申告地DESC';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.DEPARTMENT_CODE IS 'ロケ_管理部門CODE';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.DEPARTMENT_NAME IS 'ロケ_管理部門DESC';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.MNG_PLACE_CODE IS 'ロケ_事業所CODE';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.MNG_PLACE_NAME IS 'ロケ_事業所DESC';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.PLACE_CODE IS 'ロケ_場所CODE';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.PLACE_NAME IS 'ロケ_場所DESC';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.OWNER_COMPANY_CODE IS 'ロケ_本社工場区分CODE';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.OWNER_COMPANY_NAME IS 'ロケ_本社工場区分DESC';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ACC_COMPANY_CODE IS '会計_会社CODE';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ACC_COMPANY_NAME IS '会計_会社DESC';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ACC_DEPARTMENT_CODE IS '会計_部門CODE';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ACC_DEPARTMENT_NAME IS '会計_部門DESC';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ACC_DPRN_ACCOUNT_CODE IS '会計_勘定科目CODE';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ACC_DPRN_ACCOUNT_NAME IS '会計_勘定科目DESC';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ACC_DPRN_SUB_ACCOUNT_CODE IS '会計_補助科目CODE';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ACC_DPRN_SUB_ACCOUNT_NAME IS '会計_補助科目DESC';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ACC_DPRN_CUSTOMER_CODE IS '会計_顧客コードCODE';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ACC_DPRN_CUSTOMER_NAME IS '会計_顧客コードDESC';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ACC_DPRN_ENTERPRISE_CODE IS '会計_企業コードCODE';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ACC_DPRN_ENTERPRISE_NAME IS '会計_企業コードDESC';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ACC_DPRN_RESERVE1_CODE IS '会計_予備1CODE';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ACC_DPRN_RESERVE1_NAME IS '会計_予備1DESC';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ACC_DPRN_RESERVE2_CODE IS '会計_予備2CODE';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ACC_DPRN_RESERVE2_NAME IS '会計_予備2DESC';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.CODE_COMBINATION_ID IS '減価償却ID';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.DESCRIPTION IS '摘要';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.CURRENT_UNITS IS '単位';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.DEPRN_METHOD_CODE IS '償却方法';
-- Modify E_本稼動_14502 2017/12/14 Start
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.RATE IS '償却率';
-- Modify E_本稼動_14502 2017/12/14 End
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.LIFE_IN_YEAR IS '耐用年数_年';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.LIFE_IN_MONTHS IS '耐用年数_月';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.RESERVE1_CODE1 IS '予備1';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.RESERVE1_CODE2 IS '予備2';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ATTRIBUTE1 IS '更新用事業供用日';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ATTRIBUTE2 IS '取得日';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ATTRIBUTE3 IS '構造';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ATTRIBUTE4 IS '細目';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ATTRIBUTE5 IS '圧縮記帳・控除方式';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ATTRIBUTE6 IS '圧縮控除額';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ATTRIBUTE7 IS '圧縮後取得価額';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ATTRIBUTE8 IS '資産グループ番号';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ATTRIBUTE9 IS '減損計算期間履歴';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ATTRIBUTE10 IS '物件コード';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ATTRIBUTE11 IS 'リース資産';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ATTRIBUTE12 IS '開示セグメント';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ATTRIBUTE13 IS '面積';
--
-- Modify E_本稼動_14502 2017/12/14 Start
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ATTRIBUTE17 IS 'IFRS不動産取得税';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ATTRIBUTE18 IS 'IFRS借入コスト';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ATTRIBUTE19 IS 'IFRSその他';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ATTRIBUTE22 IS '固定資産資産番号';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ATTRIBUTE23 IS 'IFRS対象資産番号';
-- Modify E_本稼動_14502 2017/12/14 End
--
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.LAST_UPDATE_DATE IS '最終更新日';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.LAST_UPDATED_BY IS '最終更新者';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.CREATED_BY IS '作成者';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.CREATION_DATE IS '作成日';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.LAST_UPDATE_LOGIN IS '最終更新ログイン';
--
-- Modify E_本稼動_14502 2017/12/14 Start
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.KISYU_BOKA IS '期首帳簿価額';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.YEAR_ADD_AMOUNT IS '期中増加額';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ADD_AMOUNT IS '当期増加額';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.YEAR_DEL_AMOUNT IS '期中減少額';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.DELETE_AMOUNT IS '当期減少額';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.DEPRN_RESERVE_12 IS '期末純帳簿価額';
-- Modify E_本稼動_14502 2017/12/14 End
COMMENT ON TABLE XXCFF_FIXED_ASSETS_V IS '固定資産一覧照会ビュー';

