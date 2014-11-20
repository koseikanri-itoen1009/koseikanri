/*============================================================================
* �t�@�C���� : XxcsoCommonVAMImpl
* �T�v����   : �A�h�I���c�Ƌ��ʌ��؃A�v���P�[�V�����E���W���[���N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-09 1.0  SCS����_     �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxcso.common.schema.server;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;

/*******************************************************************************
 * �A�h�I���c�Ƌ��ʂ̌��؃A�v���P�[�V�����E���W���[���N���X�ł��B
 * @author  SCS����_
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoCommonVAMImpl extends OAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoCommonVAMImpl()
  {
  }

  /**
   * 
   * Container's getter for XxcsoAsLeadVVO1
   */
  public XxcsoAsLeadVVOImpl getXxcsoAsLeadVVO1()
  {
    return (XxcsoAsLeadVVOImpl)findViewObject("XxcsoAsLeadVVO1");
  }

  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("itoen.oracle.apps.xxcso.common.schema.server", "XxcsoAsLeadVAMLocal");
  }


  /**
   * 
   * Container's getter for XxcsoGetOnlineSysdateVVO1
   */
  public XxcsoGetOnlineSysdateVVOImpl getXxcsoGetOnlineSysdateVVO1()
  {
    return (XxcsoGetOnlineSysdateVVOImpl)findViewObject("XxcsoGetOnlineSysdateVVO1");
  }

  /**
   * 
   * Container's getter for XxcsoGetAutoAssignedCodeVVO1
   */
  public XxcsoGetAutoAssignedCodeVVOImpl getXxcsoGetAutoAssignedCodeVVO1()
  {
    return (XxcsoGetAutoAssignedCodeVVOImpl)findViewObject("XxcsoGetAutoAssignedCodeVVO1");
  }

  /**
   * 
   * Container's getter for XxcsoCustAccountVVO1
   */
  public XxcsoCustAccountVVOImpl getXxcsoCustAccountVVO1()
  {
    return (XxcsoCustAccountVVOImpl)findViewObject("XxcsoCustAccountVVO1");
  }

  /**
   * 
   * Container's getter for XxcsoSpDecisionHeaderVVO1
   */
  public XxcsoSpDecisionHeaderVVOImpl getXxcsoSpDecisionHeaderVVO1()
  {
    return (XxcsoSpDecisionHeaderVVOImpl)findViewObject("XxcsoSpDecisionHeaderVVO1");
  }
}