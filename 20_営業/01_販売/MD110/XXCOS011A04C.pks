CREATE OR REPLACE PACKAGE XXCOS011A04C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS011A04C (spec)
 * Description      : 入庫予定データの作成を行う
 * MD.050           : 入庫予定データ作成 (MD050_COS_011_A04)
 * Version          : 1.3
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
 *  2008/12/18    1.0   K.Kiriu         新規作成
 *  2008/02/27    1.1   K.Kiriu         [COS_147]税率の取得条件追加
 *  2009/03/10    1.2   T.Kitajima      [T1_0030]顧客品目の無効エラー対応
 *  2009/04/01    1.3   T.Kitajima      [T1_0043]顧客品目の絞り込み条件に単位を追加
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf          OUT    VARCHAR2,         --   エラーメッセージ #固定#
    retcode         OUT    VARCHAR2,         --   エラーコード     #固定#
    iv_file_name    IN     VARCHAR2,         --   1.ファイル名
    iv_to_s_code    IN     VARCHAR2,         --   2.搬送先保管場所
    iv_edi_c_code   IN     VARCHAR2,         --   3.EDIチェーン店コード
    iv_edi_f_number IN     VARCHAR2          --   4.EDI伝送追番
  );
END XXCOS011A04C;
/
