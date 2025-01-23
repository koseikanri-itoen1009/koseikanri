/*===========================================================================
* �t�@�C���� : XxccdSvfUtils.java
* �T�v����   : WingArc1st SVF ���[�e�B���e�B
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2024-03-13 1.0  SCSK �v�ۓc  �V�K�쐬
*============================================================================
*/
package jp.co.itoen.xxccd.xxccd10402;

import java.text.MessageFormat;

import jp.co.fit.vfreport.Vrw32;

/******************************************************************************
 * ���[�o�͂��w�����A�o�͂��ꂽ�t�@�C����Object Storage�ɃA�b�v���[�h���܂��B
 * @author  SCSK �v�ۓc
 * @version 1.0
 ******************************************************************************
 */
public class XxccdSvfUtils
{
  /******************************************************************************
   * �萔�ݒ�
   *****************************************************************************/
  // ���P�[���F���{
  private static String SVF_LOCALE = "ja";
  // �G���R�[�f�B���O�FSJIS
  private static String SVF_ENCODING = "MS932";
  // �o�͐�v�����^�FPDF
  private static String SVF_PRINTER = "PDF";
  // �N�G���w�胂�[�h�F�N�G���[�l���t�@�C��
  private static int SVF_QUERY_MODE = 0;
  // ���o�������[�h�F�݌v���Ɏw�肵���������ɒǉ�
  private static int SVF_COND_MODE = 1;
  // �f�[�^�Ȃ����b�Z�[�W�t�B�[���h��
  private static String NODATA_MSG_FIELD = "NODATA_MSG";

  // ���b�Z�[�W�t�H�[�}�b�g
  private static MessageFormat mf = new MessageFormat( "Error at {0} with code [{1}]." );

  /******************************************************************************
   * �R���X�g���N�^
   ******************************************************************************
   */
  public XxccdSvfUtils () {
  }

  /******************************************************************************
   * ���b�Z�[�W���쐬����֐�
   * @param methodName       ���\�b�h��
   * @param returnCode       �I���R�[�h
   * @return                 �쐬���ꂽ���b�Z�[�W
   ******************************************************************************
   */
  private String getMessage ( String methodName, int returnCode )
  {
    return mf.format( new Object[]{ methodName, new Integer(returnCode) }, new StringBuffer(), null ).toString();
  }

  /******************************************************************************
   * ���̓p�����[�^�ɏ]��SVF�֒��[�o�͂��w������֐�
   * @param userId           ���[�U�[
   * @param password         �p�X���[�h
   * @param hostname         SVF�T�[�o                 ���{�@�\�ł͎g�p���܂���
   * @param formFile         �t�H�[���l���t�@�C���p�X
   * @param queryFile        �N�G���[�l���t�@�C���p�X
   * @param orgId            �g�DID                    ���{�@�\�ł͎g�p���܂���
   * @param spoolName        �t�@�C���X�v�[����
   * @param message          NO DATA���b�Z�[�W         ���{�@�\�ł͎g�p���܂���
   * @param formMode         �t�H�[���l�����[�h
   * @param args             �ϒ�����
   * @return                 �쐬���ꂽ���[�̃t�@�C���T�C�Y
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
    // �ϐ��錾
    int rt = 0;
    int size = 0;

    // SVF Connect for Java API �C���X�^���X����
    Vrw32 svf = new Vrw32();

    try {

      // ���P�[�����w��
      rt = svf.VrSetLocale( SVF_LOCALE );
      if (rt < 0) {
        throw new RuntimeException( getMessage( "VrSetLocale", rt ) );
      }

      // �p�����[�^�̃G���R�[�f�B���O���w��
      rt = svf.VrInit( SVF_ENCODING );
      if (rt < 0) {
        throw new RuntimeException( getMessage( "VrInit", rt ) );
      }

      // �o�͐�̃v�����^���w��
      rt = svf.VrSetPrinter("", SVF_PRINTER);
      if (rt < 0) {
        throw new RuntimeException( getMessage( "VrSetPrinter", rt ) );
      }

      // �t�@�C���o�͐�i�X�v�[����j���w��
      rt = svf.VrSetSpoolFileName2( spoolName );
      if (rt < 0) {
        throw new RuntimeException( getMessage( "VrSetSpoolFileName2", rt ) );
      }

      // �t�H�[���l���t�@�C���E�t�H�[���l�����[�h�w��
      rt = svf.VrSetForm( formFile, formMode );
      if (rt < 0) {
        throw new RuntimeException( getMessage( "VrSetForm", rt ) );
      }

      // �N�G���[�l���t�@�C�����w��
      String conn = "UID=" + userId + ";PWD=" + password;
      rt = svf.VrSetQuery( conn, queryFile, SVF_QUERY_MODE );
      if (rt < 0) {
        throw new RuntimeException( getMessage( "VrSetQuery", rt ) );
      }

      // �ϒ��������w�肳��Ă���ꍇ�A�w�肳�ꂽ���������o������ǉ�
      if ( args.length > 0 ) {

        StringBuffer condition = new StringBuffer();
        for ( String arg : args ) {

          // ������NULL�Ȃ�ȍ~���������Ȃ�
          if ( arg == null || arg.length() == 0) {
            break;
          }

          // ������ǉ�
          if ( condition.length() == 0 ) {

            // �ŏ��͂��̂܂ܐݒ�
            condition.append( arg );

          } else {

            // 2�Ԗڈȍ~��AND�ŘA��
            condition.append( " AND " + arg );

          }
        }

        // ���o������ǉ�
        rt = svf.VrCondition( condition.toString(), SVF_COND_MODE);
        if (rt < 0) {
          throw new RuntimeException( getMessage( "VrCondition", rt ));
        }
      }

      // SVF�N�G���[���s
      rt = svf.VrExecQuery();

      // ���R�[�h���Ȃ��ꍇ(-554)�́A�f�[�^�Ȃ����b�Z�[�W�݂̂ŏo��
      if (rt == -554) {
        rt = svf.VrsOut( NODATA_MSG_FIELD, message );
        if (rt < 0) {
          throw new RuntimeException( getMessage( "VrsOut", rt ) );
        }

        // �y�[�W�I��
        rt = svf.VrEndRecord();
        if (rt < 0) {
          throw new RuntimeException( getMessage( "VrEndRecord", rt ) );
        }

      // ���R�[�h���Ȃ��ꍇ(-554)�ȊO�̃G���[
      } else if (rt < 0) {
        throw new RuntimeException( getMessage( "VrExecQuery", rt ) );
      }

      // �o�͎��s
      rt = svf.VrPrint();
      if (rt < 0) {
        throw new RuntimeException( getMessage( "VrPrint", rt ) );
      }

    } finally {

      // ���\�[�X�J���E�o�̓T�C�Y�擾
      size = svf.VrQuit();

    }

    // �I�������Ŗ�肪�������ꍇ
    if (size < 0) {
      throw new RuntimeException( getMessage( "VrQuit", size ) );
    }

    // �o�̓T�C�Y��߂�
    return size;
  }
}
