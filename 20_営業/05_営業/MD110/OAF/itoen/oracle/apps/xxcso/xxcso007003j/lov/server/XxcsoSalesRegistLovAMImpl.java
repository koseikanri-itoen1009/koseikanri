/*============================================================================
* �t�@�C���� : XxcsoSalesRegistLovAMImpl
* �T�v����   : ���k���������LOV�A�v���P�[�V�������W���[���N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-06 1.0  SCS����_    �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso007003j.lov.server;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;

/*******************************************************************************
 * ���k��������͂�LOV�A�v���P�[�V�������W���[���N���X
 * @author  SCS����_
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoSalesRegistLovAMImpl extends OAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoSalesRegistLovAMImpl()
  {
  }

  /**
   * 
   * Container's getter for XxcsoInventoryItemLovVO1
   */
  public XxcsoInventoryItemLovVOImpl getXxcsoInventoryItemLovVO1()
  {
    return (XxcsoInventoryItemLovVOImpl)findViewObject("XxcsoInventoryItemLovVO1");
  }

  /**
   * 
   * Container's getter for XxcsoNotifyUserLovVO1
   */
  public XxcsoNotifyUserLovVOImpl getXxcsoNotifyUserLovVO1()
  {
    return (XxcsoNotifyUserLovVOImpl)findViewObject("XxcsoNotifyUserLovVO1");
  }

  /**
   * 
   * Container's getter for XxcsoQuoteItemLovVO1
   */
  public XxcsoQuoteItemLovVOImpl getXxcsoQuoteItemLovVO1()
  {
    return (XxcsoQuoteItemLovVOImpl)findViewObject("XxcsoQuoteItemLovVO1");
  }

  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("itoen.oracle.apps.xxcso.xxcso007003j.lov.server", "XxcsoSalesRegistLovAMLocal");
  }

  /**
   * 
   * Container's getter for XxcsoApprovalUserLovVO1
   */
  public XxcsoApprovalUserLovVOImpl getXxcsoApprovalUserLovVO1()
  {
    return (XxcsoApprovalUserLovVOImpl)findViewObject("XxcsoApprovalUserLovVO1");
  }
}