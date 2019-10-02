CREATE OR REPLACE PACKAGE xxcmn_common_pkg
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2007. All rights reserved.
 *
 * Package Name           : xxcmn_common_pkg(SPEC)
 * Description            : 共通関数(SPEC)
 * MD.070(CMD.050)        : T_MD050_BPO_000_共通関数（補足資料）.xls
 * Version                : 1.6
 *
 * Program List
 *  -------------------- ---- ----- --------------------------------------------------
 *   Name                Type  Ret   Description
 *  -------------------- ---- ----- --------------------------------------------------
 *  get_msg                F   VAR   Message取得
 *  get_user_name          F   VAR   担当者名取得
 *  get_user_dept          F   VAR   担当部署名取得
 *  get_tbl_lock           F   BOL   テーブルロック関数
 *  del_all_data           F   BOL   テーブルデータ一括削除関数
 *  get_opminv_close_period
 *                         F   VAR   OPM在庫会計期間CLOSE年月取得関数
 *  get_category_desc      F   VAR   カテゴリ取得関数
 *  get_sagara_factory_info
 *                         P         伊藤園相良工場情報取得プロシージャ
 *  get_calender_cd        F   VAR   カレンダコード取得関数
 *  check_oprtn_day        F   NUM   稼働日チェック関数
 *  get_seq_no             P         採番関数
 *  get_dept_info          P         部署情報取得プロシージャ
 *  get_term_of_payment    F   VAR   支払条件文言取得関数
 *  check_param_date_yyyymm
 *                         F   NUM   パラメータチェック：日付形式（YYYYMM）
 *  check_param_date_yyyymmdd
 *                         F   NUM   パラメータチェック：日付形式（YYYYMMDD HH24:MI:SS）
 *  put_api_log            P   なし  標準APIログ出力API
 *  get_outbound_info      P   なし  アウトバウンド処理情報取得関数
 *  upd_outbound_info      P   なし  ファイル出力情報更新関数
 *  wf_start               P   なし  ワークフロー起動関数
 *  get_can_enc_total_qty  F   NUM   総引当可能数算出API
 *  get_can_enc_in_time_qty
 *                         F   NUM   有効日ベース引当可能数算出API
 *  get_stock_qty          F   NUM   手持在庫数量算出API
 *  get_can_enc_qty        F   NUM   引当可能数算出API
 *  rcv_ship_conv_qty      F   NUM   入出庫換算関数(生産バッチ用)
 *  get_user_dept_code     F   VAR   担当部署CD取得
 *  create_lot_mst_history P         ロットマスタ履歴作成関数
 *
 * Change Record
 * ------------ ----- ---------------- -----------------------------------------------
 *  Date         Ver.  Editor           Description
 * ------------ ----- ---------------- -----------------------------------------------
 *  2007/12/07   1.0   marushita        新規作成
 *  2008/05/07   1.1   marushita        WF起動関数のWF起動時パラメータにWFオーナーを追加
 *  2008/09/18   1.2   Oracle 山根 一浩 T_S_453対応(WFファイルコピー)
 *  2008/09/30   1.3   Yuko Kawano      OPM在庫会計期間CLOSE年月取得関数 T_S_500対応
 *  2008/10/29   1.4   T.Yoshimoto      統合指摘対応(No.251)
 *  2008/12/29   1.5   A.Shiina         [採番関数]動的に修正
 *  2019/09/19   1.6   Y.Ohishi         ロットマスタ履歴作成関数を追加
 *
 *****************************************************************************************/
--
  -- ===============================
  -- グローバル型
  -- ===============================
  TYPE outbound_rec IS RECORD(
--    wf_ope_div              xxcmn_outbound.wf_ope_div%TYPE,
    wf_class                xxcmn_outbound.wf_class%TYPE,
    wf_notification         xxcmn_outbound.wf_notification%TYPE,
    directory               VARCHAR2(150),
    file_name               VARCHAR2(150),
    file_display_name       VARCHAR2(150),
    file_last_update_date   xxcmn_outbound.file_last_update_date%TYPE,
    wf_name                 VARCHAR2(150),
    wf_owner                VARCHAR2(150),
    user_cd01               VARCHAR2(150),
    user_cd02               VARCHAR2(150),
    user_cd03               VARCHAR2(150),
    user_cd04               VARCHAR2(150),
    user_cd05               VARCHAR2(150),
    user_cd06               VARCHAR2(150),
    user_cd07               VARCHAR2(150),
    user_cd08               VARCHAR2(150),
    user_cd09               VARCHAR2(150),
    user_cd10               VARCHAR2(150)
  );
--
-- Ver_1.6 E_本稼動_15887 ADD Start
  TYPE lot_rec IS RECORD(
    item_id                       ic_lots_mst.item_id%TYPE,
    lot_id                        ic_lots_mst.lot_id%TYPE,
    lot_no                        ic_lots_mst.lot_no%TYPE,
    sublot_no                     ic_lots_mst.sublot_no%TYPE,
    lot_desc                      ic_lots_mst.lot_desc%TYPE,
    qc_grade                      ic_lots_mst.qc_grade%TYPE,
    expaction_code                ic_lots_mst.expaction_code%TYPE,
    expaction_date                ic_lots_mst.expaction_date%TYPE,
    lot_created                   ic_lots_mst.lot_created%TYPE,
    expire_date                   ic_lots_mst.expire_date%TYPE,
    retest_date                   ic_lots_mst.retest_date%TYPE,
    strength                      ic_lots_mst.strength%TYPE,
    inactive_ind                  ic_lots_mst.inactive_ind%TYPE,
    origination_type              ic_lots_mst.origination_type%TYPE,
    shipvend_id                   ic_lots_mst.shipvend_id%TYPE,
    vendor_lot_no                 ic_lots_mst.vendor_lot_no%TYPE,
    creation_date                 ic_lots_mst.creation_date%TYPE,
    last_update_date              ic_lots_mst.last_update_date%TYPE,
    created_by                    ic_lots_mst.created_by%TYPE,
    last_updated_by               ic_lots_mst.last_updated_by%TYPE,
    trans_cnt                     ic_lots_mst.trans_cnt%TYPE,
    delete_mark                   ic_lots_mst.delete_mark%TYPE,
    text_code                     ic_lots_mst.text_code%TYPE,
    last_update_login             ic_lots_mst.last_update_login%TYPE,
    program_application_id        ic_lots_mst.program_application_id%TYPE,
    program_id                    ic_lots_mst.program_id%TYPE,
    program_update_date           ic_lots_mst.program_update_date%TYPE,
    request_id                    ic_lots_mst.request_id%TYPE,
    attribute1                    ic_lots_mst.attribute1%TYPE,
    attribute2                    ic_lots_mst.attribute2%TYPE,
    attribute3                    ic_lots_mst.attribute3%TYPE,
    attribute4                    ic_lots_mst.attribute4%TYPE,
    attribute5                    ic_lots_mst.attribute5%TYPE,
    attribute6                    ic_lots_mst.attribute6%TYPE,
    attribute7                    ic_lots_mst.attribute7%TYPE,
    attribute8                    ic_lots_mst.attribute8%TYPE,
    attribute9                    ic_lots_mst.attribute9%TYPE,
    attribute10                   ic_lots_mst.attribute10%TYPE,
    attribute11                   ic_lots_mst.attribute11%TYPE,
    attribute12                   ic_lots_mst.attribute12%TYPE,
    attribute13                   ic_lots_mst.attribute13%TYPE,
    attribute14                   ic_lots_mst.attribute14%TYPE,
    attribute15                   ic_lots_mst.attribute15%TYPE,
    attribute16                   ic_lots_mst.attribute16%TYPE,
    attribute17                   ic_lots_mst.attribute17%TYPE,
    attribute18                   ic_lots_mst.attribute18%TYPE,
    attribute19                   ic_lots_mst.attribute19%TYPE,
    attribute20                   ic_lots_mst.attribute20%TYPE,
    attribute22                   ic_lots_mst.attribute22%TYPE,
    attribute21                   ic_lots_mst.attribute21%TYPE,
    attribute23                   ic_lots_mst.attribute23%TYPE,
    attribute24                   ic_lots_mst.attribute24%TYPE,
    attribute25                   ic_lots_mst.attribute25%TYPE,
    attribute26                   ic_lots_mst.attribute26%TYPE,
    attribute27                   ic_lots_mst.attribute27%TYPE,
    attribute28                   ic_lots_mst.attribute28%TYPE,
    attribute29                   ic_lots_mst.attribute29%TYPE,
    attribute30                   ic_lots_mst.attribute30%TYPE,
    attribute_category            ic_lots_mst.attribute_category%TYPE,
    odm_lot_number                ic_lots_mst.odm_lot_number%TYPE
  );
--
-- Ver_1.6 E_本稼動_15887 ADD End
  -- ===============================
  -- プロシージャおよびファンクション
  -- ===============================
--
  -- Message取得
  FUNCTION get_msg(
    iv_application   IN VARCHAR2,
    iv_name          IN VARCHAR2,
    iv_token_name1   IN VARCHAR2 DEFAULT NULL,
    iv_token_value1  IN VARCHAR2 DEFAULT NULL,
    iv_token_name2   IN VARCHAR2 DEFAULT NULL,
    iv_token_value2  IN VARCHAR2 DEFAULT NULL,
    iv_token_name3   IN VARCHAR2 DEFAULT NULL,
    iv_token_value3  IN VARCHAR2 DEFAULT NULL,
    iv_token_name4   IN VARCHAR2 DEFAULT NULL,
    iv_token_value4  IN VARCHAR2 DEFAULT NULL,
    iv_token_name5   IN VARCHAR2 DEFAULT NULL,
    iv_token_value5  IN VARCHAR2 DEFAULT NULL,
    iv_token_name6   IN VARCHAR2 DEFAULT NULL,
    iv_token_value6  IN VARCHAR2 DEFAULT NULL,
    iv_token_name7   IN VARCHAR2 DEFAULT NULL,
    iv_token_value7  IN VARCHAR2 DEFAULT NULL,
    iv_token_name8   IN VARCHAR2 DEFAULT NULL,
    iv_token_value8  IN VARCHAR2 DEFAULT NULL,
    iv_token_name9   IN VARCHAR2 DEFAULT NULL,
    iv_token_value9  IN VARCHAR2 DEFAULT NULL,
    iv_token_name10  IN VARCHAR2 DEFAULT NULL,
    iv_token_value10 IN VARCHAR2 DEFAULT NULL,
--  2008/10/29 v1.4 T.Yoshimoto Add Start 統合#251
    iv_token_name11  IN VARCHAR2 DEFAULT NULL,
    iv_token_value11 IN VARCHAR2 DEFAULT NULL
--  2008/10/29 v1.4 T.Yoshimoto Add End 統合#251
    )
    RETURN VARCHAR2;
--
  -- 担当者名取得
  FUNCTION get_user_name
    (
      in_user_id    IN FND_USER.USER_ID%TYPE -- ユーザID
    )
    RETURN VARCHAR2 ;                        -- 担当者名
--
  -- 担当部署名取得
  FUNCTION get_user_dept
    (
      in_user_id    IN FND_USER.USER_ID%TYPE -- ユーザID
    )
    RETURN VARCHAR2 ;                        -- 担当部署名
--
  -- テーブルロック関数
  FUNCTION get_tbl_lock(
    iv_schema_name IN VARCHAR2,         -- スキーマ名
    iv_table_name  IN VARCHAR2)         -- テーブル名
    RETURN BOOLEAN;                     -- TRUE:ロック成功,FALSE:ロック失敗
--
 -- テーブルデータ一括削除関数
  FUNCTION del_all_data(
    iv_schema_name IN VARCHAR2,         -- スキーマ名
    iv_table_name  IN VARCHAR2)         -- テーブル名
    RETURN BOOLEAN;                     -- TRUE:一括削除成功,FALSE:一括削除失敗
--
  -- OPM在庫会計期間CLOSE年月取得関数
  FUNCTION get_opminv_close_period RETURN VARCHAR2; -- CLSE年月YYYYMM
--
  -- カテゴリ取得関数
  FUNCTION get_category_desc(
    in_item_no      IN  VARCHAR2,     -- 品目
    iv_category_set IN  VARCHAR2)     -- カテゴリセットコード
    RETURN VARCHAR2;                  -- カテゴリ摘要
--
  -- 伊藤園相良工場情報取得プロシージャ
  PROCEDURE get_sagara_factory_info(
    ov_postal_code OUT NOCOPY VARCHAR2,     -- 郵便番号
    ov_address     OUT NOCOPY VARCHAR2,     -- 住所
    ov_tel_num     OUT NOCOPY VARCHAR2,     -- 電話番号
    ov_fax_num     OUT NOCOPY VARCHAR2,     -- FAX番号
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2);    -- ユーザー・エラー・メッセージ --# 固定 #
--
  -- カレンダコード取得関数
  FUNCTION get_calender_cd(
    iv_whse_code      IN  VARCHAR2 DEFAULT NULL,  -- 保管倉庫コード
    in_party_site_no  IN  VARCHAR2 DEFAULT NULL,  -- パーティサイト番号
    iv_leaf_drink     IN  VARCHAR2)               -- リーフドリンク区分
    RETURN VARCHAR2;
--
  -- 稼働日チェック関数
  FUNCTION check_oprtn_day(
    id_date         IN  DATE,      -- チェック対象日付
    iv_calender_cd  IN  VARCHAR2)  -- カレンダーコード
    RETURN NUMBER;
--
  -- 採番関数
  PROCEDURE get_seq_no(
    iv_seq_class  IN  VARCHAR2,     --   採番する番号を表す区分
    ov_seq_no     OUT NOCOPY VARCHAR2,     --   採番した固定長12桁の番号
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2);    --   ユーザー・エラー・メッセージ --# 固定 #
--
  -- 部署情報取得プロシージャ
  PROCEDURE get_dept_info(
    iv_dept_cd          IN  VARCHAR2,          -- 部署コード(事業所CD)
    id_appl_date        IN  DATE DEFAULT NULL, -- 基準日
    ov_postal_code      OUT NOCOPY VARCHAR2,          -- 郵便番号
    ov_address          OUT NOCOPY VARCHAR2,          -- 住所
    ov_tel_num          OUT NOCOPY VARCHAR2,          -- 電話番号
    ov_fax_num          OUT NOCOPY VARCHAR2,          -- FAX番号
    ov_dept_formal_name OUT NOCOPY VARCHAR2,          -- 部署正式名
    ov_errbuf           OUT NOCOPY VARCHAR2,          -- エラー・メッセージ           --# 固定 #
    ov_retcode          OUT NOCOPY VARCHAR2,          -- リターン・コード             --# 固定 #
    ov_errmsg           OUT NOCOPY VARCHAR2);         -- ユーザー・エラー・メッセージ --# 固定 #
--
  -- 支払条件文言取得関数
  FUNCTION get_term_of_payment(
    in_vendor_id   IN NUMBER,             -- 仕入先ID
    id_appl_date   IN DATE DEFAULT NULL)  -- 有効日付
    RETURN VARCHAR2;                      -- 支払条件文言
--
  -- パラメータチェック：日付形式（YYYYMM）
  FUNCTION check_param_date_yyyymm(
    iv_date_ym      IN VARCHAR2)          -- チェック対象日付
    RETURN NUMBER;                        -- 0:日付,1:エラー
--
  -- パラメータチェック：日付形式(YYYYMMDD HH24:MI:SS)
  FUNCTION check_param_date_yyyymmdd(
    iv_date_ymd      IN VARCHAR2)         -- チェック対象日付
    RETURN NUMBER;                        -- 0:日付,1:エラー
--
  -- 標準APIログ出力API
  PROCEDURE put_api_log(
    ov_errbuf   OUT NOCOPY VARCHAR2,          -- エラー・メッセージ           --# 固定 #
    ov_retcode  OUT NOCOPY VARCHAR2,          -- リターン・コード             --# 固定 #
    ov_errmsg   OUT NOCOPY VARCHAR2);          -- ユーザー・エラー・メッセージ --# 固定 #
--
  -- アウトバウンド処理情報取得関数
  PROCEDURE get_outbound_info(
    iv_wf_ope_div       IN  VARCHAR2,                 -- 処理区分
    iv_wf_class         IN  VARCHAR2,                 -- 対象
    iv_wf_notification  IN  VARCHAR2,                 -- 宛先
    or_outbound_rec     OUT NOCOPY outbound_rec,      -- ファイル情報
    ov_errbuf           OUT NOCOPY VARCHAR2,          -- エラー・メッセージ           --# 固定 #
    ov_retcode          OUT NOCOPY VARCHAR2,          -- リターン・コード             --# 固定 #
    ov_errmsg           OUT NOCOPY VARCHAR2);         -- ユーザー・エラー・メッセージ --# 固定 #
--
--  ファイル出力情報更新関数
  PROCEDURE upd_outbound_info(
    iv_wf_ope_div       IN  VARCHAR2,                 -- 処理区分
    iv_wf_class         IN  VARCHAR2,                 -- 対象
    iv_wf_notification  IN  VARCHAR2,                 -- 宛先
    id_last_update_date IN  DATE,                     -- ファイル最終更新日
    ov_errbuf           OUT NOCOPY VARCHAR2,          -- エラー・メッセージ           --# 固定 #
    ov_retcode          OUT NOCOPY VARCHAR2,          -- リターン・コード             --# 固定 #
    ov_errmsg           OUT NOCOPY VARCHAR2);         -- ユーザー・エラー・メッセージ --# 固定 #
--
--  ワークフロー起動関数
  PROCEDURE wf_start(
    iv_wf_ope_div       IN  VARCHAR2,                 -- 処理区分
    iv_wf_class         IN  VARCHAR2,                 -- 対象
    iv_wf_notification  IN  VARCHAR2,                 -- 宛先
    ov_errbuf           OUT NOCOPY VARCHAR2,          -- エラー・メッセージ           --# 固定 #
    ov_retcode          OUT NOCOPY VARCHAR2,          -- リターン・コード             --# 固定 #
    ov_errmsg           OUT NOCOPY VARCHAR2);         -- ユーザー・エラー・メッセージ --# 固定 #
--
  -- 総引当可能数算出API
  FUNCTION get_can_enc_total_qty(
    in_whse_id          IN NUMBER,                    -- OPM保管倉庫ID
    in_item_id          IN NUMBER,                    -- OPM品目ID
    in_lot_id           IN NUMBER DEFAULT NULL)       -- ロットID
    RETURN NUMBER;                                    -- 総引当可能数
--
  -- 有効日ベース引当可能数算出API
  FUNCTION get_can_enc_in_time_qty(
    in_whse_id          IN NUMBER,                    -- OPM保管倉庫ID
    in_item_id          IN NUMBER,                    -- OPM品目ID
    in_lot_id           IN NUMBER DEFAULT NULL,       -- ロットID
    in_active_date      IN DATE)                      -- 有効日
    RETURN NUMBER;                                    -- 引当可能数
--
  -- 手持在庫数量算出API
  FUNCTION get_stock_qty(
    in_whse_id          IN NUMBER,                    -- OPM保管倉庫ID
    in_item_id          IN NUMBER,                    -- OPM品目ID
    in_lot_id           IN NUMBER DEFAULT NULL)       -- ロットID
    RETURN NUMBER;                                    -- 手持在庫数量
--
  -- 引当可能数算出API
  FUNCTION get_can_enc_qty(
    in_whse_id          IN NUMBER,                    -- OPM保管倉庫ID
    in_item_id          IN NUMBER,                    -- OPM品目ID
    in_lot_id           IN NUMBER DEFAULT NULL,       -- ロットID
    in_active_date      IN DATE)                      -- 有効日
    RETURN NUMBER;                                    -- 引当可能数
--
  -- 入出庫換算関数(生産バッチ用)
  FUNCTION rcv_ship_conv_qty(
    iv_conv_type  IN VARCHAR2,          -- 変換方法(1:入出庫換算単位→第1単位,2:その逆)
    in_item_id    IN NUMBER,            -- OPM品目ID
    in_qty        IN NUMBER)            -- 変換対象の数量
    RETURN NUMBER;                      -- 変換結果の数量
--
  -- 担当部署CD取得
  FUNCTION get_user_dept_code
    (
      in_user_id    IN FND_USER.USER_ID%TYPE, -- ユーザID
      id_appl_date  IN DATE DEFAULT NULL      -- 基準日
    )
    RETURN VARCHAR2 ;                        -- 担当部署名
--
-- Ver_1.6 E_本稼動_15887 ADD Start
--  ロットマスタ履歴作成関数
  PROCEDURE create_lot_mst_history(
    ir_lot_data         IN  lot_rec,                  -- 更新前ロットマスタのデータ
    ov_errbuf           OUT NOCOPY VARCHAR2,          -- エラー・メッセージ           --# 固定 #
    ov_retcode          OUT NOCOPY VARCHAR2,          -- リターン・コード             --# 固定 #
    ov_errmsg           OUT NOCOPY VARCHAR2);         -- ユーザー・エラー・メッセージ --# 固定 #
--
-- Ver_1.6 E_本稼動_15887 ADD End
END xxcmn_common_pkg;
/
