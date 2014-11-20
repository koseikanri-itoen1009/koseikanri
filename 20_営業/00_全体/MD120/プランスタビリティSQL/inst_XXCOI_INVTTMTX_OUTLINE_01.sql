rem 
------------------------------------------------------------
-- MD.120 
--   プランスタビリティアウトラインのインストレーションルーチン
-- 
-- ↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
-- define orig_file      =   作成元SQLのファイル名
-- define hint_file      =   ヒント付きSQLのファイル名
-- define orig_ol_name   =   アウトライン名（30文字）
-- define hint_ol_name   =   ヒント付き用の一時アウトライン名（30文字）
-- define orig_category  =   プロファイルに設定するアウトラインカテゴリ名（30文字）
--
-- @@release_palnstabiliry.sql  <<<<<<<<<<<  変更不可
-- ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑
-- 
------------------------------------------------------------

define orig_file      = XXCOI_INVTTMTX_OUTLINE_01.sql
define hint_file      = XXCOI_INVTTMTX_OUTLINE_01_HINT.sql
define orig_ol_name   = XXCOI_INVTTMTX_OUTLINE_01
define hint_ol_name   = XXCOI_INVTTMTX_OUTLINE_01_H
define orig_category  = XXCOI_INV
@@release_palnstabiliry.sql
