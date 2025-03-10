CREATE OR REPLACE VIEW APPS.XXSKY_^Àp^ÆÒ_»Ý_V
(
 ¤iæª
,¤iæª¼
,^ÆÒR[h
,^ÆÒ¼
,KpJnú
,KpI¹ú
,IC»Îæª
,IC»Îæª¼
,¿÷ßú
,ÁïÅæª
,ÁïÅæª¼
,lÌÜüæª
,lÌÜüæª¼
,x¥»fæª
,x¥»fæª¼
,¿æR[h
,¿æ¼
,¿î
,¿î¼
,¬ûdÊ
,x¥sbLOP¿
,¿sbLOP¿
,ì¬Ò
,ì¬ú
,ÅIXVÒ
,ÅIXVú
,ÅIXVOC
)
AS
SELECT 
        XDC.goods_classe               --¤iæª
-- 2010/01/28 T.Yoshimoto Mod Start {Ò®#1168
       --,FLV01.meaning                  --¤iæª¼
       ,(SELECT FLV01.meaning
         FROM fnd_lookup_values FLV01  --NCbNR[h(¤iæª¼)
         WHERE FLV01.language    = 'JA'
           AND FLV01.lookup_type = 'XXWIP_ITEM_TYPE'
           AND FLV01.lookup_code = XDC.goods_classe
        ) FLV01_meaning
-- 2010/01/28 T.Yoshimoto Mod End {Ò®#1168
       ,XDC.delivery_company_code      --^ÆÒR[h
-- 2010/01/28 T.Yoshimoto Mod Start {Ò®#1168
       --,XCRV.party_name                --^ÆÒ¼
       ,(SELECT XCRV.party_name
         FROM xxsky_carriers_v XCRV   --^ÆÒæ¾pVIEW
         WHERE XDC.delivery_company_code = XCRV.freight_code
        ) XCRV_party_name
-- 2010/01/28 T.Yoshimoto Mod End {Ò®#1168
       ,XDC.start_date_active          --KpJnú
       ,XDC.end_date_active            --KpI¹ú
       ,XDC.online_classe              --IC»Îæª
-- 2010/01/28 T.Yoshimoto Mod Start {Ò®#1168
       --,FLV02.meaning                  --IC»Îæª¼
       ,(SELECT FLV02.meaning
         FROM fnd_lookup_values FLV02  --NCbNR[h(IC»Îæª¼)
         WHERE FLV02.language    = 'JA'
           AND FLV02.lookup_type = 'XXWIP_ONLINE_TYPE'
           AND FLV02.lookup_code = XDC.online_classe
        ) FLV02_meaning
-- 2010/01/28 T.Yoshimoto Mod End {Ò®#1168
       ,XDC.due_billing_date           --¿÷ßú
       ,XDC.consumption_tax_classe     --ÁïÅæª
-- 2010/01/28 T.Yoshimoto Mod Start {Ò®#1168
       --,FLV03.meaning                  --ÁïÅæª¼
       ,(SELECT FLV03.meaning
         FROM fnd_lookup_values FLV03  --NCbNR[h(ÁïÅæª¼)
         WHERE FLV03.language    = 'JA'
           AND FLV03.lookup_type = 'XXWIP_FARETAX_TYPE'
           AND FLV03.lookup_code = XDC.consumption_tax_classe
        ) FLV03_meaning
-- 2010/01/28 T.Yoshimoto Mod End {Ò®#1168
       ,XDC.half_adjust_classe         --lÌÜüæª
-- 2010/01/28 T.Yoshimoto Mod Start {Ò®#1168
       --,FLV04.meaning                  --lÌÜüæª¼
       ,(SELECT FLV04.meaning
         FROM fnd_lookup_values FLV04  --NCbNR[h(lÌÜüæª¼)
         WHERE FLV04.language    = 'JA'
           AND FLV04.lookup_type = 'XXCMN_ROUND'
           AND FLV04.lookup_code = XDC.half_adjust_classe
        ) FLV04_meaning
-- 2010/01/28 T.Yoshimoto Mod End {Ò®#1168
       ,XDC.payments_judgment_classe   --x¥»fæª
-- 2010/01/28 T.Yoshimoto Mod Start {Ò®#1168
       --,FLV05.meaning                  --x¥»fæª¼
       ,(SELECT FLV05.meaning
         FROM fnd_lookup_values FLV05  --NCbNR[h(x¥»fæª¼)
         WHERE FLV05.language     = 'JA'
           AND FLV05.lookup_type = 'XXCMN_PAY_JUDGEMENT'
           AND FLV05.lookup_code = XDC.payments_judgment_classe
        ) FLV05_meaning
-- 2010/01/28 T.Yoshimoto Mod End {Ò®#1168
       ,XDC.billing_code               --¿æR[h
-- 2010/01/28 T.Yoshimoto Mod Start {Ò®#1168
       --,XLCV.location_name             --¿æ¼
       ,(SELECT XLCV.location_name
         FROM xxsky_locations_v XLCV   --¿æ¼æ¾pVIEW
         WHERE XDC.billing_code = XLCV.location_code
        ) XLCV_location_name
-- 2010/01/28 T.Yoshimoto Mod End {Ò®#1168
       ,XDC.billing_standard           --¿î
-- 2010/01/28 T.Yoshimoto Mod Start {Ò®#1168
       --,FLV06.meaning                  --¿î¼
       ,(SELECT FLV06.meaning
         FROM fnd_lookup_values FLV06  --NCbNR[h(¿î¼)
         WHERE FLV06.language    = 'JA'
           AND FLV06.lookup_type = 'XXWIP_CLAIM_PAY_STD'
           AND FLV06.lookup_code = XDC.billing_standard
        ) FLV06_meaning
-- 2010/01/28 T.Yoshimoto Mod End {Ò®#1168
       ,XDC.small_weight               --¬ûdÊ
       ,XDC.pay_picking_amount         --x¥sbLOP¿
       ,XDC.bill_picking_amount        --¿sbLOP¿
-- 2010/01/28 T.Yoshimoto Mod Start {Ò®#1168
       --,FU_CB.user_name                --ì¬Ò
       ,(SELECT FU_CB.user_name
         FROM fnd_user FU_CB  --[U[}X^(created_by¼Ìæ¾p)
         WHERE XDC.created_by = FU_CB.user_id
        ) FU_CB_user_name
-- 2010/01/28 T.Yoshimoto Mod End {Ò®#1168
       ,TO_CHAR( XDC.creation_date, 'YYYY/MM/DD HH24:MI:SS')
                                       --ì¬ú
-- 2010/01/28 T.Yoshimoto Mod Start {Ò®#1168
       --,FU_LU.user_name                --ÅIXVÒ
       ,(SELECT FU_LU.user_name
         FROM fnd_user FU_LU  --[U[}X^(last_updated_by¼Ìæ¾p)
         WHERE XDC.last_updated_by = FU_LU.user_id
        ) FU_LU_user_name
-- 2010/01/28 T.Yoshimoto Mod End {Ò®#1168
       ,TO_CHAR( XDC.last_update_date, 'YYYY/MM/DD HH24:MI:SS')
                                       --ÅIXVú
-- 2010/01/28 T.Yoshimoto Mod Start {Ò®#1168
       --,FU_LL.user_name                --ÅIXVOC
       ,(SELECT FU_LL.user_name
         FROM fnd_user    FU_LL  --[U[}X^(last_update_login¼Ìæ¾p)
             ,fnd_logins FL_LL  --OC}X^(last_update_login¼Ìæ¾p)
         WHERE XDC.last_update_login = FL_LL.login_id
         AND   FL_LL.user_id         = FU_LL.user_id
        ) FU_LL_user_name
-- 2010/01/28 T.Yoshimoto Mod End {Ò®#1168
  FROM  xxwip_delivery_company  XDC    --^Àp^ÆÒAhI}X^
-- 2010/01/28 T.Yoshimoto Del Start {Ò®#1168
       --,xxsky_carriers_v        XCRV   --^ÆÒæ¾pVIEW
       --,xxsky_locations_v       XLCV   --¿æ¼æ¾pVIEW
       --,fnd_user                FU_CB  --[U[}X^(created_by¼Ìæ¾p)
       --,fnd_user                FU_LU  --[U[}X^(last_updated_by¼Ìæ¾p)
       --,fnd_user                FU_LL  --[U[}X^(last_update_login¼Ìæ¾p)
       --,fnd_logins              FL_LL  --OC}X^(last_update_login¼Ìæ¾p)
       --,fnd_lookup_values       FLV01  --NCbNR[h(¤iæª¼)
       --,fnd_lookup_values       FLV02  --NCbNR[h(IC»Îæª¼)
       --,fnd_lookup_values       FLV03  --NCbNR[h(ÁïÅæª¼)
       --,fnd_lookup_values       FLV04  --NCbNR[h(lÌÜüæª¼)
       --,fnd_lookup_values       FLV05  --NCbNR[h(x¥»fæª¼)
       --,fnd_lookup_values       FLV06  --NCbNR[h(¿î¼)
-- 2010/01/28 T.Yoshimoto Del End {Ò®#1168
 WHERE  XDC.start_date_active <= TRUNC(SYSDATE)
   AND  XDC.end_date_active   >= TRUNC(SYSDATE)
-- 2010/01/28 T.Yoshimoto Del Start {Ò®#1168
   --AND  XDC.delivery_company_code = XCRV.freight_code(+)
   --AND  XDC.billing_code          = XLCV.location_code(+)
   --AND  XDC.created_by        = FU_CB.user_id(+)
   --AND  XDC.last_updated_by   = FU_LU.user_id(+)
   --AND  XDC.last_update_login = FL_LL.login_id(+)
   --AND  FL_LL.user_id         = FU_LL.user_id(+)
   --AND  FLV01.language(+)     = 'JA'
   --AND  FLV01.lookup_type(+)  = 'XXWIP_ITEM_TYPE'
   --AND  FLV01.lookup_code(+)  = XDC.goods_classe
   --AND  FLV02.language(+)     = 'JA'
   --AND  FLV02.lookup_type(+)  = 'XXWIP_ONLINE_TYPE'
   --AND  FLV02.lookup_code(+)  = XDC.online_classe
   --AND  FLV03.language(+)     = 'JA'
   --AND  FLV03.lookup_type(+)  = 'XXWIP_FARETAX_TYPE'
   --AND  FLV03.lookup_code(+)  = XDC.consumption_tax_classe
   --AND  FLV04.language(+)     = 'JA'
   --AND  FLV04.lookup_type(+)  = 'XXCMN_ROUND'
   --AND  FLV04.lookup_code(+)  = XDC.half_adjust_classe
   --AND  FLV05.language(+)     = 'JA'
   --AND  FLV05.lookup_type(+)  = 'XXCMN_PAY_JUDGEMENT'
   --AND  FLV05.lookup_code(+)  = XDC.payments_judgment_classe
   --AND  FLV06.language(+)     = 'JA'
   --AND  FLV06.lookup_type(+)  = 'XXWIP_CLAIM_PAY_STD'
   --AND  FLV06.lookup_code(+)  = XDC.billing_standard
-- 2010/01/28 T.Yoshimoto Del End {Ò®#1168
/
COMMENT ON TABLE APPS.XXSKY_^Àp^ÆÒ_»Ý_V IS 'SKYLINKp^Àp^ÆÒi»ÝjVIEW'
/
COMMENT ON COLUMN APPS.XXSKY_^Àp^ÆÒ_»Ý_V.¤iæª                       IS '¤iæª'
/
COMMENT ON COLUMN APPS.XXSKY_^Àp^ÆÒ_»Ý_V.¤iæª¼                     IS '¤iæª¼'
/
COMMENT ON COLUMN APPS.XXSKY_^Àp^ÆÒ_»Ý_V.^ÆÒR[h                 IS '^ÆÒR[h'
/
COMMENT ON COLUMN APPS.XXSKY_^Àp^ÆÒ_»Ý_V.^ÆÒ¼                     IS '^ÆÒ¼'
/
COMMENT ON COLUMN APPS.XXSKY_^Àp^ÆÒ_»Ý_V.KpJnú                     IS 'KpJnú'
/
COMMENT ON COLUMN APPS.XXSKY_^Àp^ÆÒ_»Ý_V.KpI¹ú                     IS 'KpI¹ú'
/
COMMENT ON COLUMN APPS.XXSKY_^Àp^ÆÒ_»Ý_V.IC»Îæª           IS 'IC»Îæª'
/
COMMENT ON COLUMN APPS.XXSKY_^Àp^ÆÒ_»Ý_V.IC»Îæª¼         IS 'IC»Îæª¼'
/
COMMENT ON COLUMN APPS.XXSKY_^Àp^ÆÒ_»Ý_V.¿÷ßú                     IS '¿÷ßú'
/
COMMENT ON COLUMN APPS.XXSKY_^Àp^ÆÒ_»Ý_V.ÁïÅæª                     IS 'ÁïÅæª'
/
COMMENT ON COLUMN APPS.XXSKY_^Àp^ÆÒ_»Ý_V.ÁïÅæª¼                   IS 'ÁïÅæª¼'
/
COMMENT ON COLUMN APPS.XXSKY_^Àp^ÆÒ_»Ý_V.lÌÜüæª                   IS 'lÌÜüæª'
/
COMMENT ON COLUMN APPS.XXSKY_^Àp^ÆÒ_»Ý_V.lÌÜüæª¼                 IS 'lÌÜüæª¼'
/
COMMENT ON COLUMN APPS.XXSKY_^Àp^ÆÒ_»Ý_V.x¥»fæª                   IS 'x¥»fæª'
/
COMMENT ON COLUMN APPS.XXSKY_^Àp^ÆÒ_»Ý_V.x¥»fæª¼                 IS 'x¥»fæª¼'
/
COMMENT ON COLUMN APPS.XXSKY_^Àp^ÆÒ_»Ý_V.¿æR[h                   IS '¿æR[h'
/
COMMENT ON COLUMN APPS.XXSKY_^Àp^ÆÒ_»Ý_V.¿æ¼                       IS '¿æ¼'
/
COMMENT ON COLUMN APPS.XXSKY_^Àp^ÆÒ_»Ý_V.¿î                       IS '¿î'
/
COMMENT ON COLUMN APPS.XXSKY_^Àp^ÆÒ_»Ý_V.¿î¼                     IS '¿î¼'
/
COMMENT ON COLUMN APPS.XXSKY_^Àp^ÆÒ_»Ý_V.¬ûdÊ                       IS '¬ûdÊ'
/
COMMENT ON COLUMN APPS.XXSKY_^Àp^ÆÒ_»Ý_V.x¥sbLOP¿             IS 'x¥sbLOP¿'
/
COMMENT ON COLUMN APPS.XXSKY_^Àp^ÆÒ_»Ý_V.¿sbLOP¿             IS '¿sbLOP¿'
/
COMMENT ON COLUMN APPS.XXSKY_^Àp^ÆÒ_»Ý_V.ì¬Ò                         IS 'ì¬Ò'
/
COMMENT ON COLUMN APPS.XXSKY_^Àp^ÆÒ_»Ý_V.ì¬ú                         IS 'ì¬ú'
/
COMMENT ON COLUMN APPS.XXSKY_^Àp^ÆÒ_»Ý_V.ÅIXVÒ                     IS 'ÅIXVÒ'
/
COMMENT ON COLUMN APPS.XXSKY_^Àp^ÆÒ_»Ý_V.ÅIXVú                     IS 'ÅIXVú'
/
COMMENT ON COLUMN APPS.XXSKY_^Àp^ÆÒ_»Ý_V.ÅIXVOC               IS 'ÅIXVOC'
/

