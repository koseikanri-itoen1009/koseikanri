CREATE OR REPLACE PACKAGE xxcmn800004c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxcmn800004c(spec)
 * Description      : 品目マスタインターフェース(Outbound)
 * MD.050           : マスタインタフェース T_MD050_BPO_800
 * MD.070           : 品目マスタインタフェース T_MD070_BPO_80D
 * Version          : 1.5
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  get_item_mst           品目マスタ取得プロシージャ (D-1)
 *  output_csv             CSVファイル出力プロシージャ (D-2)
 *  upd_last_update        最終更新日時ファイル更新プロシージャ (D-3)
 *  wf_notif               Workflow通知プロシージャ (D-4)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2007/11/26    1.0  Oracle 椎名 昭圭  初回作成
 *  2008/05/08    1.1  Oracle 椎名 昭圭  変更要求#11対応
 *  2008/06/12    1.2  Oracle 丸下       日付項目書式変更
 *  2008/07/11    1.3  Oracle 椎名 昭圭  仕様不備障害#I_S_001.2対応
 *                                       仕様不備障害#I_S_192.1.2対応
 *  2008/09/18    1.4  Oracle 山根 一浩  T_S_460,T_S_453,T_S_575,T_S_559,変更#232対応
 *  2008/10/08    1.5  Oracle 椎名 昭圭  I_S_328対応
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
    iv_syohin           IN  VARCHAR2,            -- 商品区分
    iv_item             IN  VARCHAR2             -- 品目区分
  );
END xxcmn800004c;
/