CREATE OR REPLACE PACKAGE xxcmn800007c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxcmn800007c(spec)
 * Description      : 倉庫マスタインターフェース(Outbound)
 * MD.050           : マスタインタフェース T_MD050_BPO_800
 * MD.070           : 倉庫マスタインタフェース T_MD070_BPO_80G
 * Version          : 1.2
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  get_ware_mst           倉庫マスタ取得プロシージャ (G-1)
 *  output_csv             CSVファイル出力プロシージャ (G-2)
 *  upd_last_update        最終更新日時ファイル更新プロシージャ (G-3)
 *  wf_notif               Workflow通知プロシージャ (G-4)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2007/12/26    1.0  Oracle 椎名 昭圭  初回作成
 *  2008/05/02    1.1  Oracle 椎名 昭圭  変更要求#11･内部変更要求#62対応
 *  2008/06/12    1.2  Oracle 丸下       日付項目書式変更
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf              OUT NOCOPY VARCHAR2,     -- エラーメッセージ #固定#
    retcode             OUT NOCOPY VARCHAR2,     -- エラーコード     #固定#
    iv_wf_ope_div       IN  VARCHAR2,            -- 処理区分
    iv_wf_class         IN  VARCHAR2,            -- 対象
    iv_wf_notification  IN  VARCHAR2,            -- 宛先
    iv_last_update      IN  VARCHAR2,            -- 最終更新日時
    iv_deli_type        IN  VARCHAR2             -- 出荷管理元区分
  );
END xxcmn800007c;
/
