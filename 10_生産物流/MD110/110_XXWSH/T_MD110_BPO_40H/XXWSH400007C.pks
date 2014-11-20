CREATE OR REPLACE PACKAGE xxwsh400007c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwsh400007c(package)
 * Description      : 出荷依頼締め処理
 * MD.050           : T_MD050_BPO_401_出荷依頼
 * MD.070           : 出荷依頼締め処理 T_MD070_BPO_40H
 * Version          : 1.1
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
 *  2008/4/10     1.0   R.Matusita       新規作成
 *  2008/5/19     1.1   Oracle 上原正好  内部変更要求#80対応 パラメータ「拠点」追加
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf                   OUT NOCOPY VARCHAR2,         -- エラーメッセージ #固定#
    retcode                  OUT NOCOPY VARCHAR2,         -- エラーコード     #固定#
    iv_order_type_id         IN  VARCHAR2,                -- 出庫形態ID
    iv_deliver_from          IN  VARCHAR2,                -- 出荷元
    iv_sales_base            IN  VARCHAR2,                -- 拠点
    iv_sales_base_category   IN  VARCHAR2,                -- 拠点カテゴリ
    iv_lead_time_day         IN  VARCHAR2,                -- 生産物流LT
    iv_schedule_ship_date    IN  VARCHAR2,                -- 出庫日
    iv_base_record_class     IN  VARCHAR2,                -- 基準レコード区分
    iv_request_no            IN  VARCHAR2,                -- 依頼No
    iv_tighten_class         IN  VARCHAR2,                -- 締め処理区分
    iv_prod_class            IN  VARCHAR2,                -- 商品区分
    iv_tightening_program_id IN  VARCHAR2,                -- 締めコンカレントID
    iv_instruction_dept      IN  VARCHAR2                 -- 部署
  );
END xxwsh400007c;
/
