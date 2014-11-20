CREATE OR REPLACE PACKAGE APPS.XXCOS010A05R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS010A05R(spec)
 * Description      : 受注エラーリスト
 * MD.050           : 受注エラーリスト MD050_COS_010_A05
 * Version          : 1.7
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
 *  2008/12/17    1.0   K.Kumamoto       新規作成
 *  2009/02/13    1.1   M.Yamaki         [COS_072]エラーリスト種別コードの対応
 *  2009/02/24    1.2   T.Nakamura       [COS_133]メッセージ出力、ログ出力への出力内容の追加・修正
 *  2009/06/19    1.3   N.Nishimura      [T1_1437]データパージ不具合対応
 *  2009/07/23    1.4   N.Maeda          [0000300]ロック処理修正
 *  2009/08/03    1.5   M.Sano           [0000902]受注エラーリストの終了ステータス変更
 *  2009/09/29    1.6   N.Maeda          [0001338]プロシージャexecute_svfの独立トランザクション化
 *  2010/01/19    1.7   M.Sano           [E_本稼動_01159]対応
 *                                       ・入力パラメータの追加
 *                                         (実行区分･拠点･チェーン店･EDI受信日(FROM)･EDI受信日(TO))
 *                                       ・再発行の可能化
 *                                       ・出力対象のエラー情報を値リストで制御
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf        OUT    VARCHAR2         --   エラーメッセージ #固定#
   ,retcode       OUT    VARCHAR2         --   エラーコード     #固定#
   ,iv_err_list_type IN     VARCHAR2      --   エラーリスト種別
-- 2010/01/13 M.Sano Ver.1.7 add start
   ,iv_request_type             IN VARCHAR2 DEFAULT NULL --   実行区分
   ,iv_base_code                IN VARCHAR2 DEFAULT NULL --   拠点コード
   ,iv_edi_chain_code           IN VARCHAR2 DEFAULT NULL --   チェーン店コード
   ,iv_edi_received_date_from   IN VARCHAR2 DEFAULT NULL --   EDI受信日（FROM）
   ,iv_edi_received_date_to     IN VARCHAR2 DEFAULT NULL --   EDI受信日（TO)
-- 2010/01/13 M.Sano Ver.1.7 add end
  );
END XXCOS010A05R;
/
