CREATE OR REPLACE PACKAGE XXCOP004A07C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOP004A07C(spec)
 * Description      : 親コード出荷実績作成
 * MD.050           : 親コード出荷実績作成 MD050_COP_004_A07
 * Version          : 1.3
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  main                 コンカレント実行ファイル登録プロシージャ
 *  init                     初期処理(A-1)
 *  del_shipment_results     親コード出荷実績過去データ削除(A-2)
 *  renew_shipment_results   出荷倉庫コード最新化(A-3)
 *  get_shipment_results     出荷実績情報抽出(A-4)
 *  get_latest_code          最新出荷倉庫取得(A-5)
 *  ins_shipment_results     親コード出荷実績データ作成(A-7)
 *  upd_shipment_results     親コード出荷実績データ更新(A-8)
 *  upd_appl_contorols       前回処理日時時更新(A-9)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/17    1.0   SCS.Tsubomatsu   新規作成
 *  2009/02/09    1.1   SCS.Kikuchi      結合不具合No.004対応(A-5.該当データ無しの場合の処理変更)
 *  2009/02/16    1.2   SCS.Tsubomatsu   結合不具合No.010対応(A-3.更新条件見直し)
 *  2009/04/13    1.3   SCS.Kikuchi      T1_0507対応
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf            OUT VARCHAR2,           --   エラー・メッセージ  --# 固定 #
    retcode           OUT VARCHAR2            --   リターン・コード    --# 固定 #
  );

END XXCOP004A07C;
/
