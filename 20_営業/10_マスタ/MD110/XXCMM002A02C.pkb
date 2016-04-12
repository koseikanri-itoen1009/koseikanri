CREATE OR REPLACE PACKAGE BODY XXCMM002A02C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCMM002A02C(body)
 * Description      : 社員データ連携(自販機)
 * MD.050           : 社員データ連携(自販機) MD050_CMM_002_A02
 * Version          : 1.3
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理プロシージャ(A-1)
 *  get_people_data        社員データ取得プロシージャ(A-2)
 *  output_csv             CSVファイル出力プロシージャ(A-4)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/29    1.0   SCS 福間 貴子    初回作成
 *  2009/09/09    1.1   SCS 久保島 豊    障害0000337 従業員の抽出条件を変更
 *                                       ( 4(ダミー)以外 -> 1(社員)または3(派遣社員) )
 *  2016/02/24    1.2   SCSK 小路 恭弘   E_本稼動_13456対応
 *  2016/03/24    1.3   SCSK 岡田 英輝   E_本稼動_13456追加対応
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
  lock_expt                 EXCEPTION;        -- ロック(ビジー)エラー
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name               CONSTANT VARCHAR2(100) := 'XXCMM002A02C';               -- パッケージ名
  -- プロファイル
  cv_filepath               CONSTANT VARCHAR2(30)  := 'XXCMM1_JIHANKI_OUT_DIR';     -- 自販機CSVファイル出力先
  cv_filename               CONSTANT VARCHAR2(30)  := 'XXCMM1_002A02_OUT_FILE';     -- 連携用CSVファイル名
-- 2009/09/09 Ver1.1 delete start by Y.Kuboshima
--  cv_jyugyoin_kbn           CONSTANT VARCHAR2(30)  := 'XXCMM1_002A02_JYUGYOIN_KBN'; -- 従業員区分のダミー値
-- 2009/09/09 Ver1.1 delete end by Y.Kuboshima
  -- トークン
  cv_tkn_profile            CONSTANT VARCHAR2(10)  := 'NG_PROFILE';                 -- プロファイル名
  cv_tkn_filepath_nm        CONSTANT VARCHAR2(20)  := 'CSVファイル出力先';
  cv_tkn_filename_nm        CONSTANT VARCHAR2(20)  := 'CSVファイル名';
-- 2009/09/09 Ver1.1 delete start by Y.Kuboshima
--  cv_tkn_jyugoin_kbn_nm     CONSTANT VARCHAR2(20)  := '従業員区分のダミー値';
-- 2009/09/09 Ver1.1 delete end by Y.Kuboshima
  cv_tkn_word               CONSTANT VARCHAR2(10)  := 'NG_WORD';                    -- 項目名
  cv_tkn_word1              CONSTANT VARCHAR2(10)  := '社員番号';
  cv_tkn_word2              CONSTANT VARCHAR2(10)  := '、氏名 : ';
  cv_tkn_data               CONSTANT VARCHAR2(10)  := 'NG_DATA';                    -- データ
  cv_tkn_filename           CONSTANT VARCHAR2(10)  := 'FILE_NAME';                  -- ファイル名
  cv_tkn_table              CONSTANT VARCHAR2(10)  := 'NG_TABLE';                   -- テーブル
  cv_tkn_table_nm1          CONSTANT VARCHAR2(20)  := 'アサインメントマスタ';
-- 2009/09/09 Ver1.1 modify start by Y.Kuboshima
--  cv_tkn_table_nm2          CONSTANT VARCHAR2(40)  := '自販機差分連携用社員データテーブル';
-- 2016/02/24 Ver1.2 Del Start
--  cv_tkn_table_nm2          CONSTANT VARCHAR2(40)  := '、自販機差分連携用社員データテーブル';
-- 2016/02/24 Ver1.2 Del End
-- 2009/09/09 Ver1.1 modify end by Y.Kuboshima
  cv_tkn_value              CONSTANT VARCHAR2(10)  := 'VALUE';                      -- 項目名
  cv_tkn_value_nm1          CONSTANT VARCHAR2(10)  := '社員番号';
-- 2016/02/24 Ver1.2 Del Start
--  cv_tkn_value_nm2          CONSTANT VARCHAR2(10)  := '発令日';
-- 2016/02/24 Ver1.2 Del End
  cv_tkn_value_nm3          CONSTANT VARCHAR2(10)  := '漢字(姓)';
-- 2016/02/24 Ver1.2 Del Start
--  cv_tkn_value_nm4          CONSTANT VARCHAR2(10)  := 'カナ(姓)';
-- 2016/02/24 Ver1.2 Del End
  cv_tkn_value_nm5          CONSTANT VARCHAR2(10)  := '起票部門';
  cv_tkn_value_nm6          CONSTANT VARCHAR2(10)  := '漢字(名)';
-- 2016/02/24 Ver1.2 Del Start
--  cv_tkn_value_nm7          CONSTANT VARCHAR2(10)  := 'カナ(名)';
-- 2016/02/24 Ver1.2 Del End
  cv_tkn_param              CONSTANT VARCHAR2(10)  := 'PARAM';                      -- パラメータ名
  cv_tkn_param1             CONSTANT VARCHAR2(10)  := '開始日';
  cv_tkn_param2             CONSTANT VARCHAR2(10)  := '終了日';
  cv_tkn_param3             CONSTANT VARCHAR2(20)  := '入力パラメータ';
  cv_tkn_ng_value           CONSTANT VARCHAR2(10)  := 'NG_VALUE';                   -- 項目名
---- 2016/02/24 Ver1.2 Add Start
  cv_tkn_department_code    CONSTANT VARCHAR2(15)  := 'DEPARTMENT_CODE';            -- 拠点
  cv_tkn_employee_number    CONSTANT VARCHAR2(15)  := 'EMPLOYEE_NUMBER';            -- 従業員
---- 2016/03/16 Ver1.2 Add End
  -- メッセージ区分
  cv_msg_kbn_cmm            CONSTANT VARCHAR2(5)   := 'XXCMM';
  cv_msg_kbn_ccp            CONSTANT VARCHAR2(5)   := 'XXCCP';
  -- メッセージ
  cv_msg_00218              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00218';           -- 入力パラメータ指定エラー(終了日のみ指定)
  cv_msg_00038              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00038';           -- 入力パラメータ出力メッセージ
  cv_msg_00002              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00002';           -- プロファイル取得エラー
  cv_msg_05102              CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-05102';           -- ファイル名出力メッセージ
  cv_msg_00018              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00018';           -- 業務日付取得エラー
  cv_msg_00030              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00030';           -- 対象期間制限エラー
  cv_msg_00019              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00019';           -- 対象期間指定エラー
  cv_msg_00010              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00010';           -- CSVファイル存在チェック
  cv_msg_00003              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00003';           -- ファイルパス不正エラー
  cv_msg_00008              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00008';           -- ロック取得NGメッセージ
  cv_msg_00209              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00209';           -- 従業員番号重複メッセージ
  cv_msg_00216              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00216';           -- 禁則文字存在チェックメッセージ
-- 2016/02/24 Ver1.2 Del Start
--  cv_msg_00217              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00217';           -- 過去連携データ取得エラー
-- 2016/02/24 Ver1.2 Del End
  cv_msg_00007              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00007';           -- ファイルアクセス権限エラー
  cv_msg_00009              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00009';           -- CSVデータ出力エラー
-- 2016/02/24 Ver1.2 Del Start
--  cv_msg_00032              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00032';           -- 自販機差分連携用社員データテーブル更新エラー
-- 2016/02/24 Ver1.2 Del End
  cv_msg_00029              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00029';           -- アサインメントマスタ更新エラー
-- 2016/02/24 Ver1.2 Add Start
  cv_msg_00224              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00224';           -- 承認者複数警告
-- 2016/02/24 Ver1.2 Add End
  -- 固定値(設定値)
-- 2016/02/24 Ver1.2 Del Start
--  cv_riyou_kbn              CONSTANT VARCHAR2(2)   := '02';                         -- 利用者区分
--  cv_99999999               CONSTANT VARCHAR2(8)   := '99999999';                   -- 適用終了日(発令日=入社年月日)
-- 2016/02/24 Ver1.2 Del End
  cv_team_cd                CONSTANT VARCHAR2(4)   := '0000';                       -- チームコード
-- 2016/02/24 Ver1.2 Del Start
--  cv_flg_0                  CONSTANT NUMBER(1)     := 0;                            -- 利用停止フラグ(0)
--  cv_flg_1                  CONSTANT NUMBER(1)     := 1;                            -- 利用停止フラグ(1)
--  cv_tanto_cd               CONSTANT VARCHAR2(5)   := '99999';                      -- 更新担当者コード
--  cv_busyo_cd               CONSTANT VARCHAR2(6)   := '999999';                     -- 更新部署コード
--  cv_program_id             CONSTANT VARCHAR2(10)  := 'USER_ULD';                   -- 更新プログラムID
-- 2016/02/24 Ver1.2 Del End
  cv_chk_cd                 CONSTANT VARCHAR2(22)  := 'VENDING_MACHINE_SYSTEM';     -- 自販機システムチェック
  cv_flg_t                  CONSTANT VARCHAR2(1)   := 'T';                          -- 実行フラグ(T:定期)
  cv_flg_r                  CONSTANT VARCHAR2(1)   := 'R';                          -- 実行フラグ(R:随時(リカバリ))
-- 2009/09/09 Ver1.1 add start by Y.Kuboshima
  cv_jyugyoin_kbn_1         CONSTANT VARCHAR2(1)   := '1';                          -- 従業員区分(1:社員)
  cv_jyugyoin_kbn_3         CONSTANT VARCHAR2(1)   := '3';                          -- 従業員区分(3:派遣社員)
-- 2009/09/09 Ver1.1 add end by Y.Kuboshima
-- 2016/02/24 Ver1.2 Add Start
  cv_customer_class_code_1  CONSTANT VARCHAR2(1)   := '1';                          -- 拠点
  cv_del_flg_0              CONSTANT VARCHAR2(1)   := '0';                          -- 削除フラグ(0)
  cv_del_flg_1              CONSTANT VARCHAR2(1)   := '1';                          -- 削除フラグ(1)
  cv_department_flg_1       CONSTANT VARCHAR2(1)   := '1';                          -- (HOST)１課・２課フラグ:1
  cv_date_format_yyyymmdd   CONSTANT VARCHAR2(8)   := 'YYYYMMDD';                   -- 日付書式：YYYYMMDD
  cv_y                      CONSTANT VARCHAR2(1)   := 'Y';                          -- フラグ：Y
  cv_n                      CONSTANT VARCHAR2(1)   := 'N';                          -- フラグ：N
  -- 言語
  ct_user_lang              CONSTANT  fnd_lookup_values.language%TYPE := USERENV( 'LANG' );
  -- 参照タイプ
  cv_approve_code           CONSTANT VARCHAR2(19)  := 'XXCMM_APPROVE_CODE';         -- 承認者コード
-- 2016/02/24 Ver1.2 Add End
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 社員データを格納するレコード
  TYPE data_rec  IS RECORD(
-- 2016/02/24 Ver1.2 Del Start
--       person_id                per_all_people_f.person_id%TYPE,                      -- 従業員ID
-- 2016/02/24 Ver1.2 Del End
       employee_number          per_all_people_f.employee_number%TYPE,                -- 従業員番号
       effective_start_date     per_all_people_f.effective_start_date%TYPE,           -- 入社年月日
       actual_termination_date  per_periods_of_service.actual_termination_date%TYPE,  -- 退職年月日
       per_information18        per_all_people_f.per_information18%TYPE,              -- 漢字姓
       per_information19        per_all_people_f.per_information19%TYPE,              -- 漢字名
-- 2016/02/24 Ver1.2 Del Start
--       last_name                per_all_people_f.last_name%TYPE,                      -- カナ姓
--       first_name               per_all_people_f.first_name%TYPE,                     -- カナ名
-- 2016/02/24 Ver1.2 Del End
       attribute28              per_all_people_f.attribute28%TYPE,                    -- 起票部門
       ass_attribute2           per_all_assignments_f.ass_attribute2%TYPE,            -- 発令日
       ass_attribute17          per_all_assignments_f.ass_attribute17%TYPE,           -- 差分連携用日付(自販機)
       assignment_id            per_all_assignments_f.assignment_id%TYPE,             -- アサインメントID
       j_update_date            per_all_people_f.last_update_date%TYPE,               -- 従業員.最終更新日
-- 2016/02/24 Ver1.2 Mod Start
--       a_update_date            per_all_assignments_f.last_update_date%TYPE           -- アサインメント.最終更新日
       a_update_date            per_all_assignments_f.last_update_date%TYPE,           -- アサインメント.最終更新日
       attribute11              per_all_people_f.attribute11%TYPE,                    -- 職位コード（新）
       attribute13              per_all_people_f.attribute13%TYPE,                    -- 職位コード（旧）
       area_code                hz_locations.address3%TYPE                            -- 地区コード
-- 2016/02/24 Ver1.2 Mod End
  );
  -- 社員データを格納するテーブル型の定義
  TYPE data_tbl  IS TABLE OF data_rec INDEX BY BINARY_INTEGER;
-- 2016/03/24 Ver1.3 Add Start
  -- 拠点別の承認者を格納するテーブル型の定義
  TYPE g_base_applover_ttype IS TABLE OF per_people_f.employee_number%TYPE INDEX BY VARCHAR2(4);
-- 2016/03/24 Ver1.3 Add End
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gv_filepath               VARCHAR2(255);        -- 連携用CSVファイル出力先
  gv_filename               VARCHAR2(255);        -- 連携用CSVファイル名
-- 2009/09/09 Ver1.1 delete start by Y.Kuboshima
--  gv_jyugyoin_kbn           VARCHAR2(10);         -- 従業員区分のダミー値
-- 2009/09/09 Ver1.1 delete end by Y.Kuboshima
  gd_process_date           DATE;                 -- 業務日付
  gd_select_start_date      DATE;                 -- 取得開始日
  gd_select_start_datetime  DATE;                 -- 取得開始日(時刻 00:00:00)
  gd_select_end_date        DATE;                 -- 取得終了日
  gd_select_end_datetime    DATE;                 -- 取得終了日(時刻 23:59:59)
  gf_file_hand              UTL_FILE.FILE_TYPE;   -- ファイル・ハンドルの宣言
  gv_warn_flg               VARCHAR2(1);          -- 警告フラグ
  gv_run_flg                VARCHAR2(1);          -- 実行フラグ(T:定期、R:随時(リカバリ))
  gv_date_from              VARCHAR2(10);         -- 入力パラメータ：開始日
  gv_date_to                VARCHAR2(10);         -- 入力パラメータ：終了日
  gt_data_tbl               data_tbl;             -- 結合配列の定義
  gv_param_output_flg       VARCHAR2(1);          -- 入力パラメータ出力フラグ(出力前:0、出力後:1)
-- 2016/03/24 Ver1.3 Add Start
  gt_base_applover_tab      g_base_applover_ttype; -- 拠点別承認者
-- 2016/03/24 Ver1.3 Add End
--
  -- ===============================
  -- ユーザー定義グローバルカーソル
  -- ===============================
  -- 社員データ(定期実行時)
  CURSOR get_t_data_cur
  IS
-- 2016/02/24 Ver1.2 Mod Start
--    SELECT   p.person_id AS person_id,                              -- 従業員ID
--             p.employee_number AS employee_number,                  -- 従業員番号
    SELECT   p.employee_number AS employee_number,                  -- 従業員番号
-- 2016/02/24 Ver1.2 Mod End
             p.effective_start_date AS effective_start_date,        -- 入社年月日
             t.actual_termination_date AS actual_termination_date,  -- 退職年月日
             p.per_information18 AS per_information18,              -- 漢字姓
             p.per_information19 AS per_information19,              -- 漢字名
-- 2016/02/24 Ver1.2 Del Start
--             p.last_name AS last_name,                              -- カナ姓
--             p.first_name AS first_name,                            -- カナ名
-- 2016/02/24 Ver1.2 Del End
             p.attribute28 AS attribute28,                          -- 起票部門
             a.ass_attribute2 AS ass_attribute2,                    -- 発令日
             a.ass_attribute17 AS ass_attribute17,                  -- 差分連携用日付(自販機)
             a.assignment_id AS assignment_id,                      -- アサインメントID
             p.last_update_date AS j_update_date,                   -- 従業員マスタ.最終更新日
-- 2016/02/24 Ver1.2 Mod Start
--             a.last_update_date AS a_update_date                    -- アサインメントマスタ.最終更新日
             a.last_update_date AS a_update_date,                   -- アサインメントマスタ.最終更新日
             p.attribute11      AS attribute11,                     -- 職位コード（新）
             p.attribute13      AS attribute13,                     -- 職位コード（旧）
             ( SELECT  SUBSTRB( hlb.address3, 1, 2 )
               FROM    hz_cust_accounts    hcab    -- 顧客マスタ(拠点)
                      ,hz_party_sites      hpsb    -- パーティサイト
                      ,hz_cust_acct_sites  hcasb   -- 顧客サイト
                      ,hz_locations        hlb     -- 顧客事業所
               WHERE  hcab.account_number      = p.attribute28
               AND    hcab.customer_class_code = cv_customer_class_code_1 --拠点
               AND    hcab.cust_account_id     = hcasb.cust_account_id
               AND    hcasb.party_site_id      = hpsb.party_site_id
               AND    hpsb.location_id         = hlb.location_id
             )                  AS area_code                         -- 地区コード
-- 2016/02/24 Ver1.2 Mod End
    FROM     per_periods_of_service t,
             per_all_assignments_f a,
             per_all_people_f p,
             (SELECT   pp.person_id AS person_id,
                       MAX(pp.effective_start_date) as effective_start_date
              FROM     per_all_people_f pp
              WHERE    pp.current_emp_or_apl_flag = 'Y'
              GROUP BY pp.person_id) pp
    WHERE    pp.person_id = p.person_id
    AND      pp.effective_start_date = p.effective_start_date
-- 2009/09/09 Ver1.1 modify start by Y.Kuboshima
--    AND      (NVL(p.attribute3,' ') > gv_jyugyoin_kbn OR NVL(p.attribute3,' ') < gv_jyugyoin_kbn)
    AND      p.attribute3 IN (cv_jyugyoin_kbn_1, cv_jyugyoin_kbn_3)
-- 2009/09/09 Ver1.1 modify end by Y.Kuboshima
    AND      (a.ass_attribute17 IS NULL
             OR TO_CHAR(p.last_update_date,'YYYYMMDD HH24:MI:SS') > a.ass_attribute17
             OR TO_CHAR(a.last_update_date,'YYYYMMDD HH24:MI:SS') > a.ass_attribute17)
    AND      p.person_id = a.person_id
    AND      p.effective_start_date = a.effective_start_date
    AND      a.period_of_service_id = t.period_of_service_id
    ORDER BY p.employee_number
  ;
  -- 社員データ(随時(リカバリ)実行時)
  CURSOR get_r_data_cur
  IS
-- 2016/02/24 Ver1.2 Mod Start
--    SELECT   p.person_id AS person_id,                              -- 従業員ID
--             p.employee_number AS employee_number,                  -- 従業員番号
    SELECT   p.employee_number AS employee_number,                  -- 従業員番号
-- 2016/02/24 Ver1.2 Mod End
             p.effective_start_date AS effective_start_date,        -- 入社年月日
             t.actual_termination_date AS actual_termination_date,  -- 退職年月日
             p.per_information18 AS per_information18,              -- 漢字姓
             p.per_information19 AS per_information19,              -- 漢字名
-- 2016/02/24 Ver1.2 Del Start
--             p.last_name AS last_name,                              -- カナ姓
--             p.first_name AS first_name,                            -- カナ名
-- 2016/02/24 Ver1.2 Del End
             p.attribute28 AS attribute28,                          -- 起票部門
             a.ass_attribute2 AS ass_attribute2,                    -- 発令日
             a.ass_attribute17 AS ass_attribute17,                  -- 差分連携用日付(自販機)
             a.assignment_id AS assignment_id,                      -- アサインメントID
             p.last_update_date AS j_update_date,                   -- 従業員マスタ.最終更新日
-- 2016/02/24 Ver1.2 Mod Start
--             a.last_update_date AS a_update_date                    -- アサインメントマスタ.最終更新日
             a.last_update_date AS a_update_date,                   -- アサインメントマスタ.最終更新日
             p.attribute11      AS attribute11,                     -- 職位コード（新）
             p.attribute13      AS attribute13,                     -- 職位コード（旧）
             ( SELECT  SUBSTRB( hlb.address3, 1, 2 )
               FROM    hz_cust_accounts    hcab    -- 顧客マスタ(拠点)
                      ,hz_party_sites      hpsb    -- パーティサイト
                      ,hz_cust_acct_sites  hcasb   -- 顧客サイト
                      ,hz_locations        hlb     -- 顧客事業所
               WHERE  hcab.account_number      = p.attribute28
               AND    hcab.customer_class_code = cv_customer_class_code_1 --拠点
               AND    hcab.cust_account_id     = hcasb.cust_account_id
               AND    hcasb.party_site_id      = hpsb.party_site_id
               AND    hpsb.location_id         = hlb.location_id
             )                  AS area_code                         -- 地区コード
-- 2016/02/24 Ver1.2 Mod End
    FROM     per_periods_of_service t,
             per_all_assignments_f a,
             per_all_people_f p,
             (SELECT   pp.person_id AS person_id,
                       MAX(pp.effective_start_date) as effective_start_date
              FROM     per_all_people_f pp
              WHERE    pp.current_emp_or_apl_flag = 'Y'
              GROUP BY pp.person_id) pp
    WHERE    pp.person_id = p.person_id
    AND      pp.effective_start_date = p.effective_start_date
-- 2009/09/09 Ver1.1 modify start by Y.Kuboshima
--    AND      (NVL(p.attribute3,' ') > gv_jyugyoin_kbn OR NVL(p.attribute3,' ') < gv_jyugyoin_kbn)
    AND      p.attribute3 IN (cv_jyugyoin_kbn_1, cv_jyugyoin_kbn_3)
-- 2009/09/09 Ver1.1 modify end by Y.Kuboshima
    AND      (((gd_select_start_datetime <= p.last_update_date) AND (p.last_update_date <= gd_select_end_datetime))
             OR ((gd_select_start_datetime <= a.last_update_date) AND (a.last_update_date <= gd_select_end_datetime)))
    AND      p.person_id = a.person_id
    AND      p.effective_start_date = a.effective_start_date
    AND      a.period_of_service_id = t.period_of_service_id
    ORDER BY p.employee_number
  ;
-- 2016/03/24 Ver1.3 Add Start
  -- 拠点承認者データ
  CURSOR get_base_approver_cur(
     id_issue_date     DATE
    ,iv_base_code      VARCHAR2
  )
  IS
  SELECT xev.employee_number  employee_number
  FROM   xxcso_employees_v2   xev
        ,fnd_lookup_values flv
  WHERE  (
           (
             (TO_DATE(xev.issue_date, cv_date_format_yyyymmdd) <= TRUNC(id_issue_date))
             AND
             (xev.work_base_code_new = iv_base_code)
           )
           OR
           (
             (TO_DATE(xev.issue_date, cv_date_format_yyyymmdd) > TRUNC(id_issue_date))
             AND
             (xev.work_base_code_old = iv_base_code)
           )
         )
   AND   flv.lookup_type  =  cv_approve_code
   AND   flv.lookup_code  =  CASE
                               WHEN (TO_DATE(xev.issue_date, cv_date_format_yyyymmdd) <= TRUNC(id_issue_date)) THEN
                                 xev.position_code_new
                               ELSE
                                 xev.position_code_old
                             END
   AND   flv.enabled_flag =  cv_y
   AND   flv.language     =  ct_user_lang
   AND   gd_process_date  BETWEEN flv.start_date_active
                          AND     NVL( flv.end_date_active, gd_process_date )
  ORDER BY
         CASE
           WHEN (TO_DATE(xev.issue_date, cv_date_format_yyyymmdd) <= TRUNC(id_issue_date)) THEN
             xev.position_code_new
           ELSE
             xev.position_code_old
         END
        ,xev.employee_number
  ;
-- 2016/03/24 Ver1.3 Add End
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
    --自販機差分連携用社員データテーブルロック用(定期実行時)
    CURSOR get_t_dispenser_cur IS
-- 2016/02/24 Ver1.2 Mod Start
--      SELECT   d.person_id
--      FROM     xxcmm_out_people_d_dispenser d,
--               per_periods_of_service t,
      SELECT   a.person_id
      FROM     per_periods_of_service t,
-- 2016/02/24 Ver1.2 Mod End
               per_all_assignments_f a,
               per_all_people_f p
-- 2009/09/09 Ver1.1 modify start by Y.Kuboshima
--      WHERE    (NVL(p.attribute3,' ') > gv_jyugyoin_kbn OR NVL(p.attribute3,' ') < gv_jyugyoin_kbn)
      WHERE    p.attribute3 IN (cv_jyugyoin_kbn_1, cv_jyugyoin_kbn_3)
-- 2009/09/09 Ver1.1 modify end by Y.Kuboshima
      AND      (a.ass_attribute17 IS NULL
               OR TO_CHAR(p.last_update_date,'YYYYMMDD HH24:MI:SS') > a.ass_attribute17
               OR TO_CHAR(a.last_update_date,'YYYYMMDD HH24:MI:SS') > a.ass_attribute17)
      AND      p.person_id = a.person_id
      AND      p.effective_start_date = a.effective_start_date
      AND      a.period_of_service_id = t.period_of_service_id
-- 2009/09/09 Ver1.1 modify start by Y.Kuboshima
--      AND      p.person_id = d.person_id
--      FOR UPDATE NOWAIT;
-- 2016/02/24 Ver1.2 Mod Start
--      AND      p.person_id = d.person_id(+)
--      FOR UPDATE OF a.person_id, d.person_id NOWAIT;
      FOR UPDATE OF a.person_id NOWAIT;
-- 2016/02/24 Ver1.2 Mod End
-- 2009/09/09 Ver1.1 modify end by Y.Kuboshima
    --自販機差分連携用社員データテーブルロック用(随時(リカバリ)実行時)
    CURSOR get_r_dispenser_cur IS
-- 2016/02/24 Ver1.2 Mod Start
--      SELECT   d.person_id
--      FROM     xxcmm_out_people_d_dispenser d,
--               per_periods_of_service t,
      SELECT   a.person_id
      FROM     per_periods_of_service t,
-- 2016/02/24 Ver1.2 Mod End
               per_all_assignments_f a,
               per_all_people_f p
-- 2009/09/09 Ver1.1 modify start by Y.Kuboshima
--      WHERE    (NVL(p.attribute3,' ') > gv_jyugyoin_kbn OR NVL(p.attribute3,' ') < gv_jyugyoin_kbn)
      WHERE    p.attribute3 IN (cv_jyugyoin_kbn_1, cv_jyugyoin_kbn_3)
-- 2009/09/09 Ver1.1 modify end by Y.Kuboshima
      AND      (((gd_select_start_datetime <= p.last_update_date) AND (p.last_update_date <= gd_select_end_datetime))
               OR ((gd_select_start_datetime <= a.last_update_date) AND (a.last_update_date <= gd_select_end_datetime)))
      AND      p.person_id = a.person_id
      AND      p.effective_start_date = a.effective_start_date
      AND      a.period_of_service_id = t.period_of_service_id
-- 2009/09/09 Ver1.1 modify start by Y.Kuboshima
--      AND      p.person_id = d.person_id
--      FOR UPDATE NOWAIT;
-- 2016/02/24 Ver1.2 Mod Start
--      AND      p.person_id = d.person_id(+)
--      FOR UPDATE OF a.person_id, d.person_id NOWAIT;
      FOR UPDATE OF a.person_id NOWAIT;
-- 2016/02/24 Ver1.2 Mod End
-- 2009/09/09 Ver1.1 modify end by Y.Kuboshima
    --
-- 2009/09/09 Ver1.1 delete start by Y.Kuboshima
-- 自販機差分連携様社員データテーブルロックカーソルでアサイメントマスタをロックするので削除
--    --アサインメントマスタロック用(定期実行時)
--    CURSOR get_t_assignment_cur IS
--      SELECT   a.assignment_id
--      FROM     per_periods_of_service t,
--               per_all_assignments_f a,
--               per_all_people_f p
--      WHERE    (NVL(p.attribute3,' ') > gv_jyugyoin_kbn OR NVL(p.attribute3,' ') < gv_jyugyoin_kbn)
--      AND      (a.ass_attribute17 IS NULL
--               OR TO_CHAR(p.last_update_date,'YYYYMMDD HH24:MI:SS') > a.ass_attribute17
--               OR TO_CHAR(a.last_update_date,'YYYYMMDD HH24:MI:SS') > a.ass_attribute17)
--      AND      p.person_id = a.person_id
--      AND      p.effective_start_date = a.effective_start_date
--      AND      a.period_of_service_id = t.period_of_service_id
--      FOR UPDATE NOWAIT;
--    --アサインメントマスタロック用(随時(リカバリ)実行時)
--    CURSOR get_r_assignment_cur IS
--      SELECT   a.assignment_id
--      FROM     per_periods_of_service t,
--               per_all_assignments_f a,
--               per_all_people_f p
--      WHERE    (NVL(p.attribute3,' ') > gv_jyugyoin_kbn OR NVL(p.attribute3,' ') < gv_jyugyoin_kbn)
--      AND      (((gd_select_start_datetime <= p.last_update_date) AND (p.last_update_date <= gd_select_end_datetime))
--               OR ((gd_select_start_datetime <= a.last_update_date) AND (a.last_update_date <= gd_select_end_datetime)))
--      AND      p.person_id = a.person_id
--      AND      p.effective_start_date = a.effective_start_date
--      AND      a.period_of_service_id = t.period_of_service_id
--      FOR UPDATE NOWAIT;
-- 2009/09/09 Ver1.1 delete start by Y.Kuboshima-
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
    -- 入力パラメータ指定チェック(終了日のみの指定はエラー)
    IF ((gv_date_from IS NULL) AND (gv_date_to IS NOT NULL)) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cmm                               -- 'XXCMM'
                      ,iv_name         => cv_msg_00218                                 -- 入力パラメータ指定エラー
                     );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- 実行フラグの取得
    IF (gv_date_from IS NULL) THEN
      -- 定期実行時
      gv_run_flg := cv_flg_t;
    ELSE
      -- 随時(リカバリ)時
      gv_run_flg := cv_flg_r;
    END IF;
--
    -- =========================================================
    --  業務日付の取得
    -- =========================================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
    IF (gd_process_date IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cmm           -- 'XXCMM'
                      ,iv_name         => cv_msg_00018             -- 業務処理日付取得エラー
                     );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ============================================================
    --  固定出力(入力パラメータ部)
    -- ============================================================
    -- 入力パラメータ
    lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cmm         -- 'XXCMM'
                    ,iv_name         => cv_msg_00038           -- 入力パラメータ出力メッセージ
                    ,iv_token_name1  => cv_tkn_param           -- トークン(PARAM)
                    ,iv_token_value1 => cv_tkn_param3          -- パラメータ名(入力パラメータ)
                    ,iv_token_name2  => cv_tkn_value           -- トークン(VALUE)
                    ,iv_token_value2 => gv_date_from || '.' || gv_date_to
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
                    ,iv_token_value1 => cv_tkn_param1          -- パラメータ名(開始日)
                    ,iv_token_name2  => cv_tkn_value           -- トークン(VALUE)
                    ,iv_token_value2 => gv_date_from
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_errmsg
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => lv_errmsg
    );
    IF (gv_run_flg = cv_flg_t) THEN
      -- 定期実行時
      -- 取得終了日
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cmm         -- 'XXCMM'
                      ,iv_name         => cv_msg_00038           -- 入力パラメータ出力メッセージ
                      ,iv_token_name1  => cv_tkn_param           -- トークン(PARAM)
                      ,iv_token_value1 => cv_tkn_param2          -- パラメータ名(終了日)
                      ,iv_token_name2  => cv_tkn_value           -- トークン(VALUE)
                      ,iv_token_value2 => gv_date_to
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
    ELSE
      -- 随時(リカバリ)時
      gd_select_start_date := TO_DATE(gv_date_from,'YYYY/MM/DD');
      gd_select_start_datetime := TO_DATE(gv_date_from || '00:00:00','YYYY/MM/DD HH24:MI:SS');
      IF (gv_date_to IS NULL) THEN
        -- 業務日付をセット
        gd_select_end_date := gd_process_date;
      ELSE
        gd_select_end_date := TO_DATE(gv_date_to,'YYYY/MM/DD');
      END IF;
      gd_select_end_datetime := TO_DATE(TO_CHAR(gd_select_end_date,'YYYY/MM/DD') || ' 23:59:59','YYYY/MM/DD HH24:MI:SS');
      -- 取得終了日
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cmm         -- 'XXCMM'
                      ,iv_name         => cv_msg_00038           -- 入力パラメータ出力メッセージ
                      ,iv_token_name1  => cv_tkn_param           -- トークン(PARAM)
                      ,iv_token_value1 => cv_tkn_param2          -- パラメータ名(終了日)
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
    END IF;
--
    -- ============================================================
    --  プロファイルの取得
    -- ============================================================
    gv_filepath := fnd_profile.value(cv_filepath);
    IF (gv_filepath IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cmm           -- 'XXCMM'
                      ,iv_name         => cv_msg_00002             -- プロファイル取得エラー
                      ,iv_token_name1  => cv_tkn_profile           -- トークン(NG_PROFILE)
                      ,iv_token_value1 => cv_tkn_filepath_nm       -- プロファイル名(CSVファイル出力先)
                     );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    gv_filename := fnd_profile.value(cv_filename);
    IF (gv_filename IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cmm           -- 'XXCMM'
                      ,iv_name         => cv_msg_00002             -- プロファイル取得エラー
                      ,iv_token_name1  => cv_tkn_profile           -- トークン(NG_PROFILE)
                      ,iv_token_value1 => cv_tkn_filename_nm       -- プロファイル名(CSVファイル名)
                     );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
-- 2009/09/09 Ver1.1 delete start by Y.Kuboshima
--    gv_jyugyoin_kbn := fnd_profile.value(cv_jyugyoin_kbn);
--    IF (gv_jyugyoin_kbn IS NULL) THEN
--      lv_errmsg := xxccp_common_pkg.get_msg(
--                       iv_application  => cv_msg_kbn_cmm           -- 'XXCMM'
--                      ,iv_name         => cv_msg_00002             -- プロファイル取得エラー
--                      ,iv_token_name1  => cv_tkn_profile           -- トークン(NG_PROFILE)
--                      ,iv_token_value1 => cv_tkn_jyugoin_kbn_nm    -- プロファイル名(従業員区分のダミー値)
--                     );
--      lv_errbuf := lv_errmsg;
--      RAISE global_api_expt;
--    END IF;
-- 2009/09/09 Ver1.1 delete end by Y.Kuboshima
    -- ============================================================
    --  固定出力(I/Fファイル名部)
    -- ============================================================
    lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp             -- 'XXCCP'
                    ,iv_name         => cv_msg_05102               -- ファイル名出力メッセージ
                    ,iv_token_name1  => cv_tkn_filename            -- トークン(FILE_NAME)
                    ,iv_token_value1 => gv_filename                -- ファイル名
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_errmsg
    );
    -- 空行挿入
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
                         iv_application  => cv_msg_kbn_cmm         -- 'XXCMM'
                        ,iv_name         => cv_msg_00003           -- ファイルパス不正エラー
                       );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    -- =========================================================
    --  自販機差分連携用社員データテーブルの行ロック
    -- =========================================================
    BEGIN
      IF (gv_run_flg = cv_flg_t) THEN
        -- 定期実行時
        OPEN get_t_dispenser_cur;
        CLOSE get_t_dispenser_cur;
      ELSE
        -- 随時(リカバリ)時
        OPEN get_r_dispenser_cur;
        CLOSE get_r_dispenser_cur;
      END IF;
    EXCEPTION
      -- テーブルロックエラー
      WHEN lock_expt THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cmm         -- 'XXCMM'
                        ,iv_name         => cv_msg_00008           -- ロック取得NGメッセージ
                        ,iv_token_name1  => cv_tkn_table           -- トークン(NG_TABLE)
-- 2009/09/09 Ver1.1 modify start by Y.Kuboshima
--                        ,iv_token_value1 => cv_tkn_table_nm2       -- テーブル名(自販機差分連携用社員データテーブル)
-- 2016/02/24 Ver1.2 Mod Start
--                        ,iv_token_value1 => cv_tkn_table_nm1 || cv_tkn_table_nm2 -- テーブル名(アサイメントマスタ、自販機差分連携用社員データテーブル)
                        ,iv_token_value1 => cv_tkn_table_nm1       -- テーブル名(アサイメントマスタ)
-- 2016/02/24 Ver1.2 Mod End
-- 2009/09/09 Ver1.1 modify end by Y.Kuboshima
                       );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
-- 2009/09/09 Ver1.1 delete start by Y.Kuboshima
--    -- =========================================================
--    --  アサインメントマスタの行ロック
--    -- =========================================================
--    BEGIN
--      IF (gv_run_flg = cv_flg_t) THEN
--        -- 定期実行時
--        OPEN get_t_assignment_cur;
--        CLOSE get_t_assignment_cur;
--      ELSE
--        -- 随時(リカバリ)時
--        OPEN get_r_assignment_cur;
--        CLOSE get_r_assignment_cur;
--      END IF;
--    EXCEPTION
--      -- テーブルロックエラー
--      WHEN lock_expt THEN
--        lv_errmsg := xxccp_common_pkg.get_msg(
--                         iv_application  => cv_msg_kbn_cmm         -- 'XXCMM'
--                        ,iv_name         => cv_msg_00008           -- ロック取得NGメッセージ
--                        ,iv_token_name1  => cv_tkn_table           -- トークン(NG_TABLE)
--                        ,iv_token_value1 => cv_tkn_table_nm1       -- テーブル名(アサインメントマスタ)
--                       );
--        lv_errbuf := lv_errmsg;
--        RAISE global_api_expt;
--      WHEN OTHERS THEN
--        RAISE global_api_others_expt;
--    END;
-- 2009/09/09 Ver1.1 delete end by Y.Kuboshima
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
    IF (gv_run_flg = cv_flg_t) THEN
      -- 定期実行時
      OPEN get_t_data_cur;
      <<t_data_loop>>
      LOOP
        FETCH get_t_data_cur BULK COLLECT INTO gt_data_tbl;
        EXIT WHEN get_t_data_cur%NOTFOUND;
      END LOOP t_data_loop;
      CLOSE get_t_data_cur;
    ELSE
      -- 随時(リカバリ)時
      OPEN get_r_data_cur;
      <<r_data_loop>>
      LOOP
        FETCH get_r_data_cur BULK COLLECT INTO gt_data_tbl;
        EXIT WHEN get_r_data_cur%NOTFOUND;
      END LOOP r_data_loop;
      CLOSE get_r_data_cur;
    END IF;
    -- 対象件数をセット
    gn_target_cnt := gt_data_tbl.COUNT;
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
   * Description      : CSVファイル出力プロシージャ(A-4)
   ***********************************************************************************/
  PROCEDURE output_csv(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_csv';     -- プログラム名
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
    cv_flg_m            CONSTANT VARCHAR2(1)  := 'M';                -- 処理フラグ(M:未処理)
    cv_flg_s            CONSTANT VARCHAR2(1)  := 'S';                -- 処理フラグ(S:処理済み(リカバリ分))
    cv_u                CONSTANT VARCHAR2(1)  := 'U';                -- 処理区分(U:対象)
-- 2016/02/24 Ver1.2 Del Start
--    cv_i                CONSTANT VARCHAR2(1)  := 'I';                -- 対象区分(I:新規登録)
--    cv_a                CONSTANT VARCHAR2(1)  := 'A';                -- 対象区分(A:差分なし)
-- 2016/02/24 Ver1.2 Del End
    cv_o                CONSTANT VARCHAR2(1)  := 'O';                -- 処理区分(O:未対象)
-- 2016/02/24 Ver1.2 Del Start
--    cv_0                CONSTANT VARCHAR2(1)  := '0';                -- 連携フラグ(0:前回連携なし(対象区分：差分なし))
--    cv_1                CONSTANT VARCHAR2(1)  := '1';                -- 連携フラグ(1:前回連携あり(対象区分：更新、新規登録))
-- 2016/02/24 Ver1.2 Del End
-- 2016/02/24 Ver1.2 Add Start
   cv_position_code_0   CONSTANT VARCHAR2(1)  := '0';                -- 役割コード:0
   cv_position_code_1   CONSTANT VARCHAR2(1)  := '1';                -- 役割コード:1
-- 2016/02/24 Ver1.2 Add End
--
    -- *** ローカル変数 ***
    ln_loop_cnt              NUMBER;                   -- ループカウンタ
    lv_csv_text              VARCHAR2(32000);          -- 出力１行分文字列変数
    lv_ret_flg               VARCHAR2(1);              -- 処理フラグ(M:未処理、S:処理済み(リカバリ分))
    lv_chk_employee_number   VARCHAR2(22);             -- 従業員番号重複チェック用
    ln_o_cnt                 NUMBER;                   -- 差分なし、未対象の件数(対象件数に含まない)
    lv_kbn                   VARCHAR2(1);              -- 処理区分
-- 2016/02/24 Ver1.2 Del Start
--    lv_end_date              VARCHAR2(8);              -- 適用終了日
--    ln_stop_flg              NUMBER(1);                -- 利用停止フラグ
-- 2016/02/24 Ver1.2 Del End
    lv_skip_flg              VARCHAR2(1);              -- スキップフラグ用
-- 2016/02/24 Ver1.2 Add Start
    lv_del_flg               VARCHAR2(1);                               -- 削除フラグ
    lv_approve_flg           VARCHAR2(1);                               -- 承認者コード存在フラグ
    lv_position_code_flg     VARCHAR2(1);                               -- 役職コード
    lt_position_code         fnd_lookup_values.lookup_code%TYPE;        -- 職位コード
-- 2016/03/24 Ver1.3 Del Start
--    lt_position_code_new     xxcso_employees_v2.position_code_new%TYPE; -- 職位コード（新）
--    lt_position_code_old     xxcso_employees_v2.position_code_old%TYPE; -- 職位コード（旧）
-- 2016/03/24 Ver1.3 Del End
    ld_announce_date_check   DATE;                                      -- 発令日判断用日付
    ln_authorizer_count      NUMBER;                                    -- 承認者数
-- 2016/02/24 Ver1.2 Add End
-- 2016/02/24 Ver1.2 Del Start
--    -- 自販機差分連携用社員データ格納用
--    lv_employee_number       xxcmm_out_people_d_dispenser.employee_number%TYPE;
--    ld_effective_start_date  xxcmm_out_people_d_dispenser.effective_start_date%TYPE;
--    lv_per_information18     xxcmm_out_people_d_dispenser.per_information18%TYPE;
--    lv_per_information19     xxcmm_out_people_d_dispenser.per_information19%TYPE;
--    lv_last_name             xxcmm_out_people_d_dispenser.last_name%TYPE;
--    lv_first_name            xxcmm_out_people_d_dispenser.first_name%TYPE;
--    lv_location_code         xxcmm_out_people_d_dispenser.location_code%TYPE;
--    lv_announce_date         xxcmm_out_people_d_dispenser.announce_date%TYPE;
--    lv_out_flag              xxcmm_out_people_d_dispenser.out_flag%TYPE;
-- 2016/02/24 Ver1.2 Del End
-- 2016/02/24 Ver1.2 Add Start
    lt_approve_employee      per_people_f.employee_number%TYPE;         -- 承認者
-- 2016/02/24 Ver1.2 Add End
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
    -- 初期化
    ln_o_cnt := 0;
    -- 定期実行時
    IF (gv_run_flg = cv_flg_t) THEN
      gd_select_end_date := gd_process_date;
      lv_ret_flg := cv_flg_m;
-- 2016/02/24 Ver1.2 Add Start
      -- 発令日判断用日付に業務日付+1をセット
      ld_announce_date_check := gd_process_date + 1;
    -- 随時(リカバリ)実行時
    ELSE
      -- 発令日判断用日付に業務日付をセット
      ld_announce_date_check := gd_process_date;
-- 2016/02/24 Ver1.2 Add End
    END IF;
    --
    <<out_loop>>
    FOR ln_loop_cnt IN 1..gn_target_cnt LOOP
      IF (gv_run_flg = cv_flg_r) THEN
        --========================================
        -- リカバリ実行時、処理フラグ取得(A-3-1)
        --========================================
        IF ((gd_select_start_datetime  <= gt_data_tbl(ln_loop_cnt).j_update_date)
          AND (gt_data_tbl(ln_loop_cnt).j_update_date <= gd_select_end_datetime)
          AND ((gt_data_tbl(ln_loop_cnt).ass_attribute17 IS NULL)
          OR  (TO_CHAR(gt_data_tbl(ln_loop_cnt).j_update_date,'YYYYMMDD HH24:MI:SS') > gt_data_tbl(ln_loop_cnt).ass_attribute17)))
        THEN
          -- 処理フラグに「未処理」をセット
          lv_ret_flg := cv_flg_m;
        ELSIF ((gd_select_start_datetime  <= gt_data_tbl(ln_loop_cnt).a_update_date)
          AND (gt_data_tbl(ln_loop_cnt).a_update_date <= gd_select_end_datetime)
          AND ((gt_data_tbl(ln_loop_cnt).ass_attribute17 IS NULL)
          OR  (TO_CHAR(gt_data_tbl(ln_loop_cnt).a_update_date,'YYYYMMDD HH24:MI:SS') > gt_data_tbl(ln_loop_cnt).ass_attribute17)))
        THEN
          -- 処理フラグに「未処理」をセット
          lv_ret_flg := cv_flg_m;
        ELSE
          -- 処理フラグに「処理済み」をセット
          lv_ret_flg := cv_flg_s;
        END IF;
      END IF;
-- 2016/02/24 Ver1.2 Del Start
--      IF (lv_ret_flg = cv_flg_m) THEN
--        --========================================
--        -- 処理フラグが「未処理」の場合
--        --   過去連携データ取得(A-3-2)
--        --   レコード存在チェック(A-3-3)
--        --========================================
--        BEGIN
--          SELECT   employee_number,          -- 従業員番号
--                   effective_start_date,     -- 入社年月日
--                   per_information18,        -- 漢字姓
--                   per_information19,        -- 漢字名
--                   last_name,                -- カナ姓
--                   first_name,               -- カナ名
--                   location_code,            -- 起票部門
--                   announce_date             -- 発令日
--          INTO     lv_employee_number,
--                   ld_effective_start_date,
--                   lv_per_information18,
--                   lv_per_information19,
--                   lv_last_name,
--                   lv_first_name,
--                   lv_location_code,
--                   lv_announce_date
--          FROM     xxcmm_out_people_d_dispenser
--          WHERE    person_id = gt_data_tbl(ln_loop_cnt).person_id;
-- 2016/02/24 Ver1.2 Del End
          --
          --========================================
          -- 差異チェック(A-3-4)
          --========================================
          IF (gt_data_tbl(ln_loop_cnt).actual_termination_date IS NULL) THEN
            -- 退職データ以外
-- 2016/02/24 Ver1.2 Mod Start
--            IF ((gt_data_tbl(ln_loop_cnt).employee_number <> lv_employee_number)             -- 従業員番号
--              OR (gt_data_tbl(ln_loop_cnt).effective_start_date <> ld_effective_start_date)  -- 入社年月日
--              OR (gt_data_tbl(ln_loop_cnt).per_information18 <> lv_per_information18)        -- 漢字姓
--              OR (gt_data_tbl(ln_loop_cnt).per_information19 <> lv_per_information19)        -- 漢字名
--              OR (gt_data_tbl(ln_loop_cnt).last_name <> lv_last_name)                        -- カナ姓
--              OR (gt_data_tbl(ln_loop_cnt).first_name <> lv_first_name)                      -- カナ名
--              OR (gt_data_tbl(ln_loop_cnt).attribute28 <> lv_location_code)                  -- 起票部門
--              OR (gt_data_tbl(ln_loop_cnt).ass_attribute2 <> lv_announce_date))              -- 発令日
--            THEN
--              -- 処理区分に更新をセット
--              lv_kbn := cv_u;
--            ELSE
--              -- 処理区分に差分なしをセット
--              lv_kbn := cv_a;
--            END IF;
            -- 処理区分に対象をセット
            lv_kbn := cv_u;
-- 2016/02/24 Ver1.2 Mod End
          ELSE
            -- 退職データ
            IF ((gd_select_end_date >= gt_data_tbl(ln_loop_cnt).actual_termination_date)
              AND (gt_data_tbl(ln_loop_cnt).ass_attribute17 <= TO_CHAR(gt_data_tbl(ln_loop_cnt).actual_termination_date,'YYYYMMDD') || '23:59:59'))
            THEN
              -- 処理区分に対象をセット
              lv_kbn := cv_u;
            ELSE
              -- 処理区分に未対象をセット
              lv_kbn := cv_o;
            END IF;
          END IF;
-- 2016/02/24 Ver1.2 Del Start
--        EXCEPTION
--          WHEN NO_DATA_FOUND THEN
--            -- 処理区分に新規登録をセット
--            lv_kbn := cv_i;
--          WHEN OTHERS THEN
--            RAISE global_api_others_expt;
--        END;
-- 2016/02/24 Ver1.2 Del End
        -- 処理区分が未対象データの場合、次レコードの読み込み
        IF (lv_kbn = cv_o) THEN
          --===============================================
          -- 処理区分が「未対象」の場合
          -- 未対象件数のカウント
          --===============================================
          ln_o_cnt := ln_o_cnt + 1;
        ELSE
-- 2016/02/24 Ver1.2 Del Start
--          -- 処理区分が新規登録、更新の場合、CSVファイル出力・自販機差分連携用社員データ更新を実行
--          IF (lv_kbn = cv_a) THEN
--            --===============================================
--            -- 処理区分が「差分なし」の場合
--            -- 未対象件数のカウント
--            -- 自販機差分連携用社員データの更新(A-5)
--            --  (連携フラグに0:連携なしをセット)
--            -- 差分連携用日付更新(アサインメントマスタ)(A-6)
--            --===============================================
--            ln_o_cnt := ln_o_cnt + 1;
--            --===============================================
--            -- 自販機差分連携用社員データ更新(A-5)
--            --===============================================
--            BEGIN
--              UPDATE   xxcmm_out_people_d_dispenser
--              SET      out_flag = cv_0
--              WHERE    person_id = gt_data_tbl(ln_loop_cnt).person_id;
--            EXCEPTION
--              WHEN OTHERS THEN
--                lv_errmsg := xxcmn_common_pkg.get_msg(
--                                 iv_application  => cv_msg_kbn_cmm                           -- 'XXCMM'
--                                ,iv_name         => cv_msg_00032                             -- 自販機差分連携用社員テーブル更新エラー
--                                ,iv_token_name1  => cv_tkn_word                              -- トークン(NG_WORD)
--                                ,iv_token_value1 => cv_tkn_word1                             -- NG_WORD
--                                ,iv_token_name2  => cv_tkn_data                              -- トークン(NG_DATA)
--                                ,iv_token_value2 => gt_data_tbl(ln_loop_cnt).employee_number -- NG_WORDのDATA
--                               );
--                lv_errbuf := lv_errmsg;
--                RAISE global_api_expt;
--            END;
--            --===============================================
--            -- 差分連携用日付更新(アサインメントマスタ)(A-6)
--            --===============================================
--            BEGIN
--              UPDATE   per_all_assignments_f
--              SET      ass_attribute17 = TO_CHAR(SYSDATE,'YYYYMMDD HH24:MI:SS')
--              WHERE    assignment_id = gt_data_tbl(ln_loop_cnt).assignment_id
--              AND      effective_start_date = gt_data_tbl(ln_loop_cnt).effective_start_date;
--            EXCEPTION
--              WHEN OTHERS THEN
--                lv_errmsg := xxcmn_common_pkg.get_msg(
--                                 iv_application  => cv_msg_kbn_cmm                           -- 'XXCMM'
--                                ,iv_name         => cv_msg_00029                             -- アサインメントマスタ更新エラー
--                                ,iv_token_name1  => cv_tkn_word                              -- トークン(NG_WORD)
--                                ,iv_token_value1 => cv_tkn_word1                             -- NG_WORD
--                                ,iv_token_name2  => cv_tkn_data                              -- トークン(NG_DATA)
--                                ,iv_token_value2 => gt_data_tbl(ln_loop_cnt).employee_number -- NG_WORDのDATA
--                               );
--                lv_errbuf := lv_errmsg;
--                RAISE global_api_expt;
--            END;
--          ELSE
-- 2016/02/24 Ver1.2 Del End
            --===============================================
            -- 従業員番号重複チェック(A-3-5)
            --  (重複データが存在した場合、警告メッセージを表示し、処理継続)
            -- 禁則文字チェック(A-3-6)
            --  対象:従業員番号、氏名(漢字)、起票部門
            --  禁則文字が存在した場合、警告メッセージを表示してスキップにカウントし、次レコードの読み込み
            --  禁則文字が存在しなかった場合、処理継続
            -- 差分連携用日付更新(アサインメントマスタ)(A-6)
            -- 正常件数のカウント
            --===============================================
            -- スキップフラグをクリア
            lv_skip_flg := '0';
            --========================================
            -- 従業員番号重複チェック(A-3-5)
            --========================================
            -- 従業員番号が重複している場合、警告メッセージを表示
            IF (lv_chk_employee_number = SUBSTRB(gt_data_tbl(ln_loop_cnt).employee_number,1,5)) THEN
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
                               iv_application  => cv_msg_kbn_cmm                             -- 'XXCMM'
                              ,iv_name         => cv_msg_00209                               -- 従業員番号重複メッセージ
                              ,iv_token_name1  => cv_tkn_word                                -- トークン(NG_WORD)
                              ,iv_token_value1 => cv_tkn_word1                               -- NG_WORD
                              ,iv_token_name2  => cv_tkn_data                                -- トークン(NG_DATA)
                              ,iv_token_value2 => gt_data_tbl(ln_loop_cnt).employee_number   -- NG_WORDのDATA
                                                    || cv_tkn_word2
                                                    || SUBSTRB(gt_data_tbl(ln_loop_cnt).per_information18
                                                    || '　'
                                                    || gt_data_tbl(ln_loop_cnt).per_information19,1,20)
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
            -- 禁則文字チェック(A-3-6)
            --========================================
            -- 従業員番号
            IF (xxccp_common_pkg2.chk_moji(gt_data_tbl(ln_loop_cnt).employee_number,cv_chk_cd) = FALSE) THEN
              IF (gv_warn_flg = '0') THEN
                -- 警告フラグにオンをセット
                gv_warn_flg := '1';
                -- 空行挿入(入力パラメータの下)
                FND_FILE.PUT_LINE(
                   which  => FND_FILE.LOG
                  ,buff   => ''
                );
              END IF;
              -- スキップフラグをオンにセット
              lv_skip_flg := '1';
              lv_errmsg := xxccp_common_pkg.get_msg(
                               iv_application  => cv_msg_kbn_cmm                             -- 'XXCMM'
                              ,iv_name         => cv_msg_00216                               -- 禁則文字存在チェックメッセージ
                              ,iv_token_name1  => cv_tkn_ng_value                            -- トークン(NG_VALUE)
                              ,iv_token_value1 => cv_tkn_value_nm1                           -- NG_VALUE(社員番号)
                              ,iv_token_name2  => cv_tkn_word                                -- トークン(NG_WORD)
                              ,iv_token_value2 => cv_tkn_word1                               -- NG_WORD
                              ,iv_token_name3  => cv_tkn_data                                -- トークン(NG_DATA)
                              ,iv_token_value3 => gt_data_tbl(ln_loop_cnt).employee_number   -- NG_WORDのDATA
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
-- 2016/02/24 Ver1.2 Del Start
--            -- 発令日
--            IF (xxccp_common_pkg2.chk_moji(gt_data_tbl(ln_loop_cnt).ass_attribute2,cv_chk_cd) = FALSE) THEN
--              IF (gv_warn_flg = '0') THEN
--                -- 警告フラグにオンをセット
--                gv_warn_flg := '1';
--                -- 空行挿入(入力パラメータの下)
--                FND_FILE.PUT_LINE(
--                   which  => FND_FILE.LOG
--                  ,buff   => ''
--                );
--              END IF;
--              -- スキップフラグをオンにセット
--              lv_skip_flg := '1';
--              lv_errmsg := xxccp_common_pkg.get_msg(
--                               iv_application  => cv_msg_kbn_cmm                             -- 'XXCMM'
--                              ,iv_name         => cv_msg_00216                               -- 禁則文字存在チェックメッセージ
--                              ,iv_token_name1  => cv_tkn_ng_value                            -- トークン(NG_VALUE)
--                              ,iv_token_value1 => cv_tkn_value_nm2                           -- NG_VALUE(発令日)
--                              ,iv_token_name2  => cv_tkn_word                                -- トークン(NG_WORD)
--                              ,iv_token_value2 => cv_tkn_word1                               -- NG_WORD
--                              ,iv_token_name3  => cv_tkn_data                                -- トークン(NG_DATA)
--                              ,iv_token_value3 => gt_data_tbl(ln_loop_cnt).employee_number   -- NG_WORDのDATA
--                             );
--              FND_FILE.PUT_LINE(
--                 which  => FND_FILE.OUTPUT
--                ,buff   => lv_errmsg
--              );
--              FND_FILE.PUT_LINE(
--                 which  => FND_FILE.LOG
--                ,buff   => lv_errmsg
--              );
--            END IF;
-- 2016/02/24 Ver1.2 Del End
            -- 漢字(姓)
            IF (xxccp_common_pkg2.chk_moji(gt_data_tbl(ln_loop_cnt).per_information18,cv_chk_cd) = FALSE) THEN
              IF (gv_warn_flg = '0') THEN
                -- 警告フラグにオンをセット
                gv_warn_flg := '1';
                -- 空行挿入(入力パラメータの下)
                FND_FILE.PUT_LINE(
                   which  => FND_FILE.LOG
                  ,buff   => ''
                );
              END IF;
              -- スキップフラグをオンにセット
              lv_skip_flg := '1';
              lv_errmsg := xxccp_common_pkg.get_msg(
                               iv_application  => cv_msg_kbn_cmm                             -- 'XXCMM'
                              ,iv_name         => cv_msg_00216                               -- 禁則文字存在チェックメッセージ
                              ,iv_token_name1  => cv_tkn_ng_value                            -- トークン(NG_VALUE)
                              ,iv_token_value1 => cv_tkn_value_nm3                           -- NG_VALUE(漢字(姓))
                              ,iv_token_name2  => cv_tkn_word                                -- トークン(NG_WORD)
                              ,iv_token_value2 => cv_tkn_word1                               -- NG_WORD
                              ,iv_token_name3  => cv_tkn_data                                -- トークン(NG_DATA)
                              ,iv_token_value3 => gt_data_tbl(ln_loop_cnt).employee_number   -- NG_WORDのDATA
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
            -- 漢字(名)
            IF (xxccp_common_pkg2.chk_moji(gt_data_tbl(ln_loop_cnt).per_information19,cv_chk_cd) = FALSE) THEN
              IF (gv_warn_flg = '0') THEN
                -- 警告フラグにオンをセット
                gv_warn_flg := '1';
                -- 空行挿入(入力パラメータの下)
                FND_FILE.PUT_LINE(
                   which  => FND_FILE.LOG
                  ,buff   => ''
                );
              END IF;
              -- スキップフラグをオンにセット
              lv_skip_flg := '1';
              lv_errmsg := xxccp_common_pkg.get_msg(
                               iv_application  => cv_msg_kbn_cmm                             -- 'XXCMM'
                              ,iv_name         => cv_msg_00216                               -- 禁則文字存在チェックメッセージ
                              ,iv_token_name1  => cv_tkn_ng_value                            -- トークン(NG_VALUE)
                              ,iv_token_value1 => cv_tkn_value_nm6                           -- NG_VALUE(漢字(名))
                              ,iv_token_name2  => cv_tkn_word                                -- トークン(NG_WORD)
                              ,iv_token_value2 => cv_tkn_word1                               -- NG_WORD
                              ,iv_token_name3  => cv_tkn_data                                -- トークン(NG_DATA)
                              ,iv_token_value3 => gt_data_tbl(ln_loop_cnt).employee_number   -- NG_WORDのDATA
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
-- 2016/02/24 Ver1.2 Del Start
--            -- カナ(姓)
--            IF (xxccp_common_pkg2.chk_moji(gt_data_tbl(ln_loop_cnt).last_name,cv_chk_cd) = FALSE) THEN
--              IF (gv_warn_flg = '0') THEN
--                -- 警告フラグにオンをセット
--                gv_warn_flg := '1';
--                -- 空行挿入(入力パラメータの下)
--                FND_FILE.PUT_LINE(
--                   which  => FND_FILE.LOG
--                  ,buff   => ''
--                );
--              END IF;
--              -- スキップフラグをオンにセット
--              lv_skip_flg := '1';
--              lv_errmsg := xxccp_common_pkg.get_msg(
--                               iv_application  => cv_msg_kbn_cmm                             -- 'XXCMM'
--                              ,iv_name         => cv_msg_00216                               -- 禁則文字存在チェックメッセージ
--                              ,iv_token_name1  => cv_tkn_ng_value                            -- トークン(NG_VALUE)
--                              ,iv_token_value1 => cv_tkn_value_nm4                           -- NG_VALUE(カナ(姓))
--                              ,iv_token_name2  => cv_tkn_word                                -- トークン(NG_WORD)
--                              ,iv_token_value2 => cv_tkn_word1                               -- NG_WORD
--                              ,iv_token_name3  => cv_tkn_data                                -- トークン(NG_DATA)
--                              ,iv_token_value3 => gt_data_tbl(ln_loop_cnt).employee_number   -- NG_WORDのDATA
--                             );
--              FND_FILE.PUT_LINE(
--                 which  => FND_FILE.OUTPUT
--                ,buff   => lv_errmsg
--              );
--              FND_FILE.PUT_LINE(
--                 which  => FND_FILE.LOG
--                ,buff   => lv_errmsg
--              );
--            END IF;
--            -- カナ(名)
--            IF (xxccp_common_pkg2.chk_moji(gt_data_tbl(ln_loop_cnt).first_name,cv_chk_cd) = FALSE) THEN
--              IF (gv_warn_flg = '0') THEN
--                -- 警告フラグにオンをセット
--                gv_warn_flg := '1';
--                -- 空行挿入(入力パラメータの下)
--                FND_FILE.PUT_LINE(
--                   which  => FND_FILE.LOG
--                  ,buff   => ''
--                );
--              END IF;
--              -- スキップフラグをオンにセット
--              lv_skip_flg := '1';
--              lv_errmsg := xxccp_common_pkg.get_msg(
--                               iv_application  => cv_msg_kbn_cmm                             -- 'XXCMM'
--                              ,iv_name         => cv_msg_00216                               -- 禁則文字存在チェックメッセージ
--                              ,iv_token_name1  => cv_tkn_ng_value                            -- トークン(NG_VALUE)
--                              ,iv_token_value1 => cv_tkn_value_nm7                           -- NG_VALUE(カナ(名))
--                              ,iv_token_name2  => cv_tkn_word                                -- トークン(NG_WORD)
--                              ,iv_token_value2 => cv_tkn_word1                               -- NG_WORD
--                              ,iv_token_name3  => cv_tkn_data                                -- トークン(NG_DATA)
--                              ,iv_token_value3 => gt_data_tbl(ln_loop_cnt).employee_number   -- NG_WORDのDATA
--                             );
--              FND_FILE.PUT_LINE(
--                 which  => FND_FILE.OUTPUT
--                ,buff   => lv_errmsg
--              );
--              FND_FILE.PUT_LINE(
--                 which  => FND_FILE.LOG
--                ,buff   => lv_errmsg
--              );
--            END IF;
-- 2016/02/24 Ver1.2 Del End
            -- 起票部門
            IF (xxccp_common_pkg2.chk_moji(gt_data_tbl(ln_loop_cnt).attribute28,cv_chk_cd) = FALSE) THEN
              IF (gv_warn_flg = '0') THEN
                -- 警告フラグにオンをセット
                gv_warn_flg := '1';
                -- 空行挿入(入力パラメータの下)
                FND_FILE.PUT_LINE(
                   which  => FND_FILE.LOG
                  ,buff   => ''
                );
              END IF;
              -- スキップフラグをオンにセット
              lv_skip_flg := '1';
              lv_errmsg := xxccp_common_pkg.get_msg(
                               iv_application  => cv_msg_kbn_cmm                             -- 'XXCMM'
                              ,iv_name         => cv_msg_00216                               -- 禁則文字存在チェックメッセージ
                              ,iv_token_name1  => cv_tkn_ng_value                            -- トークン(NG_VALUE)
                              ,iv_token_value1 => cv_tkn_value_nm5                           -- NG_VALUE(起票部門)
                              ,iv_token_name2  => cv_tkn_word                                -- トークン(NG_WORD)
                              ,iv_token_value2 => cv_tkn_word1                               -- NG_WORD
                              ,iv_token_name3  => cv_tkn_data                                -- トークン(NG_DATA)
                              ,iv_token_value3 => gt_data_tbl(ln_loop_cnt).employee_number   -- NG_WORDのDATA
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
            IF (lv_skip_flg = '1') THEN
              --========================================
              -- 禁則文字が存在した場合
              -- スキップ件数のカウント
              --========================================
              gn_warn_cnt := gn_warn_cnt + 1;
            ELSE
              --========================================
              -- 禁則文字が存在しなかった場合
              -- 妥当性チェック(A-3-7)
              -- 承認者チェック(A-3-8)
              -- CSVファイル出力(A-4)
              -- 差分連携用日付更新(アサインメントマスタ)(A-6)
              -- 正常件数のカウント
              --========================================
-- 2016/02/24 Ver1.2 Del Start
--              -- 適用終了日の取得
--              IF (gt_data_tbl(ln_loop_cnt).ass_attribute2 = TO_CHAR(gt_data_tbl(ln_loop_cnt).effective_start_date,'YYYYMMDD')) THEN
--                lv_end_date := cv_99999999;
--              ELSE
--                lv_end_date := NULL;
--              END IF;
-- 2016/02/24 Ver1.2 Del End
              -- 削除フラグの取得
              IF (gt_data_tbl(ln_loop_cnt).actual_termination_date IS NULL) THEN
-- 2016/02/24 Ver1.2 Mod Start
--                ln_stop_flg := cv_flg_0;
                lv_del_flg := cv_del_flg_0;
-- 2016/02/24 Ver1.2 Mod End
              ELSE
                IF ((gd_select_end_date >= gt_data_tbl(ln_loop_cnt).actual_termination_date)
                  AND ((gt_data_tbl(ln_loop_cnt).ass_attribute17 IS NULL)
                  OR (gt_data_tbl(ln_loop_cnt).ass_attribute17 <= TO_CHAR(gt_data_tbl(ln_loop_cnt).actual_termination_date,'YYYYMMDD') || '23:59:59')))
                THEN
-- 2016/02/24 Ver1.2 Mod Start
--                  ln_stop_flg := cv_flg_1;
                  lv_del_flg := cv_del_flg_1;
-- 2016/02/24 Ver1.2 Mod End
                ELSE
-- 2016/02/24 Ver1.2 Mod Start
--                  ln_stop_flg := cv_flg_0;
                  lv_del_flg := cv_del_flg_0;
-- 2016/02/24 Ver1.2 Mod End
                END IF;
              END IF;
-- 2016/02/24 Ver1.2 Add Start
--
              --========================================
              -- 妥当性チェック(A-3-7)
              --========================================
              -- 発令日<=発令日判断用日付の時、職位コード（新）をセット
              IF (TO_DATE(gt_data_tbl(ln_loop_cnt).ass_attribute2, cv_date_format_yyyymmdd) <= TRUNC(ld_announce_date_check)) THEN
                lt_position_code     := gt_data_tbl(ln_loop_cnt).attribute11;
-- 2016/03/24 Ver1.3 Del Start
--                lt_position_code_new := gt_data_tbl(ln_loop_cnt).attribute11;
--                lt_position_code_old := gt_data_tbl(ln_loop_cnt).attribute11;
-- 2016/03/24 Ver1.3 Del End
              -- 発令日>発令日判断用日付の時、職位コード（旧）をセット
              ELSIF (TO_DATE(gt_data_tbl(ln_loop_cnt).ass_attribute2, cv_date_format_yyyymmdd) > TRUNC(ld_announce_date_check)) THEN
                lt_position_code     := gt_data_tbl(ln_loop_cnt).attribute13;
-- 2016/03/24 Ver1.3 Del Start
--                lt_position_code_new := gt_data_tbl(ln_loop_cnt).attribute13;
--                lt_position_code_old := gt_data_tbl(ln_loop_cnt).attribute13;
-- 2016/03/24 Ver1.3 Del End
              END IF;
--
              -- 初期化
              lv_approve_flg      := cv_n;
--
              -- 承認者コード存在チェック
              BEGIN
                SELECT cv_y  approve_flg
                INTO   lv_approve_flg
                FROM   fnd_lookup_values flv  -- 参照タイプ
                WHERE  flv.lookup_type  =  cv_approve_code
                AND    flv.lookup_code  =  lt_position_code
                AND    flv.enabled_flag =  cv_y
                AND    flv.language     =  ct_user_lang
                AND    gd_process_date  BETWEEN flv.start_date_active
                                        AND     NVL( flv.end_date_active, gd_process_date )
                ;
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  -- 取得できない場合、役職コード：0
                  lv_position_code_flg := cv_position_code_0;
                WHEN OTHERS THEN
                  RAISE global_api_others_expt;
              END;
--
              --========================================
              -- 承認者チェック(A-3-8)
              --========================================
              IF ( lv_approve_flg = cv_y ) THEN
-- 2016/03/24 Ver1.3 Mod Start
--                BEGIN
--                  SELECT COUNT(0) authorizer_count
--                  INTO   ln_authorizer_count
--                  FROM   xxcso_employees_v2  xev
--                  WHERE  (
--                          (
--                           (TO_DATE(xev.issue_date, cv_date_format_yyyymmdd) <= TRUNC(ld_announce_date_check))
--                           AND
--                           (xev.work_base_code_new = gt_data_tbl(ln_loop_cnt).attribute28)
--                           AND
--                           (xev.position_code_new  = lt_position_code_new)
--                          )
--                          OR
--                          (
--                           (TO_DATE(xev.issue_date, cv_date_format_yyyymmdd) > TRUNC(ld_announce_date_check))
--                           AND
--                           (xev.work_base_code_old = gt_data_tbl(ln_loop_cnt).attribute28)
--                           AND
--                           (xev.position_code_old  = lt_position_code_old)
--                          )
--                         )
--                  ;
--                EXCEPTION
--                  WHEN OTHERS THEN
--                  RAISE global_api_others_expt;
--                END;
----
--                -- 承認者数が複数存在する場合
--                IF ( ln_authorizer_count > 1 ) THEN
--                  lv_errmsg := xxccp_common_pkg.get_msg(
--                                   iv_application  => cv_msg_kbn_cmm                             -- 'XXCMM'
--                                  ,iv_name         => cv_msg_00224                               -- 承認者複数警告
--                                  ,iv_token_name1  => cv_tkn_department_code                     -- トークン(DEPARTMENT_CODE)
--                                  ,iv_token_value1 => gt_data_tbl(ln_loop_cnt).attribute28       -- 起票部門
--                                  ,iv_token_name2  => cv_tkn_employee_number                     -- トークン(EMPLOYEE_NUMBER)
--                                  ,iv_token_value2 => gt_data_tbl(ln_loop_cnt).employee_number   -- 従業員番号
--                                 );
--                  FND_FILE.PUT_LINE(
--                     which  => FND_FILE.OUTPUT
--                    ,buff   => lv_errmsg
--                  );
--                  -- 警告フラグにオンをセット
--                  gv_warn_flg := '1';
--                  lv_position_code_flg := cv_position_code_0;
--                ELSE
--                  lv_position_code_flg := cv_position_code_1;
--                END IF;
                -- 既に拠点単位で承認者を取得している場合
                IF ( gt_base_applover_tab.EXISTS(gt_data_tbl(ln_loop_cnt).attribute28) ) THEN
                  -- 承認者の判定
                  IF ( gt_base_applover_tab(gt_data_tbl(ln_loop_cnt).attribute28) = gt_data_tbl(ln_loop_cnt).employee_number ) THEN
                    lv_position_code_flg := cv_position_code_1;
                  ELSE
                    lv_position_code_flg := cv_position_code_0;
                  END IF;
                -- 拠点単位で承認者を取得していない場合
                ELSE
                  -- 拠点の承認者(最上位の職位者)を取得する
                  OPEN get_base_approver_cur(
                     ld_announce_date_check
                    ,gt_data_tbl(ln_loop_cnt).attribute28
                  );
                  FETCH get_base_approver_cur INTO lt_approve_employee;
                  CLOSE get_base_approver_cur;
--
                  -- 拠点の承認者が取得できた場合
                  IF ( lt_approve_employee IS NOT NULL ) THEN
                    -- 配列に承認者を格納
                    gt_base_applover_tab(gt_data_tbl(ln_loop_cnt).attribute28) := lt_approve_employee;
                    -- 承認者の判定
                    IF ( gt_base_applover_tab(gt_data_tbl(ln_loop_cnt).attribute28) = gt_data_tbl(ln_loop_cnt).employee_number ) THEN
                      lv_position_code_flg := cv_position_code_1;
                    ELSE
                      lv_position_code_flg := cv_position_code_0;
                    END IF;
                    -- 初期化
                    lt_approve_employee := NULL;
                  -- 拠点の承認者が取得できない場合
                  ELSE
                    -- メッセージ生成
                    lv_errmsg := xxccp_common_pkg.get_msg(
                                     iv_application  => cv_msg_kbn_cmm                             -- 'XXCMM'
                                    ,iv_name         => cv_msg_00224                               -- 承認者複数警告
                                    ,iv_token_name1  => cv_tkn_employee_number                     -- トークン(EMPLOYEE_NUMBER)
                                    ,iv_token_value1 => gt_data_tbl(ln_loop_cnt).employee_number   -- 従業員番号
                                    ,iv_token_name2  => cv_tkn_department_code                     -- トークン(DEPARTMENT_CODE)
                                    ,iv_token_value2 => gt_data_tbl(ln_loop_cnt).attribute28       -- 起票部門
                                   );
                    -- メッセージ出力
                    FND_FILE.PUT_LINE(
                       which  => FND_FILE.OUTPUT
                      ,buff   => lv_errmsg
                    );
                    --
                    gv_warn_flg          := '1';                -- 警告フラグにオンをセット
                    lv_position_code_flg := cv_position_code_0; -- (HOST)役職コード:0(承認者以外)
                  END IF;
                END IF;
-- 2016/03/24 Ver1.3 Mod End
              END IF;
--
-- 2016/02/24 Ver1.2 Add End
-- 2016/02/24 Ver1.2 Mod Start
--              lv_csv_text := cv_enclosed || cv_riyou_kbn || cv_enclosed || cv_delimiter      -- 利用者区分
--                || cv_enclosed || SUBSTRB(gt_data_tbl(ln_loop_cnt).employee_number,1,5)      -- ログインID
--                || cv_enclosed || cv_delimiter
--                || SUBSTRB(gt_data_tbl(ln_loop_cnt).ass_attribute2,1,8) || cv_delimiter      -- 適用開始日
--                || lv_end_date || cv_delimiter                                               -- 適用終了日
--                || cv_enclosed || SUBSTRB(gt_data_tbl(ln_loop_cnt).per_information18         -- 従業員氏名
--                || '　' || gt_data_tbl(ln_loop_cnt).per_information19,1,20)
--                || cv_enclosed || cv_delimiter
--                || cv_enclosed || SUBSTRB(gt_data_tbl(ln_loop_cnt).last_name                 -- 従業員氏名(カナ)
--                || '　' || gt_data_tbl(ln_loop_cnt).first_name,1,15)
--                || cv_enclosed || cv_delimiter
--                || cv_enclosed || SUBSTRB(gt_data_tbl(ln_loop_cnt).attribute28,1,4)          -- 拠点（部門）コード
--                || cv_enclosed || cv_delimiter
--                || cv_enclosed || cv_team_cd || cv_enclosed || cv_delimiter                  -- チームコード
--                || NULL || cv_delimiter                                                      -- 権限1
--                || NULL || cv_delimiter                                                      -- 権限2
--                || NULL || cv_delimiter                                                      -- 権限3
--                || NULL || cv_delimiter                                                      -- 権限4
--                || NULL || cv_delimiter                                                      -- 権限5
--                || NULL || cv_delimiter                                                      -- 権限6
--                || NULL || cv_delimiter                                                      -- 権限7
--                || ln_stop_flg || cv_delimiter                                               -- 利用停止フラグ
--                || cv_enclosed || NULL || cv_enclosed || cv_delimiter                        -- 作成担当者コード
--                || cv_enclosed || NULL || cv_enclosed || cv_delimiter                        -- 作成部署コード
--                || cv_enclosed || NULL || cv_enclosed || cv_delimiter                        -- 作成プログラムID
--                || cv_enclosed || cv_tanto_cd || cv_enclosed || cv_delimiter                 -- 更新担当者コード
--                || cv_enclosed || cv_busyo_cd || cv_enclosed || cv_delimiter                 -- 更新部署コード
--                || cv_enclosed || cv_program_id || cv_enclosed || cv_delimiter               -- 更新プログラムID
--                || NULL || cv_delimiter                                                      -- 作成日時時分秒
--                || NULL                                                                      -- 更新日時時分秒
              lv_csv_text := cv_enclosed || SUBSTRB(gt_data_tbl(ln_loop_cnt).employee_number,1,5)
                || cv_enclosed || cv_delimiter                                                    -- 営業担当CD
                || cv_enclosed || SUBSTRB(gt_data_tbl(ln_loop_cnt).per_information18
                || '　' || gt_data_tbl(ln_loop_cnt).per_information19,1,20)
                || cv_enclosed || cv_delimiter                                                    -- 営業担当名
                || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- (HOST)担当者名カナ
                || cv_enclosed || gt_data_tbl(ln_loop_cnt).area_code
                || cv_enclosed || cv_delimiter                                                    -- 支店CD
                || cv_enclosed || SUBSTRB(gt_data_tbl(ln_loop_cnt).attribute28,1,4)
                || cv_enclosed || cv_delimiter                                                    -- 営業所CD
                || cv_enclosed || cv_department_flg_1 || cv_enclosed || cv_delimiter              -- (HOST)１課・２課フラグ
                || cv_enclosed || cv_team_cd || cv_enclosed || cv_delimiter                       -- (HOST)課コード
                || cv_enclosed || lv_position_code_flg || cv_enclosed || cv_delimiter             -- (HOST)役職コード
                || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- 性別区分
                || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- (HOST)入社年月日
                || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- (HOST)セキュリティエリア
                || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- (HOST)パスワード
                || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- ホストデータ登録年月日６桁
                || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- ホストデータ更新年月日６桁
                || cv_enclosed || lv_del_flg || cv_enclosed || cv_delimiter                       -- 削除フラグ
                || cv_enclosed || NULL || cv_enclosed                                             -- 移動日
-- 2016/02/24 Ver1.2 Mod End
              ;
              BEGIN
                -- ファイル書き込み
                UTL_FILE.PUT_LINE(gf_file_hand,lv_csv_text);
              EXCEPTION
                -- ファイルアクセス権限エラー
                WHEN UTL_FILE.INVALID_OPERATION THEN
                  lv_errmsg := xxcmn_common_pkg.get_msg(
                                   iv_application  => cv_msg_kbn_cmm                         -- 'XXCMM'
                                  ,iv_name         => cv_msg_00007                           -- ファイルアクセス権限エラー
                                 );
                  lv_errbuf := lv_errmsg;
                  RAISE global_api_expt;
                --
                -- CSVデータ出力エラー
                WHEN UTL_FILE.WRITE_ERROR THEN
                  lv_errmsg := xxcmn_common_pkg.get_msg(
                                   iv_application  => cv_msg_kbn_cmm                         -- 'XXCMM'
                                  ,iv_name         => cv_msg_00009                           -- CSVデータ出力エラー
                                  ,iv_token_name1  => cv_tkn_word                            -- トークン(NG_WORD)
                                  ,iv_token_value1 => cv_tkn_word1                           -- NG_WORD
                                  ,iv_token_name2  => cv_tkn_data                            -- トークン(NG_DATA)
                                  ,iv_token_value2 => gt_data_tbl(ln_loop_cnt).employee_number -- NG_WORDのDATA
                                 );
                  lv_errbuf := lv_errmsg;
                  RAISE global_api_expt;
                WHEN OTHERS THEN
                  RAISE global_api_others_expt;
              END;
-- 2016/02/24 Ver1.2 Del Start
--              --========================================
--              -- 自販機差分連携用社員データ更新(A-5)
--              --========================================
--              BEGIN
--                IF (lv_kbn = cv_i) THEN
--                -- 新規登録
--                  INSERT
--                  INTO     xxcmm_out_people_d_dispenser( person_id                 -- 従業員ID
--                                                      ,employee_number             -- 従業員番号
--                                                      ,effective_start_date        -- 入社年月日
--                                                      ,per_information18           -- 漢字姓
--                                                      ,per_information19           -- 漢字名
--                                                      ,last_name                   -- カナ姓
--                                                      ,first_name                  -- カナ名
--                                                      ,location_code               -- 起票部門
--                                                      ,announce_date               -- 発令日
--                                                      ,out_flag)                   -- 連携フラグ
--                  VALUES   ( gt_data_tbl(ln_loop_cnt).person_id
--                            ,gt_data_tbl(ln_loop_cnt).employee_number
--                            ,gt_data_tbl(ln_loop_cnt).effective_start_date
--                            ,gt_data_tbl(ln_loop_cnt).per_information18
--                            ,gt_data_tbl(ln_loop_cnt).per_information19
--                            ,gt_data_tbl(ln_loop_cnt).last_name
--                            ,gt_data_tbl(ln_loop_cnt).first_name
--                            ,gt_data_tbl(ln_loop_cnt).attribute28
--                            ,gt_data_tbl(ln_loop_cnt).ass_attribute2
--                            ,cv_1);
--                ELSE
--                  -- 更新
--                  UPDATE   xxcmm_out_people_d_dispenser
--                  SET      employee_number = gt_data_tbl(ln_loop_cnt).employee_number,
--                           effective_start_date = gt_data_tbl(ln_loop_cnt).effective_start_date,
--                           per_information18 = gt_data_tbl(ln_loop_cnt).per_information18,
--                           per_information19 = gt_data_tbl(ln_loop_cnt).per_information19,
--                           last_name = gt_data_tbl(ln_loop_cnt).last_name,
--                           first_name = gt_data_tbl(ln_loop_cnt).first_name,
--                           location_code = gt_data_tbl(ln_loop_cnt).attribute28,
--                           announce_date = gt_data_tbl(ln_loop_cnt).ass_attribute2,
--                           out_flag = cv_1
--                  WHERE    person_id = gt_data_tbl(ln_loop_cnt).person_id;
--                END IF;
--              EXCEPTION
--                WHEN OTHERS THEN
--                  lv_errmsg := xxcmn_common_pkg.get_msg(
--                                   iv_application  => cv_msg_kbn_cmm               -- 'XXCMM'
--                                  ,iv_name         => cv_msg_00032                 -- 自販機差分連携用社員テーブル更新エラー
--                                  ,iv_token_name1  => cv_tkn_word                  -- トークン(NG_WORD)
--                                  ,iv_token_value1 => cv_tkn_word1                 -- NG_WORD
--                                  ,iv_token_name2  => cv_tkn_data                  -- トークン(NG_DATA)
--                                  ,iv_token_value2 => gt_data_tbl(ln_loop_cnt).employee_number -- NG_WORDのDATA
--                                 );
--                  lv_errbuf := lv_errmsg;
--                  RAISE global_api_expt;
--              END;
-- 2016/02/24 Ver1.2 Del End
              --===============================================
              -- 差分連携用日付更新(アサインメントマスタ)(A-6)
              --===============================================
-- 2016/02/24 Ver1.2 Mod Start
--              BEGIN
--                UPDATE   per_all_assignments_f
--                SET      ass_attribute17 = TO_CHAR(SYSDATE,'YYYYMMDD HH24:MI:SS')
--                WHERE    assignment_id = gt_data_tbl(ln_loop_cnt).assignment_id
--                AND      effective_start_date = gt_data_tbl(ln_loop_cnt).effective_start_date;
--              EXCEPTION
--                WHEN OTHERS THEN
--                  lv_errmsg := xxcmn_common_pkg.get_msg(
--                                   iv_application  => cv_msg_kbn_cmm               -- 'XXCMM'
--                                  ,iv_name         => cv_msg_00029                 -- アサインメントマスタ更新エラー
--                                  ,iv_token_name1  => cv_tkn_word                  -- トークン(NG_WORD)
--                                  ,iv_token_value1 => cv_tkn_word1                 -- NG_WORD
--                                  ,iv_token_name2  => cv_tkn_data                  -- トークン(NG_DATA)
--                                  ,iv_token_value2 => gt_data_tbl(ln_loop_cnt).employee_number -- NG_WORDのDATA
--                                 );
--                  lv_errbuf := lv_errmsg;
--                  RAISE global_api_expt;
--              END;
              -- 処理フラグ「未処理」の場合
              IF (lv_ret_flg = cv_flg_m) THEN
                BEGIN
                  UPDATE   per_all_assignments_f
                  SET      ass_attribute17 = TO_CHAR(SYSDATE,'YYYYMMDD HH24:MI:SS')
                  WHERE    assignment_id = gt_data_tbl(ln_loop_cnt).assignment_id
                  AND      effective_start_date = gt_data_tbl(ln_loop_cnt).effective_start_date;
                EXCEPTION
                  WHEN OTHERS THEN
                    lv_errmsg := xxcmn_common_pkg.get_msg(
                                     iv_application  => cv_msg_kbn_cmm               -- 'XXCMM'
                                    ,iv_name         => cv_msg_00029                 -- アサインメントマスタ更新エラー
                                    ,iv_token_name1  => cv_tkn_word                  -- トークン(NG_WORD)
                                    ,iv_token_value1 => cv_tkn_word1                 -- NG_WORD
                                    ,iv_token_name2  => cv_tkn_data                  -- トークン(NG_DATA)
                                    ,iv_token_value2 => gt_data_tbl(ln_loop_cnt).employee_number -- NG_WORDのDATA
                                   );
                    lv_errbuf := lv_errmsg;
                    RAISE global_api_expt;
                END;
              END IF;
-- 2016/02/24 Ver1.2 Mod End
              -- 正常件数のカウント
              gn_normal_cnt := gn_normal_cnt + 1;
            END IF;
-- 2016/02/24 Ver1.2 Del Start
--          END IF;
-- 2016/02/24 Ver1.2 Del End
        END IF;
-- 2016/02/24 Ver1.2 Del Start
--      ELSE
--        --==============================================================
--        -- 処理フラグが「処理済み」の場合
--        -- 過去連携データ(連携フラグ)取得(A-3-2)
--        -- 連携フラグが0:連携なしの場合、未対象件数にカウントし、次レコードの読み込み
--        -- 連携フラグが1:連携ありの場合、
--        --  退職年月日に値が入っていた場合、利用停止フラグに「1」をセットし、CSVファイル出力(A-4)
--        --  退職年月日に値が入っていなかった場合、利用停止フラグに「0」をセット、CSVファイル出力(A-4)
--        -- 自販機差分連携用社員データ更新(A-5)
--        --  (連携フラグには1:連携ありをセット)
--        -- 差分連携用日付更新(アサインメントマスタ)(A-6)
--        -- 正常件数のカウント
--        --==============================================================
--        BEGIN
--          SELECT   out_flag          -- 連携フラグ
--          INTO     lv_out_flag
--          FROM     xxcmm_out_people_d_dispenser
--          WHERE    person_id = gt_data_tbl(ln_loop_cnt).person_id;
--        EXCEPTION
--          WHEN NO_DATA_FOUND THEN
--            lv_errmsg := xxcmn_common_pkg.get_msg(
--                             iv_application  => cv_msg_kbn_cmm                               -- 'XXCMM'
--                            ,iv_name         => cv_msg_00217                                 -- 過去連携データ取得エラー
--                            ,iv_token_name1  => cv_tkn_word                                  -- トークン(NG_WORD)
--                            ,iv_token_value1 => cv_tkn_word1                                 -- NG_WORD
--                            ,iv_token_name2  => cv_tkn_data                                  -- トークン(NG_DATA)
--                            ,iv_token_value2 => gt_data_tbl(ln_loop_cnt).employee_number     -- NG_WORDのDATA
--                           );
--            lv_errbuf := lv_errmsg;
--            RAISE global_api_expt;
--          WHEN OTHERS THEN
--            RAISE global_api_others_expt;
--        END;
--        -- 連携フラグが0の場合は前回連携なしのため、次レコードの読み込み
--        IF (lv_out_flag = cv_0) THEN
--          ln_o_cnt := ln_o_cnt + 1;
--        ELSE
--          --===============================================
--          -- 従業員番号重複チェック(A-3-5)
--          --========================================
--          -- 従業員番号が重複している場合、警告メッセージを表示
--          IF (lv_chk_employee_number = SUBSTRB(gt_data_tbl(ln_loop_cnt).employee_number,1,5)) THEN
--            IF (gv_warn_flg = '0') THEN
--              -- 警告フラグにオンをセット
--              gv_warn_flg := '1';
--              -- 空行挿入(入力パラメータの下)
--              FND_FILE.PUT_LINE(
--                 which  => FND_FILE.LOG
--                ,buff   => ''
--              );
--            END IF;
--            lv_errmsg := xxccp_common_pkg.get_msg(
--                             iv_application  => cv_msg_kbn_cmm                             -- 'XXCMM'
--                            ,iv_name         => cv_msg_00209                               -- 従業員番号重複メッセージ
--                            ,iv_token_name1  => cv_tkn_word                                -- トークン(NG_WORD)
--                            ,iv_token_value1 => cv_tkn_word1                               -- NG_WORD
--                            ,iv_token_name2  => cv_tkn_data                                -- トークン(NG_DATA)
--                            ,iv_token_value2 => gt_data_tbl(ln_loop_cnt).employee_number   -- NG_WORDのDATA
--                                                  || cv_tkn_word2
--                                                  || SUBSTRB(gt_data_tbl(ln_loop_cnt).per_information18
--                                                  || '　'
--                                                  || gt_data_tbl(ln_loop_cnt).per_information19,1,20)
--                           );
--            FND_FILE.PUT_LINE(
--               which  => FND_FILE.OUTPUT
--              ,buff   => lv_errmsg
--            );
--            FND_FILE.PUT_LINE(
--               which  => FND_FILE.LOG
--              ,buff   => lv_errmsg
--            );
--          END IF;
--          --========================================
--          -- CSVファイル出力(A-4)
--          --========================================
--          -- 適用終了日の取得
--          IF (gt_data_tbl(ln_loop_cnt).ass_attribute2 = TO_CHAR(gt_data_tbl(ln_loop_cnt).effective_start_date,'YYYYMMDD')) THEN
--            lv_end_date := cv_99999999;
--          ELSE
--            lv_end_date := NULL;
--          END IF;
--          -- 利用停止フラグの取得
--          IF (gt_data_tbl(ln_loop_cnt).actual_termination_date IS NULL) THEN
--            ln_stop_flg := cv_flg_0;
--          ELSE
--            IF (gd_select_end_datetime >= gt_data_tbl(ln_loop_cnt).actual_termination_date) THEN
--              ln_stop_flg := cv_flg_1;
--            ELSE
--              ln_stop_flg := cv_flg_0;
--            END IF;
--          END IF;
--          lv_csv_text := cv_enclosed || cv_riyou_kbn || cv_enclosed || cv_delimiter          -- 利用者区分
--            || cv_enclosed || SUBSTRB(gt_data_tbl(ln_loop_cnt).employee_number,1,5)          -- ログインID
--            || cv_enclosed || cv_delimiter
--            || SUBSTRB(gt_data_tbl(ln_loop_cnt).ass_attribute2,1,8) || cv_delimiter          -- 適用開始日
--            || lv_end_date || cv_delimiter                                                   -- 適用終了日
--            || cv_enclosed || SUBSTRB(gt_data_tbl(ln_loop_cnt).per_information18             -- 従業員氏名
--            || '　' || gt_data_tbl(ln_loop_cnt).per_information19,1,20)
--            || cv_enclosed || cv_delimiter
--            || cv_enclosed || SUBSTRB(gt_data_tbl(ln_loop_cnt).last_name                     -- 従業員氏名（カナ）
--            || '　' || gt_data_tbl(ln_loop_cnt).first_name,1,15)
--            || cv_enclosed || cv_delimiter
--            || cv_enclosed || SUBSTRB(gt_data_tbl(ln_loop_cnt).attribute28,1,4)              -- 拠点（部門）コード
--            || cv_enclosed || cv_delimiter
--            || cv_enclosed || cv_team_cd || cv_enclosed || cv_delimiter                      -- チームコード
--            || NULL || cv_delimiter                                                          -- 権限1
--            || NULL || cv_delimiter                                                          -- 権限2
--            || NULL || cv_delimiter                                                          -- 権限3
--            || NULL || cv_delimiter                                                          -- 権限4
--            || NULL || cv_delimiter                                                          -- 権限5
--            || NULL || cv_delimiter                                                          -- 権限6
--            || NULL || cv_delimiter                                                          -- 権限7
--            || ln_stop_flg || cv_delimiter                                                   -- 利用停止フラグ
--            || cv_enclosed || NULL || cv_enclosed || cv_delimiter                            -- 作成担当者コード
--            || cv_enclosed || NULL || cv_enclosed || cv_delimiter                            -- 作成部署コード
--            || cv_enclosed || NULL || cv_enclosed || cv_delimiter                            -- 作成プログラムID
--            || cv_enclosed || cv_tanto_cd || cv_enclosed || cv_delimiter                     -- 更新担当者コード
--            || cv_enclosed || cv_busyo_cd || cv_enclosed || cv_delimiter                     -- 更新部署コード
--            || cv_enclosed || cv_program_id || cv_enclosed || cv_delimiter                   -- 更新プログラムID
--            || NULL || cv_delimiter                                                          -- 作成日時時分秒
--            || NULL                                                                          -- 更新日時時分秒
--          ;
--          BEGIN
--            -- ファイル書き込み
--            UTL_FILE.PUT_LINE(gf_file_hand,lv_csv_text);
--          EXCEPTION
--            -- ファイルアクセス権限エラー
--            WHEN UTL_FILE.INVALID_OPERATION THEN
--              lv_errmsg := xxcmn_common_pkg.get_msg(
--                               iv_application  => cv_msg_kbn_cmm                             -- 'XXCMM'
--                              ,iv_name         => cv_msg_00007                               -- ファイルアクセス権限エラー
--                             );
--              lv_errbuf := lv_errmsg;
--              RAISE global_api_expt;
--            --
--            -- CSVデータ出力エラー
--            WHEN UTL_FILE.WRITE_ERROR THEN
--              lv_errmsg := xxcmn_common_pkg.get_msg(
--                               iv_application  => cv_msg_kbn_cmm                             -- 'XXCMM'
--                              ,iv_name         => cv_msg_00009                               -- CSVデータ出力エラー
--                              ,iv_token_name1  => cv_tkn_word                                -- トークン(NG_WORD)
--                              ,iv_token_value1 => cv_tkn_word1                               -- NG_WORD
--                              ,iv_token_name2  => cv_tkn_data                                -- トークン(NG_DATA)
--                              ,iv_token_value2 => gt_data_tbl(ln_loop_cnt).employee_number   -- NG_WORDのDATA
--                             );
--              lv_errbuf := lv_errmsg;
--              RAISE global_api_expt;
--            WHEN OTHERS THEN
--              RAISE global_api_others_expt;
--          END;
--          -- 正常件数のカウント
--          gn_normal_cnt := gn_normal_cnt + 1;
--        END IF;
--      END IF;
-- 2016/02/24 Ver1.2 Del End
      lv_chk_employee_number := SUBSTRB(gt_data_tbl(ln_loop_cnt).employee_number,1,5);
    END LOOP u_out_loop;
    -- 対象件数の取得
    gn_target_cnt := gn_target_cnt - ln_o_cnt;
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
    gn_warn_cnt   := 0;
    gn_error_cnt  := 0;
    gv_warn_flg   := '0';
    gv_param_output_flg := '0';
    --
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
    --
    -- =============================================================
    --  初期処理プロシージャ(A-1)
    -- =============================================================
    init(
       lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
    --
    -- =============================================================
    --  社員データ取得プロシージャ(A-2)
    -- =============================================================
    get_people_data(
       lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
    --
    -- =============================================================
    --  CSVファイル出力プロシージャ(A-4)
    -- =============================================================
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
    iv_date_from  IN  VARCHAR2,      --   1.開始日
    iv_date_to    IN  VARCHAR2       --   2.終了日
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
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- スキップ件数メッセージ
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
    -- 入力パラメータの取得、チェック
    -- ===============================================
    gv_date_from := iv_date_from;
    gv_date_to := iv_date_to;
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
      -- 入力パラメータ出力後は、エラーメッセージとの間に空行挿入
      IF (gv_param_output_flg = '1') THEN
        -- 空行挿入
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
      gn_warn_cnt   := 0;
      gn_error_cnt  := 1;
    ELSE
      IF (gv_warn_flg = '1') THEN
        --警告の場合、リターン・コードに警告をセットする
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
    --スキップ件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_skip_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    -- 空行挿入
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
END XXCMM002A02C;
/
