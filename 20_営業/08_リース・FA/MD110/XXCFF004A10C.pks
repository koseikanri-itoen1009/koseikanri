CREATE OR REPLACE PACKAGE XXCFF004A10C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFF004A10C(spec)
 * Description      : 営業システム構築プロジェクト
 * MD.050           : 再リース要否アップロード CFF_004_A10
 * Version          : 1.3
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   p 初期処理                                (A-1)
 *  get_if_data            p ファイルアップロードIFデータ取得処理    (A-2)
 *  devide_item            p デリミタ文字項目分割                    (A-3)
 *  insert_work            p 再リース要否ワークデータ作成            (A-6)
 *  combination_check      p 組み合わせチェック                      (A-8)
 *  item_validate_check    p 項目妥当性チェック                      (A-9)
 *  re_lease_update        p 物件レコードロックと更新                (A-11)
 *  submain                p メイン処理プロシージャ
 *  main                   p コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/02    1.0   SCS大井 信幸     新規作成
 *  2009/02/09    1.1   SCS大井 信幸     ログ出力項目追加
 *  2009/02/25    1.2   SCS大井 信幸     文字列中の"を切り取り
 *  2009/02/25    1.3   SCS大井 信幸     ユーザーメッセージ出力先変更
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf         OUT    VARCHAR2,         --   エラーメッセージ #固定#
    retcode        OUT    VARCHAR2,         --   エラーコード     #固定#
    in_file_id     IN     NUMBER,           --   1.ファイルID
    iv_file_format IN     VARCHAR2          --   2.ファイルフォーマット
  );
END XXCFF004A10C;
/
