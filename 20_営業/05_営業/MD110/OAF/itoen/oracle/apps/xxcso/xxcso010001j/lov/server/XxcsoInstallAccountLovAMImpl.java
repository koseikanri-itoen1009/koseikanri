/*============================================================================
* �t�@�C���� : XxcsoInstallAccountLovAMImpl
* �T�v����   : �ڋq���k�n�u�A�v���P�[�V�����E���W���[���N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-10-31 1.0  SCS�y���    �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso010001j.lov.server;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;
/*******************************************************************************
 * �ڋq���k�n�u���쐬���邽�߂̃A�v���P�[�V�����E���W���[���N���X�ł��B
 * @author  SCS�y���
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoInstallAccountLovAMImpl extends OAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoInstallAccountLovAMImpl()
  {
  }

  /**
   * 
   * Container's getter for XxcsoInstallAccountLovVO1
   */
  public XxcsoInstallAccountLovVOImpl getXxcsoInstallAccountLovVO1()
  {
    return (XxcsoInstallAccountLovVOImpl)findViewObject("XxcsoInstallAccountLovVO1");
  }

  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("itoen.oracle.apps.xxcso.xxcso010001j.lov.server", "XxcsoInstallAccountLovAMLocal");
  }
}