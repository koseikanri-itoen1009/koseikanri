/*============================================================================
* �t�@�C���� : XxcsoSpDecisionSearchLovAMImpl
* �T�v����   : SP�ꌈ�������LOV�p�A�v���P�[�V�����E���W���[���N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-18 1.0  SCS����_    �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso020001j.lov.server;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;

/*******************************************************************************
 * SP�ꌈ������ʂ�LOV�̃A�v���P�[�V�����E���W���[���N���X�ł��B
 * @author  SCS����_
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoSpDecisionSearchLovAMImpl extends OAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoSpDecisionSearchLovAMImpl()
  {
  }


  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("itoen.oracle.apps.xxcso.xxcso020001j.lov.server", "XxcsoAccountForSearchLovAMLocal");
  }

  /**
   * 
   * Container's getter for XxcsoAccountForSearchLovVO1
   */
  public XxcsoAccountForSearchLovVOImpl getXxcsoAccountForSearchLovVO1()
  {
    return (XxcsoAccountForSearchLovVOImpl)findViewObject("XxcsoAccountForSearchLovVO1");
  }

  /**
   * 
   * Container's getter for XxcsoApplyUserLovVO1
   */
  public XxcsoApplyUserLovVOImpl getXxcsoApplyUserLovVO1()
  {
    return (XxcsoApplyUserLovVOImpl)findViewObject("XxcsoApplyUserLovVO1");
  }
}