/*============================================================================
* �t�@�C���� : XxcsoQuoteSearchLovAMImpl
* �T�v����   : ���ϔԍ�LOV�A�v���P�[�V�����E���W���[���N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-22 1.0  SCS���g    �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso017006j.lov.server;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;

/*******************************************************************************
 * ���ϔԍ�LOV���쐬���邽�߂̃A�v���P�[�V�����E���W���[���N���X�ł��B
 * @author  SCS���g
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoQuoteSearchLovAMImpl extends OAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoQuoteSearchLovAMImpl()
  {
  }


  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("itoen.oracle.apps.xxcso.xxcso017006j.lov.server", "XxcsoQuoteSearchLovAMLocal");
  }

  /**
   * 
   * Container's getter for XxcsoQuoteSearchLovVO1
   */
  public XxcsoQuoteSearchLovVOImpl getXxcsoQuoteSearchLovVO1()
  {
    return (XxcsoQuoteSearchLovVOImpl)findViewObject("XxcsoQuoteSearchLovVO1");
  }
}