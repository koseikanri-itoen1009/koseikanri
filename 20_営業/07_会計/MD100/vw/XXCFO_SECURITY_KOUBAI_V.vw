CREATE OR REPLACE FORCE VIEW XXCFO_SECURITY_KOUBAI_V(
/*************************************************************************
 * 
 * View Name       : XXCFO_SECURITY_KOUBAI_V
 * Description     : 購買関連ビュー
 * MD.050          : 
 * MD.070          : 
 * Version         : 1.1
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2008/12/18    1.0  SCS 嵐田      初回作成
 *  2009/05/01    1.1  SCS 嵐田 勇人 [障害T1_0894]コメントを追加
 ************************************************************************/
  lookup_code                           -- ルックアップコード
) AS
  SELECT flv.lookup_code lookup_code    -- ルックアップコード
    FROM fnd_lookup_values flv          -- クイックコード
   WHERE flv.lookup_type = 'XXCFO1_SECURITY_KOUBAI'                                 -- クイックコード.ルックアップタイプ = 'XXCFO1_SECURITY_KOUBAI'（セキュリティ購買関連部門）
     AND flv.language = USERENV( 'LANG' )                                           -- クイックコード.言語 = USERENV( 'LANG' )
     AND flv.enabled_flag = 'Y'                                                     -- クイックコード.有効フラグ = 'Y'
     AND TRUNC( SYSDATE ) BETWEEN TRUNC( NVL( flv.start_date_active ,SYSDATE ) )    -- TRUNC( システム日付 ) BETWEEN TRUNC( NVL( クイックコード.開始日 ,システム日付 ) )
                              AND TRUNC( NVL( flv.end_date_active ,SYSDATE ) )      -- AND TRUNC( NVL( クイックコード.終了日 ,システム日付 ) )
/
-- Modify 2009.05.01 Ver1.1 Start
COMMENT ON COLUMN  xxcfo_security_koubai_v.lookup_code      IS '購買関連部門'
/
COMMENT ON TABLE  xxcfo_security_koubai_v IS '購買関連ビュー'
/
-- Modify 2009.05.01 Ver1.1 End
