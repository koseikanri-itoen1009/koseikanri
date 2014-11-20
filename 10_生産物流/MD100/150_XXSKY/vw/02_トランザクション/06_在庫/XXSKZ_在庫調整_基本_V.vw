/*************************************************************************
 * 
 * View  Name      : XXSKZ_在庫調整_基本_V
 * Description     : XXSKZ_在庫調整_基本_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2012/11/27    1.0   SCSK 月野    初回作成
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_在庫調整_基本_V
(
 入出庫区分
,事由コード
,事由コード名
,倉庫コード
,保管場所コード
,保管場所名
,保管場所略称
,商品区分
,商品区分名
,品目区分
,品目区分名
,群コード
,品目コード
,品目名
,品目略称
,単位
,ロットNo
,製造年月日
,固有記号
,賞味期限
,在庫調整用摘要
,伝票No
,入出庫日
,入庫数
,入庫ケース数
,出庫数
,出庫ケース数
,作成者
,作成日
,最終更新者
,最終更新日
,最終更新ログイン
)
AS
SELECT  ZTIO.inout_kbn                      inout_kbn              -- 入出庫区分
       ,ZTIO.reason_code                    reason_code            -- 事由コード
       ,FLV01.meaning                       reason_code_name       -- 事由コード名
       ,ZTIO.whse_code                      whse_code              -- 倉庫コード
       ,ZTIO.loct_code                      location_code          -- 保管場所コード
       ,XILV.description                    location_name          -- 保管場所名
       ,XILV.short_name                     location_s_name        -- 保管場所略称
       ,XPCV.prod_class_code                prod_class_code        -- 商品区分
       ,XPCV.prod_class_name                prod_class_name        -- 商品区分名
       ,XICV.item_class_code                item_class_code        -- 品目区分
       ,XICV.item_class_name                item_class_name        -- 品目区分名
       ,XCCV.crowd_code                     crowd_code             -- 群コード
       ,XIMV2.item_no                       item_no                -- 品目コード
       ,XIMV2.item_name                     item_name              -- 品目名
       ,XIMV2.item_short_name               item_s_name            -- 品目略称
       ,IIMB.item_um                        item_um                -- 単位
       ,ILM.lot_no                          lot_no                 -- ロットNo
       ,ILM.attribute1                      manufacture_date       -- 製造年月日
       ,ILM.attribute2                      uniqe_sign             -- 固有記号
       ,ILM.attribute3                      expiration_date        -- 賞味期限
       ,ZTIO.attribute2                     attribute2             -- 在庫調整用摘要
       ,ZTIO.journal_no                     voucher_no             -- 伝票No
       ,ZTIO.tran_date                      standard_date          -- 入出庫日
       ,NVL( ZTIO.stock_quantity, 0)        stock_quantity         -- 入庫数
       ,NVL( TRUNC( ZTIO.stock_quantity / XIMV2.num_of_cases ) , 0)
                                            stock_cs_quantity      -- 入庫ケース数
       ,NVL( ZTIO.leaving_quantity, 0)      leaving_quantity       -- 出庫数
       ,NVL( TRUNC( ZTIO.leaving_quantity / XIMV2.num_of_cases ) , 0)
                                            leaving_cs_quantity    -- 出庫ケース数
       ,FU_CB.user_name                     created_by             -- 作成者
       ,TO_CHAR( ZTIO.creation_date, 'YYYY/MM/DD HH24:MI:SS' )
                                            creation_date          -- 作成日
       ,FU_LU.user_name                     last_updated_by        -- 最終更新者
       ,TO_CHAR( ZTIO.last_update_date, 'YYYY/MM/DD HH24:MI:SS' )
                                            last_update_date       -- 最終更新日
       ,FU_LL.user_name                     last_update_login      -- 最終更新ログイン
  FROM
       (  -- ■■ 在庫調整(入庫) ■■
           SELECT
                   '入庫'                             inout_kbn                 -- 入出庫区分(入庫)
                  ,XRPM.new_div_invent                reason_code               -- 事由コード
                  ,IJM.journal_no                     journal_no                -- 伝票No
                  ,ITC.whse_code                      whse_code                 -- 倉庫コード
                  ,ITC.location                       loct_code                 -- 保管場所コード
                  ,ITC.trans_date                     tran_date                 -- 入出庫日
                  ,ITC.item_id                        item_id                   -- 品目ID
                  ,ITC.lot_id                         lot_id                    -- ロットID
                  ,IJM.attribute2                     attribute2                -- 在庫調整用摘要
                  ,ITC.trans_qty                      stock_quantity            -- 入庫数
                  ,0                                  leaving_quantity          -- 出庫数
                   --WHOカラム
                  ,ITC.created_by                     created_by                -- 作成者
                  ,ITC.creation_date                  creation_date             -- 作成日
                  ,ITC.last_updated_by                last_updated_by           -- 最終更新者
                  ,ITC.last_update_date               last_update_date          -- 最終更新日
                  ,ITC.last_update_login              last_update_login         -- 最終更新ログイン
             FROM
                   xxcmn_rcv_pay_mst                  XRPM                      -- 受払区分アドオンマスタ
                  ,ic_adjs_jnl                        IAJ                       -- OPM在庫調整ジャーナル
                  ,ic_jrnl_mst                        IJM                       -- OPMジャーナルマスタ
                  ,xxcmn_ic_tran_cmp_arc                        ITC              -- OPM完了在庫トランザクション（標準）バックアップ
            WHERE
              -- 受払区分アドオンマスタの条件
                   XRPM.doc_type           = 'ADJI'
              AND  XRPM.reason_code        <> 'X977'                            -- 相手先在庫
              AND  XRPM.reason_code        <> 'X988'                            -- 浜岡入庫
              AND  XRPM.reason_code        <> 'X123'                            -- 移動実績訂正（出庫）
              AND  XRPM.reason_code        <> 'X201'                            -- 仕入先返品
              AND  XRPM.rcv_pay_div        = '1'                                -- 受入
              AND  XRPM.use_div_invent     = 'Y'
              -- OPM完了在庫トランザクションとの結合
              AND  ITC.doc_type            = XRPM.doc_type
              AND  ITC.reason_code         = XRPM.reason_code
              -- OPM在庫調整ジャーナルとの結合
              AND  ITC.doc_type            = IAJ.trans_type
              AND  ITC.doc_id              = IAJ.doc_id
              AND  ITC.doc_line            = IAJ.doc_line
              -- OPMジャーナルマスタとの結合
              AND  IAJ.journal_id          = IJM.journal_id
          -- ■■ 在庫調整(入庫) END ■■
        UNION ALL
          -- ■■ 在庫調整(出庫) ■■
           SELECT
                   '出庫'                             inout_kbn                 -- 入出庫区分(出庫)
                  ,XRPM.new_div_invent                reason_code               -- 事由コード
                  ,IJM.journal_no                     journal_no                -- 伝票No
                  ,ITC.whse_code                      whse_code                 -- 倉庫コード
                  ,ITC.location                       loct_code                 -- 保管場所コード
                  ,ITC.trans_date                     tran_date                 -- 入出庫日
                  ,ITC.item_id                        item_id                   -- 品目ID
                  ,ITC.lot_id                         lot_id                    -- ロットID
                  ,IJM.attribute2                     attribute2                -- 在庫調整用摘要
                  ,0                                  stock_quantity            -- 入庫数
                  ,ITC.trans_qty * -1                 leaving_quantity          -- 出庫数
                   --WHOカラム
                  ,ITC.created_by                     created_by                -- 作成者
                  ,ITC.creation_date                  creation_date             -- 作成日
                  ,ITC.last_updated_by                last_updated_by           -- 最終更新者
                  ,ITC.last_update_date               last_update_date          -- 最終更新日
                  ,ITC.last_update_login              last_update_login         -- 最終更新ログイン
             FROM
                   xxcmn_rcv_pay_mst                  XRPM                      -- 受払区分アドオンマスタ
                  ,ic_adjs_jnl                        IAJ                       -- OPM在庫調整ジャーナル
                  ,ic_jrnl_mst                        IJM                       -- OPMジャーナルマスタ
                  ,xxcmn_ic_tran_cmp_arc                        ITC             -- OPM完了在庫トランザクション（標準）バックアップ
            WHERE
              --受払区分アドオンマスタの条件
                   XRPM.doc_type          = 'ADJI'
              AND  XRPM.reason_code      <> 'X977'                  -- 相手先在庫
              AND  XRPM.reason_code      <> 'X123'                  -- 移動実績訂正（入庫）
              AND  XRPM.rcv_pay_div       = '-1'                    -- 払出
              AND  XRPM.use_div_invent    = 'Y'
              --完了在庫トランザクションの条件
              AND  ITC.doc_type           = XRPM.doc_type
              AND  ITC.reason_code        = XRPM.reason_code
              --在庫調整ジャーナルの取得
              AND  ITC.doc_type           = IAJ.trans_type
              AND  ITC.doc_id             = IAJ.doc_id
              AND  ITC.doc_line           = IAJ.doc_line
              --ジャーナルマスタの取得
              AND  IAJ.journal_id         = IJM.journal_id
          --■■ 在庫調整(出庫) END ■■
        )                                             ZTIO
       ,xxskz_item_locations_v                        XILV                      -- OPM保管場所情報VIEW
       ,xxskz_prod_class_v                            XPCV                      -- 商品区分取得VIEW
       ,xxskz_item_class_v                            XICV                      -- 品目区分取得VIEW
       ,xxskz_crowd_code_v                            XCCV                      -- 群コード取得VIEW
       ,xxskz_item_mst2_v                             XIMV2                     -- OPM品目情報VIEW2
       ,ic_item_mst_b                                 IIMB                      -- OPM品目マスタ
       ,ic_lots_mst                                   ILM                       -- ロットマスタ
       ,fnd_user                                      FU_CB                     -- ユーザーマスタ(CREATED_BY名称取得用)
       ,fnd_user                                      FU_LU                     -- ユーザーマスタ(LAST_UPDATE_BY名称取得用)
       ,fnd_user                                      FU_LL                     -- ユーザーマスタ(LAST_UPDATE_LOGIN名称取得用)
       ,fnd_logins                                    FL_LL                     -- ログインマスタ(LAST_UPDATE_LOGIN名称取得用)
       ,fnd_lookup_values                             FLV01                     -- クイックコード(事由コード名称取得用)
 WHERE
   -- OPM保管場所情報取得
        ZTIO.loct_code                                = XILV.segment1(+)
   -- 品目カテゴリ情報取得条件
   AND  ZTIO.item_id                                  = XPCV.item_id(+)
   AND  ZTIO.item_id                                  = XICV.item_id(+)
   AND  ZTIO.item_id                                  = XCCV.item_id(+)
   -- OPM品目情報取得
   AND  ZTIO.item_id                                  = XIMV2.item_id(+)
   AND  ZTIO.tran_date                               >= XIMV2.start_date_active(+)
   AND  ZTIO.tran_date                               <= XIMV2.end_date_active(+)
   -- OPM品目マスタ情報取得
   AND  ZTIO.item_id                                  = IIMB.item_id(+)
   -- OPMロットマスタ取得
   AND  ZTIO.item_id                                  = ILM.item_id(+)
   AND  ZTIO.lot_id                                   = ILM.lot_id(+)
   -- WHOカラム取得
   AND  ZTIO.created_by                               = FU_CB.user_id(+)
   AND  ZTIO.last_updated_by                          = FU_LU.user_id(+)
   AND  ZTIO.last_update_login                        = FL_LL.login_id(+)
   AND  FL_LL.user_id                                 = FU_LL.user_id(+)
   -- クイックコード(事由コード取得)
   AND  FLV01.lookup_type(+)                          = 'XXCMN_NEW_DIVISION'
   AND  FLV01.language(+)                             = 'JA'
   AND  FLV01.lookup_code(+)                          = ZTIO.reason_code
/
COMMENT ON TABLE APPS.XXSKZ_在庫調整_基本_V IS 'SKYLINK用在庫調整（基本）VIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_在庫調整_基本_V.入出庫区分                    IS '入出庫区分'
/
COMMENT ON COLUMN APPS.XXSKZ_在庫調整_基本_V.事由コード                    IS '事由コード'
/
COMMENT ON COLUMN APPS.XXSKZ_在庫調整_基本_V.事由コード名                  IS '事由コード名'
/
COMMENT ON COLUMN APPS.XXSKZ_在庫調整_基本_V.倉庫コード                    IS '倉庫コード'
/
COMMENT ON COLUMN APPS.XXSKZ_在庫調整_基本_V.保管場所コード                IS '保管場所コード'
/
COMMENT ON COLUMN APPS.XXSKZ_在庫調整_基本_V.保管場所名                    IS '保管場所名'
/
COMMENT ON COLUMN APPS.XXSKZ_在庫調整_基本_V.保管場所略称                  IS '保管場所略称'
/
COMMENT ON COLUMN APPS.XXSKZ_在庫調整_基本_V.商品区分                      IS '商品区分'
/
COMMENT ON COLUMN APPS.XXSKZ_在庫調整_基本_V.商品区分名                    IS '商品区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_在庫調整_基本_V.品目区分                      IS '品目区分'
/
COMMENT ON COLUMN APPS.XXSKZ_在庫調整_基本_V.品目区分名                    IS '品目区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_在庫調整_基本_V.群コード                      IS '群コード'
/
COMMENT ON COLUMN APPS.XXSKZ_在庫調整_基本_V.品目コード                    IS '品目コード'
/
COMMENT ON COLUMN APPS.XXSKZ_在庫調整_基本_V.品目名                        IS '品目名'
/
COMMENT ON COLUMN APPS.XXSKZ_在庫調整_基本_V.品目略称                      IS '品目略称'
/
COMMENT ON COLUMN APPS.XXSKZ_在庫調整_基本_V.単位                          IS '単位'
/
COMMENT ON COLUMN APPS.XXSKZ_在庫調整_基本_V.ロットNo                      IS 'ロットNo'
/
COMMENT ON COLUMN APPS.XXSKZ_在庫調整_基本_V.製造年月日                    IS '製造年月日'
/
COMMENT ON COLUMN APPS.XXSKZ_在庫調整_基本_V.固有記号                      IS '固有記号'
/
COMMENT ON COLUMN APPS.XXSKZ_在庫調整_基本_V.賞味期限                      IS '賞味期限'
/
COMMENT ON COLUMN APPS.XXSKZ_在庫調整_基本_V.在庫調整用摘要                IS '在庫調整用摘要'
/
COMMENT ON COLUMN APPS.XXSKZ_在庫調整_基本_V.伝票No                        IS '伝票No'
/
COMMENT ON COLUMN APPS.XXSKZ_在庫調整_基本_V.入出庫日                      IS '入出庫日'
/
COMMENT ON COLUMN APPS.XXSKZ_在庫調整_基本_V.入庫数                        IS '入庫数'
/
COMMENT ON COLUMN APPS.XXSKZ_在庫調整_基本_V.入庫ケース数                  IS '入庫ケース数'
/
COMMENT ON COLUMN APPS.XXSKZ_在庫調整_基本_V.出庫数                        IS '出庫数'
/
COMMENT ON COLUMN APPS.XXSKZ_在庫調整_基本_V.出庫ケース数                  IS '出庫ケース数'
/
COMMENT ON COLUMN APPS.XXSKZ_在庫調整_基本_V.作成者                        IS '作成者'
/
COMMENT ON COLUMN APPS.XXSKZ_在庫調整_基本_V.作成日                        IS '作成日'
/
COMMENT ON COLUMN APPS.XXSKZ_在庫調整_基本_V.最終更新者                    IS '最終更新者'
/
COMMENT ON COLUMN APPS.XXSKZ_在庫調整_基本_V.最終更新日                    IS '最終更新日'
/
COMMENT ON COLUMN APPS.XXSKZ_在庫調整_基本_V.最終更新ログイン              IS '最終更新ログイン'
/
