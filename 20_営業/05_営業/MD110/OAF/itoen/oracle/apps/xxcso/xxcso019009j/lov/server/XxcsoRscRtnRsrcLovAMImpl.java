/*============================================================================
* �t�@�C���� : XxcsoRscRtnRsrcLovAMImpl
* �T�v����   : �S���c�ƈ�LOV�p�A�v���P�[�V�����E���W���[���N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-16 1.0  SCS�x���a��    �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso019009j.lov.server;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;

/*******************************************************************************
 * �S���c�ƈ�LOV�̃A�v���P�[�V�����E���W���[���N���X
 * @author  SCS�x���a��
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoRscRtnRsrcLovAMImpl extends OAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoRscRtnRsrcLovAMImpl()
  {
  }

  /**
   * 
   * Container's getter for XxcsoRscRtnRsrcLovVO1
   */
  public XxcsoRscRtnRsrcLovVOImpl getXxcsoRscRtnRsrcLovVO1()
  {
    return (XxcsoRscRtnRsrcLovVOImpl)findViewObject("XxcsoRscRtnRsrcLovVO1");
  }

  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("itoen.oracle.apps.xxcso.xxcso019009j.lov.server", "XxcsoRscRtnRsrcLovAMLocal");
  }
}