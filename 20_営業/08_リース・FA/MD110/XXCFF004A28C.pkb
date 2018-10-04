create or replace
PACKAGE BODY XXCFF004A28C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFF004A28C(body)
 * Description      : 営業システム構築プロジェクト
 * MD.050           : 再リース要否ダウンロード 004_A28
 * Version          : 1.3
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  para_check             p パラメータチェック処理                  (A-2)
 *  csv_buf                p CSV編集処理                             (A-4)
 *  csv_header             p CSVヘッダー作成
 *  submain                p メイン処理プロシージャ
 *  main                   p コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/05    1.0   SCS大井 信幸     新規作成
 *  2009/02/09    1.1   SCS大井 信幸     ログ出力項目追加
 *  2009/08/11    1.2   SCS萱原 伸哉     統合テスト障害0000994対応
 *  2018/09/18    1.3   SCSK佐々木大和   E_本稼動_14830のため
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --正常:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --警告:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --異常:2
--
  cv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont      CONSTANT VARCHAR2(3) := '.';
--
--################################  固定部 END   ##################################
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  gv_out_msg       VARCHAR2(2000);
  gv_sep_msg       VARCHAR2(2000);
  gv_exec_user     VARCHAR2(100);
  gv_conc_name     VARCHAR2(30);
  gv_conc_status   VARCHAR2(30);
  gn_target_cnt    NUMBER;                    -- 対象件数
  gn_normal_cnt    NUMBER;                    -- 正常件数
  gn_error_cnt     NUMBER;                    -- エラー件数
  gn_warn_cnt      NUMBER;                    -- スキップ件数
  gv_process_date  VARCHAR2(30);              --文字型業務日付
--
--################################  固定部 END   ##################################
--
--##########################  固定共通例外宣言部 START  ###########################
--
  --*** 処理部共通例外 ***
  global_process_expt       EXCEPTION;
  --*** 共通関数例外 ***
  global_api_expt           EXCEPTION;
  --*** 共通関数OTHERS例外 ***
  global_api_others_expt    EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--################################  固定部 END   ##################################
---- ===============================
  -- ユーザー定義例外
  -- ===============================
--  <exception_name>          EXCEPTION;     -- <例外のコメント>
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name        CONSTANT VARCHAR2(100) := 'XXCFF004A28C';      -- パッケージ名
  cv_log             CONSTANT VARCHAR2(100) := 'LOG';               -- コンカレントログ出力先--
--
  cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCFF';             -- アドオン：会計・リース・FA領域
  cv_appl_name_cmn   CONSTANT VARCHAR2(10)  := 'XXCCP';             -- アドオン：共通・IF領域
  cv_para_err_msg    CONSTANT VARCHAR2(100) := 'APP-XXCFF1-00003';  -- パラメータ逆転エラーメッセージ
  cv_no_data_msg     CONSTANT VARCHAR2(100) := 'APP-XXCFF1-00062';  -- 対象なし警告メッセージ
--
  cv_para_from_tkn   CONSTANT VARCHAR2(100)  := 'FROM';             -- パラメータFROMトークン
  cv_para_to_tkn     CONSTANT VARCHAR2(100)  := 'TO';               -- パラメータTOトークン
  cv_csv_delim       CONSTANT VARCHAR2(3)    := ',';                -- CSV区切り文字
  cv_look_type       CONSTANT VARCHAR2(100)  := 'XXCFF1_RE_LEASE_CSV_HEADER'; -- LOOKUP TYPE
  cv_date_format     CONSTANT VARCHAR2(100)  := 'YYYY/MM/DD';       -- 日付フォーマット
  cv_money_format    CONSTANT VARCHAR2(100)  := 'FM999,999,990';    -- 金額フォーマット
  cv_obj_status_102  CONSTANT VARCHAR2(100)  := '102';              -- 契約済
  cv_obj_status_104  CONSTANT VARCHAR2(100)  := '104';              -- 再リース契約済
  cv_obj_status_108  CONSTANT VARCHAR2(100)  := '108';              -- 解約申請
  cv_class_min       CONSTANT VARCHAR2(100)  := '00';               -- リース種別最小値
-- 1.3 2018/09/18 Modified START
--cv_class_max       CONSTANT VARCHAR2(100)  := '99';               -- リース種別最大値
  cv_class_max       CONSTANT VARCHAR2(100)  := 'ZZ';               -- リース種別最大値
-- 1.3 2018/09/18 Modified END
  cv_csv_data_type   CONSTANT VARCHAR2(100)  := '"1"';              -- CSVデータ区分値
  cv_wqt             CONSTANT VARCHAR2(100)  := '"';                -- CSV文字データ囲い文字
--
  cv_tkn_val1        CONSTANT VARCHAR2(100)  := 'APP-XXCFF1-50104'; -- リース終了日From
  cv_tkn_val2        CONSTANT VARCHAR2(100)  := 'APP-XXCFF1-50105'; -- リース終了日To
  cv_tkn_val3        CONSTANT VARCHAR2(100)  := 'APP-XXCFF1-50101'; -- リース種別From
  cv_tkn_val4        CONSTANT VARCHAR2(100)  := 'APP-XXCFF1-50100'; -- リース種別To
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
    CURSOR get_release_cur(in_date_from  DATE
                          ,in_date_to    DATE
                          ,in_class_from VARCHAR2
                          ,in_class_to   VARCHAR2)
    IS
    SELECT
       xoh.lease_class                as lease_class               --リース種別
      ,xoh.re_lease_flag              as re_lease_flag             --再リース要否
      ,xoh.lease_type                 as lease_type                --リース区分
      ,xoh.re_lease_times             as re_lease_times            --再リース回数
      ,xoh.object_code                as object_code               --物件コード
      ,xoh.object_status              as object_status             --物件ステータスコード
      ,xoh.department_code            as department_code           --管理部門コード
      ,xoh.po_number                  as po_number                 --発注番号
      ,xoh.manufacturer_name          as manufacturer_name         --メーカー名
      ,xoh.age_type                   as age_type                  --年式
      ,xoh.model                      as model                     --機種
      ,xoh.serial_number              as serial_number             --機番
      ,xoh.quantity                   as quantity                  --数量
      ,xoh.chassis_number             as chassis_number            --車台番号
      ,xch.contract_number            as contract_number           --契約番号
      ,xch.lease_company              as lease_company             --リース会社コード
      ,xch.payment_frequency          as payment_frequency         --支払回数
      ,xch.lease_start_date           as lease_start_date          --リース開始日
      ,xch.lease_end_date             as lease_end_date            --リース終了日
      ,xcl.contract_line_num          as contract_line_num         --契約枝番
      ,xcl.second_total_charge        as second_total_charge       --月額リース料(税込)
      ,xcl.estimated_cash_price       as estimated_cash_price      --見積現金購入価額
      ,xcl.second_charge              as second_charge             --月額リース料(税抜)
      ,xcl.second_total_deduction     as second_total_deduction    --月額リース控除額
      ,xcl.first_installation_address as first_installation_address--初回設置場所
      ,xcl.first_installation_place   as first_installation_place  --初回設置先
      ,xlcv.lease_company_name        as lease_company_name        --リース会社名
      ,xdv.department_name            as department_name           --管理部門名
      ,xosv.object_status_name        as object_status_name        --物件ステータス名
-- 0000994 2009/08/11 ADD START
      ,xch.comments                   as comments                  --件名
-- 0000994 2009/08/11 ADD END     
    FROM
       xxcff_object_headers   xoh
      ,xxcff_contract_headers xch
      ,xxcff_contract_lines   xcl
      ,xxcff_lease_company_v  xlcv
      ,xxcff_department_v     xdv
      ,xxcff_object_status_v  xosv
    WHERE
        xch.contract_header_id = xcl.contract_header_id
    AND xcl.object_header_id   = xoh.object_header_id
    AND xch.re_lease_times     = xoh.re_lease_times
    AND xch.lease_class       >= NVL(in_class_from, cv_class_min) --パラメータ．リース種別コードFrom
    AND xch.lease_class       <= NVL(in_class_to, cv_class_max)   --パラメータ．リース種別コードTo
    AND xch.lease_end_date    >= in_date_from  --パラメータ．リース終了日From
    AND xch.lease_end_date    <= in_date_to    --パラメータ．リース終了日To
    AND xch.lease_company      = xlcv.lease_company_code(+)
    AND xoh.department_code    = xdv.department_code(+)
    AND xoh.object_status      = xosv.object_status_code(+)
    AND xoh.object_status     IN (cv_obj_status_102, cv_obj_status_104, cv_obj_status_108)
    ORDER BY
        xoh.department_code
       ,xch.lease_company
       ,xch.contract_number
       ,xcl.contract_line_num;
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
--
  /**********************************************************************************
   * Procedure Name   : para_check
   * Description      : パラメータチェック処理(A-2)
   ***********************************************************************************/
  PROCEDURE para_check(
    id_date_from  IN  DATE,                --   1.リース終了日FROM
    id_date_to    IN  DATE,                --   2.リース終了日TO
    iv_class_from IN  VARCHAR2,            --   3.リース種別FROM
    iv_class_to   IN  VARCHAR2,            --   4.リース種別TO
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'para_check'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--    リース終了日のパラメータチェック
    IF (id_date_from > id_date_to) THEN
      lv_errbuf := xxccp_common_pkg.get_msg(cv_appl_short_name, cv_para_err_msg,
                                            cv_para_from_tkn,   cv_tkn_val1,
                                            cv_para_to_tkn,     cv_tkn_val2);
      RAISE global_api_expt;
    END IF;
--    リース種別のパラメータチェック FROM,TO両方指定の場合
    IF (  (iv_class_from IS NOT NULL)
      AND (iv_class_to IS NOT NULL)) THEN
      IF (iv_class_from > iv_class_to) THEN
        lv_errbuf := xxccp_common_pkg.get_msg(cv_appl_short_name, cv_para_err_msg,
                                            cv_para_from_tkn,   cv_tkn_val3,
                                            cv_para_to_tkn,     cv_tkn_val4);
        RAISE global_api_expt;
      END IF;
    END IF;
--
  EXCEPTION
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END para_check;
--
  /**********************************************************************************
   * Procedure Name   : csv_buf
   * Description      : CSV編集処理(A-4)
   ***********************************************************************************/
  PROCEDURE csv_buf(
    ir_release    IN  get_release_cur%ROWTYPE,            --  再リース要否レコード
    ov_csvbuf     OUT NOCOPY VARCHAR2,                    --  作成CSVデータ
    ov_errbuf     OUT NOCOPY VARCHAR2,                    --  エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,                    --  リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)                    --  ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'csv_buf'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
    ov_csvbuf := NULL;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    --データ区分
    ov_csvbuf := ov_csvbuf ||           cv_csv_data_type                                              || cv_csv_delim;
    --物件コード
    ov_csvbuf := ov_csvbuf || cv_wqt || ir_release.object_code                              || cv_wqt || cv_csv_delim;
    --再リース要否
    ov_csvbuf := ov_csvbuf || cv_wqt || ir_release.re_lease_flag                            || cv_wqt || cv_csv_delim;
    --契約番号
    ov_csvbuf := ov_csvbuf || cv_wqt || ir_release.contract_number                          || cv_wqt || cv_csv_delim;
    --契約枝番
    ov_csvbuf := ov_csvbuf ||           ir_release.contract_line_num                                  || cv_csv_delim;
    --作成日付
    ov_csvbuf := ov_csvbuf || cv_wqt || gv_process_date                                     || cv_wqt || cv_csv_delim;
    --物件ステータスコード
    ov_csvbuf := ov_csvbuf || cv_wqt || ir_release.object_status                            || cv_wqt || cv_csv_delim;
    --物件ステータス名
    ov_csvbuf := ov_csvbuf || cv_wqt || ir_release.object_status_name                       || cv_wqt || cv_csv_delim;
    --管理部門コード
    ov_csvbuf := ov_csvbuf || cv_wqt || ir_release.department_code                          || cv_wqt || cv_csv_delim;
    --管理部門名
    ov_csvbuf := ov_csvbuf || cv_wqt || ir_release.department_name                          || cv_wqt || cv_csv_delim;
    --リース種別
    ov_csvbuf := ov_csvbuf || cv_wqt || ir_release.lease_class                              || cv_wqt || cv_csv_delim;
    --リース区分
    ov_csvbuf := ov_csvbuf || cv_wqt || ir_release.lease_type                               || cv_wqt || cv_csv_delim;
    --再リース回数
    ov_csvbuf := ov_csvbuf ||           ir_release.re_lease_times                                     || cv_csv_delim;
    --リース会社コード
    ov_csvbuf := ov_csvbuf || cv_wqt || ir_release.lease_company                            || cv_wqt || cv_csv_delim;
    --リース会社名
    ov_csvbuf := ov_csvbuf || cv_wqt || ir_release.lease_company_name                       || cv_wqt || cv_csv_delim;
    --支払回数
    ov_csvbuf := ov_csvbuf ||           ir_release.payment_frequency                                  || cv_csv_delim;
    --リース開始日
    ov_csvbuf := ov_csvbuf || cv_wqt || TO_CHAR(ir_release.lease_start_date,cv_date_format) || cv_wqt || cv_csv_delim;
    --リース終了日
    ov_csvbuf := ov_csvbuf || cv_wqt || TO_CHAR(ir_release.lease_end_date,cv_date_format)   || cv_wqt || cv_csv_delim;
    --初回設置場所
    ov_csvbuf := ov_csvbuf || cv_wqt || ir_release.first_installation_address               || cv_wqt || cv_csv_delim;
    --初回設置先
    ov_csvbuf := ov_csvbuf || cv_wqt || ir_release.first_installation_place                 || cv_wqt || cv_csv_delim;
    --見積現金購入価額
    ov_csvbuf := ov_csvbuf ||           ir_release.estimated_cash_price                               || cv_csv_delim;
    --月額リース料（税抜）
    ov_csvbuf := ov_csvbuf ||           ir_release.second_charge                                      || cv_csv_delim;
    --月額リース料（税込）
    ov_csvbuf := ov_csvbuf ||           ir_release.second_total_charge                                || cv_csv_delim;
    --月額控除額（税込）
    ov_csvbuf := ov_csvbuf ||           ir_release.second_total_deduction                             || cv_csv_delim;
    --発注番号
    ov_csvbuf := ov_csvbuf ||           ir_release.po_number                                          || cv_csv_delim;
    --メーカー名(製造者名)
    ov_csvbuf := ov_csvbuf || cv_wqt || ir_release.manufacturer_name                        || cv_wqt || cv_csv_delim;
    --年式
    ov_csvbuf := ov_csvbuf || cv_wqt || ir_release.age_type                                 || cv_wqt || cv_csv_delim;
    --機種
    ov_csvbuf := ov_csvbuf || cv_wqt || ir_release.model                                    || cv_wqt || cv_csv_delim;
    --機番
    ov_csvbuf := ov_csvbuf || cv_wqt || ir_release.serial_number                            || cv_wqt || cv_csv_delim;
    --数量
    ov_csvbuf := ov_csvbuf ||           ir_release.quantity                                           || cv_csv_delim;
    --車台番号
    ov_csvbuf := ov_csvbuf || cv_wqt || ir_release.chassis_number                           || cv_wqt || cv_csv_delim;
-- 0000994 2009/08/11 ADD START
    --件名
    ov_csvbuf := ov_csvbuf || cv_wqt || ir_release.comments                                 || cv_wqt || cv_csv_delim;
-- 0000994 2009/08/11 ADD END    
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END csv_buf;
--
  /**********************************************************************************
   * Procedure Name   : csv_header
   * Description      : CSVヘッダー作成
   ***********************************************************************************/
  PROCEDURE csv_header(
    ov_csvbuf     OUT NOCOPY VARCHAR2,                    --  作成CSVヘッダー
    ov_errbuf     OUT NOCOPY VARCHAR2,                    --  エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,                    --  リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)                    --  ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'csv_header'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
--
    -- *** ローカル・カーソル ***
    CURSOR csv_header_cur(in_type VARCHAR2)
    IS
    SELECT
           flv.lookup_code           AS lookup_code
          ,flv.description           AS item_name
    FROM   fnd_lookup_values_vl flv
    WHERE  lookup_type = in_type
    ORDER BY flv.meaning;
--
    -- *** ローカル・レコード ***
    csv_header_cur_rec csv_header_cur%ROWTYPE;
--
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
    ov_csvbuf := NULL;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    OPEN csv_header_cur(cv_look_type);
    LOOP
      FETCH csv_header_cur INTO csv_header_cur_rec;
      EXIT WHEN csv_header_cur%NOTFOUND;
      -- ヘッダー行を作成する。
      ov_csvbuf := ov_csvbuf || cv_wqt || csv_header_cur_rec.item_name || cv_wqt || cv_csv_delim;
    END LOOP;
    CLOSE csv_header_cur;

--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF (csv_header_cur%ISOPEN) THEN
        CLOSE csv_header_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END csv_header;
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_date_from  IN  VARCHAR2,            --   1.リース終了日FROM
    iv_date_to    IN  VARCHAR2,            --   2.リース終了日TO
    iv_class_from IN  VARCHAR2,            --   3.リース種別FROM
    iv_class_to   IN  VARCHAR2,            --   4.リース種別TO
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'submain'; -- プログラム名
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf   VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode  VARCHAR2(1);     -- リターン・コード
    lv_errmsg   VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    ld_date_from DATE;           -- リース終了日FROM
    ld_date_to   DATE;           -- リース終了日TO
    lv_csvbuf   VARCHAR2(5000);  -- エラー・メッセージ
--    lv_csvbuf   VARCHAR2(300);  -- エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- <カーソル名>

    -- <カーソル名>レコード型
    get_release_cur_rec           get_release_cur%ROWTYPE;
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- グローバル変数の初期化
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
    gv_process_date := TO_CHAR(xxccp_common_pkg2.get_process_date, cv_date_format);
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
    -- =====================================================
    --  パラメータチェック処理(A-2)
    -- =====================================================
--
    ld_date_from := TO_DATE(SUBSTR(iv_date_from, 1, 10), cv_date_format);
    ld_date_to   := TO_DATE(SUBSTR(iv_date_to, 1, 10), cv_date_format);
    para_check(
       id_date_from  => ld_date_from            --   1.リース終了日FROM
      ,id_date_to    => ld_date_to              --   2.リース終了日TO
      ,iv_class_from => iv_class_from           --   3.リース種別FROM
      ,iv_class_to   => iv_class_to             --   4.リース種別TO
      ,ov_retcode    => lv_retcode
      ,ov_errbuf     => lv_errbuf
      ,ov_errmsg     => lv_errmsg
    );
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
    -- =====================================================
    --  再リース要否抽出処理(A-3)
    -- =====================================================
    OPEN get_release_cur(ld_date_from, ld_date_to, iv_class_from, iv_class_to);
    LOOP
      FETCH get_release_cur INTO get_release_cur_rec;
      EXIT WHEN get_release_cur%NOTFOUND;
      gn_target_cnt := gn_target_cnt + 1;
      -- 1行目にはヘッダー行を出力する。
      IF (gn_target_cnt = 1) THEN
        csv_header(ov_csvbuf     => lv_csvbuf
                  ,ov_retcode    => lv_retcode
                  ,ov_errbuf     => lv_errbuf
                  ,ov_errmsg     => lv_errmsg
        );
        IF (lv_retcode = cv_status_error) THEN
        -- 標準ログに出力する。
          FND_FILE.PUT_LINE(
            which  => FND_FILE.LOG
           ,buff   => lv_errbuf
          );
        ELSE
        -- 標準出力に出力する。
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_csvbuf
          );
        END IF;
      END IF;
      -- =====================================================
      --  CSV編集処理(A-4)
      -- =====================================================
      csv_buf(get_release_cur_rec
             ,ov_csvbuf     => lv_csvbuf
             ,ov_retcode    => lv_retcode
             ,ov_errbuf     => lv_errbuf
             ,ov_errmsg     => lv_errmsg
      );
      IF (lv_retcode = cv_status_error) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      ELSE
        -- 標準出力に出力する。
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_csvbuf
        );
        gn_normal_cnt := gn_normal_cnt + 1;
      END IF;
    END LOOP;
    CLOSE get_release_cur;
    --対象件数が0の場合警告終了とする。
    --対象メッセージを出力する。
    IF (gn_target_cnt = 0) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => xxccp_common_pkg.get_msg(cv_appl_short_name, cv_no_data_msg) --エラーメッセージ
      );
      ov_retcode := cv_status_warn;
    END IF;
--
  EXCEPTION
      -- *** 任意で例外処理を記述する ****
      -- カーソルのクローズをここに記述する
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF (get_release_cur%ISOPEN) THEN
        CLOSE get_release_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--####################################  固定部 END   ##########################################
--
  END submain;
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf         OUT NOCOPY   VARCHAR2,   --   エラーメッセージ #固定#
    retcode        OUT NOCOPY   VARCHAR2,   --   エラーコード     #固定#
    iv_date_from   IN  VARCHAR2,            --   1.リース終了日FROM
    iv_date_to     IN  VARCHAR2,            --   2.リース終了日TO
    iv_class_from  IN  VARCHAR2,            --   3.リース種別FROM
    iv_class_to    IN  VARCHAR2             --   4.リース種別TO
  )
--
--
--###########################  固定部 START   ###########################
--
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';             -- プログラム名
--
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- 対象件数メッセージ
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- 成功件数メッセージ
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- エラー件数メッセージ
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- スキップ件数メッセージ
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- 警告終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- エラー終了全ロールバック
--
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- 件数メッセージ用トークン名
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf          VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode         VARCHAR2(1);     -- リターン・コード
    lv_errmsg          VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_message_code    VARCHAR2(100);   -- 終了メッセージコード
    --
  BEGIN
--
--###########################  固定部 START   #####################################################
--
    -- 固定出力
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    -- V1.1用対応  FROM
    xxccp_common_pkg.put_log_header(
       ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
      ,iv_which   => cv_log
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
    -- V1.1用対応  
    --
    xxcff_common1_pkg.put_log_param(
       ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
      ,iv_which   => cv_log
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
       iv_date_from   --   1.リース終了日FROM
      ,iv_date_to     --   2.リース終了日TO
      ,iv_class_from  --   3.リース種別FROM
      ,iv_class_to    --   4.リース種別TO
      ,lv_errbuf      -- エラー・メッセージ           --# 固定 #
      ,lv_retcode     -- リターン・コード             --# 固定 #
      ,lv_errmsg      -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --エラー出力
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
    END IF;
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_cmn
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_cmn
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_cmn
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --スキップ件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_cmn
                    ,iv_name         => cv_skip_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --終了メッセージ
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF(lv_retcode = cv_status_warn) THEN
      lv_message_code := cv_warn_msg;
    ELSIF(lv_retcode = cv_status_error) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_cmn
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --ステータスセット
    retcode := lv_retcode;
    --終了ステータスがエラーの場合はROLLBACKする
    IF (retcode = cv_status_error) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
  END main;
--
--###########################  固定部 END   #######################################################
--
END XXCFF004A28C;
/
