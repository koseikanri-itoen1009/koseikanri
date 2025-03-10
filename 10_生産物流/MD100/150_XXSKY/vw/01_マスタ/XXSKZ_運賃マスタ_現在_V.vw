/*************************************************************************
 * 
 * View  Name      : XXSKZ_^À}X^_»Ý_V
 * Description     : XXSKZ_^À}X^_»Ý_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------  -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------  -------------------------------------
 *  2012/11/22    1.0   SCSK M.Nagai ñì¬
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_^À}X^_»Ý_V
(
 x¥¿æª
,x¥¿æª¼
,¤iæª
,¤iæª¼
,^ÆÒ
,^ÆÒ¼
,zæª
,zæª¼
,^À£
,dÊ
,KpJnú
,KpI¹ú
,^ï
,[t¬Ú
,ì¬Ò
,ì¬ú
,ÅIXVÒ
,ÅIXVú
,ÅIXVOC
)
AS
SELECT  
        XDC.p_b_classe                 --x¥¿æª
-- 2010/01/28 T.Yoshimoto Mod Start {Ò®#1168
       --,FLV01.meaning                  --x¥¿æª¼
       ,(SELECT FLV01.meaning
         FROM fnd_lookup_values FLV01  --NCbNR[h(x¥¿æª¼)
         WHERE FLV01.language    = 'JA'
           AND FLV01.lookup_type = 'XXWIP_PAYCHARGE_TYPE'
           AND FLV01.lookup_code = XDC.p_b_classe
        ) FLV01_meaning
-- 2010/01/28 T.Yoshimoto Mod End {Ò®#1168
       ,XDC.goods_classe               --¤iæª
-- 2010/01/28 T.Yoshimoto Mod Start {Ò®#1168
       --,FLV02.meaning                  --¤iæª¼
       ,(SELECT FLV02.meaning
         FROM fnd_lookup_values FLV02  --NCbNR[h(¤iæª¼)
         WHERE FLV02.language    = 'JA'
           AND FLV02.lookup_type = 'XXWIP_ITEM_TYPE'
           AND FLV02.lookup_code = XDC.goods_classe
        ) FLV02_meaning
-- 2010/01/28 T.Yoshimoto Mod End {Ò®#1168
       ,XDC.delivery_company_code      --^ÆÒR[h
-- 2010/01/28 T.Yoshimoto Mod Start {Ò®#1168
       --,XCRV.party_name                --^ÆÒ¼
       ,(SELECT XCRV.party_name
         FROM xxskz_carriers_v XCRV   --^ÆÒîñVIEW
         WHERE XDC.delivery_company_code = XCRV.freight_code
        ) XCRV_party_name
-- 2010/01/28 T.Yoshimoto Mod End {Ò®#1168
       ,XDC.shipping_address_classe    --zæª
-- 2010/01/28 T.Yoshimoto Mod Start {Ò®#1168
       --,FLV03.meaning                  --zæª¼
       ,(SELECT FLV03.meaning
         FROM fnd_lookup_values FLV03  --NCbNR[h(zæª¼)
         WHERE FLV03.language    = 'JA'
           AND FLV03.lookup_type = 'XXCMN_SHIP_METHOD'
           AND FLV03.lookup_code = XDC.shipping_address_classe
        ) FLV03_meaning
-- 2010/01/28 T.Yoshimoto Mod End {Ò®#1168
       ,XDC.delivery_distance          --^À£
       ,XDC.delivery_weight            --dÊ
       ,XDC.start_date_active          --KpJnú
       ,XDC.end_date_active            --KpI¹ú
       ,XDC.shipping_expenses          --^ï
       ,XDC.leaf_consolid_add          --[t¬Ú
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
  FROM  xxwip_delivery_charges  XDC    --^ÀAhI}X^C^tF[X
-- 2010/01/28 T.Yoshimoto Del Start {Ò®#1168
       --,xxskz_carriers_v        XCRV   --^ÆÒîñVIEW
       --,fnd_user                FU_CB  --[U[}X^(created_by¼Ìæ¾p)
       --,fnd_user                FU_LU  --[U[}X^(last_updated_by¼Ìæ¾p)
       --,fnd_user                FU_LL  --[U[}X^(last_update_login¼Ìæ¾p)
       --,fnd_logins              FL_LL  --OC}X^(last_update_login¼Ìæ¾p)
       --,fnd_lookup_values       FLV01  --NCbNR[h(x¥¿æª¼)
       --,fnd_lookup_values       FLV02  --NCbNR[h(¤iæª¼)
       --,fnd_lookup_values       FLV03  --NCbNR[h(zæª¼)
-- 2010/01/28 T.Yoshimoto Del End {Ò®#1168
 WHERE  XDC.start_date_active <= TRUNC(SYSDATE)
   AND  XDC.end_date_active   >= TRUNC(SYSDATE)
-- 2010/01/28 T.Yoshimoto Del Start {Ò®#1168
   --AND  XDC.delivery_company_code = XCRV.freight_code(+)
   --AND  XDC.created_by        = FU_CB.user_id(+)
   --AND  XDC.last_updated_by   = FU_LU.user_id(+)
   --AND  XDC.last_update_login = FL_LL.login_id(+)
   --AND  FL_LL.user_id         = FU_LL.user_id(+)
   --AND  FLV01.language(+)    = 'JA'
   --AND  FLV01.lookup_type(+) = 'XXWIP_PAYCHARGE_TYPE'
   --AND  FLV01.lookup_code(+) = XDC.p_b_classe
   --AND  FLV02.language(+)    = 'JA'
   --AND  FLV02.lookup_type(+) = 'XXWIP_ITEM_TYPE'
   --AND  FLV02.lookup_code(+) = XDC.goods_classe
   --AND  FLV03.language(+)    = 'JA'
   --AND  FLV03.lookup_type(+) = 'XXCMN_SHIP_METHOD'
   --AND  FLV03.lookup_code(+) = XDC.shipping_address_classe
-- 2010/01/28 T.Yoshimoto Del End {Ò®#1168
/
COMMENT ON TABLE APPS.XXSKZ_^À}X^_»Ý_V IS 'SKYLINKp^À}X^i»ÝjVIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_^À}X^_»Ý_V.x¥¿æª                IS 'x¥¿æª'
/
COMMENT ON COLUMN APPS.XXSKZ_^À}X^_»Ý_V.x¥¿æª¼              IS 'x¥¿æª¼'
/
COMMENT ON COLUMN APPS.XXSKZ_^À}X^_»Ý_V.¤iæª                    IS '¤iæª'
/
COMMENT ON COLUMN APPS.XXSKZ_^À}X^_»Ý_V.¤iæª¼                  IS '¤iæª¼'
/
COMMENT ON COLUMN APPS.XXSKZ_^À}X^_»Ý_V.^ÆÒ                    IS '^ÆÒ'
/
COMMENT ON COLUMN APPS.XXSKZ_^À}X^_»Ý_V.^ÆÒ¼                  IS '^ÆÒ¼'
/
COMMENT ON COLUMN APPS.XXSKZ_^À}X^_»Ý_V.zæª                    IS 'zæª'
/
COMMENT ON COLUMN APPS.XXSKZ_^À}X^_»Ý_V.zæª¼                  IS 'zæª¼'
/
COMMENT ON COLUMN APPS.XXSKZ_^À}X^_»Ý_V.^À£                    IS '^À£'
/
COMMENT ON COLUMN APPS.XXSKZ_^À}X^_»Ý_V.dÊ                        IS 'dÊ'
/
COMMENT ON COLUMN APPS.XXSKZ_^À}X^_»Ý_V.KpJnú                  IS 'KpJnú'
/
COMMENT ON COLUMN APPS.XXSKZ_^À}X^_»Ý_V.KpI¹ú                  IS 'KpI¹ú'
/
COMMENT ON COLUMN APPS.XXSKZ_^À}X^_»Ý_V.^ï                      IS '^ï'
/
COMMENT ON COLUMN APPS.XXSKZ_^À}X^_»Ý_V.[t¬Ú              IS '[t¬Ú'
/
COMMENT ON COLUMN APPS.XXSKZ_^À}X^_»Ý_V.ì¬Ò                      IS 'ì¬Ò'
/
COMMENT ON COLUMN APPS.XXSKZ_^À}X^_»Ý_V.ì¬ú                      IS 'ì¬ú'
/
COMMENT ON COLUMN APPS.XXSKZ_^À}X^_»Ý_V.ÅIXVÒ                  IS 'ÅIXVÒ'
/
COMMENT ON COLUMN APPS.XXSKZ_^À}X^_»Ý_V.ÅIXVú                  IS 'ÅIXVú'
/
COMMENT ON COLUMN APPS.XXSKZ_^À}X^_»Ý_V.ÅIXVOC            IS 'ÅIXVOC'
/
