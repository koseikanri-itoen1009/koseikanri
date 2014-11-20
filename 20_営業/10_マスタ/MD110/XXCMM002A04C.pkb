CREATE OR REPLACE PACKAGE BODY XXCMM002A04C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCMM002A04C(body)
 * Description      : 社員データ連携(営業帳票システム)
 * MD.050           : 社員データ連携(営業帳票システム) MD050_CMM_002_A04
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理プロシージャ(A-1)
 *  get_people_data        社員データ取得プロシージャ(A-2)
 *  output_csv             CSVファイル出力プロシージャ(A-5)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/15    1.0   SCS 福間 貴子    初回作成
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
  gn_target_cnt    NUMBER;                    -- 対象件数
  gn_normal_cnt    NUMBER;                    -- 正常件数
  gn_error_cnt     NUMBER;                    -- エラー件数
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
  lock_expt                 EXCEPTION;        -- ロック(ビジー)エラー
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name               CONSTANT VARCHAR2(100) := 'XXCMM002A04C';               -- パッケージ名
  -- プロファイル
  cv_filepath               CONSTANT VARCHAR2(30)  := 'XXCMM1_CHOHYO_OUT_DIR';      -- 営業帳票CSVファイル出力先
  cv_filename               CONSTANT VARCHAR2(30)  := 'XXCMM1_002A04_OUT_FILE';     -- 連携用CSVファイル名
  cv_jyugyoin_kbn           CONSTANT VARCHAR2(30)  := 'XXCMM1_002A04_JYUGYOIN_KBN'; -- 従業員区分のダミー値
  -- トークン
  cv_tkn_profile            CONSTANT VARCHAR2(10)  := 'NG_PROFILE';                 -- プロファイル名
  cv_tkn_filepath_nm        CONSTANT VARCHAR2(20)  := 'CSVファイル出力先';
  cv_tkn_filename_nm        CONSTANT VARCHAR2(20)  := 'CSVファイル名';
  cv_tkn_jyugoin_kbn_nm     CONSTANT VARCHAR2(20)  := '従業員区分のダミー値';
  cv_tkn_word               CONSTANT VARCHAR2(10)  := 'NG_WORD';                    -- 項目名
  cv_tkn_word1              CONSTANT VARCHAR2(10)  := '社員番号';
  cv_tkn_word2              CONSTANT VARCHAR2(10)  := 'CSVヘッダ';
  cv_tkn_word3              CONSTANT VARCHAR2(10)  := '、氏名 : ';
  cv_tkn_data               CONSTANT VARCHAR2(10)  := 'NG_DATA';                    -- データ
  cv_tkn_filename           CONSTANT VARCHAR2(10)  := 'FILE_NAME';                  -- ファイル名
  cv_tkn_param              CONSTANT VARCHAR2(10)  := 'PARAM';                      -- パラメータ名
  cv_tkn_param1             CONSTANT VARCHAR2(20)  := '最終更新日(開始)';
  cv_tkn_param2             CONSTANT VARCHAR2(20)  := '最終更新日(終了)';
  cv_tkn_param3             CONSTANT VARCHAR2(20)  := '入力パラメータ';
  cv_tkn_value              CONSTANT VARCHAR2(10)  := 'VALUE';                      -- パラメータ値
  cv_tkn_table              CONSTANT VARCHAR2(10)  := 'NG_TABLE';                   -- テーブル
  cv_tkn_table_nm           CONSTANT VARCHAR2(20)  := 'アサインメントマスタ';
  cv_tkn_kyoten             CONSTANT VARCHAR2(10)  := 'NG_KYOTEN';                  -- 拠点コード(新)
  -- メッセージ区分
  cv_msg_kbn_cmm            CONSTANT VARCHAR2(5)   := 'XXCMM';
  cv_msg_kbn_ccp            CONSTANT VARCHAR2(5)   := 'XXCCP';
  -- メッセージ
  cv_msg_00038              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00038';           -- 入力パラメータ出力メッセージ
  cv_msg_00002              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00002';           -- プロファイル取得エラー
  cv_msg_05102              CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-05102';           -- ファイル名出力メッセージ
  cv_msg_00018              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00018';           -- 業務日付取得エラー
  cv_msg_00030              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00030';           -- 対象期間制限エラー
  cv_msg_00019              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00019';           -- 対象期間指定エラー
  cv_msg_00010              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00010';           -- CSVファイル存在チェック
  cv_msg_00003              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00003';           -- ファイルパス不正エラー
  cv_msg_00008              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00008';           -- ロック取得NGメッセージ
  cv_msg_00501              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00501';           -- AFF部門エラー
  cv_msg_00205              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00205';           -- 拠点コード(新)取得エラー
  cv_msg_00209              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00209';           -- 従業員番号重複メッセージ
  cv_msg_00007              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00007';           -- ファイルアクセス権限エラー
  cv_msg_00009              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00009';           -- CSVデータ出力エラー
  cv_msg_00029              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00029';           -- アサインメントマスタ更新エラー
  -- 固定値(CSVヘッダ、設定値)
  cv_nm1                    CONSTANT VARCHAR2(10)  := 'データ種';
  cv_nm2                    CONSTANT VARCHAR2(10)  := 'ファイル種';
  cv_nm3                    CONSTANT VARCHAR2(10)  := '更新区分';
  cv_nm4                    CONSTANT VARCHAR2(20)  := '拠点（部門）コード';
  cv_nm5                    CONSTANT VARCHAR2(12)  := '勤務地コード';
  cv_nm6                    CONSTANT VARCHAR2(12)  := '大本部コード';
  cv_nm7                    CONSTANT VARCHAR2(10)  := '本部コード';
  cv_nm8                    CONSTANT VARCHAR2(12)  := 'エリアコード';
  cv_nm9                    CONSTANT VARCHAR2(10)  := '地区コード';
  cv_nm10                   CONSTANT VARCHAR2(10)  := '職位コード';
  cv_nm11                   CONSTANT VARCHAR2(14)  := '職位並順コード';
  cv_nm12                   CONSTANT VARCHAR2(10)  := '職位名';
  cv_nm13                   CONSTANT VARCHAR2(10)  := '社員番号';
  cv_nm14                   CONSTANT VARCHAR2(20)  := '従業員氏名（カナ）';
  cv_nm15                   CONSTANT VARCHAR2(20)  := '従業員氏名（漢字）';
  cv_nm16                   CONSTANT VARCHAR2(10)  := '生年月日';
  cv_nm17                   CONSTANT VARCHAR2(10)  := '性別区分';
  cv_nm18                   CONSTANT VARCHAR2(10)  := '入社年月日';
  cv_nm19                   CONSTANT VARCHAR2(10)  := '退職年月日';
  cv_nm20                   CONSTANT VARCHAR2(20)  := '異動事由コード';
  cv_nm21                   CONSTANT VARCHAR2(10)  := '適用開始日';
  cv_nm22                   CONSTANT VARCHAR2(10)  := '資格コード';
  cv_nm23                   CONSTANT VARCHAR2(10)  := '資格名';
  cv_nm24                   CONSTANT VARCHAR2(10)  := '職種コード';
  cv_nm25                   CONSTANT VARCHAR2(10)  := '職種名';
  cv_nm26                   CONSTANT VARCHAR2(10)  := '職務コード';
  cv_nm27                   CONSTANT VARCHAR2(10)  := '職務名';
  cv_nm28                   CONSTANT VARCHAR2(10)  := '承認区分';
  cv_nm29                   CONSTANT VARCHAR2(10)  := '代行区分';
  cv_nm30                   CONSTANT VARCHAR2(10)  := '作成年月日';
  cv_nm31                   CONSTANT VARCHAR2(10)  := '最終更新日';
  cv_value1                 CONSTANT VARCHAR2(2)   := 'Z1';                         -- データ種
  cv_value2                 CONSTANT VARCHAR2(2)   := '00';                         -- ファイル種
  cv_value3_add             CONSTANT VARCHAR2(1)   := '1';                          -- 更新区分(新規追加)
  cv_value3_update          CONSTANT VARCHAR2(1)   := '2';                          -- 更新区分(修正更新)
  cv_value3_delete          CONSTANT VARCHAR2(1)   := '3';                          -- 更新区分(削除)
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 社員データを格納するレコード
  TYPE people_data_rec  IS RECORD(
       ass_attribute5   VARCHAR2(4),   -- 拠点（部門）コード
       ass_attribute3   VARCHAR2(4),   -- 勤務地コード
       attribute11      VARCHAR2(3),   -- 職位コード
       ass_attribute11  VARCHAR2(2),   -- 職位並順コード
       attribute12      VARCHAR2(20),  -- 職位名
       employee_number  VARCHAR2(5),   -- 社員番号
       kana             VARCHAR2(20),  -- 従業員氏名（カナ）
       kanji            VARCHAR2(20),  -- 従業員氏名（漢字）
       sex              VARCHAR2(1),   -- 性別区分
       start_date       VARCHAR2(8),   -- 入社年月日
       at_date          VARCHAR2(8),   -- 退職年月日
       ass_attribute1   VARCHAR2(2),   -- 異動事由コード
       ass_attribute2   VARCHAR2(8),   -- 適用開始日
       attribute7       VARCHAR2(3),   -- 資格コード
       attribute8       VARCHAR2(20),  -- 資格名
       attribute19      VARCHAR2(2),   -- 職種コード
       attribute20      VARCHAR2(20),  -- 職種名
       attribute15      VARCHAR2(3),   -- 職務コード
       attribute16      VARCHAR2(20),  -- 職務名
       ass_attribute13  VARCHAR2(7),   -- 承認区分
       ass_attribute15  VARCHAR2(7),   -- 代行区分
       assignment_id    NUMBER(10),    -- アサインメントID
       ass_attribute18  VARCHAR2(19),  -- 差分連携用日付(帳票)
       dpt2_cd          VARCHAR2(4),   -- 大本部コード
       dpt3_cd          VARCHAR2(4),   -- 本部コード
       dpt4_cd          VARCHAR2(4),   -- エリアコード
       dpt5_cd          VARCHAR2(4)    -- 地区コード
  );
  -- 社員データを格納するテーブル型の定義
  TYPE people_data_tbl  IS TABLE OF people_data_rec INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gv_filepath               VARCHAR2(255);        -- 連携用CSVファイル出力先
  gv_filename               VARCHAR2(255);        -- 連携用CSVファイル名
  gv_jyugyoin_kbn           VARCHAR2(10);         -- 従業員区分のダミー値
  gd_process_date           DATE;                 -- 業務日付
  gd_select_start_date      DATE;                 -- 取得開始日
  gd_select_start_datetime  DATE;                 -- 取得開始日(時刻 00:00:00)
  gd_select_end_date        DATE;                 -- 取得終了日
  gd_select_end_datetime    DATE;                 -- 取得終了日(時刻 23:59:59)
  gf_file_hand              UTL_FILE.FILE_TYPE;   -- ファイル・ハンドルの宣言
  gv_update_sdate           VARCHAR2(10);         -- 入力パラメータ：最終更新日(開始)
  gv_update_edate           VARCHAR2(10);         -- 入力パラメータ：最終更新日(終了)
  gv_warn_flg               VARCHAR2(1);          -- 警告フラグ
  gt_people_data_tbl        people_data_tbl;      -- 結合配列の定義
  gv_param_output_flg       VARCHAR2(1);          -- 入力パラメータ出力フラグ(出力前:0、出力後:1)
  gd_sysdate                DATE;                 -- システム日付
--
  -- ===============================
  -- ユーザー定義グローバルカーソル
  -- ===============================
  -- 入力パラメータの開始がない場合
  CURSOR get_people_data1_cur
  IS
    SELECT   SUBSTRB(a.ass_attribute5,1,4) AS ass_attribute5,                                                -- 拠点（部門）コード
             SUBSTRB(a.ass_attribute3,1,4) AS ass_attribute3,                                                -- 勤務地コード
             SUBSTRB(p.attribute11,1,3) AS attribute11,                                                      -- 職位コード
             SUBSTRB(a.ass_attribute11,1,2) AS ass_attribute11,                                              -- 職位並順コード
             SUBSTRB(p.attribute12,1,20) AS attribute12,                                                     -- 職位名
             SUBSTRB(p.employee_number,1,5) AS employee_number,                                              -- 社員番号
             SUBSTRB(p.last_name || ' ' || p.first_name,1,20) AS kana,                                       -- 従業員氏名（カナ）
             SUBSTRB(p.per_information18 || '　' || p.per_information19,1,20) AS kanji,                      -- 従業員氏名（漢字）
             SUBSTRB(p.sex,1,1) AS sex,                                                                      -- 性別区分
             TO_CHAR(p.effective_start_date,'YYYYMMDD') AS start_date,                                       -- 入社年月日
             NVL2(s.actual_termination_date,TO_CHAR(s.actual_termination_date,'YYYYMMDD'),NULL) AS at_date,  -- 退職年月日
             SUBSTRB(a.ass_attribute1,1,2) AS ass_attribute1,                                                -- 異動事由コード
             a.ass_attribute2 AS ass_attribute2,                                                             -- 適用開始日
             SUBSTRB(p.attribute7,1,3) AS attribute7,                                                        -- 資格コード
             SUBSTRB(p.attribute8,1,20) AS attribute8,                                                       -- 資格名
             SUBSTRB(p.attribute19,1,2) AS attribute19,                                                      -- 職種コード
             SUBSTRB(p.attribute20,1,20) AS attribute20,                                                     -- 職種名
             SUBSTRB(p.attribute15,1,3) AS attribute15,                                                      -- 職務コード
             SUBSTRB(p.attribute16,1,20) AS attribute16,                                                     -- 職務名
             SUBSTRB(a.ass_attribute13,1,7) AS ass_attribute13,                                              -- 承認区分
             SUBSTRB(a.ass_attribute15,1,7) AS ass_attribute15,                                              -- 代行区分
             a.assignment_id AS assignment_id,                                                               -- アサインメントID
             a.ass_attribute18 AS ass_attribute18,                                                           -- 差分連携用日付(帳票)
             SUBSTRB(b.dpt2_cd,1,4) AS dpt2_cd,                                                              -- 大本部コード
             SUBSTRB(b.dpt3_cd,1,4) AS dpt3_cd,                                                              -- 本部コード
             SUBSTRB(b.dpt4_cd,1,4) AS dpt4_cd,                                                              -- エリアコード
             SUBSTRB(b.dpt5_cd,1,4) AS dpt5_cd                                                               -- 地区コード
    FROM     xxcmm_hierarchy_dept_all_v b,
             per_periods_of_service s,
             per_all_assignments_f a,
             per_all_people_f p,
             (SELECT   pp.person_id AS person_id,
                       MAX(pp.effective_start_date) as effective_start_date
              FROM     per_all_people_f pp
              WHERE    pp.current_emp_or_apl_flag = 'Y'
              GROUP BY pp.person_id) pp
    WHERE    pp.person_id = p.person_id
    AND      pp.effective_start_date = p.effective_start_date
    AND      (p.last_update_date <= gd_select_end_datetime AND a.last_update_date <= gd_select_end_datetime)
    AND      p.person_id = a.person_id
    AND      p.effective_start_date = a.effective_start_date
    AND      a.period_of_service_id = s.period_of_service_id
    AND      (NVL(p.attribute3,' ') > gv_jyugyoin_kbn OR NVL(p.attribute3,' ') < gv_jyugyoin_kbn)
    AND      ((a.ass_attribute18 IS NULL)
             OR
             (a.ass_attribute18 < TO_CHAR(p.last_update_date,'YYYYMMDD HH24:MI:SS'))
             OR
             (a.ass_attribute18 < TO_CHAR(a.last_update_date,'YYYYMMDD HH24:MI:SS')))
    AND      (s.actual_termination_date IS NULL OR s.actual_termination_date <= gd_select_end_date)
    AND      a.ass_attribute5 = b.cur_dpt_cd(+)
    ORDER BY p.employee_number
  ;
  --
  -- 入力パラメータの開始がある場合
  CURSOR get_people_data2_cur
  IS
    SELECT   SUBSTRB(a.ass_attribute5,1,4) AS ass_attribute5,                                                -- 拠点（部門）コード
             SUBSTRB(a.ass_attribute3,1,4) AS ass_attribute3,                                                -- 勤務地コード
             SUBSTRB(p.attribute11,1,3) AS attribute11,                                                      -- 職位コード
             SUBSTRB(a.ass_attribute11,1,2) AS ass_attribute11,                                              -- 職位並順コード
             SUBSTRB(p.attribute12,1,20) AS attribute12,                                                     -- 職位名
             SUBSTRB(p.employee_number,1,5) AS employee_number,                                              -- 社員番号
             SUBSTRB(p.last_name || ' ' || p.first_name,1,20) AS kana,                                       -- 従業員氏名（カナ）
             SUBSTRB(p.per_information18 || '　' || p.per_information19,1,20) AS kanji,                      -- 従業員氏名（漢字）
             SUBSTRB(p.sex,1,1) AS sex,                                                                      -- 性別区分
             TO_CHAR(p.effective_start_date,'YYYYMMDD') AS start_date,                                       -- 入社年月日
             NVL2(s.actual_termination_date,TO_CHAR(s.actual_termination_date,'YYYYMMDD'),NULL) AS at_date,  -- 退職年月日
             SUBSTRB(a.ass_attribute1,1,2) AS ass_attribute1,                                                -- 異動事由コード
             a.ass_attribute2 AS ass_attribute2,                                                             -- 適用開始日
             SUBSTRB(p.attribute7,1,3) AS attribute7,                                                        -- 資格コード
             SUBSTRB(p.attribute8,1,20) AS attribute8,                                                       -- 資格名
             SUBSTRB(p.attribute19,1,2) AS attribute19,                                                      -- 職種コード
             SUBSTRB(p.attribute20,1,20) AS attribute20,                                                     -- 職種名
             SUBSTRB(p.attribute15,1,3) AS attribute15,                                                      -- 職務コード
             SUBSTRB(p.attribute16,1,20) AS attribute16,                                                     -- 職務名
             SUBSTRB(a.ass_attribute13,1,7) AS ass_attribute13,                                              -- 承認区分
             SUBSTRB(a.ass_attribute15,1,7) AS ass_attribute15,                                              -- 代行区分
             a.assignment_id AS assignment_id,                                                               -- アサインメントID
             a.ass_attribute18 AS ass_attribute18,                                                           -- 差分連携用日付(帳票)
             SUBSTRB(b.dpt2_cd,1,4) AS dpt2_cd,                                                              -- 大本部コード
             SUBSTRB(b.dpt3_cd,1,4) AS dpt3_cd,                                                              -- 本部コード
             SUBSTRB(b.dpt4_cd,1,4) AS dpt4_cd,                                                              -- エリアコード
             SUBSTRB(b.dpt5_cd,1,4) AS dpt5_cd                                                               -- 地区コード
    FROM     xxcmm_hierarchy_dept_all_v b,
             per_periods_of_service s,
             per_all_assignments_f a,
             per_all_people_f p,
             (SELECT   pp.person_id AS person_id,
                       MAX(pp.effective_start_date) as effective_start_date
              FROM     per_all_people_f pp
              WHERE    pp.current_emp_or_apl_flag = 'Y'
              GROUP BY pp.person_id) pp
    WHERE    pp.person_id = p.person_id
    AND      pp.effective_start_date = p.effective_start_date
    AND      (NVL(p.attribute3,' ') > gv_jyugyoin_kbn OR NVL(p.attribute3,' ') < gv_jyugyoin_kbn)
    AND      ((gd_select_start_datetime <= p.last_update_date AND p.last_update_date <= gd_select_end_datetime)
              OR (gd_select_start_datetime <= a.last_update_date AND a.last_update_date <= gd_select_end_datetime))
    AND      p.person_id = a.person_id
    AND      p.effective_start_date = a.effective_start_date
    AND      a.period_of_service_id = s.period_of_service_id
    AND      (s.actual_termination_date IS NULL OR s.actual_termination_date <= gd_select_end_date)
    AND      a.ass_attribute5 = b.cur_dpt_cd(+)
    ORDER BY p.employee_number
  ;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理プロシージャ(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init';                  -- プログラム名
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
    -- ファイルオープンモード
    cv_open_mode_w          CONSTANT VARCHAR2(10)  := 'w';           -- 上書き
--
    -- *** ローカル変数 ***
    lb_fexists              BOOLEAN;              -- ファイルが存在するかどうか
    ln_file_size            NUMBER;               -- ファイルの長さ
    ln_block_size           NUMBER;               -- ファイルシステムのブロックサイズ
--
    -- *** ローカル・カーソル ***
    -- 入力パラメータの開始がない場合
    CURSOR get_assignment1_cur IS
      SELECT   a.assignment_id
      FROM     per_periods_of_service s,
               per_all_assignments_f a,
               per_all_people_f p
      WHERE    (p.last_update_date <= gd_select_end_datetime AND a.last_update_date <= gd_select_end_datetime)
      AND      p.person_id = a.person_id
      AND      p.effective_start_date = a.effective_start_date
      AND      a.period_of_service_id = s.period_of_service_id
      AND      (NVL(p.attribute3,' ') > gv_jyugyoin_kbn OR NVL(p.attribute3,' ') < gv_jyugyoin_kbn)
      AND      ((a.ass_attribute18 IS NULL)
               OR
               (a.ass_attribute18 < TO_CHAR(p.last_update_date,'YYYYMMDD HH24:MI:SS'))
               OR
               (a.ass_attribute18 < TO_CHAR(a.last_update_date,'YYYYMMDD HH24:MI:SS')))
      AND      (s.actual_termination_date IS NULL OR s.actual_termination_date <= gd_select_end_date)
      FOR UPDATE NOWAIT;
    --
    -- 入力パラメータの開始がある場合
    CURSOR get_assignment2_cur IS
      SELECT   a.assignment_id
      FROM     per_periods_of_service s,
               per_all_assignments_f a,
               per_all_people_f p
      WHERE    (NVL(p.attribute3,' ') > gv_jyugyoin_kbn OR NVL(p.attribute3,' ') < gv_jyugyoin_kbn)
      AND      ((gd_select_start_datetime <= p.last_update_date AND p.last_update_date <= gd_select_end_datetime)
                OR (gd_select_start_datetime <= a.last_update_date AND a.last_update_date <= gd_select_end_datetime))
      AND      p.person_id = a.person_id
      AND      p.effective_start_date = a.effective_start_date
      AND      a.period_of_service_id = s.period_of_service_id
      AND      (s.actual_termination_date IS NULL OR s.actual_termination_date <= gd_select_end_date)
      FOR UPDATE NOWAIT;
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
--
    -- =========================================================
    --  取得開始日、取得終了日の取得
    -- =========================================================
    -- 業務日付の取得
    gd_process_date := xxccp_common_pkg2.get_process_date;
    IF (gd_process_date IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cmm         -- 'XXCMM'
                      ,iv_name         => cv_msg_00018           -- 業務処理日付取得エラー
                     );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    -- 取得開始日の取得
    IF (gv_update_sdate IS NOT NULL) THEN
      gd_select_start_date := TO_DATE(gv_update_sdate,'YYYY/MM/DD');
      gd_select_start_datetime := TO_DATE(gv_update_sdate || ' 00:00:00','YYYY/MM/DD HH24:MI:SS');
    END IF;
    -- 取得終了日の取得
    IF (gv_update_edate IS NULL) THEN
      -- 業務日付をセット
      gd_select_end_date := gd_process_date;
    ELSE
      -- 最終更新日(終了)をセット
      gd_select_end_date := TO_DATE(gv_update_edate,'YYYY/MM/DD');
    END IF;
    gd_select_end_datetime := TO_DATE(TO_CHAR(gd_select_end_date,'YYYY/MM/DD') || ' 23:59:59','YYYY/MM/DD HH24:MI:SS');
    -- =========================================================
    --  固定出力(入力パラメータ部)
    -- =========================================================
    -- 入力パラメータ
    lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cmm         -- 'XXCMM'
                    ,iv_name         => cv_msg_00038           -- 入力パラメータ出力メッセージ
                    ,iv_token_name1  => cv_tkn_param           -- トークン(PARAM)
                    ,iv_token_value1 => cv_tkn_param3          -- パラメータ名(入力パラメータ)
                    ,iv_token_name2  => cv_tkn_value           -- トークン(VALUE)
                    ,iv_token_value2 => gv_update_sdate || '.' || gv_update_edate
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_errmsg
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => lv_errmsg
    );
    -- 取得開始日
    lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cmm         -- 'XXCMM'
                    ,iv_name         => cv_msg_00038           -- 入力パラメータ出力メッセージ
                    ,iv_token_name1  => cv_tkn_param           -- トークン(PARAM)
                    ,iv_token_value1 => cv_tkn_param1          -- パラメータ名(最終更新日(開始))
                    ,iv_token_name2  => cv_tkn_value           -- トークン(VALUE)
                    ,iv_token_value2 => gv_update_sdate
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_errmsg
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => lv_errmsg
    );
    -- 取得終了日
    lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cmm         -- 'XXCMM'
                    ,iv_name         => cv_msg_00038           -- 入力パラメータ出力メッセージ
                    ,iv_token_name1  => cv_tkn_param           -- トークン(PARAM)
                    ,iv_token_value1 => cv_tkn_param2          -- パラメータ名(最終更新日(終了))
                    ,iv_token_name2  => cv_tkn_value           -- トークン(VALUE)
                    ,iv_token_value2 => TO_CHAR(gd_select_end_date,'YYYY/MM/DD')
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_errmsg
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => lv_errmsg
    );
    -- 空行挿入(入力パラメータの下)
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    -- 入力パラメータ出力フラグに「出力後」をセット
    gv_param_output_flg := '1';
--
    IF (gv_update_sdate IS NOT NULL) THEN
      -- =========================================================
      --  対象期間指定チェック
      -- =========================================================
      IF (gd_select_start_date > gd_select_end_date) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cmm       -- 'XXCMM'
                        ,iv_name         => cv_msg_00019         -- 対象期間指定エラー
                       );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
      -- =========================================================
      --  対象期間制限チェック(取得開始日)
      -- =========================================================
      IF (gd_select_start_date > gd_process_date) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cmm       -- 'XXCMM'
                        ,iv_name         => cv_msg_00030         -- 対象期間制限エラー
                       );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
    END IF;
    -- =========================================================
    --  対象期間制限チェック(取得終了日)
    -- =========================================================
    IF (gd_select_end_date > gd_process_date) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cmm         -- 'XXCMM'
                      ,iv_name         => cv_msg_00030           -- 対象期間制限エラー
                     );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- =============================================================================
    --  プロファイルの取得(CSVファイル出力先、CSVファイル名、従業員区分のダミー値)
    -- =============================================================================
    gv_filepath := fnd_profile.value(cv_filepath);
    IF (gv_filepath IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cmm         -- 'XXCMM'
                      ,iv_name         => cv_msg_00002           -- プロファイル取得エラー
                      ,iv_token_name1  => cv_tkn_profile         -- トークン(NG_PROFILE)
                      ,iv_token_value1 => cv_tkn_filepath_nm     -- プロファイル名(CSVファイル出力先)
                     );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    gv_filename := fnd_profile.value(cv_filename);
    IF (gv_filename IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cmm         -- 'XXCMM'
                      ,iv_name         => cv_msg_00002           -- プロファイル取得エラー
                      ,iv_token_name1  => cv_tkn_profile         -- トークン(NG_PROFILE)
                      ,iv_token_value1 => cv_tkn_filename_nm     -- プロファイル名(CSVファイル名)
                     );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    gv_jyugyoin_kbn := fnd_profile.value(cv_jyugyoin_kbn);
    IF (gv_jyugyoin_kbn IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cmm         -- 'XXCMM'
                      ,iv_name         => cv_msg_00002           -- プロファイル取得エラー
                      ,iv_token_name1  => cv_tkn_profile         -- トークン(NG_PROFILE)
                      ,iv_token_value1 => cv_tkn_jyugoin_kbn_nm  -- プロファイル名(従業員区分のダミー値)
                     );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    -- =========================================================
    --  固定出力(I/Fファイル名部)
    -- =========================================================
    lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp           -- 'XXCCP'
                    ,iv_name         => cv_msg_05102             -- ファイル名出力メッセージ
                    ,iv_token_name1  => cv_tkn_filename          -- トークン(FILE_NAME)
                    ,iv_token_value1 => gv_filename              -- ファイル名
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_errmsg
    );
    -- 空行挿入(I/Fファイル名の下)
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    -- =========================================================
    --  CSVファイル存在チェック
    -- =========================================================
    UTL_FILE.FGETATTR(gv_filepath,
                      gv_filename,
                      lb_fexists,
                      ln_file_size,
                      ln_block_size);
    IF (lb_fexists = TRUE) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cmm         -- 'XXCMM'
                      ,iv_name         => cv_msg_00010           -- ファイル作成済みエラー
                     );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- =========================================================
    --  ファイルオープン
    -- =========================================================
    BEGIN
      gf_file_hand := UTL_FILE.FOPEN(gv_filepath
                                    ,gv_filename
                                    ,cv_open_mode_w);
    EXCEPTION
      WHEN UTL_FILE.INVALID_PATH THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cmm       -- 'XXCMM'
                        ,iv_name         => cv_msg_00003         -- ファイルパス不正エラー
                       );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    -- =========================================================
    --  アサインメントマスタの行ロック
    -- =========================================================
    BEGIN
      IF (gv_update_sdate IS NULL) THEN
        OPEN get_assignment1_cur;
        CLOSE get_assignment1_cur;
      ELSE
        OPEN get_assignment2_cur;
        CLOSE get_assignment2_cur;
      END IF;
    EXCEPTION
      -- テーブルロックエラー
      WHEN lock_expt THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cmm       -- 'XXCMM'
                        ,iv_name         => cv_msg_00008         -- ロック取得NGメッセージ
                        ,iv_token_name1  => cv_tkn_table         -- トークン(NG_TABLE)
                        ,iv_token_value1 => cv_tkn_table_nm      -- テーブル名(アサインメントマスタ)
                       );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
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
   * Procedure Name   : get_people_data
   * Description      : 社員データ取得プロシージャ(A-2)
   ***********************************************************************************/
  PROCEDURE get_people_data(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_people_data';       -- プログラム名
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
--
    IF (gv_update_sdate IS NULL) THEN
      OPEN get_people_data1_cur;
      <<people_data1_loop>>
      LOOP
        FETCH get_people_data1_cur BULK COLLECT INTO gt_people_data_tbl;
        EXIT WHEN get_people_data1_cur%NOTFOUND;
      END LOOP people_data1_loop;
      CLOSE get_people_data1_cur;
    ELSE
      OPEN get_people_data2_cur;
      <<people_data2_loop>>
      LOOP
        FETCH get_people_data2_cur BULK COLLECT INTO gt_people_data_tbl;
        EXIT WHEN get_people_data2_cur%NOTFOUND;
      END LOOP people_data2_loop;
      CLOSE get_people_data2_cur;
    END IF;
--
    -- 対象件数をセット
    gn_target_cnt := gt_people_data_tbl.COUNT;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
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
  END get_people_data;
--
  /**********************************************************************************
   * Procedure Name   : output_csv
   * Description      : CSVファイル出力プロシージャ(A-5)
   ***********************************************************************************/
  PROCEDURE output_csv(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_csv';            -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
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
    cv_delimiter        CONSTANT VARCHAR2(1)  := ',';                -- CSV区切り文字
    cv_enclosed         CONSTANT VARCHAR2(2)  := '"';                -- 単語囲み文字
--
    -- *** ローカル変数 ***
    ln_loop_cnt         NUMBER;                   -- ループカウンタ
    lv_csv_text         VARCHAR2(32000);          -- 出力１行分文字列変数
    lv_update_kbn       VARCHAR2(1);              -- 更新区分
    lv_employee_number  VARCHAR2(5);              -- 従業員番号重複チェック用
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
    -- ***        ループ処理の記述         ***
    -- ***       処理部の呼び出し          ***
    -- ***************************************
--
    --========================================
    -- CSVヘッダ出力(A-3)
    --========================================
    lv_csv_text := cv_enclosed || cv_nm1 || cv_enclosed || cv_delimiter                               -- データ種
      || cv_enclosed || cv_nm2 || cv_enclosed || cv_delimiter                                         -- ファイル種
      || cv_enclosed || cv_nm3 || cv_enclosed || cv_delimiter                                         -- 更新区分
      || cv_enclosed || cv_nm4 || cv_enclosed || cv_delimiter                                         -- 拠点（部門）コード
      || cv_enclosed || cv_nm5 || cv_enclosed || cv_delimiter                                         -- 勤務地コード
      || cv_enclosed || cv_nm6 || cv_enclosed || cv_delimiter                                         -- 大本部コード
      || cv_enclosed || cv_nm7 || cv_enclosed || cv_delimiter                                         -- 本部コード
      || cv_enclosed || cv_nm8 || cv_enclosed || cv_delimiter                                         -- エリアコード
      || cv_enclosed || cv_nm9 || cv_enclosed || cv_delimiter                                         -- 地区コード
      || cv_enclosed || cv_nm10 || cv_enclosed || cv_delimiter                                        -- 職位コード
      || cv_enclosed || cv_nm11 || cv_enclosed || cv_delimiter                                        -- 職位並順コード
      || cv_enclosed || cv_nm12 || cv_enclosed || cv_delimiter                                        -- 職位名
      || cv_enclosed || cv_nm13 || cv_enclosed || cv_delimiter                                        -- 社員番号
      || cv_enclosed || cv_nm14 || cv_enclosed || cv_delimiter                                        -- 従業員氏名（カナ）
      || cv_enclosed || cv_nm15 || cv_enclosed || cv_delimiter                                        -- 従業員氏名（漢字）
      || cv_enclosed || cv_nm16 || cv_enclosed || cv_delimiter                                        -- 生年月日
      || cv_enclosed || cv_nm17 || cv_enclosed || cv_delimiter                                        -- 性別区分
      || cv_enclosed || cv_nm18 || cv_enclosed || cv_delimiter                                        -- 入社年月日
      || cv_enclosed || cv_nm19 || cv_enclosed || cv_delimiter                                        -- 退職年月日
      || cv_enclosed || cv_nm20 || cv_enclosed || cv_delimiter                                        -- 異動事由コード
      || cv_enclosed || cv_nm21 || cv_enclosed || cv_delimiter                                        -- 適用開始日
      || cv_enclosed || cv_nm22 || cv_enclosed || cv_delimiter                                        -- 資格コード
      || cv_enclosed || cv_nm23 || cv_enclosed || cv_delimiter                                        -- 資格名
      || cv_enclosed || cv_nm24 || cv_enclosed || cv_delimiter                                        -- 職種コード
      || cv_enclosed || cv_nm25 || cv_enclosed || cv_delimiter                                        -- 職種名
      || cv_enclosed || cv_nm26 || cv_enclosed || cv_delimiter                                        -- 職務コード
      || cv_enclosed || cv_nm27 || cv_enclosed || cv_delimiter                                        -- 職務名
      || cv_enclosed || cv_nm28 || cv_enclosed || cv_delimiter                                        -- 承認区分
      || cv_enclosed || cv_nm29 || cv_enclosed || cv_delimiter                                        -- 代行区分
      || cv_enclosed || cv_nm30 || cv_enclosed || cv_delimiter                                        -- 作成年月日
      || cv_enclosed || cv_nm31 || cv_enclosed                                                        -- 最終更新日
    ;
    BEGIN
      -- ファイル書き込み
      UTL_FILE.PUT_LINE(gf_file_hand,lv_csv_text);
    EXCEPTION
      -- ファイルアクセス権限エラー
      WHEN UTL_FILE.INVALID_OPERATION THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cmm           -- 'XXCMM'
                        ,iv_name         => cv_msg_00007             -- ファイルアクセス権限エラー
                       );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      --
      -- CSVデータ出力エラー
      WHEN UTL_FILE.WRITE_ERROR THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cmm           -- 'XXCMM'
                        ,iv_name         => cv_msg_00009             -- CSVデータ出力エラー
                        ,iv_token_name1  => cv_tkn_word              -- トークン(NG_WORD)
                        ,iv_token_value1 => cv_tkn_word2             -- CSVヘッダ
                        ,iv_token_name2  => cv_tkn_data              -- トークン(NG_DATA)
                        ,iv_token_value2 => NULL                     -- NULL
                       );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
    --
    lv_employee_number := ' ';
    <<out_loop>>
    FOR ln_loop_cnt IN 1..gn_target_cnt LOOP
      --========================================
      -- 拠点コード(新)の入力チェック(A-4-1)
      --========================================
      IF (gt_people_data_tbl(ln_loop_cnt).ass_attribute5 IS NULL) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cmm                                 -- 'XXCMM'
                        ,iv_name         => cv_msg_00205                                   -- 拠点コード(新)取得エラー
                        ,iv_token_name1  => cv_tkn_word                                    -- トークン(NG_WORD)
                        ,iv_token_value1 => cv_tkn_word1                                   -- NG_WORD
                        ,iv_token_name2  => cv_tkn_data                                    -- トークン(NG_DATA)
                        ,iv_token_value2 => gt_people_data_tbl(ln_loop_cnt).employee_number    -- NG_WORDのDATA
                       );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
      --========================================
      -- AFF部門取得チェック(A-4-2)
      --========================================
      IF (gt_people_data_tbl(ln_loop_cnt).dpt2_cd IS NULL) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cmm                                 -- 'XXCMM'
                        ,iv_name         => cv_msg_00501                                   -- 拠点コード(新)取得エラー
                        ,iv_token_name1  => cv_tkn_kyoten                                  -- トークン(NG_KYOTEN)
                        ,iv_token_value1 => gt_people_data_tbl(ln_loop_cnt).ass_attribute5 -- NG_KYOTEN
                       );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
      --========================================
      -- 従業員番号重複チェック(A-4-3)
      -- (従業員番号が重複している場合、警告メッセージを表示)
      --========================================
      IF (lv_employee_number = gt_people_data_tbl(ln_loop_cnt).employee_number) THEN
        IF (gv_warn_flg = '0') THEN
          -- 警告フラグにオンをセット
          gv_warn_flg := '1';
          -- 空行挿入(入力パラメータの下)
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => ''
          );
        END IF;
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cmm                                 -- 'XXCMM'
                        ,iv_name         => cv_msg_00209                                   -- 従業員番号重複メッセージ
                        ,iv_token_name1  => cv_tkn_word                                    -- トークン(NG_WORD)
                        ,iv_token_value1 => cv_tkn_word1                                   -- NG_WORD
                        ,iv_token_name2  => cv_tkn_data                                    -- トークン(NG_DATA)
                        ,iv_token_value2 => gt_people_data_tbl(ln_loop_cnt).employee_number    -- NG_WORDのDATA
                                              || cv_tkn_word3
                                              || gt_people_data_tbl(ln_loop_cnt).kanji
                       );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => lv_errmsg
        );
      END IF;
      --========================================
      -- CSVファイル出力(A-5)
      --========================================
      -- 更新区分の取得
      IF (gt_people_data_tbl(ln_loop_cnt).at_date IS NOT NULL) THEN
        lv_update_kbn := cv_value3_delete;
      ELSIF ((gt_people_data_tbl(ln_loop_cnt).ass_attribute18 IS NULL)
             OR (TO_CHAR(gd_select_end_date,'YYYYMMDD') < gt_people_data_tbl(ln_loop_cnt).start_date))
      THEN
        lv_update_kbn := cv_value3_add;
      ELSE
        lv_update_kbn := cv_value3_update;
      END IF;
      lv_csv_text := cv_enclosed || cv_value1 || cv_enclosed || cv_delimiter                              -- データ種
        || cv_enclosed || cv_value2 || cv_enclosed || cv_delimiter                                        -- ファイル種
        || lv_update_kbn || cv_delimiter                                                                  -- 更新区分
        || cv_enclosed || gt_people_data_tbl(ln_loop_cnt).ass_attribute5 || cv_enclosed || cv_delimiter   -- 拠点（部門）コード
        || cv_enclosed || gt_people_data_tbl(ln_loop_cnt).ass_attribute3 || cv_enclosed || cv_delimiter   -- 勤務地コード
        || cv_enclosed || gt_people_data_tbl(ln_loop_cnt).dpt2_cd || cv_enclosed || cv_delimiter          -- 大本部コード
        || cv_enclosed || gt_people_data_tbl(ln_loop_cnt).dpt3_cd || cv_enclosed || cv_delimiter          -- 本部コード
        || cv_enclosed || gt_people_data_tbl(ln_loop_cnt).dpt4_cd || cv_enclosed || cv_delimiter          -- エリアコード
        || cv_enclosed || gt_people_data_tbl(ln_loop_cnt).dpt5_cd || cv_enclosed || cv_delimiter          -- 地区コード
        || cv_enclosed || gt_people_data_tbl(ln_loop_cnt).attribute11 || cv_enclosed || cv_delimiter      -- 職位コード
        || cv_enclosed || gt_people_data_tbl(ln_loop_cnt).ass_attribute11 || cv_enclosed || cv_delimiter  -- 職位並順コード
        || cv_enclosed || gt_people_data_tbl(ln_loop_cnt).attribute12 || cv_enclosed || cv_delimiter      -- 職位名
        || cv_enclosed || gt_people_data_tbl(ln_loop_cnt).employee_number || cv_enclosed || cv_delimiter  -- 社員番号
        || cv_enclosed || gt_people_data_tbl(ln_loop_cnt).kana || cv_enclosed || cv_delimiter             -- 従業員氏名（カナ）
        || cv_enclosed || gt_people_data_tbl(ln_loop_cnt).kanji || cv_enclosed || cv_delimiter            -- 従業員氏名（漢字）
        || NULL || cv_delimiter                                                                           -- 生年月日
        || cv_enclosed || gt_people_data_tbl(ln_loop_cnt).sex || cv_enclosed || cv_delimiter              -- 性別区分
        || gt_people_data_tbl(ln_loop_cnt).start_date || cv_delimiter                                     -- 入社年月日
        || gt_people_data_tbl(ln_loop_cnt).at_date || cv_delimiter                                        -- 退職年月日
        || cv_enclosed || gt_people_data_tbl(ln_loop_cnt).ass_attribute1 || cv_enclosed || cv_delimiter   -- 異動事由コード
        || gt_people_data_tbl(ln_loop_cnt).ass_attribute2 || cv_delimiter                                 -- 適用開始日
        || cv_enclosed || gt_people_data_tbl(ln_loop_cnt).attribute7 || cv_enclosed || cv_delimiter       -- 資格コード
        || cv_enclosed || gt_people_data_tbl(ln_loop_cnt).attribute8 || cv_enclosed || cv_delimiter       -- 資格名
        || cv_enclosed || gt_people_data_tbl(ln_loop_cnt).attribute19 || cv_enclosed || cv_delimiter      -- 職種コード
        || cv_enclosed || gt_people_data_tbl(ln_loop_cnt).attribute20 || cv_enclosed || cv_delimiter      -- 職種名
        || cv_enclosed || gt_people_data_tbl(ln_loop_cnt).attribute15 || cv_enclosed || cv_delimiter      -- 職務コード
        || cv_enclosed || gt_people_data_tbl(ln_loop_cnt).attribute16 || cv_enclosed || cv_delimiter      -- 職務名
        || cv_enclosed || gt_people_data_tbl(ln_loop_cnt).ass_attribute13 || cv_enclosed || cv_delimiter  -- 承認区分
        || cv_enclosed || gt_people_data_tbl(ln_loop_cnt).ass_attribute15 || cv_enclosed || cv_delimiter  -- 代行区分
        || NULL || cv_delimiter                                                                           -- 作成年月日
        || NULL                                                                                           -- 最終更新日
      ;
      BEGIN
        -- ファイル書き込み
        UTL_FILE.PUT_LINE(gf_file_hand,lv_csv_text);
      EXCEPTION
        -- ファイルアクセス権限エラー
        WHEN UTL_FILE.INVALID_OPERATION THEN
          lv_errmsg := xxcmn_common_pkg.get_msg(
                           iv_application  => cv_msg_kbn_cmm                               -- 'XXCMM'
                          ,iv_name         => cv_msg_00007                                 -- ファイルアクセス権限エラー
                         );
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        --
        -- CSVデータ出力エラー
        WHEN UTL_FILE.WRITE_ERROR THEN
          lv_errmsg := xxcmn_common_pkg.get_msg(
                           iv_application  => cv_msg_kbn_cmm                               -- 'XXCMM'
                          ,iv_name         => cv_msg_00009                                 -- CSVデータ出力エラー
                          ,iv_token_name1  => cv_tkn_word                                  -- トークン(NG_WORD)
                          ,iv_token_value1 => cv_tkn_word1                                 -- NG_WORD
                          ,iv_token_name2  => cv_tkn_data                                  -- トークン(NG_DATA)
                          ,iv_token_value2 => gt_people_data_tbl(ln_loop_cnt).employee_number  -- NG_WORDのDATA
                         );
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        WHEN OTHERS THEN
          RAISE global_api_others_expt;
      END;
      --===============================================
      -- 差分連携用日付更新(アサインメントマスタ)(A-6)
      --===============================================
      BEGIN
        UPDATE   per_all_assignments_f
        SET      ass_attribute18 = TO_CHAR(SYSDATE,'YYYYMMDD HH24:MI:SS')
        WHERE    assignment_id = gt_people_data_tbl(ln_loop_cnt).assignment_id
        AND      effective_start_date = TO_DATE(gt_people_data_tbl(ln_loop_cnt).start_date,'YYYYMMDD');
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := xxcmn_common_pkg.get_msg(
                           iv_application  => cv_msg_kbn_cmm                               -- 'XXCMM'
                          ,iv_name         => cv_msg_00029                                 -- アサインメントマスタ更新エラー
                          ,iv_token_name1  => cv_tkn_word                                  -- トークン(NG_WORD)
                          ,iv_token_value1 => cv_tkn_word1                                 -- NG_WORD
                          ,iv_token_name2  => cv_tkn_data                                  -- トークン(NG_DATA)
                          ,iv_token_value2 => gt_people_data_tbl(ln_loop_cnt).employee_number  -- NG_WORDのDATA
                         );
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
      END;
      -- 処理件数のカウント
      gn_normal_cnt := gn_normal_cnt + 1;
      lv_employee_number := gt_people_data_tbl(ln_loop_cnt).employee_number;
    END LOOP out_loop;
    --
    IF (gv_warn_flg = '1') THEN
      -- 空行挿入(処理件数部の上、あるいはエラーメッセージの上)
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
    END IF;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
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
  END output_csv;
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
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain';                -- プログラム名
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
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
--
    -- グローバル変数の初期化
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gv_warn_flg   := '0';
    gv_param_output_flg := '0';
    --
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
    --
    -- =====================================================
    --  初期処理プロシージャ(A-1)
    -- =====================================================
    init(
       lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
    --
    -- =====================================================
    --  社員データ取得プロシージャ(A-2)
    -- =====================================================
    get_people_data(
       lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
    --
    -- =====================================================
    --  CSVファイル出力プロシージャ(A-5)
    -- =====================================================
    IF (gn_target_cnt > 0) THEN
      output_csv(
         lv_errbuf             -- エラー・メッセージ           --# 固定 #
        ,lv_retcode            -- リターン・コード             --# 固定 #
        ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
    --
    -- =====================================================
    --  終了処理プロシージャ(A-7)
    -- =====================================================
    -- CSVファイルをクローズする
    UTL_FILE.FCLOSE(gf_file_hand);
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
    errbuf        OUT VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode       OUT VARCHAR2,      --   リターン・コード    --# 固定 #
    iv_date_from  IN  VARCHAR2,      --   1.最終更新日(開始)
    iv_date_to    IN  VARCHAR2       --   2.最終更新日(終了)
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
    lv_message_code    VARCHAR2(100);   -- 終了メッセージコード
    --
  BEGIN
--
--###########################  固定部 START   #####################################################
--
    -- 固定出力
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    xxccp_common_pkg.put_log_header(
       ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- 入力パラメータの取得
    -- ===============================================
    gv_update_sdate := iv_date_from;
    gv_update_edate := iv_date_to;
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
      lv_errbuf   -- エラー・メッセージ            --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode = cv_status_error) THEN
      --エラー出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      -- 空行挿入(エラーメッセージと処理件数部の間)
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
      IF (gv_param_output_flg = '1') THEN
        -- 空行挿入(ログの入力パラメータの下)
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => ''
        );
      END IF;
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff => lv_errbuf --エラーメッセージ
      );
      -- エラー発生時、各件数は以下に統一して出力する
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
    ELSE
      IF (gv_warn_flg = '1') THEN
        -- 警告の場合、リターン・コードに警告をセットする
        lv_retcode := cv_status_warn;
      END IF;
    END IF;
    --
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    -- 空行挿入(終了メッセージの上)
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
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
                     iv_application  => cv_appl_short_name
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --CSVファイルがクローズされていなかった場合、クローズする
    IF (UTL_FILE.IS_OPEN(gf_file_hand)) THEN
      UTL_FILE.FCLOSE(gf_file_hand);
    END IF;
    --
    --ステータスセット
    retcode := lv_retcode;
    --終了ステータスがエラーの場合はROLLBACKする
    IF (retcode = cv_status_error) THEN
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
END XXCMM002A04C;
/
