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

define orig_file      = XXCFR_RAXTRX_OUTLINE_02.sql
define hint_file      = XXCFR_RAXTRX_OUTLINE_02_HINT.sql
define orig_ol_name   = XXCFR_RAXTRX_OUTLINE_02
define hint_ol_name   = XXCFR_RAXTRX_OUTLINE_02H
define orig_category  = XXCCP_JP1SALES
@@release_palnstabiliry.sql
