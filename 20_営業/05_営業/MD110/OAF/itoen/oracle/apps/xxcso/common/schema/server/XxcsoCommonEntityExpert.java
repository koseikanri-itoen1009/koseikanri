/*============================================================================
* �t�@�C���� : XxcsoCommonEntityExpert
* �T�v����   : �A�h�I���c�Ƌ��ʃG���e�B�e�B�G�L�X�p�[�g�N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-09 1.0  SCS����_     �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxcso.common.schema.server;
import oracle.apps.fnd.framework.server.OAEntityExpert;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.jbo.domain.Number;
import oracle.jbo.domain.Date;
import itoen.oracle.apps.xxcso.common.util.XxcsoMessage;
import itoen.oracle.apps.xxcso.common.util.XxcsoUtils;

/*******************************************************************************
 * �A�h�I���c�Ƌ��ʂ̃G���e�B�e�B�G�L�X�p�[�g�N���X�ł��B
 * @author  SCS����_
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoCommonEntityExpert extends OAEntityExpert 
{
  /*****************************************************************************
   * ���k�ԍ����擾���鏈���ł��B
   * @param leadId ���kID
   *****************************************************************************
   */
  public String getLeadNumber(Number leadId)
  {
    OADBTransaction txn = getOADBTransaction();
    XxcsoUtils.debug(txn, "[START]");
    
    XxcsoAsLeadVVOImpl leadVo
      = (XxcsoAsLeadVVOImpl)findValidationViewObject("XxcsoAsLeadVVO1");
    if ( leadVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoAsLeadVVO1");
    }
    
    leadVo.initQuery(leadId);

    XxcsoAsLeadVVORowImpl leadRow
      = (XxcsoAsLeadVVORowImpl)leadVo.first();

    XxcsoUtils.debug(txn, "[END]");

    return leadRow.getLeadNumber();
  }

  /*****************************************************************************
   * ���ϔԍ�/�_�񏑔ԍ��𕥂��o�������ł��B
   *****************************************************************************
   */
  public String getAutoAssignedCode(
    String assignClass
   ,String baseCode
   ,Date   currentDate
  )
  {
    OADBTransaction txn = getOADBTransaction();
    XxcsoUtils.debug(txn, "[START]");
    
    XxcsoGetAutoAssignedCodeVVOImpl getVo
      = (XxcsoGetAutoAssignedCodeVVOImpl)
          findValidationViewObject("XxcsoGetAutoAssignedCodeVVO1");
    if ( getVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoGetAutoAssignedCodeVVO1");
    }
    
    getVo.initQuery(assignClass, baseCode, currentDate);

    XxcsoGetAutoAssignedCodeVVORowImpl getRow
      = (XxcsoGetAutoAssignedCodeVVORowImpl)getVo.first();

    XxcsoUtils.debug(txn, "[END]");

    return getRow.getAutoAssignedCode();
  }

  /*****************************************************************************
   * �I�����C���������t���擾���鏈���ł��B
   *****************************************************************************
   */
  public Date getOnlineSysdate()
  {
    OADBTransaction txn = getOADBTransaction();
    XxcsoUtils.debug(txn, "[START]");
    
    XxcsoGetOnlineSysdateVVOImpl sysdateVo
      = (XxcsoGetOnlineSysdateVVOImpl)
          findValidationViewObject("XxcsoGetOnlineSysdateVVO1");
    if ( sysdateVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoGetOnlineSysdateVVO1");
    }
    
    sysdateVo.executeQuery();

    XxcsoGetOnlineSysdateVVORowImpl getRow
      = (XxcsoGetOnlineSysdateVVORowImpl)sysdateVo.first();

    XxcsoUtils.debug(txn, "[END]");

    return getRow.getOnlineSysdate();
  }

  /*****************************************************************************
   *�ڋq�����擾���鏈���ł��B
   * @param accountNumber �ڋq�R�[�h
   *****************************************************************************
   */
  public String getPartyName(String accountNumber)
  {
    OADBTransaction txn = getOADBTransaction();
    XxcsoUtils.debug(txn, "[START]");
    
    XxcsoCustAccountVVOImpl accountVo
      = (XxcsoCustAccountVVOImpl)
          findValidationViewObject("XxcsoCustAccountVVO1");
    if ( accountVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoCustAccountVVO1");
    }
    
    accountVo.initQuery(accountNumber);

    XxcsoCustAccountVVORowImpl accountRow
      = (XxcsoCustAccountVVORowImpl)accountVo.first();

    XxcsoUtils.debug(txn, "[END]");

    return accountRow.getPartyName();
  }

  /*****************************************************************************
   *SP�ꌈ���ԍ����擾���鏈���ł��B
   * @param spDecisionHeaderId SP�ꌈ�w�b�_ID
   *****************************************************************************
   */
  public String getSpDecisionNumber(Number spDecisionHeaderId)
  {
    OADBTransaction txn = getOADBTransaction();
    XxcsoUtils.debug(txn, "[START]");
    
    XxcsoSpDecisionHeaderVVOImpl headerVo
      = (XxcsoSpDecisionHeaderVVOImpl)
          findValidationViewObject("XxcsoSpDecisionHeaderVVO1");
    if ( headerVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoSpDecisionHeaderVVO1");
    }
    
    headerVo.initQuery(spDecisionHeaderId);

    XxcsoSpDecisionHeaderVVORowImpl headerRow
      = (XxcsoSpDecisionHeaderVVORowImpl)headerVo.first();

    XxcsoUtils.debug(txn, "[END]");

    return headerRow.getSpDecisionNumber();
  }
}