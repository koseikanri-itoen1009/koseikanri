/*************************************************************************
 * 
 * VIEW Name       : XXCSO_QT_AP_TAX_RATE_V
 * Description     : 見積用仮払税率取得ビュー
 * MD.070          : 
 * Version         : 1.2
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2011/05/17    1.0  K.Kiriu      初回作成
 *  2013/07/30    1.1  K.Kiriu      [E_本稼動_10884]消費税対応
 *  2019/06/11    1.2  K.Minoura    [E_本稼動_15472]軽減税率対応
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
--         ,flvv.start_date_active              start_date  --適用開始日(クイックコード)
--         ,flvv.end_date_active                end_date    --適用終了日(クイックコード)
---- 2013/07/30 Ver1.1 Add End
--  FROM    ap_tax_codes_all atca
---- 2013/07/30 Ver1.1 Add Start
--         ,fnd_lookup_values_vl flvv
---- 2013/07/30 Ver1.1 Add End
---- 2013/07/30 Ver1.1 Mod Start
----  WHERE   atca.name              = fnd_profile.value( 'XXCSO1_QT_AP_TAX_RATE' )                        --仮払税コード
----  AND     atca.set_of_books_id   = TO_NUMBER( fnd_profile.value( 'GL_SET_OF_BKS_ID' ) )                --会計帳簿ID
--  WHERE   atca.set_of_books_id   = TO_NUMBER( fnd_profile.value( 'GL_SET_OF_BKS_ID' ) )                --会計帳簿ID
---- 2013/07/30 Ver1.1 Mod End
---- 2013/07/30 Ver1.1 Del Start
----  AND     xxcso_util_common_pkg.get_online_sysdate BETWEEN atca.start_date
----                          AND     NVL( atca.inactive_date, xxcso_util_common_pkg.get_online_sysdate )  --適用開始、終了
---- 2013/07/30 Ver1.1 Del End
--  AND     atca.enabled_flag      = 'Y'                                       --有効フラグ
--  AND     atca.attribute2        = '1'                                       --課税集計対象(課税売上)
---- 2013/07/30 Ver1.1 Add Start
--  AND     atca.name              = flvv.lookup_code
--  AND     flvv.lookup_type       = 'XXCSO1_AP_TAX_RATE_SALES' --AP税率マスタ課税売上
--  AND     flvv.enabled_flag      = 'Y'                        --有効フラグ(参照タイプ)
---- 2013/07/30 Ver1.1 Add End
  SELECT  1 + ( NVL(xrtrv.tax_rate, 0) / 100 )      ap_tax_rate
         ,xrtrv.start_date                          start_date            --適用開始日
         ,xrtrv.end_date                            end_date              --適用終了日
         ,xrtrv.start_date_histories                start_date_histories  --消費税履歴開始日
         ,xrtrv.end_date_histories                  end_date_histories    --消費税履歴終了日
         ,xrtrv.item_code                           item_code
  FROM    xxcos_reduced_tax_rate_v xrtrv
-- 2019/06/11 Ver1.2 Mod End
WITH READ ONLY
;
COMMENT ON COLUMN XXCSO_QT_AP_TAX_RATE_V.ap_tax_rate IS '仮払税率';
-- 2013/07/30 Ver1.1 Add Start
COMMENT ON COLUMN XXCSO_QT_AP_TAX_RATE_V.start_date  IS '適用開始日';
COMMENT ON COLUMN XXCSO_QT_AP_TAX_RATE_V.end_date    IS '適用終了日';
-- 2013/07/30 Ver1.1 Add End
-- 2019/06/11 Ver1.2 Add Start
COMMENT ON COLUMN XXCSO_QT_AP_TAX_RATE_V.start_date_histories  IS '消費税履歴開始日';
COMMENT ON COLUMN XXCSO_QT_AP_TAX_RATE_V.end_date_histories    IS '消費税履歴終了日';
COMMENT ON COLUMN XXCSO_QT_AP_TAX_RATE_V.item_code             IS '品目コード';
-- 2019/06/11 Ver1.2 Add End
COMMENT ON TABLE XXCSO_QT_AP_TAX_RATE_V IS '見積用仮払税率取得ビュー';
