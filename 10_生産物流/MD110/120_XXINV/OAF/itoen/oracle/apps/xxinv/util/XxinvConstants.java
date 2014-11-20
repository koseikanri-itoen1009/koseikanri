/*============================================================================
* �t�@�C���� : XxinvConstants
* �T�v����   : INV���ʒ萔
* �o�[�W���� : 1.3
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-02-21 1.0  ������j     �V�K�쐬
* 2008-06-18 1.1  �勴�F�Y     �s��w�E�����C��
* 2008-07-10 1.2  �ɓ��ЂƂ�   �����ύX
* 2008-09-24 1.3  �ɓ��ЂƂ�   �����e�X�g �w�E156
*============================================================================
*/
package itoen.oracle.apps.xxinv.util;
import oracle.jbo.domain.Number;
/***************************************************************************
 * INV���ʒ萔�N���X�ł��B
 * @author  ORACLE ������j
 * @version 1.3
 ***************************************************************************
 */
public class XxinvConstants 
{
  /** �g�����U�N�V�������FXxinv990001jTxn */
  public static final String TXN_XXINV990001J = "Xxinv990001jTxn";
  /** �g�����U�N�V�������FXxinv510001jTxn */
  public static final String TXN_XXINV510001J = "Xxinv510001jTxn";
  /** �g�����U�N�V�������FXxinv510002jTxn */
  public static final String TXN_XXINV510002J = "Xxinv510002jTxn";
  /** �N���X���FXxinvUtility */
  public static final String CLASS_XXINV_UTILITY   = "itoen.oracle.apps.xxinv.util.XxinvUtility";
  /** �N���X���FXxpoSupplierResultsMakeAMImpl */
  public static final String CLASS_AM_XXINV510001J = "itoen.oracle.apps.xxinv.xxinv510001j.server.XxinvMovementResultsHdAMImpl";
  /** �Z�[�u�|�C���g���FXXINV510001J */
  public static final String SAVE_POINT_XXINV510001J  = "XXINV510001J";
  /** URL�F���o�Ɏ��їv���� */
  public static final String URL_XXINV510001JS = "OA.jsp?page=/itoen/oracle/apps/xxinv/xxinv510001j/webui/XxinvMovementResultsPG";
  /** URL�F���o�Ɏ��уw�b�_��� */
  public static final String URL_XXINV510001JH = "OA.jsp?page=/itoen/oracle/apps/xxinv/xxinv510001j/webui/XxinvMovementResultsHdPG";
  /** URL�F���o�Ɏ��і��׉�� */
  public static final String URL_XXINV510001JL = "OA.jsp?page=/itoen/oracle/apps/xxinv/xxinv510001j/webui/XxinvMovementResultsLnPG";
  /** URL�F�o�Ƀ��b�g���׉�� */
  public static final String URL_XXINV510002J_1 = "OA.jsp?page=/itoen/oracle/apps/xxinv/xxinv510002j/webui/XxinvMovementShippedLotPG";
  /** URL�F���Ƀ��b�g���׉�� */
  public static final String URL_XXINV510002J_2 = "OA.jsp?page=/itoen/oracle/apps/xxinv/xxinv510002j/webui/XxinvMovementShipToLotPG";
  /** URL�p�����[�^ID�F�����p�ړ��w�b�_ID */
  public static final String URL_PARAM_SEARCH_MOV_ID   = "pSearchMovHdrId";
  /** URL�p�����[�^ID�F�X�V�t���O */
  public static final String URL_PARAM_UPDATE_FLAG   = "pUpdateFlag";
  /** URL�p�����[�^ID�F�]�ƈ��敪 */
  public static final String URL_PARAM_PEOPLE_CODE   = "pPeopleCode";
  /** URL�p�����[�^ID�F���уf�[�^�敪 */
  public static final String URL_PARAM_ACTUAL_FLAG   = "pActualFlg";
  /** URL�p�����[�^ID�F���i���ʋ敪 */
  public static final String URL_PARAM_PRODUCT_FLAG   = "pProductFlg";
  /** URL�p�����[�^ID�F���i�敪 */
  public static final String URL_PARAM_ITEM_CLASS   = "pItemClass";
  /** URL�p�����[�^ID�F�����p�ړ�����ID */
  public static final String URL_PARAM_SEARCH_MOV_LINE_ID = "pSearchMovLineId";
  /** URL�p�����[�^ID�F�O���URL */
  public static final String URL_PARAM_PREV_URL     = "pPrevUrl";
  /** �����t���O�F1 �o�^ */
  public static final String PROCESS_FLAG_I = "1";
  /** �����t���O�F2 �X�V */
  public static final String PROCESS_FLAG_U = "2";
  /** �o�^�t���O�F1 �w������V�K�o�^ */
  public static final String INPUT_FLAG_1 = "1";
  /** �o�^�t���O�F2 �w���Ȃ��V�K�o�^ */
  public static final String INPUT_FLAG_2 = "2";
  /** �]�ƈ��敪�F1 ���� */
  public static final String PEOPLE_CODE_I = "1";
  /** �]�ƈ��敪�F2 �O�� */
  public static final String PEOPLE_CODE_O = "2";
  /** �X�e�[�^�X�F01 �˗��� */
  public static final String STATUS_01 = "01";
  /** �X�e�[�^�X�F02 �˗��� */
  public static final String STATUS_02 = "02";
  /** �X�e�[�^�X�F03 ������ */
  public static final String STATUS_03 = "03";
  /** �X�e�[�^�X�F04 �o�ɕ񍐗L */
  public static final String STATUS_04 = "04";
  /** �X�e�[�^�X�F05 ���ɕ񍐗L */
  public static final String STATUS_05 = "05";
  /** �X�e�[�^�X�F06 ���o�ɕ񍐗L */
  public static final String STATUS_06 = "06";
  /** �X�e�[�^�X�F99 ��� */
  public static final String STATUS_99 = "99";
  /** �ړ��^�C�v�F1 �ϑ����� */
  public static final String MOV_TYPE_1 = "1";
  /** �ړ��^�C�v�F2 �ϑ��Ȃ� */
  public static final String MOV_TYPE_2 = "2";
  /** �ʒm�X�e�[�^�X�R�[�h�F10 ���ʒm */
  public static final String NOTIFSTATSU_CODE_1O = "10";
  /** �ʒm�X�e�[�^�X�F���ʒm */
  public static final String NOTIFSTATSU_NAME_1O = "���ʒm";
  /** �^���敪�F0 �� */
  public static final String FREIGHT_CHARGE_CLASS_0 = "0";
  /** �^���敪�F1 �L */
  public static final String FREIGHT_CHARGE_CLASS_1 = "1";
  /** �d�ʗe�ϋ敪�R�[�h�F1 �d�� */
  public static final String WEIGHT_CAPACITY_CLASS_CODE_1 = "1";
  /** �d�ʗe�ϋ敪�F1 �d�� */
  public static final String WEIGHT_CAPACITY_CLASS_NAME_1 = "�d��";
  /** �d�ʗe�ϋ敪�R�[�h�F2 �e�� */
  public static final String WEIGHT_CAPACITY_CLASS_CODE_2 = "2";
  /** �d�ʗe�ϋ敪�F2 �e�� */
  public static final String WEIGHT_CAPACITY_CLASS_NAME_2 = "�e��";
  /** ���ьv��σt���O�FY ���ьv��� */
  public static final String COMP_ACTUAL_FLG_Y = "Y";
  /** ���ьv��σt���O�FN ���і��v�� */
  public static final String COMP_ACTUAL_FLG_N = "N";
  /** �i�ڋ敪�F5 ���i */
  public static final String ITEM_CLASS_5 = "5";
  /** ���R�[�h�^�C�v�F10 �w�� */
  public static final String RECORD_TYPE_10 = "10";
  /** ���R�[�h�^�C�v�F20 �o�Ɏ��� */
  public static final String RECORD_TYPE_20 = "20";
  /** ���R�[�h�^�C�v�F30 ���Ɏ��� */
  public static final String RECORD_TYPE_30 = "30";
  /** �N���p�����[�^�� */
  public static final String XXINV990001J_PARAM = "CONTENT_TYPE";
  /** ���b�Z�[�W�FAPP-XXINV-10005 �R���J�����g�N���G���[ */
  public static final String XXINV10005   = "APP-XXINV-10005";
  /** ���b�Z�[�W�FAPP-XXINV-10006 �R���J�����g�N�����탁�b�Z�[�W */
  public static final String XXINV10006   = "APP-XXINV-10006";
  /** ���b�Z�[�W�FAPP-XXINV-10009 �f�[�^�擾�G���[ */
  public static final String XXINV10009   = "APP-XXINV-10009";
  /** ���b�Z�[�W�FAPP-XXINV-10131 ���ѓ������̓��b�Z�[�W */
  public static final String XXINV10131   = "APP-XXINV-10131";
  /** ���b�Z�[�W�FAPP-XXINV-10034 �قȂ���t���b�Z�[�W */
  public static final String XXINV10034   = "APP-XXINV-10034";
  /** ���b�Z�[�W�FAPP-XXINV-10043 �����������w��G���[ */
  public static final String XXINV10043   = "APP-XXINV-10043";
  /** ���b�Z�[�W�FAPP-XXINV-10055 ���t�t�]�G���[ */
  public static final String XXINV10055   = "APP-XXINV-10055";
  /** ���b�Z�[�W�FAPP-XXINV-10058 ��ғ����G���[ */
  public static final String XXINV10058   = "APP-XXINV-10058";
  /** ���b�Z�[�W�FAPP-XXINV-10063 �i�ڏd���G���[ */
  public static final String XXINV10063   = "APP-XXINV-10063";
  /** ���b�Z�[�W�FAPP-XXINV-10064 �ۊǑq�ɖ����̓��b�Z�[�W */
  public static final String XXINV10064   = "APP-XXINV-10064";
  /** ���b�Z�[�W�FAPP-XXINV-10066 �������G���[(�o�ɓ�) */
  public static final String XXINV10066   = "APP-XXINV-10066";
  /** ���b�Z�[�W�FAPP-XXINV-10067 �������G���[(����) */
  public static final String XXINV10067   = "APP-XXINV-10067";
  /** ���b�Z�[�W�FAPP-XXINV-10120 �݌Ɋ��ԃG���[ */
  public static final String XXINV10120   = "APP-XXINV-10120";
  /** ���b�Z�[�W�FAPP-XXINV-10158 �X�V�������b�Z�[�W */
  public static final String XXINV10158   = "APP-XXINV-10158";
  /** ���b�Z�[�W�FAPP-XXINV-10159 ���b�N���s�G���[ */
  public static final String XXINV10159   = "APP-XXINV-10159";
  /** ���b�Z�[�W�FAPP-XXINV-10030 �}�C�i�X�l�G���[���b�Z�[�W */
  public static final String XXINV10030   = "APP-XXINV-10030";
  /** ���b�Z�[�W�FAPP-XXINV-10033 ���b�g���擾�G���[���b�Z�[�W */
  public static final String XXINV10033   = "APP-XXINV-10033";
  /** ���b�Z�[�W�FAPP-XXINV-10129 ���b�gNo�d���G���[ */
  public static final String XXINV10129   = "APP-XXINV-10129";
  /** ���b�Z�[�W�FAPP-XXINV-10130 ���b�g�t�]�h�~�`�F�b�N�G���[���b�Z�[�W */
  public static final String XXINV10130   = "APP-XXINV-10130";
  /** ���b�Z�[�W�FAPP-XXINV-10128 �K�{�G���[ */
  public static final String XXINV10128   = "APP-XXINV-10128";
  /** ���b�Z�[�W�FAPP-XXINV-10127 �d�ʗe�Ϗ������X�V�G���[���b�Z�[�W */
  public static final String XXINV10127   = "APP-XXINV-10127";
  /** ���b�Z�[�W�FAPP-XXINV-10160 ���l�s���G���[ */
  public static final String XXINV10160   = "APP-XXINV-10160";
  /** ���b�Z�[�W�FAPP-XXINV-10161 �o�^�������b�Z�[�W */
  public static final String XXINV10161   = "APP-XXINV-10161";
  /** ���b�Z�[�W�FAPP-XXINV-10165 ���b�g�X�e�[�^�X�G���[���b�Z�[�W */
  public static final String XXINV10165 = "APP-XXINV-10165";
  /** ���b�Z�[�W�FAPP-XXINV-10061 �K�{�`�F�b�N�G���[���b�Z�[�W */
  public static final String XXINV10061 = "APP-XXINV-10061"; // add ver1.1
  /** ���b�Z�[�W�FAPP-XXINV-10119 ���o�ɕۊǑq�ɃG���[���b�Z�[�W */
  public static final String XXINV10119 = "APP-XXINV-10119"; // add ver1.3
  /** �g�[�N���FSHIP_DATE */
  public static final String TOKEN_SHIP_DATE       = "SHIP_DATE";
  /** �g�[�N���FARRIVAL_DATE */
  public static final String TOKEN_ARRIVAL_DATE    = "ARRIVAL_DATE";
  /** �g�[�N���FTAGET_DATE */
  public static final String TOKEN_TARGET_DATE     = "TARGET_DATE";
  /** �g�[�N���FPROGRAM */
  public static final String TOKEN_PROGRAM         = "PROGRAM";
  /** �g�[�N���FID */
  public static final String TOKEN_ID              = "ID";
  /** �g�[�N���FMSG */
  public static final String TOKEN_MSG              = "MSG";
  /** �g�[�N���FITEM */
  public static final String TOKEN_ITEM = "ITEM";
  /** �g�[�N���FLOT */
  public static final String TOKEN_LOT = "LOT";
  /** �g�[�N���FLOCATION */
  public static final String TOKEN_LOCATION = "LOCATION";
  /** �g�[�N���FREVDATE */
  public static final String TOKEN_REVDATE = "REVDATE";
  /** �g�[�N���FLOT_STATUS */
  public static final String TOKEN_LOT_STATUS = "LOT_STATUS";
  /** �g�[�N�����́F�o�ɓ�(����) */
  public static final String TOKEN_NAME_SHIP_DATE    = "�o�ɓ�(����)";
  /** �g�[�N�����́F����(����) */
  public static final String TOKEN_NAME_ARRIVAL_DATE = "����(����)";
  /** �g�[�N�����́F�ړ����o�Ɏ��ѓo�^���� */
  public static final String TOKEN_NAME_MOV_ACTUAL_MAKE = "�ړ����o�Ɏ��ѓo�^����";
  /** �g�[�N�����́F�ő�z���敪 */
  public static final String TOKEN_NAME_MAX_SHIP_METHOD = "�ő�z���敪";
  /** �g�[�N�����́F�i�� */
  public static final String TOKEN_NAME_ITEM = "�i��";  // add ver1.1
  /** �y�[�W�^�C�g���̌Œ蕔�� (�u�t�@�C���A�b�v���[�h�F�@�v)*/
  public static final String DISP_TEXT = "�t�@�C���A�b�v���[�h�F";
  /** �Q�ƃ^�C�v �^�C�v���� */
  public static final String LOOKUP_TYPE = "XXINV_FILE_OBJECT";
  /** �����^�C�v�F10 �o�׈˗� */
  public static final String DOC_TYPE_SHIP    = "10";
  /** �����^�C�v�F20 �ړ� */
  public static final String DOC_TYPE_MOVE    = "20";
  /** �����^�C�v�F30 �x���w�� */
  public static final String DOC_TYPE_SUPPLY  = "30";
  /** ���уf�[�^�敪�F1 �o�Ɏ��т���N�� */
  public static final String ACTUAL_FLAG_DELI   = "1";
  /** ���уf�[�^�敪�F2 ���Ɏ��т���N�� */
  public static final String ACTUAL_FLAG_SCOC   = "2";
  /** ���i���ʋ敪�F1 ���i */
  public static final String PRODUCT_FLAG_PROD = "1";
  /** ���i���ʋ敪�F2 ���i�ȊO */
  public static final String PRODUCT_FLAG_NOT_PROD = "2";
  /** ���b�g�Ǘ��敪�F1 ���b�g�Ǘ��i */
  public static final String LOT_CTL_Y = "1";
  /** ���b�g�Ǘ��敪�F0 ���b�g�Ǘ��O�i */
  public static final String LOT_CTL_N = "0";
  /** �f�t�H���g���b�g�F0 */
  public static final Number DEFAULT_LOT = new Number(0);
  /** ���i�敪�F1 ���[�t */
  public static final String PROD_CLASS_CODE_LEAF = "1";
  /** ���i�敪�F2 �h�����N */
  public static final String PROD_CLASS_CODE_DRINK = "2";
  /** ���ʊ֐��߂�l�F0 */
  public static final Number RETURN_SUCCESS     = new Number(0);
  /** ���ʊ֐��߂�l�F1 */
  public static final Number RETURN_NOT_EXE     = new Number(1);
  /** �V�[�P���X : �u�ړ��w�b�_ID�p�v�@ */
  public static final String XXINV_MOV_HDR_S1 = "xxinv_mov_hdr_s1";
  /** �R���J�����g���F�ړ����o�Ɏ��ѓo�^�����@ */
  public static final String CONC_NAME_XXINV570001C = "XXINV570001C";// add ver1.2
}