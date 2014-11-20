CREATE OR REPLACE PACKAGE BODY xxwsh430002c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwsh430002c(body)
 * Description      : 倉替返品確定情報インタフェース
 * MD.050           : 倉替返品 T_MD050_BPO_430
 * MD.070           : 倉替返品確定情報インタフェース  T_MD070_BPO_43C
 * Version          : 1.1
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *  get_profile            プロファイル取得プロシージャ（C-1）
 *  get_rtn_info_mst       倉替返品情報抽出プロシージャ（C-2）
 *  output_csv             CSVファイル出力プロシージャ （C-3）
 *  update_xxwsh_order_lines_all  倉替返品インタフェース済フラグ更新プロシージャ(C-4)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/02/07    1.0  Oracle 井澤直也   初回作成
 *  2008/03/14    1.1  Oracle 井澤直也   内部変更要求#16対応
 *  2008/05/23    1.2  Oracle 石渡賢和   抽出条件に計上済み区分を追加
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  gv_status_normal CONSTANT VARCHAR2(1) := '0'; -- 正常
  gv_status_warn   CONSTANT VARCHAR2(1) := '1'; -- 警告
  gv_status_error  CONSTANT VARCHAR2(1) := '2'; -- エラー
  gv_sts_cd_normal CONSTANT VARCHAR2(1) := 'C'; -- ステータス(正常)
  gv_sts_cd_warn   CONSTANT VARCHAR2(1) := 'G'; -- ステータス(警告)
  gv_sts_cd_error  CONSTANT VARCHAR2(1) := 'E'; -- ステータス(エラー)
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  gv_msg_cont      CONSTANT VARCHAR2(3) := '.';
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
--
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
  check_format_expt         EXCEPTION;           -- 移動データ抽出処理での例外
  check_lock_expt           EXCEPTION;           -- ロック取得エラー
--
  PRAGMA EXCEPTION_INIT(check_lock_expt, -54);   -- ロック取得例外
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  gv_pkg_name                 CONSTANT VARCHAR2(100) := 'xxwsh430002c';      -- パッケージ名
  gv_xxwsh                    CONSTANT VARCHAR2(100) := 'XXWSH';             -- アプリケーション短縮名
  gv_profile                  CONSTANT VARCHAR2(100) := 'APP-XXWSH-11701';   -- プロファイル取得エラー
  gv_file_data_err            CONSTANT VARCHAR2(100) := 'APP-XXWSH-11702';   -- 対象データ無し
  gv_lock_err                 CONSTANT VARCHAR2(100) := 'APP-XXWSH-11703';   -- ロックエラー
  gv_file_priv_err            CONSTANT VARCHAR2(100) := 'APP-XXWSH-11704';   -- ファイルアクセス権限エラー
  gv_cur_close_err            CONSTANT VARCHAR2(100) := 'APP-XXWSH-11705';   -- カーソルクローズエラー
  gv_output_msg               CONSTANT VARCHAR2(100) := 'APP-XXWSH-01701';   -- 出力件数
  gv_err_cnt_msg              CONSTANT VARCHAR2(100) := 'APP-XXWSH-01702';   -- エラー件数
  gv_format_err               CONSTANT VARCHAR2(100) := 'APP-XXWSH-00001';   -- フォーマットエラー
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- 倉替返品情報を格納するテーブル型の定義
  TYPE order_header_id_type      IS TABLE OF xxwsh_order_headers_all.order_header_id%TYPE           INDEX BY BINARY_INTEGER;-- 受注ヘッダアドオンID
  TYPE request_no_type           IS TABLE OF xxwsh_order_headers_all.request_no%TYPE                INDEX BY BINARY_INTEGER;-- 依頼No
  TYPE arrival_date_type         IS TABLE OF xxwsh_order_headers_all.arrival_date%TYPE              INDEX BY BINARY_INTEGER;-- 着荷日
  TYPE deliver_from_type         IS TABLE OF xxwsh_order_headers_all.deliver_from%TYPE              INDEX BY BINARY_INTEGER;-- 出荷元保管場所
  TYPE head_sales_branch_type    IS TABLE OF xxwsh_order_headers_all.head_sales_branch%TYPE         INDEX BY BINARY_INTEGER;-- 管轄拠点
  TYPE deliver_to_type           IS TABLE OF xxwsh_order_headers_all.deliver_to%TYPE                INDEX BY BINARY_INTEGER;-- 配送先
  TYPE customer_code_type        IS TABLE OF xxwsh_order_headers_all.customer_code%TYPE             INDEX BY BINARY_INTEGER;-- 顧客
  TYPE shipping_item_code_type   IS TABLE OF xxwsh_order_lines_all.shipping_item_code%TYPE          INDEX BY BINARY_INTEGER;-- 出荷品目
  TYPE parent_item_id_type       IS TABLE OF xxcmn_item_mst2_v.item_no%TYPE                         INDEX BY BINARY_INTEGER;-- 親品目コード
  TYPE crowd_code_type           IS TABLE OF xxcmn_item_mst2_v.old_crowd_code%TYPE                  INDEX BY BINARY_INTEGER;-- 群コード
  TYPE item_um_type              IS TABLE OF xxcmn_item_mst2_v.item_um%TYPE                         INDEX BY BINARY_INTEGER;-- 単位
  TYPE num_of_cases_type         IS TABLE OF xxcmn_item_mst2_v.num_of_cases%TYPE                    INDEX BY BINARY_INTEGER;-- 入数
  TYPE shipped_quantity_type     IS TABLE OF xxwsh_order_lines_all.shipped_quantity%TYPE            INDEX BY BINARY_INTEGER;-- 出荷実績数量
  TYPE lookup_type_type          IS TABLE OF xxwsh_shipping_class2_v.attribute_category%TYPE        INDEX BY BINARY_INTEGER;-- 参照タイプ
  TYPE attribute1_type           IS TABLE OF xxwsh_shipping_class2_v.invoice_class_1%TYPE           INDEX BY BINARY_INTEGER;-- 伝区1
  TYPE attribute3_type           IS TABLE OF xxwsh_shipping_class2_v.send_data_type%TYPE            INDEX BY BINARY_INTEGER;-- データ種別
  TYPE order_category_code_type  IS TABLE OF oe_transaction_types_all.order_category_code%TYPE      INDEX BY BINARY_INTEGER;-- 受注カテゴリ
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gv_dest_path                 VARCHAR2(1000);      -- ファイル格納ディレクトリ
  gv_filename                  VARCHAR2(100);       -- ファイル名
  gn_output_cnt                NUMBER;              -- 出力件数
--
  -- 倉替返品情報抽出用
  gt_order_header_id_tbl       order_header_id_type;
  gt_request_no_tbl            request_no_type;
  gt_arrival_date_tbl          arrival_date_type;
  gt_deliver_from_tbl          deliver_from_type;
  gt_head_sales_branch_tbl     head_sales_branch_type;
  gt_deliver_to_tbl            deliver_to_type;
  gt_customer_code_tbl         customer_code_type;
  gt_shipping_item_code_tbl    shipping_item_code_type;
  gt_item_no_tbl               parent_item_id_type;
  gt_crowd_code_tbl            crowd_code_type;
  gt_item_um_tbl               item_um_type;
  gt_num_of_cases_tbl          num_of_cases_type;
  gt_shipped_quantity_tbl      shipped_quantity_type;
  gt_lookup_type_tbl           lookup_type_type;
  gt_attribute1_tbl            attribute1_type;
  gt_attribute3_tbl            attribute3_type;
  gt_order_category_code_tbl   order_category_code_type;
--
  /**********************************************************************************
   * Procedure Name   : get_profile
   * Description      : プロファイル取得(C-1)
   ***********************************************************************************/
  PROCEDURE get_profile(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_profile'; -- プログラム名
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
    cv_dest_path_token     CONSTANT VARCHAR2(80) := 'XXWSH:IFファイル格納ディレクトリ_倉替返品確定情報インタフェース';
    cv_filename_token      CONSTANT VARCHAR2(80) := 'XXWSH:IFファイル名_倉替返品確定情報インタフェース';
    cv_dest_path           CONSTANT VARCHAR2(30) := 'XXWSH_OB_IF_DEST_PATH_430A';
    cv_filename            CONSTANT VARCHAR2(30) := 'XXWSH_OB_IF_FILENAME_430A';
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
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ファイルパス取得
    gv_dest_path := FND_PROFILE.VALUE(cv_dest_path);
    IF (gv_dest_path IS NULL) THEN
      lv_errmsg  := xxcmn_common_pkg.get_msg(gv_xxwsh,gv_profile ,'PROF_NAME',cv_dest_path_token);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ファイル名取得
    gv_filename  := FND_PROFILE.VALUE(cv_filename);
    IF (gv_filename IS NULL) THEN
      lv_errmsg  := xxcmn_common_pkg.get_msg(gv_xxwsh,gv_profile ,'PROF_NAME',cv_filename_token);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_profile;
--
  /**********************************************************************************
   * Procedure Name   : get_rtn_info_mst
   * Description      : 倉替返品情報抽出(C-2)
   ***********************************************************************************/
  PROCEDURE get_rtn_info_mst(
    ov_errbuf             OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode            OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg             OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_rtn_info_mst'; -- プログラム名
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
    cv_lookup_code     CONSTANT VARCHAR2(2)  := '04';
    cv_lookup_type_3   CONSTANT VARCHAR2(1)  := '3'; -- 出荷支給区分（倉替返品）
    cv_tablename       CONSTANT VARCHAR2(30) := '受注アドオン';
--
    -- *** ローカル変数 ***
    i                   NUMBER; -- ループカンウンタ
--
    -- *** ローカル・カーソル ***
    -- C-2倉替返品情報抽出
    -- 行ロック
    CURSOR rm_if_cur IS
    SELECT xoha.order_header_id,                            -- 受注ヘッダアドオンID
           xoha.request_no,                                 -- 依頼No
           xoha.arrival_date,                               -- 着荷日
           xoha.deliver_from,                               -- 出荷元保管場所
           xoha.head_sales_branch,                          -- 管轄拠点
           xoha.deliver_to,                                 -- 配送先
           xoha.customer_code,                              -- 顧客
           xola.shipping_item_code,                         -- 出荷品目
           ximv2.item_no,                                   -- 親品目コード
           CASE
             WHEN (TO_DATE(ximv1.crowd_start_date,'YYYY/MM/DD') <= xoha.arrival_date)
             THEN ximv1.new_crowd_code                      -- 新群コード
             ELSE ximv1.old_crowd_code                      -- 旧群コード
           END AS crowd_code,
           ximv1.item_um,                                   -- 単位
           NVL(ximv1.num_of_cases,0)    AS num_of_cases,    -- 入数
           NVL(xola.shipped_quantity,0) AS shipped_quantity,-- 出荷実績数量
           xscv.attribute_category,                         -- 出荷区分分類
           xscv.invoice_class_1,                            -- 伝区1
           xscv.send_data_type,                             -- データ種別
           xotv.order_category_code                         -- 受注カテゴリ
    FROM xxwsh_order_headers_all       xoha,                -- 受注ヘッダアドオン
         xxwsh_order_lines_all         xola,                -- 受注明細アドオン
         xxcmn_item_mst2_v             ximv1,               -- OPM品目情報VIEW(子)
         xxcmn_item_mst2_v             ximv2,               -- OPM品目情報VIEW(親)
         xxwsh_oe_transaction_types2_v xotv,                -- 受注タイプVIEW
         xxwsh_shipping_class2_v       xscv                 -- 出荷区分情報VIEW
    WHERE xoha.req_status            = cv_lookup_code                   -- ステータス(出荷実績計上済)
      AND xoha.order_type_id         = xotv.transaction_type_id         -- 取引タイプID（受注タイプID）
      AND xoha.actual_confirm_class  = 'Y'                              -- 取引タイプID（受注タイプID）
      AND xotv.shipping_shikyu_class = cv_lookup_type_3                 -- 出荷支給区分
      AND xotv.transaction_type_name = xscv.order_transaction_type_name -- 受注タイプ名
      AND xoha.order_header_id       = xola.order_header_id             -- 受注ヘッダアドオンID
      AND xola.shipping_item_code    = ximv1.item_no                    -- 品目(子)
      AND ximv1.start_date_active   <= xoha.arrival_date                -- 適用開始日(子)
      AND ximv1.end_date_active     >= xoha.arrival_date                -- 適用終了日(子)
      AND ximv1.parent_item_id       = ximv2.item_id                    -- 品目コード(親子)
      AND ximv2.start_date_active   <= xoha.arrival_date                -- 適用開始日(親)
      AND ximv2.end_date_active     >= xoha.arrival_date                -- 適用終了日(親)
      AND xola.rm_if_flg           IS NULL                              -- 倉替返品インタフェース済フラグ
    ORDER BY
       xoha.ordered_date          -- 受注日
      ,xoha.deliver_from          -- 出荷元保管場所
      ,xoha.head_sales_branch     -- 管轄拠点
      ,xoha.result_deliver_to     -- 出荷先_実績
      ,xoha.customer_code         -- 顧客
      ,xola.shipping_item_code    -- 出荷品目(明細）
    FOR UPDATE OF xola.order_header_id NOWAIT;
--
    -- *** ローカル・レコード ***
    lr_rm_if_rec   rm_if_cur%ROWTYPE;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    OPEN rm_if_cur;-- カーソルオープン
--
    i := 0;
    <<rm_if_cur_loop>>
    LOOP
      -- レコード読込
      FETCH rm_if_cur INTO lr_rm_if_rec;
      EXIT WHEN rm_if_cur%NOTFOUND;
--
      i := i + 1;
--
      gt_order_header_id_tbl(i)      := lr_rm_if_rec.order_header_id;      -- 受注ヘッダアドオンID
      gt_request_no_tbl(i)           := lr_rm_if_rec.request_no;           -- 依頼No
      gt_arrival_date_tbl(i)         := lr_rm_if_rec.arrival_date;         -- 着荷日
      gt_deliver_from_tbl(i)         := lr_rm_if_rec.deliver_from;         -- 出荷元保管場所
      gt_head_sales_branch_tbl(i)    := lr_rm_if_rec.head_sales_branch;    -- 管轄拠点
      gt_deliver_to_tbl(i)           := NULL;                              -- 配送先
      gt_customer_code_tbl(i)        := NULL;                              -- 顧客
      gt_shipping_item_code_tbl(i)   := lr_rm_if_rec.shipping_item_code;   -- 出荷品目
      gt_item_no_tbl(i)              := lr_rm_if_rec.item_no;              -- 親品目コード
      gt_crowd_code_tbl(i)           := lr_rm_if_rec.crowd_code;           -- 群コード
      gt_item_um_tbl(i)              := lr_rm_if_rec.item_um;              -- 単位
      gt_num_of_cases_tbl(i)         := lr_rm_if_rec.num_of_cases;         -- 入数
      gt_shipped_quantity_tbl(i)     := lr_rm_if_rec.shipped_quantity;     -- 出荷実績数量
      gt_lookup_type_tbl(i)          := lr_rm_if_rec.attribute_category;   -- 参照タイプ
      gt_attribute1_tbl(i)           := lr_rm_if_rec.invoice_class_1;      -- 伝区1
      gt_attribute3_tbl(i)           := lr_rm_if_rec.send_data_type;       -- データ種別
      gt_order_category_code_tbl(i)  := lr_rm_if_rec.order_category_code;  -- 受注カテゴリ
    END LOOP rm_if_cur_loop;
--
    CLOSE rm_if_cur;
--
    -- 1件も抽出できなかった場合、警告
    IF (i = 0) THEN
      ov_errmsg  := xxcmn_common_pkg.get_msg(gv_xxwsh,gv_file_data_err,'TABLE',cv_tablename);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,ov_errmsg);
      ov_retcode := gv_status_warn;
    END IF;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
  EXCEPTION
    -- ロック取得エラー
    WHEN check_lock_expt THEN
      ov_errmsg := xxcmn_common_pkg.get_msg(gv_xxwsh, gv_lock_err);
      lv_errbuf := ov_errmsg;
      ov_errbuf := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
      -- カーソルがOPENしている場合
      IF(rm_if_cur%ISOPEN) THEN
        CLOSE rm_if_cur;
      END IF;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
      -- カーソルがOPENしている場合
      IF(rm_if_cur%ISOPEN) THEN
        CLOSE rm_if_cur;
      END IF;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      -- カーソルがOPENしている場合
      IF(rm_if_cur%ISOPEN) THEN
        CLOSE rm_if_cur;
      END IF;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      -- カーソルがOPENしている場合
      IF(rm_if_cur%ISOPEN) THEN
        CLOSE rm_if_cur;
      END IF;
--
--#####################################  固定部 END   ##########################################
--
  END get_rtn_info_mst;
  /**********************************************************************************
   * Procedure Name   : output_csv
   * Description      : インタフェースファイル出力(C-3)
   ***********************************************************************************/
  PROCEDURE output_csv(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_csv'; -- プログラム名
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
    cv_change_type        CONSTANT VARCHAR2(1) :=  '2';    -- 変換区分
    cv_status_error       CONSTANT VARCHAR2(1) :=  '1';    -- エラー返り値
    cv_rno                CONSTANT VARCHAR2(1) :=  '0';    -- R No
    cv_voucher2           CONSTANT VARCHAR2(1) :=  '2';    -- 伝区2
    cv_continue           CONSTANT VARCHAR2(2) := '00';    -- 継続
    cv_comma              CONSTANT VARCHAR2(1) :=  ',';    -- カンマ
    cv_order              CONSTANT VARCHAR2(5) := 'ORDER'; -- 受注カテゴリ
    cv_cases_value        CONSTANT VARCHAR2(8) := 'ケース数';
    cv_num_of_cases_value CONSTANT VARCHAR2(4) := '入数'    ;
    cv_number_value       CONSTANT VARCHAR2(4) := '本数'    ;
    cv_crowd_code         CONSTANT VARCHAR2(8) := '群コード';
    cn_cases_value        CONSTANT NUMBER      := 6;       -- ケース数桁数
    cn_num_of_cases_value CONSTANT NUMBER      := 4;       -- 入数桁数
    cn_number_value       CONSTANT NUMBER      := 9;       -- 本数桁数 正数
    cn_number_m_value     CONSTANT NUMBER      := 8;       -- 本数桁数 負数
    cn_crowd_code         CONSTANT NUMBER      := 4;       -- 群コード
    --
    -- *** ローカル変数 ***
    lv_after_request_no   VARCHAR2(9);      -- 変換後依頼No
    lv_csv_file           VARCHAR2(10000);  -- CSV出力情報
    ln_cases              NUMBER;           -- ケース数
    ln_number             NUMBER;           -- 本数
    ln_retcode            NUMBER;           -- 返り値
    lf_file_hand    UTL_FILE.FILE_TYPE;     -- ファイル・ハンドルの宣言
    lv_fmat               VARCHAR2(15);     -- 書式用
    lv_clm_name           VARCHAR2(8);      -- 項目格納用
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
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        ループ処理の記述         ***
    -- ***       処理部の呼び出し          ***
    -- ***************************************
    -- CSVファイルへ出力
    lf_file_hand := UTL_FILE.FOPEN(gv_dest_path,
                                   gv_filename,
                                   'w');
--
    <<gt_order_header_id_loop>>
    FOR i IN 1..gt_order_header_id_tbl.COUNT LOOP
--
      --依頼Noコンバート
      ov_retcode := xxwsh_common_pkg.convert_request_number(
                                                             cv_change_type       -- 1.変換区分
                                                            ,gt_request_no_tbl(i) -- 2.変換前依頼No
                                                            ,lv_after_request_no  -- 3.変換後依頼No
                                                           );
      -- リターン・コードにエラーが返された場合はエラー
      IF(ov_retcode = cv_status_error)THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxwsh,gv_file_data_err);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
--
      lv_fmat    := '999999999D99'; --正数用書式
      -- 出荷実績数量が0の場合
      IF(gt_shipped_quantity_tbl(i) = 0) THEN
        ln_cases  := 0;  -- ケース数
        ln_number := 0;  -- 本数
      -- 入数が0の場合
      ELSIF(gt_num_of_cases_tbl(i) = 0) THEN
        ln_cases  := NULL;                          -- ケース数
        ln_number := gt_shipped_quantity_tbl(i);    -- 本数
      ELSE
        ln_cases  := TRUNC(gt_shipped_quantity_tbl(i) / gt_num_of_cases_tbl(i));    -- ケース数
        ln_number := TRUNC(MOD(gt_shipped_quantity_tbl(i),gt_num_of_cases_tbl(i))); -- 本数
      END IF;
--
      -- 受注の場合
      IF (gt_order_category_code_tbl(i) = cv_order) THEN
        IF(LENGTH(ln_number) > cn_number_m_value) THEN
          lv_clm_name := cv_number_value;
          RAISE check_format_expt;
        END IF;
        ln_cases  := ln_cases * -1;
        ln_number := ln_number * -1;
        lv_fmat   := '99999990D99'; --負数用書式
      END IF;
--
      -- 桁数チェック
      --ケース数のチェック
      IF (LENGTH(ln_cases) > cn_cases_value) THEN
        lv_clm_name := cv_cases_value;
        RAISE check_format_expt;
      --入数
      ELSIF(LENGTH(gt_num_of_cases_tbl(i)) > cn_num_of_cases_value)THEN
        lv_clm_name := cv_num_of_cases_value;
        RAISE check_format_expt;
      --群コード
      ELSIF(LENGTH(gt_crowd_code_tbl(i)) > cn_crowd_code)THEN
        lv_clm_name := cv_crowd_code;
        RAISE check_format_expt;
      --本数のチェック
      ELSIF(LENGTH(ln_number) > cn_number_value) THEN
        lv_clm_name := cv_number_value;
        RAISE check_format_expt;
      END IF;
--
      --CSVファイル出力
      lv_csv_file := gt_attribute3_tbl(i) || cv_comma
                                          || cv_rno                                     ||cv_comma
                                          || cv_continue                                ||cv_comma
                                          || TO_CHAR(gt_arrival_date_tbl(i),'YYYYMM')   ||cv_comma
                                          || gt_deliver_from_tbl(i)                     ||cv_comma
                                          || gt_head_sales_branch_tbl(i)                ||cv_comma
                                          || gt_attribute1_tbl(i)                       ||cv_comma
                                          || cv_voucher2                                ||cv_comma
                                          || gt_deliver_to_tbl(i)                       ||cv_comma
                                          || gt_customer_code_tbl(i)                    ||cv_comma
                                          || TO_CHAR(gt_arrival_date_tbl(i),'YYYYMMDD') ||cv_comma
                                          || lv_after_request_no                        ||cv_comma
                                          || gt_shipping_item_code_tbl(i)               ||cv_comma
                                          || gt_item_no_tbl(i)                          ||cv_comma
                                          || gt_crowd_code_tbl(i)                       ||cv_comma
                                          || TO_CHAR(ln_cases,'999999')                 ||cv_comma
                                          || TO_CHAR(gt_num_of_cases_tbl(i) ,'9999')    ||cv_comma
                                          || TO_CHAR(ln_number,lv_fmat);
--
      -- CSVファイルへ出力する場合
      UTL_FILE.PUT_LINE(lf_file_hand,lv_csv_file);
      -- 出力件数
      gn_target_cnt := gn_target_cnt +1;
    END LOOP gt_item_mst_tbl_loop;
--
    --ファイルクローズ
    UTL_FILE.FCLOSE(lf_file_hand);
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    -- 書式エラー
    WHEN check_format_expt THEN
      -- ファイルがOPENされているとき
      IF (UTL_FILE.IS_OPEN(lf_file_hand)) THEN
        UTL_FILE.FCLOSE(lf_file_hand);
      END IF;
      ov_errmsg  := xxcmn_common_pkg.get_msg(gv_xxwsh,gv_format_err,'CLM_NAME',lv_clm_name);
      ov_retcode := gv_status_error;
    -- ファイルアクセス権限エラー
    WHEN UTL_FILE.ACCESS_DENIED THEN
      -- ファイルがOPENされているとき
      IF (UTL_FILE.IS_OPEN(lf_file_hand)) THEN
        UTL_FILE.FCLOSE(lf_file_hand);
      END IF;
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxwsh,gv_file_priv_err);
      lv_errbuf := lv_errmsg;
--
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      -- ファイルがOPENされているとき
      IF (UTL_FILE.IS_OPEN(lf_file_hand)) THEN
        UTL_FILE.FCLOSE(lf_file_hand);
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- ファイルがOPENされているとき
      IF (UTL_FILE.IS_OPEN(lf_file_hand)) THEN
        UTL_FILE.FCLOSE(lf_file_hand);
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- ファイルがOPENされているとき
      IF (UTL_FILE.IS_OPEN(lf_file_hand)) THEN
        UTL_FILE.FCLOSE(lf_file_hand);
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END output_csv;
--
  /**********************************************************************************
   * Procedure Name   : update_xxwsh_order_lines_all
   * Description      : 倉替返品インタフェース済フラグ更新(C-4)
   ***********************************************************************************/
  PROCEDURE update_xxwsh_order_lines_all(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_xxwsh_order_lines_all'; -- プログラム名
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
    lv_rm_if_flg  VARCHAR2(2) :=  'Y';
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
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***************************************
    --倉替返品インタフェース済フラグの更新
    FORALL i IN 1 .. gt_order_header_id_tbl.COUNT
      UPDATE xxwsh_order_lines_all
         SET rm_if_flg                   = lv_rm_if_flg               -- 倉替返品インタフェース済フラグ
           , last_updated_by             = FND_GLOBAL.USER_ID         -- 最終更新者
           , last_update_date            = SYSDATE                    -- 最終更新日
           , last_update_login           = FND_GLOBAL.LOGIN_ID        -- 最終更新ログイン
           , request_id                  = FND_GLOBAL.CONC_REQUEST_ID -- 要求ID
           , program_application_id      = FND_GLOBAL.PROG_APPL_ID    -- コンカレント・プログラム・アプリケーションid
           , program_id                  = FND_GLOBAL.CONC_PROGRAM_ID -- コンカレント・プログラムid
           , program_update_date         = SYSDATE                    -- プログラム更新日
       WHERE order_header_id             = gt_order_header_id_tbl(i); -- 受注ヘッダアドオンID
--
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END update_xxwsh_order_lines_all;
--
/**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain'; -- プログラム名
    -- ===============================
    -- ローカル変数
    -- ===============================
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
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
--
    -- グローバル変数の初期化
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
    gn_output_cnt := 0;
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- ===============================
    -- プロファイル取得 (C-1)
    -- ===============================
    get_profile(
      lv_errbuf,            -- エラー・メッセージ           --# 固定 #
      lv_retcode,           -- リターン・コード             --# 固定 #
      lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = gv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    ELSIF (lv_retcode = gv_status_warn) THEN
      ov_retcode := lv_retcode;
    END IF;
--
    -- ===============================
    -- 倉替返品情報抽出 (C-2)
    -- ===============================
    get_rtn_info_mst(
      lv_errbuf,            -- エラー・メッセージ           --# 固定 #
      lv_retcode,           -- リターン・コード             --# 固定 #
      lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = gv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    ELSIF (lv_retcode = gv_status_warn) THEN
      ov_retcode := lv_retcode;
    END IF;
--
    -- ===============================
    -- CSVへの出力(C-3)
    -- ===============================
    output_csv(
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = gv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    ELSIF (lv_retcode = gv_status_warn) THEN
      ov_retcode := lv_retcode;
    END IF;
--
    -- ==============================================
    -- 倉替返品インタフェース済みフラグ更新(C-4)
    -- ==============================================
    update_xxwsh_order_lines_all(
                               lv_errbuf,         -- エラー・メッセージ           --# 固定 #
                               lv_retcode,        -- リターン・コード             --# 固定 #
                               lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = gv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    ELSIF (lv_retcode = gv_status_warn) THEN
      ov_retcode := lv_retcode;
    END IF;
--
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
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--####################################  固定部 END   ##########################################
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf        OUT VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode       OUT VARCHAR2       --   リターン・コード    --# 固定 #
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
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main';  -- プログラム名
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
  BEGIN
--
--###########################  固定部 START   #####################################################
--
    -- ======================
    -- 固定出力用変数セット
    -- ======================
    --実行ユーザ名取得
    gv_exec_user := fnd_global.user_name;
    --実行コンカレント名取得
    SELECT fcp.concurrent_program_name
    INTO   gv_conc_name
    FROM   fnd_concurrent_programs fcp
    WHERE  fcp.application_id        = fnd_global.prog_appl_id
    AND    fcp.concurrent_program_id = fnd_global.conc_program_id
    AND    ROWNUM                    = 1;
--
    -- ======================
    -- 固定出力
    -- ======================
    --実行ユーザ名出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00001','USER',gv_exec_user);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --実行コンカレント名出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00002','CONC',gv_conc_name);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --起動時間出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10118',
                                           'TIME', TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS'));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_out_msg);
--
    --区切り文字出力
    gv_sep_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00003');
--
--
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
      lv_errbuf,   -- エラー・メッセージ           --# 固定 #
      lv_retcode,  -- リターン・コード             --# 固定 #
      lv_errmsg);  -- ユーザー・エラー・メッセージ --# 固定 #
--
--###########################  固定部 START   #####################################################
--
    -- ======================
    -- エラー・メッセージ出力
    -- ======================
    IF (lv_retcode = gv_status_error) THEN
      IF (lv_errmsg IS NULL) THEN
        --定型メッセージ・セット
        lv_errmsg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10030');
      END IF;
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
    END IF;
    -- ==================================
    -- リターン・コードのセット、終了処理
    -- ==================================
    --区切り文字列出力
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    --出力件数出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXWSH',gv_output_msg,'CNT',TO_CHAR(gn_target_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --成功件数出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00009','CNT',TO_CHAR(gn_normal_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --エラー件数出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00010','CNT',TO_CHAR(gn_error_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --スキップ件数出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00011','CNT',TO_CHAR(gn_warn_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --ステータス出力
    SELECT flv.meaning
    INTO   gv_conc_status
    FROM   fnd_lookup_values flv
    WHERE  flv.language            = userenv('LANG')
    AND    flv.view_application_id = 0
    AND    flv.security_group_id   = fnd_global.lookup_security_group(flv.lookup_type,
                                                                      flv.view_application_id)
    AND    flv.lookup_type         = 'CP_STATUS_CODE'
    AND    flv.lookup_code         = DECODE(lv_retcode,
                                            gv_status_normal,gv_sts_cd_normal,
                                            gv_status_warn,gv_sts_cd_warn,
                                            gv_sts_cd_error)
    AND    ROWNUM                  = 1;
--
    --処理ステータス出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00012','STATUS',gv_conc_status);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --ステータスセット
    retcode := lv_retcode;
    --終了ステータスがエラーの場合はROLLBACKする
    IF (retcode = gv_status_error) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
  END main;
--
--###########################  固定部 END   #######################################################
--
END xxwsh430002c;
/
