/*************************************************************************
 * 
 * VIEW Name       : XXCSO_QT_AP_TAX_RATE_V
 * Description     : ©Ïp¼¥Å¦æ¾r[
 * MD.070          : 
 * Version         : 1.2
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2011/05/17    1.0  K.Kiriu      ñì¬
 *  2013/07/30    1.1  K.Kiriu      [E_{Ò®_10884]ÁïÅÎ
 *  2019/06/11    1.2  K.Minoura    [E_{Ò®_15472]y¸Å¦Î
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXCSO_QT_AP_TAX_RATE_V
(
  ap_tax_rate
-- 2013/07/30 Ver1.1 Add Start
 ,start_date
 ,end_date
-- 2013/07/30 Ver1.1 Add End
-- 2019/06/11 Ver1.2 Add Start
 ,start_date_histories
 ,end_date_histories
 ,item_code
-- 2019/06/11 Ver1.2 Add End
)
AS
-- 2019/06/11 Ver1.2 Mod Start
--  SELECT  1 + ( NVL(atca.tax_rate, 0) / 100 ) ap_tax_rate
---- 2013/07/30 Ver1.1 Add Start
--         ,flvv.start_date_active              start_date  --KpJnú(NCbNR[h)
--         ,flvv.end_date_active                end_date    --KpI¹ú(NCbNR[h)
---- 2013/07/30 Ver1.1 Add End
--  FROM    ap_tax_codes_all atca
---- 2013/07/30 Ver1.1 Add Start
--         ,fnd_lookup_values_vl flvv
---- 2013/07/30 Ver1.1 Add End
---- 2013/07/30 Ver1.1 Mod Start
----  WHERE   atca.name              = fnd_profile.value( 'XXCSO1_QT_AP_TAX_RATE' )                        --¼¥ÅR[h
----  AND     atca.set_of_books_id   = TO_NUMBER( fnd_profile.value( 'GL_SET_OF_BKS_ID' ) )                --ïv ëID
--  WHERE   atca.set_of_books_id   = TO_NUMBER( fnd_profile.value( 'GL_SET_OF_BKS_ID' ) )                --ïv ëID
---- 2013/07/30 Ver1.1 Mod End
---- 2013/07/30 Ver1.1 Del Start
----  AND     xxcso_util_common_pkg.get_online_sysdate BETWEEN atca.start_date
----                          AND     NVL( atca.inactive_date, xxcso_util_common_pkg.get_online_sysdate )  --KpJnAI¹
---- 2013/07/30 Ver1.1 Del End
--  AND     atca.enabled_flag      = 'Y'                                       --LøtO
--  AND     atca.attribute2        = '1'                                       --ÛÅWvÎÛ(ÛÅã)
---- 2013/07/30 Ver1.1 Add Start
--  AND     atca.name              = flvv.lookup_code
--  AND     flvv.lookup_type       = 'XXCSO1_AP_TAX_RATE_SALES' --APÅ¦}X^ÛÅã
--  AND     flvv.enabled_flag      = 'Y'                        --LøtO(QÆ^Cv)
---- 2013/07/30 Ver1.1 Add End
  SELECT  1 + ( NVL(xrtrv.tax_rate, 0) / 100 )      ap_tax_rate
         ,xrtrv.start_date                          start_date            --KpJnú
         ,xrtrv.end_date                            end_date              --KpI¹ú
         ,xrtrv.start_date_histories                start_date_histories  --ÁïÅðJnú
         ,xrtrv.end_date_histories                  end_date_histories    --ÁïÅðI¹ú
         ,xrtrv.item_code                           item_code
  FROM    xxcos_reduced_tax_rate_v xrtrv
-- 2019/06/11 Ver1.2 Mod End
WITH READ ONLY
;
COMMENT ON COLUMN XXCSO_QT_AP_TAX_RATE_V.ap_tax_rate IS '¼¥Å¦';
-- 2013/07/30 Ver1.1 Add Start
COMMENT ON COLUMN XXCSO_QT_AP_TAX_RATE_V.start_date  IS 'KpJnú';
COMMENT ON COLUMN XXCSO_QT_AP_TAX_RATE_V.end_date    IS 'KpI¹ú';
-- 2013/07/30 Ver1.1 Add End
-- 2019/06/11 Ver1.2 Add Start
COMMENT ON COLUMN XXCSO_QT_AP_TAX_RATE_V.start_date_histories  IS 'ÁïÅðJnú';
COMMENT ON COLUMN XXCSO_QT_AP_TAX_RATE_V.end_date_histories    IS 'ÁïÅðI¹ú';
COMMENT ON COLUMN XXCSO_QT_AP_TAX_RATE_V.item_code             IS 'iÚR[h';
-- 2019/06/11 Ver1.2 Add End
COMMENT ON TABLE XXCSO_QT_AP_TAX_RATE_V IS '©Ïp¼¥Å¦æ¾r[';
