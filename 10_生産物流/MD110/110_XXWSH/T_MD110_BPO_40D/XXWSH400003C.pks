CREATE OR REPLACE PACKAGE xxwsh400003c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwsh400003c(package)
 * Description      : 出荷依頼確定関数
 * MD.050           : 出荷依頼               T_MD050_BPO_401
 * MD.070           : 出荷依頼確定関数       T_MD070_EDO_BPO_40D
 * Version          : 1.30
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  ship_set             出荷依頼確定関数
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/03/13    1.0   R.Matusita       初回作成
 *  2008/04/23    1.1   R.Matusita       内部変更要求#65
 *  2008/06/03    1.2   M.Uehara         内部変更要求#80
 *  2008/06/05    1.3   N.Yoshida        リードタイム妥当性チェック D-2出庫日 > 稼働日に修正
 *  2008/06/05    1.4   M.Uehara         積載効率チェック(積載効率算出)の実施条件を修正
 *  2008/06/05    1.5   N.Yoshida        出荷可否チェックにて引数設定の修正
 *                                        (入力パラメータ：管轄拠点⇒受注ヘッダの管轄拠点)
 *  2008/06/06    1.6   T.Ishiwata       出荷可否チェックにてエラーメッセージの修正
 *  2008/06/18    1.7   T.Ishiwata       締めステータスチェック区分＝２の場合、Updateするよう修正
 *                                       全体的にネスト修正
 *  2008/06/19    1.8   Y.Shindou        内部変更要求#143対応
 *  2008/07/08    1.9   N.Fukuda         ST不具合対応#405
 *  2008/07/08    1.10  M.Uehara         ST不具合対応#424
 *  2008/07/09    1.11  N.Fukuda         ST不具合対応#430
 *  2008/07/29    1.12  D.Nihei          ST不具合対応#503
 *  2008/07/30    1.13  M.Uehara         ST不具合対応#501
 *  2008/08/06    1.14  D.Nihei          ST不具合対応#525
 *                                       カテゴリ情報VIEW変更
 *  2008/08/11    1.15  M.Hokkanji       内部課題#32対応、内部変更要求#173,178対応
 *  2008/09/01    1.16  N.Yoshida        PT対応(起票なし)
 *  2008/09/24    1.17  M.Hokkanji       TE080_400指摘66対応
 *  2008/10/15    1.18  Marushita        I_S_387対応
 *  2008/11/18    1.19  M.Hokkanji       統合指摘141、632、658対応
 *  2008/11/26    1.20  M.Hokkanji       本番障害133対応
 *  2008/12/02    1.21  M.Nomura         本番障害318対応
 *  2008/12/07    1.22  M.Hokkanji       本番障害514対応
 *  2008/12/13    1.23  M.Hokkanji       本番障害554対応
 *  2008/12/24    1.24  M.Hokkanji       本番障害839対応
 *  2009/01/09    1.25  H.Itou           本番障害894対応
 *  2009/03/03    1.26  Y.Kazama         本番障害#1243対応
 *  2009/04/16    1.27  Y.Kazama         本番障害#1398対応
 *  2009/05/14    1.28  H.Itou           本番障害#1398対応
 *  2009/08/31    1.29  D.Sugahara       本番障害#1601対応
 *  2009/11/12    1.30  H.Itou           本番障害#1648対応
 *****************************************************************************************/
--
  -- 出荷依頼確定関数
  PROCEDURE ship_set(
    iv_prod_class            IN VARCHAR2  DEFAULT NULL, -- 商品区分
    iv_head_sales_branch     IN VARCHAR2  DEFAULT NULL, -- 管轄拠点
    iv_input_sales_branch    IN VARCHAR2  DEFAULT NULL, -- 入力拠点
    in_deliver_to_id         IN NUMBER    DEFAULT NULL, -- 配送先ID
    iv_request_no            IN VARCHAR2  DEFAULT NULL, -- 依頼No
    id_schedule_ship_date    IN DATE      DEFAULT NULL, -- 出庫日
    id_schedule_arrival_date IN DATE      DEFAULT NULL, -- 着日
    iv_callfrom_flg          IN VARCHAR2,               -- 呼出元フラグ
    iv_status_kbn            IN VARCHAR2,               -- 締めステータスチェック区分
    ov_errbuf                OUT NOCOPY   VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode               OUT NOCOPY   VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg                OUT NOCOPY   VARCHAR2      -- ユーザー・エラー・メッセージ --# 固定 #
    );    
END xxwsh400003c;
/
