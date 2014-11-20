CREATE OR REPLACE PACKAGE BODY xxcmn800003c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXCMN800003C(body)
 * Description      : 従業員マスタインタフェース
 * MD.050           : マスタインタフェース T_MD050_BPO_800
 * MD.070           : 従業員インタフェース T_MD070_BPO_80C
 * Version          : 1.6
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  get_profile            プロファイル取得プロシージャ
 *  get_per_person_types   パーソンタイプ取得プロシージャ
 *  set_if_lock            インタフェーステーブルに対するロック取得プロシージャ
 *  set_error_status       エラーが発生した状態にするプロシージャ
 *  set_warn_status        警告が発生した状態にするプロシージャ
 *  init_status            ステータス初期化プロシージャ
 *  is_file_status_nomal   ファイルレベルで正常か状況を確認するファンクション
 *  init_row_status        行レベルステータス初期化プロシージャ
 *  is_row_status_nomal    行レベルで正常か状況を確認するファンクション
 *  is_row_status_warn     行レベルで警告か状況を確認するファンクション
 *  set_line_lock          行単位のロックを行うプロシージャ
 *  get_xxcmn_emp_if       社員インタフェースの以前の件数取得を行うプロシージャ
 *  get_per_all_people_f   従業員IDを取得し存在チェックを行うプロシージャ
 *  get_fnd_user           ユーザーIDを取得し存在チェックを行うプロシージャ
 *  get_fnd_responsibility 職責マスタの取得を行うプロシージャ
 *  get_per_ass_all_f      従業員割当マスタの存在チェックを行うプロシージャ
 *  get_po_agents          購買担当マスタの存在チェックを行うプロシージャ
 *  get_wsh_grants         出荷ロールマスタの存在チェックを行うプロシージャ
 *  get_application        アプリケーションショート名の取得を行うプロシージャ
 *  add_report             レポート用データを設定するプロシージャ
 *  disp_report            レポート用データを出力するプロシージャ
 *  delete_emp_if          社員インタフェースのデータを削除するプロシージャ
 *  get_fnd_user_resp_all  ユーザー職責マスタの取得を行うプロシージャ
 *  exists_fnd_respons     職責マスタ存在チェックを行うプロシージャ
 *  exists_fnd_user_resp   ユーザ職責マスタ存在チェックを行うプロシージャ
 *  exists_fnd_user_all    ユーザ職責マスタの存在チェックを行います。
 *  check_insert           登録用データをチェックするプロシージャ
 *  check_update           更新用データをチェックするプロシージャ
 *  check_delete           削除用データをチェックするプロシージャ
 *  check_proc_code        操作対象のレコードであることをチェックするプロシージャ
 *  get_location_new       新規登録時に担当拠点を取得し存在チェックを行うプロシージャ
 *  get_location_mod       変更・削除時に担当拠点を取得し存在チェックを行うプロシージャ
 *  get_service_id         サービス期間IDの取得を行うプロシージャ
 *  wsh_grants_proc        出荷ロールマスタの登録・削除処理を行うプロシージャ
 *  po_agents_proc         購買担当マスタの登録・削除処理を行うプロシージャ
 *  set_assignment         ユーザ職責マスタの登録処理を行うプロシージャ
 *  update_resp_all_f      ユーザー職責マスタの更新処理を行うプロシージャ
 *  delete_group_all       ユーザー職責マスタのデータを無効化するプロシージャ
 *  insert_proc            ユーザー登録情報格納処理を行うプロシージャ
 *  update_proc            ユーザー更新情報格納処理を行うプロシージャ
 *  delete_proc            ユーザー削除情報格納処理を行うプロシージャ
 *  init_proc              初期処理を行うプロシージャ
 *  submain                社員インタフェースのデータを各マスタへ反映するプロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2007/10/29    1.0   Oracle 丸下 博宣 初回作成
 *  2008/05/19    1.1   Oracle 山根 一浩 変更要求No54対応
 *  2008/05/27    1.2   Oracle 丸下 博宣 内部変更要求No122対応
 *  2008/07/07    1.3   Oracle 山根 一浩 I_S_192対応,内部変更要求No43対応
 *  2008/10/06    1.4   Oracle 椎名 昭圭 統合障害#304対応
 *  2008/11/20    1.5   Oracle 丸下 博宣 I_S_698
 *  2009/03/25    1.6   Oracle 椎名 昭圭 本番#1340対応
 *****************************************************************************************/
--
--###############################  固定グローバル定数宣言部 START   ###############################
--
  gv_status_normal CONSTANT VARCHAR2(1) := '0';   --正常
  gv_status_warn   CONSTANT VARCHAR2(1) := '1';   --警告
  gv_status_error  CONSTANT VARCHAR2(1) := '2';   --失敗
  gv_sts_cd_normal CONSTANT VARCHAR2(1) := 'C';   --ステータス(正常)
  gv_sts_cd_warn   CONSTANT VARCHAR2(1) := 'G';   --ステータス(警告)
  gv_sts_cd_error  CONSTANT VARCHAR2(1) := 'E';   --ステータス(失敗)
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  gv_msg_dot       CONSTANT VARCHAR2(3) := '.';
  gv_msg_pnt       CONSTANT VARCHAR2(3) := ',';
  gv_flg_on        CONSTANT VARCHAR2(1) := '1';
--
--#####################################  固定部 END   #############################################
--
--###############################  固定グローバル変数宣言部 START   ###############################
--
  gv_out_msg       VARCHAR2(2000);
  gv_sep_msg       VARCHAR2(2000);
  gv_exec_user     VARCHAR2(100);             -- 実行ユーザ名
  gv_conc_name     VARCHAR2(30);              -- 実行コンカレント名
  gv_conc_status   VARCHAR2(30);              -- 処理結果
  gn_target_cnt    NUMBER;                    -- 対象件数
  gn_normal_cnt    NUMBER;                    -- 正常件数
  gn_error_cnt     NUMBER;                    -- 失敗件数
  gn_warn_cnt      NUMBER;                    -- 警告件数
  gn_report_cnt    NUMBER;                    -- レポート件数
--
--#####################################  固定部 END   #############################################
--
--##################################  固定共通例外宣言部 START   ##################################
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
--#####################################  固定部 END   #############################################
--
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
  check_sub_main_expt         EXCEPTION;     -- サブメインのエラー
  delete_group_all_expt       EXCEPTION;     -- ユーザ職責マスタ削除エラー
  exists_fnd_respons_expt     EXCEPTION;     -- 職責マスタ存在チェックエラー
  exists_fnd_user_resp_expt   EXCEPTION;     -- ユーザー職責マスタ存在チェックエラー
--
  lock_expt                   EXCEPTION;     -- ロック取得例外
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  -- インタフェースデータの操作種別
  gn_proc_insert CONSTANT NUMBER := 1; -- 登録
  gn_proc_update CONSTANT NUMBER := 2; -- 更新
  gn_proc_delete CONSTANT NUMBER := 9; -- 削除
  -- 処理状況をあらわすステータス
  gn_data_status_nomal CONSTANT NUMBER := 0; -- 正常
  gn_data_status_error CONSTANT NUMBER := 1; -- 失敗
  gn_data_status_warn  CONSTANT NUMBER := 2; -- 警告
--
  gv_pkg_name          CONSTANT VARCHAR2(100) := 'xxcmn800003c'; -- パッケージ名
  gv_def_sex           CONSTANT VARCHAR2(1)   := 'M';
  gv_owner             CONSTANT VARCHAR2(4)   := 'CUST';
  gv_msg_kbn           CONSTANT VARCHAR2(5)   := 'XXCMN';
  gv_info_category     CONSTANT VARCHAR2(2)   := 'JP';
  gv_emp_if_name       CONSTANT VARCHAR2(100) := 'xxcmn_emp_if';
  gv_user_person_type  CONSTANT per_person_types.user_person_type%TYPE := '従業員';
  gv_upd_mode          CONSTANT VARCHAR2(15)  := 'CORRECTION';
--
  --メッセージ番号
  gv_msg_80c_001       CONSTANT VARCHAR2(15) := 'APP-XXCMN-00001';  --ユーザー名
  gv_msg_80c_002       CONSTANT VARCHAR2(15) := 'APP-XXCMN-00002';  --コンカレント名
  gv_msg_80c_003       CONSTANT VARCHAR2(15) := 'APP-XXCMN-00003';  --セパレータ
  gv_msg_80c_004       CONSTANT VARCHAR2(15) := 'APP-XXCMN-00005';  --成功データ(見出し)
  gv_msg_80c_005       CONSTANT VARCHAR2(15) := 'APP-XXCMN-00006';  --エラーデータ(見出し)
  gv_msg_80c_006       CONSTANT VARCHAR2(15) := 'APP-XXCMN-00007';  --スキップデータ(見出し)
  gv_msg_80c_007       CONSTANT VARCHAR2(15) := 'APP-XXCMN-00008';  --処理件数
  gv_msg_80c_008       CONSTANT VARCHAR2(15) := 'APP-XXCMN-00009';  --成功件数
  gv_msg_80c_009       CONSTANT VARCHAR2(15) := 'APP-XXCMN-00010';  --エラー件数
  gv_msg_80c_010       CONSTANT VARCHAR2(15) := 'APP-XXCMN-00011';  --スキップ件数
  gv_msg_80c_011       CONSTANT VARCHAR2(15) := 'APP-XXCMN-00012';  --処理ステータス
  gv_msg_80c_012       CONSTANT VARCHAR2(15) := 'APP-XXCMN-10002';  --プロファイル取得エラー
  gv_msg_80c_013       CONSTANT VARCHAR2(15) := 'APP-XXCMN-10018';  --APIエラー(コンカレント)
  gv_msg_80c_014       CONSTANT VARCHAR2(15) := 'APP-XXCMN-10019';  --ロックエラー
  gv_msg_80c_015       CONSTANT VARCHAR2(15) := 'APP-XXCMN-10020';  --従業員対象外レコード
  gv_msg_80c_016       CONSTANT VARCHAR2(15) := 'APP-XXCMN-10021';  --範囲外データ
  gv_msg_80c_017       CONSTANT VARCHAR2(15) := 'APP-XXCMN-10022';  --テーブル削除エラー
  gv_msg_80c_018       CONSTANT VARCHAR2(15) := 'APP-XXCMN-10023';  --登録分の重複チェックエラー
  gv_msg_80c_019       CONSTANT VARCHAR2(15) := 'APP-XXCMN-10024';  --更新分の存在チェックエラー
  gv_msg_80c_020       CONSTANT VARCHAR2(15) := 'APP-XXCMN-10025';  --削除分の削除チェックエラー
  gv_msg_80c_021       CONSTANT VARCHAR2(15) := 'APP-XXCMN-10030';  --コンカレント定型エラー
  gv_msg_80c_022       CONSTANT VARCHAR2(15) := 'APP-XXCMN-10118';  --起動時間
  gv_msg_80c_023       CONSTANT VARCHAR2(15) := 'APP-XXCMN-10036';  --データ取得エラー１
--
  --トークン
  gv_tkn_status        CONSTANT VARCHAR2(15) := 'STATUS';
  gv_tkn_cnt           CONSTANT VARCHAR2(15) := 'CNT';
  gv_tkn_conc          CONSTANT VARCHAR2(15) := 'CONC';
  gv_tkn_user          CONSTANT VARCHAR2(15) := 'USER';
  gv_tkn_ng_profile    CONSTANT VARCHAR2(15) := 'NG_PROFILE';
  gv_tkn_table         CONSTANT VARCHAR2(15) := 'TABLE';
  gv_tkn_ng_user       CONSTANT VARCHAR2(15) := 'NG_USER';
  gv_tkn_ng_tkyoten    CONSTANT VARCHAR2(15) := 'NG_TKYOTEN';
  gv_tkn_api_name      CONSTANT VARCHAR2(15) := 'API_NAME';
  gv_tkn_time          CONSTANT VARCHAR2(15) := 'TIME';
--
  --プロファイル
  gv_prf_max_date      CONSTANT VARCHAR2(15) := 'XXCMN_MAX_DATE';         -- 最大日付
  gv_prf_min_date      CONSTANT VARCHAR2(15) := 'XXCMN_MIN_DATE';         -- 最小日付
  gv_prf_role_id       CONSTANT VARCHAR2(15) := 'XXCMN_ROLE_ID';          -- 役割ID
  gv_prf_password      CONSTANT VARCHAR2(15) := 'XXCMN_PASS_WORD';        -- 初期パスワード
  gv_prf_app_short     CONSTANT VARCHAR2(25) := 'XXCMN_APP_SHORT_NAME';   -- アプリケーションID
  gv_prf_max_date_name CONSTANT VARCHAR2(50) := 'MAX日付';
  gv_prf_min_date_name CONSTANT VARCHAR2(50) := 'MIN日付';
  gv_prf_role_id_name  CONSTANT VARCHAR2(50) := '役割ID';
  gv_prf_password_name CONSTANT VARCHAR2(50) := 'ユーザー初期パスワード';
  gv_prf_short_name    CONSTANT VARCHAR2(50) := 'アプリケーションID';
--
  -- 使用DB名
  gv_xxcmn_emp_if_name          CONSTANT VARCHAR2(100) := '社員インタフェース';
--
  -- 対象DB名
  gv_per_all_people_f_name      CONSTANT VARCHAR2(100) := '従業員マスタ';
  gv_per_all_assignments_f_name CONSTANT VARCHAR2(100) := '従業員割当マスタ';
  gv_fnd_user_name              CONSTANT VARCHAR2(100) := 'ユーザーマスタ';
  gv_fnd_user_resp_group_a_name CONSTANT VARCHAR2(100) := 'ユーザー職責マスタ';
  gv_po_agents_name             CONSTANT VARCHAR2(100) := '購買担当マスタ';
  gv_wsh_grants_name            CONSTANT VARCHAR2(100) := '出荷ロールマスタ';
  gv_fnd_user_resp_name         CONSTANT VARCHAR2(100) := '職責マスタ';
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- 各マスタへの反映処理に必要なデータを格納するレコード
  TYPE masters_rec IS RECORD(
    -- 従業員インタフェース
    seq_num                   xxcmn_emp_if.seq_num%TYPE,            --SEQ番号
    proc_code                 xxcmn_emp_if.proc_code%TYPE,          --更新区分
    employee_num              xxcmn_emp_if.employee_num%TYPE,       --営業員コード
    base_code                 xxcmn_emp_if.base_code%TYPE,          --担当拠点コード
    user_name                 xxcmn_emp_if.user_name%TYPE,          --氏名
    user_name_alt             xxcmn_emp_if.user_name_alt%TYPE,      --氏名(カナ)
    position_id               xxcmn_emp_if.position_id%TYPE,        --職位
    qualification_id          xxcmn_emp_if.qualification_id%TYPE,   --資格ポイント
    spare                     xxcmn_emp_if.spare%TYPE,              --予備
    -- 事業所マスタ
    location_id               hr_locations_all.location_id%TYPE,    --ロケーションID
    po_flag                   hr_locations_all.attribute3%TYPE,     --購買担当フラグ
    wsh_flag                  hr_locations_all.attribute4%TYPE,     --出荷担当フラグ
    resp1                     hr_locations_all.attribute5%TYPE,     --担当職責１
    resp2                     hr_locations_all.attribute6%TYPE,     --担当職責２
    resp3                     hr_locations_all.attribute7%TYPE,     --担当職責３
    resp4                     hr_locations_all.attribute8%TYPE,     --担当職責４
    resp5                     hr_locations_all.attribute9%TYPE,     --担当職責５
    resp6                     hr_locations_all.attribute10%TYPE,    --担当職責６
    resp7                     hr_locations_all.attribute11%TYPE,    --担当職責７
    resp8                     hr_locations_all.attribute12%TYPE,    --担当職責８
    resp9                     hr_locations_all.attribute13%TYPE,    --担当職責９
    resp10                    hr_locations_all.attribute14%TYPE,    --担当職責１０
    -- 従業員マスタ
    person_id                 per_all_people_f.person_id%TYPE,      --従業員ID
    object_version_number     per_all_people_f.object_version_number%TYPE,
    -- 従業員割当マスタ
    ass_object_version_number per_all_assignments_f.object_version_number%TYPE,
    period_of_service_id      per_all_assignments_f.period_of_service_id%TYPE,
    assignment_id             per_all_assignments_f.assignment_id%TYPE,
    -- ユーザマスタ
    user_id                   fnd_user.user_id%TYPE,                --ユーザーID
    -- 現在のデータ以前での件数
    row_ins_cnt               NUMBER,                               -- 登録件数
    row_upd_cnt               NUMBER,                               -- 更新件数
    row_del_cnt               NUMBER                                -- 削除件数
  );
--
  -- 各マスタへ反映するデータを格納する結合配列
  TYPE masters_tbl IS TABLE OF masters_rec INDEX BY PLS_INTEGER;
--
  -- 出力するログを格納するレコード
  TYPE report_rec IS RECORD(
    seq_num                   xxcmn_emp_if.seq_num%TYPE,            --SEQ番号
    proc_code                 xxcmn_emp_if.proc_code%TYPE,          --更新区分
    employee_num              xxcmn_emp_if.employee_num%TYPE,       --従業員コード
    base_code                 xxcmn_emp_if.base_code%TYPE,          --担当拠点コード
    user_name                 xxcmn_emp_if.user_name%TYPE,          --氏名
    user_name_alt             xxcmn_emp_if.user_name_alt%TYPE,      --氏名(カナ)
    position_id               xxcmn_emp_if.position_id%TYPE,        --職位
    qualification_id          xxcmn_emp_if.qualification_id%TYPE,   --資格ポイント
    spare                     xxcmn_emp_if.spare%TYPE,              --予備
    row_level_status          NUMBER,                               -- 0.正常,1.失敗,2.警告
    -- 反映先テーブルフラグ(0:未 1:済)
    papf_flg                  NUMBER,                               --従業員マスタ
    paaf_flg                  NUMBER,                               --従業員割当マスタ
    fusr_flg                  NUMBER,                               --ユーザーマスタ
    furg_flg                  NUMBER,                               --ユーザー職責マスタ
    pagn_flg                  NUMBER,                               --購買担当マスタ
    wshg_flg                  NUMBER,                               --出荷ロールマスタ
--
    message                   VARCHAR2(1000)
  );
--
  -- 出力するレポートを格納する結合配列
  TYPE report_tbl IS TABLE OF report_rec INDEX BY PLS_INTEGER;
--
  -- 処理状況を管理するレコード
  TYPE status_rec IS RECORD(
    file_level_status         NUMBER,                               -- 0.正常,1.失敗・警告あり
    row_level_status          NUMBER,                               -- 0.正常,1.失敗,2.警告
    row_err_message           VARCHAR2(1000)                        -- エラーメッセージ
  );
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gv_min_date        VARCHAR2(10);                                  -- 最小日付
  gv_max_date        VARCHAR2(10);                                  -- 最大日付
  gv_role_id         VARCHAR2(1);                                   -- 役割ID
  gv_bisiness_grp_id per_person_types.business_group_id%TYPE;       -- ビジネスグループID
  gv_person_type     per_person_types.person_type_id%TYPE;          -- パーソンタイプ
  gv_password        fnd_user.encrypted_foundation_password%TYPE;   -- 初期パスワード
--
  gv_employee_number per_all_people_f.employee_number%TYPE;         -- 従業員番号
--
  gv_short_name      VARCHAR2(20);                                  -- アプリケーションID
--
  -- 定数
  gn_created_by               NUMBER;                     -- 作成者
  gd_creation_date            DATE;                       -- 作成日
  gd_last_update_date         DATE;                       -- 最終更新日
  gn_last_update_by           NUMBER;                     -- 最終更新者
  gn_last_update_login        NUMBER;                     -- 最終更新ログイン
  gn_request_id               NUMBER;                     -- 要求ID
  gn_program_application_id   NUMBER;                     -- プログラムアプリケーションID
  gn_program_id               NUMBER;                     -- プログラムID
  gd_program_update_date      DATE;                       -- プログラム更新日
--
  -- ===============================
  -- ユーザー定義グローバルカーソル
  -- ===============================
--
  -- 従業員マスタ
  CURSOR gc_ppf_cur
  IS
    SELECT ppf.person_id
    FROM   per_all_people_f ppf
    WHERE  EXISTS (
      SELECT xeif.employee_num
      FROM   xxcmn_emp_if xeif
      WHERE  xeif.employee_num = ppf.employee_number
      AND    ROWNUM = 1)
    FOR UPDATE OF ppf.person_id NOWAIT;
--
  -- 従業員割当マスタ
  CURSOR gc_paf_cur
  IS
    SELECT paf.assignment_id
    FROM   per_all_assignments_f paf
    WHERE  EXISTS (
      SELECT ppf.person_id
      FROM   per_all_people_f ppf
      WHERE  EXISTS (
        SELECT xeif.employee_num
        FROM   xxcmn_emp_if xeif
        WHERE  xeif.employee_num = ppf.employee_number
        AND    ROWNUM = 1)
      AND    ppf.person_id = paf.person_id
      AND    ROWNUM = 1)
    FOR UPDATE OF paf.assignment_id NOWAIT;
--
  -- ユーザーマスタ
  CURSOR gc_fu_cur
  IS
    SELECT fu.user_id
    FROM   fnd_user fu
    WHERE  EXISTS (
      SELECT ppf.person_id
      FROM   per_all_people_f ppf
      WHERE  EXISTS (
        SELECT xeif.employee_num
        FROM   xxcmn_emp_if xeif
        WHERE  xeif.employee_num = ppf.employee_number
        AND    ROWNUM = 1)
      AND    ppf.person_id = fu.employee_id
      AND    ROWNUM = 1)
    FOR UPDATE OF fu.user_id NOWAIT;
--
  -- ユーザー職責マスタ
  CURSOR gc_fug_cur
  IS
    SELECT fug.user_id
    FROM   fnd_user_resp_groups_all fug
    WHERE  EXISTS (
      SELECT fu.user_id
      FROM   fnd_user fu
      WHERE  EXISTS (
        SELECT ppf.person_id
        FROM   per_all_people_f ppf
        WHERE  EXISTS (
          SELECT xeif.employee_num
          FROM   xxcmn_emp_if xeif
          WHERE  xeif.employee_num = ppf.employee_number
          AND    ROWNUM = 1)
        AND    ppf.person_id = fu.employee_id
        AND    ROWNUM = 1)
      AND    fu.user_id = fug.user_id
      AND    ROWNUM = 1)
    FOR UPDATE OF fug.user_id NOWAIT;
--
  -- 購買担当マスタ
  CURSOR gc_poa_cur
  IS
    SELECT poa.agent_id
    FROM   po_agents poa
    WHERE  EXISTS (
      SELECT ppf.person_id
      FROM   per_all_people_f ppf
      WHERE  EXISTS (
        SELECT xeif.employee_num
        FROM   xxcmn_emp_if xeif
        WHERE  xeif.employee_num = ppf.employee_number
        AND    ROWNUM = 1)
      AND    ppf.person_id = poa.agent_id
      AND    ROWNUM = 1)
    FOR UPDATE OF poa.agent_id NOWAIT;
--
  -- 出荷ロールマスタ
  CURSOR gc_wgs_cur
  IS
    SELECT wgs.grant_id
    FROM   wsh_grants wgs
    WHERE  EXISTS (
      SELECT fu.user_id
      FROM   fnd_user fu
      WHERE  EXISTS (
        SELECT ppf.person_id
        FROM   per_all_people_f ppf
        WHERE  EXISTS (
          SELECT xeif.employee_num
          FROM   xxcmn_emp_if xeif
          WHERE  xeif.employee_num = ppf.employee_number
          AND    ROWNUM = 1)
        AND    ppf.person_id = fu.employee_id
        AND    ROWNUM = 1)
      AND    wgs.user_id = fu.user_id
      AND    ROWNUM = 1)
    FOR UPDATE OF wgs.grant_id NOWAIT;
--
  /***********************************************************************************
   * Procedure Name   : get_profile
   * Description      : プロファイルよりMAX日付,MIN日付を取得します。
   ***********************************************************************************/
  PROCEDURE get_profile(
    ov_errbuf     OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_profile'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
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
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --最大日付取得
    gv_max_date := SUBSTR(FND_PROFILE.VALUE(gv_prf_max_date),1,10);
--
    -- プロファイルが取得できない場合はエラー
    IF (gv_max_date IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,        gv_msg_80c_012,
                                            gv_tkn_ng_profile, gv_prf_max_date_name);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --最小日付取得
    gv_min_date := SUBSTR(FND_PROFILE.VALUE(gv_prf_min_date),1,10);
--
    -- プロファイルが取得できない場合はエラー
    IF (gv_min_date IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,        gv_msg_80c_012,
                                            gv_tkn_ng_profile, gv_prf_min_date_name);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --役割ID取得
    gv_role_id := NVL(FND_PROFILE.VALUE(gv_prf_role_id),1);
--
    -- プロファイルが取得できない場合はエラー
    IF (gv_role_id IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,        gv_msg_80c_012,
                                            gv_tkn_ng_profile, gv_prf_role_id_name);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- 初期パスワード取得
    gv_password := FND_PROFILE.VALUE(gv_prf_password);
--
    -- プロファイルが取得できない場合はエラー
    IF (gv_password IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,        gv_msg_80c_012,
                                            gv_tkn_ng_profile, gv_prf_password_name);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- 2008/07/07 Add ↓
    -- アプリケーションID取得
    gv_short_name := FND_PROFILE.VALUE(gv_prf_app_short);
--
    -- プロファイルが取得できない場合はエラー
    IF (gv_short_name IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,        gv_msg_80c_012,
                                            gv_tkn_ng_profile, gv_prf_short_name);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    -- 2008/07/07 Add ↑
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END get_profile;
--
  /***********************************************************************************
   * Procedure Name   : get_per_person_types
   * Description      : パーソンタイプの取得を行います。
   ***********************************************************************************/
  PROCEDURE get_per_person_types(
    ov_errbuf    OUT NOCOPY VARCHAR2,    -- エラー・メッセージ           --# 固定 #
    ov_retcode   OUT NOCOPY VARCHAR2,    -- リターン・コード             --# 固定 #
    ov_errmsg    OUT NOCOPY VARCHAR2)    -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_per_person_types'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
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
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    BEGIN
--
      gv_person_type     := NULL;
      gv_bisiness_grp_id := NULL;
--
      SELECT ppt.person_type_id
            ,ppt.business_group_id
      INTO   gv_person_type
            ,gv_bisiness_grp_id
      FROM   per_person_types ppt
      WHERE  ppt.user_person_type = gv_user_person_type
      AND    ROWNUM = 1;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        gv_person_type     := NULL;
        gv_bisiness_grp_id := NULL;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END get_per_person_types;
--
  /***********************************************************************************
   * Procedure Name   : set_if_lock
   * Description      : 社員インタフェースのテーブルロックを行います。
   ***********************************************************************************/
  PROCEDURE set_if_lock(
    ov_errbuf   OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode  OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg   OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_if_lock'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lb_retcd  BOOLEAN;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    lb_retcd := TRUE;
--
    -- テーブルロック処理(共通関数)
    lb_retcd := xxcmn_common_pkg.get_tbl_lock(gv_msg_kbn, gv_emp_if_name);
--
    -- 失敗
    IF (NOT lb_retcd) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,   gv_msg_80c_014,
                                            gv_tkn_table, gv_xxcmn_emp_if_name);
      lv_errbuf := lv_errmsg ||gv_msg_part|| SQLERRM;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END set_if_lock;
--
  /***********************************************************************************
   * Procedure Name   : set_error_status
   * Description      : エラーが発生した状態にします。
   ***********************************************************************************/
  PROCEDURE set_error_status(
    ir_status_rec IN OUT NOCOPY status_rec,  -- 処理状況
    iv_message    IN            VARCHAR2,    -- チェック対象データ
    ov_errbuf     OUT    NOCOPY VARCHAR2,    -- エラー・メッセージ           --# 固定 #
    ov_retcode    OUT    NOCOPY VARCHAR2,    -- リターン・コード             --# 固定 #
    ov_errmsg     OUT    NOCOPY VARCHAR2)    -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_error_status'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
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
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    ir_status_rec.file_level_status := gn_data_status_error;
    ir_status_rec.row_level_status  := gn_data_status_error;
    ir_status_rec.row_err_message   := iv_message;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END set_error_status;
--
  /***********************************************************************************
   * Procedure Name   : set_warn_status
   * Description      : 警告が発生した状態にします。
   ***********************************************************************************/
  PROCEDURE set_warn_status(
    ir_status_rec IN OUT NOCOPY status_rec,  -- 処理状況
    iv_message    IN            VARCHAR2,    -- チェック対象データ
    ov_errbuf     OUT    NOCOPY VARCHAR2,    -- エラー・メッセージ           --# 固定 #
    ov_retcode    OUT    NOCOPY VARCHAR2,    -- リターン・コード             --# 固定 #
    ov_errmsg     OUT    NOCOPY VARCHAR2)    -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_warn_status'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
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
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    ir_status_rec.row_level_status  := gn_data_status_warn;
    ir_status_rec.row_err_message   := iv_message;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END set_warn_status;
--
  /***********************************************************************************
   * Procedure Name   : init_status
   * Description      : ステータスを初期化します。
   ***********************************************************************************/
  PROCEDURE init_status(
    ir_status_rec IN OUT NOCOPY status_rec,  -- 処理状況
    ov_errbuf     OUT    NOCOPY VARCHAR2,    -- エラー・メッセージ           --# 固定 #
    ov_retcode    OUT    NOCOPY VARCHAR2,    -- リターン・コード             --# 固定 #
    ov_errmsg     OUT    NOCOPY VARCHAR2)    -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init_status'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
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
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    ir_status_rec.file_level_status := gn_data_status_nomal;
    ir_status_rec.row_level_status  := gn_data_status_nomal;
    ir_status_rec.row_err_message   := NULL;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END init_status;
--
--
  /***********************************************************************************
   * Function Name    : is_file_status_nomal
   * Description      : ファイルレベルで正常な状態であるかを返します。
   ***********************************************************************************/
  FUNCTION is_file_status_nomal(
    ir_status_rec  IN status_rec)  -- 処理状況
    RETURN BOOLEAN
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'is_file_status_nomal'; --プログラム名
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lb_retcd   BOOLEAN;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
--
  BEGIN
--
    -- ***************************************
    -- ***      処理ロジックの記述         ***
    -- ***************************************
    lb_retcd := FALSE;
--
    IF (ir_status_rec.file_level_status = gn_data_status_nomal) THEN
      lb_retcd := TRUE;
    END IF;
--
    RETURN lb_retcd;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--#####################################  固定部 END   #############################################
--
  END is_file_status_nomal;
--
  /***********************************************************************************
   * Procedure Name   : init_row_status
   * Description      : 行レベルのステータスを初期化します。
   ***********************************************************************************/
  PROCEDURE init_row_status(
    ir_status_rec IN OUT NOCOPY status_rec,  -- 処理状況
    ov_errbuf     OUT    NOCOPY VARCHAR2,    -- エラー・メッセージ           --# 固定 #
    ov_retcode    OUT    NOCOPY VARCHAR2,    -- リターン・コード             --# 固定 #
    ov_errmsg     OUT    NOCOPY VARCHAR2)    -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init_row_status'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
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
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    ir_status_rec.row_level_status  := gn_data_status_nomal;
    ir_status_rec.row_err_message   := NULL;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END init_row_status;
--
  /***********************************************************************************
   * Function Name    : is_row_status_nomal
   * Description      : 行レベルで正常な状態であるかを返します。
   ***********************************************************************************/
  FUNCTION is_row_status_nomal(
    ir_status_rec  IN status_rec)  -- 処理状況
    RETURN BOOLEAN
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'is_row_status_nomal'; --プログラム名
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lb_retcd   BOOLEAN;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
--
  BEGIN
--
    -- ***************************************
    -- ***      処理ロジックの記述         ***
    -- ***************************************
    lb_retcd := FALSE;
--
    IF (ir_status_rec.row_level_status = gn_data_status_nomal) THEN
      lb_retcd := TRUE;
    END IF;
--
    RETURN lb_retcd;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--#####################################  固定部 END   #############################################
--
  END is_row_status_nomal;
--
  /***********************************************************************************
   * Function Name    : is_row_status_warn
   * Description      : 行レベルで警告状態であるかを返します。
   ***********************************************************************************/
  FUNCTION is_row_status_warn(
    ir_status_rec  IN status_rec)  -- 処理状況
    RETURN BOOLEAN
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'is_row_status_warn'; --プログラム名
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lb_retcd    BOOLEAN;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
--
  BEGIN
--
    -- ***************************************
    -- ***      処理ロジックの記述         ***
    -- ***************************************
    lb_retcd := FALSE;
--
    IF (ir_status_rec.row_level_status = gn_data_status_warn) THEN
      lb_retcd := TRUE;
    END IF;
--
    RETURN lb_retcd;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--#####################################  固定部 END   #############################################
--
  END is_row_status_warn;
--
  /***********************************************************************************
   * Procedure Name   : set_line_lock
   * Description      : テーブルの行ロックを行います。
   ***********************************************************************************/
  PROCEDURE set_line_lock(
    ir_masters_rec IN  masters_rec,  -- チェック対象データ
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_line_lock'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
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
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 従業員マスタ
    BEGIN
      OPEN gc_ppf_cur;
--
    EXCEPTION
      WHEN lock_expt THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,   gv_msg_80c_014,
                                              gv_tkn_table, gv_per_all_people_f_name);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
      WHEN NO_DATA_FOUND THEN
        NULL;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    -- 従業員割当マスタ
    BEGIN
      OPEN gc_paf_cur;
--
    EXCEPTION
      WHEN lock_expt THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,   gv_msg_80c_014,
                                              gv_tkn_table, gv_per_all_assignments_f_name);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
      WHEN NO_DATA_FOUND THEN
        NULL;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    -- ユーザーマスタ
    BEGIN
      OPEN gc_fu_cur;
--
    EXCEPTION
      WHEN lock_expt THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,   gv_msg_80c_014,
                                              gv_tkn_table, gv_fnd_user_name);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
      WHEN NO_DATA_FOUND THEN
        NULL;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    -- ユーザー職責マスタ
    BEGIN
      OPEN gc_fug_cur;
--
    EXCEPTION
      WHEN lock_expt THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,   gv_msg_80c_014,
                                              gv_tkn_table, gv_fnd_user_resp_group_a_name);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
      WHEN NO_DATA_FOUND THEN
        NULL;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    -- 購買担当マスタ
    BEGIN
      OPEN gc_poa_cur;
--
    EXCEPTION
      WHEN lock_expt THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,   gv_msg_80c_014,
                                              gv_tkn_table, gv_po_agents_name);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
      WHEN NO_DATA_FOUND THEN
        NULL;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    -- 出荷ロールマスタ
    BEGIN
      OPEN gc_wgs_cur;
--
    EXCEPTION
      WHEN lock_expt THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,   gv_msg_80c_014,
                                              gv_tkn_table, gv_wsh_grants_name);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
      WHEN NO_DATA_FOUND THEN
        NULL;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END set_line_lock;
--
  /***********************************************************************************
   * Procedure Name   : get_xxcmn_emp_if
   * Description      : 社員インタフェースの過去の件数取得を行います。
   ***********************************************************************************/
  PROCEDURE get_xxcmn_emp_if(
    ir_masters_rec  IN OUT NOCOPY masters_rec, -- チェック対象データ
    ov_errbuf       OUT    NOCOPY VARCHAR2,    -- エラー・メッセージ           --# 固定 #
    ov_retcode      OUT    NOCOPY VARCHAR2,    -- リターン・コード             --# 固定 #
    ov_errmsg       OUT    NOCOPY VARCHAR2)    -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_xxcmn_emp_if'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
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
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    BEGIN
--
      ir_masters_rec.row_ins_cnt := 0;
      ir_masters_rec.row_upd_cnt := 0;
      ir_masters_rec.row_del_cnt := 0;
--
      -- 社員インタフェース
      SELECT SUM(NVL(DECODE(xei.proc_code,gn_proc_insert,1),0)),
             SUM(NVL(DECODE(xei.proc_code,gn_proc_update,1),0)),
             SUM(NVL(DECODE(xei.proc_code,gn_proc_delete,1),0))
      INTO   ir_masters_rec.row_ins_cnt,
             ir_masters_rec.row_upd_cnt,
             ir_masters_rec.row_del_cnt
      FROM   xxcmn_emp_if xei
      WHERE  xei.employee_num = ir_masters_rec.employee_num   -- 従業員コードが同じ
      AND    xei.base_code = ir_masters_rec.base_code         -- 担当拠点コードが同じ
      AND    xei.seq_num < ir_masters_rec.seq_num             -- SEQ番号が以前のデータ
      GROUP BY xei.employee_num;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ir_masters_rec.row_ins_cnt := 0;
        ir_masters_rec.row_upd_cnt := 0;
        ir_masters_rec.row_del_cnt := 0;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END get_xxcmn_emp_if;
--
  /***********************************************************************************
   * Procedure Name   : get_per_all_people_f
   * Description      : 従業員IDを取得し存在チェックを行います。
   ***********************************************************************************/
  PROCEDURE get_per_all_people_f(
    ir_masters_rec IN OUT NOCOPY masters_rec, -- チェック対象データ
    ov_errbuf      OUT    NOCOPY VARCHAR2,    -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT    NOCOPY VARCHAR2,    -- リターン・コード             --# 固定 #
    ov_errmsg      OUT    NOCOPY VARCHAR2)    -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_per_all_people_f'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
-- 
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
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
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    BEGIN
--
      -- 従業員マスタ
      SELECT papf.person_id,                                       --従業員ID
             papf.object_version_number,                           --バージョン番号
             paaf.object_version_number,                           --バージョン番号(割当)
             paaf.period_of_service_id,
             paaf.assignment_id                                    --従業員割当ID
      INTO   ir_masters_rec.person_id,
             ir_masters_rec.object_version_number,
             ir_masters_rec.ass_object_version_number,
             ir_masters_rec.period_of_service_id,
             ir_masters_rec.assignment_id
      FROM   per_all_people_f papf                                 -- 従業員マスタ
            ,per_all_assignments_f paaf                            -- 従業員割当マスタ
      WHERE  papf.employee_number = ir_masters_rec.employee_num    --従業員番号
      AND    papf.person_id = paaf.person_id
      AND    ROWNUM = 1;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ir_masters_rec.person_id                 := NULL;
        ir_masters_rec.object_version_number     := NULL;
        ir_masters_rec.ass_object_version_number := NULL;
        ir_masters_rec.period_of_service_id      := NULL;
        ir_masters_rec.assignment_id             := NULL;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END get_per_all_people_f;
--
  /***********************************************************************************
   * Procedure Name   : get_fnd_user
   * Description      : ユーザーIDを取得し存在チェックを行います。
   ***********************************************************************************/
  PROCEDURE get_fnd_user(
    ir_masters_rec IN OUT NOCOPY masters_rec, -- チェック対象データ
    ov_errbuf      OUT    NOCOPY VARCHAR2,    -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT    NOCOPY VARCHAR2,    -- リターン・コード             --# 固定 #
    ov_errmsg      OUT    NOCOPY VARCHAR2)    -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_fnd_user'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
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
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    BEGIN
--
      -- ユーザーマスタ
      SELECT fusr.user_id
      INTO   ir_masters_rec.user_id
      FROM   per_all_people_f papf                    -- 従業員マスタ
            ,fnd_user fusr                            -- ユーザーマスタ
      WHERE  papf.person_id       = fusr.employee_id
      AND    papf.employee_number = ir_masters_rec.employee_num
      AND    ROWNUM = 1;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ir_masters_rec.user_id := NULL; -- 該当データなし
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END get_fnd_user;
--
  /***********************************************************************************
   * Procedure Name   : get_fnd_responsibility
   * Description      : 職責マスタの存在チェックを行います。
   ***********************************************************************************/
  PROCEDURE get_fnd_responsibility(
    in_resp        IN         VARCHAR2,    -- 担当職責
    ob_retcd       OUT NOCOPY BOOLEAN,     -- 検索結果
    ov_errbuf      OUT NOCOPY VARCHAR2,    -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,    -- リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2)    -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_fnd_responsibility'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_cnt     NUMBER;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    ob_retcd := TRUE;
--
    -- 職責マスタ
    SELECT COUNT(fres.application_id)
    INTO   ln_cnt
    FROM   fnd_responsibility fres                    -- 職責マスタ
          ,fnd_application    fapp
    WHERE  fres.application_id         = fapp.application_id
    AND    fres.responsibility_id      = TO_NUMBER(in_resp)
    AND    fapp.application_short_name = gv_short_name
    AND    ROWNUM = 1;
--
    IF (ln_cnt < 1) THEN
      ob_retcd := FALSE;
    END IF;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END get_fnd_responsibility;
--
  /***********************************************************************************
   * Procedure Name   : get_per_ass_all_f
   * Description      : 従業員割当マスタの存在チェックを行います。
   ***********************************************************************************/
  PROCEDURE get_per_ass_all_f(
    or_masters_rec IN         masters_rec, -- チェック対象データ
    ob_retcd       OUT NOCOPY BOOLEAN,     -- 検索結果
    ov_errbuf      OUT NOCOPY VARCHAR2,    -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,    -- リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2)    -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_per_ass_all_f'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_cnt   NUMBER;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    ob_retcd := TRUE;
--
    -- 従業員割当マスタ
    SELECT COUNT(paf.assignment_id)
    INTO   ln_cnt
    FROM   per_all_people_f ppf                    -- 従業員マスタ
          ,per_all_assignments_f paf               -- 従業員割当マスタ
    WHERE  ppf.person_id       = paf.person_id
    AND    ppf.employee_number = or_masters_rec.employee_num
    AND    ROWNUM = 1;
--
    IF (ln_cnt < 1) THEN
      ob_retcd := FALSE;
    END IF;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END get_per_ass_all_f;
--
  /***********************************************************************************
   * Procedure Name   : get_po_agents
   * Description      : 購買担当マスタの存在チェックを行います。
   ***********************************************************************************/
  PROCEDURE get_po_agents(
    or_masters_rec IN         masters_rec,  -- チェック対象データ
    ob_retcd       OUT NOCOPY BOOLEAN,      -- 検索結果
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_po_agents'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_cnt   NUMBER;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    ob_retcd := TRUE;
--
    -- 購買担当マスタ
    SELECT COUNT(poa.agent_id)
    INTO   ln_cnt
    FROM   per_all_people_f ppf                   -- 従業員マスタ
          ,po_agents poa                          -- 購買担当マスタ
    WHERE  ppf.person_id       = poa.agent_id
    AND    ppf.employee_number = or_masters_rec.employee_num
    AND    ROWNUM = 1;
--
    IF (ln_cnt < 1) THEN
      ob_retcd := FALSE;
    END IF;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END get_po_agents;
--
  /***********************************************************************************
   * Procedure Name   : get_wsh_grants
   * Description      : 出荷ロールマスタの存在チェックを行います。
   ***********************************************************************************/
  PROCEDURE get_wsh_grants(
    or_masters_rec IN         masters_rec,  -- チェック対象データ
    ob_retcd       OUT NOCOPY BOOLEAN,      -- 検索結果
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_wsh_grants'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_cnt   NUMBER;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    ob_retcd := TRUE;
--
    -- 出荷ロールマスタ
    SELECT COUNT(wgs.grant_id)
    INTO   ln_cnt
    FROM   per_all_people_f ppf                  -- 従業員マスタ
          ,fnd_user fu                           -- ユーザーマスタ
          ,wsh_grants wgs                        -- 出荷ロールマスタ
    WHERE  ppf.person_id       = fu.employee_id
    AND    wgs.user_id         = fu.user_id
    AND    ppf.employee_number = or_masters_rec.employee_num
    AND    ROWNUM = 1;
--
    IF (ln_cnt < 1) THEN
      ob_retcd := FALSE;
    END IF;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END get_wsh_grants;
--
  /***********************************************************************************
   * Procedure Name   : get_application
   * Description      : 職責キーの取得を行います。
   ***********************************************************************************/
  PROCEDURE get_application(
    iv_resp_id      IN         VARCHAR2,    -- responsibility_id
    ov_resp_key     OUT NOCOPY VARCHAR2,    -- responsibility_key
    ov_app_name     OUT NOCOPY VARCHAR2,    -- application_short_name
    ob_retcd        OUT NOCOPY BOOLEAN,     -- 検索結果
    ov_errbuf       OUT NOCOPY VARCHAR2,    -- エラー・メッセージ           --# 固定 #
    ov_retcode      OUT NOCOPY VARCHAR2,    -- リターン・コード             --# 固定 #
    ov_errmsg       OUT NOCOPY VARCHAR2)    -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_application'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
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
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    BEGIN
--
      ob_retcd := TRUE;
      ov_resp_key := NULL;
      ov_app_name := NULL;
--
      SELECT fres.responsibility_key
            ,fapp.application_short_name
      INTO   ov_resp_key
            ,ov_app_name
      FROM   fnd_responsibility fres                    -- 職責マスタ
            ,fnd_application    fapp
      WHERE  fres.application_id         = fapp.application_id
      AND    fres.responsibility_id      = iv_resp_id
      AND    fapp.application_short_name = gv_short_name
      AND    ROWNUM = 1;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ob_retcd := FALSE;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END get_application;
--
  /***********************************************************************************
   * Procedure Name   : add_report
   * Description      : レポート用データを設定します。
   ***********************************************************************************/
  PROCEDURE add_report(
    ir_status_rec  IN            status_rec,
    ir_masters_rec IN            masters_rec,
    it_report_tbl  IN OUT NOCOPY report_tbl,
    ov_errbuf      OUT    NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT    NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg      OUT    NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'add_report'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lr_report_rec report_rec;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    -- レポートレコードに値を設定
    lr_report_rec.seq_num          := ir_masters_rec.seq_num;
    lr_report_rec.proc_code        := ir_masters_rec.proc_code;
    lr_report_rec.employee_num     := ir_masters_rec.employee_num;
    lr_report_rec.base_code        := ir_masters_rec.base_code;
    lr_report_rec.user_name        := ir_masters_rec.user_name;
    lr_report_rec.user_name_alt    := ir_masters_rec.user_name_alt;
    lr_report_rec.position_id      := ir_masters_rec.position_id;
    lr_report_rec.qualification_id := ir_masters_rec.qualification_id;
    lr_report_rec.spare            := ir_masters_rec.spare;
    lr_report_rec.row_level_status := ir_status_rec.row_level_status;
    lr_report_rec.message          := ir_status_rec.row_err_message;
--
    lr_report_rec.papf_flg         := 0;
    lr_report_rec.paaf_flg         := 0;
    lr_report_rec.fusr_flg         := 0;
    lr_report_rec.furg_flg         := 0;
    lr_report_rec.pagn_flg         := 0;
    lr_report_rec.wshg_flg         := 0;
--
    -- レポートテーブルに追加
    it_report_tbl(gn_report_cnt) := lr_report_rec;
    gn_report_cnt := gn_report_cnt + 1;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END add_report;
--
  /***********************************************************************************
   * Procedure Name   : disp_report
   * Description      : レポート用データを出力します。(C-11)
   ***********************************************************************************/
  PROCEDURE disp_report(
    it_report_tbl  IN         report_tbl,   -- メッセージテーブル
    disp_kbn       IN         NUMBER,       -- 表示対象区分(0:正常,1:異常,2:警告)
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'disp_report'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lr_report_rec report_rec;
    ln_disp_cnt   NUMBER;
    lv_dspbuf     VARCHAR2(5000);  -- エラー・メッセージ
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_sep_msg);
--
    -- 正常
    IF (disp_kbn = gn_data_status_nomal) THEN
      lv_dspbuf := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_80c_004);
--
    -- エラー
    ELSIF (disp_kbn = gn_data_status_error) THEN
      lv_dspbuf := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_80c_005);
--
    -- 警告
    ELSIF (disp_kbn = gn_data_status_warn) THEN
      lv_dspbuf := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_80c_006);
    END IF;
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_dspbuf);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    -- 設定されているレポートの出力
    <<disp_report_loop>>
    FOR ln_disp_cnt IN 0..gn_report_cnt-1 LOOP
      lr_report_rec := it_report_tbl(ln_disp_cnt);
--
      --入力データの再構成
      lv_dspbuf := TO_CHAR(lr_report_rec.seq_num)   || gv_msg_pnt ||    --SEQ番号
                   TO_CHAR(lr_report_rec.proc_code) || gv_msg_pnt ||    --更新区分
                   lr_report_rec.employee_num       || gv_msg_pnt ||    --営業員コード
                   lr_report_rec.base_code          || gv_msg_pnt ||    --担当拠点コード
                   lr_report_rec.user_name          || gv_msg_pnt ||    --氏名
                   lr_report_rec.user_name_alt      || gv_msg_pnt ||    --氏名(カナ)
                   lr_report_rec.position_id        || gv_msg_pnt ||    --職位
                   lr_report_rec.qualification_id   || gv_msg_pnt ||    --資格ポイント
                   lr_report_rec.spare;                                 --予備
--
      -- 対象
      IF (lr_report_rec.row_level_status = disp_kbn) THEN
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_dspbuf);
--
        -- 正常
        IF (disp_kbn = gn_data_status_nomal) THEN
          -- 従業員マスタ
          IF (lr_report_rec.papf_flg = 1) THEN
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_per_all_people_f_name);
          END IF;
          -- 従業員割当マスタ
          IF (lr_report_rec.paaf_flg = 1) THEN
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_per_all_assignments_f_name);
          END IF;
          -- ユーザーマスタ
          IF (lr_report_rec.fusr_flg = 1) THEN
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_fnd_user_name);
          END IF;
          -- ユーザー職責マスタ
          IF (lr_report_rec.furg_flg = 1) THEN
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_fnd_user_resp_group_a_name);
          END IF;
          -- 購買担当マスタ
          IF (lr_report_rec.pagn_flg = 1) THEN
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_po_agents_name);
          END IF;
          -- 出荷ロールマスタ
          IF (lr_report_rec.wshg_flg = 1) THEN
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_wsh_grants_name);
          END IF;
--
        -- 正常以外
        ELSE
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lr_report_rec.message);
        END IF;
      END IF;
--
    END LOOP disp_report_loop;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END disp_report;
--
  /***********************************************************************************
   * Procedure Name   : delete_emp_if
   * Description      : 社員インタフェースのデータを削除します。(C-11)
   ***********************************************************************************/
  PROCEDURE delete_emp_if(
    ov_errbuf     OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_emp_if'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lb_retcd   BOOLEAN;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
 --#####################################  固定部 END   #############################################--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    lb_retcd := TRUE;
--
    -- データ削除(共通関数)
    lb_retcd := xxcmn_common_pkg.del_all_data(gv_msg_kbn, gv_emp_if_name);
--
    -- 失敗
    IF (NOT lb_retcd) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,   gv_msg_80c_017,
                                            gv_tkn_table, gv_xxcmn_emp_if_name);
      lv_errbuf := lv_errmsg ||gv_msg_part|| SQLERRM;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END delete_emp_if;
--
  /***********************************************************************************
   * Procedure Name   : get_fnd_user_resp_all
   * Description      : ユーザー職責マスタの取得を行います。
   ***********************************************************************************/
  PROCEDURE get_fnd_user_resp_all(
    in_user_id               IN         NUMBER,
    in_respons_id            IN         NUMBER,
    on_responsibility_app_id OUT        NUMBER,
    on_security_group_id     OUT        NUMBER,
    od_start_date            OUT        DATE,
    ob_retcd                 OUT NOCOPY BOOLEAN,     -- 検索結果
    ov_errbuf                OUT NOCOPY VARCHAR2,    -- エラー・メッセージ           --# 固定 #
    ov_retcode               OUT NOCOPY VARCHAR2,    -- リターン・コード             --# 固定 #
    ov_errmsg                OUT NOCOPY VARCHAR2)    -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_fnd_user_resp_all'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
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
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    BEGIN
--
      ob_retcd := TRUE;
--
      -- ユーザー職責マスタ
      SELECT fug.responsibility_application_id,
             fug.security_group_id,
             fug.start_date
      INTO   on_responsibility_app_id,
             on_security_group_id,
             od_start_date
      FROM   fnd_user_resp_groups_all fug                  -- ユーザー職責マスタ
      WHERE  fug.user_id           = in_user_id
      AND    fug.responsibility_id = in_respons_id
      AND    ROWNUM = 1;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ob_retcd := FALSE;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END get_fnd_user_resp_all;
--
  /***********************************************************************************
   * Procedure Name   : exists_fnd_respons
   * Description      : 職責マスタ存在チェックを行います。
   ***********************************************************************************/
  PROCEDURE exists_fnd_respons(
    ir_masters_rec IN OUT NOCOPY masters_rec,  -- チェック対象データ
    ob_retcd       OUT    NOCOPY BOOLEAN,      -- 検索結果
    ov_errbuf      OUT    NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT    NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg      OUT    NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'exists_fnd_respons'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lb_retcd     BOOLEAN;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
--
--#####################################  固定部 END   #############################################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    ob_retcd := TRUE;
--
    -- 職責マスタ存在チェック
    -- 担当職責１
    IF (ir_masters_rec.resp1 IS NOT NULL) THEN
      get_fnd_responsibility(ir_masters_rec.resp1,
                             lb_retcd,
                             lv_errbuf,
                             lv_retcode,
                             lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      -- 存在しない
      IF NOT (lb_retcd) THEN
        RAISE exists_fnd_respons_expt;
      END IF;
    END IF;
    -- 担当職責２
    IF (ir_masters_rec.resp2 IS NOT NULL) THEN
      get_fnd_responsibility(ir_masters_rec.resp2,
                             lb_retcd,
                             lv_errbuf,
                             lv_retcode,
                             lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      -- 存在しない
      IF NOT (lb_retcd) THEN
        RAISE exists_fnd_respons_expt;
      END IF;
    END IF;
    -- 担当職責３
    IF (ir_masters_rec.resp3 IS NOT NULL) THEN
      get_fnd_responsibility(ir_masters_rec.resp3,
                             lb_retcd,
                             lv_errbuf,
                             lv_retcode,
                             lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      -- 存在しない
      IF NOT (lb_retcd) THEN
        RAISE exists_fnd_respons_expt;
      END IF;
    END IF;
    -- 担当職責４
    IF (ir_masters_rec.resp4 IS NOT NULL) THEN
      get_fnd_responsibility(ir_masters_rec.resp4,
                             lb_retcd,
                             lv_errbuf,
                             lv_retcode,
                             lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      -- 存在しない
      IF NOT (lb_retcd) THEN
        RAISE exists_fnd_respons_expt;
      END IF;
    END IF;
    -- 担当職責５
    IF (ir_masters_rec.resp5 IS NOT NULL) THEN
      get_fnd_responsibility(ir_masters_rec.resp5,
                             lb_retcd,
                             lv_errbuf,
                             lv_retcode,
                             lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      -- 存在しない
      IF NOT (lb_retcd) THEN
        RAISE exists_fnd_respons_expt;
      END IF;
    END IF;
    -- 担当職責６
    IF (ir_masters_rec.resp6 IS NOT NULL) THEN
      get_fnd_responsibility(ir_masters_rec.resp6,
                             lb_retcd,
                             lv_errbuf,
                             lv_retcode,
                             lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      -- 存在しない
      IF NOT (lb_retcd) THEN
        RAISE exists_fnd_respons_expt;
      END IF;
    END IF;
    -- 担当職責７
    IF (ir_masters_rec.resp7 IS NOT NULL) THEN
      get_fnd_responsibility(ir_masters_rec.resp7,
                             lb_retcd,
                             lv_errbuf,
                             lv_retcode,
                             lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      -- 存在しない
      IF NOT (lb_retcd) THEN
        RAISE exists_fnd_respons_expt;
      END IF;
    END IF;
    -- 担当職責８
    IF (ir_masters_rec.resp8 IS NOT NULL) THEN
      get_fnd_responsibility(ir_masters_rec.resp8,
                             lb_retcd,
                             lv_errbuf,
                             lv_retcode,
                             lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      -- 存在しない
      IF NOT (lb_retcd) THEN
        RAISE exists_fnd_respons_expt;
      END IF;
    END IF;
    -- 担当職責９
    IF (ir_masters_rec.resp9 IS NOT NULL) THEN
      get_fnd_responsibility(ir_masters_rec.resp9,
                             lb_retcd,
                             lv_errbuf,
                             lv_retcode,
                             lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      -- 存在しない
      IF NOT (lb_retcd) THEN
        RAISE exists_fnd_respons_expt;
      END IF;
    END IF;
    -- 担当職責１０
    IF (ir_masters_rec.resp10 IS NOT NULL) THEN
      get_fnd_responsibility(ir_masters_rec.resp10,
                             lb_retcd,
                             lv_errbuf,
                             lv_retcode,
                             lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      -- 存在しない
      IF NOT (lb_retcd) THEN
        RAISE exists_fnd_respons_expt;
      END IF;
    END IF;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN  exists_fnd_respons_expt THEN
      ob_retcd := FALSE;
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END exists_fnd_respons;
--
  /***********************************************************************************
   * Procedure Name   : exists_fnd_user_all
   * Description      : ユーザー職責マスタの存在チェックを行います。
   ***********************************************************************************/
  PROCEDURE exists_fnd_user_all(
    in_user_id    IN         NUMBER,
    in_respons_id IN         NUMBER,
    ob_retcd      OUT NOCOPY BOOLEAN,     -- 検索結果
    ov_errbuf     OUT NOCOPY VARCHAR2,    -- エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,    -- リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)    -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'exists_fnd_user_all'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_cnt     NUMBER;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    ob_retcd := TRUE;
--
    -- ユーザー職責マスタ
    SELECT COUNT(furg.responsibility_application_id)
    INTO   ln_cnt
    FROM   fnd_user_resp_groups_all furg                     -- ユーザー職責マスタ
    WHERE  furg.user_id           = in_user_id
    AND    furg.responsibility_id = in_respons_id
    AND    ROWNUM = 1;
--
    -- 存在しない
    IF (ln_cnt < 1) THEN
      ob_retcd := FALSE;
    END IF;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END exists_fnd_user_all;
--
  /***********************************************************************************
   * Procedure Name   : exists_fnd_user_resp
   * Description      : ユーザー職責マスタ存在チェックを行います。
   ***********************************************************************************/
  PROCEDURE exists_fnd_user_resp(
    ir_masters_rec IN OUT NOCOPY masters_rec,  -- チェック対象データ
    ob_retcd       OUT    NOCOPY BOOLEAN,      -- 結果
    ov_errbuf      OUT    NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT    NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg      OUT    NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'exists_fnd_user_resp'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lb_retcd     BOOLEAN;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
--
--#####################################  固定部 END   #############################################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    ob_retcd := TRUE;
--
    -- ユーザー職責マスタ存在チェック
    -- 担当職責１
    IF (ir_masters_rec.resp1 IS NOT NULL) THEN
--
      exists_fnd_user_all(ir_masters_rec.user_id,
                          TO_NUMBER(ir_masters_rec.resp1),
                          lb_retcd,
                          lv_errbuf,
                          lv_retcode,
                          lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE exists_fnd_user_resp_expt;
      END IF;
--
      -- 存在する
      IF (lb_retcd) THEN
        -- 登録
        IF (ir_masters_rec.proc_code = gn_proc_insert) THEN
          RAISE exists_fnd_user_resp_expt;
        END IF;
--
      -- 存在しない
      ELSE
        -- 登録以外かつ以前に登録データが存在していない
        IF ((ir_masters_rec.proc_code <> gn_proc_insert) 
        AND (ir_masters_rec.row_ins_cnt = 0)) THEN
          RAISE exists_fnd_user_resp_expt;
        END IF;
      END IF;
    END IF;
--
    -- 担当職責２
    IF (ir_masters_rec.resp2 IS NOT NULL) THEN
--
      exists_fnd_user_all(ir_masters_rec.user_id,
                          TO_NUMBER(ir_masters_rec.resp2),
                          lb_retcd,
                          lv_errbuf,
                          lv_retcode,
                          lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE exists_fnd_user_resp_expt;
      END IF;
--
      -- 存在する
      IF (lb_retcd) THEN
        -- 登録
        IF (ir_masters_rec.proc_code = gn_proc_insert) THEN
          RAISE exists_fnd_user_resp_expt;
        END IF;
--
      -- 存在しない
      ELSE
        -- 登録以外かつ以前に登録データが存在していない
        IF ((ir_masters_rec.proc_code <> gn_proc_insert) 
        AND (ir_masters_rec.row_ins_cnt = 0)) THEN
          RAISE exists_fnd_user_resp_expt;
        END IF;
      END IF;
    END IF;
--
    -- 担当職責３
    IF (ir_masters_rec.resp3 IS NOT NULL) THEN
--
      exists_fnd_user_all(ir_masters_rec.user_id,
                          TO_NUMBER(ir_masters_rec.resp3),
                          lb_retcd,
                          lv_errbuf,
                          lv_retcode,
                          lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE exists_fnd_user_resp_expt;
      END IF;
--
      -- 存在する
      IF (lb_retcd) THEN
        -- 登録
        IF (ir_masters_rec.proc_code = gn_proc_insert) THEN
          RAISE exists_fnd_user_resp_expt;
        END IF;
--
      -- 存在しない
      ELSE
        -- 登録以外かつ以前に登録データが存在していない
        IF ((ir_masters_rec.proc_code <> gn_proc_insert) 
        AND (ir_masters_rec.row_ins_cnt = 0)) THEN
          RAISE exists_fnd_user_resp_expt;
        END IF;
      END IF;
    END IF;
--
    -- 担当職責４
    IF (ir_masters_rec.resp4 IS NOT NULL) THEN
--
      exists_fnd_user_all(ir_masters_rec.user_id,
                          TO_NUMBER(ir_masters_rec.resp4),
                          lb_retcd,
                          lv_errbuf,
                          lv_retcode,
                          lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE exists_fnd_user_resp_expt;
      END IF;
--
      -- 存在する
      IF (lb_retcd) THEN
        -- 登録
        IF (ir_masters_rec.proc_code = gn_proc_insert) THEN
          RAISE exists_fnd_user_resp_expt;
        END IF;
--
      -- 存在しない
      ELSE
        -- 登録以外かつ以前に登録データが存在していない
        IF ((ir_masters_rec.proc_code <> gn_proc_insert) 
        AND (ir_masters_rec.row_ins_cnt = 0)) THEN
          RAISE exists_fnd_user_resp_expt;
        END IF;
      END IF;
    END IF;
--
    -- 担当職責５
    IF (ir_masters_rec.resp5 IS NOT NULL) THEN
--
      exists_fnd_user_all(ir_masters_rec.user_id,
                          TO_NUMBER(ir_masters_rec.resp5),
                          lb_retcd,
                          lv_errbuf,
                          lv_retcode,
                          lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE exists_fnd_user_resp_expt;
      END IF;
--
      -- 存在する
      IF (lb_retcd) THEN
        -- 登録
        IF (ir_masters_rec.proc_code = gn_proc_insert) THEN
          RAISE exists_fnd_user_resp_expt;
        END IF;
--
      -- 存在しない
      ELSE
        -- 登録以外かつ以前に登録データが存在していない
        IF ((ir_masters_rec.proc_code <> gn_proc_insert) 
        AND (ir_masters_rec.row_ins_cnt = 0)) THEN
          RAISE exists_fnd_user_resp_expt;
        END IF;
      END IF;
    END IF;
--
    -- 担当職責６
    IF (ir_masters_rec.resp6 IS NOT NULL) THEN
--
      exists_fnd_user_all(ir_masters_rec.user_id,
                          TO_NUMBER(ir_masters_rec.resp6),
                          lb_retcd,
                          lv_errbuf,
                          lv_retcode,
                          lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE exists_fnd_user_resp_expt;
      END IF;
--
      -- 存在する
      IF (lb_retcd) THEN
        -- 登録
        IF (ir_masters_rec.proc_code = gn_proc_insert) THEN
          RAISE exists_fnd_user_resp_expt;
        END IF;
--
      -- 存在しない
      ELSE
        -- 登録以外かつ以前に登録データが存在していない
        IF ((ir_masters_rec.proc_code <> gn_proc_insert) 
        AND (ir_masters_rec.row_ins_cnt = 0)) THEN
          RAISE exists_fnd_user_resp_expt;
        END IF;
      END IF;
    END IF;
--
    -- 担当職責７
    IF (ir_masters_rec.resp7 IS NOT NULL) THEN
--
      exists_fnd_user_all(ir_masters_rec.user_id,
                          TO_NUMBER(ir_masters_rec.resp7),
                          lb_retcd,
                          lv_errbuf,
                          lv_retcode,
                          lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE exists_fnd_user_resp_expt;
      END IF;
--
      -- 存在する
      IF (lb_retcd) THEN
        -- 登録
        IF (ir_masters_rec.proc_code = gn_proc_insert) THEN
          RAISE exists_fnd_user_resp_expt;
        END IF;
--
      -- 存在しない
      ELSE
        -- 登録以外かつ以前に登録データが存在していない
        IF ((ir_masters_rec.proc_code <> gn_proc_insert) 
        AND (ir_masters_rec.row_ins_cnt = 0)) THEN
          RAISE exists_fnd_user_resp_expt;
        END IF;
      END IF;
    END IF;
--
    -- 担当職責８
    IF (ir_masters_rec.resp8 IS NOT NULL) THEN
--
      exists_fnd_user_all(ir_masters_rec.user_id,
                          TO_NUMBER(ir_masters_rec.resp8),
                          lb_retcd,
                          lv_errbuf,
                          lv_retcode,
                          lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE exists_fnd_user_resp_expt;
      END IF;
--
      -- 存在する
      IF (lb_retcd) THEN
        -- 登録
        IF (ir_masters_rec.proc_code = gn_proc_insert) THEN
          RAISE exists_fnd_user_resp_expt;
        END IF;
--
      -- 存在しない
      ELSE
        -- 登録以外かつ以前に登録データが存在していない
        IF ((ir_masters_rec.proc_code <> gn_proc_insert) 
        AND (ir_masters_rec.row_ins_cnt = 0)) THEN
          RAISE exists_fnd_user_resp_expt;
        END IF;
      END IF;
    END IF;
--
    -- 担当職責９
    IF (ir_masters_rec.resp9 IS NOT NULL) THEN
--
      exists_fnd_user_all(ir_masters_rec.user_id,
                          TO_NUMBER(ir_masters_rec.resp9),
                          lb_retcd,
                          lv_errbuf,
                          lv_retcode,
                          lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE exists_fnd_user_resp_expt;
      END IF;
--
      -- 存在する
      IF (lb_retcd) THEN
        -- 登録
        IF (ir_masters_rec.proc_code = gn_proc_insert) THEN
          RAISE exists_fnd_user_resp_expt;
        END IF;
--
      -- 存在しない
      ELSE
        -- 登録以外かつ以前に登録データが存在していない
        IF ((ir_masters_rec.proc_code <> gn_proc_insert) 
        AND (ir_masters_rec.row_ins_cnt = 0)) THEN
          RAISE exists_fnd_user_resp_expt;
        END IF;
      END IF;
    END IF;
--
    -- 担当職責１０
    IF (ir_masters_rec.resp10 IS NOT NULL) THEN
--
      exists_fnd_user_all(ir_masters_rec.user_id,
                          TO_NUMBER(ir_masters_rec.resp10),
                          lb_retcd,
                          lv_errbuf,
                          lv_retcode,
                          lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE exists_fnd_user_resp_expt;
      END IF;
--
      -- 存在する
      IF (lb_retcd) THEN
        -- 登録
        IF (ir_masters_rec.proc_code = gn_proc_insert) THEN
          RAISE exists_fnd_user_resp_expt;
        END IF;
--
      -- 存在しない
      ELSE
        -- 登録以外かつ以前に登録データが存在していない
            IF ((ir_masters_rec.proc_code <> gn_proc_insert)
            AND (ir_masters_rec.row_ins_cnt = 0)) THEN
          RAISE exists_fnd_user_resp_expt;
        END IF;
      END IF;
    END IF;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN exists_fnd_user_resp_expt THEN
      ob_retcd := FALSE;
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END exists_fnd_user_resp;
--
  /***********************************************************************************
   * Procedure Name   : check_insert
   * Description      : 登録用データのチェック処理を行います。(C-4)
   ***********************************************************************************/
  PROCEDURE check_insert(
    ir_status_rec  IN OUT NOCOPY status_rec,  -- 処理状況
    ir_masters_rec IN OUT NOCOPY masters_rec, -- チェック対象データ
    ov_errbuf      OUT    NOCOPY VARCHAR2,    -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT    NOCOPY VARCHAR2,    -- リターン・コード             --# 固定 #
    ov_errmsg      OUT    NOCOPY VARCHAR2)    -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_insert'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lb_retcd     BOOLEAN;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    IF (is_row_status_nomal(ir_status_rec)) THEN
      -- 従業員存在チェック
      get_per_all_people_f(ir_masters_rec,
                           lv_errbuf,
                           lv_retcode,
                           lv_errmsg);
--
      -- 従業員取得エラー
      IF (lv_retcode <> gv_status_normal) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,     gv_msg_80c_018,
                                              gv_tkn_ng_user, ir_masters_rec.employee_num,
                                              gv_tkn_table,   gv_per_all_people_f_name);
        RAISE global_api_expt;
      END IF;
--
      -- 従業員が存在する
      IF (ir_masters_rec.person_id IS NOT NULL) THEN
        set_error_status(ir_status_rec,
                         xxcmn_common_pkg.get_msg(gv_msg_kbn,     gv_msg_80c_018,
                                                  gv_tkn_ng_user, ir_masters_rec.employee_num,
                                                  gv_tkn_table,   gv_per_all_people_f_name),
                         lv_errbuf,
                         lv_retcode,
                         lv_errmsg);
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
        END IF;
      END IF;
--
      -- ユーザ存在チェック
      get_fnd_user(ir_masters_rec,
                   lv_errbuf,
                   lv_retcode,
                   lv_errmsg);
--
      -- ユーザ取得エラー
      IF (lv_retcode <> gv_status_normal) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,     gv_msg_80c_018,
                                              gv_tkn_ng_user, ir_masters_rec.employee_num,
                                              gv_tkn_table,   gv_fnd_user_name);
        RAISE global_api_expt;
      END IF;
--
      -- ユーザが存在する
      IF (ir_masters_rec.user_id IS NOT NULL) THEN
        set_error_status(ir_status_rec,
                         xxcmn_common_pkg.get_msg(gv_msg_kbn,     gv_msg_80c_018,
                                                  gv_tkn_ng_user, ir_masters_rec.employee_num,
                                                  gv_tkn_table,   gv_fnd_user_name),
                         lv_errbuf,
                         lv_retcode,
                         lv_errmsg);
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
        END IF;
      END IF;
--
      -- 職責マスタ存在チェック
      exists_fnd_respons(ir_masters_rec,
                         lb_retcd,
                         lv_errbuf,
                         lv_retcode,
                         lv_errmsg);
--
      IF ((lv_retcode = gv_status_error) OR (NOT lb_retcd)) THEN
        set_error_status(ir_status_rec,
                         xxcmn_common_pkg.get_msg(gv_msg_kbn,     gv_msg_80c_018,
                                                  gv_tkn_ng_user, ir_masters_rec.employee_num,
                                                  gv_tkn_table,   gv_fnd_user_name),
                         lv_errbuf,
                         lv_retcode,
                         lv_errmsg);
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
        END IF;
        IF (NOT lb_retcd) THEN
          NULL;
        ELSE
          RAISE global_api_expt;
        END IF;
      END IF;
    END IF;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END check_insert;
--
  /***********************************************************************************
   * Procedure Name   : check_update
   * Description      : 更新用データのチェック処理を行います。(C-5)
   ***********************************************************************************/
  PROCEDURE check_update(
    ir_status_rec  IN OUT NOCOPY status_rec,  -- 処理状況
    ir_masters_rec IN OUT NOCOPY masters_rec, -- チェック対象データ
    ov_errbuf      OUT    NOCOPY VARCHAR2,    -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT    NOCOPY VARCHAR2,    -- リターン・コード             --# 固定 #
    ov_errmsg      OUT    NOCOPY VARCHAR2)    -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_update'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
--
    -- *** ローカル・カーソル ***
    lb_retcd     BOOLEAN;
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
      IF (is_row_status_nomal(ir_status_rec)) THEN
--
        -- 従業員存在チェック
        get_per_all_people_f(ir_masters_rec,
                             lv_errbuf,
                             lv_retcode,
                             lv_errmsg);
--
        -- 従業員取得エラー
        IF (lv_retcode <> gv_status_normal) THEN
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,     gv_msg_80c_019,
                                                gv_tkn_ng_user, ir_masters_rec.employee_num,
                                                gv_tkn_table,   gv_per_all_people_f_name);
          RAISE global_api_expt;
        END IF;
--
        -- 従業員が存在しないかつ以前に登録データが存在しない場合
        IF ((ir_masters_rec.person_id IS NULL) AND (ir_masters_rec.row_ins_cnt = 0)) THEN
--
          set_error_status(ir_status_rec,
                           xxcmn_common_pkg.get_msg(gv_msg_kbn,     gv_msg_80c_019,
                                                    gv_tkn_ng_user, ir_masters_rec.employee_num,
                                                    gv_tkn_table,   gv_per_all_people_f_name),
                           lv_errbuf,
                           lv_retcode,
                           lv_errmsg);
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_api_expt;
          END IF;
        END IF;
--
        -- ユーザ存在チェック
        get_fnd_user(ir_masters_rec,
                     lv_errbuf,
                     lv_retcode,
                     lv_errmsg);
--
        -- ユーザ取得エラー
        IF (lv_retcode <> gv_status_normal) THEN
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,     gv_msg_80c_019,
                                                gv_tkn_ng_user, ir_masters_rec.employee_num,
                                                gv_tkn_table,   gv_fnd_user_name);
          RAISE global_api_expt;
        END IF;
--
        -- ユーザが存在しないかつ以前に登録データが存在しない場合
        IF ((ir_masters_rec.user_id IS NULL) AND (ir_masters_rec.row_ins_cnt = 0)) THEN
--
          set_error_status(ir_status_rec,
                           xxcmn_common_pkg.get_msg(gv_msg_kbn,     gv_msg_80c_019,
                                                    gv_tkn_ng_user, ir_masters_rec.employee_num,
                                                    gv_tkn_table,   gv_fnd_user_name),
                           lv_errbuf,
                           lv_retcode,
                           lv_errmsg);
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_api_expt;
          END IF;
        END IF;
--
        -- 従業員割当マスタの存在チェック
        get_per_ass_all_f(ir_masters_rec,
                          lb_retcd,
                          lv_errbuf,
                          lv_retcode,
                          lv_errmsg);
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
        END IF;
--
        -- 存在しない かつ 以前に登録データが存在しない
        IF ((NOT lb_retcd) AND (ir_masters_rec.row_ins_cnt = 0)) THEN
          set_error_status(ir_status_rec,
                           xxcmn_common_pkg.get_msg(gv_msg_kbn,     gv_msg_80c_019,
                                                    gv_tkn_ng_user, ir_masters_rec.employee_num,
                                                    gv_tkn_table,   gv_per_all_assignments_f_name),
                           lv_errbuf,
                           lv_retcode,
                           lv_errmsg);
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_api_expt;
          END IF;
        END IF;
--
-- 2009/03/25 v1.6 DELETE START
/*
        -- 購買担当マスタ存在チェック
        IF (ir_masters_rec.po_flag = gv_flg_on) THEN
          get_po_agents(ir_masters_rec,
                        lb_retcd,
                        lv_errbuf,
                        lv_retcode,
                        lv_errmsg);
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_api_expt;
          END IF;
--
          -- 存在しない かつ 以前に登録データが存在しない
          IF ((NOT lb_retcd) AND (ir_masters_rec.row_ins_cnt = 0)) THEN
            set_error_status(ir_status_rec,
                             xxcmn_common_pkg.get_msg(gv_msg_kbn,     gv_msg_80c_019,
                                                      gv_tkn_ng_user, ir_masters_rec.employee_num,
                                                      gv_tkn_table,   gv_po_agents_name),
                             lv_errbuf,
                             lv_retcode,
                             lv_errmsg);
--
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_api_expt;
            END IF;
          END IF;
        END IF;
--
        -- 出荷ロールマスタ存在チェック
        IF (ir_masters_rec.wsh_flag = gv_flg_on) THEN
          get_wsh_grants(ir_masters_rec,
                         lb_retcd,
                         lv_errbuf,
                         lv_retcode,
                         lv_errmsg);
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_api_expt;
          END IF;
--
          -- 存在しない かつ 以前に登録データが存在しない
          IF ((NOT lb_retcd) AND (ir_masters_rec.row_ins_cnt = 0)) THEN
            set_error_status(ir_status_rec,
                             xxcmn_common_pkg.get_msg(gv_msg_kbn,     gv_msg_80c_019,
                                                      gv_tkn_ng_user, ir_masters_rec.employee_num,
                                                      gv_tkn_table,   gv_wsh_grants_name),
                             lv_errbuf,
                             lv_retcode,
                             lv_errmsg);
--
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_api_expt;
            END IF;
          END IF;
        END IF;
--
*/
-- 2009/03/25 v1.6 DELETE END
        -- 職責マスタ存在チェック
        exists_fnd_respons(ir_masters_rec,
                         lb_retcd,
                         lv_errbuf,
                         lv_retcode,
                         lv_errmsg);
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
        END IF;
--
        -- 存在しない かつ 以前に登録データが存在しない
        IF ((NOT lb_retcd) AND (ir_masters_rec.row_ins_cnt = 0)) THEN
          set_error_status(ir_status_rec,
                           xxcmn_common_pkg.get_msg(gv_msg_kbn,     gv_msg_80c_019,
                                                    gv_tkn_ng_user, ir_masters_rec.employee_num,
                                                    gv_tkn_table,   gv_fnd_user_resp_name),
                           lv_errbuf,
                           lv_retcode,
                           lv_errmsg);
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_api_expt;
          END IF;
        END IF;
      END IF;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END check_update;
--
  /***********************************************************************************
   * Procedure Name   : check_delete
   * Description      : 削除用データのチェック処理を行います。(C-6)
   ***********************************************************************************/
  PROCEDURE check_delete(
    ir_status_rec  IN OUT NOCOPY status_rec,  -- 処理状況
    ir_masters_rec IN OUT NOCOPY masters_rec, -- チェック対象データ
    ov_errbuf      OUT    NOCOPY VARCHAR2,    -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT    NOCOPY VARCHAR2,    -- リターン・コード             --# 固定 #
    ov_errmsg      OUT    NOCOPY VARCHAR2)    -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_delete'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lb_retcd     BOOLEAN;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
--
  BEGIN
--
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
      IF (is_row_status_nomal(ir_status_rec)) THEN
--
        -- 従業員存在チェック
        get_per_all_people_f(ir_masters_rec,
                             lv_errbuf,
                             lv_retcode,
                             lv_errmsg);
--
        -- 従業員取得エラー
        IF (lv_retcode <> gv_status_normal) THEN
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,     gv_msg_80c_020,
                                                gv_tkn_ng_user, ir_masters_rec.employee_num,
                                                gv_tkn_table,   gv_per_all_people_f_name);
          RAISE global_api_expt;
        END IF;
--
        -- 従業員が存在しないかつ以前に登録データが存在しない場合はエラー
        IF ((ir_masters_rec.person_id IS NULL) AND (ir_masters_rec.row_ins_cnt = 0)) THEN
--
          set_warn_status(ir_status_rec,
                           xxcmn_common_pkg.get_msg(gv_msg_kbn,     gv_msg_80c_020,
                                                    gv_tkn_ng_user, ir_masters_rec.employee_num,
                                                    gv_tkn_table,   gv_per_all_people_f_name),
                           lv_errbuf,
                           lv_retcode,
                           lv_errmsg);
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_api_expt;
          END IF;
        END IF;
--
        -- ユーザ存在チェック
        get_fnd_user(ir_masters_rec,
                     lv_errbuf,
                     lv_retcode,
                     lv_errmsg);
--
        -- ユーザ取得エラー
        IF (lv_retcode <> gv_status_normal) THEN
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,     gv_msg_80c_020,
                                                gv_tkn_ng_user, ir_masters_rec.employee_num,
                                                gv_tkn_table,   gv_fnd_user_name);
          RAISE global_api_expt;
        END IF;
--
        -- ユーザーが存在しないかつ以前に登録データが存在しない場合はエラー
        IF ((ir_masters_rec.user_id IS NULL) AND (ir_masters_rec.row_ins_cnt = 0)) THEN
--
          set_warn_status(ir_status_rec,
                           xxcmn_common_pkg.get_msg(gv_msg_kbn,     gv_msg_80c_020,
                                                    gv_tkn_ng_user, ir_masters_rec.employee_num,
                                                    gv_tkn_table,   gv_fnd_user_name),
                           lv_errbuf,
                           lv_retcode,
                           lv_errmsg);
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_api_expt;
          END IF;
        END IF;
--
        -- 従業員割当マスタ存在チェック
        get_per_ass_all_f(ir_masters_rec,
                          lb_retcd,
                          lv_errbuf,
                          lv_retcode,
                          lv_errmsg);
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
        END IF;
--
        -- 存在しない かつ 以前に登録データが存在しない
        IF ((NOT lb_retcd) AND (ir_masters_rec.row_ins_cnt = 0)) THEN
          set_warn_status(ir_status_rec,
                           xxcmn_common_pkg.get_msg(gv_msg_kbn,     gv_msg_80c_020,
                                                    gv_tkn_ng_user, ir_masters_rec.employee_num,
                                                    gv_tkn_table, gv_per_all_assignments_f_name),
                           lv_errbuf,
                           lv_retcode,
                           lv_errmsg);
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_api_expt;
          END IF;
        END IF;
--
        -- 購買担当マスタ存在チェック
        IF (ir_masters_rec.po_flag = gv_flg_on) THEN
          get_po_agents(ir_masters_rec,
                        lb_retcd,
                        lv_errbuf,
                        lv_retcode,
                        lv_errmsg);
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_api_expt;
          END IF;
--
          -- 存在しない かつ 以前に登録データが存在しない
          IF ((NOT lb_retcd) AND (ir_masters_rec.row_ins_cnt = 0)) THEN
            set_warn_status(ir_status_rec,
                             xxcmn_common_pkg.get_msg(gv_msg_kbn,     gv_msg_80c_020,
                                                      gv_tkn_ng_user, ir_masters_rec.employee_num,
                                                      gv_tkn_table,   gv_po_agents_name),
                             lv_errbuf,
                             lv_retcode,
                             lv_errmsg);
--
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_api_expt;
            END IF;
          END IF;
        END IF;
--
        -- 出荷ロールマスタ存在チェック
        IF (ir_masters_rec.wsh_flag = gv_flg_on) THEN
          get_wsh_grants(ir_masters_rec,
                         lb_retcd,
                         lv_errbuf,
                         lv_retcode,
                         lv_errmsg);
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_api_expt;
          END IF;
--
          -- 存在しない かつ 以前に登録データが存在しない
          IF ((NOT lb_retcd) AND (ir_masters_rec.row_ins_cnt = 0)) THEN
            set_warn_status(ir_status_rec,
                            xxcmn_common_pkg.get_msg(gv_msg_kbn,     gv_msg_80c_020,
                                                     gv_tkn_ng_user, ir_masters_rec.employee_num,
                                                     gv_tkn_table,   gv_wsh_grants_name),
                            lv_errbuf,
                            lv_retcode,
                            lv_errmsg);
--
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_api_expt;
            END IF;
          END IF;
        END IF;
--
        -- 職責マスタ存在チェック
        exists_fnd_respons(ir_masters_rec,
                           lb_retcd,
                           lv_errbuf,
                           lv_retcode,
                           lv_errmsg);
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
        END IF;
--
        -- 存在しない かつ 以前に登録データが存在しない
        IF ((NOT lb_retcd) AND (ir_masters_rec.row_ins_cnt = 0)) THEN
          set_warn_status(ir_status_rec,
                          xxcmn_common_pkg.get_msg(gv_msg_kbn,     gv_msg_80c_020,
                                                   gv_tkn_ng_user, ir_masters_rec.employee_num,
                                                   gv_tkn_table,   gv_fnd_user_resp_name),
                          lv_errbuf,
                          lv_retcode,
                          lv_errmsg);
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_api_expt;
          END IF;
        END IF;
--
        -- ユーザー職責マスタ存在チェック
        exists_fnd_user_resp(ir_masters_rec,
                             lb_retcd,
                             lv_errbuf,
                             lv_retcode,
                             lv_errmsg);
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
        END IF;
--
        -- 存在しない かつ 以前に登録データが存在しない
        IF ((NOT lb_retcd) AND (ir_masters_rec.row_ins_cnt = 0)) THEN
          set_warn_status(ir_status_rec,
                          xxcmn_common_pkg.get_msg(gv_msg_kbn,    gv_msg_80c_020,
                                                   gv_tkn_ng_user,ir_masters_rec.employee_num,
                                                   gv_tkn_table,  gv_fnd_user_resp_group_a_name),
                          lv_errbuf,
                          lv_retcode,
                          lv_errmsg);
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_api_expt;
          END IF;
        END IF;
      END IF;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END check_delete;
--
  /***********************************************************************************
   * Procedure Name   : check_proc_code
   * Description      : 操作対象のデータであることを確認します。
   ***********************************************************************************/
  PROCEDURE check_proc_code(
    ir_status_rec  IN OUT NOCOPY status_rec,  -- 処理状況
    ir_masters_rec IN            masters_rec, -- チェック対象データ
    ov_errbuf      OUT    NOCOPY VARCHAR2,    -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT    NOCOPY VARCHAR2,    -- リターン・コード             --# 固定 #
    ov_errmsg      OUT    NOCOPY VARCHAR2)    -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_proc_code'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
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
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --処理区分が(登録・更新・削除)以外
    IF ((ir_masters_rec.proc_code <> gn_proc_insert) 
    AND (ir_masters_rec.proc_code <> gn_proc_update)
    AND (ir_masters_rec.proc_code <> gn_proc_delete)) THEN
      set_error_status(ir_status_rec,
                       xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_80c_016,
                                                'VALUE',    TO_CHAR(ir_masters_rec.proc_code)),
                       lv_errbuf,
                       lv_retcode,
                       lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
    END IF;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END check_proc_code;
--
  /***********************************************************************************
   * Procedure Name   : get_location_new
   * Description      : 新規登録時に担当拠点を取得し存在チェックを行います。(C-3)
   ***********************************************************************************/
  PROCEDURE get_location_new(
    ir_status_rec  IN OUT NOCOPY status_rec,   -- 処理状況
    ir_masters_rec IN OUT NOCOPY masters_rec,  -- チェック対象データ
    ov_errbuf      OUT    NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT    NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg      OUT    NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_location_new'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_hla_cur_cnt  NUMBER;
--
    -- *** ローカル・カーソル ***
--
    CURSOR hla_cur
    IS
      SELECT hla.location_id,                        -- ロケーションID
             hla.attribute3,                         -- 購買担当フラグ
             hla.attribute4,                         -- 出荷担当フラグ
             hla.attribute5,                         -- 担当職責１
             hla.attribute6,                         -- 担当職責２
             hla.attribute7,                         -- 担当職責３
             hla.attribute8,                         -- 担当職責４
             hla.attribute9,                         -- 担当職責５
             hla.attribute10,                        -- 担当職責６
             hla.attribute11,                        -- 担当職責７
             hla.attribute12,                        -- 担当職責８
             hla.attribute13,                        -- 担当職責９
             hla.attribute14                         -- 担当職責１０
      FROM   hr_locations_all hla                    -- 事業所マスタ
      WHERE  hla.location_code = ir_masters_rec.base_code;
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    ln_hla_cur_cnt := 0;
    OPEN hla_cur;
--
    <<hla_cur_loop>>
    LOOP
      FETCH hla_cur
      INTO  ir_masters_rec.location_id,
            ir_masters_rec.po_flag,
            ir_masters_rec.wsh_flag,
            ir_masters_rec.resp1,
            ir_masters_rec.resp2,
            ir_masters_rec.resp3,
            ir_masters_rec.resp4,
            ir_masters_rec.resp5,
            ir_masters_rec.resp6,
            ir_masters_rec.resp7,
            ir_masters_rec.resp8,
            ir_masters_rec.resp9,
            ir_masters_rec.resp10;
      EXIT WHEN hla_cur%NOTFOUND;
--
      ln_hla_cur_cnt := ln_hla_cur_cnt + 1;
    END LOOP hla_cur_loop;
    CLOSE hla_cur;
--
    -- 1件以外
    IF (ln_hla_cur_cnt <> 1) THEN
      set_error_status(ir_status_rec,
                       xxcmn_common_pkg.get_msg(gv_msg_kbn,        gv_msg_80c_015,
                                                gv_tkn_ng_tkyoten, ir_masters_rec.base_code),
                       lv_errbuf,
                       lv_retcode,
                       lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
    END IF;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
      -- カーソルが開いていれば
      IF (hla_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE hla_cur;
      END IF;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      -- カーソルが開いていれば
      IF (hla_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE hla_cur;
      END IF;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      -- カーソルが開いていれば
      IF (hla_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE hla_cur;
      END IF;
--
--#####################################  固定部 END   #############################################
--
  END get_location_new;
--
  /***********************************************************************************
   * Procedure Name   : get_location_mod
   * Description      : 変更・削除時に担当拠点を取得し存在チェックを行います。(C-3)
   ***********************************************************************************/
  PROCEDURE get_location_mod(
    ir_status_rec  IN OUT NOCOPY status_rec,   -- 処理状況
    ir_masters_rec IN OUT NOCOPY masters_rec,  -- チェック対象データ
    ov_errbuf      OUT    NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT    NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg      OUT    NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_location_mod'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_hla_cur_cnt  NUMBER;
--
    -- *** ローカル・カーソル ***
--
    CURSOR hla_cur
    IS
      SELECT hla.location_id,                        -- ロケーションID
             hla.attribute3,                         -- 購買担当フラグ
             hla.attribute4,                         -- 出荷担当フラグ
             hla.attribute5,                         -- 担当職責１
             hla.attribute6,                         -- 担当職責２
             hla.attribute7,                         -- 担当職責３
             hla.attribute8,                         -- 担当職責４
             hla.attribute9,                         -- 担当職責５
             hla.attribute10,                        -- 担当職責６
             hla.attribute11,                        -- 担当職責７
             hla.attribute12,                        -- 担当職責８
             hla.attribute13,                        -- 担当職責９
             hla.attribute14                         -- 担当職責１０
-- 2008/10/06 v1.4 UPDATE START
/*
      FROM   per_all_people_f ppf,                   -- 従業員マスタ
             per_all_assignments_f paf,              -- 従業員割当マスタ
             hr_locations_all hla                    -- 事業所マスタ
      WHERE  hla.location_code   = ir_masters_rec.base_code
      AND    ppf.employee_number = ir_masters_rec.employee_num
      AND    ppf.person_id       = paf.person_id
      AND    hla.location_id     = paf.location_id
      AND    paf.effective_start_date <= SYSDATE
      AND    paf.effective_end_date >= SYSDATE;
*/
      FROM   hr_locations_all hla                    -- 事業所マスタ
      WHERE  hla.location_code   = ir_masters_rec.base_code;
-- 2008/10/06 v1.4 UPDATE END
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    ln_hla_cur_cnt := 0;
    OPEN hla_cur;
--
    <<hla_cur_loop>>
    LOOP
      FETCH hla_cur
      INTO  ir_masters_rec.location_id,
            ir_masters_rec.po_flag,
            ir_masters_rec.wsh_flag,
            ir_masters_rec.resp1,
            ir_masters_rec.resp2,
            ir_masters_rec.resp3,
            ir_masters_rec.resp4,
            ir_masters_rec.resp5,
            ir_masters_rec.resp6,
            ir_masters_rec.resp7,
            ir_masters_rec.resp8,
            ir_masters_rec.resp9,
            ir_masters_rec.resp10;
      EXIT WHEN hla_cur%NOTFOUND;
--
      ln_hla_cur_cnt := ln_hla_cur_cnt + 1;
    END LOOP hla_cur_loop;
    CLOSE hla_cur;
--
    -- 1件以外
    IF (ln_hla_cur_cnt <> 1) THEN
      -- 削除の場合
      IF (ir_masters_rec.proc_code = gn_proc_delete) THEN
        set_warn_status(ir_status_rec,
                         xxcmn_common_pkg.get_msg(gv_msg_kbn,        gv_msg_80c_015,
                                                  gv_tkn_ng_tkyoten, ir_masters_rec.base_code),
                         lv_errbuf,
                         lv_retcode,
                         lv_errmsg);
--
      -- 削除以外の場合
      ELSE
        set_error_status(ir_status_rec,
                         xxcmn_common_pkg.get_msg(gv_msg_kbn,        gv_msg_80c_015,
                                                  gv_tkn_ng_tkyoten, ir_masters_rec.base_code),
                         lv_errbuf,
                         lv_retcode,
                         lv_errmsg);
      END IF;
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
    END IF;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
      -- カーソルが開いていれば
      IF (hla_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE hla_cur;
      END IF;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      -- カーソルが開いていれば
      IF (hla_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE hla_cur;
      END IF;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      -- カーソルが開いていれば
      IF (hla_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE hla_cur;
      END IF;
--
--#####################################  固定部 END   #############################################
--
  END get_location_mod;
--
  /***********************************************************************************
   * Procedure Name   : get_service_id
   * Description      : サービス期間IDの取得を行います。
   ***********************************************************************************/
  PROCEDURE get_service_id(
    or_masters_tbl  IN OUT NOCOPY masters_rec,
    ov_service_id   OUT    NOCOPY NUMBER,
    ov_ver_num      OUT    NOCOPY NUMBER,
    ob_retcd        OUT    NOCOPY BOOLEAN,     -- 検索結果
    ov_errbuf       OUT    NOCOPY VARCHAR2,    -- エラー・メッセージ           --# 固定 #
    ov_retcode      OUT    NOCOPY VARCHAR2,    -- リターン・コード             --# 固定 #
    ov_errmsg       OUT    NOCOPY VARCHAR2)    -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_service_id'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
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
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    BEGIN
--
      ob_retcd      := TRUE;
      ov_service_id := NULL;
      ov_ver_num    := NULL;
--
      SELECT ppos.period_of_service_id
            ,ppos.object_version_number
      INTO   ov_service_id
            ,ov_ver_num
      FROM   per_periods_of_service ppos
            ,per_all_people_f papf                       -- 従業員マスタ
      WHERE  ppos.person_id       = papf.person_id
      AND    papf.employee_number = or_masters_tbl.employee_num
      AND    ROWNUM = 1;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ob_retcd := FALSE;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END get_service_id;
--
  /***********************************************************************************
   * Procedure Name   : wsh_grants_proc
   * Description      : 出荷ロールマスタの登録・削除処理を行います。
   ***********************************************************************************/
  PROCEDURE wsh_grants_proc(
    in_proc_kbn    IN            NUMBER,      -- 処理区分
    or_masters_rec IN OUT NOCOPY masters_rec, -- チェック対象データ
    ov_errbuf      OUT    NOCOPY VARCHAR2,    -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT    NOCOPY VARCHAR2,    -- リターン・コード             --# 固定 #
    ov_errmsg      OUT    NOCOPY VARCHAR2)    -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'wsh_grants_proc'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_grant_id  wsh_grants.grant_id%TYPE;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 登録
    IF (in_proc_kbn = gn_proc_insert) THEN
      -- 登録処理
      INSERT INTO wsh_grants
      (GRANT_ID,
       USER_ID,
       ROLE_ID,
       ORGANIZATION_ID,
       START_DATE,
       END_DATE,
       CREATED_BY,
       CREATION_DATE,
       LAST_UPDATED_BY,
       LAST_UPDATE_DATE,
       LAST_UPDATE_LOGIN
      )
      VALUES (
       wsh_grants_s.NEXTVAL,                      --GRANT_ID
       or_masters_rec.user_id,                    --USER_ID
       TO_NUMBER(gv_role_id),                     --ROLE_ID
       NULL,                                      --ORGANIZATION_ID
       SYSDATE,                                   --START_DATE
       NULL,                                      --END_DATE
       gn_created_by,
       gd_creation_date,
       gn_last_update_by,
       gd_last_update_date,
       gn_last_update_login
      );
--
    -- 削除
    ELSIF (in_proc_kbn = gn_proc_delete) THEN
      -- 削除処理
      DELETE wsh_grants
      WHERE  user_id = or_masters_rec.user_id;
    END IF;
--
  EXCEPTION
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END wsh_grants_proc;
--
  /***********************************************************************************
   * Procedure Name   : po_agents_proc
   * Description      : 購買担当マスタの登録・削除処理を行います。
   ***********************************************************************************/
  PROCEDURE po_agents_proc(
    in_proc_kbn    IN            NUMBER,      -- 処理区分
    or_masters_rec IN OUT NOCOPY masters_rec, -- チェック対象データ
    ov_errbuf      OUT    NOCOPY VARCHAR2,    -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT    NOCOPY VARCHAR2,    -- リターン・コード             --# 固定 #
    ov_errmsg      OUT    NOCOPY VARCHAR2)    -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'po_agents_proc'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_rowid                      ROWID;
    lv_api_name                   VARCHAR2(200);
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 登録
    IF (in_proc_kbn = gn_proc_insert) THEN
      BEGIN
        PO_AGENTS_PKG.INSERT_ROW(
          X_ROWID               => lv_rowid
         ,X_AGENT_ID            => or_masters_rec.person_id          -- 従業員ID
         ,X_LAST_UPDATE_DATE    => gd_last_update_date
         ,X_LAST_UPDATED_BY     => gn_last_update_by
         ,X_LAST_UPDATE_LOGIN   => gn_last_update_login
         ,X_CREATION_DATE       => gd_creation_date
         ,X_CREATED_BY          => gn_last_update_by
         ,X_LOCATION_ID         => NULL
         ,X_CATEGORY_ID         => NULL
         ,X_AUTHORIZATION_LIMIT => NULL
         ,X_START_DATE_ACTIVE   => NULL
         ,X_END_DATE_ACTIVE     => NULL
         ,X_ATTRIBUTE_CATEGORY  => NULL
         ,X_ATTRIBUTE1          => NULL
         ,X_ATTRIBUTE2          => NULL
         ,X_ATTRIBUTE3          => NULL
         ,X_ATTRIBUTE4          => NULL
         ,X_ATTRIBUTE5          => NULL
         ,X_ATTRIBUTE6          => NULL
         ,X_ATTRIBUTE7          => NULL
         ,X_ATTRIBUTE8          => NULL
         ,X_ATTRIBUTE9          => NULL
         ,X_ATTRIBUTE10         => NULL
         ,X_ATTRIBUTE11         => NULL
         ,X_ATTRIBUTE12         => NULL
         ,X_ATTRIBUTE13         => NULL
         ,X_ATTRIBUTE14         => NULL
         ,X_ATTRIBUTE15         => NULL
        );
--
      EXCEPTION
        WHEN OTHERS THEN
          lv_api_name := 'PO_AGENTS_PKG.INSERT_ROW';
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,      gv_msg_80c_013,
                                                gv_tkn_api_name, lv_api_name);
          lv_errbuf := lv_errmsg;
          RAISE global_api_others_expt;
      END;
--
    -- 削除
    ELSE
      DELETE po_agents
      WHERE  agent_id = or_masters_rec.person_id;
    END IF;
--
  EXCEPTION
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END po_agents_proc;
--
  /***********************************************************************************
   * Procedure Name   : set_assignment
   * Description      : ユーザ職責マスタの登録処理を行います。
   ***********************************************************************************/
  PROCEDURE set_assignment(
    in_user_name  IN         VARCHAR2,     -- ユーザー名称
    in_date       IN         DATE,         -- 対象日付
    in_resp       IN         VARCHAR2,     -- 対象職責
    ov_errbuf     OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_assignment'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_api_name   VARCHAR2(200);
    lb_retcd      BOOLEAN;
    lv_resp_key   fnd_responsibility.responsibility_key%TYPE;
    lv_app_name   fnd_application.application_short_name%TYPE;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 担当職責からX_RESP_KEY,X_APP_SHORT_NAMEを取得する
    get_application(in_resp,
                    lv_resp_key,
                    lv_app_name,
                    lb_retcd,
                    lv_errbuf,
                    lv_retcode,
                    lv_errmsg);
--
    IF (lv_retcode <> gv_status_normal) THEN
      RAISE global_api_expt;
    END IF;
--
    BEGIN
--
        -- ユーザ職責マスタ
        FND_USER_RESP_GROUPS_API.LOAD_ROW(
          X_USER_NAME         => in_user_name
         ,X_RESP_KEY          => lv_resp_key
         ,X_APP_SHORT_NAME    => lv_app_name
         ,X_SECURITY_GROUP    => 'STANDARD'
         ,X_OWNER             => gn_created_by
         ,X_START_DATE        => TO_CHAR(in_date,'YYYY/MM/DD')
         ,X_END_DATE          => NULL
         ,X_DESCRIPTION       => NULL
         ,X_LAST_UPDATE_DATE  => SYSDATE
        );
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_api_name := 'FND_USER_RESP_GROUPS_API.LOAD_ROW';
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,      gv_msg_80c_013,
                                              gv_tkn_api_name, lv_api_name);
        lv_errbuf := lv_errmsg;
        RAISE global_api_others_expt;
    END;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END set_assignment;
--
  /***********************************************************************************
   * Procedure Name   : update_resp_all_f
   * Description      : ユーザ職責マスタの更新処理を行います。
   ***********************************************************************************/
  PROCEDURE update_resp_all_f(
    in_user_id     IN          NUMBER,       -- ユーザID
    in_user_name   IN          VARCHAR2,     -- ユーザ名称
    in_respons_id  IN          VARCHAR2,     -- 職責ID
    ov_errbuf      OUT  NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT  NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg      OUT  NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_resp_all_f'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_retcd                 NUMBER;
    lb_retst                 BOOLEAN;
    ln_responsibility_id     fnd_user_resp_groups_all.responsibility_id%TYPE;
    ln_responsibility_app_id fnd_user_resp_groups_all.responsibility_application_id%TYPE;
    ln_security_group_id     fnd_user_resp_groups_all.security_group_id%TYPE;
    ld_start_date            fnd_user_resp_groups_all.start_date%TYPE;
    ld_start_date_u          fnd_user_resp_groups_all.start_date%TYPE;
--
    lv_api_name              VARCHAR2(200);
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    IF (in_respons_id IS NOT NULL) THEN
      ln_responsibility_id := TO_NUMBER(in_respons_id);
      -- ユーザ職責マスタ取得
      get_fnd_user_resp_all(in_user_id,
                            ln_responsibility_id,
                            ln_responsibility_app_id,
                            ln_security_group_id,
                            ld_start_date,
                            lb_retst,
                            lv_errbuf,
                            lv_retcode,
                            lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      -- データあり
      IF (lb_retst = TRUE) THEN
        BEGIN
          FND_USER_RESP_GROUPS_API.UPDATE_ASSIGNMENT(
            USER_ID                       => in_user_id
           ,RESPONSIBILITY_ID             => ln_responsibility_id
           ,RESPONSIBILITY_APPLICATION_ID => ln_responsibility_app_id
           ,SECURITY_GROUP_ID             => ln_security_group_id
           ,START_DATE                    => ld_start_date
           ,END_DATE                      => NULL
           ,DESCRIPTION                   => 'Y'
          );
--
        EXCEPTION
          WHEN OTHERS THEN
            lv_api_name := 'FND_USER_RESP_GROUPS_API.UPDATE_ASSIGNMENT';
            lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,      gv_msg_80c_013,
                                                  gv_tkn_api_name, lv_api_name);
            lv_errbuf := lv_errmsg;
            RAISE global_api_others_expt;
        END;
--
      -- データなし
      ELSE
        ld_start_date_u := FND_DATE.STRING_TO_DATE(gv_min_date,'YYYY/MM/DD');
        -- ユーザ職責マスタ登録
        set_assignment(in_user_name,
                       ld_start_date_u,
                       in_respons_id,
                       lv_errbuf,
                       lv_retcode,
                       lv_errmsg);
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
        END IF;
      END IF;
    END IF;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END update_resp_all_f;
--
  /***********************************************************************************
   * Procedure Name   : delete_group_all
   * Description      : ユーザー職責マスタのデータの無効化を行います。
   ***********************************************************************************/
  PROCEDURE delete_group_all(
    ir_masters_rec IN OUT NOCOPY masters_rec,  -- チェック対象データ
    ov_errbuf      OUT    NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT    NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg      OUT    NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_group_all'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_user_id                    fnd_user_resp_groups_all.user_id%TYPE;
    ln_responsibility_id          fnd_user_resp_groups_all.responsibility_id%TYPE;
    ln_responsibility_app_id      fnd_user_resp_groups_all.responsibility_application_id%TYPE;
    ln_security_group_id          fnd_user_resp_groups_all.security_group_id%TYPE;
    ld_start_date                 fnd_user_resp_groups_all.start_date%TYPE;
--
    lv_api_name                   VARCHAR2(200);
--
    -- *** ローカル・カーソル ***
    CURSOR fug_cur
    IS
      SELECT fug.user_id,
             fug.responsibility_id,
             fug.responsibility_application_id,
             fug.security_group_id,
             fug.start_date
      FROM   fnd_user_resp_groups_all fug                      -- ユーザー職責マスタ
      WHERE  fug.user_id = ir_masters_rec.user_id;
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    BEGIN
--
      OPEN fug_cur;
--
      <<fug_cur_loop>>
      LOOP
        FETCH fug_cur
        INTO  ln_user_id,
              ln_responsibility_id,
              ln_responsibility_app_id,
              ln_security_group_id,
              ld_start_date;
        EXIT WHEN fug_cur%NOTFOUND;
--
        -- API起動
        FND_USER_RESP_GROUPS_API.UPDATE_ASSIGNMENT(
            USER_ID                       => ln_user_id
           ,RESPONSIBILITY_ID             => ln_responsibility_id
           ,RESPONSIBILITY_APPLICATION_ID => ln_responsibility_app_id
           ,SECURITY_GROUP_ID             => ln_security_group_id
           ,START_DATE                    => ld_start_date
           ,END_DATE                      => SYSDATE-1
           ,DESCRIPTION                   => 'Y'
        );
--
      END LOOP fug_cur_loop;
      CLOSE fug_cur;
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_api_name := 'FND_USER_RESP_GROUPS_API.UPDATE_ASSIGNMENT';
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,      gv_msg_80c_013,
                                              gv_tkn_api_name, lv_api_name);
        lv_errbuf := lv_errmsg;
        IF (fug_cur%ISOPEN) THEN
          -- カーソルのクローズ
          CLOSE fug_cur;
        END IF;
        RAISE delete_group_all_expt;
    END;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN delete_group_all_expt THEN
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# 任意 #
      IF (fug_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE fug_cur;
      END IF;
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
      IF (fug_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE fug_cur;
      END IF;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      IF (fug_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE fug_cur;
      END IF;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      IF (fug_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE fug_cur;
      END IF;
--
--#####################################  固定部 END   #############################################
--
  END delete_group_all;
--
  /***********************************************************************************
   * Procedure Name   : insert_proc
   * Description      : ユーザー登録情報格納処理を行います。(C-10)
   ***********************************************************************************/
  PROCEDURE insert_proc(
    ot_report_tbl  IN OUT NOCOPY report_rec,
    or_masters_tbl IN OUT NOCOPY masters_rec,
    ov_errbuf      OUT    NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT    NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg      OUT    NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_proc'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_retcd                      NUMBER;
    ld_start_date                 DATE;
--
    -- HR_EMPLOYEE_API.CREATE_EMPLOYEE
    ln_person_id                  NUMBER;
    ln_assignment_id              NUMBER;
    ln_per_object_version_number  NUMBER;
    ln_asg_object_version_number  NUMBER;
    ld_per_effective_start_date   DATE;
    ld_per_effective_end_date     DATE;
    lv_full_name                  per_all_people_f.full_name%type;
    ln_per_comment_id             NUMBER;
    ln_assignment_sequence        NUMBER;
    lv_assignment_number          per_all_assignments_f.assignment_number%type;
    lb_name_combination_warning   BOOLEAN;
    lb_assign_payroll_warning     BOOLEAN;
    lb_orig_hire_warning          BOOLEAN;
--
    -- HR_ASSIGNMENT_API.UPDATE_EMP_ASG_CRITERIA
    ln_people_group_id            NUMBER;
    ln_special_ceiling_step_id    NUMBER;
    lv_group_name                 VARCHAR2(200);
    lb_org_now_no_manager_warning BOOLEAN;
    lb_other_manager_warning      BOOLEAN;
    lb_spp_delete_warning         BOOLEAN;
    lv_entries_changes_warn       VARCHAR2(200);
    lb_tax_district_changed_warn  BOOLEAN;
--
    -- FND_USER_PKG.CREATEUSERID
    ln_user_id                    fnd_user_resp_groups_all.user_id%TYPE;
--
    lv_api_name                   VARCHAR2(200);
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 従業員マスタ(API)
    BEGIN
--
      HR_EMPLOYEE_API.CREATE_EMPLOYEE(
        P_VALIDATE                     => FALSE
       ,P_HIRE_DATE                    => SYSDATE
       ,P_BUSINESS_GROUP_ID            => gv_bisiness_grp_id
       ,P_LAST_NAME                    => or_masters_tbl.user_name_alt
       ,P_SEX                          => gv_def_sex
       ,P_PERSON_TYPE_ID               => gv_person_type
       ,P_EMPLOYEE_NUMBER              => or_masters_tbl.employee_num
       ,P_ATTRIBUTE1                   => or_masters_tbl.qualification_id
       ,P_ATTRIBUTE2                   => or_masters_tbl.position_id
       ,P_PER_INFORMATION_CATEGORY     => gv_info_category
       ,P_PER_INFORMATION18            => or_masters_tbl.user_name
       ,P_PERSON_ID                    => ln_person_id                       -- OUT
       ,P_ASSIGNMENT_ID                => ln_assignment_id                   -- OUT
       ,P_PER_OBJECT_VERSION_NUMBER    => ln_per_object_version_number       -- OUT
       ,P_ASG_OBJECT_VERSION_NUMBER    => ln_asg_object_version_number       -- OUT
       ,P_PER_EFFECTIVE_START_DATE     => ld_per_effective_start_date        -- OUT
       ,P_PER_EFFECTIVE_END_DATE       => ld_per_effective_end_date          -- OUT
       ,P_FULL_NAME                    => lv_full_name                       -- OUT
       ,P_PER_COMMENT_ID               => ln_per_comment_id                  -- OUT
       ,P_ASSIGNMENT_SEQUENCE          => ln_assignment_sequence             -- OUT
       ,P_ASSIGNMENT_NUMBER            => lv_assignment_number               -- OUT
       ,P_NAME_COMBINATION_WARNING     => lb_name_combination_warning        -- OUT
       ,P_ASSIGN_PAYROLL_WARNING       => lb_assign_payroll_warning          -- OUT
       ,P_ORIG_HIRE_WARNING            => lb_orig_hire_warning               -- OUT
      );
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_api_name := 'HR_EMPLOYEE_API.CREATE_EMPLOYEE';
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,      gv_msg_80c_013,
                                              gv_tkn_api_name, lv_api_name);
        lv_errbuf := lv_errmsg;
        RAISE global_api_others_expt;
    END;
--
    ot_report_tbl.papf_flg := 1;
--
    -- 従業員割当マスタ(API)
    BEGIN
       HR_ASSIGNMENT_API.UPDATE_EMP_ASG_CRITERIA(
           P_VALIDATE                      => FALSE
          ,P_EFFECTIVE_DATE                => SYSDATE
          ,P_DATETRACK_UPDATE_MODE         => gv_upd_mode
          ,P_ASSIGNMENT_ID                 => ln_assignment_id
          ,P_LOCATION_ID                   => or_masters_tbl.location_id
          ,P_PEOPLE_GROUP_ID               => ln_people_group_id             -- OUT
          ,P_OBJECT_VERSION_NUMBER         => ln_asg_object_version_number   -- OUT
          ,P_SPECIAL_CEILING_STEP_ID       => ln_special_ceiling_step_id     -- OUT
          ,P_GROUP_NAME                    => lv_group_name                  -- OUT
          ,P_EFFECTIVE_START_DATE          => ld_per_effective_start_date    -- OUT
          ,P_EFFECTIVE_END_DATE            => ld_per_effective_end_date      -- OUT
          ,P_ORG_NOW_NO_MANAGER_WARNING    => lb_org_now_no_manager_warning  -- OUT
          ,P_OTHER_MANAGER_WARNING         => lb_other_manager_warning       -- OUT
          ,P_SPP_DELETE_WARNING            => lb_spp_delete_warning          -- OUT
          ,P_ENTRIES_CHANGED_WARNING       => lv_entries_changes_warn        -- OUT
          ,P_TAX_DISTRICT_CHANGED_WARNING  => lb_tax_district_changed_warn   -- OUT
         );
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_api_name := 'HR_ASSIGNMENT_API.UPDATE_EMP_ASG_CRITERIA';
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,      gv_msg_80c_013,
                                              gv_tkn_api_name, lv_api_name);
        lv_errbuf := lv_errmsg;
        RAISE global_api_others_expt;
    END;
--
    ot_report_tbl.paaf_flg := 1;
--
    -- ユーザマスタ(API)
    BEGIN
--
      ln_user_id := FND_USER_PKG.CREATEUSERID(
                      X_USER_NAME            => or_masters_tbl.employee_num
                     ,X_OWNER                => gv_owner
                     ,X_UNENCRYPTED_PASSWORD => gv_password
                     ,X_START_DATE           => SYSDATE
                     ,X_LAST_LOGON_DATE      => SYSDATE
                     ,X_DESCRIPTION          => or_masters_tbl.user_name_alt
-- 2008/11/20 ADD START
-- 失効日
                     ,X_PASSWORD_LIFESPAN_DAYS => 180
-- 2008/11/20 ADD END
                     ,X_EMPLOYEE_ID          => ln_person_id
                    );
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_api_name := 'FND_USER_PKG.CREATEUSERID';
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,      gv_msg_80c_013,
                                              gv_tkn_api_name, lv_api_name);
        lv_errbuf := lv_errmsg;
        RAISE global_api_others_expt;
    END;
--
    ot_report_tbl.fusr_flg   := 1;
    or_masters_tbl.user_id   := ln_user_id;
    or_masters_tbl.person_id := ln_person_id;
    or_masters_tbl.object_version_number     := ln_per_object_version_number;
    or_masters_tbl.ass_object_version_number := ln_asg_object_version_number;
--
    ld_start_date := FND_DATE.STRING_TO_DATE(gv_min_date,'YYYY/MM/DD');
--
    -- ユーザ職責マスタ(API)
    -- 担当職責１
    IF (or_masters_tbl.resp1 IS NOT NULL) THEN
      set_assignment(or_masters_tbl.employee_num,
                     ld_start_date,
                     or_masters_tbl.resp1,
                     lv_errbuf,
                     lv_retcode,
                     lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      ot_report_tbl.furg_flg := 1;
    END IF;
    -- 担当職責２
    IF (or_masters_tbl.resp2 IS NOT NULL) THEN
      set_assignment(or_masters_tbl.employee_num,
                     ld_start_date,
                     or_masters_tbl.resp2,
                     lv_errbuf,
                     lv_retcode,
                     lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      ot_report_tbl.furg_flg := 1;
    END IF;
    -- 担当職責３
    IF (or_masters_tbl.resp3 IS NOT NULL) THEN
      set_assignment(or_masters_tbl.employee_num,
                     ld_start_date,
                     or_masters_tbl.resp3,
                     lv_errbuf,
                     lv_retcode,
                     lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      ot_report_tbl.furg_flg := 1;
    END IF;
    -- 担当職責４
    IF (or_masters_tbl.resp4 IS NOT NULL) THEN
      set_assignment(or_masters_tbl.employee_num,
                     ld_start_date,
                     or_masters_tbl.resp4,
                     lv_errbuf,
                     lv_retcode,
                     lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      ot_report_tbl.furg_flg := 1;
    END IF;
    -- 担当職責５
    IF (or_masters_tbl.resp5 IS NOT NULL) THEN
      set_assignment(or_masters_tbl.employee_num,
                     ld_start_date,
                     or_masters_tbl.resp5,
                     lv_errbuf,
                     lv_retcode,
                     lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      ot_report_tbl.furg_flg := 1;
    END IF;
    -- 担当職責６
    IF (or_masters_tbl.resp6 IS NOT NULL) THEN
      set_assignment(or_masters_tbl.employee_num,
                     ld_start_date,
                     or_masters_tbl.resp6,
                     lv_errbuf,
                     lv_retcode,
                     lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      ot_report_tbl.furg_flg := 1;
    END IF;
    -- 担当職責７
    IF (or_masters_tbl.resp7 IS NOT NULL) THEN
      set_assignment(or_masters_tbl.employee_num,
                     ld_start_date,
                     or_masters_tbl.resp7,
                     lv_errbuf,
                     lv_retcode,
                     lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      ot_report_tbl.furg_flg := 1;
    END IF;
    -- 担当職責８
    IF (or_masters_tbl.resp8 IS NOT NULL) THEN
      set_assignment(or_masters_tbl.employee_num,
                     ld_start_date,
                     or_masters_tbl.resp8,
                     lv_errbuf,
                     lv_retcode,
                     lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      ot_report_tbl.furg_flg := 1;
    END IF;
    -- 担当職責９
    IF (or_masters_tbl.resp9 IS NOT NULL) THEN
      set_assignment(or_masters_tbl.employee_num,
                     ld_start_date,
                     or_masters_tbl.resp9,
                     lv_errbuf,
                     lv_retcode,
                     lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      ot_report_tbl.furg_flg := 1;
    END IF;
    -- 担当職責１０
    IF (or_masters_tbl.resp10 IS NOT NULL) THEN
      set_assignment(or_masters_tbl.employee_num,
                     ld_start_date,
                     or_masters_tbl.resp10,
                     lv_errbuf,
                     lv_retcode,
                     lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      ot_report_tbl.furg_flg := 1;
    END IF;
--
    -- 購買担当マスタ(API)
    IF (or_masters_tbl.po_flag = gv_flg_on) THEN
--
      -- 登録
      po_agents_proc(gn_proc_insert,
                     or_masters_tbl, 
                     lv_errbuf, 
                     lv_retcode, 
                     lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      ot_report_tbl.pagn_flg := 1;
    END IF;
--
    -- 出荷ロールマスタ(直接)
    IF (or_masters_tbl.wsh_flag = gv_flg_on) THEN
      -- 登録
      wsh_grants_proc(gn_proc_insert,
                      or_masters_tbl,
                      lv_errbuf,
                      lv_retcode,
                      lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      ot_report_tbl.wshg_flg := 1;
--
    END IF;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END insert_proc;
--
  /***********************************************************************************
   * Procedure Name   : update_proc
   * Description      : ユーザー更新情報格納処理を行います。(C-10)
   ***********************************************************************************/
  PROCEDURE update_proc(
    ot_report_tbl  IN OUT NOCOPY report_rec,
    or_masters_tbl IN OUT NOCOPY masters_rec,
    ov_errbuf      OUT    NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT    NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg      OUT    NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_proc'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
--
    -- HR_PERSON_API.UPDATE_PERSON
    l_effective_start_date        DATE;
    l_effective_end_date          DATE;
    l_full_name                   per_all_people_f.full_name%TYPE;
    l_comment_id                  NUMBER;
    l_name_combination_warning    BOOLEAN;
    l_assign_payroll_warning      BOOLEAN;
    l_orig_hire_warning           BOOLEAN;
    ln_asg_object_version_number  NUMBER;
--
    -- HR_ASSIGNMENT_API.UPDATE_EMP_ASG_CRITERIA
    ln_assignment_id              NUMBER;
    ln_object_version_number      NUMBER;
    ln_special_ceiling_step_id    NUMBER;
    ln_people_group_id            NUMBER;
    lv_group_name                 VARCHAR2(200);
    ld_effective_start_date       DATE;
    ld_effective_end_date         DATE;
    lb_org_now_no_manager_warning BOOLEAN;
    lb_other_manager_warning      BOOLEAN;
    lb_spp_delete_warning         BOOLEAN;
    lv_entries_changes_warn       VARCHAR2(200);
    lb_tax_district_changed_warn  BOOLEAN;
--
    lv_api_name                   VARCHAR2(200);
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 従業員マスタの検索
    get_per_all_people_f(or_masters_tbl,
                         lv_errbuf,
                         lv_retcode,
                         lv_errmsg);
--
    -- 従業員取得エラー
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ユーザ存在チェック
    get_fnd_user(or_masters_tbl,
                 lv_errbuf,
                 lv_retcode,
                 lv_errmsg);
--
    -- ユーザ取得エラー
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    -- 従業員マスタ(API)
    BEGIN
      HR_PERSON_API.UPDATE_PERSON(
        P_VALIDATE                     => FALSE
       ,P_EFFECTIVE_DATE               => SYSDATE
       ,P_DATETRACK_UPDATE_MODE        => gv_upd_mode
       ,P_PERSON_ID                    => or_masters_tbl.person_id     -- 従業員ID
       ,P_OBJECT_VERSION_NUMBER        => or_masters_tbl.object_version_number
       ,P_PERSON_TYPE_ID               => gv_person_type
       ,P_EMPLOYEE_NUMBER              => or_masters_tbl.employee_num
       ,P_ATTRIBUTE1                   => or_masters_tbl.qualification_id
       ,P_ATTRIBUTE2                   => or_masters_tbl.position_id
       ,P_LAST_NAME                    => or_masters_tbl.user_name_alt
       ,P_PER_INFORMATION_CATEGORY     => gv_info_category
       ,P_PER_INFORMATION18            => or_masters_tbl.user_name
       ,P_EFFECTIVE_START_DATE         => l_effective_start_date       -- OUT
       ,P_EFFECTIVE_END_DATE           => l_effective_end_date         -- OUT
       ,P_FULL_NAME                    => l_full_name                  -- OUT
       ,P_COMMENT_ID                   => l_comment_id                 -- OUT
       ,P_NAME_COMBINATION_WARNING     => l_name_combination_warning   -- OUT
       ,P_ASSIGN_PAYROLL_WARNING       => l_assign_payroll_warning     -- OUT
       ,P_ORIG_HIRE_WARNING            => l_orig_hire_warning          -- OUT
      );
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_api_name := 'HR_PERSON_API.UPDATE_PERSON';
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,      gv_msg_80c_013,
                                              gv_tkn_api_name, lv_api_name);
        lv_errbuf := lv_errmsg;
        RAISE global_api_others_expt;
    END;
--
    ot_report_tbl.papf_flg := 1;
--
    ln_assignment_id := or_masters_tbl.assignment_id;
    ln_object_version_number := or_masters_tbl.ass_object_version_number;
--
    -- 従業員割当マスタ(API)
    BEGIN
      HR_ASSIGNMENT_API.UPDATE_EMP_ASG_CRITERIA(
          P_VALIDATE                      => FALSE
         ,P_EFFECTIVE_DATE                => SYSDATE
         ,P_DATETRACK_UPDATE_MODE         => gv_upd_mode
         ,P_ASSIGNMENT_ID                 => ln_assignment_id               -- 従業員割当ID
         ,P_LOCATION_ID                   => or_masters_tbl.location_id     -- 担当拠点コード
         ,P_OBJECT_VERSION_NUMBER         => ln_object_version_number       -- IN/OUT
         ,P_SPECIAL_CEILING_STEP_ID       => ln_special_ceiling_step_id     -- OUT
         ,P_PEOPLE_GROUP_ID               => ln_people_group_id             -- OUT
         ,P_GROUP_NAME                    => lv_group_name                  -- OUT
         ,P_EFFECTIVE_START_DATE          => l_effective_start_date         -- OUT
         ,P_EFFECTIVE_END_DATE            => l_effective_end_date           -- OUT
         ,P_ORG_NOW_NO_MANAGER_WARNING    => lb_org_now_no_manager_warning  -- OUT
         ,P_OTHER_MANAGER_WARNING         => lb_other_manager_warning       -- OUT
         ,P_SPP_DELETE_WARNING            => lb_spp_delete_warning          -- OUT
         ,P_ENTRIES_CHANGED_WARNING       => lv_entries_changes_warn        -- OUT
         ,P_TAX_DISTRICT_CHANGED_WARNING  => lb_tax_district_changed_warn   -- OUT
        );
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_api_name := 'HR_ASSIGNMENT_API.UPDATE_EMP_ASG_CRITERIA';
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,      gv_msg_80c_013,
                                              gv_tkn_api_name, lv_api_name);
        lv_errbuf := lv_errmsg;
        RAISE global_api_others_expt;
    END;
--
    ot_report_tbl.paaf_flg := 1;
--
    -- ユーザマスタ(API)
    BEGIN
      FND_USER_PKG.UPDATEUSER(
         X_USER_NAME          => or_masters_tbl.employee_num
        ,X_OWNER              => gv_owner
        ,X_DESCRIPTION        => or_masters_tbl.user_name_alt
        ,X_EMPLOYEE_ID        => or_masters_tbl.person_id
      );
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_api_name := 'FND_USER_PKG.UPDATEUSER';
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,      gv_msg_80c_013,
                                              gv_tkn_api_name, lv_api_name);
        lv_errbuf := lv_errmsg;
        RAISE global_api_others_expt;
    END;
--
    ot_report_tbl.fusr_flg := 1;
--
    -- 職責設定あり
    IF ((or_masters_tbl.resp1 IS NOT NULL) OR (or_masters_tbl.resp2 IS NOT NULL)
     OR (or_masters_tbl.resp3 IS NOT NULL) OR (or_masters_tbl.resp4 IS NOT NULL)
     OR (or_masters_tbl.resp5 IS NOT NULL) OR (or_masters_tbl.resp6 IS NOT NULL)
     OR (or_masters_tbl.resp7 IS NOT NULL) OR (or_masters_tbl.resp8 IS NOT NULL)
     OR (or_masters_tbl.resp9 IS NOT NULL) OR (or_masters_tbl.resp10 IS NOT NULL)) THEN
      --ユーザ職責マスタの無効化
      delete_group_all(or_masters_tbl, lv_errbuf, lv_retcode, lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
    END IF;
--
    -- ユーザ職責マスタ更新
    IF (or_masters_tbl.resp1 IS NOT NULL) THEN
      update_resp_all_f(or_masters_tbl.user_id,
                        or_masters_tbl.employee_num,
                        or_masters_tbl.resp1,
                        lv_errbuf,
                        lv_retcode,
                        lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
      ot_report_tbl.furg_flg := 1;
    END IF;
--
    -- ユーザ職責マスタ更新
    IF (or_masters_tbl.resp2 IS NOT NULL) THEN
      update_resp_all_f(or_masters_tbl.user_id,
                        or_masters_tbl.employee_num,
                        or_masters_tbl.resp2,
                        lv_errbuf,
                        lv_retcode,
                        lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
      ot_report_tbl.furg_flg := 1;
    END IF;
--
    -- ユーザ職責マスタ更新
    IF (or_masters_tbl.resp3 IS NOT NULL) THEN
      update_resp_all_f(or_masters_tbl.user_id,
                        or_masters_tbl.employee_num,
                        or_masters_tbl.resp3,
                        lv_errbuf,
                        lv_retcode,
                        lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
      ot_report_tbl.furg_flg := 1;
    END IF;
--
    -- ユーザ職責マスタ更新
    IF (or_masters_tbl.resp4 IS NOT NULL) THEN
      update_resp_all_f(or_masters_tbl.user_id,
                        or_masters_tbl.employee_num,
                        or_masters_tbl.resp4,
                        lv_errbuf,
                        lv_retcode,
                        lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
      ot_report_tbl.furg_flg := 1;
    END IF;
--
    -- ユーザ職責マスタ更新
    IF (or_masters_tbl.resp5 IS NOT NULL) THEN
      update_resp_all_f(or_masters_tbl.user_id,
                        or_masters_tbl.employee_num,
                        or_masters_tbl.resp5,
                        lv_errbuf,
                        lv_retcode,
                        lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
      ot_report_tbl.furg_flg := 1;
    END IF;
--
    -- ユーザ職責マスタ更新
    IF (or_masters_tbl.resp6 IS NOT NULL) THEN
      update_resp_all_f(or_masters_tbl.user_id,
                        or_masters_tbl.employee_num,
                        or_masters_tbl.resp6,
                        lv_errbuf,
                        lv_retcode,
                        lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
      ot_report_tbl.furg_flg := 1;
    END IF;
--
    -- ユーザ職責マスタ更新
    IF (or_masters_tbl.resp7 IS NOT NULL) THEN
      update_resp_all_f(or_masters_tbl.user_id,
                        or_masters_tbl.employee_num,
                        or_masters_tbl.resp7,
                        lv_errbuf,
                        lv_retcode,
                        lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
      ot_report_tbl.furg_flg := 1;
    END IF;
--
    -- ユーザ職責マスタ更新
    IF (or_masters_tbl.resp8 IS NOT NULL) THEN
      update_resp_all_f(or_masters_tbl.user_id,
                        or_masters_tbl.employee_num,
                        or_masters_tbl.resp8,
                        lv_errbuf,
                        lv_retcode,
                        lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
      ot_report_tbl.furg_flg := 1;
    END IF;
--
    -- ユーザ職責マスタ更新
    IF (or_masters_tbl.resp9 IS NOT NULL) THEN
      update_resp_all_f(or_masters_tbl.user_id,
                        or_masters_tbl.employee_num,
                        or_masters_tbl.resp9,
                        lv_errbuf,
                        lv_retcode,
                        lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
      ot_report_tbl.furg_flg := 1;
    END IF;
--
    -- ユーザ職責マスタ更新
    IF (or_masters_tbl.resp10 IS NOT NULL) THEN
      update_resp_all_f(or_masters_tbl.user_id,
                        or_masters_tbl.employee_num,
                        or_masters_tbl.resp10,
                        lv_errbuf,
                        lv_retcode,
                        lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
      ot_report_tbl.furg_flg := 1;
    END IF;
--
    -- 購買担当マスタ(直接)
-- 2009/03/25 v1.6 DELETE START
--    IF (or_masters_tbl.po_flag = gv_flg_on) THEN
-- 2009/03/25 v1.6 DELETE END
      -- 削除
      po_agents_proc(gn_proc_delete,
                     or_masters_tbl, 
                     lv_errbuf, 
                     lv_retcode, 
                     lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
-- 2009/03/25 v1.6 ADD START
    IF (or_masters_tbl.po_flag = gv_flg_on) THEN
-- 2009/03/25 v1.6 ADD END
      -- 登録
      po_agents_proc(gn_proc_insert,
                     or_masters_tbl, 
                     lv_errbuf, 
                     lv_retcode, 
                     lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      ot_report_tbl.pagn_flg := 1;
    END IF;
--
    -- 出荷ロールマスタ(直接)
-- 2009/03/25 v1.6 DELETE START
--    IF (or_masters_tbl.wsh_flag = gv_flg_on) THEN
-- 2009/03/25 v1.6 DELETE END
      -- 削除
      wsh_grants_proc(gn_proc_delete, 
                      or_masters_tbl, 
                      lv_errbuf, 
                      lv_retcode, 
                      lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
-- 2009/03/25 v1.6 ADD START
    IF (or_masters_tbl.wsh_flag = gv_flg_on) THEN
-- 2009/03/25 v1.6 ADD END
      -- 登録
      wsh_grants_proc(gn_proc_insert, 
                      or_masters_tbl, 
                      lv_errbuf, 
                      lv_retcode, 
                      lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      ot_report_tbl.wshg_flg := 1;
    END IF;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END update_proc;
--
  /***********************************************************************************
   * Procedure Name   : delete_proc
   * Description      : ユーザー削除情報格納処理を行います。(C-10)
   ***********************************************************************************/
  PROCEDURE delete_proc(
    ot_report_tbl  IN OUT NOCOPY report_rec,
    or_masters_tbl IN OUT NOCOPY masters_rec,
    ov_errbuf      OUT    NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT    NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg      OUT    NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_proc'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    -- HR_EX_EMPLOYEE_API.ACTUAL_TERMINATION_EMP
    ln_period_of_service_id    NUMBER;
    ln_object_version_num      NUMBER;
    ld_last_std_process_date   DATE;
    lb_supervisor_warn         BOOLEAN;
    lb_event_warn              BOOLEAN;
    lb_interview_warn          BOOLEAN;
    lb_review_warn             BOOLEAN;
    lb_recruiter_warn          BOOLEAN;
    lb_asg_future_changes_warn BOOLEAN;
    lv_entries_changed_warn    VARCHAR2(200);
    lb_pay_proposal_warn       BOOLEAN;
    lb_dod_warn                BOOLEAN;
--
    lv_api_name                VARCHAR2(200);
    lb_retcd                   BOOLEAN;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 従業員マスタの検索
    get_per_all_people_f(or_masters_tbl,
                         lv_errbuf,
                         lv_retcode,
                         lv_errmsg);
--
    -- 従業員取得エラー
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ユーザ存在チェック
    get_fnd_user(or_masters_tbl,
                 lv_errbuf,
                 lv_retcode,
                 lv_errmsg);
--
    -- ユーザ取得エラー
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    -- サービス期間ID取得
    get_service_id(or_masters_tbl,
                   ln_period_of_service_id,
                   ln_object_version_num,
                   lb_retcd,
                   lv_errbuf,
                   lv_retcode,
                   lv_errmsg);
--
    -- ユーザ取得エラー
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    BEGIN
      -- 従業員マスタ(API)
      HR_EX_EMPLOYEE_API.ACTUAL_TERMINATION_EMP(
        P_VALIDATE                   => FALSE
       ,P_EFFECTIVE_DATE             => SYSDATE-1
       ,P_PERIOD_OF_SERVICE_ID       => ln_period_of_service_id
       ,P_OBJECT_VERSION_NUMBER      => ln_object_version_num
       ,P_ACTUAL_TERMINATION_DATE    => SYSDATE                     -- 退職日
       ,P_LAST_STANDARD_PROCESS_DATE => SYSDATE                     -- 最終給与処理日
       ,P_LAST_STD_PROCESS_DATE_OUT  => ld_last_std_process_date    -- OUT
       ,P_SUPERVISOR_WARNING         => lb_supervisor_warn          -- OUT
       ,P_EVENT_WARNING              => lb_event_warn               -- OUT
       ,P_INTERVIEW_WARNING          => lb_interview_warn           -- OUT
       ,P_REVIEW_WARNING             => lb_review_warn              -- OUT
       ,P_RECRUITER_WARNING          => lb_recruiter_warn           -- OUT
       ,P_ASG_FUTURE_CHANGES_WARNING => lb_asg_future_changes_warn  -- OUT
       ,P_ENTRIES_CHANGED_WARNING    => lv_entries_changed_warn     -- OUT
       ,P_PAY_PROPOSAL_WARNING       => lb_pay_proposal_warn        -- OUT
       ,P_DOD_WARNING                => lb_dod_warn                 -- OUT
      );
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_api_name := 'HR_EX_EMPLOYEE_API.ACTUAL_TERMINATION_EMP';
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,      gv_msg_80c_013,
                                              gv_tkn_api_name, lv_api_name);
        lv_errbuf := lv_errmsg;
        RAISE global_api_others_expt;
    END;
--
    ot_report_tbl.papf_flg := 1;
--
    BEGIN
      HR_EX_EMPLOYEE_API.UPDATE_TERM_DETAILS_EMP(
        P_VALIDATE                   => FALSE
       ,P_EFFECTIVE_DATE             => SYSDATE-1
       ,P_PERIOD_OF_SERVICE_ID       => ln_period_of_service_id
       ,P_OBJECT_VERSION_NUMBER      => ln_object_version_num
       ,P_ACCEPTED_TERMINATION_DATE  => SYSDATE                    --- 退職承認日
       ,P_NOTIFIED_TERMINATION_DATE  => SYSDATE                    --- 退職届提出日
       ,P_PROJECTED_TERMINATION_DATE => SYSDATE                    --- 退職予定日
      );
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_api_name := 'HR_EX_EMPLOYEE_API.UPDATE_TERM_DETAILS_EMP';
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,      gv_msg_80c_013,
                                              gv_tkn_api_name, lv_api_name);
        lv_errbuf := lv_errmsg;
        RAISE global_api_others_expt;
    END;
--
    ot_report_tbl.paaf_flg := 1;
--
    -- ユーザマスタ(API)
    BEGIN
      FND_USER_PKG.UPDATEUSER(
         X_USER_NAME            => or_masters_tbl.employee_num
        ,X_OWNER                => gv_owner
        ,X_END_DATE             => SYSDATE-1
      );
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_api_name := 'FND_USER_PKG.UPDATEUSER';
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,      gv_msg_80c_013,
                                              gv_tkn_api_name, lv_api_name);
        lv_errbuf := lv_errmsg;
        RAISE global_api_others_expt;
    END;
--
    ot_report_tbl.fusr_flg := 1;
--
    -- ユーザ職責マスタ(API)
    delete_group_all(or_masters_tbl, 
                     lv_errbuf, 
                     lv_retcode, 
                     lv_errmsg);
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    ot_report_tbl.furg_flg := 1;
--
    -- 購買担当マスタ(直接)
    IF (or_masters_tbl.po_flag = gv_flg_on) THEN
      -- 削除
      po_agents_proc(gn_proc_delete,
                     or_masters_tbl, 
                     lv_errbuf, 
                     lv_retcode, 
                     lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      ot_report_tbl.pagn_flg := 1;
    END IF;
--
    -- 出荷ロールマスタ(直接)
    IF (or_masters_tbl.wsh_flag = gv_flg_on) THEN
      -- 削除
      wsh_grants_proc(gn_proc_delete, 
                      or_masters_tbl, 
                      lv_errbuf, 
                      lv_retcode, 
                      lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      ot_report_tbl.wshg_flg := 1;
    END IF;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END delete_proc;
--
  /***********************************************************************************
   * Procedure Name   : init_proc
   * Description      : 初期処理を行います。(C-1)
   ***********************************************************************************/
  PROCEDURE init_proc(
    ir_status_rec IN OUT NOCOPY status_rec,  -- 処理状況
    ov_errbuf     OUT    NOCOPY VARCHAR2,    -- エラー・メッセージ           --# 固定 #
    ov_retcode    OUT    NOCOPY VARCHAR2,    -- リターン・コード             --# 固定 #
    ov_errmsg     OUT    NOCOPY VARCHAR2)    -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init_proc'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
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
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- ===============================
    -- プロファイル取得
    -- ===============================
    get_profile(lv_errbuf,         -- エラー・メッセージ           --# 固定 #
                lv_retcode,        -- リターン・コード             --# 固定 #
                lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- パーソンタイプの取得
    -- ===============================
    get_per_person_types(lv_errbuf,      -- エラー・メッセージ           --# 固定 #
                         lv_retcode,     -- リターン・コード             --# 固定 #
                         lv_errmsg);     -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- 社員インタフェースロック処理
    -- ===============================
    set_if_lock(lv_errbuf,         -- エラー・メッセージ           --# 固定 #
                lv_retcode,        -- リターン・コード             --# 固定 #
                lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ファイルレベルのステータスを初期化
    init_status(ir_status_rec,
                lv_errbuf,
                lv_retcode,
                lv_errmsg);
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    -- WHOカラムの取得
    gn_created_by             := FND_GLOBAL.USER_ID;           -- 作成者
    gd_creation_date          := SYSDATE;                      -- 作成日
    gn_last_update_by         := FND_GLOBAL.USER_ID;           -- 最終更新者
    gd_last_update_date       := SYSDATE;                      -- 最終更新日
    gn_last_update_login      := FND_GLOBAL.LOGIN_ID;          -- 最終更新ログイン
    gn_request_id             := FND_GLOBAL.CONC_REQUEST_ID;   -- 要求ID
    gn_program_application_id := FND_GLOBAL.PROG_APPL_ID;      -- プログラムアプリケーションID
    gn_program_id             := FND_GLOBAL.CONC_PROGRAM_ID;   -- プログラムID
    gd_program_update_date    := SYSDATE;                      -- プログラム更新日
--
  EXCEPTION
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END init_proc;
--
  /***********************************************************************************
   * Procedure Name   : submain
   * Description      : 社員インタフェースのデータを各マスタへ反映するプロシージャ
   **********************************************************************************/
  PROCEDURE submain(
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
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain'; -- プログラム名
--
--#####################################  固定部 END   #############################################
--
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lr_masters_rec masters_rec; -- 処理対象データ格納レコード
    lr_status_rec  status_rec;  -- 処理状況格納レコード
--
    lt_report_tbl report_tbl;   -- レポート出力結合配列
--
    lt_insert_masters masters_tbl; -- 各マスタへ登録するデータ
    lt_update_masters masters_tbl; -- 各マスタへ更新するデータ
    lt_delete_masters masters_tbl; -- 各マスタへ削除するデータ
--
    ln_insert_cnt NUMBER;          -- 登録件数
    ln_update_cnt NUMBER;          -- 更新件数
    ln_delete_cnt NUMBER;          -- 削除件数
    ln_exec_cnt   NUMBER;
    ln_log_cnt    NUMBER;
    lb_retcd      BOOLEAN;         -- 検索結果
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    CURSOR emp_if_cur
    IS
      SELECT xei.seq_num,
             xei.proc_code,
             xei.employee_num,
             xei.base_code,
             xei.user_name,
             xei.user_name_alt,
             xei.position_id,
             xei.qualification_id,
             xei.spare
      FROM   xxcmn_emp_if xei
      ORDER BY xei.seq_num;
--
    lr_emp_if_rec emp_if_cur%ROWTYPE;
--
  BEGIN
--
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- グローバル変数の初期化
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
    gn_report_cnt := 0;
    ln_insert_cnt := 0;
    ln_update_cnt := 0;
    ln_delete_cnt := 0;
--
    -- ===============================
    -- 初期処理(C-1)
    -- ===============================
    init_proc(lr_status_rec,
              lv_errbuf,
              lv_retcode,
              lv_errmsg);
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ***************************************
    -- ***        ループ処理の記述         ***
    -- ***       処理部の呼び出し          ***
    -- ***************************************
--
    -- 行単位のロック実行
    set_line_lock(lr_masters_rec,
                  lv_errbuf,
                  lv_retcode,
                  lv_errmsg);
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE check_sub_main_expt;
    END IF;
--
    -- ===============================
    -- 社員インタフェース取込処理(C-2)
    -- ===============================
    OPEN emp_if_cur;
--
    <<emp_if_loop>>
    LOOP
      FETCH emp_if_cur INTO lr_emp_if_rec;
      EXIT WHEN emp_if_cur%NOTFOUND;
      gn_target_cnt := gn_target_cnt + 1; -- 処理件数カウントアップ
--
      -- 行レベルのステータスを初期化
      init_row_status(lr_status_rec,
                      lv_errbuf,
                      lv_retcode,
                      lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE check_sub_main_expt;
      END IF;
--
      -- 取得した値をレコードにコピー
      -- カーソルをグローバルにしないために関数化はしない。
      lr_masters_rec.seq_num          := lr_emp_if_rec.seq_num;
      lr_masters_rec.proc_code        := lr_emp_if_rec.proc_code;
      lr_masters_rec.employee_num     := lr_emp_if_rec.employee_num;
      lr_masters_rec.base_code        := lr_emp_if_rec.base_code;
      lr_masters_rec.user_name        := lr_emp_if_rec.user_name;
      lr_masters_rec.user_name_alt    := lr_emp_if_rec.user_name_alt;
      lr_masters_rec.position_id      := lr_emp_if_rec.position_id;
      lr_masters_rec.qualification_id := lr_emp_if_rec.qualification_id;
      lr_masters_rec.spare            := lr_emp_if_rec.spare;
--
      -- 件数の初期化
      lr_masters_rec.row_ins_cnt := 0;
      lr_masters_rec.row_upd_cnt := 0;
      lr_masters_rec.row_del_cnt := 0;
--
      -- 更新区分チェック
      check_proc_code(lr_status_rec,
                      lr_masters_rec,
                      lv_errbuf,
                      lv_retcode,
                      lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE check_sub_main_expt;
      END IF;
--
      IF (is_row_status_nomal(lr_status_rec)) THEN
        -- 以前のデータ状態の取得
        get_xxcmn_emp_if(lr_masters_rec,
                         lv_errbuf,
                         lv_retcode,
                         lv_errmsg);
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE check_sub_main_expt;
        END IF;
      END IF;
--
      IF (is_row_status_nomal(lr_status_rec)) THEN
        -- 新規登録時
        IF ((lr_masters_rec.proc_code = gn_proc_insert) 
        -- 更新で以前に新規登録あり
        OR ((lr_masters_rec.proc_code = gn_proc_update) 
        AND (lr_masters_rec.row_ins_cnt <> 0))
        -- 削除で以前に新規登録あり
        OR ((lr_masters_rec.proc_code = gn_proc_delete)
        AND (lr_masters_rec.row_ins_cnt <> 0))) THEN
          -- 新規登録時の担当拠点の取得(C-3)
          get_location_new(lr_status_rec,
                           lr_masters_rec,
                           lv_errbuf,
                           lv_retcode,
                           lv_errmsg);
        ELSE
          -- 更新・削除時の担当拠点の取得(C-3)
          get_location_mod(lr_status_rec,
                           lr_masters_rec,
                           lv_errbuf,
                           lv_retcode,
                           lv_errmsg);
        END IF;
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE check_sub_main_expt;
        END IF;
      END IF;
--
      -- 登録、更新、削除の各チェック処理へ振り分け
      -- エラーデータはチェックを行わない。
      IF (is_row_status_nomal(lr_status_rec)) THEN
--
        -- 登録
        IF (lr_masters_rec.proc_code = gn_proc_insert) THEN
--
          -- 重複データなし
          IF ((lr_masters_rec.row_ins_cnt = 0)
            AND (lr_masters_rec.row_upd_cnt = 0)
            AND (lr_masters_rec.row_del_cnt = 0)) THEN
--
            -- 登録用チェック処理(C-4)
            check_insert(lr_status_rec,
                         lr_masters_rec,
                         lv_errbuf,
                         lv_retcode,
                         lv_errmsg);
--
            IF (lv_retcode = gv_status_error) THEN
              -- エラーメッセージはチェック処理内で設定済み
              RAISE check_sub_main_expt;
            END IF;
--
            IF is_row_status_nomal(lr_status_rec) THEN
              -- 登録データ格納(C-7)
              lt_insert_masters(ln_insert_cnt) := lr_masters_rec;
              ln_insert_cnt := ln_insert_cnt + 1;
            END IF;
--
          -- 重複データが存在する場合はエラー
          ELSE
            set_error_status(lr_status_rec,
                             xxcmn_common_pkg.get_msg(gv_msg_kbn,     gv_msg_80c_018,
                                                      gv_tkn_ng_user, lr_masters_rec.employee_num,
                                                      gv_tkn_table,   gv_xxcmn_emp_if_name),
                             lv_errbuf,
                             lv_retcode,
                             lv_errmsg);
--
            IF (lv_retcode = gv_status_error) THEN
              RAISE check_sub_main_expt;
            END IF;
          END IF;
--
        -- 更新
        ELSIF (lr_masters_rec.proc_code = gn_proc_update) THEN
--
          -- 以前に削除データなし
          IF (lr_masters_rec.row_del_cnt = 0) THEN
            -- 更新用チェック処理(C-5)
            check_update(lr_status_rec,
                         lr_masters_rec,
                         lv_errbuf,
                         lv_retcode,
                         lv_errmsg);
--
            IF (lv_retcode = gv_status_error) THEN
              -- エラーメッセージはチェック処理内で設定済み
              RAISE check_sub_main_expt;
            END IF;
--
            IF (is_row_status_nomal(lr_status_rec)) THEN
              -- 更新データ格納(C-8)
              lt_update_masters(ln_update_cnt) := lr_masters_rec;
              ln_update_cnt := ln_update_cnt + 1;
            END IF;
--
          -- 以前に削除データが存在する場合は警告
          ELSE
            -- 警告を設定
            set_error_status(lr_status_rec,
                             xxcmn_common_pkg.get_msg(gv_msg_kbn,     gv_msg_80c_019,
                                                      gv_tkn_ng_user, lr_masters_rec.employee_num,
                                                      gv_tkn_table,   gv_xxcmn_emp_if_name),
                             lv_errbuf,
                             lv_retcode,
                             lv_errmsg);
--
            IF (lv_retcode = gv_status_error) THEN
              RAISE check_sub_main_expt;
            END IF;
          END IF;
--
        -- 削除
        ELSIF (lr_masters_rec.proc_code = gn_proc_delete) THEN
--
          -- 以前に削除データなし
          IF (lr_masters_rec.row_del_cnt = 0) THEN
            -- 削除用チェック処理(C-6)
            check_delete(lr_status_rec,
                         lr_masters_rec,
                         lv_errbuf,
                         lv_retcode,
                         lv_errmsg);
--
            IF (lv_retcode = gv_status_error) THEN
              -- エラーメッセージはチェック処理内で設定済み
              RAISE check_sub_main_expt;
            END IF;
--
            IF (is_row_status_nomal(lr_status_rec)) THEN
              -- 削除データ格納(C-9)
              lt_delete_masters(ln_delete_cnt) := lr_masters_rec;
              ln_delete_cnt := ln_delete_cnt + 1;
            END IF;
--
          -- 以前に削除データが存在する場合は警告
          ELSE
            -- 警告を設定
            set_warn_status(lr_status_rec,
                            xxcmn_common_pkg.get_msg(gv_msg_kbn,     gv_msg_80c_020,
                                                     gv_tkn_ng_user, lr_masters_rec.employee_num,
                                                     gv_tkn_table,   gv_xxcmn_emp_if_name),
                            lv_errbuf,
                            lv_retcode,
                            lv_errmsg);
--
            IF (lv_retcode = gv_status_error) THEN
              RAISE check_sub_main_expt;
            END IF;
          END IF;
        END IF;
      END IF;
--
      -- 正常件数をカウントアップ
      IF (is_row_status_nomal(lr_status_rec)) THEN
        gn_normal_cnt := gn_normal_cnt + 1;
--
      ELSE
        -- 警告件数をカウントアップ
        IF (is_row_status_warn(lr_status_rec)) THEN
          gn_warn_cnt := gn_warn_cnt + 1;
--
        -- 異常件数をカウントアップ
        ELSE
          gn_error_cnt := gn_error_cnt +1;
        END IF;
      END IF;
--
      -- ログ出力用データの格納
      add_report(lr_status_rec, lr_masters_rec, lt_report_tbl,
                 lv_errbuf,
                 lv_retcode,
                 lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE check_sub_main_expt;
      END IF;
--
    END LOOP emp_if_loop;
    CLOSE emp_if_cur;
--
    -- データの反映(エラーなし)
    IF (is_file_status_nomal(lr_status_rec)) THEN
--
      -- 登録処理
      -- 登録データの反映(C-10)
      <<insert_proc_loop>>
      FOR ln_exec_cnt IN 0..ln_insert_cnt-1 LOOP
        <<insert_log_loop>>
        FOR ln_log_cnt IN 0..gn_report_cnt-1 LOOP
          -- 登録
          IF (lt_report_tbl(ln_log_cnt).proc_code = gn_proc_insert) THEN
            -- SEQ番号
            IF (lt_report_tbl(ln_log_cnt).seq_num =
                lt_insert_masters(ln_exec_cnt).seq_num) THEN
--
              -- 登録処理
              insert_proc(lt_report_tbl(ln_log_cnt),
                          lt_insert_masters(ln_exec_cnt),
                          lv_errbuf,
                          lv_retcode,
                          lv_errmsg);
--
              IF (lv_retcode = gv_status_error) THEN
                RAISE check_sub_main_expt;
              END IF;
            END IF;
          END IF;
        END LOOP insert_log_loop;
      END LOOP insert_proc_loop;
--
      -- 更新処理
      -- 更新データの反映(C-10)
      <<update_proc_loop>>
      FOR ln_exec_cnt IN 0..ln_update_cnt-1 LOOP
        <<update_log_loop>>
        FOR ln_log_cnt IN 0..gn_report_cnt-1 LOOP
          -- 更新
          IF (lt_report_tbl(ln_log_cnt).proc_code = gn_proc_update) THEN
            -- SEQ番号
            IF (lt_report_tbl(ln_log_cnt).seq_num =
                lt_update_masters(ln_exec_cnt).seq_num) THEN
--
              -- 更新処理
              update_proc(lt_report_tbl(ln_log_cnt),
                          lt_update_masters(ln_exec_cnt),
                          lv_errbuf,
                          lv_retcode,
                          lv_errmsg);
--
              IF (lv_retcode = gv_status_error) THEN
                RAISE check_sub_main_expt;
              END IF;
            END IF;
          END IF;
        END LOOP update_log_loop;
      END LOOP update_proc_loop;
--
      -- 削除処理
      -- 削除データの反映(C-10)
      <<delete_proc_loop>>
      FOR ln_exec_cnt IN 0..ln_delete_cnt-1 LOOP
        <<delete_log_loop>>
        FOR ln_log_cnt IN 0..gn_report_cnt-1 LOOP
          -- 削除
          IF (lt_report_tbl(ln_log_cnt).proc_code = gn_proc_delete) THEN
            -- SEQ番号
            IF (lt_report_tbl(ln_log_cnt).seq_num =
                lt_delete_masters(ln_exec_cnt).seq_num) THEN
--
              -- 削除処理
              delete_proc(lt_report_tbl(ln_log_cnt),
                          lt_delete_masters(ln_exec_cnt),
                          lv_errbuf,
                          lv_retcode,
                          lv_errmsg);
--
              IF (lv_retcode = gv_status_error) THEN
                RAISE check_sub_main_expt;
              END IF;
            END IF;
          END IF;
        END LOOP delete_log_loop;
      END LOOP delete_proc_loop;
    END IF;
--
    IF (gn_normal_cnt > 0) THEN
      -- ログ出力処理(成功:0)(C-11)
      disp_report(lt_report_tbl, gn_data_status_nomal,
                  lv_errbuf,
                  lv_retcode,
                  lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE check_sub_main_expt;
      END IF;
    END IF;
--
    IF (gn_error_cnt > 0) THEN
      -- ログ出力処理(失敗:1)(C-11)
      disp_report(lt_report_tbl, gn_data_status_error,
                  lv_errbuf,
                  lv_retcode,
                  lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE check_sub_main_expt;
      END IF;
    END IF;
--
    IF (gn_warn_cnt > 0) THEN
      -- ログ出力処理(警告:2)(C-11)
      disp_report(lt_report_tbl, gn_data_status_warn,
                  lv_errbuf,
                  lv_retcode,
                  lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE check_sub_main_expt;
      END IF;
    END IF;
--
    IF (gc_ppf_cur%ISOPEN) THEN
      -- カーソルのクローズ
      CLOSE gc_ppf_cur;
    END IF;
    IF (gc_paf_cur%ISOPEN) THEN
      -- カーソルのクローズ
      CLOSE gc_paf_cur;
    END IF;
    IF (gc_fu_cur%ISOPEN) THEN
      -- カーソルのクローズ
      CLOSE gc_fu_cur;
    END IF;
    IF (gc_fug_cur%ISOPEN) THEN
      -- カーソルのクローズ
      CLOSE gc_fug_cur;
    END IF;
    IF (gc_poa_cur%ISOPEN) THEN
      -- カーソルのクローズ
      CLOSE gc_poa_cur;
    END IF;
    IF (gc_wgs_cur%ISOPEN) THEN
      -- カーソルのクローズ
      CLOSE gc_wgs_cur;
    END IF;
--
    -- ===============================
    -- 社員インタフェース削除処理(C-11)
    -- 正常終了異常終了にかかわらず削除を行う
    -- ===============================
    delete_emp_if(lv_errbuf,lv_retcode,lv_errmsg);
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE check_sub_main_expt;
    END IF;
--
    -- 2008/07/07 Add ↓
    IF (gn_target_cnt = 0) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                            gv_msg_80c_023);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      gn_warn_cnt := gn_warn_cnt + 1;
      ov_retcode := gv_status_warn;
    END IF;
    -- 2008/07/07 Add ↑
--
    -- エラー、ワーニングデータ有りの場合はワーニング終了する。
    IF ((gn_error_cnt + gn_warn_cnt) > 0) THEN
      ov_retcode := gv_status_warn;
    END IF;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
  EXCEPTION
      -- *** 任意で例外処理を記述する ****
    WHEN check_sub_main_expt THEN
      ov_errmsg := lv_errmsg;                                                   --# 任意 #
      ov_errbuf := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# 任意 #
      -- カーソルが開いていれば
      IF (emp_if_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE emp_if_cur;
      END IF;
      IF (gc_ppf_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE gc_ppf_cur;
      END IF;
      IF (gc_paf_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE gc_paf_cur;
      END IF;
      IF (gc_fu_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE gc_fu_cur;
      END IF;
      IF (gc_fug_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE gc_fug_cur;
      END IF;
      IF (gc_poa_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE gc_poa_cur;
      END IF;
      IF (gc_wgs_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE gc_wgs_cur;
      END IF;
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
      -- カーソルが開いていれば
      IF (emp_if_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE emp_if_cur;
      END IF;
      IF (gc_ppf_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE gc_ppf_cur;
      END IF;
      IF (gc_paf_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE gc_paf_cur;
      END IF;
      IF (gc_fu_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE gc_fu_cur;
      END IF;
      IF (gc_fug_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE gc_fug_cur;
      END IF;
      IF (gc_poa_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE gc_poa_cur;
      END IF;
      IF (gc_wgs_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE gc_wgs_cur;
      END IF;
--
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      -- カーソルが開いていれば
      IF (emp_if_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE emp_if_cur;
      END IF;
      IF (gc_ppf_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE gc_ppf_cur;
      END IF;
      IF (gc_paf_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE gc_paf_cur;
      END IF;
      IF (gc_fu_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE gc_fu_cur;
      END IF;
      IF (gc_fug_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE gc_fug_cur;
      END IF;
      IF (gc_poa_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE gc_poa_cur;
      END IF;
      IF (gc_wgs_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE gc_wgs_cur;
      END IF;
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      -- カーソルが開いていれば
      IF (emp_if_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE emp_if_cur;
      END IF;
      IF (gc_ppf_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE gc_ppf_cur;
      END IF;
      IF (gc_paf_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE gc_paf_cur;
      END IF;
      IF (gc_fu_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE gc_fu_cur;
      END IF;
      IF (gc_fug_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE gc_fug_cur;
      END IF;
      IF (gc_poa_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE gc_poa_cur;
      END IF;
      IF (gc_wgs_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE gc_wgs_cur;
      END IF;
--
--#####################################  固定部 END   #############################################
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
  PROCEDURE main(
    errbuf   OUT NOCOPY VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode  OUT NOCOPY VARCHAR2)      --   リターン・コード    --# 固定 #
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
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
    lv_msgbuf  VARCHAR2(5000);  -- エラー・メッセージ
--
--#####################################  固定部 END   #############################################
--
  BEGIN
--
--################################  固定ステータス初期化部 START   ################################
--
    -- ======================
    -- 固定出力用変数セット
    -- ======================
    --実行ユーザ名取得
    gv_exec_user := fnd_global.user_name;
--
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
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn,  gv_msg_80c_001,
                                           gv_tkn_user, gv_exec_user);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_out_msg);
--
    --実行コンカレント名出力
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn,  gv_msg_80c_002,
                                           gv_tkn_conc, gv_conc_name);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_out_msg);
--
    --起動時間出力
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn,  gv_msg_80c_022,
                                           gv_tkn_time, TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS'));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_out_msg);
--
    --区切り文字出力
    gv_sep_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_80c_003);
--
--#####################################  固定部 END   #############################################
--
    -- ===============================================
    -- submainの呼び出し(実際の処理はsubmainで行う)
    -- ===============================================
    submain(lv_errbuf,   -- エラー・メッセージ           --# 固定 #
            lv_retcode,  -- リターン・コード             --# 固定 #
            lv_errmsg);  -- ユーザー・エラー・メッセージ --# 固定 #
--
--#####################################  固定部 START   ###########################################
--
    -- ======================
    -- エラー・メッセージ出力
    -- ======================
    IF (lv_retcode = gv_status_error) THEN
      IF (lv_errmsg IS NULL) THEN
        --定型メッセージ・セット
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_80c_021);
      END IF;
      FND_FILE.PUT_LINE(FND_FILE.LOG, lv_errbuf);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_errmsg);
    END IF;
--
    --エラー以外は出力
    IF (lv_retcode != gv_status_error) THEN
      -- ==================================
      -- リターン・コードのセット、終了処理
      -- ==================================
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_sep_msg);
--
      --処理件数出力
      gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_80c_007,
                                             gv_tkn_cnt, TO_CHAR(gn_target_cnt));
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_out_msg);
--
      --成功件数出力
      gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_80c_008,
                                             gv_tkn_cnt, TO_CHAR(gn_normal_cnt));
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
      --エラー件数出力
      gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_80c_009,
                                             gv_tkn_cnt, TO_CHAR(gn_error_cnt));
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
      --警告件数出力
      gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_80c_010,
                                             gv_tkn_cnt, TO_CHAR(gn_warn_cnt));
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
    END IF;
--
    --ステータス変換
    SELECT flv.meaning
    INTO   gv_conc_status
    FROM   fnd_lookup_values flv
    WHERE  flv.language            = userenv('LANG')
    AND    flv.view_application_id = 0
    AND    flv.security_group_id   = fnd_global.lookup_security_group(flv.lookup_type, 
                                                                      flv.view_application_id)
    AND    flv.lookup_type         = 'CP_STATUS_CODE'
    AND    flv.lookup_code         = DECODE(lv_retcode,
                                            gv_status_normal, gv_sts_cd_normal,
                                            gv_status_warn,   gv_sts_cd_warn,
                                            gv_sts_cd_error)
    AND    ROWNUM                  = 1;
--
    --処理ステータス出力
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn,    gv_msg_80c_011, 
                                           gv_tkn_status, gv_conc_status);
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
      errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
  END main;
--
--#####################################  固定部 END   #############################################
--
END xxcmn800003c;
/
