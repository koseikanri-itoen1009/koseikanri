/*============================================================================
* �t�@�C���� : XxcsoQuoteStoreRegistLovAMImpl
* �T�v����   : �����≮�p���ϓ��͉��LOV�p�A�v���P�[�V�����E���W���[���N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-15 1.0  SCS�y���    �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso017002j.lov.server;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;
/*******************************************************************************
 * �����≮�p���ϓ��͉�ʂ�LOV�̃A�v���P�[�V�����E���W���[���N���X�ł��B
 * @author  SCS�y���
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoQuoteStoreRegistLovAMImpl extends OAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoQuoteStoreRegistLovAMImpl()
  {
  }

  /**
   * 
   * Container's getter for XxcsoRefQuoteNumberLovVO1
   */
  public XxcsoRefQuoteNumberLovVOImpl getXxcsoRefQuoteNumberLovVO1()
  {
    return (XxcsoRefQuoteNumberLovVOImpl)findViewObject("XxcsoRefQuoteNumberLovVO1");
  }

  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("itoen.oracle.apps.xxcso.xxcso017002j.lov.server", "XxcsoQuoteStoreRegistLovAMLocal");
  }

  /**
   * 
   * Container's getter for XxcsoAccountStoreLovVO1
   */
  public XxcsoAccountStoreLovVOImpl getXxcsoAccountStoreLovVO1()
  {
    return (XxcsoAccountStoreLovVOImpl)findViewObject("XxcsoAccountStoreLovVO1");
  }


}