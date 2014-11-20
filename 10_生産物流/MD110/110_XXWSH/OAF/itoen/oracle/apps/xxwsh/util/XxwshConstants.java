/*============================================================================
* �t�@�C���� : XxwshConstants
* �T�v����   : �o�ׁE����/�z�ԋ��ʒ萔
* �o�[�W���� : 1.1
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-03-27 1.0  �ɓ��ЂƂ�     �V�K�쐬
* 2008-06-27 1.1  �ɓ��ЂƂ�   �����s�TE080_400#157
*============================================================================
*/
package itoen.oracle.apps.xxwsh.util;
import oracle.jbo.domain.Number;
/***************************************************************************
 * �o�ׁE����/�z�ԋ��ʒ萔�N���X�ł��B
 * @author  ORACLE �ɓ��ЂƂ�
 * @version 1.1
 ***************************************************************************
 */
public class XxwshConstants 
{
  /** �N���X���FXxwshUtility */
  public static final String CLASS_XXWSH_UTILITY  = "itoen.oracle.apps.xxwsh.util.XxwshUtility";
  /** �N���X���FXxwshShipLotInputAMImpl */
  public static final String CLASS_AM_XXWSH920001J  = "itoen.oracle.apps.xxwsh.xxwsh920001j.server.XxwshShipLotInputAMImpl";
  /** URL�F�������b�g���͉�� */
  public static final String URL_XXWSH920002JH    = "OA.jsp?page=/itoen/oracle/apps/xxwsh/xxwsh920002j/webui/XxwshReserveLotInputPG";
  /** URL�F���o�׎��у��b�g���͉��(�o�׎���) */
  public static final String URL_XXWSH920001J_1   = "OA.jsp?page=/itoen/oracle/apps/xxwsh/xxwsh920001j/webui/XxwshShipLotInputPG";
  /** URL�F���o�׎��у��b�g���͉��(���Ɏ���) */
  public static final String URL_XXWSH920001J_2   = "OA.jsp?page=/itoen/oracle/apps/xxwsh/xxwsh920001j/webui/XxwshStockLotInputPG";
  /** �g�����U�N�V�������FXXWSH920001JTXN */
  public static final String TXN_XXWSH920001J     = "xxwsh920001jTxn";
  /** �g�����U�N�V�������FXXWSH920002JTXN */
  public static final String TXN_XXWSH920002J     = "xxwsh920002jTxn";
  /** URL�p�����[�^ID�F�ďo��ʋ敪 */
  public static final String URL_PARAM_CALL_PICTURE_KBN   = "wCallPictureKbn";
  /** URL�p�����[�^ID�F����ID */
  public static final String URL_PARAM_LINE_ID            = "wLineId";
  /** URL�p�����[�^ID�F�w�b�_�X�V���� */
  public static final String URL_PARAM_HEADER_UPDATE_DATE = "wHeaderUpdateDate";
  /** URL�p�����[�^ID�F���׍X�V���� */
  public static final String URL_PARAM_LINE_UPDATE_DATE   = "wLineUpdateDate";
  /** URL�p�����[�^ID�F�N���敪 */
  public static final String URL_PARAM_EXE_KBN            = "wExeKbn";
  /** URL�p�����[�^ID�F�˗�No */
  public static final String URL_PARAM_REQ_NO             = "wReqNo";
  //xxwsh920001j���b�Z�[�W
  /** ���b�Z�[�W�FAPP-XXWSH-13310 �K�{���̓p�����[�^�����̓G���[���b�Z�[�W */
  public static final String XXWSH13310 = "APP-XXWSH-13310";
  /** ���b�Z�[�W�FAPP-XXWSH-13311 ���̓p�����[�^�����G���[���b�Z�[�W */
  public static final String XXWSH13311 = "APP-XXWSH-13311";
  /** ���b�Z�[�W�FAPP-XXWSH-13302 �K�{�G���[ */
  public static final String XXWSH13302 = "APP-XXWSH-13302";
  /** ���b�Z�[�W�FAPP-XXWSH-13303 ���͒l�G���[ */
  public static final String XXWSH13303 = "APP-XXWSH-13303";
  /** ���b�Z�[�W�FAPP-XXWSH-13313 ���l�s���G���[ */
  public static final String XXWSH13313 = "APP-XXWSH-13313";
  /** ���b�Z�[�W�FAPP-XXWSH-13312 ���b�g���擾�G���[���b�Z�[�W */
  public static final String XXWSH13312 = "APP-XXWSH-13312";
  /** ���b�Z�[�W�FAPP-XXWSH-13301 ���b�g�X�e�[�^�X�G���[���b�Z�[�W */
  public static final String XXWSH13301 = "APP-XXWSH-13301";
  /** ���b�Z�[�W�FAPP-XXWSH-13305 ���b�gNo�d���G���[ */
  public static final String XXWSH13305 = "APP-XXWSH-13305";
  /** ���b�Z�[�W�FAPP-XXWSH-13304 �݌ɉ�v���ԃ`�F�b�N�G���[���b�Z�[�W */
  public static final String XXWSH13304 = "APP-XXWSH-13304";
  /** ���b�Z�[�W�FAPP-XXWSH-13306 ���b�N�G���[���b�Z�[�W */
  public static final String XXWSH13306 = "APP-XXWSH-13306";
  /** ���b�Z�[�W�FAPP-XXWSH-13308 �d�ʗe�Ϗ������X�V�֐��G���[���b�Z�[�W */
  public static final String XXWSH13308 = "APP-XXWSH-13308";
  /** ���b�Z�[�W�FAPP-XXWSH-33301 ���b�g�t�]�h�~�`�F�b�N�G���[ */
  public static final String XXWSH33301 = "APP-XXWSH-33301";
  /** ���b�Z�[�W�FAPP-XXWSH-33304 �o�^�������b�Z�[�W */
  public static final String XXWSH33304 = "APP-XXWSH-33304";
  /** ���b�Z�[�W�FAPP-XXWSH-13314 �R���J�����g�o�^�G���[ */
  public static final String XXWSH13314 = "APP-XXWSH-13314";
  //xxwsh920002j���b�Z�[�W
  /** ���b�Z�[�W�FAPP-XXWSH-12901 �������ʕs��v�G���[���b�Z�[�W */
  public static final String XXWSH12901 = "APP-XXWSH-12901";
  /** ���b�Z�[�W�FAPP-XXWSH-12902 ���l�s���G���[ */
  public static final String XXWSH12902 = "APP-XXWSH-12902";
  /** ���b�Z�[�W�FAPP-XXWSH-12903 ���̓p�����[�^�����G���[���b�Z�[�W */
  public static final String XXWSH12903 = "APP-XXWSH-12903";
  /** ���b�Z�[�W�FAPP-XXWSH-12904 �K�{���̓p�����[�^�����̓G���[���b�Z�[�W */
  public static final String XXWSH12904 = "APP-XXWSH-12904";
  /** ���b�Z�[�W�FAPP-XXWSH-12905 �}�C�i�X���ʃG���[���b�Z�[�W */
  public static final String XXWSH12905 = "APP-XXWSH-12905";
  /** ���b�Z�[�W�FAPP-XXWSH-12906 �����\���ύX�G���[���b�Z�[�W */
  public static final String XXWSH12906 = "APP-XXWSH-12906";
  /** ���b�Z�[�W�FAPP-XXWSH-12907 �ύX�σG���[���b�Z�[�W */
  public static final String XXWSH12907 = "APP-XXWSH-12907";
  /** ���b�Z�[�W�FAPP-XXWSH-12908 ���b�N�G���[ */
  public static final String XXWSH12908 = "APP-XXWSH-12908";
  /** ���b�Z�[�W�FAPP-XXWSH-12909 �ύڌ����G���[���b�Z�[�W */
  public static final String XXWSH12909 = "APP-XXWSH-12909";
  /** ���b�Z�[�W�FAPP-XXWSH-12910 �ő�z���敪�擾�G���[���b�Z�[�W */
  public static final String XXWSH12910 = "APP-XXWSH-12910";
  /** ���b�Z�[�W�FAPP-XXWSH-12911 �K�{�G���[ */
  public static final String XXWSH12911 = "APP-XXWSH-12911";
  /** ���b�Z�[�W�FAPP-XXWSH-32901 ���b�g�t�]���[�j���O */
  public static final String XXWSH32901 = "APP-XXWSH-32901";
  /** ���b�Z�[�W�FAPP-XXWSH-32902 �N�x�������[�j���O */
  public static final String XXWSH32902 = "APP-XXWSH-32902";
  /** ���b�Z�[�W�FAPP-XXWSH-32903 �w�����ʍX�V���b�Z�[�W */
  public static final String XXWSH32903 = "APP-XXWSH-32903";
  /** ���b�Z�[�W�FAPP-XXWSH-32904 �o�^�������b�Z�[�W */
  public static final String XXWSH32904 = "APP-XXWSH-32904";
  /** �g�[�N���FPARM_NAME */
  public static final String TOKEN_PARM_NAME = "PARM_NAME";
  /** �g�[�N���FLOT_STATUS */
  public static final String TOKEN_LOT_STATUS = "LOT_STATUS";
  /** �g�[�N���FDATE */
  public static final String TOKEN_DATE = "DATE";
  /** �g�[�N���FTABLE */
  public static final String TOKEN_TABLE = "TABLE";
  /** �g�[�N���FITEM */
  public static final String TOKEN_ITEM = "ITEM";
  /** �g�[�N���FLOT */
  public static final String TOKEN_LOT = "LOT";
  /** �g�[�N���FLOCATION */
  public static final String TOKEN_LOCATION = "LOCATION";
  /** �g�[�N���FREVDATE */
  public static final String TOKEN_REVDATE = "REVDATE";
  /** �g�[�N���FPRG_NAME */
  public static final String TOKEN_PRG_NAME = "PRG_NAME";
  /** �g�[�N���FERR_CODE */
  public static final String TOKEN_ERR_CODE = "ERR_CODE";
  /** �g�[�N���FERR_MSG */
  public static final String TOKEN_ERR_MSG = "ERR_MSG";
  /** �g�[�N���FKUBUN */
  public static final String TOKEN_KUBUN = "KUBUN";
  /** �g�[�N���FLOADING_EFFICIENCY */
  public static final String TOKEN_LOADING_EFFICIENCY = "LOADING_EFFICIENCY";
  /** �g�[�N���FCODE_KBN1 */
  public static final String TOKEN_CODE_KBN1 = "CODE_KBN1";
  /** �g�[�N���FSHIP_FROM */
  public static final String TOKEN_SHIP_FROM = "SHIP_FROM";
  /** �g�[�N���FCODE_KBN2 */
  public static final String TOKEN_CODE_KBN2 = "CODE_KBN2";
  /** �g�[�N���FSHIP_TO */
  public static final String TOKEN_SHIP_TO = "SHIP_TO";
  /** �g�[�N���FSHIP_DATE */
  public static final String TOKEN_SHIP_DATE = "SHIP_DATE";
  /** �g�[�N���FSHIP_TYPE */
  public static final String TOKEN_SHIP_TYPE = "SHIP_TYPE";
  /** �g�[�N���FARRIVAL_DATE */
  public static final String TOKEN_ARRIVAL_DATE = "ARRIVAL_DATE";
  /** �g�[�N���FPROD_CLASS */
  public static final String TOKEN_PROD_CLASS = "PROD_CLASS";
  /** �g�[�N�����́F����ID */
  public static final String TOKEN_NAME_LINE_ID             = "����ID";
  /** �g�[�N�����́F�ďo��ʋ敪 */
  public static final String TOKEN_NAME_CALL_PICTURE_KBN    = "�ďo��ʋ敪";
  /** �g�[�N�����́F���׍X�V���� */
  public static final String TOKEN_NAME_LINE_UPDATE_DATE    = "���׍X�V����";
  /** �g�[�N�����́F�w�b�_�X�V���� */
  public static final String TOKEN_NAME_HEADER_UPDATE_DATE  = "�w�b�_�X�V����";
  /** �g�[�N�����́F�N���敪 */
  public static final String TOKEN_NAME_EXE_KBN = "�N���敪";
  /** �g�[�N�����́F�R���J�����g�� */
  public static final String TOKEN_NAME_PGM_NAME_420001C = "�o�׈˗�/�o�׎��э쐬����";
  /** �g�[�N�����́F�d�� */
  public static final String TOKEN_NAME_WEIGHT = "�d��";
  /** �g�[�N�����́F�e�� */
  public static final String TOKEN_NAME_CAPACITY = "�e��";
  /** �g�[�N�����́F�z���� */
  public static final String TOKEN_NAME_DELIVER_TO = "�z����";
  /** �g�[�N�����́F���ɐ� */
  public static final String TOKEN_NAME_SHIP_TO = "���ɐ�";

  /** ���R�[�h�^�C�v�F10 �w�� */
  public static final String RECORD_TYPE_INST = "10";
  /** ���R�[�h�^�C�v�F20 �o�Ɏ��� */
  public static final String RECORD_TYPE_DELI = "20";
  /** ���R�[�h�^�C�v�F30 ���Ɏ��� */
  public static final String RECORD_TYPE_STOC = "30";
  /** ���R�[�h�^�C�v�F40 ������ */
  public static final String RECORD_TYPE_INVE = "40";
  /** �����^�C�v�F10 �o�׈˗� */
  public static final String DOC_TYPE_SHIP    = "10";
  /** �����^�C�v�F20 �ړ� */
  public static final String DOC_TYPE_MOVE    = "20";
  /** �����^�C�v�F30 �x���w�� */
  public static final String DOC_TYPE_SUPPLY  = "30";
  /** �i�ڃ^�C�v�F1 ���� */
  public static final String ITEM_TYPE_MTL    = "1";
  /** �i�ڃ^�C�v�F2 ���� */
  public static final String ITEM_TYPE_SHZ    = "2";
  /** �i�ڃ^�C�v�F4 �����i */
  public static final String ITEM_TYPE_HALF   = "4";
  /** �i�ڃ^�C�v�F5 ���i */
  public static final String ITEM_TYPE_PROD   = "5";
  /** �ďo��ʋ敪�F1 �o�׈˗����͉�� */
  public static final String CALL_PIC_KBN_SHIP_INPUT  = "1";
  /** �ďo��ʋ敪�F2 �x���w���쐬��� */
  public static final String CALL_PIC_KBN_PROD_CREATE = "2";
  /** �ďo��ʋ敪�F3 �ړ��˗�/�w�����͉�� */
  public static final String CALL_PIC_KBN_MOVE_ORDER  = "3";
  /** �ďo��ʋ敪�F4 �o�Ɏ��щ�� */
  public static final String CALL_PIC_KBN_DELI        = "4";
  /** �ďo��ʋ敪�F5 ���Ɏ��щ�� */
  public static final String CALL_PIC_KBN_STOC        = "5";
  /** �ďo��ʋ敪�F6 �x���ԕi��� */
  public static final String CALL_PIC_KBN_RETURN      = "6";
  /** ���t�t�H�[�}�b�g */
  public static final String DATE_FORMAT = "YYYY/MM/DD HH24:MI:SS";
  /** ���b�g�Ǘ��敪�F1 ���b�g�Ǘ��i */
  public static final String LOT_CTL_Y = "1";
  /** ���b�g�Ǘ��敪�F0 ���b�g�Ǘ��O�i */
  public static final String LOT_CTL_N = "0";
  /** �f�t�H���g���b�g�F0 */
  public static final Number DEFAULT_LOT = new Number(0);
  /** �L�����z�m��敪�F1 �m�� */
  public static final String AMOUNT_FIX_CLASS_Y = "1";
  /** �L�����z�m��敪�F2 ���m�� */
  public static final String AMOUNT_FIX_CLASS_N = "2";
  /** �o�׎x���󕥃J�e�S���F01 ���{�o�� */
  public static final String AMOUNT_SHIP_SIKYU_RCV_PAY_CTG_SAMPLE_SHIP = "01";
  /** �o�׎x���󕥃J�e�S���F02 �p���o�� */
  public static final String AMOUNT_SHIP_SIKYU_RCV_PAY_CTG_JUNK_SHIP   = "02";
  /** �o�׎x���󕥃J�e�S���F03 �q�֓��� */
  public static final String AMOUNT_SHIP_SIKYU_RCV_PAY_CTG_CHANGE_STOC = "03";
  /** �o�׎x���󕥃J�e�S���F04 �ԕi���� */
  public static final String AMOUNT_SHIP_SIKYU_RCV_PAY_CTG_RET_STOC    = "04";
  /** �o�׎x���󕥃J�e�S���F05 �L���o�� */
  public static final String AMOUNT_SHIP_SIKYU_RCV_PAY_CTG_CONS_SHIP   = "05";
  /** �o�׎x���󕥃J�e�S���F06 �L���ԕi */
  public static final String AMOUNT_SHIP_SIKYU_RCV_PAY_CTG_CONS_RET    = "06";
  /** �o�׈˗��X�e�[�^�X�F01 ���͒� */
  public static final String TRANSACTION_STATUS_INPUT = "01";
  /** �o�׈˗��X�e�[�^�X�F02 ���_�m�� */
  public static final String TRANSACTION_STATUS_HUB   = "02";
  /** �o�׈˗��X�e�[�^�X�F03 ���ߍ� */
  public static final String TRANSACTION_STATUS_CLOSE = "03";
  /** �o�׈˗��X�e�[�^�X�F04 �o�׎��ьv��� */
  public static final String TRANSACTION_STATUS_ADD   = "04";
  /** �o�׈˗��X�e�[�^�X�F99 ��� */
  public static final String TRANSACTION_STATUS_DEL   = "99";
  /** �x���˗��X�e�[�^�X�F05 ���͒� */
  public static final String XXPO_TRANSACTION_STATUS_INPUT = "05";
  /** �x���˗��X�e�[�^�X�F06 ���͊��� */
  public static final String XXPO_TRANSACTION_STATUS_HUB   = "06";
  /** �x���˗��X�e�[�^�X�F07 ��̍� */
  public static final String XXPO_TRANSACTION_STATUS_CLOSE = "07";
  /** �x���˗��X�e�[�^�X�F08 �o�׎��ьv��� */
  public static final String XXPO_TRANSACTION_STATUS_ADD   = "08";
  /** �x���˗��X�e�[�^�X�F99 ��� */
  public static final String XXPO_TRANSACTION_STATUS_DEL   = "99";
  /** �Ώ�_�ΏۊO�敪�F0 �ΏۊO */
  public static final String INCLUDE_EXCLUD_EXCLUD  = "0";
  /** �Ώ�_�ΏۊO�敪�F1 �Ώ� */
  public static final String INCLUDE_EXCLUD_INCLUDE = "1";
  /** ���i�敪�F1 ���[�t */
  public static final String PROD_CLASS_CODE_LEAF = "1";
  /** ���i�敪�F2 �h�����N */
  public static final String PROD_CLASS_CODE_DRINK = "2";
  /** �󒍃J�e�S���F�� */
  public static final String ORDER_CATEGORY_CODE_ORDER = "ORDER";
  /** ���ʊ֐��߂�l�F0 */
  public static final Number RETURN_SUCCESS     = new Number(0);
  /** ���ʊ֐��߂�l�F1 */
  public static final Number RETURN_NOT_EXE     = new Number(1);
  /** ���_���їL���敪�F1 ���㋒�_*/
  public static final String LOCATION_REL_CODE_SALE = "1";
  /** �V�[�P���X : �u�ړ����b�g�ڍ׃A�h�I��ID�p�v�@ */
  public static final String XXINV_MOV_LOT_S1 = "xxinv_mov_lot_s1";
  /** �e�[�u�����F�󒍃w�b�_�A�h�I��*/
  public static final String TABLE_NAME_ORDER_HEADERS = "�󒍃w�b�_�A�h�I��";
  /** �e�[�u�����F�󒍖��׃A�h�I��*/
  public static final String TABLE_NAME_ORDER_LINES = "�󒍖��׃A�h�I��";
  /** �e�[�u�����F�ړ��˗�/�w���w�b�_(�A�h�I��)*/
  public static final String TABLE_NAME_MOV_HEADERS = "�ړ��˗�/�w���w�b�_(�A�h�I��)";
  /** �e�[�u�����F�ړ��˗�/�w������(�A�h�I��)*/
  public static final String TABLE_NAME_MOV_LINES = "�ړ��˗�/�w������(�A�h�I��)";
  /** ���o�Ɋ��Z�P�ʎg�p�敪 1:�Ώ�*/
  public static final String CONV_UNIT_USE_KBN_INCLUDE = "1";
  /** �ꊇ�����{�^�������t���O 1:������*/
  public static final String PACKAGE_LIFT_FLAG_INCLUDE = "1";
  /** �w�����ʍX�V�t���O 1:�X�V�Ώ�*/
  public static final String INSTRUCT_QTY_UPD_FLAG_INCLUDE = "1";
  /** �w�����ʍX�V�t���O 0:�X�V�ΏۊO*/
  public static final String INSTRUCT_QTY_UPD_FLAG_EXCLUD = "0";
  /** �R�[�h�敪 4:�q��*/
  public static final String CODE_KBN_4 = "4";
  /** �R�[�h�敪 9:�z����*/
  public static final String CODE_KBN_9 = "9";
  /** �R�[�h�敪 11:�x����*/
  public static final String CODE_KBN_11 = "11";
  /** �d�ʗe�ϋ敪 : �u1 : �d�ʁv�@ */
  public static final String WGHT_CAPA_CLASS_WEIGHT   = "1";
  /** �d�ʗe�ϋ敪 : �u2 : �e�ρv�@ */
  public static final String WGHT_CAPA_CLASS_CAPACITY = "2";
  /** �ύڃI�[�o�[�敪 : �u1 : �ύڃI�[�o�v�@ */
  public static final String LOADING_OVER_CLASS_OVER = "1";
  /** �x���敪 : �u30 : ���b�g�t�]�v�@ */
  public static final String WARNING_CLASS_LOT = "30";
  /** �x���敪 : �u40 : �N�x�����v�@ */
  public static final String WARNING_CLASS_FRESH = "40";
  /** ���b�g�t�]������� : �u1 : �o��(�w��)�v�@ */
  public static final String LOT_BIZ_CLASS_SHIP_INS = "1";
  /** ���b�g�t�]������� : �u5 : �ړ�(�w��)�v�@ */
  public static final String LOT_BIZ_CLASS_MOVE_INS = "5";
  /** �����蓮�����敪�F�u20 :�蓮�����v�@ */
  public static final String AM_RESERVE_CLASS_MAN = "20";
// 2008-06-27 H.Itou ADD Start
  /** �R���J�����g���F�o�׈˗�/�o�׎��э쐬�����@ */
  public static final String CONC_NAME_XXWSH420001C = "XXWSH420001C";
// 2008-06-27 H.Itou ADD End
}