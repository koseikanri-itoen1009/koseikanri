CREATE OR REPLACE PACKAGE xxcmn800006c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxcmn800006c(spec)
 * Description      : 配送先マスタインターフェース(Outbound)
 * MD.050           : マスタインタフェース T_MD050_BPO_800
 * MD.070           : 配送先マスタインタフェース T_MD070_BPO_80F
 * Version          : 1.10
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  get_ship_mst           配送先マスタ取得プロシージャ (F-1)
 *  output_csv             CSVファイル出力プロシージャ (F-2)
 *  upd_last_update        最終更新日時ファイル更新プロシージャ (F-3)
 *  wf_notif               Workflow通知プロシージャ (F-4)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2007/12/19    1.0  Oracle 椎名 昭圭  初回作成
 *  2008/05/09    1.1  Oracle 椎名 昭圭  変更要求#11･内部変更要求#62･#66対応
 *  2008/05/14    1.2  Oracle 椎名 昭圭  内部変更要求#96対応
 *  2008/05/16    1.3  Oracle 丸下 博宣  支払先サイトアドオン略称出力を追加
 *  2008/06/12    1.4  Oracle 丸下       日付項目書式変更
 *  2008/07/11    1.5  Oracle 椎名 昭圭  仕様不備障害#I_S_192.1.2対応
 *  2008/09/18    1.6  Oracle 山根 一浩  T_S_460,T_S_453,T_S_575,T_S_559対応
 *  2008/10/08    1.7  Oracle 椎名 昭圭  I_S_329対応
 *  2008/10/16    1.6  Oracle 丸下       T_S_460再修正
 *  2009/03/30    1.8  Oracle 飯田 甫    本番障害#1346対応
 *  2009/09/04    1.9  SCS丸下           本番障害#1637
 *  2009/10/02    1.10 SCS 丸下          本番障害#1648
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
    iv_ship_type        IN  VARCHAR2             -- 出荷/有償
  );
END xxcmn800006c;
/
