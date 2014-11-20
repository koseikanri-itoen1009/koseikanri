CREATE OR REPLACE PACKAGE BODY XXCOK014A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOK014A01C(body)
 * Description      : 販売実績情報・手数料計算条件からの販売手数料計算処理
 * MD.050           : 条件別販手販協計算処理 MD050_COK_014_A01
 * Version          : 3.16
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  get_operating_day_f  稼働日取得                                   (A-16)
 *  get_tax_rate         消費税コード・税率取得                       (A-17)
 *  update_xcbi          販手計算済顧客情報データの更新               (A-15)
 *  update_xsel          販売実績連携結果の更新                       (A-12)
 *  insert_xbce          販手条件エラーテーブルへの登録               (A-11)
 *  insert_xcbs          条件別販手販協テーブルへの登録               (A-10)
 *  set_xcbs_data        条件別販手販協情報の設定                     (A-9)
 *  sales_result_loop1   販売実績の取得・売価別条件                   (A-8)
 *  sales_result_loop2   販売実績の取得・容器区分別条件               (A-8)
 *  sales_result_loop3   販売実績の取得・一律条件                     (A-8)
 *  sales_result_loop4   販売実績の取得・定額条件                     (A-8)
 *  sales_result_loop5   販売実績の取得・電気料（固定／変動）         (A-8)
 *  sales_result_loop6   販売実績の取得・入金値引率                   (A-8)
 *  delete_xbce          販手条件エラーの削除処理                     (A-7)
 *  delete_xcbs          条件別販手販協データの削除（未確定金額）     (A-3)
 *  insert_xt0c          条件別販手販協計算顧客情報一時表への登録     (A-6)
 *  get_cust_subdata     条件別販手販協計算日付情報の導出             (A-5)
 *  cust_loop            顧客情報ループ                               (A-4)
 *  purge_xcbi           販手計算済顧客情報データの削除（保持期間外） (A-14)
 *  purge_xcbs           条件別販手販協データの削除（保持期間外）     (A-2)
 *  init                 初期処理                                     (A-1)
 *  submain              メイン処理プロシージャ
 *  main                 コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/08    1.0   K.Ezaki          新規作成
 *  2009/02/13    1.1   K.Ezaki          障害COK_039 支払条件未設定顧客スキップ
 *  2009/02/17    1.2   K.Ezaki          障害COK_040 フルベンダーサイト固定修正
 *  2009/02/26    1.3   K.Ezaki          障害COK_060 一律条件計算結果累積
 *  2009/02/26    1.3   K.Ezaki          障害COK_061 一律条件定額計算
 *  2009/02/25    1.3   K.Ezaki          障害COK_062 定額条件割戻率・割戻額未設定
 *  2009/03/13    1.4   T.Taniguchi      障害T1_0036 販売実績情報カーソル定義の条件追加
 *  2009/03/25    1.5   S.Kayahara       最終行にスラッシュ追加
 *  2009/04/14    1.6   K.Yamaguchi      [障害T1_0523] 販売実績の売上金額（税込）取得方法不正対応
 *  2009/04/20    1.7   K.Yamaguchi      [障害T1_0688] 販手条件マスタの有効日を判定しないように修正
 *  2009/05/20    1.8   K.Yamaguchi      [障害T1_0686] メッセージ修正
 *  2009/06/01    2.0   K.Yamaguchi      [障害T1_0620][障害T1_0823][障害T1_1124][障害T1_1303]
 *                                       [障害T1_1400][障害T1_1402][障害T1_1422]
 *                                       修正困難により再作成
 *  2009/06/26    2.1   M.Hiruta         [障害0000269] パフォーマンスを向上させるためSQLを修正
 *  2009/07/08    2.2   M.Hiruta         [障害0000009] 条件別販手販協計算対象外の販売実績を除外するように修正
 *                                                     桁数超過を防ぐため、電気料（固定/変動）の割戻額を修正
 *  2009/07/16    2.3   K.Yamaguchi      [障害0000756] パフォーマンスを向上させるためSQLを修正
 *  2009/07/28    2.4   K.Yamaguchi      [障害0000879] パフォーマンスを向上させるためテーブルを追加
 *  2009/08/06    3.0   K.Yamaguchi      [障害0000940] パフォーマンスを向上させるためSQLを修正・修正履歴の削除
 *  2009/10/02    3.1   K.Yamaguchi      [仕様変更I_E_566] 納品VD・消化VDを処理対象に追加
 *  2009/10/19    3.2   K.Yamaguchi      [障害E_T3_00631] 消費税コード取得方法を変更
 *  2009/10/27    3.3   K.Yamaguchi      [障害E_T4_00094] 即時払いの場合にAR連携を行うように修正
 *  2009/11/09    3.4   K.Yamaguchi      [仕様変更I_E_633] 入金値引の対象となる非在庫品目を取得できるように変更
 *  2009/12/10    3.5   K.Yamaguchi      [E_本稼動_00363] 支払日で営業日が考慮されていない点を修正
 *  2009/12/21    3.6   K.Yamaguchi      [E_本稼動_00460] 定額条件・電気料のみの場合に売上金額をセット
 *  2010/02/03    3.7   K.Yamaguchi      [E_本稼動_XXXXX] 顧客使用目的でステータス判定追加
 *  2010/02/19    3.8   S.Moriyama       [E_本稼動_01446] 担当営業員が取得できなかった場合警告とする
 *  2010/03/16    3.9   K.Yamaguchi      [E_本稼動_01896] 計算対象顧客の判別を、販売実績の存在有無から顧客ステータスに変更
 *                                       [E_本稼動_01870] 売上拠点・担当営業員を締め日単位で固定化
 *  2010/04/06    3.10  K.Yamaguchi      [E_本稼動_01896] [E_本稼動_01870] 差し戻し対応
 *                                                        クイックコード取得時の有効日参照方法不正
 *  2010/05/26    3.11  K.Yamaguchi      [E_本稼動_02855] パフォーマンス対応 販売実績の更新方法を変更
 *  2010/12/13    3.12  S.Niki           [E_本稼動_01844] 販売実績の抽出条件に登録業務日付を追加
 *                                       [E_本稼動_01896] 計算対象顧客の判別を、販売実績の存在有無に差し戻し
 *  2011/04/01    3.13  M.Watanabe       [E_本稼動_06757] 販売実績にて変動電気代のみの場合でも電気料の計算対象とする
 *  2012/02/23    3.14  S.Niki           [E_本稼動_09144] 売上金額（税込）に変動電気代を加算しないよう修正
 *  2012/09/14    3.15  S.Niki           [E_本稼動_08751] パフォーマンス改善対応
 *  2012/10/01    3.16  K.Kiriu          [E_本稼動_10133] パフォーマンス改善対応(ヒント句固定化)
 *****************************************************************************************/
  --==================================================
  -- グローバル定数
  --==================================================
  -- パッケージ名
  cv_pkg_name                      CONSTANT VARCHAR2(20)    := 'XXCOK014A01C';
  -- アプリケーション短縮名
  cv_appl_short_name_cok           CONSTANT VARCHAR2(10)    := 'XXCOK';
  cv_appl_short_name_ccp           CONSTANT VARCHAR2(10)    := 'XXCCP';
  cv_appl_short_name_gl            CONSTANT VARCHAR2(10)    := 'SQLGL';
  cv_appl_short_name_ar            CONSTANT VARCHAR2(10)    := 'AR';
  -- ステータス・コード
  cv_status_normal                 CONSTANT VARCHAR2(1)     := xxccp_common_pkg.set_status_normal;  -- 正常:0
  cv_status_warn                   CONSTANT VARCHAR2(1)     := xxccp_common_pkg.set_status_warn;    -- 警告:1
  cv_status_error                  CONSTANT VARCHAR2(1)     := xxccp_common_pkg.set_status_error;   -- 異常:2
  -- WHOカラム
  cn_created_by                    CONSTANT NUMBER          := fnd_global.user_id;          -- CREATED_BY
  cn_last_updated_by               CONSTANT NUMBER          := fnd_global.user_id;          -- LAST_UPDATED_BY
  cn_last_update_login             CONSTANT NUMBER          := fnd_global.login_id;         -- LAST_UPDATE_LOGIN
  cn_request_id                    CONSTANT NUMBER          := fnd_global.conc_request_id;  -- REQUEST_ID
  cn_program_application_id        CONSTANT NUMBER          := fnd_global.prog_appl_id;     -- PROGRAM_APPLICATION_ID
  cn_program_id                    CONSTANT NUMBER          := fnd_global.conc_program_id;  -- PROGRAM_ID
  -- 言語
  cv_lang                          CONSTANT VARCHAR2(50)    := USERENV( 'LANG' );
  -- メッセージコード
  cv_msg_ccp_90000                 CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90000';        -- 対象件数
  cv_msg_ccp_90001                 CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90001';        -- 成功件数
  cv_msg_ccp_90002                 CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90002';        -- エラー件数
  cv_msg_ccp_90003                 CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90003';        -- エラー件数
  cv_msg_ccp_90004                 CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90004';        -- 正常終了
  cv_msg_ccp_90005                 CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90005';        -- 警告終了
  cv_msg_ccp_90006                 CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90006';        -- エラー終了全ロールバック
  cv_msg_cok_00003                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-00003';
  cv_msg_cok_00022                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-00022';
  cv_msg_cok_00028                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-00028';
-- 2010/02/19 Ver.3.8 [障害E_本稼動_01446] SCS S.Moriyama ADD START
  cv_msg_cok_00105                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-00105';
-- 2010/02/19 Ver.3.8 [障害E_本稼動_01446] SCS S.Moriyama ADD END
  cv_msg_cok_00044                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-00044';
  cv_msg_cok_00051                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-00051';
  cv_msg_cok_00080                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-00080';
  cv_msg_cok_00081                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-00081';
  cv_msg_cok_00086                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-00086';
-- 2009/10/19 Ver.3.2 [障害E_T3_00631] SCS K.Yamaguchi ADD START
  cv_msg_cok_00104                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-00104';
-- 2009/10/19 Ver.3.2 [障害E_T3_00631] SCS K.Yamaguchi ADD END
  cv_msg_cok_10398                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10398';
  cv_msg_cok_10401                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10401';
  cv_msg_cok_10402                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10402';
  cv_msg_cok_10404                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10404';
  cv_msg_cok_10405                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10405';
  cv_msg_cok_10426                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10426';
  cv_msg_cok_10427                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10427';
  cv_msg_cok_10454                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10454';
  cv_msg_cok_10455                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10455';
  cv_msg_cok_10456                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10456';
  cv_msg_cok_00103                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-00103';
  cv_msg_cok_10457                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10457';
-- 2012/06/19 Ver.3.15 [E_本稼動_08751] SCSK S.Niki ADD START
  cv_msg_cok_10494                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10494';
  cv_msg_cok_10495                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10495';
-- 2012/06/19 Ver.3.15 [E_本稼動_08751] SCSK S.Niki ADD END
  -- トークン
  cv_tkn_close_date                CONSTANT VARCHAR2(30)    := 'CLOSE_DATE';
  cv_tkn_container_type            CONSTANT VARCHAR2(30)    := 'CONTAINER_TYPE';
  cv_tkn_count                     CONSTANT VARCHAR2(30)    := 'COUNT';
  cv_tkn_cust_code                 CONSTANT VARCHAR2(30)    := 'CUST_CODE';
  cv_tkn_dept_code                 CONSTANT VARCHAR2(30)    := 'DEPT_CODE';
  cv_tkn_pay_date                  CONSTANT VARCHAR2(30)    := 'PAY_DATE';
  cv_tkn_proc_date                 CONSTANT VARCHAR2(30)    := 'PROC_DATE';
  cv_tkn_proc_type                 CONSTANT VARCHAR2(30)    := 'PROC_TYPE';
-- 2012/06/15 Ver.3.15 [E_本稼動_08751] SCSK S.Niki ADD START
  cv_tkn_proc_flag                 CONSTANT VARCHAR2(30)    := 'PROC_FLAG';  -- 起動フラグ
-- 2012/06/15 Ver.3.15 [E_本稼動_08751] SCSK S.Niki ADD END
  cv_tkn_profile                   CONSTANT VARCHAR2(30)    := 'PROFILE';
  cv_tkn_sales_amt                 CONSTANT VARCHAR2(30)    := 'SALES_AMT';
-- 2009/10/19 Ver.3.2 [障害E_T3_00631] SCS K.Yamaguchi ADD START
  cv_tkn_tax_div                   CONSTANT VARCHAR2(30)    := 'TAX_DIV';
-- 2009/10/19 Ver.3.2 [障害E_T3_00631] SCS K.Yamaguchi ADD END
  cv_tkn_vendor_code               CONSTANT VARCHAR2(30)    := 'VENDOR_CODE';
  cv_tkn_business_date             CONSTANT VARCHAR2(30)    := 'BUSINESS_DATE';
-- 2010/02/19 Ver.3.8 [障害E_本稼動_01446] SCS S.Moriyama ADD START
  cv_tkn_base_code                 CONSTANT VARCHAR2(30)    := 'BASE_CODE';
-- 2010/02/19 Ver.3.8 [障害E_本稼動_01446] SCS S.Moriyama ADD END
-- 2012/06/19 Ver.3.15 [E_本稼動_08751] SCSK S.Niki ADD START
  cv_tkn_data_name                 CONSTANT VARCHAR2(20)    := 'DATA_NAME';
  --
  cv_tkn_val_purge_xcbi_cnt        CONSTANT VARCHAR2(50)    := '販手計算済顧客情報データ削除件数  ： ';
  cv_tkn_val_purge_xcbs_cnt        CONSTANT VARCHAR2(50)    := '条件別販手販協データ削除件数  ： ';
  cv_tkn_val_insert_xt0c_cnt       CONSTANT VARCHAR2(50)    := '計算顧客情報一時表作成件数  ： ';
  cv_tkn_val_insert_xcbs_cnt       CONSTANT VARCHAR2(50)    := '販手販協計算処理件数  ： ';
  cv_tkn_val_update_xsel_cnt       CONSTANT VARCHAR2(50)    := '販売実績明細更新件数  ： ';
-- 2012/06/19 Ver.3.15 [E_本稼動_08751] SCSK S.Niki ADD END
  -- セパレータ
  cv_msg_part                      CONSTANT VARCHAR2(3)     := ' : ';
  cv_msg_cont                      CONSTANT VARCHAR2(3)     := '.';
  -- プロファイル・オプション名
  cv_profile_name_01               CONSTANT VARCHAR2(50)    := 'ORG_ID';                            -- MO: 営業単位
  cv_profile_name_02               CONSTANT VARCHAR2(50)    := 'GL_SET_OF_BKS_ID';                  -- 会計帳簿ID
  cv_profile_name_03               CONSTANT VARCHAR2(50)    := 'XXCOK1_BM_SUPPORT_PERIOD_FROM';     -- XXCOK:販手販協計算処理期間（From）
  cv_profile_name_04               CONSTANT VARCHAR2(50)    := 'XXCOK1_BM_SUPPORT_PERIOD_TO';       -- XXCOK:販手販協計算処理期間（To）
  cv_profile_name_05               CONSTANT VARCHAR2(50)    := 'XXCOK1_SALES_RETENTION_PERIOD';     -- XXCOK:販手販協情報保持期間
  cv_profile_name_06               CONSTANT VARCHAR2(50)    := 'XXCOK1_ELEC_CHANGE_ITEM_CODE';      -- 電気料（変動）品目コード
  cv_profile_name_07               CONSTANT VARCHAR2(50)    := 'XXCOK1_VENDOR_DUMMY_CODE';          -- 仕入先ダミーコード
  cv_profile_name_08               CONSTANT VARCHAR2(50)    := 'XXCOK1_INSTANTLY_TERM_NAME';        -- 支払条件_即時払い
  cv_profile_name_09               CONSTANT VARCHAR2(50)    := 'XXCOK1_DEFAULT_TERM_NAME';          -- 支払条件_デフォルト
  cv_profile_name_10               CONSTANT VARCHAR2(50)    := 'XXCOK1_ORG_CODE_SALES';             -- 在庫組織コード_営業組織
-- 2012/06/15 Ver.3.15 [E_本稼動_08751] SCSK S.Niki ADD START
  cv_profile_name_11               CONSTANT VARCHAR2(50)    := 'XXCOK1_XSEL_DATA_LOCK';             -- 販売実績明細データロック
-- 2012/06/15 Ver.3.15 [E_本稼動_08751] SCSK S.Niki ADD END
  -- 参照タイプ名
  cv_lookup_type_01                CONSTANT VARCHAR2(30)    := 'XXCOK1_BM_DISTRICT_PARA_MST';       -- 販手販協計算実行区分
-- 2009/10/19 Ver.3.2 [障害E_T3_00631] SCS K.Yamaguchi DELETE START
--  cv_lookup_type_02                CONSTANT VARCHAR2(30)    := 'XXCOK1_CONSUMPTION_TAX_CLASS';      -- 消費税区分
-- 2009/10/19 Ver.3.2 [障害E_T3_00631] SCS K.Yamaguchi DELETE END
  cv_lookup_type_03                CONSTANT VARCHAR2(30)    := 'XXCMM_CUST_GYOTAI_SHO';             -- 業態（小分類）
  cv_lookup_type_04                CONSTANT VARCHAR2(30)    := 'XXCMM_ITM_YOKIGUN';                 -- 容器群
  cv_lookup_type_05                CONSTANT VARCHAR2(30)    := 'XXCOS1_NO_INV_ITEM_CODE';           -- 非在庫品目
  cv_lookup_type_06                CONSTANT VARCHAR2(30)    := 'XXCMM_CUST_GYOTAI_CHU';             -- 業態（中分類）
  cv_lookup_type_07                CONSTANT VARCHAR2(30)    := 'XXCOK1_CALC_SALES_CLASS';           -- 販手計算対象売上区分
-- 2010/03/16 Ver.3.9 [E_本稼動_01896] SCS K.Yamaguchi ADD START
  cv_lookup_type_08                CONSTANT VARCHAR2(30)    := 'XXCOK1_BM_TARGET_CUST_STATUS';      -- 販手計算対象顧客ステータス
-- 2010/03/16 Ver.3.9 [E_本稼動_01896] SCS K.Yamaguchi ADD END
  -- 有効フラグ
  cv_enable                        CONSTANT VARCHAR2(1)     := 'Y';
-- 2009/11/09 Ver.3.4 [仕様変更I_E_633] SCS K.Yamaguchi ADD START
  cv_disable                       CONSTANT VARCHAR2(1)     := 'N';
-- 2009/11/09 Ver.3.4 [仕様変更I_E_633] SCS K.Yamaguchi ADD END
  -- 共通関数メッセージ出力区分
  cv_which_log                     CONSTANT VARCHAR2(10)    := 'LOG';
  -- 書式フォーマット
  cv_format_fxrrrrmmdd             CONSTANT VARCHAR2(50)    := 'FXRRRR/MM/DD';
  -- 条件別販手販協テーブル連携ステータス
  cv_xcbs_if_status_no             CONSTANT VARCHAR2(1)     := '0'; -- 未処理
  cv_xcbs_if_status_yes            CONSTANT VARCHAR2(1)     := '1'; -- 処理済
  cv_xcbs_if_status_off            CONSTANT VARCHAR2(1)     := '2'; -- 不要
  -- 顧客使用目的
  cv_site_use_code_ship            CONSTANT VARCHAR2(10)    := 'SHIP_TO'; -- 出荷先
  cv_site_use_code_bill            CONSTANT VARCHAR2(10)    := 'BILL_TO'; -- 請求先
  -- 支払月
  cv_month_type1                   CONSTANT VARCHAR2(2)     := '40'; -- 当月
  cv_month_type2                   CONSTANT VARCHAR2(2)     := '50'; -- 翌月
  -- サイト
  cv_site_type1                    CONSTANT VARCHAR2(2)     := '00'; -- 当月
  cv_site_type2                    CONSTANT VARCHAR2(2)     := '01'; -- 翌月
  -- 契約管理ステータス
  cv_xcm_status_result             CONSTANT VARCHAR2(1)     := '1'; -- 確定
  -- 条件別販手販協テーブル金額確定ステータス
  cv_xcbs_temp                     CONSTANT VARCHAR2(1)     := '0'; -- 未確定
  cv_xcbs_fix                      CONSTANT VARCHAR2(1)     := '1'; -- 確定
  -- 手数料計算インターフェース済フラグ
  cv_xsel_if_flag_yes              CONSTANT VARCHAR2(1)     := 'Y'; -- 処理済
  cv_xsel_if_flag_no               CONSTANT VARCHAR2(1)     := 'N'; -- 未処理
  -- 顧客区分
  cv_customer_class_customer       CONSTANT VARCHAR2(2)     := '10'; -- 顧客
  -- 業態（小分類）
  cv_gyotai_sho_24                 CONSTANT VARCHAR2(2)     := '24'; -- フルサービスVD（消化）
  cv_gyotai_sho_25                 CONSTANT VARCHAR2(2)     := '25'; -- フルサービスVD
-- 2009/10/02 Ver.3.1 [仕様変更I_E_566] SCS K.Yamaguchi ADD START
  cv_gyotai_sho_26                 CONSTANT VARCHAR2(2)     := '26'; -- 納品VD
  cv_gyotai_sho_27                 CONSTANT VARCHAR2(2)     := '27'; -- 消化VD
-- 2009/10/02 Ver.3.1 [仕様変更I_E_566] SCS K.Yamaguchi ADD END
  -- 業態（中分類）
  cv_gyotai_tyu_vd                 CONSTANT VARCHAR2(2)     := '11'; -- VD
  -- 営業日取得関数・処理区分
  cn_proc_type_before              CONSTANT NUMBER          := 1;  -- 前
  cn_proc_type_after               CONSTANT NUMBER          := 2;  -- 後
  -- 容器区分コード
  cv_container_code_others         CONSTANT VARCHAR2(4)     := '9999';   -- その他
  -- 計算条件
  cv_calc_type_sales_price         CONSTANT VARCHAR2(2)     := '10';  -- 売価別条件
  cv_calc_type_container           CONSTANT VARCHAR2(2)     := '20';  -- 容器区分別条件
  cv_calc_type_uniform_rate        CONSTANT VARCHAR2(2)     := '30';  -- 一律条件
  cv_calc_type_flat_rate           CONSTANT VARCHAR2(2)     := '40';  -- 定額
  cv_calc_type_electricity_cost    CONSTANT VARCHAR2(2)     := '50';  -- 電気料（固定／変動）
  -- 端数処理区分
  cv_tax_rounding_rule_nearest     CONSTANT VARCHAR2(10)    :=  'NEAREST'; -- 四捨五入
  cv_tax_rounding_rule_up          CONSTANT VARCHAR2(10)    :=  'UP';      -- 切り上げ
  cv_tax_rounding_rule_down        CONSTANT VARCHAR2(10)    :=  'DOWN';    -- 切り捨て
-- 2010/02/03 Ver.3.7 [E_本稼動_XXXXX] SCS K.Yamaguchi ADD START
  -- 顧客マスタ有効ステータス
  cv_cust_status_available         CONSTANT VARCHAR2(1)     := 'A';  -- 有効
-- 2010/02/03 Ver.3.7 [E_本稼動_XXXXX] SCS K.Yamaguchi ADD END
-- 2009/10/19 Ver.3.2 [障害E_T3_00631] SCS K.Yamaguchi ADD START
  -- 税コードダミー
  ct_tax_code_dummy                CONSTANT ar_vat_tax_b.tax_code%TYPE := NULL;
  ct_tax_rate_dummy                CONSTANT ar_vat_tax_b.tax_rate%TYPE := NULL;
-- 2009/10/19 Ver.3.2 [障害E_T3_00631] SCS K.Yamaguchi ADD END
-- 2012/06/15 Ver.3.15 [E_本稼動_08751] SCSK S.Niki ADD START
  -- 条件別販手販協計算処理起動フラグ
  cv_bm_proc_flag_1                CONSTANT VARCHAR2(1)     := '1';  -- データパージ処理
  cv_bm_proc_flag_2                CONSTANT VARCHAR2(1)     := '2';  -- 計算対象顧客一時表作成
  cv_bm_proc_flag_3                CONSTANT VARCHAR2(1)     := '3';  -- 販手販協計算処理
  cv_bm_proc_flag_4                CONSTANT VARCHAR2(1)     := '4';  -- 販売実績更新処理
  cv_bm_proc_flag_5                CONSTANT VARCHAR2(1)     := '5';  -- 計算対象顧客一時表削除
-- 2012/06/15 Ver.3.15 [E_本稼動_08751] SCSK S.Niki ADD END
  --==================================================
  -- グローバル変数
  --==================================================
  -- カウンタ
  gn_target_cnt                    NUMBER        DEFAULT 0;      -- 対象件数
  gn_normal_cnt                    NUMBER        DEFAULT 0;      -- 正常件数
  gn_error_cnt                     NUMBER        DEFAULT 0;      -- 異常件数
  gn_skip_cnt                      NUMBER        DEFAULT 0;      -- スキップ件数
  gn_contract_err_cnt              NUMBER        DEFAULT 0;      -- 販手条件エラー件数
-- 2012/06/19 Ver.3.15 [E_本稼動_08751] SCSK S.Niki ADD START
  gn_purge_xcbi_cnt                NUMBER        DEFAULT 0;      -- 販手計算済顧客情報データ削除件数
  gn_purge_xcbs_cnt                NUMBER        DEFAULT 0;      -- 条件別販手販協データ削除件数
  gn_insert_xt0c_cnt               NUMBER        DEFAULT 0;      -- 計算顧客情報一時表作成件数
  gn_insert_xcbs_cnt               NUMBER        DEFAULT 0;      -- 販手販協計算処理件数
  gn_update_xsel_cnt               NUMBER        DEFAULT 0;      -- 販売実績明細更新件数
-- 2012/06/19 Ver.3.15 [E_本稼動_08751] SCSK S.Niki ADD END
  -- 入力パラメータ
  gv_param_proc_date               VARCHAR2(10)  DEFAULT NULL;   -- 業務日付
  gv_param_proc_type               VARCHAR2(10)  DEFAULT NULL;   -- 処理区分
-- 2012/06/15 Ver.3.15 [E_本稼動_08751] SCSK S.Niki ADD START
  gv_param_proc_flag               VARCHAR2(10)  DEFAULT NULL;   -- 起動フラグ
-- 2012/06/15 Ver.3.15 [E_本稼動_08751] SCSK S.Niki ADD END
  -- 初期処理取得値
  gd_process_date                  DATE          DEFAULT NULL;   -- 業務処理日付
  gn_org_id                        NUMBER        DEFAULT NULL;   -- 営業単位ID
  gn_set_of_books_id               NUMBER        DEFAULT NULL;   -- 会計帳簿ID
  gn_bm_support_period_from        NUMBER        DEFAULT NULL;   -- XXCOK:販手販協計算処理期間（From）
  gn_bm_support_period_to          NUMBER        DEFAULT NULL;   -- XXCOK:販手販協計算処理期間（To）
  gn_sales_retention_period        NUMBER        DEFAULT NULL;   -- XXCOK:販手販協情報保持期間
  gv_elec_change_item_code         VARCHAR2(7)   DEFAULT NULL;   -- 電気料（変動）品目コード
  gv_vendor_dummy_code             VARCHAR2(9)   DEFAULT NULL;   -- 仕入先ダミーコード
  gv_instantly_term_name           VARCHAR2(8)   DEFAULT NULL;   -- 支払条件_即時払い
  gv_default_term_name             VARCHAR2(8)   DEFAULT NULL;   -- 支払条件_デフォルト
  gv_organization_code             VARCHAR2(10)  DEFAULT NULL;   -- 在庫組織コード_営業組織
  gt_calendar_code                 mtl_parameters.calendar_code%TYPE DEFAULT NULL; -- 在庫組織コード_営業組織-カレンダコード
-- 2012/06/19 Ver.3.15 [E_本稼動_08751] SCSK S.Niki ADD START
  gv_xsel_data_lock                VARCHAR2(1)   DEFAULT NULL;   -- 販手販協_販売実績明細ロック
-- 2012/06/19 Ver.3.15 [E_本稼動_08751] SCSK S.Niki ADD END
  --==================================================
  -- 共通例外
  --==================================================
  --*** 処理部共通例外 ***
  global_process_expt              EXCEPTION;
  --*** 共通関数例外 ***
  global_api_expt                  EXCEPTION;
  --*** 共通関数OTHERS例外 ***
  global_api_others_expt           EXCEPTION;
  PRAGMA EXCEPTION_INIT( global_api_others_expt, -20000 );
  --*** ロック取得エラー ***
  resource_busy_expt               EXCEPTION;
  PRAGMA EXCEPTION_INIT( resource_busy_expt, -54 );
  --==================================================
  -- グローバル例外
  --==================================================
  --*** エラー終了 ***
  error_proc_expt                  EXCEPTION;
  --*** 警告スキップ ***
  warning_skip_expt                EXCEPTION;
--
  --==================================================
  -- グローバルカーソル
  --==================================================
  -- 顧客情報
  CURSOR get_cust_data_cur IS
    SELECT /*+ ORDERED */
           ship_hca.account_number                     AS ship_cust_code             -- 【出荷先】顧客コード
         , gyotai_chu_flvv.lookup_code                 AS ship_gyotai_tyu            -- 【出荷先】業態（中分類）
         , ship_xca.business_low_type                  AS ship_gyotai_sho            -- 【出荷先】業態（小分類）
         , ship_xca.delivery_chain_code                AS ship_delivery_chain_code   -- 【出荷先】納品先チェーンコード
         , bill_hca.account_number                     AS bill_cust_code             -- 【請求先】顧客コード
         , ( CASE
               WHEN ship_xca.business_low_type = cv_gyotai_sho_25 THEN
                 ( SELECT ( CASE
                              WHEN (   (xcm.close_day_code       IS NULL)
                                    OR (xcm.transfer_day_code    IS NULL)
                                    OR (xcm.transfer_month_code  IS NULL)
                                   )
                              THEN
                                gv_default_term_name
                              ELSE
                                   xcm.close_day_code
                                || '_'
                                || xcm.transfer_day_code
                                || '_'
                                || ( CASE
                                       WHEN xcm.transfer_month_code = cv_month_type1 THEN
                                         cv_site_type1
                                       ELSE
                                         cv_site_type2
                                     END
                                   )
                            END
                          )
                   FROM xxcso_contract_managements  xcm
                   WHERE xcm.contract_management_id = ( SELECT MAX( xcm2.contract_management_id )
                                                        FROM xxcso_contract_managements  xcm2
                                                        WHERE xcm2.install_account_id = ship_hca.cust_account_id
                                                          AND xcm2.status             = cv_xcm_status_result
                                                      )
                 )
               ELSE
                 ( SELECT rtv.name
                   FROM ra_terms_vl  rtv
                   WHERE rtv.term_id = bill_hcsu.payment_term_id
                 )
             END
           )                                           AS term_name1                 -- 支払条件
         , ( CASE
               WHEN ship_xca.business_low_type = cv_gyotai_sho_25 THEN
                 NULL
               ELSE
                 ( SELECT rtv.name
                   FROM ra_terms_vl  rtv
                   WHERE rtv.term_id = TO_NUMBER( bill_hcsu.attribute2 )
                 )
             END
           )                                           AS term_name2                 -- 第2支払条件
         , ( CASE
               WHEN ship_xca.business_low_type = cv_gyotai_sho_25 THEN
                 NULL
               ELSE
                 ( SELECT rtv.name
                   FROM ra_terms_vl  rtv
                   WHERE rtv.term_id = TO_NUMBER( bill_hcsu.attribute3 )
                 )
             END
           )                                           AS term_name3                 -- 第3支払条件
         , (CASE
              WHEN ship_xca.business_low_type = cv_gyotai_sho_25 THEN
                gn_bm_support_period_to
              ELSE
                TO_NUMBER( bill_hcsu.attribute8 )
            END
           )                                           AS settle_amount_cycle        -- 金額確定サイクル
         , bill_xca.tax_div                            AS tax_div                    -- 消費税区分
-- 2009/10/19 Ver.3.2 [障害E_T3_00631] SCS K.Yamaguchi REPAIR START
--         , bill_avtb.tax_code                          AS tax_code                   -- 税金コード
--         , bill_avtb.tax_rate                          AS tax_rate                   -- 税率
         , ct_tax_code_dummy                           AS tax_code                   -- 税金コード（ダミー値NULL）
         , ct_tax_rate_dummy                           AS tax_rate                   -- 税率（ダミー値NULL）
-- 2009/10/19 Ver.3.2 [障害E_T3_00631] SCS K.Yamaguchi REPAIR END
         , bill_hcsu.tax_rounding_rule                 AS tax_rounding_rule          -- 端数処理区分
         , ( CASE
-- 2009/10/02 Ver.3.1 [仕様変更I_E_566] SCS K.Yamaguchi REPAIR START
--               WHEN gyotai_chu_flvv.lookup_code = cv_gyotai_tyu_vd THEN
               WHEN ship_xca.business_low_type IN ( cv_gyotai_sho_25, cv_gyotai_sho_24 ) THEN
-- 2009/10/02 Ver.3.1 [仕様変更I_E_566] SCS K.Yamaguchi REPAIR END
                 ship_xca.contractor_supplier_code
-- 2009/10/02 Ver.3.1 [仕様変更I_E_566] SCS K.Yamaguchi REPAIR START
--               WHEN (     ( gyotai_chu_flvv.lookup_code   <> cv_gyotai_tyu_vd )
--                      AND ( ship_xca.receiv_discount_rate IS NOT NULL         )
--                    )
               WHEN (     ( ship_xca.business_low_type    NOT IN ( cv_gyotai_sho_25, cv_gyotai_sho_24 ) )
                      AND ( ship_xca.receiv_discount_rate IS NOT NULL                                   )
                    )
-- 2009/10/02 Ver.3.1 [仕様変更I_E_566] SCS K.Yamaguchi REPAIR END
               THEN
                 gv_vendor_dummy_code
               ELSE
                 NULL
             END
           )                                           AS bm1_vendor_code            -- 【ＢＭ１】仕入先コード
         , ( CASE
               WHEN ship_xca.business_low_type = cv_gyotai_sho_25 THEN
                 ( SELECT pvs.vendor_site_code
                   FROM po_vendors       pv
                      , po_vendor_sites  pvs
                   WHERE pv.segment1        = ship_xca.contractor_supplier_code
                     AND pvs.vendor_id      = pv.vendor_id
                 )
               ELSE
                 NULL
             END
           )                                           AS bm1_vendor_site_code       -- 【ＢＭ１】仕入先サイトコード
         , ( CASE
               WHEN ship_xca.business_low_type = cv_gyotai_sho_25 THEN
                 ( SELECT  pvs.attribute4
                   FROM po_vendors       pv
                      , po_vendor_sites  pvs
                   WHERE pv.segment1        = ship_xca.contractor_supplier_code
                     AND pvs.vendor_id      = pv.vendor_id
                 )
               ELSE
                 NULL
             END
           )                                           AS bm1_bm_payment_type        -- 【ＢＭ１】BM支払区分
         , ( CASE
-- 2009/10/02 Ver.3.1 [仕様変更I_E_566] SCS K.Yamaguchi REPAIR START
--               WHEN gyotai_chu_flvv.lookup_code = cv_gyotai_tyu_vd THEN
               WHEN ship_xca.business_low_type IN ( cv_gyotai_sho_25, cv_gyotai_sho_24 ) THEN
-- 2009/10/02 Ver.3.1 [仕様変更I_E_566] SCS K.Yamaguchi REPAIR END
                 ship_xca.bm_pay_supplier_code1
               ELSE
                 NULL
             END
           )                                           AS bm2_vendor_code            -- 【ＢＭ２】仕入先コード
         , ( CASE
               WHEN ship_xca.business_low_type = cv_gyotai_sho_25 THEN
                 ( SELECT pvs.vendor_site_code
                   FROM po_vendors       pv
                      , po_vendor_sites  pvs
                   WHERE pv.segment1        = ship_xca.bm_pay_supplier_code1
                     AND pvs.vendor_id      = pv.vendor_id
                 )
               ELSE
                 NULL
             END
           )                                           AS bm2_vendor_site_code       -- 【ＢＭ２】仕入先サイトコード
         , ( CASE
               WHEN ship_xca.business_low_type = cv_gyotai_sho_25 THEN
                 ( SELECT pvs.attribute4
                   FROM po_vendors       pv
                      , po_vendor_sites  pvs
                   WHERE pv.segment1        = ship_xca.bm_pay_supplier_code1
                     AND pvs.vendor_id      = pv.vendor_id
                 )
               ELSE
                 NULL
             END
           )                                           AS bm2_bm_payment_type        -- 【ＢＭ２】BM支払区分
         , ( CASE
-- 2009/10/02 Ver.3.1 [仕様変更I_E_566] SCS K.Yamaguchi REPAIR START
--               WHEN gyotai_chu_flvv.lookup_code = cv_gyotai_tyu_vd THEN
               WHEN ship_xca.business_low_type IN ( cv_gyotai_sho_25, cv_gyotai_sho_24 ) THEN
-- 2009/10/02 Ver.3.1 [仕様変更I_E_566] SCS K.Yamaguchi REPAIR END
                 ship_xca.bm_pay_supplier_code2
               ELSE
                 NULL
             END
           )                                           AS bm3_vendor_code            -- 【ＢＭ３】仕入先コード
         , ( CASE
               WHEN ship_xca.business_low_type = cv_gyotai_sho_25 THEN
                 ( SELECT pvs.vendor_site_code
                   FROM po_vendors       pv
                      , po_vendor_sites  pvs
                   WHERE pv.segment1        = ship_xca.bm_pay_supplier_code2
                     AND pvs.vendor_id      = pv.vendor_id
                 )
               ELSE
                 NULL
             END
           )                                           AS bm3_vendor_site_code       -- 【ＢＭ３】仕入先サイトコード
         , ( CASE
               WHEN ship_xca.business_low_type = cv_gyotai_sho_25 THEN
                 ( SELECT pvs.attribute4
                   FROM po_vendors       pv
                      , po_vendor_sites  pvs
                   WHERE pv.segment1        = ship_xca.bm_pay_supplier_code2
                     AND pvs.vendor_id      = pv.vendor_id
                 )
               ELSE
                 NULL
             END
           )                                           AS bm3_bm_payment_type        -- 【ＢＭ３】BM支払区分
         , ship_xca.receiv_discount_rate               AS receiv_discount_rate       -- 入金値引率
         , ( CASE
               WHEN ship_xcbi.last_fix_closing_date IS NOT NULL THEN
                 ship_xcbi.last_fix_closing_date + 1
               ELSE
                 NULL
               END
           )                                           AS calc_target_period_from    -- 計算対象期間(FROM)
-- 2010/02/19 Ver.3.8 [障害E_本稼動_01446] SCS S.Moriyama ADD START
         , ship_xca.sale_base_code                     AS sale_base_code             -- 売上拠点コード
-- 2010/02/19 Ver.3.8 [障害E_本稼動_01446] SCS S.Moriyama ADD END
-- 2012/06/15 Ver.3.15 [E_本稼動_08751] SCSK S.Niki ADD START
         , proc_flvv.attribute1                        AS proc_type                  -- 実行区分
-- 2012/06/15 Ver.3.15 [E_本稼動_08751] SCSK S.Niki ADD END
    FROM fnd_lookup_values_vl      proc_flvv
       , hz_locations              ship_hl
       , hz_party_sites            ship_hps
       , hz_cust_acct_sites        ship_hcas
       , hz_cust_accounts          ship_hca
-- 2010/03/16 Ver.3.9 [E_本稼動_01896] SCS K.Yamaguchi ADD START
       , hz_parties                ship_hp
-- 2010/03/16 Ver.3.9 [E_本稼動_01896] SCS K.Yamaguchi ADD END
       , xxcmm_cust_accounts       ship_xca
       , hz_cust_site_uses         ship_hcsu
       , xxcok_cust_bm_info        ship_xcbi
       , hz_cust_site_uses         bill_hcsu
       , hz_cust_acct_sites        bill_hcas
       , hz_cust_accounts          bill_hca
       , xxcmm_cust_accounts       bill_xca
       , fnd_lookup_values_vl      gyotai_sho_flvv
       , fnd_lookup_values_vl      gyotai_chu_flvv
-- 2009/10/19 Ver.3.2 [障害E_T3_00631] SCS K.Yamaguchi DELETE START
--       , fnd_lookup_values_vl      tax_flvv
--       , ar_vat_tax_b              bill_avtb
-- 2009/10/19 Ver.3.2 [障害E_T3_00631] SCS K.Yamaguchi DELETE END
    WHERE proc_flvv.lookup_type        = cv_lookup_type_01
      AND proc_flvv.attribute1         = gv_param_proc_type
      AND proc_flvv.enabled_flag       = cv_enable
      AND gd_process_date        BETWEEN NVL( proc_flvv.start_date_active, gd_process_date )
                                     AND NVL( proc_flvv.end_date_active  , gd_process_date )
      AND ship_hl.address3          LIKE proc_flvv.lookup_code || '%'
      AND ship_hps.location_id         = ship_hl.location_id
      AND ship_hcas.party_site_id      = ship_hps.party_site_id
      AND ship_hca.cust_account_id     = ship_hcas.cust_account_id
-- 2010/03/16 Ver.3.9 [E_本稼動_01896] SCS K.Yamaguchi REPAIR START
--      AND EXISTS ( SELECT
--                          'X'
--                   FROM xxcos_sales_exp_headers  xseh
--                   WHERE xseh.ship_to_customer_code  = ship_hca.account_number
--                     AND ROWNUM = 1
--          )
      AND ship_hca.party_id            = ship_hp.party_id
      AND ship_hp.duns_number_c IN (
            SELECT flvv.lookup_code
            FROM fnd_lookup_values_vl  flvv
            WHERE flvv.lookup_type             = cv_lookup_type_08
              AND flvv.enabled_flag            = cv_enable
-- 2010/04/06 Ver.3.10 [E_本稼動_01896] [E_本稼動_01870] SCS K.Yamaguchi REPAIR START
--              AND flvv.start_date_active BETWEEN NVL( flvv.start_date_active, gd_process_date )
--                                             AND NVL( flvv.end_date_active  , gd_process_date )
              AND gd_process_date        BETWEEN NVL( flvv.start_date_active, gd_process_date )
                                             AND NVL( flvv.end_date_active  , gd_process_date )
-- 2010/04/06 Ver.3.10 [E_本稼動_01896] [E_本稼動_01870] SCS K.Yamaguchi REPAIR END
          )
-- 2010/03/16 Ver.3.9 [E_本稼動_01896] SCS K.Yamaguchi REPAIR END
      AND ship_xca.customer_id         = ship_hca.cust_account_id
      AND ship_hca.customer_class_code = cv_customer_class_customer
      AND ship_hca.account_number      = ship_xcbi.cust_code(+)
      AND ship_hcsu.cust_acct_site_id  = ship_hcas.cust_acct_site_id
      AND ship_hcsu.site_use_code      = cv_site_use_code_ship
      AND bill_hcsu.site_use_id        = ship_hcsu.bill_to_site_use_id
      AND bill_hcsu.site_use_code      = cv_site_use_code_bill
-- 2010/02/03 Ver.3.7 [E_本稼動_XXXXX] SCS K.Yamaguchi ADD START
      AND ship_hcsu.status             = cv_cust_status_available
      AND bill_hcsu.status             = cv_cust_status_available
-- 2010/02/03 Ver.3.7 [E_本稼動_XXXXX] SCS K.Yamaguchi ADD END
      AND bill_hcas.cust_acct_site_id  = bill_hcsu.cust_acct_site_id
      AND bill_hca.cust_account_id     = bill_hcas.cust_account_id
      AND bill_xca.customer_id         = bill_hca.cust_account_id
      AND gyotai_sho_flvv.lookup_type  = cv_lookup_type_03
      AND gyotai_sho_flvv.enabled_flag = cv_enable
      AND gd_process_date        BETWEEN NVL( gyotai_sho_flvv.start_date_active, gd_process_date )
                                     AND NVL( gyotai_sho_flvv.end_date_active  , gd_process_date )
      AND gyotai_sho_flvv.lookup_code  = ship_xca.business_low_type
      AND gyotai_chu_flvv.lookup_type  = cv_lookup_type_06
      AND gyotai_chu_flvv.enabled_flag = cv_enable
      AND gd_process_date        BETWEEN NVL( gyotai_chu_flvv.start_date_active, gd_process_date )
                                     AND NVL( gyotai_chu_flvv.end_date_active  , gd_process_date )
      AND gyotai_chu_flvv.lookup_code  = gyotai_sho_flvv.attribute1
-- 2009/10/02 Ver.3.1 [仕様変更I_E_566] SCS K.Yamaguchi REPAIR START
--      AND (    ( gyotai_sho_flvv.lookup_code IN( cv_gyotai_sho_24, cv_gyotai_sho_25 ) )
--            OR ( gyotai_chu_flvv.lookup_code <> cv_gyotai_tyu_vd                      )
--          )
      AND (    ( gyotai_sho_flvv.lookup_code IN(   cv_gyotai_sho_24
                                                 , cv_gyotai_sho_25
                                                 , cv_gyotai_sho_26
                                                 , cv_gyotai_sho_27
                                               )                     )
            OR ( gyotai_chu_flvv.lookup_code <> cv_gyotai_tyu_vd     )
          )
-- 2009/10/02 Ver.3.1 [仕様変更I_E_566] SCS K.Yamaguchi REPAIR END
-- 2009/10/19 Ver.3.2 [障害E_T3_00631] SCS K.Yamaguchi DELETE START
--      AND tax_flvv.lookup_type         = cv_lookup_type_02
--      AND tax_flvv.lookup_code         = bill_xca.tax_div
--      AND tax_flvv.enabled_flag        = cv_enable
--      AND gd_process_date        BETWEEN NVL( tax_flvv.start_date_active, gd_process_date )
--                                     AND NVL( tax_flvv.end_date_active  , gd_process_date )
--      AND bill_avtb.tax_code           = tax_flvv.attribute1
--      AND bill_avtb.validate_flag      = cv_enable
--      AND gd_process_date        BETWEEN NVL( bill_avtb.start_date, gd_process_date )
--                                     AND NVL( bill_avtb.end_date  , gd_process_date )
-- 2009/10/19 Ver.3.2 [障害E_T3_00631] SCS K.Yamaguchi DELETE END
  ;
  -- 販売実績情報・売価別条件
  CURSOR get_sales_data_cur1 IS
    SELECT xbc.sales_base_code                                     AS base_code                -- 拠点コード
         , xbc.results_employee_code                               AS emp_code                 -- 担当者コード
         , xbc.ship_to_customer_code                               AS ship_cust_code           -- 顧客【納品先】
         , xbc.ship_gyotai_sho                                     AS ship_gyotai_sho          -- 顧客【納品先】業態（小分類）
         , xbc.ship_gyotai_tyu                                     AS ship_gyotai_tyu          -- 顧客【納品先】業態（中分類）
         , xbc.bill_cust_code                                      AS bill_cust_code           -- 顧客【請求先】
         , xbc.period_year                                         AS period_year              -- 会計年度
         , xbc.ship_delivery_chain_code                            AS ship_delivery_chain_code -- チェーン店コード
         , xbc.delivery_ym                                         AS delivery_ym              -- 納品日年月
         , SUM( xbc.dlv_qty )                                      AS dlv_qty                  -- 納品数量
         , xbc.dlv_uom_code                                        AS dlv_uom_code             -- 納品単位
         , SUM( xbc.amount_inc_tax )                               AS amount_inc_tax           -- 売上金額（税込）
         , xbc.container_code                                      AS container_code           -- 容器区分コード
         , xbc.dlv_unit_price                                      AS dlv_unit_price           -- 売価金額
         , xbc.tax_div                                             AS tax_div                  -- 消費税区分
         , xbc.tax_code                                            AS tax_code                 -- 税金コード
         , xbc.tax_rate                                            AS tax_rate                 -- 消費税率
         , xbc.tax_rounding_rule                                   AS tax_rounding_rule        -- 端数処理区分
         , xbc.term_name                                           AS term_name                -- 支払条件
         , xbc.closing_date                                        AS closing_date             -- 締め日
         , xbc.expect_payment_date                                 AS expect_payment_date      -- 支払予定日
         , xbc.calc_target_period_from                             AS calc_target_period_from  -- 計算対象期間(FROM)
         , xbc.calc_target_period_to                               AS calc_target_period_to    -- 計算対象期間(TO)
         , xbc.calc_type                                           AS calc_type                -- 計算条件
         , xbc.bm1_vendor_code                                     AS bm1_vendor_code          -- 【ＢＭ１】仕入先コード
         , xbc.bm1_vendor_site_code                                AS bm1_vendor_site_code     -- 【ＢＭ１】仕入先サイトコード
         , xbc.bm1_bm_payment_type                                 AS bm1_bm_payment_type      -- 【ＢＭ１】BM支払区分
         , xbc.bm1_pct                                             AS bm1_pct                  -- 【ＢＭ１】BM率(%)
         , xbc.bm1_amt                                             AS bm1_amt                  -- 【ＢＭ１】BM金額
         , ROUND( SUM( xbc.amount_inc_tax ) * xbc.bm1_pct / 100 )  AS bm1_cond_bm_tax_pct      -- 【ＢＭ１】条件別手数料額(税込)_率
         , ROUND( SUM( xbc.dlv_qty ) * xbc.bm1_amt )               AS bm1_cond_bm_amt_tax      -- 【ＢＭ１】条件別手数料額(税込)_額
         , NULL                                                    AS bm1_electric_amt_tax     -- 【ＢＭ１】電気料(税込)
         , xbc.bm2_vendor_code                                     AS bm2_vendor_code          -- 【ＢＭ２】仕入先コード
         , xbc.bm2_vendor_site_code                                AS bm2_vendor_site_code     -- 【ＢＭ２】仕入先サイトコード
         , xbc.bm2_bm_payment_type                                 AS bm2_bm_payment_type      -- 【ＢＭ２】BM支払区分
         , xbc.bm2_pct                                             AS bm2_pct                  -- 【ＢＭ２】BM率(%)
         , xbc.bm2_amt                                             AS bm2_amt                  -- 【ＢＭ２】BM金額
         , ROUND( SUM( xbc.amount_inc_tax ) * xbc.bm2_pct / 100 )  AS bm2_cond_bm_tax_pct      -- 【ＢＭ２】条件別手数料額(税込)_率
         , ROUND( SUM( xbc.dlv_qty ) * xbc.bm2_amt )               AS bm2_cond_bm_amt_tax      -- 【ＢＭ２】条件別手数料額(税込)_額
         , NULL                                                    AS bm2_electric_amt_tax     -- 【ＢＭ２】電気料(税込)
         , xbc.bm3_vendor_code                                     AS bm3_vendor_code          -- 【ＢＭ３】仕入先コード
         , xbc.bm3_vendor_site_code                                AS bm3_vendor_site_code     -- 【ＢＭ３】仕入先サイトコード
         , xbc.bm3_bm_payment_type                                 AS bm3_bm_payment_type      -- 【ＢＭ３】BM支払区分
         , xbc.bm3_pct                                             AS bm3_pct                  -- 【ＢＭ３】BM率(%)
         , xbc.bm3_amt                                             AS bm3_amt                  -- 【ＢＭ３】BM金額
         , ROUND( SUM( xbc.amount_inc_tax ) * xbc.bm3_pct / 100 )  AS bm3_cond_bm_tax_pct      -- 【ＢＭ３】条件別手数料額(税込)_率
         , ROUND( SUM( xbc.dlv_qty ) * xbc.bm3_amt )               AS bm3_cond_bm_amt_tax      -- 【ＢＭ３】条件別手数料額(税込)_額
         , NULL                                                    AS bm3_electric_amt_tax     -- 【ＢＭ３】電気料(税込)
         , xbc.item_code                                           AS item_code                -- エラー品目コード
         , xbc.amount_fix_date                                     AS amount_fix_date          -- 金額確定日
    FROM ( SELECT xse.sales_base_code                                                              AS sales_base_code          -- 売上拠点コード
                , NVL2( xmbc.calc_type, xse.results_employee_code              , NULL )            AS results_employee_code    -- 成績計上者コード
                , xse.ship_to_customer_code                                                        AS ship_to_customer_code    -- 【出荷先】顧客コード
                , NVL2( xmbc.calc_type, xse.ship_gyotai_sho                    , NULL )            AS ship_gyotai_sho          -- 【出荷先】業態（小分類）
                , NVL2( xmbc.calc_type, xse.ship_gyotai_tyu                    , NULL )            AS ship_gyotai_tyu          -- 【出荷先】業態（中分類）
                , NVL2( xmbc.calc_type, xse.bill_cust_code                     , NULL )            AS bill_cust_code           -- 【請求先】顧客コード
                , NVL2( xmbc.calc_type, xse.period_year                        , NULL )            AS period_year              -- 会計年度
                , NVL2( xmbc.calc_type, xse.ship_delivery_chain_code           , NULL )            AS ship_delivery_chain_code -- 【出荷先】納品先チェーンコード
-- 2010/03/16 Ver.3.9 [E_本稼動_01896] SCS K.Yamaguchi REPAIR START
--                , NVL2( xmbc.calc_type, TO_CHAR( xse.delivery_date, 'RRRRMM' ) , NULL )            AS delivery_ym              -- 納品年月
                , NVL2( xmbc.calc_type, TO_CHAR( xse.closing_date, 'RRRRMM' )  , NULL )            AS delivery_ym              -- 納品年月
-- 2010/03/16 Ver.3.9 [E_本稼動_01896] SCS K.Yamaguchi REPAIR END
                , NVL2( xmbc.calc_type, xse.dlv_qty                            , NULL )            AS dlv_qty                  -- 納品数量
                , NVL2( xmbc.calc_type, xse.dlv_uom_code                       , NULL )            AS dlv_uom_code             -- 納品単位
                , xse.pure_amount + xse.tax_amount                                                 AS amount_inc_tax           -- 売上金額（税込）
                , NVL2( xmbc.calc_type, NULL, NVL( flv1.attribute1, cv_container_code_others ) )   AS container_code           -- 容器区分コード
                , xse.dlv_unit_price                                                               AS dlv_unit_price           -- 売価金額
                , NVL2( xmbc.calc_type, xse.tax_div                            , NULL )            AS tax_div                  -- 消費税区分
                , NVL2( xmbc.calc_type, xse.tax_code                           , NULL )            AS tax_code                 -- 税金コード
                , NVL2( xmbc.calc_type, xse.tax_rate                           , NULL )            AS tax_rate                 -- 消費税率
                , NVL2( xmbc.calc_type, xse.tax_rounding_rule                  , NULL )            AS tax_rounding_rule        -- 端数処理区分
                , NVL2( xmbc.calc_type, xse.term_name                          , NULL )            AS term_name                -- 支払条件
                , xse.closing_date                                                                 AS closing_date             -- 締め日
                , NVL2( xmbc.calc_type, xse.expect_payment_date                , NULL )            AS expect_payment_date      -- 支払予定日
                , NVL2( xmbc.calc_type, xse.calc_target_period_from            , NULL )            AS calc_target_period_from  -- 計算対象期間(FROM)
                , NVL2( xmbc.calc_type, xse.calc_target_period_to              , NULL )            AS calc_target_period_to    -- 計算対象期間(TO)
                , xmbc.calc_type                                                                   AS calc_type                -- 計算条件
                , NVL2( xmbc.calc_type, xse.bm1_vendor_code                    , NULL )            AS bm1_vendor_code          -- 【ＢＭ１】仕入先コード
                , NVL2( xmbc.calc_type, xse.bm1_vendor_site_code               , NULL )            AS bm1_vendor_site_code     -- 【ＢＭ１】仕入先サイトコード
                , NVL2( xmbc.calc_type, xse.bm1_bm_payment_type                , NULL )            AS bm1_bm_payment_type      -- 【ＢＭ１】BM支払区分
                , NVL2( xmbc.calc_type, xmbc.bm1_pct                           , NULL )            AS bm1_pct                  -- 【ＢＭ１】BM率(%)
                , NVL2( xmbc.calc_type, xmbc.bm1_amt                           , NULL )            AS bm1_amt                  -- 【ＢＭ１】BM金額
                , NVL2( xmbc.calc_type, xse.bm2_vendor_code                    , NULL )            AS bm2_vendor_code          -- 【ＢＭ２】仕入先コード
                , NVL2( xmbc.calc_type, xse.bm2_vendor_site_code               , NULL )            AS bm2_vendor_site_code     -- 【ＢＭ２】仕入先サイトコード
                , NVL2( xmbc.calc_type, xse.bm2_bm_payment_type                , NULL )            AS bm2_bm_payment_type      -- 【ＢＭ２】BM支払区分
                , NVL2( xmbc.calc_type, xmbc.bm2_pct                           , NULL )            AS bm2_pct                  -- 【ＢＭ２】BM率(%)
                , NVL2( xmbc.calc_type, xmbc.bm2_amt                           , NULL )            AS bm2_amt                  -- 【ＢＭ２】BM金額
                , NVL2( xmbc.calc_type, xse.bm3_vendor_code                    , NULL )            AS bm3_vendor_code          -- 【ＢＭ３】仕入先コード
                , NVL2( xmbc.calc_type, xse.bm3_vendor_site_code               , NULL )            AS bm3_vendor_site_code     -- 【ＢＭ３】仕入先サイトコード
                , NVL2( xmbc.calc_type, xse.bm3_bm_payment_type                , NULL )            AS bm3_bm_payment_type      -- 【ＢＭ３】BM支払区分
                , NVL2( xmbc.calc_type, xmbc.bm3_pct                           , NULL )            AS bm3_pct                  -- 【ＢＭ３】BM率(%)
                , NVL2( xmbc.calc_type, xmbc.bm3_amt                           , NULL )            AS bm3_amt                  -- 【ＢＭ３】BM金額
                , NVL2( xmbc.calc_type, NULL, xse.item_code )                                      AS item_code                -- エラー品目コード
                , xse.amount_fix_date                                                              AS amount_fix_date          -- 金額確定日
-- 2012/10/01 Ver.3.16 [E_本稼動_10133] SCSK K.Kiriu REPAIR START
--           FROM ( SELECT /*+ LEADING(xt0c xcbi xseh xsel xsim) USE_NL(xsel xsim) */
           FROM ( SELECT /*+
                           LEADING(xt0c xcbi hca xca)
                           USE_NL(xt0c xcbi xseh xsel xsim)
                           INDEX(xseh XXCOS_SALES_EXP_HEADERS_N08)
                         */
-- 2012/10/01 Ver.3.16 [E_本稼動_10133] SCSK K.Kiriu REPAIR END
-- 2010/03/16 Ver.3.9 [E_本稼動_01896] SCS K.Yamaguchi REPAIR START
--                         xseh.sales_base_code                   AS sales_base_code             -- 売上拠点コード
--                       , xseh.results_employee_code             AS results_employee_code       -- 成績計上者コード
                         CASE
                           WHEN TRUNC( xt0c.closing_date, 'MM' ) = TRUNC( gd_process_date, 'MM' ) THEN
                             xca.sale_base_code
                           ELSE
                             xca.past_sale_base_code
                         END                                    AS sales_base_code             -- 売上拠点コード
                       , xt0c.emp_code                          AS results_employee_code       -- 成績計上者コード
-- 2010/03/16 Ver.3.9 [E_本稼動_01896] SCS K.Yamaguchi REPAIR END
                       , xseh.ship_to_customer_code             AS ship_to_customer_code       -- 【出荷先】顧客コード
                       , xt0c.ship_gyotai_sho                   AS ship_gyotai_sho             -- 【出荷先】業態（小分類）
                       , xt0c.ship_gyotai_tyu                   AS ship_gyotai_tyu             -- 【出荷先】業態（中分類）
                       , xt0c.bill_cust_code                    AS bill_cust_code              -- 【請求先】顧客コード
                       , xt0c.period_year                       AS period_year                 -- 会計年度
                       , xt0c.ship_delivery_chain_code          AS ship_delivery_chain_code    -- 【出荷先】納品先チェーンコード
                       , xseh.delivery_date                     AS delivery_date               -- 納品日
                       , xsel.dlv_qty                           AS dlv_qty                     -- 納品数量
                       , xsel.dlv_uom_code                      AS dlv_uom_code                -- 納品単位
                       , xsel.pure_amount                       AS pure_amount                 -- 本体金額 
                       , xsel.tax_amount                        AS tax_amount                  -- 消費税金額
                       , xsel.dlv_unit_price                    AS dlv_unit_price              -- 売価金額
                       , xt0c.tax_div                           AS tax_div                     -- 消費税区分
                       , xt0c.tax_code                          AS tax_code                    -- 税金コード
                       , xt0c.tax_rate                          AS tax_rate                    -- 消費税率
                       , xt0c.tax_rounding_rule                 AS tax_rounding_rule           -- 端数処理区分
                       , xt0c.term_name                         AS term_name                   -- 支払条件
                       , xt0c.closing_date                      AS closing_date                -- 締め日
                       , xt0c.expect_payment_date               AS expect_payment_date         -- 支払予定日
                       , xt0c.calc_target_period_from           AS calc_target_period_from     -- 計算対象期間(FROM)
                       , xt0c.calc_target_period_to             AS calc_target_period_to       -- 計算対象期間(TO)
                       , xt0c.bm1_vendor_code                   AS bm1_vendor_code             -- 【ＢＭ１】仕入先コード
                       , xt0c.bm1_vendor_site_code              AS bm1_vendor_site_code        -- 【ＢＭ１】仕入先サイトコード
                       , xt0c.bm1_bm_payment_type               AS bm1_bm_payment_type         -- 【ＢＭ１】BM支払区分
                       , xt0c.bm2_vendor_code                   AS bm2_vendor_code             -- 【ＢＭ２】仕入先コード
                       , xt0c.bm2_vendor_site_code              AS bm2_vendor_site_code        -- 【ＢＭ２】仕入先サイトコード
                       , xt0c.bm2_bm_payment_type               AS bm2_bm_payment_type         -- 【ＢＭ２】BM支払区分
                       , xt0c.bm3_vendor_code                   AS bm3_vendor_code             -- 【ＢＭ３】仕入先コード
                       , xt0c.bm3_vendor_site_code              AS bm3_vendor_site_code        -- 【ＢＭ３】仕入先サイトコード
                       , xt0c.bm3_bm_payment_type               AS bm3_bm_payment_type         -- 【ＢＭ３】BM支払区分
                       , xsel.item_code                         AS item_code                   -- 在庫品目コード
                       , xt0c.amount_fix_date                   AS amount_fix_date             -- 金額確定日
                       , xsim.vessel_group                      AS vessel_group                -- 容器群コード
                  FROM xxcmm_system_items_b        xsim  -- Disc品目アドオン
                     , xxcos_sales_exp_lines       xsel  -- 販売実績明細
                     , xxcos_sales_exp_headers     xseh  -- 販売実績ヘッダ
-- 2012/06/15 Ver.3.15 [E_本稼動_08751] SCSK S.Niki MOD START
--                     , xxcok_tmp_014a01c_custdata  xt0c  -- 条件別販手販協計算顧客情報一時表
                     , xxcok_wk_014a01c_custdata   xt0c  -- 条件別販手販協計算顧客情報一時表
-- 2012/06/15 Ver.3.15 [E_本稼動_08751] SCSK S.Niki MOD END
                     , xxcok_cust_bm_info          xcbi
-- 2010/03/16 Ver.3.9 [E_本稼動_01896] SCS K.Yamaguchi ADD START
                     , hz_cust_accounts            hca
                     , xxcmm_cust_accounts         xca
-- 2010/03/16 Ver.3.9 [E_本稼動_01896] SCS K.Yamaguchi ADD END
-- 2009/10/02 Ver.3.1 [仕様変更I_E_566] SCS K.Yamaguchi REPAIR START
--                  WHERE xt0c.ship_gyotai_tyu        = cv_gyotai_tyu_vd                          -- 業態（中分類）：VD
                  WHERE xt0c.ship_gyotai_sho       IN ( cv_gyotai_sho_25, cv_gyotai_sho_24 )    -- 業態（小分類）：フルサービスVD・フルサービス（消化）VD
-- 2012/06/15 Ver.3.15 [E_本稼動_08751] SCSK S.Niki ADD START
                    AND xt0c.proc_type              = gv_param_proc_type
-- 2012/06/15 Ver.3.15 [E_本稼動_08751] SCSK S.Niki ADD END
-- 2009/10/02 Ver.3.1 [仕様変更I_E_566] SCS K.Yamaguchi REPAIR END
                    AND xseh.ship_to_customer_code  = xt0c.ship_cust_code
                    AND xseh.delivery_date         <= xt0c.closing_date
-- 2010/12/13 Ver.3.12 [E_本稼動_01844] SCS S.Niki ADD START
                    AND xseh.business_date         <= gd_process_date
-- 2010/12/13 Ver.3.12 [E_本稼動_01844] SCS S.Niki ADD END
                    AND xt0c.ship_cust_code         = xcbi.cust_code(+)
                    AND xseh.delivery_date         >= NVL( xcbi.last_fix_delivery_date, xseh.delivery_date )
                    AND EXISTS ( SELECT 'X'
                                 FROM xxcok_mst_bm_contract xmbc2 -- 販手条件マスタ
                                 WHERE xmbc2.calc_type                = cv_calc_type_sales_price      -- 計算条件：売価別条件
                                   AND xmbc2.cust_code                = xseh.ship_to_customer_code
                                   AND xmbc2.calc_target_flag         = cv_enable
                                   AND xmbc2.container_type_code     IS NULL
                                   AND ROWNUM = 1
                        )
                    AND xsim.item_code              = xsel.item_code
                    AND xseh.sales_exp_header_id    = xsel.sales_exp_header_id
                    AND xsel.to_calculate_fees_flag = cv_xsel_if_flag_no
-- 2010/03/16 Ver.3.9 [E_本稼動_01896] SCS K.Yamaguchi ADD START
                    AND xt0c.ship_cust_code         = hca.account_number
                    AND hca.cust_account_id         = xca.customer_id
-- 2010/03/16 Ver.3.9 [E_本稼動_01896] SCS K.Yamaguchi ADD END
                    AND EXISTS ( SELECT 'X'
                                 FROM fnd_lookup_values flv -- 販手計算対象売上区分
                                 WHERE flv.lookup_type         = cv_lookup_type_07             -- 参照タイプ：販手計算対象売上区分
                                   AND flv.lookup_code         = xsel.sales_class
                                   AND flv.language            = cv_lang
                                   AND flv.enabled_flag        = cv_enable
                                   AND gd_process_date   BETWEEN NVL( flv.start_date_active, gd_process_date )
                                                             AND NVL( flv.end_date_active  , gd_process_date )
                                  AND ROWNUM = 1
                        )
                    AND NOT EXISTS ( SELECT 'X'
                                     FROM fnd_lookup_values flv -- 非在庫品目
                                     WHERE flv.lookup_type         = cv_lookup_type_05 -- 参照タイプ：非在庫品目
                                       AND flv.lookup_code         = xsel.item_code
                                       AND flv.language            = cv_lang
                                       AND flv.enabled_flag        = cv_enable
                                       AND gd_process_date   BETWEEN NVL( flv.start_date_active, gd_process_date )
                                                                 AND NVL( flv.end_date_active  , gd_process_date )
                                       AND ROWNUM = 1
                        )
                )                           xse   -- 販売実績情報
              , fnd_lookup_values           flv1  -- 容器群
              , xxcok_mst_bm_contract       xmbc  -- 販手条件マスタ
           WHERE flv1.lookup_type(+)         = cv_lookup_type_04                         -- 参照タイプ：容器群
             AND flv1.lookup_code(+)         = xse.vessel_group
             AND flv1.language(+)            = cv_lang
             AND flv1.enabled_flag(+)        = cv_enable
             AND gd_process_date       BETWEEN NVL( flv1.start_date_active, gd_process_date )
                                           AND NVL( flv1.end_date_active  , gd_process_date )
             AND xmbc.calc_type(+)           = cv_calc_type_sales_price                  -- 計算条件：売価別条件
             AND xmbc.cust_code(+)           = xse.ship_to_customer_code
             AND xmbc.calc_target_flag(+)    = cv_enable
             AND xmbc.selling_price(+)       = xse.dlv_unit_price
         ) xbc -- 販売実績情報・売価別条件
    GROUP BY xbc.sales_base_code
           , xbc.results_employee_code
           , xbc.ship_to_customer_code
           , xbc.ship_gyotai_sho
           , xbc.ship_gyotai_tyu
           , xbc.bill_cust_code
           , xbc.period_year
           , xbc.ship_delivery_chain_code
           , xbc.delivery_ym
           , xbc.dlv_uom_code
           , xbc.container_code
           , xbc.dlv_unit_price
           , xbc.tax_div
           , xbc.tax_code
           , xbc.tax_rate
           , xbc.tax_rounding_rule
           , xbc.term_name
           , xbc.closing_date
           , xbc.expect_payment_date
           , xbc.calc_target_period_from
           , xbc.calc_target_period_to
           , xbc.calc_type
           , xbc.bm1_vendor_code
           , xbc.bm1_vendor_site_code
           , xbc.bm1_bm_payment_type
           , xbc.bm1_pct
           , xbc.bm1_amt
           , xbc.bm2_vendor_code
           , xbc.bm2_vendor_site_code
           , xbc.bm2_bm_payment_type
           , xbc.bm2_pct
           , xbc.bm2_amt
           , xbc.bm3_vendor_code
           , xbc.bm3_vendor_site_code
           , xbc.bm3_bm_payment_type
           , xbc.bm3_pct
           , xbc.bm3_amt
           , xbc.item_code
           , xbc.amount_fix_date
  ;
  -- 販売実績情報・容器区分別条件
  CURSOR get_sales_data_cur2 IS
    SELECT xbc.sales_base_code                                     AS base_code                -- 拠点コード
         , xbc.results_employee_code                               AS emp_code                 -- 担当者コード
         , xbc.ship_to_customer_code                               AS ship_cust_code           -- 顧客【納品先】
         , xbc.ship_gyotai_sho                                     AS ship_gyotai_sho          -- 顧客【納品先】業態（小分類）
         , xbc.ship_gyotai_tyu                                     AS ship_gyotai_tyu          -- 顧客【納品先】業態（中分類）
         , xbc.bill_cust_code                                      AS bill_cust_code           -- 顧客【請求先】
         , xbc.period_year                                         AS period_year              -- 会計年度
         , xbc.ship_delivery_chain_code                            AS ship_delivery_chain_code -- チェーン店コード
         , xbc.delivery_ym                                         AS delivery_ym              -- 納品日年月
         , SUM( xbc.dlv_qty )                                      AS dlv_qty                  -- 納品数量
         , xbc.dlv_uom_code                                        AS dlv_uom_code             -- 納品単位
         , SUM( xbc.amount_inc_tax )                               AS amount_inc_tax           -- 売上金額（税込）
         , xbc.container_code                                      AS container_code           -- 容器区分コード
         , xbc.dlv_unit_price                                      AS dlv_unit_price           -- 売価金額
         , xbc.tax_div                                             AS tax_div                  -- 消費税区分
         , xbc.tax_code                                            AS tax_code                 -- 税金コード
         , xbc.tax_rate                                            AS tax_rate                 -- 消費税率
         , xbc.tax_rounding_rule                                   AS tax_rounding_rule        -- 端数処理区分
         , xbc.term_name                                           AS term_name                -- 支払条件
         , xbc.closing_date                                        AS closing_date             -- 締め日
         , xbc.expect_payment_date                                 AS expect_payment_date      -- 支払予定日
         , xbc.calc_target_period_from                             AS calc_target_period_from  -- 計算対象期間(FROM)
         , xbc.calc_target_period_to                               AS calc_target_period_to    -- 計算対象期間(TO)
         , xbc.calc_type                                           AS calc_type                -- 計算条件
         , xbc.bm1_vendor_code                                     AS bm1_vendor_code          -- 【ＢＭ１】仕入先コード
         , xbc.bm1_vendor_site_code                                AS bm1_vendor_site_code     -- 【ＢＭ１】仕入先サイトコード
         , xbc.bm1_bm_payment_type                                 AS bm1_bm_payment_type      -- 【ＢＭ１】BM支払区分
         , xbc.bm1_pct                                             AS bm1_pct                  -- 【ＢＭ１】BM率(%)
         , xbc.bm1_amt                                             AS bm1_amt                  -- 【ＢＭ１】BM金額
         , ROUND( SUM( xbc.amount_inc_tax ) * xbc.bm1_pct / 100 )  AS bm1_cond_bm_tax_pct      -- 【ＢＭ１】条件別手数料額(税込)_率
         , ROUND( SUM( xbc.dlv_qty ) * xbc.bm1_amt )               AS bm1_cond_bm_amt_tax      -- 【ＢＭ１】条件別手数料額(税込)_額
         , NULL                                                    AS bm1_electric_amt_tax     -- 【ＢＭ１】電気料(税込)
         , xbc.bm2_vendor_code                                     AS bm2_vendor_code          -- 【ＢＭ２】仕入先コード
         , xbc.bm2_vendor_site_code                                AS bm2_vendor_site_code     -- 【ＢＭ２】仕入先サイトコード
         , xbc.bm2_bm_payment_type                                 AS bm2_bm_payment_type      -- 【ＢＭ２】BM支払区分
         , xbc.bm2_pct                                             AS bm2_pct                  -- 【ＢＭ２】BM率(%)
         , xbc.bm2_amt                                             AS bm2_amt                  -- 【ＢＭ２】BM金額
         , ROUND( SUM( xbc.amount_inc_tax ) * xbc.bm2_pct / 100 )  AS bm2_cond_bm_tax_pct      -- 【ＢＭ２】条件別手数料額(税込)_率
         , ROUND( SUM( xbc.dlv_qty ) * xbc.bm2_amt )               AS bm2_cond_bm_amt_tax      -- 【ＢＭ２】条件別手数料額(税込)_額
         , NULL                                                    AS bm2_electric_amt_tax     -- 【ＢＭ２】電気料(税込)
         , xbc.bm3_vendor_code                                     AS bm3_vendor_code          -- 【ＢＭ３】仕入先コード
         , xbc.bm3_vendor_site_code                                AS bm3_vendor_site_code     -- 【ＢＭ３】仕入先サイトコード
         , xbc.bm3_bm_payment_type                                 AS bm3_bm_payment_type      -- 【ＢＭ３】BM支払区分
         , xbc.bm3_pct                                             AS bm3_pct                  -- 【ＢＭ３】BM率(%)
         , xbc.bm3_amt                                             AS bm3_amt                  -- 【ＢＭ３】BM金額
         , ROUND( SUM( xbc.amount_inc_tax ) * xbc.bm3_pct / 100 )  AS bm3_cond_bm_tax_pct      -- 【ＢＭ３】条件別手数料額(税込)_率
         , ROUND( SUM( xbc.dlv_qty ) * xbc.bm3_amt )               AS bm3_cond_bm_amt_tax      -- 【ＢＭ３】条件別手数料額(税込)_額
         , NULL                                                    AS bm3_electric_amt_tax     -- 【ＢＭ３】電気料(税込)
         , xbc.item_code                                           AS item_code                -- エラー品目コード
         , xbc.amount_fix_date                                     AS amount_fix_date          -- 金額確定日
    FROM ( SELECT xse.sales_base_code                                                              AS sales_base_code          -- 売上拠点コード
                , NVL2( xmbc.calc_type, xse.results_employee_code              , NULL )            AS results_employee_code    -- 成績計上者コード
                , xse.ship_to_customer_code                                                        AS ship_to_customer_code    -- 【出荷先】顧客コード
                , NVL2( xmbc.calc_type, xse.ship_gyotai_sho                    , NULL )            AS ship_gyotai_sho          -- 【出荷先】業態（小分類）
                , NVL2( xmbc.calc_type, xse.ship_gyotai_tyu                    , NULL )            AS ship_gyotai_tyu          -- 【出荷先】業態（中分類）
                , NVL2( xmbc.calc_type, xse.bill_cust_code                     , NULL )            AS bill_cust_code           -- 【請求先】顧客コード
                , NVL2( xmbc.calc_type, xse.period_year                        , NULL )            AS period_year              -- 会計年度
                , NVL2( xmbc.calc_type, xse.ship_delivery_chain_code           , NULL )            AS ship_delivery_chain_code -- 【出荷先】納品先チェーンコード
-- 2010/03/16 Ver.3.9 [E_本稼動_01896] SCS K.Yamaguchi REPAIR START
--                , NVL2( xmbc.calc_type, TO_CHAR( xse.delivery_date, 'RRRRMM' ) , NULL )            AS delivery_ym              -- 納品年月
                , NVL2( xmbc.calc_type, TO_CHAR( xse.closing_date, 'RRRRMM' )  , NULL )            AS delivery_ym              -- 納品年月
-- 2010/03/16 Ver.3.9 [E_本稼動_01896] SCS K.Yamaguchi REPAIR END
                , NVL2( xmbc.calc_type, xse.dlv_qty                            , NULL )            AS dlv_qty                  -- 納品数量
                , NVL2( xmbc.calc_type, xse.dlv_uom_code                       , NULL )            AS dlv_uom_code             -- 納品単位
                , xse.pure_amount + xse.tax_amount                                                 AS amount_inc_tax           -- 売上金額（税込）
                , NVL( xse.attribute1, cv_container_code_others )                                  AS container_code           -- 容器区分コード
                , NVL2( xmbc.calc_type, NULL, xse.dlv_unit_price )                                 AS dlv_unit_price           -- 売価金額
                , NVL2( xmbc.calc_type, xse.tax_div                            , NULL )            AS tax_div                  -- 消費税区分
                , NVL2( xmbc.calc_type, xse.tax_code                           , NULL )            AS tax_code                 -- 税金コード
                , NVL2( xmbc.calc_type, xse.tax_rate                           , NULL )            AS tax_rate                 -- 消費税率
                , NVL2( xmbc.calc_type, xse.tax_rounding_rule                  , NULL )            AS tax_rounding_rule        -- 端数処理区分
                , NVL2( xmbc.calc_type, xse.term_name                          , NULL )            AS term_name                -- 支払条件
                , xse.closing_date                                                                 AS closing_date             -- 締め日
                , NVL2( xmbc.calc_type, xse.expect_payment_date                , NULL )            AS expect_payment_date      -- 支払予定日
                , NVL2( xmbc.calc_type, xse.calc_target_period_from            , NULL )            AS calc_target_period_from  -- 計算対象期間(FROM)
                , NVL2( xmbc.calc_type, xse.calc_target_period_to              , NULL )            AS calc_target_period_to    -- 計算対象期間(TO)
                , xmbc.calc_type                                                                   AS calc_type                -- 計算条件
                , NVL2( xmbc.calc_type, xse.bm1_vendor_code                    , NULL )            AS bm1_vendor_code          -- 【ＢＭ１】仕入先コード
                , NVL2( xmbc.calc_type, xse.bm1_vendor_site_code               , NULL )            AS bm1_vendor_site_code     -- 【ＢＭ１】仕入先サイトコード
                , NVL2( xmbc.calc_type, xse.bm1_bm_payment_type                , NULL )            AS bm1_bm_payment_type      -- 【ＢＭ１】BM支払区分
                , NVL2( xmbc.calc_type, xmbc.bm1_pct                           , NULL )            AS bm1_pct                  -- 【ＢＭ１】BM率(%)
                , NVL2( xmbc.calc_type, xmbc.bm1_amt                           , NULL )            AS bm1_amt                  -- 【ＢＭ１】BM金額
                , NVL2( xmbc.calc_type, xse.bm2_vendor_code                    , NULL )            AS bm2_vendor_code          -- 【ＢＭ２】仕入先コード
                , NVL2( xmbc.calc_type, xse.bm2_vendor_site_code               , NULL )            AS bm2_vendor_site_code     -- 【ＢＭ２】仕入先サイトコード
                , NVL2( xmbc.calc_type, xse.bm2_bm_payment_type                , NULL )            AS bm2_bm_payment_type      -- 【ＢＭ２】BM支払区分
                , NVL2( xmbc.calc_type, xmbc.bm2_pct                           , NULL )            AS bm2_pct                  -- 【ＢＭ２】BM率(%)
                , NVL2( xmbc.calc_type, xmbc.bm2_amt                           , NULL )            AS bm2_amt                  -- 【ＢＭ２】BM金額
                , NVL2( xmbc.calc_type, xse.bm3_vendor_code                    , NULL )            AS bm3_vendor_code          -- 【ＢＭ３】仕入先コード
                , NVL2( xmbc.calc_type, xse.bm3_vendor_site_code               , NULL )            AS bm3_vendor_site_code     -- 【ＢＭ３】仕入先サイトコード
                , NVL2( xmbc.calc_type, xse.bm3_bm_payment_type                , NULL )            AS bm3_bm_payment_type      -- 【ＢＭ３】BM支払区分
                , NVL2( xmbc.calc_type, xmbc.bm3_pct                           , NULL )            AS bm3_pct                  -- 【ＢＭ３】BM率(%)
                , NVL2( xmbc.calc_type, xmbc.bm3_amt                           , NULL )            AS bm3_amt                  -- 【ＢＭ３】BM金額
                , NVL2( xmbc.calc_type, NULL, xse.item_code )                                      AS item_code                -- エラー品目コード
                , xse.amount_fix_date                                                              AS amount_fix_date          -- 金額確定日
-- 2012/10/01 Ver.3.16 [E_本稼動_10133] SCSK K.Kiriu REPAIR START
--           FROM ( SELECT /*+ LEADING(xt0c xcbi xseh xsel xsim) USE_NL(xsel xsim) */
           FROM ( SELECT /*+
                           LEADING(xt0c xcbi hca xca)
                           USE_NL(xt0c xcbi xseh xsel xsim)
                           INDEX(xseh XXCOS_SALES_EXP_HEADERS_N08)
                         */
-- 2012/10/01 Ver.3.16 [E_本稼動_10133] SCSK K.Kiriu REPAIR END
-- 2010/03/16 Ver.3.9 [E_本稼動_01896] SCS K.Yamaguchi REPAIR START
--                         xseh.sales_base_code               AS sales_base_code                 -- 売上拠点コード
--                       , xseh.results_employee_code         AS results_employee_code           -- 成績計上者コード
                         CASE
                           WHEN TRUNC( xt0c.closing_date, 'MM' ) = TRUNC( gd_process_date, 'MM' ) THEN
                             xca.sale_base_code
                           ELSE
                             xca.past_sale_base_code
                         END                                AS sales_base_code                 -- 売上拠点コード
                       , xt0c.emp_code                      AS results_employee_code           -- 成績計上者コード
-- 2010/03/16 Ver.3.9 [E_本稼動_01896] SCS K.Yamaguchi REPAIR END
                       , xseh.ship_to_customer_code         AS ship_to_customer_code           -- 【出荷先】顧客コード
                       , xt0c.ship_gyotai_sho               AS ship_gyotai_sho                 -- 【出荷先】業態（小分類）
                       , xt0c.ship_gyotai_tyu               AS ship_gyotai_tyu                 -- 【出荷先】業態（中分類）
                       , xt0c.bill_cust_code                AS bill_cust_code                  -- 【請求先】顧客コード
                       , xt0c.period_year                   AS period_year                     -- 会計年度
                       , xt0c.ship_delivery_chain_code      AS ship_delivery_chain_code        -- 【出荷先】納品先チェーンコード
                       , xseh.delivery_date                 AS delivery_date                   -- 納品日
                       , xsel.dlv_qty                       AS dlv_qty                         -- 納品数量
                       , xsel.dlv_uom_code                  AS dlv_uom_code                    -- 納品単位
                       , xsel.pure_amount                   AS pure_amount                     -- 本体金額
                       , xsel.tax_amount                    AS tax_amount                      -- 消費税金額
                       , xsel.dlv_unit_price                AS dlv_unit_price                  -- 売価金額
                       , xt0c.tax_div                       AS tax_div                         -- 消費税区分
                       , xt0c.tax_code                      AS tax_code                        -- 税金コード
                       , xt0c.tax_rate                      AS tax_rate                        -- 消費税率
                       , xt0c.tax_rounding_rule             AS tax_rounding_rule               -- 端数処理区分
                       , xt0c.term_name                     AS term_name                       -- 支払条件
                       , xt0c.closing_date                  AS closing_date                    -- 締め日
                       , xt0c.expect_payment_date           AS expect_payment_date             -- 支払予定日
                       , xt0c.calc_target_period_from       AS calc_target_period_from         -- 計算対象期間(FROM)
                       , xt0c.calc_target_period_to         AS calc_target_period_to           -- 計算対象期間(TO)
                       , xt0c.bm1_vendor_code               AS bm1_vendor_code                 -- 【ＢＭ１】仕入先コード
                       , xt0c.bm1_vendor_site_code          AS bm1_vendor_site_code            -- 【ＢＭ１】仕入先サイトコード
                       , xt0c.bm1_bm_payment_type           AS bm1_bm_payment_type             -- 【ＢＭ１】BM支払区分
                       , xt0c.bm2_vendor_code               AS bm2_vendor_code                 -- 【ＢＭ２】仕入先コード
                       , xt0c.bm2_vendor_site_code          AS bm2_vendor_site_code            -- 【ＢＭ２】仕入先サイトコード
                       , xt0c.bm2_bm_payment_type           AS bm2_bm_payment_type             -- 【ＢＭ２】BM支払区分
                       , xt0c.bm3_vendor_code               AS bm3_vendor_code                 -- 【ＢＭ３】仕入先コード
                       , xt0c.bm3_vendor_site_code          AS bm3_vendor_site_code            -- 【ＢＭ３】仕入先サイトコード
                       , xt0c.bm3_bm_payment_type           AS bm3_bm_payment_type             -- 【ＢＭ３】BM支払区分
                       , xsel.item_code                     AS item_code                       -- 在庫品目コード
                       , xt0c.amount_fix_date               AS amount_fix_date                 -- 金額確定日
                       , flv1.attribute1                    AS attribute1                      -- 容器区分コード
                  FROM xxcmm_system_items_b        xsim  -- Disc品目アドオン
                     , xxcos_sales_exp_lines       xsel  -- 販売実績明細
                     , xxcos_sales_exp_headers     xseh  -- 販売実績ヘッダ
-- 2012/06/15 Ver.3.15 [E_本稼動_08751] SCSK S.Niki MOD START
--                     , xxcok_tmp_014a01c_custdata  xt0c  -- 条件別販手販協計算顧客情報一時表
                     , xxcok_wk_014a01c_custdata  xt0c   -- 条件別販手販協計算顧客情報一時表
-- 2012/06/15 Ver.3.15 [E_本稼動_08751] SCSK S.Niki MOD END
                     , fnd_lookup_values           flv1  -- 容器群
                     , xxcok_cust_bm_info          xcbi
-- 2010/03/16 Ver.3.9 [E_本稼動_01896] SCS K.Yamaguchi ADD START
                     , hz_cust_accounts            hca
                     , xxcmm_cust_accounts         xca
-- 2010/03/16 Ver.3.9 [E_本稼動_01896] SCS K.Yamaguchi ADD END
-- 2009/10/02 Ver.3.1 [仕様変更I_E_566] SCS K.Yamaguchi REPAIR START
--                  WHERE xt0c.ship_gyotai_tyu        = cv_gyotai_tyu_vd                          -- 業態（中分類）：VD
                  WHERE xt0c.ship_gyotai_sho       IN ( cv_gyotai_sho_25, cv_gyotai_sho_24 )    -- 業態（小分類）：フルサービスVD・フルサービス（消化）VD
-- 2012/06/15 Ver.3.15 [E_本稼動_08751] SCSK S.Niki ADD START
                    AND xt0c.proc_type              = gv_param_proc_type
-- 2012/06/15 Ver.3.15 [E_本稼動_08751] SCSK S.Niki ADD END
-- 2009/10/02 Ver.3.1 [仕様変更I_E_566] SCS K.Yamaguchi REPAIR END
                    AND xseh.ship_to_customer_code  = xt0c.ship_cust_code
                    AND xseh.delivery_date         <= xt0c.closing_date
-- 2010/12/13 Ver.3.12 [E_本稼動_01844] SCS S.Niki ADD START
                    AND xseh.business_date         <= gd_process_date
-- 2010/12/13 Ver.3.12 [E_本稼動_01844] SCS S.Niki ADD END
                    AND xt0c.ship_cust_code         = xcbi.cust_code(+)
                    AND xseh.delivery_date         >= NVL( xcbi.last_fix_delivery_date, xseh.delivery_date )
                    AND EXISTS ( SELECT 'X'
                                 FROM xxcok_mst_bm_contract xmbc2 -- 販手条件マスタ
                                 WHERE xmbc2.calc_type         = cv_calc_type_container        -- 計算条件：容器区分別条件
                                   AND xmbc2.cust_code         = xseh.ship_to_customer_code
                                   AND xmbc2.calc_target_flag  = cv_enable
                                   AND xmbc2.selling_price    IS NULL
                                   AND ROWNUM = 1
                        )
                    AND xseh.sales_exp_header_id    = xsel.sales_exp_header_id
                    AND xsel.to_calculate_fees_flag = cv_xsel_if_flag_no
-- 2010/03/16 Ver.3.9 [E_本稼動_01896] SCS K.Yamaguchi ADD START
                    AND xt0c.ship_cust_code         = hca.account_number
                    AND hca.cust_account_id         = xca.customer_id
-- 2010/03/16 Ver.3.9 [E_本稼動_01896] SCS K.Yamaguchi ADD END
                    AND EXISTS ( SELECT 'X'
                                 FROM fnd_lookup_values flv -- 販手計算対象売上区分
                                 WHERE flv.lookup_type         = cv_lookup_type_07             -- 参照タイプ：販手計算対象売上区分
                                   AND flv.lookup_code         = xsel.sales_class
                                   AND flv.language            = cv_lang
                                   AND flv.enabled_flag        = cv_enable
                                   AND gd_process_date   BETWEEN NVL( flv.start_date_active, gd_process_date )
                                                             AND NVL( flv.end_date_active  , gd_process_date )
                                   AND ROWNUM = 1
                        )
                    AND NOT EXISTS ( SELECT 'X'
                                     FROM fnd_lookup_values flv -- 非在庫品目
                                     WHERE flv.lookup_type         = cv_lookup_type_05  -- 参照タイプ：非在庫品目
                                       AND flv.lookup_code         = xsel.item_code
                                       AND flv.language            = cv_lang
                                       AND flv.enabled_flag        = cv_enable
                                       AND gd_process_date   BETWEEN NVL( flv.start_date_active, gd_process_date )
                                                                 AND NVL( flv.end_date_active  , gd_process_date )
                                       AND ROWNUM = 1
                        )
                    AND xsim.item_code              = xsel.item_code
                    AND flv1.lookup_type(+)         = cv_lookup_type_04                         -- 参照タイプ：容器群
                    AND flv1.lookup_code(+)         = xsim.vessel_group
                    AND flv1.language(+)            = cv_lang
                    AND flv1.enabled_flag(+)        = cv_enable
                    AND gd_process_date       BETWEEN NVL( flv1.start_date_active, gd_process_date )
                                                  AND NVL( flv1.end_date_active  , gd_process_date )
                )                           xse   -- 販売実績情報
              , xxcok_mst_bm_contract       xmbc  -- 販手条件マスタ
           WHERE xmbc.calc_type(+)           = cv_calc_type_container                    -- 計算条件：容器区分別条件
             AND xmbc.cust_code(+)           = xse.ship_to_customer_code
             AND xmbc.calc_target_flag(+)    = cv_enable
             AND xmbc.container_type_code(+) = NVL( xse.attribute1, cv_container_code_others )
         ) xbc -- 販売実績情報・容器区分別条件
    GROUP BY  xbc.sales_base_code
            , xbc.results_employee_code
            , xbc.ship_to_customer_code
            , xbc.ship_gyotai_sho
            , xbc.ship_gyotai_tyu
            , xbc.bill_cust_code
            , xbc.period_year
            , xbc.ship_delivery_chain_code
            , xbc.delivery_ym
            , xbc.dlv_uom_code
            , xbc.container_code
            , xbc.dlv_unit_price
            , xbc.tax_div
            , xbc.tax_code
            , xbc.tax_rate
            , xbc.tax_rounding_rule
            , xbc.term_name
            , xbc.closing_date
            , xbc.expect_payment_date
            , xbc.calc_target_period_from
            , xbc.calc_target_period_to
            , xbc.calc_type
            , xbc.bm1_vendor_code
            , xbc.bm1_vendor_site_code
            , xbc.bm1_bm_payment_type
            , xbc.bm1_pct
            , xbc.bm1_amt
            , xbc.bm2_vendor_code
            , xbc.bm2_vendor_site_code
            , xbc.bm2_bm_payment_type
            , xbc.bm2_pct
            , xbc.bm2_amt
            , xbc.bm3_vendor_code
            , xbc.bm3_vendor_site_code
            , xbc.bm3_bm_payment_type
            , xbc.bm3_pct
            , xbc.bm3_amt
            , xbc.item_code
            , xbc.amount_fix_date
  ;
  -- 販売実績情報・一律条件
  CURSOR get_sales_data_cur3 IS
-- 2012/10/01 Ver.3.16 [E_本稼動_10133] SCSK K.Kiriu REPAIR START
--    SELECT /*+ LEADING(xt0c xmbc xcbi xseh xsel) */
    SELECT /*+
             LEADING(xt0c xcbi xmbc xseh xsel)
             USE_NL(xt0c xcbi xmbc xseh xsel)
             INDEX(xseh XXCOS_SALES_EXP_HEADERS_N08)
           */
-- 2012/10/01 Ver.3.16 [E_本稼動_10133] SCSK K.Kiriu REPAIR END
-- 2010/03/16 Ver.3.9 [E_本稼動_01896] SCS K.Yamaguchi REPAIR START
--           xseh.sales_base_code                                                    AS base_code                -- 拠点コード
--         , xseh.results_employee_code                                              AS emp_code                 -- 担当者コード
           CASE
             WHEN TRUNC( xt0c.closing_date, 'MM' ) = TRUNC( gd_process_date, 'MM' ) THEN
               xca.sale_base_code
             ELSE
               xca.past_sale_base_code
           END                                                                     AS base_code                -- 拠点コード
         , xt0c.emp_code                                                           AS emp_code                 -- 担当者コード
-- 2010/03/16 Ver.3.9 [E_本稼動_01896] SCS K.Yamaguchi REPAIR END
         , xseh.ship_to_customer_code                                              AS ship_cust_code           -- 顧客【納品先】
         , xt0c.ship_gyotai_sho                                                    AS ship_gyotai_sho          -- 顧客【納品先】業態（小分類）
         , xt0c.ship_gyotai_tyu                                                    AS ship_gyotai_tyu          -- 顧客【納品先】業態（中分類）
         , xt0c.bill_cust_code                                                     AS bill_cust_code           -- 顧客【請求先】
         , xt0c.period_year                                                        AS period_year              -- 会計年度
         , xt0c.ship_delivery_chain_code                                           AS ship_delivery_chain_code -- チェーン店コード
-- 2010/03/16 Ver.3.9 [E_本稼動_01896] SCS K.Yamaguchi REPAIR START
--         , TO_CHAR( xseh.delivery_date, 'RRRRMM' )                                 AS delivery_ym              -- 納品日年月
         , TO_CHAR( xt0c.closing_date, 'RRRRMM' )                                  AS delivery_ym              -- 納品日年月
-- 2010/03/16 Ver.3.9 [E_本稼動_01896] SCS K.Yamaguchi REPAIR END
         , SUM( xsel.dlv_qty )                                                     AS dlv_qty                  -- 納品数量
         , xsel.dlv_uom_code                                                       AS dlv_uom_code             -- 納品単位
         , SUM( xsel.pure_amount + xsel.tax_amount )                               AS amount_inc_tax           -- 売上金額（税込）
         , NULL                                                                    AS container_code           -- 容器区分コード
         , NULL                                                                    AS dlv_unit_price           -- 売価金額
         , xt0c.tax_div                                                            AS tax_div                  -- 消費税区分
         , xt0c.tax_code                                                           AS tax_code                 -- 税金コード
         , xt0c.tax_rate                                                           AS tax_rate                 -- 消費税率
         , xt0c.tax_rounding_rule                                                  AS tax_rounding_rule        -- 端数処理区分
         , xt0c.term_name                                                          AS term_name                -- 支払条件
         , xt0c.closing_date                                                       AS closing_date             -- 締め日
         , xt0c.expect_payment_date                                                AS expect_payment_date      -- 支払予定日
         , xt0c.calc_target_period_from                                            AS calc_target_period_from  -- 計算対象期間(FROM)
         , xt0c.calc_target_period_to                                              AS calc_target_period_to    -- 計算対象期間(TO)
         , xmbc.calc_type                                                          AS calc_type                -- 計算条件
         , xt0c.bm1_vendor_code                                                    AS bm1_vendor_code          -- 【ＢＭ１】仕入先コード
         , xt0c.bm1_vendor_site_code                                               AS bm1_vendor_site_code     -- 【ＢＭ１】仕入先サイトコード
         , xt0c.bm1_bm_payment_type                                                AS bm1_bm_payment_type      -- 【ＢＭ１】BM支払区分
         , xmbc.bm1_pct                                                            AS bm1_pct                  -- 【ＢＭ１】BM率(%)
         , xmbc.bm1_amt                                                            AS bm1_amt                  -- 【ＢＭ１】BM金額
         , TRUNC( SUM( xsel.pure_amount + xsel.tax_amount ) * xmbc.bm1_pct / 100 ) AS bm1_cond_bm_tax_pct      -- 【ＢＭ１】条件別手数料額(税込)_率
         , TRUNC( SUM( xsel.dlv_qty ) * xmbc.bm1_amt )                             AS bm1_cond_bm_amt_tax      -- 【ＢＭ１】条件別手数料額(税込)_額
         , NULL                                                                    AS bm1_electric_amt_tax     -- 【ＢＭ１】電気料(税込)
         , xt0c.bm2_vendor_code                                                    AS bm2_vendor_code          -- 【ＢＭ２】仕入先コード
         , xt0c.bm2_vendor_site_code                                               AS bm2_vendor_site_code     -- 【ＢＭ２】仕入先サイトコード
         , xt0c.bm2_bm_payment_type                                                AS bm2_bm_payment_type      -- 【ＢＭ２】BM支払区分
         , xmbc.bm2_pct                                                            AS bm2_pct                  -- 【ＢＭ２】BM率(%)
         , xmbc.bm2_amt                                                            AS bm2_amt                  -- 【ＢＭ２】BM金額
         , TRUNC( SUM( xsel.pure_amount + xsel.tax_amount ) * xmbc.bm2_pct / 100 ) AS bm2_cond_bm_tax_pct      -- 【ＢＭ２】条件別手数料額(税込)_率
         , TRUNC( SUM( xsel.dlv_qty ) * xmbc.bm2_amt )                             AS bm2_cond_bm_amt_tax      -- 【ＢＭ２】条件別手数料額(税込)_額
         , NULL                                                                    AS bm2_electric_amt_tax     -- 【ＢＭ２】電気料(税込)
         , xt0c.bm3_vendor_code                                                    AS bm3_vendor_code          -- 【ＢＭ３】仕入先コード
         , xt0c.bm3_vendor_site_code                                               AS bm3_vendor_site_code     -- 【ＢＭ３】仕入先サイトコード
         , xt0c.bm3_bm_payment_type                                                AS bm3_bm_payment_type      -- 【ＢＭ３】BM支払区分
         , xmbc.bm3_pct                                                            AS bm3_pct                  -- 【ＢＭ３】BM率(%)
         , xmbc.bm3_amt                                                            AS bm3_amt                  -- 【ＢＭ３】BM金額
         , TRUNC( SUM( xsel.pure_amount + xsel.tax_amount ) * xmbc.bm3_pct / 100 ) AS bm3_cond_bm_tax_pct      -- 【ＢＭ３】条件別手数料額(税込)_率
         , TRUNC( SUM( xsel.dlv_qty ) * xmbc.bm3_amt )                             AS bm3_cond_bm_amt_tax      -- 【ＢＭ３】条件別手数料額(税込)_額
         , NULL                                                                    AS bm3_electric_amt_tax     -- 【ＢＭ３】電気料(税込)
         , NULL                                                                    AS item_code                -- エラー品目コード
         , xt0c.amount_fix_date                                                    AS amount_fix_date          -- 金額確定日
    FROM xxcok_mst_bm_contract       xmbc  -- 販手条件マスタ
       , xxcos_sales_exp_lines       xsel  -- 販売実績明細
       , xxcos_sales_exp_headers     xseh  -- 販売実績ヘッダ
-- 2012/06/15 Ver.3.15 [E_本稼動_08751] SCSK S.Niki MOD START
--       , xxcok_tmp_014a01c_custdata  xt0c  -- 条件別販手販協計算顧客情報一時表
       , xxcok_wk_014a01c_custdata  xt0c   -- 条件別販手販協計算顧客情報一時表
-- 2012/06/15 Ver.3.15 [E_本稼動_08751] SCSK S.Niki MOD END
       , xxcok_cust_bm_info          xcbi
-- 2010/03/16 Ver.3.9 [E_本稼動_01896] SCS K.Yamaguchi ADD START
       , hz_cust_accounts            hca
       , xxcmm_cust_accounts         xca
-- 2010/03/16 Ver.3.9 [E_本稼動_01896] SCS K.Yamaguchi ADD END
-- 2009/10/02 Ver.3.1 [仕様変更I_E_566] SCS K.Yamaguchi REPAIR START
--    WHERE xt0c.ship_gyotai_tyu        = cv_gyotai_tyu_vd                          -- 業態（中分類）：VD
    WHERE xt0c.ship_gyotai_sho       IN ( cv_gyotai_sho_25, cv_gyotai_sho_24 )    -- 業態（小分類）：フルサービスVD・フルサービス（消化）VD
-- 2009/10/02 Ver.3.1 [仕様変更I_E_566] SCS K.Yamaguchi REPAIR END
-- 2012/06/15 Ver.3.15 [E_本稼動_08751] SCSK S.Niki ADD START
      AND xt0c.proc_type              = gv_param_proc_type
-- 2012/06/15 Ver.3.15 [E_本稼動_08751] SCSK S.Niki ADD END
      AND xseh.ship_to_customer_code  = xt0c.ship_cust_code
      AND xseh.delivery_date         <= xt0c.closing_date
-- 2010/12/13 Ver.3.12 [E_本稼動_01844] SCS S.Niki ADD START
      AND xseh.business_date         <= gd_process_date
-- 2010/12/13 Ver.3.12 [E_本稼動_01844] SCS S.Niki ADD END
      AND xt0c.ship_cust_code         = xcbi.cust_code(+)
      AND xseh.delivery_date         >= NVL( xcbi.last_fix_delivery_date, xseh.delivery_date )
      AND xseh.sales_exp_header_id    = xsel.sales_exp_header_id
      AND xsel.to_calculate_fees_flag = cv_xsel_if_flag_no
-- 2010/03/16 Ver.3.9 [E_本稼動_01896] SCS K.Yamaguchi ADD START
      AND xt0c.ship_cust_code         = hca.account_number
      AND hca.cust_account_id         = xca.customer_id
-- 2010/03/16 Ver.3.9 [E_本稼動_01896] SCS K.Yamaguchi ADD END
      AND EXISTS ( SELECT 'X'
                   FROM fnd_lookup_values flv -- 販手計算対象売上区分
                   WHERE flv.lookup_type         = cv_lookup_type_07             -- 参照タイプ：販手計算対象売上区分
                     AND flv.lookup_code         = xsel.sales_class
                     AND flv.language            = cv_lang
                     AND flv.enabled_flag        = cv_enable
                     AND gd_process_date   BETWEEN NVL( flv.start_date_active, gd_process_date )
                                               AND NVL( flv.end_date_active  , gd_process_date )
                     AND ROWNUM = 1
          )
      AND NOT EXISTS ( SELECT 'X'
                       FROM fnd_lookup_values flv -- 非在庫品目
                       WHERE flv.lookup_type         = cv_lookup_type_05         -- 参照タイプ：非在庫品目
                         AND flv.lookup_code         = xsel.item_code
                         AND flv.language            = cv_lang
                         AND flv.enabled_flag        = cv_enable
                         AND gd_process_date   BETWEEN NVL( flv.start_date_active, gd_process_date )
                                                   AND NVL( flv.end_date_active  , gd_process_date )
                         AND ROWNUM = 1
          )
      AND xmbc.calc_type              = cv_calc_type_uniform_rate                 -- 計算条件：一律条件
      AND xmbc.cust_code              = xt0c.ship_cust_code
      AND xmbc.cust_code              = xseh.ship_to_customer_code
      AND xmbc.calc_target_flag       = cv_enable
      AND xmbc.container_type_code    IS NULL
      AND xmbc.selling_price          IS NULL
-- 2010/03/16 Ver.3.9 [E_本稼動_01896] SCS K.Yamaguchi REPAIR START
--    GROUP BY xseh.sales_base_code
--           , xseh.results_employee_code
    GROUP BY CASE
               WHEN TRUNC( xt0c.closing_date, 'MM' ) = TRUNC( gd_process_date, 'MM' ) THEN
                 xca.sale_base_code
               ELSE
                 xca.past_sale_base_code
             END
           , xt0c.emp_code
-- 2010/03/16 Ver.3.9 [E_本稼動_01896] SCS K.Yamaguchi REPAIR END
           , xseh.ship_to_customer_code
           , xt0c.ship_gyotai_sho
           , xt0c.ship_gyotai_tyu
           , xt0c.bill_cust_code
           , xt0c.period_year
           , xt0c.ship_delivery_chain_code
-- 2010/03/16 Ver.3.9 [E_本稼動_01896] SCS K.Yamaguchi REPAIR START
--           , TO_CHAR( xseh.delivery_date, 'RRRRMM' )
           , TO_CHAR( xt0c.closing_date, 'RRRRMM' )
-- 2010/03/16 Ver.3.9 [E_本稼動_01896] SCS K.Yamaguchi REPAIR END
           , xsel.dlv_uom_code
           , xt0c.tax_div
           , xt0c.tax_code
           , xt0c.tax_rate
           , xt0c.tax_rounding_rule
           , xt0c.term_name
           , xt0c.closing_date
           , xt0c.expect_payment_date
           , xt0c.calc_target_period_from
           , xt0c.calc_target_period_to
           , xmbc.calc_type
           , xt0c.bm1_vendor_code
           , xt0c.bm1_vendor_site_code
           , xt0c.bm1_bm_payment_type
           , xmbc.bm1_pct
           , xmbc.bm1_amt
           , xt0c.bm2_vendor_code
           , xt0c.bm2_vendor_site_code
           , xt0c.bm2_bm_payment_type
           , xmbc.bm2_pct
           , xmbc.bm2_amt
           , xt0c.bm3_vendor_code
           , xt0c.bm3_vendor_site_code
           , xt0c.bm3_bm_payment_type
           , xmbc.bm3_pct
           , xmbc.bm3_amt
           , xt0c.amount_fix_date
  ;
-- 2010/03/16 Ver.3.9 [E_本稼動_01896] SCS K.Yamaguchi REPAIR START
--  -- 販売実績情報・定額条件
--  CURSOR get_sales_data_cur4 IS
--    SELECT xseh.sales_base_code          AS base_code                -- 拠点コード
--         , xseh.results_employee_code    AS emp_code                 -- 担当者コード
--         , xbc.ship_to_customer_code     AS ship_cust_code           -- 顧客【納品先】
--         , xbc.ship_gyotai_sho           AS ship_gyotai_sho          -- 顧客【納品先】業態（小分類）
--         , xbc.ship_gyotai_tyu           AS ship_gyotai_tyu          -- 顧客【納品先】業態（中分類）
--         , xbc.bill_cust_code            AS bill_cust_code           -- 顧客【請求先】
--         , xbc.period_year               AS period_year              -- 会計年度
--         , xbc.ship_delivery_chain_code  AS ship_delivery_chain_code -- チェーン店コード
--         , xbc.delivery_ym               AS delivery_ym              -- 納品日年月
--         , xbc.dlv_qty                   AS dlv_qty                  -- 納品数量
--         , xbc.dlv_uom_code              AS dlv_uom_code             -- 納品単位
---- 2009/12/21 Ver.3.6 [E_本稼動_00460] SCS K.Yamaguchi REPAIR START
----         , xbc.amount_inc_tax            AS amount_inc_tax           -- 売上金額（税込）
--         , CASE
--             WHEN NOT EXISTS ( SELECT 'X'
--                               FROM xxcok_mst_bm_contract     xmbc
--                               WHERE xmbc.cust_code               = xbc.ship_to_customer_code
--                                 AND xmbc.calc_target_flag        = cv_enable
--                                 AND xmbc.calc_type              IN ( cv_calc_type_sales_price
--                                                                    , cv_calc_type_container
--                                                                    , cv_calc_type_uniform_rate
--                                                                    )
--                  )
--             THEN
--               xbc.amount_inc_tax
--             ELSE
--               0
--           END                           AS amount_inc_tax           -- 売上金額（税込）
---- 2009/12/21 Ver.3.6 [E_本稼動_00460] SCS K.Yamaguchi REPAIR END
--         , xbc.container_code            AS container_code           -- 容器区分コード
--         , xbc.dlv_unit_price            AS dlv_unit_price           -- 売価金額
--         , xbc.tax_div                   AS tax_div                  -- 消費税区分
--         , xbc.tax_code                  AS tax_code                 -- 税金コード
--         , xbc.tax_rate                  AS tax_rate                 -- 消費税率
--         , xbc.tax_rounding_rule         AS tax_rounding_rule        -- 端数処理区分
--         , xbc.term_name                 AS term_name                -- 支払条件
--         , xbc.closing_date              AS closing_date             -- 締め日
--         , xbc.expect_payment_date       AS expect_payment_date      -- 支払予定日
--         , xbc.calc_target_period_from   AS calc_target_period_from  -- 計算対象期間(FROM)
--         , xbc.calc_target_period_to     AS calc_target_period_to    -- 計算対象期間(TO)
--         , xbc.calc_type                 AS calc_type                -- 計算条件
--         , xbc.bm1_vendor_code           AS bm1_vendor_code          -- 【ＢＭ１】仕入先コード
--         , xbc.bm1_vendor_site_code      AS bm1_vendor_site_code     -- 【ＢＭ１】仕入先サイトコード
--         , xbc.bm1_bm_payment_type       AS bm1_bm_payment_type      -- 【ＢＭ１】BM支払区分
--         , xbc.bm1_pct                   AS bm1_pct                  -- 【ＢＭ１】BM率(%)
--         , xbc.bm1_amt                   AS bm1_amt                  -- 【ＢＭ１】BM金額
--         , NULL                          AS bm1_cond_bm_tax_pct      -- 【ＢＭ１】条件別手数料額(税込)_率
--         , TRUNC( xbc.bm1_amt )          AS bm1_cond_bm_amt_tax      -- 【ＢＭ１】条件別手数料額(税込)_額
--         , NULL                          AS bm1_electric_amt_tax     -- 【ＢＭ１】電気料(税込)
--         , xbc.bm2_vendor_code           AS bm2_vendor_code          -- 【ＢＭ２】仕入先コード
--         , xbc.bm2_vendor_site_code      AS bm2_vendor_site_code     -- 【ＢＭ２】仕入先サイトコード
--         , xbc.bm2_bm_payment_type       AS bm2_bm_payment_type      -- 【ＢＭ２】BM支払区分
--         , xbc.bm2_pct                   AS bm2_pct                  -- 【ＢＭ２】BM率(%)
--         , xbc.bm2_amt                   AS bm2_amt                  -- 【ＢＭ２】BM金額
--         , NULL                          AS bm2_cond_bm_tax_pct      -- 【ＢＭ２】条件別手数料額(税込)_率
--         , TRUNC( xbc.bm2_amt )          AS bm2_cond_bm_amt_tax      -- 【ＢＭ２】条件別手数料額(税込)_額
--         , NULL                          AS bm2_electric_amt_tax     -- 【ＢＭ２】電気料(税込)
--         , xbc.bm3_vendor_code           AS bm3_vendor_code          -- 【ＢＭ３】仕入先コード
--         , xbc.bm3_vendor_site_code      AS bm3_vendor_site_code     -- 【ＢＭ３】仕入先サイトコード
--         , xbc.bm3_bm_payment_type       AS bm3_bm_payment_type      -- 【ＢＭ３】BM支払区分
--         , xbc.bm3_pct                   AS bm3_pct                  -- 【ＢＭ３】BM率(%)
--         , xbc.bm3_amt                   AS bm3_amt                  -- 【ＢＭ３】BM金額
--         , NULL                          AS bm3_cond_bm_tax_pct      -- 【ＢＭ３】条件別手数料額(税込)_率
--         , TRUNC( xbc.bm3_amt )          AS bm3_cond_bm_amt_tax      -- 【ＢＭ３】条件別手数料額(税込)_額
--         , NULL                          AS bm3_electric_amt_tax     -- 【ＢＭ３】電気料(税込)
--         , xbc.item_code                 AS item_code                -- エラー品目コード
--         , xbc.amount_fix_date           AS amount_fix_date          -- 金額確定日
--    FROM ( SELECT /*+ LEADING(xt0c xmbc xcbi xseh xsel) */
--                  MAX( xseh.sales_exp_header_id )           AS sales_exp_header_id      -- 販売実績ヘッダID
--                , NULL                                      AS sales_base_code          -- 売上拠点コード
--                , NULL                                      AS results_employee_code    -- 成績計上者コード
--                , xseh.ship_to_customer_code                AS ship_to_customer_code    -- 【出荷先】顧客コード
--                , xt0c.ship_gyotai_sho                      AS ship_gyotai_sho          -- 【出荷先】業態（小分類）
--                , xt0c.ship_gyotai_tyu                      AS ship_gyotai_tyu          -- 【出荷先】業態（中分類）
--                , xt0c.bill_cust_code                       AS bill_cust_code           -- 【請求先】顧客コード
--                , xt0c.period_year                          AS period_year              -- 会計年度
--                , xt0c.ship_delivery_chain_code             AS ship_delivery_chain_code -- 【出荷先】納品先チェーンコード
---- 2009/12/21 Ver.3.6 [E_本稼動_00460] SCS K.Yamaguchi REPAIR START
----                , TO_CHAR( xseh.delivery_date, 'RRRRMM' )   AS delivery_ym              -- 納品年月
--                , TO_CHAR( xt0c.closing_date, 'RRRRMM' )    AS delivery_ym              -- 納品年月
---- 2009/12/21 Ver.3.6 [E_本稼動_00460] SCS K.Yamaguchi REPAIR END
--                , NULL                                      AS dlv_qty                  -- 納品数量
--                , NULL                                      AS dlv_uom_code             -- 納品単位
--                , SUM( xsel.pure_amount + xsel.tax_amount ) AS amount_inc_tax           -- 売上金額（税込）
--                , NULL                                      AS container_code           -- 容器区分コード
--                , NULL                                      AS dlv_unit_price           -- 売価金額
--                , xt0c.tax_div                              AS tax_div                  -- 消費税区分
--                , xt0c.tax_code                             AS tax_code                 -- 税金コード
--                , xt0c.tax_rate                             AS tax_rate                 -- 消費税率
--                , xt0c.tax_rounding_rule                    AS tax_rounding_rule        -- 端数処理区分
--                , xt0c.term_name                            AS term_name                -- 支払条件
--                , xt0c.closing_date                         AS closing_date             -- 締め日
--                , xt0c.expect_payment_date                  AS expect_payment_date      -- 支払予定日
--                , xt0c.calc_target_period_from              AS calc_target_period_from  -- 計算対象期間(FROM)
--                , xt0c.calc_target_period_to                AS calc_target_period_to    -- 計算対象期間(TO)
--                , xmbc.calc_type                            AS calc_type                -- 計算条件
--                , xt0c.bm1_vendor_code                      AS bm1_vendor_code          -- 【ＢＭ１】仕入先コード
--                , xt0c.bm1_vendor_site_code                 AS bm1_vendor_site_code     -- 【ＢＭ１】仕入先サイトコード
--                , xt0c.bm1_bm_payment_type                  AS bm1_bm_payment_type      -- 【ＢＭ１】BM支払区分
--                , NULL                                      AS bm1_pct                  -- 【ＢＭ１】BM率(%)
--                , xmbc.bm1_amt                              AS bm1_amt                  -- 【ＢＭ１】BM金額
--                , xt0c.bm2_vendor_code                      AS bm2_vendor_code          -- 【ＢＭ２】仕入先コード
--                , xt0c.bm2_vendor_site_code                 AS bm2_vendor_site_code     -- 【ＢＭ２】仕入先サイトコード
--                , xt0c.bm2_bm_payment_type                  AS bm2_bm_payment_type      -- 【ＢＭ２】BM支払区分
--                , NULL                                      AS bm2_pct                  -- 【ＢＭ２】BM率(%)
--                , xmbc.bm2_amt                              AS bm2_amt                  -- 【ＢＭ２】BM金額
--                , xt0c.bm3_vendor_code                      AS bm3_vendor_code          -- 【ＢＭ３】仕入先コード
--                , xt0c.bm3_vendor_site_code                 AS bm3_vendor_site_code     -- 【ＢＭ３】仕入先サイトコード
--                , xt0c.bm3_bm_payment_type                  AS bm3_bm_payment_type      -- 【ＢＭ３】BM支払区分
--                , NULL                                      AS bm3_pct                  -- 【ＢＭ３】BM率(%)
--                , xmbc.bm3_amt                              AS bm3_amt                  -- 【ＢＭ３】BM金額
--                , NULL                                      AS item_code                -- エラー品目コード
--                , xt0c.amount_fix_date                      AS amount_fix_date          -- 金額確定日
--           FROM xxcok_mst_bm_contract       xmbc  -- 販手条件マスタ
--              , xxcos_sales_exp_lines       xsel  -- 販売実績明細
--              , xxcos_sales_exp_headers     xseh  -- 販売実績ヘッダ
--              , xxcok_tmp_014a01c_custdata  xt0c  -- 条件別販手販協計算顧客情報一時表
--              , xxcok_cust_bm_info          xcbi
---- 2009/10/02 Ver.3.1 [仕様変更I_E_566] SCS K.Yamaguchi REPAIR START
----           WHERE xt0c.ship_gyotai_tyu        = cv_gyotai_tyu_vd                          -- 業態（中分類）：VD
--           WHERE xt0c.ship_gyotai_sho       IN ( cv_gyotai_sho_25, cv_gyotai_sho_24 )    -- 業態（小分類）：フルサービスVD・フルサービス（消化）VD
---- 2009/10/02 Ver.3.1 [仕様変更I_E_566] SCS K.Yamaguchi REPAIR END
--             AND xseh.ship_to_customer_code  = xt0c.ship_cust_code
--             AND xseh.delivery_date         <= xt0c.closing_date
--             AND xt0c.ship_cust_code         = xcbi.cust_code(+)
--             AND xseh.delivery_date         >= NVL( xcbi.last_fix_delivery_date, xseh.delivery_date )
--             AND xseh.sales_exp_header_id    = xsel.sales_exp_header_id
--             AND xsel.to_calculate_fees_flag = cv_xsel_if_flag_no
--             AND EXISTS ( SELECT  'X'
--                          FROM fnd_lookup_values flv -- 販手計算対象売上区分
--                          WHERE flv.lookup_type         = cv_lookup_type_07             -- 参照タイプ：販手計算対象売上区分
--                            AND flv.lookup_code         = xsel.sales_class
--                            AND flv.language            = cv_lang
--                            AND flv.enabled_flag        = cv_enable
--                            AND gd_process_date   BETWEEN NVL( flv.start_date_active, gd_process_date )
--                                                      AND NVL( flv.end_date_active  , gd_process_date )
--                            AND ROWNUM = 1
--                 )
--             AND NOT EXISTS ( SELECT 'X'
--                              FROM fnd_lookup_values flv -- 非在庫品目
--                              WHERE flv.lookup_type         = cv_lookup_type_05         -- 参照タイプ：非在庫品目
--                                AND flv.lookup_code         = xsel.item_code
--                                AND flv.language            = cv_lang
--                                AND flv.enabled_flag        = cv_enable
--                                AND gd_process_date   BETWEEN NVL( flv.start_date_active, gd_process_date )
--                                                          AND NVL( flv.end_date_active  , gd_process_date )
--                                AND ROWNUM = 1
--                 )
--             AND xmbc.calc_type              = cv_calc_type_flat_rate                    -- 計算条件：定額条件
--             AND xmbc.cust_code              = xt0c.ship_cust_code
--             AND xmbc.cust_code              = xseh.ship_to_customer_code
--             AND xmbc.calc_target_flag       = cv_enable
--             AND xmbc.container_type_code   IS NULL
--             AND xmbc.selling_price         IS NULL
--           GROUP BY xseh.ship_to_customer_code
--                  , xt0c.ship_gyotai_sho
--                  , xt0c.ship_gyotai_tyu
--                  , xt0c.bill_cust_code
--                  , xt0c.period_year
--                  , xt0c.ship_delivery_chain_code
---- 2009/12/21 Ver.3.6 [E_本稼動_00460] SCS K.Yamaguchi DELETE START
----                  , TO_CHAR( xseh.delivery_date, 'RRRRMM' )
---- 2009/12/21 Ver.3.6 [E_本稼動_00460] SCS K.Yamaguchi DELETE END
--                  , xt0c.tax_div
--                  , xt0c.tax_code
--                  , xt0c.tax_rate
--                  , xt0c.tax_rounding_rule
--                  , xt0c.term_name
--                  , xt0c.closing_date
--                  , xt0c.expect_payment_date
--                  , xt0c.calc_target_period_from
--                  , xt0c.calc_target_period_to
--                  , xmbc.calc_type
--                  , xt0c.bm1_vendor_code
--                  , xt0c.bm1_vendor_site_code
--                  , xt0c.bm1_bm_payment_type
--                  , xmbc.bm1_amt
--                  , xt0c.bm2_vendor_code
--                  , xt0c.bm2_vendor_site_code
--                  , xt0c.bm2_bm_payment_type
--                  , xmbc.bm2_amt
--                  , xt0c.bm3_vendor_code
--                  , xt0c.bm3_vendor_site_code
--                  , xt0c.bm3_bm_payment_type
--                  , xmbc.bm3_amt
--                  , xt0c.amount_fix_date
--         )                           xbc   -- 販売実績情報・定額条件
--       , xxcos_sales_exp_headers     xseh  -- 販売実績ヘッダ
--    WHERE xseh.sales_exp_header_id = xbc.sales_exp_header_id
--  ;
  -- 販売実績情報・定額条件
  CURSOR get_sales_data_cur4 IS
    SELECT /*+
-- 2012/10/01 Ver.3.16 [E_本稼動_10133] SCSK K.Kiriu REPAIR START
--             LEADING( xt0c hca xca xcbi xmbc )
             LEADING(xt0c hca xca xcbi xmbc)
             USE_NL(xt0c xcbi xmbc xseh xsel )
             INDEX(xseh XXCOS_SALES_EXP_HEADERS_N08)
-- 2012/10/01 Ver.3.16 [E_本稼動_10133] SCSK K.Kiriu REPAIR END
           */
           CASE
             WHEN TRUNC( xt0c.closing_date, 'MM' ) = TRUNC( gd_process_date, 'MM' ) THEN
               xca.sale_base_code
             ELSE
               xca.past_sale_base_code
           END                                    AS base_code                -- 拠点コード
         , xt0c.emp_code                          AS emp_code                 -- 担当者コード
         , xt0c.ship_cust_code                    AS ship_cust_code           -- 顧客【納品先】
         , xt0c.ship_gyotai_sho                   AS ship_gyotai_sho          -- 顧客【納品先】業態（小分類）
         , xt0c.ship_gyotai_tyu                   AS ship_gyotai_tyu          -- 顧客【納品先】業態（中分類）
         , xt0c.bill_cust_code                    AS bill_cust_code           -- 顧客【請求先】
         , xt0c.period_year                       AS period_year              -- 会計年度
         , xt0c.ship_delivery_chain_code          AS ship_delivery_chain_code -- チェーン店コード
         , TO_CHAR( xt0c.closing_date, 'RRRRMM' ) AS delivery_ym              -- 納品日年月
         , NULL                                   AS dlv_qty                  -- 納品数量
         , NULL                                   AS dlv_uom_code             -- 納品単位
-- 2010/12/13 Ver.3.12 [E_本稼動_01896] SCS S.Niki REPAIR START
--         , CASE
--             WHEN EXISTS ( SELECT 'X'
--                           FROM xxcok_mst_bm_contract     xmbc
--                           WHERE xmbc.cust_code               = xt0c.ship_cust_code
--                             AND xmbc.calc_target_flag        = cv_enable
--                             AND xmbc.calc_type              IN ( cv_calc_type_sales_price
--                                                                , cv_calc_type_container
--                                                                , cv_calc_type_uniform_rate
--                                                                )
--                             AND ROWNUM = 1
--                  )
--             THEN
--               0
--             ELSE
--               NVL( ( SELECT SUM( xsel.pure_amount + xsel.tax_amount )
--                      FROM xxcos_sales_exp_headers     xseh  -- 販売実績ヘッダ
--                         , xxcos_sales_exp_lines       xsel  -- 販売実績明細
--                      WHERE xseh.ship_to_customer_code  = xt0c.ship_cust_code
--                        AND xseh.delivery_date         <= xt0c.closing_date
--                        AND xseh.delivery_date         >= NVL( xcbi.last_fix_delivery_date, xseh.delivery_date )
--                        AND xseh.sales_exp_header_id    = xsel.sales_exp_header_id
--                        AND xsel.to_calculate_fees_flag = cv_xsel_if_flag_no
--                        AND EXISTS ( SELECT  'X'
--                                     FROM fnd_lookup_values flv -- 販手計算対象売上区分
--                                     WHERE flv.lookup_type         = cv_lookup_type_07             -- 参照タイプ：販手計算対象売上区分
--                                       AND flv.lookup_code         = xsel.sales_class
--                                       AND flv.language            = cv_lang
--                                       AND flv.enabled_flag        = cv_enable
--                                       AND gd_process_date   BETWEEN NVL( flv.start_date_active, gd_process_date )
--                                                                 AND NVL( flv.end_date_active  , gd_process_date )
--                                       AND ROWNUM = 1
--                            )
--                        AND NOT EXISTS ( SELECT 'X'
--                                         FROM fnd_lookup_values flv -- 非在庫品目
--                                         WHERE flv.lookup_type         = cv_lookup_type_05         -- 参照タイプ：非在庫品目
--                                           AND flv.lookup_code         = xsel.item_code
--                                           AND flv.language            = cv_lang
--                                           AND flv.enabled_flag        = cv_enable
--                                           AND gd_process_date   BETWEEN NVL( flv.start_date_active, gd_process_date )
--                                                                     AND NVL( flv.end_date_active  , gd_process_date )
--                                           AND ROWNUM = 1
--                            )
--               ), 0 )
--           END                           AS amount_inc_tax           -- 売上金額（税込）
         , SUM(
             CASE
               WHEN EXISTS ( SELECT 'X'
                             FROM xxcok_mst_bm_contract     xmbc
                             WHERE xmbc.cust_code               = xt0c.ship_cust_code
                               AND xmbc.calc_target_flag        = cv_enable
                               AND xmbc.calc_type              IN ( cv_calc_type_sales_price
                                                                  , cv_calc_type_container
                                                                  , cv_calc_type_uniform_rate
                                                                  )
                               AND ROWNUM = 1
                    )
               THEN
                 0
               ELSE
                 NVL( xsel.pure_amount + xsel.tax_amount, 0 )
             END
           )                             AS amount_inc_tax           -- 売上金額（税込）
-- 2010/12/13 Ver.3.12 [E_本稼動_01896] SCS S.Niki REPAIR END
         , NULL                          AS container_code           -- 容器区分コード
         , NULL                          AS dlv_unit_price           -- 売価金額
         , xt0c.tax_div                  AS tax_div                  -- 消費税区分
         , xt0c.tax_code                 AS tax_code                 -- 税金コード
         , xt0c.tax_rate                 AS tax_rate                 -- 消費税率
         , xt0c.tax_rounding_rule        AS tax_rounding_rule        -- 端数処理区分
         , xt0c.term_name                AS term_name                -- 支払条件
         , xt0c.closing_date             AS closing_date             -- 締め日
         , xt0c.expect_payment_date      AS expect_payment_date      -- 支払予定日
         , xt0c.calc_target_period_from  AS calc_target_period_from  -- 計算対象期間(FROM)
         , xt0c.calc_target_period_to    AS calc_target_period_to    -- 計算対象期間(TO)
         , xmbc.calc_type                AS calc_type                -- 計算条件
         , xt0c.bm1_vendor_code          AS bm1_vendor_code          -- 【ＢＭ１】仕入先コード
         , xt0c.bm1_vendor_site_code     AS bm1_vendor_site_code     -- 【ＢＭ１】仕入先サイトコード
         , xt0c.bm1_bm_payment_type      AS bm1_bm_payment_type      -- 【ＢＭ１】BM支払区分
         , NULL                          AS bm1_pct                  -- 【ＢＭ１】BM率(%)
         , xmbc.bm1_amt                  AS bm1_amt                  -- 【ＢＭ１】BM金額
         , NULL                          AS bm1_cond_bm_tax_pct      -- 【ＢＭ１】条件別手数料額(税込)_率
         , TRUNC( xmbc.bm1_amt )         AS bm1_cond_bm_amt_tax      -- 【ＢＭ１】条件別手数料額(税込)_額
         , NULL                          AS bm1_electric_amt_tax     -- 【ＢＭ１】電気料(税込)
         , xt0c.bm2_vendor_code          AS bm2_vendor_code          -- 【ＢＭ２】仕入先コード
         , xt0c.bm2_vendor_site_code     AS bm2_vendor_site_code     -- 【ＢＭ２】仕入先サイトコード
         , xt0c.bm2_bm_payment_type      AS bm2_bm_payment_type      -- 【ＢＭ２】BM支払区分
         , NULL                          AS bm2_pct                  -- 【ＢＭ２】BM率(%)
         , xmbc.bm2_amt                  AS bm2_amt                  -- 【ＢＭ２】BM金額
         , NULL                          AS bm2_cond_bm_tax_pct      -- 【ＢＭ２】条件別手数料額(税込)_率
         , TRUNC( xmbc.bm2_amt )         AS bm2_cond_bm_amt_tax      -- 【ＢＭ２】条件別手数料額(税込)_額
         , NULL                          AS bm2_electric_amt_tax     -- 【ＢＭ２】電気料(税込)
         , xt0c.bm3_vendor_code          AS bm3_vendor_code          -- 【ＢＭ３】仕入先コード
         , xt0c.bm3_vendor_site_code     AS bm3_vendor_site_code     -- 【ＢＭ３】仕入先サイトコード
         , xt0c.bm3_bm_payment_type      AS bm3_bm_payment_type      -- 【ＢＭ３】BM支払区分
         , NULL                          AS bm3_pct                  -- 【ＢＭ３】BM率(%)
         , xmbc.bm3_amt                  AS bm3_amt                  -- 【ＢＭ３】BM金額
         , NULL                          AS bm3_cond_bm_tax_pct      -- 【ＢＭ３】条件別手数料額(税込)_率
         , TRUNC( xmbc.bm3_amt )         AS bm3_cond_bm_amt_tax      -- 【ＢＭ３】条件別手数料額(税込)_額
         , NULL                          AS bm3_electric_amt_tax     -- 【ＢＭ３】電気料(税込)
         , NULL                          AS item_code                -- エラー品目コード
         , xt0c.amount_fix_date          AS amount_fix_date          -- 金額確定日
-- 2012/06/15 Ver.3.15 [E_本稼動_08751] SCSK S.Niki MOD START
--    FROM xxcok_tmp_014a01c_custdata      xt0c  -- 条件別販手販協計算顧客情報一時表
    FROM xxcok_wk_014a01c_custdata       xt0c  -- 条件別販手販協計算顧客情報一時表
-- 2012/06/15 Ver.3.15 [E_本稼動_08751] SCSK S.Niki MOD END
       , xxcok_mst_bm_contract           xmbc  -- 販手条件マスタ
       , xxcok_cust_bm_info              xcbi
       , hz_cust_accounts                hca
       , xxcmm_cust_accounts             xca
-- 2010/12/13 Ver.3.12 [E_本稼動_01896] SCS S.Niki REPAIR START
       , xxcos_sales_exp_headers         xseh  -- 販売実績ヘッダ
       , xxcos_sales_exp_lines           xsel  -- 販売実績明細
-- 2010/12/13 Ver.3.12 [E_本稼動_01896] SCS S.Niki REPAIR END
    WHERE xt0c.ship_gyotai_sho       IN ( cv_gyotai_sho_25, cv_gyotai_sho_24 )    -- 業態（小分類）：フルサービスVD・フルサービス（消化）VD
-- 2012/06/15 Ver.3.15 [E_本稼動_08751] SCSK S.Niki ADD START
      AND xt0c.proc_type              = gv_param_proc_type
-- 2012/06/15 Ver.3.15 [E_本稼動_08751] SCSK S.Niki ADD END
      AND xt0c.ship_cust_code         = xmbc.cust_code
      AND xmbc.calc_type              = cv_calc_type_flat_rate                    -- 計算条件：定額条件
      AND xmbc.calc_target_flag       = cv_enable
      AND xmbc.container_type_code   IS NULL
      AND xmbc.selling_price         IS NULL
      AND xt0c.ship_cust_code         = xcbi.cust_code(+)
      AND xt0c.ship_cust_code         = hca.account_number
      AND hca.cust_account_id         = xca.customer_id
-- 2010/12/13 Ver.3.12 [E_本稼動_01896] SCS S.Niki REPAIR START
      AND xseh.ship_to_customer_code  = xt0c.ship_cust_code
      AND xseh.delivery_date         <= xt0c.closing_date
      AND xseh.delivery_date         >= NVL( xcbi.last_fix_delivery_date, xseh.delivery_date )
-- 2010/12/13 Ver.3.12 [E_本稼動_01844] SCS S.Niki ADD START
      AND xseh.business_date         <= gd_process_date
-- 2010/12/13 Ver.3.12 [E_本稼動_01844] SCS S.Niki ADD END
      AND xseh.sales_exp_header_id    = xsel.sales_exp_header_id
      AND xsel.to_calculate_fees_flag = cv_xsel_if_flag_no
      AND EXISTS ( SELECT  'X'
                   FROM fnd_lookup_values flv -- 販手計算対象売上区分
                   WHERE flv.lookup_type         = cv_lookup_type_07             -- 参照タイプ：販手計算対象売上区分
                     AND flv.lookup_code         = xsel.sales_class
                     AND flv.language            = cv_lang
                     AND flv.enabled_flag        = cv_enable
                     AND gd_process_date   BETWEEN NVL( flv.start_date_active, gd_process_date )
                                               AND NVL( flv.end_date_active  , gd_process_date )
                     AND ROWNUM = 1
         )
      AND NOT EXISTS ( SELECT 'X'
                       FROM fnd_lookup_values flv -- 非在庫品目
                       WHERE flv.lookup_type         = cv_lookup_type_05         -- 参照タイプ：非在庫品目
                         AND flv.lookup_code         = xsel.item_code
                         AND flv.language            = cv_lang
                         AND flv.enabled_flag        = cv_enable
                         AND gd_process_date   BETWEEN NVL( flv.start_date_active, gd_process_date )
                                                   AND NVL( flv.end_date_active  , gd_process_date )
                         AND ROWNUM = 1
          )
GROUP BY CASE
           WHEN TRUNC( xt0c.closing_date, 'MM' ) = TRUNC( gd_process_date, 'MM' ) THEN
             xca.sale_base_code
           ELSE
             xca.past_sale_base_code
         END                                    -- 拠点コード
       , xt0c.emp_code                          -- 担当者コード
       , xt0c.ship_cust_code                    -- 顧客【納品先】
       , xt0c.ship_gyotai_sho                   -- 顧客【納品先】業態（小分類）
       , xt0c.ship_gyotai_tyu                   -- 顧客【納品先】業態（中分類）
       , xt0c.bill_cust_code                    -- 顧客【請求先】
       , xt0c.period_year                       -- 会計年度
       , xt0c.ship_delivery_chain_code          -- チェーン店コード
       , TO_CHAR( xt0c.closing_date, 'RRRRMM' ) -- 納品日年月
       , xt0c.tax_div                           -- 消費税区分
       , xt0c.tax_code                          -- 税金コード
       , xt0c.tax_rate                          -- 消費税率
       , xt0c.tax_rounding_rule                 -- 端数処理区分
       , xt0c.term_name                         -- 支払条件
       , xt0c.closing_date                      -- 締め日
       , xt0c.expect_payment_date               -- 支払予定日
       , xt0c.calc_target_period_from           -- 計算対象期間(FROM)
       , xt0c.calc_target_period_to             -- 計算対象期間(TO)
       , xmbc.calc_type                         -- 計算条件
       , xt0c.bm1_vendor_code                   -- 【ＢＭ１】仕入先コード
       , xt0c.bm1_vendor_site_code              -- 【ＢＭ１】仕入先サイトコード
       , xt0c.bm1_bm_payment_type               -- 【ＢＭ１】BM支払区分
       , xmbc.bm1_amt                           -- 【ＢＭ１】BM金額
       , TRUNC( xmbc.bm1_amt )                  -- 【ＢＭ１】条件別手数料額(税込)_額
       , xt0c.bm2_vendor_code                   -- 【ＢＭ２】仕入先コード
       , xt0c.bm2_vendor_site_code              -- 【ＢＭ２】仕入先サイトコード
       , xt0c.bm2_bm_payment_type               -- 【ＢＭ２】BM支払区分
       , xmbc.bm2_amt                           -- 【ＢＭ２】BM金額
       , TRUNC( xmbc.bm2_amt )                  -- 【ＢＭ２】条件別手数料額(税込)_額
       , xt0c.bm3_vendor_code                   -- 【ＢＭ３】仕入先コード
       , xt0c.bm3_vendor_site_code              -- 【ＢＭ３】仕入先サイトコード
       , xt0c.bm3_bm_payment_type               -- 【ＢＭ３】BM支払区分
       , xmbc.bm3_amt                           -- 【ＢＭ３】BM金額
       , TRUNC( xmbc.bm3_amt )                  -- 【ＢＭ３】条件別手数料額(税込)_額
       , xt0c.amount_fix_date                   -- 金額確定日
-- 2010/12/13 Ver.3.12 [E_本稼動_01896] SCS S.Niki REPAIR END
  ;
-- 2010/03/16 Ver.3.9 [E_本稼動_01896] SCS K.Yamaguchi REPAIR END
-- 2009/12/21 Ver.3.6 [E_本稼動_00460] SCS K.Yamaguchi REPAIR START
--  -- 販売実績情報・電気料（固定／変動）
--  CURSOR get_sales_data_cur5 IS
--    SELECT xbc.base_code                                                  AS base_code                  -- 拠点コード
--         , xbc.emp_code                                                   AS emp_code                   -- 担当者コード
--         , xbc.ship_cust_code                                             AS ship_cust_code             -- 顧客【納品先】
--         , xbc.ship_gyotai_sho                                            AS ship_gyotai_sho            -- 顧客【納品先】業態（小分類）
--         , xbc.ship_gyotai_tyu                                            AS ship_gyotai_tyu            -- 顧客【納品先】業態（中分類）
--         , xbc.bill_cust_code                                             AS bill_cust_code             -- 顧客【請求先】
--         , xbc.period_year                                                AS period_year                -- 会計年度
--         , xbc.ship_delivery_chain_code                                   AS ship_delivery_chain_code   -- チェーン店コード
--         , xbc.delivery_ym                                                AS delivery_ym                -- 納品日年月
--         , xbc.dlv_qty                                                    AS dlv_qty                    -- 納品数量
--         , xbc.dlv_uom_code                                               AS dlv_uom_code               -- 納品単位
--         , xbc.amount_inc_tax                                             AS amount_inc_tax             -- 売上金額（税込）
--         , xbc.container_code                                             AS container_code             -- 容器区分コード
--         , xbc.dlv_unit_price                                             AS dlv_unit_price             -- 売価金額
--         , xbc.tax_div                                                    AS tax_div                    -- 消費税区分
--         , xbc.tax_code                                                   AS tax_code                   -- 税金コード
--         , xbc.tax_rate                                                   AS tax_rate                   -- 消費税率
--         , xbc.tax_rounding_rule                                          AS tax_rounding_rule          -- 端数処理区分
--         , xbc.term_name                                                  AS term_name                  -- 支払条件
--         , xbc.closing_date                                               AS closing_date               -- 締め日
--         , xbc.expect_payment_date                                        AS expect_payment_date        -- 支払予定日
--         , xbc.calc_target_period_from                                    AS calc_target_period_from    -- 計算対象期間(FROM)
--         , xbc.calc_target_period_to                                      AS calc_target_period_to      -- 計算対象期間(TO)
--         , xbc.calc_type                                                  AS calc_type                  -- 計算条件
--         , xbc.bm1_vendor_code                                            AS bm1_vendor_code            -- 【ＢＭ１】仕入先コード
--         , xbc.bm1_vendor_site_code                                       AS bm1_vendor_site_code       -- 【ＢＭ１】仕入先サイトコード
--         , xbc.bm1_bm_payment_type                                        AS bm1_bm_payment_type        -- 【ＢＭ１】BM支払区分
--         , NULL                                                           AS bm1_pct                    -- 【ＢＭ１】BM率(%)
--         , NULL                                                           AS bm1_amt                    -- 【ＢＭ１】BM金額
--         , NULL                                                           AS bm1_cond_bm_tax_pct        -- 【ＢＭ１】条件別手数料額(税込)_率
--         , NULL                                                           AS bm1_cond_bm_amt_tax        -- 【ＢＭ１】条件別手数料額(税込)_額
--         , TRUNC( SUM( xbc.bm1_amt ) )                                    AS bm1_electric_amt_tax       -- 【ＢＭ１】電気料(税込)
--         , xbc.bm2_vendor_code                                            AS bm2_vendor_code            -- 【ＢＭ２】仕入先コード
--         , xbc.bm2_vendor_site_code                                       AS bm2_vendor_site_code       -- 【ＢＭ２】仕入先サイトコード
--         , xbc.bm2_bm_payment_type                                        AS bm2_bm_payment_type        -- 【ＢＭ２】BM支払区分
--         , NULL                                                           AS bm2_pct                    -- 【ＢＭ２】BM率(%)
--         , NULL                                                           AS bm2_amt                    -- 【ＢＭ２】BM金額
--         , NULL                                                           AS bm2_cond_bm_tax_pct        -- 【ＢＭ２】条件別手数料額(税込)_率
--         , NULL                                                           AS bm2_cond_bm_amt_tax        -- 【ＢＭ２】条件別手数料額(税込)_額
--         , NULL                                                           AS bm2_electric_amt_tax       -- 【ＢＭ２】電気料(税込)
--         , xbc.bm3_vendor_code                                            AS bm3_vendor_code            -- 【ＢＭ３】仕入先コード
--         , xbc.bm3_vendor_site_code                                       AS bm3_vendor_site_code       -- 【ＢＭ３】仕入先サイトコード
--         , xbc.bm3_bm_payment_type                                        AS bm3_bm_payment_type        -- 【ＢＭ３】BM支払区分
--         , NULL                                                           AS bm3_pct                    -- 【ＢＭ３】BM率(%)
--         , NULL                                                           AS bm3_amt                    -- 【ＢＭ３】BM金額
--         , NULL                                                           AS bm3_cond_bm_tax_pct        -- 【ＢＭ３】条件別手数料額(税込)_率
--         , NULL                                                           AS bm3_cond_bm_amt_tax        -- 【ＢＭ３】条件別手数料額(税込)_額
--         , NULL                                                           AS bm3_electric_amt_tax       -- 【ＢＭ３】電気料(税込)
--         , xbc.item_code                                                  AS item_code                  -- エラー品目コード
--         , xbc.amount_fix_date                                            AS amount_fix_date            -- 金額確定日
--    FROM ( -- 電気料（固定）
--           SELECT /*+ LEADING(xses xseh) */
--                  xseh.sales_base_code                                            AS base_code                  -- 拠点コード
--                , xseh.results_employee_code                                      AS emp_code                   -- 担当者コード
--                , xses.ship_to_customer_code                                      AS ship_cust_code             -- 顧客【納品先】
--                , xses.ship_gyotai_sho                                            AS ship_gyotai_sho            -- 顧客【納品先】業態（小分類）
--                , xses.ship_gyotai_tyu                                            AS ship_gyotai_tyu            -- 顧客【納品先】業態（中分類）
--                , xses.bill_cust_code                                             AS bill_cust_code             -- 顧客【請求先】
--                , xses.period_year                                                AS period_year                -- 会計年度
--                , xses.ship_delivery_chain_code                                   AS ship_delivery_chain_code   -- チェーン店コード
--                , xses.delivery_ym                                                AS delivery_ym                -- 納品日年月
--                , NULL                                                            AS dlv_qty                    -- 納品数量
--                , NULL                                                            AS dlv_uom_code               -- 納品単位
--                , 0                                                               AS amount_inc_tax             -- 売上金額(税込)
--                , NULL                                                            AS container_code             -- 容器区分コード
--                , NULL                                                            AS dlv_unit_price             -- 売価金額
--                , xses.tax_div                                                    AS tax_div                    -- 消費税区分
--                , xses.tax_code                                                   AS tax_code                   -- 税金コード
--                , xses.tax_rate                                                   AS tax_rate                   -- 消費税率
--                , xses.tax_rounding_rule                                          AS tax_rounding_rule          -- 端数処理区分
--                , xses.term_name                                                  AS term_name                  -- 支払条件
--                , xses.closing_date                                               AS closing_date               -- 締め日
--                , xses.expect_payment_date                                        AS expect_payment_date        -- 支払予定日
--                , xses.calc_target_period_from                                    AS calc_target_period_from    -- 計算対象期間(FROM)
--                , xses.calc_target_period_to                                      AS calc_target_period_to      -- 計算対象期間(TO)
--                , xses.calc_type                                                  AS calc_type                  -- 計算条件
--                , xses.bm1_vendor_code                                            AS bm1_vendor_code            -- 【ＢＭ１】仕入先コード
--                , xses.bm1_vendor_site_code                                       AS bm1_vendor_site_code       -- 【ＢＭ１】仕入先サイトコード
--                , xses.bm1_bm_payment_type                                        AS bm1_bm_payment_type        -- 【ＢＭ１】BM支払区分
--                , NULL                                                            AS bm1_pct                    -- 【ＢＭ１】BM率(%)
--                , xses.bm1_amt                                                    AS bm1_amt                    -- 【ＢＭ１】BM金額
--                , NULL                                                            AS bm2_vendor_code            -- 【ＢＭ２】仕入先コード
--                , NULL                                                            AS bm2_vendor_site_code       -- 【ＢＭ２】仕入先サイトコード
--                , NULL                                                            AS bm2_bm_payment_type        -- 【ＢＭ２】BM支払区分
--                , NULL                                                            AS bm2_pct                    -- 【ＢＭ２】BM率(%)
--                , NULL                                                            AS bm2_amt                    -- 【ＢＭ２】BM金額
--                , NULL                                                            AS bm3_vendor_code            -- 【ＢＭ３】仕入先コード
--                , NULL                                                            AS bm3_vendor_site_code       -- 【ＢＭ３】仕入先サイトコード
--                , NULL                                                            AS bm3_bm_payment_type        -- 【ＢＭ３】BM支払区分
--                , NULL                                                            AS bm3_pct                    -- 【ＢＭ３】BM率(%)
--                , NULL                                                            AS bm3_amt                    -- 【ＢＭ３】BM金額
--                , NULL                                                            AS item_code                  -- エラー品目コード
--                , xses.amount_fix_date                                            AS amount_fix_date            -- 金額確定日
--           FROM ( SELECT /*+ LEADING(xt0c xmbc xcbi xseh xsel ) */
--                         MAX( xseh.sales_exp_header_id )            AS sales_exp_header_id           -- 販売実績ヘッダID
--                       , xseh.ship_to_customer_code                 AS ship_to_customer_code         -- 【出荷先】顧客コード
--                       , xt0c.ship_gyotai_tyu                       AS ship_gyotai_tyu               -- 【出荷先】業態（中分類）
--                       , xt0c.ship_gyotai_sho                       AS ship_gyotai_sho               -- 【出荷先】業態（小分類）
--                       , xt0c.ship_delivery_chain_code              AS ship_delivery_chain_code      -- 【出荷先】納品先チェーンコード
--                       , xt0c.bill_cust_code                        AS bill_cust_code                -- 【請求先】顧客コード
--                       , xt0c.bm1_vendor_code                       AS bm1_vendor_code               -- 【ＢＭ１】仕入先コード
--                       , xt0c.bm1_vendor_site_code                  AS bm1_vendor_site_code          -- 【ＢＭ１】仕入先サイトコード
--                       , xt0c.bm1_bm_payment_type                   AS bm1_bm_payment_type           -- 【ＢＭ１】BM支払区分
--                       , xt0c.bm2_vendor_code                       AS bm2_vendor_code               -- 【ＢＭ２】仕入先コード
--                       , xt0c.bm2_vendor_site_code                  AS bm2_vendor_site_code          -- 【ＢＭ２】仕入先サイトコード
--                       , xt0c.bm2_bm_payment_type                   AS bm2_bm_payment_type           -- 【ＢＭ２】BM支払区分
--                       , xt0c.bm3_vendor_code                       AS bm3_vendor_code               -- 【ＢＭ３】仕入先コード
--                       , xt0c.bm3_vendor_site_code                  AS bm3_vendor_site_code          -- 【ＢＭ３】仕入先サイトコード
--                       , xt0c.bm3_bm_payment_type                   AS bm3_bm_payment_type           -- 【ＢＭ３】BM支払区分
--                       , xt0c.tax_div                               AS tax_div                       -- 消費税区分
--                       , xt0c.tax_code                              AS tax_code                      -- 税金コード
--                       , xt0c.tax_rate                              AS tax_rate                      -- 消費税率
--                       , xt0c.tax_rounding_rule                     AS tax_rounding_rule             -- 端数処理区分
--                       , xt0c.receiv_discount_rate                  AS receiv_discount_rate          -- 入金値引率
--                       , xt0c.term_name                             AS term_name                     -- 支払条件
--                       , xt0c.closing_date                          AS closing_date                  -- 締め日
--                       , xt0c.expect_payment_date                   AS expect_payment_date           -- 支払予定日
--                       , xt0c.period_year                           AS period_year                   -- 会計年度
--                       , xt0c.calc_target_period_from               AS calc_target_period_from       -- 計算対象期間(FROM)
--                       , xt0c.calc_target_period_to                 AS calc_target_period_to         -- 計算対象期間(TO)
--                       , NULL                                       AS sales_base_code               -- 売上拠点コード
--                       , NULL                                       AS results_employee_code         -- 成績計上者コード
--                       , TO_CHAR( xseh.delivery_date, 'RRRRMM' )    AS delivery_ym                   -- 納品年月
--                       , NULL                                       AS dlv_qty                       -- 納品数量
--                       , NULL                                       AS dlv_uom_code                  -- 納品単位
--                       , SUM( xsel.pure_amount + xsel.tax_amount )  AS amount_inc_tax                -- 売上金額（税込）
--                       , NULL                                       AS container_code                -- 容器区分コード
--                       , NULL                                       AS dlv_unit_price                -- 売価金額
--                       , NULL                                       AS item_code                     -- 在庫品目コード
--                       , xt0c.amount_fix_date                       AS amount_fix_date               -- 金額確定日
--                       , xmbc.calc_type                             AS calc_type                     -- 計算条件
--                       , xmbc.bm1_amt                               AS bm1_amt                       -- 【ＢＭ１】BM金額
--                  FROM xxcok_tmp_014a01c_custdata    xt0c       -- 条件別販手販協計算顧客情報一時表
--                     , xxcos_sales_exp_headers       xseh       -- 販売実績ヘッダ
--                     , xxcos_sales_exp_lines         xsel       -- 販売実績明細
--                     , xxcok_mst_bm_contract         xmbc       -- 販手条件マスタ
--                     , xxcok_cust_bm_info            xcbi
--                  WHERE xseh.ship_to_customer_code  = xt0c.ship_cust_code
--                    AND xseh.delivery_date         <= xt0c.closing_date
--                    AND xt0c.ship_cust_code         = xcbi.cust_code(+)
--                    AND xseh.delivery_date         >= NVL( xcbi.last_fix_delivery_date, xseh.delivery_date )
--                    AND xseh.sales_exp_header_id    = xsel.sales_exp_header_id
--                    AND xsel.to_calculate_fees_flag = cv_xsel_if_flag_no
--                    AND EXISTS ( SELECT 'X'
--                                 FROM fnd_lookup_values    flv
--                                 WHERE flv.lookup_type             = cv_lookup_type_07  -- 販手計算対象売上区分
--                                   AND flv.lookup_code             = xsel.sales_class
--                                   AND flv.language                = USERENV( 'LANG' )
--                                   AND flv.enabled_flag            = cv_enable
--                                   AND gd_process_date       BETWEEN NVL( flv.start_date_active, gd_process_date )
--                                                                 AND NVL( flv.end_date_active,   gd_process_date )
--                                   AND ROWNUM = 1
--                        )
--                    AND NOT EXISTS ( SELECT 'X'
--                                     FROM fnd_lookup_values             flv2       -- 非在庫品目
--                                     WHERE flv2.lookup_code         = xsel.item_code
--                                       AND flv2.lookup_type         = cv_lookup_type_05
--                                       AND flv2.language            = USERENV( 'LANG' )
--                                       AND flv2.enabled_flag        = cv_enable
--                                       AND gd_process_date       BETWEEN NVL( flv2.start_date_active, gd_process_date )
--                                                                     AND NVL( flv2.end_date_active,   gd_process_date )
--                                       AND ROWNUM = 1
--                        )
---- 2009/10/02 Ver.3.1 [仕様変更I_E_566] SCS K.Yamaguchi REPAIR START
----                    AND xt0c.ship_gyotai_tyu              = cv_gyotai_tyu_vd
--                    AND xt0c.ship_gyotai_sho             IN ( cv_gyotai_sho_25, cv_gyotai_sho_24 )    -- 業態（小分類）：フルサービスVD・フルサービス（消化）VD
---- 2009/10/02 Ver.3.1 [仕様変更I_E_566] SCS K.Yamaguchi REPAIR END
--                    AND xmbc.calc_type                    = cv_calc_type_electricity_cost
--                    AND xmbc.cust_code                    = xseh.ship_to_customer_code
--                    AND xmbc.cust_code                    = xt0c.ship_cust_code
--                    AND xmbc.calc_target_flag             = cv_enable
--                    AND xmbc.container_type_code         IS NULL
--                    AND xmbc.selling_price               IS NULL
--                  GROUP BY xseh.ship_to_customer_code
--                         , xt0c.ship_gyotai_tyu
--                         , xt0c.ship_gyotai_sho
--                         , xt0c.ship_delivery_chain_code
--                         , xt0c.bill_cust_code
--                         , xt0c.bm1_vendor_code
--                         , xt0c.bm1_vendor_site_code
--                         , xt0c.bm1_bm_payment_type
--                         , xt0c.bm2_vendor_code
--                         , xt0c.bm2_vendor_site_code
--                         , xt0c.bm2_bm_payment_type
--                         , xt0c.bm3_vendor_code
--                         , xt0c.bm3_vendor_site_code
--                         , xt0c.bm3_bm_payment_type
--                         , xt0c.tax_div
--                         , xt0c.tax_code
--                         , xt0c.tax_rate
--                         , xt0c.tax_rounding_rule
--                         , xt0c.receiv_discount_rate
--                         , xt0c.term_name
--                         , xt0c.closing_date
--                         , xt0c.expect_payment_date
--                         , xt0c.period_year
--                         , xt0c.calc_target_period_from
--                         , xt0c.calc_target_period_to
--                         , TO_CHAR( xseh.delivery_date, 'RRRRMM' )
--                         , xt0c.amount_fix_date
--                         , xmbc.calc_type
--                         , xmbc.bm1_amt
--                )                           xses      -- インラインビュー・販売実績情報（顧客サマリ）
--              , xxcos_sales_exp_headers     xseh  -- 販売実績ヘッダ
--           WHERE xseh.sales_exp_header_id = xses.sales_exp_header_id
--           UNION ALL
--           -- 電気料（変動）
--           SELECT xses.sales_base_code                                            AS base_code                  -- 拠点コード
--                , xses.results_employee_code                                      AS emp_code                   -- 担当者コード
--                , xses.ship_to_customer_code                                      AS ship_cust_code             -- 顧客【納品先】
--                , xses.ship_gyotai_sho                                            AS ship_gyotai_sho            -- 顧客【納品先】業態（小分類）
--                , xses.ship_gyotai_tyu                                            AS ship_gyotai_tyu            -- 顧客【納品先】業態（中分類）
--                , xses.bill_cust_code                                             AS bill_cust_code             -- 顧客【請求先】
--                , xses.period_year                                                AS period_year                -- 会計年度
--                , xses.ship_delivery_chain_code                                   AS ship_delivery_chain_code   -- チェーン店コード
--                , xses.delivery_ym                                                AS delivery_ym                -- 納品日年月
--                , NULL                                                            AS dlv_qty                    -- 納品数量
--                , NULL                                                            AS dlv_uom_code               -- 納品単位
--                , 0                                                               AS amount_inc_tax             -- 売上金額(税込)
--                , NULL                                                            AS container_code             -- 容器区分コード
--                , NULL                                                            AS dlv_unit_price             -- 売価金額
--                , xses.tax_div                                                    AS tax_div                    -- 消費税区分
--                , xses.tax_code                                                   AS tax_code                   -- 税金コード
--                , xses.tax_rate                                                   AS tax_rate                   -- 消費税率
--                , xses.tax_rounding_rule                                          AS tax_rounding_rule          -- 端数処理区分
--                , xses.term_name                                                  AS term_name                  -- 支払条件
--                , xses.closing_date                                               AS closing_date               -- 締め日
--                , xses.expect_payment_date                                        AS expect_payment_date        -- 支払予定日
--                , xses.calc_target_period_from                                    AS calc_target_period_from    -- 計算対象期間(FROM)
--                , xses.calc_target_period_to                                      AS calc_target_period_to      -- 計算対象期間(TO)
--                , cv_calc_type_electricity_cost                                   AS calc_type                  -- 計算条件
--                , xses.bm1_vendor_code                                            AS bm1_vendor_code            -- 【ＢＭ１】仕入先コード
--                , xses.bm1_vendor_site_code                                       AS bm1_vendor_site_code       -- 【ＢＭ１】仕入先サイトコード
--                , xses.bm1_bm_payment_type                                        AS bm1_bm_payment_type        -- 【ＢＭ１】BM支払区分
--                , NULL                                                            AS bm1_pct                    -- 【ＢＭ１】BM率(%)
--                , xses.amount_inc_tax                                             AS bm1_amt                    -- 【ＢＭ１】BM金額
--                , NULL                                                            AS bm2_vendor_code            -- 【ＢＭ２】仕入先コード
--                , NULL                                                            AS bm2_vendor_site_code       -- 【ＢＭ２】仕入先サイトコード
--                , NULL                                                            AS bm2_bm_payment_type        -- 【ＢＭ２】BM支払区分
--                , NULL                                                            AS bm2_pct                    -- 【ＢＭ２】BM率(%)
--                , NULL                                                            AS bm2_amt                    -- 【ＢＭ２】BM金額
--                , NULL                                                            AS bm3_vendor_code            -- 【ＢＭ３】仕入先コード
--                , NULL                                                            AS bm3_vendor_site_code       -- 【ＢＭ３】仕入先サイトコード
--                , NULL                                                            AS bm3_bm_payment_type        -- 【ＢＭ３】BM支払区分
--                , NULL                                                            AS bm3_pct                    -- 【ＢＭ３】BM率(%)
--                , NULL                                                            AS bm3_amt                    -- 【ＢＭ３】BM金額
--                , NULL                                                            AS item_code                  -- エラー品目コード
--                , xses.amount_fix_date                                            AS amount_fix_date            -- 金額確定日
--           FROM ( SELECT xseh.ship_to_customer_code                 AS ship_to_customer_code         -- 【出荷先】顧客コード
--                       , xt0c.ship_gyotai_tyu                       AS ship_gyotai_tyu               -- 【出荷先】業態（中分類）
--                       , xt0c.ship_gyotai_sho                       AS ship_gyotai_sho               -- 【出荷先】業態（小分類）
--                       , xt0c.ship_delivery_chain_code              AS ship_delivery_chain_code      -- 【出荷先】納品先チェーンコード
--                       , xt0c.bill_cust_code                        AS bill_cust_code                -- 【請求先】顧客コード
--                       , xt0c.bm1_vendor_code                       AS bm1_vendor_code               -- 【ＢＭ１】仕入先コード
--                       , xt0c.bm1_vendor_site_code                  AS bm1_vendor_site_code          -- 【ＢＭ１】仕入先サイトコード
--                       , xt0c.bm1_bm_payment_type                   AS bm1_bm_payment_type           -- 【ＢＭ１】BM支払区分
--                       , xt0c.bm2_vendor_code                       AS bm2_vendor_code               -- 【ＢＭ２】仕入先コード
--                       , xt0c.bm2_vendor_site_code                  AS bm2_vendor_site_code          -- 【ＢＭ２】仕入先サイトコード
--                       , xt0c.bm2_bm_payment_type                   AS bm2_bm_payment_type           -- 【ＢＭ２】BM支払区分
--                       , xt0c.bm3_vendor_code                       AS bm3_vendor_code               -- 【ＢＭ３】仕入先コード
--                       , xt0c.bm3_vendor_site_code                  AS bm3_vendor_site_code          -- 【ＢＭ３】仕入先サイトコード
--                       , xt0c.bm3_bm_payment_type                   AS bm3_bm_payment_type           -- 【ＢＭ３】BM支払区分
--                       , xt0c.tax_div                               AS tax_div                       -- 消費税区分
--                       , xt0c.tax_code                              AS tax_code                      -- 税金コード
--                       , xt0c.tax_rate                              AS tax_rate                      -- 消費税率
--                       , xt0c.tax_rounding_rule                     AS tax_rounding_rule             -- 端数処理区分
--                       , xt0c.receiv_discount_rate                  AS receiv_discount_rate          -- 入金値引率
--                       , xt0c.term_name                             AS term_name                     -- 支払条件
--                       , xt0c.closing_date                          AS closing_date                  -- 締め日
--                       , xt0c.expect_payment_date                   AS expect_payment_date           -- 支払予定日
--                       , xt0c.period_year                           AS period_year                   -- 会計年度
--                       , xt0c.calc_target_period_from               AS calc_target_period_from       -- 計算対象期間(FROM)
--                       , xt0c.calc_target_period_to                 AS calc_target_period_to         -- 計算対象期間(TO)
--                       , xseh.sales_base_code                       AS sales_base_code               -- 売上拠点コード
--                       , xseh.results_employee_code                 AS results_employee_code         -- 成績計上者コード
--                       , TO_CHAR( xseh.delivery_date, 'RRRRMM' )    AS delivery_ym                   -- 納品年月
--                       , NULL                                       AS dlv_qty                       -- 納品数量
--                       , NULL                                       AS dlv_uom_code                  -- 納品単位
--                       , SUM( xsel.pure_amount + xsel.tax_amount )  AS amount_inc_tax                -- 売上金額（税込）
--                       , NULL                                       AS container_code                -- 容器区分コード
--                       , NULL                                       AS dlv_unit_price                -- 売価金額
--                       , NULL                                       AS item_code                     -- 在庫品目コード
--                       , xt0c.amount_fix_date                       AS amount_fix_date               -- 金額確定日
--                  FROM xxcok_tmp_014a01c_custdata    xt0c       -- 条件別販手販協計算顧客情報一時表
--                     , xxcos_sales_exp_headers       xseh       -- 販売実績ヘッダ
--                     , xxcos_sales_exp_lines         xsel       -- 販売実績明細
--                     , xxcmm_system_items_b          xsim       -- Disc品目アドオン
--                     , xxcok_cust_bm_info            xcbi
--                  WHERE xseh.ship_to_customer_code  = xt0c.ship_cust_code
--                    AND xseh.delivery_date         <= xt0c.closing_date
--                    AND xt0c.ship_cust_code         = xcbi.cust_code(+)
--                    AND xseh.delivery_date         >= NVL( xcbi.last_fix_delivery_date, xseh.delivery_date )
--                    AND xseh.sales_exp_header_id    = xsel.sales_exp_header_id
--                    AND xsel.to_calculate_fees_flag = cv_xsel_if_flag_no
--                    AND EXISTS ( SELECT 'X'
--                                 FROM fnd_lookup_values    flv
--                                 WHERE flv.lookup_type             = cv_lookup_type_07  -- 販手計算対象売上区分
--                                   AND flv.lookup_code             = xsel.sales_class
--                                   AND flv.language                = USERENV( 'LANG' )
--                                   AND flv.enabled_flag            = cv_enable
--                                   AND gd_process_date       BETWEEN NVL( flv.start_date_active, gd_process_date )
--                                                                 AND NVL( flv.end_date_active,   gd_process_date )
--                                   AND ROWNUM = 1
--                        )
--                    AND xsim.item_code              = xsel.item_code
--                    AND xsel.item_code              = gv_elec_change_item_code
--                  GROUP BY xseh.ship_to_customer_code
--                         , xt0c.ship_gyotai_tyu
--                         , xt0c.ship_gyotai_sho
--                         , xt0c.ship_delivery_chain_code
--                         , xt0c.bill_cust_code
--                         , xt0c.bm1_vendor_code
--                         , xt0c.bm1_vendor_site_code
--                         , xt0c.bm1_bm_payment_type
--                         , xt0c.bm2_vendor_code
--                         , xt0c.bm2_vendor_site_code
--                         , xt0c.bm2_bm_payment_type
--                         , xt0c.bm3_vendor_code
--                         , xt0c.bm3_vendor_site_code
--                         , xt0c.bm3_bm_payment_type
--                         , xt0c.tax_div
--                         , xt0c.tax_code
--                         , xt0c.tax_rate
--                         , xt0c.tax_rounding_rule
--                         , xt0c.receiv_discount_rate
--                         , xt0c.term_name
--                         , xt0c.closing_date
--                         , xt0c.expect_payment_date
--                         , xt0c.period_year
--                         , xt0c.calc_target_period_from
--                         , xt0c.calc_target_period_to
--                         , xseh.sales_base_code
--                         , xseh.results_employee_code
--                         , TO_CHAR( xseh.delivery_date, 'RRRRMM' )
--                         , xt0c.amount_fix_date
--                )                           xses      -- インラインビュー・販売実績情報（顧客サマリ）
--         )                        xbc
--    GROUP BY xbc.base_code
--           , xbc.emp_code
--           , xbc.ship_cust_code
--           , xbc.ship_gyotai_sho
--           , xbc.ship_gyotai_tyu
--           , xbc.bill_cust_code
--           , xbc.period_year
--           , xbc.ship_delivery_chain_code
--           , xbc.delivery_ym
--           , xbc.dlv_qty
--           , xbc.dlv_uom_code
--           , xbc.amount_inc_tax
--           , xbc.container_code
--           , xbc.dlv_unit_price
--           , xbc.tax_div
--           , xbc.tax_code
--           , xbc.tax_rate
--           , xbc.tax_rounding_rule
--           , xbc.term_name
--           , xbc.closing_date
--           , xbc.expect_payment_date
--           , xbc.calc_target_period_from
--           , xbc.calc_target_period_to
--           , xbc.calc_type
--           , xbc.bm1_vendor_code
--           , xbc.bm1_vendor_site_code
--           , xbc.bm1_bm_payment_type
--           , xbc.bm1_pct
--           , xbc.bm1_amt
--           , xbc.bm2_vendor_code
--           , xbc.bm2_vendor_site_code
--           , xbc.bm2_bm_payment_type
--           , xbc.bm2_pct
--           , xbc.bm2_amt
--           , xbc.bm3_vendor_code
--           , xbc.bm3_vendor_site_code
--           , xbc.bm3_bm_payment_type
--           , xbc.bm3_pct
--           , xbc.bm3_amt
--           , xbc.item_code
--           , xbc.amount_fix_date
--  ;
-- 2010/03/16 Ver.3.9 [E_本稼動_01896] SCS K.Yamaguchi REPAIR START
--  -- 販売実績情報・電気料
--  CURSOR get_sales_data_cur5 IS
--    SELECT xses.base_code                    AS base_code                  -- 拠点コード
--         , xses.emp_code                     AS emp_code                   -- 担当者コード
--         , xses.ship_cust_code               AS ship_cust_code             -- 顧客【納品先】
--         , xses.ship_gyotai_sho              AS ship_gyotai_sho            -- 顧客【納品先】業態（小分類）
--         , xses.ship_gyotai_tyu              AS ship_gyotai_tyu            -- 顧客【納品先】業態（中分類）
--         , xses.bill_cust_code               AS bill_cust_code             -- 顧客【請求先】
--         , xses.period_year                  AS period_year                -- 会計年度
--         , xses.ship_delivery_chain_code     AS ship_delivery_chain_code   -- チェーン店コード
--         , xses.delivery_ym                  AS delivery_ym                -- 納品日年月
--         , xses.dlv_qty                      AS dlv_qty                    -- 納品数量
--         , xses.dlv_uom_code                 AS dlv_uom_code               -- 納品単位
--         , xses.amount_inc_tax               AS amount_inc_tax             -- 売上金額(税込)
--         , xses.container_code               AS container_code             -- 容器区分コード
--         , xses.dlv_unit_price               AS dlv_unit_price             -- 売価金額
--         , xses.tax_div                      AS tax_div                    -- 消費税区分
--         , xses.tax_code                     AS tax_code                   -- 税金コード
--         , xses.tax_rate                     AS tax_rate                   -- 消費税率
--         , xses.tax_rounding_rule            AS tax_rounding_rule          -- 端数処理区分
--         , xses.term_name                    AS term_name                  -- 支払条件
--         , xses.closing_date                 AS closing_date               -- 締め日
--         , xses.expect_payment_date          AS expect_payment_date        -- 支払予定日
--         , xses.calc_target_period_from      AS calc_target_period_from    -- 計算対象期間(FROM)
--         , xses.calc_target_period_to        AS calc_target_period_to      -- 計算対象期間(TO)
--         , xses.calc_type                    AS calc_type                  -- 計算条件
--         , xses.bm1_vendor_code              AS bm1_vendor_code            -- 【ＢＭ１】仕入先コード
--         , xses.bm1_vendor_site_code         AS bm1_vendor_site_code       -- 【ＢＭ１】仕入先サイトコード
--         , xses.bm1_bm_payment_type          AS bm1_bm_payment_type        -- 【ＢＭ１】BM支払区分
--         , xses.bm1_pct                      AS bm1_pct                    -- 【ＢＭ１】BM率(%)
--         , NULL                              AS bm1_amt                    -- 【ＢＭ１】BM金額
--         , NULL                              AS bm1_cond_bm_tax_pct        -- 【ＢＭ１】条件別手数料額(税込)_率
--         , NULL                              AS bm1_cond_bm_amt_tax        -- 【ＢＭ１】条件別手数料額(税込)_額
--         , xses.bm1_amt -- 変動電気料
--         + NVL( ( SELECT xmbc.bm1_amt
--                  FROM xxcok_mst_bm_contract     xmbc
--                  WHERE xmbc.calc_type               = cv_calc_type_electricity_cost  -- 計算条件：電気代
--                    AND xmbc.cust_code               = xses.ship_cust_code
--                    AND xmbc.calc_target_flag        = cv_enable
--                )       -- 固定電気料
--                , 0
--           )                                 AS bm1_electric_amt_tax       -- 【ＢＭ１】電気料(税込)
--         , xses.bm2_vendor_code              AS bm2_vendor_code            -- 【ＢＭ２】仕入先コード
--         , xses.bm2_vendor_site_code         AS bm2_vendor_site_code       -- 【ＢＭ２】仕入先サイトコード
--         , xses.bm2_bm_payment_type          AS bm2_bm_payment_type        -- 【ＢＭ２】BM支払区分
--         , xses.bm2_pct                      AS bm2_pct                    -- 【ＢＭ２】BM率(%)
--         , xses.bm2_amt                      AS bm2_amt                    -- 【ＢＭ２】BM金額
--         , NULL                              AS bm2_cond_bm_tax_pct        -- 【ＢＭ２】条件別手数料額(税込)_率
--         , NULL                              AS bm2_cond_bm_amt_tax        -- 【ＢＭ２】条件別手数料額(税込)_額
--         , NULL                              AS bm2_electric_amt_tax       -- 【ＢＭ２】電気料(税込)
--         , xses.bm3_vendor_code              AS bm3_vendor_code            -- 【ＢＭ３】仕入先コード
--         , xses.bm3_vendor_site_code         AS bm3_vendor_site_code       -- 【ＢＭ３】仕入先サイトコード
--         , xses.bm3_bm_payment_type          AS bm3_bm_payment_type        -- 【ＢＭ３】BM支払区分
--         , xses.bm3_pct                      AS bm3_pct                    -- 【ＢＭ３】BM率(%)
--         , xses.bm3_amt                      AS bm3_amt                    -- 【ＢＭ３】BM金額
--         , NULL                              AS bm3_cond_bm_tax_pct        -- 【ＢＭ３】条件別手数料額(税込)_率
--         , NULL                              AS bm3_cond_bm_amt_tax        -- 【ＢＭ３】条件別手数料額(税込)_額
--         , NULL                              AS bm3_electric_amt_tax       -- 【ＢＭ３】電気料(税込)
--         , xses.item_code                    AS item_code                  -- エラー品目コード
--         , xses.amount_fix_date              AS amount_fix_date            -- 金額確定日
--    FROM ( SELECT /*+
--                    LEADING( xt0c, xcbi )
--                    INDEX( xcbi XXCOK_CUST_BM_INFO_U01 )
--                  */
--                  CASE
--                    WHEN   TRUNC( xt0c.closing_date, 'MM' )
--                         = TRUNC( gd_process_date  , 'MM' )
--                    THEN
--                      xca.sale_base_code
--                    ELSE
--                      xca.past_sale_base_code
--                  END                                        AS base_code                  -- 拠点コード
---- 2010/02/19 Ver.3.8 [障害E_本稼動_01446] SCS S.Moriyama REPAIR START
----                , xxcok_common_pkg.get_sales_staff_code_f(
----                    xseh.ship_to_customer_code
----                  , xt0c.closing_date
----                  )                                          AS emp_code                   -- 担当者コード
--                , xt0c.emp_code                              AS emp_code                   -- 担当者コード
---- 2010/02/19 Ver.3.8 [障害E_本稼動_01446] SCS S.Moriyama REPAIR END
--                , xseh.ship_to_customer_code                 AS ship_cust_code             -- 顧客【納品先】
--                , xt0c.ship_gyotai_sho                       AS ship_gyotai_sho            -- 顧客【納品先】業態（小分類
--                , xt0c.ship_gyotai_tyu                       AS ship_gyotai_tyu            -- 顧客【納品先】業態（中分類
--                , xt0c.bill_cust_code                        AS bill_cust_code             -- 顧客【請求先】
--                , xt0c.period_year                           AS period_year                -- 会計年度
--                , xt0c.ship_delivery_chain_code              AS ship_delivery_chain_code   -- チェーン店コード
---- 2009/12/21 Ver.3.6 [E_本稼動_00460] SCS K.Yamaguchi REPAIR START
----                , TO_CHAR( xseh.delivery_date, 'RRRRMM' )    AS delivery_ym                -- 納品日年月
--                , TO_CHAR( xt0c.closing_date, 'RRRRMM' )     AS delivery_ym                -- 納品日年月
---- 2009/12/21 Ver.3.6 [E_本稼動_00460] SCS K.Yamaguchi REPAIR END
--                , NULL                                       AS dlv_qty                    -- 納品数量
--                , NULL                                       AS dlv_uom_code               -- 納品単位
--                , SUM( CASE
--                         WHEN EXISTS ( SELECT 'X'
--                                       FROM xxcok_mst_bm_contract     xmbc
--                                       WHERE xmbc.cust_code               = xt0c.ship_cust_code
--                                         AND xmbc.calc_target_flag        = cv_enable
--                                         AND xmbc.calc_type              IN ( cv_calc_type_sales_price
--                                                                            , cv_calc_type_container
--                                                                            , cv_calc_type_uniform_rate
--                                                                            , cv_calc_type_flat_rate
--                                                                            )
--                                         AND ROWNUM = 1
--                              )
--                         THEN
--                           0
--                         WHEN EXISTS ( SELECT 'X'
--                                       FROM fnd_lookup_values flv -- 非在庫品目
--                                       WHERE flv.lookup_type         = cv_lookup_type_05         -- 参照タイプ：非在庫品目
--                                         AND flv.lookup_code         = xsel.item_code
--                                         AND flv.language            = cv_lang
--                                         AND flv.enabled_flag        = cv_enable
--                                         AND gd_process_date   BETWEEN NVL( flv.start_date_active, gd_process_date )
--                                                                   AND NVL( flv.end_date_active  , gd_process_date )
--                                         AND ROWNUM = 1
--                             )
--                         THEN
--                           0
--                         ELSE
--                           xsel.pure_amount + xsel.tax_amount
--                       END
--                  )                                          AS amount_inc_tax             -- 売上金額(税込)
--                , NULL                                       AS container_code             -- 容器区分コード
--                , NULL                                       AS dlv_unit_price             -- 売価金額
--                , xt0c.tax_div                               AS tax_div                    -- 消費税区分
--                , xt0c.tax_code                              AS tax_code                   -- 税金コード
--                , xt0c.tax_rate                              AS tax_rate                   -- 消費税率
--                , xt0c.tax_rounding_rule                     AS tax_rounding_rule          -- 端数処理区分
--                , xt0c.term_name                             AS term_name                  -- 支払条件
--                , xt0c.closing_date                          AS closing_date               -- 締め日
--                , xt0c.expect_payment_date                   AS expect_payment_date        -- 支払予定日
--                , xt0c.calc_target_period_from               AS calc_target_period_from    -- 計算対象期間(FROM)
--                , xt0c.calc_target_period_to                 AS calc_target_period_to      -- 計算対象期間(TO)
--                , cv_calc_type_electricity_cost              AS calc_type                  -- 計算条件
--                , xt0c.bm1_vendor_code                       AS bm1_vendor_code            -- 【ＢＭ１】仕入先コード
--                , xt0c.bm1_vendor_site_code                  AS bm1_vendor_site_code       -- 【ＢＭ１】仕入先サイトコード
--                , xt0c.bm1_bm_payment_type                   AS bm1_bm_payment_type        -- 【ＢＭ１】BM支払区分
--                , NULL                                       AS bm1_pct                    -- 【ＢＭ１】BM率(%)
--                , SUM( CASE
--                         WHEN xsel.item_code = gv_elec_change_item_code THEN
--                           xsel.pure_amount + xsel.tax_amount
--                         ELSE
--                           0
--                       END
--                  )                                          AS bm1_amt                    -- 【ＢＭ１】BM金額
--                , NULL                                       AS bm2_vendor_code            -- 【ＢＭ２】仕入先コード
--                , NULL                                       AS bm2_vendor_site_code       -- 【ＢＭ２】仕入先サイトコード
--                , NULL                                       AS bm2_bm_payment_type        -- 【ＢＭ２】BM支払区分
--                , NULL                                       AS bm2_pct                    -- 【ＢＭ２】BM率(%)
--                , NULL                                       AS bm2_amt                    -- 【ＢＭ２】BM金額
--                , NULL                                       AS bm3_vendor_code            -- 【ＢＭ３】仕入先コード
--                , NULL                                       AS bm3_vendor_site_code       -- 【ＢＭ３】仕入先サイトコード
--                , NULL                                       AS bm3_bm_payment_type        -- 【ＢＭ３】BM支払区分
--                , NULL                                       AS bm3_pct                    -- 【ＢＭ３】BM率(%)
--                , NULL                                       AS bm3_amt                    -- 【ＢＭ３】BM金額
--                , NULL                                       AS item_code                  -- エラー品目コード
--                , xt0c.amount_fix_date                       AS amount_fix_date            -- 金額確定日
--           FROM xxcok_tmp_014a01c_custdata    xt0c       -- 条件別販手販協計算顧客情報一時表
--              , xxcos_sales_exp_headers       xseh       -- 販売実績ヘッダ
--              , xxcos_sales_exp_lines         xsel       -- 販売実績明細
--              , xxcok_cust_bm_info            xcbi
--              , hz_cust_accounts              hca
--              , xxcmm_cust_accounts           xca
--           WHERE xseh.ship_to_customer_code  = xt0c.ship_cust_code
--             AND xseh.delivery_date         <= xt0c.closing_date
--             AND xt0c.ship_gyotai_sho       IN ( cv_gyotai_sho_25, cv_gyotai_sho_24 )
--             AND xt0c.ship_cust_code         = xcbi.cust_code(+)
--             AND xt0c.ship_cust_code         = hca.account_number
--             AND hca.cust_account_id         = xca.customer_id
--             AND xseh.delivery_date         >= NVL( xcbi.last_fix_delivery_date, xseh.delivery_date )
--             AND xseh.sales_exp_header_id    = xsel.sales_exp_header_id
--             AND xsel.to_calculate_fees_flag = cv_xsel_if_flag_no
--             AND EXISTS ( SELECT 'X'
--                          FROM fnd_lookup_values    flv
--                          WHERE flv.lookup_type             = cv_lookup_type_07  -- 販手計算対象売上区分
--                            AND flv.lookup_code             = xsel.sales_class
--                            AND flv.language                = USERENV( 'LANG' )
--                            AND flv.enabled_flag            = cv_enable
--                            AND gd_process_date       BETWEEN NVL( flv.start_date_active, gd_process_date )
--                                                          AND NVL( flv.end_date_active,   gd_process_date )
--                            AND ROWNUM = 1
--                 )
--             AND (    ( EXISTS ( SELECT 'X'
--                                 FROM xxcos_sales_exp_headers   xseh2
--                                    , xxcos_sales_exp_lines     xsel2
--                                 WHERE xseh2.sales_exp_header_id    = xsel2.sales_exp_header_id
--                                   AND xseh2.ship_to_customer_code  = xt0c.ship_cust_code
--                                   AND xseh2.delivery_date         >= NVL( xcbi.last_fix_delivery_date, xseh2.delivery_date )
--                                   AND xsel2.to_calculate_fees_flag = cv_xsel_if_flag_no
--                                   AND xsel2.item_code              = gv_elec_change_item_code -- 変動電気代
--                                   AND ROWNUM = 1
--                        )
--                      )
--                   OR ( EXISTS ( SELECT 'X'
--                                 FROM xxcok_mst_bm_contract     xmbc
--                                 WHERE xmbc.calc_type               = cv_calc_type_electricity_cost  -- 計算条件：電気代
--                                   AND xmbc.cust_code               = xt0c.ship_cust_code
--                                   AND xmbc.calc_target_flag        = cv_enable
--                                   AND ROWNUM = 1
--                        )
--                      )
--                 )
--           GROUP BY CASE
--                      WHEN   TRUNC( xt0c.closing_date, 'MM' )
--                           = TRUNC( gd_process_date  , 'MM' )
--                      THEN
--                        xca.sale_base_code
--                      ELSE
--                        xca.past_sale_base_code
--                    END
---- 2010/02/19 Ver.3.8 [障害E_本稼動_01446] SCS S.Moriyama ADD START
--                  , xt0c.emp_code
---- 2010/02/19 Ver.3.8 [障害E_本稼動_01446] SCS S.Moriyama ADD END
--                  , xseh.ship_to_customer_code
--                  , xt0c.ship_gyotai_sho
--                  , xt0c.ship_gyotai_tyu
--                  , xt0c.bill_cust_code
--                  , xt0c.period_year
--                  , xt0c.ship_delivery_chain_code
---- 2009/12/21 Ver.3.6 [E_本稼動_00460] SCS K.Yamaguchi DELETE START
----                  , TO_CHAR( xseh.delivery_date, 'RRRRMM' )
---- 2009/12/21 Ver.3.6 [E_本稼動_00460] SCS K.Yamaguchi DELETE END
--                  , xt0c.tax_div
--                  , xt0c.tax_code
--                  , xt0c.tax_rate
--                  , xt0c.tax_rounding_rule
--                  , xt0c.term_name
--                  , xt0c.closing_date
--                  , xt0c.expect_payment_date
--                  , xt0c.calc_target_period_from
--                  , xt0c.calc_target_period_to
--                  , xt0c.bm1_vendor_code
--                  , xt0c.bm1_vendor_site_code
--                  , xt0c.bm1_bm_payment_type
--                  , xt0c.amount_fix_date
--         ) xses
--  ;
  -- 販売実績情報・電気料
  CURSOR get_sales_data_cur5 IS
    SELECT /*+
-- 2012/10/01 Ver.3.16 [E_本稼動_10133] SCSK K.Kiriu REPAIR START
--             LEADING( xt0c hca xca xcbi xmbc )
             LEADING( xt0c hca xca xcbi xseh xsel )
             USE_NL( xt0c hca xca xcbi xseh xsel )
             INDEX( xseh XXCOS_SALES_EXP_HEADERS_N08 )
-- 2012/10/01 Ver.3.16 [E_本稼動_10133] SCSK K.Kiriu REPAIR END
           */
           CASE
             WHEN TRUNC( xt0c.closing_date, 'MM' ) = TRUNC( gd_process_date, 'MM' ) THEN
               xca.sale_base_code
             ELSE
               xca.past_sale_base_code
           END                                    AS base_code                -- 拠点コード
         , xt0c.emp_code                          AS emp_code                 -- 担当者コード
         , xt0c.ship_cust_code                    AS ship_cust_code           -- 顧客【納品先】
         , xt0c.ship_gyotai_sho                   AS ship_gyotai_sho          -- 顧客【納品先】業態（小分類）
         , xt0c.ship_gyotai_tyu                   AS ship_gyotai_tyu          -- 顧客【納品先】業態（中分類）
         , xt0c.bill_cust_code                    AS bill_cust_code           -- 顧客【請求先】
         , xt0c.period_year                       AS period_year              -- 会計年度
         , xt0c.ship_delivery_chain_code          AS ship_delivery_chain_code -- チェーン店コード
         , TO_CHAR( xt0c.closing_date, 'RRRRMM' ) AS delivery_ym              -- 納品日年月
         , NULL                                   AS dlv_qty                  -- 納品数量
         , NULL                                   AS dlv_uom_code             -- 納品単位
-- 2010/12/13 Ver.3.12 [E_本稼動_01896] SCS S.Niki REPAIR START
-- 2012/02/23 Ver.3.14 [E_本稼動_09144] SCSK S.Niki REPAIR START
         , CASE
             WHEN EXISTS ( SELECT 'X'
                           FROM xxcok_mst_bm_contract     xmbc   -- 販手条件マスタ
                           WHERE xmbc.cust_code               = xt0c.ship_cust_code
                             AND xmbc.calc_target_flag        = cv_enable
                             AND xmbc.calc_type              IN ( cv_calc_type_sales_price    -- 売価別条件
                                                                , cv_calc_type_container      -- 容器区分別条件
                                                                , cv_calc_type_uniform_rate   -- 一律条件
                                                                , cv_calc_type_flat_rate      -- 定額
                                                                )
                             AND ROWNUM = 1
                  )
             THEN
               0
             ELSE
               ( SELECT NVL( SUM( xsel.pure_amount + xsel.tax_amount ), 0 )
                 FROM xxcos_sales_exp_headers     xseh  -- 販売実績ヘッダ
                    , xxcos_sales_exp_lines       xsel  -- 販売実績明細
                 WHERE xseh.ship_to_customer_code  = xt0c.ship_cust_code
                   AND xseh.delivery_date         <= xt0c.closing_date
                   AND xseh.delivery_date         >= NVL( xcbi.last_fix_delivery_date, xseh.delivery_date )
                   AND xseh.sales_exp_header_id    = xsel.sales_exp_header_id
                   AND xsel.to_calculate_fees_flag = cv_xsel_if_flag_no
                   AND EXISTS ( SELECT  'X'
                                FROM fnd_lookup_values flv -- 販手計算対象売上区分
                                WHERE flv.lookup_type         = cv_lookup_type_07             -- 参照タイプ：販手計算対象売上区分
                                  AND flv.lookup_code         = xsel.sales_class
                                  AND flv.language            = cv_lang
                                  AND flv.enabled_flag        = cv_enable
                                  AND gd_process_date   BETWEEN NVL( flv.start_date_active, gd_process_date )
                                                            AND NVL( flv.end_date_active  , gd_process_date )
                                  AND ROWNUM = 1
                       )
                   AND NOT EXISTS ( SELECT 'X'
                                    FROM fnd_lookup_values flv -- 非在庫品目
                                    WHERE flv.lookup_type         = cv_lookup_type_05         -- 参照タイプ：非在庫品目
                                      AND flv.lookup_code         = xsel.item_code
                                      AND flv.language            = cv_lang
                                      AND flv.enabled_flag        = cv_enable
                                      AND gd_process_date   BETWEEN NVL( flv.start_date_active, gd_process_date )
                                                                AND NVL( flv.end_date_active  , gd_process_date )
                                      AND ROWNUM = 1
                       )
               )
           END                           AS amount_inc_tax           -- 売上金額（税込）
--        , SUM(
--            CASE
--              WHEN EXISTS ( SELECT 'X'
--                            FROM xxcok_mst_bm_contract     xmbc
--                            WHERE xmbc.cust_code               = xt0c.ship_cust_code
--                              AND xmbc.calc_target_flag        = cv_enable
--                              AND xmbc.calc_type              IN ( cv_calc_type_sales_price
--                                                                 , cv_calc_type_container
--                                                                 , cv_calc_type_uniform_rate
--                                                                 , cv_calc_type_flat_rate
--                                                                 )
--                              AND ROWNUM = 1
--                   )
--              THEN
--                0
--              ELSE
--                NVL( xsel.pure_amount + xsel.tax_amount, 0 )
--            END
--          )                             AS amount_inc_tax           -- 売上金額（税込）
-- 2012/02/23 Ver.3.14 [E_本稼動_09144] SCSK S.Niki REPAIR END
-- 2010/12/13 Ver.3.12 [E_本稼動_01896] SCS S.Niki REPAIR END
         , NULL                          AS container_code           -- 容器区分コード
         , NULL                          AS dlv_unit_price           -- 売価金額
         , xt0c.tax_div                  AS tax_div                  -- 消費税区分
         , xt0c.tax_code                 AS tax_code                 -- 税金コード
         , xt0c.tax_rate                 AS tax_rate                 -- 消費税率
         , xt0c.tax_rounding_rule        AS tax_rounding_rule        -- 端数処理区分
         , xt0c.term_name                AS term_name                -- 支払条件
         , xt0c.closing_date             AS closing_date             -- 締め日
         , xt0c.expect_payment_date      AS expect_payment_date      -- 支払予定日
         , xt0c.calc_target_period_from  AS calc_target_period_from  -- 計算対象期間(FROM)
         , xt0c.calc_target_period_to    AS calc_target_period_to    -- 計算対象期間(TO)
         , cv_calc_type_electricity_cost AS calc_type                -- 計算条件
         , xt0c.bm1_vendor_code          AS bm1_vendor_code          -- 【ＢＭ１】仕入先コード
         , xt0c.bm1_vendor_site_code     AS bm1_vendor_site_code     -- 【ＢＭ１】仕入先サイトコード
         , xt0c.bm1_bm_payment_type      AS bm1_bm_payment_type      -- 【ＢＭ１】BM支払区分
         , NULL                          AS bm1_pct                  -- 【ＢＭ１】BM率(%)
         , NULL                          AS bm1_amt                  -- 【ＢＭ１】BM金額
         , NULL                          AS bm1_cond_bm_tax_pct      -- 【ＢＭ１】条件別手数料額(税込)_率
         , NULL                          AS bm1_cond_bm_amt_tax      -- 【ＢＭ１】条件別手数料額(税込)_額
         , NVL( ( SELECT SUM( xsel.pure_amount + xsel.tax_amount )  -- 変動電気料
                  FROM xxcos_sales_exp_headers     xseh  -- 販売実績ヘッダ
                     , xxcos_sales_exp_lines       xsel  -- 販売実績明細
                  WHERE xseh.ship_to_customer_code  = xt0c.ship_cust_code
                    AND xseh.delivery_date         <= xt0c.closing_date
-- 2010/12/13 Ver.3.12 [E_本稼動_01844] SCS S.Niki ADD START
                    AND xseh.business_date         <= gd_process_date
-- 2010/12/13 Ver.3.12 [E_本稼動_01844] SCS S.Niki ADD END
                    AND xseh.delivery_date         >= NVL( xcbi.last_fix_delivery_date, xseh.delivery_date )
                    AND xseh.sales_exp_header_id    = xsel.sales_exp_header_id
                    AND xsel.to_calculate_fees_flag = cv_xsel_if_flag_no
                    AND EXISTS ( SELECT  'X'
                                 FROM fnd_lookup_values flv -- 販手計算対象売上区分
                                 WHERE flv.lookup_type         = cv_lookup_type_07             -- 参照タイプ：販手計算対象売上区分
                                   AND flv.lookup_code         = xsel.sales_class
                                   AND flv.language            = cv_lang
                                   AND flv.enabled_flag        = cv_enable
                                   AND gd_process_date   BETWEEN NVL( flv.start_date_active, gd_process_date )
                                                             AND NVL( flv.end_date_active  , gd_process_date )
                                   AND ROWNUM = 1
                        )
                    AND xsel.item_code              = gv_elec_change_item_code
                )
              , 0
           )
         + NVL( ( SELECT xmbc.bm1_amt       -- 固定電気料
                  FROM xxcok_mst_bm_contract     xmbc
-- 2011/03/23 Ver.3.13 [E_本稼動_06757] SCS M.Watanabe ADD START
                      ,xxcos_sales_exp_headers   xseh  -- 販売実績ヘッダ
                      ,xxcos_sales_exp_lines     xsel  -- 販売実績明細
-- 2011/03/23 Ver.3.13 [E_本稼動_06757] SCS M.Watanabe ADD END
                  WHERE xmbc.calc_type               = cv_calc_type_electricity_cost  -- 計算条件：電気代
                    AND xmbc.cust_code               = xt0c.ship_cust_code
                    AND xmbc.calc_target_flag        = cv_enable
-- 2011/04/01 Ver.3.13 [E_本稼動_06757] SCS M.Watanabe ADD START
                    AND xseh.ship_to_customer_code   = xmbc.cust_code
                    AND xseh.delivery_date          <= xt0c.closing_date
                    AND xseh.delivery_date          >= NVL( xcbi.last_fix_delivery_date, xseh.delivery_date )
                    AND xseh.business_date          <= gd_process_date
                    AND xseh.sales_exp_header_id     = xsel.sales_exp_header_id
                    AND xsel.to_calculate_fees_flag  = cv_xsel_if_flag_no
                    AND EXISTS ( SELECT  'X'
                                 FROM fnd_lookup_values flv -- 販手計算対象売上区分
                                 WHERE flv.lookup_type         = cv_lookup_type_07             -- 参照タイプ：販手計算対象売上区分
                                   AND flv.lookup_code         = xsel.sales_class
                                   AND flv.language            = cv_lang
                                   AND flv.enabled_flag        = cv_enable
                                   AND gd_process_date   BETWEEN NVL( flv.start_date_active, gd_process_date )
                                                             AND NVL( flv.end_date_active  , gd_process_date )
                        )
                    AND xsel.item_code              <> gv_elec_change_item_code
                    AND ROWNUM = 1
-- 2011/04/01 Ver.3.13 [E_本稼動_06757] SCS M.Watanabe ADD END
                )
              , 0
           )                             AS bm1_electric_amt_tax     -- 【ＢＭ１】電気料(税込)
         , NULL                          AS bm2_vendor_code          -- 【ＢＭ２】仕入先コード
         , NULL                          AS bm2_vendor_site_code     -- 【ＢＭ２】仕入先サイトコード
         , NULL                          AS bm2_bm_payment_type      -- 【ＢＭ２】BM支払区分
         , NULL                          AS bm2_pct                  -- 【ＢＭ２】BM率(%)
         , NULL                          AS bm2_amt                  -- 【ＢＭ２】BM金額
         , NULL                          AS bm2_cond_bm_tax_pct      -- 【ＢＭ２】条件別手数料額(税込)_率
         , NULL                          AS bm2_cond_bm_amt_tax      -- 【ＢＭ２】条件別手数料額(税込)_額
         , NULL                          AS bm2_electric_amt_tax     -- 【ＢＭ２】電気料(税込)
         , NULL                          AS bm3_vendor_code          -- 【ＢＭ３】仕入先コード
         , NULL                          AS bm3_vendor_site_code     -- 【ＢＭ３】仕入先サイトコード
         , NULL                          AS bm3_bm_payment_type      -- 【ＢＭ３】BM支払区分
         , NULL                          AS bm3_pct                  -- 【ＢＭ３】BM率(%)
         , NULL                          AS bm3_amt                  -- 【ＢＭ３】BM金額
         , NULL                          AS bm3_cond_bm_tax_pct      -- 【ＢＭ３】条件別手数料額(税込)_率
         , NULL                          AS bm3_cond_bm_amt_tax      -- 【ＢＭ３】条件別手数料額(税込)_額
         , NULL                          AS bm3_electric_amt_tax     -- 【ＢＭ３】電気料(税込)
         , NULL                          AS item_code                -- エラー品目コード
         , xt0c.amount_fix_date          AS amount_fix_date          -- 金額確定日
-- 2012/06/15 Ver.3.15 [E_本稼動_08751] SCSK S.Niki MOD START
--    FROM xxcok_tmp_014a01c_custdata      xt0c  -- 条件別販手販協計算顧客情報一時表
    FROM xxcok_wk_014a01c_custdata       xt0c  -- 条件別販手販協計算顧客情報一時表
-- 2012/06/15 Ver.3.15 [E_本稼動_08751] SCSK S.Niki MOD END
       , xxcok_cust_bm_info              xcbi
       , hz_cust_accounts                hca
       , xxcmm_cust_accounts             xca
-- 2010/12/13 Ver.3.12 [E_本稼動_01896] SCS S.Niki REPAIR START
       , xxcos_sales_exp_headers         xseh  -- 販売実績ヘッダ
       , xxcos_sales_exp_lines           xsel  -- 販売実績明細
-- 2010/12/13 Ver.3.12 [E_本稼動_01896] SCS S.Niki REPAIR END
    WHERE xt0c.ship_gyotai_sho       IN ( cv_gyotai_sho_25, cv_gyotai_sho_24 )    -- 業態（小分類）：フルサービスVD・フルサービス（消化）VD
-- 2012/06/15 Ver.3.15 [E_本稼動_08751] SCSK S.Niki ADD START
      AND xt0c.proc_type              = gv_param_proc_type
-- 2012/06/15 Ver.3.15 [E_本稼動_08751] SCSK S.Niki ADD END
      AND xt0c.ship_cust_code         = xcbi.cust_code(+)
      AND xt0c.ship_cust_code         = hca.account_number
      AND hca.cust_account_id         = xca.customer_id
-- 2010/12/13 Ver.3.12 [E_本稼動_01896] SCS S.Niki REPAIR START
      AND xseh.ship_to_customer_code  = xt0c.ship_cust_code
      AND xseh.delivery_date         <= xt0c.closing_date
      AND xseh.delivery_date         >= NVL( xcbi.last_fix_delivery_date, xseh.delivery_date )
-- 2010/12/13 Ver.3.12 [E_本稼動_01844] SCS S.Niki ADD START
      AND xseh.business_date         <= gd_process_date
-- 2010/12/13 Ver.3.12 [E_本稼動_01844] SCS S.Niki ADD END
      AND xseh.sales_exp_header_id    = xsel.sales_exp_header_id
      AND xsel.to_calculate_fees_flag = cv_xsel_if_flag_no
      AND EXISTS ( SELECT  'X'
                   FROM fnd_lookup_values flv -- 販手計算対象売上区分
                   WHERE flv.lookup_type         = cv_lookup_type_07             -- 参照タイプ：販手計算対象売上区分
                     AND flv.lookup_code         = xsel.sales_class
                     AND flv.language            = cv_lang
                     AND flv.enabled_flag        = cv_enable
                     AND gd_process_date   BETWEEN NVL( flv.start_date_active, gd_process_date )
                                               AND NVL( flv.end_date_active  , gd_process_date )
                     AND ROWNUM = 1
          )
--
-- 2011/03/23 Ver.3.13 [E_本稼動_06757] SCS M.Watanabe DEL START
--      AND NOT EXISTS ( SELECT 'X'
--                       FROM fnd_lookup_values flv -- 非在庫品目
--                       WHERE flv.lookup_type         = cv_lookup_type_05         -- 参照タイプ：非在庫品目
--                         AND flv.lookup_code         = xsel.item_code
--                         AND flv.language            = cv_lang
--                         AND flv.enabled_flag        = cv_enable
--                         AND gd_process_date   BETWEEN NVL( flv.start_date_active, gd_process_date )
--                                                   AND NVL( flv.end_date_active  , gd_process_date )
--                              AND ROWNUM = 1
--          )
-- 2011/03/23 Ver.3.13 [E_本稼動_06757] SCS M.Watanabe DEL END
--
-- 2010/12/13 Ver.3.12 [E_本稼動_01896] SCS S.Niki REPAIR END
      AND (    ( EXISTS ( SELECT 'X'
                          FROM xxcos_sales_exp_headers   xseh
                             , xxcos_sales_exp_lines     xsel
                          WHERE xseh.sales_exp_header_id    = xsel.sales_exp_header_id
                            AND xseh.ship_to_customer_code  = xt0c.ship_cust_code
-- 2010/12/13 Ver.3.12 [E_本稼動_01896] SCS S.Niki REPAIR START
                            AND xseh.delivery_date         <= xt0c.closing_date
-- 2010/12/13 Ver.3.12 [E_本稼動_01896] SCS S.Niki REPAIR END
-- 2010/12/13 Ver.3.12 [E_本稼動_01844] SCS S.Niki ADD START
                            AND xseh.business_date         <= gd_process_date
-- 2010/12/13 Ver.3.12 [E_本稼動_01844] SCS S.Niki ADD END
                            AND xseh.delivery_date         >= NVL( xcbi.last_fix_delivery_date, xseh.delivery_date )
                            AND xsel.to_calculate_fees_flag = cv_xsel_if_flag_no
                            AND xsel.item_code              = gv_elec_change_item_code -- 変動電気代
                            AND ROWNUM = 1
                 )
               )
            OR ( EXISTS ( SELECT 'X'
                          FROM xxcok_mst_bm_contract     xmbc
                          WHERE xmbc.calc_type               = cv_calc_type_electricity_cost  -- 計算条件：電気代
                            AND xmbc.cust_code               = xt0c.ship_cust_code
                            AND xmbc.calc_target_flag        = cv_enable
                            AND ROWNUM = 1
                 )
               )
          )
-- 2010/12/13 Ver.3.12 [E_本稼動_01896] SCS S.Niki REPAIR START
    GROUP BY CASE
               WHEN TRUNC( xt0c.closing_date, 'MM' ) = TRUNC( gd_process_date, 'MM' ) THEN
                 xca.sale_base_code
               ELSE
                 xca.past_sale_base_code
             END                                    -- 拠点コード
           , xt0c.emp_code                          -- 担当者コード
           , xt0c.ship_cust_code                    -- 顧客【納品先】
           , xt0c.ship_gyotai_sho                   -- 顧客【納品先】業態（小分類）
           , xt0c.ship_gyotai_tyu                   -- 顧客【納品先】業態（中分類）
           , xt0c.bill_cust_code                    -- 顧客【請求先】
           , xt0c.period_year                       -- 会計年度
           , xt0c.ship_delivery_chain_code          -- チェーン店コード
           , TO_CHAR( xt0c.closing_date, 'RRRRMM' ) -- 納品日年月
           , xt0c.tax_div                           -- 消費税区分
           , xt0c.tax_code                          -- 税金コード
           , xt0c.tax_rate                          -- 消費税率
           , xt0c.tax_rounding_rule                 -- 端数処理区分
           , xt0c.term_name                         -- 支払条件
           , xt0c.closing_date                      -- 締め日
           , xt0c.expect_payment_date               -- 支払予定日
           , xt0c.calc_target_period_from           -- 計算対象期間(FROM)
           , xt0c.calc_target_period_to             -- 計算対象期間(TO)
           , xt0c.bm1_vendor_code                   -- 【ＢＭ１】仕入先コード
           , xt0c.bm1_vendor_site_code              -- 【ＢＭ１】仕入先サイトコード
           , xt0c.bm1_bm_payment_type               -- 【ＢＭ１】BM支払区分
           , xcbi.last_fix_delivery_date            -- 前回確定の納品日
           , xt0c.amount_fix_date                   -- 金額確定日
-- 2010/12/13 Ver.3.12 [E_本稼動_01896] SCS S.Niki REPAIR END
  ;
-- 2010/03/16 Ver.3.9 [E_本稼動_01896] SCS K.Yamaguchi REPAIR END
-- 2009/12/21 Ver.3.6 [E_本稼動_00460] SCS K.Yamaguchi REPAIR END
  -- 販売実績情報・入金値引率
  CURSOR get_sales_data_cur6 IS
    SELECT /*+ LEADING(xt0c xcbi xseh xsel) */
-- 2010/03/16 Ver.3.9 [E_本稼動_01896] SCS K.Yamaguchi REPAIR START
--           xseh.sales_base_code                                                                  AS base_code                -- 拠点コード
--         , xseh.results_employee_code                                                            AS emp_code                 -- 担当者コード
           CASE
             WHEN TRUNC( xt0c.closing_date, 'MM' ) = TRUNC( gd_process_date, 'MM' ) THEN
               xca.sale_base_code
             ELSE
               xca.past_sale_base_code
           END                                                                                   AS base_code                -- 拠点コード
         , xt0c.emp_code                                                                         AS emp_code                 -- 担当者コード
-- 2010/03/16 Ver.3.9 [E_本稼動_01896] SCS K.Yamaguchi REPAIR END
         , xseh.ship_to_customer_code                                                            AS ship_cust_code           -- 顧客【納品先】
         , xt0c.ship_gyotai_sho                                                                  AS ship_gyotai_sho          -- 顧客【納品先】業態（小分類）
         , xt0c.ship_gyotai_tyu                                                                  AS ship_gyotai_tyu          -- 顧客【納品先】業態（中分類）
         , xt0c.bill_cust_code                                                                   AS bill_cust_code           -- 顧客【請求先】
         , xt0c.period_year                                                                      AS period_year              -- 会計年度
         , xt0c.ship_delivery_chain_code                                                         AS ship_delivery_chain_code -- チェーン店コード
-- 2010/03/16 Ver.3.9 [E_本稼動_01896] SCS K.Yamaguchi REPAIR START
--         , TO_CHAR( xseh.delivery_date, 'RRRRMM' )                                               AS delivery_ym              -- 納品日年月
         , TO_CHAR( xt0c.closing_date, 'RRRRMM' )                                                AS delivery_ym              -- 納品日年月
-- 2010/03/16 Ver.3.9 [E_本稼動_01896] SCS K.Yamaguchi REPAIR END
         , NULL                                                                                  AS dlv_qty                  -- 納品数量
         , NULL                                                                                  AS dlv_uom_code             -- 納品単位
         , SUM( xsel.pure_amount + xsel.tax_amount )                                             AS amount_inc_tax           -- 売上金額（税込）
         , NULL                                                                                  AS container_code           -- 容器区分コード
         , NULL                                                                                  AS dlv_unit_price           -- 売価金額
         , xt0c.tax_div                                                                          AS tax_div                  -- 消費税区分
         , xt0c.tax_code                                                                         AS tax_code                 -- 税金コード
         , xt0c.tax_rate                                                                         AS tax_rate                 -- 消費税率
         , xt0c.tax_rounding_rule                                                                AS tax_rounding_rule        -- 端数処理区分
         , xt0c.term_name                                                                        AS term_name                -- 支払条件
         , xt0c.closing_date                                                                     AS closing_date             -- 締め日
         , xt0c.expect_payment_date                                                              AS expect_payment_date      -- 支払予定日
         , xt0c.calc_target_period_from                                                          AS calc_target_period_from  -- 計算対象期間(FROM)
         , xt0c.calc_target_period_to                                                            AS calc_target_period_to    -- 計算対象期間(TO)
         , '30'                                                                                  AS calc_type                -- 計算条件
         , xt0c.bm1_vendor_code                                                                  AS bm1_vendor_code          -- 【ＢＭ１】仕入先コード
         , xt0c.bm1_vendor_site_code                                                             AS bm1_vendor_site_code     -- 【ＢＭ１】仕入先サイトコード
         , NULL                                                                                  AS bm1_bm_payment_type      -- 【ＢＭ１】BM支払区分
         , xt0c.receiv_discount_rate                                                             AS bm1_pct                  -- 【ＢＭ１】BM率(%)
         , NULL                                                                                  AS bm1_amt                  -- 【ＢＭ１】BM金額
         , TRUNC( SUM( xsel.pure_amount + xsel.tax_amount ) * xt0c.receiv_discount_rate / 100 )  AS bm1_cond_bm_tax_pct      -- 【ＢＭ１】条件別手数料額(税込)_率
         , NULL                                                                                  AS bm1_cond_bm_amt_tax      -- 【ＢＭ１】条件別手数料額(税込)_額
         , NULL                                                                                  AS bm1_electric_amt_tax     -- 【ＢＭ１】電気料(税込)
         , NULL                                                                                  AS bm2_vendor_code          -- 【ＢＭ２】仕入先コード
         , NULL                                                                                  AS bm2_vendor_site_code     -- 【ＢＭ２】仕入先サイトコード
         , NULL                                                                                  AS bm2_bm_payment_type      -- 【ＢＭ２】BM支払区分
         , NULL                                                                                  AS bm2_pct                  -- 【ＢＭ２】BM率(%)
         , NULL                                                                                  AS bm2_amt                  -- 【ＢＭ２】BM金額
         , NULL                                                                                  AS bm2_cond_bm_tax_pct      -- 【ＢＭ２】条件別手数料額(税込)_率
         , NULL                                                                                  AS bm2_cond_bm_amt_tax      -- 【ＢＭ２】条件別手数料額(税込)_額
         , NULL                                                                                  AS bm2_electric_amt_tax     -- 【ＢＭ２】電気料(税込)
         , NULL                                                                                  AS bm3_vendor_code          -- 【ＢＭ３】仕入先コード
         , NULL                                                                                  AS bm3_vendor_site_code     -- 【ＢＭ３】仕入先サイトコード
         , NULL                                                                                  AS bm3_bm_payment_type      -- 【ＢＭ３】BM支払区分
         , NULL                                                                                  AS bm3_pct                  -- 【ＢＭ３】BM率(%)
         , NULL                                                                                  AS bm3_amt                  -- 【ＢＭ３】BM金額
         , NULL                                                                                  AS bm3_cond_bm_tax_pct      -- 【ＢＭ３】条件別手数料額(税込)_率
         , NULL                                                                                  AS bm3_cond_bm_amt_tax      -- 【ＢＭ３】条件別手数料額(税込)_額
         , NULL                                                                                  AS bm3_electric_amt_tax     -- 【ＢＭ３】電気料(税込)
         , NULL                                                                                  AS item_code                -- エラー品目コード
         , xt0c.amount_fix_date                                                                  AS amount_fix_date          -- 金額確定日
    FROM xxcos_sales_exp_lines       xsel  -- 販売実績明細
       , xxcos_sales_exp_headers     xseh  -- 販売実績ヘッダ
-- 2012/06/15 Ver.3.15 [E_本稼動_08751] SCSK S.Niki MOD START
--       , xxcok_tmp_014a01c_custdata  xt0c  -- 条件別販手販協計算顧客情報一時表
       , xxcok_wk_014a01c_custdata  xt0c   -- 条件別販手販協計算顧客情報一時表
-- 2012/06/15 Ver.3.15 [E_本稼動_08751] SCSK S.Niki MOD END
       , xxcok_cust_bm_info          xcbi
-- 2010/03/16 Ver.3.9 [E_本稼動_01896] SCS K.Yamaguchi ADD START
       , hz_cust_accounts            hca
       , xxcmm_cust_accounts         xca
-- 2010/03/16 Ver.3.9 [E_本稼動_01896] SCS K.Yamaguchi ADD END
-- 2009/10/02 Ver.3.1 [仕様変更I_E_566] SCS K.Yamaguchi REPAIR START
--    WHERE xt0c.ship_gyotai_tyu       <> cv_gyotai_tyu_vd                          -- 業態（中分類）：VD
    WHERE xt0c.ship_gyotai_sho   NOT IN ( cv_gyotai_sho_25, cv_gyotai_sho_24 )    -- 業態（小分類）：フルサービスVD・フルサービス（消化）VD
-- 2012/06/15 Ver.3.15 [E_本稼動_08751] SCSK S.Niki ADD START
      AND xt0c.proc_type              = gv_param_proc_type
-- 2012/06/15 Ver.3.15 [E_本稼動_08751] SCSK S.Niki ADD END
-- 2009/10/02 Ver.3.1 [仕様変更I_E_566] SCS K.Yamaguchi REPAIR END
      AND xseh.ship_to_customer_code  = xt0c.ship_cust_code
      AND xseh.delivery_date         <= xt0c.closing_date
-- 2010/12/13 Ver.3.12 [E_本稼動_01844] SCS S.Niki ADD START
      AND xseh.business_date         <= gd_process_date
-- 2010/12/13 Ver.3.12 [E_本稼動_01844] SCS S.Niki ADD END
      AND xt0c.ship_cust_code         = xcbi.cust_code(+)
      AND xseh.delivery_date         >= NVL( xcbi.last_fix_delivery_date, xseh.delivery_date )
      AND xseh.sales_exp_header_id    = xsel.sales_exp_header_id
      AND xsel.to_calculate_fees_flag = cv_xsel_if_flag_no
      AND xt0c.receiv_discount_rate  IS NOT NULL
-- 2010/03/16 Ver.3.9 [E_本稼動_01896] SCS K.Yamaguchi ADD START
      AND xt0c.ship_cust_code         = hca.account_number
      AND hca.cust_account_id         = xca.customer_id
-- 2010/03/16 Ver.3.9 [E_本稼動_01896] SCS K.Yamaguchi ADD END
      AND EXISTS (  SELECT 'X'
                    FROM fnd_lookup_values flv -- 販手計算対象売上区分
                    WHERE flv.lookup_type         = cv_lookup_type_07             -- 参照タイプ：販手計算対象売上区分
                      AND flv.lookup_code         = xsel.sales_class
                      AND flv.language            = cv_lang
                      AND flv.enabled_flag        = cv_enable
                      AND gd_process_date   BETWEEN NVL( flv.start_date_active, gd_process_date )
                                                AND NVL( flv.end_date_active  , gd_process_date )
                      AND ROWNUM = 1
          )
      AND NOT EXISTS ( SELECT 'X'
                       FROM fnd_lookup_values flv -- 非在庫品目
                       WHERE flv.lookup_type         = cv_lookup_type_05         -- 参照タイプ：非在庫品目
                         AND flv.lookup_code         = xsel.item_code
                         AND flv.language            = cv_lang
                         AND flv.enabled_flag        = cv_enable
                         AND gd_process_date   BETWEEN NVL( flv.start_date_active, gd_process_date )
                                                   AND NVL( flv.end_date_active  , gd_process_date )
-- 2009/11/09 Ver.3.4 [仕様変更I_E_633] SCS K.Yamaguchi ADD START
                         AND flv.attribute2          = cv_disable
-- 2009/11/09 Ver.3.4 [仕様変更I_E_633] SCS K.Yamaguchi ADD END
                         AND ROWNUM = 1
          )
-- 2010/03/16 Ver.3.9 [E_本稼動_01896] SCS K.Yamaguchi REPAIR START
--    GROUP BY xseh.sales_base_code
--           , xseh.results_employee_code
    GROUP BY CASE
               WHEN TRUNC( xt0c.closing_date, 'MM' ) = TRUNC( gd_process_date, 'MM' ) THEN
                 xca.sale_base_code
               ELSE
                 xca.past_sale_base_code
             END
           , xt0c.emp_code
-- 2010/03/16 Ver.3.9 [E_本稼動_01896] SCS K.Yamaguchi REPAIR END
           , xseh.ship_to_customer_code
           , xt0c.ship_gyotai_sho
           , xt0c.ship_gyotai_tyu
           , xt0c.bill_cust_code
           , xt0c.period_year
           , xt0c.ship_delivery_chain_code
-- 2010/03/16 Ver.3.9 [E_本稼動_01896] SCS K.Yamaguchi REPAIR START
--           , TO_CHAR( xseh.delivery_date, 'RRRRMM' )
           , TO_CHAR( xt0c.closing_date, 'RRRRMM' )
-- 2010/03/16 Ver.3.9 [E_本稼動_01896] SCS K.Yamaguchi REPAIR END
           , xt0c.tax_div
           , xt0c.tax_code
           , xt0c.tax_rate
           , xt0c.tax_rounding_rule
           , xt0c.term_name
           , xt0c.closing_date
           , xt0c.expect_payment_date
           , xt0c.calc_target_period_from
           , xt0c.calc_target_period_to
           , xt0c.bm1_vendor_code
           , xt0c.bm1_vendor_site_code
           , xt0c.receiv_discount_rate
           , xt0c.amount_fix_date
  ;
  --==================================================
  -- グローバルタイプ
  --==================================================
  TYPE get_sales_data_rtype        IS RECORD (
    base_code                      VARCHAR2(4)
  , emp_code                       VARCHAR2(5)
  , ship_cust_code                 VARCHAR2(9)
  , ship_gyotai_sho                VARCHAR2(2)
  , ship_gyotai_tyu                VARCHAR2(2)
  , bill_cust_code                 VARCHAR2(9)
  , period_year                    NUMBER
  , ship_delivery_chain_code       VARCHAR2(9)
  , delivery_ym                    VARCHAR2(6)
  , dlv_qty                        NUMBER
  , dlv_uom_code                   VARCHAR2(3)
  , amount_inc_tax                 NUMBER
  , container_code                 VARCHAR2(4)
  , dlv_unit_price                 NUMBER
  , tax_div                        VARCHAR2(1)
  , tax_code                       VARCHAR2(50)
  , tax_rate                       NUMBER
  , tax_rounding_rule              VARCHAR2(30)
  , term_name                      VARCHAR2(8)
  , closing_date                   DATE
  , expect_payment_date            DATE
  , calc_target_period_from        DATE
  , calc_target_period_to          DATE
  , calc_type                      VARCHAR2(2)
  , bm1_vendor_code                VARCHAR2(9)
  , bm1_vendor_site_code           VARCHAR2(10)
  , bm1_bm_payment_type            VARCHAR2(1)
  , bm1_pct                        NUMBER
  , bm1_amt                        NUMBER
  , bm1_cond_bm_tax_pct            NUMBER
  , bm1_cond_bm_amt_tax            NUMBER
  , bm1_electric_amt_tax           NUMBER
  , bm2_vendor_code                VARCHAR2(9)
  , bm2_vendor_site_code           VARCHAR2(10)
  , bm2_bm_payment_type            VARCHAR2(1)
  , bm2_pct                        NUMBER
  , bm2_amt                        NUMBER
  , bm2_cond_bm_tax_pct            NUMBER
  , bm2_cond_bm_amt_tax            NUMBER
  , bm2_electric_amt_tax           NUMBER
  , bm3_vendor_code                VARCHAR2(9)
  , bm3_vendor_site_code           VARCHAR2(10)
  , bm3_bm_payment_type            VARCHAR2(1)
  , bm3_pct                        NUMBER
  , bm3_amt                        NUMBER
  , bm3_cond_bm_tax_pct            NUMBER
  , bm3_cond_bm_amt_tax            NUMBER
  , bm3_electric_amt_tax           NUMBER
  , item_code                      VARCHAR2(7)
  , amount_fix_date                DATE
  );
  TYPE xcbs_data_ttype             IS TABLE OF xxcok_cond_bm_support%ROWTYPE INDEX BY BINARY_INTEGER;
--
  /**********************************************************************************
   * Procedure Name   : get_operating_day_f
   * Description      : 稼働日取得(A-16)
   ***********************************************************************************/
  FUNCTION get_operating_day_f(
    id_proc_date                   IN DATE             -- 処理日
  , in_days                        IN NUMBER           -- 日数
  , in_proc_type                   IN NUMBER           -- 処理区分
  )
  RETURN DATE
  IS
    --==================================================
    -- ローカル定数
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'get_operating_day_f';   -- プログラム名
    --==================================================
    -- ローカル定数
    --==================================================
    lt_calendar_date               bom_calendar_dates.calendar_date%TYPE;
  --
  BEGIN
    SELECT bcd2.calendar_date
    INTO lt_calendar_date
    FROM ( SELECT CASE
                    WHEN bcd.seq_num IS NOT NULL   THEN
                      bcd.seq_num + in_days
                    WHEN bcd.seq_num IS NULL
                     AND in_days > 0               THEN
                      bcd.prior_seq_num + in_days
                    WHEN bcd.seq_num IS NULL
                     AND in_days < 0               THEN
                      bcd.next_seq_num + in_days
                    WHEN bcd.seq_num IS NULL
                     AND in_days = 0
                     AND in_proc_type = 1          THEN
                      bcd.prior_seq_num
                    WHEN bcd.seq_num IS NULL
                     AND in_days = 0
                     AND in_proc_type = 2          THEN
                      bcd.next_seq_num
                  END                   AS seq_num
            FROM bom_calendar_dates bcd
            WHERE bcd.calendar_code  = gt_calendar_code
              AND bcd.calendar_date  = id_proc_date
         )                      bcd1
       , bom_calendar_dates     bcd2
    WHERE bcd2.calendar_code  = gt_calendar_code
      AND bcd2.seq_num        = bcd1.seq_num
    ;
    RETURN lt_calendar_date;
--
  EXCEPTION
    WHEN OTHERS THEN
      raise_application_error(
        -20000, cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM
      );
--
  END get_operating_day_f;
--
-- 2009/10/19 Ver.3.2 [障害E_T3_00631] SCS K.Yamaguchi ADD START
  /**********************************************************************************
   * Procedure Name   : get_tax_rate
   * Description      : 消費税コード・税率取得
   ***********************************************************************************/
  PROCEDURE get_tax_rate(
    ov_errbuf                      OUT VARCHAR2        -- エラー・メッセージ
  , ov_retcode                     OUT VARCHAR2        -- リターン・コード
  , ov_errmsg                      OUT VARCHAR2        -- ユーザー・エラー・メッセージ
  , it_tax_div                     IN  xxcmm_cust_accounts.tax_div%TYPE  -- 消費税区分
  , id_target_date                 IN  DATE                              -- 基準日
  , ot_tax_code                    OUT ar_vat_tax_b.tax_code%TYPE        -- 税金コード
  , ot_tax_rate                    OUT ar_vat_tax_b.tax_rate%TYPE        -- 税率
  )
  IS
    --==================================================
    -- ローカル定数
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'get_tax_rate';      -- プログラム名
    --==================================================
    -- ローカル変数
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- エラー・メッセージ
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ユーザー・エラー・メッセージ
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- 出力用メッセージ
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- メッセージ出力関数戻り値
    lt_tax_code                    ar_vat_tax_b.tax_code%TYPE DEFAULT NULL;     -- 税金コード
    lt_tax_rate                    ar_vat_tax_b.tax_rate%TYPE DEFAULT NULL;     -- 税率
--
  BEGIN
    --==================================================
    -- ステータス初期化
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- 消費税コード・税率取得
    --==================================================
    SELECT xtv.tax_code       AS tax_code
         , xtv.tax_rate       AS tax_rate
    INTO lt_tax_code
       , lt_tax_rate
    FROM xxcos_tax_v     xtv
    WHERE xtv.set_of_books_id      = gn_set_of_books_id
      AND xtv.tax_class            = it_tax_div
      AND id_target_date     BETWEEN NVL( xtv.start_date_active, id_target_date )
                                 AND NVL( xtv.end_date_active  , id_target_date )
    ;
    --==================================================
    -- 出力パラメータ設定
    --==================================================
    ov_errbuf    := NULL;
    ov_errmsg    := NULL;
    ov_retcode   := lv_end_retcode;
    ot_tax_code  := lt_tax_code;
    ot_tax_rate  := lt_tax_rate;
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00104
                    , iv_token_name1          => cv_tkn_tax_div
                    , iv_token_value1         => it_tax_div
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END get_tax_rate;
--
-- 2009/10/19 Ver.3.2 [障害E_T3_00631] SCS K.Yamaguchi ADD END
  /**********************************************************************************
   * Procedure Name   : update_xcbi
   * Description      : 販手計算済顧客情報データの更新(A-15)
   ***********************************************************************************/
  PROCEDURE update_xcbi(
    ov_errbuf                      OUT VARCHAR2        -- エラー・メッセージ
  , ov_retcode                     OUT VARCHAR2        -- リターン・コード
  , ov_errmsg                      OUT VARCHAR2        -- ユーザー・エラー・メッセージ
  )
  IS
    --==================================================
    -- ローカル定数
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'update_xcbi';      -- プログラム名
    --==================================================
    -- ローカル変数
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- エラー・メッセージ
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ユーザー・エラー・メッセージ
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- 出力用メッセージ
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- メッセージ出力関数戻り値
    -- エラー時ログ出力用退避変数
-- 2012/06/15 Ver.3.15 [E_本稼動_08751] SCSK S.Niki MOD START
--    lt_ship_cust_code              xxcok_tmp_014a01c_custdata.ship_cust_code%TYPE DEFAULT NULL;
    lt_ship_cust_code              xxcok_wk_014a01c_custdata.ship_cust_code%TYPE DEFAULT NULL;
-- 2012/06/15 Ver.3.15 [E_本稼動_08751] SCSK S.Niki MOD END
    --==================================================
    -- ローカルカーソル
    --==================================================
    CURSOR xcbi_update_lock_cur
    IS
      SELECT xcbi.cust_bm_info_id       AS cust_bm_info_id            -- 販手計算済顧客情報ID
           , xt0c.ship_cust_code        AS ship_cust_code             -- 顧客コード
           , xt0c.calc_target_period_to AS calc_target_period_to      -- 締め日
           , ( SELECT COUNT( 'X' )
               FROM xxcok_bm_contract_err xbce
               WHERE xbce.cust_code = xt0c.ship_cust_code
                 AND ROWNUM = 1
             )                          AS error_count                -- 販手条件エラーチェック
      FROM xxcok_cust_bm_info           xcbi               -- 販手販協計算済顧客情報テーブル
-- 2012/06/15 Ver.3.15 [E_本稼動_08751] SCSK S.Niki MOD START
--         , xxcok_tmp_014a01c_custdata   xt0c               -- 条件別販手販協計算顧客情報一時表
         , xxcok_wk_014a01c_custdata   xt0c                -- 条件別販手販協計算顧客情報一時表
-- 2012/06/15 Ver.3.15 [E_本稼動_08751] SCSK S.Niki MOD END
      WHERE xcbi.cust_code(+)           = xt0c.ship_cust_code
-- 2012/06/15 Ver.3.15 [E_本稼動_08751] SCSK S.Niki ADD START
        AND xt0c.proc_type              = gv_param_proc_type
-- 2012/06/15 Ver.3.15 [E_本稼動_08751] SCSK S.Niki ADD END
        AND xt0c.amount_fix_date        = gd_process_date
      FOR UPDATE OF xcbi.cust_bm_info_id NOWAIT
    ;
--
  BEGIN
    --==================================================
    -- ステータス初期化
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- 販手販協計算済顧客情報データ更新ループ
    --==================================================
    << xcbi_update_lock_loop >>
    FOR xcbi_update_lock_rec IN xcbi_update_lock_cur LOOP
      lt_ship_cust_code := xcbi_update_lock_rec.ship_cust_code;
      --==================================================
      -- 販手販協計算済顧客情報データ更新
      --==================================================
      IF( xcbi_update_lock_rec.cust_bm_info_id IS NOT NULL ) THEN
        UPDATE xxcok_cust_bm_info       xcbi
        SET xcbi.last_fix_closing_date  = xcbi_update_lock_rec.calc_target_period_to
          , xcbi.last_fix_delivery_date = CASE
                                            WHEN xcbi_update_lock_rec.error_count = 0 THEN
                                              ADD_MONTHS( TRUNC( xcbi_update_lock_rec.calc_target_period_to, 'MM' ), -1 )
                                            ELSE
                                              xcbi.last_fix_delivery_date
                                          END
          , xcbi.last_updated_by        = cn_last_updated_by
          , xcbi.last_update_date       = SYSDATE
          , xcbi.last_update_login      = cn_last_update_login
          , xcbi.request_id             = cn_request_id
          , xcbi.program_application_id = cn_program_application_id
          , xcbi.program_id             = cn_program_id
          , xcbi.program_update_date    = SYSDATE
        WHERE xcbi.cust_bm_info_id      = xcbi_update_lock_rec.cust_bm_info_id
        ;
      --==================================================
      --販手販協計算済顧客情報データ登録
      --==================================================
      ELSE
        INSERT INTO xxcok_cust_bm_info(
          cust_bm_info_id                                   -- 販手計算済顧客情報ID
        , cust_code                                         -- 顧客コード
        , last_fix_closing_date                             -- 最終確定締め日
        , last_fix_delivery_date                            -- 最終確定納品日
        , created_by                                        -- 作成者
        , creation_date                                     -- 作成日
        , last_updated_by                                   -- 最終更新者
        , last_update_date                                  -- 最終更新日
        , last_update_login                                 -- 最終更新ログイン
        , request_id                                        -- 要求ID
        , program_application_id                            -- コンカレント・プログラム・アプリケーションID
        , program_id                                        -- コンカレント・プログラムID
        , program_update_date                               -- プログラム更新日
        )
        VALUES(
          xxcok_cust_bm_info_s01.NEXTVAL                    -- cust_bm_info_id
        , xcbi_update_lock_rec.ship_cust_code               -- cust_code
        , xcbi_update_lock_rec.calc_target_period_to        -- last_fix_closing_date
        , CASE
            WHEN xcbi_update_lock_rec.error_count = 0 THEN
              ADD_MONTHS( TRUNC( xcbi_update_lock_rec.calc_target_period_to, 'MM' ), -1 )
            ELSE
              NULL
          END                                               -- last_fix_delivery_date
        , cn_created_by                                     -- created_by
        , SYSDATE                                           -- creation_date
        , cn_last_updated_by                                -- last_updated_by
        , SYSDATE                                           -- last_update_date
        , cn_last_update_login                              -- last_update_login
        , cn_request_id                                     -- request_id
        , cn_program_application_id                         -- program_application_id
        , cn_program_id                                     -- program_id
        , SYSDATE                                           -- program_update_date
        );
      END IF;
    END LOOP xcbi_update_lock_loop;
    --==================================================
    -- 出力パラメータ設定
    --==================================================
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
    ov_retcode := lv_end_retcode;
--
  EXCEPTION
    -- *** ロック取得エラー ***
    WHEN resource_busy_expt THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00103
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END update_xcbi;
--
  /**********************************************************************************
   * Procedure Name   : update_xsel
   * Description      : 販売実績連携結果の更新(A-12)
   ***********************************************************************************/
  PROCEDURE update_xsel(
    ov_errbuf                      OUT VARCHAR2        -- エラー・メッセージ
  , ov_retcode                     OUT VARCHAR2        -- リターン・コード
  , ov_errmsg                      OUT VARCHAR2        -- ユーザー・エラー・メッセージ
  )
  IS
    --==================================================
    -- ローカル定数
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'update_xsel';      -- プログラム名
    --==================================================
    -- ローカル変数
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- エラー・メッセージ
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ユーザー・エラー・メッセージ
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- 出力用メッセージ
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- メッセージ出力関数戻り値
    -- エラー時ログ出力用退避変数
    lt_sales_exp_line_id           xxcos_sales_exp_lines.sales_exp_line_id%TYPE DEFAULT NULL;
    --==================================================
    -- ローカルカーソル
    --==================================================
    CURSOR xsel_update_lock_cur
    IS
-- 2012/10/01 Ver.3.16 [E_本稼動_10133] SCSK K.Kiriu REPAIR START
--      SELECT xsel.sales_exp_line_id    AS sales_exp_line_id    -- 販売実績明細ID
      SELECT /*+
               LEADING(xt0c xcbi)
               USE_NL(xt0c xcbi xseh xsel)
               INDEX(xseh XXCOS_SALES_EXP_HEADERS_N08)
             */
             xsel.sales_exp_line_id    AS sales_exp_line_id    -- 販売実績明細ID
-- 2012/10/01 Ver.3.16 [E_本稼動_10133] SCSK K.Kiriu REPAIR END
-- 2012/06/15 Ver.3.15 [E_本稼動_08751] SCSK S.Niki MOD START
--      FROM xxcok_tmp_014a01c_custdata xt0c            -- 条件別販手販協計算顧客情報一時表
      FROM xxcok_wk_014a01c_custdata xt0c             -- 条件別販手販協計算顧客情報一時表
-- 2012/06/15 Ver.3.15 [E_本稼動_08751] SCSK S.Niki MOD END
         , xxcos_sales_exp_headers    xseh            -- 販売実績ヘッダーテーブル
         , xxcos_sales_exp_lines      xsel            -- 販売実績明細テーブル
         , xxcok_cust_bm_info         xcbi
      WHERE xseh.ship_to_customer_code   = xt0c.ship_cust_code
        AND xseh.delivery_date          <= xt0c.closing_date
-- 2010/12/13 Ver.3.12 [E_本稼動_01844] SCS S.Niki ADD START
        AND xseh.business_date          <= gd_process_date
-- 2010/12/13 Ver.3.12 [E_本稼動_01844] SCS S.Niki ADD END
        AND xt0c.amount_fix_date         = gd_process_date
        AND xt0c.ship_cust_code          = xcbi.cust_code(+)
-- 2012/06/15 Ver.3.15 [E_本稼動_08751] SCSK S.Niki ADD START
        AND xt0c.proc_type               = gv_param_proc_type
-- 2012/06/15 Ver.3.15 [E_本稼動_08751] SCSK S.Niki ADD END
        AND xseh.delivery_date          >= NVL( xcbi.last_fix_delivery_date, xseh.delivery_date )
        AND xseh.sales_exp_header_id     = xsel.sales_exp_header_id
        AND xsel.to_calculate_fees_flag  = cv_xsel_if_flag_no
        AND NOT EXISTS ( SELECT 'X'
                         FROM xxcok_bm_contract_err xbce
                         WHERE xbce.cust_code           = xseh.ship_to_customer_code
                           AND xbce.item_code           = xsel.item_code
                           AND xbce.selling_price       = xsel.dlv_unit_price
                           AND ROWNUM = 1
            )
      FOR UPDATE OF xsel.sales_exp_line_id NOWAIT
    ;
--
  BEGIN
    --==================================================
    -- ステータス初期化
    --==================================================
    lv_end_retcode := cv_status_normal;
-- 2010/05/26 Ver.3.11 [E_本稼動_02855] SCS K.Yamaguchi REPAIR START
--    --==================================================
--    -- 販売実績連携結果更新ループ
--    --==================================================
--    << xsel_update_lock_loop >>
--    FOR xsel_update_lock_rec IN xsel_update_lock_cur LOOP
--      lt_sales_exp_line_id := xsel_update_lock_rec.sales_exp_line_id;
--      --==================================================
--      -- 販売実績連携結果データ更新
--      --==================================================
--      UPDATE xxcos_sales_exp_lines      xsel
--      SET xsel.to_calculate_fees_flag = cv_xsel_if_flag_yes   -- 手数料計算インターフェース済フラグ
--        , xsel.last_updated_by        = cn_last_updated_by
--        , xsel.last_update_date       = SYSDATE
--        , xsel.last_update_login      = cn_last_update_login
--        , xsel.request_id             = cn_request_id
--        , xsel.program_application_id = cn_program_application_id
--        , xsel.program_id             = cn_program_id
--        , xsel.program_update_date    = SYSDATE
--      WHERE xsel.sales_exp_line_id = xsel_update_lock_rec.sales_exp_line_id
--      ;
--    END LOOP xsel_update_lock_loop;
-- 2012/06/19 Ver.3.15 [E_本稼動_08751] SCSK S.Niki ADD START
    --プロファイル「XXCOK1:販手販協_販売実績明細ロック」が'N'以外のときロックを取得
    IF ( gv_xsel_data_lock <> cv_disable ) THEN
-- 2012/06/19 Ver.3.15 [E_本稼動_08751] SCSK S.Niki ADD END
      --==================================================
      -- 販売実績ロック取得
      --==================================================
      OPEN  xsel_update_lock_cur;
      CLOSE xsel_update_lock_cur;
-- 2012/06/19 Ver.3.15 [E_本稼動_08751] SCSK S.Niki ADD START
    END IF;
-- 2012/06/19 Ver.3.15 [E_本稼動_08751] SCSK S.Niki ADD END
    --==================================================
    -- 販売実績連携結果データ更新
    --==================================================
    UPDATE xxcos_sales_exp_lines      xsel
    SET xsel.to_calculate_fees_flag = cv_xsel_if_flag_yes   -- 手数料計算インターフェース済フラグ
      , xsel.last_updated_by        = cn_last_updated_by
      , xsel.last_update_date       = SYSDATE
      , xsel.last_update_login      = cn_last_update_login
      , xsel.request_id             = cn_request_id
      , xsel.program_application_id = cn_program_application_id
      , xsel.program_id             = cn_program_id
      , xsel.program_update_date    = SYSDATE
-- 2012/10/01 Ver.3.16 [E_本稼動_10133] SCSK K.Kiriu REPAIR START
--    WHERE EXISTS ( SELECT 'X'
    WHERE EXISTS ( SELECT /*+
                            LEADING(xt0c xcbi)
                            USE_NL(xt0c xcbi xseh xsel2) 
                            INDEX(xseh XXCOS_SALES_EXP_HEADERS_N08)
                          */
                          'X'
-- 2012/10/01 Ver.3.16 [E_本稼動_10133] SCSK K.Kiriu REPAIR END
-- 2012/06/15 Ver.3.15 [E_本稼動_08751] SCSK S.Niki MOD START
--                   FROM xxcok_tmp_014a01c_custdata xt0c            -- 条件別販手販協計算顧客情報一時表
                   FROM xxcok_wk_014a01c_custdata xt0c             -- 条件別販手販協計算顧客情報一時表
-- 2012/06/15 Ver.3.15 [E_本稼動_08751] SCSK S.Niki MOD END
                      , xxcos_sales_exp_headers    xseh            -- 販売実績ヘッダーテーブル
                      , xxcos_sales_exp_lines      xsel2           -- 販売実績明細テーブル
                      , xxcok_cust_bm_info         xcbi
                   WHERE xseh.ship_to_customer_code   = xt0c.ship_cust_code
                     AND xseh.delivery_date          <= xt0c.closing_date
-- 2010/12/13 Ver.3.12 [E_本稼動_01844] SCS S.Niki ADD START
                     AND xseh.business_date          <= gd_process_date
-- 2010/12/13 Ver.3.12 [E_本稼動_01844] SCS S.Niki ADD END
                     AND xt0c.amount_fix_date         = gd_process_date
                     AND xt0c.ship_cust_code          = xcbi.cust_code(+)
-- 2012/06/15 Ver.3.15 [E_本稼動_08751] SCSK S.Niki ADD START
                     AND xt0c.proc_type               = gv_param_proc_type
-- 2012/06/15 Ver.3.15 [E_本稼動_08751] SCSK S.Niki ADD END
                     AND xseh.delivery_date          >= NVL( xcbi.last_fix_delivery_date, xseh.delivery_date )
                     AND xseh.sales_exp_header_id     = xsel2.sales_exp_header_id
                     AND xsel2.to_calculate_fees_flag = cv_xsel_if_flag_no
                     AND NOT EXISTS ( SELECT 'X'
                                      FROM xxcok_bm_contract_err xbce
                                      WHERE xbce.cust_code           = xseh.ship_to_customer_code
                                        AND xbce.item_code           = xsel2.item_code
                                        AND xbce.selling_price       = xsel2.dlv_unit_price
                                        AND ROWNUM = 1
                         )
                     AND xsel2.sales_exp_line_id = xsel.sales_exp_line_id
          )
    ;
-- 2010/05/26 Ver.3.11 [E_本稼動_02855] SCS K.Yamaguchi REPAIR END
-- 2012/06/19 Ver.3.15 [E_本稼動_08751] SCSK S.Niki ADD START
    -- 件数カウント
    gn_target_cnt      := SQL%ROWCOUNT;
    gn_update_xsel_cnt := SQL%ROWCOUNT;
    gn_normal_cnt      := SQL%ROWCOUNT;
-- 2012/06/19 Ver.3.15 [E_本稼動_08751] SCSK S.Niki ADD END
    --==================================================
    -- 出力パラメータ設定
    --==================================================
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
    ov_retcode := lv_end_retcode;
--
  EXCEPTION
    -- *** ロック取得エラー ***
    WHEN resource_busy_expt THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00081
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END update_xsel;
--
  /**********************************************************************************
   * Procedure Name   : insert_xbce
   * Description      : 販手条件エラーテーブルへの登録(A-11)
   ***********************************************************************************/
  PROCEDURE insert_xbce(
    ov_errbuf                      OUT VARCHAR2        -- エラー・メッセージ
  , ov_retcode                     OUT VARCHAR2        -- リターン・コード
  , ov_errmsg                      OUT VARCHAR2        -- ユーザー・エラー・メッセージ
  , i_get_sales_data_rec           IN  get_sales_data_rtype  -- 販売実績情報レコード
  )
  IS
    --==================================================
    -- ローカル定数
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'insert_xbce';      -- プログラム名
    --==================================================
    -- ローカル変数
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- エラー・メッセージ
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ユーザー・エラー・メッセージ
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- 出力用メッセージ
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- メッセージ出力関数戻り値
--
  BEGIN
    --==================================================
    -- ステータス初期化
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- 販手条件エラーテーブルへの登録
    --==================================================
    IF( i_get_sales_data_rec.calc_type IS NULL ) THEN
      INSERT INTO xxcok_bm_contract_err (
        base_code              -- 拠点コード
      , cust_code              -- 顧客コード
      , item_code              -- 品目コード
      , container_type_code    -- 容器区分コード
      , selling_price          -- 売価
      , selling_amt_tax        -- 売上金額(税込)
      , closing_date           -- 締め日
      , created_by             -- 作成者
      , creation_date          -- 作成日
      , last_updated_by        -- 最終更新者
      , last_update_date       -- 最終更新日
      , last_update_login      -- 最終更新ログイン
      , request_id             -- 要求ID
      , program_application_id -- コンカレント・プログラム・アプリケーションID
      , program_id             -- コンカレント・プログラムID
      , program_update_date    -- プログラム更新日
      )
      VALUES (
        i_get_sales_data_rec.base_code           -- 拠点コード
      , i_get_sales_data_rec.ship_cust_code      -- 顧客コード
      , i_get_sales_data_rec.item_code           -- 品目コード
      , i_get_sales_data_rec.container_code      -- 容器区分コード
      , i_get_sales_data_rec.dlv_unit_price      -- 売価
      , i_get_sales_data_rec.amount_inc_tax      -- 売上金額(税込)
      , i_get_sales_data_rec.closing_date        -- 締め日
      , cn_created_by                            -- 作成者
      , SYSDATE                                  -- 作成日
      , cn_last_updated_by                       -- 最終更新者
      , SYSDATE                                  -- 最終更新日
      , cn_last_update_login                     -- 最終更新ログイン
      , cn_request_id                            -- 要求ID
      , cn_program_application_id                -- コンカレント・プログラム・アプリケーションID
      , cn_program_id                            -- コンカレント・プログラムID
      , SYSDATE                                  -- プログラム更新日
      );
-- 2012/06/15 Ver.3.15 [E_本稼動_08751] SCSK S.Niki ADD START
      -- 件数カウント
      gn_target_cnt      := gn_target_cnt + 1;
      gn_error_cnt       := gn_error_cnt + 1;
-- 2012/06/15 Ver.3.15 [E_本稼動_08751] SCSK S.Niki ADD END
      gn_contract_err_cnt := gn_contract_err_cnt + 1;
      lv_end_retcode := cv_status_warn;
    END IF;
    --==================================================
    -- 出力パラメータ設定
    --==================================================
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
    ov_retcode := lv_end_retcode;
--
  EXCEPTION
    -- *** エラー終了 ***
    WHEN error_proc_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 処理部共通例外 ***
    WHEN global_process_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := lv_end_retcode;
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END insert_xbce;
--
  /**********************************************************************************
   * Procedure Name   : insert_xcbs
   * Description      : 条件別販手販協テーブルへの登録(A-10)
   ***********************************************************************************/
  PROCEDURE insert_xcbs(
    ov_errbuf                      OUT VARCHAR2        -- エラー・メッセージ
  , ov_retcode                     OUT VARCHAR2        -- リターン・コード
  , ov_errmsg                      OUT VARCHAR2        -- ユーザー・エラー・メッセージ
  , i_get_sales_data_rec           IN  get_sales_data_rtype      -- 販売実績情報レコード
  , i_xcbs_data_tab                IN  xcbs_data_ttype           -- 条件別販手販協情報
  )
  IS
    --==================================================
    -- ローカル定数
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'insert_xcbs';      -- プログラム名
    cn_index_1                     CONSTANT NUMBER       := 1;                  -- BM1_索引
    cn_index_2                     CONSTANT NUMBER       := 2;                  -- BM2_索引
    cn_index_3                     CONSTANT NUMBER       := 3;                  -- BM3_索引
    --==================================================
    -- ローカル変数
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- エラー・メッセージ
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ユーザー・エラー・メッセージ
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- 出力用メッセージ
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- メッセージ出力関数戻り値
    lv_fix_status                  xxcok_cond_bm_support.amt_fix_status%TYPE;   -- 金額確定ステータス
--
  BEGIN
    --==================================================
    -- ステータス初期化
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- 金額確定ステータス決定
    --==================================================
    IF( i_get_sales_data_rec.amount_fix_date = gd_process_date ) THEN
      lv_fix_status := cv_xcbs_fix;
    ELSE
      lv_fix_status := cv_xcbs_temp;
    END IF;
    --==================================================
    -- ループ処理でBM1からBM3までの3レコードを登録
    --==================================================
    << insert_xcbs_loop >>
    FOR i IN cn_index_1 .. cn_index_3 LOOP
      --==================================================
      -- 登録条件確認
      --==================================================
      IF(     ( i_xcbs_data_tab( i ).supplier_code IS NOT NULL )
          AND (    ( i_xcbs_data_tab( i ).cond_bm_amt_tax       IS NOT NULL ) -- VDBM(税込)
                OR ( i_xcbs_data_tab( i ).electric_amt_tax      IS NOT NULL ) -- 電気料(税込)
                OR ( i_xcbs_data_tab( i ).csh_rcpt_discount_amt IS NOT NULL ) -- 入金値引額
              )
      ) THEN
        --==================================================
        -- 条件別販手販協計算結果を条件別販手販協テーブルに登録
        --==================================================
        INSERT INTO xxcok_cond_bm_support (
          cond_bm_support_id        -- 条件別販手販協ID
        , base_code                 -- 拠点コード
        , emp_code                  -- 担当者コード
        , delivery_cust_code        -- 顧客【納品先】
        , demand_to_cust_code       -- 顧客【請求先】
        , acctg_year                -- 会計年度
        , chain_store_code          -- チェーン店コード
        , supplier_code             -- 仕入先コード
        , supplier_site_code        -- 仕入先サイトコード
        , calc_type                 -- 計算条件
        , delivery_date             -- 納品日年月
        , delivery_qty              -- 納品数量
        , delivery_unit_type        -- 納品単位
        , selling_amt_tax           -- 売上金額(税込)
        , rebate_rate               -- 割戻率
        , rebate_amt                -- 割戻額
        , container_type_code       -- 容器区分コード
        , selling_price             -- 売価金額
        , cond_bm_amt_tax           -- 条件別手数料額(税込)
        , cond_bm_amt_no_tax        -- 条件別手数料額(税抜)
        , cond_tax_amt              -- 条件別消費税額
        , electric_amt_tax          -- 電気料(税込)
        , electric_amt_no_tax       -- 電気料(税抜)
        , electric_tax_amt          -- 電気料消費税額
        , csh_rcpt_discount_amt     -- 入金値引額
        , csh_rcpt_discount_amt_tax -- 入金値引消費税額
        , consumption_tax_class     -- 消費税区分
        , tax_code                  -- 税金コード
        , tax_rate                  -- 消費税率
        , term_code                 -- 支払条件
        , closing_date              -- 締め日
        , expect_payment_date       -- 支払予定日
        , calc_target_period_from   -- 計算対象期間(FROM)
        , calc_target_period_to     -- 計算対象期間(TO)
        , cond_bm_interface_status  -- 連携ステータス(条件別販手販協)
        , cond_bm_interface_date    -- 連携日(条件別販手販協)
        , bm_interface_status       -- 連携ステータス(販手残高)
        , bm_interface_date         -- 連携日(販手残高)
        , ar_interface_status       -- 連携ステータス(AR)
        , ar_interface_date         -- 連携日(AR)
        , amt_fix_status            -- 金額確定ステータス
        , created_by                -- 作成者
        , creation_date             -- 作成日
        , last_updated_by           -- 最終更新者
        , last_update_date          -- 最終更新日
        , last_update_login         -- 最終更新ログイン
        , request_id                -- 要求ID
        , program_application_id    -- コンカレント・プログラム・アプリケーションID
        , program_id                -- コンカレント・プログラムID
        , program_update_date       -- プログラム更新日
        )
        VALUES (
          xxcok_cond_bm_support_s01.NEXTVAL                   -- 条件別販手販協ID
        , i_xcbs_data_tab( i ).base_code                 -- 拠点コード
        , i_xcbs_data_tab( i ).emp_code                  -- 担当者コード
        , i_xcbs_data_tab( i ).delivery_cust_code        -- 顧客【納品先】
        , i_xcbs_data_tab( i ).demand_to_cust_code       -- 顧客【請求先】
        , i_xcbs_data_tab( i ).acctg_year                -- 会計年度
        , i_xcbs_data_tab( i ).chain_store_code          -- チェーン店コード
        , i_xcbs_data_tab( i ).supplier_code             -- 仕入先コード
        , i_xcbs_data_tab( i ).supplier_site_code        -- 仕入先サイトコード
        , i_xcbs_data_tab( i ).calc_type                 -- 計算条件
        , i_xcbs_data_tab( i ).delivery_date             -- 納品日年月
        , i_xcbs_data_tab( i ).delivery_qty              -- 納品数量
        , i_xcbs_data_tab( i ).delivery_unit_type        -- 納品単位
        , i_xcbs_data_tab( i ).selling_amt_tax           -- 売上金額(税込)
        , i_xcbs_data_tab( i ).rebate_rate               -- 割戻率
        , i_xcbs_data_tab( i ).rebate_amt                -- 割戻額
        , i_xcbs_data_tab( i ).container_type_code       -- 容器区分コード
        , i_xcbs_data_tab( i ).selling_price             -- 売価金額
        , i_xcbs_data_tab( i ).cond_bm_amt_tax           -- 条件別手数料額(税込)
        , i_xcbs_data_tab( i ).cond_bm_amt_no_tax        -- 条件別手数料額(税抜)
        , i_xcbs_data_tab( i ).cond_tax_amt              -- 条件別消費税額
        , i_xcbs_data_tab( i ).electric_amt_tax          -- 電気料(税込)
        , i_xcbs_data_tab( i ).electric_amt_no_tax       -- 電気料(税抜)
        , i_xcbs_data_tab( i ).electric_tax_amt          -- 電気料消費税額
        , i_xcbs_data_tab( i ).csh_rcpt_discount_amt     -- 入金値引額
        , i_xcbs_data_tab( i ).csh_rcpt_discount_amt_tax -- 入金値引消費税額
        , i_xcbs_data_tab( i ).consumption_tax_class     -- 消費税区分
        , i_xcbs_data_tab( i ).tax_code                  -- 税金コード
        , i_xcbs_data_tab( i ).tax_rate                  -- 消費税率
        , i_xcbs_data_tab( i ).term_code                 -- 支払条件
        , i_xcbs_data_tab( i ).closing_date              -- 締め日
        , i_xcbs_data_tab( i ).expect_payment_date       -- 支払予定日
        , i_xcbs_data_tab( i ).calc_target_period_from   -- 計算対象期間(FROM)
        , i_xcbs_data_tab( i ).calc_target_period_to     -- 計算対象期間(TO)
        , i_xcbs_data_tab( i ).cond_bm_interface_status  -- 連携ステータス(条件別販手販協)
        , i_xcbs_data_tab( i ).cond_bm_interface_date    -- 連携日(条件別販手販協)
        , i_xcbs_data_tab( i ).bm_interface_status       -- 連携ステータス(販手残高)
        , i_xcbs_data_tab( i ).bm_interface_date         -- 連携日(販手残高)
        , i_xcbs_data_tab( i ).ar_interface_status       -- 連携ステータス(AR)
        , i_xcbs_data_tab( i ).ar_interface_date         -- 連携日(AR)
        , lv_fix_status                                  -- 金額確定ステータス
        , cn_created_by                                       -- 作成者
        , SYSDATE                                             -- 作成日
        , cn_last_updated_by                                  -- 最終更新者
        , SYSDATE                                             -- 最終更新日
        , cn_last_update_login                                -- 最終更新ログイン
        , cn_request_id                                       -- 要求ID
        , cn_program_application_id                           -- コンカレント・プログラム・アプリケーションID
        , cn_program_id                                       -- コンカレント・プログラムID
        , SYSDATE                                             -- プログラム更新日
        );
-- 2012/06/19 Ver.3.15 [E_本稼動_08751] SCSK S.Niki ADD START
      -- 件数カウント
      gn_insert_xcbs_cnt := gn_insert_xcbs_cnt + 1;
      gn_target_cnt      := gn_target_cnt + 1;
      gn_normal_cnt      := gn_normal_cnt + 1;
-- 2012/06/19 Ver.3.15 [E_本稼動_08751] SCSK S.Niki ADD END
      END IF;
    END LOOP insert_xcbs_loop;
    --==================================================
    -- 出力パラメータ設定
    --==================================================
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
    ov_retcode := lv_end_retcode;
--
  EXCEPTION
    -- *** エラー終了 ***
    WHEN error_proc_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 処理部共通例外 ***
    WHEN global_process_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := lv_end_retcode;
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
END insert_xcbs;
--
  /**********************************************************************************
   * Procedure Name   : set_xcbs_data
   * Description      : 条件別販手販協情報の設定(A-9)
   ***********************************************************************************/
  PROCEDURE set_xcbs_data(
    ov_errbuf                      OUT VARCHAR2        -- エラー・メッセージ
  , ov_retcode                     OUT VARCHAR2        -- リターン・コード
  , ov_errmsg                      OUT VARCHAR2        -- ユーザー・エラー・メッセージ
  , i_get_sales_data_rec           IN  get_sales_data_rtype  -- 販売実績情報レコード
  , o_xcbs_data_tab                OUT xcbs_data_ttype       -- 条件別販手販協情報
  )
  IS
    --==================================================
    -- ローカル定数
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'set_xcbs_data';    -- プログラム名
    cn_index_1                     CONSTANT NUMBER       := 1;                  -- BM1_索引
    cn_index_2                     CONSTANT NUMBER       := 2;                  -- BM2_索引
    cn_index_3                     CONSTANT NUMBER       := 3;                  -- BM3_索引
    --==================================================
    -- ローカル変数
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- エラー・メッセージ
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ユーザー・エラー・メッセージ
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- 出力用メッセージ
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- メッセージ出力関数戻り値
--
    ln_bm1_rcpt_discount_amt_notax NUMBER         DEFAULT NULL;                 -- BM1_入金値引額(税抜)_一時格納
    ln_bm2_rcpt_discount_amt_notax NUMBER         DEFAULT NULL;                 -- BM2_入金値引額(税抜)_一時格納
    ln_bm3_rcpt_discount_amt_notax NUMBER         DEFAULT NULL;                 -- BM3_入金値引額(税抜)_一時格納
--
    -- 連携ステータス(条件別販手販協)_一時格納
    lv_cond_bm_interface_status    xxcok_cond_bm_support.cond_bm_interface_status%TYPE DEFAULT NULL;
    -- 連携ステータス(販手残高)_一時格納
    lv_bm_interface_status         xxcok_cond_bm_support.bm_interface_status%TYPE      DEFAULT NULL;
    -- 連携ステータス(AR)_一時格納
    lv_ar_interface_status         xxcok_cond_bm_support.ar_interface_status%TYPE      DEFAULT NULL;
--
    l_xcbs_data_tab                     xcbs_data_ttype;                             -- 条件別販手販協テーブルタイプ
--
  BEGIN
    --==================================================
    -- ステータス初期化
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- 初期化
    --==================================================
    l_xcbs_data_tab( cn_index_1 ) := NULL;
    l_xcbs_data_tab( cn_index_2 ) := NULL;
    l_xcbs_data_tab( cn_index_3 ) := NULL;
    --==================================================
    -- 1.販売実績情報の業態(小分類)が '25':フルサービスVDの場合、VDBM(税込)を設定します。
    --==================================================
    IF( i_get_sales_data_rec.ship_gyotai_sho = cv_gyotai_sho_25 ) THEN
      -- 販売実績情報の BM1 BM率(%)が NULL以外 の場合
      IF( i_get_sales_data_rec.bm1_pct IS NOT NULL ) THEN
        l_xcbs_data_tab( cn_index_1 ).cond_bm_amt_tax       := i_get_sales_data_rec.bm1_cond_bm_tax_pct;
        l_xcbs_data_tab( cn_index_1 ).csh_rcpt_discount_amt := NULL;
      -- 販売実績情報の BM1 BM金額が NULL 以外の場合
      ELSIF( i_get_sales_data_rec.bm1_amt IS NOT NULL ) THEN
        l_xcbs_data_tab( cn_index_1 ).cond_bm_amt_tax       := i_get_sales_data_rec.bm1_cond_bm_amt_tax;
        l_xcbs_data_tab( cn_index_1 ).csh_rcpt_discount_amt := NULL;
      END IF;
--
      -- 販売実績情報の BM2 BM率(%)が NULL以外 の場合
      IF( i_get_sales_data_rec.bm2_pct IS NOT NULL ) THEN
        l_xcbs_data_tab( cn_index_2 ).cond_bm_amt_tax       := i_get_sales_data_rec.bm2_cond_bm_tax_pct;
        l_xcbs_data_tab( cn_index_2 ).csh_rcpt_discount_amt := NULL;
      -- 販売実績情報の BM2 BM金額が NULL 以外の場合
      ELSIF( i_get_sales_data_rec.bm2_amt IS NOT NULL ) THEN
        l_xcbs_data_tab( cn_index_2 ).cond_bm_amt_tax       := i_get_sales_data_rec.bm2_cond_bm_amt_tax;
        l_xcbs_data_tab( cn_index_2 ).csh_rcpt_discount_amt := NULL;
      END IF;
--
      -- 販売実績情報の BM3 BM率(%)が NULL以外 の場合
      IF( i_get_sales_data_rec.bm3_pct IS NOT NULL ) THEN
        l_xcbs_data_tab( cn_index_3 ).cond_bm_amt_tax       := i_get_sales_data_rec.bm3_cond_bm_tax_pct;
        l_xcbs_data_tab( cn_index_3 ).csh_rcpt_discount_amt := NULL;
      -- 販売実績情報の BM3 BM金額が NULL 以外の場合
      ELSIF( i_get_sales_data_rec.bm3_amt IS NOT NULL ) THEN
        l_xcbs_data_tab( cn_index_3 ).cond_bm_amt_tax       := i_get_sales_data_rec.bm3_cond_bm_amt_tax;
        l_xcbs_data_tab( cn_index_3 ).csh_rcpt_discount_amt := NULL;
      END IF;
    --==================================================
    -- 2.販売実績情報の業態(小分類)が '25':フルサービスVD以外の場合、入金値引額(税込)を設定します。
    --==================================================
    ELSIF( i_get_sales_data_rec.ship_gyotai_sho <> cv_gyotai_sho_25 ) THEN
      -- 販売実績情報の BM1 BM率(%)が NULL以外 の場合
      IF( i_get_sales_data_rec.bm1_pct IS NOT NULL ) THEN
        l_xcbs_data_tab( cn_index_1 ).cond_bm_amt_tax       := NULL;
        l_xcbs_data_tab( cn_index_1 ).csh_rcpt_discount_amt := i_get_sales_data_rec.bm1_cond_bm_tax_pct;
      -- 販売実績情報の BM1 BM金額が NULL 以外の場合
      ELSIF( i_get_sales_data_rec.bm1_amt IS NOT NULL ) THEN
        l_xcbs_data_tab( cn_index_1 ).cond_bm_amt_tax       := NULL;
        l_xcbs_data_tab( cn_index_1 ).csh_rcpt_discount_amt := i_get_sales_data_rec.bm1_cond_bm_amt_tax;
      END IF;
--
      -- 販売実績情報の BM2 BM率(%)が NULL以外 の場合
      IF( i_get_sales_data_rec.bm2_pct IS NOT NULL ) THEN
        l_xcbs_data_tab( cn_index_2 ).cond_bm_amt_tax       := NULL;
        l_xcbs_data_tab( cn_index_2 ).csh_rcpt_discount_amt := i_get_sales_data_rec.bm2_cond_bm_tax_pct;
      -- 販売実績情報の BM2 BM金額が NULL 以外の場合
      ELSIF( i_get_sales_data_rec.bm2_amt IS NOT NULL ) THEN
        l_xcbs_data_tab( cn_index_2 ).cond_bm_amt_tax       := NULL;
        l_xcbs_data_tab( cn_index_2 ).csh_rcpt_discount_amt := i_get_sales_data_rec.bm2_cond_bm_amt_tax;
      END IF;
--
      -- 販売実績情報の BM3 BM率(%)が NULL以外 の場合
      IF( i_get_sales_data_rec.bm3_pct IS NOT NULL ) THEN
        l_xcbs_data_tab( cn_index_3 ).cond_bm_amt_tax       := NULL;
        l_xcbs_data_tab( cn_index_3 ).csh_rcpt_discount_amt := i_get_sales_data_rec.bm3_cond_bm_tax_pct;
      -- 販売実績情報の BM3 BM金額が NULL 以外の場合
      ELSIF( i_get_sales_data_rec.bm3_amt IS NOT NULL ) THEN
        l_xcbs_data_tab( cn_index_3 ).cond_bm_amt_tax       := NULL;
        l_xcbs_data_tab( cn_index_3 ).csh_rcpt_discount_amt := i_get_sales_data_rec.bm3_cond_bm_amt_tax;
      END IF;
    END IF;
    --==================================================
    -- 3.各VDBM(税込)、入金値引額(税込)、電気料(税込)が NULL 以外の場合、税抜金額および消費税額を算出します。
    --==================================================
    -- BM1 VDBM(税抜)の設定
    IF( l_xcbs_data_tab( cn_index_1 ).cond_bm_amt_tax IS NOT NULL ) THEN
      l_xcbs_data_tab( cn_index_1 ).cond_bm_amt_no_tax
        := l_xcbs_data_tab( cn_index_1 ).cond_bm_amt_tax / ( 1 + ( i_get_sales_data_rec.tax_rate / 100 ) );
    END IF;
    -- BM1 入金値引額(税抜)の設定
    IF( l_xcbs_data_tab( cn_index_1 ).csh_rcpt_discount_amt IS NOT NULL ) THEN
      ln_bm1_rcpt_discount_amt_notax
        := l_xcbs_data_tab( cn_index_1 ).csh_rcpt_discount_amt / ( 1 + ( i_get_sales_data_rec.tax_rate / 100 )  );
    END IF;
    -- BM1 電気料(税抜)の設定
    IF( i_get_sales_data_rec.bm1_electric_amt_tax IS NOT NULL ) THEN
      l_xcbs_data_tab( cn_index_1 ).electric_amt_no_tax
        := i_get_sales_data_rec.bm1_electric_amt_tax / ( 1 + ( i_get_sales_data_rec.tax_rate / 100 ) );
    END IF;
    -- BM2 VDBM(税抜)の設定
    IF( l_xcbs_data_tab( cn_index_2 ).cond_bm_amt_tax IS NOT NULL ) THEN
      l_xcbs_data_tab( cn_index_2 ).cond_bm_amt_no_tax
        := l_xcbs_data_tab( cn_index_2 ).cond_bm_amt_tax / ( 1 + ( i_get_sales_data_rec.tax_rate / 100 ) );
    END IF;
    -- BM2 入金値引額(税抜)の設定
    IF( l_xcbs_data_tab( cn_index_2 ).csh_rcpt_discount_amt IS NOT NULL ) THEN
      ln_bm2_rcpt_discount_amt_notax
        := l_xcbs_data_tab( cn_index_2 ).csh_rcpt_discount_amt / ( 1 + ( i_get_sales_data_rec.tax_rate / 100 ) );
    END IF;
    -- BM2 電気料(税抜)の設定
    IF( i_get_sales_data_rec.bm2_electric_amt_tax IS NOT NULL ) THEN
      l_xcbs_data_tab( cn_index_2 ).electric_amt_no_tax
        := i_get_sales_data_rec.bm2_electric_amt_tax / ( 1 + ( i_get_sales_data_rec.tax_rate / 100 ) );
    END IF;
    -- BM3 VDBM(税抜)の設定
    IF( l_xcbs_data_tab( cn_index_3 ).cond_bm_amt_tax IS NOT NULL ) THEN
      l_xcbs_data_tab( cn_index_3 ).cond_bm_amt_no_tax
        := l_xcbs_data_tab( cn_index_3 ).cond_bm_amt_tax / ( 1 + ( i_get_sales_data_rec.tax_rate/ 100 ) );
    END IF;
    -- BM3 入金値引額(税抜)の設定
    IF( l_xcbs_data_tab( cn_index_3 ).csh_rcpt_discount_amt IS NOT NULL ) THEN
      ln_bm3_rcpt_discount_amt_notax
        := l_xcbs_data_tab( cn_index_3 ).csh_rcpt_discount_amt / ( 1 + ( i_get_sales_data_rec.tax_rate / 100 ) );
    END IF;
    -- BM3 電気料(税抜)の設定
    IF( i_get_sales_data_rec.bm3_electric_amt_tax IS NOT NULL ) THEN
      l_xcbs_data_tab( cn_index_3 ).electric_amt_no_tax
        := i_get_sales_data_rec.bm3_electric_amt_tax / ( 1 + ( i_get_sales_data_rec.tax_rate / 100 ) );
    END IF;
    --==================================================
    -- 端数処理区分による取得値の端数処理
    --==================================================
    -- 販売実績情報の端数処理区分が 'NEAREST':四捨五入の場合、少数点以下の端数を四捨五入します。
    IF( i_get_sales_data_rec.tax_rounding_rule = cv_tax_rounding_rule_nearest ) THEN
      l_xcbs_data_tab( cn_index_1 ).cond_bm_amt_no_tax  := ROUND( l_xcbs_data_tab( cn_index_1 ).cond_bm_amt_no_tax );
      ln_bm1_rcpt_discount_amt_notax                    := ROUND( ln_bm1_rcpt_discount_amt_notax );
      l_xcbs_data_tab( cn_index_1 ).electric_amt_no_tax := ROUND( l_xcbs_data_tab( cn_index_1 ).electric_amt_no_tax );
      l_xcbs_data_tab( cn_index_2 ).cond_bm_amt_no_tax  := ROUND( l_xcbs_data_tab( cn_index_2 ).cond_bm_amt_no_tax );
      ln_bm2_rcpt_discount_amt_notax                    := ROUND( ln_bm2_rcpt_discount_amt_notax );
      l_xcbs_data_tab( cn_index_2 ).electric_amt_no_tax := ROUND( l_xcbs_data_tab( cn_index_2 ).electric_amt_no_tax );
      l_xcbs_data_tab( cn_index_3 ).cond_bm_amt_no_tax  := ROUND( l_xcbs_data_tab( cn_index_3 ).cond_bm_amt_no_tax );
      ln_bm3_rcpt_discount_amt_notax                    := ROUND( ln_bm3_rcpt_discount_amt_notax );
      l_xcbs_data_tab( cn_index_3 ).electric_amt_no_tax := ROUND( l_xcbs_data_tab( cn_index_3 ).electric_amt_no_tax );
    -- 販売実績情報の端数処理区分が 'UP':切り上げの場合、小数点以下の端数を切り上げします。
    ELSIF ( i_get_sales_data_rec.tax_rounding_rule = cv_tax_rounding_rule_up ) THEN
      IF( l_xcbs_data_tab( cn_index_1 ).cond_bm_amt_no_tax > 0 )    THEN
        l_xcbs_data_tab( cn_index_1 ).cond_bm_amt_no_tax  := CEIL( l_xcbs_data_tab( cn_index_1 ).cond_bm_amt_no_tax );
      ELSIF ( l_xcbs_data_tab( cn_index_1 ).cond_bm_amt_no_tax < 0 ) THEN
        l_xcbs_data_tab( cn_index_1 ).cond_bm_amt_no_tax  := FLOOR( l_xcbs_data_tab( cn_index_1 ).cond_bm_amt_no_tax );
      END IF;
      IF( ln_bm1_rcpt_discount_amt_notax > 0 )    THEN
        ln_bm1_rcpt_discount_amt_notax  := CEIL( ln_bm1_rcpt_discount_amt_notax );
      ELSIF( ln_bm1_rcpt_discount_amt_notax < 0 ) THEN
        ln_bm1_rcpt_discount_amt_notax  := FLOOR( ln_bm1_rcpt_discount_amt_notax );
      END IF;
      IF( l_xcbs_data_tab( cn_index_1 ).electric_amt_no_tax > 0 )    THEN
        l_xcbs_data_tab( cn_index_1 ).electric_amt_no_tax  := CEIL( l_xcbs_data_tab( cn_index_1 ).electric_amt_no_tax );
      ELSIF( l_xcbs_data_tab( cn_index_1 ).electric_amt_no_tax < 0 ) THEN
        l_xcbs_data_tab( cn_index_1 ).electric_amt_no_tax  := FLOOR( l_xcbs_data_tab( cn_index_1 ).electric_amt_no_tax );
      END IF;
      IF( l_xcbs_data_tab( cn_index_2 ).cond_bm_amt_no_tax > 0 )    THEN
        l_xcbs_data_tab( cn_index_2 ).cond_bm_amt_no_tax  := CEIL( l_xcbs_data_tab( cn_index_2 ).cond_bm_amt_no_tax );
      ELSIF( l_xcbs_data_tab( cn_index_2 ).cond_bm_amt_no_tax < 0 ) THEN
        l_xcbs_data_tab( cn_index_2 ).cond_bm_amt_no_tax  := FLOOR( l_xcbs_data_tab( cn_index_2 ).cond_bm_amt_no_tax );
      END IF;
      IF( ln_bm2_rcpt_discount_amt_notax > 0 )    THEN
        ln_bm2_rcpt_discount_amt_notax  := CEIL( ln_bm2_rcpt_discount_amt_notax );
      ELSIF ( ln_bm2_rcpt_discount_amt_notax < 0 ) THEN
        ln_bm2_rcpt_discount_amt_notax  := FLOOR( ln_bm2_rcpt_discount_amt_notax );
      END IF;
      IF( l_xcbs_data_tab( cn_index_2 ).electric_amt_no_tax > 0 )    THEN
        l_xcbs_data_tab( cn_index_2 ).electric_amt_no_tax  := CEIL( l_xcbs_data_tab( cn_index_2 ).electric_amt_no_tax );
      ELSIF( l_xcbs_data_tab( cn_index_2 ).electric_amt_no_tax < 0 ) THEN
        l_xcbs_data_tab( cn_index_2 ).electric_amt_no_tax  := FLOOR( l_xcbs_data_tab( cn_index_2 ).electric_amt_no_tax );
      END IF;
      IF( l_xcbs_data_tab( cn_index_3 ).cond_bm_amt_no_tax > 0 )    THEN
        l_xcbs_data_tab( cn_index_3 ).cond_bm_amt_no_tax  := CEIL( l_xcbs_data_tab( cn_index_3 ).cond_bm_amt_no_tax );
      ELSIF( l_xcbs_data_tab( cn_index_3 ).cond_bm_amt_no_tax < 0 ) THEN
        l_xcbs_data_tab( cn_index_3 ).cond_bm_amt_no_tax  := FLOOR( l_xcbs_data_tab( cn_index_3 ).cond_bm_amt_no_tax );
      END IF;
      IF( ln_bm3_rcpt_discount_amt_notax > 0 )    THEN
        ln_bm3_rcpt_discount_amt_notax  := CEIL( ln_bm3_rcpt_discount_amt_notax );
      ELSIF( ln_bm3_rcpt_discount_amt_notax < 0 ) THEN
        ln_bm3_rcpt_discount_amt_notax  := FLOOR( ln_bm3_rcpt_discount_amt_notax );
      END IF;
      IF( l_xcbs_data_tab( cn_index_3 ).electric_amt_no_tax > 0 )    THEN
        l_xcbs_data_tab( cn_index_3 ).electric_amt_no_tax  := CEIL( l_xcbs_data_tab( cn_index_3 ).electric_amt_no_tax );
      ELSIF ( l_xcbs_data_tab( cn_index_3 ).electric_amt_no_tax < 0 ) THEN
        l_xcbs_data_tab( cn_index_3 ).electric_amt_no_tax  := FLOOR( l_xcbs_data_tab( cn_index_3 ).electric_amt_no_tax );
      END IF;
    -- 上記以外の場合、'DOWN':切り捨てが設定されていることとし、少数点以下の端数を切り捨てします。
    ELSE
      l_xcbs_data_tab( cn_index_1 ).cond_bm_amt_no_tax  := TRUNC( l_xcbs_data_tab( cn_index_1 ).cond_bm_amt_no_tax );
      ln_bm1_rcpt_discount_amt_notax                    := TRUNC( ln_bm1_rcpt_discount_amt_notax );
      l_xcbs_data_tab( cn_index_1 ).electric_amt_no_tax := TRUNC( l_xcbs_data_tab( cn_index_1 ).electric_amt_no_tax );
      l_xcbs_data_tab( cn_index_2 ).cond_bm_amt_no_tax  := TRUNC( l_xcbs_data_tab( cn_index_2 ).cond_bm_amt_no_tax );
      ln_bm2_rcpt_discount_amt_notax                    := TRUNC( ln_bm2_rcpt_discount_amt_notax );
      l_xcbs_data_tab( cn_index_2 ).electric_amt_no_tax := TRUNC( l_xcbs_data_tab( cn_index_2 ).electric_amt_no_tax );
      l_xcbs_data_tab( cn_index_3 ).cond_bm_amt_no_tax  := TRUNC( l_xcbs_data_tab( cn_index_3 ).cond_bm_amt_no_tax );
      ln_bm3_rcpt_discount_amt_notax                    := TRUNC( ln_bm3_rcpt_discount_amt_notax );
      l_xcbs_data_tab( cn_index_3 ).electric_amt_no_tax := TRUNC( l_xcbs_data_tab( cn_index_3 ).electric_amt_no_tax );
    END IF;
    --==================================================
    -- 消費税額算出
    --==================================================
    -- 消費税額
    l_xcbs_data_tab( cn_index_1 ).cond_tax_amt
      := l_xcbs_data_tab( cn_index_1 ).cond_bm_amt_tax - l_xcbs_data_tab( cn_index_1 ).cond_bm_amt_no_tax;
    l_xcbs_data_tab( cn_index_2 ).cond_tax_amt
      := l_xcbs_data_tab( cn_index_2 ).cond_bm_amt_tax - l_xcbs_data_tab( cn_index_2 ).cond_bm_amt_no_tax;
    l_xcbs_data_tab( cn_index_3 ).cond_tax_amt
      := l_xcbs_data_tab( cn_index_3 ).cond_bm_amt_tax - l_xcbs_data_tab( cn_index_3 ).cond_bm_amt_no_tax;
    -- 入金値引消費税額
    l_xcbs_data_tab( cn_index_1 ).csh_rcpt_discount_amt_tax
      := l_xcbs_data_tab( cn_index_1 ).csh_rcpt_discount_amt - ln_bm1_rcpt_discount_amt_notax;
    l_xcbs_data_tab( cn_index_2 ).csh_rcpt_discount_amt_tax
      := l_xcbs_data_tab( cn_index_2 ).csh_rcpt_discount_amt - ln_bm2_rcpt_discount_amt_notax;
    l_xcbs_data_tab( cn_index_3 ).csh_rcpt_discount_amt_tax
      := l_xcbs_data_tab( cn_index_3 ).csh_rcpt_discount_amt - ln_bm3_rcpt_discount_amt_notax;
    -- 電気料消費税額
    l_xcbs_data_tab( cn_index_1 ).electric_tax_amt
      := i_get_sales_data_rec.bm1_electric_amt_tax - l_xcbs_data_tab( cn_index_1 ).electric_amt_no_tax;
    l_xcbs_data_tab( cn_index_2 ).electric_tax_amt
      := i_get_sales_data_rec.bm2_electric_amt_tax - l_xcbs_data_tab( cn_index_2 ).electric_amt_no_tax;
    l_xcbs_data_tab( cn_index_3 ).electric_tax_amt
      := i_get_sales_data_rec.bm3_electric_amt_tax - l_xcbs_data_tab( cn_index_3 ).electric_amt_no_tax;
    --==================================================
    -- 4.各連携ステータス
    --==================================================
-- 2009/10/27 Ver.3.3 [障害E_T4_00094] SCS K.Yamaguchi REPAIR START
---- 2009/10/02 Ver.3.1 [仕様変更I_E_566] SCS K.Yamaguchi ADD START
--    -- 支払条件が即時払い
--    IF( i_get_sales_data_rec.term_name = gv_instantly_term_name ) THEN
--      lv_cond_bm_interface_status := cv_xcbs_if_status_off;    -- 条件別販手販協 不要
--      lv_bm_interface_status      := cv_xcbs_if_status_off;    -- 販手残高       不要
--      lv_ar_interface_status      := cv_xcbs_if_status_off;    -- AR             不要
---- 2009/10/02 Ver.3.1 [仕様変更I_E_566] SCS K.Yamaguchi ADD END
---- 2009/10/02 Ver.3.1 [仕様変更I_E_566] SCS K.Yamaguchi REPAIR START
----    IF(     ( i_get_sales_data_rec.ship_gyotai_sho  = cv_gyotai_sho_25 )
----        AND ( i_get_sales_data_rec.amount_fix_date <> gd_process_date  )
----    ) THEN
--    -- 販売実績情報の業態(小分類)が '25'：フルサービスVD、かつ業務日付が販売実績情報の計算対象期間(TO)と一致しない
--    ELSIF(     ( i_get_sales_data_rec.ship_gyotai_sho  = cv_gyotai_sho_25 )
--           AND ( i_get_sales_data_rec.amount_fix_date <> gd_process_date  )
--    ) THEN
---- 2009/10/02 Ver.3.1 [仕様変更I_E_566] SCS K.Yamaguchi REPAIR END
    -- 販売実績情報の業態(小分類)が '25'：フルサービスVD、かつ業務日付が販売実績情報の計算対象期間(TO)と一致しない
    IF(     ( i_get_sales_data_rec.ship_gyotai_sho  = cv_gyotai_sho_25 )
           AND ( i_get_sales_data_rec.amount_fix_date <> gd_process_date  )
    ) THEN
-- 2009/10/27 Ver.3.3 [障害E_T4_00094] SCS K.Yamaguchi REPAIR END
      lv_cond_bm_interface_status := cv_xcbs_if_status_off;    -- 条件別販手販協 不要
      lv_bm_interface_status      := cv_xcbs_if_status_no;     -- 販手残高       未処理
      lv_ar_interface_status      := cv_xcbs_if_status_off;    -- AR             不要
    -- 販売実績情報の業態(小分類)が '25'：フルサービスVD、かつ業務日付が販売実績情報の計算対象期間(TO)と一致する
    ELSIF(     ( i_get_sales_data_rec.ship_gyotai_sho  = cv_gyotai_sho_25 )
           AND ( i_get_sales_data_rec.amount_fix_date  = gd_process_date  )
    ) THEN
      lv_cond_bm_interface_status := cv_xcbs_if_status_no;     -- 条件別販手販協 未処理
      lv_bm_interface_status      := cv_xcbs_if_status_no;     -- 販手残高       未処理
      lv_ar_interface_status      := cv_xcbs_if_status_off;    -- AR             不要
    -- 販売実績情報の業態(小分類)が '25'：フルサービスVD以外、かつ業務日付が販売実績情報の計算対象期間(TO)と一致しない
    ELSIF(     ( i_get_sales_data_rec.ship_gyotai_sho <> cv_gyotai_sho_25 )
           AND ( i_get_sales_data_rec.amount_fix_date <> gd_process_date  )
    ) THEN
      lv_cond_bm_interface_status := cv_xcbs_if_status_off;    -- 条件別販手販協 不要
      lv_bm_interface_status      := cv_xcbs_if_status_off;    -- 販手残高       不要
      lv_ar_interface_status      := cv_xcbs_if_status_off;    -- AR             不要
    -- 販売実績情報の業態(小分類)が '25'：フルサービスVD、かつ業務日付が販売実績情報の計算対象期間(TO)と一致する
    ELSIF(     ( i_get_sales_data_rec.ship_gyotai_sho  <> cv_gyotai_sho_25 )
           AND ( i_get_sales_data_rec.amount_fix_date   = gd_process_date  )
    ) THEN
      lv_cond_bm_interface_status := cv_xcbs_if_status_off;    -- 条件別販手販協 不要
      lv_bm_interface_status      := cv_xcbs_if_status_off;    -- 販手残高       不要
      lv_ar_interface_status      := cv_xcbs_if_status_no;     -- AR             未処理
    END IF;
    --==================================================
    -- その他値設定
    --==================================================
    -- 仕入先コード
    l_xcbs_data_tab( cn_index_1 ).supplier_code := i_get_sales_data_rec.bm1_vendor_code;
    l_xcbs_data_tab( cn_index_2 ).supplier_code := i_get_sales_data_rec.bm2_vendor_code;
    l_xcbs_data_tab( cn_index_3 ).supplier_code := i_get_sales_data_rec.bm3_vendor_code;
    -- 仕入先サイトコード
    l_xcbs_data_tab( cn_index_1 ).supplier_site_code := i_get_sales_data_rec.bm1_vendor_site_code;
    l_xcbs_data_tab( cn_index_2 ).supplier_site_code := i_get_sales_data_rec.bm2_vendor_site_code;
    l_xcbs_data_tab( cn_index_3 ).supplier_site_code := i_get_sales_data_rec.bm3_vendor_site_code;
    -- BM率(%)
    l_xcbs_data_tab( cn_index_1 ).rebate_rate := i_get_sales_data_rec.bm1_pct;
    l_xcbs_data_tab( cn_index_2 ).rebate_rate := i_get_sales_data_rec.bm2_pct;
    l_xcbs_data_tab( cn_index_3 ).rebate_rate := i_get_sales_data_rec.bm3_pct;
    -- BM金額
    l_xcbs_data_tab( cn_index_1 ).rebate_amt := i_get_sales_data_rec.bm1_amt;
    l_xcbs_data_tab( cn_index_2 ).rebate_amt := i_get_sales_data_rec.bm2_amt;
    l_xcbs_data_tab( cn_index_3 ).rebate_amt := i_get_sales_data_rec.bm3_amt;
    -- 電気料(税込)
    l_xcbs_data_tab( cn_index_1 ).electric_amt_tax := i_get_sales_data_rec.bm1_electric_amt_tax;
    l_xcbs_data_tab( cn_index_2 ).electric_amt_tax := i_get_sales_data_rec.bm2_electric_amt_tax;
    l_xcbs_data_tab( cn_index_3 ).electric_amt_tax := i_get_sales_data_rec.bm3_electric_amt_tax;
    --==================================================
    -- 5.取得した内容を条件別販手販協情報に設定します。
    --==================================================
    << set_xcbs_data_loop >>
    FOR i IN cn_index_1 .. cn_index_3 LOOP
      -- 共通項目をループで設定
      l_xcbs_data_tab( i ).base_code                 := i_get_sales_data_rec.base_code;                 -- 拠点コード
      l_xcbs_data_tab( i ).emp_code                  := i_get_sales_data_rec.emp_code;                  -- 担当者コード
      l_xcbs_data_tab( i ).delivery_cust_code        := i_get_sales_data_rec.ship_cust_code;            -- 顧客【納品先】
      l_xcbs_data_tab( i ).demand_to_cust_code       := i_get_sales_data_rec.bill_cust_code;            -- 顧客【請求先】
      l_xcbs_data_tab( i ).acctg_year                := i_get_sales_data_rec.period_year;               -- 会計年度
      l_xcbs_data_tab( i ).chain_store_code          := i_get_sales_data_rec.ship_delivery_chain_code;  -- チェーン店コード
      l_xcbs_data_tab( i ).calc_type                 := i_get_sales_data_rec.calc_type;                 -- 計算条件
      l_xcbs_data_tab( i ).delivery_date             := i_get_sales_data_rec.delivery_ym;               -- 納品日年月
      l_xcbs_data_tab( i ).delivery_qty              := i_get_sales_data_rec.dlv_qty;                   -- 納品数量
      l_xcbs_data_tab( i ).delivery_unit_type        := i_get_sales_data_rec.dlv_uom_code;              -- 納品単位
      l_xcbs_data_tab( i ).selling_amt_tax           := i_get_sales_data_rec.amount_inc_tax;            -- 売上金額(税込)
      l_xcbs_data_tab( i ).container_type_code       := i_get_sales_data_rec.container_code;            -- 容器区分コード
      l_xcbs_data_tab( i ).selling_price             := i_get_sales_data_rec.dlv_unit_price;            -- 売価金額
      l_xcbs_data_tab( i ).consumption_tax_class     := i_get_sales_data_rec.tax_div;                   -- 消費税区分
      l_xcbs_data_tab( i ).tax_code                  := i_get_sales_data_rec.tax_code;                  -- 税金コード
      l_xcbs_data_tab( i ).tax_rate                  := i_get_sales_data_rec.tax_rate;                  -- 消費税率
      l_xcbs_data_tab( i ).term_code                 := i_get_sales_data_rec.term_name;                 -- 支払条件
      l_xcbs_data_tab( i ).closing_date              := i_get_sales_data_rec.closing_date;              -- 締め日
      l_xcbs_data_tab( i ).expect_payment_date       := i_get_sales_data_rec.expect_payment_date;       -- 支払予定日
      l_xcbs_data_tab( i ).calc_target_period_from   := i_get_sales_data_rec.calc_target_period_from;   -- 計算対象期間(FROM)
      l_xcbs_data_tab( i ).calc_target_period_to     := i_get_sales_data_rec.calc_target_period_to;     -- 計算対象期間(TO)
      l_xcbs_data_tab( i ).cond_bm_interface_status  := lv_cond_bm_interface_status;                    -- 連携ステータス(条件別販手販協)
      l_xcbs_data_tab( i ).cond_bm_interface_date    := NULL;                                           -- 連携日(条件別販手販協)
      l_xcbs_data_tab( i ).bm_interface_status       := lv_bm_interface_status;                         -- 連携ステータス(販手残高)
      l_xcbs_data_tab( i ).bm_interface_date         := NULL;                                           -- 連携日(販手残高)
      l_xcbs_data_tab( i ).ar_interface_status       := lv_ar_interface_status;                         -- 連携ステータス(AR)
      l_xcbs_data_tab( i ).ar_interface_date         := NULL;                                           -- 連携日(AR)
    END LOOP set_xcbs_data_loop;
    --==================================================
    -- 出力パラメータ設定
    --==================================================
    o_xcbs_data_tab := l_xcbs_data_tab;
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
    ov_retcode := lv_end_retcode;
--
  EXCEPTION
    -- *** エラー終了 ***
    WHEN error_proc_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 処理部共通例外 ***
    WHEN global_process_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := lv_end_retcode;
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
END set_xcbs_data;
--
  /**********************************************************************************
   * Procedure Name   : sales_result_loop1
   * Description      : 販売実績の取得・売価別条件(A-8)
   ***********************************************************************************/
  PROCEDURE sales_result_loop1(
    ov_errbuf                      OUT VARCHAR2        -- エラー・メッセージ
  , ov_retcode                     OUT VARCHAR2        -- リターン・コード
  , ov_errmsg                      OUT VARCHAR2        -- ユーザー・エラー・メッセージ
  )
  IS
    --==================================================
    -- ローカル定数
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'sales_result_loop1';             -- プログラム名
    --==================================================
    -- ローカル変数
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- エラー・メッセージ
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ユーザー・エラー・メッセージ
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- 出力用メッセージ
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- メッセージ出力関数戻り値
    l_xcbs_data_tab                xcbs_data_ttype;
    l_get_sales_data_rec           get_sales_data_rtype;
--
  BEGIN
    --==================================================
    -- ステータス初期化
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- 顧客情報の取得
    --==================================================
    OPEN get_sales_data_cur1;
    << get_sales_data_loop1 >>
    LOOP
      FETCH get_sales_data_cur1 INTO l_get_sales_data_rec;
      EXIT WHEN get_sales_data_cur1%NOTFOUND;
      --==================================================
      -- 条件別販手販協情報の設定
      --==================================================
      set_xcbs_data(
        ov_errbuf                   => lv_errbuf                  -- エラー・メッセージ
      , ov_retcode                  => lv_retcode                 -- リターン・コード
      , ov_errmsg                   => lv_errmsg                  -- ユーザー・エラー・メッセージ
      , i_get_sales_data_rec        => l_get_sales_data_rec       -- 販売実績情報レコード
      , o_xcbs_data_tab             => l_xcbs_data_tab            -- 条件別販手販協情報
      );
      IF( lv_retcode = cv_status_error ) THEN
        lv_end_retcode := cv_status_error;
        RAISE global_process_expt;
      END IF;
      --==================================================
      -- 条件別販手販協テーブルへの登録
      --==================================================
      insert_xcbs(
        ov_errbuf                   => lv_errbuf                  -- エラー・メッセージ
      , ov_retcode                  => lv_retcode                 -- リターン・コード
      , ov_errmsg                   => lv_errmsg                  -- ユーザー・エラー・メッセージ
      , i_get_sales_data_rec        => l_get_sales_data_rec       -- 販売実績情報レコード
      , i_xcbs_data_tab             => l_xcbs_data_tab            -- 条件別販手販協情報
      );
      IF( lv_retcode = cv_status_error ) THEN
        lv_end_retcode := cv_status_error;
        RAISE global_process_expt;
      END IF;
      --==================================================
      -- 販手条件エラーテーブルへの登録
      --==================================================
      insert_xbce(
        ov_errbuf                   => lv_errbuf                  -- エラー・メッセージ
      , ov_retcode                  => lv_retcode                 -- リターン・コード
      , ov_errmsg                   => lv_errmsg                  -- ユーザー・エラー・メッセージ
      , i_get_sales_data_rec        => l_get_sales_data_rec       -- 販売実績情報レコード
      );
      IF( lv_retcode = cv_status_error ) THEN
        lv_end_retcode := cv_status_error;
        RAISE global_process_expt;
      ELSIF( lv_retcode = cv_status_warn ) THEN
        lv_end_retcode := cv_status_warn;
      END IF;
    END LOOP get_sales_data_loop1;
    CLOSE get_sales_data_cur1;
    --==================================================
    -- 出力パラメータ設定
    --==================================================
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
    ov_retcode := lv_end_retcode;
--
  EXCEPTION
    -- *** エラー終了 ***
    WHEN error_proc_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 処理部共通例外 ***
    WHEN global_process_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := lv_end_retcode;
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END sales_result_loop1;
--
  /**********************************************************************************
   * Procedure Name   : sales_result_loop2
   * Description      : 販売実績の取得・容器区分別条件(A-8)
   ***********************************************************************************/
  PROCEDURE sales_result_loop2(
    ov_errbuf                      OUT VARCHAR2        -- エラー・メッセージ
  , ov_retcode                     OUT VARCHAR2        -- リターン・コード
  , ov_errmsg                      OUT VARCHAR2        -- ユーザー・エラー・メッセージ
  )
  IS
    --==================================================
    -- ローカル定数
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'sales_result_loop2';             -- プログラム名
    --==================================================
    -- ローカル変数
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- エラー・メッセージ
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ユーザー・エラー・メッセージ
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- 出力用メッセージ
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- メッセージ出力関数戻り値
    l_xcbs_data_tab                xcbs_data_ttype;
    l_get_sales_data_rec           get_sales_data_rtype;
--
  BEGIN
    --==================================================
    -- ステータス初期化
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- 顧客情報の取得
    --==================================================
    OPEN get_sales_data_cur2;
    << get_sales_data_loop2 >>
    LOOP
      FETCH get_sales_data_cur2 INTO l_get_sales_data_rec;
      EXIT WHEN get_sales_data_cur2%NOTFOUND;
      --==================================================
      -- 条件別販手販協情報の設定
      --==================================================
      set_xcbs_data(
        ov_errbuf                   => lv_errbuf                  -- エラー・メッセージ
      , ov_retcode                  => lv_retcode                 -- リターン・コード
      , ov_errmsg                   => lv_errmsg                  -- ユーザー・エラー・メッセージ
      , i_get_sales_data_rec        => l_get_sales_data_rec       -- 販売実績情報レコード
      , o_xcbs_data_tab             => l_xcbs_data_tab            -- 条件別販手販協情報
      );
      IF( lv_retcode = cv_status_error ) THEN
        lv_end_retcode := cv_status_error;
        RAISE global_process_expt;
      END IF;
      --==================================================
      -- 条件別販手販協テーブルへの登録
      --==================================================
      insert_xcbs(
        ov_errbuf                   => lv_errbuf                  -- エラー・メッセージ
      , ov_retcode                  => lv_retcode                 -- リターン・コード
      , ov_errmsg                   => lv_errmsg                  -- ユーザー・エラー・メッセージ
      , i_get_sales_data_rec        => l_get_sales_data_rec       -- 販売実績情報レコード
      , i_xcbs_data_tab             => l_xcbs_data_tab            -- 条件別販手販協情報
      );
      IF( lv_retcode = cv_status_error ) THEN
        lv_end_retcode := cv_status_error;
        RAISE global_process_expt;
      END IF;
      --==================================================
      -- 販手条件エラーテーブルへの登録
      --==================================================
      insert_xbce(
        ov_errbuf                   => lv_errbuf                  -- エラー・メッセージ
      , ov_retcode                  => lv_retcode                 -- リターン・コード
      , ov_errmsg                   => lv_errmsg                  -- ユーザー・エラー・メッセージ
      , i_get_sales_data_rec        => l_get_sales_data_rec         -- 販売実績情報レコード
      );
      IF( lv_retcode = cv_status_error ) THEN
        lv_end_retcode := cv_status_error;
        RAISE global_process_expt;
      ELSIF( lv_retcode = cv_status_warn ) THEN
        lv_end_retcode := cv_status_warn;
      END IF;
    END LOOP get_sales_data_loop2;
    CLOSE get_sales_data_cur2;
    --==================================================
    -- 出力パラメータ設定
    --==================================================
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
    ov_retcode := lv_end_retcode;
--
  EXCEPTION
    -- *** エラー終了 ***
    WHEN error_proc_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 処理部共通例外 ***
    WHEN global_process_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := lv_end_retcode;
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END sales_result_loop2;
--
  /**********************************************************************************
   * Procedure Name   : sales_result_loop3
   * Description      : 販売実績の取得・一律条件(A-8)
   ***********************************************************************************/
  PROCEDURE sales_result_loop3(
    ov_errbuf                      OUT VARCHAR2        -- エラー・メッセージ
  , ov_retcode                     OUT VARCHAR2        -- リターン・コード
  , ov_errmsg                      OUT VARCHAR2        -- ユーザー・エラー・メッセージ
  )
  IS
    --==================================================
    -- ローカル定数
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'sales_result_loop3';             -- プログラム名
    --==================================================
    -- ローカル変数
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- エラー・メッセージ
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ユーザー・エラー・メッセージ
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- 出力用メッセージ
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- メッセージ出力関数戻り値
    l_xcbs_data_tab                xcbs_data_ttype;
    l_get_sales_data_rec           get_sales_data_rtype;
--
  BEGIN
    --==================================================
    -- ステータス初期化
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- 顧客情報の取得
    --==================================================
    OPEN get_sales_data_cur3;
    << get_sales_data_loop3 >>
    LOOP
      FETCH get_sales_data_cur3 INTO l_get_sales_data_rec;
      EXIT WHEN get_sales_data_cur3%NOTFOUND;
      --==================================================
      -- 条件別販手販協情報の設定
      --==================================================
      set_xcbs_data(
        ov_errbuf                   => lv_errbuf                  -- エラー・メッセージ
      , ov_retcode                  => lv_retcode                 -- リターン・コード
      , ov_errmsg                   => lv_errmsg                  -- ユーザー・エラー・メッセージ
      , i_get_sales_data_rec        => l_get_sales_data_rec       -- 販売実績情報レコード
      , o_xcbs_data_tab             => l_xcbs_data_tab            -- 条件別販手販協情報
      );
      IF( lv_retcode = cv_status_error ) THEN
        lv_end_retcode := cv_status_error;
        RAISE global_process_expt;
      END IF;
      --==================================================
      -- 条件別販手販協テーブルへの登録
      --==================================================
      insert_xcbs(
        ov_errbuf                   => lv_errbuf                  -- エラー・メッセージ
      , ov_retcode                  => lv_retcode                 -- リターン・コード
      , ov_errmsg                   => lv_errmsg                  -- ユーザー・エラー・メッセージ
      , i_get_sales_data_rec        => l_get_sales_data_rec       -- 販売実績情報レコード
      , i_xcbs_data_tab             => l_xcbs_data_tab            -- 条件別販手販協情報
      );
      IF( lv_retcode = cv_status_error ) THEN
        lv_end_retcode := cv_status_error;
        RAISE global_process_expt;
      END IF;
      --==================================================
      -- 販手条件エラーテーブルへの登録
      --==================================================
      insert_xbce(
        ov_errbuf                   => lv_errbuf                  -- エラー・メッセージ
      , ov_retcode                  => lv_retcode                 -- リターン・コード
      , ov_errmsg                   => lv_errmsg                  -- ユーザー・エラー・メッセージ
      , i_get_sales_data_rec        => l_get_sales_data_rec       -- 販売実績情報レコード
      );
      IF( lv_retcode = cv_status_error ) THEN
        lv_end_retcode := cv_status_error;
        RAISE global_process_expt;
      ELSIF( lv_retcode = cv_status_warn ) THEN
        lv_end_retcode := cv_status_warn;
      END IF;
    END LOOP get_sales_data_loop3;
    CLOSE get_sales_data_cur3;
    --==================================================
    -- 出力パラメータ設定
    --==================================================
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
    ov_retcode := lv_end_retcode;
--
  EXCEPTION
    -- *** エラー終了 ***
    WHEN error_proc_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 処理部共通例外 ***
    WHEN global_process_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := lv_end_retcode;
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END sales_result_loop3;
--
  /**********************************************************************************
   * Procedure Name   : sales_result_loop4
   * Description      : 販売実績の取得・定額条件(A-8)
   ***********************************************************************************/
  PROCEDURE sales_result_loop4(
    ov_errbuf                      OUT VARCHAR2        -- エラー・メッセージ
  , ov_retcode                     OUT VARCHAR2        -- リターン・コード
  , ov_errmsg                      OUT VARCHAR2        -- ユーザー・エラー・メッセージ
  )
  IS
    --==================================================
    -- ローカル定数
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'sales_result_loop4';             -- プログラム名
    --==================================================
    -- ローカル変数
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- エラー・メッセージ
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ユーザー・エラー・メッセージ
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- 出力用メッセージ
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- メッセージ出力関数戻り値
    l_xcbs_data_tab                xcbs_data_ttype;
    l_get_sales_data_rec           get_sales_data_rtype;
--
  BEGIN
    --==================================================
    -- ステータス初期化
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- 顧客情報の取得
    --==================================================
    OPEN get_sales_data_cur4;
    << get_sales_data_loop4 >>
    LOOP
      FETCH get_sales_data_cur4 INTO l_get_sales_data_rec;
      EXIT WHEN get_sales_data_cur4%NOTFOUND;
      --==================================================
      -- 条件別販手販協情報の設定
      --==================================================
      set_xcbs_data(
        ov_errbuf                   => lv_errbuf                  -- エラー・メッセージ
      , ov_retcode                  => lv_retcode                 -- リターン・コード
      , ov_errmsg                   => lv_errmsg                  -- ユーザー・エラー・メッセージ
      , i_get_sales_data_rec        => l_get_sales_data_rec       -- 販売実績情報レコード
      , o_xcbs_data_tab             => l_xcbs_data_tab            -- 条件別販手販協情報
      );
      IF( lv_retcode = cv_status_error ) THEN
        lv_end_retcode := cv_status_error;
        RAISE global_process_expt;
      END IF;
      --==================================================
      -- 条件別販手販協テーブルへの登録
      --==================================================
      insert_xcbs(
        ov_errbuf                   => lv_errbuf                  -- エラー・メッセージ
      , ov_retcode                  => lv_retcode                 -- リターン・コード
      , ov_errmsg                   => lv_errmsg                  -- ユーザー・エラー・メッセージ
      , i_get_sales_data_rec        => l_get_sales_data_rec       -- 販売実績情報レコード
      , i_xcbs_data_tab             => l_xcbs_data_tab            -- 条件別販手販協情報
      );
      IF( lv_retcode = cv_status_error ) THEN
        lv_end_retcode := cv_status_error;
        RAISE global_process_expt;
      END IF;
      --==================================================
      -- 販手条件エラーテーブルへの登録
      --==================================================
      insert_xbce(
        ov_errbuf                   => lv_errbuf                  -- エラー・メッセージ
      , ov_retcode                  => lv_retcode                 -- リターン・コード
      , ov_errmsg                   => lv_errmsg                  -- ユーザー・エラー・メッセージ
      , i_get_sales_data_rec        => l_get_sales_data_rec       -- 販売実績情報レコード
      );
      IF( lv_retcode = cv_status_error ) THEN
        lv_end_retcode := cv_status_error;
        RAISE global_process_expt;
      ELSIF( lv_retcode = cv_status_warn ) THEN
        lv_end_retcode := cv_status_warn;
      END IF;
    END LOOP get_sales_data_loop4;
    CLOSE get_sales_data_cur4;
    --==================================================
    -- 出力パラメータ設定
    --==================================================
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
    ov_retcode := lv_end_retcode;
--
  EXCEPTION
    -- *** エラー終了 ***
    WHEN error_proc_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 処理部共通例外 ***
    WHEN global_process_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := lv_end_retcode;
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END sales_result_loop4;
--
  /**********************************************************************************
   * Procedure Name   : sales_result_loop5
   * Description      : 販売実績の取得・電気料（固定／変動）(A-8)
   ***********************************************************************************/
  PROCEDURE sales_result_loop5(
    ov_errbuf                      OUT VARCHAR2        -- エラー・メッセージ
  , ov_retcode                     OUT VARCHAR2        -- リターン・コード
  , ov_errmsg                      OUT VARCHAR2        -- ユーザー・エラー・メッセージ
  )
  IS
    --==================================================
    -- ローカル定数
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'sales_result_loop5';             -- プログラム名
    --==================================================
    -- ローカル変数
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- エラー・メッセージ
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ユーザー・エラー・メッセージ
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- 出力用メッセージ
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- メッセージ出力関数戻り値
    l_xcbs_data_tab                xcbs_data_ttype;
    l_get_sales_data_rec           get_sales_data_rtype;
--
  BEGIN
    --==================================================
    -- ステータス初期化
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- 顧客情報の取得
    --==================================================
    OPEN get_sales_data_cur5;
    << get_sales_data_loop5 >>
    LOOP
      FETCH get_sales_data_cur5 INTO l_get_sales_data_rec;
      EXIT WHEN get_sales_data_cur5%NOTFOUND;
      --==================================================
      -- 条件別販手販協情報の設定
      --==================================================
      set_xcbs_data(
        ov_errbuf                   => lv_errbuf                  -- エラー・メッセージ
      , ov_retcode                  => lv_retcode                 -- リターン・コード
      , ov_errmsg                   => lv_errmsg                  -- ユーザー・エラー・メッセージ
      , i_get_sales_data_rec        => l_get_sales_data_rec       -- 販売実績情報レコード
      , o_xcbs_data_tab             => l_xcbs_data_tab            -- 条件別販手販協情報
      );
      IF( lv_retcode = cv_status_error ) THEN
        lv_end_retcode := cv_status_error;
        RAISE global_process_expt;
      END IF;
      --==================================================
      -- 条件別販手販協テーブルへの登録
      --==================================================
      insert_xcbs(
        ov_errbuf                   => lv_errbuf                  -- エラー・メッセージ
      , ov_retcode                  => lv_retcode                 -- リターン・コード
      , ov_errmsg                   => lv_errmsg                  -- ユーザー・エラー・メッセージ
      , i_get_sales_data_rec        => l_get_sales_data_rec       -- 販売実績情報レコード
      , i_xcbs_data_tab             => l_xcbs_data_tab            -- 条件別販手販協情報
      );
      IF( lv_retcode = cv_status_error ) THEN
        lv_end_retcode := cv_status_error;
        RAISE global_process_expt;
      END IF;
      --==================================================
      -- 販手条件エラーテーブルへの登録
      --==================================================
      insert_xbce(
        ov_errbuf                   => lv_errbuf                  -- エラー・メッセージ
      , ov_retcode                  => lv_retcode                 -- リターン・コード
      , ov_errmsg                   => lv_errmsg                  -- ユーザー・エラー・メッセージ
      , i_get_sales_data_rec        => l_get_sales_data_rec         -- 販売実績情報レコード
      );
      IF( lv_retcode = cv_status_error ) THEN
        lv_end_retcode := cv_status_error;
        RAISE global_process_expt;
      ELSIF( lv_retcode = cv_status_warn ) THEN
        lv_end_retcode := cv_status_warn;
      END IF;
    END LOOP get_sales_data_loop5;
    CLOSE get_sales_data_cur5;
    --==================================================
    -- 出力パラメータ設定
    --==================================================
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
    ov_retcode := lv_end_retcode;
--
  EXCEPTION
    -- *** エラー終了 ***
    WHEN error_proc_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 処理部共通例外 ***
    WHEN global_process_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := lv_end_retcode;
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END sales_result_loop5;
--
  /**********************************************************************************
   * Procedure Name   : sales_result_loop6
   * Description      : 販売実績の取得・入金値引率(A-8)
   ***********************************************************************************/
  PROCEDURE sales_result_loop6(
    ov_errbuf                      OUT VARCHAR2        -- エラー・メッセージ
  , ov_retcode                     OUT VARCHAR2        -- リターン・コード
  , ov_errmsg                      OUT VARCHAR2        -- ユーザー・エラー・メッセージ
  )
  IS
    --==================================================
    -- ローカル定数
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'sales_result_loop6';             -- プログラム名
    --==================================================
    -- ローカル変数
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- エラー・メッセージ
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ユーザー・エラー・メッセージ
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- 出力用メッセージ
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- メッセージ出力関数戻り値
    l_xcbs_data_tab                xcbs_data_ttype;
    l_get_sales_data_rec           get_sales_data_rtype;
--
  BEGIN
    --==================================================
    -- ステータス初期化
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- 顧客情報の取得
    --==================================================
    OPEN get_sales_data_cur6;
    << get_sales_data_loop6 >>
    LOOP
      FETCH get_sales_data_cur6 INTO l_get_sales_data_rec;
      EXIT WHEN get_sales_data_cur6%NOTFOUND;
      --==================================================
      -- 条件別販手販協情報の設定
      --==================================================
      set_xcbs_data(
        ov_errbuf                   => lv_errbuf                  -- エラー・メッセージ
      , ov_retcode                  => lv_retcode                 -- リターン・コード
      , ov_errmsg                   => lv_errmsg                  -- ユーザー・エラー・メッセージ
      , i_get_sales_data_rec        => l_get_sales_data_rec       -- 販売実績情報レコード
      , o_xcbs_data_tab             => l_xcbs_data_tab            -- 条件別販手販協情報
      );
      IF( lv_retcode = cv_status_error ) THEN
        lv_end_retcode := cv_status_error;
        RAISE global_process_expt;
      END IF;
      --==================================================
      -- 条件別販手販協テーブルへの登録
      --==================================================
      insert_xcbs(
        ov_errbuf                   => lv_errbuf                  -- エラー・メッセージ
      , ov_retcode                  => lv_retcode                 -- リターン・コード
      , ov_errmsg                   => lv_errmsg                  -- ユーザー・エラー・メッセージ
      , i_get_sales_data_rec        => l_get_sales_data_rec       -- 販売実績情報レコード
      , i_xcbs_data_tab             => l_xcbs_data_tab            -- 条件別販手販協情報
      );
      IF( lv_retcode = cv_status_error ) THEN
        lv_end_retcode := cv_status_error;
        RAISE global_process_expt;
      END IF;
      --==================================================
      -- 販手条件エラーテーブルへの登録
      --==================================================
      insert_xbce(
        ov_errbuf                   => lv_errbuf                  -- エラー・メッセージ
      , ov_retcode                  => lv_retcode                 -- リターン・コード
      , ov_errmsg                   => lv_errmsg                  -- ユーザー・エラー・メッセージ
      , i_get_sales_data_rec        => l_get_sales_data_rec       -- 販売実績情報レコード
      );
      IF( lv_retcode = cv_status_error ) THEN
        lv_end_retcode := cv_status_error;
        RAISE global_process_expt;
      ELSIF( lv_retcode = cv_status_warn ) THEN
        lv_end_retcode := cv_status_warn;
      END IF;
    END LOOP get_sales_data_loop6;
    CLOSE get_sales_data_cur6;
    --==================================================
    -- 出力パラメータ設定
    --==================================================
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
    ov_retcode := lv_end_retcode;
--
  EXCEPTION
    -- *** エラー終了 ***
    WHEN error_proc_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 処理部共通例外 ***
    WHEN global_process_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := lv_end_retcode;
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END sales_result_loop6;
--
  /**********************************************************************************
   * Procedure Name   : delete_xbce
   * Description      : 販手条件エラーの削除処理(A-7)
   ***********************************************************************************/
  PROCEDURE delete_xbce(
    ov_errbuf                      OUT VARCHAR2        -- エラー・メッセージ
  , ov_retcode                     OUT VARCHAR2        -- リターン・コード
  , ov_errmsg                      OUT VARCHAR2        -- ユーザー・エラー・メッセージ
  )
  IS
    --==================================================
    -- ローカル定数
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'delete_xbce';      -- プログラム名
    --==================================================
    -- ローカル変数
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- エラー・メッセージ
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ユーザー・エラー・メッセージ
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- 出力用メッセージ
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- メッセージ出力関数戻り値
    -- ログ出力用退避項目
    lt_cust_code                   xxcok_bm_contract_err.cust_code%TYPE DEFAULT NULL;
    --==================================================
    -- ローカルカーソル
    --==================================================
    CURSOR xbce_delete_lock_cur
    IS
      SELECT xbce.cust_code                AS cust_code  -- 顧客コード
      FROM xxcok_bm_contract_err      xbce               -- 販手条件エラーテーブル
-- 2012/06/15 Ver.3.15 [E_本稼動_08751] SCSK S.Niki MOD START
--         , xxcok_tmp_014a01c_custdata xt0c               -- 条件別販手販協計算顧客情報一時表
         , xxcok_wk_014a01c_custdata xt0c                -- 条件別販手販協計算顧客情報一時表
-- 2012/06/15 Ver.3.15 [E_本稼動_08751] SCSK S.Niki MOD END
      WHERE xbce.cust_code  = xt0c.ship_cust_code
-- 2012/06/15 Ver.3.15 [E_本稼動_08751] SCSK S.Niki ADD START
      AND   xt0c.proc_type  = gv_param_proc_type
-- 2012/06/15 Ver.3.15 [E_本稼動_08751] SCSK S.Niki ADD END
      FOR UPDATE OF xbce.cust_code NOWAIT
    ;
--
  BEGIN
    --==================================================
    -- ステータス初期化
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- 販手条件エラー削除ループ
    --==================================================
    << xbce_delete_lock_loop >>
    FOR xbce_delete_lock_rec IN xbce_delete_lock_cur LOOP
      --==================================================
      -- 販手条件エラーデータ削除
      --==================================================
      lt_cust_code := xbce_delete_lock_rec.cust_code;
      DELETE
      FROM xxcok_bm_contract_err   xbce
      WHERE xbce.cust_code = xbce_delete_lock_rec.cust_code
      ;
    END LOOP xbce_delete_lock_loop;
    --==================================================
    -- 出力パラメータ設定
    --==================================================
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
    ov_retcode := lv_end_retcode;
--
  EXCEPTION
    -- ロック取得エラー
    WHEN resource_busy_expt THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00080
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** エラー終了 ***
    WHEN error_proc_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 処理部共通例外 ***
    WHEN global_process_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := lv_end_retcode;
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
END delete_xbce;
--
  /**********************************************************************************
   * Procedure Name   : delete_xcbs
   * Description      : 条件別販手販協データの削除（未確定金額）(A-3)
   ***********************************************************************************/
  PROCEDURE delete_xcbs(
    ov_errbuf                      OUT VARCHAR2        -- エラー・メッセージ
  , ov_retcode                     OUT VARCHAR2        -- リターン・コード
  , ov_errmsg                      OUT VARCHAR2        -- ユーザー・エラー・メッセージ
  )
  IS
    --==================================================
    -- ローカル定数
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'delete_xcbs';      -- プログラム名
    --==================================================
    -- ローカル変数
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- エラー・メッセージ
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ユーザー・エラー・メッセージ
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- 出力用メッセージ
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- メッセージ出力関数戻り値
    -- ログ出力用退避項目
    lt_cond_bm_support_id          xxcok_cond_bm_support.cond_bm_support_id%TYPE DEFAULT NULL;
    --==================================================
    -- ローカルカーソル
    --==================================================
    CURSOR xcbs_delete_lock_cur
    IS
      SELECT /*+ LEADING(flv hl) */
             xcbs.cond_bm_support_id    AS cond_bm_support_id  -- 条件別販手販協ID
           , xcbs.delivery_cust_code    AS delivery_cust_code  -- 顧客【納品先】
           , xcbs.closing_date          AS closing_date        -- 締め日
      FROM xxcok_cond_bm_support      xcbs               -- 条件別販手販協テーブル
         , hz_cust_accounts        hca                -- 顧客マスタ
         , hz_cust_acct_sites_all  hcas               -- 顧客サイトマスタ
         , hz_parties              hp                 -- パーティマスタ
         , hz_party_sites          hps                -- パーティサイトマスタ
         , hz_locations            hl                 -- 顧客所在地マスタ
         , fnd_lookup_values       flv                -- 販手販協計算実行区分
      WHERE xcbs.delivery_cust_code          = hca.account_number
        AND hca.cust_account_id              = hcas.cust_account_id
        AND hca.party_id                     = hp.party_id
        AND hp.party_id                      = hps.party_id
        AND hcas.party_site_id               = hps.party_site_id
        AND hps.location_id                  = hl.location_id
        AND hcas.org_id                      = gn_org_id
        AND flv.lookup_type                  = cv_lookup_type_01
        AND flv.attribute1                   = gv_param_proc_type
        AND flv.language                     = cv_lang
        AND gd_process_date            BETWEEN NVL( flv.start_date_active, gd_process_date )
                                           AND NVL( flv.end_date_active  , gd_process_date )
        AND flv.enabled_flag                 = cv_enable
        AND hl.address3                   LIKE flv.lookup_code || '%'
        AND xcbs.amt_fix_status    = cv_xcbs_temp -- 未確定
      FOR UPDATE OF xcbs.cond_bm_support_id NOWAIT
    ;
--
  BEGIN
    --==================================================
    -- ステータス初期化
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- 条件別販手販協削除ループ
    --==================================================
    << xcbs_delete_lock_loop >>
    FOR xcbs_delete_lock_rec IN xcbs_delete_lock_cur LOOP
      --==================================================
      -- 条件別販手販協データ削除
      --==================================================
      DELETE
      FROM xxcok_cond_bm_support   xcbs
      WHERE xcbs.cond_bm_support_id = xcbs_delete_lock_rec.cond_bm_support_id
      ;
    END LOOP xcbs_delete_lock_loop;
    --==================================================
    -- 出力パラメータ設定
    --==================================================
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
    ov_retcode := lv_end_retcode;
--
  EXCEPTION
    -- *** ロック取得エラー ***
    WHEN resource_busy_expt THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00051
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** エラー終了 ***
    WHEN error_proc_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 処理部共通例外 ***
    WHEN global_process_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := lv_end_retcode;
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
END delete_xcbs;
--
  /**********************************************************************************
   * Procedure Name   : insert_xt0c
   * Description      : 条件別販手販協計算顧客情報一時表への登録(A-6)
   ***********************************************************************************/
  PROCEDURE insert_xt0c(
    ov_errbuf                      OUT VARCHAR2        -- エラー・メッセージ
  , ov_retcode                     OUT VARCHAR2        -- リターン・コード
  , ov_errmsg                      OUT VARCHAR2        -- ユーザー・エラー・メッセージ
  , i_get_cust_data_rec            IN  get_cust_data_cur%ROWTYPE  -- 顧客情報レコード
  , iv_term_name                   IN  VARCHAR2                   -- 支払条件
  , id_close_date                  IN  DATE                       -- 締め日
  , id_expect_payment_date         IN  DATE                       -- 支払予定日
  , in_period_year                 IN  NUMBER                     -- 会計年度
  , id_amount_fix_date             IN  DATE                       -- 金額確定日
-- 2010/02/19 Ver.3.8 [障害E_本稼動_01446] SCS S.Moriyama ADD START
-- 2012/06/15 Ver.3.15 [E_本稼動_08751] SCSK S.Niki MOD START
--  , it_emp_code                    IN  xxcok_tmp_014a01c_custdata.emp_code%TYPE -- 担当者コード
  , it_emp_code                    IN  xxcok_wk_014a01c_custdata.emp_code%TYPE -- 担当者コード
-- 2012/06/15 Ver.3.15 [E_本稼動_08751] SCSK S.Niki MOD END
-- 2010/02/19 Ver.3.8 [障害E_本稼動_01446] SCS S.Moriyama ADD END
  )
  IS
    --==================================================
    -- ローカル定数
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'insert_xt0c';      -- プログラム名
    --==================================================
    -- ローカル変数
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- エラー・メッセージ
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ユーザー・エラー・メッセージ
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- 出力用メッセージ
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- メッセージ出力関数戻り値
    ld_expect_payment_date         DATE           DEFAULT NULL;                 -- 支払予定日
    ld_calc_target_period_from     DATE           DEFAULT NULL;                 -- 計算対象期間(FROM)
--
  BEGIN
    --==================================================
    -- ステータス初期化
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- 支払予定日
    --==================================================
    IF ( i_get_cust_data_rec.ship_gyotai_sho = cv_gyotai_sho_25 ) THEN
      ld_expect_payment_date := id_expect_payment_date;
    ELSE
      ld_expect_payment_date := id_close_date;
    END IF;
    --==================================================
    -- 計算対象期間(FROM)
    --==================================================
    IF ( i_get_cust_data_rec.calc_target_period_from IS NOT NULL ) THEN
      ld_calc_target_period_from := i_get_cust_data_rec.calc_target_period_from;
    ELSIF( iv_term_name = gv_instantly_term_name ) THEN
      ld_calc_target_period_from := id_close_date;
    ELSE
      ld_calc_target_period_from := ADD_MONTHS( id_close_date, -1 ) + 1;
    END IF;
    --==================================================
    -- 条件別販手販協計算顧客情報一時表への登録
    --==================================================
-- 2012/06/15 Ver.3.15 [E_本稼動_08751] SCSK S.Niki MOD START
--    INSERT INTO xxcok_tmp_014a01c_custdata (
    INSERT INTO xxcok_wk_014a01c_custdata (
-- 2012/06/15 Ver.3.15 [E_本稼動_08751] SCSK S.Niki MOD END
      ship_cust_code              -- 【出荷先】顧客コード
    , ship_gyotai_tyu             -- 【出荷先】業態（中分類）
    , ship_gyotai_sho             -- 【出荷先】業態（小分類）
    , ship_delivery_chain_code    -- 【出荷先】納品先チェーンコード
    , bill_cust_code              -- 【請求先】顧客コード
    , bm1_vendor_code             -- 【ＢＭ１】仕入先コード
    , bm1_vendor_site_code        -- 【ＢＭ１】仕入先サイトコード
    , bm1_bm_payment_type         -- 【ＢＭ１】BM支払区分
    , bm2_vendor_code             -- 【ＢＭ２】仕入先コード
    , bm2_vendor_site_code        -- 【ＢＭ２】仕入先サイトコード
    , bm2_bm_payment_type         -- 【ＢＭ２】BM支払区分
    , bm3_vendor_code             -- 【ＢＭ３】仕入先コード
    , bm3_vendor_site_code        -- 【ＢＭ３】仕入先サイトコード
    , bm3_bm_payment_type         -- 【ＢＭ３】BM支払区分
    , tax_div                     -- 消費税区分
    , tax_code                    -- 税金コード
    , tax_rate                    -- 税率
    , tax_rounding_rule           -- 端数処理区分
    , receiv_discount_rate        -- 入金値引率
    , term_name                   -- 支払条件
    , closing_date                -- 締め日
    , expect_payment_date         -- 支払予定日
    , period_year                 -- 会計年度
    , calc_target_period_from     -- 計算対象期間(FROM)
    , calc_target_period_to       -- 計算対象期間(TO)
    , amount_fix_date             -- 金額確定日
-- 2010/02/19 Ver.3.8 [障害E_本稼動_01446] SCS S.Moriyama ADD START
    , emp_code                    -- 担当者コード
-- 2010/02/19 Ver.3.8 [障害E_本稼動_01446] SCS S.Moriyama ADD END
-- 2012/06/15 Ver.3.15 [E_本稼動_08751] SCSK S.Niki ADD START
    , proc_type                   -- 実行区分
    , created_by                  -- 作成者
    , creation_date               -- 作成日
    , last_updated_by             -- 最終更新者
    , last_update_date            -- 最終更新日
    , last_update_login           -- 最終更新ログイン
    , request_id                  -- 要求ID
    , program_application_id      -- コンカレント・プログラム・アプリケーションID
    , program_id                  -- コンカレント・プログラムID
    , program_update_date         -- プログラム更新日
-- 2012/06/15 Ver.3.15 [E_本稼動_08751] SCSK S.Niki ADD END
    )
    VALUES (
      i_get_cust_data_rec.ship_cust_code             -- 【出荷先】顧客コード
    , i_get_cust_data_rec.ship_gyotai_tyu            -- 【出荷先】業態（中分類）
    , i_get_cust_data_rec.ship_gyotai_sho            -- 【出荷先】業態（小分類）
    , i_get_cust_data_rec.ship_delivery_chain_code   -- 【出荷先】納品先チェーンコード
    , i_get_cust_data_rec.bill_cust_code             -- 【請求先】顧客コード
    , i_get_cust_data_rec.bm1_vendor_code            -- 【ＢＭ１】仕入先コード
    , i_get_cust_data_rec.bm1_vendor_site_code       -- 【ＢＭ１】仕入先サイトコード
    , i_get_cust_data_rec.bm1_bm_payment_type        -- 【ＢＭ１】BM支払区分
    , i_get_cust_data_rec.bm2_vendor_code            -- 【ＢＭ２】仕入先コード
    , i_get_cust_data_rec.bm2_vendor_site_code       -- 【ＢＭ２】仕入先サイトコード
    , i_get_cust_data_rec.bm2_bm_payment_type        -- 【ＢＭ２】BM支払区分
    , i_get_cust_data_rec.bm3_vendor_code            -- 【ＢＭ３】仕入先コード
    , i_get_cust_data_rec.bm3_vendor_site_code       -- 【ＢＭ３】仕入先サイトコード
    , i_get_cust_data_rec.bm3_bm_payment_type        -- 【ＢＭ３】BM支払区分
    , i_get_cust_data_rec.tax_div                    -- 消費税区分
    , i_get_cust_data_rec.tax_code                   -- 税金コード
    , i_get_cust_data_rec.tax_rate                   -- 税率
    , i_get_cust_data_rec.tax_rounding_rule          -- 端数処理区分
    , i_get_cust_data_rec.receiv_discount_rate       -- 入金値引率
    , iv_term_name                                   -- 支払条件
    , id_close_date                                  -- 締め日
    , ld_expect_payment_date                         -- 支払予定日
    , in_period_year                                 -- 会計年度
    , ld_calc_target_period_from                     -- 計算対象期間(FROM)
    , id_close_date                                  -- 計算対象期間(TO)
    , id_amount_fix_date                             -- 金額確定日
-- 2010/02/19 Ver.3.8 [障害E_本稼動_01446] SCS S.Moriyama ADD START
    , it_emp_code                                    -- 担当者コード
-- 2010/02/19 Ver.3.8 [障害E_本稼動_01446] SCS S.Moriyama ADD END
-- 2012/06/15 Ver.3.15 [E_本稼動_08751] SCSK S.Niki ADD START
    , i_get_cust_data_rec.proc_type                  -- 実行区分
    , cn_created_by                                  -- 作成者
    , SYSDATE                                        -- 作成日
    , cn_last_updated_by                             -- 最終更新者
    , SYSDATE                                        -- 最終更新日
    , cn_last_update_login                           -- 最終更新ログイン
    , cn_request_id                                  -- 要求ID
    , cn_program_application_id                      -- コンカレント・プログラム・アプリケーションID
    , cn_program_id                                  -- コンカレント・プログラムID
    , SYSDATE                                        -- プログラム更新日
-- 2012/06/15 Ver.3.15 [E_本稼動_08751] SCSK S.Niki ADD END
    );
    --==================================================
    -- 出力パラメータ設定
    --==================================================
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
    ov_retcode := lv_end_retcode;
--
  EXCEPTION
    -- *** エラー終了 ***
    WHEN error_proc_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 処理部共通例外 ***
    WHEN global_process_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := lv_end_retcode;
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
END insert_xt0c;
--
  /**********************************************************************************
   * Procedure Name   : get_cust_subdata
   * Description      : 条件別販手販協計算日付情報の導出(A-5)
   ***********************************************************************************/
  PROCEDURE get_cust_subdata(
    ov_errbuf                      OUT VARCHAR2        -- エラー・メッセージ
  , ov_retcode                     OUT VARCHAR2        -- リターン・コード
  , ov_errmsg                      OUT VARCHAR2        -- ユーザー・エラー・メッセージ
  , i_get_cust_data_rec            IN  get_cust_data_cur%ROWTYPE  -- 顧客情報レコード
  , ov_term_name                   OUT VARCHAR2                   -- 支払条件
  , od_close_date                  OUT DATE                       -- 締め日
  , od_expect_payment_date         OUT DATE                       -- 支払予定日
  , od_bm_support_period_from      OUT DATE                       -- 条件別販手販協計算開始日
  , od_bm_support_period_to        OUT DATE                       -- 条件別販手販協計算終了日
  , on_period_year                 OUT NUMBER                     -- 会計年度
  , od_amount_fix_date             OUT DATE                       -- 金額確定日
  )
  IS
    --==================================================
    -- ローカル定数
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'get_cust_subdata';             -- プログラム名
    --==================================================
    -- ローカル変数
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- エラー・メッセージ
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ユーザー・エラー・メッセージ
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- 出力用メッセージ
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- メッセージ出力関数戻り値
    ld_tmp_bm_support_period_from  DATE           DEFAULT NULL;                 -- 条件別販手販協計算開始日(仮)
    ld_tmp_bm_support_period_to    DATE           DEFAULT NULL;                 -- 条件別販手販協計算終了日(仮)
    ld_close_date1                 DATE           DEFAULT NULL;                 -- 締め日（支払条件）
    ld_pay_date1                   DATE           DEFAULT NULL;                 -- 支払日（支払条件）
    ld_expect_payment_date1        DATE           DEFAULT NULL;                 -- 支払予定日（支払条件）
    ld_close_date2                 DATE           DEFAULT NULL;                 -- 締め日（第2支払条件）
    ld_pay_date2                   DATE           DEFAULT NULL;                 -- 支払日（第2支払条件）
    ld_expect_payment_date2        DATE           DEFAULT NULL;                 -- 支払予定日（第2支払条件）
    ld_close_date3                 DATE           DEFAULT NULL;                 -- 締め日（第3支払条件）
    ld_pay_date3                   DATE           DEFAULT NULL;                 -- 支払日（第3支払条件）
    ld_expect_payment_date3        DATE           DEFAULT NULL;                 -- 支払予定日（第3支払条件）
    ld_bm_support_period_from_1    DATE           DEFAULT NULL;                 -- 条件別販手販協計算開始日（支払条件）
    ld_bm_support_period_to_1      DATE           DEFAULT NULL;                 -- 条件別販手販協計算終了日（支払条件）
    ld_bm_support_period_from_2    DATE           DEFAULT NULL;                 -- 条件別販手販協計算開始日（第2支払条件）
    ld_bm_support_period_to_2      DATE           DEFAULT NULL;                 -- 条件別販手販協計算終了日（第2支払条件）
    ld_bm_support_period_from_3    DATE           DEFAULT NULL;                 -- 条件別販手販協計算開始日（第3支払条件）
    ld_bm_support_period_to_3      DATE           DEFAULT NULL;                 -- 条件別販手販協計算終了日（第3支払条件）
    lv_fix_term_name               VARCHAR2(10)   DEFAULT NULL;                 -- 支払条件
    ld_fix_close_date              DATE           DEFAULT NULL;                 -- 締め日
    ld_fix_expect_payment_date     DATE           DEFAULT NULL;                 -- 支払予定日
    ld_fix_bm_support_period_from  DATE           DEFAULT NULL;                 -- 条件別販手販協計算開始日
    ld_fix_bm_support_period_to    DATE           DEFAULT NULL;                 -- 条件別販手販協計算終了日
    ln_period_year                 NUMBER         DEFAULT NULL;                 -- 会計年度
    ld_amount_fix_date             DATE           DEFAULT NULL;                 -- 金額確定日
    lv_period_name                 gl_periods.period_name%TYPE DEFAULT NULL;    -- 会計期間名
    lv_closing_status              gl_period_statuses.closing_status%TYPE DEFAULT NULL;                 -- ステータス
    --==================================================
    -- ローカル例外
    --==================================================
    skip_proc_expt                 EXCEPTION; -- 計算対象外スキップ
    get_close_date_expt            EXCEPTION; -- 締め・支払日取得関数エラー
    get_operating_day_expt         EXCEPTION; -- 営業日取得関数エラー
    get_acctg_calendar_expt        EXCEPTION; -- 会計カレンダ取得関数エラー
--
  BEGIN
    --==================================================
    -- ステータス初期化
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- 即時払い判定
    --==================================================
    IF(    ( i_get_cust_data_rec.term_name1 = gv_instantly_term_name )
        OR ( i_get_cust_data_rec.term_name2 = gv_instantly_term_name )
        OR ( i_get_cust_data_rec.term_name3 = gv_instantly_term_name )
    ) THEN
      lv_fix_term_name              := gv_instantly_term_name;
      ld_fix_close_date             := gd_process_date;
      ld_fix_expect_payment_date    := gd_process_date;
      ld_fix_bm_support_period_from := gd_process_date;
      ld_fix_bm_support_period_to   := gd_process_date;
      ld_amount_fix_date            := gd_process_date;
    ELSE
      --==================================================
      -- 条件別販手販協計算開始日(仮)取得
      --==================================================
      IF( i_get_cust_data_rec.settle_amount_cycle IS NULL ) THEN
        RAISE get_operating_day_expt;
      END IF;
      ld_tmp_bm_support_period_from :=
        get_operating_day_f(
          id_proc_date             => gd_process_date                               -- IN DATE   処理日
        , in_days                  => -1 * i_get_cust_data_rec.settle_amount_cycle  -- IN NUMBER 日数
        , in_proc_type             => cn_proc_type_before                           -- IN NUMBER 処理区分
        );
      IF( ld_tmp_bm_support_period_from IS NULL ) THEN
        RAISE get_operating_day_expt;
      END IF;
      --==================================================
      -- 支払条件
      --==================================================
      IF( i_get_cust_data_rec.term_name1 IS NOT NULL ) THEN
        --==================================================
        -- 締め支払日取得（支払条件）
        --==================================================
        xxcok_common_pkg.get_close_date_p(
          ov_errbuf                  => lv_errbuf                         -- OUT VARCHAR2          ログに出力するエラー・メッセージ
        , ov_retcode                 => lv_retcode                        -- OUT VARCHAR2          リターンコード
        , ov_errmsg                  => lv_errmsg                         -- OUT VARCHAR2          ユーザーに見せるエラー・メッセージ
        , id_proc_date               => ld_tmp_bm_support_period_from     -- IN  DATE DEFAULT NULL 処理日(対象日)
        , iv_pay_cond                => i_get_cust_data_rec.term_name1    -- IN  VARCHAR2          支払条件(IN)
        , od_close_date              => ld_close_date1                    -- OUT DATE              締め日(OUT)
        , od_pay_date                => ld_pay_date1                      -- OUT DATE              支払日(OUT)
        );
        IF( lv_retcode = cv_status_error ) THEN
          RAISE get_close_date_expt;
        END IF;
        --==================================================
        -- 支払予定日取得（支払条件）
        --==================================================
        ld_expect_payment_date1 :=
          get_operating_day_f(
            id_proc_date             => ld_pay_date1                             -- IN DATE   処理日
          , in_days                  => 0                                        -- IN NUMBER 日数
          , in_proc_type             => cn_proc_type_before                      -- IN NUMBER 処理区分
          );
        IF( ld_expect_payment_date1 IS NULL ) THEN
          RAISE get_operating_day_expt;
        END IF;
        --==================================================
        -- 条件別販手販協計算開始・終了日決定（支払条件）
        --==================================================
        ld_bm_support_period_to_1   :=
          get_operating_day_f(
            id_proc_date             => ld_close_date1                           -- IN DATE   処理日
          , in_days                  => i_get_cust_data_rec.settle_amount_cycle  -- IN NUMBER 日数
          , in_proc_type             => cn_proc_type_before                      -- IN NUMBER 処理区分
          );
        IF( ld_bm_support_period_to_1 IS NULL ) THEN
          RAISE get_operating_day_expt;
        END IF;
-- 2009/10/02 Ver.3.1 [仕様変更I_E_566] SCS K.Yamaguchi REPAIR START
--        IF( i_get_cust_data_rec.ship_gyotai_tyu <> cv_gyotai_tyu_vd ) THEN
        IF(    ( i_get_cust_data_rec.ship_gyotai_sho IN ( cv_gyotai_sho_26, cv_gyotai_sho_27 ) )
            OR ( i_get_cust_data_rec.ship_gyotai_tyu <> cv_gyotai_tyu_vd                       )
         ) THEN
-- 2009/10/02 Ver.3.1 [仕様変更I_E_566] SCS K.Yamaguchi REPAIR END
          ld_bm_support_period_from_1 := ld_bm_support_period_to_1;
        ELSE
          ld_bm_support_period_from_1 :=
            get_operating_day_f(
              id_proc_date             => ld_close_date1                           -- IN DATE   処理日
            , in_days                  => ABS( gn_bm_support_period_from )         -- IN NUMBER 日数
            , in_proc_type             => cn_proc_type_before                      -- IN NUMBER 処理区分
            );
          IF( ld_bm_support_period_from_1 IS NULL ) THEN
            RAISE get_operating_day_expt;
          END IF;
        END IF;
      ELSE
        ld_bm_support_period_from_1 := NULL;
        ld_bm_support_period_to_1   := NULL;
      END IF;
      --==================================================
      -- 支払条件判定（支払条件）
      --==================================================
      IF( gd_process_date BETWEEN ld_bm_support_period_from_1
                              AND ld_bm_support_period_to_1  ) THEN
        lv_fix_term_name              := i_get_cust_data_rec.term_name1;
        ld_fix_close_date             := ld_close_date1;
-- 2009/12/10 Ver.3.5 [E_本稼動_00363] SCS K.Yamaguchi REPAIR START
--        ld_fix_expect_payment_date    := ld_pay_date1;
        ld_fix_expect_payment_date    := ld_expect_payment_date1;
-- 2009/12/10 Ver.3.5 [E_本稼動_00363] SCS K.Yamaguchi REPAIR END
        ld_fix_bm_support_period_from := ld_bm_support_period_from_1;
        ld_fix_bm_support_period_to   := ld_bm_support_period_to_1;
      END IF;
      --==================================================
      -- 第2支払条件
      -- （第1）支払条件で計算対象外の場合のみ
      --==================================================
      IF(     ( lv_fix_term_name IS NULL )
          AND ( i_get_cust_data_rec.term_name2 IS NOT NULL )
      ) THEN
        --==================================================
        -- 締め支払日取得（第2支払条件）
        --==================================================
        xxcok_common_pkg.get_close_date_p(
          ov_errbuf                  => lv_errbuf                         -- OUT VARCHAR2          ログに出力するエラー・メッセージ
        , ov_retcode                 => lv_retcode                        -- OUT VARCHAR2          リターンコード
        , ov_errmsg                  => lv_errmsg                         -- OUT VARCHAR2          ユーザーに見せるエラー・メッセージ
        , id_proc_date               => ld_tmp_bm_support_period_from     -- IN  DATE DEFAULT NULL 処理日(対象日)
        , iv_pay_cond                => i_get_cust_data_rec.term_name2    -- IN  VARCHAR2          支払条件(IN)
        , od_close_date              => ld_close_date2                    -- OUT DATE              締め日(OUT)
        , od_pay_date                => ld_pay_date2                      -- OUT DATE              支払日(OUT)
        );
        IF( lv_retcode = cv_status_error ) THEN
          RAISE get_close_date_expt;
        END IF;
        --==================================================
        -- 支払予定日取得（第2支払条件）
        --==================================================
        ld_expect_payment_date2 :=
          get_operating_day_f(
            id_proc_date             => ld_pay_date2                             -- IN DATE   処理日
          , in_days                  => 0                                        -- IN NUMBER 日数
          , in_proc_type             => cn_proc_type_before                      -- IN NUMBER 処理区分
          );
        IF( ld_expect_payment_date2 IS NULL ) THEN
          RAISE get_operating_day_expt;
        END IF;
        --==================================================
        -- 条件別販手販協計算開始・終了日決定（第2支払条件）
        --==================================================
        ld_bm_support_period_to_2   :=
          get_operating_day_f(
            id_proc_date             => ld_close_date2                           -- IN DATE   処理日
          , in_days                  => i_get_cust_data_rec.settle_amount_cycle  -- IN NUMBER 日数
          , in_proc_type             => cn_proc_type_before                      -- IN NUMBER 処理区分
          );
        IF( ld_bm_support_period_to_2 IS NULL ) THEN
          RAISE get_operating_day_expt;
        END IF;
-- 2009/10/02 Ver.3.1 [仕様変更I_E_566] SCS K.Yamaguchi REPAIR START
--        IF( i_get_cust_data_rec.ship_gyotai_tyu <> cv_gyotai_tyu_vd ) THEN
        IF(    ( i_get_cust_data_rec.ship_gyotai_sho IN ( cv_gyotai_sho_26, cv_gyotai_sho_27 ) )
            OR ( i_get_cust_data_rec.ship_gyotai_tyu <> cv_gyotai_tyu_vd                       )
         ) THEN
-- 2009/10/02 Ver.3.1 [仕様変更I_E_566] SCS K.Yamaguchi REPAIR END
          ld_bm_support_period_from_2 := ld_bm_support_period_to_2;
        ELSE
          ld_bm_support_period_from_2 := 
            get_operating_day_f(
              id_proc_date             => ld_close_date2                           -- IN DATE   処理日
            , in_days                  => ABS( gn_bm_support_period_from )         -- IN NUMBER 日数
            , in_proc_type             => cn_proc_type_before                      -- IN NUMBER 処理区分
            );
          IF( ld_bm_support_period_from_2 IS NULL ) THEN
            RAISE get_operating_day_expt;
          END IF;
        END IF;
      ELSE
        ld_bm_support_period_from_2 := NULL;
        ld_bm_support_period_to_2   := NULL;
      END IF;
      --==================================================
      -- 支払条件判定（第2支払条件）
      --==================================================
      IF( gd_process_date BETWEEN ld_bm_support_period_from_2
                              AND ld_bm_support_period_to_2  ) THEN
        lv_fix_term_name              := i_get_cust_data_rec.term_name2;
        ld_fix_close_date             := ld_close_date2;
-- 2009/12/10 Ver.3.5 [E_本稼動_00363] SCS K.Yamaguchi REPAIR START
--        ld_fix_expect_payment_date    := ld_pay_date2;
        ld_fix_expect_payment_date    := ld_expect_payment_date2;
-- 2009/12/10 Ver.3.5 [E_本稼動_00363] SCS K.Yamaguchi REPAIR END
        ld_fix_bm_support_period_from := ld_bm_support_period_from_2;
        ld_fix_bm_support_period_to   := ld_bm_support_period_to_2;
      END IF;
      --==================================================
      -- 第3支払条件
      -- （第1）支払条件・第2支払条件で計算対象外の場合のみ
      --==================================================
      IF(     ( lv_fix_term_name IS NULL )
          AND ( i_get_cust_data_rec.term_name3 IS NOT NULL )
      ) THEN
        --==================================================
        -- 締め支払日取得（第3支払条件）
        --==================================================
        xxcok_common_pkg.get_close_date_p(
          ov_errbuf                  => lv_errbuf                         -- OUT VARCHAR2          ログに出力するエラー・メッセージ
        , ov_retcode                 => lv_retcode                        -- OUT VARCHAR2          リターンコード
        , ov_errmsg                  => lv_errmsg                         -- OUT VARCHAR2          ユーザーに見せるエラー・メッセージ
        , id_proc_date               => ld_tmp_bm_support_period_from     -- IN  DATE DEFAULT NULL 処理日(対象日)
        , iv_pay_cond                => i_get_cust_data_rec.term_name3    -- IN  VARCHAR2          支払条件(IN)
        , od_close_date              => ld_close_date3                    -- OUT DATE              締め日(OUT)
        , od_pay_date                => ld_pay_date3                      -- OUT DATE              支払日(OUT)
        );
        IF( lv_retcode = cv_status_error ) THEN
          RAISE get_close_date_expt;
        END IF;
        --==================================================
        -- 支払予定日取得（第3支払条件）
        --==================================================
        ld_expect_payment_date3 :=
          get_operating_day_f(
            id_proc_date             => ld_pay_date3                             -- IN DATE   処理日
          , in_days                  => 0                                        -- IN NUMBER 日数
          , in_proc_type             => cn_proc_type_before                      -- IN NUMBER 処理区分
          );
        IF( ld_expect_payment_date3 IS NULL ) THEN
          RAISE get_operating_day_expt;
        END IF;
        --==================================================
        -- 条件別販手販協計算開始・終了日決定（第3支払条件）
        --==================================================
        ld_bm_support_period_to_3   :=
          get_operating_day_f(
            id_proc_date             => ld_close_date3                           -- IN DATE   処理日
          , in_days                  => i_get_cust_data_rec.settle_amount_cycle  -- IN NUMBER 日数
          , in_proc_type             => cn_proc_type_before                      -- IN NUMBER 処理区分
          );
        IF( ld_bm_support_period_to_3 IS NULL ) THEN
          RAISE get_operating_day_expt;
        END IF;
-- 2009/10/02 Ver.3.1 [仕様変更I_E_566] SCS K.Yamaguchi REPAIR START
--        IF( i_get_cust_data_rec.ship_gyotai_tyu <> cv_gyotai_tyu_vd ) THEN
        IF(    ( i_get_cust_data_rec.ship_gyotai_sho IN ( cv_gyotai_sho_26, cv_gyotai_sho_27 ) )
            OR ( i_get_cust_data_rec.ship_gyotai_tyu <> cv_gyotai_tyu_vd                       )
         ) THEN
-- 2009/10/02 Ver.3.1 [仕様変更I_E_566] SCS K.Yamaguchi REPAIR END
          ld_bm_support_period_from_3 := ld_bm_support_period_to_3;
        ELSE
          ld_bm_support_period_from_3 := 
            get_operating_day_f(
              id_proc_date             => ld_close_date3                           -- IN DATE   処理日
            , in_days                  => ABS( gn_bm_support_period_from )         -- IN NUMBER 日数
            , in_proc_type             => cn_proc_type_before                      -- IN NUMBER 処理区分
            );
          IF( ld_bm_support_period_from_3 IS NULL ) THEN
            RAISE get_operating_day_expt;
          END IF;
        END IF;
      ELSE
        ld_bm_support_period_from_3 := NULL;
        ld_bm_support_period_to_3   := NULL;
      END IF;
      --==================================================
      -- 支払条件判定（第3支払条件）
      --==================================================
      IF( gd_process_date BETWEEN ld_bm_support_period_from_3
                              AND ld_bm_support_period_to_3  ) THEN
        lv_fix_term_name              := i_get_cust_data_rec.term_name3;
        ld_fix_close_date             := ld_close_date3;
-- 2009/12/10 Ver.3.5 [E_本稼動_00363] SCS K.Yamaguchi REPAIR START
--        ld_fix_expect_payment_date    := ld_pay_date3;
        ld_fix_expect_payment_date    := ld_expect_payment_date3;
-- 2009/12/10 Ver.3.5 [E_本稼動_00363] SCS K.Yamaguchi REPAIR END
        ld_fix_bm_support_period_from := ld_bm_support_period_from_3;
        ld_fix_bm_support_period_to   := ld_bm_support_period_to_3;
      END IF;
      --==================================================
      -- 支払条件判定
      -- すべての支払条件で計算対象外の場合
      --==================================================
      IF( lv_fix_term_name IS NULL ) THEN
        lv_fix_term_name              := NULL;
        ld_fix_close_date             := NULL;
        ld_fix_expect_payment_date    := NULL;
        ld_fix_bm_support_period_from := NULL;
        ld_fix_bm_support_period_to   := NULL;
        ld_amount_fix_date            := NULL;
        RAISE skip_proc_expt;
      END IF;
      --==================================================
      -- 金額確定日取得
      --==================================================
      IF( lv_fix_term_name IS NOT NULL ) THEN
        ld_amount_fix_date := 
          get_operating_day_f(
            id_proc_date             => ld_fix_close_date                        -- IN DATE   処理日
          , in_days                  => i_get_cust_data_rec.settle_amount_cycle  -- IN NUMBER 日数
          , in_proc_type             => cn_proc_type_before                      -- IN NUMBER 処理区分
          );
        IF( ld_amount_fix_date IS NULL ) THEN
          RAISE get_operating_day_expt;
        END IF;
      END IF;
    END IF;
-- 2010/05/26 Ver.3.11 [E_本稼動_02855] SCS K.Yamaguchi DELETE START
--fnd_file.put_line(
--  FND_FILE.LOG
--,           '"' || i_get_cust_data_rec.ship_cust_code || '"'
--  || ',' || '"' || i_get_cust_data_rec.term_name1     || '"'
--  || ',' || '"' || ld_pay_date1                       || '"'
--  || ',' || '"' || ld_close_date1                     || '"'
--  || ',' || '"' || ld_bm_support_period_from_1        || '"'
--  || ',' || '"' || ld_bm_support_period_to_1          || '"'
--  || ',' || '"' || i_get_cust_data_rec.term_name2     || '"'
--  || ',' || '"' || ld_pay_date2                       || '"'
--  || ',' || '"' || ld_close_date2                     || '"'
--  || ',' || '"' || ld_bm_support_period_from_2        || '"'
--  || ',' || '"' || ld_bm_support_period_to_2          || '"'
--  || ',' || '"' || i_get_cust_data_rec.term_name3     || '"'
--  || ',' || '"' || ld_pay_date3                       || '"'
--  || ',' || '"' || ld_close_date3                     || '"'
--  || ',' || '"' || ld_bm_support_period_from_3        || '"'
--  || ',' || '"' || ld_bm_support_period_to_3          || '"'
--  || ',' || '"' || ld_amount_fix_date                 || '"'
--); -- For Debug
-- 2010/05/26 Ver.3.11 [E_本稼動_02855] SCS K.Yamaguchi DELETE END
    --==================================================
    -- 会計期間取得
    --==================================================
    IF( i_get_cust_data_rec.ship_gyotai_sho = cv_gyotai_sho_25 ) THEN
      xxcok_common_pkg.get_acctg_calendar_p(
        ov_errbuf                 => lv_errbuf                        -- OUT VARCHAR2     エラーバッファ
      , ov_retcode                => lv_retcode                       -- OUT VARCHAR2     リターンコード
      , ov_errmsg                 => lv_errmsg                        -- OUT VARCHAR2     エラーメッセージ
      , in_set_of_books_id        => gn_set_of_books_id               -- IN  NUMBER       会計帳簿ID
      , iv_application_short_name => cv_appl_short_name_gl            -- IN  VARCHAR2     アプリケーション短縮名
      , id_object_date            => ld_fix_expect_payment_date       -- IN  DATE         対象日
      , on_period_year            => ln_period_year                   -- OUT NUMBER       会計年度
      , ov_period_name            => lv_period_name                   -- OUT VARCHAR2     会計期間名
      , ov_closing_status         => lv_closing_status                -- OUT VARCHAR2     ステータス
      );
      IF( lv_retcode = cv_status_error ) THEN
        RAISE get_acctg_calendar_expt;
      END IF;
    ELSE
      xxcok_common_pkg.get_acctg_calendar_p(
        ov_errbuf                 => lv_errbuf                        -- OUT VARCHAR2     エラーバッファ
      , ov_retcode                => lv_retcode                       -- OUT VARCHAR2     リターンコード
      , ov_errmsg                 => lv_errmsg                        -- OUT VARCHAR2     エラーメッセージ
      , in_set_of_books_id        => gn_set_of_books_id               -- IN  NUMBER       会計帳簿ID
      , iv_application_short_name => cv_appl_short_name_ar            -- IN  VARCHAR2     アプリケーション短縮名
      , id_object_date            => ld_fix_close_date                -- IN  DATE         対象日
      , on_period_year            => ln_period_year                   -- OUT NUMBER       会計年度
      , ov_period_name            => lv_period_name                   -- OUT VARCHAR2     会計期間名
      , ov_closing_status         => lv_closing_status                -- OUT VARCHAR2     ステータス
      );
      IF( lv_retcode = cv_status_error ) THEN
        RAISE get_acctg_calendar_expt;
      END IF;
    END IF;
    --==================================================
    -- 出力パラメータ設定
    --==================================================
    ov_term_name              := lv_fix_term_name;
    od_close_date             := ld_fix_close_date;
    od_expect_payment_date    := ld_fix_expect_payment_date;
    od_bm_support_period_from := ld_fix_bm_support_period_from;
    od_bm_support_period_to   := ld_fix_bm_support_period_to;
    on_period_year            := ln_period_year;
    od_amount_fix_date        := ld_amount_fix_date;
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
    ov_retcode := lv_end_retcode;
--
  EXCEPTION
    -- *** 計算対象外スキップ ***
    WHEN skip_proc_expt THEN
      ov_term_name              := NULL;
      od_close_date             := NULL;
      od_expect_payment_date    := NULL;
      od_bm_support_period_from := NULL;
      od_bm_support_period_to   := NULL;
      on_period_year            := NULL;
      ov_errbuf  := NULL;
      ov_errmsg  := NULL;
      ov_retcode := cv_status_normal;
    -- *** 締め・支払日取得関数エラー ***
    WHEN get_close_date_expt THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_10454
                    , iv_token_name1          => cv_tkn_cust_code
                    , iv_token_value1         => i_get_cust_data_rec.ship_cust_code
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      ov_term_name              := NULL;
      od_close_date             := NULL;
      od_expect_payment_date    := NULL;
      od_bm_support_period_from := NULL;
      od_bm_support_period_to   := NULL;
      on_period_year            := NULL;
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_warn;
    -- *** 営業日取得関数エラー ***
    WHEN get_operating_day_expt THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_10455
                    , iv_token_name1          => cv_tkn_cust_code
                    , iv_token_value1         => i_get_cust_data_rec.ship_cust_code
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      ov_term_name              := NULL;
      od_close_date             := NULL;
      od_expect_payment_date    := NULL;
      od_bm_support_period_from := NULL;
      od_bm_support_period_to   := NULL;
      on_period_year            := NULL;
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_warn;
    -- *** 会計カレンダ取得関数エラー ***
    WHEN get_acctg_calendar_expt THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_10456
                    , iv_token_name1          => cv_tkn_cust_code
                    , iv_token_value1         => i_get_cust_data_rec.ship_cust_code
                    , iv_token_name2          => cv_tkn_proc_date
                    , iv_token_value2         => ld_fix_expect_payment_date
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      ov_term_name              := NULL;
      od_close_date             := NULL;
      od_expect_payment_date    := NULL;
      od_bm_support_period_from := NULL;
      od_bm_support_period_to   := NULL;
      on_period_year            := NULL;
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_warn;
    -- *** エラー終了 ***
    WHEN error_proc_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    --*** 処理部共通例外 ***
    WHEN global_process_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := lv_end_retcode;
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END get_cust_subdata;
--
  /**********************************************************************************
   * Procedure Name   : cust_loop
   * Description      : 顧客情報ループ(A-4)
   ***********************************************************************************/
  PROCEDURE cust_loop(
    ov_errbuf                      OUT VARCHAR2        -- エラー・メッセージ
  , ov_retcode                     OUT VARCHAR2        -- リターン・コード
  , ov_errmsg                      OUT VARCHAR2        -- ユーザー・エラー・メッセージ
  )
  IS
    --==================================================
    -- ローカル定数
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'cust_loop';             -- プログラム名
    --==================================================
    -- ローカル変数
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- エラー・メッセージ
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ユーザー・エラー・メッセージ
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- 出力用メッセージ
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- メッセージ出力関数戻り値
    lv_term_name                   VARCHAR2(5000) DEFAULT NULL;                 -- 支払条件
    ld_close_date                  DATE           DEFAULT NULL;                 -- 締め日
    ld_expect_payment_date         DATE           DEFAULT NULL;                 -- 支払予定日
    ld_bm_support_period_from      DATE           DEFAULT NULL;                 -- 条件別販手販協計算開始日
    ld_bm_support_period_to        DATE           DEFAULT NULL;                 -- 条件別販手販協計算終了日
    ln_period_year                 NUMBER         DEFAULT NULL;                 -- 会計年度
    ld_amount_fix_date             DATE           DEFAULT NULL;                 -- 金額確定日
-- 2010/02/19 Ver.3.8 [障害E_本稼動_01446] SCS S.Moriyama ADD START
-- 2012/06/15 Ver.3.15 [E_本稼動_08751] SCSK S.Niki MOD START
--    lt_emp_code                    xxcok_tmp_014a01c_custdata.emp_code%TYPE;    -- 担当者コード
    lt_emp_code                    xxcok_wk_014a01c_custdata.emp_code%TYPE;     -- 担当者コード
-- 2012/06/15 Ver.3.15 [E_本稼動_08751] SCSK S.Niki MOD END
-- 2010/02/19 Ver.3.8 [障害E_本稼動_01446] SCS S.Moriyama ADD END
    -- ログ出力用退避項目
    lt_ship_cust_code              hz_cust_accounts.account_number      %TYPE DEFAULT NULL;
--
  BEGIN
    --==================================================
    -- ステータス初期化
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- 顧客情報の取得
    --==================================================
    << cust_data_loop >>
    FOR get_cust_data_rec IN get_cust_data_cur LOOP
      lt_ship_cust_code := get_cust_data_rec.ship_cust_code;
      gn_target_cnt := gn_target_cnt + 1;
      DECLARE
        normal_skip_expt           EXCEPTION; -- 処理スキップ
      BEGIN
        --==================================================
        -- 条件別販手販協計算日付情報の導出
        --==================================================
        get_cust_subdata(
          ov_errbuf                   => lv_errbuf                  -- エラー・メッセージ
        , ov_retcode                  => lv_retcode                 -- リターン・コード
        , ov_errmsg                   => lv_errmsg                  -- ユーザー・エラー・メッセージ
        , i_get_cust_data_rec         => get_cust_data_rec          -- 顧客情報レコード
        , ov_term_name                => lv_term_name               -- 支払条件
        , od_close_date               => ld_close_date              -- 締め日
        , od_expect_payment_date      => ld_expect_payment_date     -- 支払予定日
        , od_bm_support_period_from   => ld_bm_support_period_from  -- 条件別販手販協計算開始日
        , od_bm_support_period_to     => ld_bm_support_period_to    -- 条件別販手販協計算終了日
        , on_period_year              => ln_period_year             -- 会計年度
        , od_amount_fix_date          => ld_amount_fix_date         -- 金額確定日
        );
        IF( lv_retcode = cv_status_error ) THEN
          lv_end_retcode := cv_status_error;
          RAISE global_process_expt;
        ELSIF( lv_retcode = cv_status_warn ) THEN
          RAISE warning_skip_expt;
        END IF;
        --==================================================
        -- 条件別販手販協計算顧客情報一時表への登録
        --==================================================
        IF( gd_process_date BETWEEN ld_bm_support_period_from AND ld_bm_support_period_to ) THEN
-- 2010/02/19 Ver.3.8 [障害E_本稼動_01446] SCS S.Moriyama ADD START
          --==================================================
          -- 担当営業員チェック
          --==================================================
          lt_emp_code := xxcok_common_pkg.get_sales_staff_code_f(
                             iv_customer_code => get_cust_data_rec.ship_cust_code
                           , id_proc_date     => ld_close_date
                         );
          IF ( lt_emp_code IS NULL ) THEN
            lv_outmsg  := xxccp_common_pkg.get_msg(
                            iv_application          => cv_appl_short_name_cok
                          , iv_name                 => cv_msg_cok_00105
                          , iv_token_name1          => cv_tkn_cust_code
                          , iv_token_value1         => get_cust_data_rec.ship_cust_code
                          , iv_token_name2          => cv_tkn_base_code
                          , iv_token_value2         => get_cust_data_rec.sale_base_code
                          );
            lb_retcode := xxcok_common_pkg.put_message_f(
                            in_which                => FND_FILE.OUTPUT
                          , iv_message              => lv_outmsg
                          , in_new_line             => 0
                          );
            RAISE warning_skip_expt;
          END IF;
-- 2010/02/19 Ver.3.8 [障害E_本稼動_01446] SCS S.Moriyama ADD END
-- 2009/10/19 Ver.3.2 [障害E_T3_00631] SCS K.Yamaguchi ADD START
          --==================================================
          -- 税コード・税率取得
          --==================================================
          get_tax_rate(
            ov_errbuf                   => lv_errbuf                  -- エラー・メッセージ
          , ov_retcode                  => lv_retcode                 -- リターン・コード
          , ov_errmsg                   => lv_errmsg                  -- ユーザー・エラー・メッセージ
          , it_tax_div                  => get_cust_data_rec.tax_div  -- 消費税区分
          , id_target_date              => ld_close_date              -- 基準日（締め日）
          , ot_tax_code                 => get_cust_data_rec.tax_code -- 税金コード
          , ot_tax_rate                 => get_cust_data_rec.tax_rate -- 税率
          );
          IF( lv_retcode = cv_status_error ) THEN
            lv_end_retcode := cv_status_error;
            RAISE global_process_expt;
          ELSIF( lv_retcode = cv_status_warn ) THEN
            RAISE warning_skip_expt;
          END IF;
-- 2009/10/19 Ver.3.2 [障害E_T3_00631] SCS K.Yamaguchi ADD END
          --==================================================
          -- 条件別販手販協計算顧客情報一時表登録
          --==================================================
          insert_xt0c(
            ov_errbuf                   => lv_errbuf                  -- エラー・メッセージ
          , ov_retcode                  => lv_retcode                 -- リターン・コード
          , ov_errmsg                   => lv_errmsg                  -- ユーザー・エラー・メッセージ
          , i_get_cust_data_rec         => get_cust_data_rec          -- 顧客情報レコード
          , iv_term_name                => lv_term_name               -- 支払条件
          , id_close_date               => ld_close_date              -- 締め日
          , id_expect_payment_date      => ld_expect_payment_date     -- 支払予定日
          , in_period_year              => ln_period_year             -- 会計年度
          , id_amount_fix_date          => ld_amount_fix_date         -- 金額確定日
-- 2010/02/19 Ver.3.8 [障害E_本稼動_01446] SCS S.Moriyama ADD START
          , it_emp_code                 => lt_emp_code                -- 担当者コード
-- 2010/02/19 Ver.3.8 [障害E_本稼動_01446] SCS S.Moriyama ADD END
          );
          IF( lv_retcode = cv_status_error ) THEN
            lv_end_retcode := cv_status_error;
            RAISE global_process_expt;
          ELSIF( lv_retcode = cv_status_warn ) THEN
            RAISE warning_skip_expt;
          END IF;
        ELSE
          RAISE normal_skip_expt;
        END IF;
        --==================================================
        -- 正常件数カウント
        --==================================================
        gn_normal_cnt := gn_normal_cnt + 1;
-- 2012/06/19 Ver.3.15 [E_本稼動_08751] SCSK S.Niki ADD START
        -- 件数カウント
        gn_insert_xt0c_cnt := gn_insert_xt0c_cnt + 1;
-- 2012/06/19 Ver.3.15 [E_本稼動_08751] SCSK S.Niki ADD END
      EXCEPTION
        WHEN normal_skip_expt THEN
          --==================================================
          -- スキップ件数カウント
          --==================================================
          gn_skip_cnt := gn_skip_cnt + 1;
        WHEN warning_skip_expt THEN
          --==================================================
          -- 異常件数カウント
          --==================================================
          gn_error_cnt := gn_error_cnt + 1;
          --==================================================
          -- ステータス設定
          --==================================================
          lv_end_retcode := cv_status_warn;
      END;
    END LOOP cust_data_loop;
    --==================================================
    -- 出力パラメータ設定
    --==================================================
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
    ov_retcode := lv_end_retcode;
--
  EXCEPTION
    -- *** エラー終了 ***
    WHEN error_proc_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 処理部共通例外 ***
    WHEN global_process_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := lv_end_retcode;
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END cust_loop;
--
  /**********************************************************************************
   * Procedure Name   : purge_xcbi
   * Description      : 販手計算済顧客情報データの削除（保持期間外）(A-14)
   ***********************************************************************************/
  PROCEDURE purge_xcbi(
    ov_errbuf                      OUT VARCHAR2        -- エラー・メッセージ
  , ov_retcode                     OUT VARCHAR2        -- リターン・コード
  , ov_errmsg                      OUT VARCHAR2        -- ユーザー・エラー・メッセージ
  )
  IS
    --==================================================
    -- ローカル定数
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'purge_xcbi';             -- プログラム名
    --==================================================
    -- ローカル変数
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- エラー・メッセージ
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ユーザー・エラー・メッセージ
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- 出力用メッセージ
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- メッセージ出力関数戻り値
    ld_start_date                  DATE           DEFAULT NULL;                 -- 業務月月初日
    --==================================================
    -- ローカルカーソル
    --==================================================
    CURSOR xcbi_parge_lock_cur(
      id_target_date               IN  DATE
    )
    IS
      SELECT /*+ LEADING(flv hl hps hcas hca xcbi) */
             xcbi.cust_bm_info_id       AS cust_bm_info_id
      FROM xxcok_cust_bm_info      xcbi               -- 販手販協計算済顧客情報テーブル
         , hz_cust_accounts        hca                -- 顧客マスタ
         , hz_cust_acct_sites_all  hcas               -- 顧客サイトマスタ
         , hz_parties              hp                 -- パーティマスタ
         , hz_party_sites          hps                -- パーティサイトマスタ
         , hz_locations            hl                 -- 顧客所在地マスタ
         , fnd_lookup_values       flv                -- 販手販協計算実行区分
      WHERE xcbi.cust_code                   = hca.account_number
        AND hca.cust_account_id              = hcas.cust_account_id
        AND hca.party_id                     = hp.party_id
        AND hp.party_id                      = hps.party_id
        AND hcas.party_site_id               = hps.party_site_id
        AND hps.location_id                  = hl.location_id
        AND hcas.org_id                      = gn_org_id
        AND flv.lookup_type                  = cv_lookup_type_01
        AND flv.attribute1                   = gv_param_proc_type
        AND flv.language                     = cv_lang
        AND gd_process_date            BETWEEN NVL( flv.start_date_active, gd_process_date )
                                           AND NVL( flv.end_date_active  , gd_process_date )
        AND flv.enabled_flag                 = cv_enable
        AND hl.address3                   LIKE flv.lookup_code || '%'
        AND xcbi.last_fix_closing_date       < id_target_date
      FOR UPDATE OF xcbi.cust_bm_info_id NOWAIT
    ;
--
  BEGIN
    --==================================================
    -- ステータス初期化
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- 月初日取得
    --==================================================
    ld_start_date := ADD_MONTHS( TRUNC( gd_process_date, 'MM' ), - gn_sales_retention_period );
    --==================================================
    -- 販手販協計算済顧客情報削除ループ
    --==================================================
    << xcbs_parge_lock_loop >>
    FOR xcbi_parge_lock_rec IN xcbi_parge_lock_cur( ld_start_date ) LOOP
      --==================================================
      -- 販手販協計算済顧客情報データ削除
      --==================================================
      BEGIN
        DELETE
        FROM xxcok_cust_bm_info      xcbi
        WHERE xcbi.cust_bm_info_id = xcbi_parge_lock_rec.cust_bm_info_id
        ;
-- 2012/06/19 Ver.3.15 [E_本稼動_08751] SCSK S.Niki ADD START
        -- 件数カウント
        gn_target_cnt     := gn_target_cnt + 1;
        gn_purge_xcbi_cnt := gn_purge_xcbi_cnt + 1;
        gn_normal_cnt     := gn_normal_cnt + 1;
-- 2012/06/19 Ver.3.15 [E_本稼動_08751] SCSK S.Niki ADD END
      EXCEPTION
        WHEN OTHERS THEN
          lv_outmsg  := xxccp_common_pkg.get_msg(
                          iv_application          => cv_appl_short_name_cok
                        , iv_name                 => cv_msg_cok_10457
                        );
          lb_retcode := xxcok_common_pkg.put_message_f(
                          in_which                => FND_FILE.OUTPUT
                        , iv_message              => lv_outmsg
                        , in_new_line             => 0
                        );
          RAISE error_proc_expt;
      END;
    END LOOP xcbi_parge_lock_loop;
    --==================================================
    -- 出力パラメータ設定
    --==================================================
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
    ov_retcode := lv_end_retcode;
--
  EXCEPTION
    --*** ロック取得エラー ***
    WHEN resource_busy_expt THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00103
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** エラー終了 ***
    WHEN error_proc_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 処理部共通例外 ***
    WHEN global_process_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := lv_end_retcode;
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END purge_xcbi;
--
  /**********************************************************************************
   * Procedure Name   : purge_xcbs
   * Description      : 条件別販手販協データの削除（保持期間外）(A-2)
   ***********************************************************************************/
  PROCEDURE purge_xcbs(
    ov_errbuf                      OUT VARCHAR2        -- エラー・メッセージ
  , ov_retcode                     OUT VARCHAR2        -- リターン・コード
  , ov_errmsg                      OUT VARCHAR2        -- ユーザー・エラー・メッセージ
  )
  IS
    --==================================================
    -- ローカル定数
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'purge_xcbs';             -- プログラム名
    --==================================================
    -- ローカル変数
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- エラー・メッセージ
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ユーザー・エラー・メッセージ
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- 出力用メッセージ
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- メッセージ出力関数戻り値
    ld_start_date                  DATE           DEFAULT NULL;                 -- 業務月月初日
    --==================================================
    -- ローカルカーソル
    --==================================================
    CURSOR xcbs_parge_lock_cur(
      id_target_date               IN  DATE
    )
    IS
      SELECT /*+ LEADING(flv hl) */
             xcbs.cond_bm_support_id    AS cond_bm_support_id
      FROM xxcok_cond_bm_support   xcbs               -- 条件別販手販協テーブル
         , hz_cust_accounts        hca                -- 顧客マスタ
         , hz_cust_acct_sites_all  hcas               -- 顧客サイトマスタ
         , hz_parties              hp                 -- パーティマスタ
         , hz_party_sites          hps                -- パーティサイトマスタ
         , hz_locations            hl                 -- 顧客所在地マスタ
         , fnd_lookup_values       flv                -- 販手販協計算実行区分
      WHERE xcbs.delivery_cust_code          = hca.account_number
        AND hca.cust_account_id              = hcas.cust_account_id
        AND hca.party_id                     = hp.party_id
        AND hp.party_id                      = hps.party_id
        AND hcas.party_site_id               = hps.party_site_id
        AND hps.location_id                  = hl.location_id
        AND hcas.org_id                      = gn_org_id
        AND flv.lookup_type                  = cv_lookup_type_01
        AND flv.attribute1                   = gv_param_proc_type
        AND flv.language                     = cv_lang
        AND gd_process_date            BETWEEN NVL( flv.start_date_active, gd_process_date )
                                           AND NVL( flv.end_date_active  , gd_process_date )
        AND flv.enabled_flag                 = cv_enable
        AND hl.address3                   LIKE flv.lookup_code || '%'
        AND xcbs.closing_date                < id_target_date
        AND xcbs.cond_bm_interface_status   <> cv_xcbs_if_status_no
        AND xcbs.bm_interface_status        <> cv_xcbs_if_status_no
        AND xcbs.ar_interface_status        <> cv_xcbs_if_status_no
        AND NOT EXISTS ( SELECT 'X'
                         FROM xxcok_backmargin_balance      xbb
                         WHERE xbb.base_code                = xcbs.base_code
                           AND xbb.cust_code                = xcbs.delivery_cust_code
                           AND xbb.supplier_code            = xcbs.supplier_code
                           AND xbb.supplier_site_code       = xcbs.supplier_site_code
                           AND xbb.closing_date             = xcbs.closing_date
                           AND xbb.expect_payment_date      = xcbs.expect_payment_date
                           AND ROWNUM = 1
            )
      FOR UPDATE OF xcbs.cond_bm_support_id NOWAIT
    ;
--
  BEGIN
    --==================================================
    -- ステータス初期化
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- 月初日取得
    --==================================================
    ld_start_date := ADD_MONTHS( TRUNC( gd_process_date, 'MM' ), - gn_sales_retention_period );
    --==================================================
    -- 条件別販手販協削除ループ
    --==================================================
    << xcbs_parge_lock_loop >>
    FOR xcbs_parge_lock_rec IN xcbs_parge_lock_cur( ld_start_date ) LOOP
      --==================================================
      -- 条件別販手販協データ削除
      --==================================================
      BEGIN
        DELETE
        FROM xxcok_cond_bm_support   xcbs
        WHERE xcbs.cond_bm_support_id = xcbs_parge_lock_rec.cond_bm_support_id
        ;
-- 2012/06/19 Ver.3.15 [E_本稼動_08751] SCSK S.Niki ADD START
        -- 件数カウント
        gn_target_cnt     := gn_target_cnt + 1;
        gn_purge_xcbs_cnt := gn_purge_xcbs_cnt + 1;
        gn_normal_cnt     := gn_normal_cnt + 1;
-- 2012/06/19 Ver.3.15 [E_本稼動_08751] SCSK S.Niki ADD END
      EXCEPTION
        WHEN OTHERS THEN
          lv_outmsg  := xxccp_common_pkg.get_msg(
                          iv_application          => cv_appl_short_name_cok
                        , iv_name                 => cv_msg_cok_10398
                        );
          lb_retcode := xxcok_common_pkg.put_message_f(
                          in_which                => FND_FILE.OUTPUT
                        , iv_message              => lv_outmsg
                        , in_new_line             => 0
                        );
          RAISE error_proc_expt;
      END;
    END LOOP xcbs_parge_lock_loop;
    --==================================================
    -- 出力パラメータ設定
    --==================================================
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
    ov_retcode := lv_end_retcode;
--
  EXCEPTION
    --*** ロック取得エラー ***
    WHEN resource_busy_expt THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00051
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** エラー終了 ***
    WHEN error_proc_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 処理部共通例外 ***
    WHEN global_process_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := lv_end_retcode;
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END purge_xcbs;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf                      OUT VARCHAR2        -- エラー・メッセージ
  , ov_retcode                     OUT VARCHAR2        -- リターン・コード
  , ov_errmsg                      OUT VARCHAR2        -- ユーザー・エラー・メッセージ
  , iv_proc_date                   IN  VARCHAR2        -- 業務日付
  , iv_proc_type                   IN  VARCHAR2        -- 実行区分
-- 2012/06/15 Ver.3.15 [E_本稼動_08751] SCSK S.Niki ADD START
  , iv_proc_flag                   IN  VARCHAR2        -- 起動フラグ
-- 2012/06/15 Ver.3.15 [E_本稼動_08751] SCSK S.Niki ADD END
  )
  IS
    --==================================================
    -- ローカル定数
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'init';             -- プログラム名
    --==================================================
    -- ローカル変数
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- エラー・メッセージ
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ユーザー・エラー・メッセージ
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- 出力用メッセージ
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- メッセージ出力関数戻り値
--
  BEGIN
    --==================================================
    -- ステータス初期化
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- プログラム入力項目を出力
    --==================================================
    -- 業務日付
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application          => cv_appl_short_name_cok
                  , iv_name                 => cv_msg_cok_00022
                  , iv_token_name1          => cv_tkn_business_date
                  , iv_token_value1         => iv_proc_date
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                => FND_FILE.OUTPUT    -- 出力区分
                  , iv_message              => lv_outmsg         -- メッセージ
                  , in_new_line             => 0                  -- 改行
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                => FND_FILE.LOG
                  , iv_message              => lv_outmsg
                  , in_new_line             => 0
                  );
    -- 処理区分
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application          => cv_appl_short_name_cok
                  , iv_name                 => cv_msg_cok_00044
                  , iv_token_name1          => cv_tkn_proc_type
                  , iv_token_value1         => iv_proc_type
                  );
    lb_retcode := xxcok_common_pkg.put_message_f( 
                    in_which                => FND_FILE.OUTPUT    -- 出力区分
                  , iv_message              => lv_outmsg          -- メッセージ
-- 2012/06/15 Ver.3.15 [E_本稼動_08751] SCSK S.Niki MOD START
--                  , in_new_line             => 1                  -- 改行
                  , in_new_line             => 0                  -- 改行
-- 2012/06/15 Ver.3.15 [E_本稼動_08751] SCSK S.Niki MOD END
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                => FND_FILE.LOG
                  , iv_message              => lv_outmsg
-- 2012/06/15 Ver.3.15 [E_本稼動_08751] SCSK S.Niki MOD START
--                  , in_new_line             => 1
                  , in_new_line             => 0
-- 2012/06/15 Ver.3.15 [E_本稼動_08751] SCSK S.Niki MOD END
                  );
-- 2012/06/15 Ver.3.15 [E_本稼動_08751] SCSK S.Niki ADD START
    -- 起動フラグ
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application          => cv_appl_short_name_cok
                  , iv_name                 => cv_msg_cok_10494
                  , iv_token_name1          => cv_tkn_proc_flag
                  , iv_token_value1         => iv_proc_flag
                  );
    lb_retcode := xxcok_common_pkg.put_message_f( 
                    in_which                => FND_FILE.OUTPUT    -- 出力区分
                  , iv_message              => lv_outmsg          -- メッセージ
                  , in_new_line             => 1                  -- 改行
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                => FND_FILE.LOG
                  , iv_message              => lv_outmsg
                  , in_new_line             => 1
                  );
-- 2012/06/15 Ver.3.15 [E_本稼動_08751] SCSK S.Niki ADD END
    --==================================================
    -- プログラム入力項目をグローバル変数へ格納
    --==================================================
    gv_param_proc_date := iv_proc_date;
    gv_param_proc_type := iv_proc_type;
-- 2012/06/15 Ver.3.15 [E_本稼動_08751] SCSK S.Niki ADD START
    gv_param_proc_flag := iv_proc_flag;
-- 2012/06/15 Ver.3.15 [E_本稼動_08751] SCSK S.Niki ADD END
    --==================================================
    -- 業務処理日付取得
    --==================================================
    IF( gv_param_proc_date IS NOT NULL ) THEN
      gd_process_date := TO_DATE( gv_param_proc_date, cv_format_fxrrrrmmdd );
    ELSE
      gd_process_date := TRUNC( xxccp_common_pkg2.get_process_date );
      IF( gd_process_date IS NULL ) THEN
        lv_outmsg  := xxccp_common_pkg.get_msg(
                        iv_application          => cv_appl_short_name_cok
                      , iv_name                 => cv_msg_cok_00028
                      );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which                => FND_FILE.OUTPUT
                      , iv_message              => lv_outmsg
                      , in_new_line             => 0
                      );
        RAISE error_proc_expt;
      END IF;
    END IF;
    --==================================================
    -- プロファイル取得(MO: 営業単位)
    --==================================================
    gn_org_id := TO_NUMBER( FND_PROFILE.VALUE( cv_profile_name_01 ) );
    IF( gn_org_id IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_profile_name_01
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- プロファイル取得(会計帳簿ID)
    --==================================================
    gn_set_of_books_id := TO_NUMBER( FND_PROFILE.VALUE( cv_profile_name_02 ) );
    IF( gn_set_of_books_id IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_profile_name_02
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- プロファイル取得(XXCOK:販手販協計算処理期間（From）)
    --==================================================
    gn_bm_support_period_from := TO_NUMBER( FND_PROFILE.VALUE( cv_profile_name_03 ) );
    IF( gn_bm_support_period_from IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_profile_name_03
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- プロファイル取得(XXCOK:販手販協計算処理期間（To）)
    --==================================================
    gn_bm_support_period_to := TO_NUMBER( FND_PROFILE.VALUE( cv_profile_name_04 ) );
    IF( gn_bm_support_period_to IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_profile_name_04
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- プロファイル取得(XXCOK:販手販協情報保持期間)
    --==================================================
    gn_sales_retention_period := TO_NUMBER( FND_PROFILE.VALUE( cv_profile_name_05 ) );
    IF( gn_sales_retention_period IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_profile_name_05
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- プロファイル取得(電気料（変動）品目コード)
    --==================================================
    gv_elec_change_item_code := FND_PROFILE.VALUE( cv_profile_name_06 );
    IF( gv_elec_change_item_code IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_profile_name_06
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- プロファイル取得(仕入先ダミーコード)
    --==================================================
    gv_vendor_dummy_code := FND_PROFILE.VALUE( cv_profile_name_07 );
    IF( gv_vendor_dummy_code IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_profile_name_07
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- プロファイル取得(支払条件_即時払い)
    --==================================================
    gv_instantly_term_name := FND_PROFILE.VALUE( cv_profile_name_08 );
    IF( gv_instantly_term_name IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_profile_name_08
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- プロファイル取得(支払条件_デフォルト)
    --==================================================
    gv_default_term_name := FND_PROFILE.VALUE( cv_profile_name_09 );
    IF( gv_default_term_name IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_profile_name_09
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- プロファイル取得(在庫組織コード_営業組織)
    --==================================================
    gv_organization_code := FND_PROFILE.VALUE( cv_profile_name_10 );
    IF( gv_organization_code IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_profile_name_10
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
-- 2012/06/15 Ver.3.15 [E_本稼動_08751] SCSK S.Niki ADD START
    --==================================================
    -- プロファイル取得(販手販協_販売実績明細ロック)
    --==================================================
    gv_xsel_data_lock := FND_PROFILE.VALUE( cv_profile_name_11 );
    IF( gv_xsel_data_lock IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_profile_name_11
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
-- 2012/06/15 Ver.3.15 [E_本稼動_08751] SCSK S.Niki ADD END
    --==================================================
    -- 稼働日カレンダコード取得
    --==================================================
    SELECT mp.calendar_code     AS calendar_code        -- カレンダーコード
    INTO gt_calendar_code
    FROM mtl_parameters       mp
    WHERE mp.organization_code = gv_organization_code
    ;
    --==================================================
    -- 出力パラメータ設定
    --==================================================
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
    ov_retcode := lv_end_retcode;
--
  EXCEPTION
    -- *** エラー終了 ***
    WHEN error_proc_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 処理部共通例外 ***
    WHEN global_process_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := lv_end_retcode;
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END init;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf                      OUT VARCHAR2        -- エラー・メッセージ
  , ov_retcode                     OUT VARCHAR2        -- リターン・コード
  , ov_errmsg                      OUT VARCHAR2        -- ユーザー・エラー・メッセージ
  , iv_proc_date                   IN  VARCHAR2        -- 業務日付
  , iv_proc_type                   IN  VARCHAR2        -- 実行区分
-- 2012/06/15 Ver.3.15 [E_本稼動_08751] SCSK S.Niki ADD START
  , iv_proc_flag                   IN  VARCHAR2        -- 起動フラグ
-- 2012/06/15 Ver.3.15 [E_本稼動_08751] SCSK S.Niki ADD END
  )
  IS
    --==================================================
    -- ローカル定数
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'submain';             -- プログラム名
    --==================================================
    -- ローカル変数
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- エラー・メッセージ
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ユーザー・エラー・メッセージ
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- 出力用メッセージ
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- メッセージ出力関数戻り値
--
  BEGIN
    --==================================================
    -- ステータス初期化
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- 初期処理(A-1)
    --==================================================
    init(
      ov_errbuf               => lv_errbuf             -- エラー・メッセージ
    , ov_retcode              => lv_retcode            -- リターン・コード
    , ov_errmsg               => lv_errmsg             -- ユーザー・エラー・メッセージ
    , iv_proc_date            => iv_proc_date          -- 業務日付
    , iv_proc_type            => iv_proc_type          -- 処理区分
-- 2012/06/15 Ver.3.15 [E_本稼動_08751] SCSK S.Niki ADD START
    , iv_proc_flag            => iv_proc_flag          -- 起動フラグ
-- 2012/06/15 Ver.3.15 [E_本稼動_08751] SCSK S.Niki ADD END
    );
    IF( lv_retcode = cv_status_error ) THEN
      lv_end_retcode := cv_status_error;
      RAISE global_process_expt;
    END IF;
-- 2012/06/15 Ver.3.15 [E_本稼動_08751] SCSK S.Niki ADD START
    --==================================================
    -- 起動フラグ：1の場合は、データパージ処理を実行
    --==================================================
    IF ( gv_param_proc_flag = cv_bm_proc_flag_1 ) THEN
-- 2012/06/15 Ver.3.15 [E_本稼動_08751] SCSK S.Niki ADD END
      --==================================================
      -- 条件別販手販協データの削除（保持期間外）(A-2)
      --==================================================
      purge_xcbs(
        ov_errbuf               => lv_errbuf             -- エラー・メッセージ
      , ov_retcode              => lv_retcode            -- リターン・コード
      , ov_errmsg               => lv_errmsg             -- ユーザー・エラー・メッセージ
      );
      IF( lv_retcode = cv_status_error ) THEN
        lv_end_retcode := cv_status_error;
        RAISE global_process_expt;
      END IF;
      --==================================================
      -- 販手計算済顧客情報データの削除（保持期間外）(A-14)
      --==================================================
      purge_xcbi(
        ov_errbuf               => lv_errbuf             -- エラー・メッセージ
      , ov_retcode              => lv_retcode            -- リターン・コード
      , ov_errmsg               => lv_errmsg             -- ユーザー・エラー・メッセージ
      );
      IF( lv_retcode = cv_status_error ) THEN
        lv_end_retcode := cv_status_error;
        RAISE global_process_expt;
      END IF;
      --==================================================
      -- パージ処理の確定
      --==================================================
      COMMIT;
-- 2012/06/15 Ver.3.15 [E_本稼動_08751] SCSK S.Niki ADD START
    END IF;
    --==================================================
    -- 起動フラグ：3の場合は、販手販協計算処理を実行
    --==================================================
    IF ( gv_param_proc_flag = cv_bm_proc_flag_3 ) THEN
-- 2012/06/15 Ver.3.15 [E_本稼動_08751] SCSK S.Niki ADD END
      --==================================================
      -- 条件別販手販協データの削除（未確定金額）(A-3)
      --==================================================
      delete_xcbs(
        ov_errbuf               => lv_errbuf             -- エラー・メッセージ
      , ov_retcode              => lv_retcode            -- リターン・コード
      , ov_errmsg               => lv_errmsg             -- ユーザー・エラー・メッセージ
      );
      IF( lv_retcode = cv_status_error ) THEN
        lv_end_retcode := cv_status_error;
        RAISE global_process_expt;
      END IF;
-- 2012/06/15 Ver.3.15 [E_本稼動_08751] SCSK S.Niki ADD START
    END IF;
--
    --==================================================
    -- 起動フラグ：5の場合は、計算対象顧客一時表削除(A-19)を実行
    --==================================================
    IF ( gv_param_proc_flag = cv_bm_proc_flag_5 ) THEN
      --トランケートを実施
      EXECUTE IMMEDIATE 'TRUNCATE TABLE xxcok.xxcok_wk_014a01c_custdata';
    END IF;
--
    --==================================================
    -- 起動フラグ：2の場合は、計算対象顧客一時表作成を実行
    --==================================================
    IF ( gv_param_proc_flag = cv_bm_proc_flag_2 ) THEN
-- 2012/06/15 Ver.3.15 [E_本稼動_08751] SCSK S.Niki ADD END
      --==================================================
      -- 顧客情報ループ(A-4)
      --==================================================
      cust_loop(
        ov_errbuf               => lv_errbuf             -- エラー・メッセージ
      , ov_retcode              => lv_retcode            -- リターン・コード
      , ov_errmsg               => lv_errmsg             -- ユーザー・エラー・メッセージ
      );
      IF( lv_retcode = cv_status_error ) THEN
        lv_end_retcode := cv_status_error;
        RAISE global_process_expt;
      ELSIF( lv_retcode = cv_status_warn ) THEN
        lv_end_retcode := cv_status_warn;
      END IF;
-- 2012/06/15 Ver.3.15 [E_本稼動_08751] SCSK S.Niki ADD START
    END IF;
    --==================================================
    -- 起動フラグ：3の場合は、販手販協計算処理を実行
    --==================================================
    IF ( gv_param_proc_flag = cv_bm_proc_flag_3 ) THEN
-- 2012/06/15 Ver.3.15 [E_本稼動_08751] SCSK S.Niki ADD END
      --==================================================
      -- 販手条件エラーの削除処理(A-7)
      --==================================================
      delete_xbce(
        ov_errbuf               => lv_errbuf             -- エラー・メッセージ
      , ov_retcode              => lv_retcode            -- リターン・コード
      , ov_errmsg               => lv_errmsg             -- ユーザー・エラー・メッセージ
      );
      IF( lv_retcode = cv_status_error ) THEN
        lv_end_retcode := cv_status_error;
        RAISE global_process_expt;
      END IF;
      --==================================================
      -- 販売実績ループ(A-8)
      --==================================================
      sales_result_loop1(
        ov_errbuf               => lv_errbuf             -- エラー・メッセージ
      , ov_retcode              => lv_retcode            -- リターン・コード
      , ov_errmsg               => lv_errmsg             -- ユーザー・エラー・メッセージ
      );
      IF( lv_retcode = cv_status_error ) THEN
        lv_end_retcode := cv_status_error;
        RAISE global_process_expt;
      ELSIF( lv_retcode = cv_status_warn ) THEN
        lv_end_retcode := cv_status_warn;
      END IF;
      --==================================================
      -- 販売実績ループ(A-8)
      --==================================================
      sales_result_loop2(
        ov_errbuf               => lv_errbuf             -- エラー・メッセージ
      , ov_retcode              => lv_retcode            -- リターン・コード
      , ov_errmsg               => lv_errmsg             -- ユーザー・エラー・メッセージ
      );
      IF( lv_retcode = cv_status_error ) THEN
        lv_end_retcode := cv_status_error;
        RAISE global_process_expt;
      ELSIF( lv_retcode = cv_status_warn ) THEN
        lv_end_retcode := cv_status_warn;
      END IF;
      --==================================================
      -- 販売実績ループ(A-8)
      --==================================================
      sales_result_loop3(
        ov_errbuf               => lv_errbuf             -- エラー・メッセージ
      , ov_retcode              => lv_retcode            -- リターン・コード
      , ov_errmsg               => lv_errmsg             -- ユーザー・エラー・メッセージ
      );
      IF( lv_retcode = cv_status_error ) THEN
        lv_end_retcode := cv_status_error;
        RAISE global_process_expt;
      ELSIF( lv_retcode = cv_status_warn ) THEN
        lv_end_retcode := cv_status_warn;
      END IF;
      --==================================================
      -- 販売実績ループ(A-8)
      --==================================================
      sales_result_loop4(
        ov_errbuf               => lv_errbuf             -- エラー・メッセージ
      , ov_retcode              => lv_retcode            -- リターン・コード
      , ov_errmsg               => lv_errmsg             -- ユーザー・エラー・メッセージ
      );
      IF( lv_retcode = cv_status_error ) THEN
        lv_end_retcode := cv_status_error;
        RAISE global_process_expt;
      ELSIF( lv_retcode = cv_status_warn ) THEN
        lv_end_retcode := cv_status_warn;
      END IF;
      --==================================================
      -- 販売実績ループ(A-8)
      --==================================================
      sales_result_loop5(
        ov_errbuf               => lv_errbuf             -- エラー・メッセージ
      , ov_retcode              => lv_retcode            -- リターン・コード
      , ov_errmsg               => lv_errmsg             -- ユーザー・エラー・メッセージ
      );
      IF( lv_retcode = cv_status_error ) THEN
        lv_end_retcode := cv_status_error;
        RAISE global_process_expt;
      ELSIF( lv_retcode = cv_status_warn ) THEN
        lv_end_retcode := cv_status_warn;
      END IF;
      --==================================================
      -- 販売実績ループ(A-8)
      --==================================================
      sales_result_loop6(
        ov_errbuf               => lv_errbuf             -- エラー・メッセージ
      , ov_retcode              => lv_retcode            -- リターン・コード
      , ov_errmsg               => lv_errmsg             -- ユーザー・エラー・メッセージ
      );
      IF( lv_retcode = cv_status_error ) THEN
        lv_end_retcode := cv_status_error;
        RAISE global_process_expt;
      ELSIF( lv_retcode = cv_status_warn ) THEN
        lv_end_retcode := cv_status_warn;
      END IF;
-- 2012/06/15 Ver.3.15 [E_本稼動_08751] SCSK S.Niki ADD START
    END IF;
    --==================================================
    -- 起動フラグ：4の場合は、販売実績更新処理を実行
    --==================================================
    IF ( gv_param_proc_flag = cv_bm_proc_flag_4 ) THEN
-- 2012/06/15 Ver.3.15 [E_本稼動_08751] SCSK S.Niki ADD END
      --==================================================
      -- 販売実績連携結果の更新(A-12)
      --==================================================
      update_xsel(
        ov_errbuf               => lv_errbuf             -- エラー・メッセージ
      , ov_retcode              => lv_retcode            -- リターン・コード
      , ov_errmsg               => lv_errmsg             -- ユーザー・エラー・メッセージ
      );
      IF( lv_retcode = cv_status_error ) THEN
        lv_end_retcode := cv_status_error;
        RAISE global_process_expt;
      END IF;
      --==================================================
      -- 販手計算済顧客情報データの更新(A-15)
      --==================================================
      update_xcbi(
        ov_errbuf               => lv_errbuf             -- エラー・メッセージ
      , ov_retcode              => lv_retcode            -- リターン・コード
      , ov_errmsg               => lv_errmsg             -- ユーザー・エラー・メッセージ
      );
      IF( lv_retcode = cv_status_error ) THEN
        lv_end_retcode := cv_status_error;
        RAISE global_process_expt;
      END IF;
-- 2012/06/15 Ver.3.15 [E_本稼動_08751] SCSK S.Niki ADD START
    END IF;
-- 2012/06/15 Ver.3.15 [E_本稼動_08751] SCSK S.Niki ADD END
    --==================================================
    -- 出力パラメータ設定
    --==================================================
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
    ov_retcode := lv_end_retcode;
--
  EXCEPTION
    -- *** 処理部共通例外 ***
    WHEN global_process_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := lv_end_retcode;
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
  PROCEDURE main(
    errbuf                         OUT VARCHAR2        -- エラーメッセージ
  , retcode                        OUT VARCHAR2        -- エラーコード
  , iv_proc_date                   IN  VARCHAR2        -- 業務日付
  , iv_proc_type                   IN  VARCHAR2        -- 実行区分
-- 2012/06/15 Ver.3.15 [E_本稼動_08751] SCSK S.Niki ADD START
  , iv_proc_flag                   IN  VARCHAR2        -- 起動フラグ
-- 2012/06/15 Ver.3.15 [E_本稼動_08751] SCSK S.Niki ADD END
  )
  IS
    --==================================================
    -- ローカル定数
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'main';             -- プログラム名
    --==================================================
    -- ローカル変数
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- エラー・メッセージ
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ユーザー・エラー・メッセージ
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- 出力用メッセージ
    lv_message_code                VARCHAR2(100)  DEFAULT NULL;                 -- 終了メッセージコード
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- メッセージ出力関数戻り値
--
  BEGIN
    --==================================================
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    --==================================================
    xxccp_common_pkg.put_log_header(
      ov_retcode              => lv_retcode
    , ov_errbuf               => lv_errbuf
    , ov_errmsg               => lv_errmsg
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    END IF;
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                 => FND_FILE.OUTPUT    -- 出力区分
                  , iv_message               => NULL               -- メッセージ
                  , in_new_line              => 1                  -- 改行
                  );
    --==================================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    --==================================================
    submain(
      ov_errbuf               => lv_errbuf             -- エラー・メッセージ
    , ov_retcode              => lv_retcode            -- リターン・コード
    , ov_errmsg               => lv_errmsg             -- ユーザー・エラー・メッセージ
    , iv_proc_date            => iv_proc_date          -- 業務日付
    , iv_proc_type            => iv_proc_type          -- 実行区分
-- 2012/06/15 Ver.3.15 [E_本稼動_08751] SCSK S.Niki ADD START
    , iv_proc_flag            => iv_proc_flag          -- 起動フラグ
-- 2012/06/15 Ver.3.15 [E_本稼動_08751] SCSK S.Niki ADD END
    );
    --==================================================
    -- 販手条件エラーメッセージ出力
    --==================================================
    IF( gn_contract_err_cnt > 0 ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application           => cv_appl_short_name_cok
                    , iv_name                  => cv_msg_cok_10401
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                 => FND_FILE.OUTPUT
                    , iv_message               => lv_outmsg
                    , in_new_line              => 1
                    );
    END IF;
    --==================================================
    -- エラー出力
    --==================================================
    IF( lv_retcode <> cv_status_normal ) THEN
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                 => FND_FILE.OUTPUT     -- 出力区分
                    , iv_message               => lv_errmsg           -- メッセージ
                    , in_new_line              => 1                   -- 改行
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                 => FND_FILE.LOG
                    , iv_message               => lv_errbuf
                    , in_new_line              => 0
                    );
    END IF;
    --==================================================
    -- 対象件数出力
    --==================================================
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application           => cv_appl_short_name_ccp
                  , iv_name                  => cv_msg_ccp_90000
                  , iv_token_name1           => cv_tkn_count
                  , iv_token_value1          => TO_CHAR( gn_target_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                 => FND_FILE.OUTPUT
                  , iv_message               => lv_outmsg
                  , in_new_line              => 0
                  );
    --==================================================
    -- 成功件数出力(エラー発生の場合、成功件数:0件 エラー件数:1件  対象件数0件の場合、成功件数:0件)
    --==================================================
    IF( lv_retcode = cv_status_error ) THEN
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
-- 2012/06/19 Ver.3.15 [E_本稼動_08751] SCSK S.Niki ADD START
      -- エラー発生の場合、処理件数に0件を出力
      gn_purge_xcbi_cnt  := 0;  -- 販手計算済顧客情報データ削除件数
      gn_purge_xcbs_cnt  := 0;  -- 条件別販手販協データ削除件数
      gn_insert_xt0c_cnt := 0;  -- 計算顧客情報一時表作成件数
      gn_insert_xcbs_cnt := 0;  -- 販手販協計算処理件数
      gn_update_xsel_cnt := 0;  -- 販売実績明細更新件数
-- 2012/06/19 Ver.3.15 [E_本稼動_08751] SCSK S.Niki ADD END
    ELSE
      IF( gn_target_cnt = 0 ) THEN
        gn_normal_cnt := 0;
      END IF;
    END IF;
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application           => cv_appl_short_name_ccp
                  , iv_name                  => cv_msg_ccp_90001
                  , iv_token_name1           => cv_tkn_count
                  , iv_token_value1          => TO_CHAR( gn_normal_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                 => FND_FILE.OUTPUT
                  , iv_message               => lv_outmsg
                  , in_new_line              => 0
                  );
    --==================================================
    -- スキップ件数出力
    --==================================================
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application           => cv_appl_short_name_ccp
                  , iv_name                  => cv_msg_ccp_90003
                  , iv_token_name1           => cv_tkn_count
                  , iv_token_value1          => TO_CHAR( gn_skip_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                 => FND_FILE.OUTPUT
                  , iv_message               => lv_outmsg
                  , in_new_line              => 0
                  );
    --==================================================
    -- エラー件数出力
    --==================================================
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application           => cv_appl_short_name_ccp
                  , iv_name                  => cv_msg_ccp_90002
                  , iv_token_name1           => cv_tkn_count
                  , iv_token_value1          => TO_CHAR( gn_error_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                 => FND_FILE.OUTPUT
                  , iv_message               => lv_outmsg
                  , in_new_line              => 1
                  );
-- 2012/06/19 Ver.3.15 [E_本稼動_08751] SCSK S.Niki ADD START
    --==================================================
    -- 販手計算済顧客情報データ削除件数出力
    --==================================================
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application           => cv_appl_short_name_cok
                  , iv_name                  => cv_msg_cok_10495
                  , iv_token_name1           => cv_tkn_data_name
                  , iv_token_value1          => cv_tkn_val_purge_xcbi_cnt
                  , iv_token_name2           => cv_tkn_count
                  , iv_token_value2          => TO_CHAR( gn_purge_xcbi_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                 => FND_FILE.OUTPUT
                  , iv_message               => lv_outmsg
                  , in_new_line              => 0
                  );
    --==================================================
    -- 条件別販手販協データ削除件数出力
    --==================================================
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application           => cv_appl_short_name_cok
                  , iv_name                  => cv_msg_cok_10495
                  , iv_token_name1           => cv_tkn_data_name
                  , iv_token_value1          => cv_tkn_val_purge_xcbs_cnt
                  , iv_token_name2           => cv_tkn_count
                  , iv_token_value2          => TO_CHAR( gn_purge_xcbs_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                 => FND_FILE.OUTPUT
                  , iv_message               => lv_outmsg
                  , in_new_line              => 0
                  );
    --==================================================
    -- 計算顧客情報一時表作成件数出力
    --==================================================
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application           => cv_appl_short_name_cok
                  , iv_name                  => cv_msg_cok_10495
                  , iv_token_name1           => cv_tkn_data_name
                  , iv_token_value1          => cv_tkn_val_insert_xt0c_cnt
                  , iv_token_name2           => cv_tkn_count
                  , iv_token_value2          => TO_CHAR( gn_insert_xt0c_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                 => FND_FILE.OUTPUT
                  , iv_message               => lv_outmsg
                  , in_new_line              => 0
                  );
    --==================================================
    -- 販手販協計算処理件数出力
    --==================================================
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application           => cv_appl_short_name_cok
                  , iv_name                  => cv_msg_cok_10495
                  , iv_token_name1           => cv_tkn_data_name
                  , iv_token_value1          => cv_tkn_val_insert_xcbs_cnt
                  , iv_token_name2           => cv_tkn_count
                  , iv_token_value2          => TO_CHAR( gn_insert_xcbs_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                 => FND_FILE.OUTPUT
                  , iv_message               => lv_outmsg
                  , in_new_line              => 0
                  );
    --==================================================
    -- 販売実績明細更新件数出力
    --==================================================
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application           => cv_appl_short_name_cok
                  , iv_name                  => cv_msg_cok_10495
                  , iv_token_name1           => cv_tkn_data_name
                  , iv_token_value1          => cv_tkn_val_update_xsel_cnt
                  , iv_token_name2           => cv_tkn_count
                  , iv_token_value2          => TO_CHAR( gn_update_xsel_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                 => FND_FILE.OUTPUT
                  , iv_message               => lv_outmsg
                  , in_new_line              => 1
                  );
-- 2012/06/19 Ver.3.15 [E_本稼動_08751] SCSK S.Niki ADD END
    --==================================================
    -- 処理終了メッセージ出力
    --==================================================
    IF( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_msg_ccp_90004;
    ELSIF( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_msg_ccp_90005;
    ELSE
      lv_message_code := cv_msg_ccp_90006;
    END IF;
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application           => cv_appl_short_name_ccp
                  , iv_name                  => lv_message_code
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                 => FND_FILE.OUTPUT
                  , iv_message               => lv_outmsg
                  , in_new_line              => 0
                  );
    --==================================================
    -- ステータスセット
    --==================================================
    retcode := lv_retcode;
    --==================================================
    -- 終了ステータスエラー時、ロールバック
    --==================================================
    IF( retcode = cv_status_error ) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** 共通関数例外 ***
    WHEN global_api_expt THEN
      errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      retcode := cv_status_error;
      ROLLBACK;
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
  END main;
END XXCOK014A01C;
/
