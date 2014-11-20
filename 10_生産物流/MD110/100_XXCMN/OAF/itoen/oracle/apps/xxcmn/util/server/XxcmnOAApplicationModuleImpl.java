/*============================================================================
* �t�@�C���� : XxcmnOAApplicationModuleImpl
* �T�v����   : ���ʃA�v���P�[�V�������W���[��
* �o�[�W���� : 1.1
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2007-12-17 1.0  ��r���     �V�K�쐬
* 2008-08-13 1.1  ��r���     clearWarnAboutChanges
*                              setWarnAboutChanges���\�b�h�ǉ�
*============================================================================
*/
package itoen.oracle.apps.xxcmn.util.server;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;
import oracle.apps.fnd.framework.server.OADBTransaction;
/***************************************************************************
 * ���ʃA�v���P�[�V�������W���[���N���X�ł��B
 * @author  ORACLE ��r ���
 * @version 1.1
 ***************************************************************************
 */
public class XxcmnOAApplicationModuleImpl extends OAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcmnOAApplicationModuleImpl()
  {
  }

  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("itoen.oracle.apps.xxcmn.util.server", "XxcmnOAApplicationModuleImplLocal");
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