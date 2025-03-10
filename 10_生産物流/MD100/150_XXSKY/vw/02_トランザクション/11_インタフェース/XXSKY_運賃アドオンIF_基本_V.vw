CREATE OR REPLACE VIEW APPS.XXSKY_^ÀAhIIF_î{_V
(
 p^[æª
,p^[æª¼
,^ÆÒ
,^ÆÒ¼
,zNO
,èóNO
,x¥¿æª
,x¥¿æª¼
,zæª
,zæª¼
,¿^À
,ÂP
,ÂQ
,dÊP
,dÊQ
,£
,¿à
,Ês¿
,sbLO¿
,¬Úàz
,v
,ì¬Ò
,ì¬ú
,ÅIXVÒ
,ÅIXVú
,ÅIXVOC
)
AS
SELECT 
        XDI.pattern_flag                                  --p^[æª
       ,CASE XDI.pattern_flag                             --p^[æª¼
            WHEN '1' THEN 'Op'
            WHEN '2' THEN 'É¡YÆp'
        END                      pattern_name
       ,XDI.delivery_company_code                         --^ÆÒ
       ,XCV.party_name                                    --^ÆÒ¼
       ,XDI.delivery_no                                   --zNo
       ,XDI.invoice_no                                    --èóNo
       ,XDI.p_b_classe                                    --x¥¿æª
       ,FLV01.meaning                                     --x¥¿æª¼
       ,XDI.delivery_classe                               --zæª
       ,FLV02.meaning                                     --zæª¼
       ,XDI.charged_amount                                --¿^À
       ,XDI.qty1                                          --ÂP
       ,XDI.qty2                                          --ÂQ
       ,XDI.delivery_weight1                              --dÊP
       ,XDI.delivery_weight2                              --dÊQ
       ,XDI.distance                                      --£
       ,XDI.many_rate                                     --¿à
       ,XDI.congestion_charge                             --Ês¿
       ,XDI.picking_charge                                --sbLO¿
       ,XDI.consolid_surcharge                            --¬Úàz
       ,XDI.total_amount                                  --v
       ,FU_CB.user_name         created_by_name           --CREATED_BYÌ[U[¼(OCÌüÍR[h)
       ,TO_CHAR( XDI.creation_date, 'YYYY/MM/DD HH24:MI:SS')
                                creation_date             --ì¬ú
       ,FU_LU.user_name         last_updated_by_name      --LAST_UPDATED_BYÌ[U[¼(OCÌüÍR[h)
       ,TO_CHAR( XDI.last_update_date, 'YYYY/MM/DD HH24:MI:SS')
                                last_update_date          --XVú
       ,FU_LL.user_name         last_update_login_name    --LAST_UPDATE_LOGINÌ[U[¼(OCÌüÍR[h)
  FROM  xxwip_deliverys_if      XDI                       --^ÀAhIC^tF[X
       ,xxsky_carriers_v        XCV                       --SKYLINKpÔVIEW ^ÆÒæ¾VIEW
       ,fnd_lookup_values       FLV01                     --x¥¿æª¼æ¾p
       ,fnd_lookup_values       FLV02                     --zæª¼æ¾p
       ,fnd_user                FU_CB                     --[U[}X^(CREATED_BY¼Ìæ¾p)
       ,fnd_user                FU_LU                     --[U[}X^(LAST_UPDATE_BY¼Ìæ¾p)
       ,fnd_user                FU_LL                     --[U[}X^(LAST_UPDATE_LOGIN¼Ìæ¾p)
       ,fnd_logins              FL_LL                     --OC}X^(LAST_UPDATE_LOGIN¼Ìæ¾p)
 WHERE  XDI.delivery_company_code = XCV.freight_code(+)
    --x¥¿æª¼æ¾ð
   AND  FLV01.language(+)         = 'JA'
   AND  FLV01.lookup_type(+)      = 'XXWIP_PAYCHARGE_TYPE'
   AND  FLV01.lookup_code(+)      = XDI.p_b_classe
   --zæª¼æ¾ð
   AND  FLV02.language(+)         = 'JA'
   AND  FLV02.lookup_type(+)      = 'XXCMN_SHIP_METHOD'
   AND  FLV02.lookup_code(+)      = XDI.delivery_classe
   --WHOJæ¾
   AND  XDI.created_by            = FU_CB.user_id(+)
   AND  XDI.last_updated_by       = FU_LU.user_id(+)
   AND  XDI.last_update_login     = FL_LL.login_id(+)
   AND  FL_LL.user_id             = FU_LL.user_id(+)
/
COMMENT ON TABLE APPS.XXSKY_^ÀAhIIF_î{_V                     IS 'SKYLINKp^ÀAhIIFiî{jVIEW'
/
COMMENT ON COLUMN APPS.XXSKY_^ÀAhIIF_î{_V.p^[æª       IS 'p^[æª'
/
COMMENT ON COLUMN APPS.XXSKY_^ÀAhIIF_î{_V.p^[æª¼     IS 'p^[æª¼'
/
COMMENT ON COLUMN APPS.XXSKY_^ÀAhIIF_î{_V.^ÆÒ           IS '^ÆÒ'
/
COMMENT ON COLUMN APPS.XXSKY_^ÀAhIIF_î{_V.^ÆÒ¼         IS '^ÆÒ¼'
/
COMMENT ON COLUMN APPS.XXSKY_^ÀAhIIF_î{_V.zNO             IS 'zNo'
/
COMMENT ON COLUMN APPS.XXSKY_^ÀAhIIF_î{_V.èóNO           IS 'èóNo'
/
COMMENT ON COLUMN APPS.XXSKY_^ÀAhIIF_î{_V.x¥¿æª       IS 'x¥¿æª'
/
COMMENT ON COLUMN APPS.XXSKY_^ÀAhIIF_î{_V.x¥¿æª¼     IS 'x¥¿æª¼'
/
COMMENT ON COLUMN APPS.XXSKY_^ÀAhIIF_î{_V.zæª           IS 'zæª'
/
COMMENT ON COLUMN APPS.XXSKY_^ÀAhIIF_î{_V.zæª¼         IS 'zæª¼'
/
COMMENT ON COLUMN APPS.XXSKY_^ÀAhIIF_î{_V.¿^À           IS '¿^À'
/
COMMENT ON COLUMN APPS.XXSKY_^ÀAhIIF_î{_V.ÂP             IS 'ÂP'
/
COMMENT ON COLUMN APPS.XXSKY_^ÀAhIIF_î{_V.ÂQ             IS 'ÂQ'
/
COMMENT ON COLUMN APPS.XXSKY_^ÀAhIIF_î{_V.dÊP             IS 'dÊP'
/
COMMENT ON COLUMN APPS.XXSKY_^ÀAhIIF_î{_V.dÊQ             IS 'dÊQ'
/
COMMENT ON COLUMN APPS.XXSKY_^ÀAhIIF_î{_V.£               IS '£'
/
COMMENT ON COLUMN APPS.XXSKY_^ÀAhIIF_î{_V.¿à             IS '¿à'
/
COMMENT ON COLUMN APPS.XXSKY_^ÀAhIIF_î{_V.Ês¿             IS 'Ês¿'
/
COMMENT ON COLUMN APPS.XXSKY_^ÀAhIIF_î{_V.sbLO¿       IS 'sbLO¿'
/
COMMENT ON COLUMN APPS.XXSKY_^ÀAhIIF_î{_V.¬Úàz       IS '¬Úàz'
/
COMMENT ON COLUMN APPS.XXSKY_^ÀAhIIF_î{_V.v               IS 'v'
/
COMMENT ON COLUMN APPS.XXSKY_^ÀAhIIF_î{_V.ì¬Ò             IS 'ì¬Ò'
/
COMMENT ON COLUMN APPS.XXSKY_^ÀAhIIF_î{_V.ì¬ú             IS 'ì¬ú'
/
COMMENT ON COLUMN APPS.XXSKY_^ÀAhIIF_î{_V.ÅIXVÒ         IS 'ÅIXVÒ'
/
COMMENT ON COLUMN APPS.XXSKY_^ÀAhIIF_î{_V.ÅIXVú         IS 'ÅIXVú'
/
COMMENT ON COLUMN APPS.XXSKY_^ÀAhIIF_î{_V.ÅIXVOC   IS 'ÅIXVOC'
/