/*============================================================================
* �t�@�C���� : XxcsoBaseSearchLovVOImpl
* �T�v����   : �T�������󋵏Ɖ�^��������LOV�A�v���P�[�V�������W���[���N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-11-06 1.0  SCS�������l  �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso008001j.lov.server;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;

/*******************************************************************************
 * �T�������󋵏Ɖ�@��������LOV�A�v���P�[�V�������W���[���N���X
 * @author  SCS�������l
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoBaseSearchLovAMImpl extends OAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoBaseSearchLovAMImpl()
  {
  }


  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("itoen.oracle.apps.xxcso.xxcso008001j.lov.server", "XxcsoDivisionSearchLovAMLocal");
  }

  /**
   * 
   * Container's getter for XxcsoBaseSearchLovVO1
   */
  public XxcsoBaseSearchLovVOImpl getXxcsoBaseSearchLovVO1()
  {
    return (XxcsoBaseSearchLovVOImpl)findViewObject("XxcsoBaseSearchLovVO1");
  }
}