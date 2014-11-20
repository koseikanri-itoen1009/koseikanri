CREATE OR REPLACE PACKAGE xxpo940004c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXPO940004C(spec)
 * Description      : 仕入・有償・移動情報抽出処理
 * MD.050           : 生産物流共通                  T_MD050_BPO_940
 * MD.070           : 仕入・有償・移動情報抽出処理  T_MD070_BPO_94D
 * Version          : 1.0
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  main                 コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/06/10    1.0   Oracle 山根 一浩 初回作成
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf                  OUT NOCOPY VARCHAR2,  --   エラー・メッセージ  --# 固定 #
    retcode                 OUT NOCOPY VARCHAR2,  --   リターン・コード    --# 固定 #
    iv_wf_ope_div        IN            VARCHAR2,  --  1.処理区分          (必須)
    iv_wf_class          IN            VARCHAR2,  --  2.対象              (必須)
    iv_wf_notification   IN            VARCHAR2,  --  3.宛先              (必須)
    iv_data_class        IN            VARCHAR2,  --  4.データ種別        (必須)
    iv_ship_no_from      IN            VARCHAR2,  --  5.配送No.FROM       (任意)
    iv_ship_no_to        IN            VARCHAR2,  --  6.配送No.TO         (任意)
    iv_req_no_from       IN            VARCHAR2,  --  7.依頼No.FROM       (任意)
    iv_req_no_to         IN            VARCHAR2,  --  8.依頼No.TO         (任意)
    iv_vendor_code       IN            VARCHAR2,  --  9.取引先            (任意)
    iv_mediation         IN            VARCHAR2,  -- 10.斡旋者            (任意)
    iv_location_code     IN            VARCHAR2,  -- 11.出庫倉庫          (任意)
    iv_arvl_code         IN            VARCHAR2,  -- 12.入庫倉庫          (任意)
    iv_vendor_site_code  IN            VARCHAR2,  -- 13.配送先            (任意)
    iv_carrier_code      IN            VARCHAR2,  -- 14.運送業者          (任意)
    iv_ship_date_from    IN            VARCHAR2,  -- 15.納入日/出庫日FROM (必須)
    iv_ship_date_to      IN            VARCHAR2,  -- 16.納入日/出庫日TO   (必須)
    iv_arrival_date_from IN            VARCHAR2,  -- 17.入庫日FROM        (任意)
    iv_arrival_date_to   IN            VARCHAR2,  -- 18.入庫日TO          (任意)
    iv_instruction_dept  IN            VARCHAR2,  -- 19.指示部署          (任意)
    iv_item_no           IN            VARCHAR2,  -- 20.品目              (任意)
    iv_update_time_from  IN            VARCHAR2,  -- 21.更新日時FROM      (任意)
    iv_update_time_to    IN            VARCHAR2,  -- 22.更新日時TO        (任意)
    iv_prod_class        IN            VARCHAR2,  -- 23.商品区分          (任意)
    iv_item_class        IN            VARCHAR2,  -- 24.品目区分          (任意)
    iv_sec_class         IN            VARCHAR2   -- 25.セキュリティ区分  (必須)
    );
END xxpo940004c;
/
