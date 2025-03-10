/*************************************************************************
 * 
 * View  Name      : XXSKZ_¿æ}X^_î{_V
 * Description     : XXSKZ_¿æ}X^_î{_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------  -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------  -------------------------------------
 *  2012/11/22    1.0   SCSK M.Nagai ñì¬
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_¿æ}X^_î{_V
(
 ¿æR[h
,¿N
,¿æ¼
,XÖÔ
,Z
,dbÔ
,FAXÔ
,Uú
,x¥ðÝèú
,O¿z
,¡ñüàz
,²®z
,Jzz
,¡ñ¿àz
,¿àzv
,¡ãz
,ÁïÅ
,Ês¿
,ì¬Ò
,ì¬ú
,ÅIXVÒ
,ÅIXVú
,ÅIXVOC
)
AS
SELECT
        XBM.billing_code                --¿æR[h
       ,XBM.billing_date                --¿N
       ,XBM.billing_name                --¿æ¼
       ,XBM.post_no                     --XÖÔ
       ,XBM.address                     --Z
       ,XBM.telephone_no                --dbÔ
       ,XBM.fax_no                      --FAXÔ
       ,XBM.money_transfer_date         --Uú
       ,XBM.condition_setting_date      --x¥ðÝèú
       ,XBM.last_month_charge_amount    --O¿z
       ,XBM.amount_receipt_money        --¡ñüàz
       ,XBM.amount_adjustment           --²®z
       ,XBM.balance_carried_forward     --Jzz
       ,XBM.charged_amount              --¡ñ¿àz
       ,XBM.charged_amount_total        --¿àzv
       ,XBM.month_sales                 --¡ãz
       ,XBM.consumption_tax             --ÁïÅ
       ,XBM.congestion_charge           --Ês¿
-- 2010/01/28 T.Yoshimoto Mod Start {Ò®#1168
       --,FU_CB.user_name                 --ì¬Ò
       ,(SELECT FU_CB.user_name
         FROM fnd_user FU_CB  --[U[}X^(created_by¼Ìæ¾p)
         WHERE XBM.created_by = FU_CB.user_id
        ) FU_CB_user_name
-- 2010/01/28 T.Yoshimoto Mod End {Ò®#1168
       ,TO_CHAR( XBM.creation_date, 'YYYY/MM/DD HH24:MI:SS')
                                        --ì¬ú
-- 2010/01/28 T.Yoshimoto Mod Start {Ò®#1168
       --,FU_LU.user_name                 --ÅIXVÒ
       ,(SELECT FU_LU.user_name
         FROM fnd_user FU_LU  --[U[}X^(last_updated_by¼Ìæ¾p)
         WHERE XBM.last_updated_by = FU_LU.user_id
        ) FU_LU_user_name
-- 2010/01/28 T.Yoshimoto Mod End {Ò®#1168
       ,TO_CHAR( XBM.last_update_date, 'YYYY/MM/DD HH24:MI:SS')
                                        --ÅIXVú
-- 2010/01/28 T.Yoshimoto Mod Start {Ò®#1168
       --,FU_LL.user_name                 --ÅIXVOC
       ,(SELECT FU_LL.user_name
         FROM fnd_user    FU_LL  --[U[}X^(last_update_login¼Ìæ¾p)
              ,fnd_logins FL_LL  --OC}X^(last_update_login¼Ìæ¾p)
         WHERE XBM.last_update_login = FL_LL.login_id
         AND   FL_LL.user_id         = FU_LL.user_id
        ) FU_LL_user_name
-- 2010/01/28 T.Yoshimoto Mod End {Ò®#1168
  FROM  xxwip_billing_mst   XBM         --¿æAhI}X^
-- 2010/01/28 T.Yoshimoto Del Start {Ò®#1168
       --,fnd_user            FU_CB       --[U[}X^(created_by¼Ìæ¾p)
       --,fnd_user            FU_LU       --[U[}X^(last_updated_by¼Ìæ¾p)
       --,fnd_user            FU_LL       --[U[}X^(last_update_login¼Ìæ¾p)
       --,fnd_logins          FL_LL       --OC}X^(last_update_login¼Ìæ¾p)
 --WHERE  XBM.created_by        = FU_CB.user_id(+)
   --AND  XBM.last_updated_by   = FU_LU.user_id(+)
   --AND  XBM.last_update_login = FL_LL.login_id(+)
   --AND  FL_LL.user_id         = FU_LL.user_id(+)
-- 2010/01/28 T.Yoshimoto Del End {Ò®#1168
/
COMMENT ON TABLE APPS.XXSKZ_¿æ}X^_î{_V IS 'SKYLINKp¿æ}X^iî{jVIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_¿æ}X^_î{_V.¿æR[h      IS '¿æR[h'
/
COMMENT ON COLUMN APPS.XXSKZ_¿æ}X^_î{_V.¿N          IS '¿N'
/
COMMENT ON COLUMN APPS.XXSKZ_¿æ}X^_î{_V.¿æ¼          IS '¿æ¼'
/
COMMENT ON COLUMN APPS.XXSKZ_¿æ}X^_î{_V.XÖÔ          IS 'XÖÔ'
/
COMMENT ON COLUMN APPS.XXSKZ_¿æ}X^_î{_V.Z              IS 'Z'
/
COMMENT ON COLUMN APPS.XXSKZ_¿æ}X^_î{_V.dbÔ          IS 'dbÔ'
/
COMMENT ON COLUMN APPS.XXSKZ_¿æ}X^_î{_V.FAXÔ           IS 'FAXÔ'
/
COMMENT ON COLUMN APPS.XXSKZ_¿æ}X^_î{_V.Uú            IS 'Uú'
/
COMMENT ON COLUMN APPS.XXSKZ_¿æ}X^_î{_V.x¥ðÝèú    IS 'x¥ðÝèú'
/
COMMENT ON COLUMN APPS.XXSKZ_¿æ}X^_î{_V.O¿z        IS 'O¿z'
/
COMMENT ON COLUMN APPS.XXSKZ_¿æ}X^_î{_V.¡ñüàz        IS '¡ñüàz'
/
COMMENT ON COLUMN APPS.XXSKZ_¿æ}X^_î{_V.²®z            IS '²®z'
/
COMMENT ON COLUMN APPS.XXSKZ_¿æ}X^_î{_V.Jzz            IS 'Jzz'
/
COMMENT ON COLUMN APPS.XXSKZ_¿æ}X^_î{_V.¡ñ¿àz      IS '¡ñ¿àz'
/
COMMENT ON COLUMN APPS.XXSKZ_¿æ}X^_î{_V.¿àzv      IS '¿àzv'
/
COMMENT ON COLUMN APPS.XXSKZ_¿æ}X^_î{_V.¡ãz        IS '¡ãz'
/
COMMENT ON COLUMN APPS.XXSKZ_¿æ}X^_î{_V.ÁïÅ            IS 'ÁïÅ'
/
COMMENT ON COLUMN APPS.XXSKZ_¿æ}X^_î{_V.Ês¿          IS 'Ês¿'
/
COMMENT ON COLUMN APPS.XXSKZ_¿æ}X^_î{_V.ì¬Ò            IS 'ì¬Ò'
/
COMMENT ON COLUMN APPS.XXSKZ_¿æ}X^_î{_V.ì¬ú            IS 'ì¬ú'
/
COMMENT ON COLUMN APPS.XXSKZ_¿æ}X^_î{_V.ÅIXVÒ        IS 'ÅIXVÒ'
/
COMMENT ON COLUMN APPS.XXSKZ_¿æ}X^_î{_V.ÅIXVú        IS 'ÅIXVú'
/
COMMENT ON COLUMN APPS.XXSKZ_¿æ}X^_î{_V.ÅIXVOC  IS 'ÅIXVOC'
/