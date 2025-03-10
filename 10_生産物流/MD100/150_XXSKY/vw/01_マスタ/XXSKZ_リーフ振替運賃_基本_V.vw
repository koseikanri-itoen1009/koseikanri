/*************************************************************************
 * 
 * View  Name      : XXSKZ_[tUÖ^À_î{_V
 * Description     : XXSKZ_[tUÖ^À_î{_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------  -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------  -------------------------------------
 *  2012/11/22    1.0   SCSK M.Nagai ñì¬
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_[tUÖ^À_î{_V
(
 KpJnú
,KpI¹ú
,ÖÝèàz
,ÂãÀP
,ÝèàzP
,ÂãÀQ
,ÝèàzQ
,ÂãÀR
,ÝèàzR
,ÂãÀS
,ÝèàzS
,ÂãÀT
,ÝèàzT
,ÂãÀU
,ÝèàzU
,ÂãÀV
,ÝèàzV
,ÂãÀW
,ÝèàzW
,ÂãÀX
,ÝèàzX
,ÂãÀPO
,ÝèàzPO
,ì¬Ò
,ì¬ú
,ÅIXVÒ
,ÅIXVú
,ÅIXVOC
)
AS
SELECT  
        XLTDC.start_date_active           --KpJnú
       ,XLTDC.end_date_active             --KpI¹ú
       ,XLTDC.setting_amount              --ÖÝèàz
       ,XLTDC.upper_limit_number1         --ÂãÀ1
       ,XLTDC.setting_amount1             --Ýèàz1
       ,XLTDC.upper_limit_number2         --ÂãÀ2
       ,XLTDC.setting_amount2             --Ýèàz2
       ,XLTDC.upper_limit_number3         --ÂãÀ3
       ,XLTDC.setting_amount3             --Ýèàz3
       ,XLTDC.upper_limit_number4         --ÂãÀ4
       ,XLTDC.setting_amount4             --Ýèàz4
       ,XLTDC.upper_limit_number5         --ÂãÀ5
       ,XLTDC.setting_amount5             --Ýèàz5
       ,XLTDC.upper_limit_number6         --ÂãÀ6
       ,XLTDC.setting_amount6             --Ýèàz6
       ,XLTDC.upper_limit_number7         --ÂãÀ7
       ,XLTDC.setting_amount7             --Ýèàz7
       ,XLTDC.upper_limit_number8         --ÂãÀ8
       ,XLTDC.setting_amount8             --Ýèàz8
       ,XLTDC.upper_limit_number9         --ÂãÀ9
       ,XLTDC.setting_amount9             --Ýèàz9
       ,XLTDC.upper_limit_number10        --ÂãÀ10
       ,XLTDC.setting_amount10            --Ýèàz10
-- 2010/01/28 T.Yoshimoto Mod Start {Ò®#1168
       --,FU_CB.user_name                   --ì¬Ò
       ,(SELECT FU_CB.user_name
         FROM fnd_user FU_CB  --[U[}X^(created_by¼Ìæ¾p)
         WHERE XLTDC.created_by = FU_CB.user_id
        ) FU_CB_user_name
-- 2010/01/28 T.Yoshimoto Mod End {Ò®#1168
       ,TO_CHAR( XLTDC.creation_date, 'YYYY/MM/DD HH24:MI:SS')
                                          --ì¬ú
-- 2010/01/28 T.Yoshimoto Mod Start {Ò®#1168
       --,FU_LU.user_name                   --ÅIXVÒ
       ,(SELECT FU_LU.user_name
         FROM fnd_user FU_LU  --[U[}X^(last_updated_by¼Ìæ¾p)
         WHERE XLTDC.last_updated_by = FU_LU.user_id
        ) FU_LU_user_name
-- 2010/01/28 T.Yoshimoto Mod End {Ò®#1168
       ,TO_CHAR( XLTDC.last_update_date, 'YYYY/MM/DD HH24:MI:SS')
                                          --ÅIXVú
-- 2010/01/28 T.Yoshimoto Mod Start {Ò®#1168
       --,FU_LL.user_name                   --ÅIXVOC
       ,(SELECT FU_LL.user_name
         FROM fnd_user    FU_LL  --[U[}X^(last_update_login¼Ìæ¾p)
              ,fnd_logins FL_LL  --OC}X^(last_update_login¼Ìæ¾p)
         WHERE XLTDC.last_update_login = FL_LL.login_id
         AND   FL_LL.user_id          = FU_LL.user_id
        ) FU_LL_user_name
-- 2010/01/28 T.Yoshimoto Mod End {Ò®#1168
  FROM  xxwip_leaf_trans_deli_chrgs XLTDC --[tUÖ^ÀAhI}X^
-- 2010/01/28 T.Yoshimoto Del Start {Ò®#1168
       --,fnd_user                    FU_CB --[U[}X^(created_by¼Ìæ¾p)
       --,fnd_user                    FU_LU --[U[}X^(last_updated_by¼Ìæ¾p)
       --,fnd_user                    FU_LL --[U[}X^(last_update_login¼Ìæ¾p)
       --,fnd_logins                  FL_LL --OC}X^(last_update_login¼Ìæ¾p)
 --WHERE  XLTDC.created_by        = FU_CB.user_id(+)
   --AND  XLTDC.last_updated_by   = FU_LU.user_id(+)
   --AND  XLTDC.last_update_login = FL_LL.login_id(+)
   --AND  FL_LL.user_id           = FU_LL.user_id(+)
-- 2010/01/28 T.Yoshimoto Del End {Ò®#1168
/
COMMENT ON TABLE APPS.XXSKZ_[tUÖ^À_î{_V IS 'SKYLINKp[tUÖ^Àiî{jVIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_[tUÖ^À_î{_V.KpJnú                 IS 'KpJnú'
/
COMMENT ON COLUMN APPS.XXSKZ_[tUÖ^À_î{_V.KpI¹ú                 IS 'KpI¹ú'
/
COMMENT ON COLUMN APPS.XXSKZ_[tUÖ^À_î{_V.ÖÝèàz                 IS 'ÖÝèàz'
/
COMMENT ON COLUMN APPS.XXSKZ_[tUÖ^À_î{_V.ÂãÀP                 IS 'ÂãÀP'
/
COMMENT ON COLUMN APPS.XXSKZ_[tUÖ^À_î{_V.ÝèàzP                 IS 'ÝèàzP'
/
COMMENT ON COLUMN APPS.XXSKZ_[tUÖ^À_î{_V.ÂãÀQ                 IS 'ÂãÀQ'
/
COMMENT ON COLUMN APPS.XXSKZ_[tUÖ^À_î{_V.ÝèàzQ                 IS 'ÝèàzQ'
/
COMMENT ON COLUMN APPS.XXSKZ_[tUÖ^À_î{_V.ÂãÀR                 IS 'ÂãÀR'
/
COMMENT ON COLUMN APPS.XXSKZ_[tUÖ^À_î{_V.ÝèàzR                 IS 'ÝèàzR'
/
COMMENT ON COLUMN APPS.XXSKZ_[tUÖ^À_î{_V.ÂãÀS                 IS 'ÂãÀS'
/
COMMENT ON COLUMN APPS.XXSKZ_[tUÖ^À_î{_V.ÝèàzS                 IS 'ÝèàzS'
/
COMMENT ON COLUMN APPS.XXSKZ_[tUÖ^À_î{_V.ÂãÀT                 IS 'ÂãÀT'
/
COMMENT ON COLUMN APPS.XXSKZ_[tUÖ^À_î{_V.ÝèàzT                 IS 'ÝèàzT'
/
COMMENT ON COLUMN APPS.XXSKZ_[tUÖ^À_î{_V.ÂãÀU                 IS 'ÂãÀU'
/
COMMENT ON COLUMN APPS.XXSKZ_[tUÖ^À_î{_V.ÝèàzU                 IS 'ÝèàzU'
/
COMMENT ON COLUMN APPS.XXSKZ_[tUÖ^À_î{_V.ÂãÀV                 IS 'ÂãÀV'
/
COMMENT ON COLUMN APPS.XXSKZ_[tUÖ^À_î{_V.ÝèàzV                 IS 'ÝèàzV'
/
COMMENT ON COLUMN APPS.XXSKZ_[tUÖ^À_î{_V.ÂãÀW                 IS 'ÂãÀW'
/
COMMENT ON COLUMN APPS.XXSKZ_[tUÖ^À_î{_V.ÝèàzW                 IS 'ÝèàzW'
/
COMMENT ON COLUMN APPS.XXSKZ_[tUÖ^À_î{_V.ÂãÀX                 IS 'ÂãÀX'
/
COMMENT ON COLUMN APPS.XXSKZ_[tUÖ^À_î{_V.ÝèàzX                 IS 'ÝèàzX'
/
COMMENT ON COLUMN APPS.XXSKZ_[tUÖ^À_î{_V.ÂãÀPO               IS 'ÂãÀPO'
/
COMMENT ON COLUMN APPS.XXSKZ_[tUÖ^À_î{_V.ÝèàzPO               IS 'ÝèàzPO'
/
COMMENT ON COLUMN APPS.XXSKZ_[tUÖ^À_î{_V.ì¬Ò                     IS 'ì¬Ò'
/
COMMENT ON COLUMN APPS.XXSKZ_[tUÖ^À_î{_V.ì¬ú                     IS 'ì¬ú'
/
COMMENT ON COLUMN APPS.XXSKZ_[tUÖ^À_î{_V.ÅIXVÒ                 IS 'ÅIXVÒ'
/
COMMENT ON COLUMN APPS.XXSKZ_[tUÖ^À_î{_V.ÅIXVú                 IS 'ÅIXVú'
/
COMMENT ON COLUMN APPS.XXSKZ_[tUÖ^À_î{_V.ÅIXVOC           IS 'ÅIXVOC'
/
