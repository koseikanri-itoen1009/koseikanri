/*============================================================================
* �t�@�C���� : XxcsoPvRegistLovAMImpl
* �T�v����   : �p�[�\�i���C�Y�E�r���[�쐬��ʁ^LOV�A�v���P�[�V�������W���[���N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-15 1.0  SCS�������l  �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso012001j.lov.server;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;

/*******************************************************************************
 * �p�[�\�i���C�Y�E�r���[�쐬��ʁ^LOV�A�v���P�[�V�������W���[���N���X
 * @author  SCS�������l
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoPvRegistLovAMImpl extends OAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoPvRegistLovAMImpl()
  {
  }


  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("itoen.oracle.apps.xxcso.xxcso012001j.lov.server", "XxcsoEmployeeItemLovAMLocal");
  }

  /**
   * 
   * Container's getter for XxcsoBaseItemLovVO1
   */
  public XxcsoBaseItemLovVOImpl getXxcsoBaseItemLovVO1()
  {
    return (XxcsoBaseItemLovVOImpl)findViewObject("XxcsoBaseItemLovVO1");
  }

  /**
   * 
   * Container's getter for XxcsoModelTypeSearchLovVO1
   */
  public XxcsoModelTypeSearchLovVOImpl getXxcsoModelTypeSearchLovVO1()
  {
    return (XxcsoModelTypeSearchLovVOImpl)findViewObject("XxcsoModelTypeSearchLovVO1");
  }

  /**
   * 
   * Container's getter for XxcsoAccountItemLovVO1
   */
  public XxcsoAccountItemLovVOImpl getXxcsoAccountItemLovVO1()
  {
    return (XxcsoAccountItemLovVOImpl)findViewObject("XxcsoAccountItemLovVO1");
  }
}