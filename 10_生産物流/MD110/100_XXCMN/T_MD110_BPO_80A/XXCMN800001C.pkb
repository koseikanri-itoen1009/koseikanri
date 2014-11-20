CREATE OR REPLACE PACKAGE BODY xxcmn800001c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2007. All rights reserved.
 *
 * Package Name     : XXCMN800001C(body)
 * Description      : 顧客インタフェース
 * MD.050           : マスタインタフェース T_MD050_BPO_800
 * MD.070           : 顧客インタフェース   T_MD070_BPO_80A
 * Version          : 1.15
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  get_profile            プロファイル取得プロシージャ
 *  set_if_lock            インタフェーステーブルに対するロック取得プロシージャ
 *  set_error_status       エラーが発生した状態にするプロシージャ
 *  set_warn_status        警告が発生した状態にするプロシージャ
 *  init_status            ステータス初期化プロシージャ
 *  is_file_status_nomal   ファイルレベルで正常か状況を確認するファンクション
 *  init_row_status        行レベルステータス初期化プロシージャ
 *  is_row_status_nomal    行レベルで正常か状況を確認するファンクション
 *  is_row_status_warn     行レベルで警告か状況を確認するファンクション
 *  chk_party_id           顧客・パーティマスタの状態を返すファンクション
 *  add_p_report           レポート用(拠点)データを設定するプロシージャ
 *  add_s_report           レポート用(配送先)データを設定するプロシージャ
 *  add_c_report           レポート用(顧客)データを設定するプロシージャ
 *  disp_p_report          レポート用(拠点)データを出力するプロシージャ
 *  disp_s_report          レポート用(配送先)データを出力するプロシージャ
 *  disp_c_report          レポート用(顧客)データを出力するプロシージャ
 *  disp_report            レポート用データを出力するプロシージャ
 *  get_class_code         顧客区分の取得を行うプロシージャ
 *  get_xxcmn_party_if     拠点インタフェースの以前の件数取得を行うプロシージャ
 *  get_xxcmn_site_if      配送先インタフェースの以前の件数取得を行うプロシージャ
 *  get_hz_parties         パーティーマスタの取得を行うプロシージャ
 *  get_hz_cust_accounts   顧客マスタの取得を行うプロシージャ
 *  get_hz_party_sites     パーティーサイトマスタの取得を行うプロシージャ
 *  get_party_num          顧客コードの取得を行うプロシージャ
 *  get_party_id           パーティIDの取得を行うプロシージャ
 *  get_party_site_id      パーティサイトマスタのサイトIDの取得を行うプロシージャ
 *  get_party_site_id_2    パーティサイトマスタのサイトIDの取得を行うプロシージャ
 *  get_site_to_if         パーティサイトマスタのサイトIDの取得を行うプロシージャ
 *  get_site_number        パーティサイトマスタのサイトIDの取得を行うプロシージャ
 *  exists_party_id        パーティIDの取得を行うプロシージャ
 *  exists_xxcmn_site_if   配送先インタフェースの存在チェックを行うプロシージャ
 *  chk_party_status       パーティマスタ・顧客マスタのステータスのチェックを行うプロシージャ
 *  chk_site_status        パーティサイトマスタのステータスのチェックを行うプロシージャ
 *  chk_party_num          顧客コードの存在チェックを行うプロシージャ
 *  chk_party_num_if       顧客コードの存在チェックを行うプロシージャ
 *  exists_party_number    パーティサイトマスタの存在チェックを行うプロシージャ
 *  check_proc_code        操作対象のレコードであることをチェックするプロシージャ
 *  check_base_code        拠点コードチェックを行うプロシージャ
 *  check_party_num        顧客コードのチェックを行うプロシージャ
 *  check_ship_to_code     配送先コードのチェックを行うプロシージャ
 *  proc_xxcmn_party       パーティアドオンマスタの処理を行うプロシージャ
 *  proc_xxcmn_party_site  パーティサイトアドオンマスタの処理を行うプロシージャ
 *  create_party_account   パーティマスタと顧客マスタの登録処理を行うプロシージャ
 *  update_hz_parties      パーティマスタの更新処理を行うプロシージャ
 *  update_hz_cust_accounts顧客マスタの更新処理を行うプロシージャ
 *  insert_hz_party_sites  パーティサイトマスタの登録処理を行うプロシージャ
 *  update_hz_party_sites  パーティサイトマスタの更新処理を行うプロシージャ
 *  proc_party             拠点反映処理を行うプロシージャ
 *  proc_cust              顧客反映処理を行うプロシージャ
 *  proc_site              配送先反映処理を行うプロシージャ
 *  proc_party_main        拠点反映処理の制御を行うプロシージャ
 *  proc_cust_main         顧客反映処理の制御を行うプロシージャ
 *  proc_site_main         配送先反映処理の制御を行うプロシージャ
 *  init_proc              初期処理を行うプロシージャ
 *  term_proc              インタフェースのデータを削除するプロシージャ
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2007/12/11    1.0   Oracle 山根 一浩 初回作成
 *  2008/04/17    1.1   Oracle 山根 一浩 変更要求No61 対応
 *  2008/05/15    1.2   Oracle 山根 一浩 変更要求No66 対応
 *  2008/05/27    1.3   Oracle 丸下 博宣 内部変更要求No122対応
 *  2008/06/23    1.4   Oracle 山根 一浩 不具合No259対応
 *  2008/07/07    1.5   Oracle 山根 一浩 I_S_192対応
 *  2008/08/08    1.6   Oracle 山根 一浩 ST不具合修正
 *  2008/08/18    1.7   Oracle 山根 一浩 変更要求No61 不具合修正対応
 *  2008/08/19    1.8   Oracle 山根 一浩 T_TE110_BPO_130-002 指摘216対応
 *  2008/08/25    1.9   Oracle 山根 一浩 T_S_442,T_S_548対応
 *  2008/10/01    1.10  Oracle 椎名 昭圭 統合障害#291対応
 *  2008/10/07    1.11  Oracle 椎名 昭圭 T_S_550対応
 *  2009/01/09    1.12  Oracle 椎名 昭圭 本番#857対応
 *  2009/02/25    1.13  Oracle 椎名 昭圭 本番#1235対応
 *  2009/04/03    1.14  Oracle 丸下 博宣 本番#1357、1360
 *  2009/10/23    1.15  SCS 丸下 博宣    本番#1670
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  gv_status_normal CONSTANT VARCHAR2(1) := '0';    --正常
  gv_status_warn   CONSTANT VARCHAR2(1) := '1';    --警告
  gv_status_error  CONSTANT VARCHAR2(1) := '2';    --失敗
  gv_sts_cd_normal CONSTANT VARCHAR2(1) := 'C';    --ステータス(正常)
  gv_sts_cd_warn   CONSTANT VARCHAR2(1) := 'G';    --ステータス(警告)
  gv_sts_cd_error  CONSTANT VARCHAR2(1) := 'E';    --ステータス(失敗)
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  gv_msg_dot       CONSTANT VARCHAR2(3) := '.';
  gv_msg_pnt       CONSTANT VARCHAR2(3) := ',';
--
--################################  固定部 END   ##################################
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  gv_out_msg       VARCHAR2(2000);
  gv_sep_msg       VARCHAR2(2000);            -- 区切り文字
  gv_exec_user     VARCHAR2(100);             -- 実行ユーザ名
  gv_conc_name     VARCHAR2(30);              -- 実行コンカレント名
  gv_conc_status   VARCHAR2(30);              -- 実行結果
  gn_target_cnt    NUMBER;                    -- 対象件数
  gn_normal_cnt    NUMBER;                    -- 正常件数
  gn_error_cnt     NUMBER;                    -- エラー件数
  gn_warn_cnt      NUMBER;                    -- スキップ件数
  gn_report_cnt    NUMBER;                    -- レポート件数
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
  check_sub_main_expt         EXCEPTION;     -- サブメインのエラー
  check_base_code_expt        EXCEPTION;     -- 拠点コードのチェックエラー
  check_party_num_expt        EXCEPTION;     -- 顧客コードのチェックエラー
  check_ship_to_code_expt     EXCEPTION;     -- 配送先コードのチェックエラー
--
  lock_expt                   EXCEPTION;     -- ロック取得エラー
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  -- インタフェースデータの操作種別
  gn_proc_insert CONSTANT NUMBER := 1;  -- 登録
  gn_proc_s_ins  CONSTANT NUMBER := 11; -- 登録(拠点紐付き)
  gn_proc_c_ins  CONSTANT NUMBER := 12; -- 登録(顧客紐付き)
--
  gn_proc_update CONSTANT NUMBER := 2;  -- 更新
  gn_proc_s_upd  CONSTANT NUMBER := 21; -- 更新(拠点紐付き)
  gn_proc_c_upd  CONSTANT NUMBER := 22; -- 更新(顧客紐付き)
--
  gn_proc_delete CONSTANT NUMBER := 9;  -- 削除
  gn_proc_s_del  CONSTANT NUMBER := 91; -- 削除/登録(拠点紐付き)
  gn_proc_c_del  CONSTANT NUMBER := 92; -- 削除/登録(顧客紐付き)
  gn_proc_ds_del CONSTANT NUMBER := 93; -- 削除(拠点紐付き)
  gn_proc_dc_del CONSTANT NUMBER := 94; -- 削除(顧客紐付き)
--
  -- 処理状況をあらわすステータス
  gn_data_status_nomal CONSTANT NUMBER := 0; -- 正常
  gn_data_status_error CONSTANT NUMBER := 1; -- 失敗
  gn_data_status_warn  CONSTANT NUMBER := 2; -- 警告
--
  gv_msg_kbn           CONSTANT VARCHAR2(5)   := 'XXCMN';
  gv_party_if_name     CONSTANT VARCHAR2(100) := 'xxcmn_party_if';
  gv_site_if_name      CONSTANT VARCHAR2(100) := 'xxcmn_site_if';
--
  gv_pkg_name          CONSTANT VARCHAR2(100) := 'xxcmn800001c';    --パッケージ名
--
  --メッセージ番号
  gv_msg_80a_001       CONSTANT VARCHAR2(15) := 'APP-XXCMN-00001';  --ユーザー名
  gv_msg_80a_002       CONSTANT VARCHAR2(15) := 'APP-XXCMN-00002';  --コンカレント名
  gv_msg_80a_003       CONSTANT VARCHAR2(15) := 'APP-XXCMN-00003';  --セパレータ
  gv_msg_80a_004       CONSTANT VARCHAR2(15) := 'APP-XXCMN-00005';  --成功データ（見出し）
  gv_msg_80a_005       CONSTANT VARCHAR2(15) := 'APP-XXCMN-00006';  --エラーデータ（見出し）
  gv_msg_80a_006       CONSTANT VARCHAR2(15) := 'APP-XXCMN-00007';  --スキップデータ（見出し）
  gv_msg_80a_007       CONSTANT VARCHAR2(15) := 'APP-XXCMN-00008';  --処理件数
  gv_msg_80a_008       CONSTANT VARCHAR2(15) := 'APP-XXCMN-00009';  --成功件数
  gv_msg_80a_009       CONSTANT VARCHAR2(15) := 'APP-XXCMN-00010';  --エラー件数
  gv_msg_80a_010       CONSTANT VARCHAR2(15) := 'APP-XXCMN-00011';  --スキップ件数
  gv_msg_80a_011       CONSTANT VARCHAR2(15) := 'APP-XXCMN-00012';  --処理ステータス
  gv_msg_80a_012       CONSTANT VARCHAR2(15) := 'APP-XXCMN-00019';  --拠点データ（見出し）
  gv_msg_80a_013       CONSTANT VARCHAR2(15) := 'APP-XXCMN-00020';  --顧客データ（見出し）
  gv_msg_80a_014       CONSTANT VARCHAR2(15) := 'APP-XXCMN-00021';  --配送先データ（見出し）
  gv_msg_80a_015       CONSTANT VARCHAR2(15) := 'APP-XXCMN-10002';  --プロファイル取得エラー
  gv_msg_80a_016       CONSTANT VARCHAR2(15) := 'APP-XXCMN-10018';  --APIエラー(コンカレント)
  gv_msg_80a_017       CONSTANT VARCHAR2(15) := 'APP-XXCMN-10019';  --ロックエラー
  gv_msg_80a_018       CONSTANT VARCHAR2(15) := 'APP-XXCMN-10022';  --テーブル削除エラー
  gv_msg_80a_019       CONSTANT VARCHAR2(15) := 'APP-XXCMN-10021';  --範囲外データ
  gv_msg_80a_020       CONSTANT VARCHAR2(15) := 'APP-XXCMN-10030';  --コンカレント定型エラー
  gv_msg_80a_021       CONSTANT VARCHAR2(15) := 'APP-XXCMN-10118';  --起動時間
  gv_msg_80a_022       CONSTANT VARCHAR2(15) := 'APP-XXCMN-10036';  --データ取得エラー１
--拠点チェック用
  gv_msg_80a_030       CONSTANT VARCHAR2(15) := 'APP-XXCMN-10070';  --更新の存在チェックエラー
  gv_msg_80a_031       CONSTANT VARCHAR2(15) := 'APP-XXCMN-10071';  --削除の存在チェックワーニング
  gv_msg_80a_032       CONSTANT VARCHAR2(15) := 'APP-XXCMN-10072';  --登録の重複チェックエラー
  gv_msg_80a_033       CONSTANT VARCHAR2(15) := 'APP-XXCMN-10073';  --対象外レコード
--顧客チェック用
  gv_msg_80a_034       CONSTANT VARCHAR2(15) := 'APP-XXCMN-10074';  --更新の存在チェックエラー
  gv_msg_80a_035       CONSTANT VARCHAR2(15) := 'APP-XXCMN-10075';  --削除の存在チェックワーニング
  gv_msg_80a_036       CONSTANT VARCHAR2(15) := 'APP-XXCMN-10076';  --登録の重複チェックエラー
--配送先チェック用
  gv_msg_80a_037       CONSTANT VARCHAR2(15) := 'APP-XXCMN-10086';  --更新の存在チェックエラー
  gv_msg_80a_038       CONSTANT VARCHAR2(15) := 'APP-XXCMN-10087';  --削除の存在チェックワーニング
  gv_msg_80a_039       CONSTANT VARCHAR2(15) := 'APP-XXCMN-10088';  --登録の重複チェックエラー
--
  --トークン
  gv_tkn_status        CONSTANT VARCHAR2(15) := 'STATUS';
  gv_tkn_cnt           CONSTANT VARCHAR2(15) := 'CNT';
  gv_tkn_conc          CONSTANT VARCHAR2(15) := 'CONC';
  gv_tkn_user          CONSTANT VARCHAR2(15) := 'USER';
  gv_tkn_time          CONSTANT VARCHAR2(15) := 'TIME';
  gv_tkn_ng_profile    CONSTANT VARCHAR2(15) := 'NG_PROFILE';
  gv_tkn_table         CONSTANT VARCHAR2(15) := 'TABLE';
  gv_tkn_ng_kyoten     CONSTANT VARCHAR2(15) := 'NG_KYOTEN';
  gv_tkn_api_name      CONSTANT VARCHAR2(15) := 'API_NAME';
  gv_tkn_ng_haisou     CONSTANT VARCHAR2(15) := 'NG_HAISOU';
  gv_tkn_ng_kokyaku    CONSTANT VARCHAR2(15) := 'NG_KOKYAKU';
--
  -- 使用DB名
  gv_xxcmn_party_if_name    CONSTANT VARCHAR2(100) := '拠点インタフェース';
  gv_xxcmn_site_if_name     CONSTANT VARCHAR2(100) := '配送先インタフェース';
  gv_hz_parties_name        CONSTANT VARCHAR2(100) := 'パーティマスタ';
  gv_hz_party_sites_name    CONSTANT VARCHAR2(100) := 'パーティサイトマスタ';
  gv_hz_cust_accounts_name  CONSTANT VARCHAR2(100) := '顧客マスタ';
  gv_hz_cust_site_name      CONSTANT VARCHAR2(100) := '顧客所在地マスタ';
  gv_xxcmn_parties_name     CONSTANT VARCHAR2(100) := 'パーティアドオンマスタ';
  gv_xxcmn_party_sites_name CONSTANT VARCHAR2(100) := 'パーティサイトアドオンマスタ';
  gv_hz_cust_site_uses_name CONSTANT VARCHAR2(100) := '顧客使用目的マスタ';
  gv_hz_locations_name      CONSTANT VARCHAR2(100) := '顧客事業所マスタ';
--
  --プロファイル
  gv_prf_max_date      CONSTANT VARCHAR2(15) := 'XXCMN_MAX_DATE';
  gv_prf_min_date      CONSTANT VARCHAR2(15) := 'XXCMN_MIN_DATE';
  gv_prf_module        CONSTANT VARCHAR2(25) := 'HZ_CREATED_BY_MODULE';
  gv_pfr_location_addr CONSTANT VARCHAR2(25) := 'XXCMN_LOCATION_ADDR';
  gv_prf_max_date_name CONSTANT VARCHAR2(50) := 'MAX日付';
  gv_prf_min_date_name CONSTANT VARCHAR2(50) := 'MIN日付';
  gv_prf_module_name   CONSTANT VARCHAR2(25) := '作成元モジュール';
  gv_pfr_location_name CONSTANT VARCHAR2(25) := 'ロケーションアドレス';
--
  gv_mode_on            CONSTANT VARCHAR2(1)  := '0';
  gv_status_on          CONSTANT VARCHAR2(1)  := 'A';    -- 有効
  gv_status_off         CONSTANT VARCHAR2(1)  := 'I';    -- 無効
  gv_validated_flag_on  CONSTANT VARCHAR2(1)  := 'N';    -- 有効
  gv_validated_flag_off CONSTANT VARCHAR2(1)  := 'I';    -- 無効
  gv_primary_flag_on    CONSTANT VARCHAR2(1)  := 'Y';
  gv_primary_flag_off   CONSTANT VARCHAR2(1)  := 'N';    -- 2008/04/17 変更要求No61 対応
--
  gv_meaning_party     CONSTANT VARCHAR2(100) := '拠点';
  gv_meaning_cust      CONSTANT VARCHAR2(100) := '顧客';
  gv_lookup_type       CONSTANT VARCHAR2(100) := 'CUSTOMER CLASS';
--
  gn_data_init    CONSTANT NUMBER := 0;  -- 初期値
  gn_data_nothing CONSTANT NUMBER := 1;  -- データなし
  gn_data_off     CONSTANT NUMBER := 2;  -- データあり(無効)
  gn_data_on      CONSTANT NUMBER := 3;  -- データあり(有効)
  gn_kbn_party    CONSTANT NUMBER := 1;  -- 拠点
  gn_kbn_site     CONSTANT NUMBER := 2;  -- 配送先
  gn_kbn_upd_site CONSTANT NUMBER := 1;  -- 拠点更新
  gn_kbn_del_site CONSTANT NUMBER := 2;  -- 拠点削除
  gn_kbn_upd_cust CONSTANT NUMBER := 3;  -- 顧客更新
  gn_kbn_del_cust CONSTANT NUMBER := 4;  -- 顧客削除
  gn_kbn_flg_on   CONSTANT NUMBER := 1;  -- 有効
  gn_kbn_flg_off  CONSTANT NUMBER := 2;  -- 無効
--
  gv_def_party_num CONSTANT xxcmn_site_if.party_num%TYPE := '000000000';  -- 2008/08/25 Add
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  -- 各マスタへの反映処理に必要なデータを格納するレコード
  TYPE masters_rec IS RECORD(
    tbl_kbn              NUMBER,
    seq_number           xxcmn_party_if.seq_number%TYPE,          -- SEQ番号
    proc_code            NUMBER,                                  -- 更新区分
    k_proc_code          NUMBER,                                  -- 更新区分(元)
    base_code            xxcmn_party_if.base_code%TYPE,           -- 拠点コード
    ship_to_code         xxcmn_site_if.ship_to_code%TYPE,         -- 配送先コード
    party_name           xxcmn_party_if.party_name%TYPE,          -- 拠点名・正式名
    party_short_name     xxcmn_party_if.party_short_name%TYPE,    -- 拠点名・略名
    party_name_alt       xxcmn_party_if.party_name_alt%TYPE,      -- 拠点名・カナ
    party_site_name1     xxcmn_site_if.party_site_name1%TYPE,     -- 配送先名称1
    party_site_name2     xxcmn_site_if.party_site_name2%TYPE,     -- 配送先名称2
    address              xxcmn_party_if.address%TYPE,             -- 住所
    party_site_addr1     xxcmn_site_if.party_site_addr1%TYPE,     -- 配送先住所1
    party_site_addr2     xxcmn_site_if.party_site_addr2%TYPE,     -- 配送先住所2
    zip                  xxcmn_party_if.zip%TYPE,                 -- 郵便番号
    phone                xxcmn_party_if.phone%TYPE,               -- 電話番号
    fax                  xxcmn_party_if.fax%TYPE,                 -- FAX番号
    old_division_code    xxcmn_party_if.old_division_code%TYPE,   -- 旧・本部コード
    new_division_code    xxcmn_party_if.new_division_code%TYPE,   -- 新・本部コード
    party_num            xxcmn_site_if.party_num%TYPE,            -- 顧客コード
    zip2                 xxcmn_party_if.zip2%TYPE,                -- 郵便番号2
    division_start_date  xxcmn_party_if.division_start_date%TYPE, -- 適用開始日（本部コード）
    location_rel_code    xxcmn_party_if.location_rel_code%TYPE,   -- 拠点実績有無区分
    customer_name1       xxcmn_site_if.customer_name1%TYPE,       -- 顧客・漢字1
    customer_name2       xxcmn_site_if.customer_name2%TYPE,       -- 顧客・漢字2
    ship_mng_code        xxcmn_party_if.ship_mng_code%TYPE,       -- 出庫管理元区分
    district_code        xxcmn_party_if.district_code%TYPE,       -- 地区名（本部コード用）
    sale_base_code       xxcmn_site_if.sale_base_code%TYPE,       -- 当月売上拠点コード
    res_sale_base_code   xxcmn_site_if.res_sale_base_code%TYPE,   -- 予約（翌月）売上拠点コード
    warehouse_code       xxcmn_party_if.warehouse_code%TYPE,      -- 倉替対象可否区分
    chain_store          xxcmn_site_if.chain_store%TYPE,          -- 売上チェーン店
    chain_store_name     xxcmn_site_if.chain_store_name%TYPE,     -- 売上チェーン店名
    terminal_code        xxcmn_party_if.terminal_code%TYPE,       -- 端末有無区分
    cal_cust_app_flg     xxcmn_site_if.cal_cust_app_flg%TYPE,     -- 中止客申請フラグ
    direct_ship_code     xxcmn_site_if.direct_ship_code%TYPE,     -- 直送区分
    shift_judg_flg       xxcmn_site_if.shift_judg_flg%TYPE,       -- 移行判定フラグ
    spare                xxcmn_party_if.spare%TYPE,               -- 予備
    --パーティマスタ
    p_party_id           hz_parties.party_id%TYPE,                -- パーティーID
    validated_flag       hz_parties.validated_flag%TYPE,          -- 有効フラグ
    party_number         hz_parties.party_number%TYPE,            -- 組織番号
    obj_party_number     hz_parties.object_version_number%TYPE,   -- オブジェクトバージョン番号
    --顧客マスタ
    cust_account_id      hz_cust_accounts.cust_account_id%TYPE,   -- 顧客ID
    c_party_id           hz_cust_accounts.party_id%TYPE,          -- パーティーID
    status               hz_cust_accounts.status%TYPE,            -- 有効ステータス
    obj_cust_number      hz_cust_accounts.object_version_number%TYPE, -- オブジェクトバージョン番号
    --パーティサイトマスタ
    party_site_id        hz_party_sites.party_site_id%TYPE,       -- パーティサイトID
    location_id          hz_party_sites.location_id%TYPE,         -- ロケーションID
    site_status          hz_party_sites.status%TYPE,              -- ステータス
    obj_site_number      hz_party_sites.object_version_number%TYPE,
    --顧客所在地マスタ
    cust_acct_site_id    hz_cust_acct_sites_all.cust_acct_site_id%TYPE,
    obj_acct_number      hz_cust_acct_sites_all.object_version_number%TYPE,
--
    --顧客事業所マスタ
    hzl_location_id      hz_locations.location_id%TYPE,                 -- 2008/08/25 Add
    hzl_obj_number       hz_locations.object_version_number%TYPE,       -- 2008/08/25 Add
-- 現在のデータ以前での件数
    -- 出庫管理元区分=0
    row_o_ins_cnt        NUMBER,                               -- 登録件数
    row_o_upd_cnt        NUMBER,                               -- 更新件数
    row_o_del_cnt        NUMBER,                               -- 削除件数
    -- 出庫管理元区分<>0
    row_z_ins_cnt        NUMBER,                               -- 登録件数
    row_z_upd_cnt        NUMBER,                               -- 更新件数
    row_z_del_cnt        NUMBER,                               -- 削除件数
    -- 顧客が同一
    row_c_ins_cnt        NUMBER,                               -- 登録件数
    row_c_upd_cnt        NUMBER,                               -- 更新件数
    row_c_del_cnt        NUMBER,                               -- 削除件数
    -- 配送先が同一
    row_s_ins_cnt        NUMBER,                               -- 登録件数
    row_s_upd_cnt        NUMBER,                               -- 更新件数
    row_s_del_cnt        NUMBER,                               -- 削除件数
    -- 顧客=NULL
    row_n_ins_cnt        NUMBER,                               -- 登録件数
    row_n_upd_cnt        NUMBER,                               -- 更新件数
    row_n_del_cnt        NUMBER,                               -- 削除件数
    -- 顧客<>NULL
    row_m_ins_cnt        NUMBER,                               -- 登録件数
    row_m_upd_cnt        NUMBER,                               -- 更新件数
    row_m_del_cnt        NUMBER                                -- 削除件数
  );
  -- 各マスタへ反映するデータを格納する結合配列
  TYPE masters_tbl IS TABLE OF masters_rec INDEX BY PLS_INTEGER;
--
  -- 出力するログを格納するレコード
  TYPE report_rec IS RECORD(
    seq_number           xxcmn_party_if.seq_number%TYPE,          -- SEQ番号
    proc_code            NUMBER,                                  -- 更新区分
    k_proc_code          NUMBER,                                  -- 更新区分
    base_code            xxcmn_party_if.base_code%TYPE,           -- 拠点コード
    ship_to_code         xxcmn_site_if.ship_to_code%TYPE,         -- 配送先コード
    party_name           xxcmn_party_if.party_name%TYPE,          -- 拠点名・正式名
    party_short_name     xxcmn_party_if.party_short_name%TYPE,    -- 拠点名・略名
    party_name_alt       xxcmn_party_if.party_name_alt%TYPE,      -- 拠点名・カナ
    party_site_name1     xxcmn_site_if.party_site_name1%TYPE,     -- 配送先名称1
    party_site_name2     xxcmn_site_if.party_site_name2%TYPE,     -- 配送先名称2
    address              xxcmn_party_if.address%TYPE,             -- 住所
    party_site_addr1     xxcmn_site_if.party_site_addr1%TYPE,     -- 配送先住所1
    party_site_addr2     xxcmn_site_if.party_site_addr2%TYPE,     -- 配送先住所2
    zip                  xxcmn_party_if.zip%TYPE,                 -- 郵便番号
    phone                xxcmn_party_if.phone%TYPE,               -- 電話番号
    fax                  xxcmn_party_if.fax%TYPE,                 -- FAX番号
    old_division_code    xxcmn_party_if.old_division_code%TYPE,   -- 旧・本部コード
    new_division_code    xxcmn_party_if.new_division_code%TYPE,   -- 新・本部コード
    party_num            xxcmn_site_if.party_num%TYPE,            -- 顧客コード
    zip2                 xxcmn_party_if.zip2%TYPE,                -- 郵便番号2
    division_start_date  xxcmn_party_if.division_start_date%TYPE, -- 適用開始日（本部コード）
    location_rel_code    xxcmn_party_if.location_rel_code%TYPE,   -- 拠点実績有無区分
    customer_name1       xxcmn_site_if.customer_name1%TYPE,       -- 顧客・漢字1
    customer_name2       xxcmn_site_if.customer_name2%TYPE,       -- 顧客・漢字2
    ship_mng_code        xxcmn_party_if.ship_mng_code%TYPE,       -- 出庫管理元区分
    district_code        xxcmn_party_if.district_code%TYPE,       -- 地区名（本部コード用）
    sale_base_code       xxcmn_site_if.sale_base_code%TYPE,       -- 当月売上拠点コード
    res_sale_base_code   xxcmn_site_if.res_sale_base_code%TYPE,   -- 予約（翌月）売上拠点コード
    warehouse_code       xxcmn_party_if.warehouse_code%TYPE,      -- 倉替対象可否区分
    chain_store          xxcmn_site_if.chain_store%TYPE,          -- 売上チェーン店
    chain_store_name     xxcmn_site_if.chain_store_name%TYPE,     -- 売上チェーン店名
    terminal_code        xxcmn_party_if.terminal_code%TYPE,       -- 端末有無区分
    cal_cust_app_flg     xxcmn_site_if.cal_cust_app_flg%TYPE,     -- 中止客申請フラグ
    direct_ship_code     xxcmn_site_if.direct_ship_code%TYPE,     -- 直送区分
    shift_judg_flg       xxcmn_site_if.shift_judg_flg%TYPE,       -- 移行判定フラグ
    spare                xxcmn_party_if.spare%TYPE,               -- 予備
    row_level_status     NUMBER,                                  -- 0.正常,1.失敗,2.警告
    -- 反映先テーブルフラグ(0:未 1:済)
    hps_flg              NUMBER,                                  --パーティマスタ
    hpss_flg             NUMBER,                                  --パーティサイトマスタ
    hca_flg              NUMBER,                                  --顧客マスタ
    hcas_flg             NUMBER,                                  --顧客所在地マスタ
    xps_flg              NUMBER,                                  --パーティアドオンマスタ
    xpss_flg             NUMBER,                                  --パーティサイトアドオンマスタ
    hcsu_flg             NUMBER,                                  --顧客使用目的マスタ
-- 2008/08/25 Add
    hzl_flg              NUMBER,                                  --顧客事業所マスタ
--
    message              VARCHAR2(1000)
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
  gv_min_date            VARCHAR2(10);                               -- 最小日付
  gv_max_date            VARCHAR2(10);                               -- 最大日付
  gv_created_by_module   VARCHAR2(50);                               -- 作成モジュール名
  gv_location_addr       VARCHAR2(50);                               -- ロケーションアドレス
  gv_customer_class_code VARCHAR2(30);
--
-- 2008/08/18 Mod ↓
/*
  gn_created_by              NUMBER(15);
  gd_creation_date           DATE;
  gn_last_updated_by         NUMBER(15);
  gd_last_update_date        DATE;
  gn_last_update_login       NUMBER(15);
  gn_request_id              NUMBER(15);
  gn_program_application_id  NUMBER(15);
  gn_program_id              NUMBER(15);
*/
  gn_created_by              NUMBER;
  gd_creation_date           DATE;
  gn_last_updated_by         NUMBER;
  gd_last_update_date        DATE;
  gn_last_update_login       NUMBER;
  gn_request_id              NUMBER;
  gn_program_application_id  NUMBER;
  gn_program_id              NUMBER;
-- 2008/08/18 Mod ↑
  gd_program_update_date     DATE;
  gd_min_date                DATE;
  gd_max_date                DATE;
  -- ===============================
  -- 拠点用
  -- ===============================
  gn_p_target_cnt    NUMBER;                    -- 対象件数
  gn_p_normal_cnt    NUMBER;                    -- 正常件数
  gn_p_error_cnt     NUMBER;                    -- エラー件数
  gn_p_warn_cnt      NUMBER;                    -- スキップ件数
  gn_p_report_cnt    NUMBER;                    -- レポート件数
  -- ===============================
  -- 配送先用
  -- ===============================
  gn_s_target_cnt    NUMBER;                    -- 対象件数
  gn_s_normal_cnt    NUMBER;                    -- 正常件数
  gn_s_error_cnt     NUMBER;                    -- エラー件数
  gn_s_warn_cnt      NUMBER;                    -- スキップ件数
  gn_s_report_cnt    NUMBER;                    -- レポート件数
  -- ===============================
  -- 顧客用
  -- ===============================
  gn_c_target_cnt    NUMBER;                    -- 対象件数
  gn_c_normal_cnt    NUMBER;                    -- 正常件数
  gn_c_error_cnt     NUMBER;                    -- エラー件数
  gn_c_warn_cnt      NUMBER;                    -- スキップ件数
  gn_c_report_cnt    NUMBER;                    -- レポート件数
--
  -- ===============================
  -- ユーザー定義グローバルカーソル
  -- ===============================
  -- 顧客マスタ
  -- 拠点IFより
  CURSOR gc_hca_party_cur
  IS
/* 2009/10/23 DEL START
    SELECT hca.party_id
    FROM   hz_cust_accounts hca
    WHERE  EXISTS (
      SELECT xpi.base_code
      FROM   xxcmn_party_if xpi
      WHERE  hca.account_number = xpi.base_code
      AND    ROWNUM = 1)
    AND    hca.status = gv_status_on
    FOR UPDATE OF hca.party_id NOWAIT;
   2009/10/23 DEL END */
-- 2009/10/23 ADD START
    SELECT hca.party_id
    FROM   hz_cust_accounts hca
          ,xxcmn_party_if xpi
    WHERE  hca.account_number = xpi.base_code
    AND    hca.status = gv_status_on
    FOR UPDATE OF hca.party_id NOWAIT;
-- 2009/10/23 ADD END
--
  -- 配送先IFより
  CURSOR gc_hca_site_cur
  IS
/* 2009/10/23 DEL START
    SELECT hca.party_id
    FROM   hz_cust_accounts hca
    WHERE  EXISTS (
      SELECT xsi.party_num
      FROM   xxcmn_site_if xsi
      WHERE  hca.account_number = xsi.party_num
      AND    ROWNUM = 1)
    AND    hca.status = gv_status_on
    FOR UPDATE OF hca.party_id NOWAIT;
   2009/10/23 DEL END */
-- 2009/10/23 ADD START
    SELECT hca.party_id
    FROM   hz_cust_accounts hca
          ,xxcmn_site_if xsi
    WHERE  hca.account_number = xsi.party_num
    AND    hca.status = gv_status_on
    FOR UPDATE OF hca.party_id NOWAIT;
-- 2009/10/23 ADD END
--
  -- パーティマスタ
  -- 拠点IFより
  CURSOR gc_hp_party_cur
  IS
/* 2009/10/23 DEL START
    SELECT hp.party_id
    FROM   hz_parties hp
    WHERE  EXISTS (
      SELECT xpi.base_code
      FROM   xxcmn_party_if xpi
      WHERE  hp.party_number = xpi.base_code
      AND    ROWNUM = 1)
    AND    hp.validated_flag = gv_validated_flag_on
    FOR UPDATE OF hp.party_id NOWAIT;
   2009/10/23 DEL END */
-- 2009/10/23 ADD START
    SELECT hp.party_id
    FROM   hz_parties hp
          ,xxcmn_party_if xpi
    WHERE  hp.party_number = xpi.base_code
    AND    hp.validated_flag = gv_validated_flag_on
    FOR UPDATE OF hp.party_id NOWAIT;
-- 2009/10/23 ADD END
--
  -- 配送先IFより
  CURSOR gc_hp_site_cur
  IS
/* 2009/10/23 DEL START
    SELECT hp.party_id
    FROM   hz_parties hp
    WHERE  EXISTS (
      SELECT xsi.party_num
      FROM   xxcmn_site_if xsi
      WHERE  hp.party_number = xsi.party_num
      AND    ROWNUM = 1)
    AND    hp.validated_flag = gv_validated_flag_on
    FOR UPDATE OF hp.party_id NOWAIT;
   2009/10/23 DEL END */
-- 2009/10/23 ADD START
    SELECT hp.party_id
    FROM   hz_parties hp
          ,xxcmn_site_if xsi
    WHERE  hp.party_number = xsi.party_num
    AND    hp.validated_flag = gv_validated_flag_on
    FOR UPDATE OF hp.party_id NOWAIT;
-- 2009/10/23 ADD END
--
  -- パーティーアドオンマスタ
  -- 拠点IFより
  CURSOR gc_xp_party_cur
  IS
/* 2009/10/23 DEL START
    SELECT xp.party_id
    FROM   xxcmn_parties xp
    WHERE  EXISTS (
      SELECT hps.party_id
      FROM   hz_parties hps
      WHERE  EXISTS (
        SELECT xpi.base_code
        FROM   xxcmn_party_if xpi
        WHERE  hps.party_number = xpi.base_code
        AND    ROWNUM = 1)
      AND    hps.validated_flag = gv_validated_flag_on
      AND    xp.party_id = hps.party_id
      AND    ROWNUM = 1)
    FOR UPDATE OF xp.party_id NOWAIT;
   2009/10/23 DEL END */
-- 2009/10/23 ADD START
    SELECT xp.party_id
    FROM   xxcmn_parties xp
          ,hz_parties hps
          ,xxcmn_party_if xpi
    WHERE  hps.party_number = xpi.base_code
    AND    hps.validated_flag = gv_validated_flag_on
    AND    xp.party_id = hps.party_id
    FOR UPDATE OF xp.party_id NOWAIT;
-- 2009/10/23 ADD END
--
  -- 配送先IFより
  CURSOR gc_xp_site_cur
  IS
/* 2009/10/23 DEL START
    SELECT xp.party_id
    FROM   xxcmn_parties xp
    WHERE  EXISTS (
      SELECT hps.party_id
      FROM   hz_parties hps
      WHERE  EXISTS (
        SELECT xsi.party_num
        FROM   xxcmn_site_if xsi
        WHERE  hps.party_number = xsi.party_num
        AND    ROWNUM = 1)
      AND    hps.validated_flag = gv_validated_flag_on
      AND    xp.party_id = hps.party_id
      AND    ROWNUM = 1)
    FOR UPDATE OF xp.party_id NOWAIT;
   2009/10/23 DEL END */
-- 2009/10/23 ADD START
    SELECT xp.party_id
    FROM   xxcmn_parties xp
          ,hz_parties hps
          ,xxcmn_site_if xsi
    WHERE  hps.party_number = xsi.party_num
    AND    hps.validated_flag = gv_validated_flag_on
    AND    xp.party_id = hps.party_id
    FOR UPDATE OF xp.party_id NOWAIT;
-- 2009/10/23 ADD END
--
  -- パーティサイトマスタ
  -- 配送先IFより
  CURSOR gc_hps_site_cur
  IS
/* 2009/10/23 DEL START
    SELECT hps.party_site_id
    FROM   hz_party_sites hps                     -- パーティサイトマスタ
    WHERE  EXISTS (
      SELECT hcas.location_id
      FROM   hz_locations hcas                    -- 顧客事業所マスタ
      WHERE  EXISTS (
        SELECT xsi.ship_to_code
        FROM   xxcmn_site_if xsi
        WHERE  hcas.province = xsi.ship_to_code
        AND    ROWNUM = 1)
      AND    hps.location_id = hcas.location_id
      AND    ROWNUM = 1)
    AND    hps.status = gv_status_on
    FOR UPDATE OF hps.party_site_id NOWAIT;
   2009/10/23 DEL END */
-- 2009/10/23 ADD START
    SELECT hps.party_site_id
    FROM   hz_party_sites hps                     -- パーティサイトマスタ
          ,hz_locations hcas                    -- 顧客事業所マスタ
          ,xxcmn_site_if xsi
    WHERE  hcas.province = xsi.ship_to_code
    AND    hps.location_id = hcas.location_id
    AND    hps.status = gv_status_on
    FOR UPDATE OF hps.party_site_id NOWAIT;
-- 2009/10/23 ADD END
--
  -- パーティーサイトアドオンマスタ
  CURSOR gc_xps_site_cur
  IS
/* 2009/10/23 DEL START
    SELECT xps.party_site_id
    FROM   xxcmn_party_sites xps                  -- パーティサイトアドオンマスタ
    WHERE  EXISTS (
      SELECT hcas.location_id
      FROM   hz_locations hcas                    -- 顧客事業所マスタ
      WHERE  EXISTS (
        SELECT xsi.ship_to_code
        FROM   xxcmn_site_if xsi
        WHERE  hcas.province = xsi.ship_to_code
        AND    ROWNUM = 1)
      AND    xps.location_id = hcas.location_id
      AND    ROWNUM = 1)
    FOR UPDATE OF xps.party_site_id NOWAIT;
   2009/10/23 DEL END */
-- 2009/10/23 ADD START
    SELECT xps.party_site_id
    FROM   xxcmn_party_sites xps                  -- パーティサイトアドオンマスタ
          ,hz_locations hcas                    -- 顧客事業所マスタ
          ,xxcmn_site_if xsi
    WHERE  hcas.province = xsi.ship_to_code
    AND    xps.location_id = hcas.location_id
    FOR UPDATE OF xps.party_site_id NOWAIT;
-- 2009/10/23 ADD END
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
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,        gv_msg_80a_015,
                                            gv_tkn_ng_profile, gv_prf_max_date_name);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    gd_max_date := FND_DATE.STRING_TO_DATE(gv_max_date,'YYYY/MM/DD');
--
    --最小日付取得
    gv_min_date := SUBSTR(FND_PROFILE.VALUE(gv_prf_min_date),1,10);
--
    -- プロファイルが取得できない場合はエラー
    IF (gv_min_date IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,        gv_msg_80a_015,
                                            gv_tkn_ng_profile, gv_prf_min_date_name);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    gd_min_date := FND_DATE.STRING_TO_DATE(gv_min_date,'YYYY/MM/DD');
--
    --作成元モジュール取得
    gv_created_by_module := SUBSTR(FND_PROFILE.VALUE(gv_prf_module),1,50);
--
    -- プロファイルが取得できない場合はエラー
    IF (gv_created_by_module IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,        gv_msg_80a_015,
                                            gv_tkn_ng_profile, gv_prf_module_name);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --ロケーションアドレス取得
    gv_location_addr := SUBSTR(FND_PROFILE.VALUE(gv_pfr_location_addr),1,50);
--
    -- プロファイルが取得できない場合はエラー
    IF (gv_location_addr IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,        gv_msg_80a_015,
                                            gv_tkn_ng_profile, gv_pfr_location_name);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
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
   * Procedure Name   : set_if_lock
   * Description      : 拠点インタフェースのテーブルロックを行います。
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
    lb_retcd          BOOLEAN;
    ln_party_id       hz_parties.party_id%TYPE;
    ln_party_site_id  hz_party_sites.party_site_id%TYPE;
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
    -- テーブルロック処理(拠点インタフェース)
    lb_retcd := xxcmn_common_pkg.get_tbl_lock(gv_msg_kbn, gv_party_if_name);
--
    -- 失敗
    IF (NOT lb_retcd) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,   gv_msg_80a_017,
                                            gv_tkn_table, gv_xxcmn_party_if_name);
      lv_errbuf := lv_errmsg ||gv_msg_part|| SQLERRM;
      RAISE global_api_expt;
    END IF;
--
    -- テーブルロック処理(配送先インタフェース)
    lb_retcd := xxcmn_common_pkg.get_tbl_lock(gv_msg_kbn, gv_site_if_name);
--
    -- 失敗
    IF (NOT lb_retcd) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,   gv_msg_80a_017,
                                            gv_tkn_table, gv_xxcmn_site_if_name);
      lv_errbuf := lv_errmsg ||gv_msg_part|| SQLERRM;
      RAISE global_api_expt;
    END IF;
--
    -- 顧客マスタ
    BEGIN
      -- 拠点IFより
      OPEN gc_hca_party_cur;
--
    EXCEPTION
      WHEN lock_expt THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,   gv_msg_80a_017,
                                              gv_tkn_table, gv_hz_cust_accounts_name);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
      WHEN NO_DATA_FOUND THEN
        NULL;
--
      WHEN OTHERS THEN
        RAISE global_api_expt;
    END;
--
    BEGIN
      -- 配送先IFより
      OPEN gc_hca_site_cur;
--
    EXCEPTION
      WHEN lock_expt THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,   gv_msg_80a_017,
                                              gv_tkn_table, gv_hz_cust_accounts_name);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
      WHEN NO_DATA_FOUND THEN
        NULL;
--
      WHEN OTHERS THEN
        RAISE global_api_expt;
    END;
--
    -- パーティマスタ
    BEGIN
      -- 拠点IFより
      OPEN gc_hp_party_cur;
--
    EXCEPTION
      WHEN lock_expt THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,   gv_msg_80a_017,
                                              gv_tkn_table, gv_hz_parties_name);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
      WHEN NO_DATA_FOUND THEN
        NULL;
--
      WHEN OTHERS THEN
        RAISE global_api_expt;
    END;
--
    BEGIN
      -- 配送先IFより
      OPEN gc_hp_site_cur;
--
    EXCEPTION
      WHEN lock_expt THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,   gv_msg_80a_017,
                                              gv_tkn_table, gv_hz_parties_name);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
      WHEN NO_DATA_FOUND THEN
        NULL;
--
      WHEN OTHERS THEN
        RAISE global_api_expt;
    END;
--
    -- パーティーアドオンマスタ
    BEGIN
      -- 拠点IFより
      OPEN gc_xp_party_cur;
--
    EXCEPTION
      WHEN lock_expt THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,   gv_msg_80a_017,
                                              gv_tkn_table, gv_xxcmn_parties_name);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
      WHEN NO_DATA_FOUND THEN
        NULL;
--
      WHEN OTHERS THEN
        RAISE global_api_expt;
    END;
--
    BEGIN
      -- 配送先IFより
      OPEN gc_xp_site_cur;
--
    EXCEPTION
      WHEN lock_expt THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,   gv_msg_80a_017,
                                              gv_tkn_table, gv_xxcmn_parties_name);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
      WHEN NO_DATA_FOUND THEN
        NULL;
--
      WHEN OTHERS THEN
        RAISE global_api_expt;
    END;
--
    -- パーティサイトマスタ
    BEGIN
      -- 配送先IFより
      OPEN gc_hps_site_cur;
--
    EXCEPTION
      WHEN lock_expt THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,   gv_msg_80a_017,
                                              gv_tkn_table, gv_hz_party_sites_name);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
      WHEN NO_DATA_FOUND THEN
        NULL;
--
      WHEN OTHERS THEN
        RAISE global_api_expt;
    END;
--
    -- パーティーサイトアドオンマスタ
    BEGIN
      -- 配送先IFより
      OPEN gc_xps_site_cur;
--
    EXCEPTION
      WHEN lock_expt THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,   gv_msg_80a_017,
                                              gv_tkn_table, gv_xxcmn_party_sites_name);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
      WHEN NO_DATA_FOUND THEN
        NULL;
--
      WHEN OTHERS THEN
        RAISE global_api_expt;
    END;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
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
    ov_errbuf        OUT NOCOPY VARCHAR2,    -- エラー・メッセージ           --# 固定 #
    ov_retcode       OUT NOCOPY VARCHAR2,    -- リターン・コード             --# 固定 #
    ov_errmsg        OUT NOCOPY VARCHAR2)    -- ユーザー・エラー・メッセージ --# 固定 #
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
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
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
    ov_errbuf        OUT NOCOPY VARCHAR2,    -- エラー・メッセージ           --# 固定 #
    ov_retcode       OUT NOCOPY VARCHAR2,    -- リターン・コード             --# 固定 #
    ov_errmsg        OUT NOCOPY VARCHAR2)    -- ユーザー・エラー・メッセージ --# 固定 #
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
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
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
    ov_errbuf        OUT NOCOPY VARCHAR2,    -- エラー・メッセージ           --# 固定 #
    ov_retcode       OUT NOCOPY VARCHAR2,    -- リターン・コード             --# 固定 #
    ov_errmsg        OUT NOCOPY VARCHAR2)    -- ユーザー・エラー・メッセージ --# 固定 #
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
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
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
    ov_errbuf        OUT NOCOPY VARCHAR2,    -- エラー・メッセージ           --# 固定 #
    ov_retcode       OUT NOCOPY VARCHAR2,    -- リターン・コード             --# 固定 #
    ov_errmsg        OUT NOCOPY VARCHAR2)    -- ユーザー・エラー・メッセージ --# 固定 #
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
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
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
   * Function Name    : chk_party_id
   * Description      : 顧客・パーティマスタの状態を返します。
   ***********************************************************************************/
  FUNCTION chk_party_id(
    ir_masters_rec IN masters_rec)
    RETURN NUMBER
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_party_id'; --プログラム名
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_kbn     NUMBER;
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
    ln_kbn := gn_data_init;
--
    -- パーティマスタ＆顧客マスタに存在しない
    IF ((ir_masters_rec.p_party_id IS NULL) AND (ir_masters_rec.c_party_id IS NULL)) THEN
      ln_kbn := gn_data_nothing;
--
    ELSE
      -- パーティマスタ＆顧客マスタに存在する
      IF ((ir_masters_rec.p_party_id IS NOT NULL)
      AND (ir_masters_rec.c_party_id IS NOT NULL)) THEN
--
        -- パーティマスタ.パーティーID = 顧客マスタ.パーティーID
        IF (ir_masters_rec.p_party_id = ir_masters_rec.c_party_id) THEN
--
          -- パーティマスタ.有効フラグ='I'(無効)
          -- 顧客マスタ.ステータス='I'(無効)
          IF ((ir_masters_rec.validated_flag = gv_validated_flag_off)
          AND (ir_masters_rec.status = gv_status_off)) THEN
            ln_kbn := gn_data_off;
--
          -- パーティマスタ.有効フラグ='N'(有効)
          -- 顧客マスタ.ステータス='A'(有効)
          ELSIF ((ir_masters_rec.validated_flag = gv_validated_flag_on)
             AND (ir_masters_rec.status = gv_status_on)) THEN
            ln_kbn := gn_data_on;
          END IF;
        END IF;
      END IF;
    END IF;
--
    RETURN ln_kbn;
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
  END chk_party_id;
--
  /***********************************************************************************
   * Procedure Name   : add_p_report
   * Description      : レポート用データを設定します。(拠点用)
   ***********************************************************************************/
  PROCEDURE add_p_report(
    ir_status_rec  IN            status_rec,   -- 処理状況
    ir_masters_rec IN            masters_rec,  -- チェック対象データ
    it_report_tbl  IN OUT NOCOPY report_tbl,   -- レポートデータ
    ov_errbuf         OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode        OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg         OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'add_p_report'; -- プログラム名
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
    lr_report_rec.seq_number          := ir_masters_rec.seq_number;
    lr_report_rec.proc_code           := ir_masters_rec.proc_code;
    lr_report_rec.base_code           := ir_masters_rec.base_code;
    lr_report_rec.party_name          := ir_masters_rec.party_name;
    lr_report_rec.party_short_name    := ir_masters_rec.party_short_name;
    lr_report_rec.party_name_alt      := ir_masters_rec.party_name_alt;
    lr_report_rec.address             := ir_masters_rec.address;
    lr_report_rec.zip                 := ir_masters_rec.zip;
    lr_report_rec.phone               := ir_masters_rec.phone;
    lr_report_rec.fax                 := ir_masters_rec.fax;
    lr_report_rec.old_division_code   := ir_masters_rec.old_division_code;
    lr_report_rec.new_division_code   := ir_masters_rec.new_division_code;
    lr_report_rec.division_start_date := ir_masters_rec.division_start_date;
    lr_report_rec.location_rel_code   := ir_masters_rec.location_rel_code;
    lr_report_rec.ship_mng_code       := ir_masters_rec.ship_mng_code;
    lr_report_rec.district_code       := ir_masters_rec.district_code;
    lr_report_rec.warehouse_code      := ir_masters_rec.warehouse_code;
    lr_report_rec.terminal_code       := ir_masters_rec.terminal_code;
    lr_report_rec.zip2                := ir_masters_rec.zip2;
    lr_report_rec.spare               := ir_masters_rec.spare;
    lr_report_rec.row_level_status    := ir_status_rec.row_level_status;
    lr_report_rec.message             := ir_status_rec.row_err_message;
--
    lr_report_rec.hps_flg         := 0;
    lr_report_rec.hpss_flg        := 0;
    lr_report_rec.hca_flg         := 0;
    lr_report_rec.hcas_flg        := 0;
    lr_report_rec.xps_flg         := 0;
    lr_report_rec.xpss_flg        := 0;
    lr_report_rec.hcsu_flg        := 0;
    lr_report_rec.hzl_flg         := 0;      -- 2008/08/25 Add
--
    -- レポートテーブルに追加
    it_report_tbl(gn_p_report_cnt) := lr_report_rec;
    gn_p_report_cnt := gn_p_report_cnt + 1;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
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
  END add_p_report;
--
  /***********************************************************************************
   * Procedure Name   : add_s_report
   * Description      : レポート用データを設定します。(配送先用)
   ***********************************************************************************/
  PROCEDURE add_s_report(
    ir_status_rec  IN            status_rec,   -- 処理状況
    ir_masters_rec IN            masters_rec,  -- チェック対象データ
    it_report_tbl  IN OUT NOCOPY report_tbl,   -- レポートデータ
    ov_errbuf         OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode        OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg         OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'add_s_report'; -- プログラム名
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
    lr_report_rec.seq_number         := ir_masters_rec.seq_number;
    lr_report_rec.proc_code          := ir_masters_rec.proc_code;
    lr_report_rec.k_proc_code        := ir_masters_rec.k_proc_code;
    lr_report_rec.ship_to_code       := ir_masters_rec.ship_to_code;
    lr_report_rec.base_code          := ir_masters_rec.base_code;
    lr_report_rec.party_site_name1   := ir_masters_rec.party_site_name1;
    lr_report_rec.party_site_name2   := ir_masters_rec.party_site_name2;
    lr_report_rec.party_site_addr1   := ir_masters_rec.party_site_addr1;
    lr_report_rec.party_site_addr2   := ir_masters_rec.party_site_addr2;
    lr_report_rec.phone              := ir_masters_rec.phone;
    lr_report_rec.fax                := ir_masters_rec.fax;
    lr_report_rec.zip                := ir_masters_rec.zip;
    lr_report_rec.party_num          := ir_masters_rec.party_num;
    lr_report_rec.zip2               := ir_masters_rec.zip2;
    lr_report_rec.customer_name1     := ir_masters_rec.customer_name1;
    lr_report_rec.customer_name2     := ir_masters_rec.customer_name2;
    lr_report_rec.sale_base_code     := ir_masters_rec.sale_base_code;
    lr_report_rec.res_sale_base_code := ir_masters_rec.res_sale_base_code;
    lr_report_rec.chain_store        := ir_masters_rec.chain_store;
    lr_report_rec.chain_store_name   := ir_masters_rec.chain_store_name;
    lr_report_rec.cal_cust_app_flg   := ir_masters_rec.cal_cust_app_flg;
    lr_report_rec.row_level_status   := ir_status_rec.row_level_status;
    lr_report_rec.message            := ir_status_rec.row_err_message;
--
    lr_report_rec.hps_flg         := 0;
    lr_report_rec.hpss_flg        := 0;
    lr_report_rec.hca_flg         := 0;
    lr_report_rec.hcas_flg        := 0;
    lr_report_rec.xps_flg         := 0;
    lr_report_rec.xpss_flg        := 0;
    lr_report_rec.hcsu_flg        := 0;
    lr_report_rec.hzl_flg         := 0;      -- 2008/08/25 Add
--
    -- レポートテーブルに追加
    it_report_tbl(gn_s_report_cnt) := lr_report_rec;
    gn_s_report_cnt := gn_s_report_cnt + 1;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
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
  END add_s_report;
--
  /***********************************************************************************
   * Procedure Name   : add_c_report
   * Description      : レポート用データを設定します。(顧客用)
   ***********************************************************************************/
  PROCEDURE add_c_report(
    ir_status_rec  IN            status_rec,   -- 処理状況
    ir_masters_rec IN            masters_rec,  -- チェック対象データ
    it_report_tbl  IN OUT NOCOPY report_tbl,   -- レポートデータ
    ov_errbuf         OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode        OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg         OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'add_c_report'; -- プログラム名
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
    lr_report_rec.seq_number         := ir_masters_rec.seq_number;
    lr_report_rec.proc_code          := ir_masters_rec.proc_code;
    lr_report_rec.k_proc_code        := ir_masters_rec.k_proc_code;
    lr_report_rec.ship_to_code       := ir_masters_rec.ship_to_code;
    lr_report_rec.base_code          := ir_masters_rec.base_code;
    lr_report_rec.party_site_name1   := ir_masters_rec.party_site_name1;
    lr_report_rec.party_site_name2   := ir_masters_rec.party_site_name2;
    lr_report_rec.party_site_addr1   := ir_masters_rec.party_site_addr1;
    lr_report_rec.party_site_addr2   := ir_masters_rec.party_site_addr2;
    lr_report_rec.phone              := ir_masters_rec.phone;
    lr_report_rec.fax                := ir_masters_rec.fax;
    lr_report_rec.zip                := ir_masters_rec.zip;
    lr_report_rec.party_num          := ir_masters_rec.party_num;
    lr_report_rec.zip2               := ir_masters_rec.zip2;
    lr_report_rec.customer_name1     := ir_masters_rec.customer_name1;
    lr_report_rec.customer_name2     := ir_masters_rec.customer_name2;
    lr_report_rec.sale_base_code     := ir_masters_rec.sale_base_code;
    lr_report_rec.res_sale_base_code := ir_masters_rec.res_sale_base_code;
    lr_report_rec.chain_store        := ir_masters_rec.chain_store;
    lr_report_rec.chain_store_name   := ir_masters_rec.chain_store_name;
    lr_report_rec.cal_cust_app_flg   := ir_masters_rec.cal_cust_app_flg;
    lr_report_rec.row_level_status   := ir_status_rec.row_level_status;
    lr_report_rec.message            := ir_status_rec.row_err_message;
--
    lr_report_rec.hps_flg         := 0;
    lr_report_rec.hpss_flg        := 0;
    lr_report_rec.hca_flg         := 0;
    lr_report_rec.hcas_flg        := 0;
    lr_report_rec.xps_flg         := 0;
    lr_report_rec.xpss_flg        := 0;
    lr_report_rec.hcsu_flg        := 0;
    lr_report_rec.hzl_flg         := 0;      -- 2008/08/25 Add
--
    -- レポートテーブルに追加
    it_report_tbl(gn_c_report_cnt) := lr_report_rec;
    gn_c_report_cnt := gn_c_report_cnt + 1;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
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
  END add_c_report;
--
  /***********************************************************************************
   * Procedure Name   : disp_p_report
   * Description      : レポート用データを出力します。(拠点用)
   ***********************************************************************************/
  PROCEDURE disp_p_report(
    it_report_tbl  IN            report_tbl,   -- レポートデータ
    disp_kbn       IN            NUMBER,       -- 表示対象区分(0:正常,1:異常,2:警告)
    ov_errbuf         OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode        OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg         OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'disp_p_report'; -- プログラム名
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
    lv_div_date   VARCHAR2(10);
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
      lv_dspbuf := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_80a_004);
--
    -- エラー
    ELSIF (disp_kbn = gn_data_status_error) THEN
      lv_dspbuf := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_80a_005);
--
    -- 警告
    ELSIF (disp_kbn = gn_data_status_warn) THEN
      lv_dspbuf := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_80a_006);
    END IF;
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_dspbuf);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    -- 設定されているレポートの出力
    <<disp_p_report_loop>>
    FOR i IN 0..gn_p_report_cnt-1 LOOP
      lr_report_rec := it_report_tbl(i);
--
      lv_div_date := TO_CHAR(lr_report_rec.division_start_date,'YYYY/MM/DD');
--
      --入力データの再構成
      lv_dspbuf := TO_CHAR(lr_report_rec.seq_number) || gv_msg_pnt ||
                   TO_CHAR(lr_report_rec.proc_code)  || gv_msg_pnt ||
                   lr_report_rec.base_code           || gv_msg_pnt ||
                   lr_report_rec.party_name          || gv_msg_pnt ||
                   lr_report_rec.party_short_name    || gv_msg_pnt ||
                   lr_report_rec.party_name_alt      || gv_msg_pnt ||
                   lr_report_rec.address             || gv_msg_pnt ||
                   lr_report_rec.zip                 || gv_msg_pnt ||
                   lr_report_rec.phone               || gv_msg_pnt ||
                   lr_report_rec.fax                 || gv_msg_pnt ||
                   lr_report_rec.old_division_code   || gv_msg_pnt ||
                   lr_report_rec.new_division_code   || gv_msg_pnt ||
                   lv_div_date                       || gv_msg_pnt ||
                   lr_report_rec.location_rel_code   || gv_msg_pnt ||
                   lr_report_rec.ship_mng_code       || gv_msg_pnt ||
                   lr_report_rec.district_code       || gv_msg_pnt ||
                   lr_report_rec.warehouse_code      || gv_msg_pnt ||
                   lr_report_rec.terminal_code       || gv_msg_pnt ||
                   lr_report_rec.zip2                || gv_msg_pnt ||
                   lr_report_rec.spare;
--
      -- 対象
      IF (lr_report_rec.row_level_status = disp_kbn) THEN
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_dspbuf);
--
        -- 正常
        IF (disp_kbn = gn_data_status_nomal) THEN
          --パーティマスタ
          IF (lr_report_rec.hps_flg = 1) THEN
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_hz_parties_name);
          END IF;
          --パーティサイトマスタ
          IF (lr_report_rec.hpss_flg = 1) THEN
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_hz_party_sites_name);
          END IF;
          --顧客マスタ
          IF (lr_report_rec.hca_flg = 1) THEN
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_hz_cust_accounts_name);
          END IF;
          --顧客所在地マスタ
          IF (lr_report_rec.hcas_flg = 1) THEN
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_hz_cust_site_name);
          END IF;
          --パーティアドオンマスタ
          IF (lr_report_rec.xps_flg = 1) THEN
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_xxcmn_parties_name);
          END IF;
          --パーティサイトアドオンマスタ
          IF (lr_report_rec.xpss_flg = 1) THEN
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_xxcmn_party_sites_name);
          END IF;
          --顧客使用目的マスタ
          IF (lr_report_rec.hcsu_flg = 1) THEN
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_hz_cust_site_uses_name);
          END IF;
-- 2008/08/25 Add ↓
          --顧客事業所マスタ
          IF (lr_report_rec.hzl_flg = 1) THEN
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_hz_locations_name);
          END IF;
-- 2008/08/25 Add ↑
--
        -- 正常以外
        ELSE
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lr_report_rec.message);
        END IF;
      END IF;
--
    END LOOP disp_p_report_loop;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
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
  END disp_p_report;
--
  /***********************************************************************************
   * Procedure Name   : disp_s_report
   * Description      : レポート用データを出力します。(配送先用)
   ***********************************************************************************/
  PROCEDURE disp_s_report(
    it_report_tbl  IN            report_tbl,   -- レポートデータ
    disp_kbn       IN            NUMBER,       -- 表示対象区分(0:正常,1:異常,2:警告)
    ov_errbuf         OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode        OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg         OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'disp_s_report'; -- プログラム名
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
      lv_dspbuf := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_80a_004);
--
    -- エラー
    ELSIF (disp_kbn = gn_data_status_error) THEN
      lv_dspbuf := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_80a_005);
--
    -- 警告
    ELSIF (disp_kbn = gn_data_status_warn) THEN
      lv_dspbuf := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_80a_006);
    END IF;
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_dspbuf);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    -- 設定されているレポートの出力
    <<disp_s_report_loop>>
    FOR i IN 0..gn_s_report_cnt-1 LOOP
      lr_report_rec := it_report_tbl(i);
--
      --入力データの再構成
      lv_dspbuf := TO_CHAR(lr_report_rec.seq_number)  || gv_msg_pnt ||
                   TO_CHAR(lr_report_rec.k_proc_code) || gv_msg_pnt ||
                   lr_report_rec.ship_to_code         || gv_msg_pnt ||
                   lr_report_rec.base_code            || gv_msg_pnt ||
                   lr_report_rec.party_site_name1     || gv_msg_pnt ||
                   lr_report_rec.party_site_name2     || gv_msg_pnt ||
                   lr_report_rec.party_site_addr1     || gv_msg_pnt ||
                   lr_report_rec.party_site_addr2     || gv_msg_pnt ||
                   lr_report_rec.phone                || gv_msg_pnt ||
                   lr_report_rec.fax                  || gv_msg_pnt ||
                   lr_report_rec.zip                  || gv_msg_pnt ||
                   lr_report_rec.party_num            || gv_msg_pnt ||
                   lr_report_rec.zip2                 || gv_msg_pnt ||
                   lr_report_rec.customer_name1       || gv_msg_pnt ||
                   lr_report_rec.customer_name2       || gv_msg_pnt ||
                   lr_report_rec.sale_base_code       || gv_msg_pnt ||
                   lr_report_rec.res_sale_base_code   || gv_msg_pnt ||
                   lr_report_rec.chain_store          || gv_msg_pnt ||
                   lr_report_rec.chain_store_name     || gv_msg_pnt ||
                   lr_report_rec.cal_cust_app_flg;
--
      -- 対象
      IF (lr_report_rec.row_level_status = disp_kbn) THEN
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_dspbuf);
--
        -- 正常
        IF (disp_kbn = gn_data_status_nomal) THEN
          --パーティマスタ
          IF (lr_report_rec.hps_flg = 1) THEN
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_hz_parties_name);
          END IF;
          --パーティサイトマスタ
          IF (lr_report_rec.hpss_flg = 1) THEN
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_hz_party_sites_name);
          END IF;
          --顧客マスタ
          IF (lr_report_rec.hca_flg = 1) THEN
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_hz_cust_accounts_name);
          END IF;
          --顧客所在地マスタ
          IF (lr_report_rec.hcas_flg = 1) THEN
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_hz_cust_site_name);
          END IF;
          --パーティアドオンマスタ
          IF (lr_report_rec.xps_flg = 1) THEN
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_xxcmn_parties_name);
          END IF;
          --パーティサイトアドオンマスタ
          IF (lr_report_rec.xpss_flg = 1) THEN
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_xxcmn_party_sites_name);
          END IF;
          --顧客使用目的マスタ
          IF (lr_report_rec.hcsu_flg = 1) THEN
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_hz_cust_site_uses_name);
          END IF;
-- 2008/08/25 Add ↓
          --顧客事業所マスタ
          IF (lr_report_rec.hzl_flg = 1) THEN
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_hz_locations_name);
          END IF;
-- 2008/08/25 Add ↑
--
        -- 正常以外
        ELSE
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lr_report_rec.message);
        END IF;
      END IF;
--
    END LOOP disp_s_report_loop;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
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
  END disp_s_report;
--
  /***********************************************************************************
   * Procedure Name   : disp_c_report
   * Description      : レポート用データを出力します。(顧客用)
   ***********************************************************************************/
  PROCEDURE disp_c_report(
    it_report_tbl  IN            report_tbl,   -- レポートデータ
    disp_kbn       IN            NUMBER,       -- 表示対象区分(0:正常,1:異常,2:警告)
    ov_errbuf         OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode        OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg         OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'disp_c_report'; -- プログラム名
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
      lv_dspbuf := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_80a_004);
--
    -- エラー
    ELSIF (disp_kbn = gn_data_status_error) THEN
      lv_dspbuf := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_80a_005);
--
    -- 警告
    ELSIF (disp_kbn = gn_data_status_warn) THEN
      lv_dspbuf := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_80a_006);
    END IF;
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_dspbuf);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    -- 設定されているレポートの出力
    <<disp_c_report_loop>>
    FOR i IN 0..gn_c_report_cnt-1 LOOP
      lr_report_rec := it_report_tbl(i);
--
      --入力データの再構成
      lv_dspbuf := TO_CHAR(lr_report_rec.seq_number)  || gv_msg_pnt ||
                   TO_CHAR(lr_report_rec.k_proc_code) || gv_msg_pnt ||
                   lr_report_rec.ship_to_code         || gv_msg_pnt ||
                   lr_report_rec.base_code            || gv_msg_pnt ||
                   lr_report_rec.party_site_name1     || gv_msg_pnt ||
                   lr_report_rec.party_site_name2     || gv_msg_pnt ||
                   lr_report_rec.party_site_addr1     || gv_msg_pnt ||
                   lr_report_rec.party_site_addr2     || gv_msg_pnt ||
                   lr_report_rec.phone                || gv_msg_pnt ||
                   lr_report_rec.fax                  || gv_msg_pnt ||
                   lr_report_rec.zip                  || gv_msg_pnt ||
                   lr_report_rec.party_num            || gv_msg_pnt ||
                   lr_report_rec.zip2                 || gv_msg_pnt ||
                   lr_report_rec.customer_name1       || gv_msg_pnt ||
                   lr_report_rec.customer_name2       || gv_msg_pnt ||
                   lr_report_rec.sale_base_code       || gv_msg_pnt ||
                   lr_report_rec.res_sale_base_code   || gv_msg_pnt ||
                   lr_report_rec.chain_store          || gv_msg_pnt ||
                   lr_report_rec.chain_store_name     || gv_msg_pnt ||
                   lr_report_rec.cal_cust_app_flg;
--
      -- 対象
      IF (lr_report_rec.row_level_status = disp_kbn) THEN
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_dspbuf);
--
        -- 正常
        IF (disp_kbn = gn_data_status_nomal) THEN
          --パーティマスタ
          IF (lr_report_rec.hps_flg = 1) THEN
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_hz_parties_name);
          END IF;
          --パーティサイトマスタ
          IF (lr_report_rec.hpss_flg = 1) THEN
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_hz_party_sites_name);
          END IF;
          --顧客マスタ
          IF (lr_report_rec.hca_flg = 1) THEN
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_hz_cust_accounts_name);
          END IF;
          --顧客所在地マスタ
          IF (lr_report_rec.hcas_flg = 1) THEN
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_hz_cust_site_name);
          END IF;
          --パーティアドオンマスタ
          IF (lr_report_rec.xps_flg = 1) THEN
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_xxcmn_parties_name);
          END IF;
          --パーティサイトアドオンマスタ
          IF (lr_report_rec.xpss_flg = 1) THEN
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_xxcmn_party_sites_name);
          END IF;
          --顧客使用目的マスタ
          IF (lr_report_rec.hcsu_flg = 1) THEN
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_hz_cust_site_uses_name);
          END IF;
-- 2008/08/25 Add ↓
          --顧客事業所マスタ
          IF (lr_report_rec.hzl_flg = 1) THEN
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_hz_locations_name);
          END IF;
-- 2008/08/25 Add ↓
--
        -- 正常以外
        ELSE
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lr_report_rec.message);
        END IF;
      END IF;
--
    END LOOP disp_c_report_loop;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
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
  END disp_c_report;
--
  /***********************************************************************************
   * Procedure Name   : disp_report
   * Description      : レポート用データを出力します。
   ***********************************************************************************/
  PROCEDURE disp_report(
    it_party_report_tbl IN            report_tbl,     -- 出力用テーブル(拠点)
    it_cust_report_tbl  IN            report_tbl,     -- 出力用テーブル(顧客)
    it_site_report_tbl  IN            report_tbl,     -- 出力用テーブル(配送先)
    ov_errbuf              OUT NOCOPY VARCHAR2,       -- エラー・メッセージ           --# 固定 #
    ov_retcode             OUT NOCOPY VARCHAR2,       -- リターン・コード             --# 固定 #
    ov_errmsg              OUT NOCOPY VARCHAR2)       -- ユーザー・エラー・メッセージ --# 固定 #
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
    lv_out_msg       VARCHAR2(2000);
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
    -- 拠点
    -- ===============================
    lv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_80a_012);
    IF (lv_out_msg IS NOT NULL) THEN
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_out_msg);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
    END IF;
--
    IF (gn_p_normal_cnt > 0) THEN
      -- ログ出力処理(成功:0)
      disp_p_report(it_party_report_tbl,
                    gn_data_status_nomal,
                    lv_errbuf,
                    lv_retcode,
                    lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
    END IF;
--
    IF (gn_p_error_cnt > 0) THEN
      -- ログ出力処理(失敗:1)
      disp_p_report(it_party_report_tbl,
                    gn_data_status_error,
                    lv_errbuf,
                    lv_retcode,
                    lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
    END IF;
--
    IF (gn_p_warn_cnt > 0) THEN
      -- ログ出力処理(警告:2)
      disp_p_report(it_party_report_tbl,
                    gn_data_status_warn,
                    lv_errbuf,
                    lv_retcode,
                    lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
    END IF;
--
    --区切り文字列出力
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    --処理件数出力
    lv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_80a_007, gv_tkn_cnt,
                                           TO_CHAR(gn_p_target_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_out_msg);
--
    --成功件数出力
    lv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_80a_008, gv_tkn_cnt,
                                           TO_CHAR(gn_p_normal_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_out_msg);
--
    --エラー件数出力
    lv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_80a_009, gv_tkn_cnt,
                                           TO_CHAR(gn_p_error_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_out_msg);
--
    --スキップ件数出力
    lv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_80a_010, gv_tkn_cnt,
                                           TO_CHAR(gn_p_warn_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_out_msg);
--
    --区切り文字列出力
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    -- ===============================
    -- 顧客
    -- ===============================
    lv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_80a_013);
    IF (lv_out_msg IS NOT NULL) THEN
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_out_msg);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
    END IF;
--
    IF (gn_c_normal_cnt > 0) THEN
      -- ログ出力処理(成功:0)
      disp_c_report(it_cust_report_tbl,
                    gn_data_status_nomal,
                    lv_errbuf,
                    lv_retcode,
                    lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
    END IF;
--
    IF (gn_c_error_cnt > 0) THEN
      -- ログ出力処理(失敗:1)
      disp_c_report(it_cust_report_tbl,
                    gn_data_status_error,
                    lv_errbuf,
                    lv_retcode,
                    lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
    END IF;
--
--    IF (gn_c_warn_cnt > 0) THEN
      -- ログ出力処理(警告:2)
--      disp_c_report(it_cust_report_tbl, gn_data_status_warn,
--                    lv_errbuf,
--                    lv_retcode,
--                    lv_errmsg);
--
--      IF (lv_retcode = gv_status_error) THEN
--        RAISE global_api_expt;
--      END IF;
--    END IF;
--
    --区切り文字列出力
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    --処理件数出力
    lv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_80a_007, gv_tkn_cnt,
                                           TO_CHAR(gn_c_target_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_out_msg);
--
    --成功件数出力
    lv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_80a_008, gv_tkn_cnt,
                                           TO_CHAR(gn_c_normal_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_out_msg);
--
    --エラー件数出力
    lv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_80a_009, gv_tkn_cnt,
                                           TO_CHAR(gn_c_error_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_out_msg);
--
    --スキップ件数出力
    lv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_80a_010, gv_tkn_cnt,
                                           TO_CHAR(gn_c_warn_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_out_msg);
--
    --区切り文字列出力
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    -- ===============================
    -- 配送先
    -- ===============================
    lv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_80a_014);
    IF (lv_out_msg IS NOT NULL) THEN
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_out_msg);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
    END IF;
--
    IF (gn_s_normal_cnt > 0) THEN
      -- ログ出力処理(成功:0)
      disp_s_report(it_site_report_tbl,
                    gn_data_status_nomal,
                    lv_errbuf,
                    lv_retcode,
                    lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
    END IF;
--
    IF (gn_s_error_cnt > 0) THEN
      -- ログ出力処理(失敗:1)
      disp_s_report(it_site_report_tbl,
                    gn_data_status_error,
                    lv_errbuf,
                    lv_retcode,
                    lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
    END IF;
--
    IF (gn_s_warn_cnt > 0) THEN
      -- ログ出力処理(警告:2)
      disp_s_report(it_site_report_tbl,
                    gn_data_status_warn,
                    lv_errbuf,
                    lv_retcode,
                    lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
    END IF;
--
    --区切り文字列出力
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    --処理件数出力
    lv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_80a_007, gv_tkn_cnt,
                                           TO_CHAR(gn_s_target_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_out_msg);
--
    --成功件数出力
    lv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_80a_008, gv_tkn_cnt,
                                           TO_CHAR(gn_s_normal_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_out_msg);
--
    --エラー件数出力
    lv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_80a_009, gv_tkn_cnt,
                                           TO_CHAR(gn_s_error_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_out_msg);
--
    --スキップ件数出力
    lv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_80a_010, gv_tkn_cnt,
                                           TO_CHAR(gn_s_warn_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_out_msg);
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
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
   * Procedure Name   : get_class_code
   * Description      : 顧客区分の取得を行います。
   ***********************************************************************************/
  PROCEDURE get_class_code(
    in_kbn          IN            NUMBER,      -- 処理区分
    ov_class_code      OUT NOCOPY VARCHAR2,    -- 顧客区分
    ob_retcd           OUT NOCOPY BOOLEAN,     -- 検索結果
    ov_errbuf          OUT NOCOPY VARCHAR2,    -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,    -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)    -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_class_code'; -- プログラム名
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
    ln_cnt        NUMBER;
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
    BEGIN
      -- 拠点
      IF (in_kbn = gn_kbn_party) THEN
--
        SELECT xlvv.lookup_code
        INTO   ov_class_code
        FROM   xxcmn_lookup_values_v xlvv
        WHERE  xlvv.lookup_type = gv_lookup_type
        AND    xlvv.meaning     = gv_meaning_party
        AND    ROWNUM           = 1;
--
      -- 顧客
      ELSE
        SELECT xlvv.lookup_code
        INTO   ov_class_code
        FROM   xxcmn_lookup_values_v xlvv
        WHERE  xlvv.lookup_type = gv_lookup_type
        AND    xlvv.meaning     = gv_meaning_cust
        AND    ROWNUM           = 1;
      END IF;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ov_class_code := NULL;
        ob_retcd := FALSE;
--
      WHEN OTHERS THEN
        RAISE global_api_expt;
    END;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
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
  END get_class_code;
--
  /***********************************************************************************
   * Procedure Name   : get_xxcmn_party_if
   * Description      : 拠点インタフェースの過去の件数取得を行います。
   ***********************************************************************************/
  PROCEDURE get_xxcmn_party_if(
    ir_masters_rec  IN OUT NOCOPY masters_rec, -- チェック対象データ
    ov_errbuf          OUT NOCOPY VARCHAR2,    -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,    -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)    -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_xxcmn_party_if'; -- プログラム名
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
      ir_masters_rec.row_o_ins_cnt := 0;
      ir_masters_rec.row_o_upd_cnt := 0;
      ir_masters_rec.row_o_del_cnt := 0;
--
      -- 拠点インタフェース
      SELECT SUM(NVL(DECODE(xpi.proc_code,gn_proc_insert,1),0)),
             SUM(NVL(DECODE(xpi.proc_code,gn_proc_update,1),0)),
             SUM(NVL(DECODE(xpi.proc_code,gn_proc_delete,1),0))
      INTO   ir_masters_rec.row_o_ins_cnt,
             ir_masters_rec.row_o_upd_cnt,
             ir_masters_rec.row_o_del_cnt
      FROM   xxcmn_party_if xpi
      WHERE  xpi.base_code = ir_masters_rec.base_code      -- 拠点コードが同じ
      AND    xpi.seq_number < ir_masters_rec.seq_number    -- SEQ番号が以前のデータ
      AND    xpi.ship_mng_code = gv_mode_on                -- 出庫管理元区分='0'
      GROUP BY base_code;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ir_masters_rec.row_o_ins_cnt := 0;
        ir_masters_rec.row_o_upd_cnt := 0;
        ir_masters_rec.row_o_del_cnt := 0;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    BEGIN
--
      ir_masters_rec.row_z_ins_cnt := 0;
      ir_masters_rec.row_z_upd_cnt := 0;
      ir_masters_rec.row_z_del_cnt := 0;
--
      -- 拠点インタフェース
      SELECT SUM(NVL(DECODE(xpi.proc_code,gn_proc_insert,1),0)),
             SUM(NVL(DECODE(xpi.proc_code,gn_proc_update,1),0)),
             SUM(NVL(DECODE(xpi.proc_code,gn_proc_delete,1),0))
      INTO   ir_masters_rec.row_z_ins_cnt,
             ir_masters_rec.row_z_upd_cnt,
             ir_masters_rec.row_z_del_cnt
      FROM   xxcmn_party_if xpi
      WHERE  xpi.base_code = ir_masters_rec.base_code      -- 拠点コードが同じ
      AND    xpi.seq_number < ir_masters_rec.seq_number    -- SEQ番号が以前のデータ
      AND    xpi.ship_mng_code <> gv_mode_on               -- 出庫管理元区分<>'0'
      GROUP BY base_code;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ir_masters_rec.row_z_ins_cnt := 0;
        ir_masters_rec.row_z_upd_cnt := 0;
        ir_masters_rec.row_z_del_cnt := 0;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
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
  END get_xxcmn_party_if;
--
  /***********************************************************************************
   * Procedure Name   : get_xxcmn_site_if
   * Description      : 配送先インタフェースの過去の件数取得を行います。
   ***********************************************************************************/
  PROCEDURE get_xxcmn_site_if(
    ir_masters_rec  IN OUT NOCOPY masters_rec, -- チェック対象データ
    ov_errbuf          OUT NOCOPY VARCHAR2,    -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,    -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)    -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_xxcmn_site_if'; -- プログラム名
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
    -- 配送先コードが同じ件数
    BEGIN
--
-- 2008/10/01 v1.10 DELETE START
/*
      ir_masters_rec.row_s_ins_cnt := 0;
      ir_masters_rec.row_s_upd_cnt := 0;
      ir_masters_rec.row_s_del_cnt := 0;
*/
-- 2008/10/01 v1.10 DELETE END
--
      -- 配送先インタフェース
-- 2008/10/01 v1.10 UPDATE START
/*
      SELECT SUM(NVL(DECODE(xsi.proc_code,gn_proc_insert,1),0)),  -- 登録
             SUM(NVL(DECODE(xsi.proc_code,gn_proc_update,1),0)),  -- 更新
             SUM(NVL(DECODE(xsi.proc_code,gn_proc_delete,1),0))   -- 削除
*/
      SELECT NVL(SUM(NVL(DECODE(xsi.proc_code,gn_proc_insert,1),0)), 0),  -- 登録
             NVL(SUM(NVL(DECODE(xsi.proc_code,gn_proc_update,1),0)), 0),  -- 更新
             NVL(SUM(NVL(DECODE(xsi.proc_code,gn_proc_delete,1),0)), 0)   -- 削除
-- 2008/10/01 v1.10 UPDATE END
      INTO   ir_masters_rec.row_s_ins_cnt,
             ir_masters_rec.row_s_upd_cnt,
             ir_masters_rec.row_s_del_cnt
      FROM   xxcmn_site_if xsi
      WHERE  xsi.ship_to_code = ir_masters_rec.ship_to_code  -- 配送先コードが同じ
      AND    xsi.seq_number < ir_masters_rec.seq_number      -- SEQ番号が以前のデータ
-- 2008/10/01 v1.10 UPDATE START
--      GROUP BY base_code;
      ;
-- 2008/10/01 v1.10 UPDATE END
--
    EXCEPTION
/*
-- 2008/10/01 v1.10 DELETE START
      WHEN NO_DATA_FOUND THEN
        ir_masters_rec.row_s_ins_cnt := 0;
        ir_masters_rec.row_s_upd_cnt := 0;
        ir_masters_rec.row_s_del_cnt := 0;
*/
-- 2008/10/01 v1.10 DELETE END
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    -- 顧客コード入力あり
-- 2008/08/25 Mod ↓
/*
    IF (ir_masters_rec.party_num IS NOT NULL) THEN
*/
    IF (ir_masters_rec.party_num <> gv_def_party_num) THEN
-- 2008/08/25 Mod ↑
      -- 顧客コードが同じ件数
      BEGIN
--
        ir_masters_rec.row_c_ins_cnt := 0;
        ir_masters_rec.row_c_upd_cnt := 0;
        ir_masters_rec.row_c_del_cnt := 0;
--
        -- 配送先インタフェース
        SELECT SUM(NVL(DECODE(xsi.proc_code,gn_proc_insert,1),0)),  -- 登録
               SUM(NVL(DECODE(xsi.proc_code,gn_proc_update,1),0)),  -- 更新
               SUM(NVL(DECODE(xsi.proc_code,gn_proc_delete,1),0))   -- 削除
        INTO   ir_masters_rec.row_c_ins_cnt,
               ir_masters_rec.row_c_upd_cnt,
               ir_masters_rec.row_c_del_cnt
        FROM   xxcmn_site_if xsi
        WHERE  xsi.party_num = ir_masters_rec.party_num        -- 顧客コードが同じ
        AND    xsi.seq_number < ir_masters_rec.seq_number      -- SEQ番号が以前のデータ
        GROUP BY party_num;
--
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          ir_masters_rec.row_c_ins_cnt := 0;
          ir_masters_rec.row_c_upd_cnt := 0;
          ir_masters_rec.row_c_del_cnt := 0;
--
        WHEN OTHERS THEN
          RAISE global_api_others_expt;
      END;
--
    -- 顧客コード入力なし
    ELSE
      ir_masters_rec.row_c_ins_cnt := 0;
      ir_masters_rec.row_c_upd_cnt := 0;
      ir_masters_rec.row_c_del_cnt := 0;
    END IF;
--
    -- 配送先コードが同じで顧客が設定されていない
    BEGIN
--
      ir_masters_rec.row_n_ins_cnt := 0;
      ir_masters_rec.row_n_upd_cnt := 0;
      ir_masters_rec.row_n_del_cnt := 0;
--
      -- 配送先インタフェース
      SELECT SUM(NVL(DECODE(xsi.proc_code,gn_proc_insert,1),0)),  -- 登録
             SUM(NVL(DECODE(xsi.proc_code,gn_proc_update,1),0)),  -- 更新
             SUM(NVL(DECODE(xsi.proc_code,gn_proc_delete,1),0))   -- 削除
      INTO   ir_masters_rec.row_n_ins_cnt,
             ir_masters_rec.row_n_upd_cnt,
             ir_masters_rec.row_n_del_cnt
      FROM   xxcmn_site_if xsi
      WHERE  xsi.ship_to_code = ir_masters_rec.ship_to_code  -- 配送先コードが同じ
      AND    xsi.seq_number < ir_masters_rec.seq_number      -- SEQ番号が以前のデータ
-- 2008/08/25 Mod ↓
/*
      AND    xsi.party_num IS NULL                           -- 顧客コードが設定されていない
*/
      AND    xsi.party_num    = gv_def_party_num
-- 2008/08/25 Mod ↑
      GROUP BY base_code;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ir_masters_rec.row_n_ins_cnt := 0;
        ir_masters_rec.row_n_upd_cnt := 0;
        ir_masters_rec.row_n_del_cnt := 0;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    -- 配送先コードが同じで顧客が設定されている
    BEGIN
--
      ir_masters_rec.row_m_ins_cnt := 0;
      ir_masters_rec.row_m_upd_cnt := 0;
      ir_masters_rec.row_m_del_cnt := 0;
--
      -- 配送先インタフェース
      SELECT SUM(NVL(DECODE(xsi.proc_code,gn_proc_insert,1),0)),  -- 登録
             SUM(NVL(DECODE(xsi.proc_code,gn_proc_update,1),0)),  -- 更新
             SUM(NVL(DECODE(xsi.proc_code,gn_proc_delete,1),0))   -- 削除
      INTO   ir_masters_rec.row_m_ins_cnt,
             ir_masters_rec.row_m_upd_cnt,
             ir_masters_rec.row_m_del_cnt
      FROM   xxcmn_site_if xsi
      WHERE  xsi.ship_to_code = ir_masters_rec.ship_to_code  -- 配送先コードが同じ
      AND    xsi.seq_number < ir_masters_rec.seq_number      -- SEQ番号が以前のデータ
-- 2008/08/25 Mod ↓
/*
      AND    xsi.party_num IS NOT NULL                       -- 顧客コードが設定されている
*/
      AND    xsi.party_num <> gv_def_party_num
-- 2008/08/25 Mod ↑
      GROUP BY base_code;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ir_masters_rec.row_m_ins_cnt := 0;
        ir_masters_rec.row_m_upd_cnt := 0;
        ir_masters_rec.row_m_del_cnt := 0;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
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
  END get_xxcmn_site_if;
--
  /***********************************************************************************
   * Procedure Name   : get_hz_parties
   * Description      : パーティーマスタの取得を行います。
   ***********************************************************************************/
  PROCEDURE get_hz_parties(
    ir_masters_rec  IN OUT NOCOPY masters_rec, -- チェック対象データ
    in_kbn          IN            NUMBER,      -- 処理区分
    ov_errbuf          OUT NOCOPY VARCHAR2,    -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,    -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)    -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_hz_parties'; -- プログラム名
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
    lv_account_number       hz_cust_accounts.account_number%TYPE;
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
    -- 2008/04/17 変更要求No61 対応
    -- 拠点
    IF (in_kbn = gn_kbn_party) THEN
      lv_account_number := ir_masters_rec.base_code;    -- 拠点コード
    ELSE
      lv_account_number := ir_masters_rec.party_num;    -- 顧客コード
    END IF;
--
    BEGIN
--
      SELECT hps.party_id                               -- パーティID
            ,hps.validated_flag                         -- 有効フラグ
            ,hps.object_version_number                  -- オブジェクトバージョン番号
      INTO   ir_masters_rec.p_party_id
            ,ir_masters_rec.validated_flag
            ,ir_masters_rec.obj_party_number
      FROM   hz_parties       hps                       -- パーティマスタ
            ,hz_cust_accounts hca                       -- 顧客マスタ
      WHERE  hps.party_id       = hca.party_id
      AND    hca.account_number = lv_account_number
      AND    ROWNUM             = 1;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ir_masters_rec.p_party_id       := NULL;
        ir_masters_rec.validated_flag   := NULL;
        ir_masters_rec.obj_party_number := NULL;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
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
  END get_hz_parties;
--
  /***********************************************************************************
   * Procedure Name   : get_hz_cust_accounts
   * Description      : 顧客マスタの取得を行います。
   ***********************************************************************************/
  PROCEDURE get_hz_cust_accounts(
    ir_masters_rec  IN OUT NOCOPY masters_rec, -- チェック対象データ
    in_kbn          IN            NUMBER,      -- 処理区分
    ov_errbuf          OUT NOCOPY VARCHAR2,    -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,    -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)    -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_hz_cust_accounts'; -- プログラム名
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
    lv_account_number      hz_cust_accounts.account_number%TYPE;
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
    -- 2008/04/17 変更要求No61 対応
    -- 拠点
    IF (in_kbn = gn_kbn_party) THEN
      lv_account_number := ir_masters_rec.base_code;  -- 拠点コード
--
    -- 顧客
    ELSE
      lv_account_number := ir_masters_rec.party_num;  -- 顧客コード
    END IF;
--
    BEGIN
--
      SELECT hca.cust_account_id,                         -- 顧客ID
             hca.party_id,                                -- パーティID
             hca.status,                                  -- 有効ステイタス
             hca.object_version_number                    -- オブジェクトバージョン番号
      INTO   ir_masters_rec.cust_account_id,
             ir_masters_rec.c_party_id,
             ir_masters_rec.status,
             ir_masters_rec.obj_cust_number
      FROM   hz_cust_accounts hca,                        -- 顧客マスタ
             hz_parties       hps                         -- パーティマスタ
      WHERE  hca.party_id       = hps.party_id
      AND    hca.account_number = lv_account_number
      AND    ROWNUM             = 1;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ir_masters_rec.c_party_id      := NULL;
        ir_masters_rec.status          := NULL;
        ir_masters_rec.obj_cust_number := NULL;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
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
  END get_hz_cust_accounts;
--
  /***********************************************************************************
   * Procedure Name   : get_hz_party_sites
   * Description      : パーティーサイトマスタの取得を行います。
   ***********************************************************************************/
  PROCEDURE get_hz_party_sites(
    ir_masters_rec  IN OUT NOCOPY masters_rec, -- チェック対象データ
    ob_retcd           OUT NOCOPY BOOLEAN,     -- 検索結果
    ov_errbuf          OUT NOCOPY VARCHAR2,    -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,    -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)    -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_hz_party_sites'; -- プログラム名
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
    lv_account_number    hz_cust_accounts.account_number%TYPE;
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
    ob_retcd := FALSE;
--
    -- 2008/04/17 変更要求No61 対応
    -- 登録(拠点紐付き)
-- 2008/08/25 Mod ↓
/*
    IF (ir_masters_rec.party_num IS NULL) THEN
*/
    IF (ir_masters_rec.party_num = gv_def_party_num) THEN
-- 2008/08/25 Mod ↑
      lv_account_number := ir_masters_rec.base_code;      -- 拠点コード
--
    -- 登録(顧客紐付き)
    ELSE
      lv_account_number := ir_masters_rec.party_num;      -- 顧客コード
    END IF;
--
    BEGIN
--
      -- パーティーサイトマスタ
      SELECT hps.party_id,                               -- パーティID
             hps.party_site_id,                          -- パーティサイトID
             hps.location_id,                            -- ロケーションID
             hps.status,                                 -- ステータス
             hp.party_number,                            -- 組織番号
             hps.object_version_number                   -- オブジェクトバージョン番号
      INTO   ir_masters_rec.p_party_id,
             ir_masters_rec.party_site_id,
             ir_masters_rec.location_id,
             ir_masters_rec.site_status,
             ir_masters_rec.party_number,
             ir_masters_rec.obj_site_number
-- 2008/08/25 Mod ↓
/*
      FROM   hz_parties             hp,                  -- パーティマスタ
             hz_party_sites         hps,                 -- パーティサイトマスタ
             hz_cust_accounts       hca,                 -- 顧客マスタ
             hz_cust_acct_sites_all hcas                 -- 顧客所在地マスタ
      WHERE  hp.party_id        = hps.party_id
      AND    hps.party_id       = hca.party_id
      AND    hps.party_site_id  = hcas.party_site_id
      AND    hca.account_number = lv_account_number
      AND    hcas.attribute18   = ir_masters_rec.ship_to_code    -- 配送先コード
      AND    hps.status         = gv_status_on;
*/
      FROM   hz_parties             hp,                  -- パーティマスタ
             hz_party_sites         hps,                 -- パーティサイトマスタ
             hz_cust_accounts       hca,                 -- 顧客マスタ
             hz_locations           hcas                 -- 顧客事業所マスタ
      WHERE  hp.party_id        = hps.party_id
      AND    hps.party_id       = hca.party_id
      AND    hps.location_id    = hcas.location_id
      AND    hca.account_number = lv_account_number
      AND    hcas.province      = ir_masters_rec.ship_to_code    -- 配送先コード
      AND    hps.status         = gv_status_on;
-- 2008/08/25 Mod ↑
--      AND    ROWNUM             = 1;
--
      ob_retcd := TRUE;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ir_masters_rec.p_party_id      := NULL;
        ir_masters_rec.party_site_id   := NULL;
        ir_masters_rec.location_id     := NULL;
        ir_masters_rec.site_status     := NULL;
        ir_masters_rec.party_number    := NULL;
        ir_masters_rec.obj_site_number := NULL;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
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
  END get_hz_party_sites;
--
  /***********************************************************************************
   * Procedure Name   : get_party_num
   * Description      : 顧客コードの取得を行います。
   ***********************************************************************************/
  PROCEDURE get_party_num(
    ir_masters_rec  IN OUT NOCOPY masters_rec,  -- チェック対象データ
    in_proc_code    IN            NUMBER,       -- 更新区分
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_party_num'; -- プログラム名
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
    lv_party_num    xxcmn_site_if.party_num%TYPE;     -- 顧客コード
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
      ir_masters_rec.party_num := NULL;
--
      -- 配送先インタフェース
      SELECT xsi.party_num
      INTO   lv_party_num
      FROM   xxcmn_site_if xsi
      WHERE  xsi.seq_number < ir_masters_rec.seq_number          -- SEQ番号が以前
      AND    xsi.ship_to_code = ir_masters_rec.ship_to_code      -- 配送先コード
-- 2008/08/25 Mod ↓
/*
      AND    xsi.party_num IS NOT NULL                           -- 顧客コードが存在する
*/
      AND    xsi.party_num <> gv_def_party_num
-- 2008/08/25 Mod ↑
      AND    xsi.proc_code = in_proc_code
      AND    xsi.seq_number IN (
        SELECT MAX(xxsi.seq_number)
        FROM   xxcmn_site_if xxsi
        WHERE  xxsi.seq_number < ir_masters_rec.seq_number
        AND    xxsi.ship_to_code = ir_masters_rec.ship_to_code
        AND    xxsi.proc_code = in_proc_code
/*
        AND    xxsi.party_num IS NOT NULL)
*/
        AND    xxsi.party_num <> gv_def_party_num)
      AND    ROWNUM = 1;
--
      ir_masters_rec.party_num := lv_party_num;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
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
  END get_party_num;
--
  /***********************************************************************************
   * Procedure Name   : get_party_id
   * Description      : パーティIDの取得処理を行います。
   ***********************************************************************************/
  PROCEDURE get_party_id(
    ir_masters_rec  IN OUT NOCOPY masters_rec,  -- チェック対象データ
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_party_id'; -- プログラム名
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
    lv_account_number     hz_cust_accounts.account_number%TYPE;
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
    -- 2008/04/17 変更要求No61 対応
    -- 登録(拠点紐付き)
-- 2008/08/25 Mod ↓
/*
    IF (ir_masters_rec.party_num IS NULL) THEN
*/
    IF (ir_masters_rec.party_num = gv_def_party_num) THEN
-- 2008/08/25 Mod ↑
      lv_account_number := ir_masters_rec.base_code;      -- 拠点コード
--
    -- 登録(顧客紐付き)
    ELSE
      lv_account_number := ir_masters_rec.party_num;      -- 顧客コード
    END IF;
--
    BEGIN
--
      SELECT hp.party_id,                                    -- パーティID
             hca.cust_account_id                             -- 顧客ID
      INTO   ir_masters_rec.p_party_id,
             ir_masters_rec.cust_account_id
      FROM   hz_parties       hp,                            -- パーティマスタ
             hz_cust_accounts hca                            -- 顧客マスタ
      WHERE  hca.party_id       = hp.party_id
      AND    hca.account_number = lv_account_number
      AND    ROWNUM             = 1;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ir_masters_rec.p_party_id      := NULL;
        ir_masters_rec.cust_account_id := NULL;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
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
  END get_party_id;
--
  /***********************************************************************************
   * Procedure Name   : get_party_site_id
   * Description      : パーティサイトマスタのサイトIDの取得を行います。
   ***********************************************************************************/
  PROCEDURE get_party_site_id(
    ir_masters_rec  IN OUT NOCOPY masters_rec,  -- チェック対象データ
    ob_retcd           OUT NOCOPY BOOLEAN,      -- 検索結果
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_party_site_id'; -- プログラム名
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
    ln_cnt               NUMBER;
    lv_status            hz_party_sites.status%TYPE;
    lv_account_number    hz_cust_accounts.account_number%TYPE;
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
/* 2008/08/18 Del ↓
    -- 2008/04/17 変更要求No61 対応
    -- 拠点紐付き
    IF ((ir_masters_rec.proc_code = gn_proc_s_upd)
     OR (ir_masters_rec.proc_code = gn_proc_s_del)
     OR (ir_masters_rec.proc_code = gn_proc_ds_del)) THEN
      lv_account_number := ir_masters_rec.base_code;       -- 拠点コード
--
    -- 顧客紐付き
    ELSIF ((ir_masters_rec.proc_code = gn_proc_c_upd)
     OR (ir_masters_rec.proc_code = gn_proc_c_del)
     OR (ir_masters_rec.proc_code = gn_proc_dc_del)) THEN
      lv_account_number := ir_masters_rec.party_num;       -- 顧客コード
    END IF;
2008/08/18 Del ↑ */
--
    BEGIN
--
      SELECT hps.party_id,                               -- パーティID
             hps.party_site_id,                          -- パーティサイトID
             hps.location_id,                            -- ロケーションID
             hps.status,                                 -- ステータス
             hp.party_number,                            -- 組織番号
             hps.object_version_number,                  -- オブジェクトバージョン番号
             hcas.cust_acct_site_id,                     -- 顧客サイトID
             hcas.object_version_number,                 -- オブジェクトバージョン番号
             hzl.location_id,                            -- ロケーションID             2008/08/25 Add
             hzl.object_version_number                   -- オブジェクトバージョン番号 2008/08/25 Add
      INTO   ir_masters_rec.p_party_id,
             ir_masters_rec.party_site_id,
             ir_masters_rec.location_id,
             ir_masters_rec.site_status,
             ir_masters_rec.party_number,
             ir_masters_rec.obj_site_number,
             ir_masters_rec.cust_acct_site_id,
             ir_masters_rec.obj_acct_number,
             ir_masters_rec.hzl_location_id,             -- 2008/08/25 Add
             ir_masters_rec.hzl_obj_number               -- 2008/08/25 Add
-- 2008/08/25 Mod ↓
/*
      FROM   hz_parties             hp,                  -- パーティマスタ
             hz_party_sites         hps,                 -- パーティサイトマスタ
             hz_cust_acct_sites_all hcas,                -- 顧客所在地マスタ
             hz_cust_accounts       hca                  -- 顧客マスタ
      WHERE  hp.party_id        = hps.party_id
      AND    hp.party_id        = hca.party_id
      AND    hps.party_site_id  = hcas.party_site_id
--      AND    hca.account_number = lv_account_number            -- 2008/08/18 Del
      AND    hps.status         = gv_status_on                   -- 有効 2008/08/18 Add
      AND    hcas.attribute18   = ir_masters_rec.ship_to_code;   -- 配送先コード
--      AND    ROWNUM = 1;                                       -- 2008/08/18 Del
*/
      FROM   hz_parties             hp,                  -- パーティマスタ
             hz_party_sites         hps,                 -- パーティサイトマスタ
             hz_cust_acct_sites_all hcas,                -- 顧客所在地マスタ
             hz_cust_accounts       hca,                 -- 顧客マスタ
             hz_locations           hzl                  -- 顧客事業所マスタ
      WHERE  hp.party_id        = hps.party_id
      AND    hp.party_id        = hca.party_id
      AND    hps.party_site_id  = hcas.party_site_id
      AND    hps.location_id    = hzl.location_id
      AND    hps.status         = gv_status_on                   -- 有効 2008/08/18 Add
      AND    hzl.province       = ir_masters_rec.ship_to_code;   -- 配送先コード
-- 2008/08/25 Mod ↑
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ob_retcd := FALSE;
        ir_masters_rec.p_party_id      := NULL;
        ir_masters_rec.party_site_id   := NULL;
        ir_masters_rec.location_id     := NULL;
        ir_masters_rec.site_status     := NULL;
        ir_masters_rec.party_number    := NULL;
        ir_masters_rec.obj_site_number := NULL;
        ir_masters_rec.hzl_location_id := NULL;             -- 2008/08/25 Add
        ir_masters_rec.hzl_obj_number  := NULL;             -- 2008/08/25 Add
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
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
  END get_party_site_id;
--
  /***********************************************************************************
   * Procedure Name   : get_party_site_id_2
   * Description      : パーティサイトマスタのサイトIDの取得を行います。
   ***********************************************************************************/
  PROCEDURE get_party_site_id_2(
    ir_masters_rec  IN OUT NOCOPY masters_rec,  -- チェック対象データ
    ob_retcd           OUT NOCOPY BOOLEAN,      -- 検索結果
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_party_site_id_2'; -- プログラム名
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
    ln_cnt               NUMBER;
    lv_status            hz_party_sites.status%TYPE;
    lv_account_number    hz_cust_accounts.account_number%TYPE;
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
    -- 登録(拠点紐付き)
-- 2008/08/25 Mod ↓
/*
    IF (ir_masters_rec.party_num IS NULL) THEN
*/
    IF (ir_masters_rec.party_num = gv_def_party_num) THEN
-- 2008/08/25 Mod ↑
      lv_account_number := ir_masters_rec.base_code;      -- 拠点コード
--
    -- 登録(顧客紐付き)
    ELSE
      lv_account_number := ir_masters_rec.party_num;      -- 顧客コード
    END IF;
--
    BEGIN
--
      SELECT hps.party_id,                               -- パーティID
             hps.party_site_id,                          -- パーティサイトID
             hps.location_id,                            -- ロケーションID
             hps.status,                                 -- ステータス
             hp.party_number,                            -- 組織番号
             hps.object_version_number,                  -- オブジェクトバージョン番号
             hcas.cust_acct_site_id,                     -- 顧客サイトID
             hcas.object_version_number,                 -- オブジェクトバージョン番号
             hzl.location_id,                            -- ロケーションID             2008/08/25 Add
             hzl.object_version_number                   -- オブジェクトバージョン番号 2008/08/25 Add
      INTO   ir_masters_rec.p_party_id,
             ir_masters_rec.party_site_id,
             ir_masters_rec.location_id,
             ir_masters_rec.site_status,
             ir_masters_rec.party_number,
             ir_masters_rec.obj_site_number,
             ir_masters_rec.cust_acct_site_id,
             ir_masters_rec.obj_acct_number,
             ir_masters_rec.hzl_location_id,             -- 2008/08/25 Add
             ir_masters_rec.hzl_obj_number               -- 2008/08/25 Add
-- 2008/08/25 Mod ↓
/*
      FROM   hz_parties             hp,                  -- パーティマスタ
             hz_party_sites         hps,                 -- パーティサイトマスタ
             hz_cust_acct_sites_all hcas,                -- 顧客所在地マスタ
             hz_cust_accounts       hca                  -- 顧客マスタ
      WHERE  hp.party_id        = hps.party_id
      AND    hp.party_id        = hca.party_id
      AND    hps.party_site_id  = hcas.party_site_id
      AND    hca.account_number = lv_account_number
      AND    hps.status         = gv_status_off                  -- 無効
      AND    hcas.attribute18   = ir_masters_rec.ship_to_code;   -- 配送先コード
*/
      FROM   hz_parties             hp,                  -- パーティマスタ
             hz_party_sites         hps,                 -- パーティサイトマスタ
             hz_cust_acct_sites_all hcas,                -- 顧客所在地マスタ
             hz_cust_accounts       hca,                 -- 顧客マスタ
             hz_locations           hzl                  -- 顧客事業所マスタ
      WHERE  hp.party_id        = hps.party_id
      AND    hp.party_id        = hca.party_id
      AND    hps.party_site_id  = hcas.party_site_id
      AND    hps.location_id    = hzl.location_id
      AND    hca.account_number = lv_account_number
      AND    hps.status         = gv_status_off                  -- 無効
      AND    hzl.province       = ir_masters_rec.ship_to_code;   -- 配送先コード
-- 2008/08/25 Mod ↑
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ob_retcd := FALSE;
        ir_masters_rec.p_party_id      := NULL;
        ir_masters_rec.party_site_id   := NULL;
        ir_masters_rec.location_id     := NULL;
        ir_masters_rec.site_status     := NULL;
        ir_masters_rec.party_number    := NULL;
        ir_masters_rec.obj_site_number := NULL;
        ir_masters_rec.hzl_location_id := NULL;             -- 2008/08/25 Add
        ir_masters_rec.hzl_obj_number  := NULL;             -- 2008/08/25 Add
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
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
  END get_party_site_id_2;
--
  /***********************************************************************************
   * Procedure Name   : get_site_to_if
   * Description      : パーティサイトマスタのサイトIDの取得を行います。
   ***********************************************************************************/
  PROCEDURE get_site_to_if(
    ir_masters_rec  IN OUT NOCOPY masters_rec,  -- チェック対象データ
    ob_retcd           OUT NOCOPY BOOLEAN,      -- 検索結果
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_site_to_if'; -- プログラム名
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
    ln_cnt               NUMBER;
    lv_status            hz_party_sites.status%TYPE;
    lv_account_number    hz_cust_accounts.account_number%TYPE;
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
    -- 2008/04/17 変更要求No61 対応
    -- 拠点紐付き
    IF ((ir_masters_rec.proc_code = gn_proc_s_upd)
     OR (ir_masters_rec.proc_code = gn_proc_s_del)
     OR (ir_masters_rec.proc_code = gn_proc_ds_del)) THEN
      lv_account_number := ir_masters_rec.base_code;      -- 拠点コード
--
    -- 顧客紐付き
    ELSIF ((ir_masters_rec.proc_code = gn_proc_c_upd)
     OR (ir_masters_rec.proc_code = gn_proc_c_del)
     OR (ir_masters_rec.proc_code = gn_proc_dc_del)) THEN
      lv_account_number := ir_masters_rec.party_num;      -- 顧客コード
    END IF;
--
    BEGIN
      SELECT hps.party_id,                               -- パーティID
             hps.party_site_id,                          -- パーティサイトID
             hps.location_id,                            -- ロケーションID
             hps.status,                                 -- ステータス
             hp.party_number,                            -- 組織番号
             hps.object_version_number,                  -- オブジェクトバージョン番号
             hcas.cust_acct_site_id,                     -- 顧客サイトID
             hcas.object_version_number                  -- オブジェクトバージョン番号
      INTO   ir_masters_rec.p_party_id,
             ir_masters_rec.party_site_id,
             ir_masters_rec.location_id,
             ir_masters_rec.site_status,
             ir_masters_rec.party_number,
             ir_masters_rec.obj_site_number,
             ir_masters_rec.cust_acct_site_id,
             ir_masters_rec.obj_acct_number
      FROM   hz_parties             hp,                  -- パーティマスタ
             hz_party_sites         hps,                 -- パーティサイトマスタ
             hz_cust_acct_sites_all hcas,                -- 顧客所在地マスタ
             hz_cust_accounts       hca                  -- 顧客マスタ
      WHERE  hp.party_id       = hps.party_id
      AND    hp.party_id       = hca.party_id
      AND    hps.party_site_id = hcas.party_site_id
      AND    hca.account_number = lv_account_number
      AND    hp.party_number IN (
        SELECT xsi.base_code
        FROM   xxcmn_site_if xsi
        WHERE  xsi.seq_number < ir_masters_rec.seq_number
        AND    xsi.ship_to_code = ir_masters_rec.ship_to_code
        AND    xsi.seq_number IN (
          SELECT MAX(xsi.seq_number)
          FROM   xxcmn_site_if xsi
          WHERE  xsi.seq_number < ir_masters_rec.seq_number
          AND    xsi.ship_to_code = ir_masters_rec.ship_to_code))
      AND    ROWNUM = 1;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ob_retcd := FALSE;
        ir_masters_rec.p_party_id      := NULL;
        ir_masters_rec.party_site_id   := NULL;
        ir_masters_rec.location_id     := NULL;
        ir_masters_rec.site_status     := NULL;
        ir_masters_rec.party_number    := NULL;
        ir_masters_rec.obj_site_number := NULL;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
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
  END get_site_to_if;
--
  /***********************************************************************************
   * Procedure Name   : get_site_number
   * Description      : パーティサイトマスタのサイトIDの取得を行います。
   ***********************************************************************************/
  PROCEDURE get_site_number(
    ir_masters_rec  IN OUT NOCOPY masters_rec,  -- チェック対象データ
    ob_retcd           OUT NOCOPY BOOLEAN,      -- 検索結果
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_site_number'; -- プログラム名
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
    ln_cnt               NUMBER;
    lv_status            hz_party_sites.status%TYPE;
    lv_account_number    hz_cust_accounts.account_number%TYPE;
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
    -- 2008/04/17 変更要求No61 対応
    -- 登録(拠点紐付き)
-- 2008/08/25 Mod ↓
/*
    IF (ir_masters_rec.party_num IS NULL) THEN
*/
    IF (ir_masters_rec.party_num = gv_def_party_num) THEN
-- 2008/08/25 Mod ↑
      lv_account_number := ir_masters_rec.base_code;      -- 拠点コード
--
    -- 登録(顧客紐付き)
    ELSE
      lv_account_number := ir_masters_rec.party_num;      -- 顧客コード
    END IF;
--
    BEGIN
--
      SELECT hps.party_id,
             hps.party_site_id,
             hps.location_id,
             hps.status,
             hp.party_number,
             hps.object_version_number,
             hcas.cust_acct_site_id,
             hcas.object_version_number
      INTO   ir_masters_rec.p_party_id,
             ir_masters_rec.party_site_id,
             ir_masters_rec.location_id,
             ir_masters_rec.site_status,
             ir_masters_rec.party_number,
             ir_masters_rec.obj_site_number,
             ir_masters_rec.cust_acct_site_id,
             ir_masters_rec.obj_acct_number
      FROM   hz_parties             hp,                  -- パーティマスタ
             hz_party_sites         hps,                 -- パーティサイトマスタ
             hz_cust_acct_sites_all hcas,                -- 顧客所在地マスタ
             hz_cust_accounts       hca                  -- 顧客マスタ
      WHERE  hp.party_id        = hps.party_id
      AND    hp.party_id        = hca.party_id
      AND    hps.party_site_id  = hcas.party_site_id
      AND    hca.account_number = lv_account_number
      AND    hps.status         = gv_status_on
      AND    ROWNUM             = 1;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ob_retcd := FALSE;
        ir_masters_rec.p_party_id      := NULL;
        ir_masters_rec.party_site_id   := NULL;
        ir_masters_rec.location_id     := NULL;
        ir_masters_rec.site_status     := NULL;
        ir_masters_rec.party_number    := NULL;
        ir_masters_rec.obj_site_number := NULL;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
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
  END get_site_number;
--
  /***********************************************************************************
   * Procedure Name   : exists_party_id
   * Description      : パーティIDの取得処理を行います。
   ***********************************************************************************/
  PROCEDURE exists_party_id(
    ir_masters_rec  IN OUT NOCOPY masters_rec,  -- チェック対象データ
    in_kbn          IN            NUMBER,       -- 処理区分
    iv_status       IN            VARCHAR2,     -- ステータス
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'exists_party_id'; -- プログラム名
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
    lb_retcd                        BOOLEAN;
    lv_account_number               hz_cust_accounts.account_number%TYPE;
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
    -- 2008/04/17 変更要求No61 対応
    -- 拠点単位
    IF (in_kbn = gn_kbn_party) THEN
      lv_account_number := ir_masters_rec.base_code;         -- 拠点コード
--
    -- 顧客単位
    ELSE
      lv_account_number := ir_masters_rec.party_num;         -- 顧客コード
    END IF;
--
    BEGIN
--
      SELECT hp.party_id,                               -- パーティID
             hp.validated_flag,                         -- 有効フラグ
             hp.object_version_number,                  -- オブジェクトバージョン番号(パーティ)
             hp.party_number,                           -- 組織番号
             hca.party_id,                              -- パーティID
             hca.status,                                -- 有効ステイタス
             hca.cust_account_id,                       -- 顧客ID
             hca.object_version_number                  -- オブジェクトバージョン番号(顧客)
      INTO   ir_masters_rec.p_party_id,
             ir_masters_rec.validated_flag,
             ir_masters_rec.obj_party_number,
             ir_masters_rec.party_number,
             ir_masters_rec.c_party_id,
             ir_masters_rec.status,
             ir_masters_rec.cust_account_id,
             ir_masters_rec.obj_cust_number
      FROM   hz_parties       hp,                       -- パーティマスタ
             hz_cust_accounts hca                       -- 顧客マスタ
      WHERE  hca.party_id       = hp.party_id
      AND    hca.account_number = lv_account_number
      AND    hca.status         = iv_status
      AND    ROWNUM             = 1;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ir_masters_rec.p_party_id       := NULL;
        ir_masters_rec.c_party_id       := NULL;
        ir_masters_rec.validated_flag   := NULL;
        ir_masters_rec.status           := NULL;
        ir_masters_rec.obj_party_number := NULL;
        ir_masters_rec.cust_account_id  := NULL;
        ir_masters_rec.obj_cust_number  := NULL;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
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
  END exists_party_id;
--
  /***********************************************************************************
   * Procedure Name   : exists_xxcmn_site_if
   * Description      : 顧客コードの存在チェックを行います。
   ***********************************************************************************/
  PROCEDURE exists_xxcmn_site_if(
    ir_masters_rec  IN OUT NOCOPY masters_rec, -- チェック対象データ
    in_kbn          IN            NUMBER,      -- 処理区分
    ob_retcd           OUT NOCOPY BOOLEAN,     -- 検索結果
    ov_errbuf          OUT NOCOPY VARCHAR2,    -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,    -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)    -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'exists_xxcmn_site_if'; -- プログラム名
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
    ln_cnt    NUMBER;
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
      -- 拠点
      IF (in_kbn = gn_kbn_party) THEN
        SELECT COUNT(xsi.seq_number)
        INTO   ln_cnt
        FROM   xxcmn_site_if xsi
        WHERE  xsi.ship_to_code = ir_masters_rec.ship_to_code  -- 配送先コードが同じ
        AND    xsi.base_code    = ir_masters_rec.base_code     -- 拠点コードが同じ
        AND    xsi.seq_number < ir_masters_rec.seq_number      -- SEQ番号が以前のデータ
        AND    (xsi.proc_code = gn_proc_insert                 -- 登録
        OR      xsi.proc_code = gn_proc_update)                -- 更新
        AND    ROWNUM = 1;
--
      -- 顧客
      ELSE
        SELECT COUNT(xsi.seq_number)
        INTO   ln_cnt
        FROM   xxcmn_site_if xsi
        WHERE  xsi.ship_to_code = ir_masters_rec.ship_to_code  -- 配送先コードが同じ
        AND    xsi.party_num    = ir_masters_rec.party_num     -- 顧客コードが同じ
        AND    xsi.seq_number < ir_masters_rec.seq_number      -- SEQ番号が以前のデータ
        AND    (xsi.proc_code = gn_proc_insert                 -- 登録
        OR      xsi.proc_code = gn_proc_update)                -- 更新
        AND    ROWNUM = 1;
      END IF;
--
    IF (ln_cnt < 1) THEN
      ob_retcd := FALSE;
    END IF;
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
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
  END exists_xxcmn_site_if;
--
  /***********************************************************************************
   * Procedure Name   : chk_party_status
   * Description      : パーティマスタ・顧客マスタのステータスのチェックを行います。
   ***********************************************************************************/
  PROCEDURE chk_party_status(
    ir_masters_rec  IN OUT NOCOPY masters_rec,  -- チェック対象データ
    on_kbn             OUT NOCOPY NUMBER,       -- チェック結果
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_party_status'; -- プログラム名
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
    ln_hca_on   NUMBER;
    ln_hca_off  NUMBER;
    ln_hp_on    NUMBER;
    ln_hp_off   NUMBER;
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
    on_kbn := gn_data_nothing;
--
    -- 2008/04/17 変更要求No61 対応
    -- 顧客マスタ・ステータス
    -- パーティマスタ・有効フラグ
    SELECT SUM(NVL(DECODE(hca.status,gv_status_on,1),0)),
           SUM(NVL(DECODE(hca.status,gv_status_off,1),0)),
           SUM(NVL(DECODE(hp.validated_flag,gv_validated_flag_on,1),0)),
           SUM(NVL(DECODE(hp.validated_flag,gv_validated_flag_off,1),0))
    INTO   ln_hca_on,
           ln_hca_off,
           ln_hp_on,
           ln_hp_off
    FROM   hz_parties       hp,                          -- パーティマスタ
           hz_cust_accounts hca                          -- 顧客マスタ
    WHERE  hca.party_id       = hp.party_id
    AND    hca.account_number = ir_masters_rec.party_num;                    -- 顧客コード
--
    -- 有効
    IF ((ln_hca_on > 0) AND (ln_hp_on > 0)) THEN
      on_kbn := gn_data_on;
    ELSE
      -- 無効
      IF((ln_hca_off > 0) AND (ln_hp_off > 0)) THEN
        on_kbn := gn_data_off;
      END IF;
    END IF;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
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
  END chk_party_status;
--
  /***********************************************************************************
   * Procedure Name   : chk_site_status
   * Description      : パーティサイトマスタのステータスのチェックを行います。
   ***********************************************************************************/
  PROCEDURE chk_site_status(
    ir_masters_rec  IN OUT NOCOPY masters_rec,  -- チェック対象データ
    on_kbn             OUT NOCOPY NUMBER,       -- チェック結果
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_site_status'; -- プログラム名
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
    ln_on_cnt            NUMBER;
    ln_off_cnt           NUMBER;
    lv_account_number    hz_cust_accounts.account_number%TYPE;
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
    on_kbn := gn_data_nothing;
-- 2008/08/18 Mod ↓
/*
--
    -- 2008/04/17 変更要求No61 対応
    -- 登録(拠点紐付き)
    IF (ir_masters_rec.party_num IS NULL) THEN
      lv_account_number := ir_masters_rec.base_code;      -- 拠点コード
--
    -- 登録(顧客紐付き)
    ELSE
      lv_account_number := ir_masters_rec.party_num;      -- 顧客コード
    END IF;

--
    SELECT SUM(NVL(DECODE(hps.status,gv_status_on,1),0)),          --ステータス有効
           SUM(NVL(DECODE(hps.status,gv_status_off,1),0))          --ステータス無効
    INTO   ln_on_cnt,
           ln_off_cnt
    FROM   hz_party_sites   hps,                         -- パーティサイトマスタ
           hz_cust_accounts hca                          -- 顧客マスタ
    WHERE  hps.party_id       = hca.party_id
    AND    hca.account_number = lv_account_number;
*/
    SELECT SUM(NVL(DECODE(hps.status,gv_status_on,1),0)),          --ステータス有効
           SUM(NVL(DECODE(hps.status,gv_status_off,1),0))          --ステータス無効
    INTO   ln_on_cnt,
           ln_off_cnt
-- 2008/08/25 Mod ↓
/*
    FROM   hz_party_sites         hps,                   -- パーティサイトマスタ
           hz_cust_acct_sites_all hcas                   -- 顧客所在地マスタ
    WHERE  hps.party_site_id  = hcas.party_site_id
    AND    hcas.attribute18   = ir_masters_rec.ship_to_code;   -- 配送先コード
*/
    FROM   hz_party_sites         hps,                   -- パーティサイトマスタ
           hz_locations           hzl                   -- 顧客事業所マスタ
    WHERE  hps.location_id  = hzl.location_id
    AND    hzl.province     = ir_masters_rec.ship_to_code;   -- 配送先コード
-- 2008/08/25 Mod ↑
-- 2008/08/18 Mod ↑
--
    -- 有効あり
    IF (ln_on_cnt > 0) THEN
      on_kbn := gn_data_on;
    ELSE
      -- 無効あり
      IF (ln_off_cnt > 0) THEN
        on_kbn := gn_data_off;
      END IF;
    END IF;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
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
  END chk_site_status;
--
  /***********************************************************************************
   * Procedure Name   : chk_party_num
   * Description      : 顧客コードの存在チェックを行います。
   ***********************************************************************************/
  PROCEDURE chk_party_num(
    ir_masters_rec  IN OUT NOCOPY masters_rec,  -- チェック対象データ
    iv_status       IN            VARCHAR2,     -- ステータス
    ov_retcd           OUT NOCOPY BOOLEAN,      -- 検索結果
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_party_num'; -- プログラム名
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
    ov_retcd := FALSE;
--
    -- 2008/04/17 変更要求No61 対応
    SELECT COUNT(hca.status)
    INTO   ln_cnt
    FROM   hz_cust_accounts hca
    WHERE  hca.account_number = ir_masters_rec.party_num       -- 顧客コード
    AND    hca.status         = iv_status
    AND    ROWNUM             = 1;
--
    IF (ln_cnt > 0) THEN
      ov_retcd := TRUE;
    END IF;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
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
  END chk_party_num;
--
  /***********************************************************************************
   * Procedure Name   : chk_party_num_if
   * Description      : 顧客コードの存在チェックを行います。
   ***********************************************************************************/
  PROCEDURE chk_party_num_if(
    ir_masters_rec  IN OUT NOCOPY masters_rec,  -- チェック対象データ
    ov_retcd           OUT NOCOPY BOOLEAN,      -- 検索結果
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_party_num_if'; -- プログラム名
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
    ov_retcd := FALSE;
--
    SELECT COUNT(xsi.proc_code)
    INTO   ln_cnt
    FROM   xxcmn_site_if xsi
-- 2008/10/01 v1.10 UPDATE START
--    WHERE  xsi.ship_to_code = ir_masters_rec.ship_to_code  -- 配送先コードが同じ
--    AND    xsi.party_num = ir_masters_rec.party_num        -- 顧客コードが同じ
    WHERE  xsi.party_num = ir_masters_rec.party_num        -- 顧客コードが同じ
-- 2008/10/01 v1.10 UPDATE END
    AND    (xsi.proc_code = gn_proc_insert                 -- 登録
    OR      xsi.proc_code = gn_proc_update)                -- 更新
    AND    xsi.seq_number < ir_masters_rec.seq_number      -- SEQ番号が以前のデータ
    AND    ROWNUM = 1;
--
    IF (ln_cnt > 0) THEN
      ov_retcd := TRUE;
    END IF;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
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
  END chk_party_num_if;
--
  /***********************************************************************************
   * Procedure Name   : exists_party_number
   * Description      : パーティサイトマスタの存在チェックを行います。
   ***********************************************************************************/
  PROCEDURE exists_party_number(
    ir_masters_rec  IN OUT NOCOPY masters_rec,  -- チェック対象データ
    iv_status       IN            VARCHAR2,     -- チェックステータス
    ob_retcd           OUT NOCOPY BOOLEAN,      -- 検索結果
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'exists_party_number'; -- プログラム名
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
    ln_cnt               NUMBER;
    lv_account_number    hz_cust_accounts.account_number%TYPE;
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
    ob_retcd := FALSE;
--
    -- 2008/04/17 変更要求No61 対応
    -- 顧客コード=NULL
-- 2008/08/25 Mod ↓
/*
    IF (ir_masters_rec.party_num IS NULL) THEN
*/
    IF (ir_masters_rec.party_num = gv_def_party_num) THEN
-- 2008/08/25 Mod ↑
      lv_account_number := ir_masters_rec.base_code;       -- 拠点コード
--
    -- 顧客コード<>NULL
    ELSE
      lv_account_number := ir_masters_rec.party_num;       -- 顧客コード
    END IF;
-- 2008/08/18 Mod ↓
/*
    SELECT COUNT(hps.party_site_id)
    INTO   ln_cnt
    FROM   hz_party_sites   hps,                         -- パーティサイトマスタ
           hz_cust_accounts hca                          -- 顧客マスタ
    WHERE  hps.party_id       = hca.party_id
    AND    hca.account_number = lv_account_number
    AND    hps.status         = iv_status
    AND    ROWNUM             = 1;
*/
-- 2008/08/18 Mod ↑
    SELECT COUNT(hps.party_site_id)
    INTO   ln_cnt
-- 2008/08/25 Mod ↓
/*
    FROM   hz_party_sites         hps,                   -- パーティサイトマスタ
           hz_cust_accounts       hca,                   -- 顧客マスタ
           hz_cust_acct_sites_all hcas                   -- 顧客所在地マスタ
    WHERE  hps.party_site_id  = hcas.party_site_id
    AND    hps.party_id       = hca.party_id
    AND    hca.account_number = lv_account_number
    AND    hcas.attribute18   = ir_masters_rec.ship_to_code    -- 配送先コード
    AND    hps.status         = iv_status;
*/
    FROM   hz_party_sites         hps,                   -- パーティサイトマスタ
           hz_cust_accounts       hca,                   -- 顧客マスタ
           hz_locations           hzl                    -- 顧客事業所マスタ
    WHERE  hps.location_id    = hzl.location_id
    AND    hps.party_id       = hca.party_id
    AND    hca.account_number = lv_account_number
    AND    hzl.province       = ir_masters_rec.ship_to_code    -- 配送先コード
    AND    hps.status         = iv_status;
-- 2008/08/25 Mod ↑
--
    IF (ln_cnt > 0) THEN
      ob_retcd := TRUE;
    END IF;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
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
  END exists_party_number;
--
  /***********************************************************************************
   * Procedure Name   : check_proc_code
   * Description      : 操作対象のデータであることを確認します。
   ***********************************************************************************/
  PROCEDURE check_proc_code(
    in_proc_code   IN            NUMBER,      -- チェック対象区分
    ir_status_rec  IN OUT NOCOPY status_rec,  -- 処理状況
    ov_errbuf         OUT NOCOPY VARCHAR2,    -- エラー・メッセージ           --# 固定 #
    ov_retcode        OUT NOCOPY VARCHAR2,    -- リターン・コード             --# 固定 #
    ov_errmsg         OUT NOCOPY VARCHAR2)    -- ユーザー・エラー・メッセージ --# 固定 #
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
    --処理区分が（登録・更新・削除）以外
    IF ((in_proc_code <> gn_proc_insert)
    AND (in_proc_code <> gn_proc_update)
    AND (in_proc_code <> gn_proc_delete)) THEN
--
      set_error_status(ir_status_rec,
                       xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_80a_019,
                                                'VALUE',    TO_CHAR(in_proc_code)),
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
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
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
   * Procedure Name   : check_base_code
   * Description      : 拠点コードチェックを行います。(A-2)
   ***********************************************************************************/
  PROCEDURE check_base_code(
    ir_status_rec   IN OUT NOCOPY status_rec,   -- 処理状況
    ir_masters_rec  IN OUT NOCOPY masters_rec,  -- チェック対象データ
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_base_code'; -- プログラム名
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
    ln_kbn     NUMBER;
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
    -- パーティマスタ存在チェック
    get_hz_parties(ir_masters_rec,
                   gn_kbn_party,
                   lv_errbuf,
                   lv_retcode,
                   lv_errmsg);
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    -- 顧客マスタ存在チェック
    get_hz_cust_accounts(ir_masters_rec,
                         gn_kbn_party,
                         lv_errbuf,
                         lv_retcode,
                         lv_errmsg);
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    ln_kbn := gn_data_init;
--
    -- 顧客・パーティマスタのチェック
    ln_kbn := chk_party_id(ir_masters_rec);
--
    IF (ln_kbn = gn_data_init) THEN
--
        -- 拠点対象外レコード
      set_error_status(ir_status_rec,
                       xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                gv_msg_80a_033,
                                                gv_tkn_ng_kyoten,
                                                ir_masters_rec.base_code),
                       lv_errbuf,
                       lv_retcode,
                       lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
      RAISE check_base_code_expt;
    END IF;
--
    -- ===============================
    -- 登録
    -- ===============================
    IF (ir_masters_rec.proc_code = gn_proc_insert) THEN
--
      -- 出庫管理元区分 = '0'
      IF (ir_masters_rec.ship_mng_code = gv_mode_on) THEN
--
        -- 顧客＆パーティマスタデータなし
        IF (ln_kbn = gn_data_nothing) THEN
--
          -- 以前に同じデータが存在しない
          IF (((ir_masters_rec.row_o_ins_cnt = 0)
           AND (ir_masters_rec.row_o_upd_cnt = 0) AND (ir_masters_rec.row_o_del_cnt = 0))
          AND ((ir_masters_rec.row_z_ins_cnt = 0)
           AND (ir_masters_rec.row_z_upd_cnt = 0) AND (ir_masters_rec.row_z_del_cnt = 0))) THEN
--
            -- 登録処理
            ir_masters_rec.proc_code := gn_proc_insert;
--
          -- 以前に同じデータが存在する
          ELSE
--
            -- 登録分の重複チェックエラー
            set_error_status(ir_status_rec,
                             xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                      gv_msg_80a_032,
                                                      gv_tkn_ng_kyoten,
                                                      ir_masters_rec.base_code),
                             lv_errbuf,
                             lv_retcode,
                             lv_errmsg);
--
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_api_expt;
            END IF;
            RAISE check_base_code_expt;
          END IF;
        END IF;
--
        -- 顧客＆パーティマスタデータあり(無効)
        IF (ln_kbn = gn_data_off) THEN
--
          -- 以前に同じデータが存在しない
          IF (((ir_masters_rec.row_o_ins_cnt = 0)
           AND (ir_masters_rec.row_o_upd_cnt = 0) AND (ir_masters_rec.row_o_del_cnt = 0))
          AND ((ir_masters_rec.row_z_ins_cnt = 0)
           AND (ir_masters_rec.row_z_upd_cnt = 0) AND (ir_masters_rec.row_z_del_cnt = 0))) THEN
--
            -- 更新処理に変換
            ir_masters_rec.proc_code := gn_proc_update;
            ir_masters_rec.validated_flag := gv_validated_flag_on;
            ir_masters_rec.status := gv_status_on;
--
          -- 以前に同じデータが存在する
          ELSE
--
            -- 登録分の重複チェックエラー
            set_error_status(ir_status_rec,
                             xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                      gv_msg_80a_032,
                                                      gv_tkn_ng_kyoten,
                                                      ir_masters_rec.base_code),
                             lv_errbuf,
                             lv_retcode,
                             lv_errmsg);
--
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_api_expt;
            END IF;
            RAISE check_base_code_expt;
          END IF;
        END IF;
--
        -- 顧客＆パーティマスタデータあり(有効)
        IF (ln_kbn = gn_data_on) THEN
--
            -- 登録分の重複チェックエラー
          set_error_status(ir_status_rec,
                             xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                      gv_msg_80a_032,
                                                      gv_tkn_ng_kyoten,
                                                      ir_masters_rec.base_code),
                           lv_errbuf,
                           lv_retcode,
                           lv_errmsg);
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_api_expt;
          END IF;
          RAISE check_base_code_expt;
        END IF;
      END IF;
--
      -- 出庫管理元区分 <> '0'
      IF (ir_masters_rec.ship_mng_code <> gv_mode_on) THEN
--
        -- 拠点対象外レコード(ワーニング)
        set_warn_status(ir_status_rec,
                        xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                 gv_msg_80a_033,
                                                 gv_tkn_ng_kyoten,
                                                 ir_masters_rec.base_code),
                         lv_errbuf,
                         lv_retcode,
                         lv_errmsg);
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
        END IF;
        RAISE check_base_code_expt;
      END IF;
      RAISE check_base_code_expt;
    END IF;
--
    -- ===============================
    -- 更新
    -- ===============================
    IF (ir_masters_rec.proc_code = gn_proc_update) THEN
--
      -- 出庫管理元区分 = '0'
      IF (ir_masters_rec.ship_mng_code = gv_mode_on) THEN
--
        -- 顧客＆パーティマスタデータなし
        IF (ln_kbn = 1) THEN
--
          -- 以前に同じデータが存在しない
          IF (((ir_masters_rec.row_o_ins_cnt = 0)
           AND (ir_masters_rec.row_o_upd_cnt = 0) AND (ir_masters_rec.row_o_del_cnt = 0))
          AND ((ir_masters_rec.row_z_ins_cnt = 0)
           AND (ir_masters_rec.row_z_upd_cnt = 0) AND (ir_masters_rec.row_z_del_cnt = 0))) THEN
            -- 登録処理に変換
            ir_masters_rec.proc_code := gn_proc_insert;
--
          -- 以前に出庫管理元区分='0'の登録・更新データが存在する
          ELSIF ((ir_masters_rec.row_o_ins_cnt <> 0) OR (ir_masters_rec.row_o_upd_cnt <> 0)) THEN
              -- 更新処理
              ir_masters_rec.proc_code := gn_proc_update;
--
          -- 以前に出庫管理元区分<>'0'の登録・更新データが存在する
          ELSIF ((ir_masters_rec.row_z_ins_cnt <> 0) OR (ir_masters_rec.row_z_upd_cnt <> 0)) THEN
              -- 登録処理
              ir_masters_rec.proc_code := gn_proc_insert;
--
          -- 以前に削除データが存在する
          ELSE
--
            -- 拠点対象外レコード
            set_warn_status(ir_status_rec,
                            xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                     gv_msg_80a_033,
                                                     gv_tkn_ng_kyoten,
                                                     ir_masters_rec.base_code),
                             lv_errbuf,
                             lv_retcode,
                             lv_errmsg);
--
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_api_expt;
            END IF;
            RAISE check_base_code_expt;
          END IF;
        END IF;
--
        -- 顧客＆パーティマスタデータあり(無効)
        IF (ln_kbn = 2) THEN
          ir_masters_rec.validated_flag := gv_validated_flag_on;
          ir_masters_rec.status := gv_status_on;
        END IF;
--
        -- 顧客＆パーティマスタデータあり(有効)
        IF (ln_kbn = gn_data_on) THEN
          -- 更新処理
          ir_masters_rec.proc_code := gn_proc_update;
        END IF;
      END IF;
--
      -- 出庫管理元区分 <> '0'
      IF (ir_masters_rec.ship_mng_code <> gv_mode_on) THEN
        -- 顧客＆パーティマスタデータなし
        -- 顧客＆パーティマスタデータあり(無効)
        IF ((ln_kbn = gn_data_nothing) OR (ln_kbn = gn_data_off)) THEN
--
          -- 以前に同じデータが存在しない
          IF (((ir_masters_rec.row_o_ins_cnt = 0)
           AND (ir_masters_rec.row_o_upd_cnt = 0) AND (ir_masters_rec.row_o_del_cnt = 0))
          AND ((ir_masters_rec.row_z_ins_cnt = 0)
           AND (ir_masters_rec.row_z_upd_cnt = 0) AND (ir_masters_rec.row_z_del_cnt = 0))) THEN
--
            -- 拠点対象外レコード
            set_warn_status(ir_status_rec,
                            xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                     gv_msg_80a_033,
                                                     gv_tkn_ng_kyoten,
                                                     ir_masters_rec.base_code),
                            lv_errbuf,
                            lv_retcode,
                            lv_errmsg);
--
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_api_expt;
            END IF;
            RAISE check_base_code_expt;
--
          -- 以前に出庫管理元区分='0'の登録・更新データが存在する
          ELSIF ((ir_masters_rec.row_o_ins_cnt <> 0) OR (ir_masters_rec.row_o_upd_cnt <> 0)) THEN
            -- 削除処理に変換
            ir_masters_rec.proc_code := gn_proc_delete;
--
            -- 以前に出庫管理元区分<>'0'の登録・更新データが存在する
          ELSIF ((ir_masters_rec.row_z_ins_cnt <> 0) OR (ir_masters_rec.row_z_upd_cnt <> 0)) THEN
--
            -- 拠点対象外レコード
            set_warn_status(ir_status_rec,
                            xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                     gv_msg_80a_033,
                                                     gv_tkn_ng_kyoten,
                                                     ir_masters_rec.base_code),
                            lv_errbuf,
                            lv_retcode,
                            lv_errmsg);
--
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_api_expt;
            END IF;
            RAISE check_base_code_expt;
--
          -- 以前に削除データが存在する
          ELSE
            -- 拠点対象外レコード
            set_warn_status(ir_status_rec,
                           xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                    gv_msg_80a_033,
                                                    gv_tkn_ng_kyoten,
                                                    ir_masters_rec.base_code),
                            lv_errbuf,
                            lv_retcode,
                            lv_errmsg);
--
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_api_expt;
            END IF;
            RAISE check_base_code_expt;
          END IF;
        END IF;
--
        -- 顧客＆パーティマスタデータあり(有効)
        IF (ln_kbn = gn_data_on) THEN
          -- 以前に同じデータが存在しない
          IF (((ir_masters_rec.row_o_ins_cnt = 0)
           AND (ir_masters_rec.row_o_upd_cnt = 0) AND (ir_masters_rec.row_o_del_cnt = 0))
          AND ((ir_masters_rec.row_z_ins_cnt = 0)
           AND (ir_masters_rec.row_z_upd_cnt = 0) AND (ir_masters_rec.row_z_del_cnt = 0))) THEN
            -- 削除処理に変換
            ir_masters_rec.proc_code := gn_proc_delete;
--
          -- 以前に出庫管理元区分='0'の登録・更新データが存在する
          ELSIF ((ir_masters_rec.row_o_ins_cnt <> 0) OR (ir_masters_rec.row_o_upd_cnt <> 0)) THEN
            -- 削除処理に変換
            ir_masters_rec.proc_code := gn_proc_delete;
--
          -- 以前に出庫管理元区分<>'0'の登録・更新データが存在する
          ELSIF ((ir_masters_rec.row_z_ins_cnt <> 0) OR (ir_masters_rec.row_z_upd_cnt <> 0)) THEN
--
            -- 拠点対象外レコード
            set_warn_status(ir_status_rec,
                            xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                     gv_msg_80a_033,
                                                     gv_tkn_ng_kyoten,
                                                     ir_masters_rec.base_code),
                           lv_errbuf,
                           lv_retcode,
                           lv_errmsg);
--
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_api_expt;
            END IF;
            RAISE check_base_code_expt;
--
          -- 以前に削除データが存在する
          ELSE
--
            -- 拠点対象外レコード
            set_warn_status(ir_status_rec,
                            xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                     gv_msg_80a_033,
                                                     gv_tkn_ng_kyoten,
                                                     ir_masters_rec.base_code),
                            lv_errbuf,
                            lv_retcode,
                            lv_errmsg);
--
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_api_expt;
            END IF;
            RAISE check_base_code_expt;
          END IF;
        END IF;
      END IF;
      RAISE check_base_code_expt;
    END IF;
--
    -- ===============================
    -- 削除
    -- ===============================
    IF (ir_masters_rec.proc_code = gn_proc_delete) THEN
--
      -- 出庫管理元区分 = '0'
      IF (ir_masters_rec.ship_mng_code = gv_mode_on) THEN
--
        -- 顧客＆パーティマスタデータなし
        -- 顧客＆パーティマスタデータあり(無効)
        IF ((ln_kbn = gn_data_nothing) OR (ln_kbn = gn_data_off))THEN
          -- 以前に同じデータが存在しない
          IF (((ir_masters_rec.row_o_ins_cnt = 0)
           AND (ir_masters_rec.row_o_upd_cnt = 0) AND (ir_masters_rec.row_o_del_cnt = 0))
          AND ((ir_masters_rec.row_z_ins_cnt = 0)
           AND (ir_masters_rec.row_z_upd_cnt = 0) AND (ir_masters_rec.row_z_del_cnt = 0))) THEN
--
            -- 削除分の存在チェックワーニング
            set_warn_status(ir_status_rec,
                            xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                     gv_msg_80a_031,
                                                     gv_tkn_ng_kyoten,
                                                     ir_masters_rec.base_code),
                            lv_errbuf,
                            lv_retcode,
                            lv_errmsg);
--
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_api_expt;
            END IF;
            RAISE check_base_code_expt;
--
          -- 以前に出庫管理元区分='0'の登録・更新データが存在する
          ELSIF ((ir_masters_rec.row_o_ins_cnt <> 0) OR (ir_masters_rec.row_o_upd_cnt <> 0)) THEN
            -- 削除処理
            ir_masters_rec.proc_code := gn_proc_delete;
--
          -- 以前に出庫管理元区分<>'0'の登録・更新データが存在する
          ELSIF ((ir_masters_rec.row_z_ins_cnt <> 0) OR (ir_masters_rec.row_z_upd_cnt <> 0)) THEN
--
            -- 削除分の存在チェックワーニング
            set_warn_status(ir_status_rec,
                            xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                     gv_msg_80a_031,
                                                     gv_tkn_ng_kyoten,
                                                     ir_masters_rec.base_code),
                            lv_errbuf,
                            lv_retcode,
                            lv_errmsg);
--
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_api_expt;
            END IF;
            RAISE check_base_code_expt;
--
          -- 以前に削除データが存在する
          ELSE
--
            -- 拠点対象外レコード
            set_warn_status(ir_status_rec,
                            xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                     gv_msg_80a_033,
                                                     gv_tkn_ng_kyoten,
                                                     ir_masters_rec.base_code),
                            lv_errbuf,
                            lv_retcode,
                            lv_errmsg);
--
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_api_expt;
            END IF;
            RAISE check_base_code_expt;
          END IF;
        END IF;
--
        -- 顧客＆パーティマスタデータあり(有効)
        IF (ln_kbn = gn_data_on) THEN
--
          -- 以前に同じデータが存在しない
          IF (((ir_masters_rec.row_o_ins_cnt = 0)
           AND (ir_masters_rec.row_o_upd_cnt = 0) AND (ir_masters_rec.row_o_del_cnt = 0))
          AND ((ir_masters_rec.row_z_ins_cnt = 0)
           AND (ir_masters_rec.row_z_upd_cnt = 0) AND (ir_masters_rec.row_z_del_cnt = 0))) THEN
            -- 削除処理
            ir_masters_rec.proc_code := gn_proc_delete;
--
          -- 以前に出庫管理元区分='0'の登録・更新データが存在する
          ELSIF ((ir_masters_rec.row_o_ins_cnt <> 0) OR (ir_masters_rec.row_o_upd_cnt <> 0)) THEN
            -- 削除処理
            ir_masters_rec.proc_code := gn_proc_delete;
--
          -- 以前に出庫管理元区分<>'0'の登録・更新データが存在する
          ELSIF ((ir_masters_rec.row_z_ins_cnt <> 0) OR (ir_masters_rec.row_z_upd_cnt <> 0)) THEN
--
            -- 削除分の存在チェックワーニング
            set_warn_status(ir_status_rec,
                            xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                     gv_msg_80a_031,
                                                     gv_tkn_ng_kyoten,
                                                     ir_masters_rec.base_code),
                            lv_errbuf,
                            lv_retcode,
                            lv_errmsg);
--
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_api_expt;
            END IF;
            RAISE check_base_code_expt;
--
          -- 以前に削除データが存在する
          ELSE
            -- 拠点対象外レコード
            set_warn_status(ir_status_rec,
                            xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                     gv_msg_80a_033,
                                                     gv_tkn_ng_kyoten,
                                                     ir_masters_rec.base_code),
                            lv_errbuf,
                            lv_retcode,
                            lv_errmsg);
--
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_api_expt;
            END IF;
            RAISE check_base_code_expt;
          END IF;
        END IF;
      END IF;
--
      -- 出庫管理元区分 <> '0'
      IF (ir_masters_rec.ship_mng_code <> gv_mode_on) THEN
        -- 顧客＆パーティマスタデータなし
        -- 顧客＆パーティマスタデータあり(無効)
        IF ((ln_kbn = gn_data_nothing) OR (ln_kbn = gn_data_off)) THEN
--
          -- 以前に同じデータが存在しない
          IF (((ir_masters_rec.row_o_ins_cnt = 0)
           AND (ir_masters_rec.row_o_upd_cnt = 0) AND (ir_masters_rec.row_o_del_cnt = 0))
          AND ((ir_masters_rec.row_z_ins_cnt = 0)
           AND (ir_masters_rec.row_z_upd_cnt = 0) AND (ir_masters_rec.row_z_del_cnt = 0))) THEN
--
            -- 拠点対象外レコード
            set_warn_status(ir_status_rec,
                            xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                     gv_msg_80a_033,
                                                     gv_tkn_ng_kyoten,
                                                     ir_masters_rec.base_code),
                            lv_errbuf,
                            lv_retcode,
                            lv_errmsg);
--
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_api_expt;
            END IF;
            RAISE check_base_code_expt;
--
          -- 以前に出庫管理元区分='0'の登録・更新データが存在する
          ELSIF ((ir_masters_rec.row_o_ins_cnt <> 0) OR (ir_masters_rec.row_o_upd_cnt <> 0)) THEN
            -- 削除処理
            ir_masters_rec.proc_code := gn_proc_delete;
--
          -- 以前に出庫管理元区分<>'0'の登録・更新データが存在する
          ELSIF ((ir_masters_rec.row_z_ins_cnt <> 0) OR (ir_masters_rec.row_z_upd_cnt <> 0)) THEN
--
            -- 拠点対象外レコード
            set_warn_status(ir_status_rec,
                            xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                     gv_msg_80a_033,
                                                     gv_tkn_ng_kyoten,
                                                     ir_masters_rec.base_code),
                            lv_errbuf,
                            lv_retcode,
                            lv_errmsg);
--
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_api_expt;
            END IF;
            RAISE check_base_code_expt;
--
          -- 以前に削除データが存在する
          ELSE
--
            -- 拠点対象外レコード
            set_warn_status(ir_status_rec,
                            xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                     gv_msg_80a_033,
                                                     gv_tkn_ng_kyoten,
                                                     ir_masters_rec.base_code),
                            lv_errbuf,
                            lv_retcode,
                            lv_errmsg);
--
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_api_expt;
            END IF;
            RAISE check_base_code_expt;
          END IF;
        END IF;
--
        -- 顧客＆パーティマスタデータあり(有効)
        IF (ln_kbn = gn_data_on) THEN
--
          -- 以前に同じデータが存在しない
          IF (((ir_masters_rec.row_o_ins_cnt = 0)
           AND (ir_masters_rec.row_o_upd_cnt = 0) AND (ir_masters_rec.row_o_del_cnt = 0))
          AND ((ir_masters_rec.row_z_ins_cnt = 0)
           AND (ir_masters_rec.row_z_upd_cnt = 0) AND (ir_masters_rec.row_z_del_cnt = 0))) THEN
            -- 削除処理
            ir_masters_rec.proc_code := gn_proc_delete;
--
          -- 以前に出庫管理元区分='0'の登録・更新データが存在する
          ELSIF ((ir_masters_rec.row_o_ins_cnt <> 0) OR (ir_masters_rec.row_o_upd_cnt <> 0)) THEN
            -- 削除処理
            ir_masters_rec.proc_code := gn_proc_delete;
--
          -- 以前に出庫管理元区分<>'0'の登録・更新データが存在する
          ELSIF ((ir_masters_rec.row_z_ins_cnt <> 0) OR (ir_masters_rec.row_z_upd_cnt <> 0)) THEN
--
            -- 拠点対象外レコード
            set_warn_status(ir_status_rec,
                            xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                     gv_msg_80a_033,
                                                     gv_tkn_ng_kyoten,
                                                     ir_masters_rec.base_code),
                            lv_errbuf,
                            lv_retcode,
                            lv_errmsg);
--
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_api_expt;
            END IF;
            RAISE check_base_code_expt;
--
          -- 以前に削除データが存在する
          ELSE
--
            -- 拠点対象外レコード
            set_warn_status(ir_status_rec,
                            xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                     gv_msg_80a_033,
                                                     gv_tkn_ng_kyoten,
                                                     ir_masters_rec.base_code),
                            lv_errbuf,
                            lv_retcode,
                            lv_errmsg);
--
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_api_expt;
            END IF;
            RAISE check_base_code_expt;
          END IF;
        END IF;
      END IF;
      RAISE check_base_code_expt;
    END IF;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN check_base_code_expt THEN
      NULL;
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
  END check_base_code;
--
  /***********************************************************************************
   * Procedure Name   : check_party_num
   * Description      : 顧客コードのチェックを行います。(A-7)
   ***********************************************************************************/
  PROCEDURE check_party_num(
    ir_status_rec   IN OUT NOCOPY status_rec,  -- 処理状況
    ir_masters_rec  IN OUT NOCOPY masters_rec, -- チェック対象データ
    ov_errbuf          OUT NOCOPY VARCHAR2,    -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,    -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)    -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_party_num'; -- プログラム名
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
    ln_kbn     NUMBER;
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
--#####################################  固定部 END   #############################################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 顧客コード=NULL
-- 2008/08/25 Mod ↓
/*
    IF (ir_masters_rec.party_num IS NULL) THEN
*/
    IF (ir_masters_rec.party_num = gv_def_party_num) THEN
-- 2008/08/25 Mod ↑
--
      -- 処理スキップ
      set_warn_status(ir_status_rec,
                      NULL,
                      lv_errbuf,
                      lv_retcode,
                      lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      RAISE check_party_num_expt;
    END IF;
--
    -- ステータスチェック
    chk_party_status(ir_masters_rec,
                     ln_kbn,
                     lv_errbuf,
                     lv_retcode,
                     lv_errmsg);
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
-- 2008/10/01 v1.10 UPDATE START
/*
    -- ===============================
    -- 登録
    -- ===============================
    IF (ir_masters_rec.k_proc_code = gn_proc_insert) THEN
--
      -- 顧客・パーティマスタデータなし
      IF (ln_kbn = gn_data_nothing) THEN
--
        -- 以前に配送先コードが同一のデータなし
        IF ((ir_masters_rec.row_s_ins_cnt = 0) AND (ir_masters_rec.row_s_upd_cnt = 0)) THEN
          ir_masters_rec.proc_code := gn_proc_insert;
--
        -- 以前に配送先コードが同一のデータあり
        ELSE
--
          -- 登録分の重複チェックエラー
          set_error_status(ir_status_rec,
                           xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                    gv_msg_80a_036,
                                                    gv_tkn_ng_kokyaku,
                                                    ir_masters_rec.party_num),
                           lv_errbuf,
                           lv_retcode,
                           lv_errmsg);
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_api_expt;
          END IF;
        END IF;
--
      -- 顧客・パーティマスタデータあり(無効)
      ELSIF (ln_kbn = gn_data_off) THEN
--
        -- 以前に配送先コードが同一のデータなし
        IF ((ir_masters_rec.row_s_ins_cnt = 0) AND (ir_masters_rec.row_s_upd_cnt = 0)) THEN
          ir_masters_rec.proc_code := gn_proc_update;
--
        -- 以前に配送先コードが同一のデータあり
        ELSE
--
          -- 登録分の重複チェックエラー
          set_error_status(ir_status_rec,
                           xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                    gv_msg_80a_036,
                                                    gv_tkn_ng_kokyaku,
                                                    ir_masters_rec.party_num),
                           lv_errbuf,
                           lv_retcode,
                           lv_errmsg);
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_api_expt;
          END IF;
        END IF;
--
      -- 顧客・パーティマスタデータあり(有効)
      ELSIF (ln_kbn = gn_data_on) THEN
--
        -- 処理スキップ
        set_warn_status(ir_status_rec,
                        NULL,
                        lv_errbuf,
                        lv_retcode,
                        lv_errmsg);
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
        END IF;
--
/* 2008.08.23 Mod ↓
        -- 登録分の重複チェックエラー
        set_error_status(ir_status_rec,
                         xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                  gv_msg_80a_036,
                                                  gv_tkn_ng_kokyaku,
                                                  ir_masters_rec.party_num),
                         lv_errbuf,
                         lv_retcode,
                         lv_errmsg);
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
        END IF;
2008.08.23 Mod ↑*//*
      END IF;
--
      RAISE check_party_num_expt;
    END IF;
--
    -- ===============================
    -- 更新
    -- ===============================
    IF (ir_masters_rec.k_proc_code = gn_proc_update) THEN
--
      -- 配送先IFの存在チェック
      chk_party_num_if(ir_masters_rec,
                       lb_retcd,
                       lv_errbuf,
                       lv_retcode,
                       lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      -- 顧客・パーティマスタデータなし
      IF (ln_kbn = gn_data_nothing) THEN
--
        -- 顧客コードなし(登録・更新)が有
        IF ((ir_masters_rec.row_n_ins_cnt > 0) OR (ir_masters_rec.row_n_upd_cnt > 0)) THEN
          ir_masters_rec.proc_code := gn_proc_insert;
--
        -- 顧客コードあり(登録・更新)が有
        ELSIF ((ir_masters_rec.row_m_ins_cnt > 0) OR (ir_masters_rec.row_m_upd_cnt > 0)) THEN
--
          -- 自身あり
          IF (lb_retcd) THEN
            ir_masters_rec.proc_code := gn_proc_update;
--
          -- 自身なし
          ELSE
            ir_masters_rec.proc_code := gn_proc_insert;
          END IF;
--
        -- 以前に配送先コードが同一のデータなし
        ELSE
--
          -- 処理スキップ
          set_warn_status(ir_status_rec,
                          NULL,
                          lv_errbuf,
                          lv_retcode,
                          lv_errmsg);
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_api_expt;
          END IF;
        END IF;
--
      -- 顧客・パーティマスタデータあり(無効)
      ELSIF (ln_kbn = gn_data_off) THEN
--
        -- 顧客コードなし(登録・更新)が有
        IF ((ir_masters_rec.row_n_ins_cnt > 0) OR (ir_masters_rec.row_n_upd_cnt > 0)) THEN
          ir_masters_rec.proc_code := gn_proc_update;
--
        -- 顧客コードあり(登録・更新)が有
        ELSIF ((ir_masters_rec.row_m_ins_cnt > 0) OR (ir_masters_rec.row_m_upd_cnt > 0)) THEN
--
          -- 自身あり
          IF (lb_retcd) THEN
            ir_masters_rec.proc_code := gn_proc_update;
--
          -- 自身なし
          ELSE
            ir_masters_rec.proc_code := gn_proc_insert;
          END IF;
--
        -- 以前に配送先コードが同一のデータなし
        ELSE
          ir_masters_rec.proc_code := gn_proc_update;
        END IF;
--
      -- 顧客・パーティマスタデータあり(有効)
      ELSIF (ln_kbn = gn_data_on) THEN
--
        -- 顧客コードなし(登録・更新)が有
        IF ((ir_masters_rec.row_n_upd_cnt > 0) OR (ir_masters_rec.row_n_ins_cnt > 0)) THEN
          ir_masters_rec.proc_code := gn_proc_update;
--
        -- 顧客コードあり(登録・更新)が有
        ELSIF ((ir_masters_rec.row_m_upd_cnt > 0) OR (ir_masters_rec.row_m_ins_cnt > 0)) THEN
--
          -- 自身あり
          IF (lb_retcd) THEN
            ir_masters_rec.proc_code := gn_proc_update;
--
          -- 自身なし
          ELSE
            ir_masters_rec.proc_code := gn_proc_insert;
          END IF;
--
        -- 以前に配送先コードが同一のデータなし
        ELSE
          ir_masters_rec.proc_code := gn_proc_update;
        END IF;
      END IF;
--
      RAISE check_party_num_expt;
    END IF;
--
    -- ===============================
    -- 削除
    -- ===============================
    IF (ir_masters_rec.k_proc_code = gn_proc_delete) THEN
--
      -- 処理スキップ
      set_warn_status(ir_status_rec,
                      NULL,
                      lv_errbuf,
                      lv_retcode,
                      lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      RAISE check_party_num_expt;
    END IF;
*/
      -- 配送先IFの存在チェック
      chk_party_num_if(ir_masters_rec,
                       lb_retcd,
                       lv_errbuf,
                       lv_retcode,
                       lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
    -- 顧客・パーティマスタデータなし
    IF ((ln_kbn = gn_data_nothing) AND (lb_retcd = FALSE)) THEN
      ir_masters_rec.proc_code := gn_proc_insert;  -- 登録
    ELSE
      ir_masters_rec.proc_code := gn_proc_update;    -- 更新
    END IF;
-- 2008/10/01 v1.10 UPDATE END
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN check_party_num_expt THEN
      NULL;
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
  END check_party_num;
--
  /***********************************************************************************
   * Procedure Name   : check_ship_to_code
   * Description      : 配送先コードのチェックを行います。(A-10)
   ***********************************************************************************/
  PROCEDURE check_ship_to_code(
    ir_status_rec   IN OUT NOCOPY status_rec,  -- 処理状況
    ir_masters_rec  IN OUT NOCOPY masters_rec, -- チェック対象データ
    ov_errbuf       OUT    NOCOPY VARCHAR2,    -- エラー・メッセージ           --# 固定 #
    ov_retcode      OUT    NOCOPY VARCHAR2,    -- リターン・コード             --# 固定 #
    ov_errmsg       OUT    NOCOPY VARCHAR2)    -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_ship_to_code'; -- プログラム名
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
    ln_kbn         NUMBER;
    ln_p_kbn       NUMBER;
    lb_on_retcd    BOOLEAN;           -- 有効
    lb_off_retcd   BOOLEAN;           -- 無効
    lb_party_retcd BOOLEAN;           -- 拠点
    lb_site_retcd  BOOLEAN;           -- 顧客
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
    ln_kbn := gn_data_init;
--
    -- パーティーサイトマスタのステータスのチェック
    chk_site_status(ir_masters_rec,
                    ln_kbn,
                    lv_errbuf,
                    lv_retcode,
                    lv_errmsg);
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ======================
    -- 登録
    -- ======================
    IF (ir_masters_rec.k_proc_code = gn_proc_insert) THEN
--
      -- パーティサイトマスタデータなし
      IF (ln_kbn = gn_data_nothing) THEN
--
        -- 以前に同じ配送先コードのデータなし
        IF ((ir_masters_rec.row_s_ins_cnt = 0)
        AND (ir_masters_rec.row_s_upd_cnt = 0)
        AND (ir_masters_rec.row_s_del_cnt = 0)) THEN
--
          -- 顧客コード=NULL
-- 2008/08/25 Mod ↓
/*
          IF (ir_masters_rec.party_num IS NULL) THEN
*/
          IF (ir_masters_rec.party_num = gv_def_party_num) THEN
-- 2008/08/25 Mod ↑
            ir_masters_rec.proc_code := gn_proc_s_ins;   -- 登録(拠点紐付き)
--
          -- 顧客コード<>NULL
          ELSE
            ir_masters_rec.proc_code := gn_proc_c_ins;   -- 登録(顧客紐付き)
          END IF;
--
        -- 以前に同じ配送先コードのデータあり
        ELSE
--
          -- 登録分の重複チェックエラー
          set_error_status(ir_status_rec,
                           xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                    gv_msg_80a_039,
                                                    gv_tkn_ng_haisou,
                                                    ir_masters_rec.ship_to_code),
                           lv_errbuf,
                           lv_retcode,
                           lv_errmsg);
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_api_expt;
          END IF;
        END IF;
--
      -- パーティサイトマスタデータあり(無効)
      ELSIF (ln_kbn = gn_data_off) THEN
--
        -- 以前に同じ配送先コードのデータなし
        IF ((ir_masters_rec.row_s_ins_cnt = 0)
        AND (ir_masters_rec.row_s_upd_cnt = 0)
        AND (ir_masters_rec.row_s_del_cnt = 0)) THEN
--
          -- 顧客コード=NULL
-- 2008/08/25 Mod ↓
/*
          IF (ir_masters_rec.party_num IS NULL) THEN
*/
          IF (ir_masters_rec.party_num = gv_def_party_num) THEN
-- 2008/08/25 Mod ↑
            ir_masters_rec.proc_code := gn_proc_s_upd;   -- 更新(拠点紐付き)
            ir_masters_rec.status := gv_status_on;       -- ステータスを有効
--
          -- 顧客コード<>NULL
          ELSE
            ir_masters_rec.proc_code := gn_proc_c_upd;   -- 更新(顧客紐付き)
            ir_masters_rec.status := gv_status_on;       -- ステータスを有効
          END IF;
--
        -- 以前に同じ配送先コードのデータあり
        ELSE
--
          -- 登録分の重複チェックエラー
          set_error_status(ir_status_rec,
                           xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                    gv_msg_80a_039,
                                                    gv_tkn_ng_haisou,
                                                    ir_masters_rec.ship_to_code),
                           lv_errbuf,
                           lv_retcode,
                           lv_errmsg);
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_api_expt;
          END IF;
        END IF;
--
      -- パーティサイトマスタデータあり(有効)
      ELSIF (ln_kbn = gn_data_on) THEN
--
        -- ステータスチェック
        chk_party_status(ir_masters_rec,
                         ln_p_kbn,
                         lv_errbuf,
                         lv_retcode,
                         lv_errmsg);
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
        END IF;

        -- 顧客・パーティマスタデータなし
        IF (ln_p_kbn <> gn_data_on) THEN
--
          -- 処理スキップ
          set_warn_status(ir_status_rec,
                          NULL,
                          lv_errbuf,
                          lv_retcode,
                          lv_errmsg);
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_api_expt;
          END IF;
        END IF;
--
/* 2008.08.23 Mod ↓
        -- 登録分の重複チェックエラー
        set_error_status(ir_status_rec,
                         xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                  gv_msg_80a_039,
                                                  gv_tkn_ng_haisou,
                                                  ir_masters_rec.ship_to_code),
                         lv_errbuf,
                         lv_retcode,
                         lv_errmsg);
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
        END IF;
2008.08.23 Mod ↑ */
      END IF;
--
      RAISE check_ship_to_code_expt;
    END IF;
--
    -- 存在チェック(無効)
    exists_party_number(ir_masters_rec,
                        gv_status_off,
                        lb_off_retcd,
                        lv_errbuf,
                        lv_retcode,
                        lv_errmsg);
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    -- 存在チェック(有効)
    exists_party_number(ir_masters_rec,
                        gv_status_on,
                        lb_on_retcd,
                        lv_errbuf,
                        lv_retcode,
                        lv_errmsg);
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    -- 存在チェック(拠点コード)
    exists_xxcmn_site_if(ir_masters_rec,
                         gn_kbn_party,
                         lb_party_retcd,
                         lv_errbuf,
                         lv_retcode,
                         lv_errmsg);
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    -- 存在チェック(顧客コード)
    exists_xxcmn_site_if(ir_masters_rec,
                         gn_kbn_site,
                         lb_site_retcd,
                         lv_errbuf,
                         lv_retcode,
                         lv_errmsg);
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ======================
    -- 更新
    -- ======================
    IF (ir_masters_rec.k_proc_code = gn_proc_update) THEN
--
      -- パーティサイトマスタデータなし
      IF (ln_kbn = gn_data_nothing) THEN
--
        -- 以前に同じ配送先コードのデータなし
        IF ((ir_masters_rec.row_s_ins_cnt = 0)
        AND (ir_masters_rec.row_s_upd_cnt = 0)
        AND (ir_masters_rec.row_s_del_cnt = 0)) THEN
--
          -- 更新分の存在チェックエラー
          set_error_status(ir_status_rec,
                           xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                    gv_msg_80a_037,
                                                    gv_tkn_ng_haisou,
                                                    ir_masters_rec.ship_to_code),
                           lv_errbuf,
                           lv_retcode,
                           lv_errmsg);
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_api_expt;
          END IF;
--
        -- 以前に同じ配送先コードのデータあり
        ELSE
--
          -- 顧客コード=NULL
-- 2008/08/25 Mod ↓
/*
          IF (ir_masters_rec.party_num IS NULL) THEN
*/
          IF (ir_masters_rec.party_num = gv_def_party_num) THEN
-- 2008/08/25 Mod ↑
--
            -- 以前に同じ拠点コードが存在している
            IF (lb_party_retcd) THEN
              ir_masters_rec.proc_code := gn_proc_s_upd;   -- 更新(拠点紐付き)
--
            -- 以前に同じ拠点コードが存在していない
            ELSE
              ir_masters_rec.proc_code := gn_proc_s_del;   -- 削除/登録(拠点紐付き)
            END IF;
--
          -- 顧客コード<>NULL
          ELSE
--
            -- 以前に同じ顧客コードが存在している
            IF (lb_site_retcd) THEN
              ir_masters_rec.proc_code := gn_proc_c_upd;   -- 更新(顧客紐付き)
--
            -- 以前に同じ顧客コードが存在していない
            ELSE
              ir_masters_rec.proc_code := gn_proc_c_del;   -- 削除/登録(顧客紐付き)
            END IF;
          END IF;
        END IF;
--
      -- パーティサイトマスタデータあり(無効)
      ELSIF (ln_kbn = gn_data_off) THEN
--
        -- 以前に同じ配送先コードのデータなし
        IF ((ir_masters_rec.row_s_ins_cnt = 0)
        AND (ir_masters_rec.row_s_upd_cnt = 0)
        AND (ir_masters_rec.row_s_del_cnt = 0)) THEN
--
          -- 顧客コード=NULL
-- 2008/08/25 Mod ↓
/*
          IF (ir_masters_rec.party_num IS NULL) THEN
*/
          IF (ir_masters_rec.party_num = gv_def_party_num) THEN
-- 2008/08/25 Mod ↑
--
            -- 拠点コード=パーティサイトマスタ.パーティ番号
            IF (lb_off_retcd) THEN
              ir_masters_rec.proc_code := gn_proc_s_upd;   -- 更新(拠点紐付き)
              ir_masters_rec.status := gv_status_on;       -- ステータスを有効
--
            -- 拠点コード<>パーティサイトマスタ.パーティ番号
            ELSE
              ir_masters_rec.proc_code := gn_proc_s_ins;   -- 登録(拠点紐付き)
            END IF;
--
          -- 顧客コード<>NULL
          ELSE
--
            -- 顧客コード=パーティサイトマスタ.パーティ番号
            IF (lb_off_retcd) THEN
              ir_masters_rec.proc_code := gn_proc_c_upd;   -- 更新(顧客紐付き)
              ir_masters_rec.status := gv_status_on;       -- ステータスを有効
--
            -- 顧客コード<>パーティサイトマスタ.パーティ番号
            ELSE
              ir_masters_rec.proc_code := gn_proc_c_ins;   -- 登録(顧客紐付き)
            END IF;
          END IF;
--
        -- 以前に同じ配送先コードのデータあり
        ELSE
--
          -- 顧客コード=NULL
-- 2008/08/25 Mod ↓
/*
          IF (ir_masters_rec.party_num IS NULL) THEN
*/
          IF (ir_masters_rec.party_num = gv_def_party_num) THEN
-- 2008/08/25 Mod ↑
--
            -- 拠点コード=パーティサイトマスタ.パーティ番号
            IF (lb_off_retcd) THEN
              ir_masters_rec.proc_code := gn_proc_s_upd;   -- 更新(拠点紐付き)
              ir_masters_rec.status := gv_status_on;       -- ステータスを有効
--
            -- 拠点コード<>パーティサイトマスタ.パーティ番号
            ELSE
              ir_masters_rec.proc_code := gn_proc_s_del;   -- 削除/登録(拠点紐付き)
            END IF;
--
          -- 顧客コード<>NULL
          ELSE
--
            -- 以前に顧客コードが存在している
            IF (lb_site_retcd) THEN
              ir_masters_rec.proc_code := gn_proc_c_upd;   -- 更新(顧客紐付き)
              ir_masters_rec.status := gv_status_on;       -- ステータスを有効
--
            -- 以前に顧客コードが存在していない
            ELSE
              ir_masters_rec.proc_code := gn_proc_c_del;   -- 削除/登録(顧客紐付き)
            END IF;
          END IF;
        END IF;
--
      -- パーティサイトマスタデータあり(有効)
      ELSIF (ln_kbn = gn_data_on) THEN
--
        -- 顧客コード=NULL
-- 2008/08/25 Mod ↓
/*
        IF (ir_masters_rec.party_num IS NULL) THEN
*/
        IF (ir_masters_rec.party_num = gv_def_party_num) THEN
-- 2008/08/25 Mod ↑
--
          -- 拠点コード=パーティサイトマスタ.パーティ番号
          IF (lb_on_retcd) THEN
            ir_masters_rec.proc_code := gn_proc_s_upd;   -- 更新(拠点紐付き)
--
          -- 拠点コード<>パーティサイトマスタ.パーティ番号
          ELSE
            ir_masters_rec.proc_code := gn_proc_s_del;   -- 削除/登録(拠点紐付き)
          END IF;
--
        -- 顧客コード<>NULL
        ELSE
--
          -- 顧客コード=パーティサイトマスタ.パーティ番号
          IF (lb_on_retcd) THEN
            ir_masters_rec.proc_code := gn_proc_c_upd;   -- 更新(顧客紐付き)
--
          -- 拠点コード<>パーティサイトマスタ.パーティ番号
          ELSE
            ir_masters_rec.proc_code := gn_proc_c_del;   -- 削除/登録(顧客紐付き)
          END IF;
        END IF;
      END IF;
--
      RAISE check_ship_to_code_expt;
    END IF;
--
    -- ======================
    -- 削除
    -- ======================
    IF (ir_masters_rec.k_proc_code = gn_proc_delete) THEN
--
      -- パーティサイトマスタデータなし
      IF (ln_kbn = gn_data_nothing) THEN
--
        -- 以前に同じ配送先コードのデータなし
        IF ((ir_masters_rec.row_s_ins_cnt = 0)
        AND (ir_masters_rec.row_s_upd_cnt = 0)
        AND (ir_masters_rec.row_s_del_cnt = 0)) THEN
--
          -- 削除分の存在チェックワーニング
          set_warn_status(ir_status_rec,
                          xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                   gv_msg_80a_038,
                                                   gv_tkn_ng_haisou,
                                                   ir_masters_rec.ship_to_code),
                          lv_errbuf,
                          lv_retcode,
                          lv_errmsg);
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_api_expt;
          END IF;
--
        -- 以前に同じ配送先コードのデータあり
        ELSE
--
          -- 登録・更新がある
          IF ((ir_masters_rec.row_s_ins_cnt > 0) OR (ir_masters_rec.row_s_upd_cnt > 0)) THEN
--
            -- 顧客コード=NULL
-- 2008/08/25 Mod ↓
/*
            IF (ir_masters_rec.party_num IS NULL) THEN
*/
            IF (ir_masters_rec.party_num = gv_def_party_num) THEN
-- 2008/08/25 Mod ↑
--
              -- 以前に拠点コードが存在している
              IF (lb_party_retcd) THEN
                ir_masters_rec.proc_code := gn_proc_ds_del;   -- 削除(拠点紐付き)
--
              -- 以前に拠点コードが存在していない
              ELSE
--
                -- 削除分の存在チェックワーニング
                set_warn_status(ir_status_rec,
                                xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                         gv_msg_80a_038,
                                                         gv_tkn_ng_haisou,
                                                         ir_masters_rec.ship_to_code),
                                lv_errbuf,
                                lv_retcode,
                                lv_errmsg);
--
                IF (lv_retcode = gv_status_error) THEN
                  RAISE global_api_expt;
                END IF;
              END IF;
--
            -- 顧客コード<>NULL
            ELSE
--
              -- 以前に顧客コードが存在している
              IF (lb_site_retcd) THEN
                ir_masters_rec.proc_code := gn_proc_dc_del;   -- 削除(顧客紐付き)
--
              -- 以前に顧客コードが存在していない
              ELSE
--
                -- 削除分の存在チェックワーニング
                set_warn_status(ir_status_rec,
                                xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                         gv_msg_80a_038,
                                                         gv_tkn_ng_haisou,
                                                         ir_masters_rec.ship_to_code),
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
          -- 削除がある
          ELSE
--
            -- 削除分の存在チェックワーニング
            set_warn_status(ir_status_rec,
                            xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                     gv_msg_80a_038,
                                                     gv_tkn_ng_haisou,
                                                     ir_masters_rec.ship_to_code),
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
      -- パーティサイトマスタデータあり(無効)
      ELSIF (ln_kbn = gn_data_off) THEN
--
        -- 以前に同じ配送先コードのデータなし
        IF ((ir_masters_rec.row_s_ins_cnt = 0)
        AND (ir_masters_rec.row_s_upd_cnt = 0)
        AND (ir_masters_rec.row_s_del_cnt = 0)) THEN
--
          -- 削除分の存在チェックワーニング
          set_warn_status(ir_status_rec,
                          xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                   gv_msg_80a_038,
                                                   gv_tkn_ng_haisou,
                                                   ir_masters_rec.ship_to_code),
                          lv_errbuf,
                          lv_retcode,
                          lv_errmsg);
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_api_expt;
          END IF;
--
        -- 以前に同じ配送先コードのデータあり
        ELSE
--
          -- 登録・更新がある
          IF ((ir_masters_rec.row_s_ins_cnt > 0) OR (ir_masters_rec.row_s_upd_cnt > 0)) THEN
--
            -- 顧客コード=NULL
-- 2008/08/25 Mod ↓
/*
            IF (ir_masters_rec.party_num IS NULL) THEN
*/
            IF (ir_masters_rec.party_num = gv_def_party_num) THEN
-- 2008/08/25 Mod ↑
--
              -- 以前に拠点コードが存在している
              IF (lb_party_retcd) THEN
                ir_masters_rec.proc_code := gn_proc_ds_del;   -- 削除(拠点紐付き)
--
              -- 以前に拠点コードが存在していない
              ELSE
--
                -- 削除分の存在チェックワーニング
                set_warn_status(ir_status_rec,
                                xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                         gv_msg_80a_038,
                                                         gv_tkn_ng_haisou,
                                                         ir_masters_rec.ship_to_code),
                                lv_errbuf,
                                lv_retcode,
                                lv_errmsg);
--
                IF (lv_retcode = gv_status_error) THEN
                  RAISE global_api_expt;
                END IF;
              END IF;
--
            -- 顧客コード<>NULL
            ELSE
--
              -- 以前に顧客コードが存在している
              IF (lb_site_retcd) THEN
                ir_masters_rec.proc_code := gn_proc_dc_del;   -- 削除(顧客紐付き)
--
              -- 以前に拠点コードが存在していない
              ELSE
--
                -- 削除分の存在チェックワーニング
                set_warn_status(ir_status_rec,
                                xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                         gv_msg_80a_038,
                                                         gv_tkn_ng_haisou,
                                                         ir_masters_rec.ship_to_code),
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
          -- 削除がある
          ELSE
--
            -- 削除分の存在チェックワーニング
            set_warn_status(ir_status_rec,
                            xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                     gv_msg_80a_038,
                                                     gv_tkn_ng_haisou,
                                                     ir_masters_rec.ship_to_code),
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
      -- パーティサイトマスタデータあり(有効)
      ELSIF (ln_kbn = gn_data_on) THEN
--
        -- 以前に同じ配送先コードのデータなし
        IF ((ir_masters_rec.row_s_ins_cnt = 0)
        AND (ir_masters_rec.row_s_upd_cnt = 0)
        AND (ir_masters_rec.row_s_del_cnt = 0)) THEN
--
            -- 拠点コード=パーティサイトマスタ.パーティ番号
            IF (lb_on_retcd) THEN
--
              -- 顧客コード=NULL
-- 2008/08/25 Mod ↓
/*
              IF (ir_masters_rec.party_num IS NULL) THEN
*/
              IF (ir_masters_rec.party_num = gv_def_party_num) THEN
-- 2008/08/25 Mod ↑
                ir_masters_rec.proc_code := gn_proc_ds_del;   -- 削除(拠点紐付き)
--
              -- 顧客コード<>NULL
              ELSE
                ir_masters_rec.proc_code := gn_proc_dc_del;   -- 削除(顧客紐付き)
              END IF;
--
            -- 拠点コード<>パーティサイトマスタ.パーティ番号
            ELSE
              -- 削除分の存在チェックワーニング
              set_warn_status(ir_status_rec,
                              xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                       gv_msg_80a_038,
                                                       gv_tkn_ng_haisou,
                                                       ir_masters_rec.ship_to_code),
                              lv_errbuf,
                              lv_retcode,
                              lv_errmsg);
--
              IF (lv_retcode = gv_status_error) THEN
                RAISE global_api_expt;
              END IF;
            END IF;
--
        -- 以前に同じ配送先コードのデータあり
        ELSE
--
          -- 登録・更新がある
          IF ((ir_masters_rec.row_s_ins_cnt > 0) OR (ir_masters_rec.row_s_upd_cnt > 0)) THEN
--
            -- 顧客コード=NULL
-- 2008/08/25 Mod ↓
/*
            IF (ir_masters_rec.party_num IS NULL) THEN
*/
            IF (ir_masters_rec.party_num = gv_def_party_num) THEN
-- 2008/08/25 Mod ↑
--
              -- 以前に拠点コードが存在している
              IF (lb_party_retcd) THEN
                ir_masters_rec.proc_code := gn_proc_ds_del;   -- 削除(拠点紐付き)
--
              -- 以前に拠点コードが存在していない
              ELSE
                -- 削除分の存在チェックワーニング
                set_warn_status(ir_status_rec,
                                xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                         gv_msg_80a_038,
                                                         gv_tkn_ng_haisou,
                                                         ir_masters_rec.ship_to_code),
                                lv_errbuf,
                                lv_retcode,
                                lv_errmsg);
--
                IF (lv_retcode = gv_status_error) THEN
                  RAISE global_api_expt;
                END IF;
              END IF;
--
            -- 顧客コード<>NULL
            ELSE
--
              -- 以前に顧客コードが存在している
              IF (lb_site_retcd) THEN
                ir_masters_rec.proc_code := gn_proc_dc_del;   -- 削除(顧客紐付き)
--
              -- 以前に顧客コードが存在していない
              ELSE
                -- 削除分の存在チェックワーニング
                set_warn_status(ir_status_rec,
                                xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                         gv_msg_80a_038,
                                                         gv_tkn_ng_haisou,
                                                         ir_masters_rec.ship_to_code),
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
          -- 削除がある
          ELSE
--
            -- 削除分の存在チェックワーニング
            set_warn_status(ir_status_rec,
                            xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                     gv_msg_80a_038,
                                                     gv_tkn_ng_haisou,
                                                     ir_masters_rec.ship_to_code),
                            lv_errbuf,
                            lv_retcode,
                            lv_errmsg);
--
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_api_expt;
            END IF;
          END IF;
        END IF;
      END IF;
--
      RAISE check_ship_to_code_expt;
    END IF;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN check_ship_to_code_expt THEN
      NULL;
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
  END check_ship_to_code;
--
  /***********************************************************************************
   * Procedure Name   : proc_xxcmn_party
   * Description      : パーティアドオンマスタの処理を行います。
   ***********************************************************************************/
  PROCEDURE proc_xxcmn_party(
    ir_masters_rec  IN            masters_rec,  -- チェック対象データ
    in_proc_kbn     IN            NUMBER,       -- 処理区分
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_xxcmn_party'; -- プログラム名
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
    lv_party_name      xxcmn_parties.party_name%TYPE;
    lv_address_line1   xxcmn_parties.address_line1%TYPE;
    lv_address_line2   xxcmn_parties.address_line2%TYPE;
--
-- 2009/02/25 v1.13 ADD START
    ln_lenb            NUMBER;
--
-- 2009/02/25 v1.13 ADD END
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
    -- 登録処理
    IF (in_proc_kbn = gn_proc_insert) THEN
--
      -- 拠点インタフェース
      IF (ir_masters_rec.tbl_kbn = gn_kbn_party) THEN
-- 2009/02/25 v1.13 ADD START
--        lv_address_line1 := SUBSTR(ir_masters_rec.address,1,15);
--        lv_address_line2 := SUBSTR(ir_masters_rec.address,31,15);
--
        lv_address_line1 := RTRIM(SUBSTRB(ir_masters_rec.address, 1, 30));
        ln_lenb          := TO_NUMBER(LENGTHB(lv_address_line1)) + 1;
        lv_address_line2 := RTRIM(SUBSTRB(ir_masters_rec.address, ln_lenb, 30));
--
-- 2009/02/25 v1.13 ADD END
        INSERT INTO xxcmn_parties
          (party_id
          ,start_date_active
          ,end_date_active
          ,party_name
          ,party_short_name
          ,party_name_alt
          ,zip
          ,address_line1
          ,address_line2
          ,phone
          ,fax
          ,created_by
          ,creation_date
          ,last_updated_by
          ,last_update_date
          ,last_update_login
          ,request_id
          ,program_application_id
          ,program_id
          ,program_update_date)
        VALUES (
           ir_masters_rec.p_party_id        --パーティID
          ,gd_min_date                      --適用開始日
          ,gd_max_date                      --適用終了日
          ,ir_masters_rec.party_name        --正式名
          ,ir_masters_rec.party_short_name  --略称
          ,ir_masters_rec.party_name_alt    --カナ名
          ,ir_masters_rec.zip2              --郵便番号2
          ,lv_address_line1                 --住所1
          ,lv_address_line2                 --住所2
          ,ir_masters_rec.phone             --電話番号
          ,ir_masters_rec.fax               --FAX番号
          ,gn_created_by
          ,gd_creation_date
          ,gn_last_updated_by
          ,gd_last_update_date
          ,gn_last_update_login
          ,gn_request_id
          ,gn_program_application_id
          ,gn_program_id
          ,gd_program_update_date);
--
      -- 配送先インタフェース(顧客)
      ELSE
        lv_party_name := ir_masters_rec.customer_name1||ir_masters_rec.customer_name2;
--
        INSERT INTO xxcmn_parties
          (party_id
          ,start_date_active
          ,end_date_active
          ,party_name
          ,created_by
          ,creation_date
          ,last_updated_by
          ,last_update_date
          ,last_update_login
          ,request_id
          ,program_application_id
          ,program_id
          ,program_update_date)
        VALUES (
           ir_masters_rec.p_party_id         --パーティID
          ,gd_min_date                       --適用開始日
          ,gd_max_date                       --適用終了日
          ,lv_party_name                     --正式名
          ,gn_created_by
          ,gd_creation_date
          ,gn_last_updated_by
          ,gd_last_update_date
          ,gn_last_update_login
          ,gn_request_id
          ,gn_program_application_id
          ,gn_program_id
          ,gd_program_update_date);
--
      END IF;
--
    -- 更新処理
    ELSE
--
      -- 拠点インタフェース
      IF (ir_masters_rec.tbl_kbn = gn_kbn_party) THEN
-- 2009/02/25 v1.13 ADD START
--        lv_address_line1 := SUBSTR(ir_masters_rec.address,1,15);
--        lv_address_line2 := SUBSTR(ir_masters_rec.address,31,15);
--
        lv_address_line1 := RTRIM(SUBSTRB(ir_masters_rec.address, 1, 30));
        ln_lenb          := TO_NUMBER(LENGTHB(lv_address_line1)) + 1;
        lv_address_line2 := RTRIM(SUBSTRB(ir_masters_rec.address, ln_lenb, 30));
--
-- 2009/02/25 v1.13 ADD END
--
        UPDATE xxcmn_parties SET
           party_name             = ir_masters_rec.party_name             --正式名
          ,party_short_name       = ir_masters_rec.party_short_name       --略称
          ,party_name_alt         = ir_masters_rec.party_name_alt         --カナ名
          ,zip                    = ir_masters_rec.zip2                   --郵便番号2
          ,address_line1          = lv_address_line1                      --住所1
          ,address_line2          = lv_address_line2                      --住所2
          ,phone                  = ir_masters_rec.phone                  --電話番号
          ,fax                    = ir_masters_rec.fax                    --FAX番号
          ,last_updated_by        = gn_last_updated_by
          ,last_update_date       = gd_last_update_date
          ,last_update_login      = gn_last_update_login
          ,request_id             = gn_request_id
          ,program_application_id = gn_program_application_id
          ,program_id             = gn_program_id
          ,program_update_date    = gd_program_update_date
        WHERE party_id            = ir_masters_rec.p_party_id;
--
      -- 配送先インタフェース(顧客)
      ELSE
        lv_party_name := ir_masters_rec.customer_name1||ir_masters_rec.customer_name2;
--
        UPDATE xxcmn_parties SET
           party_name             = lv_party_name                         --正式名
          ,last_updated_by        = gn_last_updated_by
          ,last_update_date       = gd_last_update_date
          ,last_update_login      = gn_last_update_login
          ,request_id             = gn_request_id
          ,program_application_id = gn_program_application_id
          ,program_id             = gn_program_id
          ,program_update_date    = gd_program_update_date
        WHERE party_id            = ir_masters_rec.p_party_id;
      END IF;
    END IF;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
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
  END proc_xxcmn_party;
--
  /***********************************************************************************
   * Procedure Name   : proc_xxcmn_party_site
   * Description      : パーティサイトアドオンマスタの処理を行います。
   ***********************************************************************************/
  PROCEDURE proc_xxcmn_party_site(
    ir_masters_rec  IN            masters_rec,  -- チェック対象データ
    in_proc_kbn     IN            NUMBER,       -- 処理区分
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_xxcmn_party_site'; -- プログラム名
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
    cv_def_cond   CONSTANT VARCHAR2(2) := '00';
--
    -- *** ローカル変数 ***
    lv_site_name      xxcmn_party_sites.party_site_name%TYPE;
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
    lv_site_name := ir_masters_rec.party_site_name1 || ir_masters_rec.party_site_name2;
--
    -- 登録処理
    IF (in_proc_kbn = gn_proc_insert) THEN
--
      INSERT INTO xxcmn_party_sites
        (party_site_id
        ,party_id
        ,location_id
        ,start_date_active
        ,end_date_active
        ,base_code
        ,party_site_name
        ,zip
        ,address_line1
        ,address_line2
        ,phone
        ,fax
        ,freshness_condition                     -- 2008/08/19 Add
        ,created_by
        ,creation_date
        ,last_updated_by
        ,last_update_date
        ,last_update_login
        ,request_id
        ,program_application_id
        ,program_id
        ,program_update_date)
      VALUES (
         ir_masters_rec.party_site_id            --パーティーサイトID
        ,ir_masters_rec.p_party_id               --パーティーID
        ,ir_masters_rec.location_id              --ロケーションID
        ,gd_min_date                             --適用開始日
        ,gd_max_date                             --適用終了日
        ,ir_masters_rec.base_code                --拠点コード
        ,lv_site_name                            --正式名
        ,ir_masters_rec.zip2                     --郵便番号2
        ,ir_masters_rec.party_site_addr1         --住所１
        ,ir_masters_rec.party_site_addr2         --住所２
        ,ir_masters_rec.phone                    --電話番号
        ,ir_masters_rec.fax                      --ＦＡＸ番号
        ,cv_def_cond                             --鮮度条件 2008/08/19 Add
        ,gn_created_by
        ,gd_creation_date
        ,gn_last_updated_by
        ,gd_last_update_date
        ,gn_last_update_login
        ,gn_request_id
        ,gn_program_application_id
        ,gn_program_id
        ,gd_program_update_date);
--
    -- 更新処理
    ELSE
--
      UPDATE xxcmn_party_sites SET
         base_code              = ir_masters_rec.base_code           --拠点コード
        ,party_site_name        = lv_site_name                       --正式名
        ,zip                    = ir_masters_rec.zip2                --郵便番号2
        ,address_line1          = ir_masters_rec.party_site_addr1    --住所1
        ,address_line2          = ir_masters_rec.party_site_addr2    --住所2
        ,phone                  = ir_masters_rec.phone               --電話番号
        ,fax                    = ir_masters_rec.fax                 --FAX番号
        ,last_updated_by        = gn_last_updated_by
        ,last_update_date       = gd_last_update_date
        ,last_update_login      = gn_last_update_login
        ,request_id             = gn_request_id
        ,program_application_id = gn_program_application_id
        ,program_id             = gn_program_id
        ,program_update_date    = gd_program_update_date
      WHERE party_site_id       = ir_masters_rec.party_site_id
      AND   party_id            = ir_masters_rec.p_party_id
      AND   location_id         = ir_masters_rec.location_id;
    END IF;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
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
  END proc_xxcmn_party_site;
--
  /***********************************************************************************
   * Procedure Name   : create_party_account
   * Description      : パーティマスタと顧客マスタの登録処理を行います。
   ***********************************************************************************/
  PROCEDURE create_party_account(
    ir_masters_rec  IN OUT NOCOPY masters_rec,  -- チェック対象データ
    in_kbn          IN            NUMBER,       -- 処理区分
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'create_party_account'; -- プログラム名
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
    lv_api_name                     VARCHAR2(200);
    lr_organization_rec             HZ_PARTY_V2PUB.ORGANIZATION_REC_TYPE;
    lr_cust_account_rec             HZ_CUST_ACCOUNT_V2PUB.CUST_ACCOUNT_REC_TYPE;
    lr_customer_profile_rec         HZ_CUSTOMER_PROFILE_V2PUB.CUSTOMER_PROFILE_REC_TYPE;
    ln_party_id                     NUMBER;
    lv_party_number                 hz_parties.party_number%TYPE;
    ln_profile_id                   NUMBER;
    lv_return_status                VARCHAR2(30);
    ln_msg_count                    NUMBER;
    lv_msg_data                     VARCHAR2(2000);
    ln_cust_account_id              hz_cust_accounts.cust_account_id%TYPE;
    lv_account_number               hz_cust_accounts.account_number%TYPE;
    lv_class_code                   VARCHAR2(30);
    lb_retcd                        BOOLEAN;
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
    -- 顧客区分の取得
    get_class_code(in_kbn,
                   lv_class_code,
                   lb_retcd,
                   lv_errbuf,
                   lv_retcode,
                   lv_errmsg);
--
    IF ((lv_retcode = gv_status_error) OR (NOT lb_retcd)) THEN
      RAISE global_api_expt;
    END IF;
--
    -- 必須項目
    lr_organization_rec.created_by_module        := gv_created_by_module;
    lr_cust_account_rec.created_by_module        := gv_created_by_module;
    lr_cust_account_rec.status                   := gv_status_on;
    lr_organization_rec.party_rec.validated_flag := gv_validated_flag_on;
    lr_cust_account_rec.customer_class_code      := lv_class_code;
--
    -- パーティマスタ.DFF24(マスタ受信日時)
    lr_organization_rec.party_rec.attribute24 := TO_CHAR(SYSDATE,'YYYY/MM/DD');
--
    IF (in_kbn = gn_kbn_party) THEN
--
      -- パーティ名
      lr_organization_rec.organization_name := ir_masters_rec.party_name;
      -- 顧客番号(拠点コード)
      lr_cust_account_rec.account_number    := ir_masters_rec.base_code;
      -- 属性１
      lr_cust_account_rec.attribute1        := ir_masters_rec.old_division_code;
      -- 属性２
      lr_cust_account_rec.attribute2        := ir_masters_rec.new_division_code;
      -- 属性３
      lr_cust_account_rec.attribute3 := TO_CHAR(ir_masters_rec.division_start_date,'YYYY/MM/DD');
      -- 属性４
      lr_cust_account_rec.attribute4        := ir_masters_rec.location_rel_code;
      -- 属性５
      lr_cust_account_rec.attribute5        := ir_masters_rec.ship_mng_code;
      -- 属性６
      lr_cust_account_rec.attribute6        := ir_masters_rec.warehouse_code;
      -- 属性７
      lr_cust_account_rec.attribute7        := ir_masters_rec.terminal_code;
-- 2008/10/07 v1.11 DELETE START
--      -- 属性１３
--      lr_cust_account_rec.attribute13       := ir_masters_rec.district_code;
-- 2008/10/07 v1.11 DELETE END
-- 2009/04/03 ADD START
      -- 属性１２
      lr_cust_account_rec.attribute12       := '0'; -- 中止客申請フラグ
      lr_cust_account_rec.attribute13       := '0'; -- ドリンク拠点カテゴリ ALL
      lr_cust_account_rec.attribute16       := '0'; -- リーフ拠点カテゴリ ALL
      lr_cust_account_rec.attribute14       := '0'; -- 出荷依頼自動作成区分 自動作成対象外
-- 2009/04/03 ADD END
--
    ELSE
--
      -- パーティ名
      lr_organization_rec.organization_name := ir_masters_rec.customer_name1||
                                               ir_masters_rec.customer_name2;
      -- 顧客番号(顧客コード)
      lr_cust_account_rec.account_number    := ir_masters_rec.party_num;
      -- 属性１２
      lr_cust_account_rec.attribute12       := ir_masters_rec.cal_cust_app_flg;
      -- 属性１５
      lr_cust_account_rec.attribute15       := ir_masters_rec.direct_ship_code;
-- 2008/10/07 v1.11 DELETE START
--      -- 属性１６
--      lr_cust_account_rec.attribute16       := ir_masters_rec.direct_ship_code;
-- 2008/10/07 v1.11 DELETE END
      -- 属性１７
      lr_cust_account_rec.attribute17       := ir_masters_rec.sale_base_code;
-- 2009/04/03 MOD START
      -- 属性１８
--      lr_cust_account_rec.attribute18       := ir_masters_rec.res_sale_base_code;
      -- IFされる0000は値セットにない値であるためその場合は設定しない
      IF (ir_masters_rec.res_sale_base_code <> '0000') THEN
        lr_cust_account_rec.attribute18       := ir_masters_rec.res_sale_base_code;
      END IF;
-- 2009/04/03 MOD END
      -- 属性１９
      lr_cust_account_rec.attribute19       := ir_masters_rec.chain_store;
      -- 属性２０
      lr_cust_account_rec.attribute20       := ir_masters_rec.chain_store_name;
    END IF;
--
    -- 顧客マスタ(HZ_CUST_ACCOUNT_V2PUB)
    HZ_CUST_ACCOUNT_V2PUB.CREATE_CUST_ACCOUNT (
        P_INIT_MSG_LIST        => FND_API.G_FALSE
       ,P_CUST_ACCOUNT_REC     => lr_cust_account_rec
       ,P_ORGANIZATION_REC     => lr_organization_rec
       ,P_CUSTOMER_PROFILE_REC => lr_customer_profile_rec
       ,P_CREATE_PROFILE_AMT   => FND_API.G_FALSE
       ,X_CUST_ACCOUNT_ID      => ln_cust_account_id
       ,X_ACCOUNT_NUMBER       => lv_account_number
       ,X_PARTY_ID             => ln_party_id
       ,X_PARTY_NUMBER         => lv_party_number
       ,X_PROFILE_ID           => ln_profile_id
       ,X_RETURN_STATUS        => lv_return_status
       ,X_MSG_COUNT            => ln_msg_count
       ,X_MSG_DATA             => lv_msg_data
    );
--
    -- 失敗
    IF (lv_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
      lv_api_name := 'HZ_CUST_ACCOUNT_V2PUB.CREATE_CUST_ACCOUNT';
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,      gv_msg_80a_016,
                                            gv_tkn_api_name, lv_api_name);
--
      FND_MSG_PUB.GET( P_MSG_INDEX     => 1,
                       P_ENCODED       => FND_API.G_FALSE,
                       P_DATA          => lv_msg_data,
                       P_MSG_INDEX_OUT => ln_msg_count );
--
      lv_errbuf := lv_msg_data;
      RAISE global_api_expt;
    END IF;
--
    ir_masters_rec.p_party_id   := ln_party_id;                     -- パーティID
    ir_masters_rec.party_number := lv_party_number;                 -- パーティ番号
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
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
  END create_party_account;
--
  /***********************************************************************************
   * Procedure Name   : update_hz_parties
   * Description      : パーティマスタの更新処理を行います。
   ***********************************************************************************/
  PROCEDURE update_hz_parties(
    ir_masters_rec  IN OUT NOCOPY masters_rec,  -- チェック対象データ
    in_kbn          IN            NUMBER,       -- 処理区分
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_hz_parties'; -- プログラム名
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
    lv_api_name                     VARCHAR2(200);
    lr_organization_rec             HZ_PARTY_V2PUB.ORGANIZATION_REC_TYPE;
    ln_profile_id                   NUMBER;
    lv_return_status                VARCHAR2(30);
    ln_msg_count                    NUMBER;
    lv_msg_data                     VARCHAR2(2000);
    ln_object_version_number        hz_parties.object_version_number%TYPE;
    lv_validated_flag               hz_parties.validated_flag%TYPE;
    ln_kbn                          NUMBER;
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
    -- 拠点単位
    IF ((in_kbn = gn_kbn_upd_site) OR (in_kbn = gn_kbn_del_site)) THEN
      ln_kbn := gn_kbn_party;
--
    -- 顧客単位
    ELSE
      ln_kbn := gn_kbn_site;
    END IF;
--
    -- オブジェクトバージョン番号の取得
    exists_party_id(ir_masters_rec,
                    ln_kbn,
                    gv_status_on,
                    lv_errbuf,
                    lv_retcode,
                    lv_errmsg);
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    IF (ir_masters_rec.p_party_id IS NULL) THEN
--s
      -- オブジェクトバージョン番号の取得
      exists_party_id(ir_masters_rec,
                      ln_kbn,
                      gv_status_off,
                      lv_errbuf,
                      lv_retcode,
                      lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
    END IF;
--
    -- 必須項目
    ln_object_version_number                   := ir_masters_rec.obj_party_number;
    lr_organization_rec.party_rec.party_id     := ir_masters_rec.p_party_id;
    lr_organization_rec.party_rec.party_number := ir_masters_rec.party_number;
--
    -- 有効フラグ
    IF (in_kbn = gn_kbn_upd_site) THEN
      lv_validated_flag := gv_validated_flag_on;
--
    ELSIF (in_kbn = gn_kbn_upd_cust) THEN
      lv_validated_flag := ir_masters_rec.validated_flag;
--
    ELSE
      lv_validated_flag := gv_validated_flag_off;
    END IF;
    lr_organization_rec.party_rec.validated_flag := lv_validated_flag;
--
    IF (in_kbn = gn_kbn_upd_cust) THEN
      -- 属性２４
      lr_organization_rec.party_rec.attribute24 := TO_CHAR(SYSDATE,'YYYYMMDD');
    END IF;
--
    -- パーティマスタ(HZ_PARTY_V2PUB)
    HZ_PARTY_V2PUB.UPDATE_ORGANIZATION (
        P_INIT_MSG_LIST               => FND_API.G_FALSE
       ,P_ORGANIZATION_REC            => lr_organization_rec
       ,P_PARTY_OBJECT_VERSION_NUMBER => ln_object_version_number
       ,X_PROFILE_ID                  => ln_profile_id
       ,X_RETURN_STATUS               => lv_return_status
       ,X_MSG_COUNT                   => ln_msg_count
       ,X_MSG_DATA                    => lv_msg_data
    );
--
    -- 失敗
    IF (lv_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
      lv_api_name := 'HZ_PARTY_V2PUB.UPDATE_ORGANIZATION';
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,      gv_msg_80a_016,
                                            gv_tkn_api_name, lv_api_name);
--
      FND_MSG_PUB.GET( P_MSG_INDEX     => 1,
                       P_ENCODED       => FND_API.G_FALSE,
                       P_DATA          => lv_msg_data,
                       P_MSG_INDEX_OUT => ln_msg_count );
--
      lv_errbuf := lv_msg_data;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
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
  END update_hz_parties;
--
  /***********************************************************************************
   * Procedure Name   : update_hz_cust_accounts
   * Description      : 顧客マスタの更新処理を行います。
   ***********************************************************************************/
  PROCEDURE update_hz_cust_accounts(
    ir_masters_rec  IN OUT NOCOPY masters_rec,  -- チェック対象データ
    in_kbn          IN            NUMBER,       -- 処理区分
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_hz_cust_accounts'; -- プログラム名
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
    lv_api_name                     VARCHAR2(200);
    lr_cust_account_rec             HZ_CUST_ACCOUNT_V2PUB.CUST_ACCOUNT_REC_TYPE;
    lv_return_status                VARCHAR2(30);
    ln_msg_count                    NUMBER;
    lv_msg_data                     VARCHAR2(2000);
    ln_object_version_number        hz_cust_accounts.object_version_number%TYPE;
    lv_status                       hz_cust_accounts.status%TYPE;
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
    -- オブジェクトバージョン番号の取得
    exists_party_id(ir_masters_rec,
                    gn_kbn_site,
                    gv_status_on,
                    lv_errbuf,
                    lv_retcode,
                    lv_errmsg);
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    IF (ir_masters_rec.obj_cust_number IS NULL) THEN
--
      -- オブジェクトバージョン番号の取得
      exists_party_id(ir_masters_rec,
                      gn_kbn_party,
                      gv_status_on,
                      lv_errbuf,
                      lv_retcode,
                      lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
    END IF;
--
    IF (ir_masters_rec.obj_cust_number IS NULL) THEN
--
      -- オブジェクトバージョン番号の取得
      exists_party_id(ir_masters_rec,
                      gn_kbn_site,
                      gv_status_off,
                      lv_errbuf,
                      lv_retcode,
                      lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
    END IF;
--
    IF (ir_masters_rec.obj_cust_number IS NULL) THEN
--
      -- オブジェクトバージョン番号の取得
      exists_party_id(ir_masters_rec,
                      gn_kbn_party,
                      gv_status_off,
                      lv_errbuf,
                      lv_retcode,
                      lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
    END IF;
--
    -- 必須項目
    ln_object_version_number            := ir_masters_rec.obj_cust_number;
    lr_cust_account_rec.cust_account_id := ir_masters_rec.cust_account_id;
--
    -- ステータス
    IF (in_kbn = gn_kbn_upd_site) THEN
      lv_status := gv_status_on;
--
    ELSIF (in_kbn = gn_kbn_upd_cust) THEN
      lv_status := ir_masters_rec.status;
--
    ELSE
      lv_status := gv_status_off;
    END IF;
    lr_cust_account_rec.status := lv_status;
--
    IF (in_kbn = gn_kbn_upd_site) THEN
      -- 属性１
      lr_cust_account_rec.attribute1 := ir_masters_rec.old_division_code;
      -- 属性２
      lr_cust_account_rec.attribute2 := ir_masters_rec.new_division_code;
      -- 属性３
      lr_cust_account_rec.attribute3 := TO_CHAR(ir_masters_rec.division_start_date,'YYYY/MM/DD');
      -- 属性４
      lr_cust_account_rec.attribute4 := ir_masters_rec.location_rel_code;
      -- 属性５
      lr_cust_account_rec.attribute5 := ir_masters_rec.ship_mng_code;
      -- 属性６
      lr_cust_account_rec.attribute6 := ir_masters_rec.warehouse_code;
      -- 属性７
      lr_cust_account_rec.attribute7 := ir_masters_rec.terminal_code;
--2008/10/07 v1.11 DELETE START
--      -- 属性１３
--      lr_cust_account_rec.attribute13 := ir_masters_rec.district_code;
--2008/10/07 v1.11 DELETE END
--
    ELSIF (in_kbn = gn_kbn_upd_cust) THEN
      ln_object_version_number        := ir_masters_rec.obj_cust_number;
      -- 属性１２
      lr_cust_account_rec.attribute12 := ir_masters_rec.cal_cust_app_flg;
      -- 属性１５
      lr_cust_account_rec.attribute15 := ir_masters_rec.direct_ship_code;
--2008/10/07 v1.11 DELETE START
--      -- 属性１６
--      lr_cust_account_rec.attribute16 := ir_masters_rec.direct_ship_code;
--2008/10/07 v1.11 DELETE END
      -- 属性１７
      lr_cust_account_rec.attribute17 := ir_masters_rec.sale_base_code;
      -- 属性１８
      lr_cust_account_rec.attribute18 := ir_masters_rec.res_sale_base_code;
      -- 属性１９
      lr_cust_account_rec.attribute19 := ir_masters_rec.chain_store;
      -- 属性２０
      lr_cust_account_rec.attribute20 := ir_masters_rec.chain_store_name;
    END IF;
--
    -- 顧客マスタ(HZ_CUST_ACCOUNT_V2PUB)
    HZ_CUST_ACCOUNT_V2PUB.UPDATE_CUST_ACCOUNT (
        P_INIT_MSG_LIST         => FND_API.G_FALSE
       ,P_CUST_ACCOUNT_REC      => lr_cust_account_rec
       ,P_OBJECT_VERSION_NUMBER => ln_object_version_number
       ,X_RETURN_STATUS         => lv_return_status
       ,X_MSG_COUNT             => ln_msg_count
       ,X_MSG_DATA              => lv_msg_data
    );
--
    -- 失敗
    IF (lv_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
      lv_api_name := 'HZ_CUST_ACCOUNT_V2PUB.UPDATE_CUST_ACCOUNT';
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,      gv_msg_80a_016,
                                            gv_tkn_api_name, lv_api_name);
--
      FND_MSG_PUB.GET( P_MSG_INDEX     => 1,
                       P_ENCODED       => FND_API.G_FALSE,
                       P_DATA          => lv_msg_data,
                       P_MSG_INDEX_OUT => ln_msg_count );
--
      lv_errbuf := lv_msg_data;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
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
  END update_hz_cust_accounts;
--
  /***********************************************************************************
   * Procedure Name   : insert_hz_party_sites
   * Description      : パーティサイトマスタの登録処理を行います。
   ***********************************************************************************/
  PROCEDURE insert_hz_party_sites(
    ir_masters_rec  IN OUT NOCOPY masters_rec,  -- チェック対象データ
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_hz_party_sites'; -- プログラム名
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
    lv_api_name                     VARCHAR2(200);
    lr_party_site_rec               HZ_PARTY_SITE_V2PUB.PARTY_SITE_REC_TYPE;
    lr_location_rec                 HZ_LOCATION_V2PUB.LOCATION_REC_TYPE;
    lr_cust_site_rec                HZ_CUST_ACCOUNT_SITE_V2PUB.CUST_ACCT_SITE_REC_TYPE;
    lr_cust_site_use_rec            HZ_CUST_ACCOUNT_SITE_V2PUB.CUST_SITE_USE_REC_TYPE;
    lr_customer_profile_rec         HZ_CUSTOMER_PROFILE_V2PUB.CUSTOMER_PROFILE_REC_TYPE;
    ln_location_id                  hz_party_sites.location_id%TYPE;
    ln_cust_site_id                 hz_cust_acct_sites_all.cust_acct_site_id%TYPE;
    ln_site_use_id                  hz_cust_site_uses_all.site_use_id%TYPE;
    lv_return_status                VARCHAR2(30);
    ln_msg_count                    NUMBER;
    lv_msg_data                     VARCHAR2(2000);
    lv_party_site_number            hz_party_sites.party_site_number%TYPE;
    ln_party_site_id                NUMBER;
--
    lv_county                       hz_locations.county%TYPE;
--
    -- 2008/04/17 変更要求No61 対応
    ln_cnt                          NUMBER;
    lv_primary_flag                 hz_cust_site_uses_all.primary_flag%TYPE;
--
-- 2009/01/09 v1.12 ADD START
    lv_account_number               hz_cust_accounts.account_number%TYPE;
-- 2009/01/09 v1.12 ADD END
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
    -- パーティIDの取得
    get_party_id(ir_masters_rec,
                 lv_errbuf,
                 lv_retcode,
                 lv_errmsg);
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    lr_location_rec.country := 'JP';
    IF (ir_masters_rec.party_site_addr1 IS NOT NULL) THEN
        lr_location_rec.address1 := ir_masters_rec.party_site_addr1;
--
    ELSE
        lr_location_rec.address1 := gv_location_addr;
    END IF;
--
    IF (ir_masters_rec.party_site_addr2 IS NOT NULL) THEN
      lr_location_rec.address2 := ir_masters_rec.party_site_addr2;
    END IF;
    lr_location_rec.created_by_module := gv_created_by_module;
-- 2008/08/25 Add
    lv_county := ir_masters_rec.party_site_name1 || ir_masters_rec.party_site_name2;
    lr_location_rec.province := ir_masters_rec.ship_to_code;
    lr_location_rec.county   := lv_county;
--
    -- 顧客事業所マスタ(HZ_LOCATION_V2PUB)
    HZ_LOCATION_V2PUB.CREATE_LOCATION (
        P_INIT_MSG_LIST => FND_API.G_FALSE
       ,P_LOCATION_REC  => lr_location_rec
       ,X_LOCATION_ID   => ln_location_id
       ,X_RETURN_STATUS => lv_return_status
       ,X_MSG_COUNT     => ln_msg_count
       ,X_MSG_DATA      => lv_msg_data
    );
--
    -- 失敗
    IF (lv_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
      lv_api_name := 'HZ_LOCATION_V2PUB.CREATE_LOCATION';
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,      gv_msg_80a_016,
                                            gv_tkn_api_name, lv_api_name);
--
      FND_MSG_PUB.GET( P_MSG_INDEX     => 1,
                       P_ENCODED       => FND_API.G_FALSE,
                       P_DATA          => lv_msg_data,
                       P_MSG_INDEX_OUT => ln_msg_count );
--
      lv_errbuf := lv_msg_data;
      RAISE global_api_expt;
    END IF;
--
    lr_party_site_rec.party_id := ir_masters_rec.p_party_id;
    lr_party_site_rec.location_id := ln_location_id;
    lr_party_site_rec.created_by_module := gv_created_by_module;
--
    -- 2008/04/17 変更要求No61 対応
    lr_party_site_rec.party_site_number := NULL;
--
/* 2008/08/25 Del ↓
    lr_party_site_rec.party_site_name   := ir_masters_rec.party_site_name1||
                                           ir_masters_rec.party_site_name2;
2008/08/25 Del ↑ */
    lr_party_site_rec.attribute20       := TO_CHAR(SYSDATE,'YYYYMMDD');
    lr_party_site_rec.status            := gv_status_on;
--
    -- パーティサイトマスタ(HZ_PARTY_SITE_V2PUB)
    HZ_PARTY_SITE_V2PUB.CREATE_PARTY_SITE (
        P_INIT_MSG_LIST     => FND_API.G_FALSE
       ,P_PARTY_SITE_REC    => lr_party_site_rec
       ,X_PARTY_SITE_ID     => ln_party_site_id
       ,X_PARTY_SITE_NUMBER => lv_party_site_number
       ,X_RETURN_STATUS     => lv_return_status
       ,X_MSG_COUNT         => ln_msg_count
       ,X_MSG_DATA          => lv_msg_data
    );
--
    -- 失敗
    IF (lv_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
      lv_api_name := 'HZ_PARTY_SITE_V2PUB.CREATE_PARTY_SITE';
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,      gv_msg_80a_016,
                                            gv_tkn_api_name, lv_api_name);
--
      FND_MSG_PUB.GET( P_MSG_INDEX     => 1,
                       P_ENCODED       => FND_API.G_FALSE,
                       P_DATA          => lv_msg_data,
                       P_MSG_INDEX_OUT => ln_msg_count );
--
      lv_errbuf := lv_msg_data;
      RAISE global_api_expt;
    END IF;
--
    -- 2008/04/17 変更要求No61 対応
    -- 顧客所在地マスタの検索
    BEGIN
-- 2009/01/09 v1.12 ADD START
--
      -- 顧客コード=NULL
      IF (ir_masters_rec.party_num = gv_def_party_num) THEN
        lv_account_number := ir_masters_rec.base_code;       -- 拠点コード
      -- 顧客コード<>NULL
      ELSE
        lv_account_number := ir_masters_rec.party_num;       -- 顧客コード
      END IF;
--
-- 2009/01/09 v1.12 ADD END
      SELECT COUNT(hcas.cust_acct_site_id)
      INTO   ln_cnt
-- 2008/08/25 Mod ↓
/*
      FROM   hz_cust_acct_sites_all hcas
      WHERE  hcas.attribute18 = ir_masters_rec.ship_to_code
      AND    ROWNUM = 1;
*/
-- 2009/01/09 v1.12 UPDATE START
/*
      FROM   hz_party_sites         hps,                 -- パーティサイトマスタ
             hz_cust_acct_sites_all hcas,                -- 顧客所在地マスタ
             hz_locations           hzl                  -- 顧客事業所マスタ
      WHERE  hzl.location_id   = hps.location_id
      AND    hps.party_site_id = hcas.party_site_id
      AND    hps.status         = gv_status_on
      AND    hzl.province       = ir_masters_rec.ship_to_code;   -- 配送先コード
-- 2008/08/25 Mod ↑
*/
      FROM   hz_party_sites         hps,                 -- パーティサイトマスタ
             hz_cust_acct_sites_all hcas,                -- 顧客所在地マスタ
             hz_cust_accounts       hca                  -- 顧客マスタ
      WHERE  hps.party_site_id  = hcas.party_site_id
      AND    hps.party_id       = hca.party_id
      AND    hps.status         = gv_status_on
      AND    hca.account_number = lv_account_number
      ;
-- 2009/01/09 v1.12 UPDATE END
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ln_cnt := 0;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    IF (ln_cnt = 0) THEN
      lv_primary_flag := gv_primary_flag_on;
--
    ELSE
      lv_primary_flag := gv_primary_flag_off;
    END IF;
--
    ir_masters_rec.party_site_id := ln_party_site_id;
    ir_masters_rec.location_id   := ln_location_id;
--
    lr_cust_site_rec.cust_account_id   := ir_masters_rec.cust_account_id; -- 顧客ID
    lr_cust_site_rec.party_site_id     := ln_party_site_id;               -- パーティサイトID
    lr_cust_site_rec.created_by_module := gv_created_by_module;           -- 作成モジュール
/* 2008/08/25 Del ↓
    lr_cust_site_rec.attribute18       := ir_masters_rec.ship_to_code;    -- 属性１８
2008/08/25 Del ↑ */
-- 2008/08/18 Add
    lr_cust_site_rec.attribute_category := FND_PROFILE.VALUE('ORG_ID');
-- 2009/04/03 ADD START
    -- 配送先基準カレンダを初期値設定する
    lr_cust_site_rec.attribute1         := FND_PROFILE.VALUE('XXCMN_DRNK_DELIVER_TO_STD_CAL');
    lr_cust_site_rec.attribute19        := FND_PROFILE.VALUE('XXCMN_LEAF_DELIVER_TO_STD_CAL');
-- 2009/04/03 ADD END
--
    -- 顧客所在地マスタ(HZ_CUST_ACCOUNT_SITE_V2PUB)
    HZ_CUST_ACCOUNT_SITE_V2PUB.CREATE_CUST_ACCT_SITE (
        P_INIT_MSG_LIST      => FND_API.G_FALSE
       ,P_CUST_ACCT_SITE_REC => lr_cust_site_rec
       ,X_CUST_ACCT_SITE_ID  => ln_cust_site_id
       ,X_RETURN_STATUS      => lv_return_status
       ,X_MSG_COUNT          => ln_msg_count
       ,X_MSG_DATA           => lv_msg_data
    );
--
    -- 失敗
    IF (lv_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
      lv_api_name := 'HZ_CUST_ACCOUNT_SITE_V2PUB.CREATE_CUST_ACCT_SITE';
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,      gv_msg_80a_016,
                                            gv_tkn_api_name, lv_api_name);
--
      FND_MSG_PUB.GET( P_MSG_INDEX     => 1,
                       P_ENCODED       => FND_API.G_FALSE,
                       P_DATA          => lv_msg_data,
                       P_MSG_INDEX_OUT => ln_msg_count );
--
      lv_errbuf := lv_msg_data;
      RAISE global_api_expt;
    END IF;
--
    -- 請求先
    lr_cust_site_use_rec.cust_acct_site_id := ln_cust_site_id;
    lr_cust_site_use_rec.site_use_code     := 'BILL_TO';
    lr_cust_site_use_rec.primary_flag      := lv_primary_flag;
    lr_cust_site_use_rec.status            := gv_status_on;
    lr_cust_site_use_rec.location          := ln_cust_site_id;
    lr_cust_site_use_rec.created_by_module := gv_created_by_module;
--
    -- 顧客使用目的マスタ(HZ_CUST_ACCOUNT_SITE_V2PUB)
    HZ_CUST_ACCOUNT_SITE_V2PUB.CREATE_CUST_SITE_USE(
        P_INIT_MSG_LIST        => FND_API.G_FALSE
       ,P_CUST_SITE_USE_REC    => lr_cust_site_use_rec
       ,P_CUSTOMER_PROFILE_REC => lr_customer_profile_rec
       ,P_CREATE_PROFILE       => FND_API.G_TRUE
       ,P_CREATE_PROFILE_AMT   => FND_API.G_TRUE
       ,X_SITE_USE_ID          => ln_site_use_id
       ,X_RETURN_STATUS        => lv_return_status
       ,X_MSG_COUNT            => ln_msg_count
       ,X_MSG_DATA             => lv_msg_data
    );
--
    -- 失敗
    IF (lv_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
      lv_api_name := 'HZ_CUST_ACCOUNT_SITE_V2PUB.CREATE_CUST_SITE_USE';
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,      gv_msg_80a_016,
                                            gv_tkn_api_name, lv_api_name);
--
      FND_MSG_PUB.GET( P_MSG_INDEX     => 1,
                       P_ENCODED       => FND_API.G_FALSE,
                       P_DATA          => lv_msg_data,
                       P_MSG_INDEX_OUT => ln_msg_count );
--
      lv_errbuf := lv_msg_data;
      RAISE global_api_expt;
    END IF;
--
    -- 出荷先
    lr_cust_site_use_rec.cust_acct_site_id   := ln_cust_site_id;
    lr_cust_site_use_rec.site_use_code       := 'SHIP_TO';
    lr_cust_site_use_rec.primary_flag        := lv_primary_flag;
    lr_cust_site_use_rec.status              := gv_status_on;
    lr_cust_site_use_rec.location            := ln_cust_site_id;
    lr_cust_site_use_rec.bill_to_site_use_id := ln_site_use_id;
    lr_cust_site_use_rec.created_by_module   := gv_created_by_module;
--
    -- 顧客使用目的マスタ(HZ_CUST_ACCOUNT_SITE_V2PUB)
    HZ_CUST_ACCOUNT_SITE_V2PUB.CREATE_CUST_SITE_USE(
        P_INIT_MSG_LIST         => FND_API.G_FALSE
       ,P_CUST_SITE_USE_REC     => lr_cust_site_use_rec
       ,P_CUSTOMER_PROFILE_REC  => lr_customer_profile_rec
       ,P_CREATE_PROFILE        => FND_API.G_TRUE
       ,P_CREATE_PROFILE_AMT    => FND_API.G_TRUE
       ,X_SITE_USE_ID           => ln_site_use_id
       ,X_RETURN_STATUS         => lv_return_status
       ,X_MSG_COUNT             => ln_msg_count
       ,X_MSG_DATA              => lv_msg_data
    );
--
    -- 失敗
    IF (lv_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
      lv_api_name := 'HZ_CUST_ACCOUNT_SITE_V2PUB.CREATE_CUST_SITE_USE';
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,      gv_msg_80a_016,
                                            gv_tkn_api_name, lv_api_name);
--
      FND_MSG_PUB.GET( P_MSG_INDEX     => 1,
                       P_ENCODED       => FND_API.G_FALSE,
                       P_DATA          => lv_msg_data,
                       P_MSG_INDEX_OUT => ln_msg_count );
--
      lv_errbuf := lv_msg_data;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
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
  END insert_hz_party_sites;
--
  /***********************************************************************************
   * Procedure Name   : update_hz_party_sites
   * Description      : パーティサイトマスタの更新処理を行います。
   ***********************************************************************************/
  PROCEDURE update_hz_party_sites(
    ir_masters_rec  IN OUT NOCOPY masters_rec,  -- チェック対象データ
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_hz_party_sites'; -- プログラム名
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
    lv_api_name                     VARCHAR2(200);
    lr_party_site_rec               HZ_PARTY_SITE_V2PUB.PARTY_SITE_REC_TYPE;
    lr_cust_site_rec                HZ_CUST_ACCOUNT_SITE_V2PUB.CUST_ACCT_SITE_REC_TYPE;
    lv_return_status                VARCHAR2(30);
    ln_msg_count                    NUMBER;
    lv_msg_data                     VARCHAR2(2000);
    lv_party_site_number            hz_party_sites.party_site_number%TYPE;
    ln_party_site_id                hz_party_sites.party_site_id%TYPE;
    ln_object_version_number        hz_party_sites.object_version_number%TYPE;
    lb_retcd                        BOOLEAN;
-- 2008/08/25 Add ↓
    lr_location_rec                 HZ_LOCATION_V2PUB.LOCATION_REC_TYPE;
    lv_county                       hz_locations.county%TYPE;
-- 2008/08/25 Add ↑
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
    -- パーティサイトIDの取得(有効)
    get_party_site_id(ir_masters_rec,
                      lb_retcd,
                      lv_errbuf,
                      lv_retcode,
                      lv_errmsg);
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    IF (NOT lb_retcd) THEN
      -- パーティサイトIDの取得(無効)
      get_party_site_id_2(ir_masters_rec,
                        lb_retcd,
                        lv_errbuf,
                        lv_retcode,
                        lv_errmsg);
    END IF;
/*
--
    IF (NOT lb_retcd) THEN
      -- パーティサイトIDの取得
      get_site_to_if(ir_masters_rec,
                     lb_retcd,
                     lv_errbuf,
                     lv_retcode,
                     lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      IF (NOT lb_retcd) THEN
        -- パーティサイトIDの取得
        get_site_number(ir_masters_rec,
                        lb_retcd,
                        lv_errbuf,
                        lv_retcode,
                        lv_errmsg);
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
        END IF;
      END IF;
    END IF;
*/
--
    lr_party_site_rec.party_site_id := ir_masters_rec.party_site_id;
    lr_party_site_rec.party_id      := ir_masters_rec.p_party_id;
    lr_party_site_rec.location_id   := ir_masters_rec.location_id;
    ln_object_version_number        := ir_masters_rec.obj_site_number;
--
    -- ステータス
    lr_party_site_rec.status := ir_masters_rec.status;
--
    -- パーティサイトマスタ(HZ_PARTY_SITE_V2PUB)
    HZ_PARTY_SITE_V2PUB.UPDATE_PARTY_SITE (
        P_INIT_MSG_LIST         => FND_API.G_FALSE
       ,P_PARTY_SITE_REC        => lr_party_site_rec
       ,P_OBJECT_VERSION_NUMBER => ln_object_version_number
       ,X_RETURN_STATUS         => lv_return_status
       ,X_MSG_COUNT             => ln_msg_count
       ,X_MSG_DATA              => lv_msg_data
    );
--
    -- 失敗
    IF (lv_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
      lv_api_name := 'HZ_PARTY_SITE_V2PUB.UPDATE_PARTY_SITE';
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,      gv_msg_80a_016,
                                            gv_tkn_api_name, lv_api_name);
--
      FND_MSG_PUB.GET( P_MSG_INDEX     => 1,
                       P_ENCODED       => FND_API.G_FALSE,
                       P_DATA          => lv_msg_data,
                       P_MSG_INDEX_OUT => ln_msg_count );
--
      lv_errbuf := lv_msg_data;
      RAISE global_api_expt;
    END IF;
--
    lr_cust_site_rec.cust_acct_site_id := ir_masters_rec.cust_acct_site_id;
    lr_cust_site_rec.status := ir_masters_rec.status;
    ln_object_version_number := ir_masters_rec.obj_acct_number;
--
    -- 顧客所在地マスタ(HZ_CUST_ACCOUNT_SITE_V2PUB)
    HZ_CUST_ACCOUNT_SITE_V2PUB.UPDATE_CUST_ACCT_SITE (
        P_INIT_MSG_LIST         => FND_API.G_FALSE
       ,P_CUST_ACCT_SITE_REC    => lr_cust_site_rec
       ,p_object_version_number => ln_object_version_number
       ,X_RETURN_STATUS         => lv_return_status
       ,X_MSG_COUNT             => ln_msg_count
       ,X_MSG_DATA              => lv_msg_data
    );
--
    -- 失敗
    IF (lv_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
      lv_api_name := 'HZ_CUST_ACCOUNT_SITE_V2PUB.UPDATE_CUST_ACCT_SITE';
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,      gv_msg_80a_016,
                                            gv_tkn_api_name, lv_api_name);
--
      FND_MSG_PUB.GET( P_MSG_INDEX     => 1,
                       P_ENCODED       => FND_API.G_FALSE,
                       P_DATA          => lv_msg_data,
                       P_MSG_INDEX_OUT => ln_msg_count );
--
      lv_errbuf := lv_msg_data;
      RAISE global_api_expt;
    END IF;
-- 2008/08/25 Add ↓
    lv_county := ir_masters_rec.party_site_name1 || ir_masters_rec.party_site_name2;
    lr_location_rec.location_id := ir_masters_rec.hzl_location_id;
    lr_location_rec.county      := lv_county;
    ln_object_version_number    := ir_masters_rec.hzl_obj_number;
--
    -- 顧客事業所マスタ(HZ_LOCATION_V2PUB)
    HZ_LOCATION_V2PUB.UPDATE_LOCATION (
        P_INIT_MSG_LIST         => FND_API.G_FALSE
       ,P_LOCATION_REC          => lr_location_rec
       ,P_OBJECT_VERSION_NUMBER => ln_object_version_number
       ,X_RETURN_STATUS         => lv_return_status
       ,X_MSG_COUNT             => ln_msg_count
       ,X_MSG_DATA              => lv_msg_data
    );
--
    IF (lv_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
      lv_api_name := 'HZ_LOCATION_V2PUB.UPDATE_LOCATION';
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,      gv_msg_80a_016,
                                            gv_tkn_api_name, lv_api_name);
--
      lv_errbuf := lv_msg_data;
      RAISE global_api_expt;
    END IF;
-- 2008/08/25 Add ↑
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
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
  END update_hz_party_sites;
--
  /***********************************************************************************
   * Procedure Name   : proc_party
   * Description      : 拠点反映処理を行います。
   ***********************************************************************************/
  PROCEDURE proc_party(
    ir_report_rec   IN OUT NOCOPY report_rec,   -- レポートデータ
    ir_masters_rec  IN OUT NOCOPY masters_rec,  -- チェック対象データ
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_party'; -- プログラム名
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
    -- 登録以外
    IF (ir_masters_rec.proc_code <> gn_proc_insert) THEN
--
      -- パーティマスタ存在チェック
      get_hz_parties(ir_masters_rec,
                     gn_kbn_party,
                     lv_errbuf,
                     lv_retcode,
                     lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      -- 顧客マスタ存在チェック
      get_hz_cust_accounts(ir_masters_rec,
                           gn_kbn_party,
                           lv_errbuf,
                           lv_retcode,
                           lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
    END IF;
--
    -- 拠点登録情報
    IF (ir_masters_rec.proc_code = gn_proc_insert) THEN
--
      -- パーティマスタ・顧客マスタ登録
      create_party_account(ir_masters_rec,
                           gn_kbn_party,
                           lv_errbuf,
                           lv_retcode,
                           lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
      ir_report_rec.hps_flg := 1;
      ir_report_rec.hca_flg := 1;
--
      -- パーティアドオンマスタ(直接登録)
      proc_xxcmn_party(ir_masters_rec,
                       gn_proc_insert,
                       lv_errbuf,
                       lv_retcode,
                       lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
      ir_report_rec.xps_flg := 1;
--
    -- 拠点更新情報
    ELSIF (ir_masters_rec.proc_code = gn_proc_update) THEN
--
      -- パーティマスタ更新
      update_hz_parties(ir_masters_rec,
                        gn_kbn_upd_site,
                        lv_errbuf,
                        lv_retcode,
                        lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
      ir_report_rec.hps_flg := 1;
--
      -- 顧客マスタ更新
      update_hz_cust_accounts(ir_masters_rec,
                              gn_kbn_upd_site,
                              lv_errbuf,
                              lv_retcode,
                              lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
      ir_report_rec.hca_flg := 1;
--
      -- パーティアドオンマスタ(直接更新)
      proc_xxcmn_party(ir_masters_rec,
                       gn_proc_update,
                       lv_errbuf,
                       lv_retcode,
                       lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
      ir_report_rec.xps_flg := 1;
--
    -- 拠点削除情報
    ELSIF (ir_masters_rec.proc_code = gn_proc_delete) THEN
--
      -- パーティマスタ更新
      update_hz_parties(ir_masters_rec,
                        gn_kbn_del_site,
                        lv_errbuf,
                        lv_retcode,
                        lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
      ir_report_rec.hps_flg := 1;
--
      -- 顧客マスタ更新
      update_hz_cust_accounts(ir_masters_rec,
                              gn_kbn_del_site,
                              lv_errbuf,
                              lv_retcode,
                              lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
      ir_report_rec.hca_flg := 1;
    END IF;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
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
  END proc_party;
--
  /***********************************************************************************
   * Procedure Name   : proc_cust
   * Description      : 顧客反映処理を行います。
   ***********************************************************************************/
  PROCEDURE proc_cust(
    ir_report_rec   IN OUT NOCOPY report_rec,   -- レポートデータ
    ir_masters_rec  IN OUT NOCOPY masters_rec,  -- チェック対象データ
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_cust'; -- プログラム名
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
    lv_validated_flag       hz_parties.validated_flag%TYPE;          -- 有効フラグ
    lv_status               hz_cust_accounts.status%TYPE;            -- 有効ステータス
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
    -- 登録以外
    IF (ir_masters_rec.proc_code <> gn_proc_insert) THEN
--
      IF (ir_masters_rec.p_party_id IS NULL) THEN
--
        -- パーティマスタ存在チェック
        get_hz_parties(ir_masters_rec,
                       gn_kbn_site,
                       lv_errbuf,
                       lv_retcode,
                       lv_errmsg);
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
        END IF;
      END IF;
--
      IF (ir_masters_rec.c_party_id IS NULL) THEN
--
        -- 顧客マスタ存在チェック
        get_hz_cust_accounts(ir_masters_rec,
                             gn_kbn_site,
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
    -- 顧客登録情報
    IF (ir_masters_rec.proc_code = gn_proc_insert) THEN
--
      -- パーティマスタ・顧客マスタ登録
      create_party_account(ir_masters_rec,
                           gn_kbn_site,
                           lv_errbuf,
                           lv_retcode,
                           lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
      ir_report_rec.hps_flg := 1;
      ir_report_rec.hca_flg := 1;
--
      -- パーティアドオンマスタ(直接登録)
      proc_xxcmn_party(ir_masters_rec,
                       gn_proc_insert,
                       lv_errbuf,
                       lv_retcode,
                       lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
      ir_report_rec.xps_flg := 1;
--
    -- 顧客更新情報
    ELSIF (ir_masters_rec.proc_code = gn_proc_update) THEN
--
      -- パーティマスタ更新
      update_hz_parties(ir_masters_rec,
                        gn_kbn_upd_cust,
                        lv_errbuf,
                        lv_retcode,
                        lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
      ir_report_rec.hps_flg := 1;
--
      -- 顧客マスタ更新
      update_hz_cust_accounts(ir_masters_rec,
                              gn_kbn_upd_cust,
                              lv_errbuf,
                              lv_retcode,
                              lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
      ir_report_rec.hca_flg := 1;
--
      -- パーティアドオンマスタ(直接更新)
      proc_xxcmn_party(ir_masters_rec,
                       gn_proc_update,
                       lv_errbuf,
                       lv_retcode,
                       lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
      ir_report_rec.xps_flg := 1;
--
    -- 顧客削除情報
    ELSIF (ir_masters_rec.proc_code = gn_proc_delete) THEN
--
      -- パーティマスタ更新
      update_hz_parties(ir_masters_rec,
                        gn_kbn_del_cust,
                        lv_errbuf,
                        lv_retcode,
                        lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
      ir_report_rec.hps_flg := 1;
--
      -- 顧客マスタ更新
      update_hz_cust_accounts(ir_masters_rec,
                              gn_kbn_del_cust,
                              lv_errbuf,
                              lv_retcode,
                              lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
      ir_report_rec.hca_flg := 1;
    END IF;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
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
  END proc_cust;
--
  /***********************************************************************************
   * Procedure Name   : proc_site
   * Description      : 配送先反映処理を行います。
   ***********************************************************************************/
  PROCEDURE proc_site(
    ir_report_rec   IN OUT NOCOPY report_rec,   -- レポートデータ
    ir_masters_rec  IN OUT NOCOPY masters_rec,  -- チェック対象データ
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_site'; -- プログラム名
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
    lv_validated_flag       hz_parties.validated_flag%TYPE;          -- 有効フラグ
    lv_status               hz_cust_accounts.status%TYPE;            -- 有効ステータス
    lb_retcd   BOOLEAN;
    ln_kbn     NUMBER;
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
    -- 登録以外
    IF ((ir_masters_rec.proc_code <> gn_proc_insert)
      AND (ir_masters_rec.proc_code <> gn_proc_s_ins)
      AND (ir_masters_rec.proc_code <> gn_proc_c_ins)) THEN
--
      -- パーティーサイトマスタの取得
      get_hz_party_sites(ir_masters_rec,
                         lb_retcd,
                         lv_errbuf,
                         lv_retcode,
                         lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
    -- 登録
    ELSE
-- 2008/08/25 Mod ↓
/*
      IF (ir_masters_rec.party_num IS NULL) THEN
*/
      IF (ir_masters_rec.party_num = gv_def_party_num) THEN
-- 2008/08/25 Mod ↑
        ln_kbn := gn_kbn_party;
      ELSE
        ln_kbn := gn_kbn_site;
      END IF;
--
      lv_validated_flag := ir_masters_rec.validated_flag;
      lv_status         := ir_masters_rec.status;
--
      -- パーティマスタ存在チェック
      get_hz_parties(ir_masters_rec,
                     ln_kbn,
                     lv_errbuf,
                     lv_retcode,
                     lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      IF (lv_validated_flag IS NOT NULL) THEN
        ir_masters_rec.validated_flag := lv_validated_flag;
      END IF;
--
      IF (lv_status IS NOT NULL) THEN
        ir_masters_rec.status := lv_status;
      END IF;
    END IF;
--
    -- 登録
    -- 登録(拠点紐付き)
    -- 登録(顧客紐付き)
    IF ((ir_masters_rec.proc_code = gn_proc_insert)
     OR (ir_masters_rec.proc_code = gn_proc_s_ins)
     OR (ir_masters_rec.proc_code = gn_proc_c_ins)) THEN
--
      -- パーティサイトマスタ登録
      insert_hz_party_sites(ir_masters_rec,
                            lv_errbuf,
                            lv_retcode,
                            lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
      ir_report_rec.hpss_flg := 1;
      ir_report_rec.hcas_flg := 1;
      ir_report_rec.hcsu_flg := 1;
--
      ir_report_rec.hzl_flg  := 1;           -- 2008/08/25 Add
--
      -- パーティサイトアドオンマスタ(直接登録)
      proc_xxcmn_party_site(ir_masters_rec,
                            gn_proc_insert,
                            lv_errbuf,
                            lv_retcode,
                            lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
      ir_report_rec.xpss_flg := 1;
    END IF;
--
    -- 更新
    -- 更新(拠点紐付き)
    -- 更新(顧客紐付き)
    IF ((ir_masters_rec.proc_code = gn_proc_update)
     OR (ir_masters_rec.proc_code = gn_proc_s_upd)
     OR (ir_masters_rec.proc_code = gn_proc_c_upd)) THEN
--
      ir_masters_rec.status := gv_status_on;
--
      -- パーティサイトマスタ更新
      update_hz_party_sites(ir_masters_rec,
                            lv_errbuf,
                            lv_retcode,
                            lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
      ir_report_rec.hpss_flg := 1;
      ir_report_rec.hcas_flg := 1;
      ir_report_rec.hzl_flg  := 1;           -- 2008/08/25 Add
--
      -- パーティサイトアドオンマスタ(直接更新)
      proc_xxcmn_party_site(ir_masters_rec,
                            gn_proc_update,
                            lv_errbuf,
                            lv_retcode,
                            lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
      ir_report_rec.xpss_flg := 1;
    END IF;
--
    -- 削除
    -- 削除/登録(拠点紐付き)
    -- 削除/登録(顧客紐付き)
    -- 削除(拠点紐付き)
    -- 削除(顧客紐付き)
    IF ((ir_masters_rec.proc_code = gn_proc_delete)
     OR (ir_masters_rec.proc_code = gn_proc_s_del)
     OR (ir_masters_rec.proc_code = gn_proc_c_del)
     OR (ir_masters_rec.proc_code = gn_proc_ds_del)
     OR (ir_masters_rec.proc_code = gn_proc_dc_del)) THEN
--
      ir_masters_rec.status := gv_status_off;
--
      -- パーティサイトマスタ更新
      update_hz_party_sites(ir_masters_rec,
                            lv_errbuf,
                            lv_retcode,
                            lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      -- 削除/登録(拠点紐付き)
      -- 削除/登録(顧客紐付き)
      IF ((ir_masters_rec.proc_code = gn_proc_s_del)
       OR (ir_masters_rec.proc_code = gn_proc_c_del)) THEN
        -- パーティサイトマスタ登録
        insert_hz_party_sites(ir_masters_rec,
                              lv_errbuf,
                              lv_retcode,
                              lv_errmsg);
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
        END IF;
        ir_report_rec.hcsu_flg := 1;
--
        -- パーティサイトアドオンマスタ(直接登録)
        proc_xxcmn_party_site(ir_masters_rec,
                              gn_proc_insert,
                              lv_errbuf,
                              lv_retcode,
                              lv_errmsg);
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
        END IF;
        ir_report_rec.xpss_flg := 1;
      END IF;
    END IF;
    ir_report_rec.hpss_flg := 1;
    ir_report_rec.hcas_flg := 1;
--
    ir_report_rec.hzl_flg  := 1;             -- 2008/08/25 Add
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
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
  END proc_site;
--
  /***********************************************************************************
   * Procedure Name   : proc_party_main
   * Description      : 拠点反映処理を制御します。(A-14)
   ***********************************************************************************/
  PROCEDURE proc_party_main(
    it_party_ins        IN OUT NOCOPY masters_tbl,    -- 各マスタへ登録するデータ
    it_party_upd        IN OUT NOCOPY masters_tbl,    -- 各マスタへ更新するデータ
    it_party_del        IN OUT NOCOPY masters_tbl,    -- 各マスタへ削除するデータ
    it_party_report_tbl IN OUT NOCOPY report_tbl,     -- レポート出力結合配列
    in_party_ins_cnt    IN            NUMBER,         -- 登録件数(拠点)
    in_party_upd_cnt    IN            NUMBER,         -- 更新件数(拠点)
    in_party_del_cnt    IN            NUMBER,         -- 削除件数(拠点)
    ov_errbuf              OUT NOCOPY VARCHAR2,       -- エラー・メッセージ           --# 固定 #
    ov_retcode             OUT NOCOPY VARCHAR2,       -- リターン・コード             --# 固定 #
    ov_errmsg              OUT NOCOPY VARCHAR2)       -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_party_main'; -- プログラム名
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
    ln_exec_cnt     NUMBER;
    ln_log_cnt      NUMBER;
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
    <<insert_proc_loop>>
    FOR ln_exec_cnt IN 0..in_party_ins_cnt-1 LOOP
      <<log_loop>>
      FOR ln_log_cnt IN 0..gn_p_report_cnt-1 LOOP
        -- 登録
        IF (it_party_report_tbl(ln_log_cnt).proc_code = gn_proc_insert) THEN
          -- SEQ番号が同じ
          IF (it_party_report_tbl(ln_log_cnt).seq_number =
              it_party_ins(ln_exec_cnt).seq_number) THEN
--
            -- 拠点反映処理(登録)
            proc_party(it_party_report_tbl(ln_log_cnt),
                       it_party_ins(ln_exec_cnt),
                       lv_errbuf,
                       lv_retcode,
                       lv_errmsg);
--
            IF (lv_retcode <> gv_status_normal) THEN
              RAISE global_api_expt;
            END IF;
            EXIT log_loop;
          END IF;
        END IF;
      END LOOP log_loop;
    END LOOP insert_proc_loop;
--
    <<update_proc_loop>>
    FOR ln_exec_cnt IN 0..in_party_upd_cnt-1 LOOP
      <<log_loop>>
      FOR ln_log_cnt IN 0..gn_p_report_cnt-1 LOOP
        -- 更新
        IF (it_party_report_tbl(ln_log_cnt).proc_code = gn_proc_update) THEN
          -- SEQ番号が同じ
          IF (it_party_report_tbl(ln_log_cnt).seq_number =
              it_party_upd(ln_exec_cnt).seq_number) THEN
--
            -- 拠点反映処理(更新)
            proc_party(it_party_report_tbl(ln_log_cnt),
                       it_party_upd(ln_exec_cnt),
                       lv_errbuf,
                       lv_retcode,
                       lv_errmsg);
--
            IF (lv_retcode <> gv_status_normal) THEN
              RAISE global_api_expt;
            END IF;
            EXIT log_loop;
          END IF;
        END IF;
      END LOOP log_loop;
    END LOOP update_proc_loop;
--
    <<delete_proc_loop>>
    FOR ln_exec_cnt IN 0..in_party_del_cnt-1 LOOP
      <<log_loop>>
      FOR ln_log_cnt IN 0..gn_p_report_cnt-1 LOOP
        -- 削除
        IF (it_party_report_tbl(ln_log_cnt).proc_code = gn_proc_delete) THEN
          -- SEQ番号が同じ
          IF (it_party_report_tbl(ln_log_cnt).seq_number =
              it_party_del(ln_exec_cnt).seq_number) THEN
--
            -- 拠点反映処理(削除)
            proc_party(it_party_report_tbl(ln_log_cnt),
                       it_party_del(ln_exec_cnt),
                       lv_errbuf,
                       lv_retcode,
                       lv_errmsg);
--
            IF (lv_retcode <> gv_status_normal) THEN
              RAISE global_api_expt;
            END IF;
            EXIT log_loop;
          END IF;
        END IF;
      END LOOP log_loop;
    END LOOP delete_proc_loop;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
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
  END proc_party_main;
--
  /***********************************************************************************
   * Procedure Name   : proc_cust_main
   * Description      : 顧客反映処理を制御します。(A-15)
   ***********************************************************************************/
  PROCEDURE proc_cust_main(
    it_cust_ins         IN OUT NOCOPY masters_tbl,    -- 各マスタへ登録するデータ
    it_cust_upd         IN OUT NOCOPY masters_tbl,    -- 各マスタへ更新するデータ
    it_cust_report_tbl  IN OUT NOCOPY report_tbl,     -- レポート出力結合配列
    in_cust_ins_cnt     IN            NUMBER,         -- 登録件数(顧客)
    in_cust_upd_cnt     IN            NUMBER,         -- 更新件数(顧客)
    ov_errbuf              OUT NOCOPY VARCHAR2,       -- エラー・メッセージ           --# 固定 #
    ov_retcode             OUT NOCOPY VARCHAR2,       -- リターン・コード             --# 固定 #
    ov_errmsg              OUT NOCOPY VARCHAR2)       -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_cust_main'; -- プログラム名
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
    ln_exec_cnt     NUMBER;
    ln_log_cnt      NUMBER;
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
    <<insert_proc_loop>>
    FOR ln_exec_cnt IN 0..in_cust_ins_cnt-1 LOOP
      <<log_loop>>
      FOR ln_log_cnt IN 0..gn_c_report_cnt-1 LOOP
        -- 登録
        IF (it_cust_report_tbl(ln_log_cnt).proc_code = gn_proc_insert) THEN
          -- SEQ番号が同じ
          IF (it_cust_report_tbl(ln_log_cnt).seq_number =
              it_cust_ins(ln_exec_cnt).seq_number) THEN
--
            -- 顧客反映処理(登録)
            proc_cust(it_cust_report_tbl(ln_log_cnt),
                      it_cust_ins(ln_exec_cnt),
                      lv_errbuf,
                      lv_retcode,
                      lv_errmsg);
--
            IF (lv_retcode <> gv_status_normal) THEN
              RAISE global_api_expt;
            END IF;
            EXIT log_loop;
          END IF;
        END IF;
      END LOOP log_loop;
    END LOOP insert_proc_loop;
--
    <<update_proc_loop>>
    FOR ln_exec_cnt IN 0..in_cust_upd_cnt-1 LOOP
      <<log_loop>>
      FOR ln_log_cnt IN 0..gn_c_report_cnt-1 LOOP
        -- 更新
        IF (it_cust_report_tbl(ln_log_cnt).proc_code = gn_proc_update) THEN
          -- SEQ番号が同じ
          IF (it_cust_report_tbl(ln_log_cnt).seq_number =
              it_cust_upd(ln_exec_cnt).seq_number) THEN
--
            -- 顧客反映処理(更新)
            proc_cust(it_cust_report_tbl(ln_log_cnt),
                      it_cust_upd(ln_exec_cnt),
                      lv_errbuf,
                      lv_retcode,
                      lv_errmsg);
--
            IF (lv_retcode <> gv_status_normal) THEN
              RAISE global_api_expt;
            END IF;
            EXIT log_loop;
          END IF;
        END IF;
      END LOOP log_loop;
    END LOOP update_proc_loop;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
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
  END proc_cust_main;
--
  /***********************************************************************************
   * Procedure Name   : proc_site_main
   * Description      : 配送先反映処理を制御します。(A-16)
   ***********************************************************************************/
  PROCEDURE proc_site_main(
    it_site_ins         IN OUT NOCOPY masters_tbl,    -- 各マスタへ登録するデータ
    it_site_upd         IN OUT NOCOPY masters_tbl,    -- 各マスタへ更新するデータ
    it_site_del         IN OUT NOCOPY masters_tbl,    -- 各マスタへ削除するデータ
    it_site_report_tbl  IN OUT NOCOPY report_tbl,     -- レポート出力結合配列
    in_site_ins_cnt     IN            NUMBER,         -- 登録件数(配送先)
    in_site_upd_cnt     IN            NUMBER,         -- 更新件数(配送先)
    in_site_del_cnt     IN            NUMBER,         -- 削除件数(配送先)
    ov_errbuf              OUT NOCOPY VARCHAR2,       -- エラー・メッセージ           --# 固定 #
    ov_retcode             OUT NOCOPY VARCHAR2,       -- リターン・コード             --# 固定 #
    ov_errmsg              OUT NOCOPY VARCHAR2)       -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_site_main'; -- プログラム名
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
    ln_exec_cnt     NUMBER;
    ln_log_cnt      NUMBER;
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
    <<insert_proc_loop>>
    FOR ln_exec_cnt IN 0..in_site_ins_cnt-1 LOOP
      <<log_loop>>
      FOR ln_log_cnt IN 0..gn_s_report_cnt-1 LOOP
        -- 登録
        IF ((it_site_report_tbl(ln_log_cnt).proc_code = gn_proc_insert)
         OR (it_site_report_tbl(ln_log_cnt).proc_code = gn_proc_s_ins)
         OR (it_site_report_tbl(ln_log_cnt).proc_code = gn_proc_c_ins)) THEN
          -- SEQ番号が同じ
          IF (it_site_report_tbl(ln_log_cnt).seq_number =
              it_site_ins(ln_exec_cnt).seq_number) THEN
--
            -- 配送先反映処理(登録)
            proc_site(it_site_report_tbl(ln_log_cnt),
                      it_site_ins(ln_exec_cnt),
                      lv_errbuf,
                      lv_retcode,
                      lv_errmsg);
--
            IF (lv_retcode <> gv_status_normal) THEN
              RAISE global_api_expt;
            END IF;
            EXIT log_loop;
          END IF;
        END IF;
      END LOOP log_loop;
    END LOOP insert_proc_loop;
--
    <<update_proc_loop>>
    FOR ln_exec_cnt IN 0..in_site_upd_cnt-1 LOOP
      <<log_loop>>
      FOR ln_log_cnt IN 0..gn_s_report_cnt-1 LOOP
        -- 更新
        IF ((it_site_report_tbl(ln_log_cnt).proc_code = gn_proc_update)
         OR (it_site_report_tbl(ln_log_cnt).proc_code = gn_proc_s_upd)
         OR (it_site_report_tbl(ln_log_cnt).proc_code = gn_proc_c_upd)) THEN
          -- SEQ番号が同じ
          IF (it_site_report_tbl(ln_log_cnt).seq_number =
              it_site_upd(ln_exec_cnt).seq_number) THEN
--
            -- 配送先反映処理(更新)
            proc_site(it_site_report_tbl(ln_log_cnt),
                      it_site_upd(ln_exec_cnt),
                      lv_errbuf,
                      lv_retcode,
                      lv_errmsg);
--
            IF (lv_retcode <> gv_status_normal) THEN
              RAISE global_api_expt;
            END IF;
            EXIT log_loop;
          END IF;
        END IF;
      END LOOP log_loop;
    END LOOP update_proc_loop;
--
    <<delete_proc_loop>>
    FOR ln_exec_cnt IN 0..in_site_del_cnt-1 LOOP
      <<log_loop>>
      FOR ln_log_cnt IN 0..gn_s_report_cnt-1 LOOP
        -- 削除
        IF ((it_site_report_tbl(ln_log_cnt).proc_code = gn_proc_delete)
         OR (it_site_report_tbl(ln_log_cnt).proc_code = gn_proc_s_del)
         OR (it_site_report_tbl(ln_log_cnt).proc_code = gn_proc_c_del)
         OR (it_site_report_tbl(ln_log_cnt).proc_code = gn_proc_ds_del)
         OR (it_site_report_tbl(ln_log_cnt).proc_code = gn_proc_dc_del)) THEN
          -- SEQ番号が同じ
          IF (it_site_report_tbl(ln_log_cnt).seq_number =
              it_site_del(ln_exec_cnt).seq_number) THEN
--
            -- 配送先反映処理(削除)
            proc_site(it_site_report_tbl(ln_log_cnt),
                      it_site_del(ln_exec_cnt),
                      lv_errbuf,
                      lv_retcode,
                      lv_errmsg);
--
            IF (lv_retcode <> gv_status_normal) THEN
              RAISE global_api_expt;
            END IF;
            EXIT log_loop;
          END IF;
        END IF;
      END LOOP log_loop;
    END LOOP delete_proc_loop;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
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
  END proc_site_main;
--
  /***********************************************************************************
   * Procedure Name   : init_proc
   * Description      : 初期処理を行います。
   ***********************************************************************************/
  PROCEDURE init_proc(
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
    -- テーブルロック処理
    -- ===============================
    set_if_lock(lv_errbuf,         -- エラー・メッセージ           --# 固定 #
                lv_retcode,        -- リターン・コード             --# 固定 #
                lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
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
   * Procedure Name   : term_proc
   * Description      : 終了処理を行います。(A-17)
   ***********************************************************************************/
  PROCEDURE term_proc(
    it_party_report_tbl IN            report_tbl,   -- 出力用テーブル(拠点)
    it_cust_report_tbl  IN            report_tbl,   -- 出力用テーブル(顧客)
    it_site_report_tbl  IN            report_tbl,   -- 出力用テーブル(配送先)
    ov_errbuf              OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode             OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg              OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'term_proc'; -- プログラム名
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
    -- ログ出力
    disp_report(it_party_report_tbl,
                it_cust_report_tbl,
                it_site_report_tbl,
                lv_errbuf,
                lv_retcode,
                lv_errmsg);
--
    IF (lv_retcode <> gv_status_normal) THEN
      RAISE global_api_expt;
    END IF;
--
    -- カーソルが開いていれば
    IF (gc_hca_party_cur%ISOPEN) THEN
      -- カーソルのクローズ
      CLOSE gc_hca_party_cur;
    END IF;
    -- カーソルが開いていれば
    IF (gc_hca_site_cur%ISOPEN) THEN
      -- カーソルのクローズ
      CLOSE gc_hca_site_cur;
    END IF;
    -- カーソルが開いていれば
    IF (gc_hp_party_cur%ISOPEN) THEN
      -- カーソルのクローズ
      CLOSE gc_hp_party_cur;
    END IF;
    -- カーソルが開いていれば
    IF (gc_hp_site_cur%ISOPEN) THEN
      -- カーソルのクローズ
      CLOSE gc_hp_site_cur;
    END IF;
    -- カーソルが開いていれば
    IF (gc_xp_party_cur%ISOPEN) THEN
      -- カーソルのクローズ
      CLOSE gc_xp_party_cur;
    END IF;
    -- カーソルが開いていれば
    IF (gc_xp_site_cur%ISOPEN) THEN
      -- カーソルのクローズ
      CLOSE gc_xp_site_cur;
    END IF;
    -- カーソルが開いていれば
    IF (gc_hps_site_cur%ISOPEN) THEN
      -- カーソルのクローズ
      CLOSE gc_hps_site_cur;
    END IF;
    -- カーソルが開いていれば
    IF (gc_xps_site_cur%ISOPEN) THEN
      -- カーソルのクローズ
      CLOSE gc_xps_site_cur;
    END IF;
--
    -- データ削除(拠点インタフェース)
    lb_retcd := xxcmn_common_pkg.del_all_data(gv_msg_kbn, gv_party_if_name);
--
    -- 失敗
    IF (NOT lb_retcd) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,   gv_msg_80a_018,
                                            gv_tkn_table, gv_xxcmn_party_if_name);
      lv_errbuf := lv_errmsg ||gv_msg_part|| SQLERRM;
      RAISE global_api_expt;
    END IF;
--
    -- データ削除(配送先インタフェース)
    lb_retcd := xxcmn_common_pkg.del_all_data(gv_msg_kbn, gv_site_if_name);
--
    -- 失敗
    IF (NOT lb_retcd) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,   gv_msg_80a_018,
                                            gv_tkn_table, gv_xxcmn_site_if_name);
      lv_errbuf := lv_errmsg ||gv_msg_part|| SQLERRM;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
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
  END term_proc;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
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
    lr_masters_rec      masters_rec;        -- 処理対象データ格納レコード
--
    -- ===============================
    -- 拠点用
    -- ===============================
    lt_party_ins        masters_tbl;        -- 各マスタへ登録するデータ
    lt_party_upd        masters_tbl;        -- 各マスタへ更新するデータ
    lt_party_del        masters_tbl;        -- 各マスタへ削除するデータ
    lt_party_report_tbl report_tbl;         -- レポート出力結合配列
    ln_party_ins_cnt    NUMBER;             -- 登録件数(拠点)
    ln_party_upd_cnt    NUMBER;             -- 更新件数(拠点)
    ln_party_del_cnt    NUMBER;             -- 削除件数(拠点)
    lr_party_sts_rec    status_rec;         -- 処理状況格納レコード(拠点用)
    -- ===============================
    -- 顧客用
    -- ===============================
    lt_cust_ins         masters_tbl;        -- 各マスタへ登録するデータ
    lt_cust_upd         masters_tbl;        -- 各マスタへ更新するデータ
    lt_cust_report_tbl  report_tbl;         -- レポート出力結合配列
    ln_cust_ins_cnt     NUMBER;             -- 登録件数(顧客)
    ln_cust_upd_cnt     NUMBER;             -- 更新件数(顧客)
    lr_cust_sts_rec     status_rec;         -- 処理状況格納レコード(顧客用)
    -- ===============================
    -- 配送先用
    -- ===============================
    lt_site_ins         masters_tbl;        -- 各マスタへ登録するデータ
    lt_site_upd         masters_tbl;        -- 各マスタへ更新するデータ
    lt_site_del         masters_tbl;        -- 各マスタへ削除するデータ
    lt_site_report_tbl  report_tbl;         -- レポート出力結合配列
    ln_site_ins_cnt     NUMBER;             -- 登録件数(配送先)
    ln_site_upd_cnt     NUMBER;             -- 更新件数(配送先)
    ln_site_del_cnt     NUMBER;             -- 削除件数(配送先)
    lr_site_sts_rec     status_rec;         -- 処理状況格納レコード(配送先用)
--
    lb_retcd        BOOLEAN;         -- 検索結果
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- 拠点インタフェース
    CURSOR party_if_cur
    IS
      SELECT xpi.seq_number,                           --SEQ番号
             xpi.proc_code,                            --更新区分
             xpi.base_code,                            --拠点コード
             xpi.party_name,                           --拠点名・正式名
             xpi.party_short_name,                     --拠点名・略名
             xpi.party_name_alt,                       --拠点名・カナ
             xpi.address,                              --住所
             xpi.zip,                                  --郵便番号
             xpi.phone,                                --電話番号
             xpi.fax,                                  --FAX番号
             xpi.old_division_code,                    --旧・本部コード
             xpi.new_division_code,                    --新・本部コード
             xpi.division_start_date,                  --適用開始日(本部コード)
             xpi.location_rel_code,                    --拠点実績有無区分
             xpi.ship_mng_code,                        --出庫管理元区分
             xpi.district_code,                        --地区名(本部コード用)
             xpi.warehouse_code,                       --倉替対象可否区分
             xpi.terminal_code,                        --端末有無区分
             xpi.zip2,                                 --郵便番号2
             xpi.spare                                 --予備
      FROM   xxcmn_party_if xpi
      ORDER BY seq_number;
--
    lr_party_if_rec party_if_cur%ROWTYPE;
--
    -- 配送先インタフェース
    CURSOR site_if_cur
    IS
      SELECT xsi.seq_number,                           --SEQ番号
             xsi.proc_code,                            --更新区分
             xsi.ship_to_code,                         --配送先コード
             xsi.base_code,                            --拠点コード
             xsi.party_site_name1,                     --配送先名称1
             xsi.party_site_name2,                     --配送先名称2
             xsi.party_site_addr1,                     --配送先住所1
             xsi.party_site_addr2,                     --配送先住所2
             xsi.phone,                                --電話番号
             xsi.fax,                                  --FAX番号
             xsi.zip,                                  --郵便番号
             xsi.party_num,                            --顧客コード
             xsi.zip2,                                 --郵便番号2
             xsi.customer_name1,                       --顧客・漢字1
             xsi.customer_name2,                       --顧客・漢字2
             xsi.sale_base_code,                       --当月売上拠点コード
             xsi.res_sale_base_code,                   --予約(翌月)売上拠点コード
             xsi.chain_store,                          --売上チェーン店
             xsi.chain_store_name,                     --売上チェーン店名
             xsi.cal_cust_app_flg,                     --中止客申請フラグ
             xsi.direct_ship_code,                     --直送区分
             xsi.shift_judg_flg                        --移行判定フラグ
      FROM   xxcmn_site_if xsi
      ORDER BY seq_number;
--
    lr_site_if_rec site_if_cur%ROWTYPE;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- グローバル変数の初期化
    gn_target_cnt   := 0;
    gn_normal_cnt   := 0;
    gn_error_cnt    := 0;
    gn_warn_cnt     := 0;
--
    gn_p_target_cnt := 0;
    gn_p_normal_cnt := 0;
    gn_p_error_cnt  := 0;
    gn_p_warn_cnt   := 0;
    gn_p_report_cnt := 0;
--
    gn_s_target_cnt := 0;
    gn_s_normal_cnt := 0;
    gn_s_error_cnt  := 0;
    gn_s_warn_cnt   := 0;
    gn_s_report_cnt := 0;
--
    gn_c_target_cnt := 0;
    gn_c_normal_cnt := 0;
    gn_c_error_cnt  := 0;
    gn_c_warn_cnt   := 0;
    gn_c_report_cnt := 0;
--
    ln_party_ins_cnt := 0;
    ln_party_upd_cnt := 0;
    ln_party_del_cnt := 0;
    ln_site_ins_cnt  := 0;
    ln_site_upd_cnt  := 0;
    ln_site_del_cnt  := 0;
    ln_cust_ins_cnt  := 0;
    ln_cust_upd_cnt  := 0;
--
    gn_created_by              := FND_GLOBAL.USER_ID;
    gd_creation_date           := SYSDATE;
    gn_last_updated_by         := FND_GLOBAL.USER_ID;
    gd_last_update_date        := SYSDATE;
    gn_last_update_login       := FND_GLOBAL.LOGIN_ID;
    gn_request_id              := FND_GLOBAL.CONC_REQUEST_ID;
--    gn_program_application_id  := FND_GLOBAL.QUEUE_APPL_ID;
    gn_program_application_id  := FND_GLOBAL.PROG_APPL_ID;
    gn_program_id              := FND_GLOBAL.CONC_PROGRAM_ID;
    gd_program_update_date     := SYSDATE;
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- ===============================
    -- 初期処理
    -- プロファイルの取得、テーブルロック
    -- ===============================
    init_proc(lv_errbuf,
              lv_retcode,
              lv_errmsg);
--
    IF (lv_retcode <> gv_status_normal) THEN
      RAISE check_sub_main_expt;
    END IF;
--
    -- ファイルレベルのステータスを初期化(拠点)
    init_status(lr_party_sts_rec,
                lv_errbuf,
                lv_retcode,
                lv_errmsg);
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE check_sub_main_expt;
    END IF;
--
    -- ===============================
    -- 拠点インタフェース取得処理(A-1)
    -- ===============================
    OPEN party_if_cur;
--
    <<party_if_loop>>
    LOOP
      FETCH party_if_cur INTO lr_party_if_rec;
      EXIT WHEN party_if_cur%NOTFOUND;
--
      gn_p_target_cnt := gn_p_target_cnt + 1; -- 処理件数カウントアップ(拠点)
--
      -- 行レベルのステータスを初期化
      init_row_status(lr_party_sts_rec,
                      lv_errbuf,
                      lv_retcode,
                      lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE check_sub_main_expt;
      END IF;
--
      -- 取得した値をレコードにコピー
      lr_masters_rec.tbl_kbn             := gn_kbn_party;
      lr_masters_rec.seq_number          := lr_party_if_rec.seq_number;
      lr_masters_rec.proc_code           := lr_party_if_rec.proc_code;
      lr_masters_rec.base_code           := lr_party_if_rec.base_code;
      lr_masters_rec.party_name          := lr_party_if_rec.party_name;
      lr_masters_rec.party_short_name    := lr_party_if_rec.party_short_name;
      lr_masters_rec.party_name_alt      := lr_party_if_rec.party_name_alt;
      lr_masters_rec.address             := lr_party_if_rec.address;
      lr_masters_rec.zip                 := lr_party_if_rec.zip;
      lr_masters_rec.phone               := lr_party_if_rec.phone;
      lr_masters_rec.fax                 := lr_party_if_rec.fax;
      lr_masters_rec.old_division_code   := lr_party_if_rec.old_division_code;
      lr_masters_rec.new_division_code   := lr_party_if_rec.new_division_code;
      lr_masters_rec.division_start_date := lr_party_if_rec.division_start_date;
      lr_masters_rec.location_rel_code   := lr_party_if_rec.location_rel_code;
      lr_masters_rec.ship_mng_code       := lr_party_if_rec.ship_mng_code;
      lr_masters_rec.district_code       := lr_party_if_rec.district_code;
      lr_masters_rec.warehouse_code      := lr_party_if_rec.warehouse_code;
      lr_masters_rec.terminal_code       := lr_party_if_rec.terminal_code;
      lr_masters_rec.zip2                := lr_party_if_rec.zip2;
      lr_masters_rec.spare               := lr_party_if_rec.spare;
--
      -- 件数の初期化
      lr_masters_rec.row_o_ins_cnt       := 0;
      lr_masters_rec.row_o_upd_cnt       := 0;
      lr_masters_rec.row_o_del_cnt       := 0;
      lr_masters_rec.row_z_ins_cnt       := 0;
      lr_masters_rec.row_z_upd_cnt       := 0;
      lr_masters_rec.row_z_del_cnt       := 0;
--
      -- 更新区分チェック(登録・更新・削除)
      check_proc_code(lr_masters_rec.proc_code,
                      lr_party_sts_rec,
                      lv_errbuf,
                      lv_retcode,
                      lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE check_sub_main_expt;
      END IF;
--
      IF (is_row_status_nomal(lr_party_sts_rec)) THEN
--
        -- 以前の状況の取得
        get_xxcmn_party_if(lr_masters_rec,
                           lv_errbuf,
                           lv_retcode,
                           lv_errmsg);
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE check_sub_main_expt;
        END IF;
      END IF;
--
      IF (is_row_status_nomal(lr_party_sts_rec)) THEN
--
        -- 拠点コードチェック(A-2)
        check_base_code(lr_party_sts_rec,
                        lr_masters_rec,
                        lv_errbuf,
                        lv_retcode,
                        lv_errmsg);
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE check_sub_main_expt;
        END IF;
      END IF;
--
      IF (is_row_status_nomal(lr_party_sts_rec)) THEN
--
        -- 拠点登録情報格納(A-3)
        IF (lr_masters_rec.proc_code = gn_proc_insert) THEN
          lt_party_ins(ln_party_ins_cnt) := lr_masters_rec;
          ln_party_ins_cnt := ln_party_ins_cnt + 1;
--
        -- 拠点更新情報格納(A-4)
        ELSIF (lr_masters_rec.proc_code = gn_proc_update) THEN
          lt_party_upd(ln_party_upd_cnt) := lr_masters_rec;
          ln_party_upd_cnt := ln_party_upd_cnt + 1;
--
        -- 拠点削除情報格納(A-5)
        ELSIF (lr_masters_rec.proc_code = gn_proc_delete) THEN
          lt_party_del(ln_party_del_cnt) := lr_masters_rec;
          ln_party_del_cnt := ln_party_del_cnt + 1;
        END IF;
      END IF;
--
      -- 正常件数をカウントアップ
      IF (is_row_status_nomal(lr_party_sts_rec)) THEN
        gn_p_normal_cnt := gn_p_normal_cnt + 1;
--
      ELSE
--
        -- 警告件数をカウントアップ
        IF (is_row_status_warn(lr_party_sts_rec)) THEN
          gn_p_warn_cnt := gn_p_warn_cnt + 1;
--
        -- 異常件数をカウントアップ
        ELSE
          gn_p_error_cnt := gn_p_error_cnt +1;
        END IF;
      END IF;
--
      -- ログ出力用データの格納(拠点)
      add_p_report(lr_party_sts_rec,
                   lr_masters_rec,
                   lt_party_report_tbl,
                   lv_errbuf,
                   lv_retcode,
                   lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE check_sub_main_expt;
      END IF;
--
    END LOOP party_if_loop;
--
    CLOSE party_if_cur;
--
    -- ファイルレベルのステータスを初期化(配送先)
    init_status(lr_site_sts_rec,
                lv_errbuf,
                lv_retcode,
                lv_errmsg);
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE check_sub_main_expt;
    END IF;
--
    -- ファイルレベルのステータスを初期化(顧客)
    init_status(lr_cust_sts_rec,
                lv_errbuf,
                lv_retcode,
                lv_errmsg);
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE check_sub_main_expt;
    END IF;
--
    -- ===============================
    -- 配送先インタフェース取得処理(A-6)
    -- ===============================
    OPEN site_if_cur;
--
    <<site_if_loop>>
    LOOP
      FETCH site_if_cur INTO lr_site_if_rec;
      EXIT WHEN site_if_cur%NOTFOUND;
--
      gn_s_target_cnt := gn_s_target_cnt + 1; -- 処理件数カウントアップ(配送先)
      gn_c_target_cnt := gn_c_target_cnt + 1; -- 処理件数カウントアップ(顧客)
--
      -- 行レベルのステータスを初期化
      init_row_status(lr_cust_sts_rec,
                      lv_errbuf,
                      lv_retcode,
                      lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE check_sub_main_expt;
      END IF;
--
      -- 取得した値をレコードにコピー
      lr_masters_rec.tbl_kbn            := gn_kbn_site;
      lr_masters_rec.seq_number         := lr_site_if_rec.seq_number;
      lr_masters_rec.proc_code          := lr_site_if_rec.proc_code;
      lr_masters_rec.k_proc_code        := lr_site_if_rec.proc_code;
      lr_masters_rec.ship_to_code       := lr_site_if_rec.ship_to_code;
      lr_masters_rec.base_code          := lr_site_if_rec.base_code;
      lr_masters_rec.party_site_name1   := lr_site_if_rec.party_site_name1;
      lr_masters_rec.party_site_name2   := lr_site_if_rec.party_site_name2;
      lr_masters_rec.party_site_addr1   := lr_site_if_rec.party_site_addr1;
      lr_masters_rec.party_site_addr2   := lr_site_if_rec.party_site_addr2;
      lr_masters_rec.phone              := lr_site_if_rec.phone;
      lr_masters_rec.fax                := lr_site_if_rec.fax;
      lr_masters_rec.zip                := lr_site_if_rec.zip;
      lr_masters_rec.party_num          := lr_site_if_rec.party_num;
      lr_masters_rec.zip2               := lr_site_if_rec.zip2;
      lr_masters_rec.customer_name1     := lr_site_if_rec.customer_name1;
      lr_masters_rec.customer_name2     := lr_site_if_rec.customer_name2;
      lr_masters_rec.sale_base_code     := lr_site_if_rec.sale_base_code;
      lr_masters_rec.res_sale_base_code := lr_site_if_rec.res_sale_base_code;
      lr_masters_rec.chain_store        := lr_site_if_rec.chain_store;
      lr_masters_rec.chain_store_name   := lr_site_if_rec.chain_store_name;
      lr_masters_rec.cal_cust_app_flg   := lr_site_if_rec.cal_cust_app_flg;
      lr_masters_rec.direct_ship_code   := lr_site_if_rec.direct_ship_code;
      lr_masters_rec.shift_judg_flg     := lr_site_if_rec.shift_judg_flg;
--
      -- 件数の初期化
      lr_masters_rec.row_c_ins_cnt      := 0;
      lr_masters_rec.row_c_upd_cnt      := 0;
      lr_masters_rec.row_c_del_cnt      := 0;
      lr_masters_rec.row_s_ins_cnt      := 0;
      lr_masters_rec.row_s_upd_cnt      := 0;
      lr_masters_rec.row_s_del_cnt      := 0;
      lr_masters_rec.row_n_ins_cnt      := 0;
      lr_masters_rec.row_n_upd_cnt      := 0;
      lr_masters_rec.row_n_del_cnt      := 0;
      lr_masters_rec.row_m_ins_cnt      := 0;
      lr_masters_rec.row_m_upd_cnt      := 0;
      lr_masters_rec.row_m_del_cnt      := 0;
--
      -- 以前の状況の取得
      get_xxcmn_site_if(lr_masters_rec,
                        lv_errbuf,
                        lv_retcode,
                        lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE check_sub_main_expt;
      END IF;
--
-- 2008/10/01 v1.10 UPDATE START
/*
--2008/08/08 Add ↓
      -- 顧客コード入力あり
-- 2008/08/25 Mod ↓
/*
      IF (lr_masters_rec.party_num IS NOT NULL) THEN
*//*
      IF (lr_masters_rec.party_num <> gv_def_party_num) THEN
-- 2008/08/25 Mod ↑
--2008/08/08 Add ↑
*/
      -- 顧客コード入力ありで、削除レコードでない場合
      IF (
           (lr_masters_rec.party_num <> gv_def_party_num)
             AND (lr_masters_rec.proc_code <> gn_proc_delete)
         ) THEN
-- 2008/10/01 v1.10 UPDATE END
        -- ===============================
        -- 顧客データ処理開始
        -- ===============================
        IF (is_row_status_nomal(lr_cust_sts_rec)) THEN
--
          -- 顧客コードチェック(A-7)
          check_party_num(lr_cust_sts_rec,
                          lr_masters_rec,
                          lv_errbuf,
                          lv_retcode,
                          lv_errmsg);
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE check_sub_main_expt;
          END IF;
        END IF;
--
        IF (is_row_status_nomal(lr_cust_sts_rec)) THEN
--
          -- 更新区分チェック(登録・更新・削除)
          check_proc_code(lr_masters_rec.k_proc_code,
                          lr_cust_sts_rec,
                          lv_errbuf,
                          lv_retcode,
                          lv_errmsg);
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE check_sub_main_expt;
          END IF;
        END IF;
--
        IF (is_row_status_nomal(lr_cust_sts_rec)) THEN
--
          -- 顧客登録情報格納(A-8)
          IF (lr_masters_rec.proc_code = gn_proc_insert) THEN
            lt_cust_ins(ln_cust_ins_cnt) := lr_masters_rec;
            ln_cust_ins_cnt := ln_cust_ins_cnt + 1;
--
          -- 顧客更新情報格納(A-9)
          ELSIF (lr_masters_rec.proc_code = gn_proc_update) THEN
            lt_cust_upd(ln_cust_upd_cnt) := lr_masters_rec;
            ln_cust_upd_cnt := ln_cust_upd_cnt + 1;
          END IF;
        END IF;
--
        -- 正常件数をカウントアップ
        IF (is_row_status_nomal(lr_cust_sts_rec)) THEN
          gn_c_normal_cnt := gn_c_normal_cnt + 1;
--
        ELSE
          -- 警告件数をカウントアップ
          IF (is_row_status_warn(lr_cust_sts_rec)) THEN
            IF ((lr_masters_rec.k_proc_code = gn_proc_insert)
-- 2008/08/25 Mod ↓
/*
             AND (lr_masters_rec.party_num IS NOT NULL)) THEN
*/
             AND (lr_masters_rec.party_num <> gv_def_party_num)) THEN
-- 2008/08/25 Mod ↑
              lr_cust_sts_rec.file_level_status := gn_data_status_nomal;
              gn_c_normal_cnt := gn_c_normal_cnt + 1;
            ELSE
              gn_c_warn_cnt := gn_c_warn_cnt + 1;
            END IF;
--
          -- 異常件数をカウントアップ
          ELSE
            gn_c_error_cnt := gn_c_error_cnt +1;
          END IF;
        END IF;
--
        -- ログに設定しない
        IF ((is_row_status_warn(lr_cust_sts_rec))
        AND (lr_cust_sts_rec.row_err_message IS NULL)) THEN
          NULL;
        ELSE
          -- ログ出力用データの格納(顧客)
          add_c_report(lr_cust_sts_rec,
                       lr_masters_rec,
                       lt_cust_report_tbl,
                       lv_errbuf,
                       lv_retcode,
                       lv_errmsg);
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE check_sub_main_expt;
          END IF;
        END IF;
--2008/08/08 Add ↓
      END IF;
--2008/08/08 Add ↑
--
      -- ===============================
      -- 配送先データ処理開始
      -- ===============================
--
      -- 行レベルのステータスを初期化
      init_row_status(lr_site_sts_rec,
                      lv_errbuf,
                      lv_retcode,
                      lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE check_sub_main_expt;
      END IF;
--
--
      IF (is_row_status_nomal(lr_site_sts_rec)) THEN
--
        -- 配送先コードチェック(A-10)
        check_ship_to_code(lr_site_sts_rec,
                           lr_masters_rec,
                           lv_errbuf,
                           lv_retcode,
                           lv_errmsg);
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE check_sub_main_expt;
        END IF;
      END IF;
--
      IF (is_row_status_nomal(lr_site_sts_rec)) THEN
--
        -- 更新区分チェック(登録・更新・削除)
        check_proc_code(lr_masters_rec.k_proc_code,
                        lr_site_sts_rec,
                        lv_errbuf,
                        lv_retcode,
                        lv_errmsg);
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE check_sub_main_expt;
        END IF;
      END IF;
--
      IF (is_row_status_nomal(lr_site_sts_rec)) THEN
--
        -- 配送先登録情報格納(A-11)
        IF ((lr_masters_rec.proc_code = gn_proc_insert)
         OR (lr_masters_rec.proc_code = gn_proc_s_ins)
         OR (lr_masters_rec.proc_code = gn_proc_c_ins)) THEN
          lt_site_ins(ln_site_ins_cnt) := lr_masters_rec;
          ln_site_ins_cnt := ln_site_ins_cnt + 1;
        END IF;
--
        -- 配送先更新情報格納(A-12)
        IF ((lr_masters_rec.proc_code = gn_proc_update)
         OR (lr_masters_rec.proc_code = gn_proc_s_upd)
         OR (lr_masters_rec.proc_code = gn_proc_c_upd)) THEN
          lt_site_upd(ln_site_upd_cnt) := lr_masters_rec;
          ln_site_upd_cnt := ln_site_upd_cnt + 1;
        END IF;
--
        -- 配送先削除情報格納(A-13)
        IF ((lr_masters_rec.proc_code = gn_proc_delete)
         OR (lr_masters_rec.proc_code = gn_proc_s_del)
         OR (lr_masters_rec.proc_code = gn_proc_c_del)
         OR (lr_masters_rec.proc_code = gn_proc_ds_del)
         OR (lr_masters_rec.proc_code = gn_proc_dc_del)) THEN
          lt_site_del(ln_site_del_cnt) := lr_masters_rec;
          ln_site_del_cnt := ln_site_del_cnt + 1;
        END IF;
      END IF;
--
      -- 正常件数をカウントアップ
      IF (is_row_status_nomal(lr_site_sts_rec)) THEN
        gn_s_normal_cnt := gn_s_normal_cnt + 1;
--
      ELSE
        -- 警告件数をカウントアップ
        IF (is_row_status_warn(lr_site_sts_rec)) THEN
          gn_s_warn_cnt := gn_s_warn_cnt + 1;
--
        -- 異常件数をカウントアップ
        ELSE
          gn_s_error_cnt := gn_s_error_cnt +1;
        END IF;
      END IF;
--
      -- ログ出力用データの格納(配送先)
      add_s_report(lr_site_sts_rec,
                   lr_masters_rec,
                   lt_site_report_tbl,
                   lv_errbuf,
                   lv_retcode,
                   lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE check_sub_main_expt;
      END IF;
--
    END LOOP site_if_loop;
--
    CLOSE site_if_cur;
--
    -- ===============================
    -- エラーチェック
    -- ===============================
--
    -- データの反映(エラーなし)
/* 2008/08/08 Mod ↓
    IF ((is_file_status_nomal(lr_party_sts_rec))
    AND (is_file_status_nomal(lr_cust_sts_rec))
    AND (is_file_status_nomal(lr_site_sts_rec))) THEN
2008/08/08 Mod ↓ */
--
    IF (is_file_status_nomal(lr_party_sts_rec)) THEN
      -- ===============================
      -- 拠点反映処理(A-14)
      -- ===============================
      proc_party_main(lt_party_ins,
                      lt_party_upd,
                      lt_party_del,
                      lt_party_report_tbl,
                      ln_party_ins_cnt,
                      ln_party_upd_cnt,
                      ln_party_del_cnt,
                      lv_errbuf,
                      lv_retcode,
                      lv_errmsg);
--
      IF (lv_retcode <> gv_status_normal) THEN
        RAISE check_sub_main_expt;
      END IF;
    END IF;
--
    IF (is_file_status_nomal(lr_cust_sts_rec)) THEN
      -- ===============================
      -- 顧客反映処理(A-15)
      -- ===============================
      proc_cust_main(lt_cust_ins,
                     lt_cust_upd,
                     lt_cust_report_tbl,
                     ln_cust_ins_cnt,
                     ln_cust_upd_cnt,
                     lv_errbuf,
                     lv_retcode,
                     lv_errmsg);
--
      IF (lv_retcode <> gv_status_normal) THEN
        RAISE check_sub_main_expt;
      END IF;
    END IF;
--
    IF ((is_file_status_nomal(lr_site_sts_rec))
    AND (is_file_status_nomal(lr_cust_sts_rec))) THEN
      -- ===============================
      -- 配送先反映処理(A-16)
      -- ===============================
      proc_site_main(lt_site_ins,
                     lt_site_upd,
                     lt_site_del,
                     lt_site_report_tbl,
                     ln_site_ins_cnt,
                     ln_site_upd_cnt,
                     ln_site_del_cnt,
                     lv_errbuf,
                     lv_retcode,
                     lv_errmsg);
--
      IF (lv_retcode <> gv_status_normal) THEN
        RAISE check_sub_main_expt;
      END IF;
    END IF;
--
    -- ===============================
    -- 終了処理(A-17)
    -- ===============================
    term_proc(lt_party_report_tbl,
              lt_cust_report_tbl,
              lt_site_report_tbl,
              lv_errbuf,
              lv_retcode,
              lv_errmsg);
--
    IF (lv_retcode <> gv_status_normal) THEN
      RAISE check_sub_main_expt;
    END IF;
--
    gn_target_cnt := gn_p_target_cnt+gn_s_target_cnt;
    gn_target_cnt := gn_target_cnt+gn_c_target_cnt;
--
    gn_normal_cnt := gn_p_normal_cnt+gn_s_normal_cnt;
    gn_normal_cnt := gn_normal_cnt+gn_c_normal_cnt;
--
    gn_error_cnt  := gn_p_error_cnt+gn_s_error_cnt;
    gn_error_cnt  := gn_error_cnt+gn_c_error_cnt;
--
    gn_warn_cnt   := gn_p_warn_cnt+gn_s_warn_cnt;
    gn_warn_cnt   := gn_warn_cnt+gn_c_warn_cnt;
--
    -- 2008/07/07 Add ↓
    IF (gn_target_cnt = 0) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                             gv_msg_80a_022);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
      ov_retcode := gv_status_warn;
      gn_warn_cnt := gn_warn_cnt + 1;
    END IF;
    -- 2008/07/07 Add ↑
--
    -- エラー、ワーニングデータ有りの場合はワーニング終了する。
    IF ((gn_error_cnt + gn_warn_cnt) > 0) THEN
      ov_retcode := gv_status_warn;
    END IF;
--
  EXCEPTION
      -- *** 任意で例外処理を記述する ****
    WHEN check_sub_main_expt THEN
      ov_errmsg := lv_errmsg;                                                   --# 任意 #
      ov_errbuf := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# 任意 #
      -- カーソルが開いていれば
      IF (party_if_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE party_if_cur;
      END IF;
      -- カーソルが開いていれば
      IF (site_if_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE site_if_cur;
      END IF;
      -- カーソルが開いていれば
      IF (gc_hca_party_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE gc_hca_party_cur;
      END IF;
      -- カーソルが開いていれば
      IF (gc_hca_site_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE gc_hca_site_cur;
      END IF;
      -- カーソルが開いていれば
      IF (gc_hp_party_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE gc_hp_party_cur;
      END IF;
      -- カーソルが開いていれば
      IF (gc_hp_site_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE gc_hp_site_cur;
      END IF;
      -- カーソルが開いていれば
      IF (gc_xp_party_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE gc_xp_party_cur;
      END IF;
      -- カーソルが開いていれば
      IF (gc_xp_site_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE gc_xp_site_cur;
      END IF;
      -- カーソルが開いていれば
      IF (gc_hps_site_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE gc_hps_site_cur;
      END IF;
      -- カーソルが開いていれば
      IF (gc_xps_site_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE gc_xps_site_cur;
      END IF;
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
      -- カーソルが開いていれば
      IF (party_if_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE party_if_cur;
      END IF;
      -- カーソルが開いていれば
      IF (site_if_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE site_if_cur;
      END IF;
      -- カーソルが開いていれば
      IF (gc_hca_party_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE gc_hca_party_cur;
      END IF;
      -- カーソルが開いていれば
      IF (gc_hca_site_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE gc_hca_site_cur;
      END IF;
      -- カーソルが開いていれば
      IF (gc_hp_party_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE gc_hp_party_cur;
      END IF;
      -- カーソルが開いていれば
      IF (gc_hp_site_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE gc_hp_site_cur;
      END IF;
      -- カーソルが開いていれば
      IF (gc_xp_party_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE gc_xp_party_cur;
      END IF;
      -- カーソルが開いていれば
      IF (gc_xp_site_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE gc_xp_site_cur;
      END IF;
      -- カーソルが開いていれば
      IF (gc_hps_site_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE gc_hps_site_cur;
      END IF;
      -- カーソルが開いていれば
      IF (gc_xps_site_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE gc_xps_site_cur;
      END IF;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      -- カーソルが開いていれば
      IF (party_if_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE party_if_cur;
      END IF;
      -- カーソルが開いていれば
      IF (site_if_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE site_if_cur;
      END IF;
      -- カーソルが開いていれば
      IF (gc_hca_party_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE gc_hca_party_cur;
      END IF;
      -- カーソルが開いていれば
      IF (gc_hca_site_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE gc_hca_site_cur;
      END IF;
      -- カーソルが開いていれば
      IF (gc_hp_party_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE gc_hp_party_cur;
      END IF;
      -- カーソルが開いていれば
      IF (gc_hp_site_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE gc_hp_site_cur;
      END IF;
      -- カーソルが開いていれば
      IF (gc_xp_party_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE gc_xp_party_cur;
      END IF;
      -- カーソルが開いていれば
      IF (gc_xp_site_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE gc_xp_site_cur;
      END IF;
      -- カーソルが開いていれば
      IF (gc_hps_site_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE gc_hps_site_cur;
      END IF;
      -- カーソルが開いていれば
      IF (gc_xps_site_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE gc_xps_site_cur;
      END IF;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      -- カーソルが開いていれば
      IF (party_if_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE party_if_cur;
      END IF;
      -- カーソルが開いていれば
      IF (site_if_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE site_if_cur;
      END IF;
      -- カーソルが開いていれば
      IF (gc_hca_party_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE gc_hca_party_cur;
      END IF;
      -- カーソルが開いていれば
      IF (gc_hca_site_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE gc_hca_site_cur;
      END IF;
      -- カーソルが開いていれば
      IF (gc_hp_party_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE gc_hp_party_cur;
      END IF;
      -- カーソルが開いていれば
      IF (gc_hp_site_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE gc_hp_site_cur;
      END IF;
      -- カーソルが開いていれば
      IF (gc_xp_party_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE gc_xp_party_cur;
      END IF;
      -- カーソルが開いていれば
      IF (gc_xp_site_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE gc_xp_site_cur;
      END IF;
      -- カーソルが開いていれば
      IF (gc_hps_site_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE gc_hps_site_cur;
      END IF;
      -- カーソルが開いていれば
      IF (gc_xps_site_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE gc_xps_site_cur;
      END IF;
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
    errbuf        OUT NOCOPY VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode       OUT NOCOPY VARCHAR2       --   リターン・コード    --# 固定 #
  )
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
--
    --実行コンカレント名取得
    SELECT fcp.concurrent_program_name
    INTO   gv_conc_name
    FROM   fnd_concurrent_programs fcp
    WHERE  fcp.application_id        = fnd_global.prog_appl_id
    AND    fcp.concurrent_program_id = FND_GLOBAL.CONC_PROGRAM_ID
    AND    ROWNUM                    = 1;
--
    -- ======================
    -- 固定出力
    -- ======================
    --実行ユーザ名出力
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn,  gv_msg_80a_001,
                                           gv_tkn_user, gv_exec_user);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --実行コンカレント名出力
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn,  gv_msg_80a_002,
                                           gv_tkn_conc, gv_conc_name);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --起動時間出力
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn,  gv_msg_80a_021,
                                           gv_tkn_time, TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS'));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_out_msg);
--
    --区切り文字取得
    gv_sep_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_80a_003);
--
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(lv_errbuf,   -- エラー・メッセージ           --# 固定 #
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
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_80a_020);
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
    --処理件数出力
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_80a_007, gv_tkn_cnt,
                                           TO_CHAR(gn_target_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --成功件数出力
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_80a_008, gv_tkn_cnt,
                                           TO_CHAR(gn_normal_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --エラー件数出力
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_80a_009, gv_tkn_cnt,
                                           TO_CHAR(gn_error_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --スキップ件数出力
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_80a_010, gv_tkn_cnt,
                                           TO_CHAR(gn_warn_cnt));
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
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn,    gv_msg_80a_011,
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
--###########################  固定部 END   #######################################################
--
END xxcmn800001c;
/
