/*************************************************************************
 * 
 * VIEW Name       : XXCSO_INSTALL_BASE_V
 * Description     : 共通用：物件マスタビュー
 * MD.070          : 
 * Version         : 1.3
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2009/02/01    1.0  T.Maruyama    初回作成
 *  2009/03/11    1.1  N.Yabuki      先月末項目（３項目）を追加
 *  2009/03/25    1.2  S.Kayahara    86行目改行削除
 *  2009/12/24    1.3  D.Abe         E_本稼動_00533対応
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXCSO_INSTALL_BASE_V
(
 INSTANCE_ID
,INSTANCE_NUMBER
,INSTALL_CODE
,INSTANCE_TYPE_CODE
,INSTANCE_STATUS_ID
,INSTALL_DATE
,ACTIVE_START_DATE
,VENDOR_MODEL
,VENDOR_NUMBER
,FIRST_INSTALL_DATE
,OP_REQUEST_FLAG
/* 2009.12.24 D.Abe E_本稼動_00533対応 START */
,OP_REQ_NUMBER_ACCOUNT_NUMBER
/* 2009.12.24 D.Abe E_本稼動_00533対応 END */
,NEW_OLD_FLAG
,INSTALL_PARTY_ID
,INSTALL_ACCOUNT_ID
,QUANTITY
,ACCOUNTING_CLASS_CODE
,INVENTORY_ITEM_ID
,OBJECT_VERSION_NUMBER
,COUNT_NO
,CHIKU_CD
,SAGYOUGAISYA_CD
,JIGYOUSYO_CD
,DEN_NO
,JOB_KBN
,SINTYOKU_KBN
,YOTEI_DT
,KANRYO_DT
,SAGYO_LEVEL
,DEN_NO2
,JOB_KBN2
,SINTYOKU_KBN2
,JOTAI_KBN1
,JOTAI_KBN2
,JOTAI_KBN3
,NYUKO_DT
,HIKISAKIGAISYA_CD
,HIKISAKIJIGYOSYO_CD
,SETTI_TANTO
,SETTI_TEL1
,SETTI_TEL2
,SETTI_TEL3
,HAIKIKESSAI_DT
,TENHAI_TANTO
,TENHAI_DEN_NO
,SYOYU_CD
,TENHAI_FLG
,KANRYO_KBN
,SAKUJO_FLG
,VEN_KYAKU_LAST
,VEN_TASYA_CD01
,VEN_TASYA_DAISU01
,VEN_TASYA_CD02
,VEN_TASYA_DAISU02
,VEN_TASYA_CD03
,VEN_TASYA_DAISU03
,VEN_TASYA_CD04
,VEN_TASYA_DAISU04
,VEN_TASYA_CD05
,VEN_TASYA_DAISU05
,VEN_HAIKI_FLG
,VEN_SISAN_KBN
,VEN_KOBAI_YMD
,VEN_KOBAI_KG
,SAFTY_LEVEL
,LEASE_KBN
,LAST_INST_CUST_CODE
,LAST_JOTAI_KBN
,LAST_YEAR_MONTH
)
AS
SELECT
 cii.INSTANCE_ID
,cii.INSTANCE_NUMBER
,cii.EXTERNAL_REFERENCE
,cii.INSTANCE_TYPE_CODE
,cii.INSTANCE_STATUS_ID
,cii.INSTALL_DATE
,cii.ACTIVE_START_DATE
,cii.ATTRIBUTE1
,cii.ATTRIBUTE2
,cii.ATTRIBUTE3
,cii.ATTRIBUTE4
/* 2009.12.24 D.Abe E_本稼動_00533対応 START */
,cii.ATTRIBUTE8
/* 2009.12.24 D.Abe E_本稼動_00533対応 END */
,cii.ATTRIBUTE5
,cii.OWNER_PARTY_ID
,cii.OWNER_PARTY_ACCOUNT_ID
,cii.QUANTITY
,cii.ACCOUNTING_CLASS_CODE
,cii.INVENTORY_ITEM_ID
,cii.OBJECT_VERSION_NUMBER
,xxcso_ib_common_pkg.get_ib_ext_attribs(cii.instance_id,'COUNT_NO')
,xxcso_ib_common_pkg.get_ib_ext_attribs(cii.instance_id,'CHIKU_CD')
,xxcso_ib_common_pkg.get_ib_ext_attribs(cii.instance_id,'SAGYOUGAISYA_CD')
,xxcso_ib_common_pkg.get_ib_ext_attribs(cii.instance_id,'JIGYOUSYO_CD')
,xxcso_ib_common_pkg.get_ib_ext_attribs(cii.instance_id,'DEN_NO')
,xxcso_ib_common_pkg.get_ib_ext_attribs(cii.instance_id,'JOB_KBN')
,xxcso_ib_common_pkg.get_ib_ext_attribs(cii.instance_id,'SINTYOKU_KBN')
,xxcso_ib_common_pkg.get_ib_ext_attribs(cii.instance_id,'YOTEI_DT')
,xxcso_ib_common_pkg.get_ib_ext_attribs(cii.instance_id,'KANRYO_DT')
,xxcso_ib_common_pkg.get_ib_ext_attribs(cii.instance_id,'SAGYO_LEVEL')
,xxcso_ib_common_pkg.get_ib_ext_attribs(cii.instance_id,'DEN_NO2')
,xxcso_ib_common_pkg.get_ib_ext_attribs(cii.instance_id,'JOB_KBN2')
,xxcso_ib_common_pkg.get_ib_ext_attribs(cii.instance_id,'SINTYOKU_KBN2')
,xxcso_ib_common_pkg.get_ib_ext_attribs(cii.instance_id,'JOTAI_KBN1')
,xxcso_ib_common_pkg.get_ib_ext_attribs(cii.instance_id,'JOTAI_KBN2')
,xxcso_ib_common_pkg.get_ib_ext_attribs(cii.instance_id,'JOTAI_KBN3')
,xxcso_ib_common_pkg.get_ib_ext_attribs(cii.instance_id,'NYUKO_DT')
,xxcso_ib_common_pkg.get_ib_ext_attribs(cii.instance_id,'HIKISAKIGAISYA_CD')
,xxcso_ib_common_pkg.get_ib_ext_attribs(cii.instance_id,'HIKISAKIJIGYOSYO_CD')
,xxcso_ib_common_pkg.get_ib_ext_attribs(cii.instance_id,'SETTI_TANTO')
,xxcso_ib_common_pkg.get_ib_ext_attribs(cii.instance_id,'SETTI_TEL1')
,xxcso_ib_common_pkg.get_ib_ext_attribs(cii.instance_id,'SETTI_TEL2')
,xxcso_ib_common_pkg.get_ib_ext_attribs(cii.instance_id,'SETTI_TEL3')
,xxcso_ib_common_pkg.get_ib_ext_attribs(cii.instance_id,'HAIKIKESSAI_DT')
,xxcso_ib_common_pkg.get_ib_ext_attribs(cii.instance_id,'TENHAI_TANTO')
,xxcso_ib_common_pkg.get_ib_ext_attribs(cii.instance_id,'TENHAI_DEN_NO')
,xxcso_ib_common_pkg.get_ib_ext_attribs(cii.instance_id,'SYOYU_CD')
,xxcso_ib_common_pkg.get_ib_ext_attribs(cii.instance_id,'TENHAI_FLG')
,xxcso_ib_common_pkg.get_ib_ext_attribs(cii.instance_id,'KANRYO_KBN')
,xxcso_ib_common_pkg.get_ib_ext_attribs(cii.instance_id,'SAKUJO_FLG')
,xxcso_ib_common_pkg.get_ib_ext_attribs(cii.instance_id,'VEN_KYAKU_LAST')
,xxcso_ib_common_pkg.get_ib_ext_attribs(cii.instance_id,'VEN_TASYA_CD01')
,xxcso_ib_common_pkg.get_ib_ext_attribs(cii.instance_id,'VEN_TASYA_DAISU01')
,xxcso_ib_common_pkg.get_ib_ext_attribs(cii.instance_id,'VEN_TASYA_CD02')
,xxcso_ib_common_pkg.get_ib_ext_attribs(cii.instance_id,'VEN_TASYA_DAISU02')
,xxcso_ib_common_pkg.get_ib_ext_attribs(cii.instance_id,'VEN_TASYA_CD03')
,xxcso_ib_common_pkg.get_ib_ext_attribs(cii.instance_id,'VEN_TASYA_DAISU03')
,xxcso_ib_common_pkg.get_ib_ext_attribs(cii.instance_id,'VEN_TASYA_CD04')
,xxcso_ib_common_pkg.get_ib_ext_attribs(cii.instance_id,'VEN_TASYA_DAISU04')
,xxcso_ib_common_pkg.get_ib_ext_attribs(cii.instance_id,'VEN_TASYA_CD05')
,xxcso_ib_common_pkg.get_ib_ext_attribs(cii.instance_id,'VEN_TASYA_DAISU05')
,xxcso_ib_common_pkg.get_ib_ext_attribs(cii.instance_id,'VEN_HAIKI_FLG')
,xxcso_ib_common_pkg.get_ib_ext_attribs(cii.instance_id,'VEN_SISAN_KBN')
,xxcso_ib_common_pkg.get_ib_ext_attribs(cii.instance_id,'VEN_KOBAI_YMD')
,xxcso_ib_common_pkg.get_ib_ext_attribs(cii.instance_id,'VEN_KOBAI_KG')
,xxcso_ib_common_pkg.get_ib_ext_attribs(cii.instance_id,'SAFTY_LEVEL')
,xxcso_ib_common_pkg.get_ib_ext_attribs(cii.instance_id,'LEASE_KBN')
,xxcso_ib_common_pkg.get_ib_ext_attribs(cii.instance_id,'LAST_INST_CUST_CODE')
,xxcso_ib_common_pkg.get_ib_ext_attribs(cii.instance_id,'LAST_JOTAI_KBN')
,xxcso_ib_common_pkg.get_ib_ext_attribs(cii.instance_id,'LAST_YEAR_MONTH')
FROM
 CSI_ITEM_INSTANCES cii
WITH READ ONLY
;
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.INSTANCE_ID IS 'インスタンスID';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.INSTANCE_NUMBER IS 'インスタンス番号';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.INSTALL_CODE IS '物件コード';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.INSTANCE_TYPE_CODE IS '機器区分';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.INSTANCE_STATUS_ID IS 'ステータスID';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.INSTALL_DATE IS '導入日';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.ACTIVE_START_DATE IS '開始日';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.VENDOR_MODEL IS '機種';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.VENDOR_NUMBER IS '機番';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.FIRST_INSTALL_DATE IS '初回設置日';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.OP_REQUEST_FLAG IS '作業依頼中フラグ';
/* 2009.12.24 D.Abe E_本稼動_00533対応 START */
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.OP_REQ_NUMBER_ACCOUNT_NUMBER IS '作業依頼中購買依頼No/顧客CD';
/* 2009.12.24 D.Abe E_本稼動_00533対応 END */
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.NEW_OLD_FLAG IS '新古台フラグ';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.INSTALL_PARTY_ID IS '設置先パーティID';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.INSTALL_ACCOUNT_ID IS '設置先アカウントID';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.QUANTITY IS '数量';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.ACCOUNTING_CLASS_CODE IS '会計分類';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.INVENTORY_ITEM_ID IS '品目ID';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.OBJECT_VERSION_NUMBER IS 'オブジェクトバージョン番号';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.COUNT_NO IS 'カウンターNo.';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.CHIKU_CD IS '地区コード';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.SAGYOUGAISYA_CD IS '作業会社コード';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.JIGYOUSYO_CD IS '事業所コード';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.DEN_NO IS '最終作業伝票No.';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.JOB_KBN IS '最終作業区分';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.SINTYOKU_KBN IS '最終作業進捗';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.YOTEI_DT IS '最終作業完了予定日';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.KANRYO_DT IS '最終作業完了日';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.SAGYO_LEVEL IS '最終整備内容';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.DEN_NO2 IS '最終設置伝票No.';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.JOB_KBN2 IS '最終設置区分';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.SINTYOKU_KBN2 IS '最終設置進捗';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.JOTAI_KBN1 IS '機器状態1（稼動状態）';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.JOTAI_KBN2 IS '機器状態2（状態詳細）';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.JOTAI_KBN3 IS '機器状態3（廃棄情報）';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.NYUKO_DT IS '入庫日';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.HIKISAKIGAISYA_CD IS '引揚会社コード';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.HIKISAKIJIGYOSYO_CD IS '引揚事業所コード';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.SETTI_TANTO IS '設置先担当者名';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.SETTI_TEL1 IS '設置先TEL1';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.SETTI_TEL2 IS '設置先TEL2';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.SETTI_TEL3 IS '設置先TEL3';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.HAIKIKESSAI_DT IS '廃棄決裁日';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.TENHAI_TANTO IS '転売廃棄業者';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.TENHAI_DEN_NO IS '転売廃棄伝票№';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.SYOYU_CD IS '所有者';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.TENHAI_FLG IS '転売廃棄状況フラグ';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.KANRYO_KBN IS '転売完了区分';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.SAKUJO_FLG IS '削除フラグ';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.VEN_KYAKU_LAST IS '最終顧客コード';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.VEN_TASYA_CD01 IS '他社コード１';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.VEN_TASYA_DAISU01 IS '他社台数１';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.VEN_TASYA_CD02 IS '他社コード２';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.VEN_TASYA_DAISU02 IS '他社台数２';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.VEN_TASYA_CD03 IS '他社コード３';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.VEN_TASYA_DAISU03 IS '他社台数３';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.VEN_TASYA_CD04 IS '他社コード４';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.VEN_TASYA_DAISU04 IS '他社台数４';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.VEN_TASYA_CD05 IS '他社コード５';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.VEN_TASYA_DAISU05 IS '他社台数５';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.VEN_HAIKI_FLG IS '廃棄フラグ';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.VEN_SISAN_KBN IS '資産区分';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.VEN_KOBAI_YMD IS '購買日付';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.VEN_KOBAI_KG IS '購買金額';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.SAFTY_LEVEL IS '安全設置基準';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.LEASE_KBN IS 'リース区分';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.LAST_INST_CUST_CODE IS '先月末設置先顧客コード';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.LAST_JOTAI_KBN IS '先月末機器状態';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.LAST_YEAR_MONTH IS '先月末年月';
COMMENT ON TABLE XXCSO_INSTALL_BASE_V IS '物件マスタビュー';
