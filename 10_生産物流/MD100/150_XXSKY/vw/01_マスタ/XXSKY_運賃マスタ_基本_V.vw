CREATE OR REPLACE VIEW APPS.XXSKY_^ภ}X^_๎{_V
(
 xฅฟๆช
,xฅฟๆชผ
,คiๆช
,คiๆชผ
,^ฦา
,^ฦาผ
,zๆช
,zๆชผ
,^ภฃ
,dส
,KpJn๚
,KpIน๚
,^๏
,[tฌฺ
,์ฌา
,์ฌ๚
,ลIXVา
,ลIXV๚
,ลIXVOC
)
AS
SELECT  
        XDC.p_b_classe                 --xฅฟๆช
-- 2010/01/28 T.Yoshimoto Mod Start {าฎ#1168
       --,FLV01.meaning                  --xฅฟๆชผ
       ,(SELECT FLV01.meaning
         FROM fnd_lookup_values FLV01  --NCbNR[h(xฅฟๆชผ)
         WHERE FLV01.language    = 'JA'
           AND FLV01.lookup_type = 'XXWIP_PAYCHARGE_TYPE'
           AND FLV01.lookup_code = XDC.p_b_classe
        ) FLV01_meaning
-- 2010/01/28 T.Yoshimoto Mod End {าฎ#1168
       ,XDC.goods_classe               --คiๆช
-- 2010/01/28 T.Yoshimoto Mod Start {าฎ#1168
       --,FLV02.meaning                  --คiๆชผ
       ,(SELECT FLV02.meaning
         FROM fnd_lookup_values FLV02  --NCbNR[h(คiๆชผ)
         WHERE FLV02.language    = 'JA'
           AND FLV02.lookup_type = 'XXWIP_ITEM_TYPE'
           AND FLV02.lookup_code = XDC.goods_classe
        ) FLV02_meaning
-- 2010/01/28 T.Yoshimoto Mod End {าฎ#1168
       ,XDC.delivery_company_code      --^ฦาR[h
-- 2010/01/28 T.Yoshimoto Mod Start {าฎ#1168
       --,XCRV.party_name                --^ฦาผ
       ,(SELECT XCRV.party_name
         FROM xxsky_carriers_v XCRV   --^ฦา๎๑VIEW
         WHERE XDC.delivery_company_code = XCRV.freight_code
        ) XCRV_party_name
-- 2010/01/28 T.Yoshimoto Mod End {าฎ#1168
       ,XDC.shipping_address_classe    --zๆช
-- 2010/01/28 T.Yoshimoto Mod Start {าฎ#1168
       --,FLV03.meaning                  --zๆชผ
       ,(SELECT FLV03.meaning
         FROM fnd_lookup_values FLV03  --NCbNR[h(zๆชผ)
         WHERE FLV03.language    = 'JA'
           AND FLV03.lookup_type = 'XXCMN_SHIP_METHOD'
           AND FLV03.lookup_code = XDC.shipping_address_classe
        ) FLV03_meaning
-- 2010/01/28 T.Yoshimoto Mod End {าฎ#1168
       ,XDC.delivery_distance          --^ภฃ
       ,XDC.delivery_weight            --dส
       ,XDC.start_date_active          --KpJn๚
       ,XDC.end_date_active            --KpIน๚
       ,XDC.shipping_expenses          --^๏
       ,XDC.leaf_consolid_add          --[tฌฺ
-- 2010/01/28 T.Yoshimoto Mod Start {าฎ#1168
       --,FU_CB.user_name                --์ฌา
       ,(SELECT FU_CB.user_name
         FROM fnd_user FU_CB  --[U[}X^(created_byผฬๆพp)
         WHERE XDC.created_by = FU_CB.user_id
        ) FU_CB_user_name
-- 2010/01/28 T.Yoshimoto Mod End {าฎ#1168
       ,TO_CHAR( XDC.creation_date, 'YYYY/MM/DD HH24:MI:SS')
                                       --์ฌ๚
-- 2010/01/28 T.Yoshimoto Mod Start {าฎ#1168
       --,FU_LU.user_name                --ลIXVา
       ,(SELECT FU_LU.user_name
         FROM fnd_user FU_LU  --[U[}X^(last_updated_byผฬๆพp)
         WHERE XDC.last_updated_by = FU_LU.user_id
        ) FU_LU_user_name
-- 2010/01/28 T.Yoshimoto Mod End {าฎ#1168
       ,TO_CHAR( XDC.last_update_date, 'YYYY/MM/DD HH24:MI:SS')
                                       --ลIXV๚
-- 2010/01/28 T.Yoshimoto Mod Start {าฎ#1168
       --,FU_LL.user_name                --ลIXVOC
       ,(SELECT FU_LL.user_name
         FROM fnd_user    FU_LL  --[U[}X^(last_update_loginผฬๆพp)
             ,fnd_logins FL_LL  --OC}X^(last_update_loginผฬๆพp)
         WHERE XDC.last_update_login = FL_LL.login_id
         AND   FL_LL.user_id         = FU_LL.user_id
        ) FU_LL_user_name
-- 2010/01/28 T.Yoshimoto Mod End {าฎ#1168
  FROM  xxwip_delivery_charges  XDC    --^ภAhI}X^C^tF[X
-- 2010/01/28 T.Yoshimoto Del Start {าฎ#1168
       --,xxsky_carriers_v        XCRV   --^ฦา๎๑VIEW
       --,fnd_user                FU_CB  --[U[}X^(created_byผฬๆพp)
       --,fnd_user                FU_LU  --[U[}X^(last_updated_byผฬๆพp)
       --,fnd_user                FU_LL  --[U[}X^(last_update_loginผฬๆพp)
       --,fnd_logins              FL_LL  --OC}X^(last_update_loginผฬๆพp)
       --,fnd_lookup_values       FLV01  --NCbNR[h(xฅฟๆชผ)
       --,fnd_lookup_values       FLV02  --NCbNR[h(คiๆชผ)
       --,fnd_lookup_values       FLV03  --NCbNR[h(zๆชผ)
 --WHERE  XDC.delivery_company_code = XCRV.freight_code(+)
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
-- 2010/01/28 T.Yoshimoto Del End {าฎ#1168
/
COMMENT ON TABLE APPS.XXSKY_^ภ}X^_๎{_V IS 'SKYLINKp^ภ}X^i๎{jVIEW'
/
COMMENT ON COLUMN APPS.XXSKY_^ภ}X^_๎{_V.xฅฟๆช             IS 'xฅฟๆช'
/
COMMENT ON COLUMN APPS.XXSKY_^ภ}X^_๎{_V.xฅฟๆชผ           IS 'xฅฟๆชผ'
/
COMMENT ON COLUMN APPS.XXSKY_^ภ}X^_๎{_V.คiๆช                 IS 'คiๆช'
/
COMMENT ON COLUMN APPS.XXSKY_^ภ}X^_๎{_V.คiๆชผ               IS 'คiๆชผ'
/
COMMENT ON COLUMN APPS.XXSKY_^ภ}X^_๎{_V.^ฦา                 IS '^ฦา'
/
COMMENT ON COLUMN APPS.XXSKY_^ภ}X^_๎{_V.^ฦาผ               IS '^ฦาผ'
/
COMMENT ON COLUMN APPS.XXSKY_^ภ}X^_๎{_V.zๆช                 IS 'zๆช'
/
COMMENT ON COLUMN APPS.XXSKY_^ภ}X^_๎{_V.zๆชผ               IS 'zๆชผ'
/
COMMENT ON COLUMN APPS.XXSKY_^ภ}X^_๎{_V.^ภฃ                 IS '^ภฃ'
/
COMMENT ON COLUMN APPS.XXSKY_^ภ}X^_๎{_V.dส                     IS 'dส'
/
COMMENT ON COLUMN APPS.XXSKY_^ภ}X^_๎{_V.KpJn๚               IS 'KpJn๚'
/
COMMENT ON COLUMN APPS.XXSKY_^ภ}X^_๎{_V.KpIน๚               IS 'KpIน๚'
/
COMMENT ON COLUMN APPS.XXSKY_^ภ}X^_๎{_V.^๏                   IS '^๏'
/
COMMENT ON COLUMN APPS.XXSKY_^ภ}X^_๎{_V.[tฌฺ           IS '[tฌฺ'
/
COMMENT ON COLUMN APPS.XXSKY_^ภ}X^_๎{_V.์ฌา                   IS '์ฌา'
/
COMMENT ON COLUMN APPS.XXSKY_^ภ}X^_๎{_V.์ฌ๚                   IS '์ฌ๚'
/
COMMENT ON COLUMN APPS.XXSKY_^ภ}X^_๎{_V.ลIXVา               IS 'ลIXVา'
/
COMMENT ON COLUMN APPS.XXSKY_^ภ}X^_๎{_V.ลIXV๚               IS 'ลIXV๚'
/
COMMENT ON COLUMN APPS.XXSKY_^ภ}X^_๎{_V.ลIXVOC         IS 'ลIXVOC'
/
