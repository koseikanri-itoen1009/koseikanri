/*============================================================================
* �t�@�C���� : XxcsoInstallAccountLovAMImpl
* �T�v����   : SP�ꌈ�����k�n�u�A�v���P�[�V�����E���W���[���N���X
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
 * SP�ꌈ�����k�n�u���쐬���邽�߂̃A�v���P�[�V�����E���W���[���N���X�ł��B
 * @author  SCS�y���
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoSpDecisionHeaderLovAMImpl extends OAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoSpDecisionHeaderLovAMImpl()
  {
  }

  /**
   * 
   * Container's getter for XxcsoSpDecisionHeaderLovVO1
   */
  public XxcsoSpDecisionHeaderLovVOImpl getXxcsoSpDecisionHeaderLovVO1()
  {
    return (XxcsoSpDecisionHeaderLovVOImpl)findViewObject("XxcsoSpDecisionHeaderLovVO1");
  }

  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("itoen.oracle.apps.xxcso.xxcso010001j.lov.server", "XxcsoSpDecisionHeaderLovAMLocal");
  }
}