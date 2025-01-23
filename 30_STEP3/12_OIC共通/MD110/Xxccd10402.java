/*===========================================================================
* ファイル名 : Xxccd10402.java
* 概要説明   : SVF帳票生成Java
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2024-03-13 1.0  SCSK 久保田  新規作成
*============================================================================
*/
package jp.co.itoen.xxccd.xxccd10402;

import java.util.Arrays;
import java.util.Locale;
import java.util.ResourceBundle;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import jp.co.itoen.xxccd.xxccd10402.XxccdSvfUtils;
import jp.co.itoen.xxccd.xxccd10402.XxccdObsUtils;

/*******************************************************************************
 * 帳票出力を指示し、出力されたファイルをObject Storageにアップロードします。
 * @author  SCSK 久保田
 * @version 1.0
 *******************************************************************************
 */
public class Xxccd10402
{
  /******************************************************************************
   * 定数設定
   *****************************************************************************/
  // 固定引数の数
  private static int FIXED_ARGS = 13;
  // 可変引数の数
  private static int FLEX_ARGS = 15;
  // パスワード代替表示
  private static String PASS_STRING = "***";
  // リソース
  private static ResourceBundle rb = ResourceBundle.getBundle( Xxccd10402.class.getSimpleName(), Locale.JAPANESE );
  // ロガー
  private static Logger logger = LoggerFactory.getLogger( Xxccd10402.class );

  /******************************************************************************
   * メッセージを出力する関数
   * @param name             メッセージ名
   * @param args             埋め込みトークン
   ******************************************************************************
   */
  private static void info ( String name, String ... args )
  {
    logger.info( rb.getString( name ), (Object[])args );
  }

  /******************************************************************************
   * デバッグメッセージを出力する関数
   * @param name             メッセージ名
   * @param args             埋め込みトークン
   ******************************************************************************
   */
  private static void debug ( String name, String ... args )
  {
    logger.debug( rb.getString( name ), (Object[])args );
  }

  /******************************************************************************
   * エラーメッセージを出力する関数
   * @param t                例外
   ******************************************************************************
   */
  private static void error ( Throwable t )
  {
    logger.error( rb.getString( "message.main.error" ), t );
  }

  /*****************************************************************************
   * 入力パラメータに従いSVFへ帳票出力を指示する
   * @param args[0]          ユーザーID
   * @param args[1]          パスワード
   * @param args[2]          SVFサーバ
   * @param args[3]          フォーム様式ファイルパス
   * @param args[4]          クエリー様式ファイルパス
   * @param args[5]          組織ID
   * @param args[6]          ファイルスプール先
   * @param args[7]          NO DATAメッセージ
   * @param args[8]          フォーム様式モード
   * @param args[9]          リージョン
   * @param args[10]         ネームスペース
   * @param args[11]         バケット名
   * @param args[12]         出力ファイル名
   * @param args[13]         可変パラメータ１
   * ...
   * @param args[27]         可変パラメータ１５
   *****************************************************************************
   */
  public static void main (
      String[] args
  ) throws Exception
  {
    // 開始ログ
    info( "message.main.start");

    try {

      // 可変引数を初期化（引数にあれば設定なければNULL）
      String[] conds = new String[ FLEX_ARGS ];
      for ( int i=0; i<FLEX_ARGS; i++) {
        conds[i] = ( args.length >  i + FIXED_ARGS ) ? args[ i + FIXED_ARGS ] : null;
      }

      // 引数をデバッグログに出力（パスワードは***で出力）
      if ( logger.isDebugEnabled() ) {
        debug( "message.main.parameter", String.valueOf(0), args[0]) ;
        debug( "message.main.parameter", String.valueOf(1), ( args[1].length() > 0 ) ? PASS_STRING : null );
        for ( int i=2; i<FIXED_ARGS + FLEX_ARGS; i++) {
          debug( "message.main.parameter", String.valueOf(i+1), ( args.length >  i ) ? args[i] : null );
        }
      }

      // 帳票出力サイズ初期化
      int size = 0;

      // SVFインスタンス作成
      XxccdSvfUtils svf = new XxccdSvfUtils();

      // 帳票出力
      size = svf.outputFile (
                 args[0]
               , args[1]
               , args[2]
               , args[3]
               , args[4]
               , Integer.parseInt(args[5])
               , args[6]
               , args[7]
               , Integer.parseInt(args[8])
               , conds[0]
               , conds[1]
               , conds[2]
               , conds[3]
               , conds[4]
               , conds[5]
               , conds[6]
               , conds[7]
               , conds[8]
               , conds[9]
               , conds[10]
               , conds[11]
               , conds[12]
               , conds[13]
               , conds[14]
             );

      // ステップログ出力
      info( "message.svf.complete", String.valueOf(size) );

      // ObjectStorageのフォルダを付加（取得できない場合はファイル名のまま）
      String fileName = args[12];
      try {
        fileName = rb.getString( "obs.folder" ) + "/" + args[12];
      } catch ( Exception e ) {
        debug( "message.main.missing", e.getMessage() );
      }

      // OBSインスタンス作成
      XxccdObsUtils obs = new XxccdObsUtils();

      // ファイルアップロード
      obs.uploadFile (
          args[6]
        , args[9]
        , args[10]
        , args[11]
        , fileName
      );

      // ステップログ出力
      info( "message.oci.complete" );

    // 例外処理
    } catch ( Exception e ) {

      // エラーを出力
      error( e );

      // エラーを再送
      throw e;

    }

    // 終了ログ
    info( "message.main.end");
  }
}
