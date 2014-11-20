/*============================================================================
* �t�@�C���� : XxccpOAApplicationModuleImpl
* �T�v����   : ���ʃA�v���P�[�V�������W���[��
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-11-13 1.0  SCS KUME     �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxccp.util.server;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;
import oracle.apps.fnd.framework.server.OADBTransaction;
/***************************************************************************
 * ���ʃA�v���P�[�V�������W���[���N���X�ł��B
 * @author  SCS KUME
 * @version 1.0
 ***************************************************************************
 */
public class XxccpOAApplicationModuleImpl extends OAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxccpOAApplicationModuleImpl()
  {
  }

  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("itoen.oracle.apps.xxccp.util.server", "XxccpOAApplicationModuleImplLocal");
  }

  /***************************************************************************
   * �ύX�Ɋւ���x�����N���A���܂��B
   ***************************************************************************
   */
  public void clearWarnAboutChanges()
  {
    // �X�e�[�^�X��ύX�Ȃ��ɖ߂�
    getOADBTransaction().setPlsqlState(OADBTransaction.STATUS_UNMODIFIED);
  } // clearWarnAboutChanges

  /***************************************************************************
   * �ύX�Ɋւ���x����ݒ肵�܂��B
   ***************************************************************************
   */
  public void setWarnAboutChanges()
  {
    // �X�e�[�^�X��ύX�L��ɂ���
    getOADBTransaction().setPlsqlState(OADBTransaction.STATUS_DIRTY);
  } // setWarnAboutChanges
}