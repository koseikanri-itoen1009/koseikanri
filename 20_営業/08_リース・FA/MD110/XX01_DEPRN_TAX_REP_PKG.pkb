CREATE OR REPLACE PACKAGE BODY APPS.XX01_deprn_tax_rep_pkg AS
/********************************************************************************
 * $ Header: XX01_DEPRN_TAX_REP_PKG.pkb 11.5.2 0.0.0.4 2011/07/31 $
 * 成果物の全ての知的財産権は弊社に帰属します。
 * 成果物の使用、複製、改変・翻案は、日本オラクル社との契約に記された制約条件に従うものとします。
 * ORACLEはOracle Corporationの登録商標です。
 * Copyright (c) 2001-2011 Oracle Corporation Japan All Rights Reserved
 * パッケージ名 ：  XX01_deprn_tax_rep_pkg
 * 機能概要     ：  償却資産申告書ワークテーブルデータ抽出
 * バージョン   ：  11.5.3
 * 作成者       ：
 * 作成日       ：  2001-10-10
 * 変更者       ：
 * 最終変更日   ：  2019/02/15
 * 変更履歴     ：
 *      2002-07-26  申告地コードの範囲指定を可能とする（FA標準機能変更に
 *                  伴う変更）
 *      2003-04-18  種類別明細書（全資産用）の「価額」は、償却資産申告書の
 *                  決定価格にかかわらず「評価額」を出力する（FA標準機能変更に
 *                  伴う変更）
 *      2003-08-05  UTF-8対応
 *      2004-07-02  申請地摘要取得関数の変更（fa_rx_flex_pkgのものからPRIVATE関数に変更）
 *      2005-04-11  11.5.10 CU1対応
 *                  CU1にて「償却資産税申告書」（RXFADPTX）にパラメータ
 *                  が追加された変更への対応
 *      2005-05-31  #167対応
 *      2009-08-31  ﾏｲﾅｶﾃｺﾞﾘ値が"1"-"6"以外の資産の金額が合計値に合算される障害対応
 *                  ※ﾏｲﾅｶﾃｺﾞﾘ値に1-7を指定して実行した場合の問題
 *                    種類別明細書に対象外の資産を出力したいが、申告書には出力したくない要件対応
 *      2011-07-31  種類別明細書(増加資産用)の機能拡張
 *                  以下の項目も出力可能とする。※出力/非出力制御はEXCELにて設定
 *                   ・減価残存率
 *                   ・価額
 *                   ・課税標準の特例(コード,率)
 *                   ・課税標準額
 * ------------- -------- ------------- -------------------------------------
 *  Date          Ver.     Editor        Description
 * ------------- -------- ------------- -------------------------------------
 *  2019/02/15    11.5.3    Y.Sasaki     E_本稼動_ 年号変更対応
                                         和暦の取得元を変更
 *******************************************************************************/
--
-- 2004-07-01 added start 申請地摘要の取得処理変更につき必要となった宣言です。
TYPE fa_rx_flex_desc_rec_type IS RECORD (
  application_id fnd_id_flex_structures.application_id%type,
  id_flex_code fnd_id_flex_structures.id_flex_code%type,
  id_flex_num  number,
  qualifier fnd_segment_attribute_types.segment_attribute_type%type,
  data  varchar2(240),
  concatenated_description   varchar2(2000));

TYPE fa_rx_flex_desc_table_type IS TABLE OF fa_rx_flex_desc_rec_type
INDEX BY BINARY_INTEGER;

type seg_array is table of varchar2(50) index by binary_integer;

invalid_argument exception;

fa_rx_flex_desc_t  fa_rx_flex_desc_table_type ;

cursor cflex(p_application_id in varchar2,
      p_id_flex_code in varchar2,
      p_id_flex_num in number,
      p_qualifier in varchar2,
      p_segnum in number) is
  select s.segment_num, s.application_column_name, s.flex_value_set_id
  from  fnd_id_flex_segments s
  where s.application_id = p_application_id
  and   s.id_flex_code = p_id_flex_code
  and   s.id_flex_num = p_id_flex_num
  and   s.enabled_flag = 'Y'
  and   p_qualifier = 'ALL'
  and   p_segnum is null
  union all
  select s.segment_num, s.application_column_name, s.flex_value_set_id
  from  fnd_id_flex_segments s,
        fnd_segment_attribute_values sav,
        fnd_segment_attribute_types sat
  where s.application_id = p_application_id
  and   s.id_flex_code = p_id_flex_code
  and   s.id_flex_num = p_id_flex_num
  and   s.enabled_flag = 'Y'
  and   s.application_column_name = sav.application_column_name
  and   sav.application_id = p_application_id
  and   sav.id_flex_code = p_id_flex_code
  and   sav.id_flex_num = p_id_flex_num
  and   sav.attribute_value = 'Y'
  and   sav.segment_attribute_type = sat.segment_attribute_type
  and   sat.application_id = p_application_id
  and   sat.id_flex_code = p_id_flex_code
  and   sat.unique_flag = 'Y'
  and   sat.segment_attribute_type = p_qualifier
  and   p_qualifier <> 'ALL'
  and   p_segnum is null
  union all
  select s.segment_num, s.application_column_name, s.flex_value_set_id
  from  fnd_id_flex_segments s
  where s.application_id = p_application_id
  and   s.id_flex_code = p_id_flex_code
  and   s.id_flex_num = p_id_flex_num
  and   s.enabled_flag = 'Y'
  and   s.segment_num = p_segnum
  and   p_qualifier is null
  order by 1;
-- 2004-07-01 added end 申請地摘要の取得処理変更につき必要となった宣言です。
--
--
PROCEDURE fadptx_insert_main (
  errbuf                OUT VARCHAR2,
  retcode               OUT NUMBER,
  in_sequence_id        IN  NUMBER,     -- シーケンスＩＤ
  iv_book               IN  VARCHAR2,   -- 台帳
  in_year               IN  NUMBER,     -- 対象年度
  in_locstruct_num      IN  NUMBER,     -- 事業所体系ＩＤ

--20020802 modified
  iv_state_from         IN  VARCHAR2,   -- 申告地コード自
  iv_state_to           IN  VARCHAR2,   -- 申告地コード至

  in_cat_struct_num     IN  NUMBER,     -- カテゴリ体系ID
-- 2005-04-11 Add Start
  iv_tax_asset_type_seg IN  VARCHAR2,   -- 資産種類セグメント(Tax Asset Type Segment)
-- 2005-04-11 Add End
  iv_minor_cat_exist    IN  VARCHAR2,   -- 既存補助カテゴリチェック
  iv_category_from      IN  VARCHAR2,   -- 補助カテゴリ自
  iv_category_to        IN  VARCHAR2,   -- 補助カテゴリ至
  iv_sale_code          IN  VARCHAR2,   -- 売却コード
  iv_reciept_day        IN  VARCHAR2,   -- 受付日
  iv_sum_rep            IN  VARCHAR2,   -- 償却資産申告書データの作成
  iv_all_rep            IN  VARCHAR2,   -- 種類別明細書（全資産用）データの作成
  iv_add_rep            IN  VARCHAR2,   -- 種類別明細書（増加資産用）データの作成
  iv_dec_rep            IN  VARCHAR2,   -- 種類別明細書（減少資産用）データの作成
  iv_net_book_value     IN  VARCHAR2,   -- 価額計算の選択
  iv_debug              IN  VARCHAR2    -- デバッグ
  ) IS
--
/********************************************************************************
 * PROCEDURE名  ：  fadptx_insert_main
 * 機能概要     ：  償却資産申告書ワークテーブルデータ抽出主処理
 * バージョン   ：  1.0.2
 * 引数         ：
 * 戻り値       ：  OUT errbuf                  ｴﾗｰﾊﾞｯﾌｧ
 *                  OUT retcode                 ﾚｯﾄｺｰﾄﾞ
 * 注意事項     ：  特に無し
 * 作成者       ：
 * 作成日       ：  2001-10-10
 * 変更者       ：
 * 最終変更日   ：  2005-05-31
 *      2002-07-26  申告地コードの範囲指定を可能とする（FA標準機能変更に
 *                  伴う変更）
 *      2005-05-31  #167対応
 *                  Ｎ--------------------------------------------------------Ｎ
 *******************************************************************************/
--
  -- 変数の定義
  v_errbuf      VARCHAR2( 2000 ) := NULL ;
  n_retcode     NUMBER := 0 ;
  v_procname    VARCHAR2(50)  := 'XX01_DEPRN_TAX_DEP_PKG.FADPTX_INSERT_MAIN' ;
--
  n_request_id  NUMBER ;
  n_login_id    NUMBER ;
--
  b_debug   BOOLEAN ;   -- デバッグの選択
--
  n_req_id      NUMBER ;
  n_conc_sleep_time NUMBER := 3 ;
  v_phase_code  VARCHAR2(1) ;
  v_status_code VARCHAR2(1) ;
  d_reciept_day DATE ;
--
  v_state_yn VARCHAR2(3) ;
--
  SUB_EXPT                  EXCEPTION ;
--
BEGIN
--
  -- 変数初期化
  retcode := 0;
  errbuf := NULL;
--
  -- *********
  -- 初期処理
  -- *********
  initialize( v_errbuf
            , n_retcode );
--
  -- ********************************************
  -- addition(2001/11/28)iv_reciept_dayをTO_DATE
  -- ********************************************
  d_reciept_day := TO_DATE(iv_reciept_day,'RRRR/MM/DD HH24:MI:SS') ;
--
  IF  n_retcode != 0 THEN
    RAISE SUB_EXPT;
  END IF;
--
  fa_rx_util_pkg.debug('in_sequence_id:' ||in_sequence_id);
--
    xx01_conc_util_pkg.conc_log_param( 'シーケンスＩＤ', in_sequence_id, 1 );
    xx01_conc_util_pkg.conc_log_param( '台帳', iv_book, 2 );
    xx01_conc_util_pkg.conc_log_param( '対象年度', in_year, 3 );
    xx01_conc_util_pkg.conc_log_param( '事業所体系ＩＤ', in_locstruct_num, 4 );

--20020802 modified
    xx01_conc_util_pkg.conc_log_param( '申告地コード自', iv_state_from, 5 );
    xx01_conc_util_pkg.conc_log_param( '申告地コード至', iv_state_to, 6 );

    xx01_conc_util_pkg.conc_log_param( 'カテゴリ体系ID', in_cat_struct_num, 7 );
    xx01_conc_util_pkg.conc_log_param( '既存補助カテゴリチェック', iv_minor_cat_exist, 8 );
    xx01_conc_util_pkg.conc_log_param( '補助カテゴリ自', iv_category_from, 9 );
    xx01_conc_util_pkg.conc_log_param( '補助カテゴリ至', iv_category_to, 10 );
    xx01_conc_util_pkg.conc_log_param( '売却コード', iv_sale_code, 11 );
    xx01_conc_util_pkg.conc_log_param( '受付日', iv_reciept_day, 12 );
    xx01_conc_util_pkg.conc_log_param( '償却資産申告書データの作成',iv_sum_rep, 13 );
    xx01_conc_util_pkg.conc_log_param( '種類別明細書（全資産用）データの作成',iv_all_rep, 14 );
    xx01_conc_util_pkg.conc_log_param( '種類別明細書（増加資産用）データの作成',iv_add_rep, 15 );
    xx01_conc_util_pkg.conc_log_param( '種類別明細書（減少資産用）データの作成',iv_dec_rep, 16 );
    xx01_conc_util_pkg.conc_log_param( '価額計算の選択',iv_net_book_value, 17 );
    xx01_conc_util_pkg.conc_log_param( 'デバッグ', iv_debug, 18 );

--
    xx01_conc_util_pkg.conc_log_line( '=' );
    xx01_conc_util_pkg.conc_log_put( ' ' );
    xx01_conc_util_pkg.conc_log_line( '=' );
--
  b_debug := Upper(iv_debug) LIKE 'Y%';
  IF b_debug THEN
  fa_rx_util_pkg.enable_debug;
  END IF;
--
  -- 要求ＩＤの取得
  n_request_id := fnd_global.conc_request_id ;
--
  -- LOGIN_IDの取得
  fnd_profile.get('LOGIN_ID',n_login_id);
--
  -- *************************************************************
  -- ワークテーブルにすべての市区町村区分を挿入するかどうかの判定
  -- *************************************************************
--20020802 modified
  IF (iv_state_from IS NULL) AND (iv_state_to IS NULL) THEN
    v_state_yn := 'Y';
  ELSE
    v_state_yn := 'N';
  END IF;
--
--
  -- ***************************************************************
  -- 中間テーブル（fa_deprn_tax_rep_itf）作成コンカレント要求の発行
  -- ***************************************************************
-- 2005-04-11 Modified Start
-- 11.5.10 CU1 よりパラメータ「資産種類セグメント」が追加されたため、その対応
  -- CU1対応版で無い場合
  IF UPPER(iv_tax_asset_type_seg) = 'XX01_DUMMY'  THEN
    n_req_id := FND_REQUEST.SUBMIT_REQUEST( 'OFA'                   -- application
                                            ,'RXFADPTX'             -- program
                                            ,null                   -- description
                                            ,null                   -- start_time
                                            ,FALSE                  -- sub_request
                                            ,iv_book                -- argument1（台帳）
                                            ,TO_CHAR(in_year)       -- argument2（対象年度）
                                            ,TO_CHAR(in_locstruct_num)        -- argument3（事業所体系ＩＤ）
                                            ,iv_state_from            -- argument4（申告地コード自）
                                            ,iv_state_to              -- argument5（申告地コード至）
                                            ,TO_CHAR(in_cat_struct_num)       -- argument6（カテゴリ体系ID）
                                            ,iv_minor_cat_exist     -- argument7（既存補助カテゴリチェック）
                                            ,iv_category_from       -- argument8（補助カテゴリ自）
                                            ,iv_category_to         -- argument9（補助カテゴリ至）
                                            ,iv_sale_code           -- argument10（売却コード）
                                            ,'N'                    -- argument11（償却資産申告書データの作成）
                                            ,'NO'                   -- argument12（種類別明細書（全資産用）データの作成）
                                            ,'NO'                   -- argument13（種類別明細書（増加資産用）データの作成）
                                            ,'N'                    -- argument14（種類別明細書（減少資産用）データの作成）
--2005-05-31 Update start
                                            ,iv_debug               -- argument15（デバッグ）
--                                            , v_state_yn            -- arugment15（ワークテーブルにすべての市区町村区分を挿入）
--                                            ,iv_debug               -- argument16（デバッグ）
--2005-05-31 Update End
                                            ,chr(0)
                                          ) ;

  -- CU1対応版である場合
  ELSE
    n_req_id := FND_REQUEST.SUBMIT_REQUEST( 'OFA'                   -- application
                                            ,'RXFADPTX'             -- program
                                            ,null                   -- description
                                            ,null                   -- start_time
                                            ,FALSE                  -- sub_request
                                            ,iv_book                -- argument1（台帳）
                                            ,TO_CHAR(in_year)       -- argument2（対象年度）
                                            ,TO_CHAR(in_locstruct_num)        -- argument3（事業所体系ＩＤ）
                                            ,iv_state_from            -- argument4（申告地コード自）
                                            ,iv_state_to              -- argument5（申告地コード至）
                                            ,TO_CHAR(in_cat_struct_num)       -- argument6（カテゴリ体系ID）
                                            ,iv_tax_asset_type_seg  -- argument6.5（資産種類セグメント）
                                            ,iv_minor_cat_exist     -- argument7（既存補助カテゴリチェック）
                                            ,iv_category_from       -- argument8（補助カテゴリ自）
                                            ,iv_category_to         -- argument9（補助カテゴリ至）
                                            ,iv_sale_code           -- argument10（売却コード）
                                            ,'N'                    -- argument11（償却資産申告書データの作成）
                                            ,'NO'                   -- argument12（種類別明細書（全資産用）データの作成）
                                            ,'NO'                   -- argument13（種類別明細書（増加資産用）データの作成）
                                            ,'N'                    -- argument14（種類別明細書（減少資産用）データの作成）
--2005-05-31 Update start
                                            ,iv_debug               -- argument15（デバッグ）
--                                            , v_state_yn            -- arugment15（ワークテーブルにすべての市区町村区分を挿入）
--                                            ,iv_debug               -- argument16（デバッグ）
--2005-05-31 Update End
                                            ,chr(0)
                                          ) ;

  END IF;
/*
  n_req_id := FND_REQUEST.SUBMIT_REQUEST( 'OFA'                   -- application
                                          ,'RXFADPTX'             -- program
                                          ,null                   -- description
                                          ,null                   -- start_time
                                          ,FALSE                  -- sub_request
                                          ,iv_book                -- argument1（台帳）
                                          ,TO_CHAR(in_year)       -- argument2（対象年度）
                                          ,TO_CHAR(in_locstruct_num)        -- argument3（事業所体系ＩＤ）

--20020802 modified
                                          ,iv_state_from            -- argument4（申告地コード自）
                                          ,iv_state_to              -- argument5（申告地コード至）

                                          ,TO_CHAR(in_cat_struct_num)       -- argument6（カテゴリ体系ID）
                                          ,iv_minor_cat_exist     -- argument7（既存補助カテゴリチェック）
                                          ,iv_category_from       -- argument8（補助カテゴリ自）
                                          ,iv_category_to         -- argument9（補助カテゴリ至）
                                          ,iv_sale_code           -- argument10（売却コード）
                                          ,'N'                    -- argument11（償却資産申告書データの作成）
                                          ,'NO'                   -- argument12（種類別明細書（全資産用）データの作成）
                                          ,'NO'                   -- argument13（種類別明細書（増加資産用）データの作成）
                                          ,'N'                    -- argument14（種類別明細書（減少資産用）データの作成）
                                          , v_state_yn            -- arugment15（ワークテーブルにすべての市区町村区分を挿入）
                                          ,iv_debug               -- argument16（デバッグ）
                                          ,chr(0)
                                        ) ;
*/
-- 2005-04-11 Modified End
--
--
   fa_rx_util_pkg.debug('n_req_id:' ||to_char(n_req_id));
--
  -- コンカレント要求の成功判定
  IF n_request_id = 0 THEN
    FND_MESSAGE.SET_NAME('OFA','FA_DEPRN_TAX_ERROR');
    FND_MESSAGE.SET_TOKEN('REQUEST_ID',n_request_id,TRUE);
    FND_FILE.PUT_LINE(fnd_file.output,fnd_message.get);
  ELSE
    FND_MESSAGE.SET_NAME('OFA','FA_DEPRN_TAX_COMP');
    FND_MESSAGE.SET_TOKEN('REQUEST_ID',n_request_id,TRUE);
    FND_FILE.PUT_LINE(fnd_file.output,fnd_message.get);
  END IF ;
--
  COMMIT ;
--
  -- **********************************
  -- コンカレント終了監視処理
  -- **********************************
    LOOP
      BEGIN
        SELECT  phase_code
        INTO    v_phase_code
        FROM    fnd_concurrent_requests
        WHERE   request_id = n_req_id ;
      EXCEPTION
        WHEN OTHERS THEN
        -- その他エラー
        v_errbuf := xx01_conc_util_pkg.get_message_others( 'コンカレント（RXFADPTX）終了監視処理' );
        n_retcode := 2;
        RAISE SUB_EXPT;
      END;
--
      -- 標準コンカレントの終了判定
      EXIT WHEN v_phase_code = 'C' ;
--
      -- スリープ
      dbms_lock.sleep(n_conc_sleep_time);
--
    END LOOP ;
--
  -- **********************************
  -- コンカレント完了ステータス取得処理
  -- **********************************
  BEGIN
    SELECT  status_code
    INTO    v_status_code
    FROM    fnd_concurrent_requests
    WHERE   request_id = n_req_id ;
  EXCEPTION
    WHEN OTHERS THEN
    -- その他エラー
    v_errbuf := xx01_conc_util_pkg.get_message_others( 'コンカレント（RXFADPTX）完了ステータス取得処理' );
    n_retcode := 2;
    RAISE SUB_EXPT;
  END;
--
-- 正常終了以外の場合は、処理終了とする
  IF v_status_code <> 'C' THEN
    v_errbuf := xx01_conc_util_pkg.get_message_others( 'コンカレント（RXFADPTX）の終了判定' );
    n_retcode := 2;
    RAISE SUB_EXPT;
  END IF ;
--
  -- ***************************************
  -- 償却資産申告書ワークテーブルデータ作成
  -- ***************************************
  fa_rx_util_pkg.debug('XX01_deprn_tax_rep_pkg.fadptx_insert start:');
  fa_rx_util_pkg.debug('n_req_id:' ||to_char(n_req_id));
  fa_rx_util_pkg.debug('in_sequence_id:' ||to_char(in_sequence_id));
  fa_rx_util_pkg.debug('n_request_id:' ||to_char(n_request_id));
--
  fadptx_insert(
     v_errbuf
    ,n_retcode
    ,iv_book            -- 台帳

--20020802 modified
    ,iv_state_from      -- 申告地コード自
    ,iv_state_to        -- 申告地コード至

    ,in_locstruct_num   -- 事業所体系ＩＤ
    ,in_year            -- 対象年度
    ,d_reciept_day      -- 受付日
    ,v_state_yn         -- ワークテーブルにすべての市区町村区分を挿入
    ,iv_sum_rep         -- 償却資産申告書データの作成
    ,iv_all_rep         -- 種類別明細書（全資産用）データの作成
    ,iv_add_rep         -- 種類別明細書（増加資産用）データの作成
    ,iv_dec_rep         -- 種類別明細書（減少資産用）データの作成
    ,iv_net_book_value  -- 価額計算の選択
    ,n_req_id           -- 中間テーブル作成時の要求ＩＤ
    ,in_sequence_id     -- シーケンスＩＤ
    ,n_request_id       -- コンカレント要求ＩＤ
  );
--
--
  IF  n_retcode != 0 THEN
    RAISE SUB_EXPT ;
  END IF ;
--
  COMMIT ;
--
EXCEPTION
  WHEN SUB_EXPT THEN
    ROLLBACK ;
    errbuf  := v_errbuf ;
    retcode := n_retcode ;
    IF errbuf IS NULL THEN
      errbuf  := v_procname||'でユーザー定義例外が発生しました。' ;
    END IF ;
    IF retcode IS NULL OR retcode = 0 THEN
      retcode := 2 ;
    END IF ;
    RETURN ;
  WHEN OTHERS THEN
    ROLLBACK ;
    errbuf  := xx01_conc_util_pkg.get_message_others( v_procname ) ;
    retcode := 2 ;
    RETURN ;
END fadptx_insert_main ;
--
--
PROCEDURE initialize(
  errbuf  OUT VARCHAR2,
  retcode OUT NUMBER) IS
/********************************************************************************
 * PROCEDURE名  ：  initialize
 * 機能概要     ：  変数初期化処理
 * バージョン   ：  1.0.0
 * 引数         ：  特に無し
 * 戻り値       ：  OUT errbuf
 *                  OUT retcode
 * 注意事項     ：  特に無し
 * 作成者       ：
 * 作成日       ：  2001-10-10
 * 変更者       ：
 * 最終変更日   ：  YYYY-MM-DD
 * 変更履歴     ：
 *      YYYY-MM-DD  Ｎ--------------------------------------------------------Ｎ
 *                  Ｎ--------------------------------------------------------Ｎ
 *******************************************************************************/
  v_procname    VARCHAR2(50)    := 'XX01_DEPRN_TAX_DEP_PKG.INITIALIZE' ;
  v_errbuf  VARCHAR2(2000)  := NULL ;
  n_retcode NUMBER(1)       := 0 ;
--
  SUB_EXPT                  EXCEPTION ; -- ｻﾌﾞﾙｰﾁﾝ例外処理
--
BEGIN
-- 変数初期化
  retcode := 0 ;
  errbuf := NULL ;
--
-- コンカレントログファイル出力初期処理
  xx01_conc_util_pkg.conc_log_start ;
--
-- 固定値ｾｯﾄ
  gn_created_by             := fnd_global.user_id ;
  gd_creation_date          := SYSDATE ;
  gn_last_updated_by        := fnd_global.user_id ;
  gd_last_update_date       := SYSDATE ;
  gn_last_update_login      := fnd_global.conc_login_id ;
  gn_request_id             := fnd_global.conc_request_id ;
  gn_program_application_id := fnd_global.prog_appl_id ;
  gn_program_id             := fnd_global.conc_program_id ;
  gd_program_update_date    := SYSDATE ;
--
EXCEPTION
  WHEN SUB_EXPT THEN
    -- initializeﾌﾟﾛｼｰｼﾞｬからCALLしたｻﾌﾞﾙｰﾁﾝでｴﾗｰが発生した場合
    errbuf  := v_errbuf ;
    retcode := n_retcode ;
  WHEN OTHERS THEN
    errbuf  := xx01_conc_util_pkg.get_message_others( v_procname ) ;
    retcode := 2 ;
END initialize ;
--
--
PROCEDURE separate_segments(
  p_seg_array in out nocopy seg_array,
  p_values in varchar2,
  p_sep in varchar2)
/********************************************************************************
 * PROCEDURE名  ：  separate_segments
 * 機能概要     ：  セグメント値の分離関数
 * バージョン   ：  1.0.0
 * 引数         ：  IN  p_values                Concatenated Segments
 *                  IN  p_sep                   Segment Delimiter
 * 戻り値       ：  IN OUT  p_seg_array         Segment Array
 * 注意事項     ：  fa_rx_flex_pkgの同名のプロシージャと同じ働きをします。
 *                  fa_rx_flex_pkg.separate_segmentsがprivteプロシージャなので
 *                  同じものを作成しました。
 * 作成者       ：
 * 作成日       ：  2004-07-02
 * 変更者       ：
 * 最終変更日   ：  YYYY-MM-DD
 * 変更履歴     ：
 *      YYYY-MM-DD  Ｎ--------------------------------------------------------Ｎ
 *                  Ｎ--------------------------------------------------------Ｎ
 *******************************************************************************/
IS
  i number;
  next_sep number;
  l_values varchar2(600);
BEGIN
  l_values := p_values;
  i := 1;
  while (l_values is not null) loop
    next_sep := instr(l_values, p_sep);
    if next_sep = 0 then
      p_seg_array(i) := l_values;
      l_values := null;
    else
      p_seg_array(i) := substr(l_values, 1, next_sep-1);
      l_values := substr(l_values, next_sep+1);
    end if;

    i := i+1;
  end loop;

  fa_rx_util_pkg.debug('fa_rx_flex_pkg.separate_segments('||to_char(i-1)||')-');

END separate_segments;
--
--
FUNCTION get_id_flex_num(
  p_application_id in number,
  p_id_flex_code in varchar2,
  p_id_flex_num in number) return number
/********************************************************************************
 * FUNCTION名   ：  get_id_flex_num
 * 機能概要     ：  Flexfield structure num を取得する関数です。
 * バージョン   ：  1.0.0
 * 引数         ：  IN  p_application_id      Application ID of key flexfield
 *                  IN  p_id_flex_code        Flexfield code
 * 戻り値       ：  IN  p_id_flex_num         Flexfield structure num
 * 注意事項     ：  fa_rx_flex_pkgの同名のプロシージャと同じ働きをします。
 *                  fa_rx_flex_pkg.get_id_flex_numがprivte関数なので
 *                  同じものを作成しました。
 * 作成者       ：
 * 作成日       ：  2004-07-02
 * 変更者       ：
 * 最終変更日   ：  YYYY-MM-DD
 * 変更履歴     ：
 *      YYYY-MM-DD  Ｎ--------------------------------------------------------Ｎ
 *                  Ｎ--------------------------------------------------------Ｎ
 *******************************************************************************/
IS
  l_id_flex_num number;
BEGIN
  if p_id_flex_num is not null then
    return p_id_flex_num;
  end if;

  select id_flex_num into l_id_flex_num
  from fnd_id_flex_structures
  where application_id = p_application_id
  and   id_flex_code = p_id_flex_code;

  return l_id_flex_num;
EXCEPTION
  WHEN TOO_MANY_ROWS THEN
    RAISE;
END get_id_flex_num;
--
--
function get_segment_delimiter(
  p_application_id in number,
  p_id_flex_code in varchar2,
  p_id_flex_num in number) return varchar2
/********************************************************************************
 * FUNCTION名   ：  get_segment_delimiter
 * 機能概要     ：  セグメントの区切り文字取得関数
 * バージョン   ：  1.0.0
 * 引数         ：  IN  p_application_id      Application ID of key flexfield
 *                  IN  p_id_flex_code        Flexfield code
 * 戻り値       ：  IN  p_id_flex_num         Flexfield structure num
 * 戻り値       ：  VARCHAR2                  セグメントの区切り文字
 * 注意事項     ：  fa_rx_flex_pkgの同名のプロシージャと同じ働きをします。
 *                  fa_rx_flex_pkg.get_segment_delimiterがprivte関数なので
 *                  同じものを作成しました。
 * 作成者       ：
 * 作成日       ：  2004-07-02
 * 変更者       ：
 * 最終変更日   ：  YYYY-MM-DD
 * 変更履歴     ：
 *      YYYY-MM-DD  Ｎ--------------------------------------------------------Ｎ
 *                  Ｎ--------------------------------------------------------Ｎ
 *******************************************************************************/
IS
  sep fnd_id_flex_structures.concatenated_segment_delimiter%type;
BEGIN
  select concatenated_segment_delimiter into sep
  from fnd_id_flex_structures
  where application_id = p_application_id
  and id_flex_code = p_id_flex_code
  and id_flex_num = p_id_flex_num;

  return sep;

EXCEPTION
  WHEN NO_DATA_FOUND THEN
    raise;
END get_segment_delimiter;
--
--
FUNCTION get_description(
  p_application_id in number,
  p_id_flex_code in varchar2,
  p_id_flex_num in number default NULL,
  p_qualifier in varchar2,
  p_data in varchar2) 
return varchar2
/********************************************************************************
 * FUNCTION名   ：  get_description
 * 機能概要     ：  セグメントの区切り文字取得関数
 * バージョン   ：  1.0.0
 * 引数         ：  IN  p_application_id      Application ID of key flexfield
 *                  IN  p_id_flex_code        Flexfield code
 *                  IN  p_id_flex_num         Flexfield structure num
 *                  IN  p_qualifier           Flexfield qualifier or segment number
 *                  IN  p_data                Flexfield Segments
 * 戻り値       ：  VARCHAR2                  摘要
 * 注意事項     ：  fa_rx_flex_pkgの同名のプロシージャと同じ働きをします。
 *                  fa_rx_flex_pkg.get_descriptionにBUGがあるためprivate関数
 *                  として同等の働きを行うものを作成しました。
 * 作成者       ：
 * 作成日       ：  2004-07-02
 * 変更者       ：
 * 最終変更日   ：  YYYY-MM-DD
 * 変更履歴     ：
 *      YYYY-MM-DD  Ｎ--------------------------------------------------------Ｎ
 *                  Ｎ--------------------------------------------------------Ｎ
 *******************************************************************************/
IS
  segments seg_array;
  sep fnd_id_flex_structures.concatenated_segment_delimiter%type;

  segnum   fnd_id_flex_segments.segment_num%type;
  colname  fnd_id_flex_segments.application_column_name%type;
  seg_value_set_id fnd_flex_value_sets.flex_value_set_id%type;

  seg_value varchar2(50);
  seg_desc fnd_flex_values_vl.description%type;
  concatenated_description varchar2(2000);
  i number;

  l_qualifier fnd_segment_attribute_types.segment_attribute_type%type;
  l_segnum    fnd_id_flex_segments.segment_num%type;
  l_id_flex_num   number;
  l_counter     number := 0;
  found         boolean;
BEGIN

  LOOP

    IF (fa_rx_flex_desc_t.EXISTS(l_counter))   THEN
      IF ((fa_rx_flex_desc_t(l_counter).application_id =  p_application_id)
      AND (fa_rx_flex_desc_t(l_counter).id_flex_code=p_id_flex_code)
      AND (fa_rx_flex_desc_t(l_counter).id_flex_num =  p_id_flex_num)
      AND (fa_rx_flex_desc_t(l_counter).qualifier =  p_qualifier)
      AND (fa_rx_flex_desc_t(l_counter).data = p_data)) THEN
        RETURN fa_rx_flex_desc_t(l_counter).concatenated_description;
      ELSE
        l_counter:=l_counter + 1;
      END IF;
    END IF;

    EXIT WHEN  (NOT fa_rx_flex_desc_t.EXISTS(l_counter));

  END LOOP;

  l_id_flex_num := get_id_flex_num(p_application_id, p_id_flex_code, p_id_flex_num);

  -- Get segment delimiter
  sep := get_segment_delimiter(p_application_id,p_id_flex_code,l_id_flex_num);

  -- Separate out the data
  if p_qualifier = 'ALL' then
    separate_segments(segments, p_data, sep);
  else
    segments(1) := p_data;
  end if;

  i := 1;
  if cflex%isopen then
    close cflex;
  end if;

  begin
    l_segnum := to_number(p_qualifier);
    l_qualifier := null;
  EXCEPTION
    WHEN VALUE_ERROR THEN
      l_segnum := null;
      l_qualifier := p_qualifier;
  END;

  open cflex(p_application_id,p_id_flex_code,l_id_flex_num,l_qualifier,l_segnum);
  loop
    --
    -- For each row, get its meaning
    --
    fetch cflex into segnum, colname, seg_value_set_id;
    exit when cflex%notfound;

    seg_value := segments(i);

    BEGIN
      seg_desc := fa_rx_shared_pkg.get_flex_val_meaning(seg_value_set_id, null, seg_value);
    EXCEPTION
      WHEN OTHERS THEN
        seg_desc := null;
    END;

    if concatenated_description is not null then
      concatenated_description := concatenated_description || sep;
    end if;

    concatenated_description := concatenated_description || seg_desc;

    i := i + 1;
  end loop;
  close cflex;

  if concatenated_description is null then
    --
    -- If the concatenated_description is null then that means
    -- that cflex cursor returned no rows.
    -- One of the arguments MUST be incorrect
    -- Output the parameters and raise error
    --
    raise invalid_argument;
  end if;

  fa_rx_flex_desc_t(l_counter).application_id := p_application_id;
  fa_rx_flex_desc_t(l_counter).id_flex_code   :=  p_id_flex_code;
  fa_rx_flex_desc_t(l_counter).id_flex_num    :=  p_id_flex_num;
  fa_rx_flex_desc_t(l_counter).qualifier      :=  p_qualifier;
  fa_rx_flex_desc_t(l_counter).data           :=  P_data;
  fa_rx_flex_desc_t(l_counter).concatenated_description :=concatenated_description;

  RETURN  fa_rx_flex_desc_t(l_counter).concatenated_description ;

EXCEPTION
  WHEN OTHERS THEN
    if cflex%isopen then
      close cflex;
    end if;
    raise;
END get_description;
--
--
PROCEDURE fadptx_insert(
  errbuf              OUT VARCHAR2
  ,retcode            OUT NUMBER
  ,iv_book_type_code  IN  VARCHAR2      -- 台帳

--20020802 modified
  ,iv_state_from      IN  VARCHAR2      -- 申告地コード自
  ,iv_state_to        IN  VARCHAR2      -- 申告地コード至

  ,in_locstruct_num   IN  NUMBER        -- 事業所体系ＩＤ
  ,in_year            IN  NUMBER        -- 対象年度
  ,id_reciept_day     IN  DATE          -- 受付日
  ,v_state_yn         IN  VARCHAR2      -- ワークテーブルにすべての市区町村区分を挿入
  ,iv_sum_rep         IN  VARCHAR2      -- 償却資産申告書データの作成
  ,iv_all_rep         IN  VARCHAR2      -- 種類別明細書（全資産用）データの作成
  ,iv_add_rep         IN  VARCHAR2      -- 種類別明細書（増加資産用）データの作成
  ,iv_dec_rep         IN  VARCHAR2      -- 種類別明細書（減少資産用）データの作成
  ,iv_net_book_value  IN  VARCHAR2      -- 価額計算の選択
  ,in_req_id          IN  NUMBER        -- 中間テーブル作成時の要求ＩＤ
  ,in_sequence_id     IN  NUMBER        -- シーケンスＩＤ
  ,in_request_id      IN  NUMBER) IS    -- コンカレント要求ＩＤ
/********************************************************************************
 * PROCEDURE名  ：  fadptx_insert
 * 機能概要     ：  償却資産申告書ワークテーブルデータ作成
 * バージョン   ：  1.0.6
 * 引数         ：  特に無し
 * 戻り値       ：  OUT errbuf                  ｴﾗｰﾊﾞｯﾌｧ
 *                  OUT retcode                 ﾚｯﾄｺｰﾄﾞ
 *                  IN  VARCHAR2                台帳
 *                  IN  VARCHAR2                申告地コード
 *                  IN  VARCHAR2                事業所体系ＩＤ
 *                  IN  VARCHAR2                対象年度
 *                  IN  DATE                    受付日
 *                  IN  VARCHAR2                償却資産申告書データの作成
 *                  IN  VARCHAR2                種類別明細書（全資産用）データの作成
 *                  IN  VARCHAR2                種類別明細書（増加資産用）データの作成
 *                  IN  VARCHAR2                種類別明細書（減少資産用）データの作成
 *                  IN  VARCHAR2                価額計算の選択
 *                  IN  NUMBER                  中間テーブル作成時の要求ＩＤ
 *                  IN  NUMBER                  シーケンスＩＤ
 *                  IN  NUMBER                  コンカレント要求ＩＤ
 * 注意事項     ：  特に無し
 * 作成者       ：
 * 作成日       ：  2001-10-10
 * 変更者       ：
 * 最終変更日   ：  2009-08-31
 * 変更履歴     ：
 *      2002-03-22  決定価額及び課税標準額出力不備対応
 *      2002-07-26  申告地コードの範囲指定を可能とする（FA標準機能変更に
 *                  伴う変更）
 *                  償却資産申告書の件数計算時に全除却資産を除外して計算する
 *                  ように修正
 *      2003-04-18  種類別明細書（全資産用）の「価額」は、償却資産申告書の
 *                  決定価格にかかわらず「評価額」を出力する（FA標準機能変更に
 *                  伴う変更）
 *      2003-08-05  UTF-8対応
 *      2004-07-02  申請地摘要取得関数をプライベート関数に変更
 *      2009-08-31  ﾏｲﾅｶﾃｺﾞﾘ値が"1"-"6"以外の資産の金額が合計値に合算される障害対応
 *                  ※ﾏｲﾅｶﾃｺﾞﾘ値に1-7を指定して実行した場合の問題
 *                    種類別明細書に対象外の資産を出力したいが、申告書には出力したくない要件対応
 *******************************************************************************/
-- 変数の定義
  v_procname    VARCHAR2(50)    := 'XX01_DEPRN_TAX_DEP_PKG.FADPTX_INSERT' ;
  v_errbuf      VARCHAR2( 2000 ) := NULL ;
  n_retcode     NUMBER := 0 ;
--
  n_wk_sum_seq  NUMBER := 0 ; -- 申告書用カウンタ
  n_wk_all_seq  NUMBER := 0 ; -- 全資産用カウンタ
  n_wk_add_seq  NUMBER := 0 ; -- 増加資産用カウンタ
  n_wk_dec_seq  NUMBER := 0 ; -- 減少資産用カウンタ
  n_count       NUMBER := 0 ; -- 申告書用カウンタ２
--
  v_decision          VARCHAR2(20) ;  -- 価額計算の選択
  v_imperial_code     xx01_lookup_codes.meaning%TYPE ;
  n_imperial_year     NUMBER ;
  v_year              VARCHAR2(10) ;  -- 対象年度（和暦）
  v_reciept_year_code xx01_lookup_codes.meaning%TYPE ;
  n_recpt_year        NUMBER ;
  v_reciept_year      VARCHAR2(10) ;  -- 受付年月日（和暦）
  v_reciept_month     VARCHAR2(2) ;   -- 受付年
  v_reciept_day       VARCHAR2(2) ;   -- 受付日
  v_state_old         VARCHAR2(150) := 'DEFAULT';
  v_state_old2        VARCHAR2(150) := 'DEFAULT';
  n_wk_seq NUMBER:= 0 ;
  n_all_seq NUMBER ;
  n_add_seq NUMBER ;
  n_dec_seq NUMBER ;
  n_sum_seq NUMBER ;
  v_yes_code xx01_lookup_codes.meaning%TYPE ;
  v_no_code xx01_lookup_codes.meaning%TYPE ;
  v_db_code xx01_lookup_codes.meaning%TYPE ;
  v_stl_code xx01_lookup_codes.meaning%TYPE ;
  v_both_code xx01_lookup_codes.meaning%TYPE ;

--20020802 add
  n_count1 NUMBER ;      --20020802 add
  n_count2 NUMBER ;      --20020802 add
  n_count3 NUMBER ;      --20020802 add
  n_count4 NUMBER ;      --20020802 add
  n_count5 NUMBER ;      --20020802 add
  n_count6 NUMBER ;      --20020802 add
  n_sum_count NUMBER ;   --20020802 add
--
-- 定数の定義
  cv_yes VARCHAR2(1) := 'Y' ;
  cv_no VARCHAR2(1) := 'N' ;
  cv_db VARCHAR2(2) := 'DB' ;
  cv_stl VARCHAR2(3) := 'STL' ;
  cv_both VARCHAR2(4) := 'BOTH' ;
-- UPDATE 2003-08-05
--  cv_circle VARCHAR2(2) := '○' ;
  cv_circle VARCHAR2(10) := '○' ;
  cv_com_flag VARCHAR2(6) := '000000' ;

  v_description VARCHAR2(150) ;
--
    -- **************
    -- カーソル定義1
    -- **************
    CURSOR cur_detail IS
    SELECT  dti.request_id
            ,dti.year
            ,dti.asset_id
            ,dti.asset_number
            ,dti.asset_description
            ,dti.new_used
            ,dti.book_type_code
            ,dti.minor_category
            ,dti.tax_asset_type
            ,dti.minor_cat_desc
            ,dti.state
            ,dti.start_units_assigned
            ,dti.end_units_assigned
            ,dti.start_cost
            ,dti.end_cost
            ,dti.increase_cost
            ,dti.decrease_cost
            ,dti.theoretical_nbv
            ,dti.evaluated_nbv
            ,dti.date_placed_in_service
            ,dti.era_name_num
            ,dti.add_era_year
            ,dti.add_month
            ,dti.start_life
            ,dti.end_life
            ,dti.theoretical_residual_rate
            ,dti.evaluated_residual_rate
            ,dti.adjusted_rate
            ,dti.exception_code
            ,dti.exception_rate
            ,dti.theoretical_taxable_cost
            ,dti.evaluated_taxable_cost
            ,dti.all_reason_type
            ,dti.all_reason_code
            ,dti.all_description
            ,dti.adddec_reason_type
            ,dti.adddec_reason_code
            ,dti.dec_type
            ,dti.adddec_description
            ,dti.add_dec_flag
            ,dti.functional_currency_code
            ,dti.organization_name
            ,tdi.owner_code
            ,tdi.owner
    FROM    fa_deprn_tax_rep_itf dti
            ,XX01_tax_dep_info tdi
    WHERE   dti.request_id = in_req_id
    AND     dti.book_type_code = tdi.book_type_code(+)
    AND     dti.book_type_code = iv_book_type_code
    AND     dti.state = tdi.state(+)
    ORDER BY  dti.state
              ,dti.tax_asset_type
              ,dti.asset_id ;
--
  rec_detail    cur_detail%rowtype ;
--
    -- **************
    -- カーソル定義2
    -- **************
    CURSOR cur_head IS
    SELECT
      dti.book_type_code
      ,dti.state
      ,dti.tax_asset_type
      ,sum(dti.start_cost) sum_start_cost
      ,sum(dti.increase_cost) sum_increase_cost
      ,sum(dti.decrease_cost) sum_decrease_cost
      ,sum(dti.end_cost) sum_end_cost
      ,sum(dti.theoretical_nbv) sum_theoretical_nbv
      ,sum(dti.evaluated_nbv) sum_evaluated_nbv
      ,sum(dti.theoretical_taxable_cost) sum_theoretical_taxable_cost
      ,sum(dti.evaluated_taxable_cost) sum_evaluated_taxable_cost
--20020802 del
--      ,count(dti.asset_id) sum_count
    FROM  fa_deprn_tax_rep_itf dti
    WHERE dti.request_id = in_req_id

--20020802 modified
    AND   dti.state >= NVL(iv_state_from,dti.state)
    AND   dti.state <= NVL(iv_state_to,dti.state)
--    AND   (dec_type IS NULL OR dec_type <> 1)
--
-- 2009-08-31 Add Start
    AND   dti.tax_asset_type IN ('1','2','3','4','5','6')
-- 2009-08-31 Add End
--
    GROUP BY  dti.book_type_code
              ,dti.state
              ,dti.tax_asset_type
    ORDER BY  dti.state
              ,dti.tax_asset_type ;
--
    rec_head    cur_head%rowtype ;
--

--
    -- **************
    -- カーソル定義3
    -- **************
    CURSOR cur_info(pv_state VARCHAR2) IS
    SELECT tdif.*
    FROM  XX01_tax_dep_info tdif
    WHERE book_type_code = iv_book_type_code
    AND   tdif.state = pv_state
    AND   tdif.state <> cv_com_flag ;
--
    rec_info      cur_info%rowtype ;
    rec_info_null cur_info%rowtype ;
--
    -- **************
    -- カーソル定義4
    -- **************
    CURSOR cur_nbv(pv_state VARCHAR2) IS
      SELECT   SUM(dti.theoretical_nbv) sum_theoretical_nbv -- 現在帳簿価額
              ,SUM(dti.evaluated_nbv) sum_evaluated_nbv     -- 評価額
      FROM    fa_deprn_tax_rep_itf dti
      WHERE   request_id = in_req_id
      AND     dti.end_cost >0
      AND     dti.state = pv_state
--
-- 2009-08-31 Add Start
      AND   dti.tax_asset_type IN ('1','2','3','4','5','6')
-- 2009-08-31 Add End
--
      GROUP BY dti.state
      ORDER BY  dti.state ;
--
      rec_nbv   cur_nbv%rowtype ;
--
    -- **************
    -- カーソル定義5
    -- **************
    CURSOR cur_cominfo IS
      SELECT tdif.*
      FROM  XX01_tax_dep_info tdif
      WHERE book_type_code = iv_book_type_code
      --AND   tdif.state = pv_state
      AND   tdif.state = cv_com_flag ;
--
    rec_cominfo   cur_cominfo%rowtype ;
    rec_cominfo_null    cur_cominfo%rowtype ;
--
--
BEGIN
    fa_rx_util_pkg.debug('in_sequence_id:' ||in_sequence_id);
--
--
  -- ***********************
  -- 対象年度（和暦）の取得
  -- ***********************
  BEGIN
-- V11.5.3 Y.Sasaki Modified START
--    SELECT  meaning
--    INTO    v_imperial_code
--    FROM    FA_LOOKUPS
--    WHERE   lookup_type ='JP_IMPERIAL'
--    AND     lookup_code = TO_CHAR(TO_DATE(in_year,'YYYY'),'E','nls_calendar=''Japanese Imperial''') ;
    SELECT  flv.meaning             meaning
    INTO    v_imperial_code
    FROM    fnd_lookup_values   flv
    WHERE   flv.lookup_type   = 'XXCFF1_JP_IMPERIAL'
    AND     flv.lookup_code   = TO_CHAR(TO_DATE(in_year,'YYYY'),'E','nls_calendar=''Japanese Imperial''')
    AND     flv.language      = USERENV('lang')
    AND     flv.enabled_flag  = 'Y'
    AND     SYSDATE  BETWEEN  flv.start_date_active
                     AND      NVL(flv.end_date_active, SYSDATE)
    ;
-- V11.5.3 Y.Sasaki Modified END
  EXCEPTION
    WHEN OTHERS THEN
    -- その他エラー
    v_errbuf := xx01_conc_util_pkg.get_message_others( '対象年度（和暦）取得' );
    n_retcode := 2;
    RAISE SUB_EXPT;
  END;
--
  BEGIN
    SELECT  TO_NUMBER(TO_CHAR(TO_DATE(in_year,'YYYY'),'YY','nls_calendar=''Japanese Imperial'''))
    INTO    n_imperial_year
    FROM DUAL ;
  EXCEPTION
    WHEN OTHERS THEN
    -- その他エラー
    v_errbuf := xx01_conc_util_pkg.get_message_others( '対象年度（和暦）取得' );
    n_retcode := 2;
    RAISE SUB_EXPT;
  END;
  v_year := v_imperial_code||TO_CHAR(n_imperial_year) ;
--
  -- ***********************
  -- 受付年月日（和暦）の取得
  -- ***********************
  BEGIN
-- V11.5.3 Y.Sasaki Modified START
--    SELECT  meaning
--    INTO    v_reciept_year_code
--    FROM    FA_LOOKUPS
--    WHERE   lookup_type ='JP_IMPERIAL'
--    --AND     lookup_code = TO_CHAR(TO_DATE(iv_reciept_year,'YYYY'),'E','nls_calendar=''Japanese Imperial''') ;
--    AND     lookup_code = TO_CHAR(TO_DATE(TO_CHAR(id_reciept_day,'yyyy'),'YYYY'),'E','nls_calendar=''Japanese Imperial''') ;
      SELECT  flv.meaning           meaning
      INTO    v_reciept_year_code
      FROM    fnd_lookup_values   flv
      WHERE   flv.lookup_type = 'XXCFF1_JP_IMPERIAL'
      AND     flv.lookup_code = TO_CHAR(TO_DATE(TO_CHAR(id_reciept_day,'yyyy'),'YYYY'),'E','nls_calendar=''Japanese Imperial''')
      AND     flv.language    = USERENV('lang')
      AND     flv.enabled_flag = 'Y'
      AND     SYSDATE  BETWEEN  flv.start_date_active
                       AND      NVL(flv.end_date_active, SYSDATE)
      ;
-- V11.5.3 Y.Sasaki Modified END
  EXCEPTION
    WHEN OTHERS THEN
    -- その他エラー
      v_errbuf := xx01_conc_util_pkg.get_message_others( '受付年月日（和暦）取得' ) ;
      n_retcode := 2 ;
      RAISE SUB_EXPT ;
  END ;
--
  BEGIN
    SELECT  TO_NUMBER(TO_CHAR(TO_DATE(TO_CHAR(id_reciept_day,'yyyy'),'YYYY'),'YY','nls_calendar=''Japanese Imperial'''))
    INTO    n_recpt_year
    FROM DUAL ;
  EXCEPTION
    WHEN OTHERS THEN
      -- その他エラー
      v_errbuf := xx01_conc_util_pkg.get_message_others( '受付年月日（和暦）取得' );
      n_retcode := 2;
      RAISE SUB_EXPT;
  END;
  v_reciept_year := v_reciept_year_code||TO_CHAR(n_recpt_year) ;
--
  -- *************
  -- 受付月の取得
  -- *************
  BEGIN
    SELECT TO_CHAR(id_reciept_day,'MM')
    INTO    v_reciept_month
    FROM DUAL ;
  EXCEPTION
    WHEN OTHERS THEN
      -- その他エラー
      v_errbuf := xx01_conc_util_pkg.get_message_others( '受付月取得' );
      n_retcode := 2;
      RAISE SUB_EXPT;
  END;
--
  -- *************
  -- 受付日の取得
  -- *************
  BEGIN
    SELECT TO_CHAR(id_reciept_day,'DD')
    INTO    v_reciept_day
    FROM DUAL ;
  EXCEPTION
    WHEN OTHERS THEN
      -- その他エラー
      v_errbuf := xx01_conc_util_pkg.get_message_others( '受付日取得' );
      n_retcode := 2;
      RAISE SUB_EXPT;
  END;
--
  fa_rx_util_pkg.debug('v_year:' ||v_year);
  fa_rx_util_pkg.debug('v_reciept_year:' ||v_reciept_year);
  fa_rx_util_pkg.debug('v_reciept_month:' ||v_reciept_month);
  fa_rx_util_pkg.debug('v_reciept_day:' ||v_reciept_day);
--
  -- **************************
  -- LOOKUP_CODE(YES_NO)の取得
  -- **************************
  BEGIN
    v_yes_code := xx01_conc_util_pkg.get_lookup_codes('YES_NO','Y') ;
    v_no_code := xx01_conc_util_pkg.get_lookup_codes('YES_NO','N') ;
  EXCEPTION
    WHEN OTHERS THEN
      -- その他エラー
      v_errbuf := xx01_conc_util_pkg.get_message_others( 'LOOKUP_CODE(YES_NO)の取得' );
      n_retcode := 2;
      RAISE SUB_EXPT;
  END;
--
  -- ************************************
  -- LOOKUP_CODE(DEPRN_METHOD_CODE)の取得
  -- ************************************
  BEGIN
    v_db_code := xx01_conc_util_pkg.get_lookup_codes('DEPRN_METHOD_CODE','DB') ;
    v_stl_code := xx01_conc_util_pkg.get_lookup_codes('DEPRN_METHOD_CODE','STL') ;
    v_both_code := xx01_conc_util_pkg.get_lookup_codes('DEPRN_METHOD_CODE','BOTH') ;
  EXCEPTION
    WHEN OTHERS THEN
      -- その他エラー
      v_errbuf := xx01_conc_util_pkg.get_message_others( 'LOOKUP_CODE(DEPRN_METHOD_CODE)の取得' );
      n_retcode := 2;
      RAISE SUB_EXPT;
  END;
--

  -- 中間テーブルの取得
  FOR rec_detail IN cur_detail LOOP
  n_wk_seq := n_wk_seq + 1 ;
--
    -- ***************
    -- 申告地摘要取得
    -- ***************
    BEGIN
/* 2004-07-02 deleted start
      v_description := fa_rx_flex_pkg.get_description(p_application_id  => 140,
                                              p_id_flex_code  => 'LOC#',
                                              p_id_flex_num  => 101,
                                              p_qualifier  => 'LOC_STATE',
                                              p_data   => rec_detail.state) ; -- STATE_DESC
   2004-07-02 deleted end */
/* 2004-07-02 added start */
      v_description := get_description(p_application_id  => 140,
              p_id_flex_code  => 'LOC#',
              p_id_flex_num  => 101,
              p_qualifier  => 'LOC_STATE',
              p_data   => rec_detail.state) ; -- STATE_DESC
/* 2004-07-02 added end */
            fa_rx_util_pkg.debug('v_description:'||v_description);
    EXCEPTION
      WHEN OTHERS THEN
      -- その他ｴﾗｰ
      v_errbuf := xx01_conc_util_pkg.get_message_others( '申告地摘要取得' );
      n_retcode := 2;
      RAISE SUB_EXPT;
    END ;
--
    -- ****************************************
    -- 種類別明細書（全資産用）データの作成判定
    -- ****************************************
    IF UPPER(iv_all_rep) LIKE 'Y%'
    AND rec_detail.end_cost > 0 THEN
--
      -- ワークテーブルシーケンス番号のカウント
      n_wk_all_seq := n_wk_all_seq + 1 ;
--
      -- ***************
      -- 価額計算の判定
      -- ***************
      IF iv_net_book_value ='THEORETICAL' THEN
        v_decision :='THEORETICAL';
      ELSIF iv_net_book_value ='EVALUATED' THEN
        v_decision :='EVALUATED';
      ELSE
        -- AUTOMATIC
        IF v_state_old <> rec_detail.state THEN
  --
          fa_rx_util_pkg.debug('v_state_old:' ||v_state_old);
          OPEN cur_nbv(rec_detail.state) ;
          FETCH cur_nbv INTO rec_nbv ;
  --
            IF rec_nbv.sum_theoretical_nbv > rec_nbv.sum_evaluated_nbv THEN
              v_decision :='THEORETICAL';
            ELSE
              v_decision :='EVALUATED';
            END IF ;
  --
          CLOSE cur_nbv ;
  --
        END IF ;
  --
      END IF ;
--
      v_state_old := rec_detail.state ;
      fa_rx_util_pkg.debug('v_state_old:' ||v_state_old);
      fa_rx_util_pkg.debug('iv_net_book_value:' ||iv_net_book_value);
      fa_rx_util_pkg.debug('rec_nbv.sum_theoretical_nbv:' ||TO_CHAR(rec_nbv.sum_theoretical_nbv));
      fa_rx_util_pkg.debug('rec_nbv.sum_evaluated_nbv:' ||TO_CHAR(rec_nbv.sum_evaluated_nbv));
      fa_rx_util_pkg.debug('v_decision:' ||v_decision);
--
      -- ****************************************
      -- 種類別明細書（全資産用）シーケンスの採番
      -- ****************************************
      BEGIN
        SELECT
          xx01_tax_dep_all_wk_s.nextval
        INTO
          n_all_seq
        FROM
          DUAL ;
      EXCEPTION
        WHEN OTHERS THEN
          -- その他ｴﾗｰ
          v_errbuf := xx01_conc_util_pkg.get_message_others( '種類別明細書（全資産用）シーケンスの採番' );
          n_retcode := 2;
          RAISE SUB_EXPT;
      END;
    --
      BEGIN
        fa_rx_util_pkg.debug('INSERT START XX01_tax_dep_all_wk');
        fa_rx_util_pkg.debug('sequence_id:'||in_sequence_id);
--
        INSERT INTO XX01_tax_dep_all_wk(
           sequence_id
          ,tax_dep_all_wk_id
          ,created_by
          ,creation_date
          ,last_updated_by
          ,last_update_date
          ,last_update_login
          ,request_id
          ,program_application_id
          ,program_id
          ,program_update_date
          ,book_type_code
          ,state
          ,state_desc
          ,year
          ,report_name
          ,owner_code
          ,owner
          ,tax_asset_type
          ,asset_id
          ,asset_number
          ,asset_description
          ,units_assigned
          ,era_name_num
          ,add_era_year
          ,add_month
          ,end_cost
          ,end_life
          ,residual_rate
          ,nbv
          ,exception_code
          ,exception_rate
          ,taxable_cost
          ,all_reason_code
          ,all_description
        )VALUES(
           in_sequence_id             -- SEQUENCE_ID
          ,n_all_seq                  -- WK_SEQ
          ,gn_created_by              -- CREATED_BY
          ,gd_creation_date           -- CREATION_DATE
          ,gn_last_updated_by         -- LAST_UPDATED_BY
          ,gd_last_update_date        -- LAST_UPDATE_DATE
          ,gn_last_update_login       -- LAST_UPDATE_LOGIN
          ,gn_request_id              -- REQUEST_ID
          ,gn_program_application_id  -- PROGRAM_APPLICATION_ID
          ,gn_program_id              -- PROGRAM_ID
          ,gd_program_update_date     -- PROGRAM_UPDATE_DATE
          ,rec_detail.book_type_code  -- BOOK_TYPE_CODE
          ,rec_detail.state           -- STATE
          ,v_description
          ,v_year                     -- YEAR
          ,'全資産'                   -- REPORT_NAME
          ,rec_detail.owner_code      -- OWNER_CODE
          ,rec_detail.owner           -- OWNER
          ,rec_detail.tax_asset_type  -- TAX_ASSET_TYPE
          ,rec_detail.asset_id        -- ASSET_ID
          ,rec_detail.asset_number    -- ASSET_NUMBER
          ,rec_detail.asset_description -- ASSET_DESCRIPTION
          ,rec_detail.end_units_assigned  -- UNITS_ASSIGNED
          ,rec_detail.era_name_num        -- ERA_NAME_NUM
          ,rec_detail.add_era_year    -- ADD_ERA_YEAR
          ,rec_detail.add_month       -- ADD_MONTH
          ,rec_detail.end_cost        -- END_COST
          ,rec_detail.end_life        -- END_LIFE
          ,DECODE(v_decision,'THEORETICAL',rec_detail.theoretical_residual_rate,'EVALUATED',rec_detail.evaluated_residual_rate) -- RESIDUAL_RATE
--20030418 del
--        ,DECODE(v_decision,'THEORETICAL',rec_detail.theoretical_nbv,'EVALUATED',rec_detail.evaluated_nbv) -- NBV
-- 20030418add
          ,rec_detail.evaluated_nbv       -- NBV
          ,rec_detail.exception_code      -- EXCEPTION_CODE
          ,rec_detail.exception_rate      -- EXCEPTION_RATE
          ,DECODE(v_decision,'THEORETICAL',rec_detail.theoretical_taxable_cost,'EVALUATED',rec_detail.evaluated_taxable_cost) -- TAXABLE_COST
          ,rec_detail.all_reason_code   -- ALL_REASON_CODE
          ,rec_detail.all_description   -- ALL_DESCRIPTION
        ) ;
            fa_rx_util_pkg.debug('INSERT END XX01_tax_dep_all_wk');
      EXCEPTION
        WHEN OTHERS THEN
            -- その他ｴﾗｰ
            v_errbuf := xx01_conc_util_pkg.get_message_others( '種類別明細書（全資産用）ワークテーブル設定' );
            n_retcode := 2;
            RAISE SUB_EXPT;
      END;
    END IF ;
--
    -- ****************************************
    -- 種類別明細書（増加資産用）データの作成判定
    -- ****************************************
    IF UPPER(iv_add_rep) LIKE 'Y%'
    AND rec_detail.add_dec_flag = 'A' THEN
--
      -- ワークテーブルシーケンス番号のカウント
      n_wk_add_seq := n_wk_add_seq + 1 ;
--
      -- ****************************************
      -- 種類別明細書（増加資産用）シーケンスの採番
      -- ****************************************
      BEGIN
        SELECT
          xx01_tax_dep_add_wk_s.nextval
        INTO
          n_add_seq
        FROM
          DUAL ;
      EXCEPTION
        WHEN OTHERS THEN
            -- その他ｴﾗｰ
            v_errbuf := xx01_conc_util_pkg.get_message_others( '種類別明細書（増加資産用）シーケンスの採番' );
            n_retcode := 2;
            RAISE SUB_EXPT;
      END;
--
      BEGIN
        fa_rx_util_pkg.debug('INSERT START XX01_tax_dep_add_wk');
--
        INSERT INTO XX01_tax_dep_add_wk(
           sequence_id
          ,tax_dep_add_wk_id
          ,created_by
          ,creation_date
          ,last_updated_by
          ,last_update_date
          ,last_update_login
          ,request_id
          ,program_application_id
          ,program_id
          ,program_update_date
          ,book_type_code
          ,state
          ,state_desc
          ,year
          ,report_name
          ,owner_code
          ,owner
          ,tax_asset_type
          ,asset_id
          ,asset_number
          ,asset_description
          ,add_units_assigned
          ,era_name_num
          ,add_era_year
          ,add_month
          ,increase_cost
          ,end_life
-- 2011-07-31 ADD START
          ,residual_rate
          ,nbv
          ,exception_code
          ,exception_rate
          ,taxable_cost
-- 2011-07-31 ADD END
          ,adddec_reason_code
          ,adddec_description
        )VALUES(
           in_sequence_id             -- SEQUENCE_ID
          ,n_add_seq                  -- WK_SEQ
          ,gn_created_by              -- CREATED_BY
          ,gd_creation_date           -- CREATION_DATE
          ,gn_last_updated_by         -- LAST_UPDATED_BY
          ,gd_last_update_date        -- LAST_UPDATE_DATE
          ,gn_last_update_login       -- LAST_UPDATE_LOGIN
          ,gn_request_id              -- REQUEST_ID
          ,gn_program_application_id  -- PROGRAM_APPLICATION_ID
          ,gn_program_id              -- PROGRAM_ID
          ,gd_program_update_date     -- PROGRAM_UPDATE_DATE
          ,rec_detail.book_type_code  -- BOOK_TYPE_CODE
          ,rec_detail.state           -- STATE
          ,v_description
          ,v_year                     -- YEAR
          ,'増加資産'                 -- REPORT_NAME
          ,rec_detail.owner_code      -- OWNER_CODE
          ,rec_detail.owner           -- OWNER
          ,rec_detail.tax_asset_type  -- TAX_ASSET_TYPE
          ,rec_detail.asset_id        -- ASSET_ID
          ,rec_detail.asset_number    -- ASSET_NUMBER
          ,rec_detail.asset_description -- ASSET_DESCRIPTION
          ,rec_detail.end_units_assigned  -- ADD_UNITS_ASSIGNED
          ,rec_detail.era_name_num    -- ERA_NAME_NUM
          ,rec_detail.add_era_year    -- ADD_ERA_YEAR
          ,rec_detail.add_month       -- ADD_MONTH
          ,rec_detail.increase_cost   -- INCREASE_COST
          ,rec_detail.end_life        -- END_LIFE
-- 2011-07-31 ADD START
          ,DECODE(v_decision,'THEORETICAL',rec_detail.theoretical_residual_rate,'EVALUATED',rec_detail.evaluated_residual_rate) -- RESIDUAL_RATE
          ,rec_detail.evaluated_nbv       -- NBV
          ,rec_detail.exception_code      -- EXCEPTION_CODE
          ,rec_detail.exception_rate      -- EXCEPTION_RATE
          ,DECODE(v_decision,'THEORETICAL',rec_detail.theoretical_taxable_cost,'EVALUATED',rec_detail.evaluated_taxable_cost) -- TAXABLE_COST
-- 2011-07-31 ADD END
          ,rec_detail.adddec_reason_code  -- ADDDEC_REASON_CODE
          ,rec_detail.adddec_description  -- ADDDEC_DESCRIPTION
        ) ;
        EXCEPTION
          WHEN OTHERS THEN
            -- その他ｴﾗｰ
            v_errbuf := xx01_conc_util_pkg.get_message_others( '種類別明細書（増加資産用）ワークテーブル設定' );
            n_retcode := 2;
            RAISE SUB_EXPT;
        END;
    END IF ;
    fa_rx_util_pkg.debug('INSERT END XX01_tax_dep_add_wk');
--
--
    -- *******************************************
    -- 種類別明細書（減少資産用）データの作成判定
    -- *******************************************
    IF UPPER(iv_dec_rep) LIKE 'Y%'
    AND rec_detail.add_dec_flag ='D' THEN
--
      -- ワークテーブルシーケンス番号のカウント
      n_wk_dec_seq := n_wk_dec_seq + 1 ;
--
      -- ****************************************
      -- 種類別明細書（減少資産用）シーケンスの採番
      -- ****************************************
      BEGIN
        SELECT
          xx01_tax_dep_dec_wk_s.nextval
        INTO
          n_dec_seq
        FROM
          DUAL ;
      EXCEPTION
        WHEN OTHERS THEN
            -- その他ｴﾗｰ
            v_errbuf := xx01_conc_util_pkg.get_message_others( '種類別明細書（減少資産用）シーケンスの採番' );
            n_retcode := 2;
            RAISE SUB_EXPT;
      END;
--
      BEGIN
        fa_rx_util_pkg.debug('INSERT START XX01_tax_dep_dec_wk');
--
        INSERT INTO XX01_tax_dep_dec_wk(
        SEQUENCE_ID
        ,TAX_DEP_DEC_WK_ID
        ,CREATED_BY
        ,CREATION_DATE
        ,LAST_UPDATED_BY
        ,LAST_UPDATE_DATE
        ,LAST_UPDATE_LOGIN
        ,REQUEST_ID
        ,PROGRAM_APPLICATION_ID
        ,PROGRAM_ID
        ,PROGRAM_UPDATE_DATE
        ,BOOK_TYPE_CODE
        ,STATE
        ,STATE_DESC
        ,YEAR
        ,REPORT_NAME
        ,OWNER_CODE
        ,OWNER
        ,TAX_ASSET_TYPE
        ,ASSET_ID
        ,ASSET_NUMBER
        ,ASSET_DESCRIPTION
        ,UNITS_ASSIGNED
        ,ERA_NAME_NUM
        ,ADD_ERA_YEAR
        ,ADD_MONTH
        ,DECREASE_COST
        ,LIFE
        ,ADDDEC_REASON_CODE
        ,DEC_TYPE
        ,ADDDEC_DESCRIPTION
        )
        VALUES(
        in_sequence_id              -- SEQUENCE_ID
        ,n_dec_seq                  -- WK_SEQ
        ,gn_created_by              -- CREATED_BY
        ,gd_creation_date           -- CREATION_DATE
        ,gn_last_updated_by         -- LAST_UPDATED_BY
        ,gd_last_update_date        -- LAST_UPDATE_DATE
        ,gn_last_update_login       -- LAST_UPDATE_LOGIN
        ,gn_request_id              -- REQUEST_ID
        ,gn_program_application_id  -- PROGRAM_APPLICATION_ID
        ,gn_program_id              -- PROGRAM_ID
        ,gd_program_update_date     -- PROGRAM_UPDATE_DATE
        ,rec_detail.book_type_code  -- BOOK_TYPE_CODE
        ,rec_detail.state           -- STATE
        ,v_description
        ,v_year                     -- YEAR
        ,'減少資産'                 -- REPORT_NAME
        ,rec_detail.owner_code      -- OWNER_CODE
        ,rec_detail.owner           -- OWNER
        ,rec_detail.tax_asset_type  -- TAX_ASSET_TYPE
        ,rec_detail.asset_id        -- ASSET_ID
        ,rec_detail.asset_number    -- ASSET_NUMBER
        ,rec_detail.asset_description -- ASSET_DESCRIPTION
        ,rec_detail.start_units_assigned - rec_detail.end_units_assigned  -- UNITS_ASSIGNED
        ,rec_detail.era_name_num    -- ERA_NAME_NUM
        ,rec_detail.add_era_year    -- ADD_ERA_YEAR
        ,rec_detail.add_month       -- ADD_MONTH
        ,rec_detail.decrease_cost   -- DECREASE_COST
        ,rec_detail.start_life      -- LIFE
        ,rec_detail.adddec_reason_code  -- ADDDEC_REASON_CODE
        ,rec_detail.dec_type            -- DEC_TYPE
        ,rec_detail.adddec_description  -- ADDDEC_DESCRIPTION
        ) ;
      EXCEPTION
        WHEN OTHERS THEN
          -- その他ｴﾗｰ
          v_errbuf := xx01_conc_util_pkg.get_message_others( '種類別明細書（減少資産用）ワークテーブル設定' ) ;
          n_retcode := 2 ;
          RAISE SUB_EXPT ;
      END ;
    END IF ;
    fa_rx_util_pkg.debug('INSERT END XX01_tax_dep_dec_wk');
  END LOOP ;
--
    -- *******************************************
    -- 償却資産申告書データの作成判定
    -- *******************************************
    IF UPPER(iv_sum_rep) LIKE 'Y%' THEN
      n_count := 0 ;
      v_decision := 'DEFAULT' ;
      v_state_old := 'DEFAULT';                   -- Add by Ver1.0.1 2002/03/22
--
      FOR rec_head IN cur_head LOOP
        n_count := n_count + 1 ;
--
      -- ***************
      -- 価額計算の判定
      -- ***************
      IF iv_net_book_value ='THEORETICAL' THEN
        v_decision :='THEORETICAL';
      ELSIF iv_net_book_value ='EVALUATED' THEN
        v_decision :='EVALUATED';
      ELSE
        -- AUTOMATIC
        IF v_state_old <> rec_head.state THEN
--
          fa_rx_util_pkg.debug('v_state_old:' ||v_state_old);
          OPEN cur_nbv(rec_head.state) ;
          FETCH cur_nbv INTO rec_nbv ;
--
            IF rec_nbv.sum_theoretical_nbv > rec_nbv.sum_evaluated_nbv THEN
              v_decision :='THEORETICAL';
            ELSE
              v_decision :='EVALUATED';
            END IF ;
--
          CLOSE cur_nbv ;
--
        END IF ;
--
      END IF ;
--
      v_state_old := rec_head.state ;
      fa_rx_util_pkg.debug('v_state_old:' ||v_state_old);
      fa_rx_util_pkg.debug('iv_net_book_value:' ||iv_net_book_value);
      fa_rx_util_pkg.debug('rec_nbv.sum_theoretical_nbv:' ||TO_CHAR(rec_nbv.sum_theoretical_nbv));
      fa_rx_util_pkg.debug('rec_nbv.sum_evaluated_nbv:' ||TO_CHAR(rec_nbv.sum_evaluated_nbv));
      fa_rx_util_pkg.debug('v_decision:' ||v_decision);
--
    -- ***************
    -- 申告地摘要取得
    -- ***************
    BEGIN
/* 2004-07-02 deleted start
      v_description := fa_rx_flex_pkg.get_description(p_application_id  => 140,
                                              p_id_flex_code  => 'LOC#',
                                              p_id_flex_num  => 101,
                                              p_qualifier  => 'LOC_STATE',
                                              p_data   => rec_head.state) ; -- STATE_DESC
   2004-07-02 deleted end */
/* 2004-07-02 added start */
      v_description := get_description(p_application_id  => 140,
              p_id_flex_code  => 'LOC#',
              p_id_flex_num  => 101,
              p_qualifier  => 'LOC_STATE',
            p_data   => rec_head.state) ; -- STATE_DESC
/* 2004-07-02 added end */
            fa_rx_util_pkg.debug('v_description:'||v_description);
    EXCEPTION
      WHEN OTHERS THEN
      -- その他ｴﾗｰ
      v_errbuf := xx01_conc_util_pkg.get_message_others( '申告地摘要取得' );
      n_retcode := 2;
      RAISE SUB_EXPT;
    END ;
--
        IF v_state_old2 <> rec_head.state THEN
          n_count := 1 ;
        END IF ;
        fa_rx_util_pkg.debug('v_state_old2:' ||v_state_old2);
        fa_rx_util_pkg.debug('rec_head.state:' ||rec_head.state);
--
        IF n_count = 1 THEN
          -- ワークテーブルシーケンス番号のカウント
          n_wk_sum_seq := n_wk_sum_seq + 1 ;
--
          -- 初期化
          rec_info := rec_info_null ;
--
          OPEN cur_info(rec_head.state) ;
          FETCH cur_info INTO rec_info ;
          CLOSE cur_info ;
--
          IF rec_info.state IS NOT NULL AND rec_info.com_info_flag = 'N' THEN
            rec_cominfo := rec_cominfo_null ;
            OPEN cur_cominfo ;
            FETCH cur_cominfo INTO rec_cominfo ;
            CLOSE cur_cominfo ;
--
            rec_info.post_num                 := rec_cominfo.post_num ;
            rec_info.owner_address1           := rec_cominfo.owner_address1 ;
            rec_info.owner_address2           := rec_cominfo.owner_address2 ;
            rec_info.owner_address_phonetic1  := rec_cominfo.owner_address_phonetic1 ;
            rec_info.owner_address_phonetic2  := rec_cominfo.owner_address_phonetic2 ;
            rec_info.owner_phone_num          := rec_cominfo.owner_phone_num ;
            rec_info.corporation_name         := rec_cominfo.corporation_name ;
            rec_info.corporation_phonetic     := rec_cominfo.corporation_phonetic ;
            rec_info.representative           := rec_cominfo.representative ;
            rec_info.representative_phonetic  := rec_cominfo.representative_phonetic ;
            rec_info.business                 := rec_cominfo.business ;
            rec_info.capital                  := rec_cominfo.capital ;
            rec_info.business_open_date       := rec_cominfo.business_open_date ;
            rec_info.responser                := rec_cominfo.responser ;
            rec_info.responser_name           := rec_cominfo.responser_name ;
            rec_info.responser_phone_num      := rec_cominfo.responser_phone_num ;
            rec_info.consultant_name          := rec_cominfo.consultant_name ;
            rec_info.consultant_phone_num     := rec_cominfo.consultant_phone_num ;
          END IF ;
--
          -- ****************************************
          -- 償却資産申告書シーケンスの採番
          -- ****************************************
          BEGIN
            SELECT
              xx01_tax_dep_wk_s.nextval
            INTO
              n_sum_seq
            FROM
              DUAL ;
          EXCEPTION
            WHEN OTHERS THEN
                -- その他ｴﾗｰ
                v_errbuf := xx01_conc_util_pkg.get_message_others( '償却資産申告書シーケンスの採番' );
                n_retcode := 2;
                RAISE SUB_EXPT;
          END;
--
          BEGIN
          fa_rx_util_pkg.debug('INSERT START XX01_tax_dep_wk');
        fa_rx_util_pkg.debug('rec_head.sum_theoretical_taxable_cost:' ||rec_head.sum_theoretical_taxable_cost);
            INSERT INTO XX01_tax_dep_wk(
            tax_dep_wk_id
            ,sequence_id
            ,created_by
            ,creation_date
            ,last_updated_by
            ,last_update_date
            ,last_update_login
            ,request_id
            ,program_application_id
            ,program_id
            ,program_update_date
            ,book_type_code
            ,state
            ,state_desc
            ,year
            ,reciept_year
            ,reciept_month
            ,reciept_day
            ,present_name
            ,owner_code
            ,post_num
            ,owner_address1
            ,owner_address2
            ,owner_address_phonetic1
            ,owner_address_phonetic2
            ,owner_phone_num
            ,corporation_name
            ,corporation_phonetic
            ,representative
            ,representative_phonetic
            ,business
            ,capital
            ,business_open_date
            ,responser
            ,responser_name
            ,responser_phone_num
            ,consultant_name
            ,consultant_phone_num
            ,shorten_life_flag
            ,increase_deprn_flag
            ,taxfree_asset_flag
            ,tax_exception_flag
            ,special_deprn_flag
            ,tax_deprn_method
            ,blue_form_flag
            ,location1
            ,location2
            ,location3
            ,loc1_main_flag
            ,loc2_main_flag
            ,loc3_main_flag
            ,borrowed_flag
            ,officer_name
            ,office_address
            ,office_phone_num
            ,own_flag
            ,own_loc_num
            ,rent_flag
            ,rent_loc_num
            ,note1
            ,note2
            ,note3
            ,note4
            ,note5
            ,note6
            ,start_cost1
            ,decrease_cost1
            ,increase_cost1
            ,end_cost1
            ,start_cost2
            ,decrease_cost2
            ,increase_cost2
            ,end_cost2
            ,start_cost3
            ,decrease_cost3
            ,increase_cost3
            ,end_cost3
            ,start_cost4
            ,decrease_cost4
            ,increase_cost4
            ,end_cost4
            ,start_cost5
            ,decrease_cost5
            ,increase_cost5
            ,end_cost5
            ,start_cost6
            ,decrease_cost6
            ,increase_cost6
            ,end_cost6
            ,sum_start_cost
            ,sum_decrease_cost
            ,sum_increase_cost
            ,sum_end_cost
            ,theoretical_nbv1
            ,evaluated_nbv1
            ,decision_cost1
            ,taxable_cost1
--20020802 del
--            ,count1
            ,theoretical_nbv2
            ,evaluated_nbv2
            ,decision_cost2
            ,taxable_cost2
--20020802 del
--            ,count2
            ,theoretical_nbv3
            ,evaluated_nbv3
            ,decision_cost3
            ,taxable_cost3
--20020802 del
--            ,count3
            ,theoretical_nbv4
            ,evaluated_nbv4
            ,decision_cost4
            ,taxable_cost4
--20020802 del
--            ,count4
            ,theoretical_nbv5
            ,evaluated_nbv5
            ,decision_cost5
            ,taxable_cost5
--20020802 del
--            ,count5
            ,theoretical_nbv6
            ,evaluated_nbv6
            ,decision_cost6
            ,taxable_cost6
--20020802 del
--            ,count6
            ,sum_theoretical_nbv
            ,sum_evaluated_nbv
            ,sum_decision_cost
            ,sum_taxable_cost
--20020802 del
--            ,sum_count
            ,attribute_category
            ,attribute1
            ,attribute2
            ,attribute3
            ,attribute4
            ,attribute5
            ,attribute6
            ,attribute7
            ,attribute8
            ,attribute9
            ,attribute10
            ,attribute11
            ,attribute12
            ,attribute13
            ,attribute14
            ,attribute15
            )
            VALUES(
            n_sum_seq                   -- WK_SEQ
            ,in_sequence_id             -- SEQUENCE_ID
            ,gn_created_by              -- CREATED_BY
            ,gd_creation_date           -- CREATION_DATE
            ,gn_last_updated_by         -- LAST_UPDATED_BY
            ,gd_last_update_date        -- LAST_UPDATE_DATE
            ,gn_last_update_login       -- LAST_UPDATE_LOGIN
            ,gn_request_id              -- REQUEST_ID
            ,gn_program_application_id  -- PROGRAM_APPLICATION_ID
            ,gn_program_id              -- PROGRAM_ID
            ,gd_program_update_date     -- PROGRAM_UPDATE_DATE
            ,rec_head.book_type_code    -- BOOK_TYPE_CODE
            ,rec_head.state             -- STATE
            ,v_description
            ,v_year                     -- YEAR
            ,v_reciept_year             -- RECIEPT_YEAR
            ,v_reciept_month            -- RECIEPT_MONTH
            ,v_reciept_day              -- RECIEPT_DAY
            ,rec_info.present_name      -- PRESENT_NAME
            ,rec_info.owner_code        -- OWNER_CODE
            ,rec_info.post_num          -- POST_NUM
            ,rec_info.owner_address1    -- OWNER_ADDRESS1
            ,rec_info.owner_address2    -- OWNER_ADDRESS2
            ,rec_info.owner_address_phonetic1 -- OWNER_ADDRESS_PHONETIC1
            ,rec_info.owner_address_phonetic2 -- OWNER_ADDRESS_PHONETIC2
            ,rec_info.owner_phone_num         -- OWNER_PHONE_NUM
            ,rec_info.corporation_name  -- CORPORATION_NAME
            ,rec_info.corporation_phonetic    -- CORPORATION_PHONETIC
            ,rec_info.representative    -- REPRESENTATIVE
            ,rec_info.representative_phonetic -- REPRESENTATIVE_PHONETIC
            ,rec_info.business          -- BUSINESS
            ,rec_info.capital           -- CAPITAL
            ,rec_info.business_open_date  -- BUSINESS_OPEN_DATE
            ,rec_info.responser         -- RESPONSER
            ,rec_info.responser_name    -- RESPONSER_NAME
            ,rec_info.responser_phone_num -- RESPONSER_PHONE_NUM
            ,rec_info.consultant_name   -- CONSULTANT_NAME
            ,rec_info.consultant_phone_num  -- CONSULTANT_PHONE_NUM
            ,DECODE(rec_info.shorten_life_flag,cv_yes,v_yes_code,cv_no,v_no_code,'')    -- SHORTEN_LIFE_FLAG
            ,DECODE(rec_info.increase_deprn_flag,cv_yes,v_yes_code,cv_no,v_no_code,'')  -- INCREASE_DEPRN_FLAG
            ,DECODE(rec_info.taxfree_asset_flag,cv_yes,v_yes_code,cv_no,v_no_code,'')   -- TAXFREE_ASSET_FLAG
            ,DECODE(rec_info.tax_exception_flag,cv_yes,v_yes_code,cv_no,v_no_code,'')   -- TAX_EXCEPTION_FLAG
            ,DECODE(rec_info.special_deprn_flag,cv_yes,v_yes_code,cv_no,v_no_code,'')   -- SPECIAL_DEPRN_FLAG
            ,DECODE(rec_info.tax_deprn_method,cv_db,v_db_code,cv_stl,v_stl_code,cv_both,v_both_code,'') -- TAX_DEPRN_METHOD
            ,DECODE(rec_info.blue_form_flag,cv_yes,v_yes_code,cv_no,v_no_code,'')     -- BLUE_FORM_FLAG
            ,rec_info.LOCATION1               -- LOCATION1
            ,rec_info.LOCATION2               -- LOCATION2
            ,rec_info.LOCATION3               -- LOCATION3
            ,DECODE(rec_info.main_loc_num,1,cv_circle,'')-- LOC1_MAIN_FLAG
            ,DECODE(rec_info.main_loc_num,2,cv_circle,'')-- LOC2_MAIN_FLAG
            ,DECODE(rec_info.main_loc_num,3,cv_circle,'')-- LOC3_MAIN_FLAG
            ,DECODE(rec_info.borrowed_flag,cv_yes,v_yes_code,cv_no,v_no_code,'') -- BORROWED_FLAG
            ,rec_info.OFFICER_NAME            -- OFFICER_NAME
            ,rec_info.OFFICER_ADDRESS         -- OFFICER_ADDRESS
            ,rec_info.OFFICER_PHONE_NUM       -- OFFICER_PHONE_NUM
            ,DECODE(rec_info.own_flag,cv_yes,v_yes_code,cv_no,v_no_code,'') -- OWN_FLAG
            ,rec_info.OWN_LOC_NUM             -- OWN_LOC_NUM
            ,DECODE(rec_info.rent_flag,cv_yes,v_yes_code,cv_no,v_no_code,'')                    -- RENT_FLAG
            ,rec_info.RENT_LOC_NUM            -- RENT_LOC_NUM
            ,rec_info.NOTE1                   -- NOTE1
            ,rec_info.NOTE2                   -- NOTE2
            ,rec_info.NOTE3                   -- NOTE3
            ,rec_info.NOTE4                   -- NOTE4
            ,rec_info.NOTE5                   -- NOTE5
            ,rec_info.NOTE6                   -- NOTE6
            ,DECODE(rec_head.tax_asset_type,'1',rec_head.sum_start_cost,0)    -- START_COST1
            ,DECODE(rec_head.tax_asset_type,'1',rec_head.sum_decrease_cost,0) -- DECREASE_COST1
            ,DECODE(rec_head.tax_asset_type,'1',rec_head.sum_increase_cost,0) -- INCREASE_COST1
            ,DECODE(rec_head.tax_asset_type,'1',rec_head.sum_end_cost,0)      -- END_COST1
            ,DECODE(rec_head.tax_asset_type,'2',rec_head.sum_start_cost,0)    -- START_COST2
            ,DECODE(rec_head.tax_asset_type,'2',rec_head.sum_decrease_cost,0) -- DECREASE_COST2
            ,DECODE(rec_head.tax_asset_type,'2',rec_head.sum_increase_cost,0) -- INCREASE_COST2
            ,DECODE(rec_head.tax_asset_type,'2',rec_head.sum_end_cost,0)      -- END_COST2
            ,DECODE(rec_head.tax_asset_type,'3',rec_head.sum_start_cost,0)    -- START_COST3
            ,DECODE(rec_head.tax_asset_type,'3',rec_head.sum_decrease_cost,0) -- DECREASE_COST3
            ,DECODE(rec_head.tax_asset_type,'3',rec_head.sum_increase_cost,0) -- INCREASE_COST3
            ,DECODE(rec_head.tax_asset_type,'3',rec_head.sum_end_cost,0)      -- END_COST3
            ,DECODE(rec_head.tax_asset_type,'4',rec_head.sum_start_cost,0)    -- START_COST4
            ,DECODE(rec_head.tax_asset_type,'4',rec_head.sum_decrease_cost,0) -- DECREASE_COST4
            ,DECODE(rec_head.tax_asset_type,'4',rec_head.sum_increase_cost,0) -- INCREASE_COST4
            ,DECODE(rec_head.tax_asset_type,'4',rec_head.sum_end_cost,0)      -- END_COST4
            ,DECODE(rec_head.tax_asset_type,'5',rec_head.sum_start_cost,0)    -- START_COST5
            ,DECODE(rec_head.tax_asset_type,'5',rec_head.sum_decrease_cost,0) -- DECREASE_COST5
            ,DECODE(rec_head.tax_asset_type,'5',rec_head.sum_increase_cost,0) -- INCREASE_COST5
            ,DECODE(rec_head.tax_asset_type,'5',rec_head.sum_end_cost,0)      -- END_COST5
            ,DECODE(rec_head.tax_asset_type,'6',rec_head.sum_start_cost,0)    -- START_COST6
            ,DECODE(rec_head.tax_asset_type,'6',rec_head.sum_decrease_cost,0) -- DECREASE_COST6
            ,DECODE(rec_head.tax_asset_type,'6',rec_head.sum_increase_cost,0) -- INCREASE_COST6
            ,DECODE(rec_head.tax_asset_type,'6',rec_head.sum_end_cost,0)      -- END_COST6
            ,NVL(rec_head.sum_start_cost,0)                                   -- SUM_START_COST
            ,NVL(rec_head.sum_decrease_cost,0)                                -- SUM_DECREASE_COST
            ,NVL(rec_head.sum_increase_cost,0)                                -- SUM_INCREASE_COST
            ,NVL(rec_head.sum_end_cost,0)                                     -- SUM_END_COST
            ,DECODE(rec_head.tax_asset_type,'1',rec_head.sum_theoretical_nbv,0)   -- THEORETICAL_NBV1
            ,DECODE(rec_head.tax_asset_type,'1',rec_head.sum_evaluated_nbv,0) -- EVALUATED_NBV1
            ,DECODE(rec_head.tax_asset_type,'1',DECODE(v_decision,'THEORETICAL',rec_head.sum_theoretical_nbv,'EVALUATED',rec_head.sum_evaluated_nbv,0),0) -- DECISION_COST1
            ,DECODE(rec_head.tax_asset_type,'1',DECODE(v_decision,'THEORETICAL',rec_head.sum_theoretical_taxable_cost,'EVALUATED',rec_head.sum_evaluated_taxable_cost,0),0) -- TAXABLE_COST1
--20020802 del
--            ,DECODE(rec_head.tax_asset_type,'1',rec_head.sum_count,0)         -- COUNT1
            ,DECODE(rec_head.tax_asset_type,'2',rec_head.sum_theoretical_nbv,0)   -- THEORETICAL_NBV2
            ,DECODE(rec_head.tax_asset_type,'2',rec_head.sum_evaluated_nbv,0) -- EVALUATED_NBV2
            ,DECODE(rec_head.tax_asset_type,'2',DECODE(v_decision,'THEORETICAL',rec_head.sum_theoretical_nbv,'EVALUATED',rec_head.sum_evaluated_nbv,0),0) -- DECISION_COST2
            ,DECODE(rec_head.tax_asset_type,'2',DECODE(v_decision,'THEORETICAL',rec_head.sum_theoretical_taxable_cost,'EVALUATED',rec_head.sum_evaluated_taxable_cost,0),0) -- TAXABLE_COST1
--20020802 del
--            ,DECODE(rec_head.tax_asset_type,'2',rec_head.sum_count,0)         -- COUNT2
            ,DECODE(rec_head.tax_asset_type,'3',rec_head.sum_theoretical_nbv,0)   -- THEORETICAL_NBV3
            ,DECODE(rec_head.tax_asset_type,'3',rec_head.sum_evaluated_nbv,0) -- EVALUATED_NBV3
            ,DECODE(rec_head.tax_asset_type,'3',DECODE(v_decision,'THEORETICAL',rec_head.sum_theoretical_nbv,'EVALUATED',rec_head.sum_evaluated_nbv,0),0) -- DECISION_COST3
            ,DECODE(rec_head.tax_asset_type,'3',DECODE(v_decision,'THEORETICAL',rec_head.sum_theoretical_taxable_cost,'EVALUATED',rec_head.sum_evaluated_taxable_cost,0),0) -- TAXABLE_COST1
--20020802 del
--            ,DECODE(rec_head.tax_asset_type,'3',rec_head.sum_count,0)         -- COUNT3
            ,DECODE(rec_head.tax_asset_type,'4',rec_head.sum_theoretical_nbv,0)   -- THEORETICAL_NBV4
            ,DECODE(rec_head.tax_asset_type,'4',rec_head.sum_evaluated_nbv,0) -- EVALUATED_NBV4
            ,DECODE(rec_head.tax_asset_type,'4',DECODE(v_decision,'THEORETICAL',rec_head.sum_theoretical_nbv,'EVALUATED',rec_head.sum_evaluated_nbv,0),0) -- DECISION_COST4
            ,DECODE(rec_head.tax_asset_type,'4',DECODE(v_decision,'THEORETICAL',rec_head.sum_theoretical_taxable_cost,'EVALUATED',rec_head.sum_evaluated_taxable_cost,0),0) -- TAXABLE_COST1
--20020802 del
--            ,DECODE(rec_head.tax_asset_type,'4',rec_head.sum_count,0)         -- COUNT4
            ,DECODE(rec_head.tax_asset_type,'5',rec_head.sum_theoretical_nbv,0)   -- THEORETICAL_NBV5
            ,DECODE(rec_head.tax_asset_type,'5',rec_head.sum_evaluated_nbv,0) -- EVALUATED_NBV5
            ,DECODE(rec_head.tax_asset_type,'5',DECODE(v_decision,'THEORETICAL',rec_head.sum_theoretical_nbv,'EVALUATED',rec_head.sum_evaluated_nbv,0),0) -- DECISION_COST5
            ,DECODE(rec_head.tax_asset_type,'5',DECODE(v_decision,'THEORETICAL',rec_head.sum_theoretical_taxable_cost,'EVALUATED',rec_head.sum_evaluated_taxable_cost,0),0) -- TAXABLE_COST1
--20020802 del
--            ,DECODE(rec_head.tax_asset_type,'5',rec_head.sum_count,0)         -- COUNT5
            ,DECODE(rec_head.tax_asset_type,'6',rec_head.sum_theoretical_nbv,0)   -- THEORETICAL_NBV6
            ,DECODE(rec_head.tax_asset_type,'6',rec_head.sum_evaluated_nbv,0) -- EVALUATED_NBV6
            ,DECODE(rec_head.tax_asset_type,'6',DECODE(v_decision,'THEORETICAL',rec_head.sum_theoretical_nbv,'EVALUATED',rec_head.sum_evaluated_nbv,0),0) -- DECISION_COST6
            ,DECODE(rec_head.tax_asset_type,'6',DECODE(v_decision,'THEORETICAL',rec_head.sum_theoretical_taxable_cost,'EVALUATED',rec_head.sum_evaluated_taxable_cost,0),0) -- TAXABLE_COST1
--20020802 del
--            ,DECODE(rec_head.tax_asset_type,'6',rec_head.sum_count,0)         -- COUNT6
            ,NVL(rec_head.sum_theoretical_nbv,0)                          -- SUM_THEORETICAL_NBV
            ,NVL(rec_head.sum_evaluated_nbv,0)                            -- SUM_EVALUATED_NBV
            ,DECODE(v_decision,'THEORETICAL',rec_head.sum_theoretical_nbv,'EVALUATED',rec_head.sum_evaluated_nbv,0)                           -- SUM_DECISION_COST
            ,DECODE(v_decision,'THEORETICAL',rec_head.sum_theoretical_taxable_cost,'EVALUATED',rec_head.sum_evaluated_taxable_cost,0)                                 -- SUM_TAXABLE_COST
--20020802 del
--            ,NVL(rec_head.sum_count,0)                                    -- SUM_COUNT
            ,rec_info.ATTRIBUTE_CATEGORY
            ,rec_info.ATTRIBUTE1
            ,rec_info.ATTRIBUTE2
            ,rec_info.ATTRIBUTE3
            ,rec_info.ATTRIBUTE4
            ,rec_info.ATTRIBUTE5
            ,rec_info.ATTRIBUTE6
            ,rec_info.ATTRIBUTE7
            ,rec_info.ATTRIBUTE8
            ,rec_info.ATTRIBUTE9
            ,rec_info.ATTRIBUTE10
            ,rec_info.ATTRIBUTE11
            ,rec_info.ATTRIBUTE12
            ,rec_info.ATTRIBUTE13
            ,rec_info.ATTRIBUTE14
            ,rec_info.ATTRIBUTE15
            ) ;
          EXCEPTION
            WHEN OTHERS THEN
              -- その他ｴﾗｰ
              v_errbuf := xx01_conc_util_pkg.get_message_others( '償却資産申告書ワークテーブル設定' ) ;
              n_retcode := 2 ;
              RAISE SUB_EXPT ;
          END ;
        ELSE
          BEGIN
          fa_rx_util_pkg.debug('UPDATE START XX01_tax_dep_wk');
--
            fa_rx_util_pkg.debug('rec_head.tax_asset_type:' ||rec_head.tax_asset_type);
            fa_rx_util_pkg.debug('rec_head.sum_start_cost:' ||rec_head.sum_start_cost);
            fa_rx_util_pkg.debug('in_sequence_id:' ||in_sequence_id);
            fa_rx_util_pkg.debug('n_sum_seq:' ||n_sum_seq);
--
            UPDATE XX01_tax_dep_wk
            SET start_cost1       = DECODE(rec_head.tax_asset_type,'1',rec_head.sum_start_cost,start_cost1)           -- START_COST1
            ,decrease_cost1       = DECODE(rec_head.tax_asset_type,'1',rec_head.sum_decrease_cost,decrease_cost1)     -- DECREASE_COST1
            ,increase_cost1       = DECODE(rec_head.tax_asset_type,'1',rec_head.sum_increase_cost,increase_cost1)     -- INCREASE_COST1
            ,end_cost1            = DECODE(rec_head.tax_asset_type,'1',rec_head.sum_end_cost,end_cost1)               -- END_COST1
            ,start_cost2          = DECODE(rec_head.tax_asset_type,'2',rec_head.sum_start_cost,start_cost2)           -- START_COST2
            ,decrease_cost2       = DECODE(rec_head.tax_asset_type,'2',rec_head.sum_decrease_cost,decrease_cost2)     -- DECREASE_COST2
            ,increase_cost2       = DECODE(rec_head.tax_asset_type,'2',rec_head.sum_increase_cost,increase_cost2)     -- INCREASE_COST2
            ,end_cost2            = DECODE(rec_head.tax_asset_type,'2',rec_head.sum_end_cost,end_cost2)               -- END_COST2
            ,start_cost3          = DECODE(rec_head.tax_asset_type,'3',rec_head.sum_start_cost,start_cost3)           -- START_COST3
            ,decrease_cost3       = DECODE(rec_head.tax_asset_type,'3',rec_head.sum_decrease_cost,decrease_cost3)     -- DECREASE_COST3
            ,increase_cost3       = DECODE(rec_head.tax_asset_type,'3',rec_head.sum_increase_cost,increase_cost3)     -- INCREASE_COST3
            ,end_cost3            = DECODE(rec_head.tax_asset_type,'3',rec_head.sum_end_cost,end_cost3)               -- END_COST3
            ,start_cost4          = DECODE(rec_head.tax_asset_type,'4',rec_head.sum_start_cost,start_cost4)           -- START_COST4
            ,decrease_cost4       = DECODE(rec_head.tax_asset_type,'4',rec_head.sum_decrease_cost,decrease_cost4)     -- DECREASE_COST4
            ,increase_cost4       = DECODE(rec_head.tax_asset_type,'4',rec_head.sum_increase_cost,increase_cost4)     -- INCREASE_COST4
            ,end_cost4            = DECODE(rec_head.tax_asset_type,'4',rec_head.sum_end_cost,end_cost4)               -- END_COST4
            ,start_cost5          = DECODE(rec_head.tax_asset_type,'5',rec_head.sum_start_cost,start_cost5)           -- START_COST5
            ,decrease_cost5       = DECODE(rec_head.tax_asset_type,'5',rec_head.sum_decrease_cost,decrease_cost5)     -- DECREASE_COST5
            ,increase_cost5       = DECODE(rec_head.tax_asset_type,'5',rec_head.sum_increase_cost,increase_cost5)     -- INCREASE_COST5
            ,end_cost5            = DECODE(rec_head.tax_asset_type,'5',rec_head.sum_end_cost,end_cost5)               -- END_COST5
            ,start_cost6          = DECODE(rec_head.tax_asset_type,'6',rec_head.sum_start_cost,start_cost6)           -- START_COST6
            ,decrease_cost6       = DECODE(rec_head.tax_asset_type,'6',rec_head.sum_decrease_cost,decrease_cost6)     -- DECREASE_COST6
            ,increase_cost6       = DECODE(rec_head.tax_asset_type,'6',rec_head.sum_increase_cost,increase_cost6)     -- INCREASE_COST6
            ,end_cost6            = DECODE(rec_head.tax_asset_type,'6',rec_head.sum_end_cost,end_cost6)               -- END_COST6
            ,sum_start_cost       = sum_start_cost + NVL(rec_head.sum_start_cost,0)                                   -- SUM_START_COST
            ,sum_decrease_cost    = sum_decrease_cost + NVL(rec_head.sum_decrease_cost,0)                             -- SUM_DECREASE_COST
            ,sum_increase_cost    = sum_increase_cost + NVL(rec_head.sum_increase_cost,0)                             -- SUM_INCREASE_COST
            ,sum_end_cost         = sum_end_cost + NVL(rec_head.sum_end_cost,0)                                       -- SUM_END_COST
            ,theoretical_nbv1     = DECODE(rec_head.tax_asset_type,'1',rec_head.sum_theoretical_nbv,theoretical_nbv1) -- THEORETICAL_NBV1
            ,evaluated_nbv1       = DECODE(rec_head.tax_asset_type,'1',rec_head.sum_evaluated_nbv,evaluated_nbv1)     -- EVALUATED_NBV1
            ,decision_cost1       = DECODE(rec_head.tax_asset_type,'1',DECODE(v_decision,'THEORETICAL',rec_head.sum_theoretical_nbv,'EVALUATED',rec_head.sum_evaluated_nbv,0),decision_cost1)     -- DECISION_COST1
            ,taxable_cost1        = DECODE(rec_head.tax_asset_type,'1',DECODE(v_decision,'THEORETICAL',rec_head.sum_theoretical_taxable_cost,'EVALUATED',rec_head.sum_evaluated_taxable_cost,0),taxable_cost1)        -- TAXABLE_COST1
--20020802 del
--            ,count1               = DECODE(rec_head.tax_asset_type,'1',rec_head.sum_count,count1)                     -- COUNT1
            ,theoretical_nbv2     = DECODE(rec_head.tax_asset_type,'2',rec_head.sum_theoretical_nbv,theoretical_nbv2) -- THEORETICAL_NBV2
            ,evaluated_nbv2       = DECODE(rec_head.tax_asset_type,'2',rec_head.sum_evaluated_nbv,evaluated_nbv2)     -- EVALUATED_NBV2
            ,decision_cost2       = DECODE(rec_head.tax_asset_type,'2',DECODE(v_decision,'THEORETICAL',rec_head.sum_theoretical_nbv,'EVALUATED',rec_head.sum_evaluated_nbv,0),decision_cost2)     -- DECISION_COST2
            ,taxable_cost2        = DECODE(rec_head.tax_asset_type,'2',DECODE(v_decision,'THEORETICAL',rec_head.sum_theoretical_taxable_cost,'EVALUATED',rec_head.sum_evaluated_taxable_cost,0),taxable_cost2)        -- TAXABLE_COST2
--20020802 del
--            ,count2               = DECODE(rec_head.tax_asset_type,'2',rec_head.sum_count,count2)                     -- COUNT2
            ,theoretical_nbv3     = DECODE(rec_head.tax_asset_type,'3',rec_head.sum_theoretical_nbv,theoretical_nbv3) -- THEORETICAL_NBV3
            ,evaluated_nbv3       = DECODE(rec_head.tax_asset_type,'3',rec_head.sum_evaluated_nbv,evaluated_nbv3)     -- EVALUATED_NBV3
            ,decision_cost3       = DECODE(rec_head.tax_asset_type,'3',DECODE(v_decision,'THEORETICAL',rec_head.sum_theoretical_nbv,'EVALUATED',rec_head.sum_evaluated_nbv,0),decision_cost3)     -- DECISION_COST3
            ,taxable_cost3        = DECODE(rec_head.tax_asset_type,'3',DECODE(v_decision,'THEORETICAL',rec_head.sum_theoretical_taxable_cost,'EVALUATED',rec_head.sum_evaluated_taxable_cost,0),taxable_cost3)        -- TAXABLE_COST3
--20020802 del
--            ,count3               = DECODE(rec_head.tax_asset_type,'3',rec_head.sum_count,count3)                     -- COUNT3
            ,theoretical_nbv4     = DECODE(rec_head.tax_asset_type,'4',rec_head.sum_theoretical_nbv,theoretical_nbv4) -- THEORETICAL_NBV4
            ,evaluated_nbv4       = DECODE(rec_head.tax_asset_type,'4',rec_head.sum_evaluated_nbv,evaluated_nbv4)     -- EVALUATED_NBV4
            ,decision_cost4       = DECODE(rec_head.tax_asset_type,'4',DECODE(v_decision,'THEORETICAL',rec_head.sum_theoretical_nbv,'EVALUATED',rec_head.sum_evaluated_nbv,0),decision_cost4)     -- DECISION_COST4
            ,taxable_cost4        = DECODE(rec_head.tax_asset_type,'4',DECODE(v_decision,'THEORETICAL',rec_head.sum_theoretical_taxable_cost,'EVALUATED',rec_head.sum_evaluated_taxable_cost,0),taxable_cost4)        -- TAXABLE_COST4
--20020802 del
--            ,count4               = DECODE(rec_head.tax_asset_type,'4',rec_head.sum_count,count4)                     -- COUNT4
            ,theoretical_nbv5     = DECODE(rec_head.tax_asset_type,'5',rec_head.sum_theoretical_nbv,theoretical_nbv5) -- THEORETICAL_NBV5
            ,evaluated_nbv5       = DECODE(rec_head.tax_asset_type,'5',rec_head.sum_evaluated_nbv,evaluated_nbv5)     -- EVALUATED_NBV5
            ,decision_cost5       = DECODE(rec_head.tax_asset_type,'5',DECODE(v_decision,'THEORETICAL',rec_head.sum_theoretical_nbv,'EVALUATED',rec_head.sum_evaluated_nbv,0),decision_cost5)     -- DECISION_COST5
            ,taxable_cost5        = DECODE(rec_head.tax_asset_type,'5',DECODE(v_decision,'THEORETICAL',rec_head.sum_theoretical_taxable_cost,'EVALUATED',rec_head.sum_evaluated_taxable_cost,0),taxable_cost5)        -- TAXABLE_COST5
--20020802 del
--            ,count5               = DECODE(rec_head.tax_asset_type,'5',rec_head.sum_count,count5)                     -- COUNT5
            ,theoretical_nbv6     = DECODE(rec_head.tax_asset_type,'6',rec_head.sum_theoretical_nbv,theoretical_nbv6) -- THEORETICAL_NBV6
            ,evaluated_nbv6       = DECODE(rec_head.tax_asset_type,'6',rec_head.sum_evaluated_nbv,evaluated_nbv6)     -- EVALUATED_NBV6
            ,decision_cost6       = DECODE(rec_head.tax_asset_type,'6',DECODE(v_decision,'THEORETICAL',rec_head.sum_theoretical_nbv,'EVALUATED',rec_head.sum_evaluated_nbv,0),decision_cost6)     -- DECISION_COST6
            ,taxable_cost6        = DECODE(rec_head.tax_asset_type,'6',DECODE(v_decision,'THEORETICAL',rec_head.sum_theoretical_taxable_cost,'EVALUATED',rec_head.sum_evaluated_taxable_cost,0),taxable_cost6)        -- TAXABLE_COST6
--20020802 del
--            ,count6               = DECODE(rec_head.tax_asset_type,'6',rec_head.sum_count,count6)                     -- COUNT6
            ,sum_theoretical_nbv  = sum_theoretical_nbv + NVL(rec_head.sum_theoretical_nbv,0)                         -- SUM_THEORETICAL_NBV
            ,sum_evaluated_nbv    = sum_evaluated_nbv + NVL(rec_head.sum_evaluated_nbv,0)                             -- SUM_EVALUATED_NBV
            ,sum_decision_cost    = sum_decision_cost + DECODE(v_decision,'THEORETICAL',rec_head.sum_theoretical_nbv,'EVALUATED',rec_head.sum_evaluated_nbv,0)                              -- SUM_DECISION_COST
            ,sum_taxable_cost     = sum_taxable_cost + DECODE(v_decision,'THEORETICAL',rec_head.sum_theoretical_taxable_cost,'EVALUATED',rec_head.sum_evaluated_taxable_cost,0)                                   -- SUM_TAXABLE_COST
--20020802 del
--            ,sum_count            = sum_count + NVL(rec_head.sum_count,0)                                             -- SUM_COUNT
            WHERE tax_dep_wk_id = n_sum_seq
            AND   sequence_id = in_sequence_id
            ;
          EXCEPTION
            WHEN OTHERS THEN
              -- その他ｴﾗｰ
              v_errbuf := xx01_conc_util_pkg.get_message_others( '償却資産申告書ワークテーブル設定' ) ;
              n_retcode := 2 ;
              RAISE SUB_EXPT ;
          END ;
        END IF;

--20020802 add
      SELECT                                           --20020802 add
        count(dti.asset_id)                            --20020802 add
      INTO                                             --20020802 add
        n_count1                                       --20020802 add
      FROM  fa_deprn_tax_rep_itf dti                   --20020802 add
      WHERE dti.request_id = in_req_id                 --20020802 add
      AND   dti.tax_asset_type = '1'                   --20020802 add
      AND   dti.state = rec_head.state                 --20020802 add
      AND   (dec_type IS NULL OR dec_type <> 1);       --20020802 add

      SELECT                                           --20020802 add
        count(dti.asset_id)                            --20020802 add
      INTO                                             --20020802 add
        n_count2                                       --20020802 add
      FROM  fa_deprn_tax_rep_itf dti                   --20020802 add
      WHERE dti.request_id = in_req_id                 --20020802 add
      AND   dti.tax_asset_type = '2'                   --20020802 add
      AND   dti.state = rec_head.state                 --20020802 add
      AND   (dec_type IS NULL OR dec_type <> 1);       --20020802 add

      SELECT                                           --20020802 add
        count(dti.asset_id)                            --20020802 add
      INTO                                             --20020802 add
        n_count3                                       --20020802 add
      FROM  fa_deprn_tax_rep_itf dti                   --20020802 add
      WHERE dti.request_id = in_req_id                 --20020802 add
      AND   dti.tax_asset_type = '3'                   --20020802 add
      AND   dti.state = rec_head.state                 --20020802 add
      AND   (dec_type IS NULL OR dec_type <> 1);       --20020802 add

      SELECT                                           --20020802 add
        count(dti.asset_id)                            --20020802 add
      INTO                                             --20020802 add
        n_count4                                       --20020802 add
      FROM  fa_deprn_tax_rep_itf dti                   --20020802 add
      WHERE dti.request_id = in_req_id                 --20020802 add
      AND   dti.tax_asset_type = '4'                   --20020802 add
      AND   dti.state = rec_head.state                 --20020802 add
      AND   (dec_type IS NULL OR dec_type <> 1);       --20020802 add

      SELECT                                           --20020802 add
        count(dti.asset_id)                            --20020802 add
      INTO                                             --20020802 add
        n_count5                                       --20020802 add
      FROM  fa_deprn_tax_rep_itf dti                   --20020802 add
      WHERE dti.request_id = in_req_id                 --20020802 add
      AND   dti.tax_asset_type = '5'                   --20020802 add
      AND   dti.state = rec_head.state                 --20020802 add
      AND   (dec_type IS NULL OR dec_type <> 1);       --20020802 add

      SELECT                                           --20020802 add
        count(dti.asset_id)                            --20020802 add
      INTO                                             --20020802 add
        n_count6                                       --20020802 add
      FROM  fa_deprn_tax_rep_itf dti                   --20020802 add
      WHERE dti.request_id = in_req_id                 --20020802 add
      AND   dti.tax_asset_type = '6'                   --20020802 add
      AND   dti.state = rec_head.state                 --20020802 add
      AND   (dec_type IS NULL OR dec_type <> 1);       --20020802 add

    n_sum_count := NVL(n_count1,0) + NVL(n_count2,0) + NVL(n_count3,0) +    --20020802 add
                    NVL(n_count4,0) + NVL(n_count5,0) + NVL(n_count6,0);    --20020802 add

    UPDATE XX01_tax_dep_wk                             --20020802 add
    SET count1        = NVL(n_count1,0)                --20020802 add
        ,count2       = NVL(n_count2,0)                --20020802 add
        ,count3       = NVL(n_count3,0)                --20020802 add
        ,count4       = NVL(n_count4,0)                --20020802 add
        ,count5       = NVL(n_count5,0)                --20020802 add
        ,count6       = NVL(n_count6,0)                --20020802 add
        ,sum_count    = n_sum_count                    --20020802 add
    WHERE tax_dep_wk_id = n_sum_seq                    --20020802 add
    AND   sequence_id = in_sequence_id;                --20020802 add


        v_state_old2 := rec_head.state ;
        fa_rx_util_pkg.debug('v_state_old2:' ||v_state_old2);
      END LOOP ;

    END IF;
--
          xx01_conc_util_pkg.conc_log_line ;
          xx01_conc_util_pkg.conc_log_put( '償却資産申告書ワークテーブルデータ作成件数        ：'||TO_CHAR(n_wk_sum_seq,'9,999,990')  ) ;
          xx01_conc_util_pkg.conc_log_put( '種類別明細書（全資産用）ワークテーブルデータ作成件数        ：'||TO_CHAR(n_wk_all_seq,'9,999,990')  ) ;
          xx01_conc_util_pkg.conc_log_put( '種類別明細書（増加資産用）ワークテーブルデータ作成件数      ：'||TO_CHAR(n_wk_add_seq,'9,999,990')  ) ;
          xx01_conc_util_pkg.conc_log_put( '種類別明細書（減少資産用）ワークテーブルデータ作成件数      ：'||TO_CHAR(n_wk_dec_seq,'9,999,990')  ) ;
          xx01_conc_util_pkg.conc_log_line ;
          xx01_conc_util_pkg.conc_log_put( 'シーケンスID                        ：'||TO_CHAR(in_sequence_id)) ;
          xx01_conc_util_pkg.conc_log_put( 'リクエストID                        ：'||TO_CHAR(in_request_id)) ;
          xx01_conc_util_pkg.conc_log_line ;
          XX01_conc_util_pkg.conc_log_end(fnd_global.conc_request_id) ;
--
EXCEPTION
  WHEN SUB_EXPT THEN
    IF cur_nbv%ISOPEN THEN
      CLOSE cur_nbv ;
    END IF ;
--
    IF cur_cominfo%ISOPEN THEN
      CLOSE cur_cominfo ;
    END IF ;
--
    ROLLBACK ;
    errbuf  := v_errbuf ;
    retcode := n_retcode ;
    IF errbuf IS NULL THEN
      errbuf  := v_procname||'でユーザー定義例外が発生しました。' ;
    END IF ;
    IF retcode IS NULL OR retcode = 0 THEN
      retcode := 2 ;
    END IF ;
    RETURN ;
--
  WHEN OTHERS THEN
    IF cur_nbv%ISOPEN THEN
      CLOSE cur_nbv ;
    END IF ;
--
    IF cur_cominfo%ISOPEN THEN
      CLOSE cur_cominfo ;
    END IF ;
--
    ROLLBACK ;
    errbuf  := xx01_conc_util_pkg.get_message_others( v_procname ) ;
    retcode := 2 ;
    RETURN ;
END fadptx_insert ;

END XX01_deprn_tax_rep_pkg;
/
