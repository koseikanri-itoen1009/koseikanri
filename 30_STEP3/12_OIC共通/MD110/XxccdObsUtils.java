/*===========================================================================
* �t�@�C���� : XxccdObsUtils.java
* �T�v����   : Oracle Cloud Infrastructure Object Storage ���[�e�B���e�B
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2024-03-13 1.0  SCSK �v�ۓc  �V�K�쐬
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
 * ���[�o�͂��w�����A�o�͂��ꂽ�t�@�C����Object Storage�ɃA�b�v���[�h���܂��B
 * @author  SCSK �v�ۓc
 * @version 1.0
 *******************************************************************************
 */
public class XxccdObsUtils
{
  /******************************************************************************
   * �萔�ݒ�
   *****************************************************************************/
  // OCI�ݒ�t�@�C����
  private static String OCI_CONFIG = "/config";
  // ���[CONTENT_TYPE
  private static String CONTENT_TYPE = "application/pdf";

  /******************************************************************************
   * �R���X�g���N�^
   ******************************************************************************
   */
  public XxccdObsUtils () {
  }

  /*****************************************************************************
   * Object Storage�փt�@�C�����A�b�v���[�h����֐�
   * @param spoolName        ���̓t�@�C���p�X
   * @param region           ���[�W����
   * @param namespace        �l�[���X�y�[�X
   * @param bucket           �o�P�b�g��
   * @param outfile          �o�̓t�@�C����
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
    // �ϐ��ݒ�
    ObjectStorage client = null;
    InputStream is = null;
    
    try {

      // OCI�ݒ�t�@�C���p�X���N���X�p�X����擾
      String configFile = XxccdObsUtils.class.getResource( OCI_CONFIG ).getPath();

      // OCI�ݒ�t�@�C���̃o�P�b�g���Ɠ����̃Z�N�V������ǂݍ���
      ConfigFile config = ConfigFileReader.parse( configFile, bucket );

      // OCI�F�؃v���o�C�_�쐬
      AuthenticationDetailsProvider provider = new ConfigFileAuthenticationDetailsProvider( config );

      // OCI�ڑ��N���C�A���g�쐬
      client = ObjectStorageClient.builder().build( provider );

      // ���[�W�����ݒ�
      client.setRegion( region );

      // ���[�t�@�C���w��
      File file = new File( spoolName );
      String name = file.getName();

      // ���[�t�@�C���ǂݍ���
      is = new BufferedInputStream( new FileInputStream( file ) );

      // �A�b�v���[�h���N�G�X�g�쐬
      PutObjectRequest request = PutObjectRequest.builder()
          .namespaceName( namespace )
          .bucketName( bucket )
          .objectName( outfile )
          .putObjectBody( is )
          .contentType( CONTENT_TYPE )
          .build();

      // �A�b�v���[�h
      PutObjectResponse response = client.putObject( request );

    } finally {

      // OCI�ڑ��N���C�A���g�쐬�ς݂Ȃ�N���[�Y
      if ( client != null ) {
        client.close();
      }

      // ���[�t�@�C�����J���Ă�����N���[�Y
      if ( is != null ) {
        is.close();
      }
    }
  }
}
