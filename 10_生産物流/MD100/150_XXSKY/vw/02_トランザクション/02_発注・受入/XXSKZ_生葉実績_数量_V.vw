/*************************************************************************
 * 
 * View  Name      : XXSKZ_生葉実績_数量_V
 * Description     : XXSKZ_生葉実績_数量_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2012/11/21    1.0   SCSK 月野    初回作成
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_生葉実績_数量_V
(
 伝票NO
,荒茶商品区分
,荒茶商品区分名
,荒茶品目区分
,荒茶品目区分名
,荒茶群コード
,荒茶品目コード
,荒茶品目名
,荒茶品目略称
,荒茶ロットNO
,荒茶製造年月日
,荒茶固有記号
,荒茶賞味期限
,仕上数量
,仕上単位
,入庫先コード
,入庫先名
,荷印
,備考
,集荷１数量
,集荷２数量
,受入１数量
,受入２数量
,出荷数量
,副産物１品目コード
,副産物１品目名
,副産物１品目略称
,副産物１ロットNO
,副産物１製造年月日
,副産物１固有記号
,副産物１賞味期限
,副産物１数量
,副産物１単位
,副産物２品目コード
,副産物２品目名
,副産物２品目略称
,副産物２ロットNO
,副産物２製造年月日
,副産物２固有記号
,副産物２賞味期限
,副産物２数量
,副産物２単位
,副産物３品目コード
,副産物３品目名
,副産物３品目略称
,副産物３ロットNO
,副産物３製造年月日
,副産物３固有記号
,副産物３賞味期限
,副産物３数量
,副産物３単位
,正単価入力完了フラグ
,部署コード
,部署名
,作成者
,作成日
,最終更新者
,最終更新日
,最終更新ログイン
)
AS
SELECT
        XNPT.entry_number                   --伝票No
       ,PRODC.prod_class_code               --荒茶商品区分
       ,PRODC.prod_class_name               --荒茶商品区分名
       ,ITEMC.item_class_code               --荒茶品目区分
       ,ITEMC.item_class_name               --荒茶品目区分名
       ,CROWD.crowd_code                    --荒茶群コード
       ,XNPT.aracha_item_code               --荒茶品目コード
       ,XIMV_ARA.item_name                  --荒茶品目名
       ,XIMV_ARA.item_short_name            --荒茶品目略称
       ,XNPT.aracha_lot_number              --荒茶ロットNo
       ,ILM_ARA.attribute1                  --荒茶製造年月日
       ,ILM_ARA.attribute2                  --荒茶固有記号
       ,ILM_ARA.attribute3                  --荒茶賞味期限
       ,XNPT.aracha_quantity                --仕上数量
       ,XNPT.aracha_uom                     --仕上単位
       ,XNPT.location_code                  --入庫先コード
       ,XILV_NYUK.description               --入庫先名
       ,XNPT.nijirushi                      --荷印
       ,XNPT.description                    --備考
       ,XNPT.collect1_quantity              --集荷１数量
       ,XNPT.collect2_quantity              --集荷２数量
       ,XNPT.receive1_quantity              --受入１数量
       ,XNPT.receive2_quantity              --受入２数量
       ,XNPT.shipment_quantity              --出荷数量
       ,XNPT.byproduct1_item_code           --副産物１品目コード
       ,XIMV_HUK1.item_name                 --副産物１品目名
       ,XIMV_HUK1.item_short_name           --副産物１品目略称
       ,XNPT.byproduct1_lot_number          --副産物１ロットNo
       ,ILM_HUK1.attribute1                 --副産物１製造年月日
       ,ILM_HUK1.attribute2                 --副産物１固有記号
       ,ILM_HUK1.attribute3                 --副産物１賞味期限
       ,XNPT.byproduct1_quantity            --副産物１数量
       ,XNPT.byproduct1_uom                 --副産物１単位
       ,XNPT.byproduct2_item_code           --副産物２品目コード
       ,XIMV_HUK2.item_name                 --副産物２品目名
       ,XIMV_HUK2.item_short_name           --副産物２品目略称
       ,XNPT.byproduct2_lot_number          --副産物２ロットNo
       ,ILM_HUK2.attribute1                 --副産物２製造年月日
       ,ILM_HUK2.attribute2                 --副産物２固有記号
       ,ILM_HUK2.attribute3                 --副産物２賞味期限
       ,XNPT.byproduct2_quantity            --副産物２数量
       ,XNPT.byproduct2_uom                 --副産物２単位
       ,XNPT.byproduct3_item_code           --副産物３品目コード
       ,XIMV_HUK3.item_name                 --副産物３品目名
       ,XIMV_HUK3.item_short_name           --副産物３品目略称
       ,XNPT.byproduct3_lot_number          --副産物３ロットNo
       ,ILM_HUK3.attribute1                 --副産物３製造年月日
       ,ILM_HUK3.attribute2                 --副産物３固有記号
       ,ILM_HUK3.attribute3                 --副産物３賞味期限
       ,XNPT.byproduct3_quantity            --副産物３数量
       ,XNPT.byproduct3_uom                 --副産物３単位
       ,XNPT.final_unit_price_entered_flg   --正単価入力完了フラグ
       ,XNPT.department_code                --部署コード
       ,XLV_TORI.location_name              --部署名
       ,FU_CB.user_name                     --作成者
       ,TO_CHAR( XNPT.creation_date, 'YYYY/MM/DD HH24:MI:SS')
                                            --作成日
       ,FU_LU.user_name                     --最終更新者
       ,TO_CHAR( XNPT.last_update_date, 'YYYY/MM/DD HH24:MI:SS')
                                            --最終更新日
       ,FU_LL.user_name                     --最終更新ログイン
FROM	xxpo_namaha_prod_txns     XNPT		--生葉実績アドオン
       ,xxskz_item_mst2_v         XIMV_ARA	--荒茶品目名取得用
       ,xxskz_prod_class_v        PRODC     --荒茶商品区分取得用
       ,xxskz_item_class_v        ITEMC     --荒茶品目区分取得用
       ,xxskz_crowd_code_v        CROWD     --荒茶群コード取得用
       ,ic_lots_mst               ILM_ARA	--荒茶ロット情報取得用
       ,xxskz_item_locations2_v   XILV_NYUK --入庫先名取得用
       ,xxskz_item_mst2_v         XIMV_HUK1 --副産物1品目名取得用
       ,ic_lots_mst               ILM_HUK1  --副産物1ロット情報取得用
       ,xxskz_item_mst2_v         XIMV_HUK2 --副産物2品目名取得用
       ,ic_lots_mst               ILM_HUK2  --副産物2ロット情報用
       ,xxskz_item_mst2_v         XIMV_HUK3 --副産物3品目名取得用
       ,ic_lots_mst               ILM_HUK3  --副産物3ロット情報用
       ,xxskz_locations2_v        XLV_TORI  --取込部署名取得用
       ,fnd_user                  FU_CB   	--ユーザーマスタ(CREATED_BY名称取得用)
       ,fnd_user                  FU_LU   	--ユーザーマスタ(LAST_UPDATE_BY名称取得用)
       ,fnd_user                  FU_LL   	--ユーザーマスタ(LAST_UPDATE_LOGIN名称取得用)
       ,fnd_logins                FL_LL   	--ログインマスタ(LAST_UPDATE_LOGIN名称取得用)
WHERE
--荒茶品目名取得用結合
      XIMV_ARA.item_id(+) = XNPT.aracha_item_id
  AND XIMV_ARA.start_date_active(+) <= TRUNC(SYSDATE)
  AND XIMV_ARA.end_date_active(+) >= TRUNC(SYSDATE)
--荒茶品目カテゴリ情報取得用結合
  AND XNPT.aracha_item_id = PRODC.item_id(+)
  AND XNPT.aracha_item_id = ITEMC.item_id(+)
  AND XNPT.aracha_item_id = CROWD.item_id(+)
--荒茶ロット情報取得用結合
  AND ILM_ARA.item_id(+) = XNPT.aracha_item_id
  AND ILM_ARA.lot_id(+) = XNPT.aracha_lot_id
--入庫先名取得用結合
  AND XILV_NYUK.inventory_location_id(+) = XNPT.location_id
--副産物1品目名取得用結合
  AND XIMV_HUK1.item_id(+) = XNPT.byproduct1_item_id
  AND XIMV_HUK1.start_date_active(+) <= TRUNC(SYSDATE)
  AND XIMV_HUK1.end_date_active(+) >= TRUNC(SYSDATE)
--副産物1ロット情報取得用結合
  AND ILM_HUK1.item_id(+) = XNPT.byproduct1_item_id
  AND ILM_HUK1.lot_id(+) = XNPT.byproduct1_lot_id
--副産物2品目名取得用結合
  AND XIMV_HUK2.item_id(+) = XNPT.byproduct2_item_id
  AND XIMV_HUK2.start_date_active(+) <= TRUNC(SYSDATE)
  AND XIMV_HUK2.end_date_active(+) >= TRUNC(SYSDATE)
--副産物2ロット情報用結合
  AND ILM_HUK2.item_id(+) = XNPT.byproduct2_item_id
  AND ILM_HUK2.lot_id(+) = XNPT.byproduct2_lot_id
--副産物3品目名取得用結合
  AND XIMV_HUK3.item_id(+) = XNPT.byproduct3_item_id
  AND XIMV_HUK3.start_date_active(+) <= TRUNC(SYSDATE)
  AND XIMV_HUK3.end_date_active(+) >= TRUNC(SYSDATE)
--副産物3ロット情報用結合
  AND ILM_HUK3.item_id(+) = XNPT.byproduct3_item_id
  AND ILM_HUK3.lot_id(+) = XNPT.byproduct3_lot_id
--取込部署名取得用
  AND XLV_TORI.location_code(+) = XNPT.department_code
  AND XLV_TORI.start_date_active(+) <= TRUNC(SYSDATE)
  AND XLV_TORI.end_date_active(+)   >= TRUNC(SYSDATE)
--ユーザーマスタ(CREATED_BY名称取得用結合)
  AND  FU_CB.user_id(+)  = XNPT.created_by
--ユーザーマスタ(LAST_UPDATE_BY名称取得用結合)
  AND  FU_LU.user_id(+)  = XNPT.last_updated_by
--ログインマスタ・ユーザーマスタ(LAST_UPDATE_LOGIN名称取得用結合)
  AND  FL_LL.login_id(+) = XNPT.last_update_login
  AND  FL_LL.user_id = FU_LL.user_id(+)
/	
COMMENT ON TABLE APPS.XXSKZ_生葉実績_数量_V IS 'XXSKZ_生葉実績（数量）VIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_生葉実績_数量_V.伝票NO                  IS '伝票No'
/
COMMENT ON COLUMN APPS.XXSKZ_生葉実績_数量_V.荒茶商品区分            IS '荒茶商品区分'
/
COMMENT ON COLUMN APPS.XXSKZ_生葉実績_数量_V.荒茶商品区分名          IS '荒茶商品区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_生葉実績_数量_V.荒茶品目区分            IS '荒茶品目区分'
/
COMMENT ON COLUMN APPS.XXSKZ_生葉実績_数量_V.荒茶品目区分名          IS '荒茶品目区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_生葉実績_数量_V.荒茶群コード            IS '荒茶群コード'
/
COMMENT ON COLUMN APPS.XXSKZ_生葉実績_数量_V.荒茶品目コード          IS '荒茶品目コード'
/
COMMENT ON COLUMN APPS.XXSKZ_生葉実績_数量_V.荒茶品目名              IS '荒茶品目名'
/
COMMENT ON COLUMN APPS.XXSKZ_生葉実績_数量_V.荒茶品目略称            IS '荒茶品目略称'
/
COMMENT ON COLUMN APPS.XXSKZ_生葉実績_数量_V.荒茶ロットNO            IS '荒茶ロットNo'
/
COMMENT ON COLUMN APPS.XXSKZ_生葉実績_数量_V.荒茶製造年月日          IS '荒茶製造年月日'
/
COMMENT ON COLUMN APPS.XXSKZ_生葉実績_数量_V.荒茶固有記号            IS '荒茶固有記号'
/
COMMENT ON COLUMN APPS.XXSKZ_生葉実績_数量_V.荒茶賞味期限            IS '荒茶賞味期限'
/
COMMENT ON COLUMN APPS.XXSKZ_生葉実績_数量_V.仕上数量                IS '仕上数量'
/
COMMENT ON COLUMN APPS.XXSKZ_生葉実績_数量_V.仕上単位                IS '仕上単位'
/
COMMENT ON COLUMN APPS.XXSKZ_生葉実績_数量_V.入庫先コード            IS '入庫先コード'
/
COMMENT ON COLUMN APPS.XXSKZ_生葉実績_数量_V.入庫先名                IS '入庫先名'
/
COMMENT ON COLUMN APPS.XXSKZ_生葉実績_数量_V.荷印                    IS '荷印'
/
COMMENT ON COLUMN APPS.XXSKZ_生葉実績_数量_V.備考                    IS '備考'
/
COMMENT ON COLUMN APPS.XXSKZ_生葉実績_数量_V.集荷１数量              IS '集荷１数量'
/
COMMENT ON COLUMN APPS.XXSKZ_生葉実績_数量_V.集荷２数量              IS '集荷２数量'
/
COMMENT ON COLUMN APPS.XXSKZ_生葉実績_数量_V.受入１数量              IS '受入１数量'
/
COMMENT ON COLUMN APPS.XXSKZ_生葉実績_数量_V.受入２数量              IS '受入２数量'
/
COMMENT ON COLUMN APPS.XXSKZ_生葉実績_数量_V.出荷数量                IS '出荷数量'
/
COMMENT ON COLUMN APPS.XXSKZ_生葉実績_数量_V.副産物１品目コード      IS '副産物１品目コード'
/
COMMENT ON COLUMN APPS.XXSKZ_生葉実績_数量_V.副産物１品目名          IS '副産物１品目名'
/
COMMENT ON COLUMN APPS.XXSKZ_生葉実績_数量_V.副産物１品目略称        IS '副産物１品目略称'
/
COMMENT ON COLUMN APPS.XXSKZ_生葉実績_数量_V.副産物１ロットNO        IS '副産物１ロットNo'
/
COMMENT ON COLUMN APPS.XXSKZ_生葉実績_数量_V.副産物１製造年月日      IS '副産物１製造年月日'
/
COMMENT ON COLUMN APPS.XXSKZ_生葉実績_数量_V.副産物１固有記号        IS '副産物１固有記号'
/
COMMENT ON COLUMN APPS.XXSKZ_生葉実績_数量_V.副産物１賞味期限        IS '副産物１賞味期限'
/
COMMENT ON COLUMN APPS.XXSKZ_生葉実績_数量_V.副産物１数量            IS '副産物１数量'
/
COMMENT ON COLUMN APPS.XXSKZ_生葉実績_数量_V.副産物１単位            IS '副産物１単位'
/
COMMENT ON COLUMN APPS.XXSKZ_生葉実績_数量_V.副産物２品目コード      IS '副産物２品目コード'
/
COMMENT ON COLUMN APPS.XXSKZ_生葉実績_数量_V.副産物２品目名          IS '副産物２品目名'
/
COMMENT ON COLUMN APPS.XXSKZ_生葉実績_数量_V.副産物２品目略称        IS '副産物２品目略称'
/
COMMENT ON COLUMN APPS.XXSKZ_生葉実績_数量_V.副産物２ロットNO        IS '副産物２ロットNo'
/
COMMENT ON COLUMN APPS.XXSKZ_生葉実績_数量_V.副産物２製造年月日      IS '副産物２製造年月日'
/
COMMENT ON COLUMN APPS.XXSKZ_生葉実績_数量_V.副産物２固有記号        IS '副産物２固有記号'
/
COMMENT ON COLUMN APPS.XXSKZ_生葉実績_数量_V.副産物２賞味期限        IS '副産物２賞味期限'
/
COMMENT ON COLUMN APPS.XXSKZ_生葉実績_数量_V.副産物２数量            IS '副産物２数量'
/
COMMENT ON COLUMN APPS.XXSKZ_生葉実績_数量_V.副産物２単位            IS '副産物２単位'
/
COMMENT ON COLUMN APPS.XXSKZ_生葉実績_数量_V.副産物３品目コード      IS '副産物３品目コード'
/
COMMENT ON COLUMN APPS.XXSKZ_生葉実績_数量_V.副産物３品目名          IS '副産物３品目名'
/
COMMENT ON COLUMN APPS.XXSKZ_生葉実績_数量_V.副産物３品目略称        IS '副産物３品目略称'
/
COMMENT ON COLUMN APPS.XXSKZ_生葉実績_数量_V.副産物３ロットNO        IS '副産物３ロットNo'
/
COMMENT ON COLUMN APPS.XXSKZ_生葉実績_数量_V.副産物３製造年月日      IS '副産物３製造年月日'
/
COMMENT ON COLUMN APPS.XXSKZ_生葉実績_数量_V.副産物３固有記号        IS '副産物３固有記号'
/
COMMENT ON COLUMN APPS.XXSKZ_生葉実績_数量_V.副産物３賞味期限        IS '副産物３賞味期限'
/
COMMENT ON COLUMN APPS.XXSKZ_生葉実績_数量_V.副産物３数量            IS '副産物３数量'
/
COMMENT ON COLUMN APPS.XXSKZ_生葉実績_数量_V.副産物３単位            IS '副産物３単位'
/
COMMENT ON COLUMN APPS.XXSKZ_生葉実績_数量_V.正単価入力完了フラグ    IS '正単価入力完了フラグ'
/
COMMENT ON COLUMN APPS.XXSKZ_生葉実績_数量_V.部署コード              IS '部署コード'
/
COMMENT ON COLUMN APPS.XXSKZ_生葉実績_数量_V.部署名                  IS '部署名'
/
COMMENT ON COLUMN APPS.XXSKZ_生葉実績_数量_V.作成者                  IS '作成者'
/
COMMENT ON COLUMN APPS.XXSKZ_生葉実績_数量_V.作成日                  IS '作成日'
/
COMMENT ON COLUMN APPS.XXSKZ_生葉実績_数量_V.最終更新者              IS '最終更新者'
/
COMMENT ON COLUMN APPS.XXSKZ_生葉実績_数量_V.最終更新日              IS '最終更新日'
/
COMMENT ON COLUMN APPS.XXSKZ_生葉実績_数量_V.最終更新ログイン        IS '最終更新ログイン'
/
