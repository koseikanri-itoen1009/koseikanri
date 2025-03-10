CREATE OR REPLACE VIEW APPS.XXSKY_Úq_}X^_»Ý_V
(
 gDÔ
,Úq__}X^óMú
,Úq__Ô
,Úq__¼Ì
,Úq__ªÌ
,Úq__Ji¼
,Úq__æª
,Úq__æª¼
,Úq__KpJnú
,Úq__KpI¹ú
,Úq__XÖÔ
,Úq__ZP
,Úq__ZQ
,Úq__dbÔ
,Úq__FAXÔ
,__ø
,__hN^ÀUÖî
,__hN^ÀUÖî¼
,__[t^ÀUÖî
,__[t^ÀUÖî¼
,__UÖO[v
,__UÖO[v¼
,__¨¬ubN
,__¨¬ubN¼
,___åªÞ
,___åªÞ¼
,__{R[h
,__V{R[h
,__{KpJnú
,__ÀÑL³æª
,__ÀÑL³æª¼
,__o×Ç³æª
,__o×Ç³æª¼
,__qÖÎÛÂÛæª
,__qÖÎÛÂÛæª¼
,Úq__~q\¿tO
,Úq__~q\¿tO¼
,__hN_JeS
,__hN_JeS¼
,__[t_JeS
,__[t_JeS¼
,__o×Ë©®ì¬æª
,__o×Ë©®ì¬æª¼
,Úq_¼æª
,Úq_¼æª¼
,Úq_ã_R[h
,Úq_ã_¼
,Úq_\ñã_R[h
,Úq_\ñã_¼
,Úq_ã`F[X
,Úq_ã`F[X¼
,ì¬Ò
,ì¬ú
,ÅIXVÒ
,ÅIXVú
,ÅIXVOC
)
AS
SELECT
        HP.party_number                  --gDÔ
       ,HP.attribute24                   --Úq__}X^óMú
       ,HCA.account_number               --Úq__Ô
       ,XP.party_name                    --Úq__¼Ì
       ,XP.party_short_name              --Úq__ªÌ
       ,XP.party_name_alt                --Úq__Ji¼
       ,HCA.customer_class_code          --Úq__æª
-- 2010/01/28 T.Yoshimoto Mod Start {Ò®#1168
       --,FLV01.meaning                    --Úq__æª¼
       ,(SELECT FLV01.meaning
         FROM fnd_lookup_values FLV01    --NCbNR[h(Úq__æª¼)
         WHERE FLV01.language    = 'JA'                        --¾ê
           AND FLV01.lookup_type = 'CUSTOMER CLASS'            --NCbNR[h^Cv
           AND FLV01.lookup_code = HCA.customer_class_code     --NCbNR[h
        ) FLV01_meaning
-- 2010/01/28 T.Yoshimoto Mod End {Ò®#1168
       ,XP.start_date_active             --Úq__KpJnú
       ,XP.end_date_active               --Úq__KpI¹ú
       ,XP.zip                           --Úq__XÖÔ
       ,XP.address_line1                 --Úq__ZP
       ,XP.address_line2                 --Úq__ZQ
       ,XP.phone                         --Úq__dbÔ
       ,XP.fax                           --Úq__FAXÔ
       ,XP.reserve_order                 --__ø
       ,XP.drink_transfer_std            --__hN^ÀUÖî
-- 2010/01/28 T.Yoshimoto Mod Start {Ò®#1168
       --,FLV02.meaning                    --__hN^ÀUÖî¼
       ,(SELECT FLV02.meaning
         FROM fnd_lookup_values FLV02    --NCbNR[h(__hN^ÀUÖî¼)
         WHERE FLV02.language    = 'JA'
           AND FLV02.lookup_type = 'XXCMN_TRNSFR_FARE_STD'
           AND FLV02.lookup_code = XP.drink_transfer_std
        ) FLV02_meaning
-- 2010/01/28 T.Yoshimoto Mod End {Ò®#1168
       ,XP.leaf_transfer_std             --__[t^ÀUÖî
-- 2010/01/28 T.Yoshimoto Mod Start {Ò®#1168
       --,FLV03.meaning                    --__[t^ÀUÖî¼
       ,(SELECT FLV03.meaning
         FROM fnd_lookup_values FLV03    --NCbNR[h(__[t^ÀUÖî¼)
         WHERE FLV03.language    = 'JA'
           AND FLV03.lookup_type = 'XXCMN_TRNSFR_FARE_STD'
           AND FLV03.lookup_code = XP.leaf_transfer_std
        ) FLV03_meaning
-- 2010/01/28 T.Yoshimoto Mod End {Ò®#1168
       ,XP.transfer_group                --__UÖO[v
-- 2010/01/28 T.Yoshimoto Mod Start {Ò®#1168
       --,FLV04.meaning                    --__UÖO[v¼
       ,(SELECT FLV04.meaning
         FROM fnd_lookup_values FLV04    --NCbNR[h(__UÖO[v¼)
         WHERE FLV04.language    = 'JA'
           AND FLV04.lookup_type = 'XXCMN_D04'
           AND FLV04.lookup_code = XP.transfer_group
        ) FLV04_meaning
-- 2010/01/28 T.Yoshimoto Mod End {Ò®#1168
       ,XP.distribution_block            --__¨¬ubN
-- 2010/01/28 T.Yoshimoto Mod Start {Ò®#1168
       --,FLV05.meaning                    --__¨¬ubN¼
       ,(SELECT FLV05.meaning
         FROM fnd_lookup_values FLV05    --NCbNR[h(__¨¬ubN¼)
         WHERE FLV05.language    = 'JA'
           AND FLV05.lookup_type = 'XXCMN_D12'
           AND FLV05.lookup_code = XP.distribution_block
        ) FLV05_meaning
-- 2010/01/28 T.Yoshimoto Mod End {Ò®#1168
       ,XP.base_major_division           --___åªÞ
-- 2010/01/28 T.Yoshimoto Mod Start {Ò®#1168
       --,FLV06.meaning                    --___åªÞ¼
       ,(SELECT FLV06.meaning
         FROM fnd_lookup_values FLV06    --NCbNR[h(___åªÞ¼)
         WHERE FLV06.language    = 'JA'
           AND FLV06.lookup_type = 'XXWIP_BASE_MAJOR_DIVISION'
           AND FLV06.lookup_code = XP.base_major_division
        ) FLV06_meaning
-- 2010/01/28 T.Yoshimoto Mod End {Ò®#1168
       ,HCA.attribute1                   --__{R[h
       ,HCA.attribute2                   --__V{R[h
       ,HCA.attribute3                   --__{KpJnú
       ,HCA.attribute4                   --__ÀÑL³æª
-- 2010/01/28 T.Yoshimoto Mod Start {Ò®#1168
       --,FLV09.meaning                    --__ÀÑL³æª¼
       ,(SELECT FLV09.meaning
         FROM fnd_lookup_values FLV09    --NCbNR[h(__ÀÑL³æª¼)
         WHERE FLV09.language    = 'JA'
           AND FLV09.lookup_type = 'XXCMN_BASE_RESULTS_CLASS'
           AND FLV09.lookup_code = HCA.attribute4
        ) FLV09_meaning
-- 2010/01/28 T.Yoshimoto Mod End {Ò®#1168
       ,HCA.attribute5                   --__o×Ç³æª
-- 2010/01/28 T.Yoshimoto Mod Start {Ò®#1168
       --,FLV10.meaning                    --__o×Ç³æª¼
       ,(SELECT FLV10.meaning
         FROM fnd_lookup_values FLV10    --NCbNR[h(__o×Ç³æª¼)
         WHERE FLV10.language    = 'JA'
           AND FLV10.lookup_type = 'XXCMN_SHIPMENT_MANAGEMENT'
           AND FLV10.lookup_code = HCA.attribute5
        ) FLV10_meaning
-- 2010/01/28 T.Yoshimoto Mod End {Ò®#1168
       ,HCA.attribute6                   --__qÖÎÛÂÛæª
-- 2010/01/28 T.Yoshimoto Mod Start {Ò®#1168
       --,FLV11.meaning                    --__qÖÎÛÂÛæª¼
       ,(SELECT FLV11.meaning
         FROM fnd_lookup_values FLV11    --NCbNR[h(__qÖÎÛÂÛæª¼)
         WHERE FLV11.language    = 'JA'
           AND FLV11.lookup_type = 'XXCMN_INV_OBJEC_CLASS'
           AND FLV11.lookup_code = HCA.attribute6
        ) FLV11_meaning
-- 2010/01/28 T.Yoshimoto Mod End {Ò®#1168
-- 2009/10/27 Y.Kawano Mod Start {Ô#1675
--       ,HCA.attribute12                  --Úq__~q\¿tO
       ,CASE hca.customer_class_code
        WHEN '1' THEN
          CASE hp.duns_number_c
          WHEN '30' THEN '0'
          WHEN '40' THEN '0'
          WHEN '99' THEN '0'
          ELSE '2'
          END
        WHEN '10' THEN
          CASE hp.duns_number_c
          WHEN '30' THEN '0'
          WHEN '40' THEN '0'
          ELSE '2'
          END
        END cust_enable_flag               --Úq__~q\¿tO
--       ,FLV12.meaning                    --Úq__~q\¿tO¼
       ,CASE hca.customer_class_code
        WHEN '1'  THEN FLV12.meaning
        WHEN '10' THEN FLV122.meaning
        END meaning                      --Úq__~q\¿tO¼
-- 2009/10/27 Y.Kawano Mod End {Ô#1675
       ,HCA.attribute13                  --__hN_JeS
-- 2010/01/28 T.Yoshimoto Mod Start {Ò®#1168
       --,FLV13.meaning                    --__hN_JeS¼
       ,(SELECT FLV13.meaning
         FROM fnd_lookup_values FLV13    --NCbNR[h(__hN_JeS¼)
         WHERE FLV13.language    = 'JA'
           AND FLV13.lookup_type = 'XXWSH_DRINK_BASE_CATEGORY'
           AND FLV13.lookup_code = HCA.attribute13
        ) FLV13_meaning
-- 2010/01/28 T.Yoshimoto Mod End {Ò®#1168
       ,HCA.attribute16                  --__[t_JeS
-- 2010/01/28 T.Yoshimoto Mod Start {Ò®#1168
       --,FLV14.meaning                    --__[t_JeS¼
       ,(SELECT FLV14.meaning
         FROM fnd_lookup_values FLV14    --NCbNR[h(__[t_JeS¼)
         WHERE FLV14.language    = 'JA'
           AND FLV14.lookup_type = 'XXWSH_LEAF_BASE_CATEGORY'
           AND FLV14.lookup_code = HCA.attribute16
        ) FLV14_meaning
-- 2010/01/28 T.Yoshimoto Mod End {Ò®#1168
       ,HCA.attribute14                  --__o×Ë©®ì¬æª
-- 2010/01/28 T.Yoshimoto Mod Start {Ò®#1168
       --,FLV15.meaning                    --__o×Ë©®ì¬æª¼
       ,(SELECT FLV15.meaning
         FROM fnd_lookup_values FLV15    --NCbNR[h(__o×Ë©®ì¬æª¼)
         WHERE FLV15.language    = 'JA'
           AND FLV15.lookup_type = 'XXCMN_SHIPMENT_AUTO'
           AND FLV15.lookup_code = HCA.attribute14
        ) FLV15_meaning
-- 2010/01/28 T.Yoshimoto Mod End {Ò®#1168
       ,HCA.attribute15                  --Úq_¼æª
-- 2010/01/28 T.Yoshimoto Mod Start {Ò®#1168
       --,FLV16.meaning                    --Úq_¼æª¼
       ,(SELECT FLV16.meaning
         FROM fnd_lookup_values FLV16    --NCbNR[h(Úq_¼æª¼)
         WHERE FLV16.language    = 'JA'
           AND FLV16.lookup_type = 'XXCMN_DROP_SHIP_DIV'
           AND FLV16.lookup_code = HCA.attribute15
        ) FLV16_meaning
-- 2010/01/28 T.Yoshimoto Mod End {Ò®#1168
       ,HCA.attribute17                  --Úq_ã_R[h
-- 2010/01/28 T.Yoshimoto Mod Start {Ò®#1168
       --,XCAV01.party_name                --Úq_ã_¼
       ,(SELECT XCAV01.party_name
         FROM xxsky_cust_accounts_v XCAV01   --ÚqîñVIEW(Úq_ã_¼)
         WHERE HCA.attribute17 = XCAV01.party_number
        ) XCAV01_party_name 
-- 2010/01/28 T.Yoshimoto Mod End {Ò®#1168
       ,HCA.attribute18                  --Úq_\ñã_R[h
-- 2010/01/28 T.Yoshimoto Mod Start {Ò®#1168
       --,XCAV02.party_name                --Úq_\ñã_¼
       ,(SELECT XCAV02.party_name
         FROM xxsky_cust_accounts_v XCAV02   --ÚqîñVIEW(Úq_\ñã_¼)
         WHERE HCA.attribute18 = XCAV02.party_number
        ) XCAV02_party_name 
-- 2010/01/28 T.Yoshimoto Mod End {Ò®#1168
       ,HCA.attribute19                  --Úq_ã`F[X
       ,HCA.attribute20                  --Úq_ã`F[X¼
-- 2010/01/28 T.Yoshimoto Mod Start {Ò®#1168
       --,FU_CB.user_name                  --ì¬Ò
       ,(SELECT FU_CB.user_name
         FROM fnd_user FU_CB  --[U[}X^(created_by¼Ìæ¾p)
         WHERE XP.created_by = FU_CB.user_id
        ) FU_CB_user_name
-- 2010/01/28 T.Yoshimoto Mod End {Ò®#1168
       ,TO_CHAR( XP.creation_date, 'YYYY/MM/DD HH24:MI:SS')
                                         --ì¬ú
-- 2010/01/28 T.Yoshimoto Mod Start {Ò®#1168
       --,FU_LU.user_name                  --ÅIXVÒ
       ,(SELECT FU_LU.user_name
         FROM fnd_user FU_LU  --[U[}X^(last_updated_by¼Ìæ¾p)
         WHERE XP.last_updated_by = FU_LU.user_id
        ) FU_LU_user_name
-- 2010/01/28 T.Yoshimoto Mod End {Ò®#1168
       ,TO_CHAR( XP.last_update_date, 'YYYY/MM/DD HH24:MI:SS')
                                         --ÅIXVú
-- 2010/01/28 T.Yoshimoto Mod Start {Ò®#1168
       --,FU_LL.user_name                  --ÅIXVOC
       ,(SELECT FU_LL.user_name
         FROM fnd_user    FU_LL  --[U[}X^(last_update_login¼Ìæ¾p)
             ,fnd_logins FL_LL  --OC}X^(last_update_login¼Ìæ¾p)
         WHERE XP.last_update_login = FL_LL.login_id
         AND   FL_LL.user_id        = FU_LL.user_id
        ) FU_LL_user_name
-- 2010/01/28 T.Yoshimoto Mod End {Ò®#1168
  FROM  xxcmn_parties           XP       --p[eBAhI}X^
       ,hz_parties              HP       --p[eB}X^
       ,hz_cust_accounts        HCA      --Úq}X^
-- 2010/01/28 T.Yoshimoto Del Start {Ò®#1168
       --,xxsky_cust_accounts_v   XCAV01   --ÚqîñVIEW(Úq_ã_¼)
       --,xxsky_cust_accounts_v   XCAV02   --ÚqîñVIEW(Úq_\ñã_¼)
       --,fnd_user                FU_CB    --[U[}X^(created_by¼Ìæ¾p)
       --,fnd_user                FU_LU    --[U[}X^(last_updated_by¼Ìæ¾p)
       --,fnd_user                FU_LL    --[U[}X^(last_update_login¼Ìæ¾p)
       --,fnd_logins              FL_LL    --OC}X^(last_update_login¼Ìæ¾p)
       --,fnd_lookup_values       FLV01    --NCbNR[h(Úq__æª¼)
       --,fnd_lookup_values       FLV02    --NCbNR[h(__hN^ÀUÖî¼)
       --,fnd_lookup_values       FLV03    --NCbNR[h(__[t^ÀUÖî¼)
       --,fnd_lookup_values       FLV04    --NCbNR[h(__UÖO[v¼)
       --,fnd_lookup_values       FLV05    --NCbNR[h(__¨¬ubN¼)
       --,fnd_lookup_values       FLV06    --NCbNR[h(___åªÞ¼)
       --,fnd_lookup_values       FLV09    --NCbNR[h(__ÀÑL³æª¼)
       --,fnd_lookup_values       FLV10    --NCbNR[h(__o×Ç³æª¼)
       --,fnd_lookup_values       FLV11    --NCbNR[h(__qÖÎÛÂÛæª¼)
-- 2010/01/28 T.Yoshimoto Del End {Ò®#1168
       ,fnd_lookup_values       FLV12    --NCbNR[h(Úq__~q\¿tO¼)
-- 2009/10/27 Y.Kawano Mod Start {Ô#1675
       ,fnd_lookup_values       FLV122   --NCbNR[h(Úq__~q\¿tO¼)
-- 2009/10/27 Y.Kawano Mod End   {Ô#1675
-- 2010/01/28 T.Yoshimoto Del Start {Ò®#1168
       --,fnd_lookup_values       FLV13    --NCbNR[h(__hN_JeS¼)
       --,fnd_lookup_values       FLV14    --NCbNR[h(__[t_JeS¼)
       --,fnd_lookup_values       FLV15    --NCbNR[h(__o×Ë©®ì¬æª¼)
       --,fnd_lookup_values       FLV16    --NCbNR[h(Úq_¼æª¼)
-- 2010/01/28 T.Yoshimoto Del End {Ò®#1168
 WHERE  XP.start_date_active <= TRUNC(SYSDATE)
   AND  XP.end_date_active   >= TRUNC(SYSDATE)
   AND  HP.status = 'A'                                    --Xe[^XFLø
   AND  XP.party_id = HP.party_id
   AND  HCA.status = 'A'                                   --Xe[^XFLø
   AND  XP.party_id = HCA.party_id
-- 2010/01/28 T.Yoshimoto Del Start {Ò®#1168
   --AND  HCA.attribute17 = XCAV01.party_number(+)
   --AND  HCA.attribute18 = XCAV02.party_number(+)
   --AND  XP.created_by        = FU_CB.user_id(+)
   --AND  XP.last_updated_by   = FU_LU.user_id(+)
   --AND  XP.last_update_login = FL_LL.login_id(+)
   --AND  FL_LL.user_id        = FU_LL.user_id(+)
   --AND  FLV01.language(+)    = 'JA'                        --¾ê
   --AND  FLV01.lookup_type(+) = 'CUSTOMER CLASS'            --NCbNR[h^Cv
   --AND  FLV01.lookup_code(+) = HCA.customer_class_code     --NCbNR[h
   --AND  FLV02.language(+)    = 'JA'
   --AND  FLV02.lookup_type(+) = 'XXCMN_TRNSFR_FARE_STD'
   --AND  FLV02.lookup_code(+) = XP.drink_transfer_std
   --AND  FLV03.language(+)    = 'JA'
   --AND  FLV03.lookup_type(+) = 'XXCMN_TRNSFR_FARE_STD'
   --AND  FLV03.lookup_code(+) = XP.leaf_transfer_std
   --AND  FLV04.language(+)    = 'JA'
   --AND  FLV04.lookup_type(+) = 'XXCMN_D04'
   --AND  FLV04.lookup_code(+) = XP.transfer_group
   --AND  FLV05.language(+)    = 'JA'
   --AND  FLV05.lookup_type(+) = 'XXCMN_D12'
   --AND  FLV05.lookup_code(+) = XP.distribution_block
   --AND  FLV06.language(+)    = 'JA'
   --AND  FLV06.lookup_type(+) = 'XXWIP_BASE_MAJOR_DIVISION'
   --AND  FLV06.lookup_code(+) = XP.base_major_division
   --AND  FLV09.language(+)    = 'JA'
   --AND  FLV09.lookup_type(+) = 'XXCMN_BASE_RESULTS_CLASS'
   --AND  FLV09.lookup_code(+) = HCA.attribute4
   --AND  FLV10.language(+)    = 'JA'
   --AND  FLV10.lookup_type(+) = 'XXCMN_SHIPMENT_MANAGEMENT'
   --AND  FLV10.lookup_code(+) = HCA.attribute5
   --AND  FLV11.language(+)    = 'JA'
   --AND  FLV11.lookup_type(+) = 'XXCMN_INV_OBJEC_CLASS'
   --AND  FLV11.lookup_code(+) = HCA.attribute6
-- 2010/01/28 T.Yoshimoto Del End {Ò®#1168
   AND  FLV12.language(+)    = 'JA'
   AND  FLV12.lookup_type(+) = 'XXCMN_CUST_ENABLE_FLAG'
-- 2009/10/27 Y.Kawano Mod Start {Ô#1675
--   AND  FLV12.lookup_code(+) = HCA.attribute12
   AND  FLV12.lookup_code(+) = DECODE(HP.duns_number_c,'30','0','40','0','99','0','2')
   AND  FLV122.language(+)    = 'JA'
   AND  FLV122.lookup_type(+) = 'XXCMN_CUST_ENABLE_FLAG'
   AND  FLV122.lookup_code(+) = DECODE(HP.duns_number_c,'30','0','40','0','2')
-- 2009/10/27 Y.Kawano Mod End {Ô#1675
-- 2010/01/28 T.Yoshimoto Del Start {Ò®#1168
   --AND  FLV13.language(+)    = 'JA'
   --AND  FLV13.lookup_type(+) = 'XXWSH_DRINK_BASE_CATEGORY'
   --AND  FLV13.lookup_code(+) = HCA.attribute13
   --AND  FLV14.language(+)    = 'JA'
   --AND  FLV14.lookup_type(+) = 'XXWSH_LEAF_BASE_CATEGORY'
   --AND  FLV14.lookup_code(+) = HCA.attribute16
   --AND  FLV15.language(+)    = 'JA'
   --AND  FLV15.lookup_type(+) = 'XXCMN_SHIPMENT_AUTO'
   --AND  FLV15.lookup_code(+) = HCA.attribute14
   --AND  FLV16.language(+)    = 'JA'
   --AND  FLV16.lookup_type(+) = 'XXCMN_DROP_SHIP_DIV'
   --AND  FLV16.lookup_code(+) = HCA.attribute15
-- 2010/01/28 T.Yoshimoto Del End {Ò®#1168
/
COMMENT ON TABLE APPS.XXSKY_Úq_}X^_»Ý_V IS 'SKYLINKpÚq_}X^i»ÝjVIEW'
/
COMMENT ON COLUMN APPS.XXSKY_Úq_}X^_»Ý_V.gDÔ IS 'gDÔ'
/
COMMENT ON COLUMN APPS.XXSKY_Úq_}X^_»Ý_V.Úq__}X^óMú IS 'Úq__}X^óMú'
/
COMMENT ON COLUMN APPS.XXSKY_Úq_}X^_»Ý_V.Úq__Ô IS 'Úq__Ô'
/
COMMENT ON COLUMN APPS.XXSKY_Úq_}X^_»Ý_V.Úq__¼Ì IS 'Úq__¼Ì'
/
COMMENT ON COLUMN APPS.XXSKY_Úq_}X^_»Ý_V.Úq__ªÌ IS 'Úq__ªÌ'
/
COMMENT ON COLUMN APPS.XXSKY_Úq_}X^_»Ý_V.Úq__Ji¼ IS 'Úq__Ji¼'
/
COMMENT ON COLUMN APPS.XXSKY_Úq_}X^_»Ý_V.Úq__æª IS 'Úq__æª'
/
COMMENT ON COLUMN APPS.XXSKY_Úq_}X^_»Ý_V.Úq__æª¼ IS 'Úq__æª¼'
/
COMMENT ON COLUMN APPS.XXSKY_Úq_}X^_»Ý_V.Úq__KpJnú IS 'Úq__KpJnú'
/
COMMENT ON COLUMN APPS.XXSKY_Úq_}X^_»Ý_V.Úq__KpI¹ú IS 'Úq__KpI¹ú'
/
COMMENT ON COLUMN APPS.XXSKY_Úq_}X^_»Ý_V.Úq__XÖÔ IS 'Úq__XÖÔ'
/
COMMENT ON COLUMN APPS.XXSKY_Úq_}X^_»Ý_V.Úq__ZP IS 'Úq__ZP'
/
COMMENT ON COLUMN APPS.XXSKY_Úq_}X^_»Ý_V.Úq__ZQ IS 'Úq__ZQ'
/
COMMENT ON COLUMN APPS.XXSKY_Úq_}X^_»Ý_V.Úq__dbÔ IS 'Úq__dbÔ'
/
COMMENT ON COLUMN APPS.XXSKY_Úq_}X^_»Ý_V.Úq__FAXÔ IS 'Úq__FAXÔ'
/
COMMENT ON COLUMN APPS.XXSKY_Úq_}X^_»Ý_V.__ø IS '__ø'
/
COMMENT ON COLUMN APPS.XXSKY_Úq_}X^_»Ý_V.__hN^ÀUÖî IS '__hN^ÀUÖî'
/
COMMENT ON COLUMN APPS.XXSKY_Úq_}X^_»Ý_V.__hN^ÀUÖî¼ IS '__hN^ÀUÖî¼'
/
COMMENT ON COLUMN APPS.XXSKY_Úq_}X^_»Ý_V.__[t^ÀUÖî IS '__[t^ÀUÖî'
/
COMMENT ON COLUMN APPS.XXSKY_Úq_}X^_»Ý_V.__[t^ÀUÖî¼ IS '__[t^ÀUÖî¼'
/
COMMENT ON COLUMN APPS.XXSKY_Úq_}X^_»Ý_V.__UÖO[v IS '__UÖO[v'
/
COMMENT ON COLUMN APPS.XXSKY_Úq_}X^_»Ý_V.__UÖO[v¼ IS '__UÖO[v¼'
/
COMMENT ON COLUMN APPS.XXSKY_Úq_}X^_»Ý_V.__¨¬ubN IS '__¨¬ubN'
/
COMMENT ON COLUMN APPS.XXSKY_Úq_}X^_»Ý_V.__¨¬ubN¼ IS '__¨¬ubN¼'
/
COMMENT ON COLUMN APPS.XXSKY_Úq_}X^_»Ý_V.___åªÞ IS '___åªÞ'
/
COMMENT ON COLUMN APPS.XXSKY_Úq_}X^_»Ý_V.___åªÞ¼ IS '___åªÞ¼'
/
COMMENT ON COLUMN APPS.XXSKY_Úq_}X^_»Ý_V.__{R[h IS '__{R[h'
/
COMMENT ON COLUMN APPS.XXSKY_Úq_}X^_»Ý_V.__V{R[h IS '__V{R[h'
/
COMMENT ON COLUMN APPS.XXSKY_Úq_}X^_»Ý_V.__{KpJnú IS '__{KpJnú'
/
COMMENT ON COLUMN APPS.XXSKY_Úq_}X^_»Ý_V.__ÀÑL³æª IS '__ÀÑL³æª'
/
COMMENT ON COLUMN APPS.XXSKY_Úq_}X^_»Ý_V.__ÀÑL³æª¼ IS '__ÀÑL³æª¼'
/
COMMENT ON COLUMN APPS.XXSKY_Úq_}X^_»Ý_V.__o×Ç³æª IS '__o×Ç³æª'
/
COMMENT ON COLUMN APPS.XXSKY_Úq_}X^_»Ý_V.__o×Ç³æª¼ IS '__o×Ç³æª¼'
/
COMMENT ON COLUMN APPS.XXSKY_Úq_}X^_»Ý_V.__qÖÎÛÂÛæª IS '__qÖÎÛÂÛæª'
/
COMMENT ON COLUMN APPS.XXSKY_Úq_}X^_»Ý_V.__qÖÎÛÂÛæª¼ IS '__qÖÎÛÂÛæª¼'
/
COMMENT ON COLUMN APPS.XXSKY_Úq_}X^_»Ý_V.Úq__~q\¿tO IS 'Úq__~q\¿tO'
/
COMMENT ON COLUMN APPS.XXSKY_Úq_}X^_»Ý_V.Úq__~q\¿tO¼ IS 'Úq__~q\¿tO¼'
/
COMMENT ON COLUMN APPS.XXSKY_Úq_}X^_»Ý_V.__hN_JeS IS '__hN_JeS'
/
COMMENT ON COLUMN APPS.XXSKY_Úq_}X^_»Ý_V.__hN_JeS¼ IS '__hN_JeS¼'
/
COMMENT ON COLUMN APPS.XXSKY_Úq_}X^_»Ý_V.__[t_JeS IS '__[t_JeS'
/
COMMENT ON COLUMN APPS.XXSKY_Úq_}X^_»Ý_V.__[t_JeS¼ IS '__[t_JeS¼'
/
COMMENT ON COLUMN APPS.XXSKY_Úq_}X^_»Ý_V.__o×Ë©®ì¬æª IS '__o×Ë©®ì¬æª'
/
COMMENT ON COLUMN APPS.XXSKY_Úq_}X^_»Ý_V.__o×Ë©®ì¬æª¼ IS '__o×Ë©®ì¬æª¼'
/
COMMENT ON COLUMN APPS.XXSKY_Úq_}X^_»Ý_V.Úq_¼æª IS 'Úq_¼æª'
/
COMMENT ON COLUMN APPS.XXSKY_Úq_}X^_»Ý_V.Úq_¼æª¼ IS 'Úq_¼æª¼'
/
COMMENT ON COLUMN APPS.XXSKY_Úq_}X^_»Ý_V.Úq_ã_R[h IS 'Úq_ã_R[h'
/
COMMENT ON COLUMN APPS.XXSKY_Úq_}X^_»Ý_V.Úq_ã_¼ IS 'Úq_ã_¼'
/
COMMENT ON COLUMN APPS.XXSKY_Úq_}X^_»Ý_V.Úq_\ñã_R[h IS 'Úq_\ñã_R[h'
/
COMMENT ON COLUMN APPS.XXSKY_Úq_}X^_»Ý_V.Úq_\ñã_¼ IS 'Úq_\ñã_¼'
/
COMMENT ON COLUMN APPS.XXSKY_Úq_}X^_»Ý_V.Úq_ã`F[X IS 'Úq_ã`F[X'
/
COMMENT ON COLUMN APPS.XXSKY_Úq_}X^_»Ý_V.Úq_ã`F[X¼ IS 'Úq_ã`F[X¼'
/
COMMENT ON COLUMN APPS.XXSKY_Úq_}X^_»Ý_V.ì¬Ò IS 'ì¬Ò'
/
COMMENT ON COLUMN APPS.XXSKY_Úq_}X^_»Ý_V.ì¬ú IS 'ì¬ú'
/
COMMENT ON COLUMN APPS.XXSKY_Úq_}X^_»Ý_V.ÅIXVÒ IS 'ÅIXVÒ'
/
COMMENT ON COLUMN APPS.XXSKY_Úq_}X^_»Ý_V.ÅIXVú IS 'ÅIXVú'
/
COMMENT ON COLUMN APPS.XXSKY_Úq_}X^_»Ý_V.ÅIXVOC IS 'ÅIXVOC'
/
