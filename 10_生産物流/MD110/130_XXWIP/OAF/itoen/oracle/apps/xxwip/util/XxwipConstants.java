/*============================================================================
* �t�@�C���� : XxwipConstants
* �T�v����   : ���Y���ʒ萔
* �o�[�W���� : 1.1
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2007-11-27 1.0  ��r���     �V�K�쐬
* 2008-09-10 1.1  ��r���     �����e�X�g�w�E�Ή�No30
*============================================================================
*/
package itoen.oracle.apps.xxwip.util;
/***************************************************************************
 * ���Y���ʒ萔�N���X�ł��B
 * @author  ORACLE ��r ���
 * @version 1.1
 ***************************************************************************
 */
public class XxwipConstants 
{
  /** ���b�Z�[�W�FAPP-XXWIP-00007 */
  public static final String XXWIP00007   = "APP-XXWIP-00007";
  /** ���b�Z�[�W�FAPP-XXWIP-10007 */
  public static final String XXWIP10007   = "APP-XXWIP-10007";
  /** ���b�Z�[�W�FAPP-XXWIP-10008 */
  public static final String XXWIP10008   = "APP-XXWIP-10008";
  /** ���b�Z�[�W�FAPP-XXWIP-10014 */
  public static final String XXWIP10014   = "APP-XXWIP-10014";
  /** ���b�Z�[�W�FAPP-XXWIP-10023 */
  public static final String XXWIP10023   = "APP-XXWIP-10023";
  /** ���b�Z�[�W�FAPP-XXWIP-10049 */
  public static final String XXWIP10049   = "APP-XXWIP-10049";
  /** ���b�Z�[�W�FAPP-XXWIP-10058 */
  public static final String XXWIP10058   = "APP-XXWIP-10058";
  /** ���b�Z�[�W�FAPP-XXWIP-10061 */
  public static final String XXWIP10061   = "APP-XXWIP-10061";
  /** ���b�Z�[�W�FAPP-XXWIP-10062 */
  public static final String XXWIP10062   = "APP-XXWIP-10062";
  /** ���b�Z�[�W�FAPP-XXWIP-10063 */
  public static final String XXWIP10063   = "APP-XXWIP-10063";
  /** ���b�Z�[�W�FAPP-XXWIP-10064 */
  public static final String XXWIP10064   = "APP-XXWIP-10064";
  /** ���b�Z�[�W�FAPP-XXWIP-10065 */
  public static final String XXWIP10065   = "APP-XXWIP-10065";
  /** ���b�Z�[�W�FAPP-XXWIP-10081 */
  public static final String XXWIP10081   = "APP-XXWIP-10081";
// 2008-09-10 v1.1 D.Nihei Add Start
  /** ���b�Z�[�W�FAPP-XXWIP-10082 */
  public static final String XXWIP10082   = "APP-XXWIP-10082";
  /** ���b�Z�[�W�FAPP-XXWIP-10083 */
  public static final String XXWIP10083   = "APP-XXWIP-10083";
  /** ���b�Z�[�W�FAPP-XXWIP-10084 */
  public static final String XXWIP10084   = "APP-XXWIP-10084";
  /** ���b�Z�[�W�FAPP-XXWIP-10085 */
  public static final String XXWIP10085   = "APP-XXWIP-10085";
// 2008-09-10 v1.1 D.Nihei Add End
  /** ���b�Z�[�W�FAPP-XXWIP-30001 */
  public static final String XXWIP30001   = "APP-XXWIP-30001";
  /** ���b�Z�[�W�FAPP-XXWIP-30002 */
  public static final String XXWIP30002   = "APP-XXWIP-30002";
// 2008-09-10 v1.1 D.Nihei Add Start
  /** ���b�Z�[�W�FAPP-XXWIP-30011 */
  public static final String XXWIP30011   = "APP-XXWIP-30011";
  /** ���b�Z�[�W�FAPP-XXWIP-40002 */
  public static final String XXWIP40002   = "APP-XXWIP-40002";
  /** �g�[�N���FSTATUS */
  public static final String TOKEN_STATUS     = "STATUS";
// 2008-09-10 v1.1 D.Nihei Add End
  /** �g�[�N���FITEM */
  public static final String TOKEN_ITEM       = "ITEM";
  /** �g�[�N���FAPI_NAME */
  public static final String TOKEN_API_NAME   = "API_NAME";
  /** �g�[�N�����́F�i�� */
  public static final String TOKEN_NAME_ITEM  = "�i��";
  /** URL�F�o�������ѓ��͉�� */
  public static final String URL_XXWIP200001J = "OA.jsp?page=/itoen/oracle/apps/xxwip/xxwip200001j/webui/XxwipVolumeActualPG";
  /** URL�F�������ѓ��͉�� */
  public static final String URL_XXWIP200002J = "OA.jsp?page=/itoen/oracle/apps/xxwip/xxwip200002j/webui/XxwipInvestActualPG";
	/** URL�p�����[�^ID�F�����p�o�b�`ID */
	public static final String URL_PARAM_SEARCH_BATCH_ID   = "pSearchBatchId";
	/** URL�p�����[�^ID�F�����p���Y�����ڍ�ID */
	public static final String URL_PARAM_SEARCH_MTL_DTL_ID = "pSearchMtlDtlId";
	/** URL�p�����[�^ID�F�J�ڗp�o�b�`ID */
	public static final String URL_PARAM_MOVE_BATCH_ID     = "pMoveBatchId";
	/** URL�p�����[�^ID�F�����p�o�b�`ID */
	public static final String URL_PARAM_TAB_TYPE = "pTabType";
// 2008-09-10 v1.1 D.Nihei Add Start
	/** URL�p�����[�^ID�F���������p�o�b�`ID */
	public static final String URL_PARAM_CAN_BATCH_ID         = "pCanBatchId";
	/** URL�p�����[�^ID�F���������p���Y�����ڍ�ID */
	public static final String URL_PARAM_CAN_MTL_DTL_ID       = "pCanMtlDtlId";
	/** URL�p�����[�^ID�F���������p���Y�����ڍ׃A�h�I��ID */
	public static final String URL_PARAM_CAN_MTL_DTL_ADDON_ID = "pCanMtlDtlAddonId";
	/** URL�p�����[�^ID�F���������p����ID */
	public static final String URL_PARAM_CAN_TRANS_ID         = "pCanTransId";
// 2008-09-10 v1.1 D.Nihei Add End
	/** �p�����[�^ID�F�����{�^�� */
	public static final String QS_SEARCH_BTN      = "QsSearch";
	/** �{�^��ID : �K�p�{�^�� */
	public static final String GO_BTN             = "Go";
	/** �{�^��ID : ����{�^�� */
	public static final String CANCEL_BTN         = "Cancel";
	/** �A�N�V����ID : �����i�ڃ|�b�v���X�g */
	public static final String CHANGE_INVEST_BTN  = "ChangeItemInvest";
	/** �A�N�V����ID : �ō��i�ڃ|�b�v���X�g */
	public static final String CHANGE_RE_INVEST_BTN = "ChangeItemReInvest";
	/** �A�C�R��ID : �폜�A�C�R�� */
	public static final String DELETE_ICON        = "deleteRow";
	/** �p�����[�^ID�F�o�b�`ID */
	public static final String PARAM_SC_BATCH_ID  = "QsSearchBatchId";
	/** �p�����[�^ID�F�^�u�^�C�v */
	public static final String PARAM_TAB_TYPE     = "TAB_TYPE";
	/** �p�����[�^ID�F���Y�����ڍ�ID */
	public static final String PARAM_MTL_DTL_ID   = "MTL_DTL_ID";
	/** �p�����[�^ID�F�o�b�`ID */
	public static final String PARAM_BATCH_ID     = "BATCH_ID";
	/** �^�u�^�C�v�F�������^�u */
	public static final String TAB_TYPE_INVEST    = "0";
	/** �^�u�^�C�v�F�ō����^�u */
	public static final String TAB_TYPE_REINVEST  = "1";
	/** �^�u�^�C�v�F���Y�����^�u */
	public static final String TAB_TYPE_CO_PROD   = "2";
	/** ���C���^�C�v�F�����i */
	public static final String LINE_TYPE_PROD     = "1";
	/** ���C���^�C�v�F�����i */
	public static final String LINE_TYPE_INVEST   = "-1";
	/** ���C���^�C�v�F���Y�� */
	public static final String LINE_TYPE_CO_PROD  = "2";
	/** ���C���^�C�v�F�����i */
	public static final int LINE_TYPE_INVEST_NUM   = -1;
	/** ���C���^�C�v�F���Y�� */
	public static final int LINE_TYPE_CO_PROD_NUM  = 2;
	/** �Ɩ��X�e�[�^�X�F1 �ۗ��� */
	public static final String DUTY_STATUS_HRT    = "1";
	/** �Ɩ��X�e�[�^�X�F2 �˗��� */
	public static final String DUTY_STATUS_IRZ    = "2";
	/** �Ɩ��X�e�[�^�X�F3 ��z�� */
	public static final String DUTY_STATUS_THZ    = "3";
	/** �Ɩ��X�e�[�^�X�F4 �w�}�� */
	public static final String DUTY_STATUS_SZZ    = "4";
	/** �Ɩ��X�e�[�^�X�F5 �m�F�� */
	public static final String DUTY_STATUS_KNZ    = "5";
	/** �Ɩ��X�e�[�^�X�F6 ��t�� */
	public static final String DUTY_STATUS_UTZ    = "6";
	/** �Ɩ��X�e�[�^�X�F7 ���� */
	public static final String DUTY_STATUS_COM    = "7";
	/** �Ɩ��X�e�[�^�X�F8 �N���[�Y */
	public static final String DUTY_STATUS_CLS    = "8";
	/** �Ɩ��X�e�[�^�X�F-1 ��� */
	public static final String DUTY_STATUS_CAN    = "-1";
	/** �i���X�e�[�^�X�F10 ������ */
	public static final String QT_STATUS_NON_JUDG = "10";
	/** �i���X�e�[�^�X�F50 ���i */
	public static final String QT_STATUS_PASS     = "50";
	/** ���O�敪�F1 ���� */
	public static final String IN_OUT_TYPE_JISHA  = "1";
	/** ���O�敪�F2 �ϑ��� */
	public static final String IN_OUT_TYPE_ITAKU  = "2";
	/** �ϑ��v�Z�敪�F1 �o�������� */
	public static final String TRUST_CALC_TYPE_VOLUME = "1";
	/** �ϑ��v�Z�敪�F2 �������� */
	public static final String TRUST_CALC_TYPE_INVEST = "2";
	/** �����L���敪�F1 �L */
	public static final String QT_TYPE_ON         = "1";
	/** �����L���敪�F0 �� */
	public static final String QT_TYPE_OFF        = "0";
  /** �N���X���FXxwipUtility */
  public static final String CLASS_XXWIP_UTILITY   = "itoen.oracle.apps.xxwip.util.XxwipUtility";
  /** �N���X���FXxwipVolumeActualAMImpl */
  public static final String CLASS_AM_XXWIP200001J = "itoen.oracle.apps.xxwip.xxwip200001j.server.XxwipVolumeActualAMImpl";
  /** �N���X���FXxwipInvestActualAMImpl */
  public static final String CLASS_AM_XXWIP200002J = "itoen.oracle.apps.xxwip.xxwip200002j.server.XxwipInvestActualAMImpl";
	/** �Z�[�u�|�C���g���FXXWIP200001J */
	public static final String SAVE_POINT_XXWIP200001J  = "xxwip200001j";
	/** ���R�[�h�^�C�v�F1 �}�� */
	public static final String RECORD_TYPE_INS   = "0";
	/** ���R�[�h�^�C�v�F2 �X�V */
	public static final String RECORD_TYPE_UPD   = "1";
	/** �i�ڃ^�C�v�F1 ���� */
	public static final String ITEM_TYPE_MTL     = "1";
	/** �i�ڃ^�C�v�F2 ���� */
	public static final String ITEM_TYPE_SHZ     = "2";
	/** �i�ڃ^�C�v�F4 �����i */
	public static final String ITEM_TYPE_HALF    = "4";
	/** �i�ڃ^�C�v�F5 ���i */
	public static final String ITEM_TYPE_PROD    = "5";
	/** �g�����U�N�V�������FXXWIP200001JTxn */
	public static final String TXN_XXWIP200001J  = "xxwip200001jTxn";
	/** �g�����U�N�V�������FXXWIP200002JTxn */
	public static final String TXN_XXWIP200002J  = "xxwip200002jTxn";

}
