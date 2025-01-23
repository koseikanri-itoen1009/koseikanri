/*===========================================================================
* �t�@�C���� : Xxccd10402.java
* �T�v����   : SVF���[����Java
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2024-03-13 1.0  SCSK �v�ۓc  �V�K�쐬
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
 * ���[�o�͂��w�����A�o�͂��ꂽ�t�@�C����Object Storage�ɃA�b�v���[�h���܂��B
 * @author  SCSK �v�ۓc
 * @version 1.0
 *******************************************************************************
 */
public class Xxccd10402
{
  /******************************************************************************
   * �萔�ݒ�
   *****************************************************************************/
  // �Œ�����̐�
  private static int FIXED_ARGS = 13;
  // �ψ����̐�
  private static int FLEX_ARGS = 15;
  // �p�X���[�h��֕\��
  private static String PASS_STRING = "***";
  // ���\�[�X
  private static ResourceBundle rb = ResourceBundle.getBundle( Xxccd10402.class.getSimpleName(), Locale.JAPANESE );
  // ���K�[
  private static Logger logger = LoggerFactory.getLogger( Xxccd10402.class );

  /******************************************************************************
   * ���b�Z�[�W���o�͂���֐�
   * @param name             ���b�Z�[�W��
   * @param args             ���ߍ��݃g�[�N��
   ******************************************************************************
   */
  private static void info ( String name, String ... args )
  {
    logger.info( rb.getString( name ), (Object[])args );
  }

  /******************************************************************************
   * �f�o�b�O���b�Z�[�W���o�͂���֐�
   * @param name             ���b�Z�[�W��
   * @param args             ���ߍ��݃g�[�N��
   ******************************************************************************
   */
  private static void debug ( String name, String ... args )
  {
    logger.debug( rb.getString( name ), (Object[])args );
  }

  /******************************************************************************
   * �G���[���b�Z�[�W���o�͂���֐�
   * @param t                ��O
   ******************************************************************************
   */
  private static void error ( Throwable t )
  {
    logger.error( rb.getString( "message.main.error" ), t );
  }

  /*****************************************************************************
   * ���̓p�����[�^�ɏ]��SVF�֒��[�o�͂��w������
   * @param args[0]          ���[�U�[ID
   * @param args[1]          �p�X���[�h
   * @param args[2]          SVF�T�[�o
   * @param args[3]          �t�H�[���l���t�@�C���p�X
   * @param args[4]          �N�G���[�l���t�@�C���p�X
   * @param args[5]          �g�DID
   * @param args[6]          �t�@�C���X�v�[����
   * @param args[7]          NO DATA���b�Z�[�W
   * @param args[8]          �t�H�[���l�����[�h
   * @param args[9]          ���[�W����
   * @param args[10]         �l�[���X�y�[�X
   * @param args[11]         �o�P�b�g��
   * @param args[12]         �o�̓t�@�C����
   * @param args[13]         �σp�����[�^�P
   * ...
   * @param args[27]         �σp�����[�^�P�T
   *****************************************************************************
   */
  public static void main (
      String[] args
  ) throws Exception
  {
    // �J�n���O
    info( "message.main.start");

    try {

      // �ψ������������i�����ɂ���ΐݒ�Ȃ����NULL�j
      String[] conds = new String[ FLEX_ARGS ];
      for ( int i=0; i<FLEX_ARGS; i++) {
        conds[i] = ( args.length >  i + FIXED_ARGS ) ? args[ i + FIXED_ARGS ] : null;
      }

      // �������f�o�b�O���O�ɏo�́i�p�X���[�h��***�ŏo�́j
      if ( logger.isDebugEnabled() ) {
        debug( "message.main.parameter", String.valueOf(0), args[0]) ;
        debug( "message.main.parameter", String.valueOf(1), ( args[1].length() > 0 ) ? PASS_STRING : null );
        for ( int i=2; i<FIXED_ARGS + FLEX_ARGS; i++) {
          debug( "message.main.parameter", String.valueOf(i+1), ( args.length >  i ) ? args[i] : null );
        }
      }

      // ���[�o�̓T�C�Y������
      int size = 0;

      // SVF�C���X�^���X�쐬
      XxccdSvfUtils svf = new XxccdSvfUtils();

      // ���[�o��
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

      // �X�e�b�v���O�o��
      info( "message.svf.complete", String.valueOf(size) );

      // ObjectStorage�̃t�H���_��t���i�擾�ł��Ȃ��ꍇ�̓t�@�C�����̂܂܁j
      String fileName = args[12];
      try {
        fileName = rb.getString( "obs.folder" ) + "/" + args[12];
      } catch ( Exception e ) {
        debug( "message.main.missing", e.getMessage() );
      }

      // OBS�C���X�^���X�쐬
      XxccdObsUtils obs = new XxccdObsUtils();

      // �t�@�C���A�b�v���[�h
      obs.uploadFile (
          args[6]
        , args[9]
        , args[10]
        , args[11]
        , fileName
      );

      // �X�e�b�v���O�o��
      info( "message.oci.complete" );

    // ��O����
    } catch ( Exception e ) {

      // �G���[���o��
      error( e );

      // �G���[���đ�
      throw e;

    }

    // �I�����O
    info( "message.main.end");
  }
}
