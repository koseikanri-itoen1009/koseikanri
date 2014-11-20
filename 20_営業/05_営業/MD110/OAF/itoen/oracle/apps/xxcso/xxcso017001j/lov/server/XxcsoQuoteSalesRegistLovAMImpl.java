/*============================================================================
* �t�@�C���� : XxcsoQuoteSalesRegistLovAMImpl
* �T�v����   : �̔��挩�ϓ��͉��LOV�p�A�v���P�[�V�����E���W���[���N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-21 1.0  SCS����_    �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso017001j.lov.server;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;
/*******************************************************************************
 * �̔��挩�ϓ��͉�ʂ�LOV�̃A�v���P�[�V�����E���W���[���N���X�ł��B
 * @author  SCS����_
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoQuoteSalesRegistLovAMImpl extends OAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoQuoteSalesRegistLovAMImpl()
  {
  }

  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("itoen.oracle.apps.xxcso.xxcso017001j.lov.server", "XxcsoQuoteSalesRegistLovAMLocal");
  }

  /**
   * 
   * Container's getter for XxcsoAccountSearchLovVO1
   */
  public XxcsoAccountSearchLovVOImpl getXxcsoAccountSearchLovVO1()
  {
    return (XxcsoAccountSearchLovVOImpl)findViewObject("XxcsoAccountSearchLovVO1");
  }

  /**
   * 
   * Container's getter for XxcsoInventoryItemSearchLovVO1
   */
  public XxcsoInventoryItemSearchLovVOImpl getXxcsoInventoryItemSearchLovVO1()
  {
    return (XxcsoInventoryItemSearchLovVOImpl)findViewObject("XxcsoInventoryItemSearchLovVO1");
  }
}