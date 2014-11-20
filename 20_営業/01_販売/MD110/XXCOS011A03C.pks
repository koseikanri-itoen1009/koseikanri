CREATE OR REPLACE PACKAGE APPS.XXCOS011A03C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2009. All rights reserved.
 *
 * Package Name     : XXCOS011A03C (spec)
 * Description      : 納品予定データの作成を行う
 * MD.050           : 納品予定データ作成 (MD050_COS_011_A03)
 * Version          : 1.17
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
 *  2009/01/08    1.0   H.Fujimoto       新規作成
 *  2009/02/20    1.1   H.Fujimoto       結合不具合No.106
 *  2009/02/24    1.2   H.Fujimoto       結合不具合No.126,134
 *  2009/02/25    1.3   H.Fujimoto       結合不具合No.135
 *  2009/02/25    1.4   H.Fujimoto       結合不具合No.141
 *  2009/02/27    1.5   H.Fujimoto       結合不具合No.146,149
 *  2009/03/04    1.6   H.Fujimoto       結合不具合No.154
 *  2009/04/28    1.7   K.Kiriu          [T1_0756]レコード長変更対応
 *  2009/05/12    1.8   K.Kiriu          [T1_0677]ラベル作成対応
 *                                       [T1_0937]削除時の件数カウント対応
 *  2009/05/22    1.9   M.Sano           [T1_1073]ダミー品目時の数量項目変更対応
 *  2009/06/11    1.10  T.Kitajima       [T1_1348]行Noの結合条件変更
 *  2009/06/12    1.10  T.Kitajima       [T1_1350]メインカーソルソート条件変更
 *  2009/06/12    1.10  T.Kitajima       [T1_1356]ファイルNo→顧客アドオン.EDI伝送追番
 *  2009/06/12    1.10  T.Kitajima       [T1_1357]伝票番号数値チェック
 *  2009/06/12    1.10  T.Kitajima       [T1_1358]定番特売区分0→00,1→01,2→02
 *  2009/06/19    1.10  T.Kitajima       [T1_1436]受注データ、営業単位絞込み追加
 *  2009/06/24    1.10  T.Kitajima       [T1_1359]数量換算対応
 *  2009/07/08    1.10  M.Sano           [T1_1357]レビュー指摘事項対応
 *  2009/07/10    1.10  N.Maeda          [000063]情報区分によるデータ作成対象の制御追加
 *                                       [000064]受注DFF項目追加に伴う、連携項目追加
 *  2009/07/21    1.11  K.Kiriu          [0000644]原価金額の端数処理対応
 *  2009/07/24    1.11  K.Kiriu          [T1_1359]レビュー指摘事項対応
 *  2009/08/10    1.11  K.Kiriu          [0000438]指摘事項対応
 *  2009/09/03    1.12  N.Maeda          [0001065]『XXCOS_HEAD_PROD_CLASS_V』のMainSQL取込
 *  2009/09/25    1.13  N.Maeda          [0001306]伝票計集計単位修正
 *                                       [0001307]出荷数量取得元テーブル修正
 *  2009/10/05    1.14  N.Maeda          [0001464]受注明細分割による影響対応
 *  2010/03/01    1.15  S.Karikomi       [E_本稼働_01635]ヘッダ出力拠点修正
 *                                                       件数カウント単位の同期対応
 *  2010/06/11    1.16  S.Niki           [E_本稼動_03075]拠点選択対応
 *  2011/12/15    1.17  T.Yoshimoto      [E_本稼動_02817]パラメータ(解除拠点コード)追加対応
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf              OUT    VARCHAR2,         --   エラーメッセージ #固定#
    retcode             OUT    VARCHAR2,         --   エラーコード     #固定#
    iv_file_name        IN     VARCHAR2,         --   1.ファイル名
    iv_make_class       IN     VARCHAR2,         --   2.作成区分
    iv_edi_c_code       IN     VARCHAR2,         --   3.EDIチェーン店コード
/* 2009/05/12 Ver1.8 Mod Start */
--    iv_edi_f_number     IN     VARCHAR2,         --   4.EDI伝送追番
    iv_edi_f_number_f   IN     VARCHAR2,         --   4.EDI伝送追番(ファイル名用)
    iv_edi_f_number_s   IN     VARCHAR2,         --   5.EDI伝送追番(抽出条件用)
/* 2009/05/12 Ver1.8 Mod End   */
    iv_shop_date_from   IN     VARCHAR2,         --   6.店舗納品日From
    iv_shop_date_to     IN     VARCHAR2,         --   7.店舗納品日To
    iv_sale_class       IN     VARCHAR2,         --   8.定番特売区分
    iv_area_code        IN     VARCHAR2,         --   9.地区コード
    iv_center_date      IN     VARCHAR2,         --  10.センター納品日
    iv_delivery_time    IN     VARCHAR2,         --  11.納品時刻
    iv_delivery_charge  IN     VARCHAR2,         --  12.納品担当者
    iv_carrier_means    IN     VARCHAR2,         --  13.輸送手段
    iv_proc_date        IN     VARCHAR2,         --  14.処理日
    iv_proc_time        IN     VARCHAR2,         --  15.処理時刻
/* 2011/12/15 Ver1.17 T.Yoshimoto Add Start E_本稼動_02871 */
    iv_cancel_bace_code IN     VARCHAR2,         --  16.解除拠点コード
/* 2011/12/15 Ver1.17 T.Yoshimoto Add End */
/* 2010/06/11 Ver1.21 Add Start */
    iv_slct_base_code   IN     VARCHAR2          --  17.出力拠点コード
/* 2010/06/11 Ver1.21 Add End */
  );
END XXCOS011A03C;
/
