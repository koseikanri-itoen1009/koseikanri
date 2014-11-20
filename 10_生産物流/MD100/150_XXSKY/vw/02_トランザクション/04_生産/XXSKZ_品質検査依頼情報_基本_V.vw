/*************************************************************************
 * 
 * View  Name      : XXSKZ_品質検査依頼情報_基本_V
 * Description     : XXSKZ_品質検査依頼情報_基本_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------  -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------  -------------------------------------
 *  2012/11/26    1.0   SCSK M.Nagai 初回作成
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_品質検査依頼情報_基本_V
(
 検査依頼NO
,検査種別
,検査種別名
,商品区分
,商品区分名
,品目区分
,品目区分名
,群コード
,品目コード
,品目名
,品目略称
,ロットNO
,区分
,区分名
,仕入先コード
,仕入先名
,ラインNO
,ライン名
,製造日
,固有記号
,賞味期限
,検査期間
,数量
,納入日
,検査予定日１
,検査日１
,結果１
,結果名１
,検査予定日２
,検査日２
,結果２
,結果名２
,検査予定日３
,検査日３
,結果３
,結果名３
,備考
,作成者
,作成日
,最終更新者
,最終更新日
,最終更新ログイン
)
AS
SELECT
        XQI.qt_inspect_req_no                               --検査依頼No
       ,XQI.inspect_class                                   --検査種別
       ,CASE XQI.inspect_class                              --検査種別名
            WHEN    '1' THEN    '生産'
            WHEN    '2' THEN    '発注仕入'
        END                     inspect_name
       ,XPCV.prod_class_code                                --商品区分
       ,XPCV.prod_class_name                                --商品区分名
       ,XICV.item_class_code                                --品目区分
       ,XICV.item_class_name                                --品目区分名
       ,XCCV.crowd_code                                     --群コード
       ,XIM2V.item_no                                       --品目コード
       ,XIM2V.item_name                                     --品目名
       ,XIM2V.item_short_name                               --品目略称
       ,ILM.lot_no                                          --ロットNo
       ,XQI.division                                        --区分
       ,CASE XQI.division                                   --区分名
            WHEN    '1' THEN    '生産'
            WHEN    '2' THEN    '発注'
            WHEN    '3' THEN    'ロット情報'
            WHEN    '4' THEN    '外注出来高'
            WHEN    '5' THEN    '荒茶製造'
        END                     division_name
       ,CASE XQI.division                                   --仕入先コード
            WHEN    '1' THEN    NULL
            ELSE                XQI.vendor_line
        END                     vendor_line
       ,CASE XQI.division                                   --仕入先名
            WHEN    '1' THEN    NULL
            ELSE                XV2V.vendor_name
        END                     vendor_name
       ,CASE XQI.division                                   --ラインNo
            WHEN    '1' THEN    XQI.vendor_line
            ELSE                NULL
        END                     line_no
       ,CASE XQI.division                                   --ライン名
            WHEN    '1' THEN    GRT.routing_desc
            ELSE                NULL
        END                     line_name
       ,ILM.attribute1                                      --製造日
       ,ILM.attribute2                                      --固有記号
       ,ILM.attribute3                                      --賞味期限
       ,XQI.inspect_period                                  --検査期間
       ,XQI.qty                                             --数量日
       ,XQI.prod_dely_date                                  --納入日
       ,XQI.inspect_due_date1                               --検査予定日１
       ,XQI.test_date1                                      --検査日１
       ,XQI.qt_effect1                                      --結果１
       ,FLV01.meaning           qt_effect_name1             --結果名１２
       ,XQI.inspect_due_date2                               --検査予定日２
       ,XQI.test_date2                                      --検査日２
       ,XQI.qt_effect2                                      --結果２
       ,FLV02.meaning           qt_effect_name2             --結果名２３
       ,XQI.inspect_due_date3                               --検査予定日３
       ,XQI.test_date3                                      --検査日３
       ,XQI.qt_effect3                                      --結果３
       ,FLV03.meaning           qt_effect_name3             --結果名３
       ,ILM.attribute18                                     --備考
       ,FU_CB.user_name         created_by_name             --CREATED_BYのユーザー名(ログイン時の入力コード)
       ,TO_CHAR( XQI.creation_date, 'YYYY/MM/DD HH24:MI:SS')
                                creation_date               --作成日時
       ,FU_LU.user_name         last_updated_by_name        --LAST_UPDATED_BYのユーザー名(ログイン時の入力コード)
       ,TO_CHAR( XQI.last_update_date, 'YYYY/MM/DD HH24:MI:SS')
                                last_update_date            --更新日時
       ,FU_LL.user_name         last_update_login_name      --LAST_UPDATE_LOGINのユーザー名(ログイン時の入力コード)
  FROM  xxwip_qt_inspection     XQI                         --品質検査依頼情報アドオン
       ,xxskz_prod_class_v      XPCV                        --SKYLINK用中間VIEW 商品区分取得VIEW
       ,xxskz_item_class_v      XICV                        --SKYLINK用中間VIEW 品目商品区分取得VIEW
       ,xxskz_crowd_code_v      XCCV                        --SKYLINK用中間VIEW 群コード取得VIEW
       ,xxskz_item_mst2_v       XIM2V                       --SKYLINK用中間VIEW OPM品目情報VIEW2
       ,ic_lots_mst             ILM                         --ロットNo取得用
       ,xxskz_vendors2_v        XV2V                        --SKYLINK用中間VIEW 仕入先取得VIEW
       ,gmd_routings_b          GRB                         --ライン名取得用
       ,gmd_routings_tl         GRT                         --ライン名取得用
       ,fnd_lookup_values       FLV01                       --結果名１取得用
       ,fnd_lookup_values       FLV02                       --結果名２取得用
       ,fnd_lookup_values       FLV03                       --結果名３名取得用
       ,fnd_user                FU_CB                       --ユーザーマスタ(CREATED_BY名称取得用)
       ,fnd_user                FU_LU                       --ユーザーマスタ(LAST_UPDATE_BY名称取得用)
       ,fnd_user                FU_LL                       --ユーザーマスタ(LAST_UPDATE_LOGIN名称取得用)
       ,fnd_logins              FL_LL                       --ログインマスタ(LAST_UPDATE_LOGIN名称取得用)
 WHERE
    --品目コード、品目名、品目略称取得条件
        XIM2V.item_id(+)            =  XQI.item_id
   AND  XIM2V.start_date_active(+)  <= NVL(XQI.product_date, TRUNC(SYSDATE))
   AND  XIM2V.end_date_active(+)    >= NVL(XQI.product_date, TRUNC(SYSDATE))
    --商品区分、商品区分名取得条件
   AND  XPCV.item_id(+)             =  XQI.item_id
    --品目区分、品目区分名取得条件
   AND  XICV.item_id(+)             =  XQI.item_id
    --群コード取得条件
   AND  XCCV.item_id(+)             =  XQI.item_id
    --ロットNo取得条件
   AND  ILM.item_id(+)              =  XQI.item_id
   AND  ILM.lot_id(+)               =  XQI.lot_id
    --仕入先名取得条件
   AND  XV2V.segment1(+)            =  XQI.vendor_line
   AND  XV2V.start_date_active(+)   <= NVL(XQI.product_date, TRUNC(SYSDATE))
   AND  XV2V.end_date_active(+)     >= NVL(XQI.product_date, TRUNC(SYSDATE))
    --ライン名取得条件
   AND  GRB.routing_no(+)           =  XQI.vendor_line
   AND  GRB.routing_vers(+)         =  1
   AND  GRT.language(+)             =  'JA'
   AND  GRT.routing_id(+)           =  GRB.routing_id
    --結果名１取得条件
   AND  FLV01.language(+)           = 'JA'
   AND  FLV01.lookup_type(+)        = 'XXWIP_QT_STATUS'
   AND  FLV01.lookup_code(+)        = XQI.qt_effect1
    --結果名２取得条件
   AND  FLV02.language(+)           = 'JA'
   AND  FLV02.lookup_type(+)        = 'XXWIP_QT_STATUS'
   AND  FLV02.lookup_code(+)        = XQI.qt_effect2
    --結果名３取得条件
   AND  FLV03.language(+)           = 'JA'
   AND  FLV03.lookup_type(+)        = 'XXWIP_QT_STATUS'
   AND  FLV03.lookup_code(+)        = XQI.qt_effect3
   --WHOカラム取得
   AND  XQI.created_by              = FU_CB.user_id(+)
   AND  XQI.last_updated_by         = FU_LU.user_id(+)
   AND  XQI.last_update_login       = FL_LL.login_id(+)
   AND  FL_LL.user_id               = FU_LL.user_id(+)
/
COMMENT ON TABLE APPS.XXSKZ_品質検査依頼情報_基本_V IS 'SKYLINK用品質検査依頼情報（基本）VIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_品質検査依頼情報_基本_V.検査依頼NO IS '検査依頼No'
/
COMMENT ON COLUMN APPS.XXSKZ_品質検査依頼情報_基本_V.検査種別 IS '検査種別'
/
COMMENT ON COLUMN APPS.XXSKZ_品質検査依頼情報_基本_V.検査種別名 IS '検査種別名'
/
COMMENT ON COLUMN APPS.XXSKZ_品質検査依頼情報_基本_V.商品区分 IS '商品区分'
/
COMMENT ON COLUMN APPS.XXSKZ_品質検査依頼情報_基本_V.商品区分名 IS '商品区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_品質検査依頼情報_基本_V.品目区分 IS '品目区分'
/
COMMENT ON COLUMN APPS.XXSKZ_品質検査依頼情報_基本_V.品目区分名 IS '品目区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_品質検査依頼情報_基本_V.群コード IS '群コード'
/
COMMENT ON COLUMN APPS.XXSKZ_品質検査依頼情報_基本_V.品目コード IS '品目コード'
/
COMMENT ON COLUMN APPS.XXSKZ_品質検査依頼情報_基本_V.品目名 IS '品目名'
/
COMMENT ON COLUMN APPS.XXSKZ_品質検査依頼情報_基本_V.品目略称 IS '品目略称'
/
COMMENT ON COLUMN APPS.XXSKZ_品質検査依頼情報_基本_V.ロットNO IS 'ロットNo'
/
COMMENT ON COLUMN APPS.XXSKZ_品質検査依頼情報_基本_V.区分 IS '区分'
/
COMMENT ON COLUMN APPS.XXSKZ_品質検査依頼情報_基本_V.区分名 IS '区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_品質検査依頼情報_基本_V.仕入先コード IS '仕入先コード'
/
COMMENT ON COLUMN APPS.XXSKZ_品質検査依頼情報_基本_V.仕入先名 IS '仕入先名'
/
COMMENT ON COLUMN APPS.XXSKZ_品質検査依頼情報_基本_V.ラインNO IS 'ラインNo'
/
COMMENT ON COLUMN APPS.XXSKZ_品質検査依頼情報_基本_V.ライン名 IS 'ライン名'
/
COMMENT ON COLUMN APPS.XXSKZ_品質検査依頼情報_基本_V.製造日 IS '製造日'
/
COMMENT ON COLUMN APPS.XXSKZ_品質検査依頼情報_基本_V.固有記号 IS '固有記号'
/
COMMENT ON COLUMN APPS.XXSKZ_品質検査依頼情報_基本_V.賞味期限 IS '賞味期限'
/
COMMENT ON COLUMN APPS.XXSKZ_品質検査依頼情報_基本_V.検査期間 IS '検査期間'
/
COMMENT ON COLUMN APPS.XXSKZ_品質検査依頼情報_基本_V.数量 IS '数量'
/
COMMENT ON COLUMN APPS.XXSKZ_品質検査依頼情報_基本_V.納入日 IS '納入日'
/
COMMENT ON COLUMN APPS.XXSKZ_品質検査依頼情報_基本_V.検査予定日１ IS '検査予定日１'
/
COMMENT ON COLUMN APPS.XXSKZ_品質検査依頼情報_基本_V.検査日１ IS '検査日１'
/
COMMENT ON COLUMN APPS.XXSKZ_品質検査依頼情報_基本_V.結果１ IS '結果１'
/
COMMENT ON COLUMN APPS.XXSKZ_品質検査依頼情報_基本_V.結果名１ IS '結果名１'
/
COMMENT ON COLUMN APPS.XXSKZ_品質検査依頼情報_基本_V.検査予定日２ IS '検査予定日２'
/
COMMENT ON COLUMN APPS.XXSKZ_品質検査依頼情報_基本_V.検査日２ IS '検査日２'
/
COMMENT ON COLUMN APPS.XXSKZ_品質検査依頼情報_基本_V.結果２ IS '結果２'
/
COMMENT ON COLUMN APPS.XXSKZ_品質検査依頼情報_基本_V.結果名２ IS '結果名２'
/
COMMENT ON COLUMN APPS.XXSKZ_品質検査依頼情報_基本_V.検査予定日３ IS '検査予定日３'
/
COMMENT ON COLUMN APPS.XXSKZ_品質検査依頼情報_基本_V.検査日３ IS '検査日３'
/
COMMENT ON COLUMN APPS.XXSKZ_品質検査依頼情報_基本_V.結果３ IS '結果３'
/
COMMENT ON COLUMN APPS.XXSKZ_品質検査依頼情報_基本_V.結果名３ IS '結果名３'
/
COMMENT ON COLUMN APPS.XXSKZ_品質検査依頼情報_基本_V.備考 IS '備考'
/
COMMENT ON COLUMN APPS.XXSKZ_品質検査依頼情報_基本_V.作成者 IS '作成者'
/
COMMENT ON COLUMN APPS.XXSKZ_品質検査依頼情報_基本_V.作成日 IS '作成日'
/
COMMENT ON COLUMN APPS.XXSKZ_品質検査依頼情報_基本_V.最終更新者 IS '最終更新者'
/
COMMENT ON COLUMN APPS.XXSKZ_品質検査依頼情報_基本_V.最終更新日 IS '最終更新日'
/
COMMENT ON COLUMN APPS.XXSKZ_品質検査依頼情報_基本_V.最終更新ログイン IS '最終更新ログイン'
/
