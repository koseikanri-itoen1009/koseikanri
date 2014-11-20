/*************************************************************************
 * 
 * VIEW Name       : XXCSO_QT_AP_TAX_RATE_V
 * Description     : 見積用仮払税率取得ビュー
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2011/05/17    1.0  K.Kiriu      初回作成
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXCSO_QT_AP_TAX_RATE_V
(
  ap_tax_rate
)
AS
  SELECT  1 + ( NVL(atca.tax_rate, 0) / 100 ) ap_tax_rate
  FROM    ap_tax_codes_all atca
  WHERE   atca.name              = fnd_profile.value( 'XXCSO1_QT_AP_TAX_RATE' )                        --仮払税コード
  AND     atca.set_of_books_id   = TO_NUMBER( fnd_profile.value( 'GL_SET_OF_BKS_ID' ) )                --会計帳簿ID
  AND     xxcso_util_common_pkg.get_online_sysdate BETWEEN atca.start_date
                          AND     NVL( atca.inactive_date, xxcso_util_common_pkg.get_online_sysdate )  --適用開始、終了
  AND     atca.enabled_flag      = 'Y'                                       --有効フラグ
  AND     atca.attribute2        = '1'                                       --課税集計対象(課税売上)
WITH READ ONLY
;
COMMENT ON COLUMN XXCSO_QT_AP_TAX_RATE_V.ap_tax_rate IS '仮払税率';
COMMENT ON TABLE XXCSO_QT_AP_TAX_RATE_V IS '見積用仮払税率取得ビュー';
