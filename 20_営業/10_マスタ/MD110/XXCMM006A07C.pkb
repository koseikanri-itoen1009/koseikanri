CREATE OR REPLACE PACKAGE BODY APPS.XXCMM006A07C
AS
/*************************************************************************
 * Copyright(c)SCSK Corporation, 2022. All rights reserved.
 * 
 * Package Name    : XXCMM006A07C
 * Description     : 値リストの値IF抽出
 * MD.050          : T_MD050_CMM_006_A07_値リストの値IF抽出_EBSコンカレント
 * Version         : 1.0
 * 
 * Program List
 * -------------------- -----------------------------------------------------
 *  Name                Description
 * -------------------- -----------------------------------------------------
 *  init                初期処理（パラメータチェック・プロファイル取得）(A-1)
 *  data_outbound_proc1 AFF値の抽出・ファイル出力処理                   (A-2)
 *  data_outbound_proc2 AFF階層の抽出・ファイル出力処理                 (A-3)
 *  data_outbound_proc3 AFF関連値の抽出・ファイル出力処理               (A-4)
 *  upd_oic_ctrl_tbl    管理テーブル登録・更新処理                      (A-5)
 *  submain             メイン処理プロシージャ
 *  main                コンカレント実行ファイル登録プロシージャ
 * 
 * Change Record
 * ------------- ----- ------------- -------------------------------------
 *  Date          Ver.  Editor        Description
 * ------------- ----- ------------- -------------------------------------
 *  2022-12-07    1.0   T.Okuyama     初回作成
 ************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; -- 正常:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   -- 警告:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  -- 異常:2
  --WHOカラム
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;         -- CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                    -- CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;         -- LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                    -- LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;        -- LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id; -- REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;    -- PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id; -- PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                    -- PROGRAM_UPDATE_DATE
--
  cv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont      CONSTANT VARCHAR2(3) := '.';
  cv_msg_slash     CONSTANT VARCHAR2(3) := '/';
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
  gn_target_cnt    NUMBER;                    -- 対象件数（総数）
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
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
  --*** ロック(ビジー)エラー例外 ***
  global_lock_expt          EXCEPTION;
  PRAGMA EXCEPTION_INIT(global_lock_expt,         -54);
--
--################################  固定部 END   ##################################
--
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name        CONSTANT VARCHAR2(100) := 'XXCMM006A07C'; -- パッケージ名
  cv_msg_kbn_cmm     CONSTANT VARCHAR2(5)   := 'XXCMM';        -- アドオン：マスタ・経理・共通のアプリケーション短縮名
  cv_msg_kbn_ccp     CONSTANT VARCHAR2(5)   := 'XXCCP';        -- アドオン：共通・IF領域のアプリケーション短縮名
  cv_msg_kbn_cfo     CONSTANT VARCHAR2(5)   := 'XXCFO';        -- アドオン：会計・アドオン領域のアプリケーション短縮名
  cv_msg_kbn_coi     CONSTANT VARCHAR2(5)   := 'XXCOI';        -- アドオン：販物・在庫領域のアプリケーション短縮名
--
  -- 会計フレックス・セグメント
  cv_aff_cmp         CONSTANT VARCHAR2(20) := 'XX03_COMPANY';        -- 会社
  cv_aff_dpt         CONSTANT VARCHAR2(20) := 'XX03_DEPARTMENT';     -- 部門
  cv_aff_acc         CONSTANT VARCHAR2(20) := 'XX03_ACCOUNT';        -- 勘定科目
  cv_aff_sub         CONSTANT VARCHAR2(20) := 'XX03_SUB_ACCOUNT';    -- 補助科目
  cv_aff_btp         CONSTANT VARCHAR2(20) := 'XX03_BUSINESS_TYPE';  -- 企業コード
  cv_aff_pat         CONSTANT VARCHAR2(20) := 'XX03_PARTNER';        -- 顧客コード
  cv_aff_dpt_t       CONSTANT VARCHAR2(20) := 'XX03_DEPARTMENT_T';   -- 部門T
--
  -- ファイル識別番号
  cv_fno_cmp         CONSTANT VARCHAR2(3) := '_01';                  -- 会社
  cv_fno_dpt         CONSTANT VARCHAR2(3) := '_02';                  -- 部門
  cv_fno_acc         CONSTANT VARCHAR2(3) := '_03';                  -- 勘定科目
  cv_fno_sub         CONSTANT VARCHAR2(3) := '_04';                  -- 補助科目
  cv_fno_btp         CONSTANT VARCHAR2(3) := '_05';                  -- 企業コード
  cv_fno_pat         CONSTANT VARCHAR2(3) := '_06';                  -- 顧客コード
  cv_2nd_nm          CONSTANT VARCHAR2(4) :=  '.csv';                -- ファイル拡張子
--
  -- メッセージ番号
  cv_msg_coi1_00029  CONSTANT VARCHAR2(20) := 'APP-XXCOI1-00029';    -- ディレクトリパス取得エラー
--
  cv_msg_cmm1_00002  CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00002';    -- プロファイル取得エラーメッセージ
  cv_msg_cmm1_00008  CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00008';    -- ロックエラーメッセージ
  cv_msg_cmm1_00054  CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00054';    -- 挿入エラーメッセージ
  cv_msg_cmm1_00055  CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00055';    -- 更新エラーメッセージ
  cv_msg_cmm1_00487  CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00487';    -- ファイルオープンエラーメッセージ
  cv_msg_cmm1_00488  CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00488';    -- ファイル書き込みエラーメッセージ
--
  cv_msg_cmm1_60001  CONSTANT VARCHAR2(20) := 'APP-XXCMM1-60001';    -- パラメータ出力メッセージ
  cv_msg_cmm1_60002  CONSTANT VARCHAR2(20) := 'APP-XXCMM1-60002';    -- 値セット名該当なしエラーメッセージ
  cv_msg_cmm1_60003  CONSTANT VARCHAR2(20) := 'APP-XXCMM1-60003';    -- IFファイル名出力メッセージ
  cv_msg_cmm1_60004  CONSTANT VARCHAR2(20) := 'APP-XXCMM1-60004';    -- 同一ファイル存在エラーメッセージ
  cv_msg_cmm1_60005  CONSTANT VARCHAR2(20) := 'APP-XXCMM1-60005';    -- 処理日時出力メッセージ
  cv_msg_cmm1_60006  CONSTANT VARCHAR2(20) := 'APP-XXCMM1-60006';    -- 検索対象・件数メッセージ
  cv_msg_cmm1_60007  CONSTANT VARCHAR2(20) := 'APP-XXCMM1-60007';    -- ファイル出力対象・件数メッセージ
  cv_msg_cmm1_60008  CONSTANT VARCHAR2(20) := 'APP-XXCMM1-60008';    -- OIC連携処理管理テーブル
  cv_msg_cmm1_60009  CONSTANT VARCHAR2(20) := 'APP-XXCMM1-60009';    -- 値セットの値
  cv_msg_cmm1_60010  CONSTANT VARCHAR2(20) := 'APP-XXCMM1-60010';    -- AFF階層（部門）
  cv_msg_cmm1_60011  CONSTANT VARCHAR2(20) := 'APP-XXCMM1-60011';    -- AFF階層（勘定科目）
  cv_msg_cmm1_60012  CONSTANT VARCHAR2(20) := 'APP-XXCMM1-60012';    -- AFF関連値
  cv_msg_cmm1_60043  CONSTANT VARCHAR2(20) := 'APP-XXCMM1-60043';    -- パラメータ名（値セット名）
  cv_msg_cmm1_60048  CONSTANT VARCHAR2(20) := 'APP-XXCMM1-60048';    -- パラメータ必須エラーメッセージ
--
  cv_msg1            CONSTANT VARCHAR2(2)  := '1.';                  -- メッセージNo.
  cv_msg2            CONSTANT VARCHAR2(2)  := '2.';                  -- メッセージNo.
  cv_msg3            CONSTANT VARCHAR2(2)  := '3.';                  -- メッセージNo.
  cv_msg4            CONSTANT VARCHAR2(2)  := '4.';                  -- メッセージNo.
  cv_msg5            CONSTANT VARCHAR2(2)  := '5.';                  -- メッセージNo.
--
  -- トークン
  cv_tkn_param_name  CONSTANT VARCHAR2(20) := 'PARAM_NAME';          -- パラメータ名
  cv_tkn_param_val   CONSTANT VARCHAR2(20) := 'PARAM_VAL';           -- パラメータ値
  cv_tkn_ng_profile  CONSTANT VARCHAR2(20) := 'NG_PROFILE';          -- プロファイル名
  cv_tkn_dir_tok     CONSTANT VARCHAR2(20) := 'DIR_TOK';             -- ディレクトリ名
  cv_tkn_file_name   CONSTANT VARCHAR2(20) := 'FILE_NAME';           -- ファイル名
  cv_tkn_ng_table    CONSTANT VARCHAR2(20) := 'NG_TABLE';            -- テーブル名
  cv_tkn_date1       CONSTANT VARCHAR2(20) := 'DATE1';               -- 前回処理日時（YYYY/MM/DD HH24:MI:SS）
  cv_tkn_date2       CONSTANT VARCHAR2(20) := 'DATE2';               -- 今回処理日時（YYYY/MM/DD HH24:MI:SS）
  cv_tkn_target      CONSTANT VARCHAR2(20) := 'TARGET';              -- 検索対象、またはファイル出力対象
  cv_tkn_count       CONSTANT VARCHAR2(20) := 'COUNT';               -- 件数
  cv_tkn_table       CONSTANT VARCHAR2(20) := 'TABLE';               -- テーブル名
  cv_tkn_err_msg     CONSTANT VARCHAR2(20) := 'ERR_MSG';             -- SQLERRM
  cv_tkn_sqlerrm     CONSTANT VARCHAR2(20) := 'SQLERRM';             -- SQLERRM
--
  -- プロファイル
  cv_data_filedir    CONSTANT VARCHAR2(60) := 'XXCMM1_OIC_OUT_FILE_DIR';        -- XXCMM:OIC連携データファイル格納ディレクトリ名
  cv_data_filename1  CONSTANT VARCHAR2(60) := 'XXCMM1_006A07_AFF_OUT_FILE_FIL'; -- XXCMM:AFF値連携データファイル名（OIC連携）
  cv_data_filename2  CONSTANT VARCHAR2(60) := 'XXCMM1_006A07_HIE_OUT_FILE_FIL'; -- XXCMM:AFF階層連携データファイル名（OIC連携）
  cv_data_filename3  CONSTANT VARCHAR2(60) := 'XXCMM1_006A07_REL_OUT_FILE_FIL'; -- XXCMM:AFF関連値連携データファイル名（OIC連携）
  cv_tv_start_date   CONSTANT VARCHAR2(60) := 'XXCMM1_006A07_TV_START_DATE';    -- XXCMM:ツリーバージョン開始日（OIC連携）
--
  -- 処理日書式
  cv_proc_date_fm    CONSTANT VARCHAR2(30) := 'YYYY/MM/DD HH24:MI:SS';
  cv_date_ymd        CONSTANT VARCHAR2(30) := 'YYYY/MM/DD';
  cv_comma_edit      CONSTANT VARCHAR2(30) := 'FM999,999,999';
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gn_target1_cnt          NUMBER := 0;                                          -- AFF値連携対象件数
  gn_target2_dpt_cnt      NUMBER := 0;                                          -- AFF階層（部門）連携対象件数
  gn_target2_acc_cnt      NUMBER := 0;                                          -- AFF階層（勘定科目）連携対象件数
  gn_target3_cnt          NUMBER := 0;                                          -- AFF関連値連携対象件数
  gv_data_filedir         VARCHAR2(100);                                        -- XXCMM:OIC連携データファイル格納ディレクトリ名
  gv_data_filename1       VARCHAR2(100);                                        -- XXCMM:AFF値連携データファイル名
  gv_data_filename2       VARCHAR2(100);                                        -- XXCMM:AFF階層連携データファイル名
  gv_data_filename3       VARCHAR2(100);                                        -- XXCMM:AFF関連値連携データファイル名
  gv_file_path            ALL_DIRECTORIES.DIRECTORY_PATH%TYPE;                  -- ファイルパス
  gd_tv_start_date        DATE;                                                 -- XXCMM:ツリーバージョン開始日（OIC連携）
  gd_process_date         DATE;                                                 -- 今回処理日時
  gd_pre_process_date     DATE;                                                 -- 前回処理日時
  gv_f_value_set_name     FND_FLEX_VALUE_SETS.FLEX_VALUE_SET_NAME%TYPE;         -- 値セット名
--
  -- ファイル出力関連
  gf_file_hand1           UTL_FILE.FILE_TYPE;                                   -- AFF値連携ファイル・ハンドル
  gf_file_hand2           UTL_FILE.FILE_TYPE;                                   -- AFF階層(部門/勘定科目)連携ファイル・ハンドル
  gf_file_hand3           UTL_FILE.FILE_TYPE;                                   -- AFF関連値連携ファイル・ハンドル
--
  cv_open_mode_w          CONSTANT VARCHAR2(1)  := 'w';                         -- ファイルオープンモード（上書き）
  cn_max_linesize         CONSTANT BINARY_INTEGER := 32767;                     -- ファイル行サイズ
--
  -- ==============================
  -- ユーザー定義グローバルカーソル
  -- ==============================
--
  -- (1) AFF（会社、部門、勘定科目、補助科目、企業、顧客）の値を抽出する。
  -- =============================================================================================================
  CURSOR c_outbound_data1_cur(p_flex_value_set_name IN VARCHAR2)
  IS
    SELECT /*+ LEADING(ffvs) USE_CONCAT USE_NL(ffvv.t ffvv.v) */
        ffvs.flex_value_set_name                       AS flex_value_set_name                                         -- 値セット名
      , DECODE(ffvs.flex_value_set_name, cv_aff_sub, ffvv.parent_flex_value_low || ffvv.flex_value, ffvv.flex_value) AS flex_value -- 値
      , TO_CHAR(ffvv.start_date_active, cv_date_ymd)   AS start_date_active                                           -- 開始日
      , TO_CHAR(ffvv.end_date_active,   cv_date_ymd)   AS end_date_active                                             -- 終了日
      , ffvv.summary_flag                              AS summary_flag                                                -- 要約フラグ
      , ffvv.enabled_flag                              AS enabled_flag                                                -- 有効フラグ
      , DECODE(ffvs.flex_value_set_name, cv_aff_acc, SUBSTR(ffvv.compiled_value_attributes, 5, 1), null)  AS acc_type -- 勘定科目タイプ
      , SUBSTR(ffvv.compiled_value_attributes, 3, 1)   AS posting                                                     -- 転記の許可
      , SUBSTR(ffvv.compiled_value_attributes, 1, 1)   AS regist                                                      -- 予算登録の許可
      , ffvv.description                               AS description                                                 -- 摘要
      , ffvv.attribute1                                AS attribute1                                                  -- 全attribute(1～50)
      , ffvv.attribute2                                AS attribute2
      , ffvv.attribute3                                AS attribute3
      , ffvv.attribute4                                AS attribute4
      , ffvv.attribute5                                AS attribute5
      , ffvv.attribute6                                AS attribute6
      , ffvv.attribute7                                AS attribute7
      , ffvv.attribute8                                AS attribute8
      , ffvv.attribute9                                AS attribute9
      , ffvv.attribute10                               AS attribute10
      , ffvv.attribute11                               AS attribute11
      , ffvv.attribute12                               AS attribute12
      , ffvv.attribute13                               AS attribute13
      , ffvv.attribute14                               AS attribute14
      , ffvv.attribute15                               AS attribute15
      , ffvv.attribute16                               AS attribute16
      , ffvv.attribute17                               AS attribute17
      , ffvv.attribute18                               AS attribute18
      , ffvv.attribute19                               AS attribute19
      , ffvv.attribute20                               AS attribute20
      , ffvv.attribute21                               AS attribute21
      , ffvv.attribute22                               AS attribute22
      , ffvv.attribute23                               AS attribute23
      , ffvv.attribute24                               AS attribute24
      , ffvv.attribute25                               AS attribute25
      , ffvv.attribute26                               AS attribute26
      , ffvv.attribute27                               AS attribute27
      , ffvv.attribute28                               AS attribute28
      , ffvv.attribute29                               AS attribute29
      , ffvv.attribute30                               AS attribute30
      , ffvv.attribute31                               AS attribute31
      , ffvv.attribute32                               AS attribute32
      , ffvv.attribute33                               AS attribute33
      , ffvv.attribute34                               AS attribute34
      , ffvv.attribute35                               AS attribute35
      , ffvv.attribute36                               AS attribute36
      , ffvv.attribute37                               AS attribute37
      , ffvv.attribute38                               AS attribute38
      , ffvv.attribute39                               AS attribute39
      , ffvv.attribute40                               AS attribute40
      , ffvv.attribute41                               AS attribute41
      , ffvv.attribute42                               AS attribute42
      , ffvv.attribute43                               AS attribute43
      , ffvv.attribute44                               AS attribute44
      , ffvv.attribute45                               AS attribute45
      , ffvv.attribute46                               AS attribute46
      , ffvv.attribute47                               AS attribute47
      , ffvv.attribute48                               AS attribute48
      , ffvv.attribute49                               AS attribute49
      , ffvv.attribute50                               AS attribute50
    FROM
        fnd_flex_value_sets ffvs
      , fnd_flex_values_vl  ffvv
    WHERE
        ffvs.flex_value_set_name = p_flex_value_set_name
    AND ffvs.flex_value_set_id   = ffvv.flex_value_set_id
    AND ( gd_pre_process_date is null or ffvv.last_update_date > gd_pre_process_date )
    AND SUBSTR(ffvv.flex_value, -1) != CHR(9)
    ORDER BY
      ffvv.flex_value;           -- 値
--
  -- (2)-1. AFF（部門、または勘定科目）の値セットIDを抽出する。
  -- =============================================================================================================
  CURSOR c_outbound_data2_id_cur(p_flex_value_set_name IN VARCHAR2)
  IS
    SELECT
      ffvs.flex_value_set_id  AS flex_value_set_id
    FROM
      fnd_flex_value_sets  ffvs
    WHERE
      ffvs.flex_value_set_name = p_flex_value_set_name
    AND EXISTS (
          SELECT
              1
          FROM
              fnd_flex_value_hierarchies  ffvh
          WHERE
              ffvs.flex_value_set_id = ffvh.flex_value_set_id
          AND ( gd_pre_process_date is null or ffvh.last_update_date > gd_pre_process_date )
        );
--
  --(2)-2. AFF（部門、勘定科目）階層の値セットIDより連携データを抽出する。
  -- =============================================================================================================
  CURSOR c_outbound_data2_cur( p_value_set_id IN NUMBER )
  IS
    WITH hierarchy_list AS (
       -- 階層情報を取得
       SELECT
            ffvnh.parent_flex_value  AS parent_flex_value
          , ffvv.flex_value          AS flex_value
          , ffvv.summary_flag        AS summary_flag
       FROM
            fnd_flex_value_norm_hierarchy  ffvnh
          , fnd_flex_values_vl             ffvv
       WHERE
           ffvv.flex_value_set_id = p_value_set_id
       AND ffvv.flex_value_set_id = ffvnh.flex_value_set_id
       AND (( ffvv.summary_flag = 'Y' AND ffvnh.range_attribute = 'P' ) OR
            ( ffvv.summary_flag = 'N' AND ffvnh.range_attribute = 'C' ))
       AND ffvv.flex_value BETWEEN ffvnh.child_flex_value_low and ffvnh.child_flex_value_high
     ) ,base_list AS (
     -- 最上位を取得
     SELECT
          DISTINCT
          NULL                   AS parent_flex_value
        , hl1.parent_flex_value  AS flex_value
        , 'Y'                    AS summary_flag
     FROM
         hierarchy_list  hl1
     WHERE
         NOT EXISTS (
               SELECT 1
               FROM   hierarchy_list  hl2
               WHERE  hl2.flex_value = hl1.parent_flex_value
         )
     --
     UNION ALL
     -- 最上位より配下を取得
     SELECT
          hl3.parent_flex_value  AS parent_flex_value
        , hl3.flex_value         AS flex_value
        , hl3.summary_flag       AS summary_flag
     FROM
         hierarchy_list  hl3
     )
     --
     SELECT
         NVL( bl1.parent_flex_value, 'None' )   AS parent_flex_value  -- 親値
       , bl1.flex_value                         AS flex_value         -- 値
       , DECODE( bl1.summary_flag
                   , 'Y'
                   , TO_CHAR(level)
                   , '31'
         )                                      AS depth              -- depth
     FROM
       base_list  bl1
     START WITH
       bl1.parent_flex_value is null
     CONNECT BY
       PRIOR bl1.flex_value = bl1.parent_flex_value
     ORDER BY
         level
       , bl1.parent_flex_value
       , bl1.flex_value;
--
  -- (3) AFF（勘定科目、補助科目）の関連値より連携データを抽出する。
  -- =============================================================================================================
  CURSOR c_outbound_data3_cur(p_flex_value_set_name IN VARCHAR2)
  IS
    SELECT
        cv_aff_acc                                     AS cv_aff_acc               -- 固定値：（勘定科目）
      , ffvs.flex_value_set_name                       AS flex_value_set_name      -- 値セット名
      , ffvv.parent_flex_value_low                     AS parent_flex_value_low    -- 親値
      , ffvv.parent_flex_value_low || ffvv.flex_value  AS flex_value               -- 親値+値
      , ffvv.enabled_flag                                                          -- 有効フラグ
    FROM
        fnd_flex_value_sets ffvs
      , fnd_flex_values_vl  ffvv
    WHERE
      ffvs.flex_value_set_name = p_flex_value_set_name
    AND ffvs.flex_value_set_id = ffvv.flex_value_set_id
    AND ( gd_pre_process_date IS NULL OR ffvv.last_update_date > gd_pre_process_date )
    ORDER BY
      ffvv.flex_value;
--
  -- AFFデータを格納するテーブル型の定義
  gt_aff_data1_tbl_rec      c_outbound_data1_cur%ROWTYPE;           -- AFF値取得
  gt_aff_data2_tbl_rec      c_outbound_data2_cur%ROWTYPE;           -- AFF階層取得
  gt_aff_data3_tbl_rec      c_outbound_data3_cur%ROWTYPE;           -- AFF関連値取得
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理（パラメータチェック・プロファイル取得）(A-1)
   ***********************************************************************************/
  PROCEDURE init(
      iv_flex_value_set_name  IN  VARCHAR2     -- 値セット名
    , ov_errbuf               OUT VARCHAR2     -- エラー・メッセージ            # 固定 #
    , ov_retcode              OUT VARCHAR2     -- リターン・コード              # 固定 #
    , ov_errmsg               OUT VARCHAR2)    -- ユーザー・エラー・メッセージ  # 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf    VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode   VARCHAR2(1);     -- リターン・コード
    lv_errmsg    VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_cnt       NUMBER;                                             -- 件数
    lv_msg       VARCHAR(2);                                         -- MSG No.
    lv_msgbuf    VARCHAR2(5000);                                     -- ユーザー・メッセージ
--
    -- ファイル出力関連
    lb_fexists          BOOLEAN;                                     -- ファイルが存在するかどうか
    ln_file_size        NUMBER;                                      -- ファイルの長さ
    ln_block_size       NUMBER;                                      -- ファイルシステムのブロックサイズ
--
    -- *** ローカル・カーソル ***
    -- OIC連携処理管理テーブル（排他）
    CURSOR c_prog_name_cur IS
      SELECT xoipm.pre_process_date          AS pre_process_date     -- 前回処理日時
      FROM   xxccp_oic_if_process_mng xoipm                          -- OIC連携処理管理テーブル
      WHERE  xoipm.program_name = iv_flex_value_set_name             -- 値セット名
      FOR UPDATE NOWAIT;
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
--
    -- ===================================
    -- A-1-1．入力パラメータをチェックする
    -- ===================================
--
    -- (1) 入力パラメータ出力
    -- ===================================================================
    gv_f_value_set_name := xxccp_common_pkg.get_msg(
                           iv_application  => cv_msg_kbn_cmm     -- 'XXCMM'
                         , iv_name         => cv_msg_cmm1_60043  -- パラメータ名（値セット名）
                         );
--
    lv_msgbuf := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_cmm           -- 'XXCMM'
                    , iv_name         => cv_msg_cmm1_60001        -- パラメータ出力メッセージ
                    , iv_token_name1  => cv_tkn_param_name        -- トークン(PARAM_NAME)
                    , iv_token_value1 => gv_f_value_set_name      -- 値セット名
                    , iv_token_name2  => cv_tkn_param_val         -- トークン(PARAM_VAL)
                    , iv_token_value2 => iv_flex_value_set_name   -- パラメータ（値セット名）
                   );
    -- メッセージ出力
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => lv_msgbuf
    );
    -- ログ出力
    FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
      , buff   => lv_msgbuf
    );
--
    -- (2) 入力パラメータ必須チェック
    -- ===================================================================
    IF ( iv_flex_value_set_name IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(  cv_msg_kbn_cmm     -- 'XXCMM'
                                                    , cv_msg_cmm1_60048  -- パラメータ必須エラー
                                                    , cv_tkn_param_name  -- トークン'PARAM_NAME'
                                                    , cv_msg_cmm1_60043  -- パラメータ名（値セット名）
                                                   )
                                                  , 1
                                                  , 5000);
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- (3) 値セット存在チェック
    -- ===================================================================
    -- 入力パラメータ「値セット名」が値セットテーブルに存在するかチェックする。
    SELECT COUNT(1) AS count
    INTO   ln_cnt
    FROM   fnd_flex_value_sets ffvs
    WHERE  ffvs.flex_value_set_name = iv_flex_value_set_name        -- パラメータ名（値セット名）
    AND    ffvs.flex_value_set_name in ( cv_aff_cmp, cv_aff_dpt, cv_aff_acc, cv_aff_sub, cv_aff_btp, cv_aff_pat );  -- 対象AFF
--
    IF ( ln_cnt = 0 ) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_msg_kbn_cmm     -- アドオン：マスタ・経理・共通のアプリケーション短縮名
                          , iv_name         => cv_msg_cmm1_60002  -- 値セット名該当なしエラーメッセージ
                         );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-1-2．プロファイル値を取得する
    -- ===============================
--
    -- 1.プロファイルからXXCMM:OIC連携データファイル格納ディレクトリ名取得
    -- ===================================================================
    gv_data_filedir := FND_PROFILE.VALUE( cv_data_filedir );
    -- プロファイル取得エラー時
    IF ( gv_data_filedir IS NULL ) THEN
      lv_errmsg := SUBSTRB(cv_msg1 || xxccp_common_pkg.get_msg(  cv_msg_kbn_cmm     -- 'XXCMM'
                                                               , cv_msg_cmm1_00002  -- プロファイル取得エラー
                                                               , cv_tkn_ng_profile  -- トークン'NG_PROFILE'
                                                               , cv_data_filedir
                                                              )
                                                             , 1
                                                             , 5000);
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 2.プロファイルからXXCMM:AFF値連携データファイル名（OIC連携）取得
    -- ===================================================================
    gv_data_filename1 := FND_PROFILE.VALUE( cv_data_filename1 );
    -- プロファイル取得エラー時
    IF ( gv_data_filename1 IS NULL ) THEN
      lv_errmsg := SUBSTRB(cv_msg2 || xxccp_common_pkg.get_msg(  cv_msg_kbn_cmm     -- 'XXCMM'
                                                               , cv_msg_cmm1_00002  -- プロファイル取得エラー
                                                               , cv_tkn_ng_profile  -- トークン'NG_PROFILE'
                                                               , cv_data_filename1
                                                              )
                                                             , 1
                                                             , 5000);
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 3.プロファイルからXXCMM:AFF階層連携データファイル名（OIC連携）取得
    -- ===================================================================
    gv_data_filename2 := FND_PROFILE.VALUE( cv_data_filename2 );
    -- プロファイル取得エラー時
    IF ( gv_data_filename2 IS NULL ) THEN
      lv_errmsg := SUBSTRB(cv_msg3 || xxccp_common_pkg.get_msg(  cv_msg_kbn_cmm      -- 'XXCMM'
                                                               , cv_msg_cmm1_00002   -- プロファイル取得エラー
                                                               , cv_tkn_ng_profile   -- トークン'NG_PROFILE'
                                                               , cv_data_filename2
                                                              )
                                                             , 1
                                                             , 5000);
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 4.プロファイルからXXCMM:AFF関連値連携データファイル名（OIC連携）取得
    -- ===================================================================
    gv_data_filename3 := FND_PROFILE.VALUE( cv_data_filename3 );
    -- プロファイル取得エラー時
    IF ( gv_data_filename3 IS NULL ) THEN
      lv_errmsg := SUBSTRB(cv_msg4 || xxccp_common_pkg.get_msg(  cv_msg_kbn_cmm      -- 'XXCMM'
                                                               , cv_msg_cmm1_00002   -- プロファイル取得エラー
                                                               , cv_tkn_ng_profile   -- トークン'NG_PROFILE'
                                                               , cv_data_filename3
                                                              )
                                                             , 1
                                                             , 5000);
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 5.プロファイルからXXCMM:ツリーバージョン開始日取得
    -- ===============================================================
    gd_tv_start_date := TO_DATE(FND_PROFILE.VALUE( cv_tv_start_date ), cv_date_ymd);
    -- プロファイル取得エラー時
    IF ( gd_tv_start_date IS NULL ) THEN
      lv_errmsg := SUBSTRB(cv_msg5 || xxccp_common_pkg.get_msg(  cv_msg_kbn_cmm      -- 'XXCMM'
                                                               , cv_msg_cmm1_00002   -- プロファイル取得エラー
                                                               , cv_tkn_ng_profile   -- トークン'NG_PROFILE'
                                                               , cv_tv_start_date
                                                              )
                                                             , 1
                                                             , 5000);
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ====================================================================================================
    -- A-1-3．プロファイル値「XXCMM:OIC連携データファイル格納ディレクトリ名」からディレクトリパスを取得する
    -- ====================================================================================================
    BEGIN
      SELECT RTRIM( ad.directory_path , cv_msg_slash )   AS  directory_path  -- ディレクトリパス
      INTO   gv_file_path
      FROM   all_directories  ad
      WHERE  ad.directory_name = gv_data_filedir;                         -- プロファイル値「XXCMM:OIC連携データファイル格納ディレクトリ名」
    EXCEPTION
      WHEN OTHERS THEN
        -- ディレクトリパス取得エラーメッセージ
        lv_errmsg := SUBSTRB(cv_msg1 || xxccp_common_pkg.get_msg(  cv_msg_kbn_coi         -- 'XXCOI'
                                                                 , cv_msg_coi1_00029      -- ディレクトリパス取得エラー
                                                                 , cv_tkn_dir_tok         -- トークン'DIR_TOK'
                                                                 , gv_data_filedir        -- XXCMM:OIC連携データファイル格納ディレクトリ名
                                                                )
                                                               , 1
                                                               , 5000);
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- ディレクトリパス取得エラーメッセージ
    -- directory_nameは登録されているが、directory_pathが空白の時
    IF ( gv_file_path IS NULL ) THEN
      lv_errmsg := SUBSTRB(cv_msg2 || xxccp_common_pkg.get_msg(  cv_msg_kbn_coi         -- 'XXCOI'
                                                               , cv_msg_coi1_00029      -- ディレクトリパス取得エラー
                                                               , cv_tkn_dir_tok         -- トークン'DIR_TOK'
                                                               , gv_data_filedir        -- XXCMM:OIC連携データファイル格納ディレクトリ名
                                                              )
                                                             , 1
                                                             , 5000);
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ====================================================================================================
    -- A-1-4．ファイル名に識別番号を付与し、ファイルパス/ファイル名で出力する
    -- ====================================================================================================
    gv_file_path := gv_file_path || cv_msg_slash;                   -- ファイルパス/
    CASE WHEN iv_flex_value_set_name = cv_aff_cmp THEN
           gv_data_filename1 := REPLACE( gv_data_filename1, cv_2nd_nm) || cv_fno_cmp || cv_2nd_nm;    -- 会社
           gv_data_filename2 := REPLACE( gv_data_filename2, cv_2nd_nm) || cv_fno_cmp || cv_2nd_nm;
           gv_data_filename3 := REPLACE( gv_data_filename3, cv_2nd_nm) || cv_fno_cmp || cv_2nd_nm;
         WHEN iv_flex_value_set_name = cv_aff_dpt THEN
           gv_data_filename1 := REPLACE( gv_data_filename1, cv_2nd_nm) || cv_fno_dpt || cv_2nd_nm;    -- 部門
           gv_data_filename2 := REPLACE( gv_data_filename2, cv_2nd_nm) || cv_fno_dpt || cv_2nd_nm;
           gv_data_filename3 := REPLACE( gv_data_filename3, cv_2nd_nm) || cv_fno_dpt || cv_2nd_nm;
         WHEN iv_flex_value_set_name = cv_aff_acc THEN
           gv_data_filename1 := REPLACE( gv_data_filename1, cv_2nd_nm) || cv_fno_acc || cv_2nd_nm;    -- 勘定科目
           gv_data_filename2 := REPLACE( gv_data_filename2, cv_2nd_nm) || cv_fno_acc || cv_2nd_nm;
           gv_data_filename3 := REPLACE( gv_data_filename3, cv_2nd_nm) || cv_fno_acc || cv_2nd_nm;
         WHEN iv_flex_value_set_name = cv_aff_sub THEN
           gv_data_filename1 := REPLACE( gv_data_filename1, cv_2nd_nm) || cv_fno_sub || cv_2nd_nm;    -- 補助科目
           gv_data_filename2 := REPLACE( gv_data_filename2, cv_2nd_nm) || cv_fno_sub || cv_2nd_nm;
           gv_data_filename3 := REPLACE( gv_data_filename3, cv_2nd_nm) || cv_fno_sub || cv_2nd_nm;
         WHEN iv_flex_value_set_name = cv_aff_btp THEN
           gv_data_filename1 := REPLACE( gv_data_filename1, cv_2nd_nm) || cv_fno_btp || cv_2nd_nm;    -- 企業コード
           gv_data_filename2 := REPLACE( gv_data_filename2, cv_2nd_nm) || cv_fno_btp || cv_2nd_nm;
           gv_data_filename3 := REPLACE( gv_data_filename3, cv_2nd_nm) || cv_fno_btp || cv_2nd_nm;
         WHEN iv_flex_value_set_name = cv_aff_pat THEN
           gv_data_filename1 := REPLACE( gv_data_filename1, cv_2nd_nm) || cv_fno_pat || cv_2nd_nm;    -- 顧客コード
           gv_data_filename2 := REPLACE( gv_data_filename2, cv_2nd_nm) || cv_fno_pat || cv_2nd_nm;
           gv_data_filename3 := REPLACE( gv_data_filename3, cv_2nd_nm) || cv_fno_pat || cv_2nd_nm;
         ELSE
           NULL;
    END CASE;
--
    -- 1) XXCMM:AFF値連携データファイル
    -- =================================
    lv_msgbuf := xxccp_common_pkg.get_msg(
                                           iv_application  => cv_msg_kbn_cmm                     -- 'XXCMM'
                                         , iv_name         => cv_msg_cmm1_60003                  -- IFファイル名出力メッセージ
                                         , iv_token_name1  => cv_tkn_file_name                   -- トークン(FILE_NAME)
                                         , iv_token_value1 => gv_file_path || gv_data_filename1  -- ファイルパス/AFF値連携データファイル名
                                         );
    -- メッセージ出力
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => lv_msgbuf
    );
--
    -- 2) XXCMM:AFF階層連携データファイル
    -- =================================
    lv_msgbuf := xxccp_common_pkg.get_msg(
                                           iv_application  => cv_msg_kbn_cmm                     -- 'XXCMM'
                                         , iv_name         => cv_msg_cmm1_60003                  -- IFファイル名出力メッセージ
                                         , iv_token_name1  => cv_tkn_file_name                   -- トークン(FILE_NAME)
                                         , iv_token_value1 => gv_file_path || gv_data_filename2  -- ファイルパス/XCMM:AFF階層連携データファイル名
                                         );
    -- メッセージ出力
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => lv_msgbuf
    );
--
    -- 3) XXCMM:AFF関連値連携データファイル
    -- =================================
    lv_msgbuf := xxccp_common_pkg.get_msg(
                                           iv_application  => cv_msg_kbn_cmm                     -- 'XXCMM'
                                         , iv_name         => cv_msg_cmm1_60003                  -- IFファイル名出力メッセージ
                                         , iv_token_name1  => cv_tkn_file_name                   -- トークン(FILE_NAME)
                                         , iv_token_value1 => gv_file_path || gv_data_filename3  -- ファイルパス/XXCMM:AFF関連値連携データファイル名
                                         );
    -- メッセージ出力
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => lv_msgbuf
    );
    -- 空行挿入
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
--
    -- ====================================================================
    -- A-1-5． 既に同一ファイルが存在していないかファイル数分チェックを行う
    -- ====================================================================
--
    -- 1) XXCMM:AFF値連携データファイル
    -- =================================
    UTL_FILE.FGETATTR( gv_data_filedir
                     , gv_data_filename1                                  -- AFF値連携データファイル名
                     , lb_fexists
                     , ln_file_size
                     , ln_block_size );
--
    -- 同一ファイル存在エラーメッセージ
    IF ( lb_fexists ) THEN
      lv_errmsg := SUBSTRB(cv_msg1 || xxccp_common_pkg.get_msg(  cv_msg_kbn_cmm     -- 'XXCMM'
                                                               , cv_msg_cmm1_60004  -- 同一ファイル存在エラーメッセージ
                                                              )
                                                             , 1
                                                             , 5000);
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 2) XCMM:AFF階層連携データファイル
    -- =================================
    UTL_FILE.FGETATTR( gv_data_filedir
                     , gv_data_filename2                                  -- AFF階層連携データファイル名
                     , lb_fexists
                     , ln_file_size
                     , ln_block_size );
--
    -- 同一ファイル存在エラーメッセージ
    IF ( lb_fexists ) THEN
      lv_errmsg := SUBSTRB(cv_msg2 || xxccp_common_pkg.get_msg(  cv_msg_kbn_cmm     -- 'XXCMM'
                                                               , cv_msg_cmm1_60004  -- 同一ファイル存在エラーメッセージ
                                                              )
                                                             , 1
                                                             , 5000);
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 3) XXCMM:AFF関連値連携データファイル
    -- =================================
    UTL_FILE.FGETATTR( gv_data_filedir
                     , gv_data_filename3                                  -- AFF関連値連携データファイル名
                     , lb_fexists
                     , ln_file_size
                     , ln_block_size );
--
    -- 同一ファイル存在エラーメッセージ
    IF ( lb_fexists ) THEN
      lv_errmsg := SUBSTRB(cv_msg3 || xxccp_common_pkg.get_msg(  cv_msg_kbn_cmm     -- 'XXCMM'
                                                               , cv_msg_cmm1_60004  -- 同一ファイル存在エラーメッセージ
                                                              )
                                                             , 1
                                                             , 5000);
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ===========================================================================================
    -- A-1-6．当機能の「コンカレントプログラム名」、および「前回処理日時」を取得する。（排他処理）
    -- ===========================================================================================
    BEGIN
      OPEN  c_prog_name_cur;
      FETCH c_prog_name_cur INTO gd_pre_process_date;               -- 前回処理日時
      CLOSE c_prog_name_cur;
--
    EXCEPTION
      WHEN global_lock_expt THEN  -- テーブルロックエラー
        IF ( c_prog_name_cur%ISOPEN ) THEN
          -- カーソルのクローズ
          CLOSE c_prog_name_cur;
        END IF;
--
        lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_kbn_cmm         -- 'XXCMM'
                        , iv_name         => cv_msg_cmm1_00008      -- ロックエラーメッセージ
                        , iv_token_name1  => cv_tkn_ng_table        -- トークン(NG_TABLE)
                        , iv_token_value1 => cv_msg_cmm1_60008      -- OIC連携処理管理テーブル
                       );
--
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      WHEN OTHERS THEN
        IF ( c_prog_name_cur%ISOPEN ) THEN
          -- カーソルのクローズ
          CLOSE c_prog_name_cur;
        END IF;
        RAISE global_api_others_expt;
    END;
--
    -- ========================================
    -- A-1-7．今回処理日時（SYSDATE）を取得する
    -- ========================================
    gd_process_date := cd_creation_date;                                    -- 今回処理日時
--
    -- ===========================================
    -- A-1-8．前回、および今回の処理日時を出力する
    -- ===========================================
    lv_msgbuf := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_cmm                                -- 'XXCMM'
                    , iv_name         => cv_msg_cmm1_60005                             -- 処理日時出力メッセージ
                    , iv_token_name1  => cv_tkn_date1                                  -- トークン(DATE1)
                    , iv_token_value1 => TO_CHAR(gd_pre_process_date, cv_proc_date_fm) -- 前回処理日時
                    , iv_token_name2  => cv_tkn_date2                                  -- トークン(DATE2)
                    , iv_token_value2 => TO_CHAR(gd_process_date, cv_proc_date_fm)     -- 今回処理日時
                   );
    -- メッセージ出力
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => lv_msgbuf
    );
    -- 空行挿入
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
--
    -- ==========================================
    -- A-1-9．すべてのOIC連携ファイルオープンする
    -- ==========================================
    BEGIN
        -- 1.ファイルオープン（AFF値連携データファイル）
        lv_msg := cv_msg1;
        gf_file_hand1 := UTL_FILE.FOPEN(
                                         gv_data_filedir            -- ディレクトリパス
                                       , gv_data_filename1          -- ファイル名
                                       , cv_open_mode_w             -- オープンモード
                                       , cn_max_linesize            -- ファイル行サイズ
                                       );
--
        -- 2.ファイルオープン（AFF階層連携データファイル）
        lv_msg := cv_msg2;
        gf_file_hand2 := UTL_FILE.FOPEN(
                                         gv_data_filedir            -- ディレクトリパス
                                       , gv_data_filename2          -- ファイル名
                                       , cv_open_mode_w             -- オープンモード
                                       , cn_max_linesize            -- ファイル行サイズ
                                       );
--
        -- 3.ファイルオープン（AFF関連値連携データファイル）
        lv_msg := cv_msg3;
        gf_file_hand3 := UTL_FILE.FOPEN(
                                         gv_data_filedir            -- ディレクトリパス
                                       , gv_data_filename3          -- ファイル名
                                       , cv_open_mode_w             -- オープンモード
                                       , cn_max_linesize            -- ファイル行サイズ
                                       );
--
    EXCEPTION
      WHEN UTL_FILE.INVALID_FILENAME THEN
        lv_errmsg := SUBSTRB(lv_msg || xxccp_common_pkg.get_msg(  cv_msg_kbn_cmm      -- 'XXCMM'
                                                                , cv_msg_cmm1_00487   -- ファイルオープンエラー
                                                                , cv_tkn_sqlerrm      -- トークン'SQLERRM'
                                                                , SQLERRM             -- SQLERRM（ファイル名が無効）
                                                               )
                                                              , 1
                                                              , 5000);
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
--
      WHEN UTL_FILE.INVALID_OPERATION THEN
        lv_errmsg := SUBSTRB(lv_msg || xxccp_common_pkg.get_msg(  cv_msg_kbn_cmm      -- 'XXCMM'
                                                                , cv_msg_cmm1_00487   -- ファイルオープンエラー
                                                                , cv_tkn_sqlerrm      -- トークン'SQLERRM'
                                                                , SQLERRM             -- SQLERRM（ファイルをオープンできない）
                                                               )
                                                              , 1
                                                              , 5000);
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
--
      WHEN OTHERS THEN
        lv_errmsg := SUBSTRB(lv_msg || xxccp_common_pkg.get_msg(  cv_msg_kbn_cmm      -- 'XXCMM'
                                                                , cv_msg_cmm1_00487   -- ファイルオープンエラー
                                                                , cv_tkn_sqlerrm      -- トークン'SQLERRM'
                                                                , SQLERRM             -- SQLERRM（その他）
                                                               )
                                                              , 1
                                                              , 5000);
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : data_outbound_proc1
   * Description      : AFF値の抽出・ファイル出力処理 (A-2)
   ***********************************************************************************/
  PROCEDURE data_outbound_proc1(
      iv_flex_value_set_name  IN  VARCHAR2     -- 値セット名
    , ov_errbuf               OUT VARCHAR2     -- エラー・メッセージ            # 固定 #
    , ov_retcode              OUT VARCHAR2     -- リターン・コード              # 固定 #
    , ov_errmsg               OUT VARCHAR2)    -- ユーザー・エラー・メッセージ  # 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'data_outbound_proc1'; -- プログラム名
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
    cv_space          CONSTANT VARCHAR2(1)  := ' ';                         -- LF置換単語（FBDIファイル用文字列置換）
    cv_delimiter      CONSTANT VARCHAR2(1)  := ',';                         -- CSV区切り文字
    cv_fixed_n        CONSTANT VARCHAR2(1)  := 'N';                         -- 固定出力文字
--
    -- *** ローカル変数 ***
    ln_cnt            NUMBER := 0;                                          -- 各AFF取得の件数
    lv_csv_text       VARCHAR2(30000)           DEFAULT NULL;               -- 出力１行分文字列変数
    lv_posting        VARCHAR2(1);                                          -- 転記の許可
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- =======================================
    -- A-2-1.AFF値連携データの抽出
    -- =======================================
    <<data_loop>>
    FOR gt_aff_data1_tbl_rec IN c_outbound_data1_cur( iv_flex_value_set_name ) LOOP
      -- ファイル出力行列編集
      -- 転記の許可が'Y'、かつ、SUMMARY_FLAG（要約フラグ）が'Y'の場合、'N'へ変換する。
      IF ( gt_aff_data1_tbl_rec.posting = 'Y' AND gt_aff_data1_tbl_rec.summary_flag = 'Y' ) THEN
        lv_posting := cv_fixed_n;
      ELSE
        lv_posting := gt_aff_data1_tbl_rec.posting;
      END IF;
      lv_csv_text := 
           xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.flex_value_set_name, cv_space ) || cv_delimiter  --  1.値セット名
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.flex_value, cv_space )   || cv_delimiter         --  2.値
        || gt_aff_data1_tbl_rec.start_date_active || cv_delimiter                                                   --  3.開始日
        || gt_aff_data1_tbl_rec.end_date_active || cv_delimiter                                                     --  4.終了日
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.summary_flag, cv_space ) || cv_delimiter         --  5.要約
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.enabled_flag, cv_space ) || cv_delimiter         --  6.有効
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.acc_type, cv_space )     || cv_delimiter         --  7.勘定科目タイプ
        || xxccp_oiccommon_pkg.to_csv_string( lv_posting, cv_space )                        || cv_delimiter         --  8.転記の許可
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.regist, cv_space )       || cv_delimiter         --  9.予算登録の許可
        || cv_fixed_n || cv_delimiter                                                                               -- 10.固定値：N
        || cv_fixed_n || cv_delimiter                                                                               -- 11.固定値：N
        || NULL || cv_delimiter                                                                                     -- 12.Financial Category
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.description, cv_space ) || cv_delimiter          -- 13.Description US
        || NULL || cv_delimiter                                                                                     -- 14.Description AR
        || NULL || cv_delimiter                                                                                     -- 15.Description CS
        || NULL || cv_delimiter                                                                                     -- 16.Description D
        || NULL || cv_delimiter                                                                                     -- 17.Description DK
        || NULL || cv_delimiter                                                                                     -- 18.Description E
        || NULL || cv_delimiter                                                                                     -- 19.Description EL
        || NULL || cv_delimiter                                                                                     -- 20.Description ES
        || NULL || cv_delimiter                                                                                     -- 21.Description F
        || NULL || cv_delimiter                                                                                     -- 22.Description FR
        || NULL || cv_delimiter                                                                                     -- 23.Description HR
        || NULL || cv_delimiter                                                                                     -- 24.Description HU
        || NULL || cv_delimiter                                                                                     -- 25.Description I
        || NULL || cv_delimiter                                                                                     -- 26.Description IS
        || NULL || cv_delimiter                                                                                     -- 27.Description IW
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.description, cv_space ) || cv_delimiter          -- 28.摘要
        || NULL || cv_delimiter                                                                                     -- 29.Description KO
        || NULL || cv_delimiter                                                                                     -- 30.Description NL
        || NULL || cv_delimiter                                                                                     -- 31.Description LT
        || NULL || cv_delimiter                                                                                     -- 32.Description PL
        || NULL || cv_delimiter                                                                                     -- 33.Description PT
        || NULL || cv_delimiter                                                                                     -- 34.Description PTB
        || NULL || cv_delimiter                                                                                     -- 35.Description N
        || NULL || cv_delimiter                                                                                     -- 36.Description RO
        || NULL || cv_delimiter                                                                                     -- 37.Description RU
        || NULL || cv_delimiter                                                                                     -- 38.Description S
        || NULL || cv_delimiter                                                                                     -- 39.Description SF
        || NULL || cv_delimiter                                                                                     -- 40.Description SK
        || NULL || cv_delimiter                                                                                     -- 41.Description SL
        || NULL || cv_delimiter                                                                                     -- 42.Description TH
        || NULL || cv_delimiter                                                                                     -- 43.Description TR
        || NULL || cv_delimiter                                                                                     -- 44.Description ZHS
        || NULL || cv_delimiter                                                                                     -- 45.Description ZHT
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.attribute1 , cv_space ) || cv_delimiter          -- 46.Attribute1
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.attribute2 , cv_space ) || cv_delimiter          -- 47.Attribute2
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.attribute3 , cv_space ) || cv_delimiter          -- 48.Attribute3
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.attribute4 , cv_space ) || cv_delimiter          -- 49.Attribute4
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.attribute5 , cv_space ) || cv_delimiter          -- 50.Attribute5
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.attribute6 , cv_space ) || cv_delimiter          -- 51.Attribute6
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.attribute7 , cv_space ) || cv_delimiter          -- 52.Attribute7
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.attribute8 , cv_space ) || cv_delimiter          -- 53.Attribute8
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.attribute9 , cv_space ) || cv_delimiter          -- 54.Attribute9
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.attribute10, cv_space ) || cv_delimiter          -- 55.Attribute10
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.attribute11, cv_space ) || cv_delimiter          -- 56.attribute11
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.attribute12, cv_space ) || cv_delimiter          -- 57.attribute12
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.attribute13, cv_space ) || cv_delimiter          -- 58.attribute13
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.attribute14, cv_space ) || cv_delimiter          -- 59.attribute14
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.attribute15, cv_space ) || cv_delimiter          -- 60.attribute15
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.attribute16, cv_space ) || cv_delimiter          -- 61.attribute16
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.attribute17, cv_space ) || cv_delimiter          -- 62.attribute17
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.attribute18, cv_space ) || cv_delimiter          -- 63.attribute18
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.attribute19, cv_space ) || cv_delimiter          -- 64.attribute19
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.attribute20, cv_space ) || cv_delimiter          -- 65.attribute20
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.attribute21, cv_space ) || cv_delimiter          -- 66.Attribute21
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.attribute22, cv_space ) || cv_delimiter          -- 67.Attribute22
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.attribute23, cv_space ) || cv_delimiter          -- 68.Attribute23
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.attribute24, cv_space ) || cv_delimiter          -- 69.Attribute24
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.attribute25, cv_space ) || cv_delimiter          -- 70.Attribute25
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.attribute26, cv_space ) || cv_delimiter          -- 71.Attribute26
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.attribute27, cv_space ) || cv_delimiter          -- 72.Attribute27
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.attribute28, cv_space ) || cv_delimiter          -- 73.Attribute28
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.attribute29, cv_space ) || cv_delimiter          -- 74.Attribute29
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.attribute30, cv_space ) || cv_delimiter          -- 75.Attribute30
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.attribute31, cv_space ) || cv_delimiter          -- 76.Attribute31
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.attribute32, cv_space ) || cv_delimiter          -- 77.Attribute32
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.attribute33, cv_space ) || cv_delimiter          -- 78.Attribute33
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.attribute34, cv_space ) || cv_delimiter          -- 79.Attribute34
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.attribute35, cv_space ) || cv_delimiter          -- 80.Attribute35
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.attribute36, cv_space ) || cv_delimiter          -- 81.Attribute36
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.attribute37, cv_space ) || cv_delimiter          -- 82.Attribute37
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.attribute38, cv_space ) || cv_delimiter          -- 83.Attribute38
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.attribute39, cv_space ) || cv_delimiter          -- 84.Attribute39
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.attribute40, cv_space ) || cv_delimiter          -- 85.Attribute40
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.attribute41, cv_space ) || cv_delimiter          -- 86.Attribute41
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.attribute42, cv_space ) || cv_delimiter          -- 87.Attribute42
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.attribute43, cv_space ) || cv_delimiter          -- 88.Attribute43
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.attribute44, cv_space ) || cv_delimiter          -- 89.Attribute44
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.attribute45, cv_space ) || cv_delimiter          -- 90.Attribute45
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.attribute46, cv_space ) || cv_delimiter          -- 91.Attribute46
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.attribute47, cv_space ) || cv_delimiter          -- 92.Attribute47
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.attribute48, cv_space ) || cv_delimiter          -- 93.Attribute48
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.attribute49, cv_space ) || cv_delimiter          -- 94.Attribute49
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.attribute50, cv_space ) || cv_delimiter          -- 95.Attribute50
        || NULL                                                                                                     -- 96.Data Source
      ;
--
      -- =======================================
      -- A-2-2.AFF値連携データのファイル出力
      -- =======================================
      -- ファイル書き込み
      UTL_FILE.PUT_LINE( gf_file_hand1, lv_csv_text ) ;
      ln_cnt := ln_cnt + 1 ;
    END LOOP data_loop;
--
    -- AFF値連携の対象件数をセット
    gn_target1_cnt := ln_cnt;                    -- AFF値連携の件数
    gn_target_cnt  := ln_cnt;                    -- 連携データの累計
    -- 正常件数 = 対象件数（総数）
    gn_normal_cnt  := gn_target_cnt;
--
  EXCEPTION
    WHEN UTL_FILE.WRITE_ERROR THEN
      -- ファイルクローズ
      IF ( UTL_FILE.IS_OPEN ( gf_file_hand1 )) THEN
        UTL_FILE.FCLOSE( gf_file_hand1 );
      END IF;
      lv_errmsg := SUBSTRB(cv_msg1 || xxccp_common_pkg.get_msg(  cv_msg_kbn_cmm      -- 'XXCMM'
                                                               , cv_msg_cmm1_00488   -- ファイル書き込みエラー
                                                               , cv_tkn_sqlerrm      -- トークン'SQLERRM'
                                                               , SQLERRM             -- SQLERRM
                                                              )
                                                             , 1
                                                             , 5000);
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- ファイルクローズ
      IF ( UTL_FILE.IS_OPEN ( gf_file_hand1 )) THEN
        UTL_FILE.FCLOSE( gf_file_hand1 );
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- ファイルクローズ
      IF ( UTL_FILE.IS_OPEN ( gf_file_hand1 )) THEN
        UTL_FILE.FCLOSE( gf_file_hand1 );
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END data_outbound_proc1;
--
  /**********************************************************************************
   * Procedure Name   : data_outbound_proc2
   * Description      : AFF階層の抽出・ファイル出力処理 (A-3)
   ***********************************************************************************/
  PROCEDURE data_outbound_proc2(
      iv_flex_value_set_name  IN  VARCHAR2     -- 値セット名
    , ov_errbuf               OUT VARCHAR2     -- エラー・メッセージ            # 固定 #
    , ov_retcode              OUT VARCHAR2     -- リターン・コード              # 固定 #
    , ov_errmsg               OUT VARCHAR2)    -- ユーザー・エラー・メッセージ  # 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'data_outbound_proc2'; -- プログラム名
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
    cv_space          CONSTANT VARCHAR2(1)  := ' ';                            -- LF置換単語（FBDIファイル用文字列置換）
    cv_delimiter      CONSTANT VARCHAR2(1)  := ',';                            -- CSV区切り文字
    cv_fixed_dpth     CONSTANT VARCHAR2(30) := 'XX03_DEPARTMENT_HIERARCHY';    -- 固定出力文字
    cv_fixed_dptv     CONSTANT VARCHAR2(30) := 'XX03_DEPARTMENT';              -- 固定出力文字
    cv_fixed_acch     CONSTANT VARCHAR2(30) := 'XX03_ACCOUNT_HIERARCHY';       -- 固定出力文字
    cv_fixed_accv     CONSTANT VARCHAR2(30) := 'XX03_ACCOUNT';                 -- 固定出力文字
    cv_fixed_dpth_t   CONSTANT VARCHAR2(30) := 'XX03_DEPARTMENT_HIERARCHY_T';  -- 固定出力文字(部門T)
--
--
    -- *** ローカル変数 ***
    ln_loop_cnt             NUMBER := 0;                                       -- ループカウンタ
    ln_cnt                  NUMBER := 0;                                       -- 各AFF取得の件数
    lv_csv_text             VARCHAR2(30000)           DEFAULT NULL;            -- 出力１行分文字列変数
    l_tree_code             VARCHAR2(30);                                      -- 2.Tree Code
    l_version_name          VARCHAR2(30);                                      -- 3.Tree Version Name
    ln_flex_value_set_id    fnd_flex_value_sets.flex_value_set_id%TYPE;        -- 値セットID
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- =======================================
    -- A-3-1.AFF階層連携データの抽出
    -- =======================================
    -- 入力パラメータ「値セット名」が部門（XX03_DEPARTMENT）、または勘定科目（XX03_ACCOUNT）の場合、抽出処理を行う。
--
    IF ( iv_flex_value_set_name = cv_aff_dpt OR iv_flex_value_set_name = cv_aff_acc ) THEN
      --(2)-1. 連携対象となる階層（値セットID）を取得する。
      OPEN  c_outbound_data2_id_cur( iv_flex_value_set_name );
      FETCH c_outbound_data2_id_cur INTO ln_flex_value_set_id;
      CLOSE c_outbound_data2_id_cur;
--
      --(2)-2. 部門の時、部門階層の値セットID毎に連携データを抽出する。
      IF ( iv_flex_value_set_name = cv_aff_dpt ) THEN
        ln_cnt := 0;
        <<data_loop>>
        FOR gt_aff_data2_tbl_rec IN c_outbound_data2_cur( ln_flex_value_set_id ) LOOP
          CASE WHEN gt_aff_data2_tbl_rec.flex_value        = 'T' THEN
                 l_tree_code    := cv_fixed_dpth_t;
                 l_version_name := cv_aff_dpt_t;
               WHEN gt_aff_data2_tbl_rec.parent_flex_value = 'T' THEN
                 l_tree_code    := cv_fixed_dpth_t;
                 l_version_name := cv_aff_dpt_t;
               ELSE
                 l_tree_code    := cv_fixed_dpth;
                 l_version_name := cv_aff_dpt;
          END CASE;
          -- ファイル出力行編集（部門）
          lv_csv_text :=
               cv_aff_dpt                                                                            || cv_delimiter  --  1.固定値
            || l_tree_code                                                                           || cv_delimiter  --  2.固定値
            || l_version_name                                                                        || cv_delimiter  --  3.固定値
            || TO_CHAR(gd_tv_start_date, cv_date_ymd)                                                || cv_delimiter  --  4.ツリーバージョン開始日
            || NULL                                                                                  || cv_delimiter  --  5.Tree Version End Date
            || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data2_tbl_rec.flex_value, cv_space )        || cv_delimiter  --  6.値
            || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data2_tbl_rec.parent_flex_value, cv_space ) || cv_delimiter  --  7.親値
            || gt_aff_data2_tbl_rec.depth                                                            || cv_delimiter  --  8.DEPTH
            || NULL                                                                                                   --  9.Label Short Name
          ;
          -- =================================
          -- AFF階層（部門）のファイル出力
          -- =================================
          -- ファイル書き込み
          UTL_FILE.PUT_LINE( gf_file_hand2, lv_csv_text ) ;
          ln_cnt := ln_cnt + 1 ;
        END LOOP data_loop;
--
        -- AFF階層（部門）連携の対象件数をセット
        gn_target2_dpt_cnt := ln_cnt;                       -- AFF階層（部門）連携の件数
        gn_target_cnt      := gn_target_cnt + ln_cnt;       -- 連携データの累計
        -- 正常件数 = 対象件数（総数）
        gn_normal_cnt      := gn_target_cnt;
--
      --(2)-3. 勘定科目の時、勘定科目階層の値セットID毎に連携データを抽出する。
      ELSE
        ln_cnt := 0;
        <<data_loop>>
        FOR gt_aff_data2_tbl_rec IN c_outbound_data2_cur( ln_flex_value_set_id ) LOOP
          -- ファイル出力行編集（勘定科目）
          lv_csv_text :=
               cv_aff_acc                                                                            || cv_delimiter  --  1.固定値
            || cv_fixed_acch                                                                         || cv_delimiter  --  2.固定値
            || cv_aff_acc                                                                            || cv_delimiter  --  3.固定値
            || TO_CHAR(gd_tv_start_date, cv_date_ymd)                                                || cv_delimiter  --  4.ツリーバージョン開始日
            || NULL                                                                                  || cv_delimiter  --  5.Tree Version End Date
            || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data2_tbl_rec.flex_value, cv_space )        || cv_delimiter  --  6.値
            || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data2_tbl_rec.parent_flex_value, cv_space ) || cv_delimiter  --  7.親値
            || gt_aff_data2_tbl_rec.depth                                                            || cv_delimiter  --  8.DEPTH
            || NULL                                                                                                   --  9.Label Short Name
          ;
--
          -- =================================
          -- AFF階層（勘定科目）のファイル出力
          -- =================================
          -- ファイル書き込み
          UTL_FILE.PUT_LINE( gf_file_hand2, lv_csv_text ) ;
          ln_cnt := ln_cnt + 1 ;
        END LOOP data_loop;
--
        -- AFF階層（勘定科目）連携の対象件数をセット
        gn_target2_acc_cnt := ln_cnt;                        -- AFF階層（勘定科目）連携の件数
        gn_target_cnt      := gn_target_cnt + ln_cnt;        -- 連携データの累計
        -- 正常件数 = 対象件数（総数）
        gn_normal_cnt      := gn_target_cnt;
      END IF;
--
    END IF;
--
  EXCEPTION
    WHEN UTL_FILE.WRITE_ERROR THEN
      -- ファイルクローズ
      IF ( UTL_FILE.IS_OPEN ( gf_file_hand2 )) THEN
        UTL_FILE.FCLOSE( gf_file_hand2 );
      END IF;
      lv_errmsg := SUBSTRB(cv_msg2 || xxccp_common_pkg.get_msg(  cv_msg_kbn_cmm      -- 'XXCMM'
                                                               , cv_msg_cmm1_00488   -- ファイル書き込みエラー
                                                               , cv_tkn_sqlerrm      -- トークン'SQLERRM'
                                                               , SQLERRM             -- SQLERRM
                                                              )
                                                             , 1
                                                             , 5000);
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- ファイルクローズ
      IF ( UTL_FILE.IS_OPEN ( gf_file_hand2 )) THEN
        UTL_FILE.FCLOSE( gf_file_hand2 );
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- ファイルクローズ
      IF ( UTL_FILE.IS_OPEN ( gf_file_hand2 )) THEN
        UTL_FILE.FCLOSE( gf_file_hand2 );
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END data_outbound_proc2;
--
  /**********************************************************************************
   * Procedure Name   : data_outbound_proc3
   * Description      : AFF関連値の抽出・ファイル出力処理 (A-4)
   ***********************************************************************************/
  PROCEDURE data_outbound_proc3(
      iv_flex_value_set_name  IN  VARCHAR2     -- 値セット名
    , ov_errbuf               OUT VARCHAR2     -- エラー・メッセージ            # 固定 #
    , ov_retcode              OUT VARCHAR2     -- リターン・コード              # 固定 #
    , ov_errmsg               OUT VARCHAR2)    -- ユーザー・エラー・メッセージ  # 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'data_outbound_proc3'; -- プログラム名
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
    cv_space          CONSTANT VARCHAR2(1)  := ' ';                         -- LF置換単語（FBDIファイル用文字列置換）
    cv_delimiter      CONSTANT VARCHAR2(1)  := '|';                         -- CSV区切り文字
    cv_fixed_hd1      CONSTANT VARCHAR2(30) := 'VALUE_SET_CODE1';           -- 固定出力文字（A3ヘッダー）
    cv_fixed_hd2      CONSTANT VARCHAR2(30) := 'VALUE_SET_CODE2';           -- 固定出力文字（A3ヘッダー）
    cv_fixed_hd3      CONSTANT VARCHAR2(30) := 'VALUE1';                    -- 固定出力文字（A3ヘッダー）
    cv_fixed_hd4      CONSTANT VARCHAR2(30) := 'VALUE2';                    -- 固定出力文字（A3ヘッダー）
    cv_fixed_hd5      CONSTANT VARCHAR2(30) := 'ENABLED_FLAG';              -- 固定出力文字（A3ヘッダー）
--
    -- *** ローカル変数 ***
    ln_cnt            NUMBER := 0;                                          -- 各AFF取得の件数
    lv_csv_text       VARCHAR2(30000)           DEFAULT NULL;               -- 出力１行分文字列変数
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- =======================================
    -- A-4-1.AFF関連値連携データの抽出
    -- =======================================
    -- 入力パラメータ「値セット名」が補助科目（XX03_SUB_ACCOUNT）の場合、抽出処理を行う。
--
    IF ( iv_flex_value_set_name = cv_aff_sub ) THEN
      ln_cnt := 0;
      <<data_loop>>
      FOR gt_aff_data3_tbl_rec IN c_outbound_data3_cur( iv_flex_value_set_name ) LOOP
        IF ( ln_cnt = 0 ) THEN
          -- ファイル出力行列編集（ヘッダー）
          lv_csv_text := cv_fixed_hd1 || cv_delimiter   --  1.固定値
            || cv_fixed_hd2 || cv_delimiter             --  2.固定値
            || cv_fixed_hd3 || cv_delimiter             --  3.固定値
            || cv_fixed_hd4 || cv_delimiter             --  4.固定値
            || cv_fixed_hd5                             --  5.固定値
          ;
          -- ファイル書き込み
          UTL_FILE.PUT_LINE( gf_file_hand3, lv_csv_text ) ;
        END IF;
--
        -- ファイル出力行列編集（データ行）
        lv_csv_text := gt_aff_data3_tbl_rec.cv_aff_acc  || cv_delimiter    --  1.固定値（勘定科目）
          || gt_aff_data3_tbl_rec.flex_value_set_name   || cv_delimiter    --  2.固定値（値セット名）
          || gt_aff_data3_tbl_rec.parent_flex_value_low || cv_delimiter    --  3.親値
          || gt_aff_data3_tbl_rec.flex_value            || cv_delimiter    --  4.値
          || gt_aff_data3_tbl_rec.enabled_flag                             --  5.有効
        ;
--
        -- =======================================
        -- A-4-2.AFF関連値連携データのファイル出力
        -- =======================================
        -- ファイル書き込み
        UTL_FILE.PUT_LINE( gf_file_hand3, lv_csv_text ) ;
        ln_cnt := ln_cnt + 1 ;
      END LOOP data_loop;
--
      -- AFF関連値連携の対象件数をセット
      gn_target3_cnt := ln_cnt;                                    -- AFF関連値連携の件数
      gn_target_cnt  := gn_target_cnt + ln_cnt;                    -- 連携データの累計
      -- 正常件数 = 対象件数（総数）
      gn_normal_cnt  := gn_target_cnt;
--
    END IF;
--
  EXCEPTION
    WHEN UTL_FILE.WRITE_ERROR THEN
      -- ファイルクローズ
      IF ( UTL_FILE.IS_OPEN ( gf_file_hand3 )) THEN
        UTL_FILE.FCLOSE( gf_file_hand3 );
      END IF;
      lv_errmsg := SUBSTRB(cv_msg3 || xxccp_common_pkg.get_msg(  cv_msg_kbn_cmm      -- 'XXCMM'
                                                               , cv_msg_cmm1_00488   -- ファイル書き込みエラー
                                                               , cv_tkn_sqlerrm      -- トークン'SQLERRM'
                                                               , SQLERRM             -- SQLERRM
                                                              )
                                                             , 1
                                                             , 5000);
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- ファイルクローズ
      IF ( UTL_FILE.IS_OPEN ( gf_file_hand3 )) THEN
        UTL_FILE.FCLOSE( gf_file_hand3 );
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- ファイルクローズ
      IF ( UTL_FILE.IS_OPEN ( gf_file_hand3 )) THEN
        UTL_FILE.FCLOSE( gf_file_hand3 );
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END data_outbound_proc3;
--
  /**********************************************************************************
   * Procedure Name   : upd_oic_ctrl_tbl
   * Description      : 管理テーブル登録・更新処理          (A-5)
   ***********************************************************************************/
  PROCEDURE upd_oic_ctrl_tbl(
      iv_flex_value_set_name  IN  VARCHAR2     -- 値セット名
    , ov_errbuf               OUT VARCHAR2     -- エラー・メッセージ            # 固定 #
    , ov_retcode              OUT VARCHAR2     -- リターン・コード              # 固定 #
    , ov_errmsg               OUT VARCHAR2)    -- ユーザー・エラー・メッセージ  # 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_oic_ctrl_tbl'; -- プログラム名
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
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ===============================
    -- OIC連携処理管理テーブル登録
    -- ===============================
    -- 前回処理日時がNULL（移行の時）は新規登録
    IF ( gd_pre_process_date IS NULL ) THEN
      BEGIN
        INSERT INTO xxccp_oic_if_process_mng(
           program_name
         , pre_process_date
         , created_by
         , creation_date
         , last_updated_by
         , last_update_date
         , last_update_login
         , request_id
         , program_application_id
         , program_id
         , program_update_date
        ) VALUES (
           iv_flex_value_set_name                 -- 値セット名
         , gd_process_date                        -- 今回処理日時
         , cn_created_by                          -- 作成者
         , cd_creation_date                       -- 作成日
         , cn_last_updated_by                     -- 最終更新者
         , cd_last_update_date                    -- 最終更新日
         , cn_last_update_login                   -- 最終更新ログイン
         , cn_request_id                          -- 要求ID
         , cn_program_application_id              -- コンカレント・プログラムのアプリケーションID
         , cn_program_id                          -- コンカレント・プログラムID
         , cd_program_update_date                 -- プログラムによる更新日
        );
      EXCEPTION
        WHEN OTHERS THEN
          -- 新規登録時のエラー
          lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(  cv_msg_kbn_cmm        -- 'XXCMM'
                                                        , cv_msg_cmm1_00054     -- 挿入エラー
                                                        , cv_tkn_table          -- トークン'TABLE'
                                                        , cv_msg_cmm1_60008     -- OIC連携処理管理テーブル
                                                        , cv_tkn_err_msg        -- トークン'ERR_MSG'
                                                        , SQLERRM               -- SQLERRM
                                                       )
                                                      , 1
                                                      , 5000);
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
    -- ==================================
    -- 前回処理日時を取得した時は更新処理
    -- ==================================
    ELSE
      BEGIN
        UPDATE xxccp_oic_if_process_mng
        SET    pre_process_date        = gd_process_date,             -- 今回処理日時
               last_updated_by         = cn_last_updated_by,          -- 最終更新者
               last_update_date        = cd_last_update_date,         -- 最終更新日
               last_update_login       = cn_last_update_login,        -- 最終更新ログイン
               request_id              = cn_request_id,               -- 要求ID
               program_application_id  = cn_program_application_id,   -- コンカレント・プログラム・アプリケーションID
               program_id              = cn_program_id,               -- コンカレント・プログラムID
               program_update_date     = cd_program_update_date       -- プログラム更新日
        WHERE  program_name = iv_flex_value_set_name;                 -- 値セット名
      EXCEPTION
        WHEN OTHERS THEN
          -- データ更新時のエラー
          lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(  cv_msg_kbn_cmm        -- 'XXCMM'
                                                        , cv_msg_cmm1_00055     -- 更新エラー
                                                        , cv_tkn_table          -- トークン'TABLE'
                                                        , cv_msg_cmm1_60008     -- OIC連携処理管理テーブル
                                                        , cv_tkn_err_msg        -- トークン'ERR_MSG'
                                                        , SQLERRM               -- SQLERRM
                                                       )
                                                      , 1
                                                      , 5000);
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
  END upd_oic_ctrl_tbl;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
      iv_flex_value_set_name  IN  VARCHAR2     -- 値セット名
    , ov_errbuf               OUT VARCHAR2     -- エラー・メッセージ            # 固定 #
    , ov_retcode              OUT VARCHAR2     -- リターン・コード              # 固定 #
    , ov_errmsg               OUT VARCHAR2)    -- ユーザー・エラー・メッセージ  # 固定 #
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
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
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
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- ======================================================
    --  初期処理（パラメータチェック・プロファイル取得）(A-1)
    -- ======================================================
    init(
        iv_flex_value_set_name  -- 値セット名
      , lv_errbuf               -- エラー・メッセージ            # 固定 #
      , lv_retcode              -- リターン・コード              # 固定 #
      , lv_errmsg);             -- ユーザー・エラー・メッセージ  # 固定 #
    IF ( lv_retcode = cv_status_error ) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  AFF値の抽出・ファイル出力処理 (A-2)
    -- =====================================================
    data_outbound_proc1(
        iv_flex_value_set_name  -- 値セット名
      , lv_errbuf               -- エラー・メッセージ            # 固定 #
      , lv_retcode              -- リターン・コード              # 固定 #
      , lv_errmsg);             -- ユーザー・エラー・メッセージ  # 固定 #
    IF ( lv_retcode = cv_status_error ) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  AFF階層の抽出・ファイル出力処理 (A-3)
    -- =====================================================
    data_outbound_proc2(
        iv_flex_value_set_name  -- 値セット名
      , lv_errbuf               -- エラー・メッセージ            # 固定 #
      , lv_retcode              -- リターン・コード              # 固定 #
      , lv_errmsg);             -- ユーザー・エラー・メッセージ  # 固定 #
    IF ( lv_retcode = cv_status_error ) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  AFF関連値の抽出・ファイル出力処理 (A-4)
    -- =====================================================
    data_outbound_proc3(
        iv_flex_value_set_name  -- 値セット名
      , lv_errbuf               -- エラー・メッセージ            # 固定 #
      , lv_retcode              -- リターン・コード              # 固定 #
      , lv_errmsg);             -- ユーザー・エラー・メッセージ  # 固定 #
    IF ( lv_retcode = cv_status_error ) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  管理テーブル登録・更新処理 (A-5)
    -- =====================================================
    -- 管理テーブル登録・更新処理を行う。
    upd_oic_ctrl_tbl(
        iv_flex_value_set_name  -- 値セット名
      , lv_errbuf             -- エラー・メッセージ            # 固定 #
      , lv_retcode            -- リターン・コード              # 固定 #
      , lv_errmsg);           -- ユーザー・エラー・メッセージ  # 固定 #
    IF ( lv_retcode = cv_status_error ) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--####################################  固定部 END   ##########################################
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行プロシージャ
   **********************************************************************************/
--
  PROCEDURE main(
      errbuf                  OUT VARCHAR2      -- エラー・メッセージ   # 固定 #
    , retcode                 OUT VARCHAR2      -- リターン・コード     # 固定 #
    , iv_flex_value_set_name  IN  VARCHAR2      -- 値セット名
  )
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
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';            -- アドオン：共通・IF領域
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- 対象件数メッセージ
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- 成功件数メッセージ
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- エラー件数メッセージ
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- 件数メッセージ用トークン名
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- 警告終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- エラー終了全ロールバック
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf          VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode         VARCHAR2(1);     -- リターン・コード
    lv_errmsg          VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_msgbuf          VARCHAR2(5000);  -- ユーザー・メッセージ
    lv_message_code    VARCHAR2(100);   -- 終了メッセージコード
    ln_cnt             NUMBER := 0;     -- 件数
    --
  BEGIN
--
--###########################  固定部 START   #####################################################
--
    -- 固定出力
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    xxccp_common_pkg.put_log_header(
        ov_retcode => lv_retcode
      , ov_errbuf  => lv_errbuf
      , ov_errmsg  => lv_errmsg
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
        iv_flex_value_set_name   -- 値セット名
      , lv_errbuf                -- エラー・メッセージ            # 固定 #
      , lv_retcode               -- リターン・コード              # 固定 #
      , lv_errmsg                -- ユーザー・エラー・メッセージ  # 固定 #
    );
--
    -- エラー出力
    IF ( lv_retcode = cv_status_error ) THEN
      FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
        , buff   => lv_errbuf --エラーメッセージ
      );
      -- 空行挿入
      FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => ''
      );
    END IF;
--
    -- =============
    -- A-6．終了処理
    -- =============
    -- A-6-1．すべてのファイルをクローズする
    -- =====================================
    IF ( UTL_FILE.IS_OPEN ( gf_file_hand1 )) THEN      -- AFF値連携データファイル
      UTL_FILE.FCLOSE( gf_file_hand1 );
    END IF;
    --
    IF ( UTL_FILE.IS_OPEN ( gf_file_hand2 )) THEN      -- AFF階層連携データファイル
      UTL_FILE.FCLOSE( gf_file_hand2 );
    END IF;
    --
    IF ( UTL_FILE.IS_OPEN ( gf_file_hand3 )) THEN      -- AFF関連値連携データファイル
      UTL_FILE.FCLOSE( gf_file_hand3 );
    END IF;
--
    -- A-6-2．抽出件数を出力する
    -- =========================
    -- 1.AFFの抽出件数を出力する。
    ln_cnt := gn_target1_cnt;                                             -- AFF値連携の件数
    lv_msgbuf := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_cmm                    -- 'XXCMM'
                    , iv_name         => cv_msg_cmm1_60006                 -- 検索対象・件数メッセージ
                    , iv_token_name1  => cv_tkn_target                     -- トークン(TARGET)
                    , iv_token_value1 => cv_msg_cmm1_60009                 -- 値セットの値
                    , iv_token_name2  => cv_tkn_count                      -- トークン(COUNT)
                    , iv_token_value2 => TO_CHAR(ln_cnt, cv_comma_edit)    -- 抽出件数
                   );
    -- メッセージ出力
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => lv_msgbuf
    );
--
    -- 2.AFF階層（部門）の抽出件数を出力する。
    ln_cnt := gn_target2_dpt_cnt;                                         -- AFF階層（部門）連携の件数
    lv_msgbuf := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_cmm                    -- 'XXCMM'
                    , iv_name         => cv_msg_cmm1_60006                 -- 検索対象・件数メッセージ
                    , iv_token_name1  => cv_tkn_target                     -- トークン(TARGET)
                    , iv_token_value1 => cv_msg_cmm1_60010                 -- AFF階層（部門）
                    , iv_token_name2  => cv_tkn_count                      -- トークン(COUNT)
                    , iv_token_value2 => TO_CHAR(ln_cnt, cv_comma_edit)    -- 抽出件数
                   );
    -- メッセージ出力
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => lv_msgbuf
    );
--
    -- 3.AFF階層（勘定科目）の抽出件数を出力する。
    ln_cnt := gn_target2_acc_cnt;                                         -- AFF階層（勘定科目）連携の件数
    lv_msgbuf := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_cmm                    -- 'XXCMM'
                    , iv_name         => cv_msg_cmm1_60006                 -- 検索対象・件数メッセージ
                    , iv_token_name1  => cv_tkn_target                     -- トークン(TARGET)
                    , iv_token_value1 => cv_msg_cmm1_60011                 -- AFF階層（勘定科目）
                    , iv_token_name2  => cv_tkn_count                      -- トークン(COUNT)
                    , iv_token_value2 => TO_CHAR(ln_cnt, cv_comma_edit)    -- 抽出件数
                   );
    -- メッセージ出力
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => lv_msgbuf
    );
--
    -- 4.AFF関連値連携の抽出件数を出力する。
    ln_cnt := gn_target3_cnt;                                             -- AFF関連値連携の件数
    lv_msgbuf := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_cmm                    -- 'XXCMM'
                    , iv_name         => cv_msg_cmm1_60006                 -- 検索対象・件数メッセージ
                    , iv_token_name1  => cv_tkn_target                     -- トークン(TARGET)
                    , iv_token_value1 => cv_msg_cmm1_60012                 -- (AFF関連値)
                    , iv_token_name2  => cv_tkn_count                      -- トークン(COUNT)
                    , iv_token_value2 => TO_CHAR(ln_cnt, cv_comma_edit)    -- 抽出件数
                   );
    -- メッセージ出力
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => lv_msgbuf
    );
    -- 空行挿入
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
--
    -- A-6-3．出力件数を出力する
    -- =========================
    -- エラー時の件数表示
    IF ( lv_retcode = cv_status_error ) THEN
      gn_target1_cnt     := 0;                    -- AFF値連携ファイルの出力件数
      gn_target2_dpt_cnt := 0;                    -- AFF階層（部門）連携ファイルの出力件数
      gn_target2_acc_cnt := 0;                    -- AFF階層（勘定科目）連携ファイルの出力件数
      gn_target3_cnt     := 0;                    -- AFF関連値連携ファイルの出力件数
      gn_normal_cnt      := 0;                    -- 成功件数
      gn_error_cnt       := 1;                    -- エラー件数
    END IF;
--
    -- 1.AFF値連携ファイル出力件数出力
    ln_cnt := gn_target1_cnt;                                             -- AFF値連携の件数
    lv_msgbuf := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_cmm                    -- 'XXCMM'
                    , iv_name         => cv_msg_cmm1_60007                 -- ファイル出力対象・件数メッセージ
                    , iv_token_name1  => cv_tkn_target                     -- トークン(TARGET)
                    , iv_token_value1 => gv_data_filename1                 -- AFF値連携データファイル
                    , iv_token_name2  => cv_tkn_count                      -- トークン(COUNT)
                    , iv_token_value2 => TO_CHAR(ln_cnt, cv_comma_edit)    -- 出力件数
                   );
    -- メッセージ出力
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => lv_msgbuf
    );
--
    -- 2.AFF階層連携ファイル出力件数出力
    ln_cnt := gn_target2_dpt_cnt + gn_target2_acc_cnt;                    -- AFF階層連携の件数（部門 + 勘定科目）
    lv_msgbuf := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_cmm                    -- 'XXCMM'
                    , iv_name         => cv_msg_cmm1_60007                 -- ファイル出力対象・件数メッセージ
                    , iv_token_name1  => cv_tkn_target                     -- トークン(TARGET)
                    , iv_token_value1 => gv_data_filename2                 -- FF階層連携データファイル
                    , iv_token_name2  => cv_tkn_count                      -- トークン(COUNT)
                    , iv_token_value2 => TO_CHAR(ln_cnt, cv_comma_edit)    -- 出力件数
                   );
    -- メッセージ出力
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => lv_msgbuf
    );
--
    -- 3.FF関連値連携ファイル出力件数出力
    ln_cnt := gn_target3_cnt;                                             -- AFF関連値連携の件数
    lv_msgbuf := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_cmm                    -- 'XXCMM'
                    , iv_name         => cv_msg_cmm1_60007                 -- ファイル出力対象・件数メッセージ
                    , iv_token_name1  => cv_tkn_target                     -- トークン(TARGET)
                    , iv_token_value1 => gv_data_filename3                 -- AFF関連値連携データファイル
                    , iv_token_name2  => cv_tkn_count                      -- トークン(COUNT)
                    , iv_token_value2 => TO_CHAR(ln_cnt, cv_comma_edit)    -- 出力件数
                   );
    -- メッセージ出力
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => lv_msgbuf
    );
    -- 空行挿入
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
--
    --
    -- A-6-4．対象件数、およびI/Fファイルへの出力件数（成功件数／エラー件数）を出力する
    -- ================================================================================
    -- 対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_target_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR(gn_target_cnt, cv_comma_edit)    -- 対象件数
                   );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    --
    -- 成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_success_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR(gn_normal_cnt, cv_comma_edit)    -- 成功件数
                   );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    -- 空行挿入
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
    --
    -- エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_error_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR(gn_error_cnt, cv_comma_edit)    -- エラー件数
                   );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    -- 空行挿入
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
    --
    -- A-6-5．終了ステータスにより、該当する処理終了メッセージを出力する
    -- =================================================================
    IF ( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    --ス テータスセット
    retcode := lv_retcode;
    --終了ステータスがエラーの場合はROLLBACKする
    IF ( retcode = cv_status_error ) THEN
      ROLLBACK;
    ELSE
      COMMIT;
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
END XXCMM006A07C;
/
