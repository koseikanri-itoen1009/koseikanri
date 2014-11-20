CREATE OR REPLACE PACKAGE BODY xxwsh600001c

AS

/*****************************************************************************************

 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.

 *

 * Package Name     : xxwsh600001c(body)

 * Description      : 自動配車配送計画作成処理

 * MD.050           : 配車配送計画 T_MD050_BPO_600

 * MD.070           : 自動配車配送計画作成処理 T_MD070_BPO_60B

 * Version          : 1.22

 *

 * Program List

 * ----------------------------- ---------------------------------------------------------

 *  Name                          Description

 * ----------------------------- ---------------------------------------------------------

 *  del_table_purge               パージ処理(B-1)

 *  get_req_inst_info             依頼・指示情報抽出(B-3)

 *  ins_hub_mixed_info            拠点混載情報登録処理(B-4)

 *  chk_loading_efficiency        積載効率チェック処理(B-5)

 *  set_weight_capacity_add       合計重量/容積取得 加算処理(B-7)

 *  ins_intensive_carriers_tmp    集約中間テーブル出力処理(B-8)

 *  get_max_shipping_method       最大配送区分・重量容積区分取得処理(B-6)

 *  set_delivery_no               配送No設定処理

 *  set_small_sam_class           小口配送情報作成処理

 *  get_intensive_tmp             集約中間情報抽出処理(B-9)

 *  ins_xxwsh_carriers_schedule   配車配送計画アドオン出力(B-14)

 *  upd_req_inst_info             依頼・指示情報更新処理(B-15)

 *  submain                       メイン処理プロシージャ

 *  main                          コンカレント実行ファイル登録プロシージャ

 *

 * Change Record

 * ------------- ----- ---------------- -------------------------------------------------

 *  Date          Ver.  Editor           Description

 * ------------- ----- ---------------- -------------------------------------------------

 *  2008/03/11    1.0   Y.Kanami         新規作成

 *  2008/06/26    1.1  Oracle D.Sugahara ST障害 #297対応 *

 *  2008/07/02    1.2  Oracle M.Hokkanji ST障害 #321、#351対応 *

 *  2008/07/10    1.3  Oracle M.Hokkanji TE080指摘03対応、ヘッダ積載率再計算対応

 *  2008/07/14    1.4  Oracle 山根一浩   仕様変更No.95対応

 *  2008/08/04    1.5  Oracle M.Hokkanji 結合再テスト不具合対応(400TE080_159原因2)ST#513対応

 *  2008/08/06    1.6  Oracle M.Hokkanji ST不具合493対応

 *  2008/08/08    1.7  Oracle M.Hokkanji ST不具合510対応、内部変更173対応

 *  2008/09/05    1.8  Oracle A.Shiina   PT 6-1_27 指摘41-2 対応

 *  2008/10/01    1.9  Oracle H.Itou     PT 6-1_27 指摘18 対応

 *  2008/10/16    1.10 Oracle H.Itou     T_S_625,統合テスト指摘369

 *  2008/10/24    1.11 Oracle H.Itou     T_TE080_BPO_600指摘26

 *  2008/10/30    1.12 Oracle H.Itou     統合テスト指摘526

 *  2008/11/19    1.13 SCS    H.Itou     統合テスト指摘666

 *  2008/11/29    1.14 SCS    MIYATA     ロック対応 NO WAIT　を削除してWAITにする

 *  2008/12/02    1.15 SCS    H.Itou     本番障害#220対応

 *  2008/12/07    1.16 SCS    D.Sugahara 本番障害#524暫定対応

 *  2009/01/05    1.17 SCS    H.Itou     本番障害#879対応

 *  2009/01/08    1.18 SCS    H.Itou     本番障害#558,599対応

 *  2009/01/27    1.19 SCS    H.Itou     本番障害#1028対応

 *  2009/02/27    1.20 SCS    M.Hokkanji 本番障害#1228対応

 *  2009/04/17    1.21 SCS    H.Itou     本番障害#1398対応

 *  2009/04/20    1.22 SCS    H.Itou     本番障害#1398再対応

 *****************************************************************************************/

--

--#######################  固定グローバル定数宣言部 START   #######################

--

  gv_status_normal CONSTANT VARCHAR2(1) := '0';

  gv_status_warn   CONSTANT VARCHAR2(1) := '1';

  gv_status_error  CONSTANT VARCHAR2(1) := '2';

  gv_sts_cd_normal CONSTANT VARCHAR2(1) := 'C';

  gv_sts_cd_warn   CONSTANT VARCHAR2(1) := 'G';

  gv_sts_cd_error  CONSTANT VARCHAR2(1) := 'E';

  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ';

  gv_msg_cont      CONSTANT VARCHAR2(3) := '.';

  gv_msg_comma     CONSTANT VARCHAR2(3) := ',';

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

  lock_expt       EXCEPTION;  -- ロック取得例外

  no_data         EXCEPTION;  -- データ取得例外

  to_date_expt    EXCEPTION;  -- 日付変換エラー

  to_date_expt_m  EXCEPTION;  -- 日付変換エラーm

  to_date_expt_d  EXCEPTION;  -- 日付変換エラーd

  to_date_expt_y  EXCEPTION;  -- 日付変換エラーy

--

  PRAGMA EXCEPTION_INIT(lock_expt, -54);        -- ロック取得例外

  PRAGMA EXCEPTION_INIT(to_date_expt_m, -1843); -- 日付変換エラーm

  PRAGMA EXCEPTION_INIT(to_date_expt_d, -1847); -- 日付変換エラーd

  PRAGMA EXCEPTION_INIT(to_date_expt_y, -1861); -- 日付変換エラーy

--

  -- ===============================

  -- ユーザー定義グローバル定数

  -- ===============================

  gv_pkg_name           CONSTANT VARCHAR2(100)  :=  'xxwsh600001c'; -- パッケージ名

  gv_xxwsh              CONSTANT VARCHAR2(100)  :=  'XXWSH';

                                                      -- モジュール名称略：出荷・引当/配車

  -- メッセージ

  gv_msg_xxwsh_13151    CONSTANT VARCHAR2(100)  :=  'APP-XXWSH-13151';

                                                      -- メッセージ：必須パラメータ未入力メッセージ

  gv_msg_xxwsh_11113    CONSTANT VARCHAR2(100)  :=  'APP-XXWSH-11113';

                                                      -- メッセージ：日付逆転エラーメッセージ

  gv_msg_xxwsh_11052    CONSTANT VARCHAR2(100)  :=  'APP-XXWSH-11052';

                                                      -- メッセージ：ロック取得エラー

  gv_msg_xxwsh_11804    CONSTANT VARCHAR2(100)  :=  'APP-XXWSH-11804';

                                                      -- メッセージ：対象データ無し

  gv_msg_xxwsh_11802    CONSTANT VARCHAR2(100)  :=  'APP-XXWSH-11802';

                                                      -- メッセージ：最大配送区分取得エラー

  gv_msg_xxwsh_11803    CONSTANT VARCHAR2(100)  :=  'APP-XXWSH-11803';

                                                      -- メッセージ：積載オーバーメッセージ

  gv_msg_xxwsh_11805    CONSTANT VARCHAR2(100)  :=  'APP-XXWSH-11805';

                                                      -- メッセージ：配送No取得エラー

  gv_msg_xxwsh_11806    CONSTANT VARCHAR2(100)  :=  'APP-XXWSH-11806';

                                                      -- メッセージ：入力パラメータ(見出し)

  gv_msg_xxwsh_11807    CONSTANT VARCHAR2(100)  :=  'APP-XXWSH-11807';

                                                      -- メッセージ：出荷依頼件数

  gv_msg_xxwsh_11808    CONSTANT VARCHAR2(100)  :=  'APP-XXWSH-11808';

                                                      -- メッセージ：移動指示件数

  gv_msg_xxwsh_11809    CONSTANT VARCHAR2(100)  :=  'APP-XXWSH-11809';

                                                      -- メッセージ：入力パラメータ書式エラー

  gv_msg_xxwsh_11810    CONSTANT VARCHAR2(100)  :=  'APP-XXWSH-11810';

                                                      -- メッセージ：共通関数エラー

  gv_msg_xxwsh_11813    CONSTANT VARCHAR2(100)  :=  'APP-XXWSH-11813';

                                                      -- メッセージ：運賃形態取得エラー

-- Ver1.3 M.Hokkanji Start

  gv_msg_xxwsh_11814    CONSTANT VARCHAR2(100)  :=  'APP-XXWSH-11814';

                                                      -- メッセージ：配送区分取得エラー

-- Ver1.3 M.Hokkanji End

--

  -- トークン

  gv_tkn_item           CONSTANT VARCHAR2(100)  :=  'ITEM';       -- トークン：ITEM

  gv_tkn_table          CONSTANT VARCHAR2(100)  :=  'TABLE';      -- トークン：TABLE

  gv_tkn_key            CONSTANT VARCHAR2(100)  :=  'KEY';        -- トークン：KEY

  gv_tkn_from           CONSTANT VARCHAR2(100)  :=  'FROM';       -- トークン：FROM

  gv_tkn_to             CONSTANT VARCHAR2(100)  :=  'TO';         -- トークン：TO

  gv_tkn_codekbn1       CONSTANT VARCHAR2(100)  :=  'CODEKBN1';   -- トークン：CODEKBN1

  gv_tkn_codekbn2       CONSTANT VARCHAR2(100)  :=  'CODEKBN2';   -- トークン：CODEKBN2

  gv_tkn_req_no         CONSTANT VARCHAR2(100)  :=  'REQ_NO';     -- トークン：REQ_NO

  gv_tkn_errmsg         CONSTANT VARCHAR2(100)  :=  'ERRMSG';     -- トークン：ERRMSG

  gv_tkn_count          CONSTANT VARCHAR2(100)  :=  'COUNT';      -- トークン：COUNT

  gv_tkn_parm_name      CONSTANT VARCHAR2(100)  :=  'PARM_NAME';  -- トークン：PARM_NAME

  gv_tkn_delivry_no     CONSTANT VARCHAR2(100)  :=  'DELIVERY_NO';-- トークン：DELIVERY_NO

  gv_tkn_branch         CONSTANT VARCHAR2(100)  :=  'BRANCH';     -- トークン：BRANCH

  gv_fnc_name           CONSTANT VARCHAR2(100)  :=  'FNC_NAME';   -- トークン：FNC_NAME

-- Ver1.3 M.Hokkanji Start

  gv_tkn_ship_method    CONSTANT VARCHAR2(100)  := 'SHIP_METHOD'; -- トークン：SHIP_METHOD

  gv_tkn_source_no      CONSTANT VARCHAR2(100)  := 'SOURCE_NO';   -- トークン：SOURCE_NO

-- Ver1.3 M.Hokkanji END

--

  gv_prod_cls_leaf      CONSTANT VARCHAR2(1)    :=  '1';          -- 商品区分：リーフ

  gv_prod_cls_drink     CONSTANT VARCHAR2(1)    :=  '2';          -- 商品区分：ドリンク

  gv_ship_type_ship     CONSTANT VARCHAR2(30)   :=  '1';          -- 処理種別：出荷

  gv_ship_type_move     CONSTANT VARCHAR2(30)   :=  '3';          -- 処理種別：移動

  gv_weight             CONSTANT VARCHAR2(30)   :=  '1';          -- 重量容積区分：重量

  gv_capacity           CONSTANT VARCHAR2(30)   :=  '2';          -- 重量容積区分：容積

  gv_cdkbn_storage      CONSTANT VARCHAR2(30)   :=  '4';          -- コード区分：倉庫

  gv_cdkbn_ship_to      CONSTANT VARCHAR2(30)   :=  '9';          -- コード区分：配送先

  gv_on                 CONSTANT VARCHAR2(1)    :=  '1';          -- ON

  gv_off                CONSTANT VARCHAR2(1)    :=  '0';          -- OFF

  gv_mixed_class_mixed  CONSTANT VARCHAR2(1)    :=  '2';          -- 混載種別：混載

  gv_mixed_class_int    CONSTANT VARCHAR2(1)    :=  '1';          -- 混載種別：集約

  gv_frt_chrg_type_set  CONSTANT VARCHAR2(1)    :=  '1';          -- 運賃形態：設定振替

  gv_frt_chrg_type_act  CONSTANT VARCHAR2(1)    :=  '2';          -- 運賃形態：実費振替

  gv_error              CONSTANT NUMBER         :=  1;            -- 関数戻り値：エラー

  gv_normal             CONSTANT NUMBER         :=  0;            -- 関数戻り値：正常

--

  -- 2008/07/14 Add

  gv_all_z4             CONSTANT VARCHAR2(4)    :=  'ZZZZ';

  gv_all_z9             CONSTANT VARCHAR2(9)    :=  'ZZZZZZZZZ';

--

  -- ===============================

  -- ユーザー定義グローバル型

  -- ===============================

  -- 依頼/指示情報取得用レコード型

  TYPE ship_move_rtype IS RECORD(

      deliver_no            xxwsh_order_headers_all.delivery_no%TYPE            -- 配送No

    , pre_deliver_no        xxwsh_order_headers_all.prev_delivery_no%TYPE       -- 前回配送No

    , req_mov_no            xxwsh_order_headers_all.request_no%TYPE             -- 依頼No/移動No

    , mixed_no              xxwsh_order_headers_all.mixed_no%TYPE               -- 混載元No

    , carrier_code          xxwsh_order_headers_all.freight_carrier_code%TYPE   -- 運送業者

    , carrier_id            xxwsh_order_headers_all.career_id%TYPE              -- 運送業者ID

    , ship_from             xxwsh_order_headers_all.deliver_from%TYPE           -- 出荷元保管場所

    , ship_from_id          xxwsh_order_headers_all.deliver_from_id%TYPE        -- 出荷元ID

    , ship_to               xxwsh_order_headers_all.deliver_to%TYPE             -- 出荷先

    , ship_to_id            xxwsh_order_headers_all.deliver_to_id%TYPE          -- 出荷先ID

    , ship_method_code      xxwsh_order_headers_all.shipping_method_code%TYPE   -- 配送区分

    , small_div             xxcmn_lookup_values2_v.attribute6%TYPE              -- 小口区分

    , ship_date             xxwsh_order_headers_all.schedule_ship_date%TYPE     -- 出庫日

    , arrival_date          xxwsh_order_headers_all.schedule_arrival_date%TYPE  -- 着荷日

    , based_weight          xxwsh_order_headers_all.based_weight%TYPE           -- 基本重量

    , based_capacity        xxwsh_order_headers_all.based_capacity%TYPE         -- 基本容積

    , sum_weight            xxwsh_order_headers_all.sum_weight%TYPE             -- 積載重量合計

    , sum_capacity          xxwsh_order_headers_all.sum_capacity%TYPE           -- 積載容積合計

    , weight_capacity_cls   xxwsh_order_headers_all.weight_capacity_class%TYPE  -- 重量容積区分

    , sum_pallet_weight     xxwsh_order_headers_all.sum_pallet_weight%TYPE      -- 合計パレット重量

    , item_class            xxwsh_order_headers_all.prod_class%TYPE             -- 商品区分

    , business_type_id    xxwsh_oe_transaction_types2_v.transaction_type_id%TYPE

                                                                                -- 取引タイプ

    , reserve_order         xxcmn_parties.reserve_order%TYPE                    -- 引当順

    , sales_branch          xxwsh_order_headers_all.head_sales_branch%TYPE      -- 管轄拠点

    );

--

  -- 依頼/指示情報取得用テーブル型

  TYPE ship_move_ttype IS TABLE OF ship_move_rtype INDEX BY BINARY_INTEGER;

--

  -- ソート用中間テーブルレコード型

  TYPE grp_sum_add_rtype IS RECORD(

      transaction_id      xxwsh_carriers_sort_tmp.transaction_id%TYPE           -- トランザクションID

    , tran_type           xxwsh_carriers_sort_tmp.transaction_type%TYPE         -- 処理種別

    , req_mov_no          xxwsh_carriers_sort_tmp.request_no%TYPE               -- 依頼No/移動No

    , mixed_no            xxwsh_carriers_sort_tmp.mixed_no%TYPE                 -- 混載元No

    , ship_from           xxwsh_carriers_sort_tmp.deliver_from%TYPE             -- 出荷元保管場所

    , ship_from_id        xxwsh_carriers_sort_tmp.deliver_from_id%TYPE          -- 出荷元ID

    , ship_to             xxwsh_carriers_sort_tmp.deliver_to%TYPE               -- 出荷先

    , ship_to_id          xxwsh_carriers_sort_tmp.deliver_to_id%TYPE            -- 出荷先ID

    , ship_method_code    xxwsh_carriers_sort_tmp.shipping_method_code%TYPE     -- 配送区分

    , ship_date           xxwsh_carriers_sort_tmp.schedule_ship_date%TYPE       -- 出庫日

    , arrival_date        xxwsh_carriers_sort_tmp.schedule_arrival_date%TYPE    -- 着荷日

    , order_type_id       xxwsh_carriers_sort_tmp.order_type_id%TYPE            -- 取引タイプ

    , carrier_code        xxwsh_carriers_sort_tmp.freight_carrier_code%TYPE     -- 運送業者

    , carrier_id          xxwsh_carriers_sort_tmp.career_id%TYPE                -- 運送業者ID

    , based_weight        xxwsh_carriers_sort_tmp.based_weight%TYPE             -- 基本重量

    , based_capacity      xxwsh_carriers_sort_tmp.based_capacity%TYPE           -- 基本容積

    , sum_weight          xxwsh_carriers_sort_tmp.sum_weight%TYPE               -- 積載重量合計

    , sum_capacity        xxwsh_carriers_sort_tmp.sum_capacity%TYPE             -- 積載容積合計

    , sum_pallet_weight   xxwsh_carriers_sort_tmp.sum_pallet_weight%TYPE        -- 合計パレット重量

    , max_shipping_method  xxwsh_carriers_sort_tmp.max_shipping_method_code%TYPE -- 最大配送区分

    , weight_capacity_cls xxwsh_carriers_sort_tmp.weight_capacity_class%TYPE    -- 重量容積区分

    , reserve_order       xxwsh_carriers_sort_tmp.reserve_order%TYPE            -- 引当順

    , head_sales_branch   xxwsh_carriers_sort_tmp.head_sales_branch%TYPE        -- 管轄拠点

    , finish_sum_flag     VARCHAR2(1)                                           -- 集約済フラグ

    );

--

  --

  TYPE pre_saved_flg_ttype IS

    TABLE OF xxwsh_carriers_sort_tmp.pre_saved_flg%TYPE INDEX BY BINARY_INTEGER;

                                                                          -- 拠点混載登録済フラグ

  TYPE finish_sum_flag_ttype IS TABLE OF VARCHAR2(1) INDEX BY BINARY_INTEGER;

                                                                          -- 集約済フラグ

--

  -- 加算処理用テーブル型

  TYPE grp_sum_add_ttype IS TABLE OF grp_sum_add_rtype INDEX BY BINARY_INTEGER;

--

  -- 自動配車集約中間テーブル用レコード

  TYPE intensive_carriers_tmp_rtype IS RECORD(

      intensive_no              xxwsh_intensive_carriers_tmp.intensive_no%TYPE  -- 集約No

    , transaction_type          xxwsh_intensive_carriers_tmp.transaction_type%TYPE

                                                                                -- 処理種別（配車）

    , intensive_source_no       xxwsh_intensive_carriers_tmp.intensive_source_no%TYPE

                                                                                -- 集約元No

    , deliver_from              xxwsh_intensive_carriers_tmp.deliver_from%TYPE  -- 配送元

    , deliver_from_id           xxwsh_intensive_carriers_tmp.deliver_from_id%TYPE

                                                                                -- 配送元ID

    , deliver_to                xxwsh_intensive_carriers_tmp.deliver_to%TYPE    -- 配送先

    , deliver_to_id             xxwsh_intensive_carriers_tmp.deliver_to_id%TYPE -- 配送先ID

    , schedule_ship_date        xxwsh_intensive_carriers_tmp.schedule_ship_date%TYPE

                                                                                -- 出庫予定日

    , schedule_arrival_date     xxwsh_intensive_carriers_tmp.schedule_arrival_date%TYPE

                                                                                -- 着荷予定日

    , transaction_type_name     xxwsh_intensive_carriers_tmp.transaction_type_name%TYPE

                                                                                -- 出庫形態

    , freight_carrier_code      xxwsh_intensive_carriers_tmp.freight_carrier_code%TYPE

                                                                                -- 運送業者

    , carrier_id                xxwsh_intensive_carriers_tmp.carrier_id%TYPE    -- 運送業者ID

    , head_sales_branch         xxwsh_intensive_carriers_tmp.head_sales_branch%TYPE

                                                                                -- 管轄拠点

    , reserve_order             xxwsh_intensive_carriers_tmp.reserve_order%TYPE -- 引当順

    , intensive_sum_weight      xxwsh_intensive_carriers_tmp.intensive_sum_weight%TYPE

                                                                                -- 集約合計重量

    , intensive_sum_capacity    xxwsh_intensive_carriers_tmp.intensive_sum_capacity%TYPE

                                                                                -- 集約合計容積

    , max_shipping_method_code  xxwsh_intensive_carriers_tmp.max_shipping_method_code%TYPE

                                                                                -- 最大配送区分

    , weight_capacity_class     xxwsh_intensive_carriers_tmp.weight_capacity_class%TYPE

                                                                                -- 重量容積区分

    , max_weight                xxwsh_intensive_carriers_tmp.max_weight%TYPE    -- 最大積載重量

    , max_capacity              xxwsh_intensive_carriers_tmp.max_capacity%TYPE  -- 最大積載容積

    , finish_sum_flag           VARCHAR2(1)                                     -- 集約済フラグ

    );

--

  -- 自動配車集約中間テーブル用テーブル型

  TYPE int_carr_tmp_ttype IS TABLE OF intensive_carriers_tmp_rtype INDEX BY BINARY_INTEGER;

--

  -- 配送No振り直し用レコード

  TYPE reset_delivery_no_rtype IS RECORD(

      int_no            xxwsh_mixed_carriers_tmp.intensive_no%TYPE      -- 集約No

    , req_no            xxwsh_intensive_carrier_ln_tmp.request_no%TYPE  -- 依頼No/移動No

    , delivery_no       xxwsh_mixed_carriers_tmp.delivery_no%TYPE       -- 配送No

    , prev_delivery_no  xxwsh_carriers_sort_tmp.prev_delivery_no%TYPE   -- 前回配送No

-- Ver1.2 M.Hokkanji Start

    , use_delivery_no   xxwsh_carriers_sort_tmp.delivery_no%TYPE        -- 現配送No

-- Ver1.2 M.Hokkanji End

  );

--

  -- 配送No振り直し用PL/SQL表型

  TYPE reset_delivery_no_ttype IS TABLE OF reset_delivery_no_rtype INDEX BY BINARY_INTEGER;

--

  -- ソートテーブル登録用

  TYPE transaction_id_ttype   IS

    TABLE OF xxwsh_carriers_sort_tmp.transaction_id%TYPE INDEX BY BINARY_INTEGER;

                                                                            -- トランザクションID

  TYPE deliver_no_ttype           IS

    TABLE OF xxwsh_carriers_sort_tmp.delivery_no%TYPE INDEX BY BINARY_INTEGER;

                                                                            -- 配送No

  TYPE pre_deliver_no_ttype       IS

    TABLE OF xxwsh_carriers_sort_tmp.prev_delivery_no%TYPE INDEX BY BINARY_INTEGER;

                                                                            -- 前回配送No

  TYPE req_mov_no_ttype           IS

    TABLE OF xxwsh_carriers_sort_tmp.request_no%TYPE INDEX BY BINARY_INTEGER;

                                                                            -- 依頼No/移動No

  TYPE mixed_no_ttype             IS

    TABLE OF xxwsh_carriers_sort_tmp.mixed_no%TYPE INDEX BY BINARY_INTEGER;

                                                                            -- 混載元No

  TYPE carrier_code_ttype         IS

    TABLE OF xxwsh_carriers_sort_tmp.freight_carrier_code%TYPE INDEX BY BINARY_INTEGER;

                                                                            -- 運送業者

  TYPE carrier_id_ttype           IS

    TABLE OF xxwsh_carriers_sort_tmp.career_id%TYPE INDEX BY BINARY_INTEGER;

                                                                            -- 運送業者ID

  TYPE ship_from_ttype            IS

    TABLE OF xxwsh_carriers_sort_tmp.deliver_from%TYPE INDEX BY BINARY_INTEGER;

                                                                            -- 出荷元保管場所

  TYPE ship_to_ttype              IS

    TABLE OF xxwsh_carriers_sort_tmp.deliver_to%TYPE INDEX BY BINARY_INTEGER;

                                                                            -- 出荷先

  TYPE ship_method_code_ttype     IS

    TABLE OF xxwsh_carriers_sort_tmp.shipping_method_code%TYPE INDEX BY BINARY_INTEGER;

                                                                            -- 配送区分

  TYPE small_div_ttype            IS

    TABLE OF xxwsh_carriers_sort_tmp.small_sum_class%TYPE INDEX BY BINARY_INTEGER;

                                                                            -- 小口区分

  TYPE ship_date_ttype            IS

    TABLE OF xxwsh_carriers_sort_tmp.schedule_ship_date%TYPE INDEX BY BINARY_INTEGER;

                                                                            -- 出庫日

  TYPE arrival_date_ttype         IS

    TABLE OF xxwsh_carriers_sort_tmp.schedule_arrival_date%TYPE INDEX BY BINARY_INTEGER;

                                                                            -- 着荷日

  TYPE sum_weight_ttype           IS

    TABLE OF xxwsh_carriers_sort_tmp.sum_weight%TYPE INDEX BY BINARY_INTEGER;

                                                                            -- 積載重量合計

  TYPE sum_capacity_ttype         IS

    TABLE OF xxwsh_carriers_sort_tmp.sum_capacity%TYPE INDEX BY BINARY_INTEGER;

                                                                            -- 積載容積合計

  TYPE weight_capacity_cls_ttype  IS

    TABLE OF xxwsh_carriers_sort_tmp.weight_capacity_class%TYPE INDEX BY BINARY_INTEGER;

                                                                            -- 重量容積区分

  TYPE sum_pallet_weight_ttype    IS

    TABLE OF xxwsh_carriers_sort_tmp.sum_pallet_weight%TYPE INDEX BY BINARY_INTEGER;

                                                                            -- 合計パレット重量

  TYPE item_class_ttype           IS

    TABLE OF xxwsh_carriers_sort_tmp.prod_class%TYPE INDEX BY BINARY_INTEGER;

                                                                            -- 商品区分

  TYPE business_type_ttype        IS

    TABLE OF xxwsh_carriers_sort_tmp.order_type_id%TYPE INDEX BY BINARY_INTEGER;

                                                                            -- 取引タイプ

  TYPE reserve_order_ttype        IS

    TABLE OF xxwsh_carriers_sort_tmp.reserve_order%TYPE INDEX BY BINARY_INTEGER;

                                                                            -- 引当順

  TYPE max_shipping_method_ttype   IS

    TABLE OF xxwsh_carriers_sort_tmp.max_shipping_method_code%TYPE INDEX BY BINARY_INTEGER;

                                                                            -- 最大配送区分

  TYPE head_sales_branch_ttype    IS

    TABLE OF xxwsh_carriers_sort_tmp.head_sales_branch%TYPE INDEX BY BINARY_INTEGER;

                                                                            -- 管轄拠点

  TYPE pre_saved_flag_ttype       IS

    TABLE OF xxwsh_carriers_sort_tmp.pre_saved_flg%TYPE INDEX BY BINARY_INTEGER;

                                                                            -- 拠点混載登録済

--

  -- 自動配車集約中間テーブル登録用

  TYPE intensive_no_ttype     IS

    TABLE OF xxwsh_intensive_carriers_tmp.intensive_no%TYPE INDEX BY BINARY_INTEGER;

                                                                            -- 集約No

  TYPE transaction_type_ttype IS

    TABLE OF xxwsh_intensive_carriers_tmp.transaction_type%TYPE INDEX BY BINARY_INTEGER;

                                                                            -- 処理種別

  TYPE int_source_no_ttype    IS

    TABLE OF xxwsh_intensive_carriers_tmp.intensive_source_no%TYPE INDEX BY BINARY_INTEGER;

                                                                            -- 集約元No

  TYPE deliver_from_ttype     IS

    TABLE OF xxwsh_intensive_carriers_tmp.deliver_from%TYPE INDEX BY BINARY_INTEGER;

                                                                            -- 配送元

  TYPE deliver_from_id_ttype  IS

    TABLE OF xxwsh_intensive_carriers_tmp.deliver_from_id%TYPE INDEX BY BINARY_INTEGER;

                                                                            -- 配送元ID

  TYPE deliver_to_ttype       IS

    TABLE OF xxwsh_intensive_carriers_tmp.deliver_to%TYPE INDEX BY BINARY_INTEGER;

                                                                            -- 配送先

  TYPE deliver_to_id_ttype    IS

    TABLE OF xxwsh_intensive_carriers_tmp.deliver_to_id%TYPE INDEX BY BINARY_INTEGER;

                                                                            -- 配送先ID

  TYPE sche_ship_date_ttype   IS

    TABLE OF xxwsh_intensive_carriers_tmp.schedule_ship_date%TYPE INDEX BY BINARY_INTEGER;

                                                                            -- 出庫予定日

  TYPE sche_arvl_date_ttype   IS

    TABLE OF xxwsh_intensive_carriers_tmp.schedule_arrival_date%TYPE INDEX BY BINARY_INTEGER;

                                                                            -- 着荷予定日

  TYPE tran_type_name_ttype   IS

    TABLE OF xxwsh_intensive_carriers_tmp.transaction_type_name%TYPE INDEX BY BINARY_INTEGER;

                                                                            -- 出庫形態

  TYPE freight_carry_cd_ttype IS

    TABLE OF xxwsh_intensive_carriers_tmp.freight_carrier_code%TYPE INDEX BY BINARY_INTEGER;

                                                                            -- 運送業者

  TYPE int_sum_weight_ttype   IS

    TABLE OF xxwsh_intensive_carriers_tmp.intensive_sum_weight%TYPE INDEX BY BINARY_INTEGER;

                                                                            -- 集約合計重量

  TYPE int_sum_capa_ttype     IS

    TABLE OF xxwsh_intensive_carriers_tmp.intensive_sum_capacity%TYPE INDEX BY BINARY_INTEGER;

                                                                            -- 集約合計容積

  TYPE max_ship_cd_ttype      IS

    TABLE OF xxwsh_intensive_carriers_tmp.max_shipping_method_code%TYPE INDEX BY BINARY_INTEGER;

                                                                            -- 最大配送区分

  TYPE weight_capa_cls_ttype  IS

    TABLE OF xxwsh_intensive_carriers_tmp.weight_capacity_class%TYPE INDEX BY BINARY_INTEGER;

                                                                            -- 重量容積区分

  TYPE max_weight_ttype       IS

    TABLE OF xxwsh_intensive_carriers_tmp.max_weight%TYPE INDEX BY BINARY_INTEGER;

                                                                            -- 最大積載重量

  TYPE max_capacity_ttype     IS

    TABLE OF xxwsh_intensive_carriers_tmp.max_capacity%TYPE INDEX BY BINARY_INTEGER;

                                                                            -- 最大積載容積

  TYPE based_weight_ttype     IS

    TABLE OF xxwsh_intensive_carriers_tmp.based_weight%TYPE INDEX BY BINARY_INTEGER;

                                                                            -- 基本重量

  TYPE based_capa_ttype       IS

    TABLE OF xxwsh_intensive_carriers_tmp.based_capacity%TYPE INDEX BY BINARY_INTEGER;

                                                                            -- 基本容積

  TYPE ship_to_id_ttype       IS

    TABLE OF xxwsh_intensive_carriers_tmp.deliver_to_id%TYPE INDEX BY BINARY_INTEGER;

                                                                            -- 出荷先ID

  TYPE ship_from_id_ttype     IS

    TABLE OF xxwsh_intensive_carriers_tmp.deliver_from_id%TYPE INDEX BY BINARY_INTEGER;

                                                                            -- 出荷元ID

--

  -- 自動配車集約中間明細テーブル登録用

  TYPE request_no_ttype IS

    TABLE OF xxwsh_intensive_carrier_ln_tmp.request_no%TYPE INDEX BY BINARY_INTEGER;

                                                                            -- 依頼No

--

  -- 自動配車混載中間テーブル登録用

  TYPE delivery_no_ttype IS

    TABLE OF xxwsh_mixed_carriers_tmp.delivery_no%TYPE INDEX BY BINARY_INTEGER;

                                                                            -- 配送No

  TYPE default_line_number_ttype IS

    TABLE OF xxwsh_mixed_carriers_tmp.default_line_number%TYPE INDEX BY BINARY_INTEGER;

                                                                            -- 基準明細No

  TYPE fixed_ship_code_ttype IS

    TABLE OF xxwsh_mixed_carriers_tmp.fixed_shipping_method_code%TYPE INDEX BY BINARY_INTEGER;

                                                                            -- 修正配送区分

  TYPE mixed_class_ttype IS

    TABLE OF xxwsh_mixed_carriers_tmp.mixed_class%TYPE INDEX BY BINARY_INTEGER;

                                                                            -- 混載種別

  TYPE mixed_total_weight_ttype IS

    TABLE OF xxwsh_mixed_carriers_tmp.mixed_total_weight%TYPE INDEX BY BINARY_INTEGER;

                                                                            -- 混載合計重量

  TYPE mixed_total_capacity_ttype IS

    TABLE OF xxwsh_mixed_carriers_tmp.mixed_total_capacity%TYPE INDEX BY BINARY_INTEGER;

                                                                            -- 混載合計容積

  TYPE case_quantity_ttype IS

    TABLE OF xxwsh_order_lines_all.case_quantity%TYPE INDEX BY BINARY_INTEGER;

                                                                            -- ケース数

--

  -- 配車配送計画アドオン登録用

  TYPE delivery_to_cd_cls_ttype IS

    TABLE OF xxwsh_carriers_schedule.deliver_to_code_class%TYPE INDEX BY BINARY_INTEGER;

                                                                            -- 配送先コード区分

  TYPE loading_weight_ttype IS

    TABLE OF xxwsh_carriers_schedule.loading_efficiency_weight%TYPE INDEX BY BINARY_INTEGER;

                                                                            -- 重量積載効率

  TYPE loading_capacity_ttype IS

    TABLE OF xxwsh_carriers_schedule.loading_efficiency_capacity%TYPE INDEX BY BINARY_INTEGER;

                                                                            -- 容積積載効率

  TYPE based_capacity_ttype IS

    TABLE OF xxwsh_carriers_schedule.based_capacity%TYPE INDEX BY BINARY_INTEGER;

                                                                            -- 基本容積

  TYPE freight_charge_type_ttype IS

    TABLE OF xxwsh_carriers_schedule.freight_charge_type%TYPE INDEX BY BINARY_INTEGER;

                                                                            -- 運賃形態

-- Ver1.3 M.Hokkanji Start

  TYPE mixed_ratio_ttype is

    TABLE OF xxwsh_order_headers_all.mixed_ratio%TYPE INDEX BY BINARY_INTEGER;

                                                                            -- 混載率

-- Ver1.3 M.Hokkanji End

--

  -- ===============================

  -- ユーザー定義グローバル変数

  -- ===============================

  -- パラメータ

  gv_prod_class         VARCHAR2(1);          -- 商品区分

  gv_ship_biz_type      VARCHAR2(1);          -- 処理種別

  gd_date_from          DATE;                 -- 出庫日From

  gv_parameters         VARCHAR2(5000);       -- エラー出力用

--

  -- 出力用件数

  gn_ship_cnt           NUMBER;               -- 出荷依頼件数

  gn_move_cnt           NUMBER;               -- 移動指示件数

--

  -- 依頼/指示情報取得用PL/SQL表

  gt_ship_data_tab    ship_move_ttype;        -- 出荷依頼用

  gt_move_data_tab    ship_move_ttype;        -- 移動指示用

--

  -- ソート用テーブル登録用PL/SQL表

  -- 出荷依頼用

  gt_deliver_no_s           deliver_no_ttype;           -- 配送No

  gt_pre_deliver_no_s       pre_deliver_no_ttype;       -- 前回配送No

  gt_req_mov_no_s           req_mov_no_ttype;           -- 依頼No/移動No

  gt_mixed_no_s             mixed_no_ttype;             -- 混載元No

  gt_carrier_code_s         carrier_code_ttype;         -- 運送業者

  gt_carrier_id_s           carrier_id_ttype;           -- 運送業者ID

  gt_ship_from_s            ship_from_ttype;            -- 出荷元保管場所

  gt_ship_to_s              ship_to_ttype;              -- 出荷先

  gt_ship_method_code_s     ship_method_code_ttype;     -- 配送区分

  gt_small_div_s            small_div_ttype;            -- 小口区分

  gt_ship_date_s            ship_date_ttype;            -- 出庫日

  gt_arrival_date_s         arrival_date_ttype;         -- 着荷日

  gt_sum_weight_s           sum_weight_ttype;           -- 積載重量合計

  gt_sum_capacity_s         sum_capacity_ttype;         -- 積載容積合計

  gt_weight_capacity_cls_s  weight_capacity_cls_ttype;  -- 重量容積区分

  gt_sum_pallet_weight_s    sum_pallet_weight_ttype;    -- 合計パレット重量

  gt_item_class_s           item_class_ttype;           -- 商品区分

  gt_business_type_s        business_type_ttype;        -- 取引タイプ

  gt_reserve_order_s        reserve_order_ttype;        -- 引当順

  gt_max_shipping_method_s   max_shipping_method_ttype; -- 最大配送区分

  gt_head_sales_branch_s    head_sales_branch_ttype;    -- 管轄拠点

  gt_ship_from_id_s         ship_from_id_ttype;         -- 出荷元ID

  gt_ship_to_id_s           ship_to_id_ttype;           -- 出荷先ID

  gt_based_weight_s         based_weight_ttype;         -- 基本重量

  gt_based_capacity_s       based_capa_ttype;           -- 基本容積

  gt_pre_saved_flag_s       pre_saved_flag_ttype;       -- 拠点混載登録済フラグ

--

  -- 移動指示用

  gt_deliver_no_m           deliver_no_ttype;           -- 配送No

  gt_pre_deliver_no_m       pre_deliver_no_ttype;       -- 前回配送No

  gt_req_mov_no_m           req_mov_no_ttype;           -- 依頼No/移動No

  gt_mixed_no_m             mixed_no_ttype;             -- 混載元No

  gt_carrier_code_m         carrier_code_ttype;         -- 運送業者

  gt_carrier_id_m           carrier_id_ttype;           -- 運送業者ID

  gt_ship_from_m            ship_from_ttype;            -- 出荷元保管場所

  gt_ship_to_m              ship_to_ttype;              -- 出荷先

  gt_ship_method_code_m     ship_method_code_ttype;     -- 配送区分

  gt_small_div_m            small_div_ttype;            -- 小口区分

  gt_ship_date_m            ship_date_ttype;            -- 出庫日

  gt_arrival_date_m         arrival_date_ttype;         -- 着荷日

  gt_sum_weight_m           sum_weight_ttype;           -- 積載重量合計

  gt_sum_capacity_m         sum_capacity_ttype;         -- 積載容積合計

  gt_weight_capacity_cls_m  weight_capacity_cls_ttype;  -- 重量容積区分

  gt_sum_pallet_weight_m    sum_pallet_weight_ttype;    -- 合計パレット重量

  gt_item_class_m           item_class_ttype;           -- 商品区分

  gt_business_type_m        business_type_ttype;        -- 取引タイプ

  gt_reserve_order_m        reserve_order_ttype;        -- 引当順

  gt_max_shipping_method_m   max_shipping_method_ttype; -- 最大配送区分

  gt_head_sales_branch_m    head_sales_branch_ttype;    -- 管轄拠点

  gt_ship_from_id_m         ship_from_id_ttype;         -- 出荷元ID

  gt_ship_to_id_m           ship_to_id_ttype;           -- 出荷先ID

  gt_based_weight_m         based_weight_ttype;         -- 基本重量

  gt_based_capacity_m       based_capa_ttype;           -- 基本容積

  gt_pre_saved_flag_m       pre_saved_flag_ttype;       -- 拠点混載登録済フラグ

--

  -- 同一グループ加算処理用PL/SQL表

  gt_grp_sum_add_tab_ship   grp_sum_add_ttype;          -- 出荷依頼用

  gt_grp_sum_add_tab_move   grp_sum_add_ttype;          -- 移動指示用

  gt_pre_saved_flg_tab      pre_saved_flg_ttype;        -- 拠点混載登録済フラグ

  gt_finish_sum_flag_tab    finish_sum_flag_ttype;      -- 集約済フラグ

--

  -- 自動配車集約中間テーブル登録用PL/SQL表

  gt_int_no_tab         intensive_no_ttype;             -- 集約No

  gt_tran_type_tab      transaction_type_ttype;         -- 処理種別

  gt_int_source_tab     int_source_no_ttype;            -- 集約元No

  gt_deli_from_tab      deliver_from_ttype;             -- 配送元

  gt_deli_from_id_tab   deliver_from_id_ttype;          -- 配送元ID

  gt_deli_to_tab        deliver_to_ttype;               -- 配送先

  gt_deli_to_id_tab     deliver_to_id_ttype;            -- 配送先ID

  gt_ship_date_tab      sche_ship_date_ttype;           -- 出庫予定日

  gt_arvl_date_tab      sche_arvl_date_ttype;           -- 着荷予定日

  gt_tran_type_nm_tab   tran_type_name_ttype;           -- 出庫形態

  gt_carrier_code_tab   freight_carry_cd_ttype;         -- 運送業者

  gt_carrier_id_tab     carrier_id_ttype;               -- 運送業者ID

  gt_sum_weight_tab     int_sum_weight_ttype;           -- 集約合計重量

  gt_sum_capa_tab       int_sum_capa_ttype;             -- 集約合計容積

  gt_max_ship_cd_tab    max_ship_cd_ttype;              -- 最大配送区分

  gt_weight_capa_tab    weight_capa_cls_ttype;          -- 重量容積区分

  gt_max_weight_tab     max_weight_ttype;               -- 最大積載重量

  gt_max_capa_tab       max_capacity_ttype;             -- 最大積載容積

  gt_base_weight_tab    based_weight_ttype;             -- 基本重量

  gt_base_capa_tab      based_capa_ttype;               -- 基本容積

  gt_reserve_order_tab  reserve_order_ttype;            -- 引当順

  gt_head_sales_tab     head_sales_branch_ttype;        -- 管轄拠点

--

  -- 自動配車集約中間明細テーブル登録用PL/SQL表

  gt_int_no_lines_tab intensive_no_ttype;               -- 集約No

  gt_request_no_tab   request_no_ttype;                 -- 依頼No

--

  -- 自動配車混載中間テーブル登録用PL/SQL表

  gt_intensive_no_tab           intensive_no_ttype;         -- 集約No

  gt_delivery_no_tab            delivery_no_ttype;          -- 配送No

  gt_default_line_number_tab    default_line_number_ttype;  -- 基準明細No

  gt_fixed_ship_code_tab        fixed_ship_code_ttype;      -- 修正配送区分

  gt_mixed_class_tab            mixed_class_ttype;          -- 混載種別

  gt_mixed_total_weight_tab     mixed_total_weight_ttype;   -- 混載合計重量

  gt_mixed_total_capacity_tab   mixed_total_capacity_ttype; -- 混載合計容積

  gt_mixed_no_tab               mixed_no_ttype;             -- 混載元No

--

  -- エラーキー

  gv_err_key  VARCHAR2(2000);

  -- デバッグ用

  gb_debug    BOOLEAN DEFAULT FALSE;    --デバッグログ出力用スイッチ

--

  /**********************************************************************************

   * Procedure Name   : set_debug_switch

   * Description      : デバッグ用ログ出力用切り替えスイッチ取得処理

   ***********************************************************************************/

  PROCEDURE set_debug_switch 

  IS

    -- ===============================

    -- 固定ローカル定数

    -- ===============================

    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_debug_switch'; -- プログラム名

--

--#####################  固定ローカル変数宣言部 START   ########################

--

--###########################  固定部 END   ####################################

--

    -- ===============================

    -- ユーザー宣言部

    -- ===============================

    -- *** ローカル定数 ***

    cv_debug_switch_prof_name CONSTANT VARCHAR2(30) := 'XXWSH_60B_DEBUG_SWITCH';  -- ﾃﾞﾊﾞｯｸﾞﾌﾗｸﾞ

    cv_debug_switch_ON        CONSTANT VARCHAR2(1)  := '1';   --デバッグ出力する

    cv_debug_switch_OFF       CONSTANT VARCHAR2(1)  := '0';   --デバッグ出力しない

    -- *** ローカル変数 ***

    -- *** ローカル・カーソル ***

    -- *** ローカル・レコード ***

--

  BEGIN

--

    --デバッグ切り替えプロファイル取得

    IF (FND_PROFILE.VALUE(cv_debug_switch_prof_name) = cv_debug_switch_ON ) THEN

      gb_debug := TRUE;

    END IF;

  EXCEPTION

    -- *** OTHERS例外ハンドラ ***

    WHEN OTHERS THEN

      gb_debug := FALSE;

--

--#####################################  固定部 END   ##########################################

--

  END set_debug_switch;

--

  /**********************************************************************************

   * Procedure Name   : debug_log

   * Description      : デバッグ用ログ出力処理

   ***********************************************************************************/

  PROCEDURE debug_log(in_which in number,       -- 出力先：FND_FILE.LOG or FND_FILE.OUTPUT

                      iv_msg   in varchar2 )    -- メッセージ

  IS

    -- ===============================

    -- 固定ローカル定数

    -- ===============================

    cv_prg_name   CONSTANT VARCHAR2(100) := 'debug_log'; -- プログラム名

--

--#####################  固定ローカル変数宣言部 START   ########################

--

--###########################  固定部 END   ####################################

--

    -- ===============================

    -- ユーザー宣言部

    -- ===============================

    -- *** ローカル定数 ***

    -- *** ローカル変数 ***

    -- *** ローカル・カーソル ***

    -- *** ローカル・レコード ***

--

  BEGIN

--

    --デバッグONなら出力

    IF (gb_debug) THEN

      FND_FILE.PUT_LINE(in_which, iv_msg);

    END IF;

  EXCEPTION

    -- *** OTHERS例外ハンドラ ***

    WHEN OTHERS THEN

      NULL ;

--

--#####################################  固定部 END   ##########################################

--

  END debug_log;

--

  /**********************************************************************************

   * Procedure Name   : del_table_purge

   * Description      : パージ処理(B-1)

   ***********************************************************************************/

  PROCEDURE del_table_purge(

    ov_errbuf   OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #

    ov_retcode  OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #

    ov_errmsg   OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #

  IS

    -- ===============================

    -- 固定ローカル定数

    -- ===============================

    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_table_purge'; -- プログラム名

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

    cv_tab_carriers_tmp       CONSTANT VARCHAR2(30) := 'xxwsh_intensive_carriers_tmp';

                                                            -- 自動配車集約中間テーブル

    cv_tab_carrier_ln_tmp     CONSTANT VARCHAR2(30) := 'xxwsh_intensive_carrier_ln_tmp';

                                                            -- 自動配車集約中間明細テーブル

    cv_tab_mixed_carriers_tmp CONSTANT VARCHAR2(30) := 'xxwsh_mixed_carriers_tmp';

                                                            -- 自動配車混載中間テーブル

    cv_tab_carriers_sort_tmp  CONSTANT VARCHAR2(30) := 'xxwsh_carriers_sort_tmp';

                                                            -- ソート用中間テーブル

--

    -- *** ローカル変数 ***

    lb_retcode    BOOLEAN;    -- 共通関数戻り値

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

debug_log(FND_FILE.LOG,'【パージ処理(B-1)】');

    -- ===============================

    -- 中間テーブルTRANCATE処理

    -- ===============================

    lb_retcode := xxcmn_common_pkg.del_all_data(gv_xxwsh, cv_tab_carriers_tmp);

                                                          -- 自動配車集約中間テーブル

    IF (lb_retcode = FALSE) THEN

      RAISE global_api_expt;

    END IF;

--

    lb_retcode := xxcmn_common_pkg.del_all_data(gv_xxwsh, cv_tab_carrier_ln_tmp);

                                                          -- 自動配車集約中間明細テーブル

    IF (lb_retcode = FALSE) THEN

      RAISE global_api_expt;

    END IF;

--

    lb_retcode := xxcmn_common_pkg.del_all_data(gv_xxwsh, cv_tab_mixed_carriers_tmp);

                                                          -- 自動配車混載中間テーブル

    IF (lb_retcode = FALSE) THEN

      RAISE global_api_expt;

    END IF;

--

    lb_retcode := xxcmn_common_pkg.del_all_data(gv_xxwsh, cv_tab_carriers_sort_tmp);

                                                          -- ソート用中間テーブル

    IF (lb_retcode = FALSE) THEN

      RAISE global_api_expt;

    END IF;

--

  EXCEPTION

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

  END del_table_purge;

--

  /**********************************************************************************

   * Procedure Name   : get_req_inst_info

   * Description      : 依頼・指示情報抽出(B-3)

   ***********************************************************************************/

  PROCEDURE get_req_inst_info(

      iv_prod_class           IN  VARCHAR2        --  1.商品区分

    , iv_shipping_biz_type    IN  VARCHAR2        --  2.処理種別

    , iv_block_1              IN  VARCHAR2        --  3.ブロック１

    , iv_block_2              IN  VARCHAR2        --  4.ブロック２

    , iv_block_3              IN  VARCHAR2        --  5.ブロック３

    , iv_storage_code         IN  VARCHAR2        --  6.出庫元

    , iv_transaction_type_id  IN  NUMBER          --  7.出庫形態ID

    , id_date_from            IN  DATE            --  8.出庫日From

    , id_date_to              IN  DATE            --  9.出庫日To

    , iv_forwarder            IN  NUMBER          -- 10.運送業者ID

-- 2009/01/27 H.Itou Add Start 本番障害#1028対応

    , iv_instruction_dept     IN  VARCHAR2        -- 11.指示部署

-- 2009/01/27 H.Itou Add End

    , ov_errbuf               OUT NOCOPY VARCHAR2 -- エラー・メッセージ           --# 固定 #

    , ov_retcode              OUT NOCOPY VARCHAR2 -- リターン・コード             --# 固定 #

    , ov_errmsg               OUT NOCOPY VARCHAR2 -- ユーザー・エラー・メッセージ --# 固定 #

    )

  IS

    -- ===============================

    -- 固定ローカル定数

    -- ===============================

    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_req_inst_info'; -- プログラム名

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

    cv_close            CONSTANT VARCHAR2(30) := '03';                -- ステータス：締め済み

    cv_non_notice       CONSTANT VARCHAR2(30) := '10';                -- 通知ステータス：未通知

    cv_re_notice        CONSTANT VARCHAR2(30) := '20';                -- 通知ステータス：再通知要

    cv_an_object        CONSTANT VARCHAR2(30) := '1';                 -- 自動配車対象区分:対象

    cv_cat_order        CONSTANT VARCHAR2(30) := 'ORDER';             -- 受注カテゴリ：受注

    cv_ship_shikyu_cls  CONSTANT VARCHAR2(30) := '1';                 -- 出荷支給区分：出荷依頼

    cv_ship_method      CONSTANT VARCHAR2(30) := 'XXCMN_SHIP_METHOD'; -- 配送区分

    cv_yes              CONSTANT VARCHAR2(30) := 'Y';                 -- YES

    cv_sts_fin_req      CONSTANT VARCHAR2(30) := '02';                -- ステータス：依頼済

    cv_sts_adjust       CONSTANT VARCHAR2(30) := '03';                -- ステータス：調整中

    cv_tab_name         CONSTANT VARCHAR2(30) := '依頼／指示データ';  -- テーブル名

    cv_move_type_1      CONSTANT VARCHAR2(30) := '1';                 -- 積送あり

--

    -- *** ローカル変数 ***

    TYPE cur_type IS REF CURSOR;

    exec_cur cur_type;

--

    -- 出荷依頼用

    lv_sql_0          VARCHAR2(5000);     -- SQL文字列用(固定部)

    lv_sql_1          VARCHAR2(5000);     -- SQL文字列用(変動部)

    lv_sql_2          VARCHAR2(5000);     -- SQL文字列用(固定部)

    lv_sql_3          VARCHAR2(5000);     -- SQL文字列用(変動部)

    lv_sql_4          VARCHAR2(5000);     -- SQL文字列用(固定部)

    lv_sql_buff_ship  VARCHAR2(10000);    -- 実行用SQL

    -- 移動指示用

    lv_sql_m0         VARCHAR2(5000);     -- SQL文字列用(固定部)

    lv_sql_m1         VARCHAR2(5000);     -- SQL文字列用(変動部)

    lv_sql_m2         VARCHAR2(5000);     -- SQL文字列用(固定部)

    lv_sql_m3         VARCHAR2(5000);     -- SQL文字列用(変動部)

    lv_sql_m4         VARCHAR2(5000);     -- SQL文字列用(固定部)

    lv_sql_buff_move  VARCHAR2(10000);    -- 実行用SQL

    -- 出荷/移動用

    lv_sql_ship_move  VARCHAR2(10000);    -- 実行用SQL

--

    -- 最大配送区分取得用

    return_cd                   NUMBER;   -- 戻り値

    lv_max_ship_methods_s       xxcmn_ship_methods.ship_method%TYPE;            -- 最大配送区分

    ln_drink_deadweight_s       xxcmn_ship_methods.drink_deadweight%TYPE;       -- ドリンク積載重量

    ln_leaf_deadweight_s        xxcmn_ship_methods.leaf_deadweight%TYPE;        -- リーフ積載重量

    ln_drink_loading_capacity_s xxcmn_ship_methods.drink_loading_capacity%TYPE; -- ドリンク積載容積

    ln_leaf_loading_capacity_s  xxcmn_ship_methods.leaf_loading_capacity%TYPE;  -- リーフ積載容積

    ln_palette_max_qty_s        xxcmn_ship_methods.palette_max_qty%TYPE;        -- パレット最大枚数

    lv_max_ship_methods_m       xxcmn_ship_methods.ship_method%TYPE;            -- 最大配送区分

    ln_drink_deadweight_m       xxcmn_ship_methods.drink_deadweight%TYPE;       -- ドリンク積載重量

    ln_leaf_deadweight_m        xxcmn_ship_methods.leaf_deadweight%TYPE;        -- リーフ積載重量

    ln_drink_loading_capacity_m xxcmn_ship_methods.drink_loading_capacity%TYPE; -- ドリンク積載容積

    ln_leaf_loading_capacity_m  xxcmn_ship_methods.leaf_loading_capacity%TYPE;  -- リーフ積載容積

    ln_palette_max_qty_m        xxcmn_ship_methods.palette_max_qty%TYPE;        -- パレット最大枚数

--

    -- *** ローカル・カーソル ***

    TYPE cursor_type IS REF CURSOR; -- カーソル変数

--

    get_ship_cur cursor_type;

    get_move_cur cursor_type;

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

debug_log(FND_FILE.LOG,'【依頼・指示情報抽出(B-3)】');

debug_log(FND_FILE.LOG,'処理種別：'|| iv_shipping_biz_type);

    -- ===============================

    -- パラメータKEY設定

    -- ===============================

    gv_parameters:= iv_prod_class                                   -- 商品区分

                    || gv_msg_comma ||

                    iv_shipping_biz_type                            -- 処理種別

                    || gv_msg_comma ||

                    iv_block_1                                      -- ブロック１

                    || gv_msg_comma ||

                    iv_block_2                                      -- ブロック２

                    || gv_msg_comma ||

                    iv_block_3                                      -- ブロック３

                    || gv_msg_comma ||

                    iv_storage_code                                 -- 出庫元

                    || gv_msg_comma ||

                    iv_transaction_type_id                          -- 出庫形態

                    || gv_msg_comma ||

                    TO_CHAR(id_date_from, 'YYYY/MM/DD HH24:MI:SS')  -- 出庫日From

                    || gv_msg_comma ||

                    TO_CHAR(id_date_to, 'YYYY/MM/DD HH24:MI:SS')    -- 出庫日To

                    || gv_msg_comma ||

                    TO_CHAR(iv_forwarder)                           -- 運送業者

-- 2009/01/27 H.Itou Add Start 本番障害#1028対応

                    || gv_msg_comma ||

                    iv_instruction_dept;                            -- 指示部署

-- 2009/01/27 H.Itou Add End

--

    -- ===============================

    -- SQL文字列作成(出荷依頼)

    -- ===============================

    -- 固定部

    lv_sql_0 := 'SELECT xoha.delivery_no deliver_no';                           -- 配送No

    lv_sql_0 := lv_sql_0 || ', xoha.prev_delivery_no pre_deliver_no';           -- 前回配送No

    lv_sql_0 := lv_sql_0 || ', xoha.request_no req_mov_no';                     -- 依頼No

    lv_sql_0 := lv_sql_0 || ', xoha.mixed_no mixed_no';                         -- 混載元No

    lv_sql_0 := lv_sql_0 || ', xoha.freight_carrier_code carrier_code';         -- 運送業者

    lv_sql_0 := lv_sql_0 || ', xoha.career_id carrier_id';                      -- 運送業者ID

    lv_sql_0 := lv_sql_0 || ', xoha.deliver_from ship_from';                    -- 出荷元保管場所

    lv_sql_0 := lv_sql_0 || ', xoha.deliver_from_id ship_from_id';              -- 出荷元ID

    lv_sql_0 := lv_sql_0 || ', xoha.deliver_to ship_to';                        -- 出荷先

    lv_sql_0 := lv_sql_0 || ', xoha.deliver_to_id ship_to_id';                  -- 出荷先ID

    lv_sql_0 := lv_sql_0 || ', xoha.shipping_method_code ship_method_code';     -- 配送区分

    lv_sql_0 := lv_sql_0 || ', xlv.attribute6 small_div';                       -- 小口区分

    lv_sql_0 := lv_sql_0 || ', xoha.schedule_ship_date ship_date';              -- 出庫日

    lv_sql_0 := lv_sql_0 || ', xoha.schedule_arrival_date arrival_date';        -- 着荷日

    lv_sql_0 := lv_sql_0 || ', xoha.based_weight based_weight';                 -- 基本重量

    lv_sql_0 := lv_sql_0 || ', xoha.based_capacity based_capacity';             -- 基本容積

    lv_sql_0 := lv_sql_0 || ', xoha.sum_weight sum_weight';                     -- 積載重量合計

    lv_sql_0 := lv_sql_0 || ', xoha.sum_capacity sum_capacity';                 -- 積載容積合計

    lv_sql_0 := lv_sql_0 || ', xoha.weight_capacity_class weight_capacity_cls'; -- 重量容積区分

    lv_sql_0 := lv_sql_0 || ', xoha.sum_pallet_weight sum_pallet_weight';       -- 合計パレット重量

    lv_sql_0 := lv_sql_0 || ', xoha.prod_class  item_class';                    -- 商品区分

    lv_sql_0 := lv_sql_0 || ', xotv.transaction_type_id business_type_id';      -- 取引タイプ

    lv_sql_0 := lv_sql_0 || ', xcav.reserve_order reserve_order';               -- 引当順

-- 2009/04/17 H.Itou Mod Start 本番障害#1398

--    lv_sql_0 := lv_sql_0 || ', xoha.head_sales_branch sales_branch';            -- 管轄拠点

    lv_sql_0 := lv_sql_0 || ', xcasv.base_code sales_branch';                   -- 管轄拠点

-- 2009/04/17 H.Itou Mod End

    lv_sql_0 := lv_sql_0 || ' FROM xxwsh_order_headers_all xoha';   -- 受注ヘッダアドオン

    lv_sql_0 := lv_sql_0 || ', xxwsh_carriers_schedule xcs';        -- 配車配送計画アドオン

    lv_sql_0 := lv_sql_0 || ', xxcmn_item_locations2_v xilv';       -- OPM保管場所情報VIEW2

    lv_sql_0 := lv_sql_0 || ', xxcmn_cust_acct_sites2_v xcasv';     -- 顧客サイト情報VIEW2

    lv_sql_0 := lv_sql_0 || ', xxcmn_cust_accounts2_v xcav';        -- 顧客情報VIEW2

    lv_sql_0 := lv_sql_0 || ', xxwsh_oe_transaction_types2_v xotv'; -- 受注タイプ情報VIEW2

    lv_sql_0 := lv_sql_0 || ', xxcmn_lookup_values2_v xlv';         -- クイックコード情報VIEW2

    lv_sql_0 := lv_sql_0 || ' WHERE xoha.order_type_id = xotv.transaction_type_id';

                                                                                -- 受注タイプID

    lv_sql_0 := lv_sql_0 || ' AND xoha.req_status = '''|| cv_close ||'''';      -- ステータス

    lv_sql_0 := lv_sql_0 || ' AND xoha.notif_status IN ('''|| cv_non_notice||''',

                                    '''|| cv_re_notice ||''')';                 -- 通知ステータス

    lv_sql_0 := lv_sql_0 || ' AND xoha.delivery_no = xcs.delivery_no(+)';       -- 配送NO

--    lv_sql_0 := lv_sql_0 || ' AND (xoha.delivery_no IS NULL';                   -- 配送NO

--    lv_sql_0 := lv_sql_0 || '  OR xoha.delivery_no = xcs.delivery_no)';            -- 配送NO

    lv_sql_0 := lv_sql_0 || ' AND (xcs.auto_process_type IS NULL';

    lv_sql_0 := lv_sql_0 || '  OR xcs.auto_process_type = '''|| cv_an_object ||''')';

                                                                                -- 自動配車対象区分

    lv_sql_0 := lv_sql_0 || ' AND xoha.freight_charge_class = '''|| cv_an_object ||'''';

                                                                                -- 運賃区分

    lv_sql_0 := lv_sql_0 || ' AND xoha.prod_class = '''|| iv_prod_class ||'''';

                                                                                -- 商品区分

    lv_sql_0 := lv_sql_0 || ' AND xoha.deliver_from_id = xilv.inventory_location_id';

                                                                                -- 出荷元ID

    lv_sql_0 := lv_sql_0 || ' AND xilv.disable_date IS NULL';                   -- 無効日

--

    -- 変動部(物流ブロック)

      lv_sql_1 := ' AND ((xilv.distribution_block IN (                           -- 物流ブロック

                          '''|| iv_block_1 ||''',                                 -- ブロック１

                          '''|| iv_block_2 ||''',                                 -- ブロック２

                          '''|| iv_block_3 ||''')';                               -- ブロック３

      lv_sql_1 := lv_sql_1 || ' OR xoha.deliver_from = '''|| iv_storage_code ||''')'; -- 出庫元

      lv_sql_1 := lv_sql_1 || ' OR  (('''|| iv_block_1 ||''' IS NULL) AND ('''|| iv_block_2 ||''' IS NULL) AND ('''|| iv_block_3 ||''' IS NULL) AND ('''|| iv_storage_code ||''' IS NULL)))';

--

    -- 変動部(出庫形態)

    IF (iv_transaction_type_id IS NOT NULL) THEN

      lv_sql_1 := lv_sql_1 ||' AND xotv.transaction_type_id = '|| iv_transaction_type_id ||' ';

    END IF;

--

    -- 固定部(出荷予定日)

    lv_sql_2 := ' AND xoha.schedule_ship_date >= TO_DATE(

                      '''|| TO_CHAR(id_date_from, 'YYYY/MM/DD') ||''',''YYYY/MM/DD'')';    -- 出庫日From

    lv_sql_2 := lv_sql_2 || ' AND xoha.schedule_ship_date <= TO_DATE(

                      '''|| TO_CHAR(id_date_to, 'YYYY/MM/DD') ||''',''YYYY/MM/DD'')';      -- 出庫日To

--

    -- 変動部(運送業者ID)

    IF (iv_forwarder IS NOT NULL) THEN

      lv_sql_3 := ' AND xoha.career_id = '|| iv_forwarder ||'';

    END IF;

--

-- 2009/01/27 H.Itou Add Start 本番障害#1028対応

    -- 変動部(指示部署)

    IF (iv_instruction_dept IS NOT NULL) THEN

      lv_sql_3 := lv_sql_3 || ' AND xoha.instruction_dept = '''|| iv_instruction_dept ||'''';

    END IF;

-- 2009/01/27 H.Itou Add End

--

    -- 固定部

    lv_sql_4 := ' AND xotv.order_category_code = '''|| cv_cat_order ||'''';     -- 受注カテゴリ

    lv_sql_4 := lv_sql_4 || ' AND xotv.shipping_shikyu_class =

                                      '''|| cv_ship_shikyu_cls ||'''';          -- 出荷支給区分

    lv_sql_4 := lv_sql_4 || ' AND xotv.start_date_active <= TO_DATE(

                              '''|| TO_CHAR(id_date_from,'YYYY/MM/DD')  ||''',''YYYY/MM/DD'')';

                                                                -- 受注タイプ情報VIEW2：適用開始日

    lv_sql_4 := lv_sql_4 || ' AND (xotv.end_date_active IS NULL';

    lv_sql_4 := lv_sql_4 || ' OR xotv.end_date_active >= TO_DATE(

                              '''|| TO_CHAR(id_date_from, 'YYYY/MM/DD') ||''',''YYYY/MM/DD''))';

                                                                -- 受注タイプ情報VIEW2：適用終了日

    lv_sql_4 := lv_sql_4 || ' AND xoha.shipping_method_code = xlv.lookup_code'; -- 配送区分

    lv_sql_4 := lv_sql_4 || ' AND xlv.lookup_type = '''|| cv_ship_method ||'''';

    lv_sql_4 := lv_sql_4 || ' AND (xlv.start_date_active IS NULL';

    lv_sql_4 := lv_sql_4 || ' OR xlv.start_date_active <= TO_DATE(

                              '''|| TO_CHAR(id_date_from,'YYYY/MM/DD')  ||''',''YYYY/MM/DD''))';

                                                                -- クイックコード：適用開始日

    lv_sql_4 := lv_sql_4 || ' AND (xlv.end_date_active IS NULL';

    lv_sql_4 := lv_sql_4 || ' OR xlv.end_date_active >= TO_DATE(

                              '''|| TO_CHAR(id_date_from, 'YYYY/MM/DD') ||''',''YYYY/MM/DD''))';

                                                                -- クイックコード：適用終了日

    lv_sql_4 := lv_sql_4 || ' AND xlv.enabled_flag = '''|| cv_yes ||'''';

                                                                -- クイックコード：有効フラグ

-- 2009/04/17 H.Itou Del Start 本番障害#1398 顧客付け替え時にIDが最新でないので出荷先コードで結合し、顧客マスタを参照するため、受注ヘッダと結合しない

--    lv_sql_4 := lv_sql_4 || ' AND xoha.head_sales_branch = xcav.party_number';   -- 管轄拠点

-- 2009/04/17 H.Itou Del End

    lv_sql_4 := lv_sql_4 || ' AND xcasv.start_date_active <= TO_DATE(

                              '''|| TO_CHAR(id_date_from, 'YYYY/MM/DD') ||''',''YYYY/MM/DD'')';

                                                                -- 顧客サイト情報VIEW2：適用開始日

    lv_sql_4 := lv_sql_4 || ' AND xcasv.end_date_active >= TO_DATE(

                              '''|| TO_CHAR(id_date_from, 'YYYY/MM/DD') ||''',''YYYY/MM/DD'')';

                                                                -- 顧客サイト情報VIEW2：適用終了日

-- 2009/04/17 H.Itou Mod Start 本番障害#1398 顧客付け替え時にIDが最新でないので出荷先コードで結合

--    lv_sql_4 := lv_sql_4 || ' AND xcasv.party_site_id = xoha.deliver_to_id';      -- 出荷先ID

    lv_sql_4 := lv_sql_4 || ' AND xcasv.party_site_number = xoha.deliver_to';      -- 出荷先コード

    lv_sql_4 := lv_sql_4 || ' AND xcasv.party_site_status =''A''';                 -- サイトステータス：有効

-- 2009/04/17 H.Itou Mod End

-- 2009/04/17 H.Itou Mod Start 本番障害#1398 顧客付け替え時にIDが最新でないので出荷先コードで結合し、顧客マスタを参照

--    lv_sql_4 := lv_sql_4 || ' AND xcav.party_id = xcav.party_id';                  -- パーティID

-- 2009/04/20 H.Itou Mod Start 本番障害#1398(再対応) 拠点の情報を取得したいので、拠点コードで結合

--    lv_sql_4 := lv_sql_4 || ' AND xcav.party_id = xcasv.party_id';                  -- パーティID

    lv_sql_4 := lv_sql_4 || ' AND xcav.party_number = xcasv.base_code';            -- 拠点コード

-- 2009/04/20 H.Itou Mod End

    lv_sql_4 := lv_sql_4 || ' AND xcav.party_status       = ''A'' ';

    lv_sql_4 := lv_sql_4 || ' AND xcav.account_status     = ''A'' ';

-- 2009/04/17 H.Itou Mod End

    lv_sql_4 := lv_sql_4 || ' AND xcav.start_date_active <= TO_DATE(

                              '''|| TO_CHAR(id_date_from, 'YYYY/MM/DD') ||''',''YYYY/MM/DD'')';

                                                                -- 顧客情報VIEW2：適用開始日

    lv_sql_4 := lv_sql_4 || ' AND xcav.end_date_active >= TO_DATE(

                              '''|| TO_CHAR(id_date_from, 'YYYY/MM/DD') ||''',''YYYY/MM/DD'')';

                                                                -- 顧客情報VIEW2：適用終了日

    lv_sql_4 := lv_sql_4 || ' AND xoha.latest_external_flag = '''|| cv_yes ||'''';

                                                                                -- 最新フラグ

-- Ver1.14 MIYATA Start

    lv_sql_4 := lv_sql_4 || ' FOR UPDATE OF xoha.delivery_no ';

-- Ver1.14 MIYATA End

--

    -- SQL文連結(出荷依頼)

    lv_sql_buff_ship := lv_sql_0 || lv_sql_1 || lv_sql_2 || lv_sql_3 || lv_sql_4;

--

debug_log(FND_FILE.LOG,'出荷依頼SQL: '||lv_sql_buff_ship);

--

    -- ===============================

    -- SQL文字列作成(移動指示)

    -- ===============================

    -- 固定部

    lv_sql_m0 := 'SELECT  xmrh.delivery_no deliver_no';                           -- 配送No

    lv_sql_m0 := lv_sql_m0 || ', xmrh.prev_delivery_no pre_deliver_no';           -- 前回配送No

    lv_sql_m0 := lv_sql_m0 || ', xmrh.mov_num req_mov_no';                        -- 移動番号

    lv_sql_m0 := lv_sql_m0 || ', NULL mixed_no';                                  -- 混載元No

    lv_sql_m0 := lv_sql_m0 || ', xmrh.freight_carrier_code carrier_code';         -- 運送業者

    lv_sql_m0 := lv_sql_m0 || ', xmrh.career_id carrier_id';                      -- 運送業者ID

    lv_sql_m0 := lv_sql_m0 || ', xmrh.shipped_locat_code ship_from';              -- 出荷元保管場所

    lv_sql_m0 := lv_sql_m0 || ', xmrh.shipped_locat_id ship_from_id';             -- 出荷元ID

    lv_sql_m0 := lv_sql_m0 || ', xmrh.ship_to_locat_code ship_to';                -- 出荷先

    lv_sql_m0 := lv_sql_m0 || ', xmrh.ship_to_locat_id ship_to_id';               -- 出荷先ID

    lv_sql_m0 := lv_sql_m0 || ', xmrh.shipping_method_code ship_method_code';     -- 配送区分

    lv_sql_m0 := lv_sql_m0 || ', xlv.attribute6 small_div';                       -- 小口区分

    lv_sql_m0 := lv_sql_m0 || ', xmrh.schedule_ship_date ship_date';              -- 出庫日

    lv_sql_m0 := lv_sql_m0 || ', xmrh.schedule_arrival_date arrival_date';        -- 着荷日

    lv_sql_m0 := lv_sql_m0 || ', xmrh.based_weight based_weight';                 -- 基本重量

    lv_sql_m0 := lv_sql_m0 || ', xmrh.based_capacity based_capacity';             -- 基本容積

    lv_sql_m0 := lv_sql_m0 || ', xmrh.sum_weight sum_weight';                     -- 積載重量合計

    lv_sql_m0 := lv_sql_m0 || ', xmrh.sum_capacity sum_capacity';                 -- 積載容積合計

    lv_sql_m0 := lv_sql_m0 || ', xmrh.weight_capacity_class weight_capacity_cls'; -- 重量容積区分

    lv_sql_m0 := lv_sql_m0 || ', xmrh.sum_pallet_weight sum_pallet_weight';       -- 合計パレット重量

    lv_sql_m0 := lv_sql_m0 || ', xmrh.item_class  item_class';                    -- 商品区分

-- 2009/01/08 H.Itou Mod Start 本番障害#599

--    lv_sql_m0 := lv_sql_m0 || ', xmrh.mov_type business_type_id';                 -- 取引タイプ

    lv_sql_m0 := lv_sql_m0 || ', NULL business_type_id';                          -- 取引タイプ

-- 2009/01/08 H.Itou Mod End

    lv_sql_m0 := lv_sql_m0 || ', NULL reserve_order';                             -- 引当順

    lv_sql_m0 := lv_sql_m0 || ', NULL sales_branch';                              -- 管轄拠点

    lv_sql_m0 := lv_sql_m0 || ' FROM xxinv_mov_req_instr_headers xmrh';   -- 移動依頼/指示ヘッダ

    lv_sql_m0 := lv_sql_m0 || ', xxwsh_carriers_schedule xcs';            -- 配車配送計画アドオン

    lv_sql_m0 := lv_sql_m0 || ', xxcmn_item_locations2_v xilv';           -- OPM保管場所情報VIEW2

    lv_sql_m0 := lv_sql_m0 || ', xxcmn_lookup_values2_v xlv';             -- クイックコード情報VIEW2

    lv_sql_m0 := lv_sql_m0 || ' WHERE xmrh.status IN ('''|| cv_sts_fin_req ||''',';

    lv_sql_m0 := lv_sql_m0 || ' '''|| cv_sts_adjust||''')';                     -- ステータス

    lv_sql_m0 := lv_sql_m0 || ' AND xmrh.notif_status IN ('''|| cv_non_notice||''',';

    lv_sql_m0 := lv_sql_m0 || ' '''|| cv_re_notice ||''')';                     -- 通知ステータス

    lv_sql_m0 := lv_sql_m0 || ' AND xmrh.mov_type = '''|| cv_move_type_1 ||'''';  -- 移動タイプ

    lv_sql_m0 := lv_sql_m0 || ' AND xmrh.delivery_no = xcs.delivery_no(+)';     -- 配送NO

--    lv_sql_m0 := lv_sql_m0 || ' AND (xmrh.delivery_no = NULL';     -- 配送NO

--    lv_sql_m0 := lv_sql_m0 || '  OR xmrh.delivery_no = xcs.delivery_no)';     -- 配送NO

    lv_sql_m0 := lv_sql_m0 || ' AND (xcs.auto_process_type IS NULL';

    lv_sql_m0 := lv_sql_m0 || '  OR xcs.auto_process_type = '''|| cv_an_object ||''')';

                                                                                -- 自動配車対象区分

    lv_sql_m0 := lv_sql_m0 || ' AND xmrh.freight_charge_class = '''|| cv_an_object ||'''';

                                                                                -- 運賃区分

    lv_sql_m0 := lv_sql_m0 || ' AND xmrh.item_class = '''|| iv_prod_class ||'''';

                                                                                -- 商品区分

    lv_sql_m0 := lv_sql_m0 || ' AND xmrh.shipped_locat_id = xilv.inventory_location_id';

                                                                                -- 出荷元ID

    lv_sql_m0 := lv_sql_m0 || ' AND xilv.disable_date IS NULL';                 -- 無効日

--

    -- 変動部(物流ブロック)

    lv_sql_m1 := ' AND ((xilv.distribution_block IN (

                        '''|| iv_block_1 ||''',                                       -- ブロック１

                        '''|| iv_block_2 ||''',                                       -- ブロック２

                        '''|| iv_block_3 ||''')';                                     -- ブロック３

    lv_sql_m1 := lv_sql_m1 || ' OR xmrh.shipped_locat_code = '''|| iv_storage_code ||''')';

    lv_sql_m1 := lv_sql_m1 || ' OR (('''|| iv_block_1 ||''' IS NULL) AND ('''|| iv_block_2 ||''' IS NULL) AND ('''|| iv_block_3 ||''' IS NULL) AND ('''|| iv_storage_code ||''' IS NULL)))';

--

    -- 固定部(出庫予定日)

    lv_sql_m2 := ' AND xmrh.schedule_ship_date >= TO_DATE(

                      '''|| TO_CHAR(id_date_from, 'YYYY/MM/DD') ||''',''YYYY/MM/DD'')';    -- 出庫日From

    lv_sql_m2 := lv_sql_m2 || ' AND xmrh.schedule_ship_date <= TO_DATE(

                      '''|| TO_CHAR(id_date_to, 'YYYY/MM/DD') ||''',''YYYY/MM/DD'')';      -- 出庫日To

--

    -- 変動部(運送業者ID)

    IF (iv_forwarder IS NOT NULL) THEN

      lv_sql_m3 := ' AND xmrh.career_id = '|| iv_forwarder ||'';

    END IF;

--

-- 2009/01/27 H.Itou Add Start 本番障害#1028対応

    -- 変動部(指示部署)

    IF (iv_instruction_dept IS NOT NULL) THEN

      lv_sql_m3 := lv_sql_m3 || ' AND xmrh.instruction_post_code = '''|| iv_instruction_dept ||'''';

    END IF;

-- 2009/01/27 H.Itou Add End

    -- 固定部

    lv_sql_m4 := ' AND xmrh.shipping_method_code = xlv.lookup_code';          -- 配送区分

    lv_sql_m4 := lv_sql_m4 || ' AND xlv.lookup_type = '''|| cv_ship_method ||'''';  --

    lv_sql_m4 := lv_sql_m4 || ' AND (xlv.start_date_active IS NULL';

    lv_sql_m4 := lv_sql_m4 || ' OR xlv.start_date_active <= TO_DATE(

                              '''|| TO_CHAR(id_date_from, 'YYYY/MM/DD') ||''',''YYYY/MM/DD''))';

                                                                -- クイックコード：適用開始日

    lv_sql_m4 := lv_sql_m4 || ' AND (xlv.end_date_active IS NULL';

    lv_sql_m4 := lv_sql_m4 || ' OR xlv.end_date_active >= TO_DATE(

                              '''|| TO_CHAR(id_date_from, 'YYYY/MM/DD') ||''',''YYYY/MM/DD''))';

                                                                -- クイックコード：適用終了日

    lv_sql_m4 := lv_sql_m4 || ' AND xlv.enabled_flag = '''|| cv_yes ||'''';

                                                                -- クイックコード：有効フラグ

-- Ver1.14 MIYATA Start

    lv_sql_m4 := lv_sql_m4 || ' FOR UPDATE OF xmrh.delivery_no ';

-- Ver1.14 MIYATA End

--

    -- SQL文連結(移動指示)

    lv_sql_buff_move := lv_sql_m0 || lv_sql_m1 || lv_sql_m2 || lv_sql_m3 || lv_sql_m4;

--

debug_log(FND_FILE.LOG,'移動指示SQL：'||lv_sql_buff_move);

--

    -- ===============================

    -- 出荷依頼/移動指示データ抽出

    -- ===============================

    IF (iv_shipping_biz_type = gv_ship_type_ship) THEN    -- 出荷依頼

--

      -- カーソルオープン

      OPEN get_ship_cur FOR lv_sql_buff_ship;

--

      -- 一括取得

      FETCH get_ship_cur BULK COLLECT INTO gt_ship_data_tab;

--

--debug_log(FND_FILE.LOG,'出荷依頼一括取得：件数＝'||gt_ship_data_tab.count);

--

      -- カーソルクローズ

      CLOSE get_ship_cur;

--

    ELSIF (iv_shipping_biz_type = gv_ship_type_move) THEN  -- 移動指示

--

      -- カーソルオープン

      OPEN get_move_cur FOR lv_sql_buff_move;

--

      -- 一括取得

      FETCH get_move_cur BULK COLLECT INTO gt_move_data_tab;

--

--debug_log(FND_FILE.LOG,'移動指示一括取得：件数＝'||gt_move_data_tab.count);

      -- カーソルクローズ

      CLOSE get_move_cur;

--

    ELSIF (iv_shipping_biz_type IS NULL) THEN             -- 指定なし

      -- 出荷依頼カーソルオープン

      OPEN get_ship_cur FOR lv_sql_buff_ship;

--

      -- 一括取得

      FETCH get_ship_cur BULK COLLECT INTO gt_ship_data_tab;

--

      -- カーソルクローズ

      CLOSE get_ship_cur;

--

      -- 移動指示カーソルオープン

      OPEN get_move_cur FOR lv_sql_buff_move;

--

      -- 一括取得

      FETCH get_move_cur BULK COLLECT INTO gt_move_data_tab;

--

      -- カーソルクローズ

      CLOSE get_move_cur;

--

    END IF;

--

    -- ===============================

    -- データ抽出確認

    -- ===============================

    IF (iv_shipping_biz_type = gv_ship_type_ship) THEN  -- 出荷依頼

--

debug_log(FND_FILE.LOG,'B-3 出荷依頼件数：'||gt_ship_data_tab.COUNT);

--

      IF (gt_ship_data_tab.COUNT = 0) THEN

--

debug_log(FND_FILE.LOG,'B-3 出荷依頼0件処理');

        -- エラーメッセージ取得

        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(

                      gv_xxwsh            -- モジュール名略称：XXWSH 出荷・引当/配車

                     ,gv_msg_xxwsh_11804  -- 対象データなし

                     ,gv_tkn_table        -- トークン'TABLE'

                     ,cv_tab_name         -- テーブル名：依頼／指示データ

                     ,gv_tkn_key          -- トークン'KEY'

                     ,gv_parameters       -- エラーデータ

                     ) ,1 ,5000);

       lv_errbuf := lv_errmsg;

--

        RAISE no_data;

--

      END IF;

--

      -- 出荷依頼件数

      gn_ship_cnt := gt_ship_data_tab.COUNT;

--

    ELSIF (iv_shipping_biz_type = gv_ship_type_move) THEN  -- 移動指示

--

debug_log(FND_FILE.LOG,'B-3 移動指示件数：'||gt_move_data_tab.COUNT);

--

      IF (gt_move_data_tab.COUNT = 0) THEN

debug_log(FND_FILE.LOG,'B-3 移動指示0件処理');

        -- エラーメッセージ取得

        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(

                      gv_xxwsh            -- モジュール名略称：XXWSH 出荷・引当/配車

                     ,gv_msg_xxwsh_11804  -- 対象データなし

                     ,gv_tkn_table        -- トークン'TABLE'

                     ,cv_tab_name         -- テーブル名：依頼／指示データ

                     ,gv_tkn_key          -- トークン'KEY'

                     ,gv_parameters       -- エラーデータ

                     ) ,1 ,5000);

        lv_errbuf := lv_errmsg;

--

        RAISE no_data;

--

      END IF;

--

      -- 移動指示件数

      gn_move_cnt := gt_move_data_tab.COUNT;

--

    ELSIF (iv_shipping_biz_type IS NULL) THEN  -- 処理種別指定なし

--

debug_log(FND_FILE.LOG,'B-3 出荷依頼件数：'||gt_ship_data_tab.COUNT);

debug_log(FND_FILE.LOG,'B-3 移動指示件数：'||gt_move_data_tab.COUNT);

--

      IF ((gt_ship_data_tab.COUNT = 0)

          AND

          (gt_move_data_tab.COUNT = 0)) THEN

--

debug_log(FND_FILE.LOG,'B-3 出荷依頼・移動指示0件処理（処理種別指定なし)');

        -- エラーメッセージ取得

        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(

                      gv_xxwsh            -- モジュール名略称：XXWSH 出荷・引当/配車

                     ,gv_msg_xxwsh_11804  -- 対象データなし

                     ,gv_tkn_table        -- トークン'TABLE'

                     ,cv_tab_name         -- テーブル名：依頼／指示データ

                     ,gv_tkn_key          -- トークン'KEY'

                     ,gv_parameters       -- エラーデータ

                     ) ,1 ,5000);

        lv_errbuf := lv_errmsg;

--

        RAISE no_data;

--

      END IF;

--

      -- 出力件数

      gn_ship_cnt := gt_ship_data_tab.COUNT;  -- 出荷依頼件数

      gn_move_cnt := gt_move_data_tab.COUNT;  -- 移動指示件数

--

    END IF;

--

    -- ===============================

    -- 最大配送区分取得/PLSQL表セット

    -- ===============================

    -- 出荷依頼データ

    IF (gt_ship_data_tab.COUNT > 0) THEN

--

debug_log(FND_FILE.LOG,'B3_1.0 最大配送区分取得:出荷依頼');

      <<get_max_ship_method_1>>

      FOR ln_cnt_1 IN 1..gt_ship_data_tab.COUNT LOOP

--

        -- 共通関数：最大配送区分算出関数

        return_cd := xxwsh_common_pkg.get_max_ship_method(

                    iv_code_class1

                          => gv_cdkbn_storage,                      -- コード区分1

                    iv_entering_despatching_code1

                          => gt_ship_data_tab(ln_cnt_1).ship_from,  -- 入出庫場所1

                    iv_code_class2

                          => gv_cdkbn_ship_to,                      -- コード区分2

                    iv_entering_despatching_code2

                          => gt_ship_data_tab(ln_cnt_1).ship_to,    -- 入出庫場所2

                    iv_prod_class

                          => iv_prod_class,                         -- 商品区分

                    iv_weight_capacity_class

                          => gt_ship_data_tab(ln_cnt_1).weight_capacity_cls,

                                                                    -- 重量容積区分

                    iv_auto_process_type

                          => cv_an_object,                          -- 自動配車対象区分

                    id_standard_date

                          => gt_ship_data_tab(ln_cnt_1).ship_date,  -- 基準日

                    ov_max_ship_methods

                          => lv_max_ship_methods_s,                 -- 最大配送区分

                    on_drink_deadweight

                          => ln_drink_deadweight_s,                 -- ドリンク積載重量

                    on_leaf_deadweight

                          => ln_leaf_deadweight_s,                  -- リーフ積載重量

                    on_drink_loading_capacity

                          => ln_drink_loading_capacity_s,           -- ドリンク積載容積

                    on_leaf_loading_capacity

                          => ln_leaf_loading_capacity_s,            -- リーフ積載容積

                    on_palette_max_qty

                          => ln_palette_max_qty_s                   -- パレット最大枚数

                    );

--

debug_log(FND_FILE.LOG,'B3_1.1 出荷依頼No:'|| gt_ship_data_tab(ln_cnt_1).req_mov_no);

debug_log(FND_FILE.LOG,' コード区分1:' || gv_cdkbn_storage);

debug_log(FND_FILE.LOG,' 入出庫場所1:' || gt_ship_data_tab(ln_cnt_1).ship_from);

debug_log(FND_FILE.LOG,' コード区分2:' || gv_cdkbn_ship_to);

debug_log(FND_FILE.LOG,' 入出庫場所2:' || gt_ship_data_tab(ln_cnt_1).ship_to);

debug_log(FND_FILE.LOG,' 商品区分   :' || iv_prod_class);

debug_log(FND_FILE.LOG,' 重量容積区分:'|| gt_ship_data_tab(ln_cnt_1).weight_capacity_cls);

debug_log(FND_FILE.LOG,' 自動配車対象区分:'|| cv_an_object);

debug_log(FND_FILE.LOG,' 基準日:' || TO_CHAR(gt_ship_data_tab(ln_cnt_1).ship_date,'YYYYMMDD'));

debug_log(FND_FILE.LOG,' 最大配送区分:'    || lv_max_ship_methods_s);

debug_log(FND_FILE.LOG,' ドリンク積載重量:'|| ln_drink_deadweight_s);

debug_log(FND_FILE.LOG,' リーフ積載重量:'  || ln_leaf_deadweight_s);

debug_log(FND_FILE.LOG,' ドリンク積載容積:'|| ln_drink_loading_capacity_s);

debug_log(FND_FILE.LOG,' リーフ積載容積:'  || ln_leaf_loading_capacity_s);

debug_log(FND_FILE.LOG,' パレット最大枚数:'|| ln_palette_max_qty_s);

--

        IF  (return_cd = gv_error)

          OR (lv_max_ship_methods_s IS NULL)

        THEN

--

          -- エラーメッセージ取得

          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(

                        gv_xxwsh                      -- モジュール名略称：XXWSH 出荷・引当/配車

                       ,gv_msg_xxwsh_11802            -- 最大配送区分取得エラー

                       ,gv_tkn_from                   -- トークン'FROM'

                       ,gt_ship_data_tab(ln_cnt_1).ship_from

                                                      -- 入出庫場所1

                       ,gv_tkn_to                     -- トークン'TO'

                       ,gt_ship_data_tab(ln_cnt_1).ship_to

                                                      -- 入出庫場所2

                       ,gv_tkn_codekbn1               -- トークン'CODEKBN1'

                       ,gv_cdkbn_storage              -- コード区分1

                       ,gv_tkn_codekbn2               -- トークン'CODEKBN2'

                       ,gv_cdkbn_ship_to              -- コード区分2

                      ) ,1 ,5000);

--

          RAISE global_api_expt;

--

        END IF;

--

--debug_log(FND_FILE.LOG,'ソートテーブル登録用PL/SQLにセット');

--

        -- ==================================

        -- ソートテーブル登録用PL/SQLにセット

        -- ==================================

        gt_deliver_no_s(ln_cnt_1)

            := gt_ship_data_tab(ln_cnt_1).deliver_no;             -- 配送No

        gt_pre_deliver_no_s(ln_cnt_1)

            := gt_ship_data_tab(ln_cnt_1).pre_deliver_no;         -- 前回配送No

        gt_req_mov_no_s(ln_cnt_1)

            := gt_ship_data_tab(ln_cnt_1).req_mov_no;             -- 依頼No/移動No

        gt_mixed_no_s(ln_cnt_1)

            := gt_ship_data_tab(ln_cnt_1).mixed_no;               -- 混載元No

        gt_carrier_code_s(ln_cnt_1)

            := gt_ship_data_tab(ln_cnt_1).carrier_code;           -- 運送業者

        gt_carrier_id_s(ln_cnt_1)

            := gt_ship_data_tab(ln_cnt_1).carrier_id;             -- 運送業者ID

        gt_ship_from_s(ln_cnt_1)

            := gt_ship_data_tab(ln_cnt_1).ship_from;              -- 出荷元保管場所

        gt_ship_from_id_s(ln_cnt_1)

            := gt_ship_data_tab(ln_cnt_1).ship_from_id;           -- 出荷元ID

        gt_ship_to_s(ln_cnt_1)

            := gt_ship_data_tab(ln_cnt_1).ship_to;                -- 出荷先

        gt_ship_to_id_s(ln_cnt_1)

            := gt_ship_data_tab(ln_cnt_1).ship_to_id;             -- 出荷先ID

        gt_ship_method_code_s(ln_cnt_1)

            := gt_ship_data_tab(ln_cnt_1).ship_method_code;       -- 配送区分

        gt_small_div_s(ln_cnt_1)

            := gt_ship_data_tab(ln_cnt_1).small_div;              -- 小口区分

        gt_ship_date_s(ln_cnt_1)

            := gt_ship_data_tab(ln_cnt_1).ship_date;              -- 出庫日

        gt_arrival_date_s(ln_cnt_1)

            := gt_ship_data_tab(ln_cnt_1).arrival_date;           -- 着荷日

--20080517:DSugahara修正不具合No1 基本重量、基本容積の設定->

--        gt_based_weight_s(ln_cnt_1)

--            := gt_ship_data_tab(ln_cnt_1).based_weight;           -- 基本重量

--        gt_based_capacity_s(ln_cnt_1)

--            := gt_ship_data_tab(ln_cnt_1).based_capacity;         -- 基本容積

        -- 基本重量

        IF (gt_ship_data_tab(ln_cnt_1).item_class = gv_prod_cls_leaf) THEN

          gt_based_weight_s(ln_cnt_1) := ln_leaf_deadweight_s;    -- リーフ積載重量

        ELSE

          gt_based_weight_s(ln_cnt_1) := ln_drink_deadweight_s;   -- ドリンク積載重量

        END IF;

        -- 基本容積

        IF (gt_ship_data_tab(ln_cnt_1).item_class = gv_prod_cls_leaf) THEN

          gt_based_capacity_s(ln_cnt_1) := ln_leaf_loading_capacity_s;  -- リーフ積載容積

        ELSE

          gt_based_capacity_s(ln_cnt_1) := ln_drink_loading_capacity_s; -- ドリンク積載容積

        END IF;

--20080517:DSugahara修正不具合No1 基本重量、基本容積の設定<-

        gt_sum_weight_s(ln_cnt_1)

            := gt_ship_data_tab(ln_cnt_1).sum_weight;             -- 積載重量合計

        gt_sum_capacity_s(ln_cnt_1)

            := gt_ship_data_tab(ln_cnt_1).sum_capacity;           -- 積載容積合計

        gt_weight_capacity_cls_s(ln_cnt_1)

            := gt_ship_data_tab(ln_cnt_1).weight_capacity_cls;    -- 重量容積区分

        gt_sum_pallet_weight_s(ln_cnt_1)

            := gt_ship_data_tab(ln_cnt_1).sum_pallet_weight;      -- 合計パレット重量

        gt_item_class_s(ln_cnt_1)

            := gt_ship_data_tab(ln_cnt_1).item_class;             -- 商品区分

        gt_business_type_s(ln_cnt_1)

            := gt_ship_data_tab(ln_cnt_1).business_type_id;     -- 取引タイプ

        gt_reserve_order_s(ln_cnt_1)

            := gt_ship_data_tab(ln_cnt_1).reserve_order;          -- 引当順

        gt_max_shipping_method_s(ln_cnt_1)

            := lv_max_ship_methods_s;                             -- 最大配送区分

        gt_head_sales_branch_s(ln_cnt_1)

            := gt_ship_data_tab(ln_cnt_1).sales_branch;           -- 管轄拠点

        gt_pre_saved_flag_s(ln_cnt_1)     := 0;                   -- 拠点混載登録済フラグ

--

--

--debug_log(FND_FILE.LOG,'依頼No:'|| gt_req_mov_no_s(ln_cnt_1));

--debug_log(FND_FILE.LOG,'基本重量:'|| gt_based_weight_s(ln_cnt_1));

--debug_log(FND_FILE.LOG,'基本容積:'|| gt_based_capacity_s(ln_cnt_1));

--

      END LOOP get_max_ship_method_1;

--

    END IF;

--

    -- 移動指示データ

    IF (gt_move_data_tab.COUNT > 0) THEN

--

debug_log(FND_FILE.LOG,'B3_1.2 最大配送区分取得:移動指示');

--

      <<get_max_ship_method_2>>

      FOR ln_cnt_2 IN 1..gt_move_data_tab.COUNT LOOP

--

debug_log(FND_FILE.LOG,'B3_1.2 移動指示No:'|| gt_move_data_tab(ln_cnt_2).req_mov_no);

debug_log(FND_FILE.LOG,' コード区分1:'     || gv_cdkbn_storage);

debug_log(FND_FILE.LOG,' 入出庫場所1:'     || gt_move_data_tab(ln_cnt_2).ship_from);

debug_log(FND_FILE.LOG,' コード区分2:'     || gv_cdkbn_storage);

debug_log(FND_FILE.LOG,' 入出庫場所2:'     || gt_move_data_tab(ln_cnt_2).ship_to);

debug_log(FND_FILE.LOG,' 商品区分:'        || iv_prod_class);

debug_log(FND_FILE.LOG,' 重量容積区分:'    || gt_move_data_tab(ln_cnt_2).weight_capacity_cls);

debug_log(FND_FILE.LOG,' 自動配車対象区分:'|| cv_an_object);

debug_log(FND_FILE.LOG,' 基準日:'|| to_char(gt_move_data_tab(ln_cnt_2).ship_date,'YYYYMMDD'));

--

        -- 共通関数：最大配送区分算出関数

        return_cd := xxwsh_common_pkg.get_max_ship_method(

                  iv_code_class1                => gv_cdkbn_storage,          -- コード区分1

                  iv_entering_despatching_code1 => gt_move_data_tab(ln_cnt_2).ship_from,

                                                                              -- 入出庫場所1

                  iv_code_class2                => gv_cdkbn_storage,          -- コード区分2

                  iv_entering_despatching_code2 => gt_move_data_tab(ln_cnt_2).ship_to,

                                                                              -- 入出庫場所2

                  iv_prod_class                 => iv_prod_class,             -- 商品区分

                  iv_weight_capacity_class      => gt_move_data_tab(ln_cnt_2).weight_capacity_cls,

                                                                              -- 重量容積区分

                  iv_auto_process_type          => cv_an_object,              -- 自動配車対象区分

                  id_standard_date              => gt_move_data_tab(ln_cnt_2).ship_date,

                                                                              -- 基準日

                  ov_max_ship_methods           => lv_max_ship_methods_m,     -- 最大配送区分

                  on_drink_deadweight           => ln_drink_deadweight_m,     -- ドリンク積載重量

                  on_leaf_deadweight            => ln_leaf_deadweight_m,      -- リーフ積載重量

                  on_drink_loading_capacity     => ln_drink_loading_capacity_m,

                                                                              -- ドリンク積載容積

                  on_leaf_loading_capacity      => ln_leaf_loading_capacity_m,-- リーフ積載容積

                  on_palette_max_qty            => ln_palette_max_qty_m       -- パレット最大枚数

                  );

--

debug_log(FND_FILE.LOG,' 最大配送区分:'    || lv_max_ship_methods_m);

debug_log(FND_FILE.LOG,' ドリンク積載重量:'|| ln_drink_deadweight_m);

debug_log(FND_FILE.LOG,' リーフ積載重量:'  || ln_leaf_deadweight_m);

debug_log(FND_FILE.LOG,' ドリンク積載容積:'|| ln_drink_loading_capacity_m);

debug_log(FND_FILE.LOG,' リーフ積載容積:'  || ln_leaf_loading_capacity_m);

debug_log(FND_FILE.LOG,' パレット最大枚数:'|| ln_palette_max_qty_m);

--

        IF  (return_cd = gv_error)

          OR (lv_max_ship_methods_m IS NULL)

        THEN

--

debug_log(FND_FILE.LOG,' gv_msg_xxwsh_11802 2');

          -- エラーメッセージ取得

          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(

                        gv_xxwsh                        -- モジュール名略称：XXWSH 出荷・引当/配車

                       ,gv_msg_xxwsh_11802              -- 最大配送区分取得エラー

                       ,gv_tkn_from                     -- トークン'FROM'

                       ,gt_move_data_tab(ln_cnt_2).ship_from

                                                        -- 入出庫場所1

                       ,gv_tkn_to                       -- トークン'TO'

                       ,gt_move_data_tab(ln_cnt_2).ship_to

                                                        -- 入出庫場所2

                       ,gv_tkn_codekbn1                 -- トークン'CODEKBN1'

                       ,gv_cdkbn_storage                -- コード区分1

                       ,gv_tkn_codekbn2                 -- トークン'CODEKBN2'

                       ,gv_cdkbn_storage                -- コード区分2

                      ) ,1 ,5000);

--

          RAISE global_api_expt;

--

        END IF;

--

        -- ==================================

        -- ソートテーブル登録用PL/SQLにセット

        -- ==================================

        gt_deliver_no_m(ln_cnt_2)

            := gt_move_data_tab(ln_cnt_2).deliver_no;           -- 配送No

        gt_pre_deliver_no_m(ln_cnt_2)

            := gt_move_data_tab(ln_cnt_2).pre_deliver_no;       -- 前回配送No

        gt_req_mov_no_m(ln_cnt_2)

            := gt_move_data_tab(ln_cnt_2).req_mov_no;           -- 依頼No/移動No

        gt_mixed_no_m(ln_cnt_2)

            := gt_move_data_tab(ln_cnt_2).mixed_no;             -- 混載元No

        gt_carrier_code_m(ln_cnt_2)

            := gt_move_data_tab(ln_cnt_2).carrier_code;         -- 運送業者

        gt_carrier_id_m(ln_cnt_2)

            := gt_move_data_tab(ln_cnt_2).carrier_id;           -- 運送業者ID

        gt_ship_from_m(ln_cnt_2)

            := gt_move_data_tab(ln_cnt_2).ship_from;            -- 出荷元保管場所

        gt_ship_from_id_m(ln_cnt_2)

            := gt_move_data_tab(ln_cnt_2).ship_from_id;         -- 出荷元ID

        gt_ship_to_m(ln_cnt_2)

            := gt_move_data_tab(ln_cnt_2).ship_to;              -- 出荷先

        gt_ship_to_id_m(ln_cnt_2)

            := gt_move_data_tab(ln_cnt_2).ship_to_id;           -- 出荷先ID

        gt_ship_method_code_m(ln_cnt_2)

            := gt_move_data_tab(ln_cnt_2).ship_method_code;     -- 配送区分

        gt_small_div_m(ln_cnt_2)

            := gt_move_data_tab(ln_cnt_2).small_div;            -- 小口区分

        gt_ship_date_m(ln_cnt_2)

            := gt_move_data_tab(ln_cnt_2).ship_date;            -- 出庫日

        gt_arrival_date_m(ln_cnt_2)

            := gt_move_data_tab(ln_cnt_2).arrival_date;         -- 着荷日

--

--20080517:DSugahara修正不具合No1 基本重量、基本容積の設定->

--        gt_based_weight_m(ln_cnt_2)

--            := gt_move_data_tab(ln_cnt_2).based_weight;         -- 基本重量

--        gt_based_capacity_m(ln_cnt_2)

--            := gt_move_data_tab(ln_cnt_2).based_capacity;       -- 基本容積

        -- 基本重量

        IF (gt_move_data_tab(ln_cnt_2).item_class = gv_prod_cls_leaf) THEN

          gt_based_weight_m(ln_cnt_2) := ln_leaf_deadweight_m;    -- リーフ積載重量

        ELSE

          gt_based_weight_m(ln_cnt_2) := ln_drink_deadweight_m;   -- ドリンク積載重量

        END IF;

        -- 基本容積

        IF (gt_move_data_tab(ln_cnt_2).item_class = gv_prod_cls_leaf) THEN

          gt_based_capacity_m(ln_cnt_2) := ln_leaf_loading_capacity_m;  -- リーフ積載容積

        ELSE

          gt_based_capacity_m(ln_cnt_2) := ln_drink_loading_capacity_m; -- ドリンク積載容積

        END IF;

--20080517:DSugahara修正不具合No1 基本重量、基本容積の設定<-

--

        gt_sum_weight_m(ln_cnt_2)

            := gt_move_data_tab(ln_cnt_2).sum_weight;           -- 積載重量合計

        gt_sum_capacity_m(ln_cnt_2)

            := gt_move_data_tab(ln_cnt_2).sum_capacity;         -- 積載容積合計

        gt_weight_capacity_cls_m(ln_cnt_2)

            := gt_move_data_tab(ln_cnt_2).weight_capacity_cls;  -- 重量容積区分

        gt_sum_pallet_weight_m(ln_cnt_2)

            := gt_move_data_tab(ln_cnt_2).sum_pallet_weight;    -- 合計パレット重量

        gt_item_class_m(ln_cnt_2)

            := gt_move_data_tab(ln_cnt_2).item_class;           -- 商品区分

        gt_business_type_m(ln_cnt_2)

            := gt_move_data_tab(ln_cnt_2).business_type_id;     -- 取引タイプ

        gt_reserve_order_m(ln_cnt_2)

            := gt_move_data_tab(ln_cnt_2).reserve_order;        -- 引当順

        gt_max_shipping_method_m(ln_cnt_2)

            := lv_max_ship_methods_m;                           -- 最大配送区分

        gt_head_sales_branch_m(ln_cnt_2)

            := gt_move_data_tab(ln_cnt_2).sales_branch;         -- 管轄拠点

        gt_pre_saved_flag_m(ln_cnt_2)     := 0;                 -- 拠点混載登録済フラグ

--

      END LOOP get_max_ship_method_2;

--

    END IF;

--

    -- ===============================

    -- ソート用中間テーブルに登録

    -- ===============================

--

--debug_log(FND_FILE.LOG,'ソートテーブル登録');

--

    -- 出荷依頼データあり

    IF (gt_deliver_no_s.COUNT > 0) THEN

--

debug_log(FND_FILE.LOG,'出荷依頼データ登録');

      -- 出荷依頼

      FORALL ln_cnt_1 IN 1..gt_deliver_no_s.COUNT

        INSERT INTO xxwsh_carriers_sort_tmp(      -- 自動配車ソート用中間テーブル

              transaction_id                      -- トランザクションID

            , transaction_type                    -- 処理種別(配車)

            , delivery_no                         -- 配送No

            , prev_delivery_no                    -- 前回配送No

            , request_no                          -- 依頼No/移動No

            , mixed_no                            -- 混載元No

            , freight_carrier_code                -- 運送業者

            , career_id                           -- 運送業者ID

            , deliver_from                        -- 出荷元保管場所

            , deliver_from_id                     -- 出荷元ID

            , deliver_to                          -- 出荷先

            , deliver_to_id                       -- 出荷先ID

            , shipping_method_code                -- 配送区分

            , small_sum_class                     -- 小口区分

            , schedule_ship_date                  -- 出庫日

            , schedule_arrival_date               -- 着荷日

            , based_weight                        -- 基本重量

            , based_capacity                      -- 基本容積

            , sum_weight                          -- 積載重量合計

            , sum_capacity                        -- 積載容積合計

            , weight_capacity_class               -- 重量容積区分

            , sum_pallet_weight                   -- 合計パレット重量

            , prod_class                          -- 商品区分

            , order_type_id                       -- 取引タイプ

            , reserve_order                       -- 引当順

            , max_shipping_method_code            -- 最大配送区分

            , head_sales_branch                   -- 管轄拠点

            , pre_saved_flg                       -- 拠点混載登録済フラグ

            )

            VALUES

            (

              xxwsh_carriers_sort_tmp_s1.NEXTVAL  -- トランザクションID

            , gv_ship_type_ship                   -- 処理種別(配車)

            , gt_deliver_no_s(ln_cnt_1)           -- 配送No

            , gt_pre_deliver_no_s(ln_cnt_1)       -- 前回配送No

            , gt_req_mov_no_s(ln_cnt_1)           -- 依頼No/移動No

            , gt_mixed_no_s(ln_cnt_1)             -- 混載元No

            , gt_carrier_code_s(ln_cnt_1)         -- 運送業者

            , gt_carrier_id_s(ln_cnt_1)           -- 運送業者ID

            , gt_ship_from_s(ln_cnt_1)            -- 出荷元保管場所

            , gt_ship_from_id_s(ln_cnt_1)         -- 出荷元ID

            , gt_ship_to_s(ln_cnt_1)              -- 出荷先

            , gt_ship_to_id_s(ln_cnt_1)           -- 出荷先ID

            , gt_ship_method_code_s(ln_cnt_1)     -- 配送区分

            , gt_small_div_s(ln_cnt_1)            -- 小口区分

            , gt_ship_date_s(ln_cnt_1)            -- 出庫日

            , gt_arrival_date_s(ln_cnt_1)         -- 着荷日

            , gt_based_weight_s(ln_cnt_1)         -- 基本重量

            , gt_based_capacity_s(ln_cnt_1)       -- 基本容積

            , gt_sum_weight_s(ln_cnt_1)           -- 積載重量合計

            , gt_sum_capacity_s(ln_cnt_1)         -- 積載容積合計

            , gt_weight_capacity_cls_s(ln_cnt_1)  -- 重量容積区分

            , gt_sum_pallet_weight_s(ln_cnt_1)    -- 合計パレット重量

            , gt_item_class_s(ln_cnt_1)           -- 商品区分

            , gt_business_type_s(ln_cnt_1)        -- 取引タイプ

            , gt_reserve_order_s(ln_cnt_1)        -- 引当順

            , gt_max_shipping_method_s(ln_cnt_1)  -- 最大配送区分

            , gt_head_sales_branch_s(ln_cnt_1)    -- 管轄拠点

            , gt_pre_saved_flag_s(ln_cnt_1)       -- 拠点混載登録済フラグ

            );

--

    END IF;

--

    -- 移動指示データあり

    IF (gt_deliver_no_m.COUNT > 0) THEN

--

debug_log(FND_FILE.LOG,'移動指示データ登録');

--

      -- 移動指示

      FORALL ln_cnt_2 IN 1..gt_deliver_no_m.COUNT

        INSERT INTO xxwsh_carriers_sort_tmp(      -- 自動配車ソート用中間テーブル

              transaction_id                      -- トランザクションID

            , transaction_type                    -- 処理種別(配車)

            , delivery_no                         -- 配送No

            , prev_delivery_no                    -- 前回配送No

            , request_no                          -- 依頼No/移動No

            , mixed_no                            -- 混載元No

            , freight_carrier_code                -- 運送業者

            , career_id                           -- 運送業者ID

            , deliver_from                        -- 出荷元保管場所

            , deliver_from_id                     -- 出荷元ID

            , deliver_to                          -- 出荷先

            , deliver_to_id                       -- 出荷先ID

            , shipping_method_code                -- 配送区分

            , small_sum_class                     -- 小口区分

            , schedule_ship_date                  -- 出庫日

            , schedule_arrival_date               -- 着荷日

            , based_weight                        -- 基本重量

            , based_capacity                      -- 基本容積

            , sum_weight                          -- 積載重量合計

            , sum_capacity                        -- 積載容積合計

            , weight_capacity_class               -- 重量容積区分

            , sum_pallet_weight                   -- 合計パレット重量

            , prod_class                          -- 商品区分

            , order_type_id                       -- 取引タイプ

            , reserve_order                       -- 引当順

            , max_shipping_method_code            -- 最大配送区分

            , head_sales_branch                   -- 管轄拠点

            , pre_saved_flg                       -- 拠点混載登録済フラグ

            )

            VALUES

            ( xxwsh_carriers_sort_tmp_s1.NEXTVAL  -- トランザクションID

            , gv_ship_type_move                   -- 処理種別(配車)

            , gt_deliver_no_m(ln_cnt_2)           -- 配送No

            , gt_pre_deliver_no_m(ln_cnt_2)       -- 前回配送No

            , gt_req_mov_no_m(ln_cnt_2)           -- 依頼No/移動No

            , gt_mixed_no_m(ln_cnt_2)             -- 混載元No

            , gt_carrier_code_m(ln_cnt_2)         -- 運送業者

            , gt_carrier_id_m(ln_cnt_2)           -- 運送業者ID

            , gt_ship_from_m(ln_cnt_2)            -- 出荷元保管場所

            , gt_ship_from_id_m(ln_cnt_2)         -- 出荷元ID

            , gt_ship_to_m(ln_cnt_2)              -- 出荷先

            , gt_ship_to_id_m(ln_cnt_2)           -- 出荷先ID

            , gt_ship_method_code_m(ln_cnt_2)     -- 配送区分

            , gt_small_div_m(ln_cnt_2)            -- 小口区分

            , gt_ship_date_m(ln_cnt_2)            -- 出庫日

            , gt_arrival_date_m(ln_cnt_2)         -- 着荷日

            , gt_based_weight_m(ln_cnt_2)         -- 基本重量

            , gt_based_capacity_m(ln_cnt_2)       -- 基本容積

            , gt_sum_weight_m(ln_cnt_2)           -- 積載重量合計

            , gt_sum_capacity_m(ln_cnt_2)         -- 積載容積合計

            , gt_weight_capacity_cls_m(ln_cnt_2)  -- 重量容積区分

            , gt_sum_pallet_weight_m(ln_cnt_2)    -- 合計パレット重量

            , gt_item_class_m(ln_cnt_2)           -- 商品区分

            , gt_business_type_m(ln_cnt_2)        -- 取引タイプ

            , gt_reserve_order_m(ln_cnt_2)        -- 引当順

            , gt_max_shipping_method_m(ln_cnt_2)  -- 最大配送区分

            , gt_head_sales_branch_m(ln_cnt_2)    -- 管轄拠点

            , gt_pre_saved_flag_m(ln_cnt_2)       -- 拠点混載登録済フラグ

            );

--

--

--debug_log(FND_FILE.LOG,'ソートテーブル登録完了');

--

    END IF;

-- Ver1.5 M.Hokkanji Start

    debug_log(FND_FILE.LOG,'ソートテーブル登録完了したためコミット');

    COMMIT;

-- Ver1.5 M.Hokkanji End

--

  EXCEPTION

    -- ロック取得エラー

    WHEN lock_expt THEN

      IF (get_ship_cur%ISOPEN) THEN

        CLOSE get_ship_cur;

      END IF;

      IF (get_move_cur%ISOPEN) THEN

        CLOSE get_move_cur;

      END IF;

      -- エラーメッセージ取得

      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(

                    gv_xxwsh            -- モジュール名略称：XXWSH 出荷・引当/配車

                   ,gv_msg_xxwsh_11052  -- メッセージ：ロック取得エラー

                   ),1,5000);

      ov_errmsg  := lv_errmsg;                                                  --# 任意 #

      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);

      ov_retcode := gv_status_error;                                            --# 任意 #

--

    WHEN no_data THEN

      IF (get_ship_cur%ISOPEN) THEN

        CLOSE get_ship_cur;

      END IF;

      IF (get_move_cur%ISOPEN) THEN

        CLOSE get_move_cur;

      END IF;

      ov_errmsg  := lv_errmsg;

      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);

      ov_retcode := gv_status_warn;

--

--#################################  固定例外処理部 START   ####################################

--

    -- *** 共通関数例外ハンドラ ***

    WHEN global_api_expt THEN

      IF (get_ship_cur%ISOPEN) THEN

        CLOSE get_ship_cur;

      END IF;

      IF (get_move_cur%ISOPEN) THEN

        CLOSE get_move_cur;

      END IF;

      ov_errmsg  := lv_errmsg;

      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);

      ov_retcode := gv_status_error;

    -- *** 共通関数OTHERS例外ハンドラ ***

    WHEN global_api_others_expt THEN

      IF (get_ship_cur%ISOPEN) THEN

        CLOSE get_ship_cur;

      END IF;

      IF (get_move_cur%ISOPEN) THEN

        CLOSE get_move_cur;

      END IF;

      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;

      ov_retcode := gv_status_error;

    -- *** OTHERS例外ハンドラ ***

    WHEN OTHERS THEN

      IF (get_ship_cur%ISOPEN) THEN

        CLOSE get_ship_cur;

      END IF;

      IF (get_move_cur%ISOPEN) THEN

        CLOSE get_move_cur;

      END IF;

      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;

      ov_retcode := gv_status_error;

--

--#####################################  固定部 END   ##########################################

--

  END get_req_inst_info;

--

  /**********************************************************************************

   * Procedure Name   : ins_hub_mixed_info

   * Description      : 拠点混載情報登録処理(B-4)

   ***********************************************************************************/

  PROCEDURE ins_hub_mixed_info(

    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #

    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #

    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #

  IS

    -- ===============================

    -- 固定ローカル定数

    -- ===============================

    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_hub_mixed_info'; -- プログラム名

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

    cv_pre_save             CONSTANT VARCHAR2(1) := '1';    -- 拠点混載済

--

    -- *** ローカル変数 ***

    -- 比較用変数

    lt_prev_ship_date       xxwsh_carriers_sort_tmp.schedule_ship_date%TYPE;    -- 出庫日

    lt_prev_arrival_date    xxwsh_carriers_sort_tmp.schedule_arrival_date%TYPE; -- 着荷日

    lt_prev_order_type      xxwsh_carriers_sort_tmp.order_type_id%TYPE;         -- 出庫形態

    lt_prev_freight_carrier xxwsh_carriers_sort_tmp.freight_carrier_code%TYPE;  -- 運送業者

    lt_prev_ship_from       xxwsh_carriers_sort_tmp.deliver_from%TYPE;          -- 前出荷元

    lt_prev_ship_to         xxwsh_carriers_sort_tmp.deliver_to%TYPE;            -- 前出荷先

    lt_prev_mixed_no        xxwsh_carriers_sort_tmp.mixed_no%TYPE;              -- 前混載元No

--

    ln_sum_weight           NUMBER DEFAULT 0;                       -- 集約重量(1箇所目の配送先)

    ln_sum_capacity         NUMBER DEFAULT 0;                       -- 集約容積(1箇所目の配送先)

-- 2009/01/05 H.Itou Add Start 本番障害#879

    ln_sum_weight_2         NUMBER DEFAULT 0;                       -- 集約重量(2箇所目の配送先)

    ln_sum_capacity_2       NUMBER DEFAULT 0;                       -- 集約容積(2箇所目の配送先)

-- 2009/01/05 H.Itou Add End

--

    ln_mixed_cnt            NUMBER DEFAULT 0;                       -- 混載カウント

    ln_mixed_loop_cnt       NUMBER DEFAULT 0;                       -- ループカウント

    ln_ins_cnt              NUMBER DEFAULT 0;                       -- 中間テーブル登録用カウント

    ln_work_cnt             NUMBER DEFAULT 0;                       -- 混載ワークテーブル用カウント

    lt_request_no_tab       req_mov_no_ttype;                       -- 依頼No格納用テーブル

    lt_trans_id_tab         transaction_id_ttype;                   -- トランザクションID格納用

--

    ln_intensive_no         NUMBER DEFAULT NULL;                    -- 集約No(1箇所目の配送先)

-- 2009/01/05 H.Itou Add Start 本番障害#879

    ln_intensive_no_2       NUMBER DEFAULT NULL;                    -- 集約No(2箇所目の配送先)

-- 2009/01/05 H.Itou Add End

    ln_grp_cnt              NUMBER DEFAULT 0;                       -- 同一キーグループカウント

    ln_detail_ins_cnt       NUMBER DEFAULT 0;                       -- 明細登録カウント

    ln_start_cnt            NUMBER DEFAULT 0;                       -- 処理開始カウント

    ln_end_cnt              NUMBER DEFAULT 0;                       -- 処理終了カウント

    lb_exit_flag            BOOLEAN DEFAULT FALSE;                  -- 終了フラグ

--

    -- 自動配車ソート用中間テーブル取得用レコード型

    TYPE mixed_info_rtype IS RECORD(

        transaction_id            xxwsh_carriers_sort_tmp.transaction_id%TYPE           -- トランザクションID

      , transaction_type          xxwsh_carriers_sort_tmp.transaction_type%TYPE         -- 処理種別

      , request_no                xxwsh_carriers_sort_tmp.request_no%TYPE               -- 出荷依頼NO

      , mixed_no                  xxwsh_carriers_sort_tmp.mixed_no%TYPE                 -- 混載元NO

      , deliver_from              xxwsh_carriers_sort_tmp.deliver_from%TYPE             -- 出荷元保管場所

      , deliver_from_id           xxwsh_carriers_sort_tmp.deliver_from_id%TYPE          -- 出荷元ID

      , deliver_to                xxwsh_carriers_sort_tmp.deliver_to%TYPE               -- 出荷先

      , deliver_to_id             xxwsh_carriers_sort_tmp.deliver_to_id%TYPE            -- 出荷先ID

      , shipping_method_code      xxwsh_carriers_sort_tmp.shipping_method_code%TYPE     -- 配送区分

      , schedule_ship_date        xxwsh_carriers_sort_tmp.schedule_ship_date%TYPE       -- 出庫日

      , schedule_arrival_date     xxwsh_carriers_sort_tmp.schedule_arrival_date%TYPE    -- 着荷日

      , order_type_id             xxwsh_carriers_sort_tmp.order_type_id%TYPE            -- 出庫形態

      , freight_carrier_code      xxwsh_carriers_sort_tmp.freight_carrier_code%TYPE     -- 運送業者

      , career_id                 xxwsh_carriers_sort_tmp.career_id%TYPE                -- 運送業者ID

      , based_weight              xxwsh_carriers_sort_tmp.based_weight%TYPE             -- 基本重量

      , based_capacity            xxwsh_carriers_sort_tmp.based_capacity%TYPE           -- 基本容積

      , sum_weight                xxwsh_carriers_sort_tmp.sum_weight%TYPE               -- 積載重量合計

      , sum_capacity              xxwsh_carriers_sort_tmp.sum_capacity%TYPE             -- 積載容積合計

      , sum_pallet_weight         xxwsh_carriers_sort_tmp.sum_pallet_weight%TYPE        -- 合計パレット重量

      , max_shipping_method_code  xxwsh_carriers_sort_tmp.max_shipping_method_code%TYPE -- 最大配送区分

      , weight_capacity_class     xxwsh_carriers_sort_tmp.weight_capacity_class%TYPE    -- 重量容積区分

      , reserve_order             xxwsh_carriers_sort_tmp.reserve_order%TYPE            -- 引当順

    );

--

    -- 自動配車ソート用中間テーブル取得用表型

    TYPE mixed_info_ttype IS TABLE OF mixed_info_rtype INDEX BY BINARY_INTEGER;

--

    -- 自動配車ソート用中間テーブル取得用PLSQL表

    mixed_info_tab  mixed_info_ttype;

--

    -- *** ローカル・カーソル ***

    CURSOR mixed_info_cur IS

      SELECT  xcst.transaction_id                     -- トランザクションID

            , xcst.transaction_type                   -- 処理種別

            , xcst.request_no                         -- 出荷依頼NO

            , xcst.mixed_no                           -- 混載元NO

            , xcst.deliver_from                       -- 出荷元保管場所

            , xcst.deliver_from_id                    -- 出荷元ID

            , xcst.deliver_to                         -- 出荷先

            , xcst.deliver_to_id                      -- 出荷先ID

            , xcst.shipping_method_code               -- 配送区分

            , xcst.schedule_ship_date                 -- 出庫日

            , xcst.schedule_arrival_date              -- 着荷日

            , xcst.order_type_id                      -- 出庫形態

            , xcst.freight_carrier_code               -- 運送業者

            , xcst.career_id                          -- 運送業者ID

            , xcst.based_weight                       -- 基本重量

            , xcst.based_capacity                     -- 基本容積

            , xcst.sum_weight                         -- 積載重量合計

            , xcst.sum_capacity                       -- 積載容積合計

            , xcst.sum_pallet_weight                  -- 合計パレット重量

            , xcst.max_shipping_method_code           -- 最大配送区分

            , xcst.weight_capacity_class              -- 重量容積区分

            , DECODE(xcst.reserve_order, NULL, 99999, xcst.reserve_order)

                                                      -- 引当順

      FROM xxwsh_carriers_sort_tmp xcst               -- 自動配車ソート用中間テーブル

      WHERE xcst.transaction_type = gv_ship_type_ship -- 処理種別：出荷依頼のみ

        AND xcst.mixed_no IS NOT NULL                 -- 混載元NO

      ORDER BY  xcst.schedule_ship_date               -- 出庫日

              , xcst.schedule_arrival_date            -- 着荷日

              , xcst.mixed_no                         -- 混載元NO

              , xcst.order_type_id                    -- 出庫形態

              , xcst.deliver_from                     -- 出荷元保管場所

              , xcst.freight_carrier_code             -- 運送業者

              , xcst.weight_capacity_class            -- 重量容積区分

              , xcst.reserve_order                    -- 引当順

              , xcst.head_sales_branch                -- 管轄拠点

              , xcst.deliver_to                       -- 出荷先

              , DECODE (xcst.weight_capacity_class, gv_weight

                        , xcst.sum_weight             -- 集約重量合計

                        , xcst.sum_capacity) DESC     -- 集約合計容積

      ;

--

    -- *** ローカル・レコード ***

    lr_mixed_info     mixed_info_cur%ROWTYPE;               -- カーソルレコード

    lr_intensive_tmp  xxwsh_intensive_carriers_tmp%ROWTYPE; -- 自動配車集約中間テーブルレコード(1箇所目の配送先用)

-- 2009/01/05 H.Itou Add Start 本番障害#879

    lr_intensive_tmp_2  xxwsh_intensive_carriers_tmp%ROWTYPE; -- 自動配車集約中間テーブルレコード(2箇所目の配送先用)

-- 2009/01/05 H.Itou Add End

--

debug_cnt number default 0;

--

    -- *** サブプログラム ***

    --=========================

    -- キーブレイク処理

    --=========================

    PROCEDURE ins_temp_table(

        ov_errbuf     OUT NOCOPY VARCHAR2     --   エラー・メッセージ           --# 固定 #

      , ov_retcode    OUT NOCOPY VARCHAR2     --   リターン・コード             --# 固定 #

      , ov_errmsg     OUT NOCOPY VARCHAR2     --   ユーザー・エラー・メッセージ --# 固定 #

    )

    IS

      -- *** ローカル定数 ***

      cv_sub_prg_name   CONSTANT VARCHAR2(100) := '[ins_temp_table]'; -- サブプログラム名

--

    BEGIN

debug_log(FND_FILE.LOG,'B4_1.5【キーブレイク処理】');

--

            ----------------------------------------------------------------

            -- 自動配車集約中間テーブル用PL/SQL表にセット(1箇所目の配送先)

            ----------------------------------------------------------------

            -- インサートカウント

            ln_ins_cnt  :=  ln_ins_cnt + 1;

--

            -- 集約NO取得

            SELECT xxwsh_intensive_no_s1.NEXTVAL

            INTO   ln_intensive_no

            FROM   dual;

debug_log(FND_FILE.LOG,'B4_1.51 集約NO取得：'||ln_intensive_no);

--

            -- 自動配車集約中間テーブル用PL/SQL表にセット

            gt_int_no_tab(ln_ins_cnt)

                    := ln_intensive_no;                             -- 集約NO

            gt_tran_type_tab(ln_ins_cnt)

                    :=  lr_intensive_tmp.transaction_type;          -- 処理種別

            gt_int_source_tab(ln_ins_cnt)

                    :=  lr_intensive_tmp.intensive_source_no;       -- 集約元No

            gt_deli_from_tab(ln_ins_cnt)

                    :=  lr_intensive_tmp.deliver_from;              -- 配送元

            gt_deli_from_id_tab(ln_ins_cnt)

                    :=  lr_intensive_tmp.deliver_from_id;           -- 配送元ID

            gt_deli_to_tab(ln_ins_cnt)

                    :=  lr_intensive_tmp.deliver_to;                -- 配送先

            gt_deli_to_id_tab(ln_ins_cnt)

                    :=  lr_intensive_tmp.deliver_to_id;             -- 配送先ID

            gt_ship_date_tab(ln_ins_cnt)

                    :=  lr_intensive_tmp.schedule_ship_date;        -- 出庫予定日

            gt_arvl_date_tab(ln_ins_cnt)

                    :=  lr_intensive_tmp.schedule_arrival_date;     -- 着荷予定日

            gt_tran_type_nm_tab(ln_ins_cnt)

                    :=  lr_intensive_tmp.transaction_type_name;     -- 出庫形態

            gt_carrier_code_tab(ln_ins_cnt)

                    :=  lr_intensive_tmp.freight_carrier_code;      -- 運送業者

            gt_carrier_id_tab(ln_ins_cnt)

                    :=  lr_intensive_tmp.carrier_id;                -- 運送業者ID

            gt_sum_weight_tab(ln_ins_cnt)

                    :=  ln_sum_weight;                              -- 集約合計重量

            gt_sum_capa_tab(ln_ins_cnt)

                    :=  ln_sum_capacity;                            -- 集約合計容積

            gt_max_ship_cd_tab(ln_ins_cnt)

                    :=  lr_intensive_tmp.max_shipping_method_code;  -- 最大配送区分

            gt_weight_capa_tab(ln_ins_cnt)

                    :=  lr_intensive_tmp.weight_capacity_class;     -- 重量容積区分

            gt_max_weight_tab(ln_ins_cnt)

                    :=  lr_intensive_tmp.max_weight;                -- 最大積載重量

            gt_max_capa_tab(ln_ins_cnt)

                    :=  lr_intensive_tmp.max_capacity;              -- 最大積載容積

--

-- 2009/01/05 H.Itou Add Start 本番障害#879

            ----------------------------------------------------------------

            -- 自動配車集約中間テーブル用PL/SQL表にセット(2箇所目の配送先)

            ----------------------------------------------------------------

            -- インサートカウント

            ln_ins_cnt  :=  ln_ins_cnt + 1;

--

            -- 集約NO取得

            SELECT xxwsh_intensive_no_s1.NEXTVAL

            INTO   ln_intensive_no_2

            FROM   dual;

debug_log(FND_FILE.LOG,'B4_1.51 2箇所目の配送先の集約NO取得：'||ln_intensive_no_2);

--

            -- 自動配車集約中間テーブル用PL/SQL表にセット

            gt_int_no_tab(ln_ins_cnt)       := ln_intensive_no_2;                            -- 集約NO

            gt_tran_type_tab(ln_ins_cnt)    := lr_intensive_tmp_2.transaction_type;          -- 処理種別

            gt_int_source_tab(ln_ins_cnt)   := lr_intensive_tmp_2.intensive_source_no;       -- 集約元No

            gt_deli_from_tab(ln_ins_cnt)    := lr_intensive_tmp_2.deliver_from;              -- 配送元

            gt_deli_from_id_tab(ln_ins_cnt) := lr_intensive_tmp_2.deliver_from_id;           -- 配送元ID

            gt_deli_to_tab(ln_ins_cnt)      := lr_intensive_tmp_2.deliver_to;                -- 配送先

            gt_deli_to_id_tab(ln_ins_cnt)   := lr_intensive_tmp_2.deliver_to_id;             -- 配送先ID

            gt_ship_date_tab(ln_ins_cnt)    := lr_intensive_tmp_2.schedule_ship_date;        -- 出庫予定日

            gt_arvl_date_tab(ln_ins_cnt)    := lr_intensive_tmp_2.schedule_arrival_date;     -- 着荷予定日

            gt_tran_type_nm_tab(ln_ins_cnt) := lr_intensive_tmp_2.transaction_type_name;     -- 出庫形態

            gt_carrier_code_tab(ln_ins_cnt) := lr_intensive_tmp_2.freight_carrier_code;      -- 運送業者

            gt_carrier_id_tab(ln_ins_cnt)   := lr_intensive_tmp_2.carrier_id;                -- 運送業者ID

            gt_sum_weight_tab(ln_ins_cnt)   := ln_sum_weight_2;                              -- 集約合計重量

            gt_sum_capa_tab(ln_ins_cnt)     := ln_sum_capacity_2;                            -- 集約合計容積

            gt_max_ship_cd_tab(ln_ins_cnt)  := lr_intensive_tmp_2.max_shipping_method_code;  -- 最大配送区分

            gt_weight_capa_tab(ln_ins_cnt)  := lr_intensive_tmp_2.weight_capacity_class;     -- 重量容積区分

            gt_max_weight_tab(ln_ins_cnt)   := lr_intensive_tmp_2.max_weight;                -- 最大積載重量

            gt_max_capa_tab(ln_ins_cnt)     := lr_intensive_tmp_2.max_capacity;              -- 最大積載容積

-- 2009/01/05 H.Itou Add End

--

debug_log(FND_FILE.LOG,'(B-4)gt_sum_weight_tab：'||gt_sum_weight_tab(ln_ins_cnt));

--

debug_log(FND_FILE.LOG,'-------------------------------------');

debug_log(FND_FILE.LOG,'B4_1.52 明細テーブルデータ数：'||lt_request_no_tab.COUNT);

debug_log(FND_FILE.LOG,' 開始位置 ln_start_cnt：'||ln_start_cnt);

debug_log(FND_FILE.LOG,' 終了位置 ln_end_cnt：'  ||ln_end_cnt);

debug_log(FND_FILE.LOG,' 明細用登録カウントln_detail_ins_cnt：'||ln_detail_ins_cnt);

            -- 自動配車集約中間明細テーブル用PL/SQL表に格納

            <<set_lines_request_id_loop>>

            FOR loop_cnt IN ln_start_cnt..ln_end_cnt LOOP

--

              -- 明細用登録カウント

              ln_detail_ins_cnt := ln_detail_ins_cnt + 1;

debug_log(FND_FILE.LOG,'明細用登録カウント：'||ln_detail_ins_cnt);

--

              -- 集約NO

-- 2009/01/05 H.Itou Add Start 本番障害#879

              -- 1箇所目の配送先と同じ場合

              IF (lr_intensive_tmp.deliver_to = mixed_info_tab(loop_cnt).deliver_to) THEN

-- 2009/01/05 H.Itou Add End

                gt_int_no_lines_tab(ln_detail_ins_cnt) := ln_intensive_no;

-- 2009/01/05 H.Itou Add Start 本番障害#879

              -- 2箇所目の配送先と同じ場合

              ELSE

                gt_int_no_lines_tab(ln_detail_ins_cnt) := ln_intensive_no_2;

              END IF;

-- 2009/01/05 H.Itou Add End

--

              -- 依頼NO

              gt_request_no_tab(ln_detail_ins_cnt) := lt_request_no_tab(loop_cnt);

--20080519 D.Sugahara Add 不具合No3対応->

              -- トランザクションID（ソートテーブル更新用）

-- 2008/12/02 H.Itou Mod Start 本番障害#220 ソートテーブル更新トランザクションIDがずれているため修正。

--              lt_trans_id_tab(ln_detail_ins_cnt) := mixed_info_tab(ln_detail_ins_cnt).transaction_id;

              lt_trans_id_tab(ln_detail_ins_cnt) := mixed_info_tab(loop_cnt).transaction_id;

-- 2008/12/02 H.Itou Mod End

--20080519 D.Sugahara Add 不具合No3対応<-              

--

debug_log(FND_FILE.LOG,'集約NO：'||gt_int_no_lines_tab(ln_detail_ins_cnt));

debug_log(FND_FILE.LOG,'依頼NO：'||gt_request_no_tab(ln_detail_ins_cnt));

--

            END LOOP set_lines_request_id_loop;

--debug_log(FND_FILE.LOG,'自動配車集約中間明細PLSQLにセット');

/*for i in 1..gt_int_no_lines_tab.count loop

      debug_log(FND_FILE.LOG,'集約NO:'||gt_int_no_lines_tab(i));

      debug_log(FND_FILE.LOG,'依頼NO:'||gt_request_no_tab(i));

      debug_log(FND_FILE.LOG,'---------------------------------');

end loop;

*/

--debug_log(FND_FILE.LOG,'明細テーブル初期化');

    EXCEPTION

--

--#################################  固定例外処理部 START   ####################################

--

      -- *** 共通関数例外ハンドラ ***

      WHEN global_api_expt THEN

        ov_errmsg  := lv_errmsg;

        ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||cv_sub_prg_name||gv_msg_part||lv_errbuf,1,5000);

        ov_retcode := gv_status_error;

      -- *** 共通関数OTHERS例外ハンドラ ***

      WHEN global_api_others_expt THEN

        ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||cv_sub_prg_name||gv_msg_part||SQLERRM;

        ov_retcode := gv_status_error;

      -- *** OTHERS例外ハンドラ ***

      WHEN OTHERS THEN

        ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||cv_sub_prg_name||gv_msg_part||SQLERRM;

        ov_retcode := gv_status_error;

--

--#####################################  固定部 END   ##########################################

--

    END;

--

  BEGIN

--

--##################  固定ステータス初期化部 START   ###################

--

    ov_retcode := gv_status_normal;

--

--###########################  固定部 END   ############################

--

debug_log(FND_FILE.LOG,'-----------------------------------');

debug_log(FND_FILE.LOG,'B-4【拠点混載情報登録処理(B-4)】');

    -- 変数初期化

    lt_request_no_tab.DELETE;   -- 依頼No格納用テーブル

    lt_trans_id_tab.DELETE;     -- トランザクションID格納用

    gt_int_no_tab.DELETE;       -- 集約No

    gt_tran_type_tab.DELETE;    -- 処理種別

    gt_int_source_tab.DELETE;   -- 集約元No

    gt_deli_from_tab.DELETE;    -- 配送元

    gt_deli_from_id_tab.DELETE; -- 配送元ID

    gt_deli_to_tab.DELETE;      -- 配送先

    gt_deli_to_id_tab.DELETE;   -- 配送先ID

    gt_ship_date_tab.DELETE;    -- 出庫予定日

    gt_arvl_date_tab.DELETE;    -- 着荷予定日

    gt_tran_type_nm_tab.DELETE; -- 出庫形態

    gt_carrier_code_tab.DELETE; -- 運送業者

    gt_carrier_id_tab.DELETE;   -- 運送業者ID

    gt_sum_weight_tab.DELETE;   -- 集約合計重量

    gt_sum_capa_tab.DELETE;     -- 集約合計容積

    gt_max_ship_cd_tab.DELETE;  -- 最大配送区分

    gt_weight_capa_tab.DELETE;  -- 重量容積区分

    gt_max_weight_tab.DELETE;   -- 最大積載重量

    gt_max_capa_tab.DELETE;     -- 最大積載容積

    gt_base_weight_tab.DELETE;  -- 基本重量

    gt_base_capa_tab.DELETE;    -- 基本容積

    gt_int_no_lines_tab.DELETE; -- 集約No

    gt_request_no_tab.DELETE;   -- 依頼No

--

    -- ===============================

    -- 拠点混載集約処理

    -- ===============================

    -- 自動配車ソート用中間テーブル一括取得

    OPEN mixed_info_cur;

    FETCH mixed_info_cur BULK COLLECT INTO mixed_info_tab;

    CLOSE mixed_info_cur;

--

    IF (mixed_info_tab.COUNT > 0) THEN

      <<get_mixed_no_loop>>

      LOOP

--

debug_log(FND_FILE.LOG,'対象件数：'||mixed_info_tab.COUNT);

debug_cnt := debug_cnt + 1;

--

        -- ワークカウント

        ln_work_cnt := ln_work_cnt + 1;

        ln_grp_cnt  := ln_grp_cnt + 1;

--

debug_log(FND_FILE.LOG,'B4_1.0-----------------------------------');

debug_log(FND_FILE.LOG,' ワークカウント'||ln_work_cnt);

debug_log(FND_FILE.LOG,' グループカウント'||ln_grp_cnt);

debug_log(FND_FILE.LOG,'-----------------------------------');

--

        IF (ln_grp_cnt = 1) THEN

--

          -- 開始カウント確保

          ln_start_cnt := ln_work_cnt;

          -- 1レコード目格納(基準レコード)

--

debug_log(FND_FILE.LOG,'B4_1.1基準レコード設定');

          lr_intensive_tmp.transaction_type := gv_ship_type_ship;                     -- 処理種別

          lr_intensive_tmp.intensive_source_no := mixed_info_tab(ln_work_cnt).mixed_no;

                                                                                      -- 集約元No

          lr_intensive_tmp.schedule_ship_date :=  mixed_info_tab(ln_work_cnt).schedule_ship_date;

                                                                                      -- 出庫日

          lr_intensive_tmp.schedule_arrival_date := mixed_info_tab(ln_work_cnt).schedule_arrival_date;

                                                                                      -- 着荷日

          lr_intensive_tmp.freight_carrier_code := mixed_info_tab(ln_work_cnt).freight_carrier_code;

                                                                                      -- 運送業者

          lr_intensive_tmp.carrier_id := mixed_info_tab(ln_work_cnt).career_id;       -- 運送業者ID

          lr_intensive_tmp.deliver_to := mixed_info_tab(ln_work_cnt).deliver_to;      -- 配送先

          lr_intensive_tmp.deliver_to_id := mixed_info_tab(ln_work_cnt).deliver_to_id;-- 配送先ID

          lr_intensive_tmp.deliver_from := mixed_info_tab(ln_work_cnt).deliver_from;  -- 配送元

          lr_intensive_tmp.deliver_from_id := mixed_info_tab(ln_work_cnt).deliver_from_id;

                                                                                      -- 配送元ID

          lr_intensive_tmp.transaction_type_name := mixed_info_tab(ln_work_cnt).order_type_id;

                                                                                      -- 出庫形態

          lr_intensive_tmp.max_shipping_method_code := mixed_info_tab(ln_work_cnt).shipping_method_code;

                                                                                      -- 最大配送区分

          lr_intensive_tmp.weight_capacity_class := mixed_info_tab(ln_work_cnt).weight_capacity_class;

                                                                                      -- 重量容積区分

          lr_intensive_tmp.max_weight := mixed_info_tab(ln_work_cnt).based_weight;    -- 基本重量

          lr_intensive_tmp.max_capacity := mixed_info_tab(ln_work_cnt).based_capacity;-- 基本容積

--

          -- 比較用変数に格納

          lt_prev_mixed_no        :=  mixed_info_tab(ln_work_cnt).mixed_no;               -- 混載元

          lt_prev_ship_date       :=  mixed_info_tab(ln_work_cnt).schedule_ship_date;     -- 出庫日

          lt_prev_arrival_date    :=  mixed_info_tab(ln_work_cnt).schedule_arrival_date;  -- 着荷日

          lt_prev_freight_carrier :=  mixed_info_tab(ln_work_cnt).freight_carrier_code;   -- 運送業者

          lt_prev_ship_from       :=  mixed_info_tab(ln_work_cnt).deliver_from;           -- 出荷元

          lt_prev_ship_to         :=  mixed_info_tab(ln_work_cnt).deliver_to;             -- 出荷先

          lt_prev_order_type      :=  mixed_info_tab(ln_work_cnt).order_type_id;          -- 出庫形態

--

debug_log(FND_FILE.LOG,'  混載元：  '||lt_prev_mixed_no);

debug_log(FND_FILE.LOG,'  依頼No：  '||mixed_info_tab(ln_work_cnt).request_no);

debug_log(FND_FILE.LOG,'  出庫日：  '||lt_prev_ship_date);

debug_log(FND_FILE.LOG,'  着荷日：  '||lt_prev_arrival_date);

debug_log(FND_FILE.LOG,'  運送業者：'||lt_prev_freight_carrier);

debug_log(FND_FILE.LOG,'  出荷元：  '||lt_prev_ship_from);

debug_log(FND_FILE.LOG,'  出荷先：  '||lt_prev_ship_to);

debug_log(FND_FILE.LOG,'  出庫形態：'||lt_prev_order_type);

--

        END IF;

--

debug_log(FND_FILE.LOG,'B4_1.2比較データ-------');

debug_log(FND_FILE.LOG,'  混載元：'||mixed_info_tab(ln_work_cnt).mixed_no);

debug_log(FND_FILE.LOG,'  依頼No：'||mixed_info_tab(ln_work_cnt).request_no);

debug_log(FND_FILE.LOG,'  出庫日：'||mixed_info_tab(ln_work_cnt).schedule_ship_date);

debug_log(FND_FILE.LOG,'  着荷日：'||mixed_info_tab(ln_work_cnt).schedule_arrival_date);

debug_log(FND_FILE.LOG,'  運送業者：'||mixed_info_tab(ln_work_cnt).freight_carrier_code);

debug_log(FND_FILE.LOG,'  出荷元保管場所：'||mixed_info_tab(ln_work_cnt).deliver_from);

        -- キーブレイクしない

        IF ((lt_prev_mixed_no = mixed_info_tab(ln_work_cnt).mixed_no)                       -- 混載元No

          AND (lt_prev_ship_date = mixed_info_tab(ln_work_cnt).schedule_ship_date)          -- 出庫日

          AND (lt_prev_arrival_date = mixed_info_tab(ln_work_cnt).schedule_arrival_date)    -- 着荷日

          AND (lt_prev_freight_carrier = mixed_info_tab(ln_work_cnt).freight_carrier_code)  -- 運送業者

          AND (lt_prev_ship_from = mixed_info_tab(ln_work_cnt).deliver_from))               -- 出荷元保管場所

        THEN

--

debug_log(FND_FILE.LOG,'B4_1.3キーブレイクしない Req_No: '||mixed_info_tab(ln_work_cnt).request_no);

          --配送先同一（集約）

-- 2009/01/05 H.Itou Add Start 本番障害#879

--          IF (lt_prev_ship_to = mixed_info_tab(ln_work_cnt).deliver_to) THEN

          IF (lr_intensive_tmp.deliver_to = mixed_info_tab(ln_work_cnt).deliver_to) THEN

-- 2009/01/05 H.Itou Add End

--

debug_log(FND_FILE.LOG,'B4_1.31 配送先同一');

            -- 重量／容積集約

            IF (mixed_info_tab(ln_work_cnt).weight_capacity_class = gv_weight) THEN

--

                -- 重量

                ln_sum_weight := ln_sum_weight

                                + mixed_info_tab(ln_work_cnt).sum_weight          -- 積載重量合計

                                + mixed_info_tab(ln_work_cnt).sum_pallet_weight;  -- 合計パレット重量

--

            ELSE

--

                -- 容積

                ln_sum_capacity := ln_sum_capacity

                                  + mixed_info_tab(ln_work_cnt).sum_capacity;     -- 積載容積合計

--

            END IF;

--

          -- 配送先が異なる

-- 2009/01/05 H.Itou Add Start 本番障害#879

--          ELSIF (lt_prev_ship_to <> mixed_info_tab(ln_work_cnt).deliver_to) THEN -- 混載

          ELSIF (lr_intensive_tmp.deliver_to <> mixed_info_tab(ln_work_cnt).deliver_to) THEN -- 混載

-- 2009/01/05 H.Itou Add End

debug_log(FND_FILE.LOG,'B4_1.32 配送先異なる');

-- 2009/01/05 H.Itou Add Start 本番障害#879

            -- 2箇所目の配送先情報を設定

            IF (ln_mixed_cnt = 0) THEN

              lr_intensive_tmp_2.transaction_type         := gv_ship_type_ship;                                 -- 処理種別

              lr_intensive_tmp_2.intensive_source_no      := mixed_info_tab(ln_work_cnt).mixed_no;              -- 集約元No

              lr_intensive_tmp_2.schedule_ship_date       := mixed_info_tab(ln_work_cnt).schedule_ship_date;    -- 出庫日

              lr_intensive_tmp_2.schedule_arrival_date    := mixed_info_tab(ln_work_cnt).schedule_arrival_date; -- 着荷日

              lr_intensive_tmp_2.freight_carrier_code     := mixed_info_tab(ln_work_cnt).freight_carrier_code;  -- 運送業者

              lr_intensive_tmp_2.carrier_id               := mixed_info_tab(ln_work_cnt).career_id;             -- 運送業者ID

              lr_intensive_tmp_2.deliver_to               := mixed_info_tab(ln_work_cnt).deliver_to;            -- 配送先

              lr_intensive_tmp_2.deliver_to_id            := mixed_info_tab(ln_work_cnt).deliver_to_id;         -- 配送先ID

              lr_intensive_tmp_2.deliver_from             := mixed_info_tab(ln_work_cnt).deliver_from;          -- 配送元

              lr_intensive_tmp_2.deliver_from_id          := mixed_info_tab(ln_work_cnt).deliver_from_id;       -- 配送元ID

              lr_intensive_tmp_2.transaction_type_name    := mixed_info_tab(ln_work_cnt).order_type_id;         -- 出庫形態

              lr_intensive_tmp_2.max_shipping_method_code := mixed_info_tab(ln_work_cnt).shipping_method_code;  -- 最大配送区分

              lr_intensive_tmp_2.weight_capacity_class    := mixed_info_tab(ln_work_cnt).weight_capacity_class; -- 重量容積区分

              lr_intensive_tmp_2.max_weight               := mixed_info_tab(ln_work_cnt).based_weight;          -- 基本重量

              lr_intensive_tmp_2.max_capacity             := mixed_info_tab(ln_work_cnt).based_capacity;        -- 基本容積

            END IF;

-- 2009/01/05 H.Itou Add Start 本番障害#879

            -- 混載カウント

            ln_mixed_cnt := ln_mixed_cnt + 1;

debug_log(FND_FILE.LOG,'混載カウント：'||ln_mixed_cnt);

--

            -- 重量／容積集約

            IF (mixed_info_tab(ln_work_cnt).weight_capacity_class = gv_weight) THEN

--

              -- 重量

-- 2009/01/05 H.Itou Add Start 本番障害#879

              ln_sum_weight_2 := ln_sum_weight_2

-- 2009/01/05 H.Itou Add End

                              + mixed_info_tab(ln_work_cnt).sum_weight          -- 積載重量合計

                              + mixed_info_tab(ln_work_cnt).sum_pallet_weight;  -- 合計パレット重量

--

            ELSE

              -- 容積

-- 2009/01/05 H.Itou Add Start 本番障害#879

--              ln_sum_capacity := ln_sum_capacity + mixed_info_tab(ln_work_cnt).sum_capacity;

              ln_sum_capacity_2 := ln_sum_capacity_2 + mixed_info_tab(ln_work_cnt).sum_capacity;

-- 2009/01/05 H.Itou Add End

--

            END IF;

--

          END IF;

--

debug_log(FND_FILE.LOG,'重量合計(1箇所目の配送先)：'||ln_sum_weight);

debug_log(FND_FILE.LOG,'容積合計(1箇所目の配送先)：'||ln_sum_capacity);

debug_log(FND_FILE.LOG,'重量合計(2箇所目の配送先)：'||ln_sum_weight_2);

debug_log(FND_FILE.LOG,'容積合計(2箇所目の配送先)：'||ln_sum_capacity_2);

--20080519 D.Sugahara Del 不具合No3対応->

          -- トランザクションID（ソートテーブル更新用）

--          lt_trans_id_tab(ln_work_cnt) := mixed_info_tab(ln_work_cnt).transaction_id;

--20080519 D.Sugahara Del 不具合No3対応->

--

          -- 依頼No

          lt_request_no_tab(ln_work_cnt) := mixed_info_tab(ln_work_cnt).request_no;

--

          -- 現在の値を比較用変数にセットする

          lt_prev_mixed_no        :=  mixed_info_tab(ln_work_cnt).mixed_no;               -- 混載元

          lt_prev_ship_date       :=  mixed_info_tab(ln_work_cnt).schedule_ship_date;     -- 出庫日

          lt_prev_arrival_date    :=  mixed_info_tab(ln_work_cnt).schedule_arrival_date;  -- 着荷日

          lt_prev_freight_carrier :=  mixed_info_tab(ln_work_cnt).freight_carrier_code;   -- 運送業者

          lt_prev_ship_from       :=  mixed_info_tab(ln_work_cnt).deliver_from;           -- 出荷元

          lt_prev_ship_to         :=  mixed_info_tab(ln_work_cnt).deliver_to;             -- 出荷先

          lt_prev_order_type      :=  mixed_info_tab(ln_work_cnt).order_type_id;          -- 出庫形態

--

        -- キーブレイクしたか最終レコードの場合

        ELSE

debug_log(FND_FILE.LOG,'B4_1.4キーブレイクしたか最終レコードの場合');

--

          -- 混載の場合は、中間テーブルに登録用PL/SQL表にセット

          IF (ln_mixed_cnt > 0) THEN  -- 混載カウント

debug_log(FND_FILE.LOG,'混載カウントあり');

            -- 終了カウント確保

            ln_end_cnt := ln_work_cnt - 1;

--

debug_log(FND_FILE.LOG,'B4_1.41キーブレイク処理呼び出し');

            -- キーブレイク時処理

            ins_temp_table(

                  ov_errbuf     => lv_errbuf

                , ov_retcode    => lv_retcode

                , ov_errmsg     => lv_errmsg

            );

            IF (lv_retcode = gv_status_error) THEN

              RAISE global_api_expt;

            END IF;

--

debug_log(FND_FILE.LOG,'キーブレイク処理終了①');

--

          END IF;

          -- ワークテーブル用カウンタリセット(キーブレイク時のレコードを基準レコードにする）

          ln_work_cnt := ln_work_cnt - 1;

--

debug_log(FND_FILE.LOG,'ワークカウントリセット：'||ln_work_cnt);

--

          -- 混載カウントリセット

          ln_mixed_cnt := 0;

--

debug_log(FND_FILE.LOG,'混載カウントリセット：'||ln_mixed_cnt);

--

          -- グループカウントをリセット

          ln_grp_cnt := 0;

--

debug_log(FND_FILE.LOG,'グループカウントリセット：'||ln_grp_cnt);

--

          -- 集約値をリセット

          ln_sum_weight   := 0;

          ln_sum_capacity := 0;

-- 2009/01/05 H.Itou Add Start 本番障害#879

          ln_sum_weight_2   := 0;

          ln_sum_capacity_2 := 0;

-- 2009/01/05 H.Itou Add End

--

debug_log(FND_FILE.LOG,'集約値リセット');

--

        END IF;

--

debug_log(FND_FILE.LOG,'ln_work_cnt(終了?)：'|| ln_work_cnt);

--

        -- 終了処理

        IF ln_work_cnt >= mixed_info_tab.COUNT THEN

          -- 混載の場合は、中間テーブルに登録用PL/SQL表にセット

          IF (ln_mixed_cnt = 0) THEN

--

            lb_exit_flag := TRUE;

--

          ELSIF (ln_mixed_cnt > 0) THEN  -- 混載カウント

--

debug_log(FND_FILE.LOG,'終了処理');

            -- 終了カウント確保

            ln_end_cnt := ln_work_cnt;

--

            -- キーブレイク時処理

            ins_temp_table(

                  ov_errbuf     => lv_errbuf

                , ov_retcode    => lv_retcode

                , ov_errmsg     => lv_errmsg

            );

            IF (lv_retcode = gv_status_error) THEN

              RAISE global_api_expt;

            END IF;

--

debug_log(FND_FILE.LOG,'キーブレイク処理終了②');

--

            lb_exit_flag := TRUE;

--

          END IF;

--

        END IF;

--

        EXIT WHEN lb_exit_flag;

--@DS ループ保険必要？

      END LOOP get_mixed_no_loop;

--

--debug_log(FND_FILE.LOG,'中間テーブルPLSQLデータ数:'||gt_int_no_tab.count);

--

debug_log(FND_FILE.LOG,'★自動配車集約中間テーブル登録：拠点混載情報登録処理');

debug_log(FND_FILE.LOG,'登録数：'||gt_tran_type_tab.COUNT);

debug_log(FND_FILE.LOG,'PLSQL表：gt_tran_type_tab');

      -- ===============================

      -- 中間テーブル一括登録処理

      -- ===============================

      FORALL ln_cnt IN 1..gt_tran_type_tab.COUNT

        INSERT INTO xxwsh_intensive_carriers_tmp(   -- 自動配車集約中間テーブル

            intensive_no              -- 集約No

          , transaction_type          -- 処理種別

          , intensive_source_no       -- 集約元No

          , deliver_from              -- 配送元

          , deliver_from_id           -- 配送元ID

          , deliver_to                -- 配送先

          , deliver_to_id             -- 配送先ID

          , schedule_ship_date        -- 出庫予定日

          , schedule_arrival_date     -- 着荷予定日

          , transaction_type_name     -- 出庫形態

          , freight_carrier_code      -- 運送業者

          , carrier_id                -- 運送業者ID

          , intensive_sum_weight      -- 集約合計重量

          , intensive_sum_capacity    -- 集約合計容積

          , max_shipping_method_code  -- 最大配送区分

          , weight_capacity_class     -- 重量容積区分

          , max_weight                -- 最大積載重量

          , max_capacity              -- 最大積載容積

          )

          VALUES

          (

            gt_int_no_tab(ln_cnt)         -- 集約No

          , gt_tran_type_tab(ln_cnt)      -- 処理種別

          , gt_int_source_tab(ln_cnt)     -- 集約元No

          , gt_deli_from_tab(ln_cnt)      -- 配送元

          , gt_deli_from_id_tab(ln_cnt)   -- 配送元ID

          , gt_deli_to_tab(ln_cnt)        -- 配送先

          , gt_deli_to_id_tab(ln_cnt)     -- 配送先ID

          , gt_ship_date_tab(ln_cnt)      -- 出庫予定日

          , gt_arvl_date_tab(ln_cnt)      -- 着荷予定日

          , gt_tran_type_nm_tab(ln_cnt)   -- 出庫形態

          , gt_carrier_code_tab(ln_cnt)   -- 運送業者

          , gt_carrier_id_tab(ln_cnt)     -- 運送業者ID

          , gt_sum_weight_tab(ln_cnt)     -- 集約合計重量

          , gt_sum_capa_tab(ln_cnt)       -- 集約合計容積

          , gt_max_ship_cd_tab(ln_cnt)    -- 最大配送区分

          , gt_weight_capa_tab(ln_cnt)    -- 重量容積区分

          , gt_max_weight_tab(ln_cnt)     -- 最大積載重量

          , gt_max_capa_tab(ln_cnt)       -- 最大積載容積

          );

--

debug_log(FND_FILE.LOG,'自動配車集約中間テーブル登録数：'||gt_tran_type_tab.COUNT);

-------------------------------------------

/*for i in 1.. gt_tran_type_tab.count loop

      debug_log(FND_FILE.LOG,'集約NO:'||gt_int_no_tab(i));

      debug_log(FND_FILE.LOG,'処理種別:'||gt_tran_type_tab(i));

      debug_log(FND_FILE.LOG,'集約元No:'||gt_int_source_tab(i));

      debug_log(FND_FILE.LOG,'配送元:'||gt_deli_from_tab(i));

      debug_log(FND_FILE.LOG,'配送元ID:'||gt_deli_from_id_tab(i));

      debug_log(FND_FILE.LOG,'配送先:'||gt_deli_to_tab(i));

      debug_log(FND_FILE.LOG,'配送先ID:'||gt_deli_to_id_tab(i));

      debug_log(FND_FILE.LOG,'出庫予定日:'||gt_ship_date_tab(i));

      debug_log(FND_FILE.LOG,'着荷予定日:'||gt_arvl_date_tab(i));

      debug_log(FND_FILE.LOG,'出庫形態:'||gt_tran_type_nm_tab(i));

      debug_log(FND_FILE.LOG,'運送業者:'||gt_carrier_code_tab(i));

      debug_log(FND_FILE.LOG,'運送業者ID:'||gt_carrier_id_tab(i));

      debug_log(FND_FILE.LOG,'集約合計重量:'||gt_sum_weight_tab(i));

      debug_log(FND_FILE.LOG,'集約合計容積:'||gt_sum_capa_tab(i));

      debug_log(FND_FILE.LOG,'最大配送区分:'||gt_max_ship_cd_tab(i));

      debug_log(FND_FILE.LOG,'重量容積区分:'||gt_weight_capa_tab(i));

      debug_log(FND_FILE.LOG,'最大積載重量:'||gt_max_weight_tab(i));

      debug_log(FND_FILE.LOG,'最大積載容積:'||gt_max_capa_tab(i));

      debug_log(FND_FILE.LOG,'---------------------------------');

end loop;

*/

--------------------------------------------

debug_log(FND_FILE.LOG,'集約No数：'|| gt_int_no_lines_tab.COUNT);

debug_log(FND_FILE.LOG,'依頼No数：'|| gt_request_no_tab.COUNT);

debug_log(FND_FILE.LOG,'明細テーブル登録数：'||gt_request_no_tab.COUNT);

debug_log(FND_FILE.LOG,'PLSQL表：gt_request_no_tab');

      FORALL ln_cnt_2 IN 1..gt_request_no_tab.COUNT

        INSERT INTO xxwsh_intensive_carrier_ln_tmp(  -- 自動配車集約中間明細テーブル

            intensive_no

          , request_no

          )

          VALUES

          (

            gt_int_no_lines_tab(ln_cnt_2) -- 集約NO

          , gt_request_no_tab(ln_cnt_2)   -- 依頼NO

          );

debug_log(FND_FILE.LOG,'自動配車集約中間明細テーブル登録数：'|| gt_request_no_tab.COUNT);

--for i in 1..gt_request_no_tab.count loop

--debug_log(FND_FILE.LOG,'ループ内');

--      debug_log(FND_FILE.LOG,'集約NO:'||gt_int_no_lines_tab(i));

--      debug_log(FND_FILE.LOG,'依頼NO:'||gt_request_no_tab(i));

--      debug_log(FND_FILE.LOG,'---------------------------------');

--end loop;

--

      -- =================================

      -- 拠点混載登録済フラグ一括更新処理

      -- =================================

      FORALL ln_cnt_3 IN 1..lt_trans_id_tab.COUNT

        UPDATE xxwsh_carriers_sort_tmp                    -- 自動配車ソート用中間テーブル

          SET pre_saved_flg = cv_pre_save                 -- 拠点混載登録済フラグ

        WHERE transaction_id = lt_trans_id_tab(ln_cnt_3)  -- トランザクションID

        ;

debug_log(FND_FILE.LOG,'自動配車ソート用中間テーブル更新数：'|| lt_trans_id_tab.COUNT);

    END IF;

-- Ver1.5 M.Hokkanji Start

    debug_log(FND_FILE.LOG,'自動配車集約中間テーブル登録後コミット');

    COMMIT;

-- Ver1.5 M.Hokkanji End

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

  END ins_hub_mixed_info;

--

  /**********************************************************************************

   * Procedure Name   : chk_loading_efficiency

   * Description      : 積載効率チェック処理(B-5)

   ***********************************************************************************/

  PROCEDURE chk_loading_efficiency(

    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #

    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #

    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #

  IS

    -- ===============================

    -- 固定ローカル定数

    -- ===============================

    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_loading_efficiency'; -- プログラム名

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

    cv_pre_save     CONSTANT VARCHAR2(1) := '1';           -- 拠点混載登録：登録済

    cv_loading_over CONSTANT VARCHAR2(1) := '1';           -- 積載オーバー区分：オーバー

    cv_allocation   CONSTANT VARCHAR2(1) := '1';           -- 自動配車対象区分：対象

--

    -- *** ローカル変数 ***

    lv_loading_over_class       VARCHAR2(1);                          -- 積載オーバー区分

    lv_ship_methods             xxcmn_ship_methods.ship_method%TYPE;  -- 出荷方法

    ln_load_efficiency_weight   NUMBER;                               -- 重量積載効率

    ln_load_efficiency_capacity NUMBER;                               -- 容積積載効率

    lv_mixed_ship_method        VARCHAR2(2);                          -- 混載配送区分

    ln_err_cnt                  NUMBER DEFAULT 0;                     -- ループカウント

--

    -- *** ローカル・カーソル ***

    CURSOR mixed_info_cur IS

      SELECT  xcst.transaction_id                     -- トランザクションID

            , xcst.transaction_type                   -- 処理種別

            , xcst.request_no                         -- 出荷依頼NO

            , xcst.mixed_no                           -- 混載元NO

            , xcst.deliver_from                       -- 出荷元保管場所

            , xcst.deliver_from_id                    -- 出荷元ID

            , xcst.deliver_to                         -- 出荷先

            , xcst.deliver_to_id                      -- 出荷先ID

            , xcst.shipping_method_code               -- 配送区分

            , xcst.schedule_ship_date                 -- 出庫日

            , xcst.schedule_arrival_date              -- 着荷日

            , xcst.order_type_id                      -- 出庫形態

            , xcst.freight_carrier_code               -- 運送業者

            , xcst.career_id                          -- 運送業者ID

            , xcst.based_weight                       -- 基本重量

            , xcst.based_capacity                     -- 基本容積

            , xcst.sum_weight                         -- 積載重量合計

            , xcst.sum_capacity                       -- 積載容積合計

            , xcst.sum_pallet_weight                  -- 合計パレット重量

            , xcst.max_shipping_method_code           -- 最大配送区分

            , xcst.weight_capacity_class              -- 重量容積区分

            , DECODE(reserve_order, NULL, 99999, reserve_order)

                                                      -- 引当順

      FROM xxwsh_carriers_sort_tmp xcst               -- 自動配車ソート用中間テーブル

      WHERE xcst.transaction_type = gv_ship_type_ship -- 処理種別：出荷依頼

        AND xcst.mixed_no IS NOT NULL                 -- 混載元NO

      ORDER BY  xcst.schedule_ship_date          -- 出庫日

              , xcst.schedule_arrival_date       -- 着荷日

              , xcst.mixed_no                    -- 混載元NO

              , xcst.max_shipping_method_code    -- 最大配送区分

              , xcst.order_type_id               -- 出庫形態

              , xcst.deliver_from                -- 出荷元保管場所

              , xcst.freight_carrier_code        -- 運送業者

              , xcst.weight_capacity_class       -- 重量容積区分

              , xcst.reserve_order               -- 引当順

              , xcst.head_sales_branch           -- 管轄拠点

              , xcst.deliver_to                  -- 出荷先

              , DECODE (xcst.weight_capacity_class, gv_weight

                        , xcst.sum_weight             -- 集約重量合計

                        , xcst.sum_capacity) DESC     -- 集約合計容積

      ;

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

debug_log(FND_FILE.LOG,'【積載効率チェック処理(B-5)】');

    -- ==================================

    -- 積載効率チェック

    -- ==================================

    <<chk_efficiency_loop>>

    FOR rec_cnt IN mixed_info_cur LOOP

--

      -- 変数初期化

      lv_errmsg                   := NULL;

      lv_errbuf                   := NULL;

      lv_loading_over_class       := NULL;

      lv_ship_methods             := NULL;

      ln_load_efficiency_weight   := NULL;

      ln_load_efficiency_capacity := NULL;

      lv_mixed_ship_method        := NULL;

--

      -- 重量

      IF (rec_cnt.weight_capacity_class = gv_weight) THEN

--

debug_log(FND_FILE.LOG,'積載効率チェック：重量');

debug_log(FND_FILE.LOG,'-----------------------------------');

debug_log(FND_FILE.LOG,'合計重量:'||rec_cnt.sum_weight);

debug_log(FND_FILE.LOG,'合計容積:'||NULL);

debug_log(FND_FILE.LOG,'コード区分１:'||gv_cdkbn_storage);

debug_log(FND_FILE.LOG,'入出庫場所コード１:'||rec_cnt.deliver_from);

debug_log(FND_FILE.LOG,'コード区分２:'||gv_cdkbn_ship_to);

debug_log(FND_FILE.LOG,'入出庫場所コード２:'||rec_cnt.deliver_to);

debug_log(FND_FILE.LOG,'出荷方法:'||rec_cnt.shipping_method_code);

debug_log(FND_FILE.LOG,'商品区分:'||gv_prod_class);

debug_log(FND_FILE.LOG,'自動配車対象区分:'||cv_allocation);

debug_log(FND_FILE.LOG,'基準日(適用日基準日):'||TO_char(rec_cnt.schedule_ship_date,'yyyymmdd'));



--

        -- 共通関数：積載効率チェック(積載効率)

        xxwsh_common910_pkg.calc_load_efficiency(

            in_sum_weight                  => rec_cnt.sum_weight        -- 1.合計重量

          , in_sum_capacity                => NULL                      -- 2.合計容積

          , iv_code_class1                 => gv_cdkbn_storage          -- 3.コード区分１

          , iv_entering_despatching_code1  => rec_cnt.deliver_from      -- 4.入出庫場所コード１

          , iv_code_class2                 => gv_cdkbn_ship_to          -- 5.コード区分２

          , iv_entering_despatching_code2  => rec_cnt.deliver_to        -- 6.入出庫場所コード２

--          , iv_ship_method                 => rec_cnt.shipping_method_code --2008.05.16 D.sugahara

          , iv_ship_method                 => rec_cnt.max_shipping_method_code

                                                                        -- 7.出荷方法

          , iv_prod_class                  => gv_prod_class             -- 8.商品区分

          , iv_auto_process_type           => cv_allocation             -- 9.自動配車対象区分

          , id_standard_date               => rec_cnt.schedule_ship_date

                                                                        -- 10.基準日(適用日基準日)

          , ov_retcode                     => lv_retcode                -- 11.リターンコード

          , ov_errmsg_code                 => lv_errmsg                 -- 12.エラーメッセージコード

          , ov_errmsg                      => lv_errbuf                 -- 13.エラーメッセージ

          , ov_loading_over_class          => lv_loading_over_class     -- 14.積載オーバー区分

          , ov_ship_methods                => lv_ship_methods           -- 15.出荷方法

          , on_load_efficiency_weight      => ln_load_efficiency_weight -- 16.重量積載効率

          , on_load_efficiency_capacity    => ln_load_efficiency_capacity

                                                                        -- 17.容積積載効率

          , ov_mixed_ship_method           => lv_mixed_ship_method      -- 18.混載配送区分

        );

--



debug_log(FND_FILE.LOG,'リターンコード:'||lv_retcode);

debug_log(FND_FILE.LOG,'エラーメッセージコード:'||lv_errmsg);

debug_log(FND_FILE.LOG,'エラーメッセージ:'||lv_errbuf);

debug_log(FND_FILE.LOG,'積載オーバー区分:'||lv_loading_over_class);

debug_log(FND_FILE.LOG,'出荷方法:'||lv_ship_methods);

debug_log(FND_FILE.LOG,'重量積載効率:'||ln_load_efficiency_weight);

debug_log(FND_FILE.LOG,'容積積載効率:'||ln_load_efficiency_capacity);

debug_log(FND_FILE.LOG,'混載配送区分:'||lv_mixed_ship_method);



--

        -- 共通関数がエラーの場合

-- Ver1.7 M.Hokkanji START

        IF (lv_retcode <> gv_status_normal) THEN

--        IF (lv_retcode = gv_status_error) THEN

-- Ver1.16 2008/12/07 START

--          lv_errmsg := lv_errbuf;

        BEGIN

          lv_errmsg  :=  to_char(rec_cnt.sum_weight) -- 1.合計重量

                          || gv_msg_comma ||

                          NULL                -- 2.合計容積

                          || gv_msg_comma ||

                          gv_cdkbn_storage    -- 3.コード区分１

                          || gv_msg_comma ||

                          rec_cnt.deliver_from  -- 4.入出庫場所コード１

                          || gv_msg_comma ||

                          gv_cdkbn_ship_to      -- 5.コード区分２

                          || gv_msg_comma ||

                          rec_cnt.deliver_to    -- 6.入出庫場所コード２

                          || gv_msg_comma ||

                          rec_cnt.max_shipping_method_code -- 7.出荷方法

                          || gv_msg_comma ||

                          gv_prod_class       -- 8.商品区分

                          || gv_msg_comma ||

                          cv_allocation       -- 9.自動配車対象区分

                          || gv_msg_comma ||

                          TO_CHAR(rec_cnt.schedule_ship_date, 'YYYY/MM/DD'); -- 10.基準日

          lv_errmsg := lv_errmsg|| '(重量,容積,コード区分1,コード1,コード区分2,コード2';

          lv_errmsg := lv_errmsg|| ',配送区分,商品区分,自動配車対象区分,基準日'; -- msg

          lv_errmsg := lv_errmsg||lv_errbuf ;

        EXCEPTION

          WHEN OTHERS THEN

            lv_errmsg := lv_errbuf ;

        END;

-- Ver1.16 2008/12/07 END

-- Ver1.7 M.Hokkanji End

--

debug_log(FND_FILE.LOG,'関数エラー');

--

          RAISE global_api_expt;

        END IF;

--

        -- 積載オーバーの場合

        IF (lv_loading_over_class = cv_loading_over) THEN

--

          -- エラーカウント

          ln_err_cnt := ln_err_cnt + 1;

--

debug_log(FND_FILE.LOG,'積載オーバーカウント:'||ln_err_cnt);

--

          -- エラーメッセージ取得

          lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(

                        gv_xxwsh            -- モジュール名略称：XXWSH 出荷・引当/配車

                      , gv_msg_xxwsh_11803  -- メッセージ：APP-XXWSH-11803 積載オーバーメッセージ

                      , gv_tkn_req_no       -- トークン：REQ_NO

                      , rec_cnt.request_no  -- 出荷依頼No

                     ),1,5000);

--

          -- エラーメッセージ出力

          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);

debug_log(FND_FILE.LOG,'エラーメッセージ:'||lv_errmsg);

--

        END IF;

--

      -- 容積

      ELSE

--

        -- 共通関数：積載効率チェック(積載効率)

        xxwsh_common910_pkg.calc_load_efficiency(

            in_sum_weight                  => NULL                      -- 1.合計重量

          , in_sum_capacity                => rec_cnt.sum_capacity      -- 2.合計容積

          , iv_code_class1                 => gv_cdkbn_storage          -- 3.コード区分１

          , iv_entering_despatching_code1  => rec_cnt.deliver_from      -- 4.入出庫場所コード１

          , iv_code_class2                 => gv_cdkbn_ship_to          -- 5.コード区分２

          , iv_entering_despatching_code2  => rec_cnt.deliver_to        -- 6.入出庫場所コード２

--          , iv_ship_method                 => rec_cnt.shipping_method_code --2008.05.16 D.sugahara

          , iv_ship_method                 => rec_cnt.max_shipping_method_code

                                                                        -- 7.出荷方法

          , iv_prod_class                  => gv_prod_class             -- 8.商品区分

          , iv_auto_process_type           => cv_allocation             -- 9.自動配車対象区分

          , id_standard_date               => rec_cnt.schedule_ship_date

                                                                        -- 10.基準日(適用日基準日)

          , ov_retcode                     => lv_retcode                -- 11.リターンコード

          , ov_errmsg_code                 => lv_errmsg                 -- 12.エラーメッセージコード

          , ov_errmsg                      => lv_errbuf                 -- 13.エラーメッセージ

          , ov_loading_over_class          => lv_loading_over_class     -- 14.積載オーバー区分

          , ov_ship_methods                => lv_ship_methods           -- 15.出荷方法

          , on_load_efficiency_weight      => ln_load_efficiency_weight -- 16.重量積載効率

          , on_load_efficiency_capacity    => ln_load_efficiency_capacity

                                                                        -- 17.容積積載効率

          , ov_mixed_ship_method           => lv_mixed_ship_method      -- 18.混載配送区分

        );

        -- 共通関数がエラーの場合

-- Ver1.7 M.Hokkanji START

        IF (lv_retcode <> gv_status_normal) THEN

-- Ver1.16 2008/12/07 START

--          lv_errmsg := lv_errbuf;

--        IF (lv_retcode = gv_status_error) THEN

--          lv_errmsg := lv_errbuf;

        BEGIN

          lv_errmsg  :=  NULL -- 1.合計重量

                          || gv_msg_comma ||

                          rec_cnt.sum_capacity                -- 2.合計容積

                          || gv_msg_comma ||

                          gv_cdkbn_storage    -- 3.コード区分１

                          || gv_msg_comma ||

                          rec_cnt.deliver_from  -- 4.入出庫場所コード１

                          || gv_msg_comma ||

                          gv_cdkbn_ship_to      -- 5.コード区分２

                          || gv_msg_comma ||

                          rec_cnt.deliver_to    -- 6.入出庫場所コード２

                          || gv_msg_comma ||

                          rec_cnt.max_shipping_method_code -- 7.出荷方法

                          || gv_msg_comma ||

                          gv_prod_class       -- 8.商品区分

                          || gv_msg_comma ||

                          cv_allocation       -- 9.自動配車対象区分

                          || gv_msg_comma ||

                          TO_CHAR(rec_cnt.schedule_ship_date, 'YYYY/MM/DD'); -- 10.基準日

          lv_errmsg := lv_errmsg|| '(重量,容積,コード区分1,コード1,コード区分2,コード2';

          lv_errmsg := lv_errmsg|| ',配送区分,商品区分,自動配車対象区分,基準日'; -- msg

          lv_errmsg := lv_errmsg||lv_errbuf ;

        EXCEPTION

          WHEN OTHERS THEN

            lv_errmsg := lv_errbuf ;

        END;

-- Ver1.16 2008/12/07 End

-- Ver1.7 M.Hokkanji End

          RAISE global_api_expt;

        END IF;

--

        -- 積載オーバーの場合

        IF (lv_loading_over_class = cv_loading_over) THEN

--

          -- エラーカウント

          ln_err_cnt := ln_err_cnt + 1;

--

          -- エラーメッセージ取得

          lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(

                        gv_xxwsh            -- モジュール名略称：XXWSH 出荷・引当/配車

                      , gv_msg_xxwsh_11803  -- メッセージ：APP-XXWSH-11803 積載オーバーメッセージ

                      , gv_tkn_req_no       -- トークン：REQ_NO

                      , rec_cnt.request_no  -- 出荷依頼No

                     ),1,5000);

--

          -- エラーメッセージ出力

          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);

--

        END IF;

--

      END IF;

--

    END LOOP chk_efficiency_loop;

--

    -- ==================================

    -- エラー処理

    -- ==================================

    IF (ln_err_cnt > 0) THEN

      -- 積載オーバーが存在すればエラー

      RAISE global_api_expt;

    END IF;

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

  END chk_loading_efficiency;

--

  /**********************************************************************************

   * Procedure Name   : set_weight_capacity_add

   * Description      : 合計重量/容積取得 加算処理(B-7)

   ***********************************************************************************/

  PROCEDURE set_weight_capacity_add(

    it_group_sum_add_tab  IN  grp_sum_add_ttype,   -- 処理対象テーブル

    ov_errbuf             OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #

    ov_retcode            OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #

    ov_errmsg             OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #

  IS

    -- ===============================

    -- 固定ローカル定数

    -- ===============================

    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_weight_capacity_add'; -- プログラム名

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

    cv_finish_proc            CONSTANT VARCHAR2(1) := '1';  -- 集約済

    cv_over_loading           CONSTANT VARCHAR2(1) := '2';  -- 積載オーバー（配列用）

    cv_object                 CONSTANT VARCHAR2(1) := '1';  -- 自動配車対象

--20080517:DSugahara Add不具合1対応

    cv_loading_over CONSTANT VARCHAR2(1) := '1';            -- 関数用積載オーバー区分：オーバー    

--

    -- *** ローカル変数 ***

    -- 処理対象外PL/SQL表型

    TYPE over_loading_ttype IS TABLE OF VARCHAR2(1) INDEX BY BINARY_INTEGER;

--

    -- 積載効率オーバー対象格納用PL/SQL表

    lt_skip_process_tab       finish_sum_flag_ttype;

    -- 積載効率オーバーフラグ

    lb_over_loading           BOOLEAN DEFAULT FALSE;

--

    -- 比較用変数

    lt_prev_ship_date         xxwsh_carriers_sort_tmp.schedule_ship_date%TYPE;    -- 出庫日

    lt_prev_arrival_date      xxwsh_carriers_sort_tmp.schedule_arrival_date%TYPE; -- 着荷日

    lt_prev_order_type        xxwsh_carriers_sort_tmp.order_type_id%TYPE;         -- 出庫形態

    lt_prev_freight_carrier   xxwsh_carriers_sort_tmp.freight_carrier_code%TYPE;  -- 運送業者

    lt_prev_ship_from         xxwsh_carriers_sort_tmp.deliver_from%TYPE;          -- 出荷元

    lt_prev_ship_to           xxwsh_carriers_sort_tmp.deliver_to%TYPE;            -- 出荷先

    lt_prev_w_c_class         xxwsh_carriers_sort_tmp.weight_capacity_class%TYPE; -- 重量容積区分

    lt_prev_fin_proc          VARCHAR2(1);                                        -- 集約済フラグ

--

    lt_request_no_tab         req_mov_no_ttype;                               -- 依頼No設定用テーブル

    lt_trans_id_tab           transaction_id_ttype;                           -- トランザクションID

    ln_pre_reqno_cnt          NUMBER DEFAULT 0;                               -- 依頼No格納用カウント

    lb_last_data_flag         BOOLEAN DEFAULT FALSE;                          -- 最終レコードフラグ

    ln_ins_reqno_cnt          NUMBER DEFAULT 0;                               -- 依頼No格納用カウント

--

    -- グループ1件目のデータ格納用

    first_tran_type           xxwsh_carriers_sort_tmp.transaction_type%TYPE;      -- 処理種別

    first_req_no              xxwsh_carriers_sort_tmp.request_no%TYPE;            -- 依頼/指示No

    first_ship_date           xxwsh_carriers_sort_tmp.schedule_ship_date%TYPE;    -- 出庫日

    first_arrival_date        xxwsh_carriers_sort_tmp.schedule_arrival_date%TYPE; -- 着荷日

    first_order_type          xxwsh_carriers_sort_tmp.order_type_id%TYPE;         -- 出庫形態

    first_freight_carrier     xxwsh_carriers_sort_tmp.freight_carrier_code%TYPE;  -- 運送業者

    first_freight_carrier_id  xxwsh_carriers_sort_tmp.career_id%TYPE;             -- 運送業者ID

    first_ship_from           xxwsh_carriers_sort_tmp.deliver_from%TYPE;          -- 出荷元

    first_ship_from_id        xxwsh_carriers_sort_tmp.deliver_from_id%TYPE;       -- 出荷元ID

    first_ship_to             xxwsh_carriers_sort_tmp.deliver_to%TYPE;            -- 出荷先

    first_ship_to_id          xxwsh_carriers_sort_tmp.deliver_to_id%TYPE;         -- 出荷先ID

    first_w_c_class           xxwsh_carriers_sort_tmp.weight_capacity_class%TYPE; -- 重量容積区分

    first_head_sales          xxwsh_carriers_sort_tmp.head_sales_branch%TYPE;     -- 管轄拠点

    first_reserve_order       xxwsh_carriers_sort_tmp.reserve_order%TYPE;         -- 引当順

--

    ln_grp_sum_cnt            NUMBER DEFAULT 0;                               -- 集約グループカウント

    ln_ship_loop_cnt          NUMBER DEFAULT 0;                               -- ループカウント

    lv_grp_max_ship_methods   xxcmn_ship_methods.ship_method%TYPE;            -- group最大配送区分

    ln_drink_deadweight       xxcmn_ship_methods.drink_deadweight%TYPE;       -- ドリンク積載重量

    ln_leaf_deadweight        xxcmn_ship_methods.leaf_deadweight%TYPE;        -- リーフ積載重量

    ln_drink_loading_capacity xxcmn_ship_methods.drink_loading_capacity%TYPE; -- ドリンク積載容積

    ln_leaf_loading_capacity  xxcmn_ship_methods.leaf_loading_capacity%TYPE;  -- リーフ積載容積

    ln_palette_max_qty        xxcmn_ship_methods.palette_max_qty%TYPE;        -- パレット最大枚数

    return_cd                 VARCHAR2(1);                                    -- 共通関数戻り値

    ln_sum_weight             NUMBER DEFAULT 0;                               -- 集約重量

    ln_sum_capacity           NUMBER DEFAULT 0;                               -- 集約容積

    ln_sum_cnt                NUMBER DEFAULT 0;                               -- 集約済カウント

    ln_loop_cnt_1             NUMBER DEFAULT 0;                               -- ループカウント

    ln_err_cnt                NUMBER DEFAULT 0;                               -- エラーカウント

    lb_finish_proc            BOOLEAN DEFAULT FALSE;                          -- 処理済フラグ

    ln_start_no               NUMBER;                                         -- 集約開始No

    ln_end_no                 NUMBER;                                         -- 集約終了No

    ln_intensive_no           NUMBER;                                         -- 集約No

    lv_cdkbn_2                VARCHAR2(1);                                    -- コード区分２

    lv_rerun_flag             VARCHAR2(1) DEFAULT gv_off;                     -- 再実行フラグ

    ln_ins_cnt                NUMBER DEFAULT 0;                               -- インサートカウント

    ln_end_chk_cnt            NUMBER DEFAULT 0;                               -- 終了確認カウンタ

--20080517:DSugahara Add 不具合No1

    --積載効率チェック関数用

    lv_loading_over_class       VARCHAR2(1);                         -- 積載オーバー区分

    lv_ship_methods             xxcmn_ship_methods.ship_method%TYPE; -- 出荷方法

    ln_load_efficiency_weight   xxwsh_carriers_schedule.loading_efficiency_weight%TYPE;   -- 重量積載効率

    ln_load_efficiency_capacity xxwsh_carriers_schedule.loading_efficiency_capacity%TYPE; -- 容積積載効率

    lv_mixed_ship_method        xxcmn_ship_methods.ship_method%TYPE; -- 混載配送区分

--

--

    -- *** ローカル・カーソル ***

--

    -- *** ローカル・レコード ***

--

-- debug

exit_cnt number default 0;

debug_cnt number default 0;

    -- *** サブプログラム ***

    -- ==========================

    -- キーブレイク処理

    -- ==========================

    PROCEDURE lproc_keybrake_proc_B7(

        ov_errbuf     OUT NOCOPY VARCHAR2  -- エラー・メッセージ --# 固定 #

      , ov_retcode    OUT NOCOPY VARCHAR2  -- リターン・コード   --# 固定 #

      , ov_errmsg     OUT NOCOPY VARCHAR2  -- ユーザー・エラー・メッセージ --# 固定 #

    )

    IS

    -- *** ローカル定数 ***

      cv_sub_prg_name   CONSTANT VARCHAR2(100) := '[lproc_keybrake_proc_B7]'; -- サブプログラム名

--

    BEGIN

      -- ============================

      -- 基準レコード終了確認

      -- ============================

      -- キーブレイク時、基準レコードが未集約の場合、処理済とする

      IF (lt_skip_process_tab(ln_start_no) = 0) THEN

--

          -- 基準レコードを処理済とする

          lt_skip_process_tab(ln_start_no) := cv_finish_proc;

--

      END IF;

--

      -- ============================

      -- 登録用テーブルにセット

      -- ============================

      -- インサートカウント

      ln_ins_cnt := ln_ins_cnt + 1;

--

debug_log(FND_FILE.LOG,'B7_0.01 インサートカウント:'||ln_ins_cnt);

--

      -- 集約NO取得

      SELECT xxwsh_intensive_no_s1.NEXTVAL

      INTO   ln_intensive_no

      FROM   dual;

--

debug_log(FND_FILE.LOG,'B7_0.02 集約NO取得:'||ln_intensive_no);

--

      -- 自動配車集約中間テーブル登録用PL/SQL表にセット

      gt_int_no_tab(ln_ins_cnt)         :=  ln_intensive_no;          -- 集約NO

      gt_tran_type_tab(ln_ins_cnt)      :=  first_tran_type;          -- 処理種別

      gt_int_source_tab(ln_ins_cnt)     :=  first_req_no;             -- 集約元No：依頼No

      gt_deli_from_tab(ln_ins_cnt)      :=  first_ship_from;          -- 配送元

      gt_deli_from_id_tab(ln_ins_cnt)   :=  first_ship_from_id;       -- 配送元ID

      gt_deli_to_tab(ln_ins_cnt)        :=  first_ship_to;            -- 配送先

      gt_deli_to_id_tab(ln_ins_cnt)     :=  first_ship_to_id;         -- 配送先ID

      gt_ship_date_tab(ln_ins_cnt)      :=  first_ship_date;          -- 出庫予定日

      gt_arvl_date_tab(ln_ins_cnt)      :=  first_arrival_date;       -- 着荷予定日

      gt_tran_type_nm_tab(ln_ins_cnt)   :=  first_order_type;         -- 出庫形態

      gt_carrier_code_tab(ln_ins_cnt)   :=  first_freight_carrier;    -- 運送業者

      gt_carrier_id_tab(ln_ins_cnt)     :=  first_freight_carrier_id; -- 運送業者ID

      gt_sum_weight_tab(ln_ins_cnt)     :=  ln_sum_weight;            -- 集約合計重量

      gt_sum_capa_tab(ln_ins_cnt)       :=  ln_sum_capacity;          -- 集約合計容積

      gt_max_ship_cd_tab(ln_ins_cnt)    :=  lv_grp_max_ship_methods;  -- 最大配送区分

      gt_weight_capa_tab(ln_ins_cnt)    :=  first_w_c_class;          -- 重量容積区分

      gt_head_sales_tab(ln_ins_cnt)     :=  first_head_sales;         -- 管轄拠点

      gt_reserve_order_tab(ln_ins_cnt)  :=  first_reserve_order;      -- 引当順

--

debug_log(FND_FILE.LOG,'(B-7)gt_sum_weight_tab：'||gt_sum_weight_tab(ln_ins_cnt));

--

debug_log(FND_FILE.LOG,'B7_0.03 自動配車集約中間テーブル登録用PL/SQL表にセット');

--

      IF (gv_prod_class = gv_prod_cls_leaf) THEN

debug_log(FND_FILE.LOG,'B7_0.04 商品区分：リーフ');

        -- 商品区分：リーフ

        IF (first_w_c_class = gv_weight) THEN

--

          gt_max_weight_tab(ln_ins_cnt) := ln_leaf_deadweight;        -- 最大積載重量

          gt_max_capa_tab(ln_ins_cnt)   := NULL;                      -- 最大積載容積

        ELSE

--

          gt_max_weight_tab(ln_ins_cnt) := NULL;                      -- 最大積載重量

          gt_max_capa_tab(ln_ins_cnt)   := ln_leaf_loading_capacity;  -- 最大積載容積

        END IF;

--

      ELSE

debug_log(FND_FILE.LOG,'B7_0.05 商品区分：ドリンク');

        -- 商品区分：ドリンク

        IF (first_w_c_class = gv_weight) THEN

--

          gt_max_weight_tab(ln_ins_cnt) := ln_drink_deadweight;       -- 最大積載重量

          gt_max_capa_tab(ln_ins_cnt)   := NULL;                      -- 最大積載容積

--

        ELSE

--

          gt_max_weight_tab(ln_ins_cnt) := NULL;                      -- 最大積載重量

          gt_max_capa_tab(ln_ins_cnt)   := ln_drink_loading_capacity; -- 最大積載容積

--

        END IF;

--

      END IF;

--

        -- 自動配車集約中間明細テーブル用PL/SQL表に格納

debug_log(FND_FILE.LOG,'B7_0.06 自動配車集約中間明細テーブル用PL/SQL表に格納');

--debug_log(FND_FILE.LOG,'データ数：'|| lt_request_no_tab.COUNT);

--debug_log(FND_FILE.LOG,'ln_loop_cnt_1：'|| ln_loop_cnt_1);

      -- =============================================

      -- 自動配車集約中間明細テーブル用PL/SQL表に格納

      -- =============================================

      <<set_lines_request_id_loop>>

      FOR loop_cnt IN 1..lt_request_no_tab.COUNT LOOP

--

        ln_ins_reqno_cnt := ln_ins_reqno_cnt + 1;

        -- 集約NO

        gt_int_no_lines_tab(ln_ins_reqno_cnt) := ln_intensive_no;

--

        -- 依頼NO

        gt_request_no_tab(ln_ins_reqno_cnt) := lt_request_no_tab(loop_cnt);

debug_log(FND_FILE.LOG,'B7_0.07 依頼NO：'|| gt_request_no_tab(loop_cnt));

--

      END LOOP set_lines_request_id_loop;

--

      -- 集約合計重量、集約合計容積をリセット

      ln_sum_weight   := 0;

      ln_sum_capacity := 0;

--

      -- 依頼No設定用テーブル、カウンタをリセット

      lt_request_no_tab.DELETE;

      ln_pre_reqno_cnt := 0;

--

--debug_log(FND_FILE.LOG,'集約合計重量、集約合計容積をリセット');

--

--debug_log(FND_FILE.LOG,'ln_start_no:'||ln_start_no);

--debug_log(FND_FILE.LOG,'ln_end_no:'||ln_end_no);

--

      -- グループの全データが集約したか確認

      <<finish_chk_loop>>

      FOR ln_cnt IN ln_start_no..ln_end_no LOOP

--

debug_log(FND_FILE.LOG,'B7_0.08 グループの全データが集約したか確認');

--

        -- 未集約のデータがあった場合は、再度、処理する

        IF (lt_skip_process_tab(ln_cnt) = 0) THEN

--

debug_log(FND_FILE.LOG,'B7_0.09 再度処理：再実行フラグON');

--

          -- ループカウントに集約開始Noをセットする

          ln_loop_cnt_1 := ln_start_no;

          -- 再実行フラグ：ON

          lv_rerun_flag := gv_on;

--

debug_log(FND_FILE.LOG,'B7_0.10 Exit finish_chk_loop');

          EXIT;

--

        END IF;

--

      END LOOP finish_chk_loop;

--

    EXCEPTION

      -- *** 共通関数例外ハンドラ ***

      WHEN global_api_expt THEN

debug_log(FND_FILE.LOG,'B7_0.11 global_api_expt');

        ov_errmsg  := lv_errmsg;

        ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||cv_sub_prg_name||gv_msg_part||lv_errbuf,1,5000);

        ov_retcode := gv_status_error;

      -- *** 共通関数OTHERS例外ハンドラ ***

      WHEN global_api_others_expt THEN

debug_log(FND_FILE.LOG,'B7_0.12 global_api_others_expt');

        ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||cv_sub_prg_name||gv_msg_part||SQLERRM;

        ov_retcode := gv_status_error;

      -- *** OTHERS例外ハンドラ ***

      WHEN OTHERS THEN

debug_log(FND_FILE.LOG,'B7_0.13 OTHERS');

        ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||cv_sub_prg_name||gv_msg_part||SQLERRM;

        ov_retcode := gv_status_error;

--

    END lproc_keybrake_proc_B7;

--

  BEGIN

--

--##################  固定ステータス初期化部 START   ###################

--

    ov_retcode := gv_status_normal;

--

--###########################  固定部 END   ############################

--

debug_log(FND_FILE.LOG,'【合計重量/容積取得 加算処理(B-7)】');

--

    -- 変数初期化

    lt_request_no_tab.DELETE;       -- 依頼No格納用テーブル

    lt_trans_id_tab.DELETE;         -- トランザクションID格納用

    gt_int_no_tab.DELETE;           -- 集約No

    gt_tran_type_tab.DELETE;        -- 処理種別

    gt_int_source_tab.DELETE;       -- 集約元No

    gt_deli_from_tab.DELETE;        -- 配送元

    gt_deli_from_id_tab.DELETE;     -- 配送元ID

    gt_deli_to_tab.DELETE;          -- 配送先

    gt_deli_to_id_tab.DELETE;       -- 配送先ID

    gt_ship_date_tab.DELETE;        -- 出庫予定日

    gt_arvl_date_tab.DELETE;        -- 着荷予定日

    gt_tran_type_nm_tab.DELETE;     -- 出庫形態

    gt_carrier_code_tab.DELETE;     -- 運送業者

    gt_carrier_id_tab.DELETE;       -- 運送業者ID

    gt_sum_weight_tab.DELETE;       -- 集約合計重量

    gt_sum_capa_tab.DELETE;         -- 集約合計容積

    gt_max_ship_cd_tab.DELETE;      -- 最大配送区分

    gt_weight_capa_tab.DELETE;      -- 重量容積区分

    gt_max_weight_tab.DELETE;       -- 最大積載重量

    gt_max_capa_tab.DELETE;         -- 最大積載容積

    gt_base_weight_tab.DELETE;      -- 基本重量

    gt_base_capa_tab.DELETE;        -- 基本容積

    gt_reserve_order_tab.DELETE;    -- 引当順

    gt_head_sales_tab.DELETE;       -- 管轄拠点

    gt_pre_saved_flg_tab.DELETE;    -- 拠点混載登録済フラグ

    lt_skip_process_tab.DELETE;     -- 処理対象外(処理済:1、積載効率オーバー:2)

    gt_int_no_lines_tab.DELETE;     -- 集約No(明細用)

    gt_request_no_tab.DELETE;       -- 依頼No(明細用)

--

debug_log(FND_FILE.LOG,'B7_1.01 処理件数：'||it_group_sum_add_tab.COUNT);

    -- 処理対象外テーブルの初期化

    IF (it_group_sum_add_tab.COUNT > 0) THEN

debug_log(FND_FILE.LOG,'B7_1.02 処理対象外テーブルの初期化P');

      FOR loop_cnt IN 1..it_group_sum_add_tab.COUNT LOOP

        lt_skip_process_tab(loop_cnt) := 0;

      END LOOP;

--

    END IF;

--

debug_log(FND_FILE.LOG,'loop begin');

debug_log(FND_FILE.LOG,'ln_sum_weight:'|| ln_sum_weight);

--

    <<get_max_ship_cd>>

    LOOP

      -- ループカウント

      ln_loop_cnt_1 := ln_loop_cnt_1 + 1;

--

debug_log(FND_FILE.LOG,'B7_1.03 get_max_ship_cd LOOP');

debug_log(FND_FILE.LOG,'----------------------------------------');

debug_log(FND_FILE.LOG,'ループカウント:'|| ln_loop_cnt_1);

--

--debug_log(FND_FILE.LOG,'依頼No：'|| it_group_sum_add_tab(ln_loop_cnt_1).req_mov_no);

--debug_log(FND_FILE.LOG,'処理対象外フラグ：'|| lt_skip_process_tab(ln_loop_cnt_1));

      -- 未処理で積載効率オーバーしていないデータのみ処理

      IF (lt_skip_process_tab(ln_loop_cnt_1) = 0) THEN

--

debug_log(FND_FILE.LOG,'B7_1.04 未処理で積載効率オーバーしていないデータのみ処理');

debug_log(FND_FILE.LOG,'依頼No：'|| it_group_sum_add_tab(ln_loop_cnt_1).req_mov_no);

--debug_log(FND_FILE.LOG,'処理対象');

--

        -- グループカウント

        ln_grp_sum_cnt := ln_grp_sum_cnt + 1;

debug_log(FND_FILE.LOG,'グループカウント：'||ln_grp_sum_cnt);

--

        -- 1件目の最大配送区分を取得する

        IF (ln_grp_sum_cnt = 1) THEN

debug_log(FND_FILE.LOG,'B7_1.05 1件目の最大配送区分を取得する');

--

--debug_log(FND_FILE.LOG,'1件目の最大配送区分取得');

--

          -- スタートNOを格納

          ln_start_no := ln_loop_cnt_1;

--debug_log(FND_FILE.LOG,'スタートNO確保：'|| ln_start_no);

--

          -- コード区分２設定

          IF (it_group_sum_add_tab(ln_loop_cnt_1).tran_type = gv_ship_type_ship) THEN -- 出荷依頼

            lv_cdkbn_2  :=  gv_cdkbn_ship_to; -- 配送先

          ELSE

            lv_cdkbn_2  :=  gv_cdkbn_storage; -- 倉庫

          END IF;

--

debug_log(FND_FILE.LOG,'B7_1.06 最大配送区分算出関数Call');

debug_log(FND_FILE.LOG,'コード区分1:'||gv_cdkbn_storage);

debug_log(FND_FILE.LOG,'入出庫場所1:'||it_group_sum_add_tab(ln_loop_cnt_1).ship_from);

debug_log(FND_FILE.LOG,'コード区分2:'||lv_cdkbn_2);

debug_log(FND_FILE.LOG,'入出庫場所2:'||it_group_sum_add_tab(ln_loop_cnt_1).ship_to);

debug_log(FND_FILE.LOG,'商品区分:'||gv_prod_class);

debug_log(FND_FILE.LOG,'重量容積区分:'||it_group_sum_add_tab(ln_loop_cnt_1).weight_capacity_cls);

debug_log(FND_FILE.LOG,'自動配車対象区分:'||cv_object);

debug_log(FND_FILE.LOG,'基準日:'||to_char(it_group_sum_add_tab(ln_loop_cnt_1).ship_date,'YYYYMMDD'));

--

          -- 共通関数：最大配送区分算出関数

          return_cd := xxwsh_common_pkg.get_max_ship_method(

                      iv_code_class1                => gv_cdkbn_storage,          -- コード区分1

                      iv_entering_despatching_code1 => it_group_sum_add_tab(ln_loop_cnt_1).ship_from,

                                                                                  -- 入出庫場所1

                      iv_code_class2                => lv_cdkbn_2,                -- コード区分2

                      iv_entering_despatching_code2 => it_group_sum_add_tab(ln_loop_cnt_1).ship_to,

                                                                                  -- 入出庫場所2

                      iv_prod_class                 => gv_prod_class,             -- 商品区分

                      iv_weight_capacity_class      => it_group_sum_add_tab(ln_loop_cnt_1).weight_capacity_cls,                      -- 重量容積区分

                      iv_auto_process_type          => cv_object,                 -- 自動配車対象区分

                      id_standard_date              => it_group_sum_add_tab(ln_loop_cnt_1).ship_date,

                                                                                  -- 基準日

                      ov_max_ship_methods           => lv_grp_max_ship_methods,   -- 最大配送区分

                      on_drink_deadweight           => ln_drink_deadweight,       -- ドリンク積載重量

                      on_leaf_deadweight            => ln_leaf_deadweight,        -- リーフ積載重量

                      on_drink_loading_capacity     => ln_drink_loading_capacity, -- ドリンク積載容積

                      on_leaf_loading_capacity      => ln_leaf_loading_capacity,  -- リーフ積載容積

                      on_palette_max_qty            => ln_palette_max_qty         -- パレット最大枚数

                      );

--

debug_log(FND_FILE.LOG,'最大配送区分:'||lv_grp_max_ship_methods);

debug_log(FND_FILE.LOG,'ドリンク積載重量:'||ln_drink_deadweight);

debug_log(FND_FILE.LOG,'リーフ積載重量:'||ln_leaf_deadweight);

debug_log(FND_FILE.LOG,'ドリンク積載容積:'||ln_drink_loading_capacity);

debug_log(FND_FILE.LOG,'リーフ積載容積:'||ln_leaf_loading_capacity);

debug_log(FND_FILE.LOG,'パレット最大枚数:'||ln_palette_max_qty);

--

          IF  (return_cd = gv_error)

            OR (lv_grp_max_ship_methods IS NULL)

          THEN

--

debug_log(FND_FILE.LOG,'B7_1.07 最大配送区分算出関数例外');

            -- エラーメッセージ取得

            lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(

                           gv_xxwsh                      -- モジュール名略称：XXWSH 出荷・引当/配車

                         , gv_msg_xxwsh_11802            -- 最大配送区分取得エラー

                         , gv_tkn_from                   -- トークン'FROM'

                         , it_group_sum_add_tab(ln_loop_cnt_1).ship_from

                                                         -- 入出庫場所1

                         , gv_tkn_to                     -- トークン'TO'

                         , it_group_sum_add_tab(ln_loop_cnt_1).ship_to

                                                        -- 入出庫場所2

                         , gv_tkn_codekbn1               -- トークン'CODEKBN1'

                         , gv_cdkbn_storage              -- コード区分1

                         , gv_tkn_codekbn2               -- トークン'CODEKBN2'

                         , gv_cdkbn_ship_to              -- コード区分2

                        ) ,1 ,5000);

--

             RAISE global_api_expt;

--

          END IF;

--debug_log(FND_FILE.LOG,'最大配送区分取得：'|| lv_grp_max_ship_methods);

--

          -- グループ1件目データを保持

          first_tran_type           := it_group_sum_add_tab(ln_loop_cnt_1).tran_type;

                                                                                -- 処理種別

          first_req_no              := it_group_sum_add_tab(ln_loop_cnt_1).req_mov_no;

                                                                                -- 依頼No/指示No

          first_ship_date           := it_group_sum_add_tab(ln_loop_cnt_1).ship_date;

                                                                                -- 出庫日

          first_arrival_date        := it_group_sum_add_tab(ln_loop_cnt_1).arrival_date;

                                                                                -- 着荷日

          first_order_type          := it_group_sum_add_tab(ln_loop_cnt_1).order_type_id;

                                                                                -- 出庫形態

          first_freight_carrier     := it_group_sum_add_tab(ln_loop_cnt_1).carrier_code;

                                                                                -- 配送業者

          first_freight_carrier_id  := it_group_sum_add_tab(ln_loop_cnt_1).carrier_id;

                                                                                -- 配送業者ID

          first_ship_from           := it_group_sum_add_tab(ln_loop_cnt_1).ship_from;

                                                                                -- 出荷元

          first_ship_from_id        := it_group_sum_add_tab(ln_loop_cnt_1).ship_from_id;

                                                                                -- 出荷元ID

          first_ship_to             := it_group_sum_add_tab(ln_loop_cnt_1).ship_to;

                                                                                -- 出荷先

          first_ship_to_id          := it_group_sum_add_tab(ln_loop_cnt_1).ship_to_id;

                                                                                -- 出荷先ID

          first_w_c_class           := it_group_sum_add_tab(ln_loop_cnt_1).weight_capacity_cls;

                                                                                -- 重量容積区分

          first_head_sales          := it_group_sum_add_tab(ln_loop_cnt_1).head_sales_branch;

                                                                                -- 管轄拠点

          first_reserve_order       := it_group_sum_add_tab(ln_loop_cnt_1).reserve_order;

                                                                                -- 引当順

--

          -- 比較用変数に格納

          lt_prev_ship_date       := it_group_sum_add_tab(ln_loop_cnt_1).ship_date; -- 出庫日

          lt_prev_arrival_date    := it_group_sum_add_tab(ln_loop_cnt_1).arrival_date;

                                                                                    -- 着荷日

          lt_prev_order_type      := it_group_sum_add_tab(ln_loop_cnt_1).order_type_id;

                                                                                    -- 出庫形態

          lt_prev_freight_carrier := it_group_sum_add_tab(ln_loop_cnt_1).carrier_code;

                                                                                    -- 配送業者

          lt_prev_ship_from       := it_group_sum_add_tab(ln_loop_cnt_1).ship_from; -- 出荷元

          lt_prev_ship_to         := it_group_sum_add_tab(ln_loop_cnt_1).ship_to;   -- 出荷先

          lt_prev_w_c_class       := it_group_sum_add_tab(ln_loop_cnt_1).weight_capacity_cls;

                                                                                    -- 重量容積区分

debug_log(FND_FILE.LOG,'B7_1.08 基準レコード保持');

--

        END IF;

--

debug_log(FND_FILE.LOG,'B7_1.09 キーブレイクしない 前');

        -- キーブレイクしない

        IF  (lt_prev_ship_date       = it_group_sum_add_tab(ln_loop_cnt_1).ship_date)

                                                                                  -- 出庫日

          AND (lt_prev_arrival_date    = it_group_sum_add_tab(ln_loop_cnt_1).arrival_date)

                                                                                  -- 着荷日

          AND (NVL(lt_prev_order_type,0)      = NVL(it_group_sum_add_tab(ln_loop_cnt_1).order_type_id, 0))

                                                                                  -- 出庫形態

          AND (NVL(lt_prev_freight_carrier,0) = NVL(it_group_sum_add_tab(ln_loop_cnt_1).carrier_code, 0))

                                                                                  -- 配送業者

          AND (NVL(lt_prev_ship_from,0)       = NVL(it_group_sum_add_tab(ln_loop_cnt_1).ship_from, 0))

                                                                                  -- 出荷元

          AND (NVL(lt_prev_ship_to,0)         = NVL(it_group_sum_add_tab(ln_loop_cnt_1).ship_to, 0))

                                                                                  -- 出荷先

          AND (NVL(lt_prev_w_c_class,0)       = NVL(it_group_sum_add_tab(ln_loop_cnt_1).weight_capacity_cls, 0))

                                                                                  -- 重量容積区分

        THEN

--

debug_log(FND_FILE.LOG,'B7_1.10 キーブレイクなし');

          --========================================

          -- 積載効率オーバーチェック(移動指示のみ)

          --========================================

          IF (it_group_sum_add_tab(ln_loop_cnt_1).tran_type = gv_ship_type_move) THEN -- 移動指示

--

debug_log(FND_FILE.LOG,'B7_1.11 積載効率オーバーチェック(移動指示のみ)');

--

            -- 重量の場合

            IF (it_group_sum_add_tab(ln_loop_cnt_1).weight_capacity_cls = gv_weight) THEN

--

--20080517:DSugahara 不具合No1対応->

--              IF (it_group_sum_add_tab(ln_loop_cnt_1).based_weight <  -- 基本重量

--                  it_group_sum_add_tab(ln_loop_cnt_1).sum_weight)     -- 積載重量合計

--              THEN

              -- 共通関数：積載効率チェック(積載効率)

              xxwsh_common910_pkg.calc_load_efficiency(

                  in_sum_weight                  => 

                        it_group_sum_add_tab(ln_loop_cnt_1).sum_weight        -- 1.合計重量

                , in_sum_capacity                => NULL                      -- 2.合計容積

                , iv_code_class1                 => gv_cdkbn_storage          -- 3.コード区分１

                , iv_entering_despatching_code1  => 

                        it_group_sum_add_tab(ln_loop_cnt_1).ship_from         -- 4.入出庫場所コード１

                , iv_code_class2                 => lv_cdkbn_2                -- 5.コード区分２

                , iv_entering_despatching_code2  => 

                        it_group_sum_add_tab(ln_loop_cnt_1).ship_to           -- 6.入出庫場所コード２

                , iv_ship_method                 => 

                        it_group_sum_add_tab(ln_loop_cnt_1).max_shipping_method -- 7.出荷方法

                , iv_prod_class                  => gv_prod_class             -- 8.商品区分

                , iv_auto_process_type           => cv_object                 -- 9.自動配車対象区分

                , id_standard_date               => 

                        it_group_sum_add_tab(ln_loop_cnt_1).ship_date         -- 10.基準日(適用日基準日)

                , ov_retcode                     => lv_retcode                -- 11.リターンコード

                , ov_errmsg_code                 => lv_errmsg                 -- 12.エラーメッセージコード

                , ov_errmsg                      => lv_errbuf                 -- 13.エラーメッセージ

                , ov_loading_over_class          => lv_loading_over_class     -- 14.積載オーバー区分

                , ov_ship_methods                => lv_ship_methods           -- 15.出荷方法

                , on_load_efficiency_weight      => ln_load_efficiency_weight -- 16.重量積載効率

                , on_load_efficiency_capacity    => ln_load_efficiency_capacity

                                                                              -- 17.容積積載効率

                , ov_mixed_ship_method           => lv_mixed_ship_method      -- 18.混載配送区分

              );

              -- 共通関数がエラーの場合

-- Ver1.7 M.Hokkanji START

              IF (lv_retcode <> gv_status_normal) THEN

--              IF (lv_retcode = gv_status_error) THEN

-- Ver1.16 2008/12/07 START

--          lv_errmsg := lv_errbuf;

--        IF (lv_retcode = gv_status_error) THEN

--          lv_errmsg := lv_errbuf;

        BEGIN

          lv_errmsg  :=  it_group_sum_add_tab(ln_loop_cnt_1).sum_weight -- 1.合計重量

                          || gv_msg_comma ||

                          NULL                -- 2.合計容積

                          || gv_msg_comma ||

                          gv_cdkbn_storage    -- 3.コード区分１

                          || gv_msg_comma ||

                          it_group_sum_add_tab(ln_loop_cnt_1).ship_from  -- 4.入出庫場所コード１

                          || gv_msg_comma ||

                          lv_cdkbn_2      -- 5.コード区分２

                          || gv_msg_comma ||

                          it_group_sum_add_tab(ln_loop_cnt_1).ship_to    -- 6.入出庫場所コード２

                          || gv_msg_comma ||

                          it_group_sum_add_tab(ln_loop_cnt_1).max_shipping_method -- 7.出荷方法

                          || gv_msg_comma ||

                          gv_prod_class       -- 8.商品区分

                          || gv_msg_comma ||

                          cv_object       -- 9.自動配車対象区分

                          || gv_msg_comma ||

                          TO_CHAR(it_group_sum_add_tab(ln_loop_cnt_1).ship_date, 'YYYY/MM/DD'); -- 10.基準日

          lv_errmsg := lv_errmsg|| '(重量,容積,コード区分1,コード1,コード区分2,コード2';

          lv_errmsg := lv_errmsg|| ',配送区分,商品区分,自動配車対象区分,基準日'; -- msg

          lv_errmsg := lv_errbuf ;

        EXCEPTION

          WHEN OTHERS THEN

            lv_errmsg := lv_errbuf ;

        END;

-- Ver1.16 2008/12/07 End

-- Ver1.7 M.Hokkanji End

debug_log(FND_FILE.LOG,'B7_1.111　移動積載効率オーバーチェック関数エラー(重量)');

                RAISE global_api_expt;

              END IF;

--

              -- 積載オーバーの場合

              IF (lv_loading_over_class = cv_loading_over) THEN

--20080517:DSugahara 不具合No1対応<-

--

                ln_err_cnt := ln_err_cnt + 1;

--

                -- 処理対象外テーブルに積載オーバーを設定

                lt_skip_process_tab(ln_loop_cnt_1) := cv_over_loading;

debug_log(FND_FILE.LOG,'B7_1.12 積載オーバー重量の場合lt_skip_process_tab:'||lt_skip_process_tab(ln_loop_cnt_1));

debug_log(FND_FILE.LOG,'first_req_no:'|| first_req_no);

--

                -- 積載オーバー対象フラグ設定

                lb_over_loading := TRUE;

--

                -- エラーメッセージ取得

                lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(

                              gv_xxwsh            -- モジュール名略称：XXWSH 出荷・引当/配車

                            , gv_msg_xxwsh_11803  -- メッセージ：APP-XXWSH-11803 積載オーバーメッセージ

                            , gv_tkn_req_no       -- トークン：REQ_NO

                            , it_group_sum_add_tab(ln_loop_cnt_1).req_mov_no

                                                  -- 移動番号

                           ),1,5000);

--

                -- エラーメッセージ出力

                FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);

--2008.06.05 K.Yamane

                ln_grp_sum_cnt := 0;

--

              END IF;

--

            -- 容積の場合

            ELSIF (it_group_sum_add_tab(ln_loop_cnt_1).weight_capacity_cls = gv_capacity) THEN

--

debug_log(FND_FILE.LOG,'B7_1.13.0 基本容積:'||it_group_sum_add_tab(ln_loop_cnt_1).based_capacity);

debug_log(FND_FILE.LOG,'B7_1.13.0 積載容積合計:'||it_group_sum_add_tab(ln_loop_cnt_1).sum_capacity);

--

--

--20080517:DSugahara 不具合No1対応->

--              IF (it_group_sum_add_tab(ln_loop_cnt_1).based_capacity <  -- 基本容積

--                  it_group_sum_add_tab(ln_loop_cnt_1).sum_capacity)     -- 積載容積合計

--              THEN

              -- 共通関数：積載効率チェック(積載効率)

              xxwsh_common910_pkg.calc_load_efficiency(

                  in_sum_weight                  => NULL                      -- 1.合計重量

                , in_sum_capacity                => 

                        it_group_sum_add_tab(ln_loop_cnt_1).sum_capacity      -- 2.合計容積

                , iv_code_class1                 => gv_cdkbn_storage          -- 3.コード区分１

                , iv_entering_despatching_code1  => 

                        it_group_sum_add_tab(ln_loop_cnt_1).ship_from         -- 4.入出庫場所コード１

                , iv_code_class2                 => lv_cdkbn_2                -- 5.コード区分２

                , iv_entering_despatching_code2  => 

                        it_group_sum_add_tab(ln_loop_cnt_1).ship_to           -- 6.入出庫場所コード２

                , iv_ship_method                 => 

                        it_group_sum_add_tab(ln_loop_cnt_1).max_shipping_method -- 7.出荷方法

                , iv_prod_class                  => gv_prod_class             -- 8.商品区分

                , iv_auto_process_type           => cv_object                 -- 9.自動配車対象区分

                , id_standard_date               => 

                        it_group_sum_add_tab(ln_loop_cnt_1).ship_date         -- 10.基準日(適用日基準日)

                , ov_retcode                     => lv_retcode                -- 11.リターンコード

                , ov_errmsg_code                 => lv_errmsg                 -- 12.エラーメッセージコード

                , ov_errmsg                      => lv_errbuf                 -- 13.エラーメッセージ

                , ov_loading_over_class          => lv_loading_over_class     -- 14.積載オーバー区分

                , ov_ship_methods                => lv_ship_methods           -- 15.出荷方法

                , on_load_efficiency_weight      => ln_load_efficiency_weight -- 16.重量積載効率

                , on_load_efficiency_capacity    => ln_load_efficiency_capacity

                                                                              -- 17.容積積載効率

                , ov_mixed_ship_method           => lv_mixed_ship_method      -- 18.混載配送区分

              );

              -- 共通関数がエラーの場合

-- Ver1.7 M.Hokkanji START

              IF (lv_retcode <> gv_status_normal) THEN

--              IF (lv_retcode = gv_status_error) THEN

-- Ver1.16 2008/12/07 START

--          lv_errmsg := lv_errbuf;

          lv_errmsg  :=  NULL -- 1.合計重量

                          || gv_msg_comma ||

                          it_group_sum_add_tab(ln_loop_cnt_1).sum_capacity                -- 2.合計容積

                          || gv_msg_comma ||

                          gv_cdkbn_storage    -- 3.コード区分１

                          || gv_msg_comma ||

                          it_group_sum_add_tab(ln_loop_cnt_1).ship_from  -- 4.入出庫場所コード１

                          || gv_msg_comma ||

                          lv_cdkbn_2      -- 5.コード区分２

                          || gv_msg_comma ||

                          it_group_sum_add_tab(ln_loop_cnt_1).ship_to    -- 6.入出庫場所コード２

                          || gv_msg_comma ||

                          it_group_sum_add_tab(ln_loop_cnt_1).max_shipping_method -- 7.出荷方法

                          || gv_msg_comma ||

                          gv_prod_class       -- 8.商品区分

                          || gv_msg_comma ||

                          cv_object       -- 9.自動配車対象区分

                          || gv_msg_comma ||

                          TO_CHAR( it_group_sum_add_tab(ln_loop_cnt_1).ship_date, 'YYYY/MM/DD'); -- 10.基準日

          lv_errmsg := lv_errmsg|| '(重量,容積,コード区分1,コード1,コード区分2,コード2';

          lv_errmsg := lv_errmsg|| ',配送区分,商品区分,自動配車対象区分,基準日'; -- msg

          lv_errmsg := lv_errmsg||lv_errbuf ;

-- Ver1.16 2008/12/07 End          

-- Ver1.7 M.Hokkanji End

debug_log(FND_FILE.LOG,'B7_1.131　移動積載効率オーバーチェック関数エラー(容積)');

                RAISE global_api_expt;

              END IF;

--

              -- 積載オーバーの場合

              IF (lv_loading_over_class = cv_loading_over) THEN

--20080517:DSugahara 不具合No1対応<-

--

                ln_err_cnt := ln_err_cnt + 1;

--

                -- 処理対象外テーブルに積載オーバーを設定

                lt_skip_process_tab(ln_loop_cnt_1) := cv_over_loading;

debug_log(FND_FILE.LOG,'B7_1.13 積載オーバー容積の場合lt_skip_process_tab:'||lt_skip_process_tab(ln_loop_cnt_1));

debug_log(FND_FILE.LOG,'first_req_no:'|| first_req_no);

--

                -- 積載オーバー対象フラグ設定

                lb_over_loading := TRUE;

--

                -- エラーメッセージ取得

                lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(

                              gv_xxwsh            -- モジュール名略称：XXWSH 出荷・引当/配車

                            , gv_msg_xxwsh_11803  -- メッセージ：APP-XXWSH-11803 積載オーバーメッセージ

                            , gv_tkn_req_no       -- トークン：REQ_NO

                            , it_group_sum_add_tab(ln_loop_cnt_1).req_mov_no    -- 移動番号

                           ),1,5000);

--

                -- エラーメッセージ出力

                FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);

--2008.06.05 K.Yamane

                ln_grp_sum_cnt := 0;

--

              END IF;

--

            END IF;

--

          END IF;

--

--if (lb_over_loading) then

--debug_log(FND_FILE.LOG,'積載効率オーバー:TRUE');

--else

--debug_log(FND_FILE.LOG,'積載効率オーバー:FALSE');

--end if;



          -- 積載効率オーバーしていない

--          IF (lb_over_loading = FALSE) THEN

          IF ( lt_skip_process_tab(ln_loop_cnt_1) != cv_over_loading ) THEN

--

--debug_log(FND_FILE.LOG,'積載効率オーバーなし');

            --======================================

            -- B-7.合計重量／容積取得 加算処理

            --======================================

debug_log(FND_FILE.LOG,'B7_1.14 合計重量／容積取得 加算処理');

            lb_finish_proc := TRUE;

--

            -- 重量の場合

            IF (it_group_sum_add_tab(ln_loop_cnt_1).weight_capacity_cls = gv_weight) THEN

--

debug_log(FND_FILE.LOG,'B7_1.14.2 ln_sum_weight：'|| ln_sum_weight);

debug_log(FND_FILE.LOG,'B7_1.14.2 sum_weight：'|| it_group_sum_add_tab(ln_loop_cnt_1).sum_weight);

debug_log(FND_FILE.LOG,'B7_1.14.2 sum_pallet_weight：'|| it_group_sum_add_tab(ln_loop_cnt_1).sum_pallet_weight);

--

              -- 集約する

              ln_sum_weight := ln_sum_weight

                              + NVL(it_group_sum_add_tab(ln_loop_cnt_1).sum_weight,0)

                                                                                -- 積載重量合計

                              + NVL(it_group_sum_add_tab(ln_loop_cnt_1).sum_pallet_weight,0);

                                                                                -- 合計パレット重量

--

debug_log(FND_FILE.LOG,'B7_1.14.2 積載重量合計：'|| ln_sum_weight);

--

            ELSE  -- 容積

--

              -- 集約する

              ln_sum_capacity := ln_sum_capacity

                                + NVL(it_group_sum_add_tab(ln_loop_cnt_1).sum_capacity,0);

                                                                                -- 積載容積合計

--

debug_log(FND_FILE.LOG,'B7_1.14.2 積載容積合計加算：'|| ln_sum_capacity);

--

            END IF;

--

            --======================================

            -- 積載重量オーバーチェック

            --======================================

debug_log(FND_FILE.LOG,'B7_1.15 積載重量オーバーチェック');

            IF (gv_prod_class = gv_prod_cls_leaf) THEN  -- 商品区分：リーフ

--

debug_log(FND_FILE.LOG,'B7_1.16 商品区分：リーフ');

--

              IF (it_group_sum_add_tab(ln_loop_cnt_1).weight_capacity_cls = gv_weight) THEN -- 重量

--

debug_log(FND_FILE.LOG,'B7_1.17 重量');

--

                IF (ln_leaf_deadweight < ln_sum_weight) THEN  -- リーフ積載重量

debug_log(FND_FILE.LOG,'B7_1.18 加算取り消し');

                  -- 加算を取りやめる

                  ln_sum_weight := ln_sum_weight

                                  - NVL(it_group_sum_add_tab(ln_loop_cnt_1).sum_weight,0)

                                                                              -- 積載重量合計

                                  - NVL(it_group_sum_add_tab(ln_loop_cnt_1).sum_pallet_weight,0);

                                                                              -- 合計パレット重量

--

                  -- 集約済フラグ

                  lb_finish_proc := FALSE; -- 未集約

--

--

debug_log(FND_FILE.LOG,'B7_1.18 積載重量合計：'|| ln_sum_weight);

                END IF;

--

              ELSE

--

debug_log(FND_FILE.LOG,'B7_1.19 容積');

                IF (ln_leaf_loading_capacity < ln_sum_capacity) THEN  -- リーフ積載容積

debug_log(FND_FILE.LOG,'B7_1.20 加算取り消し');

                  -- 加算を取りやめる

                  ln_sum_capacity := ln_sum_capacity

                                  - NVL(it_group_sum_add_tab(ln_loop_cnt_1).sum_capacity,0);

                                                                              -- 積載容積合計

--

                  -- 集約済フラグ

                  lb_finish_proc := FALSE; -- 未集約

--

                END IF;

--

              END IF;

--

            ELSIF (gv_prod_class = gv_prod_cls_drink) THEN  -- 商品区分：ドリンク

--

debug_log(FND_FILE.LOG,'B7_1.21 商品区分：ドリンク');

--

              IF (it_group_sum_add_tab(ln_loop_cnt_1).weight_capacity_cls = gv_weight) THEN -- 重量

--

debug_log(FND_FILE.LOG,'B7_1.22 重量');

--

                IF (ln_drink_deadweight < ln_sum_weight) THEN  -- ドリンク積載重量

debug_log(FND_FILE.LOG,'B7_1.23 加算取り消し');

                  -- 加算を取りやめる

                  ln_sum_weight := ln_sum_weight

                                  - NVL(it_group_sum_add_tab(ln_loop_cnt_1).sum_weight,0)

                                                                              -- 積載重量合計

                                  - NVL(it_group_sum_add_tab(ln_loop_cnt_1).sum_pallet_weight,0);

                                                                              -- 合計パレット重量

--

                  -- 集約済フラグ

                  lb_finish_proc := FALSE; -- 未集約

--

debug_log(FND_FILE.LOG,'B7_1.23 積載重量合計：'|| ln_sum_weight);

--

                END IF;

--

              ELSE

--

debug_log(FND_FILE.LOG,'B7_1.24 容積');

--

                IF (ln_drink_loading_capacity < ln_sum_capacity) THEN  -- ドリンク積載容積

debug_log(FND_FILE.LOG,'B7_1.25.1 最大容積＜積載容積集計：'||ln_drink_loading_capacity||'＜'||ln_sum_capacity);

debug_log(FND_FILE.LOG,'B7_1.25.2 加算取り消し');

                  -- 加算を取りやめる

                  ln_sum_capacity := ln_sum_capacity

                                  - NVL(it_group_sum_add_tab(ln_loop_cnt_1).sum_capacity,0);

                                                                              -- 積載重量合計

--

                  -- 集約済フラグ

                  lb_finish_proc := FALSE; -- 未集約

--

                END IF;

--

              END IF;

--

            END IF;

--

            IF (lb_finish_proc) THEN  -- 集約済フラグ：集約済

--

debug_log(FND_FILE.LOG,'B7_1.26 lt_skip_process_tab(基準レコード):'||lt_skip_process_tab(ln_start_no));

--

              IF (lt_skip_process_tab(ln_start_no) = 0) THEN

                -- 基準レコードの集約済フラグ(対象外)をセットする

                lt_skip_process_tab(ln_loop_cnt_1) := cv_finish_proc;

--

              END IF;

--

              -- 比較レコードの集約済フラグ(対象外)をセットする

              lt_skip_process_tab(ln_loop_cnt_1) := cv_finish_proc;

debug_log(FND_FILE.LOG,'B7_1.27 lt_skip_process_tab:'||lt_skip_process_tab(ln_loop_cnt_1));

--

--debug_log(FND_FILE.LOG,'集約済フラグをセット');

--

              -- 依頼No格納用カウンタ

              ln_pre_reqno_cnt := ln_pre_reqno_cnt + 1;

--

              -- 依頼Noを格納

              lt_request_no_tab(ln_pre_reqno_cnt)  := it_group_sum_add_tab(ln_loop_cnt_1).req_mov_no;

debug_log(FND_FILE.LOG,'B7_1.28 依頼No：'||lt_request_no_tab(ln_pre_reqno_cnt));

--

              -- 処理済フラグを初期化

              lb_finish_proc := FALSE;

--

--debug_log(FND_FILE.LOG,'処理済フラグを初期化');

--

            END IF;

--

--

          END IF;

--

        -- キーブレイクした場合

        ELSE

--

debug_log(FND_FILE.LOG,'B7_1.30 キーブレイク');

--

          -- 終了時カウントを格納

          ln_end_no := ln_loop_cnt_1 - 1;

--

debug_log(FND_FILE.LOG,'B7_1.31 終了時カウント格納:'|| ln_end_no);

debug_log(FND_FILE.LOG,'first_req_no:'|| first_req_no);

--

          -- ==============================

          -- キーブレイク処理

          -- ==============================

          lproc_keybrake_proc_B7(

              ov_errbuf      => lv_errbuf

            , ov_retcode     => lv_retcode

            , ov_errmsg      => lv_errmsg

          );

          -- 処理がエラーの場合

          IF (lv_retcode = gv_status_error) THEN

debug_log(FND_FILE.LOG,'B7_1.32 キーブレイク処理例外');

            RAISE global_api_expt;

          END IF;

--

          -- 次のグループの処理に移行

          IF (lv_rerun_flag = gv_off) THEN

debug_log(FND_FILE.LOG,'B7_1.33 次グループの処理に移行');

--

              -- キーブレイクしたレコードを再読込するためループカウントを戻す

              ln_loop_cnt_1 := ln_loop_cnt_1 - 1;

--

              -- グループカウントをリセットする

              ln_grp_sum_cnt := 0;

--

          ELSIF (lv_rerun_flag = gv_on) THEN

debug_log(FND_FILE.LOG,'B7_1.34 次グループの処理に移行しない');

            -- 同一キーグループ内の未処理のデータを処理する

            -- ループカウンタをスタートに戻す

            ln_loop_cnt_1 := ln_start_no - 1;

--

            -- グループカウントをリセットする

            ln_grp_sum_cnt := 0;

--

          END IF;

debug_log(FND_FILE.LOG,'B7_1.35 比較用変数に格納 ln_loop_cnt_1='|| to_char(ln_loop_cnt_1));

debug_log(FND_FILE.LOG,'B7_1.351 比較用変数Count ='|| to_char(it_group_sum_add_tab.count));

--

          IF (ln_loop_cnt_1 > 0) THEN

--

            -- 比較用変数に格納

            lt_prev_ship_date       := it_group_sum_add_tab(ln_loop_cnt_1).ship_date;   -- 出庫日

            lt_prev_arrival_date    := it_group_sum_add_tab(ln_loop_cnt_1).arrival_date;

                                                                                        -- 着荷日

            lt_prev_order_type      := it_group_sum_add_tab(ln_loop_cnt_1).order_type_id;

                                                                                        -- 出庫形態

            lt_prev_freight_carrier := it_group_sum_add_tab(ln_loop_cnt_1).carrier_code;

                                                                                        -- 配送業者

            lt_prev_ship_from       := it_group_sum_add_tab(ln_loop_cnt_1).ship_from;   -- 出荷元

            lt_prev_ship_to         := it_group_sum_add_tab(ln_loop_cnt_1).ship_to;     -- 出荷先

            lt_prev_w_c_class       := it_group_sum_add_tab(ln_loop_cnt_1).weight_capacity_cls;

--

          END IF;

--

        END IF;

debug_log(FND_FILE.LOG,'B7_1.36');

--

      END IF; -- 未処理データのみ対象

--

--if (lb_last_data_flag) then

--debug_log(FND_FILE.LOG,'最終レコードフラグ：TRUE');

--else

--debug_log(FND_FILE.LOG,'最終レコードフラグ：FALSE');

--end if;

debug_log(FND_FILE.LOG,'B7_1.36.1 ln_loop_cnt_1：'|| ln_loop_cnt_1);

      -- ==============================

      -- 最終レコード処理

      -- ==============================

      IF (ln_loop_cnt_1 >= it_group_sum_add_tab.COUNT)  -- カウント：最終レコード

--        AND (lb_last_data_flag = FALSE)             -- 最終レコードフラグ FALSE

      THEN

debug_log(FND_FILE.LOG,'B7_1.37 最終レコード処理');

--

        -- 終了時カウントを格納

        ln_end_no := ln_loop_cnt_1;

debug_log(FND_FILE.LOG,'【最終レコード処理】');

--

debug_log(FND_FILE.LOG,'終了時カウント格納:'|| ln_loop_cnt_1);

debug_log(FND_FILE.LOG,'first_req_no:'|| first_req_no);

--

        -- ==============================

        -- キーブレイク処理

        -- ==============================

        lproc_keybrake_proc_B7(

            ov_errbuf      => lv_errbuf

          , ov_retcode     => lv_retcode

          , ov_errmsg      => lv_errmsg

        );

        -- 処理がエラーの場合

        IF (lv_retcode = gv_status_error) THEN

debug_log(FND_FILE.LOG,'B7_1.38 最終レコード処理 キーブレイク処理例外');

          RAISE global_api_expt;

        END IF;

--

--debug_log(FND_FILE.LOG,'再度処理：'||lv_rerun_flag);

--

        -- 再実行フラグ：OFF

        IF lv_rerun_flag = gv_off THEN

debug_log(FND_FILE.LOG,'B7_1.39 処理終了');

          EXIT;

--

        ELSIF lv_rerun_flag = gv_on THEN

          -- 同一キーグループ内の未処理のデータを処理する

          -- ループカウンタをスタートに戻す

debug_log(FND_FILE.LOG,'B7_1.40  処理終了');

          ln_loop_cnt_1 := ln_start_no - 1;

--

          -- グループカウントをリセットする

          ln_grp_sum_cnt := 0;

--

        END IF;

--

        -- 最終データフラグをセット

        lb_last_data_flag := TRUE;

--debug_log(FND_FILE.LOG,'最終データフラグをセット');

        --============================

        -- 終了チェック

        --============================

        ln_end_chk_cnt := 0;

--

        FOR end_chk IN 1..lt_skip_process_tab.COUNT LOOP

  debug_log(FND_FILE.LOG,'B7_1.41 終了チェック');

--

          IF (lt_skip_process_tab(end_chk) = 0) THEN

--

            ln_end_chk_cnt := ln_end_chk_cnt + 1;

--

          END IF;

--

        END LOOP;

--

        IF ln_end_chk_cnt = 0 THEN

  debug_log(FND_FILE.LOG,'B7_1.42 終了');

          -- 終了

          EXIT;

--

        END IF;

      END IF;

--

    END LOOP get_max_ship_cd;

--

    --移動積載オーバーありの場合

    IF ( lb_over_loading ) THEN          

debug_log(FND_FILE.LOG,'B7_1.43 移動積載オーバーありの場合警告');

      ov_retcode := gv_status_warn; --警告

      gn_warn_cnt := NVL(gn_warn_cnt,0) + NVL(ln_err_cnt,0);

    END IF;

--

debug_log(FND_FILE.LOG,'合計重量/容積取得 加算処理終了');

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

  END set_weight_capacity_add;

--

  /**********************************************************************************

   * Procedure Name   : ins_intensive_carriers_tmp

   * Description      : 集約中間テーブル出力処理(B-8)

   ***********************************************************************************/

  PROCEDURE ins_intensive_carriers_tmp(

    ov_errbuf   OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #

    ov_retcode  OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #

    ov_errmsg   OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #

  IS

    -- ===============================

    -- 固定ローカル定数

    -- ===============================

    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_intensive_carriers_tmp'; -- プログラム名

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

    ov_retcode := gv_status_normal;

--

--###########################  固定部 END   ############################

--

debug_log(FND_FILE.LOG,'【集約中間テーブル出力処理(B-8)】');

debug_log(FND_FILE.LOG,'集約件数  ：'||gt_int_no_tab.count);

debug_log(FND_FILE.LOG,'処理種別件数：'||gt_tran_type_tab.count);

debug_log(FND_FILE.LOG,'集約元件数：'||gt_int_source_tab.count);

debug_log(FND_FILE.LOG,'配送元件数：'||gt_deli_from_tab.count);

debug_log(FND_FILE.LOG,'配送元ID件数：'||gt_deli_from_id_tab.count);

debug_log(FND_FILE.LOG,'配送先件数：'||gt_deli_to_tab.count);

debug_log(FND_FILE.LOG,'配送先ID件数：'||gt_deli_to_id_tab.count);

debug_log(FND_FILE.LOG,'出庫予定日件数：'||gt_ship_date_tab.count);

debug_log(FND_FILE.LOG,'着荷予定日件数：'||gt_arvl_date_tab.count);

debug_log(FND_FILE.LOG,'出庫形態件数：'||gt_tran_type_nm_tab.count);

debug_log(FND_FILE.LOG,'運送業者件数：'||gt_carrier_code_tab.count);

debug_log(FND_FILE.LOG,'運送業者ID件数：'||gt_carrier_id_tab.count);

debug_log(FND_FILE.LOG,'管轄拠点件数：'||gt_head_sales_tab.count);

debug_log(FND_FILE.LOG,'引当順件数：'||gt_reserve_order_tab.count);

debug_log(FND_FILE.LOG,'集約合計重量件数：'||gt_sum_weight_tab.count);

debug_log(FND_FILE.LOG,'集約合計容積件数：'||gt_sum_capa_tab.count);

debug_log(FND_FILE.LOG,'最大配送区分件数：'||gt_max_ship_cd_tab.count);

debug_log(FND_FILE.LOG,'重量容積区分件数：'||gt_weight_capa_tab.count);

debug_log(FND_FILE.LOG,'最大積載重量件数：'||gt_max_weight_tab.count);

debug_log(FND_FILE.LOG,'最大積載容積件数：'||gt_max_capa_tab.count);

--

-- 2008/10/01 H.Itou Del Start PT 6-1_27 指摘18

--for i in 1..gt_int_no_tab.count loop

--debug_log(FND_FILE.LOG,'---------------------------');

--debug_log(FND_FILE.LOG,'集約No  ：'||gt_int_no_tab(i));

--debug_log(FND_FILE.LOG,'処理種別：'||gt_tran_type_tab(i));

--debug_log(FND_FILE.LOG,'集約元No：'||gt_int_source_tab(i));

--debug_log(FND_FILE.LOG,'配送元：'||gt_deli_from_tab(i));

--debug_log(FND_FILE.LOG,'配送元ID：'||gt_deli_from_id_tab(i));

--debug_log(FND_FILE.LOG,'配送先：'||gt_deli_to_tab(i));

--debug_log(FND_FILE.LOG,'配送先ID：'||gt_deli_to_id_tab(i));

--debug_log(FND_FILE.LOG,'出庫予定日：'||gt_ship_date_tab(i));

--debug_log(FND_FILE.LOG,'着荷予定日：'||gt_arvl_date_tab(i));

--debug_log(FND_FILE.LOG,'出庫形態：'||gt_tran_type_nm_tab(i));

--debug_log(FND_FILE.LOG,'運送業者：'||gt_carrier_code_tab(i));

--debug_log(FND_FILE.LOG,'運送業者ID：'||gt_carrier_id_tab(i));

--debug_log(FND_FILE.LOG,'管轄拠点：'||gt_head_sales_tab(i));

--debug_log(FND_FILE.LOG,'引当順：'||gt_reserve_order_tab(i));

--debug_log(FND_FILE.LOG,'集約合計重量：'||gt_sum_weight_tab(i));

--debug_log(FND_FILE.LOG,'集約合計容積：'||gt_sum_capa_tab(i));

--debug_log(FND_FILE.LOG,'最大配送区分：'||gt_max_ship_cd_tab(i));

--debug_log(FND_FILE.LOG,'重量容積区分：'||gt_weight_capa_tab(i));

--debug_log(FND_FILE.LOG,'最大積載重量：'||gt_max_weight_tab(i));

--debug_log(FND_FILE.LOG,'最大積載容積：'||gt_max_capa_tab(i));

--end loop;

-- 2008/10/01 H.Itou Del End

debug_log(FND_FILE.LOG,'★自動配車集約中間テーブル登録：集約中間テーブル出力処理(B-8)');

debug_log(FND_FILE.LOG,'登録数：'||gt_int_no_tab.COUNT);

debug_log(FND_FILE.LOG,'PLSQL表：gt_int_no_tab');

    --======================================

    -- B-8.集約中間テーブル出力処理

    --======================================

    FORALL ln_cnt IN 1..gt_int_no_tab.COUNT

      INSERT INTO xxwsh_intensive_carriers_tmp(   -- 自動配車集約中間テーブル

          intensive_no              -- 集約No

        , transaction_type          -- 処理種別

        , intensive_source_no       -- 集約元No

        , deliver_from              -- 配送元

        , deliver_from_id           -- 配送元ID

        , deliver_to                -- 配送先

        , deliver_to_id             -- 配送先ID

        , schedule_ship_date        -- 出庫予定日

        , schedule_arrival_date     -- 着荷予定日

        , transaction_type_name     -- 出庫形態

        , freight_carrier_code      -- 運送業者

        , carrier_id                -- 運送業者ID

        , head_sales_branch         -- 管轄拠点

        , reserve_order             -- 引当順

        , intensive_sum_weight      -- 集約合計重量

        , intensive_sum_capacity    -- 集約合計容積

        , max_shipping_method_code  -- 最大配送区分

        , weight_capacity_class     -- 重量容積区分

        , max_weight                -- 最大積載重量

        , max_capacity              -- 最大積載容積

        )

        VALUES

        (

          gt_int_no_tab(ln_cnt)         -- 集約No

        , gt_tran_type_tab(ln_cnt)      -- 処理種別

        , gt_int_source_tab(ln_cnt)     -- 集約元No

        , gt_deli_from_tab(ln_cnt)      -- 配送元

        , gt_deli_from_id_tab(ln_cnt)   -- 配送元ID

        , gt_deli_to_tab(ln_cnt)        -- 配送先

        , gt_deli_to_id_tab(ln_cnt)     -- 配送先ID

        , gt_ship_date_tab(ln_cnt)      -- 出庫予定日

        , gt_arvl_date_tab(ln_cnt)      -- 着荷予定日

        , gt_tran_type_nm_tab(ln_cnt)   -- 出庫形態

        , gt_carrier_code_tab(ln_cnt)   -- 運送業者

        , gt_carrier_id_tab(ln_cnt)     -- 運送業者ID

        , gt_head_sales_tab(ln_cnt)     -- 管轄拠点

        , gt_reserve_order_tab(ln_cnt)  -- 引当順

        , gt_sum_weight_tab(ln_cnt)     -- 集約合計重量

        , gt_sum_capa_tab(ln_cnt)       -- 集約合計容積

        , gt_max_ship_cd_tab(ln_cnt)    -- 最大配送区分

        , gt_weight_capa_tab(ln_cnt)    -- 重量容積区分

        , gt_max_weight_tab(ln_cnt)     -- 最大積載重量

        , gt_max_capa_tab(ln_cnt)       -- 最大積載容積

        );

--

debug_log(FND_FILE.LOG,'集約No  ：'||gt_int_no_lines_tab.count);

debug_log(FND_FILE.LOG,'依頼No：'||gt_request_no_tab.count);

-- 2008/10/01 H.Itou Del Start PT 6-1_27 指摘18

--for i in 1..gt_int_no_lines_tab.count loop

--debug_log(FND_FILE.LOG,'集約No  ：'||gt_int_no_lines_tab(i));

--debug_log(FND_FILE.LOG,'依頼No：'||gt_request_no_tab(i));

--end loop;

-- 2008/10/01 H.Itou Del End

debug_log(FND_FILE.LOG,'自動配車集約中間明細テーブル登録数：'||gt_request_no_tab.COUNT);

debug_log(FND_FILE.LOG,'PLSQL表：gt_int_no_lines_tab');

    FORALL ln_cnt_2 IN 1..gt_int_no_lines_tab.COUNT

      INSERT INTO xxwsh_intensive_carrier_ln_tmp(  -- 自動配車集約中間明細テーブル

          intensive_no

        , request_no

        )

        VALUES

        (

          gt_int_no_lines_tab(ln_cnt_2)   -- 集約No

        , gt_request_no_tab(ln_cnt_2)     -- 依頼No

        );

-- Ver1.5 M.Hokkanji Start

   debug_log(FND_FILE.LOG,'自動配車集約中間明細テーブル登録後コミット');

   COMMIT;

-- Ver1.5 M.Hokkanji End

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

  END ins_intensive_carriers_tmp;

--

  /**********************************************************************************

   * Procedure Name   : get_max_shipping_method

   * Description      : 最大配送区分・重量容積区分取得処理(B-6)

   ***********************************************************************************/

  PROCEDURE get_max_shipping_method(

    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #

    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #

    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #

  IS

    -- ===============================

    -- 固定ローカル定数

    -- ===============================

    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_max_shipping_method'; -- プログラム名

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

    cv_not_save       CONSTANT VARCHAR2(1)  := '0';       -- 拠点混載登録済フラグ：未登録

    cv_finish_proc    CONSTANT VARCHAR2(1)  := '1';       -- 処理済

--

    -- *** ローカル変数 ***

    lb_warning_flg  BOOLEAN DEFAULT FALSE; -- 警告フラグ（警告の場合：TRUE)

--

    -- *** ローカル・カーソル ***

    -- 出荷依頼

    CURSOR ship_cur IS

      SELECT  xcst.transaction_id           transaction_id      -- トランザクションID

            , xcst.transaction_type         tran_type           -- 処理種別

            , xcst.request_no               req_mov_no          -- 依頼NO

            , xcst.mixed_no                 mixed_no            -- 混載元NO

            , xcst.deliver_from             ship_from           -- 出荷元保管場所

            , xcst.deliver_from_id          ship_from_id        -- 出荷元ID

            , xcst.deliver_to               ship_to             -- 出荷先

            , xcst.deliver_to_id            ship_to_id          -- 出荷先ID

            , xcst.shipping_method_code     ship_method_code    -- 配送区分

            , xcst.schedule_ship_date       ship_date           -- 出庫日

            , xcst.schedule_arrival_date    arrival_date        -- 着荷日

            , xcst.order_type_id            order_type_id       -- 出庫形態

            , xcst.freight_carrier_code     carrier_code        -- 運送業者

            , xcst.career_id                carrier_id          -- 運送業者ID

            , xcst.based_weight             based_weight        -- 基本重量

            , xcst.based_capacity           based_capacity      -- 基本容積

            , xcst.sum_weight               sum_weight          -- 積載重量合計

            , xcst.sum_capacity             sum_capacity        -- 積載容積合計

            , xcst.sum_pallet_weight        sum_pallet_weight   -- 合計パレット重量

            , xcst.max_shipping_method_code max_shipping_method -- 最大配送区分

            , xcst.weight_capacity_class    weight_capacity_cls -- 重量容積区分

            , DECODE(reserve_order, NULL, 99999, reserve_order) reserve_order

                                                                -- 引当順

            , xcst.head_sales_branch        head_sales_branch   -- 管轄拠点

            , NULL                          finish_sum_flag     -- 集約済フラグ

      FROM xxwsh_carriers_sort_tmp xcst               -- 自動配車ソート用中間テーブル

      WHERE xcst.transaction_type = gv_ship_type_ship -- 処理種別：出荷依頼

        AND xcst.pre_saved_flg = cv_not_save          -- 拠点混載登録フラグ:未登録

      ORDER BY  ship_date                       -- 出庫日

              , arrival_date                    -- 着荷日

              , mixed_no                        -- 混載元NO

              , order_type_id                   -- 出庫形態

              , ship_from                       -- 出荷元保管場所

              , carrier_code                    -- 運送業者

              , weight_capacity_cls             -- 重量容積区分

              , reserve_order                   -- 引当順

              , head_sales_branch               -- 管轄拠点

              , ship_to                         -- 出荷先

              , DECODE (weight_capacity_cls, gv_weight

                        , sum_weight            -- 集約重量合計

                        , sum_capacity) DESC    -- 集約合計容積

      ;

--

    -- 移動指示

    CURSOR move_cur IS

      SELECT  xcst.transaction_id           transaction_id      -- トランザクションID

            , xcst.transaction_type         tran_type           -- 処理種別

            , xcst.request_no               req_mov_no          -- 移動No

            , xcst.mixed_no                 mixed_no            -- 混載元NO

            , xcst.deliver_from             ship_from           -- 出荷元保管場所

            , xcst.deliver_from_id          ship_from_id        -- 出荷元ID

            , xcst.deliver_to               ship_to             -- 出荷先

            , xcst.deliver_to_id            ship_to_id          -- 出荷先ID

            , xcst.shipping_method_code     ship_method_code    -- 配送区分

            , xcst.schedule_ship_date       ship_date           -- 出庫日

            , xcst.schedule_arrival_date    arrival_date        -- 着荷日

            , xcst.order_type_id            order_type_id       -- 出庫形態

            , xcst.freight_carrier_code     carrier_code        -- 運送業者

            , xcst.career_id                carrier_id          -- 運送業者ID

            , xcst.based_weight             based_weight        -- 基本重量

            , xcst.based_capacity           based_capacity      -- 基本容積

            , xcst.sum_weight               sum_weight          -- 積載重量合計

            , xcst.sum_capacity             sum_capacity        -- 積載容積合計

            , xcst.sum_pallet_weight        sum_pallet_weight   -- 合計パレット重量

            , xcst.max_shipping_method_code max_shipping_method -- 最大配送区分

            , xcst.weight_capacity_class    weight_capacity_cls -- 重量容積区分

            , DECODE(reserve_order, NULL, 99999, reserve_order) reserve_order

                                                                -- 引当順

            , xcst.head_sales_branch        head_sales_branch   -- 管轄拠点

            , NULL                          finish_sum_flag     -- 集約済フラグ

      FROM xxwsh_carriers_sort_tmp xcst                     -- 自動配車ソート用中間テーブル

      WHERE xcst.transaction_type = gv_ship_type_move       -- 処理種別：移動指示

      ORDER BY  ship_date                       -- 出庫日

              , arrival_date                    -- 着荷日

              , ship_from                       -- 出荷元保管場所

              , carrier_code                    -- 運送業者

              , weight_capacity_cls             -- 重量容積区分

              , ship_to                         -- 出荷先

              , DECODE (weight_capacity_cls, gv_weight

                        , sum_weight            -- 集約重量合計

                        , sum_capacity) DESC    -- 集約合計容積

      ;

--

    -- *** ローカル・レコード ***

    lr_ship_info  ship_cur%ROWTYPE;   -- 出荷依頼情報

    lr_move_info  move_cur%ROWTYPE;   -- 移動指示情報

--

  BEGIN

--

--##################  固定ステータス初期化部 START   ###################

--

    ov_retcode := gv_status_normal;

--

--###########################  固定部 END   ############################

--

debug_log(FND_FILE.LOG,'【最大配送区分・重量容積区分取得処理(B-6)】');

    -- テーブル初期化

    gt_grp_sum_add_tab_ship.DELETE; -- 出荷依頼用

    gt_grp_sum_add_tab_move.DELETE; -- 移動指示用

--

    --======================================

    -- B-6.最大配送区分、重量容積区分取得処理

    --======================================

    -- 出荷依頼

    OPEN ship_cur;

    FETCH ship_cur BULK COLLECT INTO gt_grp_sum_add_tab_ship;

    CLOSE ship_cur;

--

    IF (gt_grp_sum_add_tab_ship.COUNT > 0) THEN

--

debug_log(FND_FILE.LOG,'出荷依頼件数:'|| gt_grp_sum_add_tab_ship.COUNT);

--

      -- ================================

      -- 合計重量/容積取得 加算処理(B-7)

      -- ================================

      set_weight_capacity_add(

           it_group_sum_add_tab => gt_grp_sum_add_tab_ship  -- 処理テーブル

         , ov_errbuf            => lv_errbuf                -- エラー・メッセージ           --# 固定 #

         , ov_retcode           => lv_retcode               -- リターン・コード             --# 固定 #

         , ov_errmsg            => lv_errmsg                -- ユーザー・エラー・メッセージ --# 固定 #

      );

      -- 処理がエラーの場合

      IF (lv_retcode = gv_status_error) THEN

        RAISE global_api_expt;

      ELSIF lv_retcode = gv_status_warn THEN

        lb_warning_flg := TRUE;

      END IF;

--

      -- ================================

      -- 集約中間テーブル出力処理(B-8)

      -- ================================

      ins_intensive_carriers_tmp(

           ov_errbuf  => lv_errbuf    -- エラー・メッセージ           --# 固定 #

         , ov_retcode => lv_retcode   -- リターン・コード             --# 固定 #

         , ov_errmsg  => lv_errmsg    -- ユーザー・エラー・メッセージ --# 固定 #

      );

      -- 処理がエラーの場合

      IF (lv_retcode = gv_status_error) THEN

        RAISE global_api_expt;

      END IF;

--

    END IF;

--

    OPEN move_cur;

    FETCH move_cur BULK COLLECT INTO gt_grp_sum_add_tab_move;

    CLOSE move_cur;

--

    IF (gt_grp_sum_add_tab_move.COUNT > 0) THEN

--

debug_log(FND_FILE.LOG,'移動指示件数:'|| gt_grp_sum_add_tab_move.COUNT);

      -- ================================

      -- 合計重量/容積取得 加算処理(B-7)

      -- ================================

      set_weight_capacity_add(

           it_group_sum_add_tab => gt_grp_sum_add_tab_move  -- 処理テーブル

         , ov_errbuf            => lv_errbuf                -- エラー・メッセージ           --# 固定 #

         , ov_retcode           => lv_retcode               -- リターン・コード             --# 固定 #

         , ov_errmsg            => lv_errmsg                -- ユーザー・エラー・メッセージ --# 固定 #

      );

      -- 処理がエラーの場合

      IF (lv_retcode = gv_status_error) THEN

        RAISE global_api_expt;

      ELSIF (lv_retcode = gv_status_warn) THEN

        --処理が警告の場合

debug_log(FND_FILE.LOG,'B-7.合計重量/容積取得 加算処理 警告メッセージ：'||lv_errmsg);

        lb_warning_flg := TRUE;

      END IF;

--

      -- ================================

      -- 集約中間テーブル出力処理(B-8)

      -- ================================

      ins_intensive_carriers_tmp(

           ov_errbuf  => lv_errbuf    -- エラー・メッセージ           --# 固定 #

         , ov_retcode => lv_retcode   -- リターン・コード             --# 固定 #

         , ov_errmsg  => lv_errmsg    -- ユーザー・エラー・メッセージ --# 固定 #

      );

      -- 処理がエラーの場合

      IF (lv_retcode = gv_status_error) THEN

        RAISE global_api_expt;

      END IF;

--

    END IF;

--

    --警告ありの場合ステータス警告

    IF ( lb_warning_flg ) THEN

      ov_retcode := gv_status_warn;

    END IF;





  EXCEPTION

--

--#################################  固定例外処理部 START   ####################################

--

    -- *** 共通関数例外ハンドラ ***

    WHEN global_api_expt THEN

      IF (ship_cur%ISOPEN) THEN

        CLOSE ship_cur;

      END IF;

      IF (move_cur%ISOPEN) THEN

        CLOSE move_cur;

      END IF;

      ov_errmsg  := lv_errmsg;

      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);

      ov_retcode := gv_status_error;

    -- *** 共通関数OTHERS例外ハンドラ ***

    WHEN global_api_others_expt THEN

      IF (ship_cur%ISOPEN) THEN

        CLOSE ship_cur;

      END IF;

      IF (move_cur%ISOPEN) THEN

        CLOSE move_cur;

      END IF;

      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;

      ov_retcode := gv_status_error;

    -- *** OTHERS例外ハンドラ ***

    WHEN OTHERS THEN

      IF (ship_cur%ISOPEN) THEN

        CLOSE ship_cur;

      END IF;

      IF (move_cur%ISOPEN) THEN

        CLOSE move_cur;

      END IF;

      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;

      ov_retcode := gv_status_error;

--

--#####################################  固定部 END   ##########################################

--

  END get_max_shipping_method;

--

  /**********************************************************************************

   * Procedure Name   : set_delivery_no

   * Description      : 配送No設定処理

   ***********************************************************************************/

  PROCEDURE set_delivery_no(

    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #

    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #

    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #

  IS

    -- ===============================

    -- 固定ローカル定数

    -- ===============================

    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_delivery_no'; -- プログラム名

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

    cv_possibility    CONSTANT VARCHAR2(1) := '0';    -- 使用可

    cv_impossibility  CONSTANT VARCHAR2(1) := '1';    -- 使用不可

    cv_delivery_kbn   CONSTANT VARCHAR2(1) := '5';    -- 採番番号区分：配送No

--

    -- *** ローカル変数 ***

    -- 比較用変数

    lt_bf_request_no        xxwsh_intensive_carrier_ln_tmp.request_no%TYPE; -- 依頼No/移動No

    lt_bf_delivery_no       xxwsh_mixed_carriers_tmp.delivery_no%TYPE;      -- 配送No

    lt_bf_prev_request_no   xxwsh_carriers_sort_tmp.request_no%TYPE;        -- 集約前依頼No

    lt_bf_prev_delivery_no  xxwsh_carriers_sort_tmp.prev_delivery_no%TYPE;  -- 前回配送No

--

    -- PL/SQL表

    lt_delivery_no_dat      reset_delivery_no_ttype;    -- カーソルデータ取得用

    lt_intensive_no_tab     intensive_no_ttype;         -- 集約No

    lt_delivery_no_tab      deliver_no_ttype;           -- 配送No

    lt_upd_delivery_no_tab  deliver_no_ttype;           -- 更新用配送No

    lt_request_no_tab       req_mov_no_ttype;           -- 依頼No/移動No

    lt_prev_delivery_no_tab pre_deliver_no_ttype;       -- 前回配送No

    lt_prev_request_no_tab  req_mov_no_ttype;           -- 集約前依頼No/移動No

    lt_fin_delivery_no_tab  deliver_no_ttype;           -- 使用済配送No

--

    ln_loop_cnt             NUMBER DEFAULT 0;                               -- ループカウンタ

    ln_cnt                  NUMBER DEFAULT 0;                               -- ループカウンタ

    ln_chk_1                NUMBER DEFAULT 0;                               -- チェックカウンタ１

    ln_chk_2                NUMBER DEFAULT 0;                               -- チェックカウンタ２

    ln_reg_cnt              NUMBER DEFAULT 0;                               -- 配送No設定用カウンタ

    ln_delivery_grp_cnt     NUMBER DEFAULT 0;                               -- 配送グループカウンタ

    ln_start_cnt            NUMBER DEFAULT 0;                               -- 開始カウント

    ln_end_cnt              NUMBER DEFAULT 0;                               -- 終了カウント

    ln_fin_cnt              NUMBER DEFAULT 0;                               -- 使用済配送No登録用

    lt_delivery_no_tmp      xxwsh_mixed_carriers_tmp.delivery_no%TYPE;      -- 配送No(TEMP)

    lt_decision_delivery_no xxwsh_mixed_carriers_tmp.delivery_no%TYPE;      -- 配送No(確定)

    lb_new_ins_flag         BOOLEAN DEFAULT FALSE;                          -- 新規登録フラグ

    lv_possible_flag        VARCHAR2(1);                                    -- 配送No使用可否

    lb_last_data_flag       BOOLEAN DEFAULT FALSE;                          -- 最終データフラグ

    lt_chk_delivery_no      xxwsh_mixed_carriers_tmp.delivery_no%TYPE;      -- 配送No(使用確認用)

    lb_used_flag            BOOLEAN DEFAULT FALSE;                          -- 使用済フラグ

    ln_use_chk_cnt          NUMBER DEFAULT 0;

debug_cnt number default 0;

--

    -- *** ローカル・カーソル ***

--

    CURSOR set_delivery_no_cur IS

-- Ver1.20 M.Hokkanji Start

--      SELECT  xmct.intensive_no     int_no                  -- 集約No

      SELECT  /*+ leading(xcst xiclt xict xmct) hash(xcst xiclt xict xmct) */

              xmct.intensive_no     int_no                  -- 集約No

-- Ver1.20 M.Hokkanji End

            , xcst.request_no       req_no                  -- 依頼No

            , xmct.delivery_no      delivery_no             -- 配送No

            , xcst.prev_delivery_no prev_delivery_no        -- 前回配送No

-- Ver1.2 M.Hokkanji Start

            , xcst.delivery_no      use_delivery_no         -- 現配送No

-- Ver1.2 M.Hokkanji End

        FROM  xxwsh_intensive_carriers_tmp   xict           -- 自動配車集約中間テーブル

            , xxwsh_intensive_carrier_ln_tmp xiclt          -- 自動配車集約中間明細テーブル

            , xxwsh_mixed_carriers_tmp       xmct           -- 自動配車混載中間テーブル

            , xxwsh_carriers_sort_tmp        xcst           -- 自動配車ソート用中間テーブル

       WHERE  xict.intensive_no = xiclt.intensive_no        -- 集約No

         AND  xict.intensive_no = xmct.intensive_no         -- 集約No

         AND  xiclt.request_no  = xcst.request_no           -- 依頼No

-- Ver1.3 M.Hokkanji Start

-- TE080指摘事項08対応

--      ORDER BY  xmct.delivery_no ASC                        -- 配送No

      ORDER BY  xict.transaction_type ASC                     -- 業務種別

              , xmct.delivery_no ASC                          -- 配送No

-- Ver1.3 M.Hokkanji End

-- Ver1.2 M.Hokkanji Start

--              , xcst.prev_delivery_no ASC                   -- 前回配送No

              , NVL(xcst.delivery_no,xcst.prev_delivery_no) ASC -- 前回配送No

-- Ver1.2 M.Hokkanji End

    ;

--

    -- *** ローカル・レコード ***

    lr_set_deliver_no   set_delivery_no_cur%ROWTYPE;

--

    -- *** サブ・プログラム ***

    -- ======================

    -- 前回配送No使用済確認

    -- ======================

    PROCEDURE chk_finish_delivery_no(

        in_delivery_no IN  xxwsh_carriers_schedule.delivery_no%TYPE

      , ov_finish_flag OUT NOCOPY VARCHAR2    -- 使用可否フラグ(1:使用不可、0:使用可)

      , ov_errbuf      OUT NOCOPY VARCHAR2    -- エラー・メッセージ           --# 固定 #

      , ov_retcode     OUT NOCOPY VARCHAR2    -- リターン・コード             --# 固定 #

      , ov_errmsg      OUT NOCOPY VARCHAR2    -- ユーザー・エラー・メッセージ --# 固定 #

    )

    IS

      -- *** ローカル定数 ***

      ln_deliv_cnt NUMBER DEFAULT 0;  --配送No使用確認用カウンタ

-- Ver1.2 M.Hokkanji Start

      ln_header_cnt NUMBER DEFAULT 0; -- 対象配送No使用ヘッダ確認用カウンタ

-- Ver1.2 M.Hokkanji End

      -- *** ローカル定数 ***

      cv_sub_prg_name   CONSTANT VARCHAR2(100) := '[chk_finish_delivery_no]'; -- サブプログラム名

-- Ver1.2 M.Hokkanji Start

      cv_yes            CONSTANT VARCHAR2(1) := 'Y';    -- YES

-- Ver1.2 M.Hokkanji End

--

      -- ローカルカーソル

      CURSOR get_delivery_no(in_delivery_no xxwsh_carriers_schedule.delivery_no%TYPE) IS

        SELECT  COUNT(xcs.delivery_no) delivery_no_cnt  -- 配送No

          FROM  xxwsh_carriers_schedule xcs             -- 配車配送計画アドオン

         WHERE  xcs.delivery_no = in_delivery_no

           AND  ROWNUM          = 1

        ;

    BEGIN

debug_log(FND_FILE.LOG,'前回配送No使用確認');

      -- 使用可否フラグ初期化

      ov_finish_flag := cv_possibility;

      --配送No使用確認カーソルオープン

      OPEN get_delivery_no(in_delivery_no);

      FETCH get_delivery_no  INTO ln_deliv_cnt;

      CLOSE get_delivery_no;

      IF (ln_deliv_cnt > 0) THEN

-- Ver1.2 M.Hokkanji Start

--debug_log(FND_FILE.LOG,'前回配送No:'||in_delivery_no||' 使用不可');

debug_log(FND_FILE.LOG,'前回配送No:'||in_delivery_no||' 配車配送計画存在有');

-- 対象の配送Noを使用している各ヘッダが、自動配車ソート用中間テーブルに全て

-- 存在する場合は、既存の配送Noは再採番されるため使用可とする。

-- 

        SELECT COUNT(a.request_no)

          INTO ln_header_cnt

          FROM ( SELECT xoh.delivery_no delivery_no,

                        xoh.request_no request_no

                   FROM xxwsh_order_headers_all xoh

                  WHERE xoh.delivery_no = in_delivery_no

                    AND xoh.latest_external_flag = cv_yes

                 UNION ALL

                 SELECT xmrih.delivery_no delivery_no,

                        xmrih.mov_num request_no

                   FROM xxinv_mov_req_instr_headers xmrih

                  WHERE xmrih.delivery_no = in_delivery_no

               ) a

        WHERE NOT EXISTS (

                SELECT xcst.request_no

                  FROM xxwsh_carriers_sort_tmp xcst

                 WHERE xcst.request_no = a.request_no

              )

          AND ROWNUM = 1;

        IF (ln_header_cnt > 0) THEN

debug_log(FND_FILE.LOG,'前回配送No:'||in_delivery_no||' 使用不可');

          ov_finish_flag := cv_impossibility; -- 使用不可

        END IF;

      END IF;

-- Ver1.2 M.Hokkanji End

--

--      <<chk_delivery_no_loop>>

--      FOR ln_cnt IN get_delivery_no(in_delivery_no) LOOP

--

--        IF (ln_cnt.delivery_no_cnt > 0) THEN

--

--debug_log(FND_FILE.LOG,'前回配送No使用不可');

--          ov_finish_flag := cv_impossibility; -- 使用不可

--

--        END IF;

--

--      END LOOP chk_delivery_no_loop;

--

    EXCEPTION

      -- *** 共通関数例外ハンドラ ***

      WHEN global_api_expt THEN

        ov_errmsg  := lv_errmsg;

        ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||cv_sub_prg_name||gv_msg_part||

                              lv_errbuf,1,5000);

        ov_retcode := gv_status_error;

      -- *** 共通関数OTHERS例外ハンドラ ***

      WHEN global_api_others_expt THEN

        ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||cv_sub_prg_name||gv_msg_part||SQLERRM;

        ov_retcode := gv_status_error;

      -- *** OTHERS例外ハンドラ ***

      WHEN OTHERS THEN

        ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||cv_sub_prg_name||gv_msg_part||SQLERRM;

        ov_retcode := gv_status_error;

    END  chk_finish_delivery_no;

--

    -- ======================

    -- キーブレイク処理

    -- ======================

    PROCEDURE lproc_keybrake_process(

        ov_errbuf      OUT NOCOPY VARCHAR2    -- エラー・メッセージ           --# 固定 #

      , ov_retcode     OUT NOCOPY VARCHAR2    -- リターン・コード             --# 固定 #

      , ov_errmsg      OUT NOCOPY VARCHAR2    -- ユーザー・エラー・メッセージ --# 固定 #

    )

    IS

      -- *** ローカル定数 ***

      cv_sub_prg_name   CONSTANT VARCHAR2(100) := '[lproc_keybrake_process]'; -- サブプログラム名

    BEGIN

--

debug_log(FND_FILE.LOG,'キーブレイク処理');

debug_log(FND_FILE.LOG,'配送グループ内の前回配送No数:'||lt_prev_delivery_no_tab.COUNT);

--2008.05.22 D.Sugahara 不具合No10対応->

          ln_chk_1 := ln_start_cnt - 1; --前回配送No配列の開始位置を設定(-1する)

--2008.05.22 D.Sugahara 不具合No10対応<-

          -- 配送グループ内の全前回配送Noを使用済確認する

          <<prev_delivery_no_chk>>

          FOR i IN 1..lt_prev_delivery_no_tab.COUNT LOOP

--

            -- カウンタ

            ln_chk_1 := ln_chk_1 + 1;

            IF (ln_chk_1 > lt_prev_delivery_no_tab.COUNT) THEN

              EXIT;

            END IF;

debug_log(FND_FILE.LOG,'1 前回配送No:'|| lt_prev_delivery_no_tab(ln_chk_1));

debug_log(FND_FILE.LOG,'カウンタ:'|| ln_chk_1);

            IF lt_prev_delivery_no_tab(ln_chk_1) IS NOT NULL THEN

--

debug_log(FND_FILE.LOG,'1-2前回配送No使用済確認(配車配送アドオン)');

              -- 前回配送No使用済確認(配車配送アドオン)

              chk_finish_delivery_no(

                  in_delivery_no => lt_prev_delivery_no_tab(ln_chk_1)

                , ov_finish_flag => lv_possible_flag

                , ov_errbuf      => lv_errbuf

                , ov_retcode     => lv_retcode

                , ov_errmsg      => lv_errmsg

              );

              -- 処理がエラーの場合

              IF (lv_retcode = gv_status_error) THEN

                RAISE global_api_expt;

              END IF;

--

              -- 配車配送アドオンで使用されていない場合、

              IF (lv_possible_flag = cv_possibility) THEN

debug_log(FND_FILE.LOG,'1-1-1前回配送No使用可能（配車配送アドオンチェック）');

--

                -- 現在処理中グループ内の配送Noが既に処理済の配送Noと重複しないか確認

debug_log(FND_FILE.LOG,'現在処理中グループ内の配送No数:'||lt_upd_delivery_no_tab.COUNT);

                lb_used_flag := FALSE;

                FOR cnt_2 IN 1..lt_upd_delivery_no_tab.COUNT LOOP

--

debug_log(FND_FILE.LOG,'2-1-1-1現在処理中グループ内確認');

debug_log(FND_FILE.LOG,'cnt_2   :'||cnt_2);

debug_log(FND_FILE.LOG,'ln_chk_1:'||ln_chk_1);

debug_log(FND_FILE.LOG,'2 対象配送No:'|| lt_upd_delivery_no_tab(cnt_2));

                  IF (lt_upd_delivery_no_tab(cnt_2) = lt_prev_delivery_no_tab(ln_chk_1)) THEN

--

debug_log(FND_FILE.LOG,'2-1-1-2現在処理中グループ使用済み');

                    lb_used_flag := TRUE;

                    EXIT;

--

                  END IF;

--

                END LOOP;

debug_log(FND_FILE.LOG,'ループ終了');

--

                -- 配車配送計画アドオンでも処理中データで使用されていない場合は採用

                IF (NOT lb_used_flag) THEN

debug_log(FND_FILE.LOG,'3 採用：'||lt_prev_delivery_no_tab(ln_chk_1));

                  -- 確定配送Noにセット

                  lt_decision_delivery_no := lt_prev_delivery_no_tab(ln_chk_1);

                  EXIT;

                END IF;

--

              END IF;

--

            END IF;

--

          END LOOP prev_delivery_no_chk;

--

--debug_log(FND_FILE.LOG,'★2現在処理中グループ内の配送チェック件数：'||lt_prev_delivery_no_tab.COUNT);

--

          -- 確定配送NoがNULLの場合は採番する

          IF (lt_decision_delivery_no IS NULL) THEN

--

debug_log(FND_FILE.LOG,'4 配送No採番');

            -- 共通関数：採番関数

            xxcmn_common_pkg.get_seq_no(

                  iv_seq_class  => cv_delivery_kbn

                , ov_seq_no     => lt_decision_delivery_no

                , ov_errbuf     => lv_errbuf

                , ov_retcode    => lv_retcode

                , ov_errmsg     => lv_errmsg

            );

            -- 処理がエラーの場合

            IF (lv_retcode = gv_status_error) THEN

              -- エラーメッセージ取得

              lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(

                              gv_xxwsh            -- モジュール名略称：XXWSH 出荷・引当/配車

                            , gv_msg_xxwsh_11805  -- メッセージ：APP-XXWSH-11805 配送No取得エラー

                            , gv_tkn_errmsg       -- トークン：ERRMSG

                            , lv_errmsg           -- 共通関数のエラーメッセージ

                           ),1,5000);

              RAISE global_process_expt;

            END IF;

debug_log(FND_FILE.LOG,'3-1');

-- Ver1.2 M.Hokkanji Start

          -- 既存の配送Noを使用する場合は配車配送計画に存在する配送を削除する。

          ELSE

debug_log(FND_FILE.LOG,'4a 既存配送No削除処理');

            BEGIN

              DELETE xxwsh_carriers_schedule xcs

               WHERE xcs.delivery_no = lt_decision_delivery_no;

            EXCEPTION

              WHEN NO_DATA_FOUND THEN

                NULL; -- 削除データが存在しない場合は処理続行

            END;

debug_log(FND_FILE.LOG,'4b 既存配送No削除処理終了');

-- Ver1.2 M.Hokkanji End

--

          END IF;

--

debug_log(FND_FILE.LOG,'5 採番結果：'||lt_decision_delivery_no);

          -- 更新用PL/SQL表にセットする

--

          -- 配送No設定用カウンタセット

          ln_reg_cnt := ln_start_cnt - 1;

--

debug_log(FND_FILE.LOG,'5a配送No設定用カウンタ開始='||ln_start_cnt);

debug_log(FND_FILE.LOG,'5b配送No設定用カウンタ終了='||ln_end_cnt);

          <<deliver_no_decision_loop>>

          FOR i IN ln_start_cnt..ln_end_cnt LOOP

--

            ln_reg_cnt := ln_reg_cnt + 1;

debug_log(FND_FILE.LOG,'6-1配送NOをPLSQL表に設定：'||lt_decision_delivery_no);

            -- 配送NOを設定する

            lt_upd_delivery_no_tab(ln_reg_cnt)  := lt_decision_delivery_no;

--

          END LOOP deliver_no_decision_loop;

--

-- 20080603 K.Yamane 不具合No11->

--debug_log(FND_FILE.LOG,'6前回配送No用PL/SQL表初期化');

          -- 前回配送No用PL/SQL表初期化

--          lt_prev_delivery_no_tab.DELETE;

--debug_log(FND_FILE.LOG,'7前回配送No用PL/SQL表初期化後カウント：'||lt_prev_delivery_no_tab.count);

-- 20080603 K.Yamane 不具合No11<-

debug_log(FND_FILE.LOG,'7前回配送No用PL/SQL表カウント：'||lt_prev_delivery_no_tab.count);

    EXCEPTION

      -- *** 共通関数例外ハンドラ ***

      WHEN global_api_expt THEN

        ov_errmsg  := lv_errmsg;

        ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||cv_sub_prg_name||gv_msg_part||

                              lv_errbuf,1,5000);

        ov_retcode := gv_status_error;

      -- *** 共通関数OTHERS例外ハンドラ ***

      WHEN global_api_others_expt THEN

        ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||cv_sub_prg_name||gv_msg_part||SQLERRM;

        ov_retcode := gv_status_error;

      -- *** OTHERS例外ハンドラ ***

      WHEN OTHERS THEN

        ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||cv_sub_prg_name||gv_msg_part||SQLERRM;

        ov_retcode := gv_status_error;

    END  lproc_keybrake_process;

--

  BEGIN

--

--##################  固定ステータス初期化部 START   ###################

--

    ov_retcode := gv_status_normal;

--

--###########################  固定部 END   ############################

--

debug_log(FND_FILE.LOG,'【B-13 配送No設定処理】');

--

    -- 変数初期化

    lt_decision_delivery_no   := NULL;  -- 確定配送No

--

    -- PL/SQL表初期化

    lt_delivery_no_dat.DELETE;        -- カーソルデータ取得用

    lt_intensive_no_tab.DELETE;       -- 集約No

    lt_delivery_no_tab.DELETE;        -- 配送No

    lt_request_no_tab.DELETE;         -- 依頼No/移動No

    lt_upd_delivery_no_tab.DELETE;    -- 更新用配送No

    lt_prev_delivery_no_tab.DELETE;   -- 前回配送No

    lt_prev_request_no_tab.DELETE;    -- 集約前依頼No/移動No

    lt_fin_delivery_no_tab.DELETE;    -- 使用済配送No

--

    -- ==========================

    --  配送Noセット

    -- ==========================

    -- オープンカーソル

    OPEN  set_delivery_no_cur;

    FETCH set_delivery_no_cur BULK COLLECT INTO lt_delivery_no_dat;

    CLOSE set_delivery_no_cur;

--

    IF (lt_delivery_no_dat.COUNT > 0) THEN

debug_log(FND_FILE.LOG,'カーソルデータカウント：'|| lt_delivery_no_dat.COUNT);

      <<set_delivery_no_loop>>

      LOOP

--

        -- ループカウント

        ln_loop_cnt := ln_loop_cnt + 1;

debug_log(FND_FILE.LOG,'ループカウント：'|| ln_loop_cnt);

debug_cnt := debug_cnt +1;

--

        -- 配送グループ内カウント

        ln_delivery_grp_cnt := ln_delivery_grp_cnt + 1;

debug_log(FND_FILE.LOG,'配送グループカウンタ：'||ln_delivery_grp_cnt);

--

        -- 配送グループ1件目の情報を確保する

        IF (ln_delivery_grp_cnt = 1) THEN

--

debug_log(FND_FILE.LOG,'基準レコードをセット');

--

          -- グループ開始カウントを保持

          ln_start_cnt := ln_loop_cnt;

--

          -- 比較用変数に格納

          lt_bf_request_no        := lt_delivery_no_dat(ln_loop_cnt).req_no;      -- 依頼No/移動No

          lt_bf_delivery_no       := lt_delivery_no_dat(ln_loop_cnt).delivery_no; -- 配送No(配送グループ)

          lt_bf_prev_delivery_no  := lt_delivery_no_dat(ln_loop_cnt).prev_delivery_no; -- 前回配送No

debug_log(FND_FILE.LOG,'依頼No/移動No:'||lt_bf_request_no);

debug_log(FND_FILE.LOG,'配送No(配送グループ):'||lt_bf_delivery_no);

debug_log(FND_FILE.LOG,'前回配送No:'||lt_bf_prev_delivery_no);

debug_log(FND_FILE.LOG,'---------------------------');

--

        END IF;

--

--

        -- キーブレイクしない

        IF (NVL(lt_bf_delivery_no, 0) = NVL(lt_delivery_no_dat(ln_loop_cnt).delivery_no, 0))

          AND (lb_last_data_flag = FALSE)

        THEN

                                                                                -- 同一配送グループ

debug_log(FND_FILE.LOG,'同一配送グループ');

--

-- Ver1.2 M.Hokkanji Start

          -- 現在配送Noが設定されている場合は現在の配送Noを使用

          IF (lt_delivery_no_dat(ln_loop_cnt).use_delivery_no IS NOT NULL ) THEN

            lt_prev_delivery_no_tab(ln_loop_cnt) := lt_delivery_no_dat(ln_loop_cnt).use_delivery_no;

          ELSE

            -- 前回配送NoをPL/SQL表に格納

            lt_prev_delivery_no_tab(ln_loop_cnt) := lt_delivery_no_dat(ln_loop_cnt).prev_delivery_no;

          END IF;

debug_log(FND_FILE.LOG,'比較用配送No:'||lt_prev_delivery_no_tab(ln_loop_cnt));

--debug_log(FND_FILE.LOG,'前回配送No:'||lt_prev_delivery_no_tab(ln_loop_cnt));

-- Ver1.2 M.Hokkanji End

--

          -- 集約No

          lt_intensive_no_tab(ln_loop_cnt) := lt_delivery_no_dat(ln_loop_cnt).int_no;

debug_log(FND_FILE.LOG,'集約No:'||lt_delivery_no_dat(ln_loop_cnt).int_no);

--

          -- 配送No

          lt_delivery_no_tab(ln_loop_cnt)  := lt_delivery_no_dat(ln_loop_cnt).delivery_no;

debug_log(FND_FILE.LOG,'仮配送No:'||lt_delivery_no_dat(ln_loop_cnt).delivery_no);

debug_log(FND_FILE.LOG,'---------------------------');

--

        -- キーブレイク

        ELSE

--

debug_log(FND_FILE.LOG,'キーブレイク');

          -- 終了カウントを確保

          ln_end_cnt := ln_loop_cnt - 1;

--

          -- キーブレイク処理

          lproc_keybrake_process(

              ov_errbuf      => lv_errbuf

            , ov_retcode     => lv_retcode

            , ov_errmsg      => lv_errmsg

          );

          -- 処理がエラーの場合

          IF (lv_retcode = gv_status_error) THEN

            RAISE global_api_expt;

          END IF;

--

          -- 配送グループカウント初期化

          ln_delivery_grp_cnt := 0;

--

          -- ループカウント初期化(次の配送グループを処理)

          ln_loop_cnt := ln_end_cnt;

          -- 配送No初期化

          lt_decision_delivery_no := NULL;

--

          -- 比較用変数に格納

          lt_bf_request_no        := lt_delivery_no_dat(ln_loop_cnt).req_no;            -- 依頼No/移動No

          lt_bf_delivery_no       := lt_delivery_no_dat(ln_loop_cnt).delivery_no;       -- 配送No

          lt_bf_prev_delivery_no  := lt_delivery_no_dat(ln_loop_cnt).prev_delivery_no;  -- 前回配送No

--

        END IF;

--

        IF (ln_loop_cnt = lt_delivery_no_dat.COUNT) THEN

debug_log(FND_FILE.LOG,'最終レコード処理');

          ln_end_cnt := ln_loop_cnt;

          -- キーブレイク処理

          lproc_keybrake_process(

              ov_errbuf      => lv_errbuf

            , ov_retcode     => lv_retcode

            , ov_errmsg      => lv_errmsg

          );

          -- 処理がエラーの場合

          IF (lv_retcode = gv_status_error) THEN

            RAISE global_api_expt;

          END IF;

debug_log(FND_FILE.LOG,'終了フラグ：TRUE');

          lb_last_data_flag := TRUE;

--

        END IF;

--

        EXIT WHEN lb_last_data_flag;

/*if (debug_cnt >= 100) then

  exit;

debug_log(FND_FILE.LOG,'■強制EXIT');

end if;

*/

      END LOOP set_delivery_no_loop;

--

debug_log(FND_FILE.LOG,'ループ処理');

    END IF;

--

    -- ==========================

    --  配送No.一括更新処理

    -- ==========================

debug_log(FND_FILE.LOG,'配送No.一括更新処理');

debug_log(FND_FILE.LOG,'登録数：'||lt_intensive_no_tab.COUNT);

/*

for i in 1..lt_intensive_no_tab.COUNT loop

debug_log(FND_FILE.LOG,'集約No：'|| lt_intensive_no_tab(i));

debug_log(FND_FILE.LOG,'配送No：'|| lt_delivery_no_tab(i));

debug_log(FND_FILE.LOG,'確定配送No：'|| lt_upd_delivery_no_tab(i));

debug_log(FND_FILE.LOG,'-------------------------------');

end loop;

*/

    FORALL upd_cnt IN 1..lt_intensive_no_tab.COUNT

      UPDATE  xxwsh_mixed_carriers_tmp                      -- 自動配車混載中間テーブル

         SET  delivery_no = lt_upd_delivery_no_tab(upd_cnt) -- 配送No

       WHERE  intensive_no = lt_intensive_no_tab(upd_cnt)   -- 集約No

         AND  delivery_no = lt_delivery_no_tab(upd_cnt)     -- 配送No

      ;

--

debug_log(FND_FILE.LOG,'配送No設定処理終了');

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

  END set_delivery_no;

--

  /**********************************************************************************

   * Procedure Name   : set_small_sam_class

   * Description      : 小口配送情報作成処理

   ***********************************************************************************/

  PROCEDURE set_small_sam_class(

-- 2008/10/16 H.Itou Add Start T_S_625 集約Noごとに処理を行うように変更

    iv_intensive_no IN VARCHAR2,           -- 集約No

-- 2008/10/16 H.Itou Add End

-- 2008/10/30 H.Itou Add Start 統合テスト指摘526 リーフの場合の配送区分を指定

    iv_ship_method  IN VARCHAR2,           -- 配送区分

-- 2008/10/30 H.Itou Add End

    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #

    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #

    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #

  IS

    -- ===============================

    -- 固定ローカル定数

    -- ===============================

    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_small_sam_class'; -- プログラム名

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

    cv_an_object      CONSTANT VARCHAR2(1)  := '1';     -- 対象

    cv_yes            CONSTANT VARCHAR2(1)  := 'Y';     -- YES

    cv_small_amount_b CONSTANT VARCHAR2(2)  := '11';    -- 小口B

    cv_small_amount_a CONSTANT VARCHAR2(2)  := '12';    -- 小口A

-- 2009/01/08 H.Itou Add Start 本番障害#558

    cv_small_amount_2 CONSTANT VARCHAR2(2)  := '15';    -- 2t車小口

-- 2009/01/08 H.Itou Add End

--

    -- *** ローカル変数 ***

    -- 自動配車集約中間テーブル登録用PL/SQL表

    lt_int_no_tab         intensive_no_ttype;     -- 集約No(削除用)

    lt_tran_type_tab      transaction_type_ttype; -- 処理種別

    lt_int_source_tab     int_source_no_ttype;    -- 集約元No

    lt_deli_from_tab      deliver_from_ttype;     -- 配送元

    lt_deli_from_id_tab   deliver_from_id_ttype;  -- 配送元ID

    lt_deli_to_tab        deliver_to_ttype;       -- 配送先

    lt_deli_to_id_tab     deliver_to_id_ttype;    -- 配送先ID

    lt_ship_date_tab      sche_ship_date_ttype;   -- 出庫予定日

    lt_arvl_date_tab      sche_arvl_date_ttype;   -- 着荷予定日

    lt_tran_type_nm_tab   tran_type_name_ttype;   -- 出庫形態

    lt_carrier_code_tab   freight_carry_cd_ttype; -- 運送業者

    lt_carrier_id_tab     carrier_id_ttype;       -- 運送業者ID

    lt_sum_weight_tab     int_sum_weight_ttype;   -- 集約合計重量

    lt_sum_capa_tab       int_sum_capa_ttype;     -- 集約合計容積

    lt_max_ship_cd_tab    max_ship_cd_ttype;      -- 最大配送区分

    lt_weight_capa_tab    weight_capa_cls_ttype;  -- 重量容積区分

    lt_max_weight_tab     max_weight_ttype;       -- 最大積載重量

    lt_max_capa_tab       max_capacity_ttype;     -- 最大積載容積

    lt_base_weight_tab    based_weight_ttype;     -- 基本重量

    lt_base_capa_tab      based_capa_ttype;       -- 基本容積

    lt_delivery_no_tab    delivery_no_ttype;      -- 配送No

    lt_fix_ship_method_cd fixed_ship_code_ttype;  -- 修正配送区分

    lt_sum_case_qty_tab   case_quantity_ttype;    -- ケース数

    lt_ins_int_no_tab     intensive_no_ttype;     -- 集約No(登録用)

--

    -- 自動配車集約中間明細テーブル登録用PL/SQL表

    lt_int_no_lines_tab intensive_no_ttype;     -- 集約No

    lt_request_no_tab   request_no_ttype;       -- 依頼No

--

    -- 自動配車混載中間テーブル登録用PL/SQL表

    lt_intensive_no_tab           intensive_no_ttype;         -- 集約No

    lt_mixed_delivery_no_tab      delivery_no_ttype;          -- 配送No

    lt_fixed_ship_code_tab        fixed_ship_code_ttype;      -- 修正配送区分

    lt_mixed_class_tab            mixed_class_ttype;          -- 混載種別

    lt_mixed_total_weight_tab     mixed_total_weight_ttype;   -- 混載合計重量

    lt_mixed_total_capacity_tab   mixed_total_capacity_ttype; -- 混載合計容積

    lt_mixed_no_tab               mixed_no_ttype;             -- 混載元No

--

    ln_loop_cnt       NUMBER DEFAULT 0;                           -- ループカウント(集約)

    ln_loop_cnt_2     NUMBER DEFAULT 0;                           -- ループカウント(混載)

    ln_intensive_no   NUMBER DEFAULT 0;                           -- 集約Noシーケンス用

    lt_max_case_qty   xxwsh_ship_method_v.max_case_quantity%TYPE; -- 最大ケース数

    ln_temp_ship_no   NUMBER;                                     -- 仮配送No

--

    TYPE get_cur_rtype IS RECORD(

        int_no              xxwsh_intensive_carriers_tmp.intensive_no%TYPE             -- 集約No

      , ship_type           xxwsh_intensive_carriers_tmp.transaction_type%TYPE         -- 処理種別:出荷依頼

      , int_source_no       xxwsh_intensive_carriers_tmp.intensive_source_no%TYPE      -- 集約元No

-- 2008/10/16 H.Itou Del Start T_S_625

--      , delivery_no         xxwsh_mixed_carriers_tmp.delivery_no%TYPE                  -- 配送No

-- 2008/10/16 H.Itou Del End

      , req_no              xxwsh_order_headers_all.request_no%TYPE                    -- 依頼No

      , deliver_from        xxwsh_order_headers_all.deliver_from%TYPE                  -- 出荷元保管場所

      , deliver_from_id     xxwsh_order_headers_all.deliver_from_id%TYPE               -- 出荷元ID

      , deliver_to          xxwsh_order_headers_all.deliver_to%TYPE                    -- 出荷先

      , deliver_to_id       xxwsh_order_headers_all.deliver_to_id%TYPE                 -- 出荷先ID

      , ship_date           xxwsh_order_headers_all.schedule_ship_date%TYPE            -- 出荷予定日

      , arrival_date        xxwsh_order_headers_all.schedule_arrival_date%TYPE         -- 着荷予定日

      , tran_type           xxwsh_order_headers_all.order_type_id%TYPE                 -- 出庫形態ID

      , tran_type_name      xxwsh_oe_transaction_types_v.transaction_type_name%TYPE    -- 出庫形態名

      , carry_code          xxwsh_order_headers_all.freight_carrier_code%TYPE          -- 運送業者

      , career_id           xxwsh_order_headers_all.career_id%TYPE                     -- 運送業者ID

      , sum_weight          xxwsh_order_headers_all.sum_weight%TYPE                    -- 積載重量合計

      , sum_capacity        xxwsh_order_headers_all.sum_capacity%TYPE                  -- 積載容積合計

      , max_ship_method     xxwsh_intensive_carriers_tmp.max_shipping_method_code%TYPE -- 最大配送区分

      , w_c_class           xxwsh_order_headers_all.weight_capacity_class%TYPE         -- 重量容積区分

      , max_weight          xxwsh_intensive_carriers_tmp.max_weight%TYPE               -- 最大積載重量

      , max_capacity        xxwsh_intensive_carriers_tmp.max_capacity%TYPE             -- 最大積載容積

-- 2008/10/16 H.Itou Del Start T_S_625

--      , fix_ship_method_cd  xxwsh_mixed_carriers_tmp.fixed_shipping_method_code%TYPE   -- 修正配送区分

-- 2008/10/16 H.Itou Del End

      , small_quantity      xxwsh_order_headers_all.small_quantity%TYPE                -- 小口個数

    );

--

    TYPE get_cur_ttype IS TABLE OF get_cur_rtype INDEX BY BINARY_INTEGER;

--

    -- *** ローカル・カーソル ***

    CURSOR small_amount_cur IS

      SELECT  xict.intensive_no               int_no              -- 集約No

            , xict.transaction_type           ship_type           -- 処理種別:出荷依頼

            , xict.intensive_source_no        int_source_no       -- 集約元No

-- 2008/10/16 H.Itou Del Start T_S_625

--            , xmct.delivery_no                delivery_no         -- 配送No

-- 2008/10/16 H.Itou Del End

            , xoha.request_no                 req_no              -- 依頼No

            , xoha.deliver_from               deliver_from        -- 出荷元保管場所

            , xoha.deliver_from_id            deliver_from_id     -- 出荷元ID

            , xoha.deliver_to                 deliver_to          -- 出荷先

            , xoha.deliver_to_id              deliver_to_id       -- 出荷先ID

            , xoha.schedule_ship_date         ship_date           -- 出荷予定日

            , xoha.schedule_arrival_date      arrival_date        -- 着荷予定日

            , xoha.order_type_id              tran_type           -- 出庫形態ID

            , xotv.transaction_type_name      tran_type_name      -- 出庫形態名

            , xoha.freight_carrier_code       carry_code          -- 運送業者

            , xoha.career_id                  career_id           -- 運送業者ID

            , xoha.sum_weight                 sum_weight          -- 積載重量合計

            , xoha.sum_capacity               sum_capacity        -- 積載容積合計

            , xict.max_shipping_method_code   max_ship_method     -- 最大配送区分

            , xoha.weight_capacity_class      w_c_class           -- 重量容積区分

            , xict.max_weight                 max_weight          -- 最大積載重量

            , xict.max_capacity               max_capacity        -- 最大積載容積

-- 2008/10/16 H.Itou Del Start T_S_625

--            , xmct.fixed_shipping_method_code fix_ship_method_cd  -- 修正配送区分

-- 2008/10/16 H.Itou Del End

            , xoha.small_quantity             small_quantity      -- 小口個数

-- 2008/10/16 H.Itou Del Start T_S_625

--        FROM  xxwsh_mixed_carriers_tmp        xmct                -- 自動配車混載中間テーブル

-- 2008/10/16 H.Itou Del End

-- 2008/10/16 H.Itou Mod Start T_S_625

--            , xxwsh_intensive_carriers_tmp    xict                -- 自動配車集約中間テーブル

         FROM xxwsh_intensive_carriers_tmp   xict                -- 自動配車集約中間テーブル

-- 2008/10/16 H.Itou Mod End

            , xxwsh_intensive_carrier_ln_tmp  xicl                -- 自動配車集約中間明細テーブル

            , xxwsh_order_headers_all         xoha                -- 受注ヘッダアドオン

-- 2008/10/16 H.Itou Del Start T_S_625

--            , xxwsh_ship_method_v             xsmv                -- 配送区分情報View

-- 2008/10/16 H.Itou Del End

            , xxwsh_oe_transaction_types_v    xotv                -- 受注タイプ情報View

-- 2008/10/16 H.Itou Del Start T_S_625

--       WHERE  xict.intensive_no = xmct.intensive_no               -- 集約No

-- 2008/10/16 H.Itou Del End

-- 2008/10/16 H.Itou Mod Start T_S_625

--         AND  xict.intensive_no = xicl.intensive_no               -- 集約No

       WHERE  xict.intensive_no = xicl.intensive_no               -- 集約No

-- 2008/10/16 H.Itou Mod End

-- 2008/10/16 H.Itou Del Start T_S_625

--         AND  xmct.fixed_shipping_method_code = xsmv.ship_method_code

--                                                                  -- 配送区分

--         AND  xsmv.small_amount_class = cv_an_object              -- 小口区分

-- 2008/10/16 H.Itou Del End

         AND  xicl.request_no = xoha.request_no                   -- 依頼No

         AND  xoha.latest_external_flag = cv_yes                  -- 最新フラグ

         AND  xoha.order_type_id = xotv.transaction_type_id       -- 取引タイプID

-- 2008/10/16 H.Itou Add Start T_S_625

         AND  xict.intensive_no = iv_intensive_no                 -- 集約No

-- 2008/10/16 H.Itou Add End

-- Ver1.7 M.Hokkanji START

--         AND  xoha.mixed_no IS NULL                               -- 混載元No

-- Ver1.7 M.Hokkanji END

      UNION ALL

      SELECT  xict.intensive_no               int_no              -- 集約No

            , xict.transaction_type           ship_type           -- 処理種別:出荷依頼

            , xict.intensive_source_no        int_source_no       -- 集約元No

-- 2008/10/16 H.Itou Del Start T_S_625

--            , xmct.delivery_no                delivery_no         -- 配送No

-- 2008/10/16 H.Itou Del End

            , xmrih.mov_num                   req_no              -- 依頼No

            , xmrih.shipped_locat_code        deliver_from        -- 出荷元保管場所

            , xmrih.shipped_locat_id          deliver_from_id     -- 出荷元ID

            , xmrih.ship_to_locat_code        deliver_to          -- 出荷先

            , xmrih.ship_to_locat_id          deliver_to_id       -- 出荷先ID

            , xmrih.schedule_ship_date        ship_date           -- 出荷予定日

            , xmrih.schedule_arrival_date     arrival_date        -- 着荷予定日

            , NULL                            tran_type           -- 出庫形態ID

            , NULL                            tran_type_name      -- 出庫形態名

            , xmrih.freight_carrier_code      carry_code          -- 運送業者

            , xmrih.career_id                 career_id           -- 運送業者ID

            , xmrih.sum_weight                sum_weight          -- 積載重量合計

            , xmrih.sum_capacity              sum_capacity        -- 積載容積合計

            , xict.max_shipping_method_code   max_ship_method     -- 最大配送区分

            , xmrih.weight_capacity_class     w_c_class           -- 重量容積区分

            , xict.max_weight                 max_weight          -- 最大積載重量

            , xict.max_capacity               max_capacity        -- 最大積載容積

-- 2008/10/16 H.Itou Del Start T_S_625

--            , xmct.fixed_shipping_method_code fix_ship_method_cd  -- 修正配送区分

-- 2008/10/16 H.Itou Del End

            , xmrih.small_quantity            small_quantity      -- 小口個数

-- 2008/10/16 H.Itou Del Start T_S_625

--        FROM  xxwsh_mixed_carriers_tmp        xmct                -- 自動配車混載中間テーブル

-- 2008/10/16 H.Itou Del End

-- 2008/10/16 H.Itou Mod Start T_S_625

         FROM xxwsh_intensive_carriers_tmp    xict                -- 自動配車集約中間テーブル

-- 2008/10/16 H.Itou Mod End

            , xxwsh_intensive_carrier_ln_tmp  xicl                -- 自動配車集約中間明細テーブル

            , xxinv_mov_req_instr_headers     xmrih               -- 移動依頼/指示ヘッダアドオン

-- 2008/10/16 H.Itou Del Start T_S_625

--            , xxwsh_ship_method_v             xsmv                -- 配送区分情報View

-- 2008/10/16 H.Itou Del End

-- 2008/10/16 H.Itou Del Start T_S_625

--       WHERE  xict.intensive_no = xmct.intensive_no               -- 集約No

-- 2008/10/16 H.Itou Del End

-- 2008/10/16 H.Itou Mod Start T_S_625

--         AND  xict.intensive_no = xicl.intensive_no               -- 集約No

       WHERE  xict.intensive_no = xicl.intensive_no               -- 集約No

-- 2008/10/16 H.Itou Mod End

-- 2008/10/16 H.Itou Del Start T_S_625

--         AND  xmct.fixed_shipping_method_code = xsmv.ship_method_code

--                                                                  -- 配送区分

--         AND  xsmv.small_amount_class = cv_an_object              -- 小口区分

-- 2008/10/16 H.Itou Del End

         AND  xicl.request_no = xmrih.mov_num                     -- 依頼No

-- 2008/10/16 H.Itou Add Start T_S_625

         AND  xict.intensive_no = iv_intensive_no                 -- 集約No

-- 2008/10/16 H.Itou Add End

      ;

--

    -- *** ローカル・レコード ***

    lt_get_tab get_cur_ttype;

--

  BEGIN

--

--##################  固定ステータス初期化部 START   ###################

--

    ov_retcode := gv_status_normal;

--

--###########################  固定部 END   ############################

--

debug_log(FND_FILE.LOG,'【小口配送情報作成処理】');

--

    -- PL/SQL表初期化

    lt_int_no_tab.DELETE;         -- 集約No

    lt_tran_type_tab.DELETE;      -- 処理種別

    lt_int_source_tab.DELETE;     -- 集約元No

    lt_deli_from_tab.DELETE;      -- 配送元

    lt_deli_from_id_tab.DELETE;   -- 配送元ID

    lt_deli_to_tab.DELETE;        -- 配送先

    lt_deli_to_id_tab.DELETE;     -- 配送先ID

    lt_ship_date_tab.DELETE;      -- 出庫予定日

    lt_arvl_date_tab.DELETE;      -- 着荷予定日

    lt_tran_type_nm_tab.DELETE;   -- 出庫形態

    lt_carrier_code_tab.DELETE;   -- 運送業者

    lt_carrier_id_tab.DELETE;     -- 運送業者ID

    lt_sum_weight_tab.DELETE;     -- 集約合計重量

    lt_sum_capa_tab.DELETE;       -- 集約合計容積

    lt_max_ship_cd_tab.DELETE;    -- 最大配送区分

    lt_weight_capa_tab.DELETE;    -- 重量容積区分

    lt_max_weight_tab.DELETE;     -- 最大積載重量

    lt_max_capa_tab.DELETE;       -- 最大積載容積

    lt_fix_ship_method_cd.DELETE; -- 修正配送区分

    lt_delivery_no_tab.DELETE;    -- 配送No

    lt_int_no_lines_tab.DELETE;   -- 集約No

    lt_request_no_tab.DELETE;     -- 依頼No

    lt_sum_case_qty_tab.DELETE;   -- ケース数

--

    -- 自動配車混載中間テーブル登録用PL/SQL表

    lt_intensive_no_tab.DELETE;         -- 集約No

    lt_mixed_delivery_no_tab.DELETE;    -- 配送No

    lt_fixed_ship_code_tab.DELETE;      -- 修正配送区分

    lt_mixed_class_tab.DELETE;          -- 混載種別

    lt_mixed_total_weight_tab.DELETE;   -- 混載合計重量

    lt_mixed_total_capacity_tab.DELETE; -- 混載合計容積

    lt_mixed_no_tab.DELETE;             -- 混載元No

--

-- 2009/01/08 H.Itou Add Start

    -- 小口B最大ケース数取得

    SELECT  xsmv.max_case_quantity    -- 最大ケース数

    INTO    lt_max_case_qty

    FROM    xxwsh_ship_method_v xsmv  -- クイックコード

    WHERE   xsmv.ship_method_code = cv_small_amount_b

    ;

debug_log(FND_FILE.LOG,'小口Bケース数:'||lt_max_case_qty);

-- 2009/01/08 H.Itou Add End

--

    OPEN small_amount_cur;

    FETCH small_amount_cur BULK COLLECT INTO lt_get_tab;

    CLOSE small_amount_cur;

--

    <<small_amount_loop>>

    FOR ln_cnt IN 1..lt_get_tab.COUNT LOOP

--

debug_log(FND_FILE.LOG,'処理開始');

--

      ln_loop_cnt := ln_loop_cnt + 1;

--

debug_log(FND_FILE.LOG,'ループカウント：'||ln_loop_cnt);

--

      -- PL/SQL表に格納

      lt_int_no_tab(ln_loop_cnt)          := lt_get_tab(ln_loop_cnt).int_no;          -- 集約No

      lt_tran_type_tab(ln_loop_cnt)       := lt_get_tab(ln_loop_cnt).ship_type;       -- 処理種別

      lt_int_source_tab(ln_loop_cnt)      := lt_get_tab(ln_loop_cnt).int_source_no;   -- 集約元No

      lt_deli_from_tab(ln_loop_cnt)       := lt_get_tab(ln_loop_cnt).deliver_from;    -- 配送元

      lt_deli_from_id_tab(ln_loop_cnt)    := lt_get_tab(ln_loop_cnt).deliver_from_id; -- 配送元ID

      lt_deli_to_tab(ln_loop_cnt)         := lt_get_tab(ln_loop_cnt).deliver_to;      -- 配送先

      lt_deli_to_id_tab(ln_loop_cnt)      := lt_get_tab(ln_loop_cnt).deliver_to_id;   -- 配送先ID

      lt_ship_date_tab(ln_loop_cnt)       := lt_get_tab(ln_loop_cnt).ship_date;       -- 出庫予定日

      lt_arvl_date_tab(ln_loop_cnt)       := lt_get_tab(ln_loop_cnt).arrival_date;    -- 着荷予定日

      lt_tran_type_nm_tab(ln_loop_cnt)    := lt_get_tab(ln_loop_cnt).tran_type;       -- 出庫形態

      lt_carrier_code_tab(ln_loop_cnt)    := lt_get_tab(ln_loop_cnt).carry_code;      -- 運送業者

      lt_carrier_id_tab(ln_loop_cnt)      := lt_get_tab(ln_loop_cnt).career_id;       -- 運送業者ID

      lt_sum_weight_tab(ln_loop_cnt)      := lt_get_tab(ln_loop_cnt).sum_weight;      -- 積載合計重量

      lt_sum_capa_tab(ln_loop_cnt)        := lt_get_tab(ln_loop_cnt).sum_capacity;    -- 積載合計容積

      lt_max_ship_cd_tab(ln_loop_cnt)     := lt_get_tab(ln_loop_cnt).max_ship_method; -- 最大配送区分

      lt_weight_capa_tab(ln_loop_cnt)     := lt_get_tab(ln_loop_cnt).w_c_class;       -- 重量容積区分

      lt_max_weight_tab(ln_loop_cnt)      := lt_get_tab(ln_loop_cnt).max_weight;      -- 最大積載重量

      lt_max_capa_tab(ln_loop_cnt)        := lt_get_tab(ln_loop_cnt).max_capacity;    -- 最大積載容積

-- 2008/10/16 H.Itou Del Start T_S_625

--      lt_fix_ship_method_cd(ln_loop_cnt)  := lt_get_tab(ln_loop_cnt).fix_ship_method_cd;

--                                                                                      -- 修正配送区分

--      lt_delivery_no_tab(ln_loop_cnt)     := lt_get_tab(ln_loop_cnt).delivery_no;     -- 配送No

-- 2008/10/16 H.Itou Del End

-- 2009/01/08 H.Itou Mod Start 本番障害#558 リーフの場合も配送区分を固定値(2t車小口)にする

---- 2008/10/30 H.Itou Mod Start 統合テスト指摘526 リーフの場合の配送区分が設定されないので、INパラメータで渡された値をセットする

--      lt_fix_ship_method_cd(ln_loop_cnt)  := iv_ship_method;                          -- 修正配送区分

---- 2008/10/30 H.Itou Mod End

      -- 修正配送区分

      -- ドリンクかつ、小口B最大ケース数より多い場合

      IF ((gv_prod_class = gv_prod_cls_drink)

      AND (lt_get_tab(ln_loop_cnt).small_quantity > lt_max_case_qty)) THEN

        lt_fix_ship_method_cd(ln_loop_cnt) := cv_small_amount_a;    -- 小口A

--

      -- ドリンクかつ、小口B最大ケース数以下の場合

      ELSIF ((gv_prod_class = gv_prod_cls_drink)

      AND    (lt_get_tab(ln_loop_cnt).small_quantity <= lt_max_case_qty)) THEN

        lt_fix_ship_method_cd(ln_loop_cnt) := cv_small_amount_b;    -- 小口B

--

      -- リーフの場合

      ELSE

        lt_fix_ship_method_cd(ln_loop_cnt) := cv_small_amount_2;    -- 2t車小口

      END IF;

-- 2009/01/08 H.Itou Mod End

      lt_request_no_tab(ln_loop_cnt)      := lt_get_tab(ln_loop_cnt).req_no;          -- 依頼No

      lt_sum_case_qty_tab(ln_loop_cnt)    := lt_get_tab(ln_loop_cnt).small_quantity;   -- ケース数

--

debug_log(FND_FILE.LOG,'PL/SQL表に格納');

debug_log(FND_FILE.LOG,'集約No:'||lt_int_no_tab(ln_loop_cnt) );

--

      -- 集約NO取得

      SELECT xxwsh_intensive_no_s1.NEXTVAL

      INTO   ln_intensive_no

      FROM   dual;

--

      lt_ins_int_no_tab(ln_loop_cnt)    := ln_intensive_no;         -- 集約No(登録用)

--

debug_log(FND_FILE.LOG,'登録用集約No:'||lt_ins_int_no_tab(ln_loop_cnt));

--

    END LOOP small_amount_loop;

--

    -- ==============================

    --  自動配車中間テーブル削除処理

    -- ==============================

    -- 取得した集約Noで各中間テーブルを削除する

    -- 自動配車集約中間テーブル

    FORALL ln_cnt_1 IN 1..lt_int_no_tab.COUNT

      DELETE FROM xxwsh_intensive_carriers_tmp

        WHERE intensive_no = lt_int_no_tab(ln_cnt_1)

    ;

--

debug_log(FND_FILE.LOG,'自動配車集約中間テーブル削除');

--

    -- 自動配車集約中間明細テーブル

    FORALL ln_cnt_2 IN 1..lt_int_no_tab.COUNT

      DELETE FROM xxwsh_intensive_carrier_ln_tmp

        WHERE intensive_no = lt_int_no_tab(ln_cnt_2)

    ;

--

debug_log(FND_FILE.LOG,'自動配車集約中間明細テーブル削除');

--

    -- 自動配車混載中間テーブル

    FORALL ln_cnt_3 IN 1..lt_int_no_tab.COUNT

      DELETE FROM xxwsh_mixed_carriers_tmp

        WHERE intensive_no = lt_int_no_tab(ln_cnt_3)

    ;

--

debug_log(FND_FILE.LOG,'自動配車混載中間テーブル削除');

--

--

debug_log(FND_FILE.LOG,'★自動配車集約中間テーブル登録：小口配送情報作成処理');

debug_log(FND_FILE.LOG,'登録数：'||lt_ins_int_no_tab.count);

debug_log(FND_FILE.LOG,'PLSQL表：lt_ins_int_no_tab');

    -- ==================================

    --  自動配車集約中間テーブル登録処理

    -- ==================================

    FORALL ln_cnt IN 1..lt_ins_int_no_tab.COUNT

      INSERT INTO xxwsh_intensive_carriers_tmp(   -- 自動配車集約中間テーブル

          intensive_no              -- 集約No

        , transaction_type          -- 処理種別

        , intensive_source_no       -- 集約元No

        , deliver_from              -- 配送元

        , deliver_from_id           -- 配送元ID

        , deliver_to                -- 配送先

        , deliver_to_id             -- 配送先ID

        , schedule_ship_date        -- 出庫予定日

        , schedule_arrival_date     -- 着荷予定日

        , transaction_type_name     -- 出庫形態

        , freight_carrier_code      -- 運送業者

        , carrier_id                -- 運送業者ID

        , intensive_sum_weight      -- 集約合計重量

        , intensive_sum_capacity    -- 集約合計容積

        , max_shipping_method_code  -- 最大配送区分

        , weight_capacity_class     -- 重量容積区分

        , max_weight                -- 最大積載重量

        , max_capacity              -- 最大積載容積

        )

        VALUES

        (

          lt_ins_int_no_tab(ln_cnt)     -- 集約No

        , lt_tran_type_tab(ln_cnt)      -- 処理種別

        , lt_int_source_tab(ln_cnt)     -- 集約元No

        , lt_deli_from_tab(ln_cnt)      -- 配送元

        , lt_deli_from_id_tab(ln_cnt)   -- 配送元ID

        , lt_deli_to_tab(ln_cnt)        -- 配送先

        , lt_deli_to_id_tab(ln_cnt)     -- 配送先ID

        , lt_ship_date_tab(ln_cnt)      -- 出庫予定日

        , lt_arvl_date_tab(ln_cnt)      -- 着荷予定日

        , lt_tran_type_nm_tab(ln_cnt)   -- 出庫形態

        , lt_carrier_code_tab(ln_cnt)   -- 運送業者

        , lt_carrier_id_tab(ln_cnt)     -- 運送業者ID

        , lt_sum_weight_tab(ln_cnt)     -- 集約合計重量

        , lt_sum_capa_tab(ln_cnt)       -- 集約合計容積

        , lt_max_ship_cd_tab(ln_cnt)    -- 最大配送区分

        , lt_weight_capa_tab(ln_cnt)    -- 重量容積区分

        , lt_max_weight_tab(ln_cnt)     -- 最大積載重量

        , lt_max_capa_tab(ln_cnt)       -- 最大積載容積

        );

--

debug_log(FND_FILE.LOG,'自動配車集約中間明細テーブル登録数：'||lt_ins_int_no_tab.COUNT);

debug_log(FND_FILE.LOG,'PLSQL表：lt_ins_int_no_tab');

--

    FORALL ln_cnt_2 IN 1..lt_ins_int_no_tab.COUNT

      INSERT INTO xxwsh_intensive_carrier_ln_tmp(  -- 自動配車集約中間明細テーブル

          intensive_no                -- 集約No

        , request_no                  -- 依頼No

        )

        VALUES

        (

          lt_ins_int_no_tab(ln_cnt_2) -- 集約No

        , lt_request_no_tab(ln_cnt_2) -- 依頼No

        );

debug_log(FND_FILE.LOG,'自動配車集約中間明細テーブル登録');

--

-- 2009/01/08 H.Itou Del Start 本番障害#558 small_amount_loop内で配送区分の設定を行うため

--    -- 商品区分がドリンクの場合のみ配送区分設定を行う

--    IF (gv_prod_class = gv_prod_cls_drink) THEN

--debug_log(FND_FILE.LOG,'最大ケース数チェック：商品区分：ドリンク');

--      -- ==================================

--      --  配送区分設定

--      -- ==================================

--      -- 最大ケース数取得

--      SELECT  xsmv.max_case_quantity    -- 最大ケース数

--      INTO    lt_max_case_qty

--      FROM    xxwsh_ship_method_v xsmv  -- クイックコード

--      WHERE   xsmv.ship_method_code = cv_small_amount_b

--      ;

--debug_log(FND_FILE.LOG,'小口Bケース数:'||lt_max_case_qty);

--debug_log(FND_FILE.LOG,'lt_intensive_no_tab.COUNT:'||lt_intensive_no_tab.COUNT);

----

--      <<reset_ship_method>>

----2008.05.27 D.Sugahara 不具合No9対応->

----      FOR rec_cnt IN 1..lt_intensive_no_tab.COUNT LOOP

--      FOR rec_cnt IN 1..lt_ins_int_no_tab.COUNT LOOP

----2008.05.27 D.Sugahara 不具合No9対応<-

----

--        ln_loop_cnt_2 := ln_loop_cnt_2 + 1;

----

--        lt_intensive_no_tab(ln_loop_cnt_2)  := lt_int_no_tab(ln_loop_cnt_2);  -- 集約No

----

--debug_log(FND_FILE.LOG,'ケース数合計:'||lt_sum_case_qty_tab(ln_loop_cnt_2));

--        -- 修正配送区分

--        IF (lt_sum_case_qty_tab(ln_loop_cnt_2) > lt_max_case_qty) THEN

----

--          lt_fix_ship_method_cd(ln_loop_cnt_2)     := cv_small_amount_a;    -- 小口A

----

--        ELSIF (lt_sum_case_qty_tab(ln_loop_cnt_2) <= lt_max_case_qty) THEN

----

--          lt_fix_ship_method_cd(ln_loop_cnt_2)     := cv_small_amount_b;    -- 小口B

----

--        END IF;

----

--      END LOOP reset_ship_method;

----

--    END IF;

-- 2009/01/08 H.Itou Del End

--

-- 2008/10/01 H.Itou Del Start PT 6-1_27 指摘18

--for ln_cnt_3 in 1.. lt_ins_int_no_tab.COUNT loop

--debug_log(FND_FILE.LOG,'集約No:'||lt_ins_int_no_tab(ln_cnt_3));           -- 集約No

--debug_log(FND_FILE.LOG,'配送No:'||lt_delivery_no_tab(ln_cnt_3));          -- 配送No

--debug_log(FND_FILE.LOG,'基準明細No:'||lt_int_source_tab(ln_cnt_3));           -- 基準明細No

--debug_log(FND_FILE.LOG,'修正配送区分:'||lt_fix_ship_method_cd(ln_cnt_3));      -- 修正配送区分

--debug_log(FND_FILE.LOG,'混載合計重量:'||lt_sum_weight_tab(ln_cnt_3));   -- 混載合計重量

--debug_log(FND_FILE.LOG,'混載合計容積:'||lt_sum_capa_tab(ln_cnt_3)); -- 混載合計容積

--end loop;

-- 2008/10/01 H.Itou Del End

    -- ==================================

    --  仮配送NO取得

    -- ==================================

    FOR loop_cnt IN 1..lt_ins_int_no_tab.COUNT LOOP

--

      SELECT xxwsh_temp_delivery_no_s1.NEXTVAL

      INTO   ln_temp_ship_no

      FROM   dual;

--

      lt_mixed_delivery_no_tab(loop_cnt)  := ln_temp_ship_no;

--

    END LOOP;

--

    -- ==================================

    --  自動配車混載中間テーブル登録

    -- ==================================

    FORALL ln_cnt_3 IN 1..lt_ins_int_no_tab.COUNT

      INSERT INTO xxwsh_mixed_carriers_tmp(

          intensive_no                -- 集約No

        , delivery_no                 -- 配送No

        , default_line_number         -- 基準明細No

        , fixed_shipping_method_code  -- 修正配送区分

        , mixed_class                 -- 混載種別

        , mixed_total_weight          -- 混載合計重量

        , mixed_total_capacity        -- 混載合計容積

        , mixed_no                    -- 混載元No

      )

       VALUES

      (

          lt_ins_int_no_tab(ln_cnt_3)         -- 集約No

        , lt_mixed_delivery_no_tab(ln_cnt_3)  -- 仮配送No

--2008.5.26 D.Sugahara 不具合No9対応->        

--        , lt_int_source_tab(ln_cnt_3)         -- 基準明細No

        , lt_request_no_tab(ln_cnt_3)         -- 基準明細No (1配送1依頼のため、元の依頼/移動No）

--2008.5.26 D.Sugahara 不具合No9対応<-

        , lt_fix_ship_method_cd(ln_cnt_3)     -- 修正配送区分

        , gv_mixed_class_int                  -- 混載種別

        , lt_sum_weight_tab(ln_cnt_3)         -- 混載合計重量

        , lt_sum_capa_tab(ln_cnt_3)           -- 混載合計容積

        , NULL                                -- 混載元No

      );

debug_log(FND_FILE.LOG,'自動配車混載中間テーブル登録');

--

debug_log(FND_FILE.LOG,'小口配送情報作成処理終了');

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

  END set_small_sam_class;

--

  /**********************************************************************************

   * Procedure Name   : get_intensive_tmp

   * Description      : 集約中間情報抽出処理(B-9)

   ***********************************************************************************/

  PROCEDURE get_intensive_tmp(

    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #

    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #

    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #

  IS

    -- ===============================

    -- 固定ローカル定数

    -- ===============================

    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_intensive_tmp'; -- プログラム名

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

    cn_consolid_parmit    CONSTANT NUMBER       := 1;   -- 混載許可フラグ：許可

    cv_finish_intensive   CONSTANT VARCHAR2(1)  := '1'; -- 集約済

    cv_consolid           CONSTANT VARCHAR2(1)  := '1'; -- 混載可否フラグ取得

    cv_ship_method        CONSTANT VARCHAR2(1)  := '2'; -- 配送区分取得

    cv_allocation         CONSTANT VARCHAR2(1)  := '1'; -- 自動配車対象区分：対象

    cv_judge_ship_method  CONSTANT VARCHAR2(1)  := '0'; -- 配送区分混載判定

--2008.05.27 D.Sugahara不具合No9 対応->

    cv_an_object          CONSTANT VARCHAR2(1)  := '1'; -- 対象    

--2008.05.27 D.Sugahara不具合No9 対応<-

-- Ver1.3 M.Hokkanji Start

    cv_table_name_con     CONSTANT VARCHAR2(30) := '配送区分情報VIEW2';

    cv_ship_method_name   CONSTANT VARCHAR2(30) := '混載配送区分';

    cv_effective_date     CONSTANT VARCHAR2(30) := '基準日';

    cv_consolid_false     CONSTANT NUMBER       := 0;   -- 混載許可フラグ：不許可

-- Ver1.3 M.Hokkanji End

-- 2009/01/05 H.Itou Add Start 本番障害#879

    cv_pre_save           CONSTANT VARCHAR2(1) := '1';           -- 拠点混載登録：登録済

    cv_not_save           CONSTANT VARCHAR2(1) := '0';           -- 拠点混載登録：未登録

-- 2009/01/05 H.Itou Add End

--

    -- *** ローカル変数 ***

    TYPE get_intensive_tmp_rtype IS RECORD(

        intensive_no              xxwsh_intensive_carriers_tmp.intensive_no%TYPE  -- 集約No

      , transaction_type          xxwsh_intensive_carriers_tmp.transaction_type%TYPE

                                                                                  -- 処理種別（配車）

      , intensive_source_no       xxwsh_intensive_carriers_tmp.intensive_source_no%TYPE

                                                                                  -- 集約元No

      , deliver_from              xxwsh_intensive_carriers_tmp.deliver_from%TYPE  -- 配送元

      , deliver_to                xxwsh_intensive_carriers_tmp.deliver_to%TYPE    -- 配送先

      , schedule_ship_date        xxwsh_intensive_carriers_tmp.schedule_ship_date%TYPE

                                                                                  -- 出庫予定日

      , schedule_arrival_date     xxwsh_intensive_carriers_tmp.schedule_arrival_date%TYPE

                                                                                  -- 着荷予定日

      , transaction_type_name     xxwsh_intensive_carriers_tmp.transaction_type_name%TYPE

                                                                                  -- 出庫形態

      , freight_carrier_code      xxwsh_intensive_carriers_tmp.freight_carrier_code%TYPE

                                                                                  -- 運送業者

      , head_sales_branch         xxwsh_intensive_carriers_tmp.head_sales_branch%TYPE

                                                                                  -- 管轄拠点

      , reserve_order             xxwsh_intensive_carriers_tmp.reserve_order%TYPE -- 引当順

      , intensive_sum_weight      xxwsh_intensive_carriers_tmp.intensive_sum_weight%TYPE

                                                                                  -- 集約合計重量

      , intensive_sum_capacity    xxwsh_intensive_carriers_tmp.intensive_sum_capacity%TYPE

                                                                                  -- 集約合計容積

      , max_shipping_method_code  xxwsh_intensive_carriers_tmp.max_shipping_method_code%TYPE

                                                                                  -- 最大配送区分

      , weight_capacity_class     xxwsh_intensive_carriers_tmp.weight_capacity_class%TYPE

                                                                                  -- 重量容積区分

      , max_weight                xxwsh_intensive_carriers_tmp.max_weight%TYPE    -- 最大積載重量

      , max_capacity              xxwsh_intensive_carriers_tmp.max_capacity%TYPE  -- 最大積載容積

      , finish_sum_flag           VARCHAR2(1)                                     -- 集約済フラグ

-- 2009/01/05 H.Itou Add Start 本番障害#879

      , pre_saved_flg             xxwsh_carriers_sort_tmp.pre_saved_flg%TYPE      -- 拠点混載登録済フラグ

-- 2009/01/05 H.Itou Add End

      );

--

    -- 自動配車集約中間テーブル用PLSQL表型

    TYPE get_intensive_tmp_ttype IS TABLE OF get_intensive_tmp_rtype INDEX BY BINARY_INTEGER;

--

    lt_intensive_tab            get_intensive_tmp_ttype;    -- 自動配車集約中間テーブル用PLSQL表

--

    -- 混載済データカウント保持用

    TYPE mixed_cnt_ttype IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;

    lt_mixed_cnt_tab  mixed_cnt_ttype;    -- 混載済データカウント保持用テーブル

--

    -- 自動配車混載テーブル登録用PLSQL表

    lt_intensive_no_tab         intensive_no_ttype;         -- 集約No用

    lt_mixed_class_tab          mixed_class_ttype;          -- 混載種別用

    lt_mix_total_weight         mixed_total_weight_ttype;   -- 混載合計重量

    lt_mix_total_capacity       mixed_total_capacity_ttype; -- 混載合計容積

--

    -- 共通関数用

    lv_loading_over_class       VARCHAR2(1);                          -- 積載オーバー区分

    lv_ship_optimization        xxcmn_ship_methods.ship_method%TYPE;  -- 出荷方法

    ln_load_efficiency_weight   NUMBER;                               -- 重量積載効率

    ln_load_efficiency_capacity NUMBER;                               -- 容積積載効率

    lv_mixed_ship_method        VARCHAR2(2);                          -- 混載配送区分

--

    -- 比較用変数

    lt_prev_ship_date       xxwsh_carriers_sort_tmp.schedule_ship_date%TYPE;    -- 出庫日

    lt_prev_arrival_date    xxwsh_carriers_sort_tmp.schedule_arrival_date%TYPE; -- 着荷日

    lt_prev_ship_from       xxwsh_carriers_sort_tmp.deliver_from%TYPE;          -- 出荷元

    lt_prev_ship_to         xxwsh_carriers_sort_tmp.deliver_to%TYPE;            -- 出荷先

    lt_prev_freight_carrier xxwsh_carriers_sort_tmp.freight_carrier_code%TYPE;  -- 運送業者

    lt_prev_w_c_class       xxwsh_carriers_sort_tmp.weight_capacity_class%TYPE; -- 重量容積区分

--

    -- グループ1件目データ格納用

    first_intensive_no              xxwsh_intensive_carriers_tmp.intensive_no%TYPE;

                                                                                -- 集約No

    first_transaction_type          xxwsh_intensive_carriers_tmp.transaction_type%TYPE;

                                                                                -- 処理種別

    first_intensive_source_no       xxwsh_intensive_carriers_tmp.intensive_source_no%TYPE;

                                                                                -- 集約元No

    first_deliver_from              xxwsh_intensive_carriers_tmp.deliver_from%TYPE;

                                                                                -- 配送元

    first_deliver_to                xxwsh_intensive_carriers_tmp.deliver_to%TYPE;

                                                                                -- 配送先

    first_schedule_ship_date        xxwsh_intensive_carriers_tmp.schedule_ship_date%TYPE;

                                                                                -- 出庫予定日

    first_schedule_arrival_date     xxwsh_intensive_carriers_tmp.schedule_arrival_date%TYPE;

                                                                                -- 着荷予定日

    first_transaction_type_name     xxwsh_intensive_carriers_tmp.transaction_type_name%TYPE;

                                                                                -- 出庫形態

    first_freight_carrier_code      xxwsh_intensive_carriers_tmp.freight_carrier_code%TYPE;

                                                                                -- 運送業者

    first_intensive_sum_weight      xxwsh_intensive_carriers_tmp.intensive_sum_weight%TYPE;

                                                                                -- 集約合計重量

    first_intensive_sum_capacity    xxwsh_intensive_carriers_tmp.intensive_sum_capacity%TYPE;

                                                                                -- 集約合計容積

    first_max_shipping_method_code  xxwsh_intensive_carriers_tmp.max_shipping_method_code%TYPE;

                                                                                -- 最大配送区分

    first_weight_capacity_class     xxwsh_intensive_carriers_tmp.weight_capacity_class%TYPE;

                                                                                -- 重量容積区分

    first_max_weight                xxwsh_intensive_carriers_tmp.max_weight%TYPE;

                                                                                -- 最大積載重量

    first_max_capacity              xxwsh_intensive_carriers_tmp.max_capacity%TYPE;

                                                                                -- 最大積載容積

-- 2009/01/05 H.Itou Mod Start 本番障害#879

    first_pre_saved_flg             xxwsh_carriers_sort_tmp.pre_saved_flg%TYPE; -- 拠点混載登録済フラグ

-- 2009/01/05 H.Itou Mod End

--

    ln_intensive_weight       NUMBER DEFAULT 0;                                 -- 混載合計重量

    ln_intensive_capacity     NUMBER DEFAULT 0;                                 -- 混載合計容積

    lv_consolid_flag          VARCHAR2(1);                                  -- 混載可否フラグ:ルート

    lv_consolid_flag_ships    VARCHAR2(1);                                  -- 混載可否フラグ:配送区分

    lv_cdkbn_1                xxcmn_delivery_lt2_v.code_class1%TYPE;        -- コード区分１

    lv_cdkbn_2                xxcmn_delivery_lt2_v.code_class2%TYPE;        -- コード区分２

    lv_cdkbn_2_opt            VARCHAR2(1);                                  -- コード区分２(最適化用)

-- Ver1.3 M.Hokkanji Start

    lv_cdkbn_2_con            VARCHAR2(1);                                  -- コード区分２(混載チェック用)

-- Ver1.3 M.Hokkanji End

    lv_mixed_flag             VARCHAR2(1) DEFAULT NULL;                     -- 混載済フラグ

    lv_second_ship_to         xxwsh_intensive_carriers_tmp.deliver_to%TYPE; -- 2件目の出荷先

    lv_brake_flag             BOOLEAN DEFAULT FALSE;                        -- ブレイクフラグ

    lv_next_ship_method_flag  BOOLEAN DEFAULT FALSE;                        -- 次の配送区分フラグ

    lt_ship_method_cls        xxwsh_intensive_carriers_tmp.max_shipping_method_code%TYPE;

                                                                            -- 次の配送区分

--

    ln_temp_ship_no           NUMBER;                 -- 仮配送No

    lv_rerun_flag             VARCHAR2(1);            -- 再実行フラグ

    lb_finish_flag            BOOLEAN DEFAULT FALSE;  -- 終了フラグ

    ln_finish_judge_cnt       NUMBER DEFAULT 0;       -- 終了判定カウント

    lb_last_data_flag         BOOLEAN DEFAULT FALSE;  -- 最終レコードフラグ

    ln_for_ins_cnt            NUMBER;                 -- PLSQL表格納用カウント(混載種別)

--

    ln_next_weight_capacity   NUMBER;                 -- 次の配送区分の重量・容積

--

    ln_grp_sum_cnt            NUMBER DEFAULT 0;   -- グループカウンタ

    ln_intensive_no_cnt       NUMBER DEFAULT 0;   -- 混載レコード登録用カウンタ

--

    ln_loop_cnt               NUMBER DEFAULT 0;   -- ループカウンタ

    ln_order_num_cnt          NUMBER DEFAULT 1;   -- 配送区分検索回数

    ln_parent_no              NUMBER;             -- 基準レコードカウンタ

    ln_child_no               NUMBER;             -- 混載相手レコードカウンタ

    ln_tab_ins_idx            NUMBER DEFAULT 0;   -- 自動配車混載中間テーブル登録用カウンタ

--

debug_cnt number default 0;

--

    -- *** ローカル・カーソル ***

    CURSOR get_intensive_cur IS

      SELECT  xict.intensive_no             intensive_no              -- 集約No

            , xict.transaction_type         transaction_type          -- 処理種別

            , xict.intensive_source_no      intensive_source_no       -- 集約元No

            , xict.deliver_from             deliver_from              -- 配送元

            , xict.deliver_to               deliver_to                -- 配送先

            , xict.schedule_ship_date       schedule_ship_date        -- 出庫予定日

            , xict.schedule_arrival_date    schedule_arrival_date     -- 着荷予定日

            , xict.transaction_type_name    transaction_type_name     -- 出庫形態

            , xict.freight_carrier_code     freight_carrier_code      -- 運送業者

            , xict.head_sales_branch        head_sales_branch         -- 管轄拠点

            , DECODE(xict.reserve_order, NULL, 99999, xict.reserve_order) reserve_order

                                                                      -- 引当順

            , xict.intensive_sum_weight     intensive_sum_weight      -- 集約合計重量

            , xict.intensive_sum_capacity   intensive_sum_capacity    -- 集約合計容積

            , xict.max_shipping_method_code max_shipping_method_code  -- 最大配送区分

            , xict.weight_capacity_class    weight_capacity_class     -- 重量容積区分

            , xict.max_weight               max_weight                -- 最大積載重量

            , xict.max_capacity             max_capacity              -- 最大積載容積

            , NULL                          finish_sum_flag           -- 集約済フラグ

-- 2009/01/05 H.Itou Add Start 本番障害#879

            , xcst.pre_saved_flg            pre_saved_flg             -- 拠点混載登録済フラグ

-- 2009/01/05 H.Itou Add End

      FROM    xxwsh_intensive_carriers_tmp xict  -- 自動配車集約中間テーブル

-- 2009/01/05 H.Itou Add Start 本番障害#879

            , xxwsh_carriers_sort_tmp      xcst  -- 自動配車ソート用中間テーブル

      WHERE   xict.intensive_source_no = xcst.request_no

-- 2009/01/05 H.Itou Add End

      ORDER BY  xict.schedule_ship_date       -- 出庫予定日

              , xict.schedule_arrival_date    -- 着荷予定日

              , xict.deliver_from             -- 配送元

              , xict.freight_carrier_code     -- 運送業者

              , xict.weight_capacity_class    -- 重量容積区分

              , xict.reserve_order            -- 引当順

              , xict.head_sales_branch        -- 管轄拠点

              , DECODE (xict.weight_capacity_class, gv_weight

                        , xict.intensive_sum_weight         -- 集約重量合計

-- 2009/01/05 H.Itou Add Start 本番障害#879

--                        , xict.weight_capacity_class) DESC  -- 集約合計容積

                        , xict.intensive_sum_capacity) DESC  -- 集約合計容積

-- 2009/01/05 H.Itou Add End

      ;

--

    -- *** ローカル・レコード ***

--

    -- *** サブプログラム ***

    -- ============================

    -- 混載可否フラグ/配送区分取得

    -- ============================

    PROCEDURE get_consolidated_flag(

        iv_code_class1                IN xxcmn_delivery_lt2_v.code_class1%TYPE

      , iv_entering_despatching_code1 IN xxcmn_delivery_lt2_v.entering_despatching_code1%TYPE

      , iv_code_class2                IN xxcmn_delivery_lt2_v.code_class2%TYPE

      , iv_entering_despatching_code2 IN xxcmn_delivery_lt2_v.entering_despatching_code2%TYPE

      , iv_ship_method                IN xxwsh_intensive_carriers_tmp.max_shipping_method_code%TYPE

      , ov_consolidate_flag           OUT NOCOPY xxcmn_delivery_lt2_v.consolidated_flag%TYPE

      , ov_errbuf                     OUT NOCOPY VARCHAR2  -- エラー・メッセージ --# 固定 #

      , ov_retcode                    OUT NOCOPY VARCHAR2  -- リターン・コード   --# 固定 #

      , ov_errmsg                     OUT NOCOPY VARCHAR2  -- ユーザー・エラー・メッセージ --# 固定 #

    )

    IS

      -- ===============================

      -- 固定ローカル定数

      -- ===============================

      cv_sub_prg_name   CONSTANT VARCHAR2(100) := '[get_consolidated_flag]'; -- サブプログラム名

--

      -- ローカル変数

      lt_consolid_flag  xxcmn_delivery_lt2_v.consolidated_flag%TYPE;   -- 混載可否フラグ

      lv_ship_method    xxcmn_delivery_lt2_v.ship_method%TYPE;         -- 配送区分

--

    BEGIN

--

debug_log(FND_FILE.LOG,'《混載可否フラグ取得》');

      -- 変数初期化

      lt_consolid_flag  := NULL;

      lv_ship_method    := NULL;

--

debug_log(FND_FILE.LOG,'gd_date_from:'|| TO_CHAR(gd_date_from,'yyyy/mm/dd'));

debug_log(FND_FILE.LOG,'コード区分1:'|| iv_code_class1);

debug_log(FND_FILE.LOG,'入出庫場所1:'|| iv_entering_despatching_code1);

debug_log(FND_FILE.LOG,'コード区分2:'|| iv_code_class2);

debug_log(FND_FILE.LOG,'入出庫場所2:'|| iv_entering_despatching_code2);

      IF (iv_ship_method IS NULL) THEN

--

        -- ルート判定

        BEGIN

--

-- 2008/10/24 H.Itou Mod Start T_TE080_BPO_600指摘26

--          SELECT xdlv.consolidated_flag

          SELECT CASE 

                   -- 商品区分がドリンクの場合、ドリンク混載可否フラグ

                   WHEN (gv_prod_class = gv_prod_cls_drink) THEN xdlv.consolidated_flag

                   -- 商品区分がリーフの場合、リーフ混載可否フラグ

                   ELSE                                          xdlv.leaf_consolidated_flag

                 END  consolidated_flag

-- 2008/10/24 H.Itou Mod End

            INTO lt_consolid_flag

-- 2008/10/01 H.Itou Mod Start PT 6-1_27 指摘18 出荷方法LTの外部結合のないxxcmn_delivery_lt3_vに変更。

--            FROM xxcmn_delivery_lt2_v xdlv                                        -- 配送L/T情報VIEW2

            FROM xxcmn_delivery_lt3_v   xdlv

-- 2008/10/01 H.Itou Mod End PT 6-1_27 指摘18

           WHERE xdlv.code_class1 = iv_code_class1                                -- コード区分１

             AND xdlv.entering_despatching_code1 = iv_entering_despatching_code1  -- 入出庫場所１

             AND xdlv.code_class2 = iv_code_class2                                -- コード区分２

             AND xdlv.entering_despatching_code2 = iv_entering_despatching_code2  -- 入出庫場所２

             AND xdlv.lt_start_date_active <= gd_date_from                        -- 配送LT適用開始日

             AND (xdlv.lt_end_date_active IS NULL

                  OR xdlv.lt_end_date_active   >= gd_date_from)               -- 配送LT適用終了日

-- 2008.05.21 D.Sugahara 不具合No7対応->

--  混載可否判定時は出荷方法の適用日を見ない

--             AND xdlv.sm_start_date_active <= gd_date_from                  -- 出荷方法適用開始日

--             AND (xdlv.sm_end_date_active IS NULL

--                  OR xdlv.sm_end_date_active >= gd_date_from)               -- 出荷方法適用終了日

-- 2008.05.21 D.Sugahara 不具合No7対応<-

-- 2008/10/24 H.Itou Del Start T_TE080_BPO_600指摘26

--             AND xdlv.consolidated_flag = cn_consolid_parmit                  -- 混載可否フラグ：可

--             AND ROWNUM = 1

-- 2008/10/24 H.Itou Del End

          ;

--

        EXCEPTION

--

          -- データがない場合

          WHEN NO_DATA_FOUND THEN

            NULL;

debug_log(FND_FILE.LOG,'ルート判定:NO_DATA_FOUND');

        END;

--

-- 2008/10/24 H.Itou Mod Start T_TE080_BPO_600指摘26

--        IF (lt_consolid_flag IS NOT NULL) THEN

        -- 混載可否フラグが「可」の場合、「可」を返す。

        IF (lt_consolid_flag = cn_consolid_parmit) THEN

-- 2008/10/24 H.Itou Mod End

          -- 拠点混載：許可

          ov_consolidate_flag := cn_consolid_parmit;

--

-- 2008/10/24 H.Itou Add Start T_TE080_BPO_600指摘26

        -- 混載可否フラグが「可」でない場合、NULLを返す。

        ELSE

          ov_consolidate_flag := NULL;

-- 2008/10/24 H.Itou Add End

        END IF;

--

      ELSE

        -- 配送区分判定

        BEGIN

          SELECT xdl.ship_method

            INTO lv_ship_method

            FROM xxcmn_delivery_lt2_v xdl                                   -- 配送L/T情報VIEW2

           WHERE xdl.code_class1 = iv_code_class1                           -- コード区分１

             AND (xdl.entering_despatching_code1 = iv_entering_despatching_code1 -- 入出庫場所１

              OR  xdl.entering_despatching_code1 = gv_all_z4)               -- 2008/07/14 Add

             AND xdl.code_class2 = iv_code_class2                           -- コード区分２

             AND (xdl.entering_despatching_code2 = iv_entering_despatching_code2 -- 入出庫場所２

              OR  xdl.entering_despatching_code2 = DECODE(iv_code_class2,

                                                          gv_cdkbn_ship_to,

                                                          gv_all_z9,

                                                          gv_all_z4))       -- 2008/07/14 Add

             AND xdl.ship_method = iv_ship_method                           -- 配送区分

             AND xdl.lt_start_date_active <= gd_date_from                   -- 配送LT適用開始日

             AND (xdl.lt_end_date_active IS NULL

                  OR xdl.lt_end_date_active   >= gd_date_from)              -- 配送LT適用終了日

             AND xdl.sm_start_date_active <= gd_date_from                   -- 出荷方法適用開始日

             AND (xdl.sm_end_date_active IS NULL

                  OR xdl.sm_end_date_active >= gd_date_from)                -- 出荷方法適用終了日

             AND ROWNUM = 1

           ;

        EXCEPTION

          -- データがない場合

          WHEN NO_DATA_FOUND THEN

            NULL;

--

debug_log(FND_FILE.LOG,'配送区分判定:NO_DATA_FOUND');

        END;

--

        IF (lv_ship_method IS NOT NULL) THEN

debug_log(FND_FILE.LOG,'混載許可フラグ：許可');

          -- 混載許可フラグ：許可

          ov_consolidate_flag  := cn_consolid_parmit;

        END IF;

--

      END IF;

--

debug_log(FND_FILE.LOG,'--------------------------');

--

    EXCEPTION

      -- *** 共通関数例外ハンドラ ***

      WHEN global_api_expt THEN

        ov_errmsg  := lv_errmsg;

        ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||cv_sub_prg_name||gv_msg_part||lv_errbuf,1,5000);

        ov_retcode := gv_status_error;

      -- *** 共通関数OTHERS例外ハンドラ ***

      WHEN global_api_others_expt THEN

        ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||cv_sub_prg_name||gv_msg_part||SQLERRM;

        ov_retcode := gv_status_error;

      -- *** OTHERS例外ハンドラ ***

      WHEN OTHERS THEN

        ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||cv_sub_prg_name||gv_msg_part||SQLERRM;

        ov_retcode := gv_status_error;

    END;

--

    -- ============================

    -- 配送区分取得

    -- ============================

    PROCEDURE get_ship_method_class(

        iv_code_class1                IN xxcmn_delivery_lt_v.code_class1%TYPE

      , iv_entering_despatching_code1 IN xxcmn_delivery_lt_v.entering_despatching_code1%TYPE

      , iv_code_class2                IN xxcmn_delivery_lt_v.code_class2%TYPE

      , iv_entering_despatching_code2 IN xxcmn_delivery_lt_v.entering_despatching_code2%TYPE

      , iv_weight_capa_class          IN xxwsh_intensive_carriers_tmp.weight_capacity_class%TYPE

      , in_order_num                  IN NUMBER

      , ov_ship_method_class          OUT NOCOPY xxcmn_delivery_lt_v.ship_method%TYPE

      , on_next_weight_capacity       OUT NOCOPY NUMBER

      , ov_errbuf                     OUT NOCOPY VARCHAR2  -- エラー・メッセージ --# 固定 #

      , ov_retcode                    OUT NOCOPY VARCHAR2  -- リターン・コード   --# 固定 #

      , ov_errmsg                     OUT NOCOPY VARCHAR2  -- ユーザー・エラー・メッセージ --# 固定 #

    )

    IS

--

      -- ===============================

      -- 固定ローカル定数

      -- ===============================

      cv_sub_prg_name   CONSTANT VARCHAR2(100) := '[get_ship_method_class]';  -- サブプログラム名

      cv_not_mixed      CONSTANT VARCHAR2(100) := '0';                        -- 混載区分:対象外

--

      -- ローカル変数

      lt_ship_method      xxcmn_delivery_lt_v.ship_method%TYPE;

      ln_loop_cnt         NUMBER;

      ln_data_cnt         NUMBER DEFAULT 1;   -- データカウンタ

debug_cnt number default 0;

--

      -- ローカルカーソル

/*

      CURSOR ship_method_class_cur IS

        SELECT  xdl.ship_method                         -- 出荷方法

                  , xdl.drink_deadweight                -- ドリンク積載重量

                  , xdl.leaf_deadweight                 -- リーフ積載重量

                  , xdl.drink_loading_capacity          -- ドリンク積載容積

                  , xdl.leaf_loading_capacity           -- リーフ積載容積

          FROM  xxcmn_delivery_lt2_v xdl                -- 配送L/T情報VIEW2

              , xxwsh_ship_method2_v xsmv               -- 配送区分情報View2

         WHERE xdl.ship_method = xsmv.ship_method_code  -- 配送区分

           AND xsmv.mixed_class = cv_not_mixed          -- 混載区分

           AND xdl.code_class1 = iv_code_class1                                 -- コード区分１

           AND xdl.entering_despatching_code1 = iv_entering_despatching_code1   -- 入出庫場所１

           AND xdl.code_class2 = iv_code_class2                                 -- コード区分２

           AND xdl.entering_despatching_code2 = iv_entering_despatching_code2   -- 入出庫場所２

           AND xdl.lt_start_date_active <= gd_date_from                -- 配送LT適用開始日

           AND (xdl.lt_end_date_active IS NULL

                OR xdl.lt_end_date_active   >= gd_date_from)           -- 配送LT適用終了日

           AND xdl.sm_start_date_active <= gd_date_from                -- 出荷方法適用開始日

           AND (xdl.sm_end_date_active IS NULL

                OR xdl.sm_end_date_active >= gd_date_from)             -- 出荷方法適用終了日

           AND NVL(xdl.consolidated_flag, '0') = '0'

           AND DECODE(gv_prod_class, gv_prod_cls_drink

                  , xdl.drink_deadweight                     -- ドリンク積載重量

                  , xdl.leaf_deadweight) IS NOT NULL         -- リーフ積載重量

           AND DECODE(gv_prod_class, gv_prod_cls_drink

                  , xdl.drink_loading_capacity               -- ドリンク積載容積

                  , xdl.leaf_loading_capacity) IS NOT NULL   -- リーフ積載容積

        ORDER BY xdl.ship_method DESC

*/

      -- 2008/07/14 Mod ↓

      CURSOR ship_method_class_cur IS

        SELECT  union_sel.ship_method                     -- 出荷方法

              , union_sel.drink_deadweight                -- ドリンク積載重量

              , union_sel.leaf_deadweight                 -- リーフ積載重量

              , union_sel.drink_loading_capacity          -- ドリンク積載容積

              , union_sel.leaf_loading_capacity           -- リーフ積載容積

        FROM (

          SELECT  '1' as sel_flg                      -- 検索順

                , xdl.ship_method                     -- 出荷方法

                , xdl.drink_deadweight                -- ドリンク積載重量

                , xdl.leaf_deadweight                 -- リーフ積載重量

                , xdl.drink_loading_capacity          -- ドリンク積載容積

                , xdl.leaf_loading_capacity           -- リーフ積載容積

            FROM  xxcmn_delivery_lt2_v xdl                -- 配送L/T情報VIEW2

                , xxwsh_ship_method2_v xsmv               -- 配送区分情報View2

           WHERE xdl.ship_method = xsmv.ship_method_code  -- 配送区分

             AND xsmv.mixed_class = cv_not_mixed          -- 混載区分

             AND xdl.code_class1 = iv_code_class1                                 -- コード区分１

             AND xdl.entering_despatching_code1 = iv_entering_despatching_code1   -- 入出庫場所１

             AND xdl.code_class2 = iv_code_class2                                 -- コード区分２

             AND xdl.entering_despatching_code2 = iv_entering_despatching_code2   -- 入出庫場所２

             AND xdl.lt_start_date_active <= gd_date_from       -- 配送LT適用開始日

             AND (xdl.lt_end_date_active IS NULL

                  OR xdl.lt_end_date_active   >= gd_date_from)  -- 配送LT適用終了日

             AND xdl.sm_start_date_active <= gd_date_from       -- 出荷方法適用開始日

             AND (xdl.sm_end_date_active IS NULL

                  OR xdl.sm_end_date_active >= gd_date_from)    -- 出荷方法適用終了日

-- Ver1.5 M.Hokkanji Start

--             AND NVL(xdl.consolidated_flag, '0') = '0'         -- 混載許可フラグ:混載不許可

-- Ver1.5 M.Hokkanji End

-- 2008/10/16 H.Itou Mod Start 統合テスト指摘369 0より大きいものを対象とする。

--             AND DECODE(gv_prod_class, gv_prod_cls_drink

--                    , xdl.drink_deadweight                     -- ドリンク積載重量

--                    , xdl.leaf_deadweight) IS NOT NULL         -- リーフ積載重量

--             AND DECODE(gv_prod_class, gv_prod_cls_drink

--                    , xdl.drink_loading_capacity               -- ドリンク積載容積

--                    , xdl.leaf_loading_capacity) IS NOT NULL   -- リーフ積載容積

             AND (CASE

                    -- ドリンク積載重量

                    WHEN ((gv_prod_class        = gv_prod_cls_drink)

                    AND   (iv_weight_capa_class = gv_weight)) THEN

                      xdl.drink_deadweight

                    -- リーフ積載重量

                    WHEN ((gv_prod_class        = gv_prod_cls_leaf)

                    AND   (iv_weight_capa_class = gv_weight)) THEN

                      xdl.leaf_deadweight

                    -- ドリンク積載容積

                    WHEN ((gv_prod_class        = gv_prod_cls_drink)

                    AND   (iv_weight_capa_class = gv_capacity)) THEN

                      xdl.drink_loading_capacity

                    -- リーフ積載容積

                    WHEN ((gv_prod_class        = gv_prod_cls_leaf)

                    AND   (iv_weight_capa_class = gv_capacity)) THEN

                      xdl.leaf_loading_capacity

                  END) > 0

--2008/10/16 H.Itou Mod End

          UNION

          SELECT  '2' as sel_flg                      -- 検索順

                , xdl.ship_method                     -- 出荷方法

                , xdl.drink_deadweight                -- ドリンク積載重量

                , xdl.leaf_deadweight                 -- リーフ積載重量

                , xdl.drink_loading_capacity          -- ドリンク積載容積

                , xdl.leaf_loading_capacity           -- リーフ積載容積

            FROM  xxcmn_delivery_lt2_v xdl                -- 配送L/T情報VIEW2

                , xxwsh_ship_method2_v xsmv               -- 配送区分情報View2

           WHERE xdl.ship_method = xsmv.ship_method_code  -- 配送区分

             AND xsmv.mixed_class = cv_not_mixed          -- 混載区分

             AND xdl.code_class1 = iv_code_class1                                 -- コード区分１

             AND xdl.entering_despatching_code1 = gv_all_z4   -- 入出庫場所１

             AND xdl.code_class2 = iv_code_class2                                 -- コード区分２

             AND xdl.entering_despatching_code2 = iv_entering_despatching_code2   -- 入出庫場所２

             AND xdl.lt_start_date_active <= gd_date_from       -- 配送LT適用開始日

             AND (xdl.lt_end_date_active IS NULL

                  OR xdl.lt_end_date_active   >= gd_date_from)  -- 配送LT適用終了日

             AND xdl.sm_start_date_active <= gd_date_from       -- 出荷方法適用開始日

             AND (xdl.sm_end_date_active IS NULL

                  OR xdl.sm_end_date_active >= gd_date_from)    -- 出荷方法適用終了日

-- Ver1.5 M.Hokkanji Start

--             AND NVL(xdl.consolidated_flag, '0') = '0'         -- 混載許可フラグ:混載不許可

-- Ver1.5 M.Hokkanji End

-- 2008/10/16 H.Itou Mod Start 統合テスト指摘369 0より大きいものを対象とする。

--             AND DECODE(gv_prod_class, gv_prod_cls_drink

--                    , xdl.drink_deadweight                     -- ドリンク積載重量

--                    , xdl.leaf_deadweight) IS NOT NULL         -- リーフ積載重量

--             AND DECODE(gv_prod_class, gv_prod_cls_drink

--                    , xdl.drink_loading_capacity               -- ドリンク積載容積

--                    , xdl.leaf_loading_capacity) IS NOT NULL   -- リーフ積載容積

             AND (CASE

                    -- ドリンク積載重量

                    WHEN ((gv_prod_class        = gv_prod_cls_drink)

                    AND   (iv_weight_capa_class = gv_weight)) THEN

                      xdl.drink_deadweight

                    -- リーフ積載重量

                    WHEN ((gv_prod_class        = gv_prod_cls_leaf)

                    AND   (iv_weight_capa_class = gv_weight)) THEN

                      xdl.leaf_deadweight

                    -- ドリンク積載容積

                    WHEN ((gv_prod_class        = gv_prod_cls_drink)

                    AND   (iv_weight_capa_class = gv_capacity)) THEN

                      xdl.drink_loading_capacity

                    -- リーフ積載容積

                    WHEN ((gv_prod_class        = gv_prod_cls_leaf)

                    AND   (iv_weight_capa_class = gv_capacity)) THEN

                      xdl.leaf_loading_capacity

                  END) > 0

--2008/10/16 H.Itou Mod End

          UNION

          SELECT  '3' as sel_flg                      -- 検索順

                , xdl.ship_method                     -- 出荷方法

                , xdl.drink_deadweight                -- ドリンク積載重量

                , xdl.leaf_deadweight                 -- リーフ積載重量

                , xdl.drink_loading_capacity          -- ドリンク積載容積

                , xdl.leaf_loading_capacity           -- リーフ積載容積

            FROM  xxcmn_delivery_lt2_v xdl                -- 配送L/T情報VIEW2

                , xxwsh_ship_method2_v xsmv               -- 配送区分情報View2

           WHERE xdl.ship_method = xsmv.ship_method_code  -- 配送区分

             AND xsmv.mixed_class = cv_not_mixed          -- 混載区分

             AND xdl.code_class1 = iv_code_class1                                 -- コード区分１

             AND xdl.entering_despatching_code1 = iv_entering_despatching_code1   -- 入出庫場所１

             AND xdl.code_class2 = iv_code_class2                                 -- コード区分２

             AND xdl.entering_despatching_code2 = DECODE(iv_code_class2,

                                                         gv_cdkbn_ship_to,

                                                         gv_all_z9,

                                                         gv_all_z4)     -- 入出庫場所２

             AND xdl.lt_start_date_active <= gd_date_from       -- 配送LT適用開始日

             AND (xdl.lt_end_date_active IS NULL

                  OR xdl.lt_end_date_active   >= gd_date_from)  -- 配送LT適用終了日

             AND xdl.sm_start_date_active <= gd_date_from       -- 出荷方法適用開始日

             AND (xdl.sm_end_date_active IS NULL

                  OR xdl.sm_end_date_active >= gd_date_from)    -- 出荷方法適用終了日

-- Ver1.5 M.Hokkanji Start

--             AND NVL(xdl.consolidated_flag, '0') = '0'         -- 混載許可フラグ:混載不許可

-- Ver1.5 M.Hokkanji End

-- 2008/10/16 H.Itou Mod Start 統合テスト指摘369 0より大きいものを対象とする。

--             AND DECODE(gv_prod_class, gv_prod_cls_drink

--                    , xdl.drink_deadweight                     -- ドリンク積載重量

--                    , xdl.leaf_deadweight) IS NOT NULL         -- リーフ積載重量

--             AND DECODE(gv_prod_class, gv_prod_cls_drink

--                    , xdl.drink_loading_capacity               -- ドリンク積載容積

--                    , xdl.leaf_loading_capacity) IS NOT NULL   -- リーフ積載容積

             AND (CASE

                    -- ドリンク積載重量

                    WHEN ((gv_prod_class        = gv_prod_cls_drink)

                    AND   (iv_weight_capa_class = gv_weight)) THEN

                      xdl.drink_deadweight

                    -- リーフ積載重量

                    WHEN ((gv_prod_class        = gv_prod_cls_leaf)

                    AND   (iv_weight_capa_class = gv_weight)) THEN

                      xdl.leaf_deadweight

                    -- ドリンク積載容積

                    WHEN ((gv_prod_class        = gv_prod_cls_drink)

                    AND   (iv_weight_capa_class = gv_capacity)) THEN

                      xdl.drink_loading_capacity

                    -- リーフ積載容積

                    WHEN ((gv_prod_class        = gv_prod_cls_leaf)

                    AND   (iv_weight_capa_class = gv_capacity)) THEN

                      xdl.leaf_loading_capacity

                  END) > 0

--2008/10/16 H.Itou Mod End

          UNION

          SELECT  '4' as sel_flg                      -- 検索順

                , xdl.ship_method                     -- 出荷方法

                , xdl.drink_deadweight                -- ドリンク積載重量

                , xdl.leaf_deadweight                 -- リーフ積載重量

                , xdl.drink_loading_capacity          -- ドリンク積載容積

                , xdl.leaf_loading_capacity           -- リーフ積載容積

            FROM  xxcmn_delivery_lt2_v xdl                -- 配送L/T情報VIEW2

                , xxwsh_ship_method2_v xsmv               -- 配送区分情報View2

           WHERE xdl.ship_method = xsmv.ship_method_code  -- 配送区分

             AND xsmv.mixed_class = cv_not_mixed          -- 混載区分

             AND xdl.code_class1 = iv_code_class1               -- コード区分１

             AND xdl.entering_despatching_code1 = gv_all_z4     -- 入出庫場所１

             AND xdl.code_class2 = iv_code_class2               -- コード区分２

             AND xdl.entering_despatching_code2 = DECODE(iv_code_class2,

                                                         gv_cdkbn_ship_to,

                                                         gv_all_z9,

                                                         gv_all_z4)     -- 入出庫場所２

             AND xdl.lt_start_date_active <= gd_date_from       -- 配送LT適用開始日

             AND (xdl.lt_end_date_active IS NULL

                  OR xdl.lt_end_date_active   >= gd_date_from)  -- 配送LT適用終了日

             AND xdl.sm_start_date_active <= gd_date_from       -- 出荷方法適用開始日

             AND (xdl.sm_end_date_active IS NULL

                  OR xdl.sm_end_date_active >= gd_date_from)    -- 出荷方法適用終了日

-- Ver1.5 M.Hokkanji Start

--             AND NVL(xdl.consolidated_flag, '0') = '0'         -- 混載許可フラグ:混載不許可

-- Ver1.5 M.Hokkanji End

-- 2008/10/16 H.Itou Mod Start 統合テスト指摘369 0より大きいものを対象とする。

--             AND DECODE(gv_prod_class, gv_prod_cls_drink

--                    , xdl.drink_deadweight                     -- ドリンク積載重量

--                    , xdl.leaf_deadweight) IS NOT NULL         -- リーフ積載重量

--             AND DECODE(gv_prod_class, gv_prod_cls_drink

--                    , xdl.drink_loading_capacity               -- ドリンク積載容積

--                    , xdl.leaf_loading_capacity) IS NOT NULL   -- リーフ積載容積

             AND (CASE

                    -- ドリンク積載重量

                    WHEN ((gv_prod_class        = gv_prod_cls_drink)

                    AND   (iv_weight_capa_class = gv_weight)) THEN

                      xdl.drink_deadweight

                    -- リーフ積載重量

                    WHEN ((gv_prod_class        = gv_prod_cls_leaf)

                    AND   (iv_weight_capa_class = gv_weight)) THEN

                      xdl.leaf_deadweight

                    -- ドリンク積載容積

                    WHEN ((gv_prod_class        = gv_prod_cls_drink)

                    AND   (iv_weight_capa_class = gv_capacity)) THEN

                      xdl.drink_loading_capacity

                    -- リーフ積載容積

                    WHEN ((gv_prod_class        = gv_prod_cls_leaf)

                    AND   (iv_weight_capa_class = gv_capacity)) THEN

                      xdl.leaf_loading_capacity

                  END) > 0

--2008/10/16 H.Itou Mod End

        ) union_sel

       ,(

          SELECT  MIN(union_sel.sel_flg) as min_flg

                , union_sel.ship_method                     -- 出荷方法

          FROM (

            SELECT  '1' as sel_flg                      -- 検索順

                  , xdl.ship_method                     -- 出荷方法

              FROM  xxcmn_delivery_lt2_v xdl                -- 配送L/T情報VIEW2

                  , xxwsh_ship_method2_v xsmv               -- 配送区分情報View2

             WHERE xdl.ship_method = xsmv.ship_method_code  -- 配送区分

               AND xsmv.mixed_class = cv_not_mixed          -- 混載区分

               AND xdl.code_class1 = iv_code_class1                                -- コード区分１

               AND xdl.entering_despatching_code1 = iv_entering_despatching_code1  -- 入出庫場所１

               AND xdl.code_class2 = iv_code_class2                                -- コード区分２

               AND xdl.entering_despatching_code2 = iv_entering_despatching_code2  -- 入出庫場所２

               AND xdl.lt_start_date_active <= gd_date_from      -- 配送LT適用開始日

               AND (xdl.lt_end_date_active IS NULL

                    OR xdl.lt_end_date_active   >= gd_date_from) -- 配送LT適用終了日

               AND xdl.sm_start_date_active <= gd_date_from      -- 出荷方法適用開始日

               AND (xdl.sm_end_date_active IS NULL

                    OR xdl.sm_end_date_active >= gd_date_from)   -- 出荷方法適用終了日

-- Ver1.5 M.Hokkanji Start

--               AND NVL(xdl.consolidated_flag, '0') = '0'         -- 混載許可フラグ:混載不許可

-- Ver1.5 M.Hokkanji End

-- 2008/10/16 H.Itou Mod Start 統合テスト指摘369 0より大きいものを対象とする。

--               AND DECODE(gv_prod_class, gv_prod_cls_drink

--                      , xdl.drink_deadweight                     -- ドリンク積載重量

--                      , xdl.leaf_deadweight) IS NOT NULL         -- リーフ積載重量

--               AND DECODE(gv_prod_class, gv_prod_cls_drink

--                      , xdl.drink_loading_capacity               -- ドリンク積載容積

--                      , xdl.leaf_loading_capacity) IS NOT NULL   -- リーフ積載容積

               AND (CASE

                      -- ドリンク積載重量

                      WHEN ((gv_prod_class        = gv_prod_cls_drink)

                      AND   (iv_weight_capa_class = gv_weight)) THEN

                        xdl.drink_deadweight

                      -- リーフ積載重量

                      WHEN ((gv_prod_class        = gv_prod_cls_leaf)

                      AND   (iv_weight_capa_class = gv_weight)) THEN

                        xdl.leaf_deadweight

                      -- ドリンク積載容積

                      WHEN ((gv_prod_class        = gv_prod_cls_drink)

                      AND   (iv_weight_capa_class = gv_capacity)) THEN

                        xdl.drink_loading_capacity

                      -- リーフ積載容積

                      WHEN ((gv_prod_class        = gv_prod_cls_leaf)

                      AND   (iv_weight_capa_class = gv_capacity)) THEN

                        xdl.leaf_loading_capacity

                    END) > 0

--2008/10/16 H.Itou Mod End

            UNION

            SELECT  '2' as sel_flg                      -- 検索順

                  , xdl.ship_method                     -- 出荷方法

              FROM  xxcmn_delivery_lt2_v xdl                -- 配送L/T情報VIEW2

                  , xxwsh_ship_method2_v xsmv               -- 配送区分情報View2

             WHERE xdl.ship_method = xsmv.ship_method_code  -- 配送区分

               AND xsmv.mixed_class = cv_not_mixed          -- 混載区分

               AND xdl.code_class1 = iv_code_class1              -- コード区分１

               AND xdl.entering_despatching_code1 = gv_all_z4    -- 入出庫場所１

               AND xdl.code_class2 = iv_code_class2              -- コード区分２

               AND xdl.entering_despatching_code2 = iv_entering_despatching_code2  -- 入出庫場所２

               AND xdl.lt_start_date_active <= gd_date_from      -- 配送LT適用開始日

               AND (xdl.lt_end_date_active IS NULL

                    OR xdl.lt_end_date_active   >= gd_date_from) -- 配送LT適用終了日

               AND xdl.sm_start_date_active <= gd_date_from      -- 出荷方法適用開始日

               AND (xdl.sm_end_date_active IS NULL

                    OR xdl.sm_end_date_active >= gd_date_from)   -- 出荷方法適用終了日

-- Ver1.5 M.Hokkanji Start

--               AND NVL(xdl.consolidated_flag, '0') = '0'         -- 混載許可フラグ:混載不許可

-- Ver1.5 M.Hokkanji End

-- 2008/10/16 H.Itou Mod Start 統合テスト指摘369 0より大きいものを対象とする。

--               AND DECODE(gv_prod_class, gv_prod_cls_drink

--                      , xdl.drink_deadweight                     -- ドリンク積載重量

--                      , xdl.leaf_deadweight) IS NOT NULL         -- リーフ積載重量

--               AND DECODE(gv_prod_class, gv_prod_cls_drink

--                      , xdl.drink_loading_capacity               -- ドリンク積載容積

--                      , xdl.leaf_loading_capacity) IS NOT NULL   -- リーフ積載容積

               AND (CASE

                      -- ドリンク積載重量

                      WHEN ((gv_prod_class        = gv_prod_cls_drink)

                      AND   (iv_weight_capa_class = gv_weight)) THEN

                        xdl.drink_deadweight

                      -- リーフ積載重量

                      WHEN ((gv_prod_class        = gv_prod_cls_leaf)

                      AND   (iv_weight_capa_class = gv_weight)) THEN

                        xdl.leaf_deadweight

                      -- ドリンク積載容積

                      WHEN ((gv_prod_class        = gv_prod_cls_drink)

                      AND   (iv_weight_capa_class = gv_capacity)) THEN

                        xdl.drink_loading_capacity

                      -- リーフ積載容積

                      WHEN ((gv_prod_class        = gv_prod_cls_leaf)

                      AND   (iv_weight_capa_class = gv_capacity)) THEN

                        xdl.leaf_loading_capacity

                    END) > 0

--2008/10/16 H.Itou Mod End

            UNION

            SELECT  '3' as sel_flg                      -- 検索順

                  , xdl.ship_method                     -- 出荷方法

              FROM  xxcmn_delivery_lt2_v xdl                -- 配送L/T情報VIEW2

                  , xxwsh_ship_method2_v xsmv               -- 配送区分情報View2

             WHERE xdl.ship_method = xsmv.ship_method_code  -- 配送区分

               AND xsmv.mixed_class = cv_not_mixed          -- 混載区分

               AND xdl.code_class1 = iv_code_class1               -- コード区分１

               AND xdl.entering_despatching_code1 = iv_entering_despatching_code1  -- 入出庫場所１

               AND xdl.code_class2 = iv_code_class2               -- コード区分２

               AND xdl.entering_despatching_code2 = DECODE(iv_code_class2,

                                                           gv_cdkbn_ship_to,

                                                           gv_all_z9,

                                                           gv_all_z4)     -- 入出庫場所２

               AND xdl.lt_start_date_active <= gd_date_from       -- 配送LT適用開始日

               AND (xdl.lt_end_date_active IS NULL

                    OR xdl.lt_end_date_active   >= gd_date_from)  -- 配送LT適用終了日

               AND xdl.sm_start_date_active <= gd_date_from       -- 出荷方法適用開始日

               AND (xdl.sm_end_date_active IS NULL

                    OR xdl.sm_end_date_active >= gd_date_from)    -- 出荷方法適用終了日

-- Ver1.5 M.Hokkanji Start

--               AND NVL(xdl.consolidated_flag, '0') = '0'         -- 混載許可フラグ:混載不許可

-- Ver1.5 M.Hokkanji End

-- 2008/10/16 H.Itou Mod Start 統合テスト指摘369 0より大きいものを対象とする。

--               AND DECODE(gv_prod_class, gv_prod_cls_drink

--                      , xdl.drink_deadweight                     -- ドリンク積載重量

--                      , xdl.leaf_deadweight) IS NOT NULL         -- リーフ積載重量

--               AND DECODE(gv_prod_class, gv_prod_cls_drink

--                      , xdl.drink_loading_capacity               -- ドリンク積載容積

--                      , xdl.leaf_loading_capacity) IS NOT NULL   -- リーフ積載容積

               AND (CASE

                      -- ドリンク積載重量

                      WHEN ((gv_prod_class        = gv_prod_cls_drink)

                      AND   (iv_weight_capa_class = gv_weight)) THEN

                        xdl.drink_deadweight

                      -- リーフ積載重量

                      WHEN ((gv_prod_class        = gv_prod_cls_leaf)

                      AND   (iv_weight_capa_class = gv_weight)) THEN

                        xdl.leaf_deadweight

                      -- ドリンク積載容積

                      WHEN ((gv_prod_class        = gv_prod_cls_drink)

                      AND   (iv_weight_capa_class = gv_capacity)) THEN

                        xdl.drink_loading_capacity

                      -- リーフ積載容積

                      WHEN ((gv_prod_class        = gv_prod_cls_leaf)

                      AND   (iv_weight_capa_class = gv_capacity)) THEN

                        xdl.leaf_loading_capacity

                    END) > 0

--2008/10/16 H.Itou Mod End

            UNION

            SELECT  '4' as sel_flg                      -- 検索順

                  , xdl.ship_method                     -- 出荷方法

              FROM  xxcmn_delivery_lt2_v xdl                -- 配送L/T情報VIEW2

                  , xxwsh_ship_method2_v xsmv               -- 配送区分情報View2

             WHERE xdl.ship_method = xsmv.ship_method_code  -- 配送区分

               AND xsmv.mixed_class = cv_not_mixed          -- 混載区分

               AND xdl.code_class1 = iv_code_class1             -- コード区分１

               AND xdl.entering_despatching_code1 = gv_all_z4   -- 入出庫場所１

               AND xdl.code_class2 = iv_code_class2             -- コード区分２

               AND xdl.entering_despatching_code2 = DECODE(iv_code_class2,

                                                           gv_cdkbn_ship_to,

                                                           gv_all_z9,

                                                           gv_all_z4)   -- 入出庫場所２

               AND xdl.lt_start_date_active <= gd_date_from     -- 配送LT適用開始日

               AND (xdl.lt_end_date_active IS NULL

                    OR xdl.lt_end_date_active   >= gd_date_from)  -- 配送LT適用終了日

               AND xdl.sm_start_date_active <= gd_date_from       -- 出荷方法適用開始日

               AND (xdl.sm_end_date_active IS NULL

                    OR xdl.sm_end_date_active >= gd_date_from)    -- 出荷方法適用終了日

-- Ver1.5 M.Hokkanji Start

--               AND NVL(xdl.consolidated_flag, '0') = '0'         -- 混載許可フラグ:混載不許可

-- Ver1.5 M.Hokkanji End

-- 2008/10/16 H.Itou Mod Start 統合テスト指摘369 0より大きいものを対象とする。

--               AND DECODE(gv_prod_class, gv_prod_cls_drink

--                      , xdl.drink_deadweight                     -- ドリンク積載重量

--                      , xdl.leaf_deadweight) IS NOT NULL         -- リーフ積載重量

--               AND DECODE(gv_prod_class, gv_prod_cls_drink

--                      , xdl.drink_loading_capacity               -- ドリンク積載容積

--                      , xdl.leaf_loading_capacity) IS NOT NULL   -- リーフ積載容積

               AND (CASE

                      -- ドリンク積載重量

                      WHEN ((gv_prod_class        = gv_prod_cls_drink)

                      AND   (iv_weight_capa_class = gv_weight)) THEN

                        xdl.drink_deadweight

                      -- リーフ積載重量

                      WHEN ((gv_prod_class        = gv_prod_cls_leaf)

                      AND   (iv_weight_capa_class = gv_weight)) THEN

                        xdl.leaf_deadweight

                      -- ドリンク積載容積

                      WHEN ((gv_prod_class        = gv_prod_cls_drink)

                      AND   (iv_weight_capa_class = gv_capacity)) THEN

                        xdl.drink_loading_capacity

                      -- リーフ積載容積

                      WHEN ((gv_prod_class        = gv_prod_cls_leaf)

                      AND   (iv_weight_capa_class = gv_capacity)) THEN

                        xdl.leaf_loading_capacity

                    END) > 0

--2008/10/16 H.Itou Mod End

          ) union_sel

          group by union_sel.ship_method

        ) union_flg

        WHERE union_sel.sel_flg = union_flg.min_flg

        AND   union_sel.ship_method = union_flg.ship_method

        ORDER BY union_sel.ship_method DESC

       ;

      -- 2008/07/14 Mod ↑

--

       -- ローカルレコード

       lr_ship_method_class ship_method_class_cur%ROWTYPE;

--

    BEGIN

--

debug_log(FND_FILE.LOG,'7-2-1配送区分取得');

debug_log(FND_FILE.LOG,'7-2-1重量容積区分：' || iv_weight_capa_class);

debug_log(FND_FILE.LOG,'7-2-1コード区分１：'||iv_code_class1);

debug_log(FND_FILE.LOG,'7-2-1入出庫場所コード１：'||iv_entering_despatching_code1);

debug_log(FND_FILE.LOG,'7-2-1コード区分２：'||iv_code_class2);

debug_log(FND_FILE.LOG,'7-2-1入出庫場所コード２：'||iv_entering_despatching_code2);

debug_log(FND_FILE.LOG,'7-2-1基準日：'||TO_CHAR(gd_date_from,'YYYY/MM/DD'));

debug_log(FND_FILE.LOG,'7-2-1商品区分：'||gv_prod_class);

debug_log(FND_FILE.LOG,'7-2-1検索順番：'||in_order_num);

--

      -- ===================

      -- 配送区分取得

      -- ===================

      OPEN ship_method_class_cur;

      -- 配送区分

      FETCH ship_method_class_cur INTO lr_ship_method_class;

--

      LOOP

--

debug_cnt := debug_cnt + 1;

        ln_data_cnt := ln_data_cnt + 1;

--

        FETCH ship_method_class_cur INTO lr_ship_method_class;

        EXIT WHEN ship_method_class_cur%NOTFOUND;

--

        IF (ln_data_cnt = in_order_num) THEN

--

          ov_ship_method_class := lr_ship_method_class.ship_method;

--

          -- 重量容積区分：重量

          IF (iv_weight_capa_class = gv_weight) THEN

--

            -- 商品区分：リーフ

            IF (gv_prod_class = gv_prod_cls_leaf) THEN

--

              -- リーフ積載重量

              on_next_weight_capacity := lr_ship_method_class.leaf_deadweight;-- リーフ積載重量

--

            ELSE

              -- ドリンク積載重量

              on_next_weight_capacity := lr_ship_method_class.drink_deadweight;

--

            END IF;

--

          -- 重量容積区分：容積

          ELSE

--

            -- 商品区分：リーフ

            IF (gv_prod_class = gv_prod_cls_leaf) THEN

--

              -- リーフ積載容積

-- 2009/01/05 H.Itou Mod Start 本番障害#879

--              on_next_weight_capacity := lr_ship_method_class.drink_loading_capacity;

              on_next_weight_capacity := lr_ship_method_class.leaf_loading_capacity;

-- 2009/01/05 H.Itou Mod End

--

            ELSE

              -- ドリンク積載容積

              on_next_weight_capacity := lr_ship_method_class.drink_loading_capacity;

--

            END IF;

--

          END IF;

--

          EXIT;

--

        END IF;

--

-- debug -----------------

/*if debug_cnt >= 100 then

  exit;

debug_log(FND_FILE.LOG,'■強制EXIT');

end if;

--------------------------

*/

      END LOOP;

--

debug_log(FND_FILE.LOG,'次の配送区分：'|| ov_ship_method_class);

--

      CLOSE ship_method_class_cur;

--

    EXCEPTION

      -- *** 共通関数例外ハンドラ ***

      WHEN global_api_expt THEN

        IF (ship_method_class_cur%ISOPEN) THEN

          CLOSE ship_method_class_cur;

        END IF;

        ov_errmsg  := lv_errmsg;

        ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||cv_sub_prg_name||gv_msg_part||lv_errbuf,1,5000);

        ov_retcode := gv_status_error;

      -- *** 共通関数OTHERS例外ハンドラ ***

      WHEN global_api_others_expt THEN

        IF (ship_method_class_cur%ISOPEN) THEN

          CLOSE ship_method_class_cur;

        END IF;

        ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||cv_sub_prg_name||gv_msg_part||SQLERRM;

        ov_retcode := gv_status_error;

      -- *** OTHERS例外ハンドラ ***

      WHEN OTHERS THEN

        IF (ship_method_class_cur%ISOPEN) THEN

          CLOSE ship_method_class_cur;

        END IF;

        ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||cv_sub_prg_name||gv_msg_part||SQLERRM;

        ov_retcode := gv_status_error;

    END;

--

    -- ============================

    -- キーブレイク時処理

    -- ============================

    PROCEDURE lproc_keybrake_process(

        ov_errbuf     OUT NOCOPY VARCHAR2  -- エラー・メッセージ --# 固定 #

      , ov_retcode    OUT NOCOPY VARCHAR2  -- リターン・コード   --# 固定 #

      , ov_errmsg     OUT NOCOPY VARCHAR2  -- ユーザー・エラー・メッセージ --# 固定 #

    )

    IS

      -- ===============================

      -- 固定ローカル定数

      -- ===============================

      cv_sub_prg_name   CONSTANT VARCHAR2(100) := '[lproc_keybrake_process]'; -- サブプログラム名

--

      ln_non_processing_cnt NUMBER DEFAULT 0;   -- 未処理カウント

--

    BEGIN

debug_log(FND_FILE.LOG,'7キーブレイク処理');

debug_log(FND_FILE.LOG,'7-0-1再実行フラグ初期化：OFF');

debug_log(FND_FILE.LOG,'7-0-2基準レコードカウント：'|| ln_parent_no);

--

      -- 基準レコードが未処理の場合、次の配送区分を検索

      IF (lt_intensive_tab(ln_parent_no).finish_sum_flag IS NULL) THEN

--

debug_log(FND_FILE.LOG,'7-1基準レコードが未処理。次の配送区分を検索');

        -- 検索回数

        ln_order_num_cnt := ln_order_num_cnt + 1;

debug_log(FND_FILE.LOG,'7-2検索回数：'|| ln_order_num_cnt);

--

        -- 次の配送区分を取得

        get_ship_method_class(

                iv_code_class1                => gv_cdkbn_storage     -- コード区分１：倉庫

              , iv_entering_despatching_code1 => first_deliver_from   -- 配送元

              , iv_code_class2                => lv_cdkbn_2     -- コード区分２：倉庫 or 配送先

              , iv_entering_despatching_code2 => first_deliver_to           -- 配送先

-- Ver1.5 M.Hokkanji Start

              , iv_weight_capa_class          => first_weight_capacity_class -- 重量容積区分

--              , iv_weight_capa_class          => first_intensive_sum_weight -- 重量容積区分

-- Ver1.5 M.Hokkanji End

              , in_order_num                  => ln_order_num_cnt           -- 検索順

              , ov_ship_method_class          => lt_ship_method_cls         -- 次の配送区分

              , on_next_weight_capacity       => ln_next_weight_capacity    -- 積載重量／容積

              , ov_errbuf                     => lv_errbuf

              , ov_retcode                    => lv_retcode

              , ov_errmsg                     => lv_errmsg

        );

--

        IF (lv_retcode = gv_status_error) THEN

          gv_err_key  :=  gv_cdkbn_storage

                          || gv_msg_comma ||

                          first_deliver_from

                          || gv_msg_comma ||

                          lv_cdkbn_2

                          || gv_msg_comma ||

                          first_deliver_to

                          || gv_msg_comma ||

-- Ver1.5 M.Hokkanji Start

--                          first_intensive_sum_weight

                          first_weight_capacity_class

-- Ver1.5 M.Hokkanji End

                          || gv_msg_comma ||

                          ln_order_num_cnt

                          ;

          -- エラーメッセージ取得

          lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(

                          gv_xxwsh            -- モジュール名略称：XXWSH 出荷・引当/配車

                        , gv_msg_xxwsh_11810  -- メッセージ：APP-XXWSH-11810 共通関数エラー

                        , gv_fnc_name         -- トークン：FNC_NAME

                        , 'get_ship_method_class' -- 関数名

                        , gv_tkn_key              -- トークン：KEY

                        , gv_err_key              -- 関数実行キー

                       ),1,5000);

          RAISE global_api_expt;

        END IF;

--

        -- 次の配送区分が取得できた場合

        IF (lt_ship_method_cls IS NOT NULL) THEN

--

debug_log(FND_FILE.LOG,'7-3次の配送区分取得');

debug_log(FND_FILE.LOG,'7-3次の配送区分:' || lt_ship_method_cls);

          -- 次の配送区分が基準明細の集約合計を超えるかチェックする

          IF (first_weight_capacity_class = gv_weight) THEN

debug_log(FND_FILE.LOG,'7-3-1配送区分が基準明細の集約合計を超えるかチェック:重量');

debug_log(FND_FILE.LOG,'7-3-1:基準明細重量：' || first_intensive_sum_weight);

debug_log(FND_FILE.LOG,'7-3-1:次の配送区分重量：' || ln_next_weight_capacity);

--

            -- 重量の場合

--

            IF (first_intensive_sum_weight > ln_next_weight_capacity) THEN

--

debug_log(FND_FILE.LOG,'7-3-1-1重量オーバー');

              -- 集約合計重量が積載重量をオーバーするため混載不可、集約とする

              -- 処理済フラグ：処理済

              lt_intensive_tab(ln_parent_no).finish_sum_flag := cv_finish_intensive;

--

              -- 混載種別格納

              lt_mixed_class_tab(ln_parent_no) := gv_mixed_class_int;  -- 集約

--

              -- 混載済データカウンタ格納

              lt_mixed_cnt_tab(ln_parent_no) := ln_loop_cnt;

--

              -- 混載済フラグ設定

              lv_mixed_flag  := gv_mixed_class_int; -- 集約

--

            ELSE

--

debug_log(FND_FILE.LOG,'7-3-1-2重量オーバーしない');

              -- 積載オーバーチェック用に変数に格納

              first_max_weight := ln_next_weight_capacity;

--

            END IF;

--

          ELSE

debug_log(FND_FILE.LOG,'7-3-2配送区分が基準明細の集約合計を超えるかチェック:容積');

debug_log(FND_FILE.LOG,'7-3-2:基準明細容積：' || first_intensive_sum_capacity);

debug_log(FND_FILE.LOG,'7-3-2:次の配送区分容積：' || ln_next_weight_capacity);

            -- 容積の場合

            IF (first_intensive_sum_capacity > ln_next_weight_capacity) THEN

--

debug_log(FND_FILE.LOG,'7-3-2-1容積オーバー');

              -- 集約合計重量が積載重量をオーバーするため混載不可、集約とする

              lt_intensive_tab(ln_parent_no).finish_sum_flag := cv_finish_intensive;

--

              -- 混載種別格納

              lt_mixed_class_tab(ln_parent_no) := gv_mixed_class_int;  -- 集約

--

              -- 混載済データカウンタ格納

              lt_mixed_cnt_tab(ln_parent_no) := ln_loop_cnt;

--

              -- 混載済フラグ設定

              lv_mixed_flag  := gv_mixed_class_int; -- 集約

--

            ELSE

debug_log(FND_FILE.LOG,'7-3-2-2容積オーバーしない');

--

              -- 積載オーバーチェック用に変数に格納

              first_max_capacity := ln_next_weight_capacity;

--

            END IF;

--

          END IF;

--

        -- 次の配送区分が取得できない場合

        ELSE

debug_log(FND_FILE.LOG,'7-4次の配送区分取得できず');

----

          -- 混載種別格納に集約をセットする

          lt_mixed_class_tab(ln_parent_no) := gv_mixed_class_int;  -- 集約

--

debug_log(FND_FILE.LOG,'7-4-1基準レコードを集約にする');

debug_log(FND_FILE.LOG,'7-4-1基準レコードのカウンタ：'||ln_parent_no);

          -- 基準レコードを処理済にする。

          lt_intensive_tab(ln_parent_no).finish_sum_flag := cv_finish_intensive;

                                                                        -- 処理済フラグ

debug_log(FND_FILE.LOG,'7-4-2基準レコードを処理済にする');

--

          -- 混載済フラグ設定

          lv_mixed_flag  := gv_mixed_class_int; -- 集約

debug_log(FND_FILE.LOG,'7-4-3混載済フラグ：集約');

--

        END IF;

--

      END IF;

--

    EXCEPTION

      -- *** 共通関数例外ハンドラ ***

      WHEN global_api_expt THEN

        ov_errmsg  := lv_errmsg;

        ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||cv_sub_prg_name||gv_msg_part||lv_errbuf,1,5000);

        ov_retcode := gv_status_error;

      -- *** 共通関数OTHERS例外ハンドラ ***

      WHEN global_api_others_expt THEN

        ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||cv_sub_prg_name||gv_msg_part||SQLERRM;

        ov_retcode := gv_status_error;

      -- *** OTHERS例外ハンドラ ***

      WHEN OTHERS THEN

        ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||cv_sub_prg_name||gv_msg_part||SQLERRM;

        ov_retcode := gv_status_error;

--

    END lproc_keybrake_process;

--

    -- =================================

    -- 混載テーブル登録用データ設定処理

    -- =================================

    PROCEDURE set_ins_data(

        ov_errbuf     OUT NOCOPY VARCHAR2  -- エラー・メッセージ --# 固定 #

      , ov_retcode    OUT NOCOPY VARCHAR2  -- リターン・コード   --# 固定 #

      , ov_errmsg     OUT NOCOPY VARCHAR2  -- ユーザー・エラー・メッセージ --# 固定 #

    )

    IS

      -- ===============================

      -- 固定ローカル定数

      -- ===============================

      cv_sub_prg_name   CONSTANT VARCHAR2(100) := '[set_ins_data]'; -- サブプログラム名

--

--2008.05.27 D.Sugahara 不具合No9対応->

      lv_small_amt_cnt NUMBER DEFAULT 0;   -- 小口区分判定用カウント

--2008.05.27 D.Sugahara 不具合No9対応<-

--

    BEGIN

--

--

debug_log(FND_FILE.LOG,'9-1混載テーブル登録用データ設定処理');

debug_log(FND_FILE.LOG,'9-2仮配送No取得');

--2008/10/16 H.Itou Del Start T_S_625

--      -- 仮配送NO取得

--      SELECT xxwsh_temp_delivery_no_s1.NEXTVAL

--      INTO   ln_temp_ship_no

--      FROM   dual;

--2008/10/16 H.Itou Del End T_S_625

debug_log(FND_FILE.LOG,'9-3最適配送区分設定');

      -- ======================

      -- B-12.最適配送区分設定

      -- ======================

      -- コード区分２設定（基準レコードの処理区分）

      IF (lt_intensive_tab(ln_parent_no).transaction_type = gv_ship_type_ship) THEN -- 出荷依頼

debug_log(FND_FILE.LOG,'9-4-0最適配送区分設定lt_intensive_tab(ln_parent_no).transaction_type:'||lt_intensive_tab(ln_parent_no).transaction_type);

        lv_cdkbn_2_opt  :=  gv_cdkbn_ship_to; -- 配送先

      ELSE

        lv_cdkbn_2_opt  :=  gv_cdkbn_storage; -- 倉庫

      END IF;

debug_log(FND_FILE.LOG,'9-4最適配送区分設定');

      -- 共通関数：積載効率チェック

      -- 重量容積区分：重量

      IF (first_weight_capacity_class = gv_weight) THEN

debug_log(FND_FILE.LOG,'9-4-1重量');

debug_log(FND_FILE.LOG,'★★★★★★★★★★★★★★★');

debug_log(FND_FILE.LOG,'9-4-1-1:混載種別：'|| lt_mixed_class_tab(ln_parent_no));

debug_log(FND_FILE.LOG,'9-4-1-1合計重量：'||ln_intensive_weight);

debug_log(FND_FILE.LOG,'9-4-1-1コード区分１：'||gv_cdkbn_storage);

debug_log(FND_FILE.LOG,'9-4-1-1入出庫場所コード１：'||first_deliver_from);

debug_log(FND_FILE.LOG,'9-4-1-1コード区分２：'||lv_cdkbn_2_opt);

debug_log(FND_FILE.LOG,'9-4-1-1入出庫場所コード２：'||first_deliver_to);

debug_log(FND_FILE.LOG,'9-4-1-1基準日：'||TO_CHAR(first_schedule_ship_date,'YYYY/MM/DD'));

debug_log(FND_FILE.LOG,'★★★★★★★★★★★★★★★');

        xxwsh_common910_pkg.calc_load_efficiency(

            in_sum_weight                  => ln_intensive_weight

                                                            -- 1.合計重量

          , in_sum_capacity                => NULL          -- 2.合計容積

          , iv_code_class1                 => gv_cdkbn_storage

                                                            -- 3.コード区分１

          , iv_entering_despatching_code1  => first_deliver_from

                                                            -- 4.入出庫場所コード１

          , iv_code_class2                 => lv_cdkbn_2_opt

                                                            -- 5.コード区分２

          , iv_entering_despatching_code2  => first_deliver_to

                                                            -- 6.入出庫場所コード２

          , iv_ship_method                 => NULL          -- 7.出荷方法

          , iv_prod_class                  => gv_prod_class -- 8.商品区分

          , iv_auto_process_type           => cv_allocation -- 9.自動配車対象区分

          , id_standard_date               => first_schedule_ship_date

                                                            -- 10.基準日(適用日基準日)

          , ov_retcode                     => lv_retcode    -- 11.リターンコード

          , ov_errmsg_code                 => lv_errmsg     -- 12.エラーメッセージコード

          , ov_errmsg                      => lv_errbuf     -- 13.エラーメッセージ

          , ov_loading_over_class          => lv_loading_over_class

                                                            -- 14.積載オーバー区分

          , ov_ship_methods                => lv_ship_optimization

                                                            -- 15.出荷方法(最適配送区分)

          , on_load_efficiency_weight      => ln_load_efficiency_weight

                                                            -- 16.重量積載効率

          , on_load_efficiency_capacity    => ln_load_efficiency_capacity

                                                            -- 17.容積積載効率

          , ov_mixed_ship_method           => lv_mixed_ship_method

                                                            -- 18.混載配送区分

        );

        -- 共通関数がエラーの場合

-- Ver1.7 M.Hokkanji START

        IF (lv_retcode <> gv_status_normal) THEN

--        IF (lv_retcode = gv_status_error) THEN

-- Ver1.7 M.Hokkanji End

          gv_err_key  :=  ln_intensive_weight -- 1.合計重量

                          || gv_msg_comma ||

                          NULL                -- 2.合計容積

                          || gv_msg_comma ||

                          gv_cdkbn_storage    -- 3.コード区分１

                          || gv_msg_comma ||

                          first_deliver_from  -- 4.入出庫場所コード１

                          || gv_msg_comma ||

                          lv_cdkbn_2_opt      -- 5.コード区分２

                          || gv_msg_comma ||

                          first_deliver_to    -- 6.入出庫場所コード２

                          || gv_msg_comma ||

                          NULL                -- 7.出荷方法

                          || gv_msg_comma ||

                          gv_prod_class       -- 8.商品区分

                          || gv_msg_comma ||

                          cv_allocation       -- 9.自動配車対象区分

                          || gv_msg_comma ||

                          TO_CHAR(first_schedule_ship_date, 'YYYY/MM/DD') -- 10.基準日

                          ;

          -- エラーメッセージ取得

          lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(

                          gv_xxwsh            -- モジュール名略称：XXWSH 出荷・引当/配車

                        , gv_msg_xxwsh_11810  -- メッセージ：APP-XXWSH-11810 共通関数エラー

                        , gv_fnc_name         -- トークン：FNC_NAME

                        , 'xxwsh_common910_pkg.calc_load_efficiency' -- 関数名

                        , gv_tkn_key              -- トークン：KEY

                        , gv_err_key              -- 関数実行キー

                        ),1,5000);

          RAISE global_api_expt;

        END IF;

debug_log(FND_FILE.LOG,'9-4-1-1積載オーバー区分：'||lv_loading_over_class);

debug_log(FND_FILE.LOG,'9-4-1-1出荷方法(最適配送区分)：'||lv_ship_optimization);

debug_log(FND_FILE.LOG,'9-4-1-1重量積載効率：'||ln_load_efficiency_weight);

debug_log(FND_FILE.LOG,'9-4-1-1容積積載効率：'||ln_load_efficiency_capacity);

debug_log(FND_FILE.LOG,'9-4-1-1混載配送区分：'||lv_mixed_ship_method);

      -- 重量容積区分：容積

      ELSE

debug_log(FND_FILE.LOG,'9-4-2容積');

debug_log(FND_FILE.LOG,'★★★★★★★★★★★★★★★');

debug_log(FND_FILE.LOG,'9-4-2-1-0:'|| ln_parent_no);

debug_log(FND_FILE.LOG,'9-4-2-1-1:混載種別'|| lt_mixed_class_tab(ln_parent_no));

debug_log(FND_FILE.LOG,'9-4-2-1-2合計容積：'||ln_intensive_capacity);

debug_log(FND_FILE.LOG,'9-4-2-1-3コード区分１：'||gv_cdkbn_storage);

debug_log(FND_FILE.LOG,'9-4-2-1-4入出庫場所コード１：'||first_deliver_from);

debug_log(FND_FILE.LOG,'9-4-2-1-5コード区分２：'||lv_cdkbn_2_opt);

debug_log(FND_FILE.LOG,'9-4-2-1-6入出庫場所コード２：'||first_deliver_to);

debug_log(FND_FILE.LOG,'9-4-1-1-7基準日：'||TO_CHAR(first_schedule_ship_date,'YYYY/MM/DD'));

debug_log(FND_FILE.LOG,'★★★★★★★★★★★★★★★');

        xxwsh_common910_pkg.calc_load_efficiency(

            in_sum_weight                  => NULL          -- 1.合計重量

          , in_sum_capacity                => ln_intensive_capacity

                                                            -- 2.合計容積

          , iv_code_class1                 => gv_cdkbn_storage

                                                            -- 3.コード区分１

          , iv_entering_despatching_code1  => first_deliver_from

                                                            -- 4.入出庫場所コード１

          , iv_code_class2                 => lv_cdkbn_2_opt

                                                            -- 5.コード区分２

          , iv_entering_despatching_code2  => first_deliver_to

                                                            -- 6.入出庫場所コード２

          , iv_ship_method                 => NULL          -- 7.出荷方法

          , iv_prod_class                  => gv_prod_class -- 8.商品区分

          , iv_auto_process_type           => cv_allocation -- 9.自動配車対象区分

          , id_standard_date               => first_schedule_ship_date

                                                            -- 10.基準日(適用日基準日)

          , ov_retcode                     => lv_retcode

                                                            -- 11.リターンコード

          , ov_errmsg_code                 => lv_errmsg     -- 12.エラーメッセージコード

          , ov_errmsg                      => lv_errbuf     -- 13.エラーメッセージ

          , ov_loading_over_class          => lv_loading_over_class

                                                            -- 14.積載オーバー区分

          , ov_ship_methods                => lv_ship_optimization

                                                            -- 15.出荷方法(最適配送区分)

          , on_load_efficiency_weight      => ln_load_efficiency_weight

                                                            -- 16.重量積載効率

          , on_load_efficiency_capacity    => ln_load_efficiency_capacity

                                                            -- 17.容積積載効率

          , ov_mixed_ship_method           => lv_mixed_ship_method

                                                            -- 18.混載配送区分

        );

        -- 共通関数がエラーの場合

-- Ver1.7 M.Hokkanji START

        IF (lv_retcode <> gv_status_normal) THEN

--        IF (lv_retcode = gv_status_error) THEN

-- Ver1.7 M.Hokkanji End

          gv_err_key  :=  NULL                  -- 1.合計重量

                          || gv_msg_comma ||

                          ln_intensive_capacity -- 2.合計容積

                          || gv_msg_comma ||

                          gv_cdkbn_storage      -- 3.コード区分１

                          || gv_msg_comma ||

                          first_deliver_from    -- 4.入出庫場所コード１

                          || gv_msg_comma ||

                          gv_cdkbn_ship_to      -- 5.コード区分２

                          || gv_msg_comma ||

                          first_deliver_to      -- 6.入出庫場所コード２

                          || gv_msg_comma ||

                          NULL                  -- 7.出荷方法

                          || gv_msg_comma ||

                          gv_prod_class         -- 8.商品区分

                          || gv_msg_comma ||

                          cv_allocation         -- 9.自動配車対象区分

                          || gv_msg_comma ||

                          TO_CHAR(first_schedule_ship_date, 'YYYY/MM/DD') -- 10.基準日

                          ;

          -- エラーメッセージ取得

          lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(

                          gv_xxwsh            -- モジュール名略称：XXWSH 出荷・引当/配車

                        , gv_msg_xxwsh_11810  -- メッセージ：APP-XXWSH-11810 共通関数エラー

                        , gv_fnc_name         -- トークン：FNC_NAME

                        , 'xxwsh_common910_pkg.calc_load_efficiency' -- 関数名

                        , gv_tkn_key              -- トークン：KEY

                        , gv_err_key              -- 関数実行キー

                        ),1,5000);

          RAISE global_api_expt;

        END IF;

debug_log(FND_FILE.LOG,'9-4-2-1積載オーバー区分：'||lv_loading_over_class);

debug_log(FND_FILE.LOG,'9-4-2-1出荷方法(最適配送区分)：'||lv_ship_optimization);

debug_log(FND_FILE.LOG,'9-4-2-1重量積載効率：'||ln_load_efficiency_weight);

debug_log(FND_FILE.LOG,'9-4-2-1容積積載効率：'||ln_load_efficiency_capacity);

debug_log(FND_FILE.LOG,'9-4-2-1混載配送区分：'||lv_mixed_ship_method);

      END IF;

--

-- 2008/10/01 H.Itou Del Start

--for j in 1..lt_intensive_no_tab.count loop

--debug_log(FND_FILE.LOG,'混載合計重量：'||lt_mix_total_weight(j));

--debug_log(FND_FILE.LOG,'混載合計容積：'||lt_mix_total_capacity(j));

--end loop;

-- 2008/10/01 H.Itou Del End

--

-- Ver1.3 M.Hokkanji Start

      -- 混載の場合、最適化した配送区分が混載データに存在するかを確認

      IF (lt_mixed_class_tab(ln_parent_no) = gv_mixed_class_mixed) THEN

        IF (lt_intensive_tab(ln_child_no).transaction_type = gv_ship_type_ship) THEN -- 出荷依頼

debug_log(FND_FILE.LOG,'9-4-a最適配送区分設定');

          lv_cdkbn_2_con  :=  gv_cdkbn_ship_to; -- 配送先

        ELSE

          lv_cdkbn_2_con  :=  gv_cdkbn_storage; -- 倉庫

        END IF;

debug_log(FND_FILE.LOG,'9-4-b最適配送区分存在チェック');

        get_consolidated_flag(

            iv_code_class1                => gv_cdkbn_storage         -- コード区分１

          , iv_entering_despatching_code1 => first_deliver_from       -- 入出庫場所１

          , iv_code_class2                => lv_cdkbn_2_con           -- コード区分２

          , iv_entering_despatching_code2 => lt_intensive_tab(ln_child_no).deliver_to

                                                                      -- 入出庫場所２

          , iv_ship_method                => lv_ship_optimization     -- 配送区分

          , ov_consolidate_flag           => lv_consolid_flag_ships

                                                                      -- 混載可否フラグ:配送区分

          , ov_errbuf                     => lv_errbuf

          , ov_retcode                    => lv_retcode

          , ov_errmsg                     => lv_errmsg

        );

        IF (lv_retcode = gv_status_error) THEN

debug_log(FND_FILE.LOG,'9-4-b最適配送区分存在チェック関数エラー');

          RAISE global_api_expt;

        END IF;

        -- 混載可否フラグが取得できなかった場合

        IF (NVL(lv_consolid_flag_ships,cv_consolid_false) = cv_consolid_false) THEN

debug_log(FND_FILE.LOG,'9-4-c最適配送区分取得失敗');

          lv_ship_optimization := lt_ship_method_cls;

debug_log(FND_FILE.LOG,'9-4-d混載配送区分取得');

debug_log(FND_FILE.LOG,'配送区分：'||lv_ship_optimization);

debug_log(FND_FILE.LOG,'基準日：'||TO_CHAR(first_schedule_ship_date,'YYYY/MM/DD'));

          BEGIN

            SELECT xsmv.mixed_ship_method_code

            INTO   lv_mixed_ship_method

            FROM   xxwsh_ship_method2_v xsmv

            WHERE  xsmv.ship_method_code = lv_ship_optimization

            AND    first_schedule_ship_date

                   BETWEEN xsmv.start_date_active

                       AND NVL(xsmv.end_date_active,first_schedule_ship_date);

          EXCEPTION

            WHEN OTHERS THEN

debug_log(FND_FILE.LOG,'9-4-e混載配送区分取得失敗');

            -- エラーメッセージ取得

            lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(

                           gv_xxwsh            -- モジュール名略称：XXWSH 出荷・引当/配車

                          ,gv_msg_xxwsh_11804  -- 対象データなし

                          ,gv_tkn_table        -- トークン'TABLE'

                          ,cv_table_name_con   -- テーブル名：配送区分情報VIEW2

                          ,gv_tkn_key          -- トークン'KEY'

                          ,cv_ship_method_name || ':' || lv_ship_optimization || '、' ||

                          cv_effective_date || ':' || TO_CHAR(first_schedule_ship_date,'YYYY/MM/DD')

                         ) ,1 ,5000);

            RAISE global_api_expt;

          END;

        END IF;

      END IF;

debug_log(FND_FILE.LOG,'9-4-f小口区分確認');

      -- 混載データがルートに存在するかチェックする判断を行うため

      -- 小口区分チェックをループ前に移動

      --小口区分確認

      BEGIN

        SELECT  COUNT(xsmv.ship_method_code)                 -- 出荷方法

          INTO  lv_small_amt_cnt

          FROM  xxwsh_ship_method2_v xsmv                    -- 配送区分情報View2

         WHERE xsmv.ship_method_code = lv_ship_optimization  -- 配送区分

           AND xsmv.small_amount_class = '1'                 -- 小口区分

           AND xsmv.start_date_active <= gd_date_from        -- 出荷方法適用開始日

           AND (xsmv.end_date_active IS NULL

                OR xsmv.end_date_active >= gd_date_from)     -- 出荷方法適用終了日

          AND ROWNUM = 1

          ;

      EXCEPTION

        -- *** OTHERS例外ハンドラ ***

        WHEN OTHERS THEN

          lv_small_amt_cnt := 0;

      END;

debug_log(FND_FILE.LOG,'小口区分lv_small_amt_cnt:' || lv_small_amt_cnt);

      -- 混載で小口ではない場合混載配送区分が該当ルートに存在するかをチェック

      IF ((lt_mixed_class_tab(ln_parent_no) = gv_mixed_class_mixed)

        AND (lv_small_amt_cnt = 0 )) THEN

debug_log(FND_FILE.LOG,'9-4-g混載配送区分ルートチェック(基準元)');

debug_log(FND_FILE.LOG,'コード区分１:' || gv_cdkbn_storage);

debug_log(FND_FILE.LOG,'入出庫場所１:' || first_deliver_from);

debug_log(FND_FILE.LOG,'コード区分２:' || lv_cdkbn_2_opt);

debug_log(FND_FILE.LOG,'入出庫場所２:' || first_deliver_to);

debug_log(FND_FILE.LOG,'配送区分:' || lv_mixed_ship_method );

        get_consolidated_flag(

            iv_code_class1                => gv_cdkbn_storage         -- コード区分１

          , iv_entering_despatching_code1 => first_deliver_from       -- 入出庫場所１

          , iv_code_class2                => lv_cdkbn_2_opt           -- コード区分２

          , iv_entering_despatching_code2 => first_deliver_to

                                                                      -- 入出庫場所２

-- 2008/11/19 H.Itou Mod Start 統合テスト指摘666 出荷方法アドオンマスタに混載配送区分のデータは登録しないので、配送区分でチェック実施。

--          , iv_ship_method                => lv_mixed_ship_method     -- 配送区分

          , iv_ship_method                => lv_ship_optimization     -- 配送区分

-- 2008/11/19 H.Itou Mod End

          , ov_consolidate_flag           => lv_consolid_flag_ships

                                                                      -- 混載可否フラグ:配送区分

          , ov_errbuf                     => lv_errbuf

          , ov_retcode                    => lv_retcode

          , ov_errmsg                     => lv_errmsg

        );

        IF (lv_retcode = gv_status_error) THEN

debug_log(FND_FILE.LOG,'9-4-g混載配送区分ルートチェック(基準元)関数エラー');

          RAISE global_api_expt;

        END IF;

        -- 混載可否フラグが取得できなかった場合

        IF (NVL(lv_consolid_flag_ships,cv_consolid_false) = cv_consolid_false) THEN

debug_log(FND_FILE.LOG,'9-4-g混載配送区分ルートチェック(基準元)関数エラー');

          -- エラーメッセージ取得

          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(

                         gv_xxwsh            -- モジュール名略称：XXWSH 出荷・引当/配車

                        ,gv_msg_xxwsh_11814  -- 配送区分存在エラー

                        ,gv_tkn_codekbn1     -- トークン'コード区分1'

                        ,gv_cdkbn_storage

                        ,gv_tkn_from         -- トークン'保管場所1'

                        ,first_deliver_from

                        ,gv_tkn_codekbn2     -- トークン'コード区分2'

                        ,lv_cdkbn_2_opt

                        ,gv_tkn_to           -- トークン'保管場所2'

                        ,first_deliver_to

                        ,gv_tkn_ship_method  -- トークン'配送区分'

                        ,lv_mixed_ship_method

                        ,gv_tkn_source_no    -- トークン'集約元No'

                        ,first_intensive_source_no

                       ) ,1 ,5000);

          RAISE global_api_expt;

        END IF;

debug_log(FND_FILE.LOG,'9-4-h混載配送区分ルートチェック(混載先)');

debug_log(FND_FILE.LOG,'コード区分１:' || gv_cdkbn_storage);

debug_log(FND_FILE.LOG,'入出庫場所１:' || first_deliver_from);

debug_log(FND_FILE.LOG,'コード区分２:' || lv_cdkbn_2_con);

debug_log(FND_FILE.LOG,'入出庫場所２:' || first_deliver_to);

debug_log(FND_FILE.LOG,'配送区分:' || lv_mixed_ship_method );

        get_consolidated_flag(

            iv_code_class1                => gv_cdkbn_storage         -- コード区分１

          , iv_entering_despatching_code1 => first_deliver_from       -- 入出庫場所１

          , iv_code_class2                => lv_cdkbn_2_con           -- コード区分２

          , iv_entering_despatching_code2 => lt_intensive_tab(ln_child_no).deliver_to

                                                                      -- 入出庫場所２

-- 2008/11/19 H.Itou Mod Start 統合テスト指摘666 出荷方法アドオンマスタに混載配送区分のデータは登録しないので、配送区分でチェック実施。

--          , iv_ship_method                => lv_mixed_ship_method     -- 配送区分

          , iv_ship_method                => lv_ship_optimization     -- 配送区分

-- 2008/11/19 H.Itou Mod End

          , ov_consolidate_flag           => lv_consolid_flag_ships

                                                                      -- 混載可否フラグ:配送区分

          , ov_errbuf                     => lv_errbuf

          , ov_retcode                    => lv_retcode

          , ov_errmsg                     => lv_errmsg

        );

        IF (lv_retcode = gv_status_error) THEN

debug_log(FND_FILE.LOG,'9-4-h混載配送区分ルートチェック(混載先)関数エラー');

          RAISE global_api_expt;

        END IF;

        -- 混載可否フラグが取得できなかった場合

        IF (NVL(lv_consolid_flag_ships,cv_consolid_false) = cv_consolid_false) THEN

debug_log(FND_FILE.LOG,'9-4-h混載配送区分ルートチェック(混載先)関数エラー');

          -- エラーメッセージ取得

          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(

                         gv_xxwsh            -- モジュール名略称：XXWSH 出荷・引当/配車

                        ,gv_msg_xxwsh_11814  -- 配送区分存在エラー

                        ,gv_tkn_codekbn1     -- トークン'コード区分1'

                        ,gv_cdkbn_storage

                        ,gv_tkn_from         -- トークン'保管場所1'

                        ,first_deliver_from

                        ,gv_tkn_codekbn2     -- トークン'コード区分2'

                        ,lv_cdkbn_2_con

                        ,gv_tkn_to           -- トークン'保管場所2'

                        ,lt_intensive_tab(ln_child_no).deliver_to

                        ,gv_tkn_ship_method  -- トークン'配送区分'

                        ,lv_mixed_ship_method

                        ,gv_tkn_source_no    -- トークン'集約元No'

                        ,first_intensive_source_no

                       ) ,1 ,5000);

          RAISE global_api_expt;

        END IF;

      END IF;

-- Ver1.3 M.Hokkanji End

      <<plsql_tab_setting_loop>>

      FOR rec_idx IN 1..lt_intensive_no_tab.COUNT LOOP

--2008/10/16 H.Itou Add Start T_S_625

        -- 小口の場合、混載・集約を解除します。

        IF (lv_small_amt_cnt <> 0) THEN

          -- ==============================

          --  小口配送情報作成処理

          -- ==============================

          set_small_sam_class(

             iv_intensive_no => lt_intensive_no_tab(rec_idx)                 --集約No

-- 2008/10/30 H.Itou Add Start 統合テスト指摘526 リーフの場合の配送区分を指定

           , iv_ship_method  => lv_ship_optimization                         --配送区分

-- 2008/10/30 H.Itou Add End

           , ov_errbuf       => lv_errbuf    -- エラー・メッセージ           --# 固定 #

           , ov_retcode      => lv_retcode   -- リターン・コード             --# 固定 #

           , ov_errmsg       => lv_errmsg    -- ユーザー・エラー・メッセージ --# 固定 #

          );

          -- 処理がエラーの場合

          IF (lv_retcode = gv_status_error) THEN

            RAISE global_api_expt;

          END IF;

--

        ELSE

          -- 1件目のとき、仮配送No取得

          IF (rec_idx = 1) THEN

            -- 仮配送NO取得

            SELECT xxwsh_temp_delivery_no_s1.NEXTVAL

            INTO   ln_temp_ship_no

            FROM   dual;

          END IF;

--2008/10/16 H.Itou Add End T_S_625

debug_log(FND_FILE.LOG,'9-5PLSQLに格納');

          -- 登録用カウント

          ln_tab_ins_idx := ln_tab_ins_idx + 1;

debug_log(FND_FILE.LOG,'9-5-0 インサートカウント:'|| ln_tab_ins_idx);

debug_log(FND_FILE.LOG,'9-5-0 rec_idx:'|| rec_idx);

          -- =========================================

          -- 自動配車混載中間テーブル用PL/SQL表に格納

          -- =========================================

          gt_intensive_no_tab(ln_tab_ins_idx)         := lt_intensive_no_tab(rec_idx);

                                                                              -- 集約No

debug_log(FND_FILE.LOG,'9-5-1-0集約No(gt_intensive_no_tab):'|| gt_intensive_no_tab(ln_tab_ins_idx));

          gt_delivery_no_tab(ln_tab_ins_idx)          := ln_temp_ship_no;       -- 仮配送No

debug_log(FND_FILE.LOG,'9-5-1-0-1仮配送Nogt_delivery_no_tab(ln_tab_ins_idx):'|| gt_delivery_no_tab(ln_tab_ins_idx));

          gt_default_line_number_tab(ln_tab_ins_idx)  := first_intensive_source_no;

debug_log(FND_FILE.LOG,'9-5-1-0-2基準明細No(gt_default_line_number_tab(ln_tab_ins_idx)):'|| gt_default_line_number_tab(ln_tab_ins_idx));

                                                                              -- 基準明細No

debug_log(FND_FILE.LOG,'9-5-1-1-修正配送区分');

--debug_log(FND_FILE.LOG,'9-5-1-1-1 ln_loop_cnt:'|| ln_loop_cnt);

--debug_log(FND_FILE.LOG,'9-5-1-1-1 ln_first_intensive_cnt:'|| ln_parent_no);

--debug_log(FND_FILE.LOG,'9-5-1-1-1 lt_mixed_class_tab(ln_parent_no):'|| lt_mixed_class_tab(ln_parent_no));

--debug_log(FND_FILE.LOG,'9-5-1-1-1 ln_tab_ins_idx:'|| ln_tab_ins_idx);

debug_log(FND_FILE.LOG,'9-5-1-1-1 ln_parent_no:'|| ln_parent_no);

--2008.05.27 D.Sugahara 不具合No9対応->

-- Ver1.3 M.Hokkanji Start

          -- 混載データがルートに存在するかチェックする判断を行うため

          -- 小口区分チェックをループ前に移動

/*

          --小口区分確認

          BEGIN

            SELECT  COUNT(xsmv.ship_method_code)                 -- 出荷方法

              INTO  lv_small_amt_cnt

              FROM  xxwsh_ship_method2_v xsmv                    -- 配送区分情報View2

             WHERE xsmv.ship_method_code = lv_ship_optimization  -- 配送区分

               AND xsmv.small_amount_class = '1'                 -- 小口区分

               AND xsmv.start_date_active <= gd_date_from        -- 出荷方法適用開始日

               AND (xsmv.end_date_active IS NULL

                    OR xsmv.end_date_active >= gd_date_from)     -- 出荷方法適用終了日

              AND ROWNUM = 1

              ;

          EXCEPTION

            -- *** OTHERS例外ハンドラ ***

            WHEN OTHERS THEN

              lv_small_amt_cnt := 0;

          END;

*/

-- Ver1.3 M.Hokkanji End

--2008.05.27 D.Sugahara 不具合No9対応<-

          -- 修正配送区分

          IF (lt_mixed_class_tab(ln_parent_no) = gv_mixed_class_mixed) THEN

--        IF (lt_mixed_class_tab(ln_first_intensive_cnt) = gv_mixed_class_mixed) THEN

debug_log(FND_FILE.LOG,'9-5-1-1修正配送区分：混載');

            -- 混載種別が「混載」の場合

--2008.05.27 D.Sugahara 不具合No9対応->

            --小口の場合は混載配送区分ではなく通常の配送区分をセットする

            --gt_fixed_ship_code_tab(ln_tab_ins_idx)    := lv_mixed_ship_method;  -- 混載配送区分

            IF (lv_small_amt_cnt = 0) THEN

              gt_fixed_ship_code_tab(ln_tab_ins_idx)    := lv_mixed_ship_method;  -- 混載配送区分

            ELSE

              gt_fixed_ship_code_tab(ln_tab_ins_idx)    := lv_ship_optimization;  -- 出荷方法

            END IF;

--2008.05.27 D.Sugahara 不具合No9対応<-

          ELSE

debug_log(FND_FILE.LOG,'9-5-1-2修正配送区分：集約');

            -- 混載種別が「集約」の場合

            gt_fixed_ship_code_tab(ln_tab_ins_idx)    := lv_ship_optimization;  -- 出荷方法

          END IF;

debug_log(FND_FILE.LOG,'9-5-1-2修正配送区分:'||ln_tab_ins_idx);

debug_log(FND_FILE.LOG,'9-5-1-2修正配送区分:'||gt_fixed_ship_code_tab(ln_tab_ins_idx));

          -- 混載種別

          IF lv_mixed_flag = gv_mixed_class_mixed THEN

debug_log(FND_FILE.LOG,'9-5-2-1混載種別：混載');

debug_log(FND_FILE.LOG,'9-5-2-1-1ln_tab_ins_idx:'||ln_tab_ins_idx);

--

            gt_mixed_class_tab(ln_tab_ins_idx)        := gv_mixed_class_mixed; -- 混載

--

          ELSE

debug_log(FND_FILE.LOG,'9-5-2-2混載種別：集約');

--

            gt_mixed_class_tab(ln_tab_ins_idx)        := gv_mixed_class_int;   -- 集約

--

          END IF;

--

          -- 混載合計重量

          gt_mixed_total_weight_tab(ln_tab_ins_idx)   := lt_mix_total_weight(rec_idx);

debug_log(FND_FILE.LOG,'9-5-3混載合計重量');

--

          -- 混載合計容積

          gt_mixed_total_capacity_tab(ln_tab_ins_idx) := lt_mix_total_capacity(rec_idx);

debug_log(FND_FILE.LOG,'9-5-4混載合計容積');

--

          -- 混載元No

          gt_mixed_no_tab(ln_tab_ins_idx)             := first_intensive_source_no;

debug_log(FND_FILE.LOG,'9-5-5混載元No');

--

--2008/10/16 H.Itou Add Start T_S_625

        END IF;

--2008/10/16 H.Itou Add End

      END LOOP plsql_tab_setting_loop;

debug_log(FND_FILE.LOG,'9-6 混載合計重量、混載合計容積をリセット');

      -- 混載合計重量、混載合計容積をリセット

      ln_intensive_weight   := 0; -- 混載合計重量

      ln_intensive_capacity := 0; -- 混載合計容積

      ln_order_num_cnt      := 1; -- 配送区分検索回数

--

      -- 混載合計重量・容積登録用カウントリセット

      ln_intensive_no_cnt   := 0;   -- カウンタ

      lt_intensive_no_tab.DELETE;   -- 集約No用テーブル

      -- 混載合計重量・容積初期化

      lt_mix_total_weight.DELETE;

      lt_mix_total_capacity.DELETE;

--

debug_log(FND_FILE.LOG,'6-7 PL/SQL表初期化');

      -- PL/SQL表リセット

      lt_intensive_no_tab.DELETE; -- 集約No

      lt_mixed_class_tab.DELETE;  -- 混載種別

--

      -- ループカウントリセット

--        ln_loop_cnt := ln_start_no - 1;

--debug_log(FND_FILE.LOG,'6-7-1 ループカウントリセット:'|| ln_loop_cnt);

        -- グループカウントをリセットする

--        ln_grp_sum_cnt := 0;

--debug_log(FND_FILE.LOG,'6-7-2 グループカウントリセット:'|| ln_grp_sum_cnt);

      -- 混載済フラグ初期化

      lv_mixed_flag := NULL;

    EXCEPTION

      -- *** 共通関数例外ハンドラ ***

      WHEN global_api_expt THEN

        ov_errmsg  := lv_errmsg;

        ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||cv_sub_prg_name||gv_msg_part||lv_errbuf,1,5000);

        ov_retcode := gv_status_error;

      -- *** 共通関数OTHERS例外ハンドラ ***

      WHEN global_api_others_expt THEN

        ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||cv_sub_prg_name||gv_msg_part||SQLERRM;

        ov_retcode := gv_status_error;

      -- *** OTHERS例外ハンドラ ***

      WHEN OTHERS THEN

        ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||cv_sub_prg_name||gv_msg_part||SQLERRM;

        ov_retcode := gv_status_error;

--

    END set_ins_data;

--

  BEGIN

--

--##################  固定ステータス初期化部 START   ###################

--

    ov_retcode := gv_status_normal;

--

--###########################  固定部 END   ############################

--

debug_log(FND_FILE.LOG,'【集約中間情報抽出処理(B-9)】');

--

    -- 自動配車集約中間テーブル用テーブル初期化

    lt_intensive_tab.DELETE;

    lt_mixed_class_tab.DELETE;

    lt_mix_total_weight.DELETE;

    lt_mix_total_capacity.DELETE;

--

    -- 自動配車混載中間テーブル登録用PL/SQL表初期化

    gt_intensive_no_tab.DELETE;         -- 集約No

    gt_delivery_no_tab.DELETE;          -- 配送No

    gt_default_line_number_tab.DELETE;  -- 基準明細No

    gt_fixed_ship_code_tab.DELETE;      -- 修正配送区分

    gt_mixed_class_tab.DELETE;          -- 混載種別

    gt_mixed_total_weight_tab.DELETE;   -- 混載合計重量

    gt_mixed_total_capacity_tab.DELETE; -- 混載合計容積

    gt_mixed_no_tab.DELETE;             -- 混載元No

--

    -- =========================

    -- B-9.集約中間情報抽出処理

    -- =========================

    OPEN get_intensive_cur;

    FETCH get_intensive_cur BULK COLLECT INTO lt_intensive_tab;

    CLOSE get_intensive_cur;

--

    -- 集約データが存在する

    IF (lt_intensive_tab.COUNT > 0) THEN

--

debug_log(FND_FILE.LOG,'集約START');

--

      <<optimization_loop>>

      LOOP

-----

debug_cnt := debug_cnt + 1;

-----

        -- ループカウント

        ln_loop_cnt := ln_loop_cnt + 1;

--

debug_log(FND_FILE.LOG,'----------------------------');

debug_log(FND_FILE.LOG,'1 ln_loop_cnt1:'|| ln_loop_cnt);

--

        -- 未混載データのみ対象

        IF (lt_intensive_tab(ln_loop_cnt).finish_sum_flag IS NULL) THEN

--

          -- グループカウント

          ln_grp_sum_cnt := ln_grp_sum_cnt + 1;

--

debug_log(FND_FILE.LOG,'1-1 グループカウント:'|| ln_grp_sum_cnt);

debug_log(FND_FILE.LOG,'ループカウント'|| ln_loop_cnt);

debug_log(FND_FILE.LOG,'----------------------------------------');

--

          IF  (ln_grp_sum_cnt = 1) THEN

--

            -- 基準レコードカウント保持

            ln_parent_no  := ln_loop_cnt;

--

debug_log(FND_FILE.LOG,'1-1-1基準レコードを設定');

debug_log(FND_FILE.LOG,'----------------------------------------');

debug_log(FND_FILE.LOG,'1-1-1 ln_parent_no:'|| ln_parent_no);

debug_log(FND_FILE.LOG,'集約No:'|| lt_intensive_tab(ln_parent_no).intensive_no);

debug_log(FND_FILE.LOG,'処理種別:'|| lt_intensive_tab(ln_parent_no).transaction_type);

debug_log(FND_FILE.LOG,'集約元No:'|| lt_intensive_tab(ln_parent_no).intensive_source_no);

debug_log(FND_FILE.LOG,'配送元:'|| lt_intensive_tab(ln_parent_no).deliver_from);

debug_log(FND_FILE.LOG,'配送先:'|| lt_intensive_tab(ln_parent_no).deliver_to);

debug_log(FND_FILE.LOG,'出庫予定日:'|| lt_intensive_tab(ln_parent_no).schedule_ship_date);

debug_log(FND_FILE.LOG,'着荷予定日:'|| lt_intensive_tab(ln_parent_no).schedule_arrival_date);

debug_log(FND_FILE.LOG,'出庫形態:'|| lt_intensive_tab(ln_parent_no).transaction_type_name);

debug_log(FND_FILE.LOG,'運送業者:'|| lt_intensive_tab(ln_parent_no).freight_carrier_code);

debug_log(FND_FILE.LOG,'管轄拠点:'|| lt_intensive_tab(ln_parent_no).head_sales_branch);

debug_log(FND_FILE.LOG,'引当順:'|| lt_intensive_tab(ln_parent_no).reserve_order);

debug_log(FND_FILE.LOG,'集約合計重量:'|| lt_intensive_tab(ln_parent_no).intensive_sum_weight);

debug_log(FND_FILE.LOG,'集約合計容積:'|| lt_intensive_tab(ln_parent_no).intensive_sum_capacity);

debug_log(FND_FILE.LOG,'最大配送区分:'|| lt_intensive_tab(ln_parent_no).max_shipping_method_code);

debug_log(FND_FILE.LOG,'重量容積区分:'|| lt_intensive_tab(ln_parent_no).weight_capacity_class);

debug_log(FND_FILE.LOG,'最大積載重量:'|| lt_intensive_tab(ln_parent_no).max_weight);

debug_log(FND_FILE.LOG,'最大積載容積:'|| lt_intensive_tab(ln_parent_no).max_capacity);

--

--

            -- グループの1レコード目を確保:基準レコード

            first_intensive_no

                  := lt_intensive_tab(ln_parent_no).intensive_no;              -- 集約No

            first_transaction_type

                  := lt_intensive_tab(ln_parent_no).transaction_type;          -- 処理種別

            first_intensive_source_no

                  := lt_intensive_tab(ln_parent_no).intensive_source_no;       -- 集約元No(基準明細)

            first_deliver_from

                  := lt_intensive_tab(ln_parent_no).deliver_from;              -- 配送元

            first_deliver_to

                  := lt_intensive_tab(ln_parent_no).deliver_to;                -- 配送先

            first_schedule_ship_date

                  := lt_intensive_tab(ln_parent_no).schedule_ship_date;        -- 出庫日

            first_schedule_arrival_date

                  := lt_intensive_tab(ln_parent_no).schedule_arrival_date;     -- 着荷日

            first_transaction_type_name

                  := lt_intensive_tab(ln_parent_no).transaction_type_name;     -- 出庫形態

            first_freight_carrier_code

                  := lt_intensive_tab(ln_parent_no).freight_carrier_code;      -- 運送業者

            first_intensive_sum_weight

                  := lt_intensive_tab(ln_parent_no).intensive_sum_weight;      -- 集約合計重量

            first_intensive_sum_capacity

                  := lt_intensive_tab(ln_parent_no).intensive_sum_capacity;    -- 集約合計容積

            first_max_shipping_method_code

                  := lt_intensive_tab(ln_parent_no).max_shipping_method_code;  -- 最大配送区分

            first_weight_capacity_class

                  := lt_intensive_tab(ln_parent_no).weight_capacity_class;     -- 重量容積区分

            first_max_weight

                  := lt_intensive_tab(ln_parent_no).max_weight;                -- 最大積載重量

            first_max_capacity

                  := lt_intensive_tab(ln_parent_no).max_capacity;              -- 最大積載容積

-- 2009/01/05 H.Itou Mod Start 本番障害#879

            first_pre_saved_flg := lt_intensive_tab(ln_parent_no).pre_saved_flg;  -- 拠点混載登録済フラグ

-- 2009/01/05 H.Itou Mod End

--

            -- 比較用変数にキー項目を格納

            lt_prev_ship_date       := lt_intensive_tab(ln_parent_no).schedule_ship_date;    -- 出庫日

            lt_prev_arrival_date    := lt_intensive_tab(ln_parent_no).schedule_arrival_date; -- 着荷日

            lt_prev_ship_from       := lt_intensive_tab(ln_parent_no).deliver_from;          -- 出荷元

            lt_prev_freight_carrier := lt_intensive_tab(ln_parent_no).freight_carrier_code;  -- 運送業者

            lt_prev_w_c_class       := lt_intensive_tab(ln_parent_no).weight_capacity_class; -- 重量容積区分

--

            -- 比較用配送区分

            lt_ship_method_cls      := first_max_shipping_method_code;  -- 最大配送区分

--

            -- =========================================

            -- 基準レコードの混載テーブル用データ仮登録

            -- =========================================

debug_log(FND_FILE.LOG,'1-2基準レコードのデータを格納');

--

            -- 混載カウンタ

            ln_intensive_no_cnt := ln_intensive_no_cnt + 1;

--

debug_log(FND_FILE.LOG,'1-2-1混載カウンタ:'|| ln_intensive_no_cnt);

--

            -- 集約No用PLSQL表に格納

            lt_intensive_no_tab(ln_intensive_no_cnt) := lt_intensive_tab(ln_parent_no).intensive_no;

--

            -- 重量

            IF (lt_intensive_tab(ln_parent_no).weight_capacity_class = gv_weight) THEN

--

debug_log(FND_FILE.LOG,'1-2-1-1重量');

debug_log(FND_FILE.LOG,'1-2-1-2 重量:'||lt_intensive_tab(ln_loop_cnt).intensive_sum_weight);

debug_log(FND_FILE.LOG,'1-2-1-3 lt_mix_total_weight.count:'||lt_mix_total_weight.count);

                -- 集約合計重量

                lt_mix_total_weight(ln_intensive_no_cnt)

                    := lt_intensive_tab(ln_parent_no).intensive_sum_weight;

--

debug_log(FND_FILE.LOG,'1-2-1-4 混載合計重量セット');

                -- 集約合計容積

                lt_mix_total_capacity(ln_intensive_no_cnt) := NULL;

debug_log(FND_FILE.LOG,'1-2-1-5 混載合計容積セット');

                -- 加算チェック用

                ln_intensive_weight := lt_mix_total_weight(ln_intensive_no_cnt);

debug_log(FND_FILE.LOG,'1-2-1-6 加算チェック用基準レコード重量セット');

--

debug_log(FND_FILE.LOG,'GRP混載合計重量:'|| ln_intensive_weight);

debug_log(FND_FILE.LOG,'混載済フラグ:'|| lv_mixed_flag);

--

              -- 容積

              ELSE

--

debug_log(FND_FILE.LOG,'1-2-2-1容積');

                -- 集約合計重量

                lt_mix_total_weight(ln_intensive_no_cnt) := NULL;

--

                -- 集約合計容積

                lt_mix_total_capacity(ln_intensive_no_cnt)

                    := lt_intensive_tab(ln_parent_no).intensive_sum_capacity;

                -- 加算チェック用

                ln_intensive_capacity := lt_mix_total_capacity(ln_intensive_no_cnt);

--

              END IF;

--            -- 混載済データカウンタ格納

--            lt_mixed_cnt_tab(ln_intensive_no_cnt) := ln_first_intensive_cnt;

--

debug_log(FND_FILE.LOG,'1-2-2-2集約No格納');

debug_log(FND_FILE.LOG,'1-2-2-4集約No格納カウント(ln_intensive_no_cnt):'|| ln_intensive_no_cnt);

debug_log(FND_FILE.LOG,'1-2-2-5集約No:'|| lt_intensive_no_tab(ln_intensive_no_cnt));

          END IF;

--

debug_log(FND_FILE.LOG,'----------------------------------------');

debug_log(FND_FILE.LOG,'2次レコード読込：比較対象');

debug_log(FND_FILE.LOG,'----------------------------------------');

debug_log(FND_FILE.LOG,'出庫予定日:'|| lt_intensive_tab(ln_loop_cnt).schedule_ship_date);

debug_log(FND_FILE.LOG,'着荷予定日:'|| lt_intensive_tab(ln_loop_cnt).schedule_arrival_date);

debug_log(FND_FILE.LOG,'配送元:'|| lt_intensive_tab(ln_loop_cnt).deliver_from);

debug_log(FND_FILE.LOG,'運送業者:'|| lt_intensive_tab(ln_loop_cnt).freight_carrier_code);

debug_log(FND_FILE.LOG,'重量容積区分:'|| lt_intensive_tab(ln_loop_cnt).weight_capacity_class);

debug_log(FND_FILE.LOG,'集約元No:'|| lt_intensive_tab(ln_loop_cnt).intensive_source_no);

debug_log(FND_FILE.LOG,'----------------------------------------');

--

          -- キー項目の同じデータを混載する（キーブレイクしない）

          IF  (

                (lt_prev_ship_date           = lt_intensive_tab(ln_loop_cnt).schedule_ship_date)

                                                                                      -- 出庫日

                AND (lt_prev_arrival_date    = lt_intensive_tab(ln_loop_cnt).schedule_arrival_date)

                                                                                      -- 着荷日

                AND (lt_prev_ship_from       = lt_intensive_tab(ln_loop_cnt).deliver_from)

                                                                                      -- 出荷元

                AND (lt_prev_freight_carrier = lt_intensive_tab(ln_loop_cnt).freight_carrier_code)

                                                                                      -- 運送業者

                AND (lt_prev_w_c_class       = lt_intensive_tab(ln_loop_cnt).weight_capacity_class)

              )                                                                       -- 重量容積区分

--

          THEN

--

debug_log(FND_FILE.LOG,'3混載処理');

            -- グループの1件目の重量／容積を集約変数に格納

            IF (ln_grp_sum_cnt > 1) THEN

--

debug_log(FND_FILE.LOG,'3-2 混載相手読込');

debug_log(FND_FILE.LOG,'2レコード目以降');

--

              -- コード区分１、２の設定

              IF (lt_intensive_tab(ln_loop_cnt).transaction_type = gv_ship_type_ship) THEN -- 出荷依頼

                lv_cdkbn_1  :=  gv_cdkbn_ship_to; -- 配送先

                lv_cdkbn_2  :=  gv_cdkbn_ship_to; -- 配送先

              ELSE

                lv_cdkbn_1  :=  gv_cdkbn_storage; -- 倉庫

                lv_cdkbn_2  :=  gv_cdkbn_storage; -- 倉庫

              END IF;

--

-- 2008/10/01 H.Itou Add Start PT 6-1_27 指摘18 基準レコードと同じ配送先の場合は重量オーバーで混載できないので、混載不可とする。

-- 2009/01/05 H.Itou Mod Start 本番障害#879 基準レコードが拠点混載登録済みの場合、同一混載元No(集約元No)以外、混載不可とする。

--              IF (first_deliver_to = lt_intensive_tab(ln_loop_cnt).deliver_to) THEN

              IF   ((first_deliver_to = lt_intensive_tab(ln_loop_cnt).deliver_to) 

                OR ((cv_pre_save IN (first_pre_saved_flg, lt_intensive_tab(ln_loop_cnt).pre_saved_flg))

                AND (first_intensive_source_no <> lt_intensive_tab(ln_loop_cnt).intensive_source_no))) THEN

-- 2009/01/05 H.Itou Mod End

                -- 混載可否フラグ：不可

                lv_consolid_flag := NULL;

--

              -- 基準レコードと違う配送先の場合は、混載可否判定処理を呼び、混載許可フラグを取得する。

              ELSE

-- 2008/10/01 H.Itou Add End

debug_log(FND_FILE.LOG,'3-3 混載可否判定①');

--

                -- ============================

                -- 混載可否判定処理：ルート①

                -- ============================

                get_consolidated_flag(

                      iv_code_class1                => lv_cdkbn_1         -- コード区分１

                    , iv_entering_despatching_code1 => first_deliver_to   -- 入出庫場所１

                    , iv_code_class2                => lv_cdkbn_2         -- コード区分２

                    , iv_entering_despatching_code2 => lt_intensive_tab(ln_loop_cnt).deliver_to

                                                                          -- 入出庫場所２

                    , iv_ship_method                => NULL               -- 配送区分判定

                    , ov_consolidate_flag           => lv_consolid_flag   -- 混載可否フラグ

                    , ov_errbuf                     => lv_errbuf

                    , ov_retcode                    => lv_retcode

                    , ov_errmsg                     => lv_errmsg

                );

--

debug_log(FND_FILE.LOG,'混載可否判定処理：ルート①');

debug_log(FND_FILE.LOG,'コード区分1：'|| lv_cdkbn_1);

debug_log(FND_FILE.LOG,'入出庫場所1：'|| first_deliver_to);

debug_log(FND_FILE.LOG,'コード区分2：'|| lv_cdkbn_2);

debug_log(FND_FILE.LOG,'入出庫場所2：'|| lt_intensive_tab(ln_loop_cnt).deliver_to);

--

                IF (lv_retcode = gv_status_error) THEN

                  RAISE global_api_expt;

                END IF;

--

                -- 混載可否判定処理①で混載可否フラグが取得できない場合、逆ルートで検索する

                IF (lv_consolid_flag IS NULL) THEN

debug_log(FND_FILE.LOG,'3-4 混載可否判定②');

                  -- ============================

                  -- 混載可否判定処理：ルート②

                  -- ============================

                  get_consolidated_flag(

                        iv_code_class1                => lv_cdkbn_2       -- コード区分２

                      , iv_entering_despatching_code1 => lt_intensive_tab(ln_loop_cnt).deliver_to

                                                                          -- 入出庫場所２

                      , iv_code_class2                => lv_cdkbn_1       -- コード区分１

                      , iv_entering_despatching_code2 => first_deliver_to -- 入出庫場所１

                      , iv_ship_method                => NULL             -- 配送区分判定

                      , ov_consolidate_flag           => lv_consolid_flag -- 混載可否フラグ

                      , ov_errbuf                     => lv_errbuf

                      , ov_retcode                    => lv_retcode

                      , ov_errmsg                     => lv_errmsg

                  );

--

                  IF (lv_retcode = gv_status_error) THEN

                    RAISE global_api_expt;

                  END IF;

--

debug_log(FND_FILE.LOG,'混載可否判定処理：ルート②');

debug_log(FND_FILE.LOG,'コード区分1：'|| lv_cdkbn_2);

debug_log(FND_FILE.LOG,'入出庫場所1：'|| lt_intensive_tab(ln_loop_cnt).deliver_to);

debug_log(FND_FILE.LOG,'コード区分2：'|| lv_cdkbn_1);

debug_log(FND_FILE.LOG,'入出庫場所2：'|| first_deliver_to);

--

                END IF;

-- 2008/10/01 H.Itou Add Start PT 6-1_27 指摘18

              END IF;

-- 2008/10/01 H.Itou Add End

--

debug_log(FND_FILE.LOG,'混載許可フラグ：'|| lv_consolid_flag);

--

              -- 混載許可フラグ（ルート）：許可

              IF (lv_consolid_flag = cn_consolid_parmit) THEN

debug_log(FND_FILE.LOG,'3-5 混載許可');

--

                -- 最大配送区分が同一の場合

                IF (lt_ship_method_cls = lt_intensive_tab(ln_loop_cnt).max_shipping_method_code) THEN

debug_log(FND_FILE.LOG,'3-5-1 最大配送区分が同一');

--

                  -- 混載を許可

                  lv_consolid_flag_ships := cn_consolid_parmit;

--

                ELSE

--

debug_log(FND_FILE.LOG,'3-5-2 最大配送区分が同一ではない');

                  -- ============================

                  -- 混載可否判定処理：配送区分

                  -- ===========================

--

debug_log(FND_FILE.LOG,'3-5-2-1混載可否判定処理：配送区分');

--

                  -- コード区分１、２の設定

                  IF (lt_intensive_tab(ln_loop_cnt).transaction_type = gv_ship_type_ship) THEN -- 出荷依頼

                    lv_cdkbn_2  :=  gv_cdkbn_ship_to; -- 配送先

                  ELSE

                    lv_cdkbn_2  :=  gv_cdkbn_storage; -- 倉庫

                  END IF;

--

                  -- ※次レコードの配送区分に基準明細の配送区分が含まれているかチェック

debug_log(FND_FILE.LOG,'3-5-2-2※次レコードの配送区分に基準明細の配送区分が含まれているかチェック');

debug_log(FND_FILE.LOG,'cdkbn_1(from)= '||gv_cdkbn_storage);

debug_log(FND_FILE.LOG,'despatching_code1(from)= '||first_deliver_from);

debug_log(FND_FILE.LOG,'cdkbn_2(to)= '||lv_cdkbn_2);

debug_log(FND_FILE.LOG,'despatching_code2(to)= '||lt_intensive_tab(ln_loop_cnt).deliver_to);

debug_log(FND_FILE.LOG,'lt_ship_method_cls= '||lt_ship_method_cls);

                  get_consolidated_flag(

                        iv_code_class1                => gv_cdkbn_storage      -- コード区分１

--20080714 mod                      , iv_entering_despatching_code1 => first_deliver_to   -- 入出庫場所１

                      , iv_entering_despatching_code1 => first_deliver_from               -- 入出庫場所１

                      , iv_code_class2                => lv_cdkbn_2         -- コード区分２

                      , iv_entering_despatching_code2 => lt_intensive_tab(ln_loop_cnt).deliver_to

                                                                            -- 入出庫場所２

                      , iv_ship_method                => lt_ship_method_cls -- 配送区分

                      , ov_consolidate_flag           => lv_consolid_flag_ships

                                                                            -- 混載可否フラグ:配送区分

                      , ov_errbuf                     => lv_errbuf

                      , ov_retcode                    => lv_retcode

                      , ov_errmsg                     => lv_errmsg

                  );

                  IF (lv_retcode = gv_status_error) THEN

                    gv_err_key  :=  lv_cdkbn_1

                                    || gv_msg_comma ||

                                    first_deliver_to

                                    || gv_msg_comma ||

                                    lv_cdkbn_2

                                    || gv_msg_comma ||

                                    lt_intensive_tab(ln_loop_cnt).deliver_to

                                    || gv_msg_comma ||

                                    lt_ship_method_cls

                                    ;

                    -- エラーメッセージ取得

                    lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(

                                    gv_xxwsh            -- モジュール名略称：XXWSH 出荷・引当/配車

                                  , gv_msg_xxwsh_11810  -- メッセージ：APP-XXWSH-11810 共通関数エラー

                                  , gv_fnc_name         -- トークン：FNC_NAME

                                  , 'get_consolidated_flag' -- 関数名

                                  , gv_tkn_key              -- トークン：KEY

                                  , gv_err_key              -- 関数実行キー

                                 ),1,5000);

                    RAISE global_api_expt;

                  END IF;

--

                END IF;

--

--

debug_log(FND_FILE.LOG,'3-5-3混載許可フラグ（配送区分）:'|| lv_consolid_flag_ships);

                -- 混載許可フラグ（配送区分）：許可

                IF (lv_consolid_flag_ships = cn_consolid_parmit) THEN

debug_log(FND_FILE.LOG,'3-6集約合計重量／容積加算');

--

                  -- ============================

                  -- B-11.集約合計重量／容積加算

                  -- ============================

                  -- 混載合計重量

                  IF (lt_intensive_tab(ln_loop_cnt).weight_capacity_class = gv_weight) THEN

debug_log(FND_FILE.LOG,'3-6-1混載合計重量');

debug_log(FND_FILE.LOG,'基準レコードの最大積載重量：'||first_max_weight);

--

                    -- 基準レコードの最大積載重量と比較

                    IF (first_max_weight <

                          ln_intensive_weight + lt_intensive_tab(ln_loop_cnt).intensive_sum_weight)

                    THEN

debug_log(FND_FILE.LOG,'3-6-1-1混載合計重量オーバー');

                      -- 混載済フラグ設定

                      lv_mixed_flag  := NULL;

                    ELSE  -- 混載可能

debug_log(FND_FILE.LOG,'3-6-1-2混載合計重量加算');

debug_log(FND_FILE.LOG,'3-6-1-2ln_loop_cnt:'||ln_loop_cnt);

                      -- 混載相手のカウンタ保持

                      ln_child_no := ln_loop_cnt;

--

                      -- 混載カウンタ

                      ln_intensive_no_cnt := ln_intensive_no_cnt + 1;

debug_log(FND_FILE.LOG,'3-6-1-2-1 ln_intensive_no_cnt:'||ln_intensive_no_cnt);

                      -- 集約合計重量(混載相手)

                      lt_mix_total_weight(ln_intensive_no_cnt)

                          := lt_intensive_tab(ln_child_no).intensive_sum_weight;

--

                      -- 集約合計容積(混載相手)

                      lt_mix_total_capacity(ln_intensive_no_cnt) := NULL;

--

                      -- 混載合計重量(基準レコード集約合計重量+混載相手の集約合計重量)

                      ln_intensive_weight

                          := ln_intensive_weight + lt_intensive_tab(ln_child_no).intensive_sum_weight;

--

                      -- 混載済フラグ設定

                      lv_mixed_flag  := gv_mixed_class_mixed; -- 混載

                    END IF;

--

debug_log(FND_FILE.LOG,'GRP集約合計重量:'|| ln_intensive_weight);

--

                  -- 混載合計容積

                  ELSE

--

debug_log(FND_FILE.LOG,'3-6-2混載合計容積');

debug_log(FND_FILE.LOG,'基準レコードの最大積載容積：'||first_max_capacity);

debug_log(FND_FILE.LOG,'3-6-2-1 first_max_capacity:'|| first_max_capacity);

debug_log(FND_FILE.LOG,'3-6-2-1 ln_intensive_capacity:'|| ln_intensive_capacity);

debug_log(FND_FILE.LOG,'3-6-2-1 lt_intensive_tab(ln_loop_cnt).intensive_sum_capacity:'|| lt_intensive_tab(ln_loop_cnt).intensive_sum_capacity);

                    -- 基準レコードの最大積載容積と比較

                    IF (first_max_capacity <

                        ln_intensive_capacity + lt_intensive_tab(ln_loop_cnt).intensive_sum_capacity)

                    THEN

--

debug_log(FND_FILE.LOG,'3-6-2-1 混載合計容積オーバー');

                      -- 混載済フラグ設定

                      lv_mixed_flag  := NULL;

--

                    ELSE  -- 混載可能

debug_log(FND_FILE.LOG,'3-6-2-2 混載合計容積加算');

debug_log(FND_FILE.LOG,'3-6-2-2 ln_loop_cnt：'|| ln_loop_cnt);

                      -- 混載相手のカウンタ保持

                      ln_child_no := ln_loop_cnt;

--

                      -- 混載カウンタ

                      ln_intensive_no_cnt := ln_intensive_no_cnt + 1;

                      -- 集約合計重量(混載相手)

                      lt_mix_total_weight(ln_intensive_no_cnt) := NULL;

--

                      -- 集約合計容積(混載相手)

                      lt_mix_total_capacity(ln_intensive_no_cnt)

                          := lt_intensive_tab(ln_child_no).intensive_sum_capacity;

                      -- 混載合計容積(基準レコード集約合計容積+混載相手の集約合計容積)

                      ln_intensive_capacity

                          := ln_intensive_capacity + lt_intensive_tab(ln_child_no).intensive_sum_capacity;

--

                      -- 混載済フラグ設定

                      lv_mixed_flag  := gv_mixed_class_mixed; -- 混載

--

                    END IF;

--

                  END IF;

--

                  --======================

                  -- 混載した場合

                  --======================

                  IF (lv_mixed_flag = gv_mixed_class_mixed) THEN

--

debug_log(FND_FILE.LOG,'3-7混載済');

--

                    -- 基準レコードの混載種別格納

                    lt_mixed_class_tab(ln_parent_no)  := gv_mixed_class_mixed;  -- 混載

--

debug_log(FND_FILE.LOG,'3-7-1基準レコードの混載種別：'||lt_mixed_class_tab(ln_parent_no));

--

                    -- 基準レコードの処理済フラグ設定

                    lt_intensive_tab(ln_parent_no).finish_sum_flag

                                                                := cv_finish_intensive;   --  処理済

--

debug_log(FND_FILE.LOG,'3-7-2基準レコードの処理済フラグ：'||lt_intensive_tab(ln_parent_no).finish_sum_flag);

--

                    -- 混載相手の混載種別格納

                    lt_mixed_class_tab(ln_child_no)  := gv_mixed_class_mixed;  -- 混載

debug_log(FND_FILE.LOG,'3-7-3混載相手の混載種別：'||lt_mixed_class_tab(ln_child_no));

debug_log(FND_FILE.LOG,'ln_child_no：'||ln_child_no);

--

                    -- 混載相手の処理済フラグ設定

                    lt_intensive_tab(ln_child_no).finish_sum_flag

                                                                := cv_finish_intensive;   --  処理済

--

debug_log(FND_FILE.LOG,'3-7-4混載相手の処理済フラグ：'||lt_intensive_tab(ln_child_no).finish_sum_flag);

--********************************************************************************************

                    -- 混載相手のレコードをセットする

--

debug_log(FND_FILE.LOG,'3-7-5混載カウンタ:'|| ln_intensive_no_cnt);

                    -- 集約No用PLSQL表に混載相手を格納

                    lt_intensive_no_tab(ln_intensive_no_cnt)

                          := lt_intensive_tab(ln_child_no).intensive_no;

--

--                    -- 混載済データカウンタ格納

--                    lt_mixed_cnt_tab(ln_intensive_no_cnt) := ln_loop_cnt;

--

debug_log(FND_FILE.LOG,'3-7-6集約済フラグ設定：'||lt_intensive_tab(ln_child_no).finish_sum_flag);

--

                  END IF;

--

                END IF;

--

              END IF;

--

            END IF;

--

          -- =========================

          -- キーブレイク時

          -- =========================

          ELSE

--

debug_log(FND_FILE.LOG,'4キーブレイク');

--

              -- コード区分２設定

              IF (lt_intensive_tab(ln_loop_cnt).transaction_type = gv_ship_type_ship) THEN -- 出荷依頼

                lv_cdkbn_2  :=  gv_cdkbn_ship_to; -- 配送先

              ELSE

                lv_cdkbn_2  :=  gv_cdkbn_storage; -- 倉庫

              END IF;

--

            -- キーブレイク時処理

            lproc_keybrake_process(

                  ov_errbuf     => lv_errbuf

                , ov_retcode    => lv_retcode

                , ov_errmsg     => lv_errmsg

            );

            IF (lv_retcode = gv_status_error) THEN

              RAISE global_api_expt;

            END IF;

--

            -- ループカウンタ初期化

            ln_loop_cnt := 0;

---------------------

          END IF;

--

debug_log(FND_FILE.LOG,'ln_loop_cnt：'|| ln_loop_cnt);

debug_log(FND_FILE.LOG,'lt_intensive_tab.COUNT:'|| lt_intensive_tab.COUNT);

--

          -- =================================

          -- 混載済、集約済の場合

          -- =================================

          IF (lv_mixed_flag IS NOT NULL) THEN

debug_log(FND_FILE.LOG,'6混載済、集約済:PLSQLにセット');

            set_ins_data(

                  ov_errbuf     => lv_errbuf

                , ov_retcode    => lv_retcode

                , ov_errmsg     => lv_errmsg

            );

            IF (lv_retcode = gv_status_error) THEN

              RAISE global_api_expt;

            END IF;

--

debug_log(FND_FILE.LOG,'ln_tab_ins_idx:'||ln_tab_ins_idx);

--debug_log(FND_FILE.LOG,'gt_fixed_ship_code_tab:'||gt_fixed_ship_code_tab(ln_tab_ins_idx));

--

debug_log(FND_FILE.LOG,'6-1再実行フラグON or NULL');

            -- ループカウントリセット

            ln_loop_cnt := 0;

debug_log(FND_FILE.LOG,'6-1-1ループカウントリセット:'||ln_loop_cnt);

            -- グループカウンタリセット(最初の読込レコードを基準レコードにする)

            ln_grp_sum_cnt := 0;

debug_log(FND_FILE.LOG,'6-1-2 グループカウントリセット:'||ln_grp_sum_cnt);

            -- 混載済フラグリセット

            lv_mixed_flag := NULL;

          END IF;

        END IF;

--

        -- =======================

        -- 最終データ確定処理

        -- =======================

        IF (ln_loop_cnt = lt_intensive_tab.COUNT) THEN

debug_log(FND_FILE.LOG,'8最終データ確定処理');

--

          -- キーブレイク時処理

          lproc_keybrake_process(

                ov_errbuf     => lv_errbuf

              , ov_retcode    => lv_retcode

              , ov_errmsg     => lv_errmsg

          );

          IF (lv_retcode = gv_status_error) THEN

            RAISE global_api_expt;

          END IF;

--

          -- ループカウントリセット

          ln_loop_cnt := 0;

--

          IF (lv_mixed_flag IS NOT NULL) THEN

            -- 混載テーブル登録用データ設定処理

            set_ins_data(

                  ov_errbuf     => lv_errbuf

                , ov_retcode    => lv_retcode

                , ov_errmsg     => lv_errmsg

            );

            IF (lv_retcode = gv_status_error) THEN

              RAISE global_api_expt;

            END IF;

--

debug_log(FND_FILE.LOG,'ln_tab_ins_idx:'||ln_tab_ins_idx);

--debug_log(FND_FILE.LOG,'gt_fixed_ship_code_tab:'||gt_fixed_ship_code_tab(ln_tab_ins_idx));

--

            -- ループカウントリセット

            ln_loop_cnt := 0;

debug_log(FND_FILE.LOG,'6-1-1ループカウントリセット:'||ln_loop_cnt);

            -- グループカウンタリセット(最初の読込レコードを基準レコードにする)

            ln_grp_sum_cnt := 0;

debug_log(FND_FILE.LOG,'6-1-2 グループカウントリセット:'||ln_grp_sum_cnt);

            -- 混載済フラグリセット

            lv_mixed_flag := NULL;

          END IF;

--

          -- =======================

          -- 終了判定

          -- =======================

          -- 終了判定カウント初期化

          ln_finish_judge_cnt := 0;

--

debug_log(FND_FILE.LOG,'7終了判定');

debug_log(FND_FILE.LOG,'7-0 lt_intensive_tab.COUNT:'|| lt_intensive_tab.COUNT);

--

          <<finish_judge_loop>>

          FOR judge_rec IN 1..lt_intensive_tab.COUNT LOOP

--

debug_log(FND_FILE.LOG,'7-1-0 finish_sum_flag:'|| lt_intensive_tab(judge_rec).finish_sum_flag);

            IF (lt_intensive_tab(judge_rec).finish_sum_flag IS NULL) THEN

debug_log(FND_FILE.LOG,'7-1-1 終了');

--

              -- 終了判定カウント

              ln_finish_judge_cnt := ln_finish_judge_cnt + 1;

--

            END IF;

--

          END LOOP finish_judge_loop;

--

          -- 終了

          EXIT WHEN ln_finish_judge_cnt = 0;

--

        END IF;

debug_log(FND_FILE.LOG,'・終了判定カウント:'|| ln_finish_judge_cnt);

--

      END LOOP  optimization_loop;

--

    END IF;

--

    -- ==============================

    -- B-13.混載中間テーブル出力処理

    -- ==============================

-- 2008/10/01 H.Itou Del Start PT 6-1_27 指摘18

-- ↓debug

--    debug_log(FND_FILE.LOG,'gt_intensive_no_tab.COUNT:'|| gt_intensive_no_tab.COUNT);

--    debug_log(FND_FILE.LOG,'混載中間テーブル登録用データ');

--  for ln_cnt in 1..gt_intensive_no_tab.COUNT LOOP

--    debug_cnt := debug_cnt + 1;

--    debug_log(FND_FILE.LOG,'----------------------------------');

--    debug_log(FND_FILE.LOG,'■集約No:'||gt_intensive_no_tab(ln_cnt));

--    debug_log(FND_FILE.LOG,'■配送No:'||gt_delivery_no_tab(ln_cnt));

--    debug_log(FND_FILE.LOG,'■基準明細No:'||gt_default_line_number_tab(ln_cnt));

--    debug_log(FND_FILE.LOG,'■修正配送区分: '||gt_fixed_ship_code_tab(ln_cnt));

--    debug_log(FND_FILE.LOG,'■混載種別:'||gt_mixed_class_tab(ln_cnt) );

--    debug_log(FND_FILE.LOG,'■混載合計重量:'||gt_mixed_total_weight_tab(ln_cnt));

--    debug_log(FND_FILE.LOG,'■混載合計容積:'||gt_mixed_total_capacity_tab(ln_cnt));

--    debug_log(FND_FILE.LOG,'■混載元No:'||gt_mixed_no_tab(ln_cnt));

----

--  end loop;

---- ↑debug

-- 2008/10/01 H.Itou Del End

    FORALL ln_cnt IN 1..gt_intensive_no_tab.COUNT

      INSERT INTO xxwsh_mixed_carriers_tmp(

          intensive_no                  -- 集約No

        , delivery_no                   -- 配送No

        , default_line_number           -- 基準明細No

        , fixed_shipping_method_code    -- 修正配送区分

        , mixed_class                   -- 混載種別

        , mixed_total_weight            -- 混載合計重量

        , mixed_total_capacity          -- 混載合計容積

        , mixed_no                      -- 混載元No

      )

       VALUES

      (

          gt_intensive_no_tab(ln_cnt)         -- 集約No

        , gt_delivery_no_tab(ln_cnt)          -- 配送No

        , gt_default_line_number_tab(ln_cnt)  -- 基準明細No

        , gt_fixed_ship_code_tab(ln_cnt)      -- 修正配送区分

        , gt_mixed_class_tab(ln_cnt)          -- 混載種別

        , gt_mixed_total_weight_tab(ln_cnt)   -- 混載合計重量

        , gt_mixed_total_capacity_tab(ln_cnt) -- 混載合計容積

        , gt_mixed_no_tab(ln_cnt)             -- 混載元No

      );

--

-- Ver1.5 M.Hokkanji Start

debug_log(FND_FILE.LOG,'小口配送情報作成処理前にコミット');

    COMMIT;

-- Ver1.5 M.Hokkanji End

debug_log(FND_FILE.LOG,'小口配送情報作成処理');

--

--2008/10/16 H.Itou Del Start T_S_625 小口の配送Noを最後に採番しないために、set_ins_dataへ移動

--    -- ==============================

--    -- 小口配送情報作成処理

--    -- ==============================

--    set_small_sam_class(

--           ov_errbuf  => lv_errbuf    -- エラー・メッセージ           --# 固定 #

--         , ov_retcode => lv_retcode   -- リターン・コード             --# 固定 #

--         , ov_errmsg  => lv_errmsg    -- ユーザー・エラー・メッセージ --# 固定 #

--        );

--    -- 処理がエラーの場合

--    IF (lv_retcode = gv_status_error) THEN

--      RAISE global_api_expt;

--    END IF;

--2008/10/16 H.Itou Del End

--

-- Ver1.5 M.Hokkanji Start

-- 配送No設定以降はロールバックするためエラーを特定できるようここでコミット

debug_log(FND_FILE.LOG,'配送No設定で既存配車を削除しているためここでコミット処理');

    COMMIT;

-- Ver1.5 M.Hokkanji End

debug_log(FND_FILE.LOG,'配送No設定(振り直し)');

    -- ==================================

    --  配送No設定(振り直し)

    -- ==================================

    set_delivery_no(

           ov_errbuf  => lv_errbuf    -- エラー・メッセージ           --# 固定 #

         , ov_retcode => lv_retcode   -- リターン・コード             --# 固定 #

         , ov_errmsg  => lv_errmsg    -- ユーザー・エラー・メッセージ --# 固定 #

        );

    -- 処理がエラーの場合

    IF (lv_retcode = gv_status_error) THEN

      RAISE global_api_expt;

    END IF;

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

  END get_intensive_tmp;

--

  /**********************************************************************************

   * Procedure Name   : ins_xxwsh_carriers_schedule

   * Description      : 配車配送計画アドオン出力(B-14)

   ***********************************************************************************/

  PROCEDURE ins_xxwsh_carriers_schedule(

    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #

    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #

    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #

  IS

    -- ===============================

    -- 固定ローカル定数

    -- ===============================

    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_xxwsh_carriers_schedule'; -- プログラム名

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

    cv_object                   CONSTANT VARCHAR2(2) := '1';  -- 対象区分：対象

    cn_sts_error                CONSTANT NUMBER := 1;         -- 共通関数エラー

-- Ver1.5 M.Hokkanji Start

    cv_non_slip_class           CONSTANT VARCHAR2(2) := '1';  -- 伝票無し配車区分

-- Ver1.5 M.Hokkanji End

--

-- 20080603 K.Yamane 不具合No4->

    -- *** ローカル変数 ***

    TYPE lb_over_loading_ttype IS TABLE OF BOOLEAN INDEX BY BINARY_INTEGER;

-- 20080603 K.Yamane 不具合No4<-

--

    -- 配車配送計画アドオン登録用PL/SQL表

    lt_tran_type_tab            transaction_type_ttype;       -- 処理種別

    lt_mixed_cls_tab            mixed_class_ttype;            -- 混載種別

    lt_delivery_no_tab          delivery_no_ttype;            -- 配送No

    lt_default_line_number_tab  default_line_number_ttype;    -- 基準明細

    lt_carrier_id_tab           carrier_id_ttype;             -- 運送業者ID

    lt_carry_cd_tab             freight_carry_cd_ttype;       -- 運送業者コード

    lt_deliver_from_id_tab      deliver_from_id_ttype;        -- 配送元ID

    lt_deliver_from_tab         deliver_from_ttype;           -- 配送元コード

    lt_deliver_to_id_tab        deliver_to_id_ttype;          -- 配送先ID

    lt_deliver_to_tab           deliver_to_ttype;             -- 配送先コード

    lt_delivery_to_cd_cls_tab   delivery_to_cd_cls_ttype;     -- 配送先コード区分

    lt_fixed_ship_code_tab      fixed_ship_code_ttype;        -- 修正配送区分

    lt_tran_type_name_tab       tran_type_name_ttype;         -- 出庫形態

    lt_sche_ship_date_tab       sche_ship_date_ttype;         -- 出庫予定日

    lt_sche_arvl_date_tab       sche_arvl_date_ttype;         -- 着荷予定日

    lt_mixed_total_weight_tab   mixed_total_weight_ttype;     -- 混載合計重量

    lt_mixed_total_capacity_tab mixed_total_capacity_ttype;   -- 混載合計容積

    lt_loading_weight_tab       loading_weight_ttype;         -- 重量積載効率

    lt_loading_capacity_tab     loading_capacity_ttype;       -- 容積積載効率

    lt_based_weight_tab         based_weight_ttype;           -- 基本重量

    lt_based_capacity_tab       based_capacity_ttype;         -- 基本容積

    lt_weight_capa_cls_tab      weight_capa_cls_ttype;        -- 重量容積区分

    lt_freight_charge_type_tab  freight_charge_type_ttype;    -- 運賃形態

--

-- 20080603 K.Yamane 不具合No4->

    lt_tran_type_tab2            transaction_type_ttype;       -- 処理種別

    lt_mixed_cls_tab2            mixed_class_ttype;            -- 混載種別

    lt_delivery_no_tab2          delivery_no_ttype;            -- 配送No

    lt_default_line_number_tab2  default_line_number_ttype;    -- 基準明細

    lt_carrier_id_tab2           carrier_id_ttype;             -- 運送業者ID

    lt_carry_cd_tab2             freight_carry_cd_ttype;       -- 運送業者コード

    lt_deliver_from_id_tab2      deliver_from_id_ttype;        -- 配送元ID

    lt_deliver_from_tab2         deliver_from_ttype;           -- 配送元コード

    lt_deliver_to_id_tab2        deliver_to_id_ttype;          -- 配送先ID

    lt_deliver_to_tab2           deliver_to_ttype;             -- 配送先コード

    lt_delivery_to_cd_cls_tab2   delivery_to_cd_cls_ttype;     -- 配送先コード区分

    lt_fixed_ship_code_tab2      fixed_ship_code_ttype;        -- 修正配送区分

    lt_tran_type_name_tab2       tran_type_name_ttype;         -- 出庫形態

    lt_sche_ship_date_tab2       sche_ship_date_ttype;         -- 出庫予定日

    lt_sche_arvl_date_tab2       sche_arvl_date_ttype;         -- 着荷予定日

    lt_mixed_total_weight_tab2   mixed_total_weight_ttype;     -- 混載合計重量

    lt_mixed_total_capacity_tab2 mixed_total_capacity_ttype;   -- 混載合計容積

    lt_loading_weight_tab2       loading_weight_ttype;         -- 重量積載効率

    lt_loading_capacity_tab2     loading_capacity_ttype;       -- 容積積載効率

    lt_based_weight_tab2         based_weight_ttype;           -- 基本重量

    lt_based_capacity_tab2       based_capacity_ttype;         -- 基本容積

    lt_weight_capa_cls_tab2      weight_capa_cls_ttype;        -- 重量容積区分

    lt_freight_charge_type_tab2  freight_charge_type_ttype;    -- 運賃形態

--

    lt_over_loading_tab         lb_over_loading_ttype;

-- 20080603 K.Yamane 不具合No4<-

--

    ln_cnt                      NUMBER DEFAULT 0;             -- ループカウンタ

--

    lv_cdkbn_1                  xxcmn_delivery_lt2_v.code_class1%TYPE;

                                                              -- コード区分１

    lv_cdkbn_2                  xxcmn_delivery_lt2_v.code_class2%TYPE;

                                                              -- コード区分２

    lt_tran_type                xxwsh_intensive_carriers_tmp.transaction_type%TYPE;

                                                              -- 処理種別(基準明細用)

    ln_retnum                   NUMBER;                       -- 共通関数戻り値

    lv_warning_msg              VARCHAR2(255);                -- 警告メッセージ

    ln_drink_deadweight         xxcmn_ship_methods.drink_deadweight%TYPE;

                                                              -- ドリンク積載重量

    ln_leaf_deadweight          xxcmn_ship_methods.leaf_deadweight%TYPE;

                                                              -- リーフ積載重量

    ln_drink_loading_capacity   xxcmn_ship_methods.drink_loading_capacity%TYPE;

                                                              -- ドリンク積載容積

    ln_leaf_loading_capacity    xxcmn_ship_methods.leaf_loading_capacity%TYPE;

                                                              -- リーフ積載容積

    ln_palette_max_qty          xxcmn_ship_methods.palette_max_qty%TYPE;

                                                              -- パレット最大枚数

    lv_transfer_standard_drink  xxcmn_cust_accounts2_v.drink_transfer_std%TYPE;

                                                              -- ドリンク運賃振替基準

    lv_transfer_standard_leaf   xxcmn_cust_accounts2_v.leaf_transfer_std%TYPE;

                                                              -- リーフ運賃振替基準

    lv_party_number             xxcmn_cust_accounts2_v.party_number%TYPE;

                                                              -- 組織番号

    lv_delivery_no              xxwsh_mixed_carriers_tmp.delivery_no%TYPE;

                                                              -- 配送No

    lv_default_line_number      xxwsh_mixed_carriers_tmp.default_line_number%TYPE;

                                                              -- 基準明細No

--

    lv_class_code               xxcmn_cust_accounts_v.customer_class_code%TYPE;

--

    -- 共通関数戻り値用

    lv_loading_over_class       VARCHAR2(2);                          -- 積載オーバー区分

    lv_ship_methods             xxcmn_ship_methods.ship_method%TYPE;  -- 出荷方法

    ln_load_efficiency_weight   NUMBER;                               -- 重量積載効率

    ln_load_efficiency_capacity NUMBER;                               -- 容積積載効率

    lv_mixed_ship_method        VARCHAR2(2);                          -- 混載配送区分

--

    -- WHOカラム

    lt_user_id          xxcmn_txn_lot_cost.created_by%TYPE;             -- 作成者、最終更新者

    lt_login_id         xxcmn_txn_lot_cost.last_update_login%TYPE;      -- 最終更新ログイン

    lt_conc_request_id  xxcmn_txn_lot_cost.request_id%TYPE;             -- 要求ID

    lt_prog_appl_id     xxcmn_txn_lot_cost.program_application_id%TYPE; -- アプリケーションID

    lt_conc_program_id  xxcmn_txn_lot_cost.program_id%TYPE;             -- プログラムID

--

    -- *** ローカル・カーソル ***

--

    CURSOR get_put_data_cur IS

      SELECT  mixed.transaction_type            tran_type             -- 処理種別

           ,  mixed.mixed_class                 mixed_class           -- 混載種別

           ,  mixed.delivery_no                 delivery_no           -- 配送No

           ,  mixed.default_line_number         default_line_number   -- 基準明細No

           ,  mixed.carrier_id                  carrier_id            -- 運送業者ID

           ,  mixed.freight_carrier_code        freight_carrier_code  -- 運送業者

           ,  mixed.deliver_from                deliver_from          -- 配送元

           ,  mixed.deliver_to                  deliver_to            -- 配送先

-- 20080603 K.Yamane 不具合No12->

           ,  mixed.deliver_to_id               deliver_to_id         -- 配送先ID

-- 20080603 K.Yamane 不具合No12<-

           ,  mixed.fixed_shipping_method_code  fix_ship_method_cls   -- 修正配送区分

--2008.06.26 D.Sugahara ST#297対応->                               

           ,  mixed.std_ship_method             std_ship_method       -- 通常配送区分           

--2008.06.26 D.Sugahara ST#297対応<-                               

           ,  mixed.schedule_ship_date          ship_date             -- 出庫日

           ,  mixed.schedule_arrival_date       arrival_date          -- 着荷日

           ,  mixed.transaction_type_name       tran_type_name        -- 出庫形態

           ,  SUM(mixed.mixed_total_weight)     mix_total_weight      -- 混載合計重量

           ,  SUM(mixed.mixed_total_capacity)   mix_total_capacity    -- 混載合計容積

           ,  mixed.weight_capacity_class       m_c_class             -- 重量容積区分

-- Ver1.5 M.Hokkanji Start

--           ,  mixed.max_weight                  max_weight            -- 最大積載重量

--           ,  mixed.max_capacity                max_capacity          -- 最大積載容積

-- Ver1.5 M.Hokkanji End

-- Ver1.20 M.Hokkanji Start

--        FROM (SELECT  DISTINCT xict.transaction_type  -- 処理種別

        FROM (SELECT /*+ leading(xcst xmct xict xmcv) hash(xcst xmct xict xmcv) */

             DISTINCT xict.transaction_type  -- 処理種別

-- Ver1.20 M.Hokkanji End

                    , xmct.mixed_class                -- 混載種別

                    , xmct.delivery_no                -- 配送No

                    , xmct.default_line_number        -- 基準明細No

                    , xict.carrier_id                 -- 運送業者ID

                    , xict.freight_carrier_code       -- 運送業者

--2008.05.26 D.Sugahara 不具合No9対応->

--                    , xict.deliver_from               -- 配送元

--                    , xict.deliver_to                 -- 配送先

                    , xcst.deliver_from               -- 配送元

                    , xcst.deliver_to                 -- 配送先

--2008.05.26 D.Sugahara 不具合No9対応<-

-- 20080603 K.Yamane 不具合No12->

                    , xcst.deliver_to_id              -- 配送先ID

-- 20080603 K.Yamane 不具合No12<-

                    , xmct.fixed_shipping_method_code -- 修正配送区分

--2008.06.26 D.Sugahara ST#297対応->                    

                    ,nvl(xcmv.ship_method_code,xmct.fixed_shipping_method_code) std_ship_method

--2008.06.26 D.Sugahara ST#297対応<-                    

                    , xict.schedule_ship_date         -- 出庫日

                    , xict.schedule_arrival_date      -- 着荷日

                    , xict.transaction_type_name      -- 出庫形態

                    , xmct.mixed_total_weight         -- 混載合計重量

                    , xmct.mixed_total_capacity       -- 混載合計容積

                    , xict.weight_capacity_class      -- 重量容積区分

-- Ver1.5 M.Hokkanji Start

--                    , xict.max_weight                 -- 最大積載重量

--                    , xict.max_capacity               -- 最大積載容積

-- Ver1.5 M.Hokkanji End

               FROM xxwsh_intensive_carriers_tmp xict       -- 自動配車集約中間テーブル

--2008.05.26 D.Sugahara 不具合No9対応->

                  , xxwsh_mixed_carriers_tmp     xmct       -- 自動配車混載中間テーブル

                  , xxwsh_carriers_sort_tmp      xcst       -- 自動配車ソート用中間テーブル

--2008.06.26 D.Sugahara ST#297対応->

                  ,xxwsh_ship_method_v           xcmv       -- 配送区分ビュー（通常配送区分用）

--2008.06.26 D.Sugahara ST#297対応<-

--              WHERE xmct.default_line_number = xict.intensive_source_no   -- 基準明細

--                AND xmct.intensive_no = xict.intensive_no   -- 集約No

-- Ver1.20 M.Hokkanji Start

                WHERE xcst.request_no   = xmct.default_line_number

                  AND xmct.intensive_no = xict.intensive_no

                  AND xmct.fixed_shipping_method_code = xcmv.mixed_ship_method_code(+)

-- Ver1.20 M.Hokkanji End

--              WHERE xmct.intensive_no = xict.intensive_no   -- 集約No 

--                AND xcst.request_no   = xmct.default_line_number --基準明細条件

--                AND xcmv.mixed_ship_method_code(+) = xmct.fixed_shipping_method_code 

--2008.05.26 D.Sugahara 不具合No9対応<-

            ) mixed

         GROUP BY

              mixed.transaction_type            -- 処理種別

            , mixed.mixed_class                 -- 混載種別

            , mixed.delivery_no                 -- 配送No

            , mixed.default_line_number         -- 基準明細No

            , mixed.carrier_id                  -- 運送業者ID

            , mixed.deliver_from                -- 配送元

            , mixed.deliver_to                  -- 配送先

            , mixed.deliver_to_id               -- 配送先ID

            , mixed.freight_carrier_code        -- 運送業者

            , mixed.fixed_shipping_method_code  -- 修正配送区分

--2008.06.26 D.Sugahara ST#297対応->                                

            , mixed.std_ship_method             -- 通常配送区分

--2008.06.26 D.Sugahara ST#297対応<-            

            , mixed.schedule_ship_date          -- 出庫日

            , mixed.schedule_arrival_date       -- 着荷日

            , mixed.transaction_type_name       -- 出庫形態

            , mixed.weight_capacity_class       -- 重量容積区分

-- Ver1.5 M.Hokkanji Start

--            , mixed.max_weight                  -- 最大積載重量

--            , mixed.max_capacity                -- 最大積載容積

-- Ver1.5 M.Hokkanji End

      ;

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

    -- 登録用PL/SQL表初期化

    lt_tran_type_tab.DELETE;            -- 処理種別

    lt_mixed_cls_tab.DELETE;            -- 混載種別

    lt_delivery_no_tab.DELETE;          -- 配送No

    lt_default_line_number_tab.DELETE;  -- 基準明細

    lt_carrier_id_tab.DELETE;           -- 運送業者ID

    lt_carry_cd_tab.DELETE;             -- 運送業者コード

--    lt_deliver_from_id_tab.DELETE;      -- 配送元ID

--    lt_deliver_from_tab.DELETE;         -- 配送元コード

--    lt_deliver_to_id_tab.DELETE;        -- 配送先ID

--    lt_deliver_to_tab.DELETE;           -- 配送先コード

    lt_delivery_to_cd_cls_tab.DELETE;   -- 配送先コード区分

    lt_tran_type_name_tab.DELETE;       -- 出庫形態

    lt_fixed_ship_code_tab.DELETE;      -- 修正配送区分

    lt_sche_ship_date_tab.DELETE;       -- 出庫予定日

    lt_sche_arvl_date_tab.DELETE;       -- 着荷予定日

    lt_mixed_total_weight_tab.DELETE;   -- 混載合計重量

    lt_mixed_total_capacity_tab.DELETE; -- 混載合計容積

    lt_loading_weight_tab.DELETE;       -- 重量積載効率

    lt_loading_capacity_tab.DELETE;     -- 容積積載効率

    lt_based_weight_tab.DELETE;         -- 基本重量

    lt_based_capacity_tab.DELETE;       -- 基本容積

    lt_weight_capa_cls_tab.DELETE;      -- 重量容積区分

--

    -- ===========================

    -- 登録用データ設定

    -- ===========================

--

debug_log(FND_FILE.LOG,'【配車配送計画アドオン出力】');

--

    <<put_date_loop>>

    FOR cur_rec IN get_put_data_cur LOOP

      -- ループカウンタ

      ln_cnt  := ln_cnt + 1;

--

      lt_tran_type_tab(ln_cnt)            := cur_rec.tran_type;             -- 処理種別

      lt_mixed_cls_tab(ln_cnt)            := cur_rec.mixed_class;           -- 混載種別

      lt_delivery_no_tab(ln_cnt)          := cur_rec.delivery_no;           -- 配送No

      lt_default_line_number_tab(ln_cnt)  := cur_rec.default_line_number;   -- 基準明細No

      lt_carrier_id_tab(ln_cnt)           := cur_rec.carrier_id;            -- 運送業者ID

      lt_carry_cd_tab(ln_cnt)             := cur_rec.freight_carrier_code;  -- 運送業者コード

--      lt_deliver_from_id_tab(ln_cnt)      := cur_rec.deliver_from_id;       -- 配送元ID

--      lt_deliver_from_tab(ln_cnt)         := cur_rec.deliver_from;          -- 配送元コード

--      lt_deliver_to_id_tab(ln_cnt)        := cur_rec.deliver_to_id;         -- 配送先ID

--      lt_deliver_to_tab(ln_cnt)           := cur_rec.deliver_to;            -- 配送先コード

      lt_fixed_ship_code_tab(ln_cnt)      := cur_rec.fix_ship_method_cls;   -- 修正配送区分

      lt_sche_ship_date_tab(ln_cnt)       := cur_rec.ship_date;             -- 出庫予定日

      lt_sche_arvl_date_tab(ln_cnt)       := cur_rec.arrival_date;          -- 着荷予定日

--

-- 20080603 K.Yamane 不具合No4->

      lt_over_loading_tab(ln_cnt)         := TRUE;

-- 20080603 K.Yamane 不具合No4<-

--

debug_log(FND_FILE.LOG,'1基本重量、基本容積を取得');

--

      -- コード区分１、２の設定

      IF (cur_rec.mixed_class = gv_mixed_class_int) THEN      -- 集約

--

debug_log(FND_FILE.LOG,'1-1集約');

--

        IF (cur_rec.tran_type = gv_ship_type_ship) THEN

--

debug_log(FND_FILE.LOG,'1-1-1処理種別：出荷');

--

          lv_cdkbn_2  :=  gv_cdkbn_ship_to; -- 配送先

        ELSIF (cur_rec.tran_type = gv_ship_type_move) THEN

--

debug_log(FND_FILE.LOG,'1-1-2処理種別：移動');

--

          lv_cdkbn_2  :=  gv_cdkbn_storage; -- 倉庫

        END IF;

      ELSIF (cur_rec.mixed_class = gv_mixed_class_mixed) THEN -- 混載

--

debug_log(FND_FILE.LOG,'1-2混載');

--debug_log(FND_FILE.LOG,'依頼No/移動No:'lt_default_line_number_tab(ln_cnt));

--

debug_log(FND_FILE.LOG,'基準明細の処理種別を取得:'||lt_tran_type);

--

debug_log(FND_FILE.LOG,'1-2-1コード区分1,2設定:'||lt_tran_type);

        -- コード区分１、２の設定

        IF (cur_rec.tran_type = gv_ship_type_ship) THEN -- 出荷依頼

--

debug_log(FND_FILE.LOG,'1-2-1-1処理種別：出荷');

--

          lv_cdkbn_2  :=  gv_cdkbn_ship_to; -- 配送先

        ELSE

--

debug_log(FND_FILE.LOG,'1-2-1-2処理種別：移動');

--

          lv_cdkbn_2  :=  gv_cdkbn_storage; -- 倉庫

        END IF;

--

      END IF;

debug_log(FND_FILE.LOG,'2配送先コード区分、出庫形態設定');

      -- 配送先コード区分、出庫形態設定

      IF (cur_rec.mixed_class = gv_mixed_class_int) THEN -- 混載種別：集約

debug_log(FND_FILE.LOG,'2-1混載種別：集約');

--

        -- 配送先コード

        IF (cur_rec.tran_type = gv_ship_type_ship) THEN   -- 処理種別：出荷依頼

--

debug_log(FND_FILE.LOG,'2-1-1処理種別：出荷依頼');

          lt_delivery_to_cd_cls_tab(ln_cnt) := gv_cdkbn_ship_to;  -- 配送先

--

        ELSE

--

debug_log(FND_FILE.LOG,'2-1-2処理種別：移動指示');

          lt_delivery_to_cd_cls_tab(ln_cnt) := gv_cdkbn_storage;  -- 倉庫

--

        END IF;

debug_log(FND_FILE.LOG,'2-1-3出庫形態');

        -- 出庫形態

        lt_tran_type_name_tab(ln_cnt) := cur_rec.tran_type_name;

--

      ELSE  -- 混載種別：混載

--

debug_log(FND_FILE.LOG,'2-2混載種別：混載');

--

        -- 配送先コード

        lt_delivery_to_cd_cls_tab(ln_cnt) := NULL;

--

        -- 出庫形態

        lt_tran_type_name_tab(ln_cnt) := NULL;

--

      END IF;

-- 20080603 K.Yamane 不具合No12->

debug_log(FND_FILE.LOG,'・配送先ID:'|| cur_rec.deliver_to_id);

      -- 配送先コードの取得

      BEGIN

        SELECT xcav.customer_class_code            -- 顧客区分

        INTO   lv_class_code

-- 2009/04/17 H.Itou Mod Start 本番障害#1398

--        FROM   xxcmn_cust_acct_sites_v xcsv        -- 顧客サイト情報ビュー

--              ,xxcmn_cust_accounts_v   xcav        -- 顧客情報ビュー

        FROM   xxcmn_cust_acct_sites2_v xcsv        -- 顧客サイト情報ビュー2

              ,xxcmn_cust_accounts2_v   xcav        -- 顧客情報ビュー2

-- 2009/04/17 H.Itou Mod End

        WHERE xcsv.party_id      = xcav.party_id

-- 2009/04/17 H.Itou Mod Start 本番障害#1398 顧客付け替え時にIDが最新でないので出荷先コードで結合し、顧客マスタを参照

--        AND   xcsv.party_site_id = cur_rec.deliver_to_id;

        AND   xcsv.party_site_number  = cur_rec.deliver_to

        AND   xcsv.start_date_active <= TRUNC(cur_rec.ship_date)

        AND  (xcsv.end_date_active   IS NULL OR

              xcsv.end_date_active   >= TRUNC(cur_rec.ship_date))

        AND   xcsv.party_site_status  = 'A'                       -- サイトステータス：有効

        AND   xcav.start_date_active <= TRUNC(cur_rec.ship_date)

        AND  (xcav.end_date_active   IS NULL OR

              xcav.end_date_active   >= TRUNC(cur_rec.ship_date))

        AND   xcav.party_status       = 'A'

        AND   xcav.account_status     = 'A'

        ;

-- 2009/04/17 H.Itou Mod End

--

      EXCEPTION

        WHEN NO_DATA_FOUND THEN

          lv_class_code := NULL;

--

        WHEN OTHERS THEN

          RAISE global_api_others_expt;

      END;

--

      lt_delivery_to_cd_cls_tab(ln_cnt) := lv_class_code;

-- 20080603 K.Yamane 不具合No12<-

--

debug_log(FND_FILE.LOG,'3基本重量、基本容積を取得');

-- 20080603 K.Yamane 不具合No13->

--      lt_delivery_to_cd_cls_tab(ln_cnt)   := lv_cdkbn_2;    -- 配送先コード区分

-- 20080603 K.Yamane 不具合No13<-

--

debug_log(FND_FILE.LOG,'3-1 基本重量、基本容積を取得');

debug_log(FND_FILE.LOG,'・コード区分１:'|| gv_cdkbn_storage);

debug_log(FND_FILE.LOG,'・入出庫場所コード:'|| cur_rec.deliver_from);

debug_log(FND_FILE.LOG,'・コード区分２:'|| lv_cdkbn_2);

debug_log(FND_FILE.LOG,'・入出庫場所コード２:'|| cur_rec.deliver_to);

debug_log(FND_FILE.LOG,'・基準日:'||to_char(cur_rec.ship_date,'YYYY/MM/DD'));

debug_log(FND_FILE.LOG,'・修正配送区分:'||cur_rec.fix_ship_method_cls);

debug_log(FND_FILE.LOG,'・通常配送区分:'||cur_rec.std_ship_method);

--

      -- 基本重量、基本容積を取得

      ln_retnum :=  xxwsh_common_pkg.get_max_pallet_qty(    -- 共通関数：最大パレット枚数算出関数

                        iv_code_class1

                                => gv_cdkbn_storage             -- コード区分１

                      , iv_entering_despatching_code1

                                => cur_rec.deliver_from         -- 入出庫場所コード１

                      , iv_code_class2

                                => lv_cdkbn_2                   -- コード区分２

                      , iv_entering_despatching_code2

                                => cur_rec.deliver_to           -- 入出庫場所コード２

                      , id_standard_date

                                => cur_rec.ship_date            -- 基準日

                      , iv_ship_methods

--2008.06.26 D.Sugahara ST#297対応->                                          

--                                => cur_rec.fix_ship_method_cls  -- 修正配送区分

                                => cur_rec.std_ship_method      -- 通常配送区分                                

--2008.06.26 D.Sugahara ST#297対応<-                                

                      , on_drink_deadweight

                                => ln_drink_deadweight          -- ドリンク積載重量

                      , on_leaf_deadweight

                                => ln_leaf_deadweight           -- リーフ積載重量

                      , on_drink_loading_capacity

                                => ln_drink_loading_capacity    -- ドリンク積載容積

                      , on_leaf_loading_capacity

                                => ln_leaf_loading_capacity     -- リーフ積載容積

                      , on_palette_max_qty

                                => ln_palette_max_qty           -- パレット最大枚数

                   );

debug_log(FND_FILE.LOG,'3-2 共通関数実施');

debug_log(FND_FILE.LOG,'・リターンコード:'|| ln_retnum);

debug_log(FND_FILE.LOG,'・ドリンク積載重量:'|| ln_drink_deadweight);

debug_log(FND_FILE.LOG,'・リーフ積載重量:'|| ln_leaf_deadweight);

debug_log(FND_FILE.LOG,'・ドリンク積載容積:'|| ln_leaf_loading_capacity);

debug_log(FND_FILE.LOG,'・リーフ積載容積:'|| ln_leaf_loading_capacity);

debug_log(FND_FILE.LOG,'・パレット最大枚数:'|| ln_palette_max_qty);

      -- 共通関数エラーの場合

      IF (ln_retnum = cn_sts_error) THEN

        gv_err_key  :=  gv_cdkbn_storage

                        || gv_msg_comma ||

                        cur_rec.deliver_from

                        || gv_msg_comma ||

                        lv_cdkbn_2

                        || gv_msg_comma ||

                        cur_rec.deliver_to

                        || gv_msg_comma ||

                        TO_CHAR(cur_rec.ship_date, 'YYYY/MM/DD')

                        || gv_msg_comma ||

                        cur_rec.fix_ship_method_cls

                        ;

        -- エラーメッセージ取得

        lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(

                        gv_xxwsh                -- モジュール名略称：XXWSH 出荷・引当/配車

                      , gv_msg_xxwsh_11810      -- メッセージ：APP-XXWSH-11810 共通関数エラー

                      , gv_fnc_name             -- トークン：FNC_NAME

                      , 'xxwsh_common_pkg.get_max_pallet_qty' -- 関数名

                      , gv_tkn_key              -- トークン：KEY

                      , gv_err_key              -- 関数実行キー

                      ),1,5000);

        RAISE global_api_expt;

      END IF;

--

debug_log(FND_FILE.LOG,'ドリンク積載重量:'|| ln_drink_deadweight);

debug_log(FND_FILE.LOG,'リーフ積載重量:'|| ln_leaf_deadweight);

debug_log(FND_FILE.LOG,'ドリンク積載容積:'|| ln_leaf_loading_capacity);

debug_log(FND_FILE.LOG,'リーフ積載容積:'|| ln_leaf_loading_capacity);

debug_log(FND_FILE.LOG,'パレット最大枚数:'|| ln_palette_max_qty);

--

debug_log(FND_FILE.LOG,'3積載効率チェック');

      -- 重量容積区分：重量

      IF (cur_rec.m_c_class = gv_weight) THEN

debug_log(FND_FILE.LOG,'3-1重量容積区分：重量');

        -- 重量

        lt_mixed_total_weight_tab(ln_cnt)   := cur_rec.mix_total_weight;      -- 混載合計重量

        lt_mixed_total_capacity_tab(ln_cnt) := NULL;                          -- 混載合計容積

debug_log(FND_FILE.LOG,'3-1-2混載合計重量設定');

--

        -- 共通関数：積載効率チェック(積載効率算出)

        xxwsh_common910_pkg.calc_load_efficiency(

            in_sum_weight                  => cur_rec.mix_total_weight    --  1.合計重量

          , in_sum_capacity                => NULL                        --  2.合計容積

          , iv_code_class1                 => gv_cdkbn_storage            --  3.コード区分１

          , iv_entering_despatching_code1  => cur_rec.deliver_from        --  4.入出庫場所コード１

          , iv_code_class2                 => lv_cdkbn_2                  --  5.コード区分２

          , iv_entering_despatching_code2  => cur_rec.deliver_to          --  6.入出庫場所コード２

--2008.06.26 D.Sugahara ST#297対応->                                          

--          , iv_ship_method                 => cur_rec.fix_ship_method_cls --  7.出荷方法

          , iv_ship_method                 => cur_rec.std_ship_method      -- 通常配送区分                                

--2008.06.26 D.Sugahara ST#297対応<-                                

          , iv_prod_class                  => gv_prod_class               --  8.商品区分

          , iv_auto_process_type           => NULL                        --  9.自動配車対象区分

          , id_standard_date               => cur_rec.ship_date           -- 10.基準日(適用日基準日)

          , ov_retcode                     => lv_retcode                  -- 11.リターンコード

          , ov_errmsg_code                 => lv_errmsg                   -- 12.エラーメッセージコード

          , ov_errmsg                      => lv_errbuf                   -- 13.エラーメッセージ

          , ov_loading_over_class          => lv_loading_over_class       -- 14.積載オーバー区分

          , ov_ship_methods                => lv_ship_methods             -- 15.出荷方法

          , on_load_efficiency_weight      => ln_load_efficiency_weight   -- 16.重量積載効率

          , on_load_efficiency_capacity    => ln_load_efficiency_capacity -- 17.容積積載効率

          , ov_mixed_ship_method           => lv_mixed_ship_method        -- 18.混載配送区分

        );

        -- 共通関数がエラーの場合

-- Ver1.7 M.Hokkanji START

        IF (lv_retcode <> gv_status_normal) THEN

--        IF (lv_retcode = gv_status_error) THEN

-- Ver1.7 M.Hokkanji END

          gv_err_key  :=  cur_rec.mix_total_weight        --  1.合計重量

                          || gv_msg_comma ||

                          NULL                            --  2.合計容積

                          || gv_msg_comma ||

                          gv_cdkbn_storage                --  3.コード区分１

                          || gv_msg_comma ||

                          cur_rec.deliver_from            --  4.入出庫場所コード１

                          || gv_msg_comma ||

                          lv_cdkbn_2                      --  5.コード区分２

                          || gv_msg_comma ||

                          cur_rec.deliver_to              --  6.入出庫場所コード２

                          || gv_msg_comma ||

                          cur_rec.fix_ship_method_cls     --  7.出荷方法

                          || gv_msg_comma ||

                          gv_prod_class                   --  8.商品区分

                          || gv_msg_comma ||

                          NULL                                      --  9.自動配車対象区分

                          || gv_msg_comma ||

                          TO_CHAR(cur_rec.ship_date, 'YYYY/MM/DD')  -- 10.基準日(適用日基準日)

                          ;

          -- エラーメッセージ取得

          lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(

                          gv_xxwsh            -- モジュール名略称：XXWSH 出荷・引当/配車

                        , gv_msg_xxwsh_11810  -- メッセージ：APP-XXWSH-11810 共通関数エラー

                        , gv_fnc_name         -- トークン：FNC_NAME

                        , 'xxwsh_common910_pkg.calc_load_efficiency' -- 関数名

                        , gv_tkn_key              -- トークン：KEY

                        , gv_err_key              -- 関数実行キー

                        ),1,5000);

          RAISE global_api_expt;

        END IF;

--

debug_log(FND_FILE.LOG,'3-1-3積載効率算出');

        -- 重量積載効率設定

        lt_loading_weight_tab(ln_cnt)       := ln_load_efficiency_weight; -- 重量積載効率

        lt_loading_capacity_tab(ln_cnt)     := NULL;                      -- 容積積載効率

debug_log(FND_FILE.LOG,'3-1-4重量積載効率設定');

--

debug_log(FND_FILE.LOG,'3-1-5基本重量設定');

        -- 基本重量設定

        IF (gv_prod_class = gv_prod_cls_leaf) THEN

debug_log(FND_FILE.LOG,'3-1-5-1リーフ');

          -- 商品区分：リーフ

          lt_based_weight_tab(ln_cnt)       := ln_leaf_deadweight;        -- リーフ積載重量

          lt_based_capacity_tab(ln_cnt)     := NULL;                      -- リーフ積載容積

--

        ELSE

debug_log(FND_FILE.LOG,'3-1-5-2ドリンク');

          -- 商品区分：ドリンク

          lt_based_weight_tab(ln_cnt)       := ln_drink_deadweight;       -- ドリンク積載重量

          lt_based_capacity_tab(ln_cnt)     := NULL;                      -- ドリンク積載容積

--

        END IF;

--

debug_log(FND_FILE.LOG,'3-2重量容積区分：容積');

      -- 重量容積区分：容積

      ELSIF (cur_rec.m_c_class = gv_capacity) THEN

debug_log(FND_FILE.LOG,'3-2-1重量容積区分：容積');

        -- 容積

        lt_mixed_total_weight_tab(ln_cnt)   := NULL;                          -- 混載合計重量

        lt_mixed_total_capacity_tab(ln_cnt) := cur_rec.mix_total_capacity;    -- 混載合計容積

debug_log(FND_FILE.LOG,'3-2-2混載合計容積');

--

        -- 共通関数：積載効率チェック(積載効率算出)

        xxwsh_common910_pkg.calc_load_efficiency(

            in_sum_weight                  => NULL                        --  1.合計重量

          , in_sum_capacity                => cur_rec.mix_total_capacity  --  2.合計容積

          , iv_code_class1                 => gv_cdkbn_storage            --  3.コード区分１

          , iv_entering_despatching_code1  => cur_rec.deliver_from        --  4.入出庫場所コード１

          , iv_code_class2                 => lv_cdkbn_2                  --  5.コード区分２

          , iv_entering_despatching_code2  => cur_rec.deliver_to          --  6.入出庫場所コード２

--2008.06.26 D.Sugahara ST#297対応->                                          

--          , iv_ship_method                 => cur_rec.fix_ship_method_cls --  7.出荷方法

          , iv_ship_method                 => cur_rec.std_ship_method      -- 通常配送区分                                

--2008.06.26 D.Sugahara ST#297対応<-                                

          , iv_prod_class                  => gv_prod_class               --  8.商品区分

          , iv_auto_process_type           => NULL                        --  9.自動配車対象区分

          , id_standard_date               => cur_rec.ship_date           -- 10.基準日(適用日基準日)

          , ov_retcode                     => lv_retcode                  -- 11.リターンコード

          , ov_errmsg_code                 => lv_errmsg                   -- 12.エラーメッセージコード

          , ov_errmsg                      => lv_errbuf                   -- 13.エラーメッセージ

          , ov_loading_over_class          => lv_loading_over_class       -- 14.積載オーバー区分

          , ov_ship_methods                => lv_ship_methods             -- 15.出荷方法

          , on_load_efficiency_weight      => ln_load_efficiency_weight   -- 16.重量積載効率

          , on_load_efficiency_capacity    => ln_load_efficiency_capacity -- 17.容積積載効率

          , ov_mixed_ship_method           => lv_mixed_ship_method        -- 18.混載配送区分

        );

        -- 共通関数がエラーの場合

-- Ver1.7 M.Hokkanji START

        IF (lv_retcode <> gv_status_normal) THEN

--        IF (lv_retcode = gv_status_error) THEN

-- Ver1.7 M.Hokkanji END

          gv_err_key  :=  NULL                        --  1.合計重量

                          || gv_msg_comma ||

                          cur_rec.mix_total_capacity  --  2.合計容積

                          || gv_msg_comma ||

                          gv_cdkbn_storage            --  3.コード区分１

                          || gv_msg_comma ||

                          cur_rec.deliver_from        --  4.入出庫場所コード１

                          || gv_msg_comma ||

                          lv_cdkbn_2                  --  5.コード区分２

                          || gv_msg_comma ||

                          cur_rec.deliver_to          --  6.入出庫場所コード２

                          || gv_msg_comma ||

                          cur_rec.fix_ship_method_cls --  7.出荷方法

                          || gv_msg_comma ||

                          gv_prod_class               --  8.商品区分

                          || gv_msg_comma ||

                          NULL                                      --  9.自動配車対象区分

                          || gv_msg_comma ||

                          TO_CHAR(cur_rec.ship_date, 'YYYY/MM/DD')  -- 10.基準日(適用日基準日)

                          ;

          -- エラーメッセージ取得

          lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(

                          gv_xxwsh            -- モジュール名略称：XXWSH 出荷・引当/配車

                        , gv_msg_xxwsh_11810  -- メッセージ：APP-XXWSH-11810 共通関数エラー

                        , gv_fnc_name         -- トークン：FNC_NAME

                        , 'xxwsh_common910_pkg.calc_load_efficiency' -- 関数名

                        , gv_tkn_key              -- トークン：KEY

                        , gv_err_key              -- 関数実行キー

                        ),1,5000);

--

-- 20080603 K.Yamane 不具合No4->

          -- 積載オーバー対象フラグ設定

          lt_over_loading_tab(ln_cnt) := FALSE;

-- 20080603 K.Yamane 不具合No4<-

        END IF;

--

debug_log(FND_FILE.LOG,'3-2-3容積積載効率');

        -- 容積積載効率設定

        lt_loading_weight_tab(ln_cnt)     := NULL;                        -- 重量積載効率

        lt_loading_capacity_tab(ln_cnt)   := ln_load_efficiency_capacity; -- 容積積載効率

--

debug_log(FND_FILE.LOG,'3-2-4基本重量設定');

        -- 基本重量設定

        IF (gv_prod_class = gv_prod_cls_leaf) THEN

debug_log(FND_FILE.LOG,'3-2-4-1リーフ');

--

          -- 商品区分：リーフ

          lt_based_weight_tab(ln_cnt)     := NULL;                        -- リーフ積載重量

          lt_based_capacity_tab(ln_cnt)   := ln_leaf_loading_capacity;    -- リーフ積載容積

--

        ELSE

debug_log(FND_FILE.LOG,'3-2-4-1ドリンク');

          -- 商品区分：ドリンク

          lt_based_weight_tab(ln_cnt)     := NULL;                        -- ドリンク積載重量

          lt_based_capacity_tab(ln_cnt)   := ln_drink_loading_capacity;   -- ドリンク積載容積

--

        END IF;

--

      END IF;

--

debug_log(FND_FILE.LOG,'3-2-5重量容積区分');

      lt_weight_capa_cls_tab(ln_cnt)      := cur_rec.m_c_class;           -- 重量容積区分

--

debug_log(FND_FILE.LOG,'3-2-6運賃形態');

      --運賃形態の取得

      IF (cur_rec.tran_type = gv_ship_type_ship) THEN

debug_log(FND_FILE.LOG,'3-2-6運賃形態:出荷');

--

        BEGIN

          SELECT xca.drink_transfer_std         --ドリンク運賃振替基準

                ,xca.leaf_transfer_std          --リーフ運賃振替基準

                ,xca.party_number               --組織番号

                ,xmct.delivery_no               --配送No

                ,xmct.default_line_number       --基準明細No

            INTO lv_transfer_standard_drink     -- ドリンク運賃振替基準

                ,lv_transfer_standard_leaf      -- リーフ運賃振替基準

                ,lv_party_number                -- 組織番号

                ,lv_delivery_no                 -- 配送No

                ,lv_default_line_number         -- 基準明細No

            FROM xxcmn_cust_accounts2_v    xca                  -- 顧客情報VIEW2

-- 2009/04/17 H.Itou Add Start 本番障害#1398 顧客付け替え時にIDが最新でないので出荷先コードで結合し、顧客マスタを参照

               , xxcmn_cust_acct_sites2_v  xcsv                 -- 顧客サイト情報VIEW2

-- 2009/04/17 H.Itou Add End

               , xxwsh_mixed_carriers_tmp  xmct                 -- 自動配車混載中間テーブル

               , xxwsh_order_headers_all   xoha                 -- 受注ヘッダアドオン

-- 2009/04/17 H.Itou Mod Start 本番障害#1398 顧客付け替え時にIDが最新でないので出荷先コードで結合し、顧客マスタを参照

--           WHERE xca.party_number = xoha.head_sales_branch

-- 2009/04/20 H.Itou Mod Start 本番障害#1398(再対応) 拠点の情報を取得したいので、拠点コードで結合

--           WHERE xca.party_id           = xcsv.party_id

           WHERE xca.party_number       = xcsv.base_code

-- 2009/04/20 H.Itou Mod End

             AND xcsv.party_site_number = xoha.deliver_to  -- 出荷先コードで顧客サイトを結合

             AND xcsv.party_site_status = 'A'              -- サイトステータス：有効

             AND xcsv.start_date_active <= TRUNC(cur_rec.ship_date)

             AND (xcsv.end_date_active IS NULL OR

                  xcsv.end_date_active >= TRUNC(cur_rec.ship_date))

-- 2009/04/17 H.Itou Mod End

             AND xca.start_date_active <= TRUNC(cur_rec.ship_date)

             AND (xca.end_date_active IS NULL OR

                  xca.end_date_active >= TRUNC(cur_rec.ship_date))

             AND xoha.request_no  = xmct.default_line_number

             AND xmct.delivery_no = cur_rec.delivery_no

             AND xoha.latest_external_flag = 'Y'

             AND xca.party_status   = 'A'

             AND xca.account_status = 'A'

             AND ROWNUM = 1     --混載単位<->集約No単位での重複を排除

           ;

        EXCEPTION

          -- データ取得失敗時

          WHEN OTHERS THEN

debug_log(FND_FILE.LOG,'3-2-6運賃振替基準取得1 エラー：MSG= ['||SQLERRM||']');

debug_log(FND_FILE.LOG,' 配送NO、出荷予定日= ['||cur_rec.delivery_no || ',' || cur_rec.ship_date || ']' );

            --警告ログ出力

            ov_retcode := gv_status_warn;

            lt_freight_charge_type_tab(ln_cnt) := NULL;    --運賃形態にNULL設定

            lv_warning_msg  := SUBSTRB(xxcmn_common_pkg.get_msg(

                          gv_xxwsh                -- モジュール名略称：XXWSH 出荷・引当/配車

                        , gv_msg_xxwsh_11813      -- メッセージ：APP-XXWSH-11813 運賃形態取得エラー

                        , gv_tkn_delivry_no       -- トークン：配送No

                        , lv_delivery_no

                        , gv_tkn_req_no           -- トークン：基準明細No

                        , lv_default_line_number

                        , gv_tkn_branch           -- トークン：組織番号

                        , lv_party_number

                         ),1,255);

            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_warning_msg);

        END;

--

        IF (gv_prod_class = gv_prod_cls_leaf  AND lv_transfer_standard_leaf IS NULL) OR

           (gv_prod_class = gv_prod_cls_drink AND lv_transfer_standard_drink IS NULL) THEN

            --運賃振替基準が取得できなかった場合警告ログ出力

debug_log(FND_FILE.LOG,'3-2-6運賃振替基準取得エラー2（項目NULL) ');

debug_log(FND_FILE.LOG,' 配送NO、出荷予定日:['||cur_rec.delivery_no || ',' || to_char(cur_rec.ship_date,'YYYYMMDD') || ']' );

            ov_retcode := gv_status_warn;

            lt_freight_charge_type_tab(ln_cnt) := NULL;    --運賃形態にNULL設定

            lv_warning_msg  := SUBSTRB(xxcmn_common_pkg.get_msg(

                          gv_xxwsh                -- モジュール名略称：XXWSH 出荷・引当/配車

                        , gv_msg_xxwsh_11813      -- メッセージ：APP-XXWSH-11813 運賃形態取得エラー

                        , gv_tkn_delivry_no       -- トークン：配送No

                        , lv_delivery_no

                        , gv_tkn_req_no           -- トークン：基準明細No

                        , lv_default_line_number

                        , gv_tkn_branch           -- トークン：組織番号

                        , lv_party_number

                         ),1,255);

            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_warning_msg);

--

        ELSE

          --運賃振替基準設定

          IF ( gv_prod_class = gv_prod_cls_leaf ) THEN

            --リーフ

            lt_freight_charge_type_tab(ln_cnt) := lv_transfer_standard_leaf;      -- リーフ運賃振替基準

debug_log(FND_FILE.LOG,'3-2-6 リーフ運賃振替基準設定→ '||lv_transfer_standard_leaf);

          ELSE

            --ドリンク

debug_log(FND_FILE.LOG,'3-2-6 ドリンク運賃振替基準設定→ '||lv_transfer_standard_drink);

            lt_freight_charge_type_tab(ln_cnt) := lv_transfer_standard_drink;     -- ドリンク運賃振替基準

          END IF;

--

        END IF;

      ELSIF (cur_rec.tran_type = gv_ship_type_move) THEN

--

debug_log(FND_FILE.LOG,'3-2-6運賃形態：移動');

        -- 運賃形態：移動の場合は実費振替

        lt_freight_charge_type_tab(ln_cnt) := gv_frt_chrg_type_act; -- 実費振替

      END IF;

--

    END LOOP;

--

debug_log(FND_FILE.LOG,'4配車配送計画アドオン一括登録処理');

    -- =================================

    -- 配車配送計画アドオン一括登録処理

    -- =================================

debug_log(FND_FILE.LOG,'4-1.1WHOカラム取得');

    -- WHOカラム取得

    lt_user_id          := FND_GLOBAL.USER_ID;          -- 作成者、最終更新者

    lt_login_id         := FND_GLOBAL.LOGIN_ID;         -- 最終更新ログイン

    lt_conc_request_id  := FND_GLOBAL.CONC_REQUEST_ID;  -- 要求ID

    lt_prog_appl_id     := FND_GLOBAL.PROG_APPL_ID;     -- アプリケーションID

    lt_conc_program_id  := FND_GLOBAL.CONC_PROGRAM_ID;  -- プログラムID

--

-- 20080603 K.Yamane 不具合No4->

    ln_cnt := 1;

debug_log(FND_FILE.LOG,'4-1.2 入れ替え開始:'||lt_tran_type_tab.COUNT);

    <<set_date_loop>>

    FOR ins_cnt IN 1..lt_tran_type_tab.COUNT LOOP

      IF (lt_over_loading_tab(ins_cnt)) THEN

        lt_tran_type_tab2(ln_cnt)            := lt_tran_type_tab(ins_cnt);

        lt_mixed_cls_tab2(ln_cnt)            := lt_mixed_cls_tab(ins_cnt);

        lt_delivery_no_tab2(ln_cnt)          := lt_delivery_no_tab(ins_cnt);

        lt_default_line_number_tab2(ln_cnt)  := lt_default_line_number_tab(ins_cnt);

        lt_carrier_id_tab2(ln_cnt)           := lt_carrier_id_tab(ins_cnt);

        lt_carry_cd_tab2(ln_cnt)             := lt_carry_cd_tab(ins_cnt);

        lt_delivery_to_cd_cls_tab2(ln_cnt)   := lt_delivery_to_cd_cls_tab(ins_cnt);

        lt_fixed_ship_code_tab2(ln_cnt)      := lt_fixed_ship_code_tab(ins_cnt);

        lt_tran_type_name_tab2(ln_cnt)       := lt_tran_type_name_tab(ins_cnt);

        lt_sche_ship_date_tab2(ln_cnt)       := lt_sche_ship_date_tab(ins_cnt);

        lt_sche_arvl_date_tab2(ln_cnt)       := lt_sche_arvl_date_tab(ins_cnt);

        lt_mixed_total_weight_tab2(ln_cnt)   := lt_mixed_total_weight_tab(ins_cnt);

        lt_mixed_total_capacity_tab2(ln_cnt) := lt_mixed_total_capacity_tab(ins_cnt);

        lt_loading_weight_tab2(ln_cnt)       := lt_loading_weight_tab(ins_cnt);

        lt_loading_capacity_tab2(ln_cnt)     := lt_loading_capacity_tab(ins_cnt);

        lt_based_weight_tab2(ln_cnt)         := lt_based_weight_tab(ins_cnt);

        lt_based_capacity_tab2(ln_cnt)       := lt_based_capacity_tab(ins_cnt);

        lt_weight_capa_cls_tab2(ln_cnt)      := lt_weight_capa_cls_tab(ins_cnt);

        lt_freight_charge_type_tab2(ln_cnt)  := lt_freight_charge_type_tab(ins_cnt);

        ln_cnt := ln_cnt + 1;

      END IF;

    END LOOP;

debug_log(FND_FILE.LOG,'4-1.2 入れ替え終了');

-- 20080603 K.Yamane 不具合No4<-

--

debug_log(FND_FILE.LOG,'4-2一括登録処理：件数＝'||lt_tran_type_tab2.COUNT);

debug_log(FND_FILE.LOG,'4-2一括登録処理');

    FORALL ins_cnt IN 1..lt_tran_type_tab2.COUNT

      INSERT INTO xxwsh_carriers_schedule( -- 配車配送計画（アドオン）

          transaction_id                -- トランザクションID

        , transaction_type              -- 処理種別（配車）

        , mixed_type                    -- 混載種別

        , delivery_no                   -- 配送No

        , default_line_number           -- 基準明細No

        , carrier_id                    -- 運送業者ID

        , carrier_code                  -- 運送業者

        , deliver_from_id               -- 配送元ID

        , deliver_from                  -- 配送元

        , deliver_to_id                 -- 配送先ID

        , deliver_to                    -- 配送先

        , deliver_to_code_class         -- 配送先コード区分

        , delivery_type                 -- 配送区分

        , order_type_id                 -- 出庫形態

        , auto_process_type             -- 自動配車対象区分

        , schedule_ship_date            -- 出庫予定日

        , schedule_arrival_date         -- 着荷予定日

        , description                   -- 摘要

        , payment_freight_flag          -- 支払運賃計算対象フラグ

        , demand_freight_flag           -- 請求運賃計算対象フラグ

        , sum_loading_weight            -- 積載重量合計

        , sum_loading_capacity          -- 積載容積合計

        , loading_efficiency_weight     -- 重量積載効率

        , loading_efficiency_capacity   -- 容積積載効率

        , based_weight                  -- 基本重量

        , based_capacity                -- 基本容積

        , result_freight_carrier_id     -- 運送業者_実績ID

        , result_freight_carrier_code   -- 運送業者_実績

        , result_shipping_method_code   -- 配送区分_実績

        , shipped_date                  -- 出荷日

        , arrival_date                  -- 着荷日

        , weight_capacity_class         -- 重量容積区分

        , freight_charge_type           -- 運賃形態

-- Ver1.5 M.Hokkanji Start

        , non_slip_class                -- 伝票なし配車区分

        , prod_class                    -- 商品区分

-- Ver1.5 M.Hokkanji End

        , created_by                    -- 作成者

        , creation_date                 -- 作成日

        , last_updated_by               -- 最終更新者

        , last_update_date              -- 最終更新日

        , last_update_login             -- 最終更新ログイン

        , request_id                    -- 要求ID

        , program_application_id        -- コンカレント・プログラム・アプリケーションID

        , program_id                    -- コンカレント・プログラムID

        , program_update_date           -- プログラム更新日

      )

      VALUES

      (

          xxwsh_careers_schedule_s1.NEXTVAL     -- トランザクションID

        , lt_tran_type_tab2(ins_cnt)            -- 処理種別（配車）

        , lt_mixed_cls_tab2(ins_cnt)            -- 混載種別

        , lt_delivery_no_tab2(ins_cnt)          -- 配送No

        , lt_default_line_number_tab2(ins_cnt)  -- 基準明細No

        , lt_carrier_id_tab2(ins_cnt)           -- 運送業者ID

        , lt_carry_cd_tab2(ins_cnt)             -- 運送業者

        , NULL                                  -- 配送元ID

        , NULL                                  -- 配送元

        , NULL                                  -- 配送先ID

        , NULL                                  -- 配送先

        , lt_delivery_to_cd_cls_tab2(ins_cnt)   -- 配送先コード区分

        , lt_fixed_ship_code_tab2(ins_cnt)      -- 配送区分

        , lt_tran_type_name_tab2(ins_cnt)       -- 出庫形態

        , cv_object                             -- 自動配車対象区分

        , lt_sche_ship_date_tab2(ins_cnt)       -- 出庫予定日

        , lt_sche_arvl_date_tab2(ins_cnt)       -- 着荷予定日

        , NULL                                  -- 摘要

        , cv_object                             -- 支払運賃計算対象フラグ

        , cv_object                             -- 請求運賃計算対象フラグ

        , lt_mixed_total_weight_tab2(ins_cnt)   -- 積載重量合計

        , lt_mixed_total_capacity_tab2(ins_cnt) -- 積載容積合計

        , lt_loading_weight_tab2(ins_cnt)       -- 重量積載効率

        , lt_loading_capacity_tab2(ins_cnt)     -- 容積積載効率

        , lt_based_weight_tab2(ins_cnt)         -- 基本重量

        , lt_based_capacity_tab2(ins_cnt)       -- 基本容積

        , NULL                                  -- 運送業者_実績ID

        , NULL                                  -- 運送業者_実績

        , NULL                                  -- 配送区分_実績

        , NULL                                  -- 出荷日

        , NULL                                  -- 着荷日

        , lt_weight_capa_cls_tab2(ins_cnt)      -- 重量容積区分

        , lt_freight_charge_type_tab2(ins_cnt)  -- 運賃形態

-- Ver1.5 M.Hokkanji Start

        , cv_non_slip_class                     -- 伝票なし配車区分

        , gv_prod_class                         -- 商品区分

-- Ver1.5 M.Hokkanji End

        , lt_user_id                            -- 作成者

        , SYSDATE                               -- 作成日

        , lt_user_id                            -- 最終更新者

        , SYSDATE                               -- 最終更新日

        , lt_login_id                           -- 最終更新ログイン

        , lt_conc_request_id                    -- 要求ID

        , lt_prog_appl_id                       -- コンカレント・プログラム・アプリケーションID

        , lt_conc_program_id                    -- コンカレント・プログラムID

        , SYSDATE                               -- プログラム更新日

      );

--

    -- 登録件数設定

    gn_target_cnt  := lt_tran_type_tab2.COUNT;

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

  END ins_xxwsh_carriers_schedule;

--

  /**********************************************************************************

   * Procedure Name   : upd_req_inst_info

   * Description      : 依頼・指示情報更新処理(B-15)

   ***********************************************************************************/

  PROCEDURE upd_req_inst_info(

    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #

    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #

    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #

  IS

    -- ===============================

    -- 固定ローカル定数

    -- ===============================

    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_req_inst_info'; -- プログラム名

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

    cv_yes        CONSTANT VARCHAR2(1) := 'Y';         -- YES

-- Ver1.3 M.Hokkanji Start

    cv_an_object      CONSTANT VARCHAR2(1)   := '1';   -- 対象

    cv_table_name     CONSTANT VARCHAR2(100) := '自動配車ソート用中間テーブル';

    cv_parameter_name CONSTANT VARCHAR2(100) := '依頼No/移動No:';

    cv_0              CONSTANT NUMBER        := 0;     -- 数値判定用

    cv_loading_over   CONSTANT VARCHAR2(1) := '1';     -- 積載オーバー区分：オーバー

    cn_sts_error      CONSTANT NUMBER := 1;            -- 共通関数エラー

-- Ver1.3 M.Hokkanji End

--

    -- *** ローカル変数 ***

    lt_upd_req_no_ship_tab        request_no_ttype;   -- 依頼No

    lt_upd_req_no_move_tab        request_no_ttype;   -- 移動No

    lt_upd_delibery_no_ship_tab   delivery_no_ttype;  -- 配送No(出荷依頼)

    lt_upd_delibery_no_move_tab   delivery_no_ttype;  -- 配送No(移動指示)

    ln_loop_cnt                   NUMBER DEFAULT 0;   -- ループカウント

--20080517 D.Sugahara 不具合No2対応

    ln_loop_cnt_ship              NUMBER DEFAULT 0;   -- ループカウント(出荷依頼用）

    ln_loop_cnt_move              NUMBER DEFAULT 0;   -- ループカウント(移動指示用）

--

-- Ver1.2 M.Hokkanji Start

    lt_upd_method_code_ship_tab   ship_method_code_ttype; -- 配送No

    lt_upd_method_code_move_tab   ship_method_code_ttype; -- 配送No

-- Ver1.2 M.Hokkanji End

-- 20080603 K.Yamane 不具合No4->

    ln_cnt                        NUMBER;

-- 20080603 K.Yamane 不具合No4<-

--

    -- WHOカラム

    lt_user_id          xxcmn_txn_lot_cost.created_by%TYPE;             -- 作成者、最終更新者

    lt_login_id         xxcmn_txn_lot_cost.last_update_login%TYPE;      -- 最終更新ログイン

-- 20080603 K.Yamane 不具合No14->

    lt_conc_request_id  xxcmn_txn_lot_cost.request_id%TYPE;             -- 要求ID

    lt_prog_appl_id     xxcmn_txn_lot_cost.program_application_id%TYPE; -- アプリケーションID

    lt_conc_program_id  xxcmn_txn_lot_cost.program_id%TYPE;             -- プログラムID

-- 20080603 K.Yamane 不具合No14<-

-- Ver1.3 M.Hokkanji Start

    -- ヘッダ登録用

    lt_ship_based_weight        based_weight_ttype;                                  -- 基本重量(出荷)

    lt_ship_based_capacity      based_capa_ttype;                                    -- 基本容積(出荷)

    lt_ship_loading_weight      loading_weight_ttype;                                -- 重量積載効率(出荷)

    lt_ship_loading_capacity    loading_capacity_ttype;                              -- 容積積載効率(出荷)

    lt_ship_mixed_ratio         mixed_ratio_ttype;                                   -- 混載率(出荷)

    lt_move_based_weight        based_weight_ttype;                                  -- 基本重量(移動)

    lt_move_based_capacity      based_capa_ttype;                                    -- 基本容積(移動)

    lt_move_loading_weight      loading_weight_ttype;                                -- 重量積載効率(移動)

    lt_move_loading_capacity    loading_capacity_ttype;                              -- 容積積載効率(移動)

    lt_move_mixed_ratio         mixed_ratio_ttype;                                   -- 混載率(移動)

    -- 配車配送取得用

    lt_sum_loading_weight       xxwsh_carriers_schedule.sum_loading_weight%TYPE;     -- 重量合計

    lt_sum_loading_capacity     xxwsh_carriers_schedule.sum_loading_capacity%TYPE;   -- 容積合計

    lt_small_amount_class       xxwsh_ship_method_v.small_amount_class%TYPE;         -- 小口区分

    -- ソート

    lt_sort_sum_weight          xxwsh_carriers_sort_tmp.sum_weight%TYPE;             -- ソート積載重量合計

    lt_sort_sum_capacity        xxwsh_carriers_sort_tmp.sum_capacity%TYPE;           -- ソート積載容積合計

    lt_sort_pallet_weight       xxwsh_carriers_sort_tmp.sum_pallet_weight%TYPE;      -- ソートパレット重量合計

    lt_sort_deliver_from        xxwsh_carriers_sort_tmp.deliver_from%TYPE;           -- ソート出庫元保管場所

    lt_sort_deliver_to          xxwsh_carriers_sort_tmp.deliver_to%TYPE;             -- ソート出庫先保管場所

    lt_schedule_ship_date       xxwsh_carriers_sort_tmp.schedule_ship_date%TYPE;     -- ソート出庫予定日

    lt_weight_capacity_class    xxwsh_carriers_sort_tmp.weight_capacity_class%TYPE;  -- 重量容積区分

    lt_prod_class               xxwsh_carriers_sort_tmp.prod_class%TYPE;             -- 商品区分

    lt_based_weight             xxwsh_carriers_sort_tmp.based_weight%TYPE;           -- 基本重量

    lt_based_capacity           xxwsh_carriers_sort_tmp.based_capacity%TYPE;         -- 基本容積

    -- 一時処理用

    lt_mixed_ratio              xxwsh_order_headers_all.mixed_ratio%TYPE;            -- 混載率

    lt_sum_weight               xxwsh_carriers_schedule.sum_loading_weight%TYPE;     -- 重量合計

    lv_code_kbn                 VARCHAR2(1);                                         -- コード区分

    lv_loading_over_class       VARCHAR2(1);                                         -- 積載オーバー区分

    lv_ship_methods             xxcmn_ship_methods.ship_method%TYPE;                 -- 出荷方法

    ln_load_efficiency_weight   NUMBER;                                              -- 重量積載効率

    ln_load_efficiency_capacity NUMBER;                                              -- 容積積載効率

    lv_mixed_ship_method        VARCHAR2(2);                                         -- 混載配送区分

    ln_set_efficiency_weight    NUMBER;                                              -- SET用重量積載効率

    ln_set_efficiency_capacity  NUMBER;                                              -- SET用容積積載効率

    ln_drink_deadweight         NUMBER;                                              -- ドリンク積載重量

    ln_leaf_deadweight          NUMBER;                                              -- リーフ積載重量

    ln_leaf_loading_capacity    NUMBER;                                              -- リーフ積載容積

    ln_drink_loading_capacity   NUMBER;                                              -- ドリンク積載容積

    ln_palette_max_qty          NUMBER;                                              -- パレット最大枚数

    ln_retnum                   NUMBER;                                              -- 共通関数戻り値

-- Ver1.3 M.Hokkanji End

--

    -- *** ローカル・カーソル ***

    CURSOR get_upd_key_cur IS

      SELECT  xict.transaction_type transaction_type  -- 処理種別

            , xiclt.request_no      request_no        -- 依頼No/移動No

            , xmct.delivery_no      delivery_no       -- 配送No

-- Ver1.2 M.Hokkanji Start

            , xmct.fixed_shipping_method_code fixed_shipping_method_code -- 修正配送区分

-- Ver1.2 M.Hokkanji End

        FROM  xxwsh_intensive_carriers_tmp   xict     -- 自動配車集約中間テーブル

            , xxwsh_intensive_carrier_ln_tmp xiclt    -- 自動配車集約中間明細テーブル

            , xxwsh_mixed_carriers_tmp       xmct     -- 自動配車混載中間テーブル

       WHERE  xict.intensive_no = xiclt.intensive_no  -- 集約No

         AND  xict.intensive_no = xmct.intensive_no   -- 集約No

    ;

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

debug_log(FND_FILE.LOG,'B-15【依頼・指示情報更新処理】');

    -- ================

    -- 更新キー取得

    -- ================

    <<get_upd_key_loop>>

    FOR cur_rec IN get_upd_key_cur LOOP

--

--debug_log(FND_FILE.LOG,'更新キー取得');

      ln_loop_cnt := ln_loop_cnt + 1;

--

-- 20080603 K.Yamane 不具合No4->

      -- 配車配送計画アドオンの存在チェック

-- Ver1.3 M.Hokkanji Start

      -- 配車配送計画から値を取得する必要があるため修正

debug_log(FND_FILE.LOG,'B-15_a【配車配送計画情報取得】' || 'delivery_no:' || cur_rec.delivery_no);

      BEGIN

        SELECT  xcs.sum_loading_weight     sum_loading_weight      -- 積載重量合計

               ,xcs.sum_loading_capacity   sum_loading_capacity    -- 積載容積合計

               ,xsmv.small_amount_class    small_amount_class      -- 小口区分

        INTO   lt_sum_loading_weight,

               lt_sum_loading_capacity,

               lt_small_amount_class

        FROM   xxwsh_carriers_schedule xcs, -- 

               xxwsh_ship_method_v xsmv     -- 配送区分情報View

        WHERE  xcs.delivery_no = cur_rec.delivery_no

        AND    xsmv.ship_method_code = xcs.delivery_type;

        ln_cnt := 1;

debug_log(FND_FILE.LOG,'B-15_b1【配車配送計画情報取得対象有】');

debug_log(FND_FILE.LOG,'B-15_b1 lt_sum_loading_weight:' || lt_sum_loading_weight);

debug_log(FND_FILE.LOG,'B-15_b1 lt_sum_loading_capacity:' || lt_sum_loading_capacity);

debug_log(FND_FILE.LOG,'B-15_b1 lt_small_amount_class:' || lt_small_amount_class);

      EXCEPTION

        WHEN NO_DATA_FOUND THEN

debug_log(FND_FILE.LOG,'B-15_b2【配車配送計画情報取得対象データ無】');

          ln_cnt := 0;

      END;

--      SELECT COUNT(xcs.transaction_id)

--      INTO   ln_cnt

--      FROM   xxwsh_carriers_schedule xcs

--      WHERE  xcs.delivery_no = cur_rec.delivery_no

--      AND    ROWNUM = 1;

--

-- Ver1.3 M.Hokkanji End

      -- 配車配送計画アドオンに存在すれば

      IF (ln_cnt > 0) THEN

-- Ver1.3 M.Hokkanji Start

debug_log(FND_FILE.LOG,'B-15_c1【自動配車ソート用中間テーブルデータ取得】cur_rec.request_no:' || cur_rec.request_no);

        -- ヘッダを更新するのに必要な情報を取得

        BEGIN

          SELECT  NVL(xcst.sum_weight,cv_0)        sum_weight             -- 積載重量合計

                 ,NVL(xcst.sum_capacity,cv_0)      sum_capacity           -- 積載容積合計

                 ,NVL(xcst.sum_pallet_weight,cv_0) sum_pallet_weight      -- 合計パレット重量

                 ,xcst.deliver_from                deliver_from           -- 出庫元保管場所

                 ,xcst.deliver_to                  deliver_to             -- 出荷先

                 ,xcst.schedule_ship_date          schedule_ship_date     -- 出庫予定日

                 ,xcst.weight_capacity_class       weight_capacity_class  -- 重量容積区分

                 ,xcst.prod_class                  prod_class             -- 商品区分

          INTO    lt_sort_sum_weight

                 ,lt_sort_sum_capacity

                 ,lt_sort_pallet_weight

                 ,lt_sort_deliver_from

                 ,lt_sort_deliver_to

                 ,lt_schedule_ship_date

                 ,lt_weight_capacity_class

                 ,lt_prod_class

          FROM    xxwsh_carriers_sort_tmp xcst

          WHERE   xcst.request_no = cur_rec.request_no;

debug_log(FND_FILE.LOG,'B-15_c2【自動配車ソート用中間テーブルデータ取得成功】');

debug_log(FND_FILE.LOG,'B-15_c2 lt_sort_sum_weight:' || lt_sort_sum_weight);

debug_log(FND_FILE.LOG,'B-15_c2 lt_sort_sum_capacity:' || lt_sort_sum_capacity);

debug_log(FND_FILE.LOG,'B-15_c2 lt_sort_pallet_weightt:' || lt_sort_pallet_weight);

debug_log(FND_FILE.LOG,'B-15_c2 lt_sort_deliver_from:' || lt_sort_deliver_from);

debug_log(FND_FILE.LOG,'B-15_c2 lt_sort_deliver_to:' || lt_sort_deliver_to);

debug_log(FND_FILE.LOG,'B-15_c2 lt_schedule_ship_date:' || TO_DATE(lt_schedule_ship_date,'YYYY/MM/DD'));

debug_log(FND_FILE.LOG,'B-15_c2 lt_weight_capacity_class:' || lt_weight_capacity_class);

debug_log(FND_FILE.LOG,'B-15_c2 lt_prod_class:' || lt_prod_class);

        EXCEPTION

          WHEN NO_DATA_FOUND THEN

debug_log(FND_FILE.LOG,'B-15_c3【自動配車ソート用中間テーブルデータ取得失敗】');

            -- エラーメッセージ取得

            lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(

                           gv_xxwsh            -- モジュール名略称：XXWSH 出荷・引当/配車

                          ,gv_msg_xxwsh_11804  -- 対象データなし

                          ,gv_tkn_table        -- トークン'TABLE'

                          ,cv_table_name       -- テーブル名：自動配車ソート用中間テーブル

                          ,gv_tkn_key          -- トークン'KEY'

                          ,cv_parameter_name || cur_rec.request_no -- エラーデータ

                         ) ,1 ,5000);

            RAISE global_api_expt;

        END;

debug_log(FND_FILE.LOG,'B-15_d【重量設定】');

        -- 小口の場合はパレット重量を加味しない

        IF (lt_small_amount_class = cv_an_object) THEN

          lt_sum_weight := lt_sort_sum_weight;

        ELSE

          lt_sum_weight := lt_sort_sum_weight + lt_sort_pallet_weight;

        END IF;

debug_log(FND_FILE.LOG,'B-15_e【混載率取得】');

        -- 重量容積区分が重量の場合

        IF (lt_weight_capacity_class = gv_weight) THEN

          -- 取得した重量合計が0の場合

          IF (lt_sum_loading_weight = cv_0) THEN

            lt_mixed_ratio := cv_0; --混載率に0をセット

          ELSE

            lt_mixed_ratio := ROUND(lt_sum_weight / lt_sum_loading_weight * 100,2);

          END IF;

        ELSE

          -- 取得した容積合計が0の場合

          IF (lt_sum_loading_capacity = cv_0) THEN

            lt_mixed_ratio := cv_0; --混載率に0をセット

          ELSE

            lt_mixed_ratio := ROUND(lt_sort_sum_capacity / lt_sum_loading_capacity * 100,2);

          END IF;

        END IF;

debug_log(FND_FILE.LOG,'B-15_f【コード区分セット】');

        -- 処理種別：出荷の場合

        IF (cur_rec.transaction_type = gv_ship_type_ship) THEN

          lv_code_kbn := gv_cdkbn_ship_to;

        ELSE

          lv_code_kbn := gv_cdkbn_storage;

        END IF;

--

debug_log(FND_FILE.LOG,'B-15_g1【重量積載効率算出】');

debug_log(FND_FILE.LOG,'-----------------------------------');

debug_log(FND_FILE.LOG,'B-15_g1 合計重量:' || lt_sum_weight);

debug_log(FND_FILE.LOG,'B-15_g1 合計容積:NULL');

debug_log(FND_FILE.LOG,'B-15_g1 コード区分1:' || gv_cdkbn_storage);

debug_log(FND_FILE.LOG,'B-15_g1 入出庫場所コード１:' || lt_sort_deliver_from);

debug_log(FND_FILE.LOG,'B-15_g1 コード区分2:' || lv_code_kbn);

debug_log(FND_FILE.LOG,'B-15_g1 入出庫場所コード2:' || lt_sort_deliver_to);

debug_log(FND_FILE.LOG,'B-15_g1 出荷方法:' || cur_rec.fixed_shipping_method_code);

debug_log(FND_FILE.LOG,'B-15_g1 商品区分:' || gv_prod_class);

debug_log(FND_FILE.LOG,'B-15_g1 自動配車対象区分:NULL');

debug_log(FND_FILE.LOG,'B-15_g1 基準日(適用日基準日):' || TO_CHAR(lt_schedule_ship_date,'YYYY/MM/DD'));

debug_log(FND_FILE.LOG,'-----------------------------------');

--

        -- 共通関数：積載効率チェック(積載効率)

        xxwsh_common910_pkg.calc_load_efficiency(

            in_sum_weight                  => NVL(lt_sum_weight,0)      -- 1.合計重量

          , in_sum_capacity                => NULL                      -- 2.合計容積

          , iv_code_class1                 => gv_cdkbn_storage          -- 3.コード区分１

          , iv_entering_despatching_code1  => lt_sort_deliver_from      -- 4.入出庫場所コード１

          , iv_code_class2                 => lv_code_kbn               -- 5.コード区分２

          , iv_entering_despatching_code2  => lt_sort_deliver_to        -- 6.入出庫場所コード２

          , iv_ship_method                 => cur_rec.fixed_shipping_method_code

                                                                        -- 7.出荷方法

          , iv_prod_class                  => lt_prod_class             -- 8.商品区分

          , iv_auto_process_type           => NULL                      -- 9.自動配車対象区分

          , id_standard_date               => lt_schedule_ship_date

                                                                        -- 10.基準日(適用日基準日)

          , ov_retcode                     => lv_retcode                -- 11.リターンコード

          , ov_errmsg_code                 => lv_errmsg                 -- 12.エラーメッセージコード

          , ov_errmsg                      => lv_errbuf                 -- 13.エラーメッセージ

          , ov_loading_over_class          => lv_loading_over_class     -- 14.積載オーバー区分

          , ov_ship_methods                => lv_ship_methods           -- 15.出荷方法

          , on_load_efficiency_weight      => ln_load_efficiency_weight -- 16.重量積載効率

          , on_load_efficiency_capacity    => ln_load_efficiency_capacity

                                                                        -- 17.容積積載効率

          , ov_mixed_ship_method           => lv_mixed_ship_method      -- 18.混載配送区分

        );

--

debug_log(FND_FILE.LOG,'-----------------------------------');

debug_log(FND_FILE.LOG,'B-15_g2 リターンコード:' || lv_retcode);

debug_log(FND_FILE.LOG,'B-15_g2 エラーメッセージコード:' || lv_errmsg);

debug_log(FND_FILE.LOG,'B-15_g2 エラーメッセージ:' || lv_errbuf);

debug_log(FND_FILE.LOG,'B-15_g2 積載オーバー区分:' || lv_loading_over_class);

debug_log(FND_FILE.LOG,'B-15_g2 出荷方法:' || lv_ship_methods);

debug_log(FND_FILE.LOG,'B-15_g2 重量積載効率:' || ln_load_efficiency_weight);

debug_log(FND_FILE.LOG,'B-15_g2 容積積載効率:' || ln_load_efficiency_capacity);

debug_log(FND_FILE.LOG,'B-15_g2 混載配送区分:' || lv_mixed_ship_method);

        -- 共通関数がエラーの場合

-- Ver1.7 M.Hokkanji START

        IF (lv_retcode <> gv_status_normal) THEN

--        IF (lv_retcode = gv_status_error) THEN

-- Ver1.16 2008/12/07 START

--          lv_errmsg := lv_errbuf;

--          lv_errmsg := lv_errbuf;

        BEGIN

          lv_errmsg  :=   NVL(lt_sum_weight,0) -- 1.合計重量

                          || gv_msg_comma ||

                          NULL                -- 2.合計容積

                          || gv_msg_comma ||

                          gv_cdkbn_storage    -- 3.コード区分１

                          || gv_msg_comma ||

                          lt_sort_deliver_from  -- 4.入出庫場所コード１

                          || gv_msg_comma ||

                          lv_code_kbn      -- 5.コード区分２

                          || gv_msg_comma ||

                          lt_sort_deliver_to    -- 6.入出庫場所コード２

                          || gv_msg_comma ||

                          cur_rec.fixed_shipping_method_code -- 7.出荷方法

                          || gv_msg_comma ||

                          lt_prod_class       -- 8.商品区分

                          || gv_msg_comma ||

                          NULL       -- 9.自動配車対象区分

                          || gv_msg_comma ||

                          TO_CHAR(lt_schedule_ship_date, 'YYYY/MM/DD'); -- 10.基準日

          lv_errmsg := lv_errmsg|| '(重量,容積,コード区分1,コード1,コード区分2,コード2';

          lv_errmsg := lv_errmsg|| ',配送区分,商品区分,自動配車対象区分,基準日'; -- msg

          lv_errmsg := lv_errmsg||lv_errbuf ;

        EXCEPTION

          WHEN OTHERS THEN

            lv_errmsg := lv_errbuf ;

        END;

-- Ver1.16 2008/12/07 End

-- Ver1.7 M.Hokkanji END

--

debug_log(FND_FILE.LOG,'B-15_g3【重量積載効率取得エラー】');

--

          RAISE global_api_expt;

        END IF;

--

-- Ver 1.7 M.Hokkanji Start

-- 各ヘッダに設定するときは積載オーバーを除外

-- Ver 1.7 M.Hokkanji End

        -- 積載オーバーの場合

--        IF (lv_loading_over_class = cv_loading_over) THEN

--debug_log(FND_FILE.LOG,'B-15_g4【重量積載効率積載オーバー】');

          -- エラーメッセージ取得

--          lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg(

--                           gv_xxwsh            -- モジュール名略称：XXWSH 出荷・引当/配車

--                         , gv_msg_xxwsh_11803  -- メッセージ：APP-XXWSH-11803 積載オーバーメッセージ

--                         , gv_tkn_req_no       -- トークン：REQ_NO

--                         , cur_rec.request_no  -- 出荷依頼No

--                        ),1,5000);

--          lv_errbuf := lv_errmsg;

--          RAISE global_api_expt;

--        END IF;

-- Ver 1.7 M.Hokkanji End

debug_log(FND_FILE.LOG,'B-15_g5【重量積載効率セット】');

        -- 重量積載効率をセット

        ln_set_efficiency_weight := ln_load_efficiency_weight;

--

debug_log(FND_FILE.LOG,'B-15_h1【容積積載効率算出】');

debug_log(FND_FILE.LOG,'-----------------------------------');

debug_log(FND_FILE.LOG,'B-15_h1 合計重量:NULL');

debug_log(FND_FILE.LOG,'B-15_h1 合計容積:'|| lt_sort_sum_capacity);

debug_log(FND_FILE.LOG,'B-15_h1 コード区分1:' || gv_cdkbn_storage);

debug_log(FND_FILE.LOG,'B-15_h1 入出庫場所コード１:' || lt_sort_deliver_from);

debug_log(FND_FILE.LOG,'B-15_h1 コード区分2:' || lv_code_kbn);

debug_log(FND_FILE.LOG,'B-15_h1 入出庫場所コード2:' || lt_sort_deliver_to);

debug_log(FND_FILE.LOG,'B-15_h1 出荷方法:' || cur_rec.fixed_shipping_method_code);

debug_log(FND_FILE.LOG,'B-15_h1 商品区分:' || gv_prod_class);

debug_log(FND_FILE.LOG,'B-15_h1 自動配車対象区分:NULL');

debug_log(FND_FILE.LOG,'B-15_h1 基準日(適用日基準日):' || TO_CHAR(lt_schedule_ship_date,'YYYY/MM/DD'));

debug_log(FND_FILE.LOG,'-----------------------------------');

--

        -- 共通関数：積載効率チェック(積載効率)

        xxwsh_common910_pkg.calc_load_efficiency(

            in_sum_weight                  => NULL                        -- 1.合計重量

          , in_sum_capacity                => NVL(lt_sort_sum_capacity,0) -- 2.合計容積

          , iv_code_class1                 => gv_cdkbn_storage          -- 3.コード区分１

          , iv_entering_despatching_code1  => lt_sort_deliver_from      -- 4.入出庫場所コード１

          , iv_code_class2                 => lv_code_kbn               -- 5.コード区分２

          , iv_entering_despatching_code2  => lt_sort_deliver_to        -- 6.入出庫場所コード２

          , iv_ship_method                 => cur_rec.fixed_shipping_method_code

                                                                        -- 7.出荷方法

          , iv_prod_class                  => lt_prod_class             -- 8.商品区分

          , iv_auto_process_type           => NULL                      -- 9.自動配車対象区分

          , id_standard_date               => lt_schedule_ship_date

                                                                        -- 10.基準日(適用日基準日)

          , ov_retcode                     => lv_retcode                -- 11.リターンコード

          , ov_errmsg_code                 => lv_errmsg                 -- 12.エラーメッセージコード

          , ov_errmsg                      => lv_errbuf                 -- 13.エラーメッセージ

          , ov_loading_over_class          => lv_loading_over_class     -- 14.積載オーバー区分

          , ov_ship_methods                => lv_ship_methods           -- 15.出荷方法

          , on_load_efficiency_weight      => ln_load_efficiency_weight -- 16.重量積載効率

          , on_load_efficiency_capacity    => ln_load_efficiency_capacity

                                                                        -- 17.容積積載効率

          , ov_mixed_ship_method           => lv_mixed_ship_method      -- 18.混載配送区分

        );

--

debug_log(FND_FILE.LOG,'-----------------------------------');

debug_log(FND_FILE.LOG,'B-15_h2 リターンコード:' || lv_retcode);

debug_log(FND_FILE.LOG,'B-15_h2 エラーメッセージコード:' || lv_errmsg);

debug_log(FND_FILE.LOG,'B-15_h2 エラーメッセージ:' || lv_errbuf);

debug_log(FND_FILE.LOG,'B-15_h2 積載オーバー区分:' || lv_loading_over_class);

debug_log(FND_FILE.LOG,'B-15_h2 出荷方法:' || lv_ship_methods);

debug_log(FND_FILE.LOG,'B-15_h2 重量積載効率:' || ln_load_efficiency_weight);

debug_log(FND_FILE.LOG,'B-15_h2 容積積載効率:' || ln_load_efficiency_capacity);

debug_log(FND_FILE.LOG,'B-15_h2 混載配送区分:' || lv_mixed_ship_method);

        -- 共通関数がエラーの場合

-- Ver1.7 M.Hokkanji START

        IF (lv_retcode <> gv_status_normal) THEN

--        IF (lv_retcode = gv_status_error) THEN

          lv_errmsg := lv_errbuf;

-- Ver1.7 M.Hokkanji END

--       

debug_log(FND_FILE.LOG,'B-15_h3【容積積載効率取得エラー】');

--

          RAISE global_api_expt;

        END IF;

--

-- Ver 1.7 M.Hokkanji Start

-- 各ヘッダに積載率を設定する場合は積載オーバを除外

        -- 積載オーバーの場合

--        IF (lv_loading_over_class = cv_loading_over) THEN

--debug_log(FND_FILE.LOG,'B-15_h4【容積積載効率積載オーバー】');

          -- エラーメッセージ取得

--          lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg(

--                           gv_xxwsh            -- モジュール名略称：XXWSH 出荷・引当/配車

--                         , gv_msg_xxwsh_11803  -- メッセージ：APP-XXWSH-11803 積載オーバーメッセージ

--                         , gv_tkn_req_no       -- トークン：REQ_NO

--                         , cur_rec.request_no  -- 出荷依頼No

--                        ),1,5000);

--          lv_errbuf := lv_errmsg;

--          RAISE global_api_expt;

--        END IF;

-- Ver 1.7 M.Hokkanji End

debug_log(FND_FILE.LOG,'B-15_h5【容積積載効率セット】');

        -- 容積積載効率をセット

        ln_set_efficiency_capacity := ln_load_efficiency_capacity;

debug_log(FND_FILE.LOG,'B-15_i1【基本重量基本容積取得】');

        ln_retnum :=  xxwsh_common_pkg.get_max_pallet_qty(    -- 共通関数：最大パレット枚数算出関数

                          iv_code_class1

                                  => gv_cdkbn_storage             -- コード区分１

                        , iv_entering_despatching_code1

                                  => lt_sort_deliver_from         -- 入出庫場所コード１

                        , iv_code_class2

                                  => lv_code_kbn                  -- コード区分２

                        , iv_entering_despatching_code2

                                  => lt_sort_deliver_to           -- 入出庫場所コード２

                        , id_standard_date

                                  => lt_schedule_ship_date        -- 基準日

                        , iv_ship_methods

                                  => cur_rec.fixed_shipping_method_code

                                                                  -- 配送区分                                

                        , on_drink_deadweight

                                  => ln_drink_deadweight          -- ドリンク積載重量

                        , on_leaf_deadweight

                                  => ln_leaf_deadweight           -- リーフ積載重量

                        , on_drink_loading_capacity

                                  => ln_drink_loading_capacity    -- ドリンク積載容積

                        , on_leaf_loading_capacity

                                  => ln_leaf_loading_capacity     -- リーフ積載容積

                        , on_palette_max_qty

                                  => ln_palette_max_qty           -- パレット最大枚数

                     );

debug_log(FND_FILE.LOG,'B-15_i2【基本重量基本容積取得後】');

debug_log(FND_FILE.LOG,'・リターンコード:'|| ln_retnum);

debug_log(FND_FILE.LOG,'・ドリンク積載重量:'|| ln_drink_deadweight);

debug_log(FND_FILE.LOG,'・リーフ積載重量:'|| ln_leaf_deadweight);

debug_log(FND_FILE.LOG,'・ドリンク積載容積:'|| ln_leaf_loading_capacity);

debug_log(FND_FILE.LOG,'・リーフ積載容積:'|| ln_leaf_loading_capacity);

debug_log(FND_FILE.LOG,'・パレット最大枚数:'|| ln_palette_max_qty);

        -- 共通関数エラーの場合

        IF (ln_retnum = cn_sts_error) THEN

          gv_err_key  :=  gv_cdkbn_storage

                          || gv_msg_comma ||

                          lt_sort_deliver_from

                          || gv_msg_comma ||

                          lv_code_kbn

                          || gv_msg_comma ||

                          lt_sort_deliver_to

                          || gv_msg_comma ||

                          TO_CHAR(lt_schedule_ship_date, 'YYYY/MM/DD')

                          || gv_msg_comma ||

                          cur_rec.fixed_shipping_method_code

                          ;

          -- エラーメッセージ取得

          lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(

                          gv_xxwsh                -- モジュール名略称：XXWSH 出荷・引当/配車

                        , gv_msg_xxwsh_11810      -- メッセージ：APP-XXWSH-11810 共通関数エラー

                        , gv_fnc_name             -- トークン：FNC_NAME

                        , 'xxwsh_common_pkg.get_max_pallet_qty' -- 関数名

                        , gv_tkn_key              -- トークン：KEY

                        , gv_err_key              -- 関数実行キー

                        ),1,5000);

          RAISE global_api_expt;

        END IF;

debug_log(FND_FILE.LOG,'B-15_i3【基本重量基本容積特定処理】');

        -- 商品区分がリーフの場合

        IF ( lt_prod_class = gv_prod_cls_leaf) THEN

          lt_based_weight   := ln_leaf_deadweight;

          lt_based_capacity := ln_leaf_loading_capacity;

        ELSE

          lt_based_weight   := ln_drink_deadweight;

          lt_based_capacity := ln_drink_loading_capacity;

        END IF;

--

-- Ver1.3 M.Hokkanji End

--

        -- 処理種別：出荷

        IF (cur_rec.transaction_type = gv_ship_type_ship) THEN

--

debug_log(FND_FILE.LOG,'B15_1.0 処理種別：出荷 ln_loop_cnt= '||to_char(ln_loop_cnt));

--20080517 D.Sugahara 不具合No2対応->

--        lt_upd_req_no_ship_tab(ln_loop_cnt)       := cur_rec.request_no;    -- 依頼No

--        lt_upd_delibery_no_ship_tab(ln_loop_cnt)  := cur_rec.delivery_no;   -- 配送No

          ln_loop_cnt_ship := ln_loop_cnt_ship + 1;                -- ループカウント(出荷依頼用）

          lt_upd_req_no_ship_tab(ln_loop_cnt_ship)       := cur_rec.request_no;    -- 依頼No

          lt_upd_delibery_no_ship_tab(ln_loop_cnt_ship)  := cur_rec.delivery_no;   -- 配送No

--20080517 D.Sugahara 不具合No2対応<-

-- Ver1.2 M.Hokkanji Start

          lt_upd_method_code_ship_tab(ln_loop_cnt_ship)  := cur_rec.fixed_shipping_method_code; -- 修正配送区分

-- Ver1.2 M.Hokkanji End

--

-- Ver1.3 M.Hokkanji Start

          lt_ship_based_weight(ln_loop_cnt_ship)         := lt_based_weight;            -- 基本重量

          lt_ship_based_capacity(ln_loop_cnt_ship)       := lt_based_capacity;          -- 基本容積

          lt_ship_loading_weight(ln_loop_cnt_ship)       := ln_set_efficiency_weight;   -- 重量積載効率

          lt_ship_loading_capacity(ln_loop_cnt_ship)     := ln_set_efficiency_capacity; -- 容積積載効率

          lt_ship_mixed_ratio(ln_loop_cnt_ship)          := lt_mixed_ratio;             -- 混載率

-- Ver1.3 M.Hokkanji End

        -- 処理種別：移動

        ELSE

debug_log(FND_FILE.LOG,'B15_1.1 処理種別：移動 ln_loop_cnt= '||to_char(ln_loop_cnt));

--20080517 D.Sugahara 不具合No2対応->

--        lt_upd_req_no_move_tab(ln_loop_cnt)       := cur_rec.request_no;    -- 移動No

--        lt_upd_delibery_no_move_tab(ln_loop_cnt)  := cur_rec.delivery_no;   -- 配送No

          ln_loop_cnt_move := ln_loop_cnt_move + 1;                -- ループカウント(出荷依頼用）

          lt_upd_req_no_move_tab(ln_loop_cnt_move)       := cur_rec.request_no;    -- 移動No

          lt_upd_delibery_no_move_tab(ln_loop_cnt_move)  := cur_rec.delivery_no;   -- 配送No

--20080517 D.Sugahara 不具合No2対応<-

-- Ver1.2 M.Hokkanji Start

          lt_upd_method_code_move_tab(ln_loop_cnt_move)  := cur_rec.fixed_shipping_method_code; -- 修正配送区分

-- Ver1.2 M.Hokkanji End

--

-- Ver1.3 M.Hokkanji Start

          lt_move_based_weight(ln_loop_cnt_move)         := lt_based_weight;            -- 基本重量

          lt_move_based_capacity(ln_loop_cnt_move)       := lt_based_capacity;          -- 基本容積

          lt_move_loading_weight(ln_loop_cnt_move)       := ln_set_efficiency_weight;   -- 重量積載効率

          lt_move_loading_capacity(ln_loop_cnt_move)     := ln_set_efficiency_capacity; -- 容積積載効率

          lt_move_mixed_ratio(ln_loop_cnt_move)          := lt_mixed_ratio;             -- 混載率

-- Ver1.3 M.Hokkanji End

--

        END IF;

--

      END IF;

-- 20080603 K.Yamane 不具合No4<-

--

    END LOOP get_upd_key_loop;

--

    -- ============================

    --  依頼・指示情報一括更新処理

    -- ============================

    -- WHOカラム取得

    lt_user_id          := FND_GLOBAL.USER_ID;          -- 作成者、最終更新者

    lt_login_id         := FND_GLOBAL.LOGIN_ID;         -- 最終更新ログイン

-- 20080603 K.Yamane 不具合No14->

    lt_conc_request_id  := FND_GLOBAL.CONC_REQUEST_ID;  -- 要求ID

    lt_prog_appl_id     := FND_GLOBAL.PROG_APPL_ID;     -- アプリケーションID

    lt_conc_program_id  := FND_GLOBAL.CONC_PROGRAM_ID;  -- プログラムID

-- 20080603 K.Yamane 不具合No14<-

--

debug_log(FND_FILE.LOG,'B15_1.2 出荷更新件数：'||to_char(lt_upd_req_no_ship_tab.COUNT));

debug_log(FND_FILE.LOG,'B15_1.2 移動更新件数：'||to_char(lt_upd_req_no_move_tab.COUNT));

    -- 受注ヘッダアドオン

    FORALL upd_cnt_1 IN 1..lt_upd_req_no_ship_tab.COUNT

--debug_log(FND_FILE.LOG,'B15_1.3 出荷更新： '||to_char(upd_cnt_1)||'件目');

      UPDATE xxwsh_order_headers_all

         SET  delivery_no            = lt_upd_delibery_no_ship_tab(upd_cnt_1)  -- 配送No

            , last_updated_by        = lt_user_id                              -- 最終更新者

            , last_update_date       = SYSDATE                                 -- 最終更新日

            , last_update_login      = lt_login_id                             -- 最終更新ログイン

            , request_id             = lt_conc_request_id                      -- 要求ID

-- Ver1.2 M.Hokkanji Start

            , shipping_method_code   = lt_upd_method_code_ship_tab(upd_cnt_1)  -- 配送区分

-- Ver1.2 M.Hokkanji End

-- Ver1.3 M.Hokkanji Start

            , based_weight           = lt_ship_based_weight(upd_cnt_1)         -- 基本重量

            , based_capacity         = lt_ship_based_capacity(upd_cnt_1)       -- 基本容積

            , loading_efficiency_weight

                                     = lt_ship_loading_weight(upd_cnt_1)       -- 重量積載効率

            , loading_efficiency_capacity

                                     = lt_ship_loading_capacity(upd_cnt_1)     -- 容積積載効率

            , mixed_ratio            = lt_ship_mixed_ratio(upd_cnt_1)          -- 混載率

-- Ver1.3 M.Hokkanji End

-- 20080603 K.Yamane 不具合No14->

            , program_application_id = lt_prog_appl_id                         -- ｱﾌﾟﾘｹｰｼｮﾝID

            , program_id             = lt_conc_program_id                      -- プログラムID

            , program_update_date    = SYSDATE                                 -- プログラム更新日

-- 20080603 K.Yamane 不具合No14<-

       WHERE  request_no           = lt_upd_req_no_ship_tab(upd_cnt_1)    -- 依頼No

         AND  latest_external_flag = cv_yes                               -- 最新フラグ

      ;

--

    -- 移動依頼/指示ヘッダアドオン

    FORALL upd_cnt_2 IN 1..lt_upd_req_no_move_tab.COUNT

--debug_log(FND_FILE.LOG,'B15_1.4 移動更新： '||to_char(upd_cnt_2)||'件目');

      UPDATE xxinv_mov_req_instr_headers

         SET  delivery_no            = lt_upd_delibery_no_move_tab(upd_cnt_2)  -- 配送No

            , last_updated_by        = lt_user_id                              -- 最終更新者

            , last_update_date       = SYSDATE                                 -- 最終更新日

            , last_update_login      = lt_login_id                             -- 最終更新ログイン

-- Ver1.2 M.Hokkanji Start

            , shipping_method_code   = lt_upd_method_code_move_tab(upd_cnt_2)  -- 配送区分

-- Ver1.2 M.Hokkanji End

-- Ver1.3 M.Hokkanji Start

            , based_weight           = lt_move_based_weight(upd_cnt_2)         -- 基本重量

            , based_capacity         = lt_move_based_capacity(upd_cnt_2)       -- 基本容積

            , loading_efficiency_weight

                                     = lt_move_loading_weight(upd_cnt_2)       -- 重量積載効率

            , loading_efficiency_capacity

                                     = lt_move_loading_capacity(upd_cnt_2)     -- 容積積載効率

            , mixed_ratio            = lt_move_mixed_ratio(upd_cnt_2)          -- 混載率

-- Ver1.3 M.Hokkanji End

-- 20080603 K.Yamane 不具合No14->

            , request_id             = lt_conc_request_id                      -- 要求ID

            , program_application_id = lt_prog_appl_id                         -- ｱﾌﾟﾘｹｰｼｮﾝID

            , program_id             = lt_conc_program_id                      -- プログラムID

            , program_update_date    = SYSDATE                                 -- プログラム更新日

-- 20080603 K.Yamane 不具合No14<-

       WHERE  mov_num           = lt_upd_req_no_move_tab(upd_cnt_2)       -- 移動No

      ;

-- Ver1.2 M.Hokkanji Start

    -- 今回対象となったヘッダに紐付く配送Noで紐付きが無くなったものを削除

    BEGIN

      DELETE xxwsh_carriers_schedule xch

       WHERE xch.delivery_no IN (

-- Ver1.6 M.Hokkanji Start

--               SELECT xcst.delivery_no

               SELECT NVL(xcst.delivery_no,xcst.mixed_no)

-- Ver1.6 M.Hokkanji End

                 FROM xxwsh_carriers_sort_tmp xcst

-- Ver1.6 M.Hokkanji Start

                  WHERE NOT EXISTS (

--                WHERE xcst.delivery_no IS NOT NULL

--                AND NOT EXISTS (

-- Ver1.6 M.Hokkanji End

-- Ver1.8 A.Shiina START

/*

                      SELECT xoh.delivery_no delivery_no

                        FROM xxwsh_order_headers_all xoh

-- Ver1.6 M.Hokkanji Start

--                       WHERE xoh.delivery_no = xcst.delivery_no

                       WHERE NVL(xoh.delivery_no,xoh.mixed_no) = NVL(xcst.delivery_no,xcst.mixed_no)

-- Ver1.6 M.Hokkanji End

                         AND xoh.latest_external_flag = 'Y')

                AND NOT EXISTS (

                      SELECT xmrih.delivery_no delivery_no

                        FROM xxinv_mov_req_instr_headers xmrih

                       WHERE xmrih.delivery_no = xcst.delivery_no

               ));

*/

                    SELECT xoh.delivery_no delivery_no

                    FROM   xxwsh_order_headers_all xoh

                    WHERE  xoh.delivery_no IS NOT NULL

                    AND    xoh.delivery_no = NVL ( xcst.delivery_no , xcst.mixed_no )

                    AND    xoh.latest_external_flag = 'Y'

                    AND    ROWNUM <= 1

                    UNION ALL

                    SELECT xoh.delivery_no delivery_no

                    FROM   xxwsh_order_headers_all xoh

                    WHERE  xoh.delivery_no IS NULL

                    AND    xoh.mixed_no = NVL ( xcst.delivery_no , xcst.mixed_no )

                    AND    xoh.latest_external_flag = 'Y'

                    AND    ROWNUM <= 1)

                  AND NOT EXISTS (

                    SELECT xmrih.delivery_no delivery_no

                    FROM   xxinv_mov_req_instr_headers xmrih

                    WHERE  xmrih.delivery_no = xcst.delivery_no

                    AND    ROWNUM <= 1) ) ;

-- Ver1.8 A.Shiina END

    EXCEPTION

      WHEN NO_DATA_FOUND THEN

        NULL; -- 対象件数が0件の場合はエラーとしない。

    END;

debug_log(FND_FILE.LOG,'B15_1.3 配車配送計画削除件数：'||TO_CHAR(SQL%rowcount));

-- Ver1.2 M.Hokkanji End

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

  END upd_req_inst_info;

--

  /**********************************************************************************

   * Procedure Name   : submain

   * Description      : メイン処理プロシージャ

   **********************************************************************************/

  PROCEDURE submain(

    iv_prod_class           IN  VARCHAR2,         --  1.商品区分

    iv_shipping_biz_type    IN  VARCHAR2,         --  2.処理種別

    iv_block_1              IN  VARCHAR2,         --  3.ブロック1

    iv_block_2              IN  VARCHAR2,         --  4.ブロック2

    iv_block_3              IN  VARCHAR2,         --  5.ブロック3

    iv_storage_code         IN  VARCHAR2,         --  6.出庫元

    iv_transaction_type_id  IN  VARCHAR2,         --  7.出庫形態ID

    iv_date_from            IN  VARCHAR2,         --  8.出庫日From

    iv_date_to              IN  VARCHAR2,         --  9.出庫日To

    iv_forwarder_id         IN  VARCHAR2,         -- 10.運送業者ID

-- 2009/01/27 H.Itou Add Start 本番障害#1028対応

    iv_instruction_dept     IN  VARCHAR2,         -- 11.指示部署

-- 2009/01/27 H.Itou Add End

    ov_errbuf               OUT NOCOPY VARCHAR2,  -- エラー・メッセージ           --# 固定 #

    ov_retcode              OUT NOCOPY VARCHAR2,  -- リターン・コード             --# 固定 #

    ov_errmsg               OUT NOCOPY VARCHAR2)  -- ユーザー・エラー・メッセージ --# 固定 #

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

    lv_errbuf  VARCHAR2(5000);        -- エラー・メッセージ

    lv_retcode VARCHAR2(1);           -- リターン・コード

    lv_errmsg  VARCHAR2(5000);        -- ユーザー・エラー・メッセージ

    lb_warning_flg  BOOLEAN DEFAULT FALSE; -- 警告フラグ（警告の場合：TRUE)

--

--###########################  固定部 END   ####################################

--

    -- ===============================

    -- ユーザー宣言部

    -- ===============================

    -- *** ローカル定数 ***

    cv_prod_class CONSTANT VARCHAR2(100)  :=  '商品区分';   -- 商品区分

    cv_date_from  CONSTANT VARCHAR2(100)  :=  '出庫日FROM'; -- 出庫日From

    cv_date_to    CONSTANT VARCHAR2(100)  :=  '出庫日TO';   -- 出庫日To

--

    -- *** ローカル変数 ***

    lv_msg        VARCHAR2(5000);                           -- ローカルメッセージ

    ld_date_from  DATE;                                     -- 出庫日From

    ld_date_to    DATE;                                     -- 出庫日To

--

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

debug_log(FND_FILE.LOG,'【サブメイン】');

    -- グローバル変数の初期化

    gn_target_cnt := 0;

    gn_normal_cnt := 0;

    gn_error_cnt  := 0;

    gn_warn_cnt   := 0;

--

    -- ===============================

    -- B-1.パージ処理

    -- ===============================

    del_table_purge(

       ov_errbuf  => lv_errbuf    -- エラー・メッセージ           --# 固定 #

     , ov_retcode => lv_retcode   -- リターン・コード             --# 固定 #

     , ov_errmsg  => lv_errmsg    -- ユーザー・エラー・メッセージ --# 固定 #

    );

    -- パージ処理がエラーの場合

    IF (lv_retcode = gv_status_error) THEN

      RAISE global_process_expt;

    END IF;

debug_log(FND_FILE.LOG,'B-1.パージ処理終了');

--

debug_log(FND_FILE.LOG,'B-2.パラメータチェック処理開始');

    -- ===============================

    -- B-2.パラメータチェック処理

    -- ===============================

    -- 商品区分未入力

    IF (iv_prod_class IS NULL) THEN

      -- エラーメッセージ取得

      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(

                      gv_xxwsh            -- モジュール名略称：XXWSH 出荷・引当/配車

                    , gv_msg_xxwsh_13151  -- メッセージ：APP-XXWSH-13151 必須パラメータ未入力エラー

                    , gv_tkn_item         -- トークン：ITEM

                    , cv_prod_class       -- パラメータ．商品区分

                   ),1,5000);

      RAISE global_process_expt;

--

    END IF;

debug_log(FND_FILE.LOG,'・商品区分');

--

    -- 出庫日From未入力

    IF (iv_date_from IS NULL) THEN

      -- エラーメッセージ取得

      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(

                      gv_xxwsh            -- モジュール名略称：XXWSH 出荷・引当/配車

                    , gv_msg_xxwsh_13151  -- メッセージ：APP-XXWSH-13151 必須パラメータ未入力エラー

                    , gv_tkn_item         -- トークン：ITEM

                    , cv_date_from        -- パラメータ．出庫日From

                   ),1,5000);

      RAISE global_process_expt;

    ELSE

      BEGIN

        -- 書式チェック

        SELECT FND_DATE.CANONICAL_TO_DATE(iv_date_from)

        INTO  ld_date_from

        FROM  DUAL

        ;

      EXCEPTION

        WHEN to_date_expt_m THEN

          -- 月が無効

          RAISE to_date_expt;

        WHEN to_date_expt_d THEN

          -- 日が無効

          RAISE to_date_expt;

        WHEN to_date_expt_y THEN

          -- リテラルと不一致

          RAISE to_date_expt;

        WHEN OTHERS THEN

          RAISE global_process_expt;

      END;

--

    END IF;

--

debug_log(FND_FILE.LOG,'・出庫日FROM');

    -- 出庫日To未入力

    IF (iv_date_To IS NULL) THEN

      -- エラーメッセージ取得

      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(

                      gv_xxwsh            -- モジュール名略称：XXWSH 出荷・引当/配車

                    , gv_msg_xxwsh_13151  -- メッセージ：APP-XXWSH-13151 必須パラメータ未入力エラー

                    , gv_tkn_item         -- トークン：ITEM

                    , cv_date_To          -- パラメータ．出庫日To

                   ),1,5000);

      RAISE global_process_expt;

--

    ELSE

--

      BEGIN

        -- 書式チェック

        SELECT FND_DATE.CANONICAL_TO_DATE(iv_date_to)

        INTO  ld_date_to

        FROM  DUAL

        ;

      EXCEPTION

        WHEN to_date_expt_m THEN

          -- 月が無効

          RAISE to_date_expt;

        WHEN to_date_expt_d THEN

          -- 日が無効

          RAISE to_date_expt;

        WHEN to_date_expt_y THEN

          -- リテラルと不一致

          RAISE to_date_expt;

        WHEN OTHERS THEN

          RAISE global_process_expt;

      END;

--

    END IF;

--

debug_log(FND_FILE.LOG,'・出庫日To');

    -- 日付逆転

    IF (ld_date_from > ld_date_to) THEN

      -- エラーメッセージ取得

      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(

                      gv_xxwsh            -- モジュール名略称：XXWSH 出荷・引当/配車

                    , gv_msg_xxwsh_11113  -- メッセージ：APP-XXWSH-11113 日付逆転エラー

                   ),1,5000);

      RAISE global_process_expt;

    END IF;

--

debug_log(FND_FILE.LOG,'パラメータチェック終了');

    -- パラメータをグローバル変数にセット

    gv_prod_class     :=  iv_prod_class;        -- 商品区分

    gv_ship_biz_type  :=  iv_shipping_biz_type; -- 処理種別

    gd_date_from      :=  ld_date_from;         -- 出庫日From

--

    -- ===============================

    -- B-3.依頼指示情報抽出

    -- ===============================

    get_req_inst_info(

        iv_prod_class           => iv_prod_class            --  1.商品区分

      , iv_shipping_biz_type    => iv_shipping_biz_type     --  2.処理種別

      , iv_block_1              => iv_block_1               --  3.ブロック１

      , iv_block_2              => iv_block_2               --  4.ブロック２

      , iv_block_3              => iv_block_3               --  5.ブロック３

      , iv_storage_code         => iv_storage_code          --  6.出庫元

      , iv_transaction_type_id  => iv_transaction_type_id   --  7.出庫形態ID

      , id_date_from            => ld_date_from             --  8.出庫日From

      , id_date_to              => ld_date_to               --  9.出庫日To

      , iv_forwarder            => iv_forwarder_id          -- 10.運送業者ID

-- 2009/01/27 H.Itou Add Start 本番障害#1028対応

      , iv_instruction_dept     => iv_instruction_dept      -- 11.指示部署

-- 2009/01/27 H.Itou Add End

      , ov_errbuf               => lv_errbuf                -- エラー・メッセージ           --# 固定 #

      , ov_retcode              => lv_retcode               -- リターン・コード             --# 固定 #

      , ov_errmsg               => lv_errmsg                -- ユーザー・エラー・メッセージ --# 固定 #

    );

    -- エラー制御

    IF (lv_retcode = gv_status_error) THEN

      -- 処理がエラーの場合

      RAISE global_process_expt;

    ELSIF (lv_retcode = gv_status_warn) THEN

      --処理が警告の場合

debug_log(FND_FILE.LOG,'B-3.依頼指示情報抽出 警告メッセージ：'||lv_errmsg);

      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);

      lb_warning_flg := TRUE;

    END IF;

--

debug_log(FND_FILE.LOG,'B-3.依頼指示情報抽出 終了ステータス＝'||lv_retcode);

    --B-3正常の場合のみ以下の処理を行う（警告：データなしの場合、以下の処理は行わない）

    IF (lv_retcode = gv_status_normal) THEN

--

      -- パラメータ.処理種別が「出荷依頼」または指定無しの場合のみ実施

      IF (iv_shipping_biz_type = gv_ship_type_ship)

        OR (iv_shipping_biz_type IS NULL)

      THEN

--

        -- ===============================

        -- B-4.拠点混載情報登録処理

        -- ===============================

        ins_hub_mixed_info(

             ov_errbuf  => lv_errbuf    -- エラー・メッセージ           --# 固定 #

           , ov_retcode => lv_retcode   -- リターン・コード             --# 固定 #

           , ov_errmsg  => lv_errmsg    -- ユーザー・エラー・メッセージ --# 固定 #

          );

        -- 処理がエラーの場合

        IF (lv_retcode = gv_status_error) THEN

          RAISE global_process_expt;

        END IF;

debug_log(FND_FILE.LOG,'B-4.拠点混載情報登録処理');

--

        -- ===============================

        -- B-5.積載効率チェック処理

        -- ===============================

        chk_loading_efficiency(

             ov_errbuf  => lv_errbuf    -- エラー・メッセージ           --# 固定 #

           , ov_retcode => lv_retcode   -- リターン・コード             --# 固定 #

           , ov_errmsg  => lv_errmsg    -- ユーザー・エラー・メッセージ --# 固定 #

          );

        -- 処理がエラーの場合

        IF (lv_retcode = gv_status_error) THEN

          RAISE global_process_expt;

        END IF;

--

      END IF;

debug_log(FND_FILE.LOG,'B-5.積載効率チェック処理');

--

      -- =======================================

      -- B-6.最大配送区分、重量容積区分取得処理

      -- =======================================

        get_max_shipping_method(

             ov_errbuf  => lv_errbuf    -- エラー・メッセージ           --# 固定 #

           , ov_retcode => lv_retcode   -- リターン・コード             --# 固定 #

           , ov_errmsg  => lv_errmsg    -- ユーザー・エラー・メッセージ --# 固定 #

          );

--

      -- 処理がエラーの場合

      IF (lv_retcode = gv_status_error) THEN

        RAISE global_process_expt;

      ELSIF (lv_retcode = gv_status_warn) THEN

        --処理が警告の場合

debug_log(FND_FILE.LOG,'B-6.最大配送区分、重量容積区分取得処理 警告メッセージ：'||lv_errmsg);

        lb_warning_flg := TRUE;

      END IF;

debug_log(FND_FILE.LOG,'B-6.最大配送区分、重量容積区分取得処理');

--

      -- =============================

      -- B-9.集約中間情報抽出処理

      -- =============================

        get_intensive_tmp(

             ov_errbuf  => lv_errbuf    -- エラー・メッセージ           --# 固定 #

           , ov_retcode => lv_retcode   -- リターン・コード             --# 固定 #

           , ov_errmsg  => lv_errmsg    -- ユーザー・エラー・メッセージ --# 固定 #

          );

--

      -- 処理がエラーの場合

      IF (lv_retcode = gv_status_error) THEN

        RAISE global_process_expt;

      END IF;

--

debug_log(FND_FILE.LOG,'B-9.集約中間情報抽出処理');

      -- ===============================

      -- B-14.配車配送計画アドオン出力

      -- ===============================

        ins_xxwsh_carriers_schedule(

             ov_errbuf  => lv_errbuf    -- エラー・メッセージ           --# 固定 #

           , ov_retcode => lv_retcode   -- リターン・コード             --# 固定 #

           , ov_errmsg  => lv_errmsg    -- ユーザー・エラー・メッセージ --# 固定 #

          );

--

      -- 処理がエラーの場合

      IF (lv_retcode = gv_status_error) THEN

        RAISE global_process_expt;

      ELSIF (lv_retcode = gv_status_warn) THEN

        --処理が警告の場合

        lb_warning_flg := TRUE;

      END IF;

--

debug_log(FND_FILE.LOG,'B-14.配車配送計画アドオン出力 ステータス＝ '||lv_retcode);

      -- ===============================

      -- B-15.依頼・指示情報更新処理

      -- ===============================

      upd_req_inst_info(

             ov_errbuf  => lv_errbuf    -- エラー・メッセージ           --# 固定 #

           , ov_retcode => lv_retcode   -- リターン・コード             --# 固定 #

           , ov_errmsg  => lv_errmsg    -- ユーザー・エラー・メッセージ --# 固定 #

          );

--

      -- 処理がエラーの場合

      IF (lv_retcode = gv_status_error) THEN

        RAISE global_process_expt;

      END IF;

--

    END IF; -- B-3正常なら

    --警告処理

    IF (lb_warning_flg) THEN

      ov_retcode := gv_status_warn; --いずれかの処理で警告なら警告終了

    END IF;

--

debug_log(FND_FILE.LOG,'B-15.依頼・指示情報更新処理');

    -- ===============================

    -- レポート出力処理

    -- ===============================

    -- 区切り文字列出力

    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);

--

    -- 入力パラメータ(見出し)

    lv_msg  := SUBSTRB(xxcmn_common_pkg.get_msg(

                  gv_xxwsh            -- モジュール名略称：XXCMN 共通

                , gv_msg_xxwsh_11806  -- メッセージ：APP-XXWSH-11806 入力パラメータ(見出し)

                ),1,5000);

--

    -- 入力パラメータ見出し出力

    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_msg);

--

    -- 入力パラメータ出力

    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_parameters);

--

    -- 区切り文字列出力

    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);

--

    -- 出荷依頼件数

    IF (gn_ship_cnt > 0) THEN

      lv_msg  := SUBSTRB(xxcmn_common_pkg.get_msg(

                    gv_xxwsh            -- モジュール名略称：XXCMN 共通

                  , gv_msg_xxwsh_11807  -- メッセージ：APP-XXWSH-11807 出荷依頼件数

                  , gv_tkn_count        -- トークン：COUNT

                  , gn_ship_cnt         -- 出荷依頼件数

                  ),1,5000);

      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_msg);

    END IF;

--

    IF (gn_move_cnt > 0) THEN

      -- 移動指示件数

      lv_msg  := SUBSTRB(xxcmn_common_pkg.get_msg(

                    gv_xxwsh            -- モジュール名略称：XXCMN 共通

                  , gv_msg_xxwsh_11808  -- メッセージ：APP-XXWSH-11808 出荷依頼件数

                  , gv_tkn_count        -- トークン：COUNT

                  , gn_move_cnt         -- 移動指示件数

                  ),1,5000);

      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_msg);

    END IF;

debug_log(FND_FILE.LOG,'レポート出力');

debug_log(FND_FILE.LOG,'終了ステータス＝ '||ov_retcode);

--

  EXCEPTION

      -- *** 任意で例外処理を記述する ****

      -- カーソルのクローズをここに記述する

    WHEN to_date_expt THEN

      -- エラーメッセージ取得

      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(

                      gv_xxwsh            -- モジュール名略称：XXWSH 出荷・引当/配車

                    , gv_msg_xxwsh_11809  -- メッセージ：APP-XXWSH-11809 入力パラメータ書式エラー

                    , gv_tkn_parm_name    -- トークン：PARM_NAME

                    , cv_date_To          -- パラメータ．出庫日To

                   ),1,5000);

      ov_errmsg  := lv_errmsg;

      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);

      ov_retcode := gv_status_error;

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

    errbuf                  OUT NOCOPY VARCHAR2,  -- エラー・メッセージ  --# 固定 #

    retcode                 OUT NOCOPY VARCHAR2,  -- リターン・コード    --# 固定 #

    iv_prod_class           IN  VARCHAR2,         --  1.商品区分

    iv_shipping_biz_type    IN  VARCHAR2,         --  2.処理種別

    iv_block_1              IN  VARCHAR2,         --  3.ブロック1

    iv_block_2              IN  VARCHAR2,         --  4.ブロック2

    iv_block_3              IN  VARCHAR2,         --  5.ブロック3

    iv_storage_code         IN  VARCHAR2,         --  6.出庫元

    iv_transaction_type_id  IN  VARCHAR2,         --  7.出庫形態ID

    iv_date_from            IN  VARCHAR2,         --  8.出庫日From

    iv_date_to              IN  VARCHAR2,         --  9.出庫日To

    iv_forwarder_id         IN  VARCHAR2,         -- 10.運送業者ID

-- 2009/01/27 H.Itou Add Start 本番障害#1028対応

    iv_instruction_dept     IN  VARCHAR2          -- 11.指示部署

-- 2009/01/27 H.Itou Add End

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

    -- ログ出力フラグ設定

    set_debug_switch();

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

--###########################  固定部 END   #############################

--

debug_log(FND_FILE.LOG,'MAIN');

debug_log(FND_FILE.LOG,'サブメイン呼出');

    -- ===============================================

    -- submainの呼び出し（実際の処理はsubmainで行う）

    -- ===============================================

    submain(

      iv_prod_class           => iv_prod_class,          --  1.商品区分

      iv_shipping_biz_type    => iv_shipping_biz_type,   --  2.処理種別

      iv_block_1              => iv_block_1,             --  3.ブロック1

      iv_block_2              => iv_block_2,             --  4.ブロック2

      iv_block_3              => iv_block_3,             --  5.ブロック3

      iv_storage_code         => iv_storage_code,        --  6.出庫元

      iv_transaction_type_id  => iv_transaction_type_id, --  7.出庫形態ID

      iv_date_from            => iv_date_from,           --  8.出庫日From

      iv_date_to              => iv_date_to,             --  9.出庫日To

      iv_forwarder_id         => iv_forwarder_id,        -- 10.運送業者ID

-- 2009/01/27 H.Itou Add Start 本番障害#1028対応

      iv_instruction_dept     => iv_instruction_dept,    -- 11.指示部署

-- 2009/01/27 H.Itou Add End

      ov_errbuf               => lv_errbuf,              -- エラー・メッセージ           --# 固定 #

      ov_retcode              => lv_retcode,             -- リターン・コード             --# 固定 #

      ov_errmsg               => lv_errmsg);             -- ユーザー・エラー・メッセージ --# 固定 #

--

--###########################  固定部 START   #####################################################

--

debug_log(FND_FILE.LOG,'エラーメッセージ出力');

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

debug_log(FND_FILE.LOG,'リターンコードセット、終了処理');

    -- ==================================

    -- リターン・コードのセット、終了処理

    -- ==================================

    --区切り文字列出力

    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);

--

    --処理件数出力

    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00008','CNT',TO_CHAR(gn_target_cnt));

    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);

--

    --成功件数出力

--    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00009','CNT',TO_CHAR(gn_normal_cnt));

--    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);

--

    --エラー件数出力

    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00010','CNT',TO_CHAR(gn_error_cnt));

    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);

--

    --スキップ件数出力

    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00011','CNT',TO_CHAR(gn_warn_cnt));

    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);

--

debug_log(FND_FILE.LOG,'ステータス出力');

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

-- Ver1.5 M.Hokkanji Start

-- 各中間テーブル作成処理でコミットを入れたためロールバックを実行するように変更

--  (配車配送計画作成後もしくは削除後にエラーとなった場合にロールバックするため

-- テスト中はROLLBACKはコメントアウト***************************************************

    --COMMIT;

    --終了ステータスがエラーの場合はROLLBACKする

    IF (retcode = gv_status_error) THEN

      ROLLBACK;

    END IF;

-- Ver1.5 M.Hokkanji End

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

END xxwsh600001c;

/

