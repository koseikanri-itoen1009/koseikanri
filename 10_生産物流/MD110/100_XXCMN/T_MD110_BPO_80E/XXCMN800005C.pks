CREATE OR REPLACE PACKAGE xxcmn800005c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxcmn800005c(spec)
 * Description      : 拠点マスタインターフェース(Outbound)
 * MD.050           : マスタインタフェース T_MD050_BPO_800
 * MD.070           : 拠点マスタインタフェース T_MD070_BPO_80E
 * Version          : 1.6
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  get_str_mst            拠点マスタ取得プロシージャ (E-1)
 *  output_csv             CSVファイル出力プロシージャ (E-2)
 *  upd_last_update        最終更新日時ファイル更新プロシージャ (E-3)
 *  wf_notif               Workflow通知プロシージャ (E-4)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2007/12/11    1.0  Oracle 椎名 昭圭  初回作成
 *  2008/04/30    1.1  Oracle 椎名 昭圭  変更要求#11対応
 *  2008/05/14    1.2  Oracle 椎名 昭圭  内部変更要求#96対応
 *  2008/06/12    1.3  Oracle 丸下       日付項目書式変更
 *  2008/07/11    1.4  Oracle 椎名 昭圭  仕様不備障害#I_S_192.1.2対応
 *  2008/09/18    1.5  Oracle 山根 一浩  T_S_460,T_S_453,T_S_575,T_S_559対応
 *  2009/10/02    1.6  SCS 丸下          本番障害#1648
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
    iv_last_update      IN  VARCHAR2             -- 最終更新日時
  );
END xxcmn800005c;
/
