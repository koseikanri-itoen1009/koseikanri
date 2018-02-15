CREATE OR REPLACE FORCE VIEW XXCFF_FIXED_ASSETS_V
(
ASSET_ID,                      --帒嶻ID
ASSET_NUMBER,                  --帒嶻斣崋
BOOK_TYPE_CODE,                --戜挔柤
COST,                          --庢摼壙妟
ADJUSTED_RECOVERABLE_COST,     --彏媝懳徾妟
DEPRN_RESERVE,                 --弮挔曤壙妟
-- ADD E_杮壱摦_04156 2010/08/04 Start
LAST_FISCAL_YEAR,              --戜挔嵟怴夛寁擭搙
DEPRN_FISCAL_YEAR,             --嵟廔彏媝帪夛寁擭搙
-- ADD E_杮壱摦_04156 2010/08/04 End
YTD_DEPRN,                     --擭彏媝椵寁妟
TOTAL_AMOUNT,                  --彏媝椵寁妟
--
-- Modify E_杮壱摦_14502 2017/12/14 Start
MONTH_DEPRN,                   --摉寧彏媝椵寁妟
BONUS_DEPRN_AMOUNT,            --无芭綇瀷p
BONUS_YTD_DEPRN,               --无芭綌N彏媝椵寁妟
BONUS_DEPRN_RESERVE,           --无芭綇瀷p椵寁妟
-- Modify E_杮壱摦_14502 2017/12/14 End
--
PERIOD_NAME,                   --尭壙彏媝懳徾婜娫
ORIGINAL_COST,                 --摉弶庢摼壙妟
SALVAGE_VALUE,                 --巆懚壙妟
DATE_PLACED_IN_SERVICE,        --帠嬈嫙梡擔
CATEGORY_CODE,                 --僇僥_庬椶CODE
CATEGORY_NAME,                 --僇僥_庬椶DESC
DCLR_DPRN_CODE,                --僇僥_彏媝怽崘CODE
DCLR_DPRN_NAME,                --僇僥_彏媝怽崘DESC
ASSET_ACCOUNT_CODE,            --僇僥_帒嶻姩掕CODE
ASSET_ACCOUNT_NAME,            --僇僥_帒嶻姩掕DESC
ACCOUNT_CODE,                  --僇僥_彏媝壢栚CODE
ACCOUNT_NAME,                  --僇僥_彏媝壢栚DESC
SEGMENT5,                      --僇僥_懴梡擭悢CODE
SEGMENT5_DESC,                 --僇僥_懴梡擭悢DESC
DPRN_METHOD_CODE,              --僇僥_彏媝曽朄CODE
DPRN_METHOD_NAME,              --僇僥_彏媝曽朄DESC
LEASE_CLASS_CODE,              --僇僥_儕乕僗庬暿CODE
LEASE_CLASS_NAME,              --僇僥_儕乕僗庬暿DESC
DCLR_PLACE_CODE,               --儘働_怽崘抧CODE
DCLR_PLACE_NAME,               --儘働_怽崘抧DESC
DEPARTMENT_CODE,               --儘働_娗棟晹栧CODE
DEPARTMENT_NAME,               --儘働_娗棟晹栧DESC
MNG_PLACE_CODE,                --儘働_帠嬈強CODE
MNG_PLACE_NAME,                --儘働_帠嬈強DESC
PLACE_CODE,                    --儘働_応強CODE
PLACE_NAME,                    --儘働_応強DESC
OWNER_COMPANY_CODE,            --儘働_杮幮岺応嬫暘CODE
OWNER_COMPANY_NAME,            --儘働_杮幮岺応嬫暘DESC
ACC_COMPANY_CODE,              --夛寁_夛幮CODE
ACC_COMPANY_NAME,              --夛寁_夛幮DESC
ACC_DEPARTMENT_CODE,           --夛寁_晹栧CODE
ACC_DEPARTMENT_NAME,           --夛寁_晹栧DESC
ACC_DPRN_ACCOUNT_CODE,         --夛寁_姩掕壢栚CODE
ACC_DPRN_ACCOUNT_NAME,         --夛寁_姩掕壢栚DESC
ACC_DPRN_SUB_ACCOUNT_CODE,     --夛寁_曗彆壢栚CODE
ACC_DPRN_SUB_ACCOUNT_NAME,     --夛寁_曗彆壢栚DESC
ACC_DPRN_CUSTOMER_CODE,        --夛寁_屭媞僐乕僪CODE
ACC_DPRN_CUSTOMER_NAME,        --夛寁_屭媞僐乕僪DESC
ACC_DPRN_ENTERPRISE_CODE,      --夛寁_婇嬈僐乕僪CODE
ACC_DPRN_ENTERPRISE_NAME,      --夛寁_婇嬈僐乕僪DESC
ACC_DPRN_RESERVE1_CODE,        --夛寁_梊旛1CODE
ACC_DPRN_RESERVE1_NAME,        --夛寁_梊旛1DESC
ACC_DPRN_RESERVE2_CODE,        --夛寁_梊旛2CODE
ACC_DPRN_RESERVE2_NAME,        --夛寁_梊旛2DESC
CODE_COMBINATION_ID,           --尭壙彏媝ID
DESCRIPTION,                   --揈梫
CURRENT_UNITS,                 --扨埵
DEPRN_METHOD_CODE,             --彏媝曽朄
--
-- Modify E_杮壱摦_14502 2017/12/14 Start
RATE,                          --彏媝棪(晛捠彏媝棪)
-- Modify E_杮壱摦_14502 2017/12/14 End
--
LIFE_IN_YEAR,                  --懴梡擭悢_擭
LIFE_IN_MONTHS,                --懴梡擭悢_寧
RESERVE1_CODE1,                --梊旛1
RESERVE1_CODE2,                --梊旛2
ATTRIBUTE1,                    --峏怴梡帠嬈嫙梡擔
ATTRIBUTE2,                    --庢摼擔
ATTRIBUTE3,                    --峔憿
ATTRIBUTE4,                    --嵶栚
ATTRIBUTE5,                    --埑弅婰挔丒峊彍曽幃
ATTRIBUTE6,                    --埑弅峊彍妟
ATTRIBUTE7,                    --埑弅屻庢摼壙妟
ATTRIBUTE8,                    --帒嶻僌儖乕僾斣崋
ATTRIBUTE9,                    --尭懝寁嶼婜娫棜楌
ATTRIBUTE10,                   --暔審僐乕僪
ATTRIBUTE11,                   --儕乕僗帒嶻
ATTRIBUTE12,                   --奐帵僙僌儊儞僩
ATTRIBUTE13,                   --柺愊
--
-- Modify E_杮壱摦_14502 2017/12/14 Start
ATTRIBUTE17,                   --IFRS晄摦嶻庢摼惻
ATTRIBUTE18,                   --IFRS庁擖僐僗僩
ATTRIBUTE19,                   --IFRS偦偺懠
ATTRIBUTE22,                   --屌掕帒嶻帒嶻斣崋
ATTRIBUTE23,                   --IFRS懳徾帒嶻斣崋
-- Modify E_杮壱摦_14502 2017/12/14 End
--
LAST_UPDATE_DATE,              --嵟廔峏怴擔
LAST_UPDATED_BY,               --嵟廔峏怴幰
CREATED_BY,                    --嶌惉幰
CREATION_DATE,                 --嶌惉擔
--
-- Modify E_杮壱摦_14502 2017/12/14 Start
--LAST_UPDATE_LOGIN              --嵟廔峏怴儘僌僀儞
LAST_UPDATE_LOGIN,              --嵟廔峏怴儘僌僀儞
-- Modify E_杮壱摦_14502 2017/12/14 End
--
-- Modify E_杮壱摦_14502 2017/12/14 Start
KISYU_BOKA,                       -- 婜庱挔曤壙妟
YEAR_ADD_AMOUNT,                  -- 婜拞憹壛妟
ADD_AMOUNT,                       -- 摉婜憹壛妟
YEAR_DEL_AMOUNT,                  -- 婜拞尭彮妟
DELETE_AMOUNT,                    -- 摉婜尭彮妟
DEPRN_RESERVE_12                  -- 婜枛弮挔曤壙妟
-- Modify E_杮壱摦_14502 2017/12/14 End
)
AS 
-- Modify 2009.08.19 Ver1.1 Start
--  SELECT MAIN.ASSET_ID                AS ASSET_ID--帒嶻ID
  SELECT
         /*+   
-- Modify E_嵟廔堏峴儕僴_00469 2009.10.13 Start
           LEADING(MAIN) --LEADING(MAIN.B)
-- Modify E_嵟廔堏峴儕僴_00469 2009.10.13 End
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
       MAIN.ASSET_ID                AS ASSET_ID--帒嶻ID
-- Modify 2009.08.19 Ver1.1 End
      ,C.ASSET_NUMBER               AS ASSET_NUMBER--帒嶻斣崋
      ,MAIN.BOOK_TYPE_CODE          AS BOOK_TYPE_CODE--戜挔柤
      ,MAIN.COST                    AS COST--庢摼壙妟
      ,MAIN.ADJUSTED_RECOVERABLE_COST  AS ADJUSTED_RECOVERABLE_COST--彏媝懳徾妟
      ,MAIN.DEPRN_RESERVE           AS DEPRN_RESERVE--弮挔曤壙妟
--
-- Modify E_杮壱摦_04156 2010/08/04 Start
      ,MAIN.LAST_FISCAL_YEAR        AS LAST_FISCAL_YEAR  --戜挔偺嵟怴夛寁擭搙
      ,MAIN.DEPRN_FISCAL_YEAR       AS DEPRN_FISCAL_YEAR --帒嶻偺嵟廔彏媝帪偺夛寁擭搙
      ,CASE
         WHEN (MAIN.LAST_FISCAL_YEAR = MAIN.DEPRN_FISCAL_YEAR) THEN
           MAIN.YTD_DEPRN
         ELSE
           0
         END YTD_DEPRN                                       --擭彏媝椵寁妟
      --,MAIN.YTD_DEPRN               AS YTD_DEPRN--擭彏媝椵寁妟
-- Modify E_杮壱摦_04156 2010/08/04 End
--
      ,MAIN.TOTAL_AMOUNT            AS TOTAL_AMOUNT--彏媝椵寁妟
--
-- Modify E_杮壱摦_14502 2017/12/14 Start
      ,MAIN.MONTH_DEPRN                 AS MONTH_DEPRN                      -- 摉寧彏媝椵寁妟
      ,MAIN.BONUS_DEPRN_AMOUNT          AS BONUS_DEPRN_AMOUNT               -- 无芭綇瀷p
      ,MAIN.BONUS_YTD_DEPRN             AS BONUS_YTD_DEPRN                  -- 无芭綌N彏媝椵寁妟
      ,MAIN.BONUS_DEPRN_RESERVE         AS BONUS_DEPRN_RESERVE              -- 无芭綇瀷p椵寁妟
-- Modify E_杮壱摦_14502 2017/12/14 end
--
-- Modify 2009.08.19 Ver1.1 Start
--      ,FDP.PERIOD_NAME              AS PERIOD_NAME--尭壙彏媝懳徾婜娫
      ,MAIN.PERIOD_NAME             AS PERIOD_NAME--尭壙彏媝懳徾婜娫
-- Modify 2009.08.19 Ver1.1 End
      ,MAIN.ORIGINAL_COST           AS ORIGINAL_COST--摉弶庢摼壙妟
      ,MAIN.SALVAGE_VALUE           AS SALVAGE_VALUE--巆懚壙妟
      ,MAIN.DATE_PLACED_IN_SERVICE  AS DATE_PLACED_IN_SERVICE--帠嬈嫙梡擔
      ,FC.SEGMENT1                  AS CATEGORY_CODE--僇僥_庬椶CODE
      ,FC.SEGMENT1_DESC             AS CATEGORY_NAME--僇僥_庬椶DESC
      ,FC.SEGMENT2                  AS DCLR_DPRN_CODE--僇僥_彏媝怽崘CODE
      ,FC.SEGMENT2_DESC             AS DCLR_DPRN_NAME--僇僥_彏媝怽崘DESC
      ,FC.SEGMENT3                  AS ASSET_ACCOUNT_CODE--僇僥_帒嶻姩掕CODE
      ,FC.SEGMENT3_DESC             AS ASSET_ACCOUNT_NAME--僇僥_帒嶻姩掕DESC
      ,FC.SEGMENT4                  AS ACCOUNT_CODE--僇僥_彏媝壢栚CODE
      ,FC.SEGMENT4_DESC             AS ACCOUNT_NAME--僇僥_彏媝壢栚DESC
      ,FC.SEGMENT5                  AS SEGMENT5--僇僥_懴梡擭悢CODE
      ,FC.SEGMENT5_DESC             AS SEGMENT5_DESC--僇僥_懴梡擭悢DESC
      ,FC.SEGMENT6                  AS DPRN_METHOD_CODE--僇僥_彏媝曽朄CODE
      ,FC.SEGMENT6_DESC             AS DPRN_METHOD_NAME--僇僥_彏媝曽朄DESC
      ,FC.SEGMENT7                  AS LEASE_CLASS_CODE--僇僥_儕乕僗庬暿CODE
      ,FC.SEGMENT7_DESC             AS LEASE_CLASS_NAME--僇僥_儕乕僗庬暿DESC
      ,FL.SEGMENT1                  AS DCLR_PLACE_CODE--儘働_怽崘抧CODE
      ,FL.SEGMENT1_DESC             AS DCLR_PLACE_NAME--儘働_怽崘抧DESC
      ,FL.SEGMENT2                  AS DEPARTMENT_CODE--儘働_娗棟晹栧CODE
      ,FL.SEGMENT2_DESC             AS DEPARTMENT_NAME--儘働_娗棟晹栧DESC
      ,FL.SEGMENT3                  AS MNG_PLACE_CODE--儘働_帠嬈強CODE
      ,FL.SEGMENT3_DESC             AS MNG_PLACE_NAME--儘働_帠嬈強DESC
      ,FL.SEGMENT4                  AS PLACE_CODE--儘働_応強CODE
      ,FL.SEGMENT4                  AS PLACE_NAME--儘働_応強DESC
      ,FL.SEGMENT5                  AS OWNER_COMPANY_CODE--儘働_杮幮岺応嬫暘CODE
      ,FL.SEGMENT5_DESC             AS OWNER_COMPANY_NAME--儘働_杮幮岺応嬫暘DESC
      ,CC.SEGMENT1                  AS ACC_COMPANY_CODE--夛寁_夛幮CODE
      ,CC.SEGMENT1_DESC             AS ACC_COMPANY_NAME--夛寁_夛幮DESC
      ,CC.SEGMENT2                  AS ACC_DEPARTMENT_CODE--夛寁_晹栧CODE
      ,CC.SEGMENT2_DESC             AS ACC_DEPARTMENT_NAME--夛寁_晹栧DESC
      ,CC.SEGMENT3                  AS ACC_DPRN_ACCOUNT_CODE--夛寁_姩掕壢栚CODE
      ,CC.SEGMENT3_DESC             AS ACC_DPRN_ACCOUNT_NAME--夛寁_姩掕壢栚DESC
      ,CC.SEGMENT4                  AS ACC_DPRN_SUB_ACCOUNT_CODE--夛寁_曗彆壢栚CODE
      ,CC.SEGMENT4_DESC             AS ACC_DPRN_SUB_ACCOUNT_NAME--夛寁_曗彆壢栚DESC
      ,CC.SEGMENT5                  AS ACC_DPRN_CUSTOMER_CODE--夛寁_屭媞僐乕僪CODE
      ,CC.SEGMENT5_DESC             AS ACC_DPRN_CUSTOMER_NAME--夛寁_屭媞僐乕僪DESC
      ,CC.SEGMENT6                  AS ACC_DPRN_ENTERPRISE_CODE--夛寁_婇嬈僐乕僪CODE
      ,CC.SEGMENT6_DESC             AS ACC_DPRN_ENTERPRISE_NAME--夛寁_婇嬈僐乕僪DESC
      ,CC.SEGMENT7                  AS ACC_DPRN_RESERVE1_CODE--夛寁_梊旛1CODE
      ,CC.SEGMENT7_DESC             AS ACC_DPRN_RESERVE1_NAME--夛寁_梊旛1DESC
      ,CC.SEGMENT8                  AS ACC_DPRN_RESERVE2_CODE--夛寁_梊旛2CODE
      ,CC.SEGMENT8_DESC             AS ACC_DPRN_RESERVE2_NAME--夛寁_梊旛2DESC
      ,D.CODE_COMBINATION_ID        AS CODE_COMBINATION_ID--尭壙彏媝ID
      ,C.DESCRIPTION                AS DESCRIPTION--揈梫
      ,C.CURRENT_UNITS              AS CURRENT_UNITS--扨埵
      ,MAIN.DEPRN_METHOD_CODE       AS DEPRN_METHOD_CODE--彏媝曽朄
--
-- Modify E_杮壱摦_14502 2017/12/14 Start
      ,MAIN.BASIC_RATE * 100            AS RATE                             -- 彏媝棪(晛捠彏媝棪)
-- Modify E_杮壱摦_14502 2017/12/14 End
--
      ,MAIN.LIFE_IN_YEAR            AS LIFE_IN_YEAR--懴梡擭悢_擭
      ,MAIN.LIFE_IN_MONTHS          AS LIFE_IN_MONTHS--懴梡擭悢_寧
      ,FA.SEGMENT1                  AS RESERVE1_CODE1  --梊旛1
      ,FA.SEGMENT2                  AS RESERVE1_CODE2  --梊旛2
      ,C.ATTRIBUTE1                 AS ATTRIBUTE1--峏怴梡帠嬈嫙梡擔
      ,C.ATTRIBUTE2                 AS ATTRIBUTE2--庢摼擔
      ,C.ATTRIBUTE3                 AS ATTRIBUTE3--峔憿
      ,C.ATTRIBUTE4                 AS ATTRIBUTE4--嵶栚
      ,C.ATTRIBUTE5                 AS ATTRIBUTE5--"埑弅婰挔丒峊彍曽幃"
      ,C.ATTRIBUTE6                 AS ATTRIBUTE6--埑弅峊彍妟
      ,C.ATTRIBUTE7                 AS ATTRIBUTE7--埑弅屻庢摼壙妟
      ,C.ATTRIBUTE8                 AS ATTRIBUTE8--帒嶻僌儖乕僾斣崋
      ,C.ATTRIBUTE9                 AS ATTRIBUTE9--尭懝寁嶼婜娫棜楌
      ,C.ATTRIBUTE10                AS ATTRIBUTE10--暔審僐乕僪
      ,C.ATTRIBUTE11                AS ATTRIBUTE11--儕乕僗帒嶻
      ,C.ATTRIBUTE12                AS ATTRIBUTE12--奐帵僙僌儊儞僩
      ,C.ATTRIBUTE13                AS ATTRIBUTE13--柺愊
--
-- Modify E_杮壱摦_14502 2017/12/14 Start
      ,C.ATTRIBUTE17                    AS ATTRIBUTE17                      -- IFRS晄摦嶻庢摼惻
      ,C.ATTRIBUTE18                    AS ATTRIBUTE18                      -- IFRS庁擖僐僗僩
      ,C.ATTRIBUTE19                    AS ATTRIBUTE19                      -- IFRS偦偺懠
      ,C.ATTRIBUTE22                    AS ATTRIBUTE22                      -- 屌掕帒嶻帒嶻斣崋
      ,C.ATTRIBUTE23                    AS ATTRIBUTE23                      -- IFRS懳徾帒嶻斣崋
-- Modify E_杮壱摦_14502 2017/12/14 End
--
      ,C.LAST_UPDATE_DATE           AS LAST_UPDATE_DATE--嵟廔峏怴擔
      ,C.LAST_UPDATED_BY            AS LAST_UPDATED_BY--嵟廔峏怴幰
      ,C.CREATED_BY                 AS CREATED_BY--嶌惉幰
      ,C.CREATION_DATE              AS CREATION_DATE--嶌惉擔
      ,C.LAST_UPDATE_LOGIN          AS LAST_UPDATE_LOGIN--嵟廔峏怴儘僌僀儞
--
-- Modify E_杮壱摦_14502 2018/01/12 Start
      ,CASE
         WHEN (NVL(KISYU.KISYU_BOKA, 0) = 0)
         AND  (TO_CHAR(MAIN.DATE_PLACED_IN_SERVICE,'YYYYMM') <= TO_CHAR(MAIN.CALENDAR_PERIOD_CLOSE_DATE,'YYYYMM')) THEN
           CASE
             WHEN (MAIN.LAST_FISCAL_YEAR = MAIN.DEPRN_FISCAL_YEAR) THEN
               MAIN.YTD_DEPRN + MAIN.DEPRN_RESERVE            --夁嫀擭搙偺帒嶻傪摉擭偵帒嶻捛壛偟偨応崌丄婜庱曤壙偑庢傟側偄偺偱丄-婜枛弮挔曤壙妟亄擭彏媝椵寁妟偱嶼弌
             ELSE
               MAIN.DEPRN_RESERVE
             END
         ELSE
           NVL(KISYU.KISYU_BOKA, 0)
         END                            AS KISYU_BOKA                       -- 婜庱挔曤壙妟
-- Modify E_杮壱摦_14502 2018/01/12 End
--
-- Modify E_杮壱摦_14502 2017/12/14 Start
      ,CASE
         WHEN (TO_CHAR(MAIN.DATE_PLACED_IN_SERVICE, 'YYYYMM') <= TO_CHAR(MAIN.CALENDAR_PERIOD_CLOSE_DATE, 'YYYYMM'))
         AND  (TO_CHAR(MAIN.DATE_PLACED_IN_SERVICE, 'YYYYMM') >= TO_CHAR(MAIN.CALENDAR_PERIOD_OPEN_DATE , 'YYYYMM')) THEN
           MAIN.COST
         ELSE
           0
         END                            AS YEAR_ADD_AMOUNT                  -- 婜拞憹壛妟
      ,CASE
         WHEN (TO_CHAR(MAIN.DATE_PLACED_IN_SERVICE, 'YYYYMM') = TO_CHAR(MAIN.CALENDAR_PERIOD_CLOSE_DATE, 'YYYYMM')) THEN
           MAIN.COST
         ELSE
           0
         END                            AS ADD_AMOUNT                       -- 摉婜憹壛妟
      ,CASE
         WHEN (TO_CHAR(MAIN.DATE_RETIRED, 'YYYYMM') <= TO_CHAR(MAIN.CALENDAR_PERIOD_CLOSE_DATE, 'YYYYMM'))
         AND  (TO_CHAR(MAIN.DATE_RETIRED, 'YYYYMM') >= TO_CHAR(MAIN.CALENDAR_PERIOD_OPEN_DATE, 'YYYYMM')) THEN
           MAIN.NBV_RETIRED     -- 彍攧媝挔曤壙妟
         ELSE
           0
         END                            AS YEAR_DEL_AMOUNT                  -- 婜拞尭彮妟
      ,CASE
        WHEN (TO_CHAR(MAIN.DATE_RETIRED, 'YYYYMM') = TO_CHAR(MAIN.CALENDAR_PERIOD_CLOSE_DATE, 'YYYYMM')) THEN
          MAIN.NBV_RETIRED      -- 彍攧媝挔曤壙妟
        ELSE
          0
        END                             AS DELETE_AMOUNT                    -- 摉婜尭彮妟
      ,MAIN.DEPRN_RESERVE               AS DEPRN_RESERVE_12                 -- 婜枛弮挔曤壙妟
-- Modify E_杮壱摦_14502 2017/12/14 End
--
-- Modify 2009.08.19 Ver1.1 Start
--FROM   FA_BOOK_CONTROLS          FBC  -- 帒嶻戜挔
--      ,FA_ADDITIONS              C    -- 帒嶻徻嵶
FROM   FA_ADDITIONS              C    -- 帒嶻徻嵶
-- Modify 2009.08.19 Ver1.1 End
      ,FA_DISTRIBUTION_HISTORY   D    -- 帒嶻妱摉
-- Modify 2009.08.19 Ver1.1 Start
--      ,FA_DEPRN_PERIODS          FDP  -- 尭壙彏媝婜娫
-- Modify 2009.08.19 Ver1.1 End
      ,XXCFF_FA_CATEGORY_V       FC   -- 帒嶻僇僥僑儕儅僗僞
      ,XXCFF_FA_LOCATION_V       FL   -- 帠嬈強儅僗僞
      ,XXCFF_FA_CCID_V           CC   -- 姩掕壢栚懱宯儅僗僞
      ,FA_ASSET_KEYWORDS         FA
-- Modify 2009.08.19 Ver1.1 Start
--      ,(SELECT  B.ASSET_ID                     AS ASSET_ID--帒嶻ID
-- Modify E_杮壱摦_14502 2018/01/16 Start
--      ,(SELECT  /*+ USE_NL(FBC B FDP FDS FDS_MAX)
--                    INDEX( FDP FA_DEPRN_PERIODS_U3)
--                */
      ,(SELECT  /*+ USE_NL(FBC B FDP FDS FDS_MAX)
                    INDEX( B FA_BOOKS_N1)
                    INDEX( FDP FA_DEPRN_PERIODS_U3)
                */
-- Modify E_杮壱摦_14502 2018/01/16 End
                B.ASSET_ID                     AS ASSET_ID--帒嶻ID
-- Modify 2009.08.19 Ver1.1 End
               ,B.BOOK_TYPE_CODE               AS BOOK_TYPE_CODE--戜挔柤
               ,B.COST                         AS COST--庢摼壙妟
               ,B.ADJUSTED_RECOVERABLE_COST    AS ADJUSTED_RECOVERABLE_COST--彏媝懳徾妟
               ,DECODE(SIGN(B.COST - NVL(FDS.DEPRN_RESERVE, 0)),1,B.COST - NVL(FDS.DEPRN_RESERVE, 0),0) AS DEPRN_RESERVE--弮挔曤壙妟
               ,FDS.YTD_DEPRN                  AS YTD_DEPRN--擭彏媝椵寁妟
--
-- Modify E_杮壱摦_14502 2017/12/14 Start
--               ,FDS.DEPRN_RESERVE               AS TOTAL_AMOUNT--彏媝椵寁妟
               ,FDS.TOTAL_AMOUNT               AS TOTAL_AMOUNT--彏媝椵寁妟
               ,FDS.DEPRN_AMOUNT                    AS MONTH_DEPRN                          -- 摉寧彏媝椵寁妟
               ,FDS.BONUS_DEPRN_AMOUNT                                                      -- 无芭綇瀷p
               ,FDS.BONUS_YTD_DEPRN                                                         -- 无芭綌N彏媝椵寁妟
               ,FDS.BONUS_DEPRN_RESERVE                                                     -- 无芭綇瀷p椵寁妟
-- Modify E_杮壱摦_14502 2017/12/14 End
--
               ,B.ORIGINAL_COST                AS ORIGINAL_COST--摉弶庢摼壙妟
               ,B.SALVAGE_VALUE                AS SALVAGE_VALUE--巆懚壙妟
               ,B.DATE_PLACED_IN_SERVICE       AS DATE_PLACED_IN_SERVICE--帠嬈嫙梡擔
               ,B.DEPRN_METHOD_CODE            AS DEPRN_METHOD_CODE--彏媝曽朄
--
-- Modify E_杮壱摦_14502 2017/12/14 Start
               ,B.BASIC_RATE                        AS BASIC_RATE                           -- 彏媝棪(晛捠彏媝棪)
-- Modify E_杮壱摦_14502 2017/12/14 End
--
               ,NVL(TRUNC(B.LIFE_IN_MONTHS/12),0)  AS LIFE_IN_YEAR--懴梡擭悢_擭
               ,NVL(  MOD(B.LIFE_IN_MONTHS,12),0)  AS LIFE_IN_MONTHS--懴梡擭悢_寧
               ,FDS.PERIOD_COUNTER           AS PERIOD_COUNTER
-- Modify 2009.08.19 Ver1.1 Start
               ,FDP.PERIOD_NAME              AS PERIOD_NAME
-- Modify 2009.08.19 Ver1.1 End
--
-- Add E_杮壱摦_04156 2010/08/04 Start
               ,FDP.FISCAL_YEAR              AS LAST_FISCAL_YEAR                         --戜挔偺嵟怴夛寁擭搙
               ,(SELECT /*+ 
                            INDEX( FDP_FISCAL FA_DEPRN_PERIODS_U3)
                        */
                        FDP_FISCAL.FISCAL_YEAR
                 FROM APPS.FA_DEPRN_PERIODS FDP_FISCAL
                 WHERE B.BOOK_TYPE_CODE   = FDP_FISCAL.BOOK_TYPE_CODE
                 AND   FDS.PERIOD_COUNTER = FDP_FISCAL.PERIOD_COUNTER) DEPRN_FISCAL_YEAR --嵟廔彏媝帪偺夛寁擭搙
-- Add E_杮壱摦_04156 2010/08/04 End
--
-- Modify E_杮壱摦_14502 2017/12/14 Start
               ,FDP1.CALENDAR_PERIOD_OPEN_DATE                                              -- 乮尭壙彏媝婜娫乯摉擭搙奐巒擔
               ,FDP1.PERIOD_COUNTER                                                         -- 乮尭壙彏媝婜娫乯摉擭搙奐巒偺婜娫斣崋
               ,FDP.CALENDAR_PERIOD_CLOSE_DATE                                              -- 乮尭壙彏媝婜娫乯摉寧枛擔
               ,FDP.PERIOD_COUNTER                                                          -- 乮尭壙彏媝婜娫乯摉寧偺婜娫斣崋
               ,RET.DATE_RETIRED                                                            -- 彍攧媝擔
               ,RET.NBV_RETIRED                                                             -- 彍攧媝挔曤壙妟
               ,B.PERIOD_COUNTER_FULLY_RETIRED                                              -- 慡彍攧媝幚巤偟偨婜娫俬俢
               ,FDP1.PERIOD_COUNTER                 AS PERIOD_COUNTER1                      -- 摉擭搙奐巒偺婜娫俬俢
               ,FDP1.FISCAL_YEAR                    AS FISCAL_YEAR                          -- 摉擭搙奐巒偺婜娫俬俢
-- Modify E_杮壱摦_14502 2017/12/14 End
--
        FROM    FA_BOOKS                  B    -- 帒嶻戜挔忣曬
--
              ,(SELECT  FDSY.DEPRN_RESERVE
-- Modify E_杮壱摦_14502 2017/12/14 Start
                       ,FDSY.DEPRN_AMOUNT               AS DEPRN_AMOUNT-- 摉寧彏媝妟
-- Modify E_杮壱摦_14502 2017/12/14 End
--
                       ,FDSY.YTD_DEPRN                  AS YTD_DEPRN--擭彏媝椵寁妟
                       ,FDSY.DEPRN_RESERVE              AS TOTAL_AMOUNT--彏媝椵寁妟
--
-- Modify E_杮壱摦_14502 2017/12/14 Start
                       ,FDSY.BONUS_DEPRN_AMOUNT         -- 无芭綇瀷p
                       ,FDSY.BONUS_YTD_DEPRN            -- 无芭綌N彏媝椵寁妟
                       ,FDSY.BONUS_DEPRN_RESERVE        -- 无芭綌N彏媝椵寁妟
-- Modify E_杮壱摦_14502 2017/12/14 End
--
                       ,FDSY.PERIOD_COUNTER
                       ,FDSY.ASSET_ID
                       ,FDSY.BOOK_TYPE_CODE
                 FROM   FA_DEPRN_SUMMARY  FDSY
                 WHERE  FDSY.DEPRN_SOURCE_CODE   = 'DEPRN') FDS  -- 尭壙彏媝僒儅儕
              ,(SELECT MAX(FDSY.PERIOD_COUNTER) PERIOD_COUNTER
                      ,FDSY.ASSET_ID
                      ,FDSY.BOOK_TYPE_CODE
                FROM   FA_DEPRN_SUMMARY  FDSY
                GROUP BY FDSY.ASSET_ID
                        ,FDSY.BOOK_TYPE_CODE) FDS_MAX
-- Modify 2009.08.19 Ver1.1 Start
              ,FA_BOOK_CONTROLS          FBC  -- 帒嶻戜挔儅僗僞
              ,FA_DEPRN_PERIODS          FDP  -- 尭壙彏媝婜娫
-- Modify 2009.08.19 Ver1.1 End
--
-- Modify E_杮壱摦_14502 2017/12/14 Start
              ,FA_DEPRN_PERIODS          FDP1 -- 尭壙彏媝婜娫 擭巒
                -- 彍攧媝忣曬
              ,(SELECT /*+
                           INDEX( FR FA_RETIREMENTS_N1)
                       */
                       FR.ASSET_ID                  -- 帒嶻ID
                      ,FR.BOOK_TYPE_CODE            -- 戜挔
                      ,FR.NBV_RETIRED               -- 彍攧媝挔曤壙妟
                      ,FR.DATE_RETIRED              -- 彍攧媝擔
                      ,FR.TRANSACTION_HEADER_ID_IN  -- 庢堷ID
                FROM   FA_RETIREMENTS FR
                WHERE  EXISTS (
                                SELECT 1
                                FROM   FA_BOOK_CONTROLS          FBC2  -- 帒嶻戜挔儅僗僞
                                WHERE  1 = 1
                                AND    FBC2.BOOK_TYPE_CODE = FR.BOOK_TYPE_CODE
                                AND    FBC2.DISTRIBUTION_SOURCE_BOOK  IN ( FND_PROFILE.VALUE('XXCFF1_FIXED_ASSETS_BOOKS')
                                                                          ,FND_PROFILE.VALUE('XXCFF1_FIXED_IFRS_ASSET_REGISTER'))
                              )
               ) RET
-- Modify E_杮壱摦_14502 2017/12/14 End
--
        WHERE  B.BOOK_TYPE_CODE        = FDS_MAX.BOOK_TYPE_CODE-- 戜挔柤
        AND    B.TRANSACTION_HEADER_ID_OUT IS NULL  -- 嵟怴偺戜挔僨乕僞
        AND    B.ASSET_ID              = FDS_MAX.ASSET_ID -- 帒嶻ID
-- Modify 2009.08.19 Ver1.1 Start
--
-- Modify E_杮壱摦_14502 2017/12/14 Start
--        AND   B.PERIOD_COUNTER_FULLY_RETIRED IS NULL  -- 彍丒攧媝嵪傒偺屌掕帒嶻偼懳徾奜
        AND    NVL(B.PERIOD_COUNTER_FULLY_RETIRED,9999999) >= FDP1.PERIOD_COUNTER                   --仛 摉擭搙埲崀偺彍攧媝僨乕僞偼弌椡偡傞丅
-- Modify E_杮壱摦_14502 2017/12/14 End
--
        AND   FBC.BOOK_TYPE_CODE           = B.BOOK_TYPE_CODE
--
-- Modify E_杮壱摦_14502 2017/12/14 Start
--        AND   FBC.DISTRIBUTION_SOURCE_BOOK = FND_PROFILE.VALUE('XXCFF1_FIXED_ASSETS_BOOKS')        
        AND    FBC.DISTRIBUTION_SOURCE_BOOK                 IN (FND_PROFILE.VALUE('XXCFF1_FIXED_ASSETS_BOOKS')  ,
                                                                FND_PROFILE.VALUE('XXCFF1_FIXED_IFRS_ASSET_REGISTER')) --仛 IFRS戜挔傕昞帵
-- Modify E_杮壱摦_14502 2017/12/14 End
--
        AND   FBC.BOOK_TYPE_CODE           = FDP.BOOK_TYPE_CODE
        AND   FBC.LAST_PERIOD_COUNTER      = FDP.PERIOD_COUNTER
-- Modify 2009.08.19 Ver1.1 End
        AND   FDS.PERIOD_COUNTER(+)    =  FDS_MAX.PERIOD_COUNTER
        AND   FDS.ASSET_ID(+)          =  FDS_MAX.ASSET_ID
--
-- Modify E_杮壱摦_14502 2017/12/14 Start
--        AND   FDS.BOOK_TYPE_CODE(+)    =  FDS_MAX.BOOK_TYPE_CODE) MAIN -- 彏媝
        AND    FDS.BOOK_TYPE_CODE(+)                        = FDS_MAX.BOOK_TYPE_CODE
        AND    FDP.BOOK_TYPE_CODE                           = FDP1.BOOK_TYPE_CODE
        AND    FDP.FISCAL_YEAR                              = FDP1.FISCAL_YEAR
        AND    FDP1.PERIOD_NUM                              = 1                                     -- 擭巒
        AND    B.ASSET_ID                                   = RET.ASSET_ID (+)                      -- 彍攧媝偺寢崌
        AND    B.BOOK_TYPE_CODE                             = RET.BOOK_TYPE_CODE (+)                -- 彍攧媝偺寢崌
        AND    B.TRANSACTION_HEADER_ID_IN                   = RET.TRANSACTION_HEADER_ID_IN (+)      -- 彍攧媝偺寢崌
       ) MAIN -- 彏媝
      ,(SELECT  /*+
                    INDEX( FB FA_BOOKS_N1)
                */
                FDS.ASSET_ID
               ,FDS.BOOK_TYPE_CODE
               ,FDP_FISCAL.FISCAL_YEAR + 1    AS FISCAL_YEAR      -- 擭搙
               ,FDP_FISCAL.PERIOD_CLOSE_DATE                      -- 慜擭僋儘乕僘擔
               ,(FB.COST - FDS.DEPRN_RESERVE) AS KISYU_BOKA       -- 婜庱曤壙
               ,FB.COST                       AS KISYU_COST       -- 婜庱庢摼壙妟
               ,FDS.DEPRN_RESERVE                                 -- 婜庱尨壙庢摼椵寁妟
        FROM    APPS.FA_DEPRN_SUMMARY  FDS
               ,APPS.FA_DEPRN_PERIODS  FDP_FISCAL
               ,APPS.FA_BOOKS          FB
        WHERE   1 = 1
        AND     EXISTS (
                        SELECT 1
                        FROM   FA_BOOK_CONTROLS          FBC3  -- 帒嶻戜挔儅僗僞
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
-- Modify E_杮壱摦_14502 2017/12/14 End
--
-- Modify 2009.08.19 Ver1.1 Start
--WHERE  FBC.DISTRIBUTION_SOURCE_BOOK    =  FND_PROFILE.VALUE('XXCFF1_FIXED_ASSETS_BOOKS')
--AND    FBC.BOOK_TYPE_CODE              = MAIN.BOOK_TYPE_CODE -- 戜挔柤
--AND    MAIN.ASSET_ID                   = C.ASSET_ID -- 	帒嶻ID
WHERE  MAIN.ASSET_ID           = C.ASSET_ID -- 帒嶻ID
-- Modify 2009.08.19 Ver1.1 End
AND    D.TRANSACTION_HEADER_ID_OUT IS NULL  -- 嵟怴偺妱摉僨乕僞
AND    MAIN.ASSET_ID           = D.ASSET_ID -- 帒嶻ID
-- Modify 2009.08.19 Ver1.1 Start
--AND    FBC.LAST_PERIOD_COUNTER = FDP.PERIOD_COUNTER -- 僇儗儞僟ID
--AND    FBC.BOOK_TYPE_CODE      = FDP.BOOK_TYPE_CODE -- 戜挔柤
-- Modify 2009.08.19 Ver1.1 End
AND    C.ASSET_CATEGORY_ID     = FC.CATE_CCID -- 帒嶻僇僥僑儕ID
AND    D.LOCATION_ID           = FL.LOCATION_ID -- 帠嬈強ID
AND    D.CODE_COMBINATION_ID   = CC.CCID-- 夛寁僙僌儊儞僩ID
-- Modify E_杮壱摦_13168 2015/08/28 Start
--AND    C.ASSET_KEY_CCID        = FA.CODE_COMBINATION_ID
AND    C.ASSET_KEY_CCID        = FA.CODE_COMBINATION_ID(+)
-- Modify E_杮壱摦_13168 2015/08/28 End
--
-- Modify E_杮壱摦_14502 2017/12/14 Start
AND    MAIN.ASSET_ID           = KISYU.ASSET_ID(+)  
AND    MAIN.BOOK_TYPE_CODE     = KISYU.BOOK_TYPE_CODE(+)        --仛捛壛丗彍攧媝偺寢崌
AND    MAIN.FISCAL_YEAR        = KISYU.FISCAL_YEAR(+)
-- Modify E_杮壱摦_14502 2017/12/14 END
;
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ASSET_ID IS '帒嶻ID';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ASSET_NUMBER IS '帒嶻斣崋';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.BOOK_TYPE_CODE IS '戜挔柤';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.COST IS '庢摼壙妟';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ADJUSTED_RECOVERABLE_COST IS '彏媝懳徾妟';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.DEPRN_RESERVE IS '弮挔曤壙妟';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.LAST_FISCAL_YEAR IS '戜挔嵟怴夛寁擭搙';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.DEPRN_FISCAL_YEAR IS '嵟廔彏媝帪夛寁擭搙';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.YTD_DEPRN IS '擭彏媝椵寁妟';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.TOTAL_AMOUNT IS '彏媝椵寁妟';
--
-- Modify E_杮壱摦_14502 2017/12/14 Start
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.MONTH_DEPRN IS '摉寧彏媝椵寁妟';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.BONUS_DEPRN_AMOUNT IS '无芭綇瀷p';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.BONUS_YTD_DEPRN IS '无芭綌N彏媝椵寁妟';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.BONUS_DEPRN_RESERVE IS '无芭綇瀷p椵寁妟';
-- Modify E_杮壱摦_14502 2017/12/14 End
--
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.PERIOD_NAME IS '尭壙彏媝懳徾婜娫';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ORIGINAL_COST IS '摉弶庢摼壙妟';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.SALVAGE_VALUE IS '巆懚壙妟';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.DATE_PLACED_IN_SERVICE IS '帠嬈嫙梡擔';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.CATEGORY_CODE IS '僇僥_庬椶CODE';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.CATEGORY_NAME IS '僇僥_庬椶DESC';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.DCLR_DPRN_CODE IS '僇僥_彏媝怽崘CODE';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.DCLR_DPRN_NAME IS '僇僥_彏媝怽崘DESC';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ASSET_ACCOUNT_CODE IS '僇僥_帒嶻姩掕CODE';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ASSET_ACCOUNT_NAME IS '僇僥_帒嶻姩掕DESC';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ACCOUNT_CODE IS '僇僥_彏媝壢栚CODE';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ACCOUNT_NAME IS '僇僥_彏媝壢栚DESC';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.SEGMENT5 IS '僇僥_懴梡擭悢CODE';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.SEGMENT5_DESC IS '僇僥_懴梡擭悢DESC';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.DPRN_METHOD_CODE IS '僇僥_彏媝曽朄CODE';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.DPRN_METHOD_NAME IS '僇僥_彏媝曽朄DESC';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.LEASE_CLASS_CODE IS '僇僥_儕乕僗庬暿CODE';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.LEASE_CLASS_NAME IS '僇僥_儕乕僗庬暿DESC';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.DCLR_PLACE_CODE IS '儘働_怽崘抧CODE';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.DCLR_PLACE_NAME IS '儘働_怽崘抧DESC';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.DEPARTMENT_CODE IS '儘働_娗棟晹栧CODE';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.DEPARTMENT_NAME IS '儘働_娗棟晹栧DESC';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.MNG_PLACE_CODE IS '儘働_帠嬈強CODE';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.MNG_PLACE_NAME IS '儘働_帠嬈強DESC';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.PLACE_CODE IS '儘働_応強CODE';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.PLACE_NAME IS '儘働_応強DESC';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.OWNER_COMPANY_CODE IS '儘働_杮幮岺応嬫暘CODE';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.OWNER_COMPANY_NAME IS '儘働_杮幮岺応嬫暘DESC';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ACC_COMPANY_CODE IS '夛寁_夛幮CODE';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ACC_COMPANY_NAME IS '夛寁_夛幮DESC';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ACC_DEPARTMENT_CODE IS '夛寁_晹栧CODE';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ACC_DEPARTMENT_NAME IS '夛寁_晹栧DESC';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ACC_DPRN_ACCOUNT_CODE IS '夛寁_姩掕壢栚CODE';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ACC_DPRN_ACCOUNT_NAME IS '夛寁_姩掕壢栚DESC';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ACC_DPRN_SUB_ACCOUNT_CODE IS '夛寁_曗彆壢栚CODE';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ACC_DPRN_SUB_ACCOUNT_NAME IS '夛寁_曗彆壢栚DESC';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ACC_DPRN_CUSTOMER_CODE IS '夛寁_屭媞僐乕僪CODE';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ACC_DPRN_CUSTOMER_NAME IS '夛寁_屭媞僐乕僪DESC';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ACC_DPRN_ENTERPRISE_CODE IS '夛寁_婇嬈僐乕僪CODE';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ACC_DPRN_ENTERPRISE_NAME IS '夛寁_婇嬈僐乕僪DESC';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ACC_DPRN_RESERVE1_CODE IS '夛寁_梊旛1CODE';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ACC_DPRN_RESERVE1_NAME IS '夛寁_梊旛1DESC';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ACC_DPRN_RESERVE2_CODE IS '夛寁_梊旛2CODE';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ACC_DPRN_RESERVE2_NAME IS '夛寁_梊旛2DESC';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.CODE_COMBINATION_ID IS '尭壙彏媝ID';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.DESCRIPTION IS '揈梫';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.CURRENT_UNITS IS '扨埵';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.DEPRN_METHOD_CODE IS '彏媝曽朄';
-- Modify E_杮壱摦_14502 2017/12/14 Start
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.RATE IS '彏媝棪';
-- Modify E_杮壱摦_14502 2017/12/14 End
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.LIFE_IN_YEAR IS '懴梡擭悢_擭';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.LIFE_IN_MONTHS IS '懴梡擭悢_寧';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.RESERVE1_CODE1 IS '梊旛1';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.RESERVE1_CODE2 IS '梊旛2';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ATTRIBUTE1 IS '峏怴梡帠嬈嫙梡擔';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ATTRIBUTE2 IS '庢摼擔';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ATTRIBUTE3 IS '峔憿';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ATTRIBUTE4 IS '嵶栚';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ATTRIBUTE5 IS '埑弅婰挔丒峊彍曽幃';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ATTRIBUTE6 IS '埑弅峊彍妟';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ATTRIBUTE7 IS '埑弅屻庢摼壙妟';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ATTRIBUTE8 IS '帒嶻僌儖乕僾斣崋';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ATTRIBUTE9 IS '尭懝寁嶼婜娫棜楌';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ATTRIBUTE10 IS '暔審僐乕僪';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ATTRIBUTE11 IS '儕乕僗帒嶻';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ATTRIBUTE12 IS '奐帵僙僌儊儞僩';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ATTRIBUTE13 IS '柺愊';
--
-- Modify E_杮壱摦_14502 2017/12/14 Start
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ATTRIBUTE17 IS 'IFRS晄摦嶻庢摼惻';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ATTRIBUTE18 IS 'IFRS庁擖僐僗僩';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ATTRIBUTE19 IS 'IFRS偦偺懠';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ATTRIBUTE22 IS '屌掕帒嶻帒嶻斣崋';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ATTRIBUTE23 IS 'IFRS懳徾帒嶻斣崋';
-- Modify E_杮壱摦_14502 2017/12/14 End
--
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.LAST_UPDATE_DATE IS '嵟廔峏怴擔';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.LAST_UPDATED_BY IS '嵟廔峏怴幰';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.CREATED_BY IS '嶌惉幰';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.CREATION_DATE IS '嶌惉擔';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.LAST_UPDATE_LOGIN IS '嵟廔峏怴儘僌僀儞';
--
-- Modify E_杮壱摦_14502 2017/12/14 Start
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.KISYU_BOKA IS '婜庱挔曤壙妟';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.YEAR_ADD_AMOUNT IS '婜拞憹壛妟';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ADD_AMOUNT IS '摉婜憹壛妟';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.YEAR_DEL_AMOUNT IS '婜拞尭彮妟';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.DELETE_AMOUNT IS '摉婜尭彮妟';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.DEPRN_RESERVE_12 IS '婜枛弮挔曤壙妟';
-- Modify E_杮壱摦_14502 2017/12/14 End
COMMENT ON TABLE XXCFF_FIXED_ASSETS_V IS '屌掕帒嶻堦棗徠夛價儏乕';

