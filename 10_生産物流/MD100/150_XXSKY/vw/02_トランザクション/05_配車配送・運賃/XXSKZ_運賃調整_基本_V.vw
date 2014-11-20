/*************************************************************************
 * 
 * View  Name      : XXSKZ_‰^’À’²®_Šî–{_V
 * Description     : XXSKZ_‰^’À’²®_Šî–{_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2012/11/26    1.0   SCSK ŒŽ–ì    ‰‰ñì¬
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_‰^’À’²®_Šî–{_V
(
 ¤•i‹æ•ª
,¤•i‹æ•ª–¼
,‰^‘—‹ÆŽÒ
,‰^‘—‹ÆŽÒ–¼
,¿‹æ
,¿‹æ–¼
,”NŒŽ
,Žx•¥€–Ú‚P
,Žx•¥€–Ú‚P–¼
,Žx•¥‹àŠz‚P
,Žx•¥”ñ‰ÛÅ‚P
,Žx•¥€–Ú‚Q
,Žx•¥€–Ú‚Q–¼
,Žx•¥‹àŠz‚Q
,Žx•¥”ñ‰ÛÅ‚Q
,Žx•¥€–Ú‚R
,Žx•¥€–Ú‚R–¼
,Žx•¥‹àŠz‚R
,Žx•¥”ñ‰ÛÅ‚R
,Žx•¥€–Ú‚S
,Žx•¥€–Ú‚S–¼
,Žx•¥‹àŠz‚S
,Žx•¥”ñ‰ÛÅ‚S
,Žx•¥€–Ú‚T
,Žx•¥€–Ú‚T–¼
,Žx•¥‹àŠz‚T
,Žx•¥”ñ‰ÛÅ‚T
,Á”ïÅ’²®
,¿‹€–Ú‚P
,¿‹€–Ú‚P–¼
,¿‹‹àŠz‚P
,¿‹”ñ‰ÛÅ‚P
,¿‹€–Ú‚Q
,¿‹€–Ú‚Q–¼
,¿‹‹àŠz‚Q
,¿‹”ñ‰ÛÅ‚Q
,¿‹€–Ú‚R
,¿‹€–Ú‚R–¼
,¿‹‹àŠz‚R
,¿‹”ñ‰ÛÅ‚R
,¿‹€–Ú‚S
,¿‹€–Ú‚S–¼
,¿‹‹àŠz‚S
,¿‹”ñ‰ÛÅ‚S
,¿‹€–Ú‚T
,¿‹€–Ú‚T–¼
,¿‹‹àŠz‚T
,¿‹”ñ‰ÛÅ‚T
,”ñ‰ÛÅ¿‹‹àŠz‡Œv
,ì¬ŽÒ
,ì¬“ú
,ÅIXVŽÒ
,ÅIXV“ú
,ÅIXVƒƒOƒCƒ“
)
AS
SELECT 
        XAC.goods_classe                                    --¤•i‹æ•ª
       ,FLV01.meaning           goods_classe_name           --¤•i‹æ•ª–¼
       ,XAC.delivery_company_code                           --‰^‘—‹ÆŽÒ
       ,XC2V.party_name         carrier_name                --‰^‘—‹ÆŽÒ–¼
       ,XAC.billing_code                                    --¿‹æ
       ,XL2V.location_name      billing_name                --¿‹æ–¼
       ,XAC.billing_date                                    --”NŒŽ
       ,XAC.item_payment1                                   --Žx•¥€–Ú‚P
       ,FLV02.meaning           item_payment1_name          --Žx•¥€–Ú‚P–¼
       ,XAC.amount_payment1                                 --Žx•¥‹àŠz‚P
       ,XAC.tax_free_payment1                               --Žx•¥”ñ‰ÛÅ‚P
       ,XAC.item_payment2                                   --Žx•¥€–Ú‚Q
       ,FLV03.meaning           item_payment2_name          --Žx•¥€–Ú‚Q–¼
       ,XAC.amount_payment2                                 --Žx•¥‹àŠz‚Q
       ,XAC.tax_free_payment2                               --Žx•¥”ñ‰ÛÅ‚Q
       ,XAC.item_payment3                                   --Žx•¥€–Ú‚R
       ,FLV04.meaning           item_payment3_name          --Žx•¥€–Ú‚R–¼
       ,XAC.amount_payment3                                 --Žx•¥‹àŠz‚R
       ,XAC.tax_free_payment3                               --Žx•¥”ñ‰ÛÅ‚R
       ,XAC.item_payment4                                   --Žx•¥€–Ú‚S
       ,FLV05.meaning           item_payment4_name          --Žx•¥€–Ú‚S–¼
       ,XAC.amount_payment4                                 --Žx•¥‹àŠz‚S
       ,XAC.tax_free_payment4                               --Žx•¥”ñ‰ÛÅ‚S
       ,XAC.item_payment5                                   --Žx•¥€–Ú‚T
       ,FLV06.meaning           item_payment5_name          --Žx•¥€–Ú‚T–¼
       ,XAC.amount_payment5                                 --Žx•¥‹àŠz‚T
       ,XAC.tax_free_payment5                               --Žx•¥”ñ‰ÛÅ‚T
       ,XAC.adj_tax_extra                                   --Á”ïÅ’²®
       ,XAC.item_billing1                                   --¿‹€–Ú‚P
       ,FLV07.meaning           item_billing1_name          --¿‹€–Ú‚P–¼
       ,XAC.amount_billing1                                 --¿‹‹àŠz‚P
       ,XAC.tax_free_billing1                               --¿‹”ñ‰ÛÅ‚P
       ,XAC.item_billing2                                   --¿‹€–Ú‚Q
       ,FLV08.meaning           item_billing2_name          --¿‹€–Ú‚Q–¼
       ,XAC.amount_billing2                                 --¿‹‹àŠz‚Q
       ,XAC.tax_free_billing2                               --¿‹”ñ‰ÛÅ‚Q
       ,XAC.item_billing3                                   --¿‹€–Ú‚R
       ,FLV09.meaning           item_billing3_name          --¿‹€–Ú‚R–¼
       ,XAC.amount_billing3                                 --¿‹‹àŠz‚R
       ,XAC.tax_free_billing3                               --¿‹”ñ‰ÛÅ‚R
       ,XAC.item_billing4                                   --¿‹€–Ú‚S
       ,FLV10.meaning           item_billing4_name          --¿‹€–Ú‚S–¼
       ,XAC.amount_billing4                                 --¿‹‹àŠz‚S
       ,XAC.tax_free_billing4                               --¿‹”ñ‰ÛÅ‚S
       ,XAC.item_billing5                                   --¿‹€–Ú‚T
       ,FLV11.meaning           item_billing5_name          --¿‹€–Ú‚T–¼
       ,XAC.amount_billing5                                 --¿‹‹àŠz‚T
       ,XAC.tax_free_billing5                               --¿‹”ñ‰ÛÅ‚T
       ,XAC.no_tax_billing_total                            --”ñ‰ÛÅ¿‹‹àŠz‡Œv
       ,FU_CB.user_name         created_by_name             --CREATED_BY‚Ìƒ†[ƒU[–¼(ƒƒOƒCƒ“Žž‚Ì“ü—ÍƒR[ƒh)
       ,TO_CHAR( XAC.creation_date, 'YYYY/MM/DD HH24:MI:SS')
                                creation_date               --ì¬“úŽž
       ,FU_LU.user_name         last_updated_by_name        --LAST_UPDATED_BY‚Ìƒ†[ƒU[–¼(ƒƒOƒCƒ“Žž‚Ì“ü—ÍƒR[ƒh)
       ,TO_CHAR( XAC.last_update_date, 'YYYY/MM/DD HH24:MI:SS')
                                last_update_date            --XV“úŽž
       ,FU_LL.user_name         last_update_login_name      --LAST_UPDATE_LOGIN‚Ìƒ†[ƒU[–¼(ƒƒOƒCƒ“Žž‚Ì“ü—ÍƒR[ƒh)
  FROM  xxwip_adj_charges       XAC                         --‰^’À’²®ƒAƒhƒIƒ“ƒCƒ“ƒ^ƒtƒF[ƒX
       ,xxskz_carriers2_v       XC2V                        --SKYLINK—p’†ŠÔVIEW ‰^‘—‹ÆŽÒŽæ“¾VIEW
       ,xxskz_locations2_v      XL2V                        --SKYLINK—p’†ŠÔVIEW ¿‹æŽæ“¾VIEW
       ,fnd_lookup_values       FLV01                       --¤•i‹æ•ª–¼Žæ“¾—p
       ,fnd_lookup_values       FLV02                       --Žx•¥€–Ú‚P–¼Žæ“¾—p
       ,fnd_lookup_values       FLV03                       --Žx•¥€–Ú‚Q–¼Žæ“¾—p
       ,fnd_lookup_values       FLV04                       --Žx•¥€–Ú‚R–¼Žæ“¾—p
       ,fnd_lookup_values       FLV05                       --Žx•¥€–Ú‚S–¼Žæ“¾—p
       ,fnd_lookup_values       FLV06                       --Žx•¥€–Ú‚T–¼Žæ“¾—p
       ,fnd_lookup_values       FLV07                       --¿‹€–Ú‚P–¼Žæ“¾—p
       ,fnd_lookup_values       FLV08                       --¿‹€–Ú‚Q–¼Žæ“¾—p
       ,fnd_lookup_values       FLV09                       --¿‹€–Ú‚R–¼Žæ“¾—p
       ,fnd_lookup_values       FLV10                       --¿‹€–Ú‚S–¼Žæ“¾—p
       ,fnd_lookup_values       FLV11                       --¿‹€–Ú‚T–¼Žæ“¾—p
       ,fnd_user                FU_CB                       --ƒ†[ƒU[ƒ}ƒXƒ^(CREATED_BY–¼ÌŽæ“¾—p)
       ,fnd_user                FU_LU                       --ƒ†[ƒU[ƒ}ƒXƒ^(LAST_UPDATE_BY–¼ÌŽæ“¾—p)
       ,fnd_user                FU_LL                       --ƒ†[ƒU[ƒ}ƒXƒ^(LAST_UPDATE_LOGIN–¼ÌŽæ“¾—p)
       ,fnd_logins              FL_LL                       --ƒƒOƒCƒ“ƒ}ƒXƒ^(LAST_UPDATE_LOGIN–¼ÌŽæ“¾—p)
 WHERE
    --‰^‘—‹ÆŽÒ–¼Žæ“¾ðŒ
        XC2V.freight_code(+)        =  XAC.delivery_company_code
   AND  XC2V.start_date_active(+)   <= LAST_DAY(TO_DATE(XAC.billing_date || '01', 'YYYYMMDD'))
   AND  XC2V.end_date_active(+)     >= LAST_DAY(TO_DATE(XAC.billing_date || '01', 'YYYYMMDD'))
    --¿‹æ–¼Žæ“¾ðŒ
   AND  XL2V.location_code(+)       =  XAC.billing_code
   AND  XL2V.start_date_active(+)   <= LAST_DAY(TO_DATE(XAC.billing_date || '01', 'YYYYMMDD'))
   AND  XL2V.end_date_active(+)     >= LAST_DAY(TO_DATE(XAC.billing_date || '01', 'YYYYMMDD'))
    --¤•i‹æ•ª–¼Žæ“¾ðŒ
   AND  FLV01.language(+)           = 'JA'
   AND  FLV01.lookup_type(+)        = 'XXWIP_ITEM_TYPE'
   AND  FLV01.lookup_code(+)        = XAC.goods_classe
    --Žx•¥€–Ú‚P–¼Žæ“¾ðŒ
   AND  FLV02.language(+)           = 'JA'
   AND  FLV02.lookup_type(+)        = 'XXWIP_PAY_BILL_ITEM'
   AND  FLV02.lookup_code(+)        = XAC.item_payment1
    --Žx•¥€–Ú‚Q–¼Žæ“¾ðŒ
   AND  FLV03.language(+)           = 'JA'
   AND  FLV03.lookup_type(+)        = 'XXWIP_PAY_BILL_ITEM'
   AND  FLV03.lookup_code(+)        = XAC.item_payment2
    --Žx•¥€–Ú‚R–¼Žæ“¾ðŒ
   AND  FLV04.language(+)           = 'JA'
   AND  FLV04.lookup_type(+)        = 'XXWIP_PAY_BILL_ITEM'
   AND  FLV04.lookup_code(+)        = XAC.item_payment3
    --Žx•¥€–Ú‚S–¼Žæ“¾ðŒ
   AND  FLV05.language(+)           = 'JA'
   AND  FLV05.lookup_type(+)        = 'XXWIP_PAY_BILL_ITEM'
   AND  FLV05.lookup_code(+)        = XAC.item_payment4
    --Žx•¥€–Ú‚T–¼Žæ“¾ðŒ
   AND  FLV06.language(+)           = 'JA'
   AND  FLV06.lookup_type(+)        = 'XXWIP_PAY_BILL_ITEM'
   AND  FLV06.lookup_code(+)        = XAC.item_payment5
    --¿‹€–Ú‚P–¼Žæ“¾ðŒ
   AND  FLV07.language(+)           = 'JA'
   AND  FLV07.lookup_type(+)        = 'XXWIP_PAY_BILL_ITEM'
   AND  FLV07.lookup_code(+)        = XAC.item_billing1
    --¿‹€–Ú‚Q–¼Žæ“¾ðŒ
   AND  FLV08.language(+)           = 'JA'
   AND  FLV08.lookup_type(+)        = 'XXWIP_PAY_BILL_ITEM'
   AND  FLV08.lookup_code(+)        = XAC.item_billing2
    --¿‹€–Ú‚R–¼Žæ“¾ðŒ
   AND  FLV09.language(+)           = 'JA'
   AND  FLV09.lookup_type(+)        = 'XXWIP_PAY_BILL_ITEM'
   AND  FLV09.lookup_code(+)        = XAC.item_billing3
    --¿‹€–Ú‚S–¼Žæ“¾ðŒ
   AND  FLV10.language(+)           = 'JA'
   AND  FLV10.lookup_type(+)        = 'XXWIP_PAY_BILL_ITEM'
   AND  FLV10.lookup_code(+)        = XAC.item_billing4
    --¿‹€–Ú‚T–¼Žæ“¾ðŒ
   AND  FLV11.language(+)           = 'JA'
   AND  FLV11.lookup_type(+)        = 'XXWIP_PAY_BILL_ITEM'
   AND  FLV11.lookup_code(+)        = XAC.item_billing5
   --WHOƒJƒ‰ƒ€Žæ“¾
   AND  XAC.created_by              = FU_CB.user_id(+)
   AND  XAC.last_updated_by         = FU_LU.user_id(+)
   AND  XAC.last_update_login       = FL_LL.login_id(+)
   AND  FL_LL.user_id               = FU_LL.user_id(+)
/
COMMENT ON TABLE APPS.XXSKZ_‰^’À’²®_Šî–{_V                     IS 'SKYLINK—p‰^’À’²®iŠî–{jVIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_‰^’À’²®_Šî–{_V.¤•i‹æ•ª           IS '¤•i‹æ•ª'
/
COMMENT ON COLUMN APPS.XXSKZ_‰^’À’²®_Šî–{_V.¤•i‹æ•ª–¼         IS '¤•i‹æ•ª–¼'
/
COMMENT ON COLUMN APPS.XXSKZ_‰^’À’²®_Šî–{_V.‰^‘—‹ÆŽÒ           IS '‰^‘—‹ÆŽÒ'
/
COMMENT ON COLUMN APPS.XXSKZ_‰^’À’²®_Šî–{_V.‰^‘—‹ÆŽÒ–¼         IS '‰^‘—‹ÆŽÒ–¼'
/
COMMENT ON COLUMN APPS.XXSKZ_‰^’À’²®_Šî–{_V.¿‹æ             IS '¿‹æ'
/
COMMENT ON COLUMN APPS.XXSKZ_‰^’À’²®_Šî–{_V.¿‹æ–¼           IS '¿‹æ–¼'
/
COMMENT ON COLUMN APPS.XXSKZ_‰^’À’²®_Šî–{_V.”NŒŽ               IS '”NŒŽ'
/
COMMENT ON COLUMN APPS.XXSKZ_‰^’À’²®_Šî–{_V.Žx•¥€–Ú‚P         IS 'Žx•¥€–Ú‚P'
/
COMMENT ON COLUMN APPS.XXSKZ_‰^’À’²®_Šî–{_V.Žx•¥€–Ú‚P–¼       IS 'Žx•¥€–Ú‚P–¼'
/
COMMENT ON COLUMN APPS.XXSKZ_‰^’À’²®_Šî–{_V.Žx•¥‹àŠz‚P         IS 'Žx•¥‹àŠz‚P'
/
COMMENT ON COLUMN APPS.XXSKZ_‰^’À’²®_Šî–{_V.Žx•¥”ñ‰ÛÅ‚P       IS 'Žx•¥”ñ‰ÛÅ‚P'
/
COMMENT ON COLUMN APPS.XXSKZ_‰^’À’²®_Šî–{_V.Žx•¥€–Ú‚Q         IS 'Žx•¥€–Ú‚Q'
/
COMMENT ON COLUMN APPS.XXSKZ_‰^’À’²®_Šî–{_V.Žx•¥€–Ú‚Q–¼       IS 'Žx•¥€–Ú‚Q–¼'
/
COMMENT ON COLUMN APPS.XXSKZ_‰^’À’²®_Šî–{_V.Žx•¥‹àŠz‚Q         IS 'Žx•¥‹àŠz‚Q'
/
COMMENT ON COLUMN APPS.XXSKZ_‰^’À’²®_Šî–{_V.Žx•¥”ñ‰ÛÅ‚Q       IS 'Žx•¥”ñ‰ÛÅ‚Q'
/
COMMENT ON COLUMN APPS.XXSKZ_‰^’À’²®_Šî–{_V.Žx•¥€–Ú‚R         IS 'Žx•¥€–Ú‚R'
/
COMMENT ON COLUMN APPS.XXSKZ_‰^’À’²®_Šî–{_V.Žx•¥€–Ú‚R–¼       IS 'Žx•¥€–Ú‚R–¼'
/
COMMENT ON COLUMN APPS.XXSKZ_‰^’À’²®_Šî–{_V.Žx•¥‹àŠz‚R         IS 'Žx•¥‹àŠz‚R'
/
COMMENT ON COLUMN APPS.XXSKZ_‰^’À’²®_Šî–{_V.Žx•¥”ñ‰ÛÅ‚R       IS 'Žx•¥”ñ‰ÛÅ‚R'
/
COMMENT ON COLUMN APPS.XXSKZ_‰^’À’²®_Šî–{_V.Žx•¥€–Ú‚S         IS 'Žx•¥€–Ú‚S'
/
COMMENT ON COLUMN APPS.XXSKZ_‰^’À’²®_Šî–{_V.Žx•¥€–Ú‚S–¼       IS 'Žx•¥€–Ú‚S–¼'
/
COMMENT ON COLUMN APPS.XXSKZ_‰^’À’²®_Šî–{_V.Žx•¥‹àŠz‚S         IS 'Žx•¥‹àŠz‚S'
/
COMMENT ON COLUMN APPS.XXSKZ_‰^’À’²®_Šî–{_V.Žx•¥”ñ‰ÛÅ‚S       IS 'Žx•¥”ñ‰ÛÅ‚S'
/
COMMENT ON COLUMN APPS.XXSKZ_‰^’À’²®_Šî–{_V.Žx•¥€–Ú‚T         IS 'Žx•¥€–Ú‚T'
/
COMMENT ON COLUMN APPS.XXSKZ_‰^’À’²®_Šî–{_V.Žx•¥€–Ú‚T–¼       IS 'Žx•¥€–Ú‚T–¼'
/
COMMENT ON COLUMN APPS.XXSKZ_‰^’À’²®_Šî–{_V.Žx•¥‹àŠz‚T         IS 'Žx•¥‹àŠz‚T'
/
COMMENT ON COLUMN APPS.XXSKZ_‰^’À’²®_Šî–{_V.Žx•¥”ñ‰ÛÅ‚T       IS 'Žx•¥”ñ‰ÛÅ‚T'
/
COMMENT ON COLUMN APPS.XXSKZ_‰^’À’²®_Šî–{_V.Á”ïÅ’²®         IS 'Á”ïÅ’²®'
/
COMMENT ON COLUMN APPS.XXSKZ_‰^’À’²®_Šî–{_V.¿‹€–Ú‚P         IS '¿‹€–Ú‚P'
/
COMMENT ON COLUMN APPS.XXSKZ_‰^’À’²®_Šî–{_V.¿‹€–Ú‚P–¼       IS '¿‹€–Ú‚P–¼'
/
COMMENT ON COLUMN APPS.XXSKZ_‰^’À’²®_Šî–{_V.¿‹‹àŠz‚P         IS '¿‹‹àŠz‚P'
/
COMMENT ON COLUMN APPS.XXSKZ_‰^’À’²®_Šî–{_V.¿‹”ñ‰ÛÅ‚P       IS '¿‹”ñ‰ÛÅ‚P'
/
COMMENT ON COLUMN APPS.XXSKZ_‰^’À’²®_Šî–{_V.¿‹€–Ú‚Q         IS '¿‹€–Ú‚Q'
/
COMMENT ON COLUMN APPS.XXSKZ_‰^’À’²®_Šî–{_V.¿‹€–Ú‚Q–¼       IS '¿‹€–Ú‚Q–¼'
/
COMMENT ON COLUMN APPS.XXSKZ_‰^’À’²®_Šî–{_V.¿‹‹àŠz‚Q         IS '¿‹‹àŠz‚Q'
/
COMMENT ON COLUMN APPS.XXSKZ_‰^’À’²®_Šî–{_V.¿‹”ñ‰ÛÅ‚Q       IS '¿‹”ñ‰ÛÅ‚Q'
/
COMMENT ON COLUMN APPS.XXSKZ_‰^’À’²®_Šî–{_V.¿‹€–Ú‚R         IS '¿‹€–Ú‚R'
/
COMMENT ON COLUMN APPS.XXSKZ_‰^’À’²®_Šî–{_V.¿‹€–Ú‚R–¼       IS '¿‹€–Ú‚R–¼'
/
COMMENT ON COLUMN APPS.XXSKZ_‰^’À’²®_Šî–{_V.¿‹‹àŠz‚R         IS '¿‹‹àŠz‚R'
/
COMMENT ON COLUMN APPS.XXSKZ_‰^’À’²®_Šî–{_V.¿‹”ñ‰ÛÅ‚R       IS '¿‹”ñ‰ÛÅ‚R'
/
COMMENT ON COLUMN APPS.XXSKZ_‰^’À’²®_Šî–{_V.¿‹€–Ú‚S         IS '¿‹€–Ú‚S'
/
COMMENT ON COLUMN APPS.XXSKZ_‰^’À’²®_Šî–{_V.¿‹€–Ú‚S–¼       IS '¿‹€–Ú‚S–¼'
/
COMMENT ON COLUMN APPS.XXSKZ_‰^’À’²®_Šî–{_V.¿‹‹àŠz‚S         IS '¿‹‹àŠz‚S'
/
COMMENT ON COLUMN APPS.XXSKZ_‰^’À’²®_Šî–{_V.¿‹”ñ‰ÛÅ‚S       IS '¿‹”ñ‰ÛÅ‚S'
/
COMMENT ON COLUMN APPS.XXSKZ_‰^’À’²®_Šî–{_V.¿‹€–Ú‚T         IS '¿‹€–Ú‚T'
/
COMMENT ON COLUMN APPS.XXSKZ_‰^’À’²®_Šî–{_V.¿‹€–Ú‚T–¼       IS '¿‹€–Ú‚T–¼'
/
COMMENT ON COLUMN APPS.XXSKZ_‰^’À’²®_Šî–{_V.¿‹‹àŠz‚T         IS '¿‹‹àŠz‚T'
/
COMMENT ON COLUMN APPS.XXSKZ_‰^’À’²®_Šî–{_V.¿‹”ñ‰ÛÅ‚T       IS '¿‹”ñ‰ÛÅ‚T'
/
COMMENT ON COLUMN APPS.XXSKZ_‰^’À’²®_Šî–{_V.”ñ‰ÛÅ¿‹‹àŠz‡Œv IS '”ñ‰ÛÅ¿‹‹àŠz‡Œv'
/
COMMENT ON COLUMN APPS.XXSKZ_‰^’À’²®_Šî–{_V.ì¬ŽÒ             IS 'ì¬ŽÒ'
/
COMMENT ON COLUMN APPS.XXSKZ_‰^’À’²®_Šî–{_V.ì¬“ú             IS 'ì¬“ú'
/
COMMENT ON COLUMN APPS.XXSKZ_‰^’À’²®_Šî–{_V.ÅIXVŽÒ         IS 'ÅIXVŽÒ'
/
COMMENT ON COLUMN APPS.XXSKZ_‰^’À’²®_Šî–{_V.ÅIXV“ú         IS 'ÅIXV“ú'
/
COMMENT ON COLUMN APPS.XXSKZ_‰^’À’²®_Šî–{_V.ÅIXVƒƒOƒCƒ“   IS 'ÅIXVƒƒOƒCƒ“'
/