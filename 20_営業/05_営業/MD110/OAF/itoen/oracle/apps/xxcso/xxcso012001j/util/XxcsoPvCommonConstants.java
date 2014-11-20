/*============================================================================
* �t�@�C���� : XxcsoPvCommonConstants
* �T�v����   : �����ėp�����^�p�[�\�i���C�Y�r���[���ʌŒ�l�N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-09 1.0  SCS�������l  �V�K�쐬
* 2009-04-24 1.1  SCS�������l  [ST��QT1_634]��ƈ˗����t���O�ǉ��Ή�
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso012001j.util;

/*******************************************************************************
 * �����ėp�����^�p�[�\�i���C�Y�r���[���ʌŒ�l�N���X
 * @author  SCS�������l
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoPvCommonConstants 
{
  /*****************************************************************************
   * URL�p�����[�^
   *****************************************************************************
   */
  public static final String EXECUTE_MODE_QUERY    = "QUERY";
  public static final String EXECUTE_MODE_CREATE   = "CREATE";
  public static final String EXECUTE_MODE_COPY     = "COPY";
  public static final String EXECUTE_MODE_UPDATE   = "UPDATE";

  public static final String PV_DISPLAY_MODE_1     = "1";
  public static final String PV_DISPLAY_MODE_2     = "2";

  /*****************************************************************************
   * �v���t�@�C���I�v�V�����l
   *****************************************************************************
   */
  public static final String XXCSO1_IB_PV_D_VIEW_LINES
                                                  = "XXCSO1_IB_PV_D_VIEW_LINES";

  /*****************************************************************************
   * �A�h�o���X�e�[�u�����[�W������
   *****************************************************************************
   */
  public static final String EXTRACT_CONDITION_ADV_TBL_RN
                                                  = "ExtractConditionAdvTblRN";

  public static final String SELECT_VIEW_ADV_TBL_RN = "SelectViewAdvTblRN";

  /*****************************************************************************
   * ��ʓ��Œ�l(�p�[�\�i���C�Y�r���[�쐬���)
   *****************************************************************************
   */

  // �p�[�\�i���C�Y�r���[�\�����
  public static final int    VIEW_ID_SEED             = -1;
  public static final String DEFAULT_FLAG_YES         = "Y";
  public static final String DEFAULT_FLAG_NO          = "N";
  public static final String KEY_VIEW_ID              = "VIEW_ID";
  public static final String KEY_VIEW_NAME            = "VIEW_NAME";
  public static final String KEY_EXEC_MODE            = "EXEC_MODE";


  /*****************************************************************************
   * ��ʓ��Œ�l(�p�[�\�i���C�Y�r���[�쐬���)
   *****************************************************************************
   */

  public static final int    SORT_SETTING_SIZE        = 3;
  public static final String SORT_LINE_CAPTION1       = "��";
  public static final String SORT_LINE_CAPTION2       = "�\�[�g";
  public static final String ADD_VIEW_NAME_COPY       = "�̕���";

// 2009/04/24 [ST��QT1_634] Mod Start
//  public static final int    EXTRACT_SIZE             = 78;
  public static final int    EXTRACT_SIZE             = 79;
// 2009/04/24 [ST��QT1_634] Mod End
  public static final String EXTRACT_RENDER           = "ExtractRender";
  public static final String EXTRACT_AND              = "1";
  public static final String EXTRACT_OR               = "2";

  public static final String EXTRACT_VALUE_010        = "010";
  public static final String EXTRACT_VALUE_030        = "030";
  public static final String EXTRACT_VALUE_090        = "090";

  public static final String EXTRACT_TYPE_VARCHAR2    = "VARCHAR2";
  public static final String EXTRACT_TYPE_NUMBER      = "NUMBER";
  public static final String EXTRACT_TYPE_DATE        = "DATE";
  
  public static final String VIEW_OPEN_CODE_OPEN      = "1";
  public static final String VIEW_OPEN_CODE_CLOSE     = "0";

  /*****************************************************************************
   * ��ʓ��Œ�l (�������ėp�������)
   *****************************************************************************
   */
  public static final String FLAG_ENABLE              = "1";

  public static final String EXTRACT_FIRST            = "1 = 1";

  public static final String COMMA                    = ",";
  public static final String SPACE                    = " ";
  public static final String SINGLE_QUOTE             = "'";

  public static final String METHOD_CONTAIN           = "3";
  public static final String METHOD_START             = "4";
  public static final String METHOD_END               = "5";

  public static final String REPLACE_WORD             = ":\\$V1";

  public static final String KEY_ID                   = "ID";
  public static final String KEY_NAME                 = "NAME";
  public static final String KEY_ATTR_NAME            = "ATTR_NAME";
  public static final String KEY_DATA_TYPE            = "DATA_TYPE";

  public static final String VIEW_NAME                = "InstallBasePvSumVO";

  public static final String RN_TABLE_LAYOUT_CELL0301 = "PvDesignCfRN0301";
  // �����ėp���Table�̌Œ�l
  public static final String RN_TABLE                 = "InstallBaseTblRN";

  public static final String TABLE_WIDTH              = "100%";

  // �ڍ�image�̌Œ�l
  public static final String IMAGE_LABEL              = "�ڍׂ̕\��"; 
  public static final String IMAGE_SOURCE
                                 = "/OA_MEDIA/eyeglasses_24x24_transparent.gif"; 
  public static final String IMAGE_SHORT_DESC         = "�ڍׂ̕\��"; 
  public static final String IMAGE_VIEW_ATTR          = "InstanceId"; 
  public static final String IMAGE_ACTION_NAME        = "DetailIconClick"; 
  public static final String IMAGE_FIRE_ACTION_NAME   = "SelectedInstanceId"; 
  public static final String IMAGE_FIRE_ACTION_PARAM  = "{$InstanceId}"; 
  public static final String IMAGE_HEIGHT             = "25"; 
  public static final String IMAGE_WIDTH              = "25"; 

  /*****************************************************************************
   * Switcher��
   *****************************************************************************
   */
  public static final String UPDATE_ENABLED           = "UpdateEnabled";
  public static final String UPDATE_DISABLED          = "UpdateDisabled";
  public static final String DELETE_ENABLED           = "DeleteEnabled";
  public static final String DELETE_DISABLED          = "DeleteDisabled";
  public static final String DEFAULT_FLAG             = "DefaultFlag";

  /*****************************************************************************
   * ���b�Z�[�W�pTOKEN
   *****************************************************************************
   */
  // �p�[�\�i���C�Y�r���[�\�����
  public static final String MSG_RECORD              = "���R�[�h";
  public static final String MSG_VIEW                = "�r���[";
  public static final String MSG_VIEW_NAME           = "�r���[��";

  // �p�[�\�i���C�Y�r���[�쐬���
  public static final String MSG_EXTRACT_COLUMN      = "��������";
  public static final String MSG_EXTRACT_TOKEN_010   = "���_�R�[�h";
  public static final String MSG_EXTRACT_TOKEN_030   = "�����R�[�h";
  public static final String MSG_EXTRACT_TOKEN_090   = "�ڋq�R�[�h";

}