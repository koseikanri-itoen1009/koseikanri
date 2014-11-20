/*************************************************************************
 * 
 * View  Name      : XXSKZ_出荷依頼締め_基本_V
 * Description     : XXSKZ_出荷依頼締め_基本_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2012/11/22    1.0   SCSK 月野    初回作成
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_出荷依頼締め_基本_V
(
 締めコンカレントID
,受注タイプ
,出荷元保管場所
,出荷元保管場所名
,商品区分
,商品区分名
,拠点
,拠点名
,拠点カテゴリ
,拠点カテゴリ名
,生産物流LT
,出荷予定日
,締め_解除区分
,締め_解除区分名
,締め実施日時
,基準レコード区分
,基準レコード区分名
,作成者
,作成日
,最終更新者
,最終更新日
,最終更新ログイン
)
AS
SELECT 
        XTC.concurrent_id                                       --締めコンカレントID
       ,CASE XTC.order_type_id                                  --受注タイプ
            WHEN    -999    THEN    'ALL'
            ELSE                    OTTT.name
        END                         transaction_type_name
       ,XTC.deliver_from                                        --出荷元保管場所
       ,XILV.description            deliver_from_name           --出荷元保管場所名
       ,XTC.prod_class                                          --商品区分
       ,FLV01.meaning               prod_class_name             --商品区分名
       ,XTC.sales_branch                                        --拠点
       ,XCA2V.party_name            sales_branch_name           --拠点名
       ,XTC.sales_branch_category                               --拠点カテゴリ
       ,FLV02.meaning               sales_branch_category_name  --拠点カテゴリ名
       ,CASE XTC.lead_time_day                                  --受注タイプ
            WHEN    -999    THEN    'ALL'                       --生産物流LT
            ELSE                    TO_CHAR(XTC.lead_time_day, 'FM9999')
        END                         lead_time_day
       ,XTC.schedule_ship_date                                  --出荷予定日
       ,XTC.tighten_release_class                               --締め_解除区分
       ,FLV03.meaning               tighten_release_class_name  --締め_解除区分名
       ,TO_CHAR( XTC.tightening_date, 'YYYY/MM/DD HH24:MI:SS')
                                                                --締め実施日時
       ,XTC.base_record_class                                   --基準レコード区分
       ,CASE XTC.base_record_class                              --基準レコード区分名
            WHEN    'Y' THEN    '基準レコード'
            WHEN    'N' THEN    'それ以外'
        END                         base_record_class_name
       ,FU_CB.user_name             created_by_name             --CREATED_BYのユーザー名(ログイン時の入力コード)
       ,TO_CHAR( XTC.creation_date, 'YYYY/MM/DD HH24:MI:SS')
                                    creation_date               --作成日時
       ,FU_LU.user_name             last_updated_by_name        --LAST_UPDATED_BYのユーザー名(ログイン時の入力コード)
       ,TO_CHAR( XTC.last_update_date, 'YYYY/MM/DD HH24:MI:SS')
                                    last_update_date            --更新日時
       ,FU_LL.user_name             last_update_login_name      --LAST_UPDATE_LOGINのユーザー名(ログイン時の入力コード)
  FROM  xxwsh_tightening_control    XTC                         --出荷依頼締め管理（アドオン）
       ,oe_transaction_types_tl     OTTT                        --受注タイプ名取得用
       ,xxskz_item_locations_v      XILV                        --SKYLINK用中間VIEW 出荷元保管場所名取得VIEW
       ,xxskz_cust_accounts2_v      XCA2V                       --SKYLINK用中間VIEW 拠点名取得VIEW
       ,fnd_lookup_values           FLV01                       --商品区分名取得用
       ,fnd_lookup_values           FLV02                       --拠点カテゴリ名取得用
       ,fnd_lookup_values           FLV03                       --締め_解除区分名取得用
       ,fnd_user                    FU_CB                       --ユーザーマスタ(CREATED_BY名称取得用)
       ,fnd_user                    FU_LU                       --ユーザーマスタ(LAST_UPDATE_BY名称取得用)
       ,fnd_user                    FU_LL                       --ユーザーマスタ(LAST_UPDATE_LOGIN名称取得用)
       ,fnd_logins                  FL_LL                       --ログインマスタ(LAST_UPDATE_LOGIN名称取得用)
 WHERE
    --受注タイプ名(出庫形態)取得条件
        OTTT.language(+)            = 'JA'
   AND  OTTT.transaction_type_id(+) =  XTC.order_type_id
    --出荷元保管場所名取得条件
   AND  XILV.segment1(+)            =  XTC.deliver_from
    --拠点名取得条件
   AND  XCA2V.party_number(+)       =  XTC.sales_branch
   AND  XCA2V.start_date_active(+)  <= XTC.tightening_date
   AND  XCA2V.end_date_active(+)    >= XTC.tightening_date
    --商品区分名取得条件
   AND  FLV01.language(+)           =  'JA'
   AND  FLV01.lookup_type(+)        =  'XXWIP_ITEM_TYPE'
   AND  FLV01.lookup_code(+)        =  XTC.prod_class
   --拠点カテゴリ名取得条件
   AND  FLV02.language(+)           =  'JA'
   AND  FLV02.lookup_type(+)        =  'XXWSH_DRINK_BASE_CATEGORY'
   AND  FLV02.lookup_code(+)        =  XTC.sales_branch_category
    --締め_解除区分名取得条件
   AND  FLV03.language(+)           =  'JA'
   AND  FLV03.lookup_type(+)        =  'XXWSH_TIGHTEN_RELEASE_CLASS'
   AND  FLV03.lookup_code(+)        =  XTC.tighten_release_class
   --WHOカラム取得
   AND  XTC.created_by              =  FU_CB.user_id(+)
   AND  XTC.last_updated_by         =  FU_LU.user_id(+)
   AND  XTC.last_update_login       =  FL_LL.login_id(+)
   AND  FL_LL.user_id               =  FU_LL.user_id(+)
/
COMMENT ON TABLE APPS.XXSKZ_出荷依頼締め_基本_V                     IS 'SKYLINK用出荷依頼締め（基本）VIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷依頼締め_基本_V.締めコンカレントID IS '締めコンカレントID'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷依頼締め_基本_V.受注タイプ         IS '受注タイプ'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷依頼締め_基本_V.出荷元保管場所     IS '出荷元保管場所'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷依頼締め_基本_V.出荷元保管場所名   IS '出荷元保管場所名'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷依頼締め_基本_V.商品区分           IS '商品区分'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷依頼締め_基本_V.商品区分名         IS '商品区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷依頼締め_基本_V.拠点               IS '拠点'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷依頼締め_基本_V.拠点名             IS '拠点名'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷依頼締め_基本_V.拠点カテゴリ       IS '拠点カテゴリ'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷依頼締め_基本_V.拠点カテゴリ名     IS '拠点カテゴリ名'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷依頼締め_基本_V.生産物流LT         IS '生産物流LT'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷依頼締め_基本_V.出荷予定日         IS '出荷予定日'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷依頼締め_基本_V.締め_解除区分      IS '締め_解除区分'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷依頼締め_基本_V.締め_解除区分名    IS '締め_解除区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷依頼締め_基本_V.締め実施日時       IS '締め実施日時'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷依頼締め_基本_V.基準レコード区分   IS '基準レコード区分'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷依頼締め_基本_V.基準レコード区分名 IS '基準レコード区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷依頼締め_基本_V.作成者             IS '作成者'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷依頼締め_基本_V.作成日             IS '作成日'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷依頼締め_基本_V.最終更新者         IS '最終更新者'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷依頼締め_基本_V.最終更新日         IS '最終更新日'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷依頼締め_基本_V.最終更新ログイン   IS '最終更新ログイン'
/                                                                       
