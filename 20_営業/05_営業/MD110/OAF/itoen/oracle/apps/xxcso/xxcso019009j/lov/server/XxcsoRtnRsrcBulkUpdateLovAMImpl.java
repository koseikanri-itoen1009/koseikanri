/*============================================================================
* �t�@�C���� : XxcsoRtnRsrcBulkUpdateLovAMImpl
* �T�v����   : �ڋq�R�[�hLOV�p�A�v���P�[�V�����E���W���[���N���X
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
 * �ڋq�R�[�hLOV�̃A�v���P�[�V�����E���W���[���N���X
 * @author  SCS�x���a��
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoRtnRsrcBulkUpdateLovAMImpl extends OAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoRtnRsrcBulkUpdateLovAMImpl()
  {
  }

  /**
   * 
   * Container's getter for XxcsoAccountRtnRsrcLovVO1
   */
  public XxcsoAccountRtnRsrcLovVOImpl getXxcsoAccountRtnRsrcLovVO1()
  {
    return (XxcsoAccountRtnRsrcLovVOImpl)findViewObject("XxcsoAccountRtnRsrcLovVO1");
  }

  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("itoen.oracle.apps.xxcso.xxcso019009j.lov.server", "XxcsoRtnRsrcBulkUpdateLovAMLocal");
  }


}