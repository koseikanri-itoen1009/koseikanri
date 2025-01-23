/*===========================================================================
* ファイル名 : XxccdSvfUtils.java
* 概要説明   : WingArc1st SVF ユーティリティ
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2024-03-13 1.0  SCSK 久保田  新規作成
*============================================================================
*/
package jp.co.itoen.xxccd.xxccd10402;

import java.text.MessageFormat;

import jp.co.fit.vfreport.Vrw32;

/******************************************************************************
 * 帳票出力を指示し、出力されたファイルをObject Storageにアップロードします。
 * @author  SCSK 久保田
 * @version 1.0
 ******************************************************************************
 */
public class XxccdSvfUtils
{
  /******************************************************************************
   * 定数設定
   *****************************************************************************/
  // ロケール：日本
  private static String SVF_LOCALE = "ja";
  // エンコーディング：SJIS
  private static String SVF_ENCODING = "MS932";
  // 出力先プリンタ：PDF
  private static String SVF_PRINTER = "PDF";
  // クエリ指定モード：クエリー様式ファイル
  private static int SVF_QUERY_MODE = 0;
  // 抽出条件モード：設計時に指定した条件式に追加
  private static int SVF_COND_MODE = 1;
  // データなしメッセージフィールド名
  private static String NODATA_MSG_FIELD = "NODATA_MSG";

  // メッセージフォーマット
  private static MessageFormat mf = new MessageFormat( "Error at {0} with code [{1}]." );

  /******************************************************************************
   * コンストラクタ
   ******************************************************************************
   */
  public XxccdSvfUtils () {
  }

  /******************************************************************************
   * メッセージを作成する関数
   * @param methodName       メソッド名
   * @param returnCode       終了コード
   * @return                 作成されたメッセージ
   ******************************************************************************
   */
  private String getMessage ( String methodName, int returnCode )
  {
    return mf.format( new Object[]{ methodName, new Integer(returnCode) }, new StringBuffer(), null ).toString();
  }

  /******************************************************************************
   * 入力パラメータに従いSVFへ帳票出力を指示する関数
   * @param userId           ユーザー
   * @param password         パスワード
   * @param hostname         SVFサーバ                 ※本機能では使用しません
   * @param formFile         フォーム様式ファイルパス
   * @param queryFile        クエリー様式ファイルパス
   * @param orgId            組織ID                    ※本機能では使用しません
   * @param spoolName        ファイルスプール先
   * @param message          NO DATAメッセージ         ※本機能では使用しません
   * @param formMode         フォーム様式モード
   * @param args             可変長引数
   * @return                 作成された帳票のファイルサイズ
   ******************************************************************************
   */
  public int outputFile (
      String       userId
    , String       password
    , String       hostname
    , String       formFile
    , String       queryFile
    , int          orgId
    , String       spoolName
    , String       message
    , int          formMode
    , String ...   args
  )
  {
    // 変数宣言
    int rt = 0;
    int size = 0;

    // SVF Connect for Java API インスタンス生成
    Vrw32 svf = new Vrw32();

    try {

      // ロケールを指定
      rt = svf.VrSetLocale( SVF_LOCALE );
      if (rt < 0) {
        throw new RuntimeException( getMessage( "VrSetLocale", rt ) );
      }

      // パラメータのエンコーディングを指定
      rt = svf.VrInit( SVF_ENCODING );
      if (rt < 0) {
        throw new RuntimeException( getMessage( "VrInit", rt ) );
      }

      // 出力先のプリンタを指定
      rt = svf.VrSetPrinter("", SVF_PRINTER);
      if (rt < 0) {
        throw new RuntimeException( getMessage( "VrSetPrinter", rt ) );
      }

      // ファイル出力先（スプール先）を指定
      rt = svf.VrSetSpoolFileName2( spoolName );
      if (rt < 0) {
        throw new RuntimeException( getMessage( "VrSetSpoolFileName2", rt ) );
      }

      // フォーム様式ファイル・フォーム様式モード指定
      rt = svf.VrSetForm( formFile, formMode );
      if (rt < 0) {
        throw new RuntimeException( getMessage( "VrSetForm", rt ) );
      }

      // クエリー様式ファイルを指定
      String conn = "UID=" + userId + ";PWD=" + password;
      rt = svf.VrSetQuery( conn, queryFile, SVF_QUERY_MODE );
      if (rt < 0) {
        throw new RuntimeException( getMessage( "VrSetQuery", rt ) );
      }

      // 可変長引数が指定されている場合、指定された数だけ抽出条件を追加
      if ( args.length > 0 ) {

        StringBuffer condition = new StringBuffer();
        for ( String arg : args ) {

          // 引数がNULLなら以降を処理しない
          if ( arg == null || arg.length() == 0) {
            break;
          }

          // 条件を追加
          if ( condition.length() == 0 ) {

            // 最初はそのまま設定
            condition.append( arg );

          } else {

            // 2番目以降をANDで連結
            condition.append( " AND " + arg );

          }
        }

        // 抽出条件を追加
        rt = svf.VrCondition( condition.toString(), SVF_COND_MODE);
        if (rt < 0) {
          throw new RuntimeException( getMessage( "VrCondition", rt ));
        }
      }

      // SVFクエリー実行
      rt = svf.VrExecQuery();

      // レコードがない場合(-554)は、データなしメッセージのみで出力
      if (rt == -554) {
        rt = svf.VrsOut( NODATA_MSG_FIELD, message );
        if (rt < 0) {
          throw new RuntimeException( getMessage( "VrsOut", rt ) );
        }

        // ページ終了
        rt = svf.VrEndRecord();
        if (rt < 0) {
          throw new RuntimeException( getMessage( "VrEndRecord", rt ) );
        }

      // レコードがない場合(-554)以外のエラー
      } else if (rt < 0) {
        throw new RuntimeException( getMessage( "VrExecQuery", rt ) );
      }

      // 出力実行
      rt = svf.VrPrint();
      if (rt < 0) {
        throw new RuntimeException( getMessage( "VrPrint", rt ) );
      }

    } finally {

      // リソース開放・出力サイズ取得
      size = svf.VrQuit();

    }

    // 終了処理で問題があった場合
    if (size < 0) {
      throw new RuntimeException( getMessage( "VrQuit", size ) );
    }

    // 出力サイズを戻す
    return size;
  }
}
