/*============================================================================
* �t�@�C���� : XxcsoAccountNumberLovAMImpl
* �T�v����   : �K��E����v���ʁ@�ڋq�R�[�h�k�n�u�A�v���P�[�V�������W���[���N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-07 1.0  SCS�p�M�F�@  �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso019001j.lov.server;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;

/*******************************************************************************
 * �K��E����v���ʁ@�ڋq�R�[�h�k�n�u�A�v���P�[�V�������W���[���N���X
 * @author  SCS�p�M�F
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoAccountNumberLovAMImpl extends OAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoAccountNumberLovAMImpl()
  {
  }

  /**
   * 
   * Container's getter for XxcsoAccountNumberLovVO1
   */
  public XxcsoAccountNumberLovVOImpl getXxcsoAccountNumberLovVO1()
  {
    return (XxcsoAccountNumberLovVOImpl)findViewObject("XxcsoAccountNumberLovVO1");
  }

  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("itoen.oracle.apps.xxcso.xxcso019001j.lov.server", "XxcsoAccountNumberLovAMLocal");
  }
}