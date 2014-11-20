CREATE OR REPLACE FORCE VIEW XXCFO_PAY_GROUP_V(
/*************************************************************************
 * 
 * View Name       : XXCFO_PAY_GROUP_V
 * Description     : 支払グループビュー
 * MD.050          : 
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2008/12/18    1.0  SCS 嵐田     初回作成
 ************************************************************************/
  lookup_code,                          -- ルックアップコード
  attribute2                            -- 支払可能部門
) AS
  SELECT flv.lookup_code lookup_code    -- ルックアップコード
        ,flv.attribute2 attribute2      -- 支払可能部門
    FROM fnd_lookup_values flv          -- クイックコード
        ,fnd_application fa             -- アプリケーション管理マスタ
   WHERE fa.application_short_name = 'PO'                                           -- アプリケーション管理マスタ.アプリケーション短縮名 = ‘PO’
     AND fa.application_id = flv.view_application_id                                -- アプリケーション管理マスタ.アプリケーションID = 支払グループ.ビューアプリケーションID
     AND flv.lookup_type = 'PAY GROUP'                                              -- 支払グループ.ルックアップタイプ = 'PAY GROUP'（支払グループ）
     AND flv.language = USERENV( 'LANG' )                                           -- 支払グループ.言語 = USERENV( 'LANG' )
     AND flv.enabled_flag = 'Y'                                                     -- 支払グループ.有効フラグ = 'Y'
     AND TRUNC( SYSDATE ) BETWEEN TRUNC( NVL( flv.start_date_active ,SYSDATE ) )    -- TRUNC( システム日付 ) BETWEEN TRUNC( NVL( 支払グループ.開始日 ,システム日付 ) )
                              AND TRUNC( NVL( flv.end_date_active ,SYSDATE ) )      -- AND TRUNC( NVL( 支払グループ.終了日 ,システム日付 ) )
/
