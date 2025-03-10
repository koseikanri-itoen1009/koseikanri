CREATE OR REPLACE VIEW APPS.XXSKY_^À²®_î{_V
(
 ¤iæª
,¤iæª¼
,^ÆÒ
,^ÆÒ¼
,¿æ
,¿æ¼
,N
,x¥ÚP
,x¥ÚP¼
,x¥àzP
,x¥ñÛÅP
,x¥ÚQ
,x¥ÚQ¼
,x¥àzQ
,x¥ñÛÅQ
,x¥ÚR
,x¥ÚR¼
,x¥àzR
,x¥ñÛÅR
,x¥ÚS
,x¥ÚS¼
,x¥àzS
,x¥ñÛÅS
,x¥ÚT
,x¥ÚT¼
,x¥àzT
,x¥ñÛÅT
,ÁïÅ²®
,¿ÚP
,¿ÚP¼
,¿àzP
,¿ñÛÅP
,¿ÚQ
,¿ÚQ¼
,¿àzQ
,¿ñÛÅQ
,¿ÚR
,¿ÚR¼
,¿àzR
,¿ñÛÅR
,¿ÚS
,¿ÚS¼
,¿àzS
,¿ñÛÅS
,¿ÚT
,¿ÚT¼
,¿àzT
,¿ñÛÅT
,ñÛÅ¿àzv
,ì¬Ò
,ì¬ú
,ÅIXVÒ
,ÅIXVú
,ÅIXVOC
)
AS
SELECT 
        XAC.goods_classe                                    --¤iæª
       ,FLV01.meaning           goods_classe_name           --¤iæª¼
       ,XAC.delivery_company_code                           --^ÆÒ
       ,XC2V.party_name         carrier_name                --^ÆÒ¼
       ,XAC.billing_code                                    --¿æ
       ,XL2V.location_name      billing_name                --¿æ¼
       ,XAC.billing_date                                    --N
       ,XAC.item_payment1                                   --x¥ÚP
       ,FLV02.meaning           item_payment1_name          --x¥ÚP¼
       ,XAC.amount_payment1                                 --x¥àzP
       ,XAC.tax_free_payment1                               --x¥ñÛÅP
       ,XAC.item_payment2                                   --x¥ÚQ
       ,FLV03.meaning           item_payment2_name          --x¥ÚQ¼
       ,XAC.amount_payment2                                 --x¥àzQ
       ,XAC.tax_free_payment2                               --x¥ñÛÅQ
       ,XAC.item_payment3                                   --x¥ÚR
       ,FLV04.meaning           item_payment3_name          --x¥ÚR¼
       ,XAC.amount_payment3                                 --x¥àzR
       ,XAC.tax_free_payment3                               --x¥ñÛÅR
       ,XAC.item_payment4                                   --x¥ÚS
       ,FLV05.meaning           item_payment4_name          --x¥ÚS¼
       ,XAC.amount_payment4                                 --x¥àzS
       ,XAC.tax_free_payment4                               --x¥ñÛÅS
       ,XAC.item_payment5                                   --x¥ÚT
       ,FLV06.meaning           item_payment5_name          --x¥ÚT¼
       ,XAC.amount_payment5                                 --x¥àzT
       ,XAC.tax_free_payment5                               --x¥ñÛÅT
       ,XAC.adj_tax_extra                                   --ÁïÅ²®
       ,XAC.item_billing1                                   --¿ÚP
       ,FLV07.meaning           item_billing1_name          --¿ÚP¼
       ,XAC.amount_billing1                                 --¿àzP
       ,XAC.tax_free_billing1                               --¿ñÛÅP
       ,XAC.item_billing2                                   --¿ÚQ
       ,FLV08.meaning           item_billing2_name          --¿ÚQ¼
       ,XAC.amount_billing2                                 --¿àzQ
       ,XAC.tax_free_billing2                               --¿ñÛÅQ
       ,XAC.item_billing3                                   --¿ÚR
       ,FLV09.meaning           item_billing3_name          --¿ÚR¼
       ,XAC.amount_billing3                                 --¿àzR
       ,XAC.tax_free_billing3                               --¿ñÛÅR
       ,XAC.item_billing4                                   --¿ÚS
       ,FLV10.meaning           item_billing4_name          --¿ÚS¼
       ,XAC.amount_billing4                                 --¿àzS
       ,XAC.tax_free_billing4                               --¿ñÛÅS
       ,XAC.item_billing5                                   --¿ÚT
       ,FLV11.meaning           item_billing5_name          --¿ÚT¼
       ,XAC.amount_billing5                                 --¿àzT
       ,XAC.tax_free_billing5                               --¿ñÛÅT
       ,XAC.no_tax_billing_total                            --ñÛÅ¿àzv
       ,FU_CB.user_name         created_by_name             --CREATED_BYÌ[U[¼(OCÌüÍR[h)
       ,TO_CHAR( XAC.creation_date, 'YYYY/MM/DD HH24:MI:SS')
                                creation_date               --ì¬ú
       ,FU_LU.user_name         last_updated_by_name        --LAST_UPDATED_BYÌ[U[¼(OCÌüÍR[h)
       ,TO_CHAR( XAC.last_update_date, 'YYYY/MM/DD HH24:MI:SS')
                                last_update_date            --XVú
       ,FU_LL.user_name         last_update_login_name      --LAST_UPDATE_LOGINÌ[U[¼(OCÌüÍR[h)
  FROM  xxwip_adj_charges       XAC                         --^À²®AhIC^tF[X
       ,xxsky_carriers2_v       XC2V                        --SKYLINKpÔVIEW ^ÆÒæ¾VIEW
       ,xxsky_locations2_v      XL2V                        --SKYLINKpÔVIEW ¿ææ¾VIEW
       ,fnd_lookup_values       FLV01                       --¤iæª¼æ¾p
       ,fnd_lookup_values       FLV02                       --x¥ÚP¼æ¾p
       ,fnd_lookup_values       FLV03                       --x¥ÚQ¼æ¾p
       ,fnd_lookup_values       FLV04                       --x¥ÚR¼æ¾p
       ,fnd_lookup_values       FLV05                       --x¥ÚS¼æ¾p
       ,fnd_lookup_values       FLV06                       --x¥ÚT¼æ¾p
       ,fnd_lookup_values       FLV07                       --¿ÚP¼æ¾p
       ,fnd_lookup_values       FLV08                       --¿ÚQ¼æ¾p
       ,fnd_lookup_values       FLV09                       --¿ÚR¼æ¾p
       ,fnd_lookup_values       FLV10                       --¿ÚS¼æ¾p
       ,fnd_lookup_values       FLV11                       --¿ÚT¼æ¾p
       ,fnd_user                FU_CB                       --[U[}X^(CREATED_BY¼Ìæ¾p)
       ,fnd_user                FU_LU                       --[U[}X^(LAST_UPDATE_BY¼Ìæ¾p)
       ,fnd_user                FU_LL                       --[U[}X^(LAST_UPDATE_LOGIN¼Ìæ¾p)
       ,fnd_logins              FL_LL                       --OC}X^(LAST_UPDATE_LOGIN¼Ìæ¾p)
 WHERE
    --^ÆÒ¼æ¾ð
        XC2V.freight_code(+)        =  XAC.delivery_company_code
   AND  XC2V.start_date_active(+)   <= LAST_DAY(TO_DATE(XAC.billing_date || '01', 'YYYYMMDD'))
   AND  XC2V.end_date_active(+)     >= LAST_DAY(TO_DATE(XAC.billing_date || '01', 'YYYYMMDD'))
    --¿æ¼æ¾ð
   AND  XL2V.location_code(+)       =  XAC.billing_code
   AND  XL2V.start_date_active(+)   <= LAST_DAY(TO_DATE(XAC.billing_date || '01', 'YYYYMMDD'))
   AND  XL2V.end_date_active(+)     >= LAST_DAY(TO_DATE(XAC.billing_date || '01', 'YYYYMMDD'))
    --¤iæª¼æ¾ð
   AND  FLV01.language(+)           = 'JA'
   AND  FLV01.lookup_type(+)        = 'XXWIP_ITEM_TYPE'
   AND  FLV01.lookup_code(+)        = XAC.goods_classe
    --x¥ÚP¼æ¾ð
   AND  FLV02.language(+)           = 'JA'
   AND  FLV02.lookup_type(+)        = 'XXWIP_PAY_BILL_ITEM'
   AND  FLV02.lookup_code(+)        = XAC.item_payment1
    --x¥ÚQ¼æ¾ð
   AND  FLV03.language(+)           = 'JA'
   AND  FLV03.lookup_type(+)        = 'XXWIP_PAY_BILL_ITEM'
   AND  FLV03.lookup_code(+)        = XAC.item_payment2
    --x¥ÚR¼æ¾ð
   AND  FLV04.language(+)           = 'JA'
   AND  FLV04.lookup_type(+)        = 'XXWIP_PAY_BILL_ITEM'
   AND  FLV04.lookup_code(+)        = XAC.item_payment3
    --x¥ÚS¼æ¾ð
   AND  FLV05.language(+)           = 'JA'
   AND  FLV05.lookup_type(+)        = 'XXWIP_PAY_BILL_ITEM'
   AND  FLV05.lookup_code(+)        = XAC.item_payment4
    --x¥ÚT¼æ¾ð
   AND  FLV06.language(+)           = 'JA'
   AND  FLV06.lookup_type(+)        = 'XXWIP_PAY_BILL_ITEM'
   AND  FLV06.lookup_code(+)        = XAC.item_payment5
    --¿ÚP¼æ¾ð
   AND  FLV07.language(+)           = 'JA'
   AND  FLV07.lookup_type(+)        = 'XXWIP_PAY_BILL_ITEM'
   AND  FLV07.lookup_code(+)        = XAC.item_billing1
    --¿ÚQ¼æ¾ð
   AND  FLV08.language(+)           = 'JA'
   AND  FLV08.lookup_type(+)        = 'XXWIP_PAY_BILL_ITEM'
   AND  FLV08.lookup_code(+)        = XAC.item_billing2
    --¿ÚR¼æ¾ð
   AND  FLV09.language(+)           = 'JA'
   AND  FLV09.lookup_type(+)        = 'XXWIP_PAY_BILL_ITEM'
   AND  FLV09.lookup_code(+)        = XAC.item_billing3
    --¿ÚS¼æ¾ð
   AND  FLV10.language(+)           = 'JA'
   AND  FLV10.lookup_type(+)        = 'XXWIP_PAY_BILL_ITEM'
   AND  FLV10.lookup_code(+)        = XAC.item_billing4
    --¿ÚT¼æ¾ð
   AND  FLV11.language(+)           = 'JA'
   AND  FLV11.lookup_type(+)        = 'XXWIP_PAY_BILL_ITEM'
   AND  FLV11.lookup_code(+)        = XAC.item_billing5
   --WHOJæ¾
   AND  XAC.created_by              = FU_CB.user_id(+)
   AND  XAC.last_updated_by         = FU_LU.user_id(+)
   AND  XAC.last_update_login       = FL_LL.login_id(+)
   AND  FL_LL.user_id               = FU_LL.user_id(+)
/
COMMENT ON TABLE APPS.XXSKY_^À²®_î{_V                     IS 'SKYLINKp^À²®iî{jVIEW'
/
COMMENT ON COLUMN APPS.XXSKY_^À²®_î{_V.¤iæª           IS '¤iæª'
/
COMMENT ON COLUMN APPS.XXSKY_^À²®_î{_V.¤iæª¼         IS '¤iæª¼'
/
COMMENT ON COLUMN APPS.XXSKY_^À²®_î{_V.^ÆÒ           IS '^ÆÒ'
/
COMMENT ON COLUMN APPS.XXSKY_^À²®_î{_V.^ÆÒ¼         IS '^ÆÒ¼'
/
COMMENT ON COLUMN APPS.XXSKY_^À²®_î{_V.¿æ             IS '¿æ'
/
COMMENT ON COLUMN APPS.XXSKY_^À²®_î{_V.¿æ¼           IS '¿æ¼'
/
COMMENT ON COLUMN APPS.XXSKY_^À²®_î{_V.N               IS 'N'
/
COMMENT ON COLUMN APPS.XXSKY_^À²®_î{_V.x¥ÚP         IS 'x¥ÚP'
/
COMMENT ON COLUMN APPS.XXSKY_^À²®_î{_V.x¥ÚP¼       IS 'x¥ÚP¼'
/
COMMENT ON COLUMN APPS.XXSKY_^À²®_î{_V.x¥àzP         IS 'x¥àzP'
/
COMMENT ON COLUMN APPS.XXSKY_^À²®_î{_V.x¥ñÛÅP       IS 'x¥ñÛÅP'
/
COMMENT ON COLUMN APPS.XXSKY_^À²®_î{_V.x¥ÚQ         IS 'x¥ÚQ'
/
COMMENT ON COLUMN APPS.XXSKY_^À²®_î{_V.x¥ÚQ¼       IS 'x¥ÚQ¼'
/
COMMENT ON COLUMN APPS.XXSKY_^À²®_î{_V.x¥àzQ         IS 'x¥àzQ'
/
COMMENT ON COLUMN APPS.XXSKY_^À²®_î{_V.x¥ñÛÅQ       IS 'x¥ñÛÅQ'
/
COMMENT ON COLUMN APPS.XXSKY_^À²®_î{_V.x¥ÚR         IS 'x¥ÚR'
/
COMMENT ON COLUMN APPS.XXSKY_^À²®_î{_V.x¥ÚR¼       IS 'x¥ÚR¼'
/
COMMENT ON COLUMN APPS.XXSKY_^À²®_î{_V.x¥àzR         IS 'x¥àzR'
/
COMMENT ON COLUMN APPS.XXSKY_^À²®_î{_V.x¥ñÛÅR       IS 'x¥ñÛÅR'
/
COMMENT ON COLUMN APPS.XXSKY_^À²®_î{_V.x¥ÚS         IS 'x¥ÚS'
/
COMMENT ON COLUMN APPS.XXSKY_^À²®_î{_V.x¥ÚS¼       IS 'x¥ÚS¼'
/
COMMENT ON COLUMN APPS.XXSKY_^À²®_î{_V.x¥àzS         IS 'x¥àzS'
/
COMMENT ON COLUMN APPS.XXSKY_^À²®_î{_V.x¥ñÛÅS       IS 'x¥ñÛÅS'
/
COMMENT ON COLUMN APPS.XXSKY_^À²®_î{_V.x¥ÚT         IS 'x¥ÚT'
/
COMMENT ON COLUMN APPS.XXSKY_^À²®_î{_V.x¥ÚT¼       IS 'x¥ÚT¼'
/
COMMENT ON COLUMN APPS.XXSKY_^À²®_î{_V.x¥àzT         IS 'x¥àzT'
/
COMMENT ON COLUMN APPS.XXSKY_^À²®_î{_V.x¥ñÛÅT       IS 'x¥ñÛÅT'
/
COMMENT ON COLUMN APPS.XXSKY_^À²®_î{_V.ÁïÅ²®         IS 'ÁïÅ²®'
/
COMMENT ON COLUMN APPS.XXSKY_^À²®_î{_V.¿ÚP         IS '¿ÚP'
/
COMMENT ON COLUMN APPS.XXSKY_^À²®_î{_V.¿ÚP¼       IS '¿ÚP¼'
/
COMMENT ON COLUMN APPS.XXSKY_^À²®_î{_V.¿àzP         IS '¿àzP'
/
COMMENT ON COLUMN APPS.XXSKY_^À²®_î{_V.¿ñÛÅP       IS '¿ñÛÅP'
/
COMMENT ON COLUMN APPS.XXSKY_^À²®_î{_V.¿ÚQ         IS '¿ÚQ'
/
COMMENT ON COLUMN APPS.XXSKY_^À²®_î{_V.¿ÚQ¼       IS '¿ÚQ¼'
/
COMMENT ON COLUMN APPS.XXSKY_^À²®_î{_V.¿àzQ         IS '¿àzQ'
/
COMMENT ON COLUMN APPS.XXSKY_^À²®_î{_V.¿ñÛÅQ       IS '¿ñÛÅQ'
/
COMMENT ON COLUMN APPS.XXSKY_^À²®_î{_V.¿ÚR         IS '¿ÚR'
/
COMMENT ON COLUMN APPS.XXSKY_^À²®_î{_V.¿ÚR¼       IS '¿ÚR¼'
/
COMMENT ON COLUMN APPS.XXSKY_^À²®_î{_V.¿àzR         IS '¿àzR'
/
COMMENT ON COLUMN APPS.XXSKY_^À²®_î{_V.¿ñÛÅR       IS '¿ñÛÅR'
/
COMMENT ON COLUMN APPS.XXSKY_^À²®_î{_V.¿ÚS         IS '¿ÚS'
/
COMMENT ON COLUMN APPS.XXSKY_^À²®_î{_V.¿ÚS¼       IS '¿ÚS¼'
/
COMMENT ON COLUMN APPS.XXSKY_^À²®_î{_V.¿àzS         IS '¿àzS'
/
COMMENT ON COLUMN APPS.XXSKY_^À²®_î{_V.¿ñÛÅS       IS '¿ñÛÅS'
/
COMMENT ON COLUMN APPS.XXSKY_^À²®_î{_V.¿ÚT         IS '¿ÚT'
/
COMMENT ON COLUMN APPS.XXSKY_^À²®_î{_V.¿ÚT¼       IS '¿ÚT¼'
/
COMMENT ON COLUMN APPS.XXSKY_^À²®_î{_V.¿àzT         IS '¿àzT'
/
COMMENT ON COLUMN APPS.XXSKY_^À²®_î{_V.¿ñÛÅT       IS '¿ñÛÅT'
/
COMMENT ON COLUMN APPS.XXSKY_^À²®_î{_V.ñÛÅ¿àzv IS 'ñÛÅ¿àzv'
/
COMMENT ON COLUMN APPS.XXSKY_^À²®_î{_V.ì¬Ò             IS 'ì¬Ò'
/
COMMENT ON COLUMN APPS.XXSKY_^À²®_î{_V.ì¬ú             IS 'ì¬ú'
/
COMMENT ON COLUMN APPS.XXSKY_^À²®_î{_V.ÅIXVÒ         IS 'ÅIXVÒ'
/
COMMENT ON COLUMN APPS.XXSKY_^À²®_î{_V.ÅIXVú         IS 'ÅIXVú'
/
COMMENT ON COLUMN APPS.XXSKY_^À²®_î{_V.ÅIXVOC   IS 'ÅIXVOC'
/