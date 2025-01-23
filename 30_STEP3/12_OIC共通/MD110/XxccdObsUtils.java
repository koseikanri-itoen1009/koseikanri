/*===========================================================================
* ファイル名 : XxccdObsUtils.java
* 概要説明   : Oracle Cloud Infrastructure Object Storage ユーティリティ
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2024-03-13 1.0  SCSK 久保田  新規作成
*============================================================================
*/
package jp.co.itoen.xxccd.xxccd10402;

import java.io.File;
import java.io.InputStream;
import java.io.FileInputStream;
import java.io.BufferedInputStream;
import java.io.IOException;

import com.oracle.bmc.ConfigFileReader;
import com.oracle.bmc.ConfigFileReader.ConfigFile;
import com.oracle.bmc.auth.AuthenticationDetailsProvider;
import com.oracle.bmc.auth.ConfigFileAuthenticationDetailsProvider;
import com.oracle.bmc.objectstorage.ObjectStorage;
import com.oracle.bmc.objectstorage.ObjectStorageClient;
import com.oracle.bmc.objectstorage.requests.PutObjectRequest;
import com.oracle.bmc.objectstorage.responses.PutObjectResponse;
import com.oracle.bmc.objectstorage.requests.GetObjectRequest;
import com.oracle.bmc.objectstorage.responses.GetObjectResponse;
import com.oracle.bmc.model.BmcException;

/*******************************************************************************
 * 帳票出力を指示し、出力されたファイルをObject Storageにアップロードします。
 * @author  SCSK 久保田
 * @version 1.0
 *******************************************************************************
 */
public class XxccdObsUtils
{
  /******************************************************************************
   * 定数設定
   *****************************************************************************/
  // OCI設定ファイル名
  private static String OCI_CONFIG = "/config";
  // 帳票CONTENT_TYPE
  private static String CONTENT_TYPE = "application/pdf";

  /******************************************************************************
   * コンストラクタ
   ******************************************************************************
   */
  public XxccdObsUtils () {
  }

  /*****************************************************************************
   * Object Storageへファイルをアップロードする関数
   * @param spoolName        入力ファイルパス
   * @param region           リージョン
   * @param namespace        ネームスペース
   * @param bucket           バケット名
   * @param outfile          出力ファイル名
   *****************************************************************************
   */
  public void uploadFile(
      String       spoolName
    , String       region
    , String       namespace
    , String       bucket
    , String       outfile
  ) throws BmcException, IOException, Exception
  {
    // 変数設定
    ObjectStorage client = null;
    InputStream is = null;
    
    try {

      // OCI設定ファイルパスをクラスパスから取得
      String configFile = XxccdObsUtils.class.getResource( OCI_CONFIG ).getPath();

      // OCI設定ファイルのバケット名と同名のセクションを読み込み
      ConfigFile config = ConfigFileReader.parse( configFile, bucket );

      // OCI認証プロバイダ作成
      AuthenticationDetailsProvider provider = new ConfigFileAuthenticationDetailsProvider( config );

      // OCI接続クライアント作成
      client = ObjectStorageClient.builder().build( provider );

      // リージョン設定
      client.setRegion( region );

      // 帳票ファイル指定
      File file = new File( spoolName );
      String name = file.getName();

      // 帳票ファイル読み込み
      is = new BufferedInputStream( new FileInputStream( file ) );

      // アップロードリクエスト作成
      PutObjectRequest request = PutObjectRequest.builder()
          .namespaceName( namespace )
          .bucketName( bucket )
          .objectName( outfile )
          .putObjectBody( is )
          .contentType( CONTENT_TYPE )
          .build();

      // アップロード
      PutObjectResponse response = client.putObject( request );

    } finally {

      // OCI接続クライアント作成済みならクローズ
      if ( client != null ) {
        client.close();
      }

      // 帳票ファイルを開いていたらクローズ
      if ( is != null ) {
        is.close();
      }
    }
  }
}
